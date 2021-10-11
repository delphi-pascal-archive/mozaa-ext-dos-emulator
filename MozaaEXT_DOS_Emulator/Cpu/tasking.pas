{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)


{$if BX_SUPPORT_TASKING = 1}

{$if BX_CPU_LEVEL >= 2}

// Notes:
// ===
// Step 2: TSS descriptor is not busy TS (for IRET); GP (for JMP, CALL, INT)
//   returns error code (Task's backlink TSS)???

// *   TSS selector must map to GDT
// *   TSS is stored in linear address space
// * what to do with I/O Map Base
// * what to do with T flag
// * where to set CR3 and flush paging cache
// * what happens when fault occurs, with some seg regs having valid bit cleared?
// * should check validity of current TR(TSS) before writing into it
//

  // ===========
  // 286 Task State Segment
  // ===========
  // dynamic item                     orhex  dec  offset
  // 0       task LDT selector        or2a   42
  // 1       DS selector              or28   40
  // 1       SS selector              or26   38
  // 1       CS selector              or24   36
  // 1       ES selector              or22   34
  // 1       DI                       or20   32
  // 1       SI                       or1e   30
  // 1       BP                       or1c   28
  // 1       SP                       or1a   26
  // 1       BX                       or18   24
  // 1       DX                       or16   22
  // 1       CX                       or14   20
  // 1       AX                       or12   18
  // 1       flag word                or10   16
  // 1       IP (entry point)         or0e   14
  // 0       SS for CPL 2             or0c   12
  // 0       SP for CPL 2             or0a   10
  // 0       SS for CPL 1             or08   08
  // 0       SP for CPL 1             or06   06
  // 0       SS for CPL 0             or04   04
  // 0       SP for CPL 0             or02   02
  //         back link selector to TSSor00   00


  // ===========
  // 386 Task State Segment
  // ===========
  // |31            16|15                    0|
  // |I/O Map Base    |000000000000000000000|T| 64  static
  // |0000000000000000| LDT                  or60  static
  // |0000000000000000| GS selector          or5c  dynamic
  // |0000000000000000| FS selector          or58  dynamic
  // |0000000000000000| DS selector          or54  dynamic
  // |0000000000000000| SS selector          or50  dynamic
  // |0000000000000000| CS selector          or4c  dynamic
  // |0000000000000000| ES selector          or48  dynamic
  //or               EDI                    or44  dynamic
  //or               ESI                    or40  dynamic
  //or               EBP                    or3c  dynamic
  //or               ESP                    or38  dynamic
  //or               EBX                    or34  dynamic
  //or               EDX                    or30  dynamic
  //or               ECX                    or2c  dynamic
  //or               EAX                    or28  dynamic
  //or               EFLAGS                 or24  dynamic
  //or               EIP (entry point)      or20  dynamic
  //or          CR3 (PDPR)                  or1c  static
  // |000000000000000orSS for CPL 2         or18  static
  //or          ESP for CPL 2               or14  static
  // |000000000000000orSS for CPL 1         or10  static
  //or          ESP for CPL 1               or0c  static
  // |000000000000000orSS for CPL 0         or08  static
  //or          ESP for CPL 0               or04  static
  // |000000000000000orback link to prev TSSor00  dynamic (updated only when return expected)


  // =========================
  // Effect of task switch on Busy, NT, and Link Fields
  // =========================

  // Field         jump        call/interrupt     iret
  // ------------------------------------------------------
  // new busy bit  Set         Set                No change
  // old busy bit  Cleared     No change          Cleared
  // new NT flag   No change   Set                No change
  // old NT flag   No change   No change          Cleared
  // new link      No change   old TSS selector   No change
  // old link      No change   No change          No change
  // CR0.TS        Set         Set                Set

  // Note: I checked 386, 486, and Pentium, and they all exhibited
  //       exactly the same behaviour as above.  There seems to
  //       be some misprints in the Intel docs.


procedure BX_CPU_C.task_switch(tss_selector:pbx_selector_t; tss_descriptor:pbx_descriptor_t;source:unsigned;
                     dword1:Bit32u; dword2:Bit32u);
var
  obase32:Bit32u; // base address of old TSS
  nbase32:Bit32u; // base address of new TSS
  temp32, newCR3:Bit32u;
  raw_cs_selector, raw_ss_selector, raw_ds_selector, raw_es_selector,
         raw_fs_selector, raw_gs_selector, raw_ldt_selector:Bit16u;
  temp16, trap_word:Bit16u;
  cs_selector, ss_selector, ds_selector, es_selector, gs_selector, ldt_selector,fs_selector:bx_selector_t;
  cs_descriptor, ss_descriptor, ds_descriptor, es_descriptor, gs_descriptor, ldt_descriptor,fs_descriptor:bx_descriptor_t;
  old_TSS_max, new_TSS_max, old_TSS_limit, new_TSS_limit:Bit32u;
  newEAX, newECX, newEDX, newEBX:Bit32u;
  newESP, newEBP, newESI, newEDI:Bit32u;
  newEFLAGS, oldEFLAGS, newEIP:Bit32u;
  exception_no:unsigned;
  error_code:Bit16u;
  good:Bool;

  label post_exception;
