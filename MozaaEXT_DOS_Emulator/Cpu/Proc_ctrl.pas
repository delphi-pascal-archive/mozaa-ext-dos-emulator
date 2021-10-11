{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.UndefinedOpcode(Instruction:PBxInstruction_tag);
begin
  BX_DEBUG(Format('UndefinedOpcode: %02x causes exception 6', [Instruction^.b1]));
  exception2([BX_UD_EXCEPTION, 0, 0]);
  //VEDERE CODICE SORGENTE ORIGINALE
end;

procedure BX_CPU_C.NOP(I:PBxInstruction_tag);
begin
end;

procedure BX_CPU_C.HLT(I:PBxInstruction_tag);
begin
  // hack to panic if HLT comes from BIOS
  if Boolean( sregs[BX_SEG_REG_CS].selector.value = $f000 ) then
    BX_PANIC(('HALT instruction encountered in the BIOS ROM'));

  if Boolean(CPL <> 0) then begin
    BX_INFO(('HLT(): CPL <> 0'));
    exception2([BX_GP_EXCEPTION, 0, 0]);
    exit;
    end;

  if Boolean( eflags.if_=0) then begin
    BX_INFO(('WARNING: HLT instruction with IF:=0!'));
    end;

  // stops instruction execution and places the processor in a
  // HALT state.  An enabled interrupt, NMI, or reset will resume
  // execution.  If interrupt (including NMI) is used to resume
  // execution after HLT, the saved CS:eIP points to instruction
  // following HLT.

  // artificial trap bit, why use another variable.
  debug_trap := debug_trap or $80000000; // artificial trap
  async_event := 1; // so processor knows to check
  // Execution of this instruction completes.  The processor
  // will remain in a halt state until one of the above conditions
  // is met.

{$if BX_USE_IDLE_HACK=1}
  bx_gui.sim_is_idle ();
{$ifend} (* BX_USE_IDLE_HACK *)
end;

procedure BX_CPU_C.CLTS(I:PBxInstruction_tag);
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('CLTS: not implemented for < 286'));
{$else}

  if Boolean(v8086_mode()) then BX_PANIC(('clts: v8086 mod_e unsupported'));

  (* read errata file *)
  // does CLTS also clear NT flag???

  // #GP(0) if CPL is not 0
  if Boolean(CPL <> 0) then begin
    BX_INFO(('CLTS(): CPL <> 0'));
    exception2([BX_GP_EXCEPTION, 0, 0]);
    exit;
    end;

  cr0.ts := 0;
  Self.cr0.val32 := Self.cr0.val32 and not $08; 
{$ifend}
end;

procedure BX_CPU_C.INVD(I:PBxInstruction_tag);
begin
  BX_INFO(('---------------'));
  BX_INFO(('- INVD called -'));
  BX_INFO(('---------------'));

{$if BX_CPU_LEVEL >= 4
  invalidate_prefetch_q();

  if Boolean(Self.cr0.pe) then begin
    if Boolean(CPL <> 0) then begin
      BX_INFO(('INVD: CPL <> 0'));
      exception(BX_GP_EXCEPTION, 0, 0);
      end;
    end;
  BX_INSTR_CACHE_CNTRL(BX_INSTR_INVD);
{$else}
  UndefinedOpcode(i);
{$ifend}
end;

procedure BX_CPU_C.WBINVD(I:PBxInstruction_tag);
begin
  BX_INFO(('WBINVD: (ignoring)'));

{$if BX_CPU_LEVEL >= 4}
  invalidate_prefetch_q();

  if Boolean(Self.cr0.pe) then begin
    if Boolean(CPL<>0) then begin
      BX_INFO(('WBINVD: CPL <> 0'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      end;
    end;
  //BX_INSTR_CACHE_CNTRL(BX_INSTR_WBINVD); !!
{$else}
  UndefinedOpcode(i);
{$ifend}
end;

procedure BX_CPU_C.MOV_DdRd(I:PBxInstruction_tag);
var
  val_32:Bit32u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('MOV_DdRd: not supported on < 386'));
{$else}

  if Boolean(v8086_mode()) then BX_PANIC(('MOV_DdRd: v8086 mod_e unsupported'));

  (* NOTES:
   *   32bit operands always used
   *   r/m field specifies general register
   *   mod_ field should always be 11 binary
   *   reg field specifies which special register
   *)

  if Boolean(i^.mod_ <> $c0) then begin
    BX_PANIC(('MOV_DdRd(): rm field not a register!'));
    end;

  invalidate_prefetch_q();

  if Boolean(Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)) and CPL<>0) then begin
    BX_PANIC(('MOV_DdRd: CPL <> 0'));
    (* #GP(0) if CPL is not 0 *)
    exception2([BX_GP_EXCEPTION, 0, 0]);
    end;

  val_32 := BX_READ_32BIT_REG(i^.rm);
  {if Boolean(bx_dbg.dreg)
    BX_INFO(('MOV_DdRd: DR[%u]:=%08xh unhandled',
      (unsigned) i^.nnn, (unsigned) val_32)); !!!}

  case (i^.nnn) of
    0: // DR0
      Self.dr0 := val_32;
    1: // DR1
      Self.dr1 := val_32;
    2: // DR2
      Self.dr2 := val_32;
    3: // DR3
      Self.dr3 := val_32;

    4, // DR4
    6: // DR6
      begin
      // DR4 aliased to DR6 by default.  With Debug Extensions on,
      // access to DR4 causes #UD
{$if BX_CPU_LEVEL >= 4}
        if Boolean( (i^.nnn = 4) and Boolean(Self.cr4 and $00000008) ) then begin
          // Debug extensions on
          BX_INFO(('MOV_DdRd: access to DR4 causes #UD'));
          UndefinedOpcode(i);
          end;
{$ifend}
{$if BX_CPU_LEVEL <= 4}
      // On 386/486 bit12 is settable
          Self.dr6 := (Self.dr6 and $ffff0ff0) or (val_32 and $0000f00f);
{$else}
      // On Pentium+, bit12 is always zero
          Self.dr6 := (Self.dr6 and $ffff0ff0) or (val_32 and $0000e00f);
{$ifend}
     end;
    5, // DR5
    7:
      begin// DR7
      // Note: 486+ ignore GE and LE flags.  On the 386, exact
      // data breakpoint matching does not occur unless it is enabled
      // by setting the LE and/or GE flags.

      // DR5 aliased to DR7 by default.  With Debug Extensions on,
      // access to DR5 causes #UD
{$if BX_CPU_LEVEL >= 4}
      if Boolean( (i^.nnn = 5) and Boolean(Self.cr4 and $00000008) ) then begin
        // Debug extensions (CR4.DE) on
        BX_INFO(('MOV_DdRd: access to DR5 causes #UD'));
        UndefinedOpcode(i);
        end;
{$ifend}
      // Some sanity checks...
      if Boolean( val_32  and $00002000 ) then begin
        BX_PANIC(('MOV_DdRd: GD bit not supported yet'));
        // Note: processor clears GD upon entering debug exception
        // handler, to allow access to the debug registers
        end;
      if Boolean( (((val_32 shr 16)  and 3)=2) or
           (((val_32 shr 20)  and 3)=2) or
           (((val_32 shr 24)  and 3)=2) or
           (((val_32 shr 28)  and 3)=2) ) then begin
        // IO breakpoints (10b) are not yet supported.
        BX_PANIC(Format('MOV_DdRd: write of %08x contains IO breakpoint',[val_32]));
        end;
      if Boolean( (((val_32 shr 18)  and 3)=2) or
           (((val_32 shr 22)  and 3)=2) or
           (((val_32 shr 26)  and 3)=2) or
           (((val_32 shr 30)  and 3)=2) ) then begin
        // LEN0..3 contains undefined length specifier (10b)
        BX_PANIC(Format('MOV_DdRd: write of %08x contains undefined LENx',[val_32]));
        end;
      if Boolean( ((((val_32 shr 16)  and 3)=0) and (((val_32 shr 18)  and 3) <> 0)) or
           ((((val_32 shr 20)  and 3)=0) and (((val_32 shr 22)  and 3) <> 0)) or
           ((((val_32 shr 24)  and 3)=0) and (((val_32 shr 26)  and 3) <> 0)) or
           ((((val_32 shr 28)  and 3)=0) and (((val_32 shr 30)  and 3) <> 0)) ) then begin
        // Instruction breakpoint with LENx not 00b (1-byte length)
        BX_PANIC(Format('MOV_DdRd: write of %08x, R/W:=00b LEN <> 00b', [val_32]));
        end;
{$if BX_CPU_LEVEL <= 4}
      // 386/486: you can play with all the bits except b10 is always 1
      Self.dr7 := val_32 or $00000400;
{$else}
      // Pentium+: bits15,14,12 are hardwired to 0, rest are settable.
      // Even bits 11,10 are changeable though reserved.
      Self.dr7 := (val_32  and $ffff2fff)or$00000400;
{$ifend}
    end;
    else
      BX_PANIC(('MOV_DdRd: control register index out of range'));
    end;
{$ifend}
end;

procedure BX_CPU_C.MOV_RdDd(I:PBxInstruction_tag);
var
  val_32:Bit32u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('MOV_RdDd: not supported on < 386'));
{$else}

  if Boolean(v8086_mode()) then begin
    BX_INFO(('MOV_RdDd: v8086 mod_e causes #GP'));
    exception2([BX_GP_EXCEPTION, 0, 0]);
    end;

  if Boolean(i^.mod_ <> $c0) then begin
    BX_PANIC(('MOV_RdDd(): rm field not a register!'));
    UndefinedOpcode(i);
    end;

  if Boolean(Boolean(Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0))) and (CPL<>0)) then begin
    BX_INFO(('MOV_RdDd: CPL <> 0 causes #GP'));
    exception2([BX_GP_EXCEPTION, 0, 0]);
    exit;
    end;

