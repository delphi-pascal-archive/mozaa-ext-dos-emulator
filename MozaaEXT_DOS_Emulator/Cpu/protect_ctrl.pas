{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
procedure BX_CPU_C.ARPL_EwGw(I:PBxInstruction_tag);
var
  op2_16, op1_16:Bit16u;
  op1_32:Bit32u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('ARPL_EwRw: not supported on 8086!'));
{$else} (* 286+ *)

  if Boolean(Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0))) then begin
    (* op1_16 is a register or memory reference *)
    if Boolean(i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    if Boolean( (op1_16  and $03) < (op2_16  and $03) ) then begin
      op1_16 := (op1_16  and $fffc)or(op2_16  and $03);
      (* now write back to destination *)
      if Boolean(i^.mod_ = $c0) then begin
        if Boolean(i^.os_32) then begin
          // if 32bit opsize, then $ff3f is or'd into
          // upper 16bits of register

          op1_32 := BX_READ_32BIT_REG(i^.rm);
          op1_32 := (op1_32 and $ffff0000) or op1_16;
          op1_32 := op1_32 or $ff3f0000;
          BX_WRITE_32BIT_REG(i^.rm, op1_32);
          end
        else begin
          BX_WRITE_16BIT_REG(i^.rm, op1_16);
          end;
        end
      else begin
        write_RMW_virtual_word(op1_16);
        end;
      set_ZF(1);
      end
  else begin
      set_ZF(0);
      end;
    end
  else begin
    // ARPL not recognized in real or v8086 mod_e
    UndefinedOpcode(i);
    exit;
    end;
{$ifend}
end;

procedure BX_CPU_C.LAR_GvEw(I:PBxInstruction_tag);
var
  raw_selector:Bit16u;
  descriptor:bx_descriptor_t;
  selector:bx_selector_t;
  dword1, dword2:Bit32u;
begin
  (* for 16 bit operand size mod_e *)

  if Boolean(v8086_mode()) then BX_PANIC(('protect_ctrl: v8086 mod_e unsupported'));

  if Boolean(real_mode()) then begin
    BX_PANIC(('LAR_GvEw: not recognized in real mod_e'));
    UndefinedOpcode(i);
    exit;
    end;


  if Boolean(i^.mod_ = $c0) then begin
    raw_selector := BX_READ_16BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_word(i^.seg, i^.rm_addr, @raw_selector);
    end;

  (* if selector null, clear ZF and done *)
  if Boolean( (raw_selector  and $fffc) = 0 ) then begin
    set_ZF(0);
    exit;
    end;

  parse_selector(raw_selector, @selector);

  if Boolean( fetch_raw_descriptor2(@selector, @dword1, @dword2)=0) then begin
    (* not within descriptor table *)
    set_ZF(0);
    exit;
    end;

  parse_descriptor(dword1, dword2, @descriptor);

  if Boolean(descriptor.valid=0) then begin
    set_ZF(0);
    //BX_DEBUG(('lar(): descriptor valid bit cleared'));
    exit;
    end;

  (* if source selector is visible at CPL  and RPL,
   * within the descriptor table, and of type accepted by LAR instruction,
   * then load register with segment limit and set ZF
   *)

  if Boolean( descriptor.segmentType ) then begin (* normal segment *)
    if Boolean( descriptor.segment.executable and descriptor.segment.c_ed ) then begin
      (* ignore DPL for conforming segments *)
      end
  else begin
      if Boolean( (descriptor.dpl<CPL) or (descriptor.dpl<selector.rpl) ) then begin
        set_ZF(0);
        exit;
        end;
      end;
    set_ZF(1);
    if Boolean(i^.os_32) then begin
      (* masked by 00FxFF00, where x is undefined *)
      BX_WRITE_32BIT_REG(i^.nnn, dword2  and $00ffff00);
      end
  else begin
      BX_WRITE_16BIT_REG(i^.nnn, dword2  and $ff00);
      end;
    exit;
    end
  else begin (* system or gate segment *)
    case ( descriptor.type_ ) of
      1, (* available TSS *)
      2, (* LDT *)
      3, (* busy TSS *)
      4, (* 286 call gate *)
      5, (* task gate *)
{$if BX_CPU_LEVEL >= 3}
      9,  (* available 32bit TSS *)
      11, (* busy 32bit TSS *)
      12: (* 32bit call gate *)
{$ifend}
        begin
        end;
      else (* rest not accepted types to LAR *)
        begin
          set_ZF(0);
          BX_DEBUG(('lar(): not accepted type'));
          exit;
        end;
      end;

    if Boolean( (descriptor.dpl<CPL) or (descriptor.dpl<selector.rpl) ) then begin
      set_ZF(0);
      exit;
      end;
    set_ZF(1);
    if Boolean(i^.os_32) then begin
      (* masked by 00FxFF00, where x is undefined ??? *)
      BX_WRITE_32BIT_REG(i^.nnn, dword2  and $00ffff00);
      end
  else begin
      BX_WRITE_16BIT_REG(i^.nnn, dword2  and $ff00);
      end;
    exit;
    end;
end;

procedure BX_CPU_C.LSL_GvEw(I:PBxInstruction_tag);
var
  raw_selector:Bit16u;
  limit32:Bit32u;
  selector:bx_selector_t;
  dword1, dword2:Bit32u;
  descriptor_dpl:Bit32u;
  type_:Bit32u;
  label lsl_ok;
begin
  (* for 16 bit operand size mod_e *)
  //bx_descriptor_t descriptor;

  if Boolean(v8086_mode()) then BX_PANIC(('protect_ctrl: v8086 mod_e unsupported'));

  if Boolean(real_mode()) then begin
    BX_PANIC(('LSL_GvEw: not recognized in real mod_e'));
    UndefinedOpcode(i);
    exit;
    end;

  if Boolean(i^.mod_ = $c0) then begin
    raw_selector := BX_READ_16BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_word(i^.seg, i^.rm_addr, @raw_selector);
    end;


  (* if selector null, clear ZF and done *)
  if Boolean( (raw_selector  and $fffc) = 0 ) then begin
    set_ZF(0);
    exit;
    end;

  parse_selector(raw_selector, @selector);

  if Boolean( fetch_raw_descriptor2(@selector, @dword1, @dword2)=0) then begin
    (* not within descriptor table *)
    set_ZF(0);
    exit;
    end;

  //parse_descriptor(dword1, dword2, @descriptor);

  descriptor_dpl := (dword2 shr 13)  and $03;

  if Boolean( (dword2  and $00001000) = 0 ) then begin // system segment

    type_ := (dword2 shr 8)  and $0000000f;
    case (type_) of
      1, // 16bit TSS
      3, // 16bit TSS
      2, // LDT
      9, // 32bit TSS    G00A
      11:// 32bit TSS    G00A
        begin
          limit32 := (dword1 and $0000ffff) or (dword2 and $000f0000);
          if Boolean( Bool(dword2 and $00800000) ) then
            limit32 := (limit32 shl 12) or $00000fff;
          if Boolean( (descriptor_dpl<CPL) or (descriptor_dpl<selector.rpl) ) then begin
            set_ZF(0);
            exit;
          end;
          goto lsl_ok;
        end;
      else
        begin
          set_ZF(0);
        end;
      end;
    end
  else begin // data  and code segment
    limit32 := (dword1  and $0000ffff)or(dword2  and $000f0000);
    if Boolean( dword2  and $00800000 ) then
      limit32 := (limit32 shl 12)or$00000fff;
    if Boolean( (dword2  and $00000c00) = $00000c00 ) then begin
      // conforming code segment, no check done
      goto lsl_ok;
      end;

    if Boolean( (descriptor_dpl<CPL) or (descriptor_dpl<selector.rpl) ) then begin
      set_ZF(0);
      exit;
      end;
    goto lsl_ok;
    end;

lsl_ok:
  (* all checks pass, limit32 is now byte granular, write to op1 *)
  set_ZF(1);

  if Boolean(i^.os_32) then
    BX_WRITE_32BIT_REG(i^.nnn, limit32)
  else
    // chop off upper 16 bits
    BX_WRITE_16BIT_REG(i^.nnn, Bit16u(limit32));
end;

procedure BX_CPU_C.SLDT_Ew(I:PBxInstruction_tag);
var
  val16:Bit16u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('SLDT_Ew: not supported on 8086!'));
{$else}
  if Boolean(v8086_mode()) then BX_PANIC(('protect_ctrl: v8086 mod_e unsupported'));

  if Boolean(real_mode()) then begin
    (* not recognized in real address mod_e *)
    BX_ERROR(('SLDT_Ew: encountered in real mod_e.'));
    UndefinedOpcode(i);
    end
  else begin

    val16 := self.ldtr.selector.value;
    if Boolean(i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, val16);
      end
  else begin
      write_virtual_word(i^.seg, i^.rm_addr, @val16);
      end;
    end;
{$ifend}
end;