begin

//BX_DEBUG(( 'TASKING: ENTER' ));

  invalidate_prefetch_q();

  // Discard any traps and inhibits for new context; traps will
  // resume upon return.
  Self.debug_trap := 0;
  Self.inhibit_mask := 0;




  // The following checks are made before calling task_switch(), for
  // JMP  and CALL only.  These checks are NOT made for exceptions, interrupts,  and IRET
  //
  //   1) TSS DPL must be >= CPL
  //   2) TSS DPL must be >= TSS selector RPL
  //   3) TSS descriptor is not busy.  TS(for IRET); GP(for JMP, CALL, INT)

  // Privilege and busy checks done in CALL, JUMP, INT, IRET

  exception_no := 256; // no exception
  error_code   := 0;
  oldEFLAGS := read_eflags(); 

  // Gather info about old TSS
  if (Self.tr.cache.type_ <= 3) then begin
    // sanity check type: cannot have busy bit
    assert((Self.tr.cache.type_ and 2) = 0);
    obase32 := Self.tr.cache.tss286.base;
    old_TSS_max   := 43;
    old_TSS_limit := Self.tr.cache.tss286.limit;
    end
  else begin
    obase32 := Self.tr.cache.tss386.base;
    old_TSS_max   := 103;
    old_TSS_limit := Self.tr.cache.tss386.limit_scaled;
    end;

  // Gather info about new TSS
  if (tss_descriptor^.type_ <= 3) then begin // begin1,3end;
    nbase32 := tss_descriptor^.tss286.base; // new TSS.base
    new_TSS_max   := 43;
    new_TSS_limit := tss_descriptor^.tss286.limit;
    end
  else begin // tss_descriptor^.type := begin9,11end;
    nbase32 := tss_descriptor^.tss386.base; // new TSS.base
    new_TSS_max   := 103;
    new_TSS_limit := tss_descriptor^.tss386.limit_scaled;
    end;

  // Task State Seg must be present, else #NP(TSS selector)
  if (tss_descriptor^.p=0) then begin
    BX_INFO(('task_switch: TSS.p = 0'));
    exception2([BX_NP_EXCEPTION, tss_selector^.value  and $fffc, 0]);
    end;

  // TSS must have valid limit, else #TS(TSS selector)
  if ((tss_selector^.ti<>0) or (tss_descriptor^.valid=0) or (new_TSS_limit < new_TSS_max)) then begin
    BX_PANIC(('task_switch(): TR not valid'));
    exception2([BX_TS_EXCEPTION, tss_selector^.value  and $fffc, 0]);
    end;
{$if BX_SUPPORT_PAGING=1}
  // Check that old TSS, new TSS, and all segment descriptors
  // used in the task switch are paged in.
  if (Self.cr0.pg)<>0 then begin
    //BX_RW, BX_READ, BX_WRITE
    // Old TSS
    dtranslate_linear(obase32, 0, (*rw*) BX_WRITE);
    dtranslate_linear(obase32+old_TSS_max, 0, (*rw*) BX_WRITE);

    // New TSS
    dtranslate_linear(nbase32, 0, (*rw*) 0);
    dtranslate_linear(nbase32+new_TSS_max, 0, (*rw*) 0);

    // ??? fix RW above
    // ??? touch old/new TSS descriptors here when necessary.
    end;
{$ifend} // BX_SUPPORT_PAGING

  // Need to fetch all new registers and temporarily store them.

  if (tss_descriptor^.type_ <= 3) then begin
    access_linear(nbase32 + 14, 2, 0, BX_READ, @temp16);
      newEIP := temp16; // zero out upper word
    access_linear(nbase32 + 16, 2, 0, BX_READ, @temp16);
      newEFLAGS := temp16;

    // incoming TSS is 16bit:
    //   - upper word of general registers is set to $FFFF
    //   - upper word of eflags is zero'd
    //   - FS, GS are zero'd
    //   - upper word of eIP is zero'd
    access_linear(nbase32 + 18, 2, 0, BX_READ, @temp16);
      newEAX := $ffff0000 or temp16;
    access_linear(nbase32 + 20, 2, 0, BX_READ, @temp16);
      newECX := $ffff0000 or temp16;
    access_linear(nbase32 + 22, 2, 0, BX_READ, @temp16);
      newEDX := $ffff0000 or temp16;
    access_linear(nbase32 + 24, 2, 0, BX_READ, @temp16);
      newEBX := $ffff0000 or temp16;
    access_linear(nbase32 + 26, 2, 0, BX_READ, @temp16);
      newESP := $ffff0000 or temp16;
    access_linear(nbase32 + 28, 2, 0, BX_READ, @temp16);
      newEBP := $ffff0000 or temp16;
    access_linear(nbase32 + 30, 2, 0, BX_READ, @temp16);
      newESI := $ffff0000 or temp16;
    access_linear(nbase32 + 32, 2, 0, BX_READ, @temp16);
      newEDI := $ffff0000 or temp16;

    access_linear(nbase32 + 34, 2, 0, BX_READ, @raw_es_selector);
    access_linear(nbase32 + 36, 2, 0, BX_READ, @raw_cs_selector);
    access_linear(nbase32 + 38, 2, 0, BX_READ, @raw_ss_selector);
    access_linear(nbase32 + 40, 2, 0, BX_READ, @raw_ds_selector);
    access_linear(nbase32 + 42, 2, 0, BX_READ, @raw_ldt_selector);

    raw_fs_selector := 0; // use a NULL selector
    raw_gs_selector := 0; // use a NULL selector
    // No CR3 change for 286 task switch
    newCR3 := 0;   // keep compiler happy (not used)
    trap_word := 0; // keep compiler happy (not used)
    end
  else begin
    access_linear(nbase32 + $1c, 4, 0, BX_READ, @newCR3);
    access_linear(nbase32 + $20, 4, 0, BX_READ, @newEIP);
    access_linear(nbase32 + $24, 4, 0, BX_READ, @newEFLAGS);
    access_linear(nbase32 + $28, 4, 0, BX_READ, @newEAX);
    access_linear(nbase32 + $2c, 4, 0, BX_READ, @newECX);
    access_linear(nbase32 + $30, 4, 0, BX_READ, @newEDX);
    access_linear(nbase32 + $34, 4, 0, BX_READ, @newEBX);
    access_linear(nbase32 + $38, 4, 0, BX_READ, @newESP);
    access_linear(nbase32 + $3c, 4, 0, BX_READ, @newEBP);
    access_linear(nbase32 + $40, 4, 0, BX_READ, @newESI);
    access_linear(nbase32 + $44, 4, 0, BX_READ, @newEDI);
    access_linear(nbase32 + $48, 2, 0, BX_READ, @raw_es_selector);
    access_linear(nbase32 + $4c, 2, 0, BX_READ, @raw_cs_selector);
    access_linear(nbase32 + $50, 2, 0, BX_READ, @raw_ss_selector);
    access_linear(nbase32 + $54, 2, 0, BX_READ, @raw_ds_selector);
    access_linear(nbase32 + $58, 2, 0, BX_READ, @raw_fs_selector);
    access_linear(nbase32 + $5c, 2, 0, BX_READ, @raw_gs_selector);
    access_linear(nbase32 + $60, 2, 0, BX_READ, @raw_ldt_selector);
    access_linear(nbase32 + $64, 2, 0, BX_READ, @trap_word);
    // I/O Map Base Address ???
    end;