{  if Boolean(bx_dbg.dreg) then
    BX_INFO(('MOV_RdDd: DR%u not implemented yet', i^.nnn)); !!!}

  case (i^.nnn) of
    0: // DR0
      val_32 := Self.dr0;
    1: // DR1
      val_32 := Self.dr1;
    2: // DR2
      val_32 := Self.dr2;
    3: // DR3
      val_32 := Self.dr3;

    4, // DR4
    6:
      begin// DR6
      // DR4 aliased to DR6 by default.  With Debug Extensions on,
      // access to DR4 causes #UD
{$if BX_CPU_LEVEL >= 4}
      if Boolean( (i^.nnn = 4) and Boolean(Self.cr4 and $00000008) ) then begin
        // Debug extensions on
        BX_INFO(('MOV_RdDd: access to DR4 causes #UD'));
        UndefinedOpcode(i);
        end;
{$ifend}
      val_32 := Self.dr6;
     end;

    5, // DR5
    7:
      begin// DR7
      // DR5 aliased to DR7 by default.  With Debug Extensions on,
      // access to DR5 causes #UD
{$if BX_CPU_LEVEL >= 4}
      if Boolean( (i^.nnn = 5) and Boolean(Self.cr4 and $00000008) ) then begin
        // Debug extensions on
        BX_INFO(('MOV_RdDd: access to DR5 causes #UD'));
        UndefinedOpcode(i);
        end;
{$ifend}
      val_32 := Self.dr7;
      end;

    else
      begin
        BX_PANIC(('MOV_RdDd: control register index out of range'));
        val_32 := 0;
      end;  
    end;
  BX_WRITE_32BIT_REG(i^.rm, val_32);
{$ifend}
end;

procedure BX_CPU_C.LMSW_Ew(I:PBxInstruction_tag);
var
  msw:Bit16u;
  cr0:Bit32u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('LMSW_Ew(): not supported on 8086!'));
{$else}

  if Boolean(v8086_mode()) then BX_PANIC(('proc_ctrl: v8086 mod_e unsupported'));

  if Boolean( Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)) ) then begin
    if Boolean( CPL  <>  0 ) then begin
      BX_INFO(Format('LMSW: CPL  <>  0, CPL:=%u',[CPL]));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      exit;
      end;
    end;

  if Boolean(i^.mod_ = $c0) then begin
    msw := BX_READ_16BIT_REG(i^.rm);
    end
  else begin
    read_virtual_word(i^.seg, i^.rm_addr, @msw);
    end;

  // LMSW does not affect PG,CD,NW,AM,WP,NE,ET bits, and cannot clear PE

  // LMSW cannot clear PE
  if Boolean( ((msw and $0001)=0) and Boolean(Self.cr0.pe) ) then begin
    msw := msw or $0001; // adjust PE bit to current value of 1
    end;

  msw := msw and $000f; // LMSW only affects last 4 flags
  cr0 := (Self.cr0.val32 and $fffffff0) or msw;
   SetCR0(cr0); 
{$ifend} (* BX_CPU_LEVEL < 2 *)
end;

procedure BX_CPU_C.SMSW_Ew(I:PBxInstruction_tag);
var
  msw:Bit16u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('SMSW_Ew: not supported yet!'));
{$else}


