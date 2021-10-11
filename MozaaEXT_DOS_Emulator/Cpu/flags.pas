{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.set_CF(val:Bool);
begin
    self.lf_flags_status := self.lf_flags_status and $fffff0;
    self.eflags.cf := val;
    end;

procedure BX_CPU_C.set_AF(val:Bool);
begin
    self.lf_flags_status := self.lf_flags_status and $fff0ff;
    self.eflags.af := val;
    end;

procedure BX_CPU_C.set_ZF(val:Bool);
begin
    self.lf_flags_status := self.lf_flags_status and $ff0fff;
    self.eflags.zf := val;
    end;

procedure BX_CPU_C.set_SF(val:Bool);
begin
    self.lf_flags_status := self.lf_flags_status and $f0ffff;
    self.eflags.sf := val;
    end;


procedure BX_CPU_C.set_OF(val:Bool);
begin
    self.lf_flags_status := self.lf_flags_status and $0fffff;
    self.eflags.of_ := val;
    end;

procedure BX_CPU_C.set_PF(val:Bool);
begin
    self.lf_flags_status := self.lf_flags_status and $ffff0f;
    self.lf_pf := val;
    end;

procedure BX_CPU_C.set_PF_base(val:Bit8u);
begin
    self.eflags.pf_byte := val;
    self.lf_flags_status := (self.lf_flags_status and $ffff0f) or BX_LF_MASK_P;
    end;

procedure BX_CPU_C.SET_FLAGS_OSZAPC_8(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word);
begin
  oszapc.op1_8 := op1;
  oszapc.op2_8 := op2;
  oszapc.result_8 := result;
  oszapc.instr := ins;
  lf_flags_status := BX_LF_MASK_OSZAPC;
end;

procedure BX_CPU_C.SET_FLAGS_OSZAPC_8_CF(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word; last_CF:Bool);
begin
  oszapc.op1_8 := op1;
  oszapc.op2_8 := op2;
  oszapc.result_8 := result;
  oszapc.instr := ins;
  oszapc.prev_CF := last_CF;
  lf_flags_status := BX_LF_MASK_OSZAPC;
end;

procedure BX_CPU_C.SET_FLAGS_OSZAP_8(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word);
begin
  oszap.op1_8 := op1;
  oszap.op2_8 := op2;
  oszap.result_8 := result;
  oszap.instr := ins;
  lf_flags_status := (lf_flags_status and $00000f) or BX_LF_MASK_OSZAP;
end;

procedure BX_CPU_C.SET_FLAGS_OSZAP_32(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word);  //INLINE
begin
  oszap.op1_32 :=     op1;
  oszap.op2_32 :=     op2;
  oszap.result_32 :=  result;
  oszap.instr :=      ins;
  lf_flags_status :=  (lf_flags_status and $00000f) or BX_LF_MASK_OSZAP;
end;

procedure BX_CPU_C.SET_FLAGS_OSZAPC_32(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word);
begin
  oszapc.op1_32 := op1;
  oszapc.op2_32 := op2;
  oszapc.result_32 := result;
  oszapc.instr := ins;
  lf_flags_status := BX_LF_MASK_OSZAPC;
end;

procedure BX_CPU_C.SET_FLAGS_OSZAPC_32_CF(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word; last_CF:Bool);
begin
  oszapc.op1_32 := op1;
  oszapc.op2_32 := op2;
  oszapc.result_32 := result;
  oszapc.instr := ins;
  oszapc.prev_CF := last_CF;
  lf_flags_status := BX_LF_MASK_OSZAPC; 
end;

procedure BX_CPU_C.BX_WRITE_32BIT_REG(index:Word; val:bit32u);
begin
  gen_reg[index].erx := val;
end;

procedure BX_CPU_C.SET_FLAGS_OSZAPC_16(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word);
begin
  oszapc.op1_16 := op1;
  oszapc.op2_16 := op2;
  oszapc.result_16 := result;
  oszapc.instr := ins;
  lf_flags_status := BX_LF_MASK_OSZAPC;
end;

procedure BX_CPU_C.SET_FLAGS_OSZAPC_16_CF(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word; last_CF:Bool);
begin
  oszapc.op1_16 := op1;
  oszapc.op2_16 := op2;
  oszapc.result_16 := result;
  oszapc.instr := ins;
  oszapc.prev_CF := last_CF;
  lf_flags_status := BX_LF_MASK_OSZAPC;
end;

procedure BX_CPU_C.SET_FLAGS_OSZAP_16(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word);
begin
  oszap.op1_16 := op1;
  oszap.op2_16 := op2;
  oszap.result_16 := result;
  oszap.instr := ins;
  lf_flags_status := (lf_flags_status and $00000f) or BX_LF_MASK_OSZAP;
end;

procedure BX_CPU_C.SET_FLAGS_OxxxxC(new_of, new_cf:Bool);
begin
  eflags.of_ := new_of;
  eflags.cf :=  new_cf;
  lf_flags_status := lf_flags_status and $0ffff0; 
end;