{$if 0=1}
if (ss_descriptor.u.segment.d_b and (tss_descriptor^.type<9)) then begin
  BX_DEBUG(( '++++++++++++++++++++++++++' ));
  Self.sregs[BX_SEG_REG_SS].cache.valid := 0;
  exception(BX_SS_EXCEPTION, raw_ss_selector  and $fffc, 0);
  end;
{$ifend}


  //
  // Step 6: If JMP or IRET, clear busy bit in old task TSS descriptor,
  //         otherwise leave set.
  //

  // effect on Busy bit of old task
  if ( (source=BX_TASK_FROM_JUMP) or (source=BX_TASK_FROM_IRET) ) then begin
    // Bit is cleared
    access_linear(Self.gdtr.base +
                  Self.tr.selector.index*8 + 4,
                  4, 0, BX_READ, @temp32);
    //temp32 @:= ~$00000200;  !!! ~
    temp32 := temp32 and not $00000200;
    access_linear(Self.gdtr.base +
                  Self.tr.selector.index*8 + 4,
                  4, 0, BX_WRITE, @temp32);
    end;


  //
  // Step 7: If IRET, clear NT flag in temp image of EFLAGS, otherwise
  //         leave alone.
  //

  if (source = BX_TASK_FROM_IRET) then begin
    // NT flags in old task is cleared with an IRET
    //oldEFLAGS := oldEFLAGS @:= ~$00004000; !!! ~
      oldEFLAGS := oldEFLAGS and not $00004000;
    end;


  //
  // Step 8: Save dynamic state of old task.
  //

  if (Self.tr.cache.type_ <= 3) then begin
    // sanity check: tr.cache.type cannot have busy bit
    assert ((Self.tr.cache.type_  and 2) = 0);
    temp16 := IP; access_linear(obase32 + 14, 2, 0, BX_WRITE, @temp16);
    temp16 := oldEFLAGS; access_linear(obase32 + 16, 2, 0, BX_WRITE, @temp16);
    temp16 := AX; access_linear(obase32 + 18, 2, 0, BX_WRITE, @temp16);
    temp16 := CX; access_linear(obase32 + 20, 2, 0, BX_WRITE, @temp16);
    temp16 := DX; access_linear(obase32 + 22, 2, 0, BX_WRITE, @temp16);
    temp16 := BX; access_linear(obase32 + 24, 2, 0, BX_WRITE, @temp16);
    temp16 := SP; access_linear(obase32 + 26, 2, 0, BX_WRITE, @temp16);
    temp16 := BP; access_linear(obase32 + 28, 2, 0, BX_WRITE, @temp16);
    temp16 := SI; access_linear(obase32 + 30, 2, 0, BX_WRITE, @temp16);
    temp16 := DI; access_linear(obase32 + 32, 2, 0, BX_WRITE, @temp16);
    temp16 := Self.sregs[BX_SEG_REG_ES].selector.value;
                 access_linear(obase32 + 34, 2, 0, BX_WRITE, @temp16);
    temp16 := Self.sregs[BX_SEG_REG_CS].selector.value;
                 access_linear(obase32 + 36, 2, 0, BX_WRITE, @temp16);
    temp16 := Self.sregs[BX_SEG_REG_SS].selector.value;
                 access_linear(obase32 + 38, 2, 0, BX_WRITE, @temp16);
    temp16 := Self.sregs[BX_SEG_REG_DS].selector.value;
                 access_linear(obase32 + 40, 2, 0, BX_WRITE, @temp16);
    end
  else begin
    temp32 := EIP; access_linear(obase32 + $20, 4, 0, BX_WRITE, @temp32);
    temp32 := oldEFLAGS; access_linear(obase32 + $24, 4, 0, BX_WRITE, @temp32);
    temp32 := EAX; access_linear(obase32 + $28, 4, 0, BX_WRITE, @temp32);
    temp32 := ECX; access_linear(obase32 + $2c, 4, 0, BX_WRITE, @temp32);
    temp32 := EDX; access_linear(obase32 + $30, 4, 0, BX_WRITE, @temp32);
    temp32 := EBX; access_linear(obase32 + $34, 4, 0, BX_WRITE, @temp32);
    temp32 := ESP; access_linear(obase32 + $38, 4, 0, BX_WRITE, @temp32);
    temp32 := EBP; access_linear(obase32 + $3c, 4, 0, BX_WRITE, @temp32);
    temp32 := ESI; access_linear(obase32 + $40, 4, 0, BX_WRITE, @temp32);
    temp32 := EDI; access_linear(obase32 + $44, 4, 0, BX_WRITE, @temp32);
    temp16 := Self.sregs[BX_SEG_REG_ES].selector.value;
                  access_linear(obase32 + $48, 2, 0, BX_WRITE, @temp16);
    temp16 := Self.sregs[BX_SEG_REG_CS].selector.value;
                  access_linear(obase32 + $4c, 2, 0, BX_WRITE, @temp16);
    temp16 := Self.sregs[BX_SEG_REG_SS].selector.value;
                  access_linear(obase32 + $50, 2, 0, BX_WRITE, @temp16);
    temp16 := Self.sregs[BX_SEG_REG_DS].selector.value;
                  access_linear(obase32 + $54, 2, 0, BX_WRITE, @temp16);
    temp16 := Self.sregs[BX_SEG_REG_FS].selector.value;
                  access_linear(obase32 + $58, 2, 0, BX_WRITE, @temp16);
    temp16 := Self.sregs[BX_SEG_REG_GS].selector.value;
                  access_linear(obase32 + $5c, 2, 0, BX_WRITE, @temp16);
    end;



  //
  // Commit point.  At this point, we commit to the new
  // context.  If an unrecoverable error occurs in further
  // processing, we complete the task switch without performing
  // additional access and segment availablility checks and
  // generate the appropriate exception prior to beginning
  // execution of the new task.
  //


  // Task switch clears LE/L3/L2/L1/L0 in DR7
  //Self.dr7 @:= ~$00000155; !!! ~
  Self.dr7 := Self.dr7 and not $00000155;