{$if BX_CPU_LEVEL = 2}
  msw := $fff0; (* 80286 init value *)
  msw :=msw or (Self.cr0.ts  shl  3) or
         (Self.cr0.em  shl  2) or
         (Self.cr0.mp  shl  1) or
         Self.cr0.pe;
{$else} (* 386+ *)
  (* reserved bits 0 ??? *)
  (* should NE bit be included here ??? *)
  // should ET bit be included here (AW)
  msw :=  (Self.cr0.ts  shl  3) or
         (Self.cr0.em  shl  2) or
         (Self.cr0.mp  shl  1) or
         Self.cr0.pe;
{$ifend}


  if Boolean(i^.mod_ = $c0) then begin
    if Boolean(i^.os_32) then begin
      BX_WRITE_32BIT_REG(i^.rm, msw);  // zeros out high 16bits
      end
  else begin
      BX_WRITE_16BIT_REG(i^.rm, msw);
      end;
    end
  else begin
    write_virtual_word(i^.seg, i^.rm_addr, @msw);
    end;

{$ifend}
end;

procedure BX_CPU_C.MOV_CdRd(I:PBxInstruction_tag);
var
  val_32:Bit32u;
begin
  // mov general register data to control register
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('MOV_CdRd: not supported on < 386'));
{$else}

  if Boolean(v8086_mode) then BX_PANIC(('proc_ctrl: v8086 mod_e unsupported'));

  (* NOTES:
   *   32bit operands always used
   *   r/m field specifies general register
   *   mod_ field should always be 11 binary
   *   reg field specifies which special register
   *)

  if Boolean(i^.mod_  <>  $c0) then begin
    BX_PANIC(('MOV_CdRd(): rm field not a register!'));
    end;

  invalidate_prefetch_q();

  if Boolean(Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)) and CPL <> 0) then begin
    BX_PANIC(('MOV_CdRd: CPL <> 0'));
    (* #GP(0) if CPL is not 0 *)
    exception2([BX_GP_EXCEPTION, 0, 0]);
    exit;
    end;

  val_32 := BX_READ_32BIT_REG(i^.rm);

  case (i^.nnn) of
    0:
      begin // CR0 (MSW)
      // BX_INFO(('MOV_CdRd:CR0: R32 := %08x\n @CS:EIP %04x:%04x ',
      //   (unsigned) val_32,
      //   (unsigned) Self.sregs[BX_SEG_REG_CS].selector.value,
      //   (unsigned) Self.eip));
      SetCR0(val_32);
      end;
    1: (* CR1 *)
      BX_PANIC(('MOV_CdRd: CR1 not implemented yet'));
    2: (* CR2 *)
      begin
        BX_DEBUG(('MOV_CdRd: CR2 not implemented yet'));
	      BX_DEBUG(('MOV_CdRd: CR2 := reg'));
        Self.cr2 := val_32;
      end;
    3: // CR3
      begin
        {if Boolean(bx_dbg.creg) then
          BX_INFO(('MOV_CdRd:CR3 := %08x', (unsigned) val_32)); !!!}
        // Reserved bits take on value of MOV instruction
        CR3_change(val_32);
        //BX_INSTR_TLB_CNTRL(BX_INSTR_MOV_CR3, val_32); {!!!!!}
      end;
    4:
      begin
      // CR4
{$if BX_CPU_LEVEL = 3}
      BX_PANIC(Format('MOV_CdRd: write to CR4 of $%08x on 386',[val_32]));
      UndefinedOpcode(i);
{$else}
      //  Protected mod_e: #GP(0) if attempt to write a 1 to
      //  any reserved bit of CR4

      BX_INFO(Format('MOV_CdRd: ignoring write to CR4 of $%08x',[val_32]));
      if Boolean(val_32) then begin
        BX_INFO(Format('MOV_CdRd: (CR4) write of $%08x not supported!',[val_32]));
        end;
      // Only allow writes of 0 to CR4 for now.
      // Writes to bits in CR4 should not be 1s as CPUID
      // returns not-supported for all of these features.
      Self.cr4 := 0;
{$ifend}
      end;
    else
      BX_PANIC(('MOV_CdRd: control register index out of range'));
    end;
{$ifend}
end;

procedure BX_CPU_C.MOV_RdCd(I:PBxInstruction_tag);
var
  val_32:Bit32u;
begin
  // mov control register data to register
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('MOV_RdCd: not supported on < 386'));
{$else}

  if Boolean(v8086_mode()) then BX_PANIC(('proc_ctrl: v8086 mod_e unsupported'));

  (* NOTES:
   *   32bit operands always used
   *   r/m field specifies general register
   *   mod_ field should always be 11 binary
   *   reg field specifies which special register
   *)

  if Boolean(i^.mod_  <>  $c0) then begin
    BX_PANIC(('MOV_RdCd(): rm field not a register!'));
    end;

  if Boolean(Boolean(Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0))) and (CPL <> 0)) then begin
    BX_PANIC(('MOV_RdCd: CPL <> 0'));
    (* #GP(0) if CPL is not 0 *)
    exception2([BX_GP_EXCEPTION, 0, 0]);
    exit;
    end;

  case (i^.nnn) of
    0:
      begin // CR0 (MSW)
        val_32 := Self.cr0.val32;
{$if 1=2} //!!!!
      BX_INFO(('MOV_RdCd:CR0: R32 := %08x\n @CS:EIP %04x:%04x',
        (unsigned) val_32,
        (unsigned) Self.sregs[BX_SEG_REG_CS].selector.value,
        (unsigned) Self.eip));
{$ifend}
      end;
    1: (* CR1 *)
      begin
        BX_PANIC(('MOV_RdCd: CR1 not implemented yet'));
        val_32 := 0;
      end;
    2: (* CR2 *)
      begin
        {if Boolean(bx_dbg.creg)
          BX_INFO(('MOV_RdCd: CR2')); !!!!}
        val_32 := Self.cr2;
      end;
    3:
      begin// CR3
      {if Boolean(bx_dbg.creg)
        BX_INFO(('MOV_RdCd: reading CR3')); !!!!}
      val_32 := Self.cr3;
      end;
    4: // CR4
      begin
{$if BX_CPU_LEVEL = 3}
      val_32 := 0;
      BX_INFO(('MOV_RdCd: read of CR4 causes #UD'));
      UndefinedOpcode(i);
{$else}
      BX_INFO(('MOV_RdCd: read of CR4'));
      val_32 := Self.cr4;
{$ifend}
      end;
    else
      BX_PANIC(('MOV_RdCd: control register index out of range'));
      val_32 := 0;
    end;
  BX_WRITE_32BIT_REG(i^.rm, val_32);
{$ifend}
end;

procedure BX_CPU_C.MOV_TdRd(I:PBxInstruction_tag);
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('MOV_TdRd:'));
{$elseif BX_CPU_LEVEL <= 4}
  BX_PANIC(('MOV_TdRd:'));
{$else}
  // Pentium+ does not have TRx.  They were redesigned using the MSRs.
  BX_INFO(('MOV_TdRd: causes #UD'));
  UndefinedOpcode(i);
{$ifend}
end;

