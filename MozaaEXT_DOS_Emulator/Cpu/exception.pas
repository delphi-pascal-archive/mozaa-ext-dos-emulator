{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
const
BX_ET_BENIGN       = 0;
BX_ET_CONTRIBUTORY = 1;
BX_ET_PAGE_FAULT   = 2;

BX_ET_DOUBLE_FAULT = 10;


is_exception_OK:array[0..2,0..2] of Bool =
    ((1, 1, 1),  (* 1st exception is BENIGN *)
    (1, 0, 1) , (* 1st exception is CONTRIBUTORY *)
    (1, 0, 0));  (* 1st exception is PAGE_FAULT *)

procedure BX_CPU_C.interrupt(vector:Bit8u; is_INT:Bool; is_error_code:Bool;error_code:Bit16u);
var
  dword1, dword2:Bit32u;
  gate_descriptor, cs_descriptor:bx_descriptor_t;
  cs_selector:bx_selector_t;

  raw_tss_selector:Bit16u;
  tss_selector:bx_selector_t;
  tss_descriptor:bx_descriptor_t;

  gate_dest_selector:Bit16u;
  gate_dest_offset:Bit32u;

  old_SS, old_CS, SS_for_cpl_x:Bit16u;
  ESP_for_cpl_x, old_EIP, old_ESP:Bit32u;
  ss_descriptor:bx_descriptor_t;
  ss_selector:bx_selector_t;
  bytes:Integer;
  temp_ESP:Bit32u;
  cs_selector_2, ip_:Bit16u;

  label end_case;
begin

//BX_DEBUG(( '.interrupt(%u)', vector ));

  //BX_INSTR_INTERRUPT(vector);
  invalidate_prefetch_q();

  // Discard any traps and inhibits for new context; traps will
  // resume upon return.
  Self.debug_trap := 0;
  Self.inhibit_mask := 0;

{$if BX_CPU_LEVEL >= 2}
//  unsigned prev_errno;

  BX_DEBUG(Format('interrupt(): vector := %u, INT := %u, EXT := %u',[vector, is_INT, Self.EXT]));

Self.save_cs  := Self.sregs[BX_SEG_REG_CS];
Self.save_ss  := Self.sregs[BX_SEG_REG_SS];
Self.save_eip := EIP;
Self.save_esp := ESP;

//  prev_errno := Self.errorno;

  if Boolean(real_mode()=0) then begin


    // interrupt vector must be within IDT table limits,
    // else #GP(vector number*8 + 2 + EXT)
    if Boolean( (vector*8 + 7) > Self.idtr.limit) then begin
      BX_DEBUG(Format('IDT.limit := %04x', [Self.idtr.limit]));
      BX_DEBUG(Format('IDT.base  := %06x', [Self.idtr.base]));
      BX_DEBUG(('interrupt vector must be within IDT table limits'));
      BX_DEBUG(('bailing'));
      BX_DEBUG(('interrupt(): vector > idtr.limit'));

      exception2([BX_GP_EXCEPTION, vector*8 + 2, 0]);
      end;

    // descriptor AR byte must indicate interrupt gate, trap gate,
    // or task gate, else #GP(vector*8 + 2 + EXT)
    access_linear(Self.idtr.base + vector*8,     4, 0,
      BX_READ, @dword1);
    access_linear(Self.idtr.base + vector*8 + 4, 4, 0,
      BX_READ, @dword2);

    parse_descriptor(dword1, dword2, @gate_descriptor);

    if Boolean( (gate_descriptor.valid=0) or (gate_descriptor.segmentType<>0)) then begin
      BX_DEBUG(('interrupt(): gate descriptor is not valid sys seg'));
      exception2([BX_GP_EXCEPTION, vector*8 + 2, 0]);
      end;

    case gate_descriptor.type_ of
      5, // task gate
      6, // 286 interrupt gate
      7, // 286 trap gate
      14, // 386 interrupt gate
      15: // 386 trap gate
        goto end_case;
      else
        begin
        BX_DEBUG(Format('interrupt(): gate.type(%u) <> 5,6,7,14,15 ',[gate_descriptor.type_]));
        exception2([BX_GP_EXCEPTION, vector*8 + 2, 0]);
        exit;
        end;
      end;
end_case:

    // if software interrupt, then gate descripor DPL must be >= CPL,
    // else #GP(vector * 8 + 2 + EXT)
    if Boolean((is_INT<>0) and (gate_descriptor.dpl < CPL)) then begin
(* ??? *)
      BX_DEBUG(('interrupt(): is_INT @ and (dpl < CPL)'));
      exception2([BX_GP_EXCEPTION, vector*8 + 2, 0]);
      exit;
      end;

    // Gate must be present, else #NP(vector * 8 + 2 + EXT)
    if Boolean(gate_descriptor.p = 0) then begin
      BX_DEBUG(('interrupt(): p = 0'));
      exception2([BX_NP_EXCEPTION, vector*8 + 2, 0]);
      end;

    case gate_descriptor.type_ of
      5: // 286/386 task gate
        // examine selector to TSS, given in task gate descriptor
        begin
          raw_tss_selector := gate_descriptor.taskgate.tss_selector;
          parse_selector(raw_tss_selector, @tss_selector);

        // must specify global in the local/global bit,
        //      else #TS(TSS selector)
// +++
// 486/Pent books say #TSS(selector)
// PPro+ says #GP(selector)
        if Boolean(tss_selector.ti) then begin
          BX_PANIC(('interrupt: tss_selector.ti:=1'));
          exception2([BX_TS_EXCEPTION, raw_tss_selector  and $fffc, 0]);
          exit;
          end;

        // index must be within GDT limits, else #TS(TSS selector)
        fetch_raw_descriptor(@tss_selector, @dword1, @dword2,
          BX_TS_EXCEPTION);

        // AR byte must specify available TSS,
        //   else #TS(TSS selector)
        parse_descriptor(dword1, dword2, @tss_descriptor);
        if Boolean(tss_descriptor.valid=0 or tss_descriptor.segmentType) then begin
          BX_PANIC(('exception: TSS selector points to bad TSS'));
          exception2([BX_TS_EXCEPTION, raw_tss_selector  and $fffc, 0]);
          exit;
          end;
        if Boolean((tss_descriptor.type_<>9) and (tss_descriptor.type_<>1)) then begin
          BX_PANIC(('exception: TSS selector points to bad TSS'));
          exception2([BX_TS_EXCEPTION, raw_tss_selector  and $fffc, 0]);
          exit;
          end;


        // TSS must be present, else #NP(TSS selector)
        // done in task_switch()

        // switch tasks with nesting to TSS
        task_switch(@tss_selector, @tss_descriptor,
                    BX_TASK_FROM_CALL_OR_INT, dword1, dword2);

        // if interrupt was caused by fault with error code
        //   stack limits must allow push of 2 more bytes, else #SS(0)
        // push error code onto stack

        //??? push_16 vs push_32
        if Boolean( is_error_code ) then begin
          //if Boolean(tss_descriptor.type=9)
          if Boolean(Self.sregs[BX_SEG_REG_CS].cache.segment.d_b) then
            push_32(error_code)
          else
            push_16(error_code);
          end;

        // instruction pointer must be in CS limit, else #GP(0)
        //if Boolean(EIP > cs_descriptor.u.segment.limit_scaled) then beginend;
        if Boolean(EIP > Self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled) then begin
          BX_PANIC(('exception(): eIP > CS.limit'));
          exception2([BX_GP_EXCEPTION, $0000, 0]);
          end;
        exit;
        end;

      6, // 286 interrupt gate
      7, // 286 trap gate
      14, // 386 interrupt gate
      15: // 386 trap gate
      begin
        if Boolean( gate_descriptor.type_ >= 14 ) then begin // 386 gate
          gate_dest_selector := gate_descriptor.gate386.dest_selector;
          gate_dest_offset   := gate_descriptor.gate386.dest_offset;
          end
        else begin // 286 gate
          gate_dest_selector := gate_descriptor.gate286.dest_selector;
          gate_dest_offset   := gate_descriptor.gate286.dest_offset;
          end;

        // examine CS selector and descriptor given in gate descriptor
        // selector must be non-null else #GP(EXT)
        if Boolean( (gate_dest_selector  and $fffc) = 0 ) then begin
          BX_PANIC(('int_trap_gate(): selector null'));
          exception2([BX_GP_EXCEPTION, 0, 0]);
          end;

        parse_selector(gate_dest_selector, @cs_selector);

        // selector must be within its descriptor table limits
        // else #GP(selector+EXT)
        fetch_raw_descriptor(@cs_selector, @dword1, @dword2,
                                BX_GP_EXCEPTION);
        parse_descriptor(dword1, dword2, @cs_descriptor);

        // descriptor AR byte must indicate code seg
        // and code segment descriptor DPL<=CPL, else #GP(selector+EXT)
        if Boolean((cs_descriptor.valid=0) or (cs_descriptor.segmentType=0) or (cs_descriptor.segment.executable=0) or
             (cs_descriptor.dpl>CPL)) then begin
          BX_DEBUG(('interrupt(): not code segment'));
          exception2([BX_GP_EXCEPTION, cs_selector.value  and $fffc, 0]);
          end;

        // segment must be present, else #NP(selector + EXT)
        if Boolean( cs_descriptor.p=0 ) then begin
          BX_DEBUG(('interrupt(): segment not present'));
          exception2([BX_NP_EXCEPTION, cs_selector.value  and $fffc, 0]);
          end;

        // if code segment is non-conforming and DPL < CPL then
        // INTERRUPT TO INNER PRIVILEGE:
        if Boolean( (cs_descriptor.segment.c_ed=0) and (cs_descriptor.dpl<CPL)) then begin

          BX_DEBUG(('interrupt(): INTERRUPT TO INNER PRIVILEGE'));

          // check selector and descriptor for new stack in current TSS
          get_SS_ESP_from_TSS(cs_descriptor.dpl,
                              @SS_for_cpl_x, @ESP_for_cpl_x);

          // Selector must be non-null else #TS(EXT)
          if Boolean( (SS_for_cpl_x  and $fffc) = 0 ) then begin
            BX_PANIC(('interrupt(): SS selector null'));
            (* TS(ext) *)
            exception2([BX_TS_EXCEPTION, 0, 0]);
            end;

          // selector index must be within its descriptor table limits
          // else #TS(SS selector + EXT)
          parse_selector(SS_for_cpl_x, @ss_selector);
          // fetch 2 dwords of descriptor; call handles out of limits checks
          fetch_raw_descriptor(@ss_selector, @dword1, @dword2,
                                  BX_TS_EXCEPTION);
          parse_descriptor(dword1, dword2, @ss_descriptor);

          // selector rpl must := dpl of code segment,
          // else #TS(SS selector + ext)
          if Boolean(ss_selector.rpl <> cs_descriptor.dpl) then begin
            BX_PANIC(('interrupt(): SS.rpl !:= CS.dpl'));
            exception2([BX_TS_EXCEPTION, SS_for_cpl_x  and $fffc, 0]);
            end;

          // stack seg DPL must := DPL of code segment,
          // else #TS(SS selector + ext)
          if Boolean(ss_descriptor.dpl <> cs_descriptor.dpl) then begin
            BX_PANIC(('interrupt(): SS.dpl !:= CS.dpl'));
            exception2([BX_TS_EXCEPTION, SS_for_cpl_x  and $fffc, 0]);
            end;

          // descriptor must indicate writable data segment,
          // else #TS(SS selector + EXT)
          if Boolean((ss_descriptor.valid=0) or (ss_descriptor.segmentType=0) or (ss_descriptor.segment.executable=1) or
              (ss_descriptor.segment.r_w=0)) then begin
            BX_PANIC(('interrupt(): SS not writable data segment'));
            exception2([BX_TS_EXCEPTION, SS_for_cpl_x  and $fffc, 0]);
            end;

          // seg must be present, else #SS(SS selector + ext)
          if Boolean(ss_descriptor.p=0) then begin
            BX_PANIC(('interrupt(): SS not present'));
            exception2([BX_SS_EXCEPTION, SS_for_cpl_x  and $fffc, 0]);
            end;

          if Boolean(gate_descriptor.type_>=14) then begin
            // 386 int/trap gate
            // new stack must have room for 20|24 bytes, else #SS(0)
            if Boolean( is_error_code ) then
              bytes := 24
            else
              bytes := 20;
            if Boolean(v8086_mode()) then
              bytes := bytes + 16;
            end
          else begin
            // new stack must have room for 10|12 bytes, else #SS(0)
            if Boolean( is_error_code ) then
              bytes := 12
            else
              bytes := 10;
            if Boolean(v8086_mode()) then begin
              bytes := bytes +8;
              BX_PANIC(('interrupt: int/trap gate VM'));
              end;
            end;

// 486,Pentium books
// new stack must have room for 10/12 bytes, else #SS(0) 486 book
// PPro+
// new stack must have room for 10/12 bytes, else #SS(seg selector)
          if Boolean( can_push(@ss_descriptor, ESP_for_cpl_x, bytes)=0 ) then begin
            BX_PANIC(Format('interrupt(): new stack doesn''t have room for %u bytes',[bytes]));
            // SS(???)
            end;

          // IP must be within CS segment boundaries, else #GP(0)
          if Boolean(gate_dest_offset > cs_descriptor.segment.limit_scaled) then begin
            BX_PANIC(('interrupt(): gate eIP > CS.limit'));
            exception2([BX_GP_EXCEPTION, 0, 0]);
            end;

          old_ESP := ESP;
          old_SS  := Self.sregs[BX_SEG_REG_SS].selector.value;
          old_EIP := EIP;
          old_CS  := Self.sregs[BX_SEG_REG_CS].selector.value;

          // load new SS:SP values from TSS
          load_ss(@ss_selector, @ss_descriptor, cs_descriptor.dpl);

          if Boolean(ss_descriptor.segment.d_b) then
            ESP := ESP_for_cpl_x
          else
            SP := ESP_for_cpl_x; // leave upper 16bits

          // load new CS:IP values from gate
          // set CPL to new code segment DPL
          // set RPL of CS to CPL
          load_cs(@cs_selector, @cs_descriptor, cs_descriptor.dpl);
          EIP := gate_dest_offset;

          if Boolean(gate_descriptor.type_>=14) then begin // 386 int/trap gate
            if Boolean(v8086_mode()) then begin
              push_32(Self.sregs[BX_SEG_REG_GS].selector.value);
              push_32(Self.sregs[BX_SEG_REG_FS].selector.value);
              push_32(Self.sregs[BX_SEG_REG_DS].selector.value);
              push_32(Self.sregs[BX_SEG_REG_ES].selector.value);
              Self.sregs[BX_SEG_REG_GS].cache.valid := 0;
              Self.sregs[BX_SEG_REG_GS].selector.value := 0;
              Self.sregs[BX_SEG_REG_FS].cache.valid := 0;
              Self.sregs[BX_SEG_REG_FS].selector.value := 0;
              Self.sregs[BX_SEG_REG_DS].cache.valid := 0;
              Self.sregs[BX_SEG_REG_DS].selector.value := 0;
              Self.sregs[BX_SEG_REG_ES].cache.valid := 0;
              Self.sregs[BX_SEG_REG_ES].selector.value := 0;
              end;
            // push long pointer to old stack onto new stack
            push_32(old_SS);
            push_32(old_ESP);

            // push EFLAGS
            push_32(read_eflags());

            // push long pointer to return address onto new stack
            push_32(old_CS);
            push_32(old_EIP);

            if Boolean( is_error_code ) then
              push_32(error_code);
            end
          else begin // 286 int/trap gate
            if Boolean(v8086_mode()) then begin
              BX_PANIC(('286 int/trap gate, VM'));
              end;
            // push long pointer to old stack onto new stack
            push_16(old_SS);
            push_16(old_ESP); // ignores upper 16bits

            // push FLAGS
            push_16(read_flags());

            // push return address onto new stack
            push_16(old_CS);
            push_16(old_EIP); // ignores upper 16bits

            if Boolean( is_error_code ) then
              push_16(error_code);
            end;

          // if INTERRUPT GATE set IF to 0
          if Boolean( (gate_descriptor.type_ and 1)=0 ) then// even is int-gate
            Self.eflags.if_ := 0;
          Self.eflags.tf := 0;
          Self.eflags.vm := 0;
          Self.eflags.rf := 0;
          Self.eflags.nt := 0;
          exit;
          end;

        if Boolean(v8086_mode()) then begin
          exception2([BX_GP_EXCEPTION, cs_selector.value  and $fffc, 0]);
          end;

        // if code segment is conforming OR code segment DPL := CPL then
        // INTERRUPT TO SAME PRIVILEGE LEVEL:
        if Boolean((cs_descriptor.segment.c_ed=1) or (cs_descriptor.dpl=CPL)) then begin

          if Boolean(Self.sregs[BX_SEG_REG_SS].cache.segment.d_b) then
            temp_ESP := ESP
          else
            temp_ESP := SP;

          BX_DEBUG(('int_trap_gate286(): INTERRUPT TO SAME PRIVILEGE'));

          // Current stack limits must allow pushing 6|8 bytes, else #SS(0)
          if Boolean(gate_descriptor.type_ >= 14) then begin // 386 gate
            if Boolean( is_error_code ) then
              bytes := 16
            else
              bytes := 12;
            end
          else begin // 286 gate
            if Boolean( is_error_code ) then
              bytes := 8
            else
              bytes := 6;
            end;

          if Boolean( can_push(@Self.sregs[BX_SEG_REG_SS].cache,
                         temp_ESP, bytes)=0 ) then begin
            BX_DEBUG(('interrupt(): stack doesn''t have room'));
            exception2([BX_SS_EXCEPTION, 0, 0]);
            end;

          // eIP must be in CS limit else #GP(0)
          if Boolean(gate_dest_offset > cs_descriptor.segment.limit_scaled) then begin
            BX_PANIC(('interrupt(): IP > cs descriptor limit'));
            exception2([BX_GP_EXCEPTION, 0, 0]);
            end;

          // push flags onto stack
          // push current CS selector onto stack
          // push return offset onto stack
          if Boolean(gate_descriptor.type_ >= 14) then begin // 386 gate
            push_32(read_eflags());
            push_32(Self.sregs[BX_SEG_REG_CS].selector.value);
            push_32(EIP);
            if Boolean( is_error_code ) then
              push_32(error_code)
            end
          else begin // 286 gate
            push_16(read_flags());
            push_16(Self.sregs[BX_SEG_REG_CS].selector.value);
            push_16(IP);
            if Boolean( is_error_code ) then
              push_16(error_code);
            end;

          // load CS:IP from gate
          // load CS descriptor
          // set the RPL field of CS to CPL
          load_cs(@cs_selector, @cs_descriptor, CPL);
          EIP := gate_dest_offset;

          // if interrupt gate then set IF to 0
          if Boolean( (gate_descriptor.type_ and 1)=0 ) then // even is int-gate
            Self.eflags.if_ := 0;
          Self.eflags.tf := 0;
          Self.eflags.nt := 0;
          Self.eflags.vm := 0;
          Self.eflags.rf := 0;
          exit;
          end;

        // else #GP(CS selector + ext)
        BX_DEBUG(('interrupt: bad descriptor'));
        BX_DEBUG(Format('c_ed:=%u, descriptor.dpl:=%u, CPL:=%u',[cs_descriptor.segment.c_ed,cs_descriptor.dpl,CPL]));
        BX_DEBUG(Format('cs.segment := %u',[cs_descriptor.segmentType]));
        exception2([BX_GP_EXCEPTION, cs_selector.value  and $fffc, 0]);
        end;
      (*else
        BX_PANIC(('bad descriptor type in interrupt()!'));*)
    end;
  end
  else
{$ifend}
    begin (* real mod_e *)

    if Boolean( (vector*4+3) > Self.idtr.limit ) then
      BX_PANIC(('interrupt(real mod_e) vector > limit'));

    push_16(read_flags());

    cs_selector_2 := Self.sregs[BX_SEG_REG_CS].selector.value;
    push_16(cs_selector_2);
    ip_ := Self.eip;
    push_16(ip_);

    access_linear(Self.idtr.base + 4 * vector,     2, 0, BX_READ, @ip_);
    IP := ip_;
    access_linear(Self.idtr.base + 4 * vector + 2, 2, 0, BX_READ, @cs_selector_2);
    load_seg_reg(@Self.sregs[BX_SEG_REG_CS], cs_selector_2);

    (* INT affects the following flags: I,T *)
    Self.eflags.if_ := 0;
    Self.eflags.tf  := 0;
{$if BX_CPU_LEVEL >= 4}
    Self.eflags.ac  := 0;
{$ifend}
    Self.eflags.rf := 0;
    end;
end;

procedure BX_CPU_C.exception(vector:unsigned;error_code:Bit16u;is_INT:Bool);
  // vector:     0..255: vector in IDT
  // error_code: if exception generates and error, push this error code

var
  push_error:Bool;
  exception_type:Bit8u;
  prev_errno:unsigned;
begin

{$if BX_DEBUGGER=1}
  if Boolean(bx_guard.special_unwind_stack) then begin
    BX_INFO (('exception() returning early because special_unwind_stack is set'));
    exit;
  end;
{$ifend}

//BX_DEBUG(( '.exception(%u)', vector ));

  //BX_INSTR_EXCEPTION(vector);
  invalidate_prefetch_q();

  //UNUSED(is_INT);

  //BX_DEBUG(('exception(%02x h)', (unsigned) vector));

  // if not initial error, restore previous register values from
  // previous attempt to handle exception
  if Boolean(Self.errorno) then begin
    Self.sregs[BX_SEG_REG_CS]  := Self.save_cs;
    Self.sregs[BX_SEG_REG_SS]  := Self.save_ss;
    EIP := Self.save_eip;
    ESP := Self.save_esp;
    end;

  Inc(Self.errorno);
  if Boolean(Self.errorno >= 3) then begin
    BX_PANIC(('exception(): 3rd exception with no resolution'));
    BX_ERROR(('WARNING: Any simulation after this point is completely bogus.'));
{$if BX_DEBUGGER=1}
    bx_guard.special_unwind_stack := true;
{$ifend}
    exit;
    end;

  (* careful not to get here with curr_exception[1]=DOUBLE_FAULT *)
  (* ...index on DOUBLE_FAULT below, will be out of bounds *)

  (* if 1st was a double fault (software INT?), then shutdown *)
  if Boolean( (Self.errorno=2) and (Self.curr_exception[0]=BX_ET_DOUBLE_FAULT) ) then begin
    BX_PANIC(('exception(): triple fault encountered'));
    BX_ERROR(('WARNING: Any simulation after this point is completely bogus.'));
{$if BX_DEBUGGER=1}
    bx_guard.special_unwind_stack := true;
{$ifend}
    exit;
    end;

  (* ??? this is not totally correct, should be done depending on
   * vector *)
  (* backup IP to value before error occurred *)
  EIP := Self.prev_eip;
  ESP := Self.prev_esp;

  // note: fault-class exceptions _except_ #DB set RF in
  //       eflags image.

  case vector of
    0: // DIV by 0
      begin
        push_error := 0;
        exception_type := BX_ET_CONTRIBUTORY;
        Self.eflags.rf := 1;
      end;
    1: // debug exceptions
      begin
        push_error := 0;
        exception_type := BX_ET_BENIGN;
      end;
    2: // NMI
      begin
        push_error := 0;
        exception_type := BX_ET_BENIGN;
      end;
    3: // breakpoint
      begin
      push_error := 0;
      exception_type := BX_ET_BENIGN;
      end;
    4: // overflow
      begin
      push_error := 0;
      exception_type := BX_ET_BENIGN;
      end;
    5: // bounds check
      begin
      push_error := 0;
      exception_type := BX_ET_BENIGN;
      Self.eflags.rf := 1;
      end;
    6: // invalid opcode
      begin
      push_error := 0;
      exception_type := BX_ET_BENIGN;
      Self.eflags.rf := 1;
      end;
    7: // device not available
      begin
      push_error := 0;
      exception_type := BX_ET_BENIGN;
      Self.eflags.rf := 1;
      end;
    8: // double fault
      begin
      push_error := 1;
      exception_type := BX_ET_DOUBLE_FAULT;
      end;
    9: // coprocessor segment overrun (286,386 only)
      begin
      push_error := 0;
      exception_type := BX_ET_CONTRIBUTORY;
      Self.eflags.rf := 1;
      BX_PANIC(('exception(9): unfinished'));
      end;
    10: // invalid TSS
      begin
      push_error := 1;
      exception_type := BX_ET_CONTRIBUTORY;
      error_code := (error_code  and $fffe) or Self.EXT;
      Self.eflags.rf := 1;
      end;
    11: // segment not present
      begin
      push_error := 1;
      exception_type := BX_ET_CONTRIBUTORY;
      error_code := (error_code  and $fffe) or Self.EXT;
      Self.eflags.rf := 1;
      end;
    12: // stack fault
      begin
      push_error := 1;
      exception_type := BX_ET_CONTRIBUTORY;
      error_code := (error_code  and $fffe) or Self.EXT;
      Self.eflags.rf := 1;
      end;
    13: // general protection
      begin
      push_error := 1;
      exception_type := BX_ET_CONTRIBUTORY;
      error_code := (error_code  and $fffe) or Self.EXT;
      Self.eflags.rf := 1;
      end;
    14: // page fault
      begin
      push_error := 1;
      exception_type := BX_ET_PAGE_FAULT;
      // ??? special format error returned
      Self.eflags.rf := 1;
      end;
    15: // reserved
      begin
      BX_PANIC(('exception(15): reserved'));
      push_error := 0;     // keep compiler happy for now
      exception_type := 0; // keep compiler happy for now
      end;
    16: // floating-point error
      begin
      push_error := 0;
      exception_type := BX_ET_BENIGN;
      Self.eflags.rf := 1;
      end;
{$if BX_CPU_LEVEL >= 4}
    17: // alignment check
      begin
      BX_PANIC(('exception(): alignment-check, vector 17 unimplemented'));
      push_error := 0;     // keep compiler happy for now
      exception_type := 0; // keep compiler happy for now
      Self.eflags.rf := 1;
      end;
{$ifend}
{$if BX_CPU_LEVEL >= 5}
    18: // machine check
      begin
      BX_PANIC(('exception(): machine-check, vector 18 unimplemented'));
      push_error := 0;     // keep compiler happy for now
      exception_type := 0; // keep compiler happy for now
      end;
{$ifend}
    else
      begin
      BX_PANIC(Format('exception(%u): bad vector',[vector]));
      push_error := 0;     // keep compiler happy for now
      exception_type := 0; // keep compiler happy for now
      end;
    end;

  if Boolean(exception_type <> BX_ET_PAGE_FAULT) then begin
    // Page faults have different format
    error_code := (error_code  and $fffe) or Self.EXT;
    end;
  Self.EXT := 1;

  (* if we've already had 1st exception, see if 2nd causes a
   * Double Fault instead.  Otherwise, just record 1st exception
   *)
  if Boolean(Self.errorno >= 2) then begin
    if Boolean(is_exception_OK[Self.curr_exception[0]][exception_type]) then
      Self.curr_exception[1] := exception_type
    else begin
      Self.curr_exception[1] := BX_ET_DOUBLE_FAULT;
      vector := 8;
    end;
  end
  else begin
    Self.curr_exception[0] := exception_type;
  end;


{$if BX_CPU_LEVEL >= 2}
  if Boolean(real_mode()=0) then begin
    prev_errno := Self.errorno;
    Self.interrupt(vector, 0, push_error, error_code);
//    if Boolean(Self.errorno > prev_errno) then begin
//      BX_INFO(('segment_exception(): errorno changed'));
//      longjmp(jmp_buf_env, 1); // go back to main decode loop
//      exit;
//      end;

//    if Boolean(push_error) then begin
//      (* push error code on stack, after handling interrupt *)
//      (* pushed as a word or dword depending upon default size ??? *)
//      if Boolean(ss.cache.u.segment.d_b)
//        push_32((Bit32u) error_code); (* upper bits reserved *)
//      else
//        push_16(error_code);
//      if Boolean(Self.errorno > prev_errno) then begin
//        BX_PANIC(('segment_exception(): errorno changed'));
//        exit;
//        end;
//      end;
    Self.errorno := 0; // error resolved
    if vector = 16 then
      reloop:=True
    else
      longjmp(savejump, 1); // go back to main decode loop
    end
  else // real mod_e
{$ifend}
    begin
    // not INT, no error code pushed
    Self.interrupt(vector, 0, 0, 0);
    Self.errorno := 0; // error resolved
    if vector = 16 then
      reloop:=True
    else
      longjmp(savejump, 1); // go back to main decode loop
    //longjmp(Self.jmp_buf_env, 1); // go back to main decode loop
    end;
end;


function BX_CPU_C.int_number(seg:pbx_segment_reg_t):Integer;
begin
  if Boolean(seg = @Self.sregs[BX_SEG_REG_SS]) then
    Result:=(BX_SS_EXCEPTION)
  else
    Result:=(BX_GP_EXCEPTION);
end;

procedure BX_CPU_C.shutdown_cpu;
begin
{$if BX_CPU_LEVEL > 2}
  BX_PANIC(('shutdown_cpu(): not implemented for 386'));
{$ifend}

  invalidate_prefetch_q();
  BX_PANIC(('shutdown_cpu(): not finished'));

end;