// effect on link field of new task
if ( source=BX_TASK_FROM_CALL_OR_INT ) then begin
  // set to selector of old task's TSS
  temp16 := Self.tr.selector.value;
  access_linear(nbase32 + 0, 2, 0, BX_WRITE, @temp16);
  end;



  //
  // Step 9: If call or interrupt, set the NT flag in the eflags
  //         image stored in new task's TSS.  If IRET or JMP,
  //         NT is restored from new TSS eflags image. (no change)
  //

  // effect on NT flag of new task
  if ( source=BX_TASK_FROM_CALL_OR_INT ) then begin
    newEFLAGS := newEFLAGS or $4000; // flag is set
    end;


  //
  // Step 10: If CALL, interrupt, or JMP, set busy flag in new task's
  //          TSS descriptor.  If IRET, leave set.
  //

  if ( (source=BX_TASK_FROM_JUMP) or (source=BX_TASK_FROM_CALL_OR_INT) ) then begin
    // set the new task's busy bit
    access_linear(Self.gdtr.base + tss_selector^.index*8 + 4,
                  4, 0, BX_READ, @dword2);
    dword2 := dword2 or $00000200;
    access_linear(Self.gdtr.base + tss_selector^.index*8 + 4,
                  4, 0, BX_WRITE, @dword2);
    end;


  //
  // Step 11: Set TS flag in the CR0 image stored in the new task TSS.
  //

  // set TS bit in CR0 register
  Self.cr0.ts := 1;
  Self.cr0.val32 := Self.cr0.val32 or $00000008;


  //
  // Step 12: Load the task register with the segment selector and
  //          descriptor for the new task TSS.
  //

  Self.tr.selector := tss_selector^;
  Self.tr.cache    := tss_descriptor^;
  // Reset the busy-flag, because all functions expect non-busy types in
  // tr.cache.  From Peter Lammich <peterl@sourceforge.net>.
  //Self.tr.cache.type_ @:= ~2; !!! ~
  Self.tr.cache.type_ := Self.tr.cache.type_ and not 2;


  //
  // Step 13: Load the new task (dynamic) state from new TSS.
  //          Any errors associated with loading and qualification of
  //          segment descriptors in this step occur in the new task's
  //          context.  State loaded here includes LDTR, CR3,
  //          EFLAGS, EIP, general purpose registers, and segment
  //          descriptor parts of the segment registers.
  //

  if (tss_descriptor^.type_ >= 9) then begin
    CR3_change(newCR3); // Tell paging unit about new cr3 value
    BX_DEBUG (Format('task_switch changing CR3 to $%08x\n', [newCR3]));
    //BX_INSTR_TLB_CNTRL(BX_INSTR_TASKSWITCH, newCR3);
    end;

  EIP:=newEIP;
  Self.prev_eip := EIP;
  write_eflags(newEFLAGS, 1,1,1,1); 
  EAX := newEAX;
  ECX := newECX;
  EDX := newEDX;
  EBX := newEBX;
  ESP := newESP;
  EBP := newEBP;
  ESI := newESI;
  EDI := newEDI;

  // Fill in selectors for all segment registers.  If errors
  // occur later, the selectors will at least be loaded.
  parse_selector(raw_es_selector, @es_selector);
  Self.sregs[BX_SEG_REG_ES].selector := es_selector;
  parse_selector(raw_cs_selector, @cs_selector);
  Self.sregs[BX_SEG_REG_CS].selector := cs_selector;
  parse_selector(raw_ss_selector, @ss_selector);
  Self.sregs[BX_SEG_REG_SS].selector := ss_selector;
  parse_selector(raw_ds_selector, @ds_selector);
  Self.sregs[BX_SEG_REG_DS].selector := ds_selector;
  parse_selector(raw_fs_selector, @fs_selector);
  Self.sregs[BX_SEG_REG_FS].selector := fs_selector;
  parse_selector(raw_gs_selector, @gs_selector);
  Self.sregs[BX_SEG_REG_GS].selector := gs_selector;
  parse_selector(raw_ldt_selector, @ldt_selector);
  Self.ldtr.selector                 := ldt_selector;

  // Start out with invalid descriptor caches, fill in
  // with values only as they are validated.
  Self.ldtr.cache.valid := 0;
  Self.sregs[BX_SEG_REG_ES].cache.valid := 0;
  Self.sregs[BX_SEG_REG_CS].cache.valid := 0;
  Self.sregs[BX_SEG_REG_SS].cache.valid := 0;
  Self.sregs[BX_SEG_REG_DS].cache.valid := 0;
  Self.sregs[BX_SEG_REG_FS].cache.valid := 0;
  Self.sregs[BX_SEG_REG_GS].cache.valid := 0;


