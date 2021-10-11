{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
procedure BX_CPU_C.RETnear16_Iw(I:PBxInstruction_tag);
var
  imm16:Bit16u;
  temp_ESP:Bit32u;
  return_IP:Bit16u;
begin

{$if BX_DEBUGGER=01}
  self.show_flag |:= Flag_ret;
{$ifend}

  if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then (* 32bit stack *)
    temp_ESP := ESP
  else
    temp_ESP := SP;

  imm16 := i^.Iw;

  invalidate_prefetch_q();


    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if (can_pop(2)=0) then begin
        BX_PANIC(('retnear_iw: can''t pop IP'));
        (* ??? #SS(0) -or #GP(0) *)
        end;

      access_linear(self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 0,
        2, Bool(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_READ, @return_IP);

      if ( return_IP > self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled ) then begin
        BX_PANIC(('retnear_iw: IP > limit'));
        end;

      if (can_pop(2 + imm16)=0 ) then begin
        BX_PANIC(('retnear_iw: can''t release bytes from stack'));
        (* #GP(0) -or #SS(0) ??? *)
        end;

      self.eip := return_IP;
      if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then (* 32bit stack *)
        ESP := ESP + 2 + imm16 (* ??? should it be 2*imm16 ? *)
      else
        SP  := SP  + 2 + imm16;
      end
  else begin
      pop_16(@return_IP);
      self.eip := return_IP;
      if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then (* 32bit stack *)
        ESP := ESP + imm16 (* ??? should it be 2*imm16 ? *)
      else
        SP  := SP + imm16;
      end;

  //BX_INSTR_UCNEAR_BRANCH(BX_INSTR_IS_RET, self.eip);
end;

procedure BX_CPU_C.RETnear16(I:PBxInstruction_tag);
var
  temp_ESP:Bit32u;
  return_IP:Bit16u;
begin

{$if BX_DEBUGGER=01}
  self.show_flag |:= Flag_ret;
{$ifend}

  invalidate_prefetch_q();

  if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then (* 32bit stack *)
    temp_ESP := ESP
  else
    temp_ESP := SP;


    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if ( can_pop(2)=0 ) then begin
        BX_PANIC(('retnear: can''t pop IP'));
        (* ??? #SS(0) -or #GP(0) *)
        end;

      access_linear(self.sregs[BX_SEG_REG_SS].cache.segment.base + temp_ESP + 0,
        2, Bool(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_READ, @return_IP);

      if ( return_IP > self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled ) then begin
        BX_PANIC(('retnear: IP > limit'));
        end;

      self.eip := return_IP;
      if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then (* 32bit stack *)
        ESP := ESP + 2
      else
        SP  := SP + 2;
      end
  else begin
      pop_16(@return_IP);
      self.eip := return_IP;
      end;

  //BX_INSTR_UCNEAR_BRANCH(BX_INSTR_IS_RET, self.eip);
end;

  procedure
BX_CPU_C.RETfar16_Iw(I:PBxInstruction_tag);
var
  imm16:Bit16s;
  ip, cs_raw:Bit16u;
  label done;
begin

{$if BX_DEBUGGER=01}
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


    pop_16(@ip);
    pop_16(@cs_raw);
    self.eip := Bit32u(ip);
    load_seg_reg(@self.sregs[BX_SEG_REG_CS], cs_raw);
    if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
      ESP := ESP + imm16
    else
      SP  := SP  + imm16;

done:
  //BX_INSTR_FAR_BRANCH(BX_INSTR_IS_RET,
  //                    self.sregs[BX_SEG_REG_CS].selector.value, self.eip);
  exit;
end;

procedure BX_CPU_C.RETfar16(I:PBxInstruction_tag);
var
  ip_, cs_raw:Bit16u;
  label done;
begin

{$if BX_DEBUGGER = 01}
  self.show_flag |:= Flag_ret;
{$ifend}

  invalidate_prefetch_q();

{$if BX_CPU_LEVEL >= 2}
  if ( Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)) )<>0 then begin
    self.return_protected(i, 0);
    goto done;
    end;
{$ifend}

    pop_16(@ip_);
    pop_16(@cs_raw);
    self.eip := Bit32u(ip_);
    load_seg_reg(@self.sregs[BX_SEG_REG_CS], cs_raw);

done:
  //BX_INSTR_FAR_BRANCH(BX_INSTR_IS_RET,
  //                    self.sregs[BX_SEG_REG_CS].selector.value, self.eip);
  exit;
end;

procedure BX_CPU_C.CALL_Aw(I:PBxInstruction_tag);
var
  new_EIP:Bit32u;
begin

{$if BX_DEBUGGER=01}
  self.show_flag |:= Flag_call;
{$ifend}

  invalidate_prefetch_q();

  new_EIP := EIP + Bit32s(i^.Id);
  new_EIP := new_EIP and $0000ffff;
{$if BX_CPU_LEVEL >= 2}
  if ( (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0))<>0) and (new_EIP > self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled) ) then begin
    BX_PANIC(('call_av: new_IP > self.sregs[BX_SEG_REG_CS].limit'));
    exception2([BX_GP_EXCEPTION, 0, 0]);
    end;
{$ifend}

  (* push 16 bit EA of next instruction *)
  push_16(IP);

  self.eip := new_EIP;

  //BX_INSTR_UCNEAR_BRANCH(BX_INSTR_IS_CALL, self.eip);
end;

procedure BX_CPU_C.CALL16_Ap(I:PBxInstruction_tag);
var
  cs_raw:Bit16u;
  disp16:Bit16u;
  label done;
begin

{$if BX_DEBUGGER=1}
  self.show_flag |:= Flag_call;
{$ifend}

  disp16 := i^.Iw;
  cs_raw := i^.Iw2;
  invalidate_prefetch_q();

{$if BX_CPU_LEVEL >= 2}
  if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
    self.call_protected(i, cs_raw, disp16); 
    goto done;
    end;
{$ifend}
  push_16(self.sregs[BX_SEG_REG_CS].selector.value);
  push_16(Bit16u(self.eip));
  self.eip := Bit32u(disp16);
  load_seg_reg(@self.sregs[BX_SEG_REG_CS], cs_raw);

done:
  //BX_INSTR_FAR_BRANCH(BX_INSTR_IS_CALL,
  //                    self.sregs[BX_SEG_REG_CS].selector.value, self.eip);
  exit;
end;

procedure BX_CPU_C.CALL_Ew(I:PBxInstruction_tag);
var
  temp_ESP:Bit32u;
  op1_16:Bit16u;
begin

{$if BX_DEBUGGER=1}
  self.show_flag |:= Flag_call;
{$ifend}

  if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
    temp_ESP := ESP
  else
    temp_ESP := SP;


    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;
    invalidate_prefetch_q();

{$if BX_CPU_LEVEL >= 2}
    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if (op1_16 > self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled) then begin
        BX_PANIC(('call_ev: IP out of CS limits!'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        end;
      if ( can_push(@self.sregs[BX_SEG_REG_SS].cache, temp_ESP, 2)=0 ) then begin
        BX_PANIC(('call_ev: can''t push IP'));
        end;
      end;
{$ifend}

    push_16(IP);

    self.eip := op1_16;

  //BX_INSTR_UCNEAR_BRANCH(BX_INSTR_IS_CALL, self.eip);
end;

procedure BX_CPU_C.CALL16_Ep(I:PBxInstruction_tag);
var
  cs_raw:Bit16u;
  op1_16:Bit16u;
  label Done;
begin

{$if BX_DEBUGGER=1}
  self.show_flag |:= Flag_call;
{$ifend}

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      BX_PANIC(('CALL_Ep: op1 is a register'));
      end;

    (* pointer, segment address pair *)
    read_virtual_word(i^.seg, i^.rm_addr, @op1_16);
    read_virtual_word(i^.seg, i^.rm_addr+2, @cs_raw);
    invalidate_prefetch_q();

    if ( Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)) )<>0 then begin
      self.call_protected(i, cs_raw, op1_16); 
      goto done;
      end;

    push_16(self.sregs[BX_SEG_REG_CS].selector.value);
    push_16(IP);

    self.eip := op1_16;
    load_seg_reg(@self.sregs[BX_SEG_REG_CS], cs_raw);

done:
  //BX_INSTR_FAR_BRANCH(BX_INSTR_IS_CALL,
  //                    self.sregs[BX_SEG_REG_CS].selector.value, self.eip);
  exit;
end;

procedure BX_CPU_C.JMP_Jw(I:PBxInstruction_tag);
var
  new_EIP:Bit32u;
begin


  invalidate_prefetch_q();

  new_EIP := EIP + Bit32s(i^.Id);
  new_EIP := new_EIP and $0000ffff;

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

procedure BX_CPU_C.JCC_Jw(I:PBxInstruction_tag);
var
  condition:Boolean;
  new_EIP:Bit32u;
begin
  condition:=false;
  case (i^.b1 and $0f) of
    $00: begin (* JO *) condition := get_OF() <> 0; end;
    $01: begin (* JNO *) condition := not (get_OF() <> 0); end;
    $02: begin (* JB *) condition := get_CF()<>0; end;
    $03: begin (* JNB *) condition := (get_CF() = 0); end;
    $04: begin (* JZ *) condition := get_ZF() <> 0; end;
    $05: begin (* JNZ *) condition := not (get_ZF() <> 0); end;
    $06: begin (* JBE *) condition := (get_CF() <> 0) or (get_ZF() <> 0); end;
    $07: begin (* JNBE *) condition := not (get_CF() <> 0) and not (get_ZF() <> 0); end;
    $08: begin (* JS *) condition := get_SF() <> 0; end;
    $09: begin (* JNS *) condition := not (get_SF() <> 0); end;
    $0A: begin (* JP *) condition := (get_PF())<>0; end;
    $0B: begin (* JNP *) condition := (get_PF() = 0); end;
    $0C: begin (* JL *) condition := get_SF() <> get_OF(); end;
    $0D: begin (* JNL *) condition := get_SF() = get_OF(); end;
    $0E: begin (* JLE *) condition := (get_ZF()<>0) or (get_SF() <> get_OF());
      end;
    $0F: begin (* JNLE *) condition := (get_SF() = get_OF()) and (get_ZF()=0);
      end;
    end;

  if (condition) then begin

    new_EIP := EIP + Bit32s(i^.Id);
    new_EIP := new_EIP and $0000ffff;
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
    //BX_INSTR_CNEAR_BRANCH_NOT_TAKEN();
    end;
{$ifend}
end;

procedure BX_CPU_C.JMP_Ew(I:PBxInstruction_tag);
var
  new_EIP:Bit32u;
  op1_16:Bit16u;
begin
    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    invalidate_prefetch_q();
    new_EIP := op1_16;

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

procedure BX_CPU_C.JMP16_Ep(I:PBxInstruction_tag);
var
  cs_raw:Bit16u;
  op1_16:Bit16u;
  label done;
begin

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      (* far indirect must specify a memory address *)
      BX_PANIC(('JMP_Ep(): op1 is a register'));
      end;

    (* pointer, segment address pair *)
    read_virtual_word(i^.seg, i^.rm_addr, @op1_16);
    read_virtual_word(i^.seg, i^.rm_addr+2, @cs_raw);
    invalidate_prefetch_q();

{$if BX_CPU_LEVEL >= 2}
    if ( Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)) )<>0 then begin
      self.jump_protected(i, cs_raw, op1_16); 
      goto done;
      end;
{$ifend}

    self.eip := op1_16;
    load_seg_reg(@self.sregs[BX_SEG_REG_CS], cs_raw);

done:
  //BX_INSTR_FAR_BRANCH(BX_INSTR_IS_JMP,
                      //self.sregs[BX_SEG_REG_CS].selector.value, self.eip);
  exit;
end;

procedure BX_CPU_C.IRET16(I:PBxInstruction_tag);
var
  ip_, cs_raw, flags:Bit16u;
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


  pop_16(@ip_);
  pop_16(@cs_raw);
  pop_16(@flags);

  load_seg_reg(@self.sregs[BX_SEG_REG_CS], cs_raw);
  self.eip := Bit32u(ip_);
  write_flags(flags, (* change IOPL? *) 1, (* change IF? *) 1);

done:
  //BX_INSTR_FAR_BRANCH(BX_INSTR_IS_IRET,
  //                    self.sregs[BX_SEG_REG_CS].selector.value, self.eip);
  exit;
end;