procedure BX_CPU_C.MOV_RdTd(I:PBxInstruction_tag);
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('MOV_RdTd:'));
{$elseif BX_CPU_LEVEL <= 4}
  BX_PANIC(('MOV_RdTd:'));
{$else}
  // Pentium+ does not have TRx.  They were redesigned using the MSRs.
  BX_INFO(('MOV_RdTd: causes #UD'));
  UndefinedOpcode(i);
{$ifend}
end;

procedure BX_CPU_C.LOADALL(I:PBxInstruction_tag);
var
  msw, tr, flags, iplocal, ldtr:Bit16u;
  ds_raw, ss_raw, cs_raw, es_raw:Bit16u;
  di_, si_, bp_, sp_, bx_, dx_, cx_, ax_:Bit16u;
  base_15_0, limit:Bit16u;
  base_23_16, access:Bit8u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('undocumented LOADALL instruction not supported on 8086'));
{$else}

  if Boolean(v8086_mode()) then BX_PANIC(('proc_ctrl: v8086 mod_e unsupported'));

{$if BX_CPU_LEVEL > 2}
  BX_PANIC(('loadall: not implemented for 386'));
  (* ??? need to set G and other bits, and compute .limit_scaled also *)
  (* for all segments CS,DS,SS,... *)
{$ifend}

  if Boolean(Self.cr0.pe) then begin
    BX_PANIC((
      'LOADALL not yet supported for protected mod_e'));
    end;

