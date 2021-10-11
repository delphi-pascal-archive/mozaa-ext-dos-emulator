{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.RETnear32_Iw(I:PBxInstruction_tag);
var
  imm16:Bit16u;
  temp_ESP:Bit32u;
  return_EIP:Bit32u;
begin

{$if BX_DEBUGGER=1}
  self.show_flag |:= Flag_ret;
{$ifend}

  if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then (* 32bit stack *)
    temp_ESP := ESP
  else
    temp_ESP := SP;

  imm16 := i^.Iw;

  invalidate_prefetch_q();


    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if ( can_pop(4)=0 ) then begin
        BX_PANIC(('retnear_iw: can''t pop EIP'));
        (* ??? #SS(0) -or #GP(0) *)
        end;

      access_linear(self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 0,
        4, Bool(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_READ, @return_EIP);

      if ((Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0))<>0) and
          (return_EIP > self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled) ) then begin
        BX_DEBUG(('retnear_iw: EIP > limit'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        end;

      (* Pentium book says imm16 is number of words ??? *)
      if ( can_pop(4 + imm16)=0 ) then begin
        BX_PANIC(('retnear_iw: can''t release bytes from stack'));
        (* #GP(0) -or #SS(0) ??? *)
        end;

      self.eip := return_EIP;
      if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then (* 32bit stack *)
        ESP := ESP + 4 + imm16 (* ??? should it be 2*imm16 ? *)
      else
        SP := SP + 4 + imm16;
      end
  else begin
      pop_32(@return_EIP);
      self.eip := return_EIP;
      if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then (* 32bit stack *)
        ESP := ESP + imm16 (* ??? should it be 2*imm16 ? *)
      else
        SP := SP + imm16;
      end;

  //BX_INSTR_UCNEAR_BRANCH(BX_INSTR_IS_RET, self.eip);
end;

procedure BX_CPU_C.RETnear32(I:PBxInstruction_tag);
var
  temp_ESP:Bit32u;
  return_EIP:Bit32u;
begin

{$if BX_DEBUGGER=1}
  self.show_flag |:= Flag_ret;
{$ifend}

  invalidate_prefetch_q();

  if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then (* 32bit stack *)
    temp_ESP := ESP
  else
    temp_ESP := SP;


    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if ( can_pop(4)=0 ) then begin
        BX_PANIC(('retnear: can''t pop EIP'));
        (* ??? #SS(0) -or #GP(0) *)
        end;

      access_linear(self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 0,
        4, Bool(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_READ, @return_EIP);

      if ( return_EIP > self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled ) then begin
        BX_PANIC(('retnear: EIP > limit'));
        exception(BX_GP_EXCEPTION, 0, 0);
        end;
      self.eip := return_EIP;
      if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then (* 32bit stack *)
        ESP:=ESP + 4
      else
        SP:=SP + 4;
      end
  else begin
      pop_32(@return_EIP);
      self.eip := return_EIP;
      end;

  //BX_INSTR_UCNEAR_BRANCH(BX_INSTR_IS_RET, self.eip);
end;

procedure BX_CPU_C.RETfar32_Iw(I:PBxInstruction_tag);
var
  eip, ecs_raw:Bit32u;
  imm16:Bit16s;
  label done;
begin

{$if BX_DEBUGGER=1}
  self.show_flag |:= Flag_ret;
{$ifend}
  (* ??? is imm16, number of bytes/words depending on operandsize ? *)

  imm16 := i^.Iw;

  invalidate_prefetch_q();

{$if BX_CPU_LEVEL >= 2}
  if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
    self.return_protected(i, imm16); 
    goto done;
    end;
{$ifend}


    pop_32(@eip);
    pop_32(@ecs_raw);
    self.eip := eip;
    load_seg_reg(@self.sregs[BX_SEG_REG_CS], Bit16u(ecs_raw));
    if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
      ESP := ESP + imm16
    else
      SP  := SP + imm16;

done:
  //BX_INSTR_FAR_BRANCH(BX_INSTR_IS_RET,
  //                    self.sregs[BX_SEG_REG_CS].selector.value, self.eip);
  exit;
end;

procedure BX_CPU_C.RETfar32(I:PBxInstruction_tag);
var
  eip, ecs_raw:Bit32u;
  label done;
begin

{$if BX_DEBUGGER=1}
  self.show_flag |:= Flag_ret;
{$ifend}

  invalidate_prefetch_q();

{$if BX_CPU_LEVEL >= 2}
  if ( Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)) )<>0 then begin
    self.return_protected(i, 0); 
    goto done;
    end;
{$ifend}


    pop_32(@eip);
    pop_32(@ecs_raw); (* 32bit pop, MSW discarded *)
    self.eip := eip;
    load_seg_reg(@self.sregs[BX_SEG_REG_CS], Bit16u(ecs_raw));

done:
  //BX_INSTR_FAR_BRANCH(BX_INSTR_IS_RET,
    //                  self.sregs[BX_SEG_REG_CS].selector.value, self.eip);
  exit;
end;

procedure BX_CPU_C.CALL_Ad(I:PBxInstruction_tag);
var
  new_EIP:Bit32u;
  disp32:Bit32s;
begin

{$if BX_DEBUGGER=1}
  self.show_flag |:= Flag_call;
{$ifend}

  disp32 := i^.Id;
  invalidate_prefetch_q();

  new_EIP := EIP + disp32;

  if ( Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)) )<>0 then begin
    if ( new_EIP > self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled ) then begin
      BX_PANIC(('call_av: offset outside of CS limits'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      end;
    end;

  (* push 32 bit EA of next instruction *)
  push_32(self.eip);
  self.eip := new_EIP;

  //BX_INSTR_UCNEAR_BRANCH(BX_INSTR_IS_CALL, self.eip);
end;

procedure BX_CPU_C.CALL32_Ap(I:PBxInstruction_tag);
var
  cs_raw:Bit16u;
  disp32:Bit32u;
  label done;
begin

{$if BX_DEBUGGER=1}
  self.show_flag |:= Flag_call;
{$ifend}

  disp32 := i^.Id;
  cs_raw := i^.Iw2;
  invalidate_prefetch_q();

  if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
    self.call_protected(i, cs_raw, disp32); 
    goto done;
    end;
  push_32(self.sregs[BX_SEG_REG_CS].selector.value);
  push_32(self.eip);
  self.eip := disp32;
  load_seg_reg(@self.sregs[BX_SEG_REG_CS], cs_raw);

done:
  //BX_INSTR_FAR_BRANCH(BX_INSTR_IS_CALL,
  //                    self.sregs[BX_SEG_REG_CS].selector.value, self.eip);
  exit;
end;

procedure BX_CPU_C.CALL_Ed(I:PBxInstruction_tag);
var
  temp_ESP:Bit32u;
  op1_32:Bit32u;
begin

{$if BX_DEBUGGER=1}
  self.show_flag |:= Flag_call;
{$ifend}

  if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
    temp_ESP := ESP
  else
    temp_ESP := SP;


    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      read_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;
    invalidate_prefetch_q();

    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if (op1_32 > self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled) then begin
        BX_DEBUG(('call_ev: EIP out of CS limits! at %s:%d'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        end;
      if ( can_push(@self.sregs[BX_SEG_REG_SS].cache, temp_ESP, 4)=0 ) then begin
        BX_PANIC(('call_ev: can''t push EIP'));
        end;
      end;

    push_32(self.eip);

    self.eip := op1_32;

  //BX_INSTR_UCNEAR_BRANCH(BX_INSTR_IS_CALL, self.eip);
end;

procedure BX_CPU_C.CALL32_Ep(I:PBxInstruction_tag);
var
  cs_raw:Bit16u;
  op1_32:Bit32u;
  label done;
begin

{$if BX_DEBUGGER=1}
  self.show_flag |:= Flag_call;
{$ifend}

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      BX_PANIC(('CALL_Ep: op1 is a register'));
      end;

    (* pointer, segment address pair *)
    read_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
    read_virtual_word(i^.seg, i^.rm_addr+4, @cs_raw);
    invalidate_prefetch_q();

    if ( Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)) )<>0 then begin
      self.call_protected(i, cs_raw, op1_32);
      goto done;
      end;

    push_32(self.sregs[BX_SEG_REG_CS].selector.value);
    push_32(self.eip);

    self.eip := op1_32;
    load_seg_reg(@self.sregs[BX_SEG_REG_CS], cs_raw);

done:
  //BX_INSTR_FAR_BRANCH(BX_INSTR_IS_CALL,
  //                    self.sregs[BX_SEG_REG_CS].selector.value, self.eip);
  exit;
end;

procedure BX_CPU_C.JMP_Jd(I:PBxInstruction_tag);
var
  new_EIP:Bit32u;
begin

    invalidate_prefetch_q();

    new_EIP := EIP + Bit32s(i^.Id);

{$if BX_CPU_LEVEL >= 2}
  if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
    if ( new_EIP > self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled ) then begin
      BX_PANIC(('jmp_jv: offset outside of CS limits'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      end;
    end;
{$ifend}

  self.eip := new_EIP;
  //BX_INSTR_UCNEAR_BRANCH(BX_INSTR_IS_JMP, new_EIP);
end;

procedure BX_CPU_C.JCC_Jd(I:PBxInstruction_tag);
var
  condition:Bool;
  new_EIP:Bit32u;
begin
  condition:=0;
  case (i^.b1 and $0f) of
    $00: (* JO *) begin condition := get_OF(); end;
    $01: (* JNO *) begin condition := Bool(get_OF()=0); end;
    $02: (* JB *) begin condition := Bool(get_CF() <> 0); end;
    $03: (* JNB *) begin condition := Bool(get_CF() = 0); end;
    $04: (* JZ *) begin condition := Bool(get_ZF() <> 0); end;
    $05: (* JNZ *) begin condition := Bool(get_ZF() = 0); end;
    $06: (* JBE *) begin condition := Bool(get_CF() or get_ZF()); end;
    $07: (* JNBE *) begin condition := Bool(((get_CF()=0) and (get_ZF()=0))); end;
    $08: (* JS *) begin condition := Bool(get_SF() <> 0); end;
    $09: (* JNS *) begin condition :=Bool(get_SF()=0); end;
    $0A: (* JP *) begin condition := Bool(get_PF() <> 0); end;
    $0B: (* JNP *) begin condition := Bool(get_PF()=0); end;
    $0C: (* JL *) begin condition := Bool((get_SF() <> get_OF())); end;
    $0D: (* JNL *) begin condition := Bool((get_SF() = get_OF())); end;
    $0E: (* JLE *) begin condition := Bool(((get_ZF()<>0) or (get_SF() <> get_OF())));
      end;
    $0F: (* JNLE *) begin condition := Bool(((get_SF() = get_OF()) and
                            (get_ZF()=0)));
      end;
    end;

  if (condition)<>0 then begin

    new_EIP := EIP + Bit32s(i^.Id);
{$if BX_CPU_LEVEL >= 2}
    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if ( new_EIP > self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled ) then begin
        BX_PANIC(('jo_routine: offset outside of CS limits'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        end;
      end;
{$ifend}
    EIP := new_EIP;
    //BX_INSTR_CNEAR_BRANCH_TAKEN(new_EIP);
    revalidate_prefetch_q();
    end;
{$if BX_INSTRUMENTATION=1}
  else begin
    BX_INSTR_CNEAR_BRANCH_NOT_TAKEN();
    end;
{$ifend}
end;

procedure BX_CPU_C.JMP_Ap(I:PBxInstruction_tag);
var
  disp32:Bit32u;
  cs_raw:Bit16u;
  label done;
begin

  invalidate_prefetch_q();

  if (i^.os_32)<>0 then begin
    disp32 := i^.Id;
    end
  else begin
    disp32 := i^.Iw;
    end;
  cs_raw := i^.Iw2;

{$if BX_CPU_LEVEL >= 2}
  if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
    self.jump_protected(i, cs_raw, disp32); 
    goto done;
    end;
{$ifend}

  load_seg_reg(@self.sregs[BX_SEG_REG_CS], cs_raw);
  self.eip := disp32;

done:
  //BX_INSTR_FAR_BRANCH(BX_INSTR_IS_JMP,
  //                    self.sregs[BX_SEG_REG_CS].selector.value, self.eip);
  exit;
end;

procedure BX_CPU_C.JMP_Ed(I:PBxInstruction_tag);
var
  new_EIP:Bit32u;
  op1_32:Bit32u;
begin

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    invalidate_prefetch_q();
    new_EIP := op1_32;

{$if BX_CPU_LEVEL >= 2}
  if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
    if (new_EIP > self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled) then begin
      BX_PANIC(('jmp_ev: IP out of CS limits!'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      end;
    end;
{$ifend}

  self.eip := new_EIP;

  //BX_INSTR_UCNEAR_BRANCH(BX_INSTR_IS_JMP, new_EIP);
end;

  (* Far indirect jump *)

procedure BX_CPU_C.JMP32_Ep(I:PBxInstruction_tag);
var
  cs_raw:Bit16u;
  op1_32:Bit32u;
  label done;
begin

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      (* far indirect must specify a memory address *)
      BX_PANIC(('JMP_Ep(): op1 is a register'));
      end;

    (* pointer, segment address pair *)
    read_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
    read_virtual_word(i^.seg, i^.rm_addr+4, @cs_raw);
    invalidate_prefetch_q();

    if ( Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)) )<>0 then begin
      self.jump_protected(i, cs_raw, op1_32); 
      goto done;
      end;

    self.eip := op1_32;
    load_seg_reg(@self.sregs[BX_SEG_REG_CS], cs_raw);

done:
  //BX_INSTR_FAR_BRANCH(BX_INSTR_IS_JMP,
  //                    self.sregs[BX_SEG_REG_CS].selector.value, self.eip);
  exit;
end;

procedure BX_CPU_C.IRET32(I:PBxInstruction_tag);
var
  eip, ecs_raw, eflags:Bit32u;
  label done;
begin

{$if BX_DEBUGGER=1}
  self.show_flag |:= Flag_iret;
  self.show_eip := self.eip;
{$ifend}

  invalidate_prefetch_q();

  if (v8086_mode())<>0 then begin
    // IOPL check in stack_return_from_v86()
    stack_return_from_v86(i);
    goto done;
    end;

{$if BX_CPU_LEVEL >= 2}
  if (self.cr0.pe)<>0 then begin
    iret_protected(i); 
    goto done;
    end;
{$ifend}

  BX_ERROR(('IRET32 called when you''re not in vm8086 mod_e or protected mod_e.'));
  BX_ERROR(('IRET32 may not be implemented right, since it doesn''t check anything.'));
  BX_PANIC(('Please report that you have found a test case for BX_CPU_C.IRET32.'));

    pop_32(@eip);
    pop_32(@ecs_raw);
    pop_32(@eflags);

    load_seg_reg(@self.sregs[BX_SEG_REG_CS], Bit16u(ecs_raw));
    self.eip := eip;
    //FIXME: this should do (eflags  and $257FD5)or(EFLAGSor$1A0000)
    write_eflags(eflags, (* change IOPL? *) 1, (* change IF? *) 1, 0, 1);

done:
  //BX_INSTR_FAR_BRANCH(BX_INSTR_IS_IRET,
  //                    self.sregs[BX_SEG_REG_CS].selector.value, self.eip);
  exit;
end;