procedure BX_CPU_C.STR_Ew(I:PBxInstruction_tag);
var
  val16:Bit16u;
begin
  if Boolean(v8086_mode()) then BX_PANIC(('protect_ctrl: v8086 mod_e unsupported'));

  if Boolean(real_mode()) then begin
    // not recognized in real address mod_e
    BX_PANIC(('STR_Ew: encountered in real mod_e.'));
    UndefinedOpcode(i);
    end
  else begin

    val16 := self.tr.selector.value;
    if Boolean(i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, val16);
      end
  else begin
      write_virtual_word(i^.seg, i^.rm_addr, @val16);
      end;
    end;
end;

procedure BX_CPU_C.LLDT_Ew(I:PBxInstruction_tag);
var
  descriptor:bx_descriptor_t;
  selector:bx_selector_t;
  raw_selector:Bit16u;
  dword1, dword2:Bit32u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('LLDT_Ew: not supported on 8086!'));
{$else}
  if Boolean(v8086_mode()) then BX_PANIC(('protect_ctrl: v8086 mod_e unsupported'));

  invalidate_prefetch_q();

  if Boolean(real_mode()) then begin
    BX_PANIC(('lldt: not recognized in real mod_e'));
    UndefinedOpcode(i);
    exit;
    end
  else begin (* protected mod_e *)

    (* #GP(0) if the current privilege level is not 0 *)
    if Boolean(CPL <> 0) then begin
      BX_PANIC(('LLDT: CPL !:= 0'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      exit;
      end;

    if Boolean(i^.mod_ = $c0) then begin
      raw_selector := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      read_virtual_word(i^.seg, i^.rm_addr, @raw_selector);
      end;

    (* if selector is NULL, invalidate and done *)
    if Boolean((raw_selector  and $fffc) = 0) then begin
      self.ldtr.selector.value := raw_selector;
      self.ldtr.cache.valid := 0;
      exit;
      end;

    (* parse fields in selector *)
    parse_selector(raw_selector, @selector);

    // #GP(selector) if the selector operand does not point into GDT
    if Boolean(selector.ti <> 0) then begin
      BX_ERROR(('LLDT: selector.ti !:= 0'));
      exception2([BX_GP_EXCEPTION, raw_selector  and $fffc, 0]);
      end;

    if Boolean((selector.index*8 + 7) > self.gdtr.limit) then begin
      BX_PANIC(('lldt: GDT: index > limit'));
      exception2([BX_GP_EXCEPTION, raw_selector  and $fffc, 0]);
      exit;
      end;

    access_linear(self.gdtr.base + selector.index*8,     4, 0,
      BX_READ, @dword1);
    access_linear(self.gdtr.base + selector.index*8 + 4, 4, 0,
      BX_READ, @dword2);

    parse_descriptor(dword1, dword2, @descriptor);

    (* if selector doesn't point to an LDT descriptor #GP(selector) *)
    if Boolean( (descriptor.valid=0) or (descriptor.segmentType<>0)  or (descriptor.type_<>2) ) then begin
      BX_ERROR(('lldt: doesn''t point to an LDT descriptor!'));
      exception2([BX_GP_EXCEPTION, raw_selector  and $fffc, 0]);
      end;

    (* #NP(selector) if LDT descriptor is not present *)
    if Boolean(descriptor.p=0) then begin
      BX_ERROR(('lldt: LDT descriptor not present!'));
      exception2([BX_NP_EXCEPTION, raw_selector  and $fffc, 0]);
      end;

    if Boolean(descriptor.ldt.limit < 7) then begin
      BX_ERROR(('lldt: ldtr.limit < 7'));
      end;

    self.ldtr.selector := selector;
    self.ldtr.cache := descriptor;
    self.ldtr.cache.valid := 1;

    exit;
    end;
{$ifend}
end;

procedure BX_CPU_C.LTR_Ew(I:PBxInstruction_tag);
var
  descriptor:bx_descriptor_t;
  selector:bx_selector_t;
  raw_selector:Bit16u;
  dword1, dword2:Bit32u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('LTR_Ew: not supported on 8086!'));
{$else}
  if Boolean(v8086_mode()) then BX_PANIC(('protect_ctrl: v8086 mod_e unsupported'));


  invalidate_prefetch_q();

  if Boolean(Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0))) then begin

    (* #GP(0) if the current privilege level is not 0 *)
    if Boolean(CPL <> 0) then begin
      BX_PANIC(('LTR: CPL !:= 0'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      exit;
      end;

    if Boolean(i^.mod_ = $c0) then begin
      raw_selector := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      read_virtual_word(i^.seg, i^.rm_addr, @raw_selector);
      end;

    (* if selector is NULL, invalidate and done *)
    if Boolean((raw_selector  and $fffc) = 0) then begin
      BX_PANIC(('ltr: loading with NULL selector!'));
      (* if this is OK, then invalidate and load selector  and descriptor cache *)
      (* load here *)
      self.tr.selector.value := raw_selector;
      self.tr.cache.valid := 0;
      exit;
      end;

    (* parse fields in selector, then check for null selector *)
    parse_selector(raw_selector, @selector);

    if Boolean(selector.ti) then begin
      BX_PANIC(('ltr: selector.ti !:= 0'));
      exit;
      end;

    (* fetch 2 dwords of descriptor; call handles out of limits checks *)
    fetch_raw_descriptor(@selector, @dword1, @dword2, BX_GP_EXCEPTION);

    parse_descriptor(dword1, dword2, @descriptor);

    (* #GP(selector) if object is not a TSS or is already busy *)
    if Boolean( (descriptor.valid=0) or (descriptor.segmentType <> 0)  or ((descriptor.type_<>1) and (descriptor.type_<>9)) ) then begin
      BX_PANIC(('ltr: doesn''t point to an available TSS descriptor!'));
      exception2([BX_GP_EXCEPTION, raw_selector  and $fffc, 0]); (* 0 ??? *)
      exit;
      end;

    (* #NP(selector) if TSS descriptor is not present *)
    if Boolean(descriptor.p=0) then begin
      BX_PANIC(('ltr: LDT descriptor not present!'));
      exception2([BX_NP_EXCEPTION, raw_selector  and $fffc, 0]); (* 0 ??? *)
      exit;
      end;

    if Boolean((descriptor.type_=1) and (descriptor.tss286.limit<43)) then begin
      BX_PANIC(('ltr:286TSS: loading tr.limit < 43'));
      end
  else if Boolean((descriptor.type_=9) and (descriptor.tss386.limit_scaled<103)) then begin
      BX_PANIC(('ltr:386TSS: loading tr.limit < 103'));
      end;

    self.tr.selector := selector;
    self.tr.cache    := descriptor;
    self.tr.cache.valid := 1;
    // tr.cache.type should not have busy bit, or it would not get 
    // through the conditions above.
    assert((self.tr.cache.type_ and 2) = 0);

    (* mark as busy *)
    dword2 := dword2 or $00000200; (* set busy bit *)
    access_linear(self.gdtr.base + selector.index*8 + 4, 4, 0,
      BX_WRITE, @dword2);

    exit;
    end
  else begin
    BX_PANIC(('ltr_ew: not recognized in real-mod_e!'));
    UndefinedOpcode(i);
    exit;
    end;
{$ifend}
end;

  procedure
BX_CPU_C.VERR_Ew(I:PBxInstruction_tag);
var
  raw_selector:Bit16u;
  descriptor:bx_descriptor_t;
  selector:bx_selector_t;
  dword1, dword2:Bit32u;
begin
  (* for 16 bit operand size mod_e *)

  if Boolean(v8086_mode()) then BX_PANIC(('protect_ctrl: v8086 mod_e unsupported'));


  if Boolean(real_mode()) then begin
    BX_PANIC(('VERR_Ew: not recognized in real mod_e'));
    UndefinedOpcode(i);
    exit;
    end;

  if Boolean(i^.mod_ = $c0) then begin
    raw_selector := BX_READ_16BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_word(i^.seg, i^.rm_addr, @raw_selector);
    end;

  (* if selector null, clear ZF and done *)
  if Boolean( (raw_selector  and $fffc) = 0 ) then begin
    set_ZF(0);
    BX_ERROR(('VERR: null selector'));
    exit;
    end;

  (* if source selector is visible at CPL  and RPL,
   * within the descriptor table, and of type accepted by VERR instruction,
   * then load register with segment limit and set ZF *)
  parse_selector(raw_selector, @selector);

  if Boolean( fetch_raw_descriptor2(@selector, @dword1, @dword2)=0) then begin
    (* not within descriptor table *)
    set_ZF(0);
    BX_ERROR(('VERR: not in table'));
    exit;
    end;

  parse_descriptor(dword1, dword2, @descriptor);

  if Boolean( descriptor.segmentType=0 ) then begin (* system or gate descriptor *)
    set_ZF(0); (* inaccessible *)
    BX_ERROR(('VERR: system descriptor'));
    exit;
    end;

  if Boolean( descriptor.valid=0 ) then begin
    set_ZF(0);
    BX_INFO(('VERR: valid bit cleared'));
    exit;
    end;

  (* normal data/code segment *)
  if Boolean( descriptor.segment.executable ) then begin (* code segment *)
    (* ignore DPL for readable conforming segments *)
    if Boolean( descriptor.segment.c_ed and
         descriptor.segment.r_w) then begin
      set_ZF(1); (* accessible *)
      BX_INFO(('VERR: conforming code, OK'));
      exit;
      end;
    if Boolean( descriptor.segment.r_w=0 ) then begin
      set_ZF(0); (* inaccessible *)
      BX_INFO(('VERR: code not readable'));
      exit;
      end;
    (* readable, non-conforming code segment *)
    if Boolean( (descriptor.dpl<CPL) or (descriptor.dpl<selector.rpl) ) then begin
      set_ZF(0); (* inaccessible *)
      BX_INFO(('VERR: non-coforming code not withing priv level'));
      exit;
      end;
    set_ZF(1); (* accessible *)
    BX_INFO(('VERR: code seg readable'));
    exit;
    end
  else begin (* data segment *)
    if Boolean( (descriptor.dpl<CPL) or (descriptor.dpl<selector.rpl) ) then begin
      set_ZF(0); (* not accessible *)
      BX_INFO(('VERR: data seg not withing priv level'));
      exit;
      end;
    set_ZF(1); (* accessible *)
    BX_ERROR(('VERR: data segment OK'));
    exit;
    end;
end;

procedure BX_CPU_C.VERW_Ew(I:PBxInstruction_tag);
var
  raw_selector:Bit16u;
  descriptor:bx_descriptor_t;
  selector:bx_selector_t;
  dword1, dword2:Bit32u;
begin
  (* for 16 bit operand size mod_e *)

  if Boolean(v8086_mode()) then BX_PANIC(('protect_ctrl: v8086 mod_e unsupported'));

  if Boolean(real_mode()) then begin
    BX_PANIC(('VERW_Ew: not recognized in real mod_e'));
    UndefinedOpcode(i);
    exit;
    end;

  if Boolean(i^.mod_ = $c0) then begin
    raw_selector := BX_READ_16BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_word(i^.seg, i^.rm_addr, @raw_selector);
    end;

  (* if selector null, clear ZF and done *)
  if Boolean( (raw_selector  and $fffc) = 0 ) then begin
    set_ZF(0);
    BX_ERROR(('VERW: null selector'));
    exit;
    end;

  (* if source selector is visible at CPL  and RPL,
   * within the descriptor table, and of type accepted by VERW instruction,
   * then load register with segment limit and set ZF *)
  parse_selector(raw_selector, @selector);

  if Boolean( fetch_raw_descriptor2(@selector, @dword1, @dword2)=0) then begin
    (* not within descriptor table *)
    set_ZF(0);
    BX_ERROR(('VERW: not in table'));
    exit;
    end;

  parse_descriptor(dword1, dword2, @descriptor);

  (* rule out system segments  and code segments *)
  if Boolean( (descriptor.segmentType=0) or (descriptor.segment.executable<>0) ) then begin
    set_ZF(0);
    BX_ERROR(('VERW: system seg or code'));
    exit;
    end;

  if Boolean( descriptor.valid=0 ) then begin
    set_ZF(0);
    BX_INFO(('VERW: valid bit cleared'));
    exit;
    end;

  (* data segment *)
  if Boolean( descriptor.segment.r_w ) then begin (* writable *)
    if Boolean( (descriptor.dpl<CPL) or (descriptor.dpl<selector.rpl) ) then begin
      set_ZF(0); (* not accessible *)
      BX_INFO(('VERW: writable data seg not within priv level'));
      exit;
      end;
    set_ZF(1); (* accessible *)
    BX_ERROR(('VERW: data seg writable'));
    exit;
    end;

  set_ZF(0); (* not accessible *)
  BX_INFO(('VERW: data seg not writable'));
  exit;
end;

procedure BX_CPU_C.SGDT_Ms(I:PBxInstruction_tag);
var
  limit_16:Bit16u;
  base_32:Bit32u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('SGDT_Ms: not supported on 8086!'));
{$else}

  if Boolean(v8086_mode()) then BX_PANIC(('protect_ctrl: v8086 mod_e unsupported'));


  (* op1 is a register or memory reference *)
  if Boolean(i^.mod_ = $c0) then begin
    (* undefined opcode exception *)
    BX_PANIC(('SGDT_Ms: use of register is undefined opcode.'));
    UndefinedOpcode(i);
    exit;
    end;

  limit_16 := self.gdtr.limit;
  base_32  := self.gdtr.base;
{$if BX_CPU_LEVEL = 2}
  base_32 := base_32 or $ff000000; (* ??? *)
{$else} (* 386+ *)
  (* 32bit processors always write 32bits of base *)
{$ifend}
  write_virtual_word(i^.seg, i^.rm_addr, @limit_16);

  write_virtual_dword(i^.seg, i^.rm_addr+2, @base_32);

{$ifend}
end;

procedure BX_CPU_C.SIDT_Ms(I:PBxInstruction_tag);
var
  limit_16:Bit16u;
  base_32:Bit32u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('SIDT_Ms: not supported on 8086!'));
{$else}

  if Boolean(v8086_mode()) then BX_PANIC(('protect_ctrl: v8086 mod_e unsupported'));

  (* op1 is a register or memory reference *)
  if Boolean(i^.mod_ = $c0) then begin
    (* undefined opcode exception *)
    BX_PANIC(('SIDT: use of register is undefined opcode.'));
    UndefinedOpcode(i);
    exit;
    end;

  limit_16 := self.idtr.limit;
  base_32  := self.idtr.base;

{$if BX_CPU_LEVEL = 2}
  base_32 := base_32 or $ff000000;
{$else} (* 386+ *)
  (* ??? regardless of operand size, all 32bits of base are stored *)
{$ifend}

  write_virtual_word(i^.seg, i^.rm_addr, @limit_16);

  write_virtual_dword(i^.seg, i^.rm_addr+2, @base_32);

{$ifend}
end;

procedure BX_CPU_C.LGDT_Ms(I:PBxInstruction_tag);
var
  limit_16:Bit16u;
  base0_31:Bit32u;
  base0_15:Bit16u;
  base16_23:Bit8u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('LGDT_Ms: not supported on 8086!'));
{$else}

  if Boolean(v8086_mode()) then BX_PANIC(('protect_ctrl: v8086 mod_e unsupported'));

  invalidate_prefetch_q();

  if Boolean((Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0))<>0) and (CPL<>0)) then begin
    BX_PANIC(('LGDT: protected mod_e: CPL!:=0'));
    exception2([BX_GP_EXCEPTION, 0, 0]);
    exit;
    end;

  (* op1 is a register or memory reference *)
  if Boolean(i^.mod_ = $c0) then begin
    BX_PANIC(('LGDT generating exception 6'));
    UndefinedOpcode(i);
    exit;
    end;

{$if BX_CPU_LEVEL >= 3}
  if Boolean(i^.os_32) then begin

    read_virtual_word(i^.seg, i^.rm_addr, @limit_16);

    read_virtual_dword(i^.seg, i^.rm_addr + 2, @base0_31);

    self.gdtr.limit := limit_16;
    self.gdtr.base := base0_31;
    end
  else
{$ifend}
    begin

    read_virtual_word(i^.seg, i^.rm_addr, @limit_16);

    read_virtual_word(i^.seg, i^.rm_addr + 2, @base0_15);

    read_virtual_byte(i^.seg, i^.rm_addr + 4, @base16_23);

    (* ignore high 8 bits *)

    self.gdtr.limit := limit_16;
    self.gdtr.base := (base16_23 shl 16) or base0_15;
    end;
{$ifend}
end;

procedure BX_CPU_C.LIDT_Ms(I:PBxInstruction_tag);
var
  limit_16:Bit16u;
  base_32:Bit32u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('LIDT_Ms: not supported on 8086!'));
{$else}

  if Boolean(v8086_mode()) then BX_PANIC(('protect_ctrl: v8086 mod_e unsupported'));

  invalidate_prefetch_q();

  if Boolean(Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0))) then begin
    if Boolean(CPL <> 0) then begin
      BX_PANIC(Format('LIDT(): CPL(%u) !:= 0',[CPL]));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      exit;
      end;
    end;

  (* op1 is a register or memory reference *)
  if Boolean(i^.mod_ = $c0) then begin
    (* undefined opcode exception *)
    BX_PANIC(('LIDT generating exception 6'));
    UndefinedOpcode(i);
    exit;
    end;

  read_virtual_word(i^.seg, i^.rm_addr, @limit_16);

  read_virtual_dword(i^.seg, i^.rm_addr + 2, @base_32);

  self.idtr.limit := limit_16;

{$if BX_CPU_LEVEL >= 3}
  if Boolean(i^.os_32) then
    self.idtr.base := base_32
  else
{$ifend}
    self.idtr.base := base_32 and $00ffffff; (* ignore upper 8 bits *)

{$ifend}
end;
