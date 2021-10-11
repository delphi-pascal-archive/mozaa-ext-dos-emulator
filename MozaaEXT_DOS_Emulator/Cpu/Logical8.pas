{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.XOR_EbGb(I:PBxInstruction_tag);
var
  op2, op1, result:Bit8u;
begin

  (* op2 is a register, op2_addr is an index of a register *)
  op2 := BX_READ_8BIT_REG(i^.nnn);

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1);
    end;

  result := op1 xor op2;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result);
    end
  else begin
    write_RMW_virtual_byte(result);
    end;

  SET_FLAGS_OSZAPC_8(op1, op2, result, BX_INSTR_XOR8);
end;

procedure BX_CPU_C.XOR_GbEb(I:PBxInstruction_tag);
var
  op2, op1, result:Bit8u;
begin

  op1 := BX_READ_8BIT_REG(i^.nnn);

  (* op2 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op2 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op2);
    end;

  result := op1 xor op2;

  (* now write result back to destination, which is a register *)
  BX_WRITE_8BIT_REG(i^.nnn, result);

  SET_FLAGS_OSZAPC_8(op1, op2, result, BX_INSTR_XOR8);
end;


procedure BX_CPU_C.XOR_ALIb(I:PBxInstruction_tag);
var
  op2, op1, sum:Bit8u;
begin
  op1 := AL;

  op2 := i^.Ib;

  sum := op1 xor op2;

  (* now write sum back to destination, which is a register *)
  AL := sum;

  SET_FLAGS_OSZAPC_8(op1, op2, sum, BX_INSTR_XOR8);
end;


procedure BX_CPU_C.XOR_EbIb(I:PBxInstruction_tag);
var
  op2, op1, result:Bit8u;
begin

  op2 := i^.Ib;

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1);
    end;

  result := op1 xor op2;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result);
    end
  else begin
    write_RMW_virtual_byte(result);
    end;

  SET_FLAGS_OSZAPC_8(op1, op2, result, BX_INSTR_XOR8);
end;

procedure BX_CPU_C.OR_EbIb(I:PBxInstruction_tag);
var
  op2, op1, result:Bit8u;
begin

  op2 := i^.Ib;

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1);
    end;

  result := op1 or op2;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result);
    end
  else begin
    write_RMW_virtual_byte(result);
    end;

  SET_FLAGS_OSZAPC_8(op1, op2, result, BX_INSTR_OR8);
end;


procedure BX_CPU_C.NOT_Eb(I:PBxInstruction_tag);
var
  op1_8, result_8:Bit8u;
begin

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  result_8 := not op1_8; // ~

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_RMW_virtual_byte(result_8);
    end;
end;


procedure BX_CPU_C.OR_EbGb(I:PBxInstruction_tag);
var
  op2, op1, result:Bit8u;
begin

  (* op2 is a register, op2_addr is an index of a register *)
  op2 := BX_READ_8BIT_REG(i^.nnn);

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1);
    end;

  result := op1 or op2;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result);
    end
  else begin
    write_RMW_virtual_byte(result);
    end;

  SET_FLAGS_OSZAPC_8(op1, op2, result, BX_INSTR_OR8);
end;

procedure BX_CPU_C.OR_GbEb(I:PBxInstruction_tag);
var
  op2, op1, result:Bit8u;
begin

  op1 := BX_READ_8BIT_REG(i^.nnn);

  (* op2 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op2 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op2);
    end;

  result := op1 or op2;

  (* now write result back to destination, which is a register *)
  BX_WRITE_8BIT_REG(i^.nnn, result);


  SET_FLAGS_OSZAPC_8(op1, op2, result, BX_INSTR_OR8);
end;

procedure BX_CPU_C.OR_ALIb(I:PBxInstruction_tag);
var
  op1, op2, sum:Bit8u;
begin

  op1 := AL;

  op2 := i^.Ib;

  sum := op1 or op2;

  (* now write sum back to destination, which is a register *)
  AL := sum;

  SET_FLAGS_OSZAPC_8(op1, op2, sum, BX_INSTR_OR8);
end;

procedure BX_CPU_C.AND_EbGb(I:PBxInstruction_tag);
var
  op2, op1, result:Bit8u;
begin

  (* op2 is a register, op2_addr is an index of a register *)
  op2 := BX_READ_8BIT_REG(i^.nnn);

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1);
    end;

  result := op1 and op2;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result);
    end
  else begin
    write_RMW_virtual_byte(result);
    end;

  SET_FLAGS_OSZAPC_8(op1, op2, result, BX_INSTR_AND8);
end;

procedure BX_CPU_C.AND_GbEb(I:PBxInstruction_tag);
var
  op2, op1, result:Bit8u;
begin

  op1 := BX_READ_8BIT_REG(i^.nnn);

  (* op2 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op2 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op2);
    end;

  result := op1 and op2;

  (* now write result back to destination, which is a register *)
  BX_WRITE_8BIT_REG(i^.nnn, result);

  SET_FLAGS_OSZAPC_8(op1, op2, result, BX_INSTR_AND8);
end;


procedure BX_CPU_C.AND_ALIb(I:PBxInstruction_tag);
var
  op1, op2, sum:Bit8u;
begin

  op1 := AL;

  op2 := i^.Ib;

  sum := op1 and op2;

  (* now write sum back to destination, which is a register *)
  AL := sum;

  SET_FLAGS_OSZAPC_8(op1, op2, sum, BX_INSTR_AND8);
end;

procedure BX_CPU_C.AND_EbIb(I:PBxInstruction_tag);
var
  op2, op1, result:Bit8u;
begin

  op2 := i^.Ib;

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1);
    end;

  result := op1 and op2;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result);
    end
  else begin
    write_RMW_virtual_byte(result);
    end;

  SET_FLAGS_OSZAPC_8(op1, op2, result, BX_INSTR_AND8);
end;

procedure BX_CPU_C.TEST_EbGb(I:PBxInstruction_tag);
var
  op2, op1, result:Bit8u;
begin

  (* op2 is a register, op2_addr is an index of a register *)
  op2 := BX_READ_8BIT_REG(i^.nnn);

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op1);
    end;

  result := op1 and op2;

  SET_FLAGS_OSZAPC_8(op1, op2, result, BX_INSTR_TEST8);
end;

procedure BX_CPU_C.TEST_ALIb(I:PBxInstruction_tag);
var
  op2, op1, result:Bit8u;
begin

  (* op1 is the AL register *)
  op1 := AL;

  (* op2 is imm8 *)
  op2 := i^.Ib;

  result := op1 and op2;

  SET_FLAGS_OSZAPC_8(op1, op2, result, BX_INSTR_TEST8);
end;

procedure BX_CPU_C.TEST_EbIb(I:PBxInstruction_tag);
var
  op2, op1, result:Bit8u;
begin

  op2 := i^.Ib;

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op1);
    end;

  result := op1 and op2;

  SET_FLAGS_OSZAPC_8(op1, op2, result, BX_INSTR_TEST8);
end;