BX_PANIC(('LOADALL: handle CR0.val32'));
  (* MSW *)
  sysmemory.read_physical( $806, 2, @msw);
  Self.cr0.pe := (msw and $01); msw := msw shr 1;
  Self.cr0.mp := (msw and $01); msw := msw shr 1;
  Self.cr0.em := (msw and $01); msw := msw shr 1;
  Self.cr0.ts := (msw and $01);
  //BX_INFO(('LOADALL: pe:=%u, mp:=%u, em:=%u, ts:=%u',
  //  (unsigned) Self.cr0.pe, (unsigned) Self.cr0.mp,
  //  (unsigned) Self.cr0.em, (unsigned) Self.cr0.ts));

  if Boolean(Self.cr0.pe or Self.cr0.mp or Self.cr0.em or Self.cr0.ts) then
    BX_PANIC(('LOADALL set PE, MP, EM or TS bits in MSW!'));

  (* TR *)
  sysmemory.read_physical($816, 2, @tr);
  Self.tr.selector.value := tr;
  Self.tr.selector.rpl   := (tr  and $03);  tr := tr shr 2;
  Self.tr.selector.ti    := (tr  and $01);  tr := tr shr 1;
  Self.tr.selector.index := tr;
  sysmemory.read_physical($860, 2, @base_15_0);
  sysmemory.read_physical($862, 1, @base_23_16);
  sysmemory.read_physical($863, 1, @access);
  sysmemory.read_physical($864, 2, @limit);

	Self.tr.cache.p := (access  and $80) shr 7;
  Self.tr.cache.valid := Self.tr.cache.p;
  Self.tr.cache.dpl         := (access  and $60) shr 5;
  Self.tr.cache.segmentType     := (access  and $10) shr 4;
  // don't allow busy bit in tr.cache.type, so bit 2 is masked away too.
  Self.tr.cache.type_        := (access  and $0d);
  Self.tr.cache.tss286.base  := (base_23_16 shl 16) or base_15_0;
  Self.tr.cache.tss286.limit := limit;

  if Boolean( (Self.tr.selector.value  and $fffc) = 0 ) then begin
    Self.tr.cache.valid := 0;
    end;
  if Boolean( Self.tr.cache.valid = 0 ) then begin
    end;
  if Boolean( Self.tr.cache.tss286.limit < 43 ) then begin
    Self.tr.cache.valid := 0;
    end;
  if Boolean( Self.tr.cache.type_ <> 1 ) then begin
    Self.tr.cache.valid := 0;
    end;
  if Boolean( Self.tr.cache.segmentType ) then begin
    Self.tr.cache.valid := 0;
    end;
  if Boolean(Self.tr.cache.valid=0) then begin
    Self.tr.cache.tss286.base   := 0;
    Self.tr.cache.tss286.limit  := 0;
    Self.tr.cache.p            := 0;
    Self.tr.selector.value     := 0;
    Self.tr.selector.index     := 0;
    Self.tr.selector.ti        := 0;
    Self.tr.selector.rpl       := 0;
    end;


  (* FLAGS *)
  sysmemory.read_physical($818, 2, @flags);
  //write_flags(flags, 1, 1);

  (* IP *)
  sysmemory.read_physical($81a, 2, @iplocal);
  IP := iplocal;

  (* LDTR *)
  sysmemory.read_physical($81c, 2, @ldtr);
  Self.ldtr.selector.value := ldtr;
  Self.ldtr.selector.rpl   := (ldtr  and $03);  ldtr:= ldtr shr  2;
  Self.ldtr.selector.ti    := (ldtr  and $01);  ldtr:= ldtr shr  1;
  Self.ldtr.selector.index := ldtr;
  if Boolean( (Self.ldtr.selector.value  and $fffc) = 0 ) then begin
    Self.ldtr.cache.valid   := 0;
    Self.ldtr.cache.p       := 0;
    Self.ldtr.cache.segmentType := 0;
    Self.ldtr.cache.type_    := 0;
    Self.ldtr.cache.ldt.base := 0;
    Self.ldtr.cache.ldt.limit := 0;
    Self.ldtr.selector.value := 0;
    Self.ldtr.selector.index := 0;
    Self.ldtr.selector.ti    := 0;
    end
  else begin
    sysmemory.read_physical($854, 2, @base_15_0);
    sysmemory.read_physical($856, 1, @base_23_16);
    sysmemory.read_physical($857, 1, @access);
    sysmemory.read_physical($858, 2, @limit);
		Self.ldtr.cache.p  := access  shr  7;
    Self.ldtr.cache.valid      := Self.ldtr.cache.p;
    Self.ldtr.cache.dpl        := (access  shr  5)  and $03;
    Self.ldtr.cache.segmentType    := (access  shr  4)  and $01;
    Self.ldtr.cache.type_       := (access  and $0f);
    Self.ldtr.cache.ldt.base := (base_23_16  shl  16) or base_15_0;
    Self.ldtr.cache.ldt.limit := limit;

    if Boolean(access = 0) then begin
      BX_PANIC(('loadall: LDTR case access byte:=0.'));
      end;
    if Boolean( Self.ldtr.cache.valid=0 ) then begin
      BX_PANIC(('loadall: ldtr.valid:=0'));
      end;
    if Boolean(Self.ldtr.cache.segmentType) then begin (* not a system segment *)
      BX_INFO(Format('         AR byte := %02x',[access]));
      BX_PANIC(('loadall: LDTR descriptor cache loaded with non system segment'));
      end;
    if Boolean( Self.ldtr.cache.type_  <>  2 ) then begin
      BX_PANIC(Format('loadall: LDTR.type(%u)  <>  2', [(access  and $0f)]));
      end;
    end;

  (* DS *)
  sysmemory.read_physical($81e, 2, @ds_raw);
  Self.sregs[BX_SEG_REG_DS].selector.value := ds_raw;
  Self.sregs[BX_SEG_REG_DS].selector.rpl   := (ds_raw  and $03);  ds_raw := ds_raw shr 2;
  Self.sregs[BX_SEG_REG_DS].selector.ti    := (ds_raw  and $01);  ds_raw := ds_raw shr 1;
  Self.sregs[BX_SEG_REG_DS].selector.index := ds_raw;
  sysmemory.read_physical($848, 2, @base_15_0);
  sysmemory.read_physical($84a, 1, @base_23_16);
  sysmemory.read_physical($84b, 1, @access);
  sysmemory.read_physical($84c, 2, @limit);
  Self.sregs[BX_SEG_REG_DS].cache.segment.base := (base_23_16  shl  16) or base_15_0;
  Self.sregs[BX_SEG_REG_DS].cache.segment.limit := limit;
  Self.sregs[BX_SEG_REG_DS].cache.segment.a      := (access  and $01); access := access  shr 1;
  Self.sregs[BX_SEG_REG_DS].cache.segment.r_w        := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_DS].cache.segment.c_ed       := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_DS].cache.segment.executable := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_DS].cache.segmentType    := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_DS].cache.dpl        := (access  and $03); access := access shr 2;
	Self.sregs[BX_SEG_REG_DS].cache.p := (access  and $01);
  Self.sregs[BX_SEG_REG_DS].cache.valid      :=  Self.sregs[BX_SEG_REG_DS].cache.p;

  if Boolean( (Self.sregs[BX_SEG_REG_DS].selector.value  and $fffc) = 0 ) then begin
    Self.sregs[BX_SEG_REG_DS].cache.valid := 0;
    end;
  if Boolean((Self.sregs[BX_SEG_REG_DS].cache.valid=0) or (Self.sregs[BX_SEG_REG_DS].cache.segmentType=0)) then begin
    BX_PANIC(('loadall: DS invalid'));
    end;

  (* SS *)
  sysmemory.read_physical($820, 2, @ss_raw);
  Self.sregs[BX_SEG_REG_SS].selector.value := ss_raw;
  Self.sregs[BX_SEG_REG_SS].selector.rpl   := (ss_raw and $03); ss_raw := ss_raw shr 2;
  Self.sregs[BX_SEG_REG_SS].selector.ti    := (ss_raw and $01); ss_raw := ss_raw shr 1;
  Self.sregs[BX_SEG_REG_SS].selector.index := ss_raw;
  sysmemory.read_physical($842, 2, @base_15_0);
  sysmemory.read_physical($844, 1, @base_23_16);
  sysmemory.read_physical($845, 1, @access);
  sysmemory.read_physical($846, 2, @limit);
  Self.sregs[BX_SEG_REG_SS].cache.segment.base := (base_23_16  shl  16) or base_15_0;
  Self.sregs[BX_SEG_REG_SS].cache.segment.limit := limit;
  Self.sregs[BX_SEG_REG_SS].cache.segment.a          := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_SS].cache.segment.r_w        := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_SS].cache.segment.c_ed       := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_SS].cache.segment.executable := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_SS].cache.segmentType    := (access and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_SS].cache.dpl        := (access and $03); access := access shr 2;
  Self.sregs[BX_SEG_REG_SS].cache.p          := (access and $01);

  if Boolean( (Self.sregs[BX_SEG_REG_SS].selector.value  and $fffc) = 0 ) then begin
    Self.sregs[BX_SEG_REG_SS].cache.valid := 0;
    end;
  if Boolean((Self.sregs[BX_SEG_REG_SS].cache.valid=0)  or (Self.sregs[BX_SEG_REG_SS].cache.segmentType=0)) then begin
    BX_PANIC(('loadall: SS invalid'));
    end;


  (* CS *)
  sysmemory.read_physical($822, 2, @cs_raw);
  Self.sregs[BX_SEG_REG_CS].selector.value := cs_raw;
  Self.sregs[BX_SEG_REG_CS].selector.rpl   := (cs_raw  and $03); cs_raw := cs_raw shr 2;

  //BX_INFO(('LOADALL: setting cs_.selector.rpl to %u',
  //  (unsigned) Self.sregs[BX_SEG_REG_CS].selector.rpl));

  Self.sregs[BX_SEG_REG_CS].selector.ti    := (cs_raw  and $01); cs_raw := cs_raw shr 1;
  Self.sregs[BX_SEG_REG_CS].selector.index := cs_raw;
  sysmemory.read_physical($83c, 2, @base_15_0);
  sysmemory.read_physical($83e, 1, @base_23_16);
  sysmemory.read_physical($83f, 1, @access);
  sysmemory.read_physical($840, 2, @limit);
  Self.sregs[BX_SEG_REG_CS].cache.segment.base := (base_23_16 shl 16) or base_15_0;
  Self.sregs[BX_SEG_REG_CS].cache.segment.limit := limit;
  Self.sregs[BX_SEG_REG_CS].cache.segment.a          := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_CS].cache.segment.r_w        := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_CS].cache.segment.c_ed       := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_CS].cache.segment.executable := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_CS].cache.segmentType    := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_CS].cache.dpl        := (access  and $03); access := access shr 2;
  Self.sregs[BX_SEG_REG_CS].cache.p          := (access  and $01);

  if Boolean( (Self.sregs[BX_SEG_REG_CS].selector.value  and $fffc) = 0 ) then begin
    Self.sregs[BX_SEG_REG_CS].cache.valid := 0;
    end;
  if Boolean((Self.sregs[BX_SEG_REG_CS].cache.valid=0) or (Self.sregs[BX_SEG_REG_CS].cache.segmentType=0)) then begin
    BX_PANIC(('loadall: CS invalid'));
    end;

  (* ES *)
  sysmemory.read_physical($824, 2, @es_raw);
  Self.sregs[BX_SEG_REG_ES].selector.value := es_raw;
  Self.sregs[BX_SEG_REG_ES].selector.rpl   := (es_raw  and $03); es_raw := es_raw shr 2;
  Self.sregs[BX_SEG_REG_ES].selector.ti    := (es_raw  and $01); es_raw := es_raw  shr 1;
  Self.sregs[BX_SEG_REG_ES].selector.index := es_raw;
  sysmemory.read_physical($836, 2, @base_15_0);
  sysmemory.read_physical($838, 1, @base_23_16);
  sysmemory.read_physical($839, 1, @access);
  sysmemory.read_physical($83a, 2, @limit);
  Self.sregs[BX_SEG_REG_ES].cache.segment.base := (base_23_16  shl  16) or base_15_0;
  Self.sregs[BX_SEG_REG_ES].cache.segment.limit := limit;
  Self.sregs[BX_SEG_REG_ES].cache.segment.a          := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_ES].cache.segment.r_w        := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_ES].cache.segment.c_ed       := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_ES].cache.segment.executable := (access  and $01); access := access  shr 1;
  Self.sregs[BX_SEG_REG_ES].cache.segmentType    := (access  and $01); access := access shr 1;
  Self.sregs[BX_SEG_REG_ES].cache.dpl        := (access  and $03); access := access shr 2;
  Self.sregs[BX_SEG_REG_ES].cache.p          := (access  and $01);

