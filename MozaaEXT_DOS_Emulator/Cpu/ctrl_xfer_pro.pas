{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

{$if BX_CPU_LEVEL >= 2}
procedure BX_CPU_C.jump_protected(Istr:PBxInstruction_tag; cs_raw:Bit16u; disp32:Bit32u);
var
  descriptor:bx_descriptor_t;
  selector:bx_selector_t;
  dword1, dword2:Bit32u;

  raw_tss_selector:Bit16u;
  tss_selector, gate_cs_selector:bx_selector_t;
  tss_descriptor, gate_cs_descriptor:bx_descriptor_t;
  gate_cs_raw:Bit16u;
  temp_eIP:Bit32u;
begin
  (* destination selector is not null else #GP(0) *)
  if ((cs_raw and $fffc) = 0) then begin
    BX_PANIC(('jump_protected: cs = 0'));
    exception2([BX_GP_EXCEPTION, 0, 0]);
    exit;
    end;

  parse_selector(cs_raw, @selector);

  (* destination selector index is whithin its descriptor table
     limits else #GP(selector) *)
  fetch_raw_descriptor(@selector, @dword1, @dword2,
    BX_GP_EXCEPTION);

  (* examine AR byte of destination selector for legal values: *)
  parse_descriptor(dword1, dword2, @descriptor);

  if ( descriptor.segmentType )<>0 then begin
    if ( descriptor.segment.executable=0 ) then begin
      BX_ERROR(('jump_protected: S:=1: descriptor not executable'));
      exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
      exit;
      end;
    // CASE: JUMP CONFORMING CODE SEGMENT:
    if ( descriptor.segment.c_ed )<>0 then begin
      // descripor DPL must be <= CPL else #GP(selector)
      if (descriptor.dpl > CPL) then begin
        BX_ERROR(('jump_protected: dpl > CPL'));
        exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
        exit;
        end;

      (* segment must be PRESENT else #NP(selector) *)
      if (descriptor.p = 0) then begin
        BX_ERROR(('jump_protected: p = 0'));
        exception2([BX_NP_EXCEPTION, cs_raw  and $fffc, 0]);
        exit;
        end;

      (* instruction pointer must be in code segment limit else #GP(0) *)
      if (disp32 > descriptor.segment.limit_scaled) then begin
        BX_PANIC(('jump_protected: IP > limit'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        exit;
        end;

      (* Load CS:IP from destination pointer *)
      (* Load CS-cache with new segment descriptor *)
      (* CPL does not change for conforming code segment *)
      load_cs(@selector, @descriptor, CPL);
      Self.eip := disp32;
      exit;
      end

    // CASE: jump nonconforming code segment:
    else begin
      (* RPL of destination selector must be <= CPL else #GP(selector) *)
      if (selector.rpl > CPL) then begin
        BX_PANIC(('jump_protected: rpl > CPL'));
        exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
        exit;
        end;

      // descriptor DPL must := CPL else #GP(selector)
      if (descriptor.dpl <> CPL) then begin
        BX_ERROR(('jump_protected: dpl !:= CPL'));
        exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
        exit;
        end;

      (* segment must be PRESENT else #NP(selector) *)
      if (descriptor.p = 0) then begin
        BX_ERROR(('jump_protected: p = 0'));
        exception2([BX_NP_EXCEPTION, cs_raw  and $fffc, 0]);
        exit;
        end;

      (* IP must be in code segment limit else #GP(0) *)
      if (disp32 > descriptor.segment.limit_scaled) then begin
        BX_PANIC(('jump_protected: IP > limit'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        exit;
        end;

      (* load CS:IP from destination pointer *)
      (* load CS-cache with new segment descriptor *)
      (* set RPL field of CS register to CPL *)
      load_cs(@selector, @descriptor, CPL);
      Self.eip := disp32;
      exit;
      end;
    BX_PANIC(('jump_protected: segment:=1'));
    end

  else begin


    case descriptor.type_ of
      1, // 286 available TSS
      9: // 386 available TSS
      begin
        //if ( descriptor.type=1 )
        //  BX_INFO(('jump to 286 TSS'));
        //else
        //  BX_INFO(('jump to 386 TSS'));

        // TSS DPL must be >= CPL, else #GP(TSS selector)
        if (descriptor.dpl < CPL) then begin
          BX_PANIC(('jump_protected: TSS.dpl < CPL'));
          exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // TSS DPL must be >= TSS selector RPL, else #GP(TSS selector)
        if (descriptor.dpl < selector.rpl) then begin
          BX_PANIC(('jump_protected: TSS.dpl < selector.rpl'));
          exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // descriptor AR byte must specify available TSS,
        //   else #GP(TSS selector) *)
        // this is taken care of by the 'default' case of switch statement *)

        // Task State Seg must be present, else #NP(TSS selector)
        // checked in task_switch()

        // SWITCH_TASKS _without_ nesting to TSS
        task_switch(@selector, @descriptor,
          BX_TASK_FROM_JUMP, dword1, dword2);

        // IP must be in code seg limit, else #GP(0)
        if (EIP > Self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled) then begin
          BX_ERROR(('jump_protected: TSS.p = 0'));
          exception2([BX_GP_EXCEPTION, 0, 0]);
          exit;
          end;
        exit;
      end;

      3: // Busy 286 TSS
        begin
        BX_PANIC(('jump_protected: JUMP to busy 286 TSS unsupported.'));
        exit;
        end;

      4: // 286 call gate
        begin
        BX_ERROR(('jump_protected: JUMP TO 286 CALL GATE:'));

        // descriptor DPL must be >= CPL else #GP(gate selector)
        if (descriptor.dpl < CPL) then begin
          BX_ERROR(('jump_protected: gate.dpl < CPL'));
          exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // descriptor DPL must be >= gate selector RPL else #GP(gate selector)
        if (descriptor.dpl < selector.rpl) then begin
          BX_ERROR(('jump_protected: gate.dpl < selector.rpl'));
          exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // gate must be present else #NP(gate selector)
        if (descriptor.p=0) then begin
          BX_PANIC(('jump_protected: task gate.p = 0'));
          exception2([BX_NP_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // examine selector to code segment given in call gate descriptor
        // selector must not be null, else #GP(0)
        gate_cs_raw := descriptor.gate286.dest_selector;
        if ( (gate_cs_raw  and $fffc) = 0 ) then begin
          BX_PANIC(('jump_protected: CS selector null'));
          exception2([BX_GP_EXCEPTION, $0000, 0]);
          end;
        parse_selector(gate_cs_raw, @gate_cs_selector);

        // selector must be within its descriptor table limits else #GP(CS selector)
        fetch_raw_descriptor(@gate_cs_selector, @dword1, @dword2,
          BX_GP_EXCEPTION);
        parse_descriptor(dword1, dword2, @gate_cs_descriptor);
        // descriptor AR byte must indicate code segment else #GP(CS selector)
        if ( (gate_cs_descriptor.valid=0) or (gate_cs_descriptor.segmentType=0) or
             (gate_cs_descriptor.segment.executable=0) ) then begin
          BX_ERROR(('jump_protected: AR byte: not code segment.'));
          exception2([BX_GP_EXCEPTION, gate_cs_raw  and $fffc, 0]);
          end;

        // if non-conforming, code segment descriptor DPL must := CPL else #GP(CS selector)
        if (gate_cs_descriptor.segment.c_ed=0) then begin
          if (gate_cs_descriptor.dpl <> CPL) then begin
            BX_ERROR(('jump_protected: non-conform: code seg des DPL !:= CPL.'));
            exception2([BX_GP_EXCEPTION, gate_cs_raw  and $fffc, 0]);
            end;
          end
        // if conforming, then code segment descriptor DPL must <= CPL else #GP(CS selector)
        else begin
          if (gate_cs_descriptor.dpl > CPL) then begin
            BX_ERROR(('jump_protected: conform: code seg des DPL > CPL.'));
            exception2([BX_GP_EXCEPTION, gate_cs_raw  and $fffc, 0]);
            end;
          end;

        // code segment must be present else #NP(CS selector)
        if (gate_cs_descriptor.p=0) then begin
          BX_ERROR(('jump_protected: code seg not present.'));
          exception2([BX_NP_EXCEPTION, gate_cs_raw  and $fffc, 0]);
          end;

        // IP must be in code segment limit else #GP(0)
        if ( descriptor.gate286.dest_offset >
             gate_cs_descriptor.segment.limit_scaled ) then begin
          BX_PANIC(('jump_protected: IP > limit'));
          exception2([BX_GP_EXCEPTION, $0000, 0]);
          end;

        // load CS:IP from call gate
        // load CS cache with new code segment
        // set rpl of CS to CPL
        load_cs(@gate_cs_selector, @gate_cs_descriptor, CPL);
        EIP := descriptor.gate286.dest_offset;
        exit;
        end;


      5: // task gate
      begin
//BX_INFO(('jump_pro: task gate'));

        // gate descriptor DPL must be >= CPL else #GP(gate selector)
        if (descriptor.dpl < CPL) then begin
          BX_PANIC(('jump_protected: gate.dpl < CPL'));
          exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // gate descriptor DPL must be >= gate selector RPL
        //   else #GP(gate selector)
        if (descriptor.dpl < selector.rpl) then begin
          BX_PANIC(('jump_protected: gate.dpl < selector.rpl'));
          exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // task gate must be present else #NP(gate selector)
        if (descriptor.p=0) then begin
          BX_PANIC(('jump_protected: task gate.p = 0'));
          exception2([BX_NP_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // examine selector to TSS, given in Task Gate descriptor
        // must specify global in the local/global bit else #GP(TSS selector)

        raw_tss_selector := descriptor.taskgate.tss_selector;
        parse_selector(raw_tss_selector, @tss_selector);
        if (tss_selector.ti)<>0 then begin
          BX_PANIC(('jump_protected: tss_selector.ti:=1'));
          exception2([BX_GP_EXCEPTION, raw_tss_selector  and $fffc, 0]);
          exit;
          end;

        // index must be within GDT limits else #GP(TSS selector)
        fetch_raw_descriptor(@tss_selector, @dword1, @dword2,
          BX_GP_EXCEPTION);

        // descriptor AR byte must specify available TSS
        //   else #GP(TSS selector)
        parse_descriptor(dword1, dword2, @tss_descriptor);
        if (tss_descriptor.valid=0 or tss_descriptor.segmentType) then begin
          BX_ERROR(('jump_protected: TSS selector points to bad TSS'));
          exception2([BX_GP_EXCEPTION, raw_tss_selector  and $fffc, 0]);
          end;
        if ((tss_descriptor.type_<>9) and (tss_descriptor.type_<>1)) then begin
          BX_ERROR(('jump_protected: TSS selector points to bad TSS'));
          exception2([BX_GP_EXCEPTION, raw_tss_selector  and $fffc, 0]);
          end;


        // task state segment must be present, else #NP(tss selector)
        if (tss_descriptor.p=0) then begin
          BX_PANIC(('jump_protected: task descriptor.p = 0'));
          exception2([BX_NP_EXCEPTION, raw_tss_selector  and $fffc, 0]);
          end;

        // SWITCH_TASKS _without_ nesting to TSS
        task_switch(@tss_selector, @tss_descriptor,
                    BX_TASK_FROM_JUMP, dword1, dword2);

        // eIP must be within code segment limit, else #GP(0)
        if (Self.sregs[BX_SEG_REG_CS].cache.segment.d_b)<>0 then
          temp_eIP := EIP
        else
          temp_eIP :=  IP;
        if (temp_eIP > Self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled) then begin
          BX_PANIC(('jump_protected: eIP > cs.limit'));
          exception2([BX_GP_EXCEPTION, $0000, 0]);
          end;

      end;

      11: // Busy 386 TSS
        begin
        BX_PANIC(('jump_protected: JUMP to busy 386 TSS unsupported.'));
        exit;
        end;

      12: // 386 call gate
        begin
        //BX_ERROR(('jump_protected: JUMP TO 386 CALL GATE:'));

        // descriptor DPL must be >= CPL else #GP(gate selector)
        if (descriptor.dpl < CPL) then begin
          BX_PANIC(('jump_protected: gate.dpl < CPL'));
          exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // descriptor DPL must be >= gate selector RPL else #GP(gate selector)
        if (descriptor.dpl < selector.rpl) then begin
          BX_PANIC(('jump_protected: gate.dpl < selector.rpl'));
          exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // gate must be present else #NP(gate selector)
        if (descriptor.p=0) then begin
          BX_PANIC(('jump_protected: task gate.p = 0'));
          exception2([BX_NP_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // examine selector to code segment given in call gate descriptor
        // selector must not be null, else #GP(0)
        gate_cs_raw := descriptor.gate386.dest_selector;
        if ( (gate_cs_raw  and $fffc) = 0 ) then begin
          BX_PANIC(('jump_protected: CS selector null'));
          exception2([BX_GP_EXCEPTION, $0000, 0]);
          end;
        parse_selector(gate_cs_raw, @gate_cs_selector);

        // selector must be within its descriptor table limits else #GP(CS selector)
        fetch_raw_descriptor(@gate_cs_selector, @dword1, @dword2,
          BX_GP_EXCEPTION);
        parse_descriptor(dword1, dword2, @gate_cs_descriptor);
        // descriptor AR byte must indicate code segment else #GP(CS selector)
        if ( (gate_cs_descriptor.valid=0) or
             (gate_cs_descriptor.segmentType=0) or
             (gate_cs_descriptor.segment.executable=0) ) then begin
          BX_PANIC(('jump_protected: AR byte: not code segment.'));
          exception2([BX_GP_EXCEPTION, gate_cs_raw  and $fffc, 0]);
          end;

        // if non-conforming, code segment descriptor DPL must := CPL else #GP(CS selector)
        if (gate_cs_descriptor.segment.c_ed=0) then begin
          if (gate_cs_descriptor.dpl <> CPL) then begin
            BX_PANIC(('jump_protected: non-conform: code seg des DPL !:= CPL.'));
            exception2([BX_GP_EXCEPTION, gate_cs_raw  and $fffc, 0]);
            end;
          end
        // if conforming, then code segment descriptor DPL must <= CPL else #GP(CS selector)
        else begin
          if (gate_cs_descriptor.dpl > CPL) then begin
            BX_PANIC(('jump_protected: conform: code seg des DPL > CPL.'));
            exception2([BX_GP_EXCEPTION, gate_cs_raw  and $fffc, 0]);
            end;
          end;

        // code segment must be present else #NP(CS selector)
        if (gate_cs_descriptor.p=0) then begin
          BX_PANIC(('jump_protected: code seg not present.'));
          exception2([BX_NP_EXCEPTION, gate_cs_raw  and $fffc, 0]);
          end;

        // IP must be in code segment limit else #GP(0)
        if ( descriptor.gate386.dest_offset >
             gate_cs_descriptor.segment.limit_scaled ) then begin
          BX_PANIC(('jump_protected: IP > limit'));
          exception2([BX_GP_EXCEPTION, $0000, 0]);
          end;

        // load CS:IP from call gate
        // load CS cache with new code segment
        // set rpl of CS to CPL
        load_cs(@gate_cs_selector, @gate_cs_descriptor, CPL);
        EIP := descriptor.gate386.dest_offset;
        exit;
        end;

      else
        begin
        BX_ERROR(Format('jump_protected: gate type %u unsupported',
          [descriptor.type_]));
        exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
        exit;
      end;
    end;
    end;
end;
{$ifend} (* if BX_CPU_LEVEL >= 2 *)


{$if BX_CPU_LEVEL >= 2}
procedure BX_CPU_C.call_protected(I:PBxInstruction_tag; cs_raw:Bit16u; disp32:Bit32u);
var
  cs_selector:bx_selector_t;
  dword1, dword2:Bit32u;
  cs_descriptor:bx_descriptor_t;
  temp_ESP:Bit32u;
  gate_descriptor:bx_descriptor_t;
  gate_selector:bx_selector_t;
  new_EIP:Bit32u;
  dest_selector:Bit16u;
  raw_tss_selector:Bit16u;
  tss_selector:bx_selector_t;
  tss_descriptor:bx_descriptor_t;
  temp_eIP:Bit32u;

  SS_for_cpl_x:Bit16u ;
  ESP_for_cpl_x:Bit32u;
  ss_selector:bx_selector_t;
  ss_descriptor:bx_descriptor_t;
  room_needed:unsigned;
  param_count:Bit8u;
  return_SS, return_CS:Bit16u;
  return_ESP, return_EIP:Bit32u;
  return_ss_base:Bit32u;
  parameter_word:array[0..32] of Bit16u;
  parameter_dword:array[0..32] of Bit32u;
  i_:Bit8u;
begin

  (* Opsize in effect for CALL is specified by the D bit for the
   * segment containing dest  and by any opsize prefix.
   * For gate descriptor, deterermined by type of call gate:
   * 4:=16bit, 12:=32bit
   * count field: 16bit specifies #words, 32bit specifies #dwords
   *)

  (* new cs selector must not be null, else #GP(0) *)
  if ( (cs_raw  and $fffc) = 0 ) then begin
    BX_PANIC(('call_protected: CS selector null'));
    exception2([BX_GP_EXCEPTION, 0, 0]);
    end;

  parse_selector(cs_raw, @cs_selector);

  // check new CS selector index within its descriptor limits,
  // else #GP(new CS selector)
  fetch_raw_descriptor(@cs_selector, @dword1, @dword2,
    BX_GP_EXCEPTION);

  parse_descriptor(dword1, dword2, @cs_descriptor);

  // examine AR byte of selected descriptor for various legal values
  if (cs_descriptor.valid=0) then begin
    BX_PANIC(('call_protected: invalid CS descriptor'));
    exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
    end;

  if (cs_descriptor.segmentType)<>0 then begin // normal segment

    if (cs_descriptor.segment.executable=0) then begin
      BX_PANIC(('call_protected: non executable segment'));
      exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
      exit;
      end;

    if (cs_descriptor.segment.c_ed)<>0 then begin // conforming code segment
      // DPL must be <= CPL, else #GP(code seg selector)
      if (cs_descriptor.dpl > CPL) then begin
        BX_PANIC(('call_protected: cs.dpl > CPL'));
        exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
        exit;
        end;
      end
  else begin // non-conforming code segment
      // RPL must be <= CPL, else #GP(code seg selector)
      // DPL must be := CPL, else #GP(code seg selector)
      if ( (cs_selector.rpl > CPL) or
           (cs_descriptor.dpl <> CPL) ) then begin
        BX_PANIC(('call_protected: cs.rpl > CPL'));
        exception2([BX_GP_EXCEPTION, cs_raw  and $fffc, 0]);
        end;
      end;

    // segment must be present, else #NP(code seg selector)
    if (cs_descriptor.p = 0) then begin
      BX_ERROR(('call_protected: cs.p := 0'));
      exception2([BX_NP_EXCEPTION, cs_raw  and $fffc, 0]);
      end;

    if (Self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
      temp_ESP := ESP
    else
      temp_ESP := SP;

    // stack must be big enough for return addr, else #SS(0)
    if (i^.os_32)<>0 then begin
      if ( can_push(@Self.sregs[BX_SEG_REG_SS].cache, temp_ESP, 8)=0 ) then begin
        BX_PANIC(('call_protected: stack doesn''t have room for ret addr'));
        exception2([BX_SS_EXCEPTION, 0, 0]);
        end;

      // IP must be in code seg limit, else #GP(0)
      if (disp32 > cs_descriptor.segment.limit_scaled) then begin
        BX_PANIC(('call_protected: IP not in code seg limit'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        end;

      // push return address onto stack (CS padded to 32bits)
      push_32(Bit32u(Self.sregs[BX_SEG_REG_CS].selector.value));
      push_32(EIP);
      end
  else begin // 16bit opsize
      if ( can_push(@Self.sregs[BX_SEG_REG_SS].cache, temp_ESP, 4)=0 ) then begin
        BX_PANIC(('call_protected: stack doesn''t have room for ret addr'));
        exception2([BX_SS_EXCEPTION, 0, 0]);
        end;

      // IP must be in code seg limit, else #GP(0)
      if (disp32 > cs_descriptor.segment.limit_scaled) then begin
        BX_PANIC(('call_protected: IP not in code seg limit'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        end;

      push_16(Self.sregs[BX_SEG_REG_CS].selector.value);
      push_16(IP);
      end;

    // load code segment descriptor into CS cache
    // load CS with new code segment selector
    // set RPL of CS to CPL
    // load eIP with new offset
    load_cs(@cs_selector, @cs_descriptor, CPL);
    Self.eip := disp32;
    if (cs_descriptor.segment.d_b=0) then
      Self.eip := Self.eip and $0000ffff;
    exit;
    end
  else begin // gate  and special segment

    (* 1 level of indirection via gate, switch gate  and cs *)
    gate_descriptor := cs_descriptor;
    gate_selector   := cs_selector;

    case gate_descriptor.type_ of
      1, // available 16bit TSS
      9: // available 32bit TSS
        //if (gate_descriptor.type=1)
        //  BX_INFO(('call_protected: 16bit available TSS'));
        //else
        //  BX_INFO(('call_protected: 32bit available TSS'));

        // TSS DPL must be >= CPL, else #TS(TSS selector)
        begin
        if (gate_descriptor.dpl < CPL) then begin
          BX_PANIC(('call_protected: TSS.dpl < CPL'));
          exception2([BX_TS_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // TSS DPL must be >= TSS selector RPL, else #TS(TSS selector)
        if (gate_descriptor.dpl < gate_selector.rpl) then begin
          BX_PANIC(('call_protected: TSS.dpl < selector.rpl'));
          exception2([BX_TS_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // descriptor AR byte must specify available TSS,
        //   else #TS(TSS selector) *)
        // this is taken care of by the 'default' case of switch statement *)

        // Task State Seg must be present, else #NP(TSS selector)
        // checked in task_switch()

        // SWITCH_TASKS _without_ nesting to TSS
        task_switch(@gate_selector, @gate_descriptor,
          BX_TASK_FROM_CALL_OR_INT, dword1, dword2);

        // IP must be in code seg limit, else #TS(0)
        if (EIP > Self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled) then begin
          BX_INFO(('call_protected: TSS.p = 0'));
          exception2([BX_TS_EXCEPTION, 0, 0]);
          exit;
          end;
        exit;
        end;

      5: // TASK GATE
        begin
        //BX_INFO(('call_protected: task gate'));
        // gate descriptor DPL must be >= CPL else #TS(gate selector)
        if (gate_descriptor.dpl < CPL) then begin
          BX_PANIC(('call_protected: gate.dpl < CPL'));
          exception2([BX_TS_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // gate descriptor DPL must be >= gate selector RPL
        //   else #TS(gate selector)
        if (gate_descriptor.dpl < gate_selector.rpl) then begin
          BX_PANIC(('call_protected: gate.dpl < selector.rpl'));
          exception2([BX_TS_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // task gate must be present else #NP(gate selector)
        if (gate_descriptor.p=0) then begin
          BX_PANIC(('call_protected: task gate.p = 0'));
          exception2([BX_NP_EXCEPTION, cs_raw  and $fffc, 0]);
          exit;
          end;

        // examine selector to TSS, given in Task Gate descriptor
        // must specify global in the local/global bit else #TS(TSS selector)

        raw_tss_selector := gate_descriptor.taskgate.tss_selector;
        parse_selector(raw_tss_selector, @tss_selector);
        if (tss_selector.ti)<>0 then begin
          BX_PANIC(('call_protected: tss_selector.ti:=1'));
          exception2([BX_TS_EXCEPTION, raw_tss_selector  and $fffc, 0]);
          exit;
          end;

        // index must be within GDT limits else #TS(TSS selector)
        fetch_raw_descriptor(@tss_selector, @dword1, @dword2,
          BX_TS_EXCEPTION);

        // descriptor AR byte must specify available TSS
        //   else #TS(TSS selector)
        parse_descriptor(dword1, dword2, @tss_descriptor);
        if ((tss_descriptor.valid=0) or (tss_descriptor.segmentType<>0)) then begin
          BX_PANIC(('call_protected: TSS selector points to bad TSS'));
          exception2([BX_TS_EXCEPTION, raw_tss_selector  and $fffc, 0]);
          end;
        if ((tss_descriptor.type_<>9) and (tss_descriptor.type_<>1)) then begin
          BX_PANIC(('call_protected: TSS selector points to bad TSS'));
          exception2([BX_TS_EXCEPTION, raw_tss_selector  and $fffc, 0]);
          end;


        // task state segment must be present, else #NP(tss selector)
        if (tss_descriptor.p=0) then begin
          BX_PANIC(('call_protected: task descriptor.p = 0'));
          exception2([BX_NP_EXCEPTION, raw_tss_selector  and $fffc, 0]);
          end;

        // SWITCH_TASKS without nesting to TSS
        task_switch(@tss_selector, @tss_descriptor,
                    BX_TASK_FROM_CALL_OR_INT, dword1, dword2);

        // eIP must be within code segment limit, else #TS(0)
        if (Self.sregs[BX_SEG_REG_CS].cache.segment.d_b)<>0 then
          temp_eIP := EIP
        else
          temp_eIP :=  IP;
        if (temp_eIP > Self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled) then begin
          BX_PANIC(('call_protected: eIP > cs.limit'));
          exception2([BX_TS_EXCEPTION, $0000, 0]);
          end;

        exit;
        end;

      4, // 16bit CALL GATE
      12: // 32bit CALL GATE
//if (gate_descriptor.type=4)
//  BX_INFO(('CALL: 16bit call gate'));
//else
//  BX_INFO(('CALL: 32bit call gate'));

        // call gate DPL must be >= CPL, else #GP(call gate selector)
        // call gate DPL must be >= RPL, else #GP(call gate selector)
        begin
        if ( (gate_descriptor.dpl < CPL) or
             (gate_descriptor.dpl < gate_selector.rpl) ) then begin
          BX_PANIC(('call_protected: DPL < CPL or RPL'));
          exception2([BX_GP_EXCEPTION, gate_selector.value  and $fffc, 0]);
          end;

        // call gate must be present, else #NP(call gate selector)
        if (gate_descriptor.p=0) then begin
          BX_PANIC(('call_protected: not present'));
          exception2([BX_NP_EXCEPTION, gate_selector.value  and $fffc, 0]);
          end;

        // examine code segment selector in call gate descriptor

        if (gate_descriptor.type_=4) then begin
          dest_selector := gate_descriptor.gate286.dest_selector;
          new_EIP := gate_descriptor.gate286.dest_offset;
          end
        else begin
          dest_selector := gate_descriptor.gate386.dest_selector;
          new_EIP := gate_descriptor.gate386.dest_offset;
          end;

        // selector must not be null else #GP(0)
        if ( (dest_selector  and $fffc) = 0 ) then begin
          BX_PANIC(('call_protected: selector in gate null'));
          exception2([BX_GP_EXCEPTION, 0, 0]);
          end;

        parse_selector(dest_selector, @cs_selector);

        // selector must be within its descriptor table limits,
        //   else #GP(code segment selector)
        fetch_raw_descriptor(@cs_selector, @dword1, @dword2,
          BX_GP_EXCEPTION);
        parse_descriptor(dword1, dword2, @cs_descriptor);

        // AR byte of selected descriptor must indicate code segment,
        //   else #GP(code segment selector)
        // DPL of selected descriptor must be <= CPL,
        // else #GP(code segment selector)
        if ((cs_descriptor.valid=0) or (cs_descriptor.segmentType=0) or (cs_descriptor.segment.executable=0) or
            (cs_descriptor.dpl > CPL)) then begin
          BX_PANIC(('call_protected: selected desciptor not code'));
          exception2([BX_GP_EXCEPTION, cs_selector.value  and $fffc, 0]);
          end;

        // CALL GATE TO MORE PRIVILEGE
        // if non-conforming code segment and DPL < CPL then
        // ??? use gate_descriptor.dpl or cs_descriptor.dpl ???
        if ( (cs_descriptor.segment.c_ed=0)  and (cs_descriptor.dpl < CPL) ) then begin


//BX_INFO(('CALL: Call Gate: to more priviliged level'));

          // get new SS selector for new privilege level from TSS
          get_SS_ESP_from_TSS(cs_descriptor.dpl,
                              @SS_for_cpl_x, @ESP_for_cpl_x);

(* ??? use dpl or rpl ??? *)

          // check selector  and descriptor for new SS:
          // selector must not be null, else #TS(0)
          if ( (SS_for_cpl_x  and $fffc) = 0 ) then begin
            BX_PANIC(('call_protected: new SS null'));
            exception2([BX_TS_EXCEPTION, 0, 0]);
            exit;
            end;

          // selector index must be within its descriptor table limits,
          //   else #TS(SS selector)
          parse_selector(SS_for_cpl_x, @ss_selector);
          fetch_raw_descriptor(@ss_selector, @dword1, @dword2,
            BX_TS_EXCEPTION);

          parse_descriptor(dword1, dword2, @ss_descriptor);

          // selector's RPL must equal DPL of code segment,
          //   else #TS(SS selector)
          if (ss_selector.rpl <> cs_descriptor.dpl) then begin
            BX_PANIC(('call_protected: SS selector.rpl !:= CS descr.dpl'));
            exception2([BX_TS_EXCEPTION, SS_for_cpl_x  and $fffc, 0]);
            exit;
            end;

          // stack segment DPL must equal DPL of code segment,
          //   else #TS(SS selector)
          if (ss_descriptor.dpl <> cs_descriptor.dpl) then begin
            BX_PANIC(('call_protected: SS descr.rpl !:= CS descr.dpl'));
            exception2([BX_TS_EXCEPTION, SS_for_cpl_x  and $fffc, 0]);
            exit;
            end;

          // descriptor must indicate writable data segment,
          //   else #TS(SS selector)
          if ((ss_descriptor.valid=0) or (ss_descriptor.segmentType=0) or
              (ss_descriptor.segment.executable<>0) or (ss_descriptor.segment.r_w=0)) then begin
            BX_INFO(('call_protected: ss descriptor not writable data seg'));
            exception2([BX_TS_EXCEPTION, SS_for_cpl_x  and $fffc, 0]);
            exit;
            end;

          // segment must be present, else #SS(SS selector)
          if (ss_descriptor.p=0) then begin
            BX_PANIC(('call_protected: ss descriptor not present.'));
            exception2([BX_SS_EXCEPTION, SS_for_cpl_x  and $fffc, 0]);
            exit;
            end;

          if ( cs_descriptor.segment.d_b )<>0 then
            // new stack must have room for parameters plus 16 bytes
            room_needed := 16
          else
            // new stack must have room for parameters plus 8 bytes
            room_needed :=  8;

          if (gate_descriptor.type_=4) then begin
            // get word count from call gate, mask to 5 bits
            param_count := gate_descriptor.gate286.word_count  and $1f;
            room_needed := room_needed + param_count*2;
            end
          else begin
            // get word count from call gate, mask to 5 bits
            param_count := gate_descriptor.gate386.dword_count  and $1f;
            room_needed := room_needed + param_count*4;
            end;

          // new stack must have room for parameters plus return info
          //   else #SS(SS selector)

          if ( can_push(@ss_descriptor, ESP_for_cpl_x, room_needed)=0 ) then begin
            BX_INFO(('call_protected: stack doesn''t have room'));
            exception2([BX_SS_EXCEPTION, SS_for_cpl_x  and $fffc, 0]);
            exit;
            end;

          // new eIP must be in code segment limit else #GP(0)
          if ( new_EIP > cs_descriptor.segment.limit_scaled ) then begin
            BX_PANIC(('call_protected: IP not within CS limits'));
            exception2([BX_GP_EXCEPTION, 0, 0]);
            exit;
            end;


          // save return SS:eSP to be pushed on new stack
          return_SS := Self.sregs[BX_SEG_REG_SS].selector.value;
          if (Self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
            return_ESP := ESP
          else
            return_ESP :=  SP;
          return_ss_base := Self.sregs[BX_SEG_REG_SS].cache.segment.base;

          // save return CS:eIP to be pushed on new stack
          return_CS := Self.sregs[BX_SEG_REG_CS].selector.value;
          if ( cs_descriptor.segment.d_b )<>0 then
            return_EIP := EIP
          else
            return_EIP :=  IP;


          if (gate_descriptor.type_=4) then begin
            i_:=0;
            while i_ < param_count do // !!! param_count - 1 ??
            begin
              access_linear(return_ss_base + return_ESP + i_*2,
                2, 0, BX_READ, @parameter_word[i_]);
                Inc(i_);
              end;
            end
          else begin
            i_:=0;
            while i_ < param_count do // !!! param_count - 1 ??
              access_linear(return_ss_base + return_ESP + i_*4,
                4, 0, BX_READ, @parameter_dword[i_]);
              Inc(i_);
              end;
            end;

          (* load new SS:SP value from TSS *)
          (* load SS descriptor *)
          load_ss(@ss_selector, @ss_descriptor, ss_descriptor.dpl);
          if (ss_descriptor.segment.d_b)<>0 then
            ESP := ESP_for_cpl_x
          else
            SP :=  Bit16u(ESP_for_cpl_x);

          (* load new CS:IP value from gate *)
          (* load CS descriptor *)
          (* set CPL to stack segment DPL *)
          (* set RPL of CS to CPL *)
          load_cs(@cs_selector, @cs_descriptor, cs_descriptor.dpl);
          EIP := new_EIP;

          // push pointer of old stack onto new stack
          if (gate_descriptor.type_=4) then begin
            push_16(return_SS);
            push_16(Bit16u(return_ESP));
            end
          else begin
            push_32(return_SS);
            push_32(return_ESP);
            end;

          (* get word count from call gate, mask to 5 bits *)
          (* copy parameters from old stack onto new stack *)
          if (Self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
            temp_ESP := ESP
          else
            temp_ESP :=  SP;

          if (gate_descriptor.type_=4) then begin
            i_:=param_count;
            while i_ > 0 do // !!! for i:=param_count-1 downto 0 do ???
              begin
              push_16(parameter_word[i_-1]);
                dec(i_);
              //access_linear(Self.sregs[BX_SEG_REG_SS].cache.u.segment.base + temp_ESP + i*2,
              //  2, 0, BX_WRITE, @parameter_word[i]);
              end;
            end
          else begin
            i_:=param_count;
            while i_ > 0 do // !!! for i:=param_count-1 downto 0 do ???
              begin
              push_32(parameter_dword[i_-1]);
                dec(i_);
              //access_linear(Self.sregs[BX_SEG_REG_SS].cache.u.segment.base + temp_ESP + i*4,
              //  4, 0, BX_WRITE, @parameter_dword[i]);
              end;
            end;

          // push return address onto new stack
          if (gate_descriptor.type_=4) then begin
            push_16(return_CS);
            push_16(Bit16u(return_EIP));
            end
          else begin
            push_32(return_CS);
            push_32(return_EIP);
            end;

          exit;
          end;

        // CALL GATE TO SAME PRIVILEGE
        else begin

//BX_INFO(('CALL: Call Gate: to same priviliged level'));
          if (Self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
            temp_ESP := ESP
          else
            temp_ESP := SP;

          if (gate_descriptor.type_=12) then begin
          //if (i^.os_32) then beginend;
            // stack must room for 8-byte return address (2 are padding)
            //   else #SS(0)
            if ( can_push(@Self.sregs[BX_SEG_REG_SS].cache, temp_ESP, 8)=0 ) then begin
              BX_PANIC(('call_protected: stack doesn''t have room for 8 bytes'));
              exception2([BX_SS_EXCEPTION, 0, 0]);
              end;
            end
          else begin
            // stack must room for 4-byte return address
            //   else #SS(0)
            if ( can_push(@Self.sregs[BX_SEG_REG_SS].cache, temp_ESP, 4)=0 ) then begin
              BX_PANIC(('call_protected: stack doesn''t have room for 4 bytes'));
              exception2([BX_SS_EXCEPTION, 0, 0]);
              end;
            end;

          // EIP must be within code segment limit, else #GP(0)
          if ( new_EIP > cs_descriptor.segment.limit_scaled ) then begin
            BX_PANIC(('call_protected: IP not within code segment limits'));
            exception2([BX_GP_EXCEPTION, 0, 0]);
            end;

          if (gate_descriptor.type_=12) then begin
            // push return address onto stack
            push_32(Self.sregs[BX_SEG_REG_CS].selector.value);
            push_32(EIP);
            end
          else begin
            // push return address onto stack
            push_16(Self.sregs[BX_SEG_REG_CS].selector.value);
            push_16(IP);
            end;

          // load CS:EIP from gate
          // load code segment descriptor into CS register
          // set RPL of CS to CPL
          load_cs(@cs_selector, @cs_descriptor, CPL);
          EIP := new_EIP;

          exit;
          end;

        BX_PANIC(('call_protected: call gate: should not get here'));
        exit;
      end;
      {else
        begin
        BX_PANIC(('call_protected: type := %d',
          (unsigned) cs_descriptor.type));
        exit;
      end;}
    BX_PANIC(('call_protected: gate segment unfinished'));
    end;

  BX_PANIC(('call_protected: shouldn''t get here!'));
  exit;
end;
{$ifend} (* 286+ *)


{$if BX_CPU_LEVEL >= 2}
procedure BX_CPU_C.return_protected(I:PBxInstruction_tag; pop_bytes:Bit16u);
var
  return_SP:Bit16u;
  raw_cs_selector, raw_ss_selector:Bit16u ;
  cs_selector, ss_selector:bx_selector_t;
  cs_descriptor, ss_descriptor:bx_descriptor_t;
  stack_cs_offset, stack_param_offset:Bit32u;
  return_EIP, return_ESP, temp_ESP:Bit32u;
  dword1, dword2:Bit32u;
  Return_IP:Bit16u;
begin

  (* + 6+N*2: SS     or+12+N*4:     SS *)
  (* + 4+N*2: SP     or+ 8+N*4:    ESP *)
  (*          parm N or+        parm N *)
  (*          parm 3 or+        parm 3 *)
  (*          parm 2 or+        parm 2 *)
  (*          parm 1 or+ 8:     parm 1 *)
  (* + 2:     CS     or+ 4:         CS *)
  (* + 0:     IP     or+ 0:        EIP *)

{$if BX_CPU_LEVEL >= 3}
  if ( i^.os_32 )<>0 then begin
    (* operand size:=32: third word on stack must be within stack limits,
     *   else #SS(0); *)
    if (can_pop(6)=0) then begin
      BX_PANIC(('return_protected: 3rd word not in stack limits'));
      (* #SS(0) *)
      exit;
      end;
    stack_cs_offset := 4;
    stack_param_offset := 8;
    end
  else
{$ifend}
    begin
    (* operand size:=16: second word on stack must be within stack limits,
     *   else #SS(0);
     *)
    if ( can_pop(4)=0) then begin
      BX_PANIC(('return_protected: 2nd word not in stack limits'));
      (* #SS(0) *)
      exit;
      end;
    stack_cs_offset := 2;
    stack_param_offset := 4;
    end;

  if (Self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
  temp_ESP := ESP
  else
  temp_ESP := SP;

  // return selector RPL must be >= CPL, else #GP(return selector)
  access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP +
                       stack_cs_offset, 2, Bool(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_READ, @raw_cs_selector);
  parse_selector(raw_cs_selector, @cs_selector);
  if ( cs_selector.rpl < CPL ) then begin
    BX_ERROR(('return_protected: CS.rpl < CPL'));
    BX_ERROR(Format('  CS.rpl:=%u CPL:=%u', [cs_selector.rpl, CPL]));
    exception2([BX_GP_EXCEPTION, raw_cs_selector  and $fffc, 0]);
    exit;
    end;

  // if return selector RPL = CPL then
  // RETURN TO SAME LEVEL
  if ( cs_selector.rpl = CPL ) then begin
    //BX_INFO(('return: to same level %04x:%08x',
    //   Self.sregs[BX_SEG_REG_CS].selector.value,
    //   Self.prev_eip));
    // return selector must be non-null, else #GP(0)
    if ( (raw_cs_selector  and $fffc) = 0 ) then begin
      BX_PANIC(('return_protected: CS null'));
      (* #GP(0) *)
      exit;
      end;

    // selector index must be within its descriptor table limits,
    // else #GP(selector)
    fetch_raw_descriptor(@cs_selector, @dword1, @dword2,
      BX_GP_EXCEPTION);

    // descriptor AR byte must indicate code segment, else #GP(selector)
    parse_descriptor(dword1, dword2, @cs_descriptor);
    if ((cs_descriptor.valid=0) or (cs_descriptor.segmentType=0) or (cs_descriptor.segment.executable=0)) then begin
      BX_INFO(('return_protected: same: AR byte not code'));
      exception2([BX_GP_EXCEPTION, raw_cs_selector  and $fffc, 0]);
      end;

    // if non-conforming then code segment DPL must := CPL,
    // else #GP(selector)
    if ((cs_descriptor.segment.c_ed=0) and (cs_descriptor.dpl<>CPL)) then begin
      BX_PANIC(('return_protected: non-conforming, DPL!:=CPL'));
      (* #GP(selector) *)
      exit;
      end;

    // if conforming then code segment DPL must be <= CPL,
    // else #GP(selector)
    if ((cs_descriptor.segment.c_ed <> 0) and (cs_descriptor.dpl>CPL)) then begin
      BX_INFO(('return_protected: conforming, DPL>CPL'));
      exception2([BX_GP_EXCEPTION, raw_cs_selector  and $fffc, 0]);
      end;

    // code segment must be present, else #NP(selector)
    if (cs_descriptor.p=0) then begin
      BX_ERROR(('return_protected: not present'));
      exception2([BX_NP_EXCEPTION, raw_cs_selector  and $fffc, 0]);
      exit;
      end;

    // top word on stack must be within stack limits, else #SS(0)
    if ( can_pop(stack_param_offset + pop_bytes)=0) then begin
      BX_PANIC(('return_protected: top word not in stack limits'));
      (* #SS(0) *)
      exit;
      end;

    // eIP must be in code segment limit, else #GP(0)
{$if BX_CPU_LEVEL >= 3}
    if (i^.os_32)<>0 then begin
      access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 0,
        4, Bool(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_READ, @return_EIP);
      end
  else
{$ifend}
      begin
      access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 0,
        2, Bool(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_READ, @return_IP);
      return_EIP := return_IP;
      end;

    if ( return_EIP > cs_descriptor.segment.limit_scaled ) then begin
      BX_PANIC(('return_protected: return IP > CS.limit'));
      (* #GP(0) *)
      exit;
      end;

    // load CS:eIP from stack
    // load CS register with descriptor
    // increment eSP
    load_cs(@cs_selector, @cs_descriptor, CPL);
    Self.eip := return_EIP;
    if (Self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
      ESP := ESP + stack_param_offset + pop_bytes
    else
      SP := SP + stack_param_offset + pop_bytes;

    exit;
    end

  (* RETURN TO OUTER PRIVILEGE LEVEL *)
  else begin
    (* + 6+N*2: SS     or+12+N*4:     SS *)
    (* + 4+N*2: SP     or+ 8+N*4:    ESP *)
    (*          parm N or+        parm N *)
    (*          parm 3 or+        parm 3 *)
    (*          parm 2 or+        parm 2 *)
    (*          parm 1 or+ 8:     parm 1 *)
    (* + 2:     CS     or+ 4:         CS *)
    (* + 0:     IP     or+ 0:        EIP *)

//BX_INFO(('return: to outer level %04x:%08x',
//  Self.sregs[BX_SEG_REG_CS].selector.value,
//  Self.prev_eip));

    if (i^.os_32)<>0 then begin
      (* top 16+immediate bytes on stack must be within stack limits, else #SS(0) *)
      if ( can_pop(16 + pop_bytes)=0) then begin
        BX_PANIC(('return_protected: 8 bytes not within stack limits'));
        (* #SS(0) *)
        exit;
        end;
      end
  else begin
      (* top 8+immediate bytes on stack must be within stack limits, else #SS(0) *)
      if ( can_pop(8 + pop_bytes)=0) then begin
        BX_PANIC(('return_protected: 8 bytes not within stack limits'));
        (* #SS(0) *)
        exit;
        end;
      end;

    (* examine return CS selector and associated descriptor *)

    (* selector must be non-null else #GP(0) *)
    if ( (raw_cs_selector  and $fffc) = 0 ) then begin
      BX_PANIC(('return_protected: CS selector null'));
      (* #GP(0) *)
      exit;
      end;

    (* selector index must be within its descriptor table limits,
     * else #GP(selector) *)
    fetch_raw_descriptor(@cs_selector, @dword1, @dword2,
      BX_GP_EXCEPTION);
    parse_descriptor(dword1, dword2, @cs_descriptor);

    (* descriptor AR byte must indicate code segment else #GP(selector) *)
    if ((cs_descriptor.valid=0) or (cs_descriptor.segmentType=0) or (cs_descriptor.segment.executable=0)) then begin
      BX_PANIC(('return_protected: AR byte not code'));
      (* #GP(selector) *)
      exit;
      end;

    (* if non-conforming code then code seg DPL must equal return selector RPL
     * else #GP(selector) *)
    if ((cs_descriptor.segment.c_ed=0) and (cs_descriptor.dpl<>cs_selector.rpl)) then begin
      BX_PANIC(('return_protected: non-conforming seg DPL !:= selector.rpl'));
      (* #GP(selector) *)
      exit;
      end;

    (* if conforming then code segment DPL must be <= return selector RPL
     * else #GP(selector) *)
    if ((cs_descriptor.segment.c_ed <>0) and (cs_descriptor.dpl>cs_selector.rpl)) then begin
      BX_PANIC(('return_protected: conforming seg DPL > selector.rpl'));
      (* #GP(selector) *)
      exit;
      end;

    (* segment must be present else #NP(selector) *)
    if (cs_descriptor.p=0) then begin
      BX_PANIC(('return_protected: segment not present'));
      (* #NP(selector) *)
      exit;
      end;

    (* examine return SS selector and associated descriptor: *)
    if (i^.os_32)<>0 then begin
      access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 12 + pop_bytes,
        2, 0, BX_READ, @raw_ss_selector);
      access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 8 + pop_bytes,
        4, 0, BX_READ, @return_ESP);
      access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 0,
        4, 0, BX_READ, @return_EIP);
      end
  else begin

      access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 6 + pop_bytes,
        2, 0, BX_READ, @raw_ss_selector);
      access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 4 + pop_bytes,
        2, 0, BX_READ, @return_SP);
      return_ESP := return_SP;
      access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 0,
        2, 0, BX_READ, @return_IP);
      return_EIP := return_IP;
      end;

    (* selector must be non-null else #GP(0) *)
    if ( (raw_ss_selector  and $fffc) = 0 ) then begin
      BX_PANIC(('return_protected: SS selector null'));
      (* #GP(0) *)
      exit;
      end;

    (* selector index must be within its descriptor table limits,
     * else #GP(selector) *)
    parse_selector(raw_ss_selector, @ss_selector);
    fetch_raw_descriptor(@ss_selector, @dword1, @dword2,
      BX_GP_EXCEPTION);
    parse_descriptor(dword1, dword2, @ss_descriptor);

    (* selector RPL must := RPL of the return CS selector,
     * else #GP(selector) *)
    if (ss_selector.rpl <> cs_selector.rpl) then begin
      BX_INFO(('return_protected: ss.rpl !:= cs.rpl'));
      exception2([BX_GP_EXCEPTION, raw_ss_selector  and $fffc, 0]);
      exit;
      end;

    (* descriptor AR byte must indicate a writable data segment,
     * else #GP(selector) *)
    if ((ss_descriptor.valid=0) or (ss_descriptor.segmentType=0) or (ss_descriptor.segment.executable<>0) or
        (ss_descriptor.segment.r_w=0)) then begin
      BX_PANIC(('return_protected: SS.AR byte not writable data'));
      (* #GP(selector) *)
      exit;
      end;

    (* descriptor dpl must := RPL of the return CS selector,
     * else #GP(selector) *)
    if (ss_descriptor.dpl <> cs_selector.rpl) then begin
      BX_PANIC(('return_protected: SS.dpl !:= cs.rpl'));
      (* #GP(selector) *)
      exit;
      end;

    (* segment must be present else #SS(selector) *)
    if (ss_descriptor.p=0) then begin
      BX_PANIC(('ss.p = 0'));
      (* #NP(selector) *)
      exit;
      end;

    (* eIP must be in code segment limit, else #GP(0) *)
    if (return_EIP > cs_descriptor.segment.limit_scaled) then begin
      BX_PANIC(('return_protected: eIP > cs.limit'));
      (* #GP(0) *)
      exit;
      end;

    (* set CPL to RPL of return CS selector *)
    (* load CS:IP from stack *)
    (* set CS RPL to CPL *)
    (* load the CS-cache with return CS descriptor *)
    load_cs(@cs_selector, @cs_descriptor, cs_selector.rpl);
    Self.eip := return_EIP;

    (* load SS:SP from stack *)
    (* load SS-cache with return SS descriptor *)
    load_ss(@ss_selector, @ss_descriptor, cs_selector.rpl);
    if (ss_descriptor.segment.d_b)<>0 then
      ESP := return_ESP + pop_bytes
    else
      SP  := Bit16u(return_ESP + pop_bytes);

    (* check ES, DS, FS, GS for validity *)
    validate_seg_regs();

    exit;
    end;

  exit;
end;
{$ifend}

{$if BX_CPU_LEVEL >= 2}
procedure BX_CPU_C.iret_protected(I:PBxInstruction_tag);
var
  raw_cs_selector, raw_ss_selector:Bit16u;
  cs_selector, ss_selector:bx_selector_t;
  dword1, dword2:Bit32u;
  cs_descriptor, ss_descriptor:bx_descriptor_t;
  base32:Bit32u;
  raw_link_selector:Bit16u;
  link_selector:bx_selector_t;
  tss_descriptor:bx_descriptor_t;

  top_nbytes_same, top_nbytes_outer:Bit16u;
  cs_offset, ss_offset:Bit32u;
  new_eip, new_esp, temp_ESP, new_eflags:Bit32u;
  new_ip, new_sp, new_flags:Bit16u;
  prev_cpl:Bit8u;
begin

  if (Self.eflags.nt)<>0 then begin (* NT := 1: RETURN FROM NESTED TASK *)
    (* what's the deal with NT  and VM ? *)

    if (Self.eflags.vm)<>0 then
      BX_PANIC(('IRET: vm set?'));

    // TASK_RETURN:

    //BX_INFO(('IRET: nested task return'));

    if (Self.tr.cache.valid=0) then
      BX_PANIC(('IRET: TR not valid'));
    if (Self.tr.cache.type_ = 1) then
      base32 := Self.tr.cache.tss286.base
    else if (Self.tr.cache.type_ = 9) then
      base32 := Self.tr.cache.tss386.base
    else begin
      BX_PANIC(('IRET: TR not valid'));
      base32 := 0; // keep compiler happy
      end;

    // examine back link selector in TSS addressed by current TR:
    access_linear(base32 + 0, 2, 0, BX_READ, @raw_link_selector);

    // must specify global, else #TS(new TSS selector)
    parse_selector(raw_link_selector, @link_selector);
    if (link_selector.ti)<>0 then begin
      BX_PANIC(('iret: link selector.ti:=1'));
      exception2([BX_TS_EXCEPTION, raw_link_selector  and $fffc, 0]);
      end;

    // index must be within GDT limits, else #TS(new TSS selector)
    fetch_raw_descriptor(@link_selector, @dword1, @dword2, BX_TS_EXCEPTION);

    // AR byte must specify TSS, else #TS(new TSS selector)
    // new TSS must be busy, else #TS(new TSS selector)
    parse_descriptor(dword1, dword2, @tss_descriptor);
    if ((tss_descriptor.valid=0) or (tss_descriptor.segmentType<>0)) then begin
      BX_INFO(('iret: TSS selector points to bad TSS'));
      exception2([BX_TS_EXCEPTION, raw_link_selector  and $fffc, 0]);
      end;
    if ((tss_descriptor.type_<>11) and (tss_descriptor.type_<>3)) then begin
      BX_INFO(('iret: TSS selector points to bad TSS'));
      exception2([BX_TS_EXCEPTION, raw_link_selector  and $fffc, 0]);
      end;


    // TSS must be present, else #NP(new TSS selector)
    if (tss_descriptor.p=0) then begin
      BX_INFO(('iret: task descriptor.p = 0'));
      exception2([BX_NP_EXCEPTION, raw_link_selector  and $fffc, 0]);
      end;

    // switch tasks (without nesting) to TSS specified by back link selector
    task_switch(@link_selector, @tss_descriptor,
                BX_TASK_FROM_IRET, dword1, dword2);

    // mark the task just abandoned as not busy

    // eIP must be within code seg limit, else #GP(0)
    if (EIP > Self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled) then begin
      BX_PANIC(('iret: eIP > cs.limit'));
      exception2([BX_GP_EXCEPTION, $0000, 0]);
      end;
    exit;
    end

  else begin (* NT := 0: INTERRUPT RETURN ON STACK -or STACK_RETURN_TO_V86 *)

    (* 16bit opsize or  32bit opsize
     * ===============
     * SS     eSP+8 or  SS     eSP+16
     * SP     eSP+6 or  ESP    eSP+12
     * -------------------------------
     * FLAGS  eSP+4 or  EFLAGS eSP+8
     * CS     eSP+2 or  CS     eSP+4
     * IP     eSP+0 or  EIP    eSP+0
     *)

    if (i^.os_32)<>0 then begin
      top_nbytes_same    := 12;
      top_nbytes_outer   := 20;
      cs_offset := 4;
      ss_offset := 16;
      end
  else begin
      top_nbytes_same    := 6;
      top_nbytes_outer   := 10;
      cs_offset := 2;
      ss_offset := 8;
      end;

    (* CS on stack must be within stack limits, else #SS(0) *)
    if ( can_pop(top_nbytes_same)=0) then begin
      BX_PANIC(('iret: CS not within stack limits'));
      exception2([BX_SS_EXCEPTION, 0, 0]);
      exit;
      end;

    if (Self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
      temp_ESP := ESP
    else
      temp_ESP := SP;

    access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + cs_offset,
      2, Bool(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_READ, @raw_cs_selector);

    if (i^.os_32)<>0 then begin
      access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 0,
        4, Bool(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_READ, @new_eip);
      access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 8,
        4, Bool(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_READ, @new_eflags);

      // if VM:=1 in flags image on stack then STACK_RETURN_TO_V86
      if (new_eflags  and $00020000)<>0 then begin
        if (CPL <> 0) then
          BX_PANIC(('iret: VM set on stack, CPL!:=0'));
        Self.stack_return_to_v86(new_eip, raw_cs_selector, new_eflags);
        exit;
        end;
      end
  else begin
      access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 0,
        2, Bool(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_READ, @new_ip);
      access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 4,
        2, Bool(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_READ, @new_flags);
      end;

    parse_selector(raw_cs_selector, @cs_selector);

    // return CS selector must be non-null, else #GP(0)
    if ( (raw_cs_selector  and $fffc) = 0 ) then begin
      BX_PANIC(('iret: return CS selector null'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      exit;
      end;

    // selector index must be within descriptor table limits,
    // else #GP(return selector)
    fetch_raw_descriptor(@cs_selector, @dword1, @dword2,
      BX_GP_EXCEPTION);

    parse_descriptor(dword1, dword2, @cs_descriptor);

    // AR byte must indicate code segment else #GP(return selector)
    if ( (cs_descriptor.valid=0) or (cs_descriptor.segmentType=0) or (cs_descriptor.segment.executable=0)) then begin
      BX_PANIC(('iret: AR byte indicated non code segment'));
      exception2([BX_GP_EXCEPTION, raw_cs_selector  and $fffc, 0]);
      exit;
      end;

    // return CS selector RPL must be >= CPL, else #GP(return selector)
    if (cs_selector.rpl < CPL) then begin
      BX_PANIC(('iret: return selector RPL < CPL'));
      exception2([BX_GP_EXCEPTION, raw_cs_selector  and $fffc, 0]);
      exit;
      end;

    // if return code seg descriptor is conforming
    //   and return code seg DPL > return code seg selector RPL
    //     then #GP(return selector)
    if ((cs_descriptor.segment.c_ed<>0) and (cs_descriptor.dpl > cs_selector.rpl)) then begin
      BX_PANIC(('iret: conforming, DPL > cs_selector.RPL'));
      exception2([BX_GP_EXCEPTION, raw_cs_selector  and $fffc, 0]);
      exit;
      end;

    // if return code seg descriptor is non-conforming
    //   and return code seg DPL !:= return code seg selector RPL
    //     then #GP(return selector)
    if ((cs_descriptor.segment.c_ed=0) and (cs_descriptor.dpl <> cs_selector.rpl)) then begin
      BX_INFO(('(mch) iret: Return with DPL !:= RPL. #GP(selector)'));
      exception2([BX_GP_EXCEPTION, raw_cs_selector  and $fffc, 0]);
      exit;
      end;

    // segment must be present else #NP(return selector)
    if ( cs_descriptor.p=0 ) then begin
      BX_PANIC(('iret: not present'));
      exception2([BX_NP_EXCEPTION, raw_cs_selector  and $fffc, 0]);
      exit;
      end;

    if (cs_selector.rpl = CPL) then begin (* INTERRUPT RETURN TO SAME LEVEL *)
      (* top 6/12 bytes on stack must be within limits, else #SS(0) *)
      (* satisfied above *)

      if (i^.os_32)<>0 then begin
        (* return EIP must be in code segment limit else #GP(0) *)
        if ( new_eip > cs_descriptor.segment.limit_scaled ) then begin
          BX_PANIC(('iret: IP > descriptor limit'));
          exception2([BX_GP_EXCEPTION, 0, 0]);
          exit;
          end;
        (* load CS:EIP from stack *)
        (* load CS-cache with new code segment descriptor *)
        load_cs(@cs_selector, @cs_descriptor, CPL);
        EIP := new_eip;

        (* load EFLAGS with 3rd doubleword from stack *)
        write_eflags(new_eflags, Bool(CPL=0), Bool(CPL<=IOPL), 0, 1);
        end
      else begin
        (* return IP must be in code segment limit else #GP(0) *)
        if ( new_ip > cs_descriptor.segment.limit_scaled ) then begin
          BX_PANIC(('iret: IP > descriptor limit'));
          exception2([BX_GP_EXCEPTION, 0, 0]);
          exit;
          end;
        (* load CS:IP from stack *)
        (* load CS-cache with new code segment descriptor *)
        load_cs(@cs_selector, @cs_descriptor, CPL);
        EIP := new_ip;

        (* load flags with third word on stack *)
        write_flags(new_flags, Bool(CPL=0), Bool(CPL<=IOPL));
        end;

      (* increment stack by 6/12 *)
      if (Self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
        ESP := ESP + top_nbytes_same
      else
        SP := SP + top_nbytes_same;
      exit;
      end
  else begin (* INTERRUPT RETURN TO OUTER PRIVILEGE LEVEL *)
      (* 16bit opsize or  32bit opsize
       * ===============
       * SS     eSP+8 or  SS     eSP+16
       * SP     eSP+6 or  ESP    eSP+12
       * FLAGS  eSP+4 or  EFLAGS eSP+8
       * CS     eSP+2 or  CS     eSP+4
       * IP     eSP+0 or  EIP    eSP+0
       *)

      (* top 10/20 bytes on stack must be within limits else #SS(0) *)
      if ( can_pop(top_nbytes_outer)=0) then begin
        BX_PANIC(('iret: top 10/20 bytes not within stack limits'));
        exception2([BX_SS_EXCEPTION, 0, 0]);
        exit;
        end;

      (* examine return SS selector and associated descriptor *)
      access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + ss_offset,
        2, 0, BX_READ, @raw_ss_selector);

      (* selector must be non-null, else #GP(0) *)
      if ( (raw_ss_selector  and $fffc) = 0 ) then begin
        BX_PANIC(('iret: SS selector null'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        exit;
        end;

      parse_selector(raw_ss_selector, @ss_selector);

      (* selector RPL must := RPL of return CS selector,
       * else #GP(SS selector) *)
      if ( ss_selector.rpl <> cs_selector.rpl) then begin
        BX_PANIC(('iret: SS.rpl !:= CS.rpl'));
        exception2([BX_GP_EXCEPTION, raw_ss_selector  and $fffc, 0]);
        exit;
        end;

      (* selector index must be within its descriptor table limits,
       * else #GP(SS selector) *)
      fetch_raw_descriptor(@ss_selector, @dword1, @dword2,
        BX_GP_EXCEPTION);

      parse_descriptor(dword1, dword2, @ss_descriptor);

      (* AR byte must indicate a writable data segment,
       * else #GP(SS selector) *)
      if ((ss_descriptor.valid=0) or (ss_descriptor.segmentType=0) or (ss_descriptor.segment.executable<>0) or
           (ss_descriptor.segment.r_w=0)) then begin
        BX_PANIC(('iret: SS AR byte not writable code segment'));
        exception2([BX_GP_EXCEPTION, raw_ss_selector  and $fffc, 0]);
        exit;
        end;

      (* stack segment DPL must equal the RPL of the return CS selector,
       * else #GP(SS selector) *)
      if ( ss_descriptor.dpl <> cs_selector.rpl ) then begin
        BX_PANIC(('iret: SS.dpl !:= CS selector RPL'));
        exception2([BX_GP_EXCEPTION, raw_ss_selector  and $fffc, 0]);
        exit;
        end;

      (* SS must be present, else #NP(SS selector) *)
      if ( ss_descriptor.p=0 ) then begin
        BX_PANIC(('iret: SS not present!'));
        exception2([BX_NP_EXCEPTION, raw_ss_selector  and $fffc, 0]);
        exit;
        end;


      if (i^.os_32)<>0 then begin
        access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 0,
          4, 0, BX_READ, @new_eip);
        access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 8,
          4, 0, BX_READ, @new_eflags);
        access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 12,
          4, 0, BX_READ, @new_esp);
        end
      else begin
        access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 0,
          2, 0, BX_READ, @new_ip);
        access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 4,
          2, 0, BX_READ, @new_flags);
        access_linear(Self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 6,
          2, 0, BX_READ, @new_sp);
        new_eip := new_ip;
        new_esp := new_sp;
        new_eflags := new_flags;
        end;

      (* EIP must be in code segment limit, else #GP(0) *)
      if ( new_eip > cs_descriptor.segment.limit_scaled ) then begin
        BX_PANIC(('iret: IP > descriptor limit'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        exit;
        end;

      (* load CS:EIP from stack *)
      (* load the CS-cache with CS descriptor *)
      (* set CPL to the RPL of the return CS selector *)
      prev_cpl := CPL; (* previous CPL *)
      load_cs(@cs_selector, @cs_descriptor, cs_selector.rpl);
      Self.eip := new_eip;

      (* load flags from stack *)
      // perhaps I should always write_eflags(), thus zeroing
      // out the upper 16bits of eflags for CS.D_B=0 ???
      if (cs_descriptor.segment.d_b)<>0 then
        write_eflags(new_eflags, Bool(prev_cpl=0), Bool(prev_cpl<=IOPL), 0, 1)
      else
        write_flags(Bit16u(new_eflags), Bool(prev_cpl=0), Bool(prev_cpl<=IOPL));

      // load SS:eSP from stack
      // load the SS-cache with SS descriptor
      load_ss(@ss_selector, @ss_descriptor, cs_selector.rpl);
      if (ss_descriptor.segment.d_b)<>0 then
        ESP := new_esp
      else
        SP  := new_esp;

      validate_seg_regs();

      exit;
      end;
    end;
  BX_PANIC(('IRET: shouldn''t get here!'));
end;
{$ifend}


{$if BX_CPU_LEVEL >= 2}
procedure BX_CPU_C.validate_seg_regs;
begin
  if ( Self.sregs[BX_SEG_REG_ES].cache.dpl<CPL ) then begin
    Self.sregs[BX_SEG_REG_ES].cache.valid := 0;
    Self.sregs[BX_SEG_REG_ES].selector.value := 0;
    end;
  if ( Self.sregs[BX_SEG_REG_DS].cache.dpl<CPL ) then begin
    Self.sregs[BX_SEG_REG_DS].cache.valid := 0;
    Self.sregs[BX_SEG_REG_DS].selector.value := 0;
    end;
  if ( Self.sregs[BX_SEG_REG_FS].cache.dpl<CPL ) then begin
    Self.sregs[BX_SEG_REG_FS].cache.valid := 0;
    Self.sregs[BX_SEG_REG_FS].selector.value := 0;
    end;
  if ( Self.sregs[BX_SEG_REG_GS].cache.dpl<CPL ) then begin
    Self.sregs[BX_SEG_REG_GS].cache.valid := 0;
    Self.sregs[BX_SEG_REG_GS].selector.value := 0;
    end;
end;
{$ifend}

