{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

{$if BX_SUPPORT_PAGING=1}
const
  BX_INVALID_TLB_ENTRY = $ffffffff;

{$if BX_CPU_LEVEL >= 4}
  BX_PRIV_CHECK_SIZE = 32;
{$else}
  BX_PRIV_CHECK_SIZE =16;
{$ifend}

var
  priv_check_array:array[0..BX_PRIV_CHECK_SIZE] of Word;

procedure BX_CPU_C.TLB_flush;
var
  I:Word;
begin
  {$if BX_USE_TLB=$01}
  i:=0;
  while i < BX_TLB_SIZE do
    begin
      TLB.entry[i].lpf := BX_INVALID_TLB_ENTRY;
      Inc(i);
    end;
  {$ifend}  // #if BX_USE_TLB

  invalidate_prefetch_q();
end;

procedure BX_CPU_C.TLB_clear;
var
  I:Word;
begin
  {$if BX_USE_TLB=$01}
    for i:=0 to BX_TLB_SIZE do {BX_TLB_SIZE -1 ???}
      TLB.entry[i].lpf := BX_INVALID_TLB_ENTRY;
  {$ifend}  // #if BX_USE_TLB
end;

procedure BX_CPU_C.TLB_init;
var
  i:Word;
  wp, us_combined, rw_combined, us_current, rw_current:Word;
begin
{$if BX_USE_TLB = $01}
  for i:=0 to BX_TLB_SIZE do
    TLB.entry[i].lpf := BX_INVALID_TLB_ENTRY;

  //
  // Setup privilege check matrix.
  //

  for i:=0 to BX_PRIV_CHECK_SIZE do
    begin
      wp          := (i and $10) shr 4;
      us_current  := (i and $08) shr 3;
      us_combined := (i and $04) shr 2;
      rw_combined := (i and $02) shr 1;
      rw_current  := (i and $01) shr 0;
      if Boolean(wp) then
        begin // when write protect on
          if us_current > us_combined then // user access, supervisor page
            priv_check_array[i] := 0
          else if rw_current > rw_combined then // RW access, RO page
            priv_check_array[i] := 0
          else
            priv_check_array[i] := 1;
        end
    else
      begin
         // when write protect off
        if us_current = 0 then // Supervisor mode access, anything goes
          priv_check_array[i] := 1
        else
          begin
              // user mode access
            if us_combined = 0 then // user access, supervisor Page
              priv_check_array[i] := 0
            else if rw_current > rw_combined then // RW access, RO page
              priv_check_array[i] := 0
            else
              priv_check_array[i] := 1;
          end;
      end;
   end;
{$ifend}
end;

procedure BX_CPU_C.INVLPG(Instruction:PBxInstruction_tag);
begin
  {$if BX_CPU_LEVEL >= 4}
    invalidate_prefetch_q();

    // Operand must not be a register
    if (Instruction.mod_ = $c0) then
      begin
        BX_INFO('INVLPG: op is a register');
        UndefinedOpcode(Instruction);
      end;
    // Can not be executed in v8086 mode
    if Boolean(v8086_mode()) then
      exception(BX_GP_EXCEPTION, 0, 0);

    // Protected instruction: CPL0 only
    if Boolean(cr0.pe) then
      begin
        if (CPL <> 0) then
          begin
            BX_INFO('INVLPG: CPL!=0');
            exception2([BX_GP_EXCEPTION, 0, 0]);
          end;
      end;

  {$if BX_USE_TLB = $01}
      // Just clear the entire TLB, ugh!
      TLB_clear();
  {$ifend} // BX_USE_TLB
    //BX_INSTR_TLB_CNTRL(BX_INSTR_INVLPG, 0); !!!vedere sorgente

  {$else}
    // not supported on < 486
    UndefinedOpcode(instruction);
  {$ifend}
end;

procedure BX_CPU_C.enable_paging;
begin
  TLB_flush();
  //if bx_dbg.paging then BX_INFO('enable_paging():');
//BX_DEBUG(( "enable_paging():-------------------------" ));
end;

procedure BX_CPU_C.disable_paging;
begin
  TLB_flush();
  //if bx_dbg.paging then BX_INFO('enable_paging():');
//BX_DEBUG(( "enable_paging():-------------------------" ));
end;


procedure BX_CPU_C.CR3_change(value32:Bit32u);

begin

{  if bx_dbg.paging then

    begin

      BX_INFO('CR3_change(): flush TLB cache');
      BX_INFO(Format('Page Directory Base %08x', value32));
    end;}

  // flush TLB even if value does not change
  TLB_flush();
  cr3 := value32;
end;

function BX_CPU_C.itranslate_linear(laddress:Bit32u; pl:unsigned):Bit32u;
var
  lpf, ppf, poffset, TLB_index, error_code, paddress:Bit32u;
  pde, pde_addr:Bit32u;
  pte, pte_addr:Bit32u;
  priv_index:Word;
  combined_access:Bit32u;
  label priv_check, page_fault;
begin
  lpf       := laddress and $fffff000; // linear page frame
  poffset   := laddress and $00000fff; // physical offset
  TLB_index := (lpf and $003ff000) shr 12;
  if TLB.entry[TLB_index].lpf = lpf then
    begin
      paddress        := TLB.entry[TLB_index].ppf or poffset;
      combined_access := TLB.entry[TLB_index].combined_access;
  priv_check:
      priv_index :=
    {$if BX_CPU_LEVEL >= 4}
      (cr0.wp shl 4) or   // bit 4
    {$ifend}
      (pl shl 3) or                       // bit 3
      (combined_access and $06);       // bit 2,1
                                      // bit 0 == 0
      if Boolean(priv_check_array[priv_index]) then
        begin
          // Operation has proper privilege.
          Result:=paddress;
          exit;
        end;
      error_code := $fffffff9; // RSVD=1, P=1
      goto page_fault;
      end;
      // Get page dir entry
      pde_addr := (cr3 and $fffff000) or ((laddress and $ffc00000) shr 20);
      sysmemory.read_physical(pde_addr, 4, @pde);
      if Boolean((pde and $01)=0) then
        begin
          // Page Directory Entry NOT present
          error_code := $fffffff8; // RSVD=1, P=0
          goto page_fault;
        end;
      // Get page table entry
      pte_addr := (pde and $fffff000) or ((laddress and $003ff000) shr 10);
      sysmemory.read_physical(pte_addr, 4, @pte);

      // update PDE if A bit was not set before
      if Boolean( (pde and $20)=0) then
        begin
          pde := pde or $20;
          sysmemory.write_physical(pde_addr, 4, @pde);
        end;

      if Boolean( (pte and $01)=0) then
        begin
          // Page Table Entry NOT present
          error_code := $fffffff8; // RSVD=1, P=0
          goto page_fault;
        end;
      //BW added: update PTE if A bit was not set before
      if Boolean( (pte and $20)=0) then
        begin
          pte := pte or $20;
          sysmemory.write_physical(pte_addr, 4, @pte);
        end;
      // 386 and 486+ have different bahaviour for combining
      // privilege from PDE and PTE.
    {$if BX_CPU_LEVEL = 3}
      combined_access  := (pde or pte) and $04; // U/S
      combined_access := combined_access or (pde and pte) and $02; // R/W
    {$else} // 486+
      combined_access  := (pde and pte) and $06; // U/S and R/W
    {$ifend}

      ppf := pte and $fffff000;
      paddress := ppf or poffset;

      TLB.entry[TLB_index].lpf := lpf;
      TLB.entry[TLB_index].ppf := ppf;
      TLB.entry[TLB_index].pte_addr := pte_addr;
      TLB.entry[TLB_index].combined_access := combined_access;
      goto priv_check;
    page_fault:
      error_code :=error_code or (pl shl 2);
      cr2 := laddress;
      // invalidate entry - we can get away without maintaining A bit in PTE
      // if we don't maintain TLB entries without it set.
      TLB.entry[TLB_index].lpf := BX_INVALID_TLB_ENTRY;
      exception(BX_PF_EXCEPTION, error_code, 0);
end;

function BX_CPU_C.dtranslate_linear(laddress:Bit32u; pl:unsigned; rw:unsigned):Bit32u;
var
  lpf, ppf, poffset, TLB_index, error_code, paddress:Bit32u;
  pde, pde_addr:Bit32u;
  pte, pte_addr:Bit32u;
  priv_index:unsigned;
  is_rw:Bool;
  combined_access, new_combined_access:Bit32u;
  label priv_check;
  label page_fault_check;
  label page_fault_not_present;
  label page_fault_proper;
begin
  lpf       := laddress and $fffff000; // linear page frame
  poffset   := laddress and $00000fff; // physical offset
  TLB_index := (lpf and $003ff000) shr 12;
  is_rw := Bool((rw>=BX_WRITE)); // write or r-m-w

  if (TLB.entry[TLB_index].lpf = lpf) then
    begin
      paddress        := TLB.entry[TLB_index].ppf or poffset;
      combined_access := TLB.entry[TLB_index].combined_access;
      priv_check:
      priv_index :=
      {$if BX_CPU_LEVEL >= 4}
        (cr0.wp shl 4) or  // bit 4
      {$ifend}
      (pl shl 3) or                      // bit 3
      (combined_access and $06) or     // bit 2,1
      is_rw;                         // bit 0
      if (Boolean(priv_check_array[priv_index])) then
        begin
          // Operation has proper privilege.
          // See if A/D bits need updating.
          //BW !! a read access does not do any updates, patched load
          new_combined_access := combined_access or is_rw;
          if new_combined_access = combined_access then
            begin
            // A/D bits already up-to-date
              Result:=paddress;
              exit;
           end;
        TLB.entry[TLB_index].combined_access := new_combined_access;
        pte_addr := TLB.entry[TLB_index].pte_addr;
        sysmemory.read_physical(pte_addr, 4, @pte); // get old PTE
        pte := pte or $20 or (is_rw shl 6);
        sysmemory.write_physical(pte_addr, 4, @pte); // write updated PTE
        Result:=paddress;
        exit;
        end;
      error_code := $fffffff9; // RSVD=1, P=1
      goto page_fault_check;
   end;
      // Get page dir entry
      pde_addr := (cr3 and $fffff000) or ((laddress and $ffc00000) shr 20);
      sysmemory.read_physical(pde_addr, 4, @pde);
      if (pde and $01)=0  then
        begin
          // Page Directory Entry NOT present
          error_code := $fffffff8; // RSVD=1, P=0
          goto page_fault_not_present;
        end;
      // Get page table entry
      pte_addr := (pde and $fffff000) or ((laddress and $003ff000) shr 10);
      sysmemory.read_physical(pte_addr, 4, @pte);

    // update PDE if A bit was not set before
    if ( (pde and $20)=0 ) then
      begin
        pde :=pde or $20;
        sysmemory.write_physical(pde_addr, 4, @pde);
      end;
    if ( (pte and $01)=0 ) then
      begin
        // Page Table Entry NOT present
        error_code := $fffffff8; // RSVD=1, P=0
        goto page_fault_not_present;
      end;

    //BW added: update PTE if A bit was not set before
    if ( (pte and $20) =0) then
      begin
        pte := pte or $20;
        sysmemory.write_physical(pte_addr, 4, @pte);
      end;
      // 386 and 486+ have different bahaviour for combining
      // privilege from PDE and PTE.
    {$if BX_CPU_LEVEL = 3}
      combined_access  := (pde or pte) and $04; // U/S
      combined_access := combined_access or (pde and pte) and $02; // R/W
    {$else} // 486+
      combined_access  := (pde and pte) and $06; // U/S and R/W
    {$ifend}

      ppf := pte and $fffff000;
      paddress := ppf or poffset;

      TLB.entry[TLB_index].lpf := lpf;
      TLB.entry[TLB_index].ppf := ppf;
      TLB.entry[TLB_index].pte_addr := pte_addr;
      TLB.entry[TLB_index].combined_access := combined_access;
      goto priv_check;

      page_fault_check:
      // (mch) Define RMW_WRITES for old behavior
      {$ifndef RMW_WRITES}
        (* (mch) Ok, so we know it's a page fault. It the access is a
           read-modify-write access we check if the read faults, if it
           does then we (optionally) do not set the write bit *)
        if (rw = BX_RW) then
          begin
                priv_index :=
      {$if BX_CPU_LEVEL >= 4}
                        (cr0.wp shl 4) or               // bit 4
      {$ifend}
                        (pl shl 3) or                   // bit 3
                        (combined_access and $06) or  // bit 2,1
                        0;                      // bit 0 (read)
                if (priv_check_array[priv_index] = 0) then
                  begin
                        // Fault on read
                        is_rw := 0;
                  end;
          end;
      {$endif} // RMW_WRITES
        goto page_fault_proper;
        page_fault_not_present:
        {$ifndef RMW_WRITES}
          if (rw = BX_RW) then
                  is_rw := 0;
        {$endif} // RMW_WRITES
          goto page_fault_proper;
    page_fault_proper:
    error_code := error_code or (pl shl 2) or (is_rw shl 1);
    cr2 := laddress;
  // invalidate entry - we can get away without maintaining A bit in PTE
  // if we don't maintain TLB entries without it set.
  TLB.entry[TLB_index].lpf := BX_INVALID_TLB_ENTRY;
  exception(BX_PF_EXCEPTION, error_code, 0);
end;

procedure BX_CPU_C.access_linear(const laddress:Bit32u; const length:unsigned; const pl:unsigned; rw:unsigned; data:Pointer);
var
  mod4096:Bit32u;
  xlate_rw:Word;
begin
  if rw=BX_RW then
    begin
      xlate_rw := BX_RW;
      rw := BX_READ;
    end
  else begin
    xlate_rw := rw;
    end;

    ////*********
    if self.cr0.pg<>0 then
    begin
    // check for reference across multiple pages
    mod4096 := laddress and $00000fff;
    if ( (mod4096 + length) <= 4096 ) then
      begin
        // Bit32u paddress1;

        // access within single page
        address_xlation.paddress1 := dtranslate_linear(laddress, pl, xlate_rw);
        address_xlation.pages     := 1;

        if (rw = BX_READ) then
          begin
            //BX_INSTR_LIN_READ(laddress, BX_CPU_THIS_PTR address_xlation.paddress1, length);
            sysmemory.read_physical(address_xlation.paddress1, length, data);
          end
        else
          begin
            {
            BX_INSTR_LIN_WRITE(laddress, BX_CPU_THIS_PTR address_xlation.paddress1, length);}
            sysmemory.write_physical(address_xlation.paddress1, length, data);
          end;
        exit;
     end
     else
     begin
        // access across 2 pages
        address_xlation.paddress1 := dtranslate_linear(laddress, pl, xlate_rw);
        address_xlation.len1      := 4096 - mod4096;
        address_xlation.len2      := length - address_xlation.len1;
        address_xlation.pages     := 2;

        address_xlation.paddress2 := dtranslate_linear(laddress + address_xlation.len1, pl, xlate_rw);

        //VEDERE CODICE ORIGINALE
      if (rw = BX_READ) then begin
        sysmemory.read_physical(address_xlation.paddress1,
                             address_xlation.len1, data);
        sysmemory.read_physical(address_xlation.paddress2,
                             address_xlation.len2,
                             PBit8u(Integer(data) + address_xlation.len1));
        end
      else begin
        sysmemory.write_physical(address_xlation.paddress1,
                              address_xlation.len1, data);
        sysmemory.write_physical(address_xlation.paddress2,
                              address_xlation.len2,
                              PBit8u(Integer(data) + address_xlation.len1));
        end;
     end;
   end
   else
    begin
      // paging off, pass linear address thru to physical
      if (rw = BX_READ) then begin
        sysmemory.read_physical(laddress, length, data);
        end
      else begin
        sysmemory.write_physical(laddress, length, data);
      end;
      exit;
     end;
end;
{$ifend}