{$if 0 =1}
    BX_INFO(('cs_.dpl := %02x', (unsigned) Self.sregs[BX_SEG_REG_CS].cache.dpl));
    BX_INFO(('ss.dpl := %02x', (unsigned) Self.sregs[BX_SEG_REG_SS].cache.dpl));
    BX_INFO(('Self.sregs[BX_SEG_REG_DS].dpl := %02x', (unsigned) Self.ds.cache.dpl));
    BX_INFO(('Self.sregs[BX_SEG_REG_ES].dpl := %02x', (unsigned) Self.es.cache.dpl));
    BX_INFO(('LOADALL: setting cs_.selector.rpl to %u',
      (unsigned) Self.sregs[BX_SEG_REG_CS].selector.rpl));
    BX_INFO(('LOADALL: setting ss.selector.rpl to %u',
      (unsigned) Self.sregs[BX_SEG_REG_SS].selector.rpl));
    BX_INFO(('LOADALL: setting ds.selector.rpl to %u',
      (unsigned) Self.sregs[BX_SEG_REG_DS].selector.rpl));
    BX_INFO(('LOADALL: setting es.selector.rpl to %u',
      (unsigned) Self.sregs[BX_SEG_REG_ES].selector.rpl));
{$ifend}

  if Boolean( (Self.sregs[BX_SEG_REG_ES].selector.value  and $fffc) = 0 ) then begin
    Self.sregs[BX_SEG_REG_ES].cache.valid := 0;
    end;
  if Boolean((Self.sregs[BX_SEG_REG_ES].cache.valid=0)  or (Self.sregs[BX_SEG_REG_ES].cache.segmentType=0)) then begin
    BX_PANIC(('loadall: ES invalid'));
    end;

  (* DI *)
  sysmemory.read_physical($826, 2, @di_);
  DI := di_;

  (* SI *)
  sysmemory.read_physical($828, 2, @si_);
  SI := si_;

  (* BP *)
  sysmemory.read_physical($82a, 2, @bp_);
  BP := bp_;

  (* SP *)
  sysmemory.read_physical($82c, 2, @sp_);
  SP := sp_;

  (* BX *)
  sysmemory.read_physical($82e, 2, @bx_);
  BX := bx_;

  (* DX *)
  sysmemory.read_physical($830, 2, @dx_);
  DX := dx_;

  (* CX *)
  sysmemory.read_physical($832, 2, @cx_);
  CX := cx_;

  (* AX *)
  sysmemory.read_physical($834, 2, @ax_);
  AX := ax_;

  (* GDTR *)
  sysmemory.read_physical($84e, 2, @base_15_0);
  sysmemory.read_physical($850, 1, @base_23_16);
  sysmemory.read_physical($851, 1, @access);
  sysmemory.read_physical($852, 2, @limit);
  Self.gdtr.base := (base_23_16 shl 16) or base_15_0;
  Self.gdtr.limit := limit;

{$if 0=1}
  if Boolean(access)
      BX_INFO(('LOADALL: GDTR access bits not 0 (%02x).',
        (unsigned) access));
{$ifend}

  (* IDTR *)
  sysmemory.read_physical($85a, 2, @base_15_0);
  sysmemory.read_physical($85c, 1, @base_23_16);
  sysmemory.read_physical($85d, 1, @access);
  sysmemory.read_physical($85e, 2, @limit);
  Self.idtr.base := (base_23_16 shl 16) or base_15_0;
  Self.idtr.limit := limit;
{$ifend}
end;


procedure BX_CPU_C.CPUID(I:PBxInstruction_tag);
{$if BX_CPU_LEVEL >= 4}
  var
    type_, family, mod_el, stepping, features:Word;
{$ifend}
begin

  invalidate_prefetch_q();

{$if BX_CPU_LEVEL >= 4}
  case EAX of
    0:
      begin
        // EAX: highest input value understood by CPUID
        // EBX: vendor ID string
        // EDX: vendor ID string
        // ECX: vendor ID string
        EAX := 1; // 486 or pentium
        EBX := $756e6547; // 'Genu'
        EDX := $49656e69; // 'ineI'
        ECX := $6c65746e; // 'ntel'
      end;

    1:
      begin
        // EAX[3:0]   Stepping ID
        // EAX[7:4]   mod_el: starts at 1
        // EAX[11:8]  Family: 4:=486, 5:=Pentium, 6:=PPro
        // EAX[13:12] Type: 0:=OEM,1:=overdrive,2:=dual cpu,3:=reserved
        // EAX[31:14] Reserved
        // EBX:       Reserved (0)
        // ECX:       Reserved (0)
        // EDX:       Feature Flags
        //   [0:0]   FPU on chip
        //   [1:1]   VME: Virtual-8086 mod_e enhancements
        //   [2:2]   DE: Debug Extensions (I/O breakpoints)
        //   [3:3]   PSE: Page Size Extensions
        //   [4:4]   TSC: Time Stamp Counter
        //   [5:5]   MSR: RDMSR and WRMSR support
        //   [6:6]   PAE: Physical Address Extensions
        //   [7:7]   MCE: Machine Check Exception
        //   [8:8]   CXS: CMPXCHG8B instruction
        //   [9:9]   APIC: APIC on Chip
        //   [11:10] Reserved
        //   [12:12] MTRR: Memory Type Range Reg
        //   [13:13] PGE/PTE Global Bit
        //   [14:14] MCA: Machine Check Architecture
        //   [15:15] CMOV: Cond Mov/Cmp Instructions
        //   [22:16] Reserved
        //   [23:23] MMX Technology
        //   [31:24] Reserved

        features := 0; // start with none
        type_ := 0; // OEM

{$if BX_CPU_LEVEL = 4}
      family := 4;
{$if BX_SUPPORT_FPU = 1} //XXXX
      // 486dx
      mod_el := 1;
      stepping := 3;
      features := features or $01;
{$else}
      // 486sx
      mod_el := 2;
      stepping := 3;
{$ifend}