// need to test valid bit in fetch_raw_descriptor?()
// or set limit to 0 instead when LDT is loaded with
// null. ??? +++
Self.ldtr.cache.ldt.limit := 0;

  // LDTR
  if (ldt_selector.ti)<>0 then begin
    // LDT selector must be in GDT
    BX_INFO(('task_switch: bad LDT selector TI:=1'));
    exception_no := BX_TS_EXCEPTION;
    error_code   := raw_ldt_selector  and $fffc;
    goto post_exception;
    end;

// ??? is LDT loaded in v8086 mod_e
  if ( (raw_ldt_selector  and $fffc) <> 0 ) then begin
    good := fetch_raw_descriptor2(@ldt_selector, @dword1, @dword2);
    if (good=0) then begin
      BX_INFO(('task_switch: bad LDT fetch'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_ldt_selector  and $fffc;
      goto post_exception;
      end;

    parse_descriptor(dword1, dword2, @ldt_descriptor);

    // LDT selector of new task is valid, else #TS(new task's LDT)
    if ((ldt_descriptor.valid=0) or (ldt_descriptor.type_ <> 2) or (ldt_descriptor.segmentType <> 0) or
      (ldt_descriptor.ldt.limit<7)) then begin
      BX_INFO(('task_switch: bad LDT segment'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_ldt_selector  and $fffc;
      goto post_exception;
      end

    // LDT of new task is present in memory, else #TS(new tasks's LDT)
    else if (ldt_descriptor.p=0) then begin
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_ldt_selector  and $fffc;
      goto post_exception;
      end;
    // All checks pass, fill in LDTR shadow cache
    Self.ldtr.cache := ldt_descriptor;
    end
  else begin
    // NULL LDT selector is OK, leave cache invalid
    end;

  if (v8086_mode())<>0 then begin
    // load seg regs as 8086 registers
    load_seg_reg(@Self.sregs[BX_SEG_REG_CS], raw_cs_selector);
    load_seg_reg(@Self.sregs[BX_SEG_REG_SS], raw_ss_selector);
    load_seg_reg(@Self.sregs[BX_SEG_REG_DS], raw_ds_selector);
    load_seg_reg(@Self.sregs[BX_SEG_REG_ES], raw_es_selector);
    load_seg_reg(@Self.sregs[BX_SEG_REG_FS], raw_fs_selector);
    load_seg_reg(@Self.sregs[BX_SEG_REG_GS], raw_gs_selector);
    end
  else begin

  // CS
  if ( (raw_cs_selector  and $fffc) <> 0 ) then begin
    good := fetch_raw_descriptor2(@cs_selector, @dword1, @dword2);
    if (good=0) then begin
      BX_INFO(('task_switch: bad CS fetch'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_cs_selector  and $fffc;
      goto post_exception;
      end;

    parse_descriptor(dword1, dword2, @cs_descriptor);

    // CS descriptor AR byte must indicate code segment else #TS(CS)
    if ((cs_descriptor.valid=0) or (cs_descriptor.segmentType=0) or
        (cs_descriptor.segment.executable=0)) then begin
      BX_PANIC(('task_switch: CS not valid executable seg'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_cs_selector  and $fffc;
      goto post_exception;
      end
    // if non-conforming then DPL must equal selector RPL else #TS(CS)
    else if ((cs_descriptor.segment.c_ed=0) and (cs_descriptor.dpl<>cs_selector.rpl)) then begin
      BX_INFO(('task_switch: non-conforming: CS.dpl!:=CS.RPL'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_cs_selector  and $fffc;
      goto post_exception;
      end
    // if conforming then DPL must be <= selector RPL else #TS(CS)
    else if ((cs_descriptor.segment.c_ed <> 0) and (cs_descriptor.dpl>cs_selector.rpl)) then begin
      BX_INFO(('task_switch: conforming: CS.dpl>RPL'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_cs_selector  and $fffc;
      goto post_exception;
      end
    // Code segment is present in memory, else #NP(new code segment)
    else if (cs_descriptor.p=0) then begin
      BX_PANIC(('task_switch: CS.p=0'));
      exception_no := BX_NP_EXCEPTION;
      error_code   := raw_cs_selector  and $fffc;
      goto post_exception;
      end;
    // All checks pass, fill in shadow cache
    Self.sregs[BX_SEG_REG_CS].cache    := cs_descriptor;
    end
  else begin
    // If new cs selector is null #TS(CS)
    BX_PANIC(('task_switch: CS NULL'));
    exception_no := BX_TS_EXCEPTION;
    error_code   := raw_cs_selector  and $fffc;
    goto post_exception;
    end;


  // SS
  if ( (raw_ss_selector  and $fffc) <> 0 ) then begin
    good := fetch_raw_descriptor2(@ss_selector, @dword1, @dword2);
    if (good=0) then begin
      BX_INFO(('task_switch: bad SS fetch'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_ss_selector  and $fffc;
      goto post_exception;
      end;

    parse_descriptor(dword1, dword2, @ss_descriptor);
    // SS selector must be within its descriptor table limits else #TS(SS)
    // SS descriptor AR byte must must indicate writable data segment,
    // else #TS(SS)
    if ((ss_descriptor.valid=0) or (ss_descriptor.segmentType=0) or (ss_descriptor.segment.executable <> 0) or
        (ss_descriptor.segment.r_w=0)) then begin
      BX_INFO(('task_switch: SS not valid'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_ss_selector  and $fffc;
      goto post_exception;
      end

    //
    // Stack segment is present in memory, else #SF(new stack segment)
    //
    else if (ss_descriptor.p=0) then begin
      BX_PANIC(('task_switch: SS not present'));
      exception_no := BX_SS_EXCEPTION;
      error_code   := raw_ss_selector  and $fffc;
      goto post_exception;
      end

    // Stack segment DPL matches CS.RPL, else #TS(new stack segment)
    else if (ss_descriptor.dpl <> cs_selector.rpl) then begin
      BX_PANIC(('task_switch: SS.rpl !:= CS.RPL'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_ss_selector  and $fffc;
      goto post_exception;
      end

    // Stack segment DPL matches selector RPL, else #TS(new stack segment)
    else if (ss_descriptor.dpl <> ss_selector.rpl) then begin
      BX_PANIC(('task_switch: SS.dpl !:= SS.rpl'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_ss_selector  and $fffc;
      goto post_exception;
      end;

{$if 0=1}
    // +++
    else if (ss_descriptor.u.segment.d_b @ and (tss_descriptor^.type<9)) then begin
      BX_DEBUG(( '++++++++++++++++++++++++++' ));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_ss_selector  and $fffc;
      goto post_exception;
      end;
{$ifend}
    // All checks pass, fill in shadow cache
    Self.sregs[BX_SEG_REG_SS].cache    := ss_descriptor;
    end
  else begin
    // SS selector is valid, else #TS(new stack segment)
    BX_PANIC(('task_switch: SS NULL'));
    exception_no := BX_TS_EXCEPTION;
    error_code   := raw_ss_selector  and $fffc;
    goto post_exception;
    end;


  //   if new selector is not null then perform following checks:
  //     index must be within its descriptor table limits else #TS(selector)
  //     AR byte must indicate data or readable code else #TS(selector)
  //     if data or non-conforming code then:
  //       DPL must be >= CPL else #TS(selector)
  //       DPL must be >= RPL else #TS(selector)
  //     AR byte must indicate PRESENT else #NP(selector)
  //     load cache with new segment descriptor and set valid bit



  // DS
  if ( (raw_ds_selector  and $fffc) <> 0 ) then begin
    good := fetch_raw_descriptor2(@ds_selector, @dword1, @dword2);
    if (good=0) then begin
      BX_INFO(('task_switch: bad DS fetch'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_ds_selector  and $fffc;
      goto post_exception;
      end;

    parse_descriptor(dword1, dword2, @ds_descriptor);
    if ((ds_descriptor.valid=0) or (ds_descriptor.segmentType=0) or
        ((ds_descriptor.segment.executable<>0) and (ds_descriptor.segment.r_w=0))) then begin
      BX_PANIC(('task_switch: DS not valid'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_ds_selector  and $fffc;
      goto post_exception;
      end
    // if data or non-conforming code
    else if (ds_descriptor.type_<12) and
        ((ds_descriptor.dpl<cs_selector.rpl) or (ds_descriptor.dpl<ds_selector.rpl)) then begin
      BX_PANIC(('task_switch: DS.dpl not valid'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_ds_selector  and $fffc;
      goto post_exception;
      end
  else if (ds_descriptor.p=0) then begin
      BX_PANIC(('task_switch: DS.p=0'));
      exception_no := BX_NP_EXCEPTION;
      error_code   := raw_ds_selector  and $fffc;
      goto post_exception;
      end;
    // All checks pass, fill in shadow cache
    Self.sregs[BX_SEG_REG_DS].cache    := ds_descriptor;
    end
  else begin
    // NULL DS selector is OK, leave cache invalid
    end;

  // ES
  if ( (raw_es_selector  and $fffc) <> 0 ) then begin
    good := fetch_raw_descriptor2(@es_selector, @dword1, @dword2);
    if (good=0) then begin
      BX_INFO(('task_switch: bad ES fetch'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_es_selector  and $fffc;
      goto post_exception;
      end;

    parse_descriptor(dword1, dword2, @es_descriptor);
    if ((es_descriptor.valid=0) or (es_descriptor.segmentType=0) or
       ((es_descriptor.segment.executable<>0) and (es_descriptor.segment.r_w=0))) then begin
      BX_PANIC(('task_switch: ES not valid'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_es_selector  and $fffc;
      goto post_exception;
      end
    // if data or non-conforming code
    else if ((es_descriptor.type_<12) and ((es_descriptor.dpl<cs_selector.rpl) or (es_descriptor.dpl<es_selector.rpl))) then begin
      BX_PANIC(('task_switch: ES.dpl not valid'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_es_selector  and $fffc;
      goto post_exception;
      end
  else if (es_descriptor.p=0) then begin
      BX_PANIC(('task_switch: ES.p=0'));
      exception_no := BX_NP_EXCEPTION;
      error_code   := raw_es_selector  and $fffc;
      goto post_exception;
      end;
    // All checks pass, fill in shadow cache
    Self.sregs[BX_SEG_REG_ES].cache    := es_descriptor;
    end
  else begin
    // NULL ES selector is OK, leave cache invalid
    end;


  // FS
  if ( (raw_fs_selector  and $fffc) <> 0 ) then begin // not NULL
    good := fetch_raw_descriptor2(@fs_selector, @dword1, @dword2);
    if (good=0) then begin
      BX_INFO(('task_switch: bad FS fetch'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_fs_selector  and $fffc;
      goto post_exception;
      end;

    parse_descriptor(dword1, dword2, @fs_descriptor);
    if ((fs_descriptor.valid=0) or (fs_descriptor.segmentType=0) or
        ((fs_descriptor.segment.executable<>0) and
         (fs_descriptor.segment.r_w=0))) then begin
      BX_PANIC(('task_switch: FS not valid'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_fs_selector  and $fffc;
      goto post_exception;
      end
    // if data or non-conforming code
    else if ((fs_descriptor.type_<12) and
        ((fs_descriptor.dpl<cs_selector.rpl) or
         (fs_descriptor.dpl<fs_selector.rpl))) then begin
      BX_PANIC(('task_switch: FS.dpl not valid'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_fs_selector  and $fffc;
      goto post_exception;
      end
  else if (fs_descriptor.p=0) then begin
      BX_PANIC(('task_switch: FS.p=0'));
      exception_no := BX_NP_EXCEPTION;
      error_code   := raw_fs_selector  and $fffc;
      goto post_exception;
      end;
    // All checks pass, fill in shadow cache
    Self.sregs[BX_SEG_REG_FS].cache    := fs_descriptor;
    end
  else begin
    // NULL FS selector is OK, leave cache invalid
    end;

  // GS
  if ( (raw_gs_selector  and $fffc) <> 0 ) then begin
    good := fetch_raw_descriptor2(@gs_selector, @dword1, @dword2);
    if (good=0) then begin
      BX_INFO(('task_switch: bad GS fetch'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_gs_selector  and $fffc;
      goto post_exception;
      end;

    parse_descriptor(dword1, dword2, @gs_descriptor);
    if ((gs_descriptor.valid=0) or (gs_descriptor.segmentType=0) or
        ((gs_descriptor.segment.executable<>0) and
         (gs_descriptor.segment.r_w=0))) then begin
      BX_PANIC(('task_switch: GS not valid'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_gs_selector  and $fffc;
      goto post_exception;
      end
    // if data or non-conforming code
    else if ((gs_descriptor.type_<12) and
        ((gs_descriptor.dpl<cs_selector.rpl) or
         (gs_descriptor.dpl<gs_selector.rpl))) then begin
      BX_PANIC(('task_switch: GS.dpl not valid'));
      exception_no := BX_TS_EXCEPTION;
      error_code   := raw_gs_selector  and $fffc;
      goto post_exception;
      end
  else if (gs_descriptor.p=0) then begin
      BX_PANIC(('task_switch: GS.p=0'));
      //exception(BX_NP_EXCEPTION, raw_gs_selector  and $fffc, 0);
      exception_no := BX_NP_EXCEPTION;
      error_code   := raw_gs_selector  and $fffc;
      goto post_exception;
      end;
    // All checks pass, fill in shadow cache
    Self.sregs[BX_SEG_REG_GS].cache    := gs_descriptor;
    end
  else begin
    // NULL GS selector is OK, leave cache invalid
    end;

    end;


  if ((tss_descriptor^.type_>=9) and ((trap_word  and $0001)<>0)) then begin
    Self.debug_trap := Self.debug_trap or $00008000; // BT flag in DR6
    Self.async_event := 1; // so processor knows to check
    BX_INFO(('task_switch: T bit set in new TSS.'));
    end;



  //
  // Step 14: Begin execution of new task.
  //
//BX_DEBUG(( 'TASKING: LEAVE' ));
  exit;

post_exception:
  Self.debug_trap := 0;
  Self.inhibit_mask := 0;
  BX_INFO(Format('task switch: posting exception %u after commit point', [exception_no]));
  exception2([exception_no, error_code, 0]);
  exit;
end;

procedure BX_CPU_C.get_SS_ESP_from_TSS(pl:unsigned; ss:PBit16u; esp:PBit32u);
var
  TSSstackaddr:Bit32u;
  temp16:Bit16u;
begin
  if (Self.tr.cache.valid=0) then
    BX_PANIC(('get_SS_ESP_from_TSS: TR.cache invalid'));

  if (Self.tr.cache.type_=9) then begin
    // 32-bit TSS

    TSSstackaddr := 8*pl + 4;
    if ( (TSSstackaddr+7) >Self.tr.cache.tss386.limit_scaled ) then
      exception2([BX_TS_EXCEPTION,
                Self.tr.selector.value  and $fffc, 0]);

    access_linear(Self.tr.cache.tss386.base +
      TSSstackaddr+4, 2, 0, BX_READ, ss);
    access_linear(Self.tr.cache.tss386.base +
      TSSstackaddr,   4, 0, BX_READ, esp);
    end
  else if (Self.tr.cache.type_=1) then begin
    // 16-bit TSS

    TSSstackaddr := 4*pl + 2;
    if ( (TSSstackaddr+4) > Self.tr.cache.tss286.limit ) then
      exception2([BX_TS_EXCEPTION,
                Self.tr.selector.value  and $fffc, 0]);

    access_linear(Self.tr.cache.tss286.base +
      TSSstackaddr+2, 2, 0, BX_READ, ss);
    access_linear(Self.tr.cache.tss286.base +
      TSSstackaddr,   2, 0, BX_READ, @temp16);
    esp^ := temp16; // truncate
    end
  else begin
    BX_PANIC(Format('get_SS_ESP_from_TSS: TR is bogus type (%u)',[Self.tr.cache.type_]));
    end;
end;
{$ifend}



{$else}  // BX_SUPPORT_TASKING


// for non-support of hardware tasking

#if BX_CPU_LEVEL >= 2
  (* corresponds to SWITCH_TASKS algorithm in Intel documentation *)
  procedure
BX_CPU_C.task_switch(bx_selector_t *selector,
                 bx_descriptor_t *descriptor, unsigned source,
                 Bit32u dword1, Bit32u dword2)
begin
  UNUSED(selector);
  UNUSED(descriptor);
  UNUSED(source);
  UNUSED(dword1);
  UNUSED(dword2);

  BX_INFO(('task_switch(): not complete'));
end;
{$ifend}