{$elseif BX_CPU_LEVEL = 5}
      family := 5;
      mod_el := 1; // Pentium (60,66)
      stepping := 3; // ???
      features := features or (1 shl 4);   // implement TSC
{$if BX_SUPPORT_FPU = $01}
      features := features or $01;
{$ifend}

{$elseif BX_CPU_LEVEL = 6}
      family := 6;
      mod_el := 1; // Pentium Pro
      stepping := 3; // ???
      features := features or (1 shl 4);   // implement TSC
{$if BX_SUPPORT_APIC = $01}
      features := features or (1 shl 9);   // APIC on chip
{$ifend}
{$if BX_SUPPORT_FPU = $01}
      features |:= $01;
{$ifend}
{$else}
      BX_PANIC(('CPUID: not implemented for > 6'));
{$ifend}

      EAX := (family  shl 8)or(mod_el shl 4) or stepping;
      ECX := 0;
      EBX := ECX; // reserved
      EDX := features;
      end;

    else
      begin
        EAX := 0;
        EBX := 0;
        ECX := 0;
        EDX := 0; // Reserved, undefined
      end;
    end;
{$else}
  BX_PANIC(('CPUID: not available on < late 486'));
{$ifend}
end;

procedure BX_CPU_C.SetCR0(val_32:Bit32u);
var
  prev_pe, prev_pg:Bool;
begin
  // from either MOV_CdRd() or debug functions
  // protection checks made already or forcing from debug

  prev_pe := Self.cr0.pe;
  prev_pg := Self.cr0.pg;

  Self.cr0.pe := val_32 and $01;
  Self.cr0.mp := (val_32  shr  1) and $01;
  Self.cr0.em := (val_32  shr  2) and $01;
  Self.cr0.ts := (val_32  shr  3) and $01;
  // cr0.et is hardwired to 1
{$if BX_CPU_LEVEL >= 4 }
  Self.cr0.ne := (val_32  shr  5)   and $01;
  Self.cr0.wp := (val_32  shr  16)  and $01;
  Self.cr0.am := (val_32  shr  18)  and $01;
  Self.cr0.nw := (val_32  shr  29)  and $01;
  Self.cr0.cd := (val_32  shr  30)  and $01;
{$ifend}
  Self.cr0.pg := (val_32  shr  31)  and $01;

  // handle reserved bits behaviour
{$if BX_CPU_LEVEL = 3}
  Self.cr0.val32 := val_32 or $7ffffff0;
{$elseif BX_CPU_LEVEL = 4}
  Self.cr0.val32 := (val_32 or $00000010)  and $e005003f;
{$elseif BX_CPU_LEVEL = 5}
  Self.cr0.val32 := val_32 or $00000010;
{$elseif BX_CPU_LEVEL = 6}
  Self.cr0.val32 := (val_32 or $00000010)  and $e005003f;
{$else}
 {$error 'MOV_CdRd: implement reserved bits behaviour for this CPU_LEVEL'}
{$ifend}

  //if Boolean(Self.cr0.ts)
  //  BX_INFO(('MOV_CdRd:CR0.TS set $%x', (unsigned) val_32));

  if Boolean((prev_pe=0) and Boolean(Self.cr0.pe)) then begin
    enter_protected_mode();
    end
  else if Boolean((prev_pe=1) and (Self.cr0.pe=0)) then begin
    enter_real_mode();
    end;

  if Boolean((prev_pg=0) and Boolean(Self.cr0.pg)) then
    enable_paging()
  else if Boolean((prev_pg=1) and Boolean(Self.cr0.pg=0)) then
    disable_paging();
end;

procedure BX_CPU_C.RSM(I:PBxInstruction_tag);
begin
{$if BX_CPU_LEVEL >= 4}
  invalidate_prefetch_q();

  BX_PANIC(('RSM: System Management mod_e not implemented yet'));
{$else}
  UndefinedOpcode(i);
{$ifend}
end;

procedure BX_CPU_C.RDTSC(I:PBxInstruction_tag);
var
{$if BX_CPU_LEVEL >= 5}
  tsd:Bool;
  cpl:Bool;
{$ifend}
  ticks:Bit64u;
begin
{$if BX_CPU_LEVEL >= 5}
  if Boolean(Self.cr4 and 4) then tsd:=1 else tsd:=0;
  cpl := CPL;
  if Boolean((tsd=0) or ((tsd=1) and (cpl=0))) then begin
    // return ticks
    ticks := bx_pc_system.time_ticks (); 
    EAX := Bit32u(ticks and $ffffffff);
    EDX := Bit32u((ticks shr 32)  and $ffffffff);
    //BX_INFO(('RDTSC: returning EDX:EAX := %08x:%08x', EDX, EAX));
  end else begin
    // not allowed to use RDTSC!
    exception2([BX_GP_EXCEPTION, 0, 0]);
  end;
{$else}
  UndefinedOpcode(i);
{$ifend}
end;

procedure BX_CPU_C.RDMSR(I:PBxInstruction_tag);
label do_exception;
begin
{$if BX_CPU_LEVEL >= 5}
	invalidate_prefetch_q();

	if Boolean(v8086_mode()) then begin
		BX_INFO(('RDMSR: Invalid whilst in virtual 8086 mod_e'));
		goto do_exception;
	end;

	if Boolean(CPL <>  0) then begin
		BX_INFO(('RDMSR: CPL <>  0'));
		goto do_exception;
	end;

	(* We have the requested MSR register in ECX *)
	case ECX of
{$if BX_CPU_LEVEL = 5}
		(* The following registers are defined for Pentium only *)
		BX_MSR_P5_MC_ADDR,
		BX_MSR_MC_TYPE:
    begin
      (* TODO *)
    end;

		BX_MSR_TSC:
      begin
  			RDTSC(i);
	  	end;

		BX_MSR_CESR:
      begin
  			(* TODO *)
	  	end;
{$else}
		(* These are noops on i686... *)
		BX_MSR_P5_MC_ADDR,
		BX_MSR_MC_TYPE:
      begin
  			(* do nothing *)
			end;

		BX_MSR_TSC:
      begin
		  	RDTSC(i);
			end;

		(* ... And these cause an exception on i686 *)
		BX_MSR_CESR,
		BX_MSR_CTR0,
		BX_MSR_CTR1:
			goto do_exception;
{$ifend}	(* BX_CPU_LEVEL = 5 *)

		(* MSR_APICBASE
		   0:7		Reserved
		   8		This is set if its the BSP
		   9:10		Reserved
		   11		APIC Global Enable bit (1:=enabled 0:=disabled)
		   12:35	APIC Base Address
		   36:63	Reserved
		*)
		BX_MSR_APICBASE:
      begin
        (* we return low 32 bits in EAX, and high in EDX *)
        EAX := Self.msr.apicbase  and $ff;
        EDX := Self.msr.apicbase  shr  32;
        BX_INFO(Format('RDMSR: Read %08x:%08x from MSR_APICBASE',[EDX, EAX]));
			end;

		else
      begin
  			BX_INFO(('RDMSR: Unknown register!'));
	  		goto do_exception;
      end;

	end;
{$ifend}	(* BX_CPU_LEVEL >= 5 *)

do_exception:
	exception2([BX_GP_EXCEPTION, 0, 0]);
end;

procedure BX_CPU_C.WRMSR(I:PBxInstruction_tag);
label do_exception;
begin
{$if BX_CPU_LEVEL >= 5}
	invalidate_prefetch_q();

	if Boolean(v8086_mode()) then begin
		BX_INFO(('WRMSR: Invalid whilst in virtual 8086 mod_e'));
		goto do_exception;
	end;

	if Boolean(CPL <>  0) then begin
		BX_INFO(('WDMSR: CPL <>  0'));
		goto do_exception;
	end;

	(* ECX has the MSR to write to *)
	case ECX of
{$if BX_CPU_LEVEL = 5}
		(* The following registers are defined for Pentium only *)
		BX_MSR_P5_MC_ADDR,
		BX_MSR_MC_TYPE,
		BX_MSR_TSC,
		BX_MSR_CESR:
      begin
  			(* TODO *)
			end;
{$else}
		(* These are noops on i686... *)
		BX_MSR_P5_MC_ADDR,
		BX_MSR_MC_TYPE,
		BX_MSR_TSC:
      begin
  			(* do nothing *)
			end;

		(* ... And these cause an exception on i686 *)
		BX_MSR_CESR,
		BX_MSR_CTR0,
		BX_MSR_CTR1:
      begin
  			goto do_exception;
      end;  
{$ifend}	(* BX_CPU_LEVEL = 5 *)

		(* MSR_APICBASE
		   0:7		Reserved
		   8		This is set if its the BSP
		   9:10		Reserved
		   11		APIC Global Enable bit (1:=enabled 0:=disabled)
		   12:35	APIC Base Address
		   36:63	Reserved
		*)

		BX_MSR_APICBASE:
      begin
  			Self.msr.apicbase := Bit64u(EDX  shl  32) + EAX;
	  		BX_INFO(Format('WRMSR: wrote %08x:%08x to MSR_APICBASE', [EDX, EAX]));
			end;
			
		else
			BX_INFO(('WRMSR: Unknown register!'));
			goto do_exception;

	end;
{$ifend}	(* BX_CPU_LEVEL >= 5 *)

do_exception:
	exception2([BX_GP_EXCEPTION, 0, 0]);

end;

{$if BX_X86_DEBUGGER=1}
  Bit32u
BX_CPU_C.hwdebug_compare(Bit32u laddr_0, unsigned size,
                          unsigned opa, unsigned opb)
begin
  // Support x86 hardware debug facilities (DR0..DR7)
  Bit32u dr7 := Self.dr7;

  Boolean ibpoint_found := 0;
  Bit32u  laddr_n := laddr_0 + (size - 1);
  Bit32u  dr0, dr1, dr2, dr3;
  Bit32u  dr0_n, dr1_n, dr2_n, dr3_n;
  Bit32u  len0, len1, len2, len3;
  static  unsigned alignment_mask[4] :=
    //    00b:=1      01b:=2     10b:=undef     11b:=4
    begin $ffffffff, $fffffffe, $ffffffff, $fffffffc end;;
  Bit32u dr0_op, dr1_op, dr2_op, dr3_op;

  len0 := (dr7 shr 18)  and 3;
  len1 := (dr7 shr 22)  and 3;
  len2 := (dr7 shr 26)  and 3;
  len3 := (dr7 shr 30)  and 3;

  dr0 := Self.dr0  and alignment_mask[len0];
  dr1 := Self.dr1  and alignment_mask[len1];
  dr2 := Self.dr2  and alignment_mask[len2];
  dr3 := Self.dr3  and alignment_mask[len3];

  dr0_n := dr0 + len0;
  dr1_n := dr1 + len1;
  dr2_n := dr2 + len2;
  dr3_n := dr3 + len3;

  dr0_op := (dr7 shr 16)  and 3;
  dr1_op := (dr7 shr 20)  and 3;
  dr2_op := (dr7 shr 24)  and 3;
  dr3_op := (dr7 shr 28)  and 3;

  // See if this instruction address matches any breakpoints
  if Boolean( (dr7  and $00000003) ) then begin
    if Boolean( (dr0_op=opa or dr0_op=opb) @@
         (laddr_0 <= dr0_n) @@
         (laddr_n >= dr0) )
      ibpoint_found := 1;
    end;
  if Boolean( (dr7  and $0000000c) ) then begin
    if Boolean( (dr1_op=opa or dr1_op=opb) @@
         (laddr_0 <= dr1_n) @@
         (laddr_n >= dr1) )
      ibpoint_found := 1;
    end;
  if Boolean( (dr7  and $00000030) ) then begin
    if Boolean( (dr2_op=opa or dr2_op=opb) @@
         (laddr_0 <= dr2_n) @@
         (laddr_n >= dr2) )
      ibpoint_found := 1;
    end;
  if Boolean( (dr7  and $000000c0) ) then begin
    if Boolean( (dr3_op=opa or dr3_op=opb) @@
         (laddr_0 <= dr3_n) @@
         (laddr_n >= dr3) )
      ibpoint_found := 1;
    end;

  // If *any* enabled breakpoints matched, then we need to
  // set status bits for *all* breakpoints, even disabled ones,
  // as long as they meet the other breakpoint criteria.
  // This code is similar to that above, only without the
  // breakpoint enabled check.  Seems weird to duplicate effort,
  // but its more efficient to do it this way.
  if Boolean(ibpoint_found) then begin
    // dr6_mask is the return value.  These bits represent the bits to
    // be OR'd into DR6 as a result of the debug event.
    Bit32u  dr6_mask:=0;
    if Boolean( (dr0_op=opa or dr0_op=opb) @@
         (laddr_0 <= dr0_n) @@
         (laddr_n >= dr0) )
      dr6_mask |:= $01;
    if Boolean( (dr1_op=opa or dr1_op=opb) @@
         (laddr_0 <= dr1_n) @@
         (laddr_n >= dr1) )
      dr6_mask |:= $02;
    if Boolean( (dr2_op=opa or dr2_op=opb) @@
         (laddr_0 <= dr2_n) @@
         (laddr_n >= dr2) )
      dr6_mask |:= $04;
    if Boolean( (dr3_op=opa or dr3_op=opb) @@
         (laddr_0 <= dr3_n) @@
         (laddr_n >= dr3) )
      dr6_mask |:= $08;
    return(dr6_mask);
    end;
  return(0);
end;
{$ifend}

