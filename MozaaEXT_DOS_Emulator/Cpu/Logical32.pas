{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

  procedure
BX_CPU_C.XOR_EdGd(I:PBxInstruction_tag);
var
  op2_32, op1_32, result_32:Bit32u;
begin

    (* op2_32 is a register, op2_addr is an index of a register *)
    op2_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    result_32 := op1_32 xor op2_32;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, result_32);
      end
  else begin
      write_RMW_virtual_dword(result_32);
      end;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, result_32, BX_INSTR_XOR32);
end;


procedure BX_CPU_C.XOR_GdEd(I:PBxInstruction_tag);
var
  op2_32, op1_32, result_32:Bit32u;
begin

    op1_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op2_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op2_32);
      end;

    result_32 := op1_32 xor op2_32;

    (* now write result back to destination *)
    BX_WRITE_32BIT_REG(i^.nnn, result_32);

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, result_32, BX_INSTR_XOR32);
end;

procedure BX_CPU_C.XOR_EAXId(I:PBxInstruction_tag);
var
  op1_32, op2_32, sum_32:Bit32u;
begin
    (* for 32 bit operand size mod_e *)

    op1_32 := EAX;

    op2_32 := i^.Id;

    sum_32 := op1_32 xor op2_32;

    (* now write sum back to destination *)
    EAX := sum_32;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, sum_32, BX_INSTR_XOR32);
end;

procedure BX_CPU_C.XOR_EdId(I:PBxInstruction_tag);
var
  op2_32, op1_32, result_32:Bit32u;
begin

    op2_32 := i^.Id;

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    result_32 := op1_32 xor op2_32;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, result_32);
      end
  else begin
      write_RMW_virtual_dword(result_32);
      end;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, result_32, BX_INSTR_XOR32);
end;


procedure BX_CPU_C.OR_EdId(I:PBxInstruction_tag);
var
  op2_32, op1_32, result_32:Bit32u;
begin

    op2_32 := i^.Id;

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    result_32 := op1_32 or op2_32;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, result_32);
      end
  else begin
      write_RMW_virtual_dword(result_32);
      end;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, result_32, BX_INSTR_OR32);
end;

procedure BX_CPU_C.NOT_Ed(I:PBxInstruction_tag);
var
  op1_32, result_32:Bit32u;
begin

    (* op1 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    result_32 := not op1_32; //~

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, result_32);
      end
  else begin
      write_RMW_virtual_dword(result_32);
      end;
end;


procedure BX_CPU_C.OR_EdGd(I:PBxInstruction_tag);
var
  op2_32, op1_32, result_32:Bit32u;
begin
    (* op2_32 is a register, op2_addr is an index of a register *)
    op2_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    result_32 := op1_32 or op2_32;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, result_32);
      end
  else begin
      write_RMW_virtual_dword(result_32);
      end;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, result_32, BX_INSTR_OR32);
end;

procedure BX_CPU_C.OR_GdEd(I:PBxInstruction_tag);
var
  op2_32, op1_32, result_32:Bit32u;
begin

    op1_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op2_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op2_32);
      end;

    result_32 := op1_32 or op2_32;

    (* now write result back to destination *)
    BX_WRITE_32BIT_REG(i^.nnn, result_32);

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, result_32, BX_INSTR_OR32);
end;

procedure BX_CPU_C.OR_EAXId(I:PBxInstruction_tag);
var
  op1_32, op2_32, sum_32:Bit32u;
begin

    op1_32 := EAX;

    op2_32 := i^.Id;

    sum_32 := op1_32 or op2_32;

    (* now write sum back to destination *)
    EAX := sum_32;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, sum_32, BX_INSTR_OR32);
end;

procedure BX_CPU_C.AND_EdGd(I:PBxInstruction_tag);
var
  op2_32, op1_32, result_32:Bit32u;
begin
    (* op2_32 is a register, op2_addr is an index of a register *)
    op2_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    result_32 := op1_32  and op2_32;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, result_32);
      end
  else begin
      write_RMW_virtual_dword(result_32);
      end;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, result_32, BX_INSTR_AND32);
end;


  procedure
BX_CPU_C.AND_GdEd(I:PBxInstruction_tag);
var
  op2_32, op1_32, result_32:Bit32u;
begin

    op1_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op2_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op2_32);
      end;

    result_32 := op1_32  and op2_32;

    (* now write result back to destination *)
    BX_WRITE_32BIT_REG(i^.nnn, result_32);

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, result_32, BX_INSTR_AND32);
end;


  procedure
BX_CPU_C.AND_EAXId(I:PBxInstruction_tag);
var
  op1_32, op2_32, sum_32:Bit32u;
begin

    op1_32 := EAX;

    op2_32 := i^.Id;

    sum_32 := op1_32  and op2_32;

    (* now write sum back to destination *)
    EAX := sum_32;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, sum_32, BX_INSTR_AND32);
end;

procedure BX_CPU_C.AND_EdId(I:PBxInstruction_tag);
var
  op2_32, op1_32, result_32:Bit32u;
begin

    op2_32 := i^.Id;

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    result_32 := op1_32  and op2_32;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, result_32);
      end
  else begin
      write_RMW_virtual_dword(result_32);
      end;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, result_32, BX_INSTR_AND32);
end;


procedure BX_CPU_C.TEST_EdGd(I:PBxInstruction_tag);
var
  op2_32, op1_32, result_32:Bit32u;
begin

    (* op2_32 is a register, op2_addr is an index of a register *)
    op2_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    result_32 := op1_32  and op2_32;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, result_32, BX_INSTR_TEST32);
end;

procedure BX_CPU_C.TEST_EAXId(I:PBxInstruction_tag);
var
  op2_32, op1_32, result_32:Bit32u;
begin

    (* op1 is EAX register *)
    op1_32 := EAX;

    (* op2 is imm32 *)
    op2_32 := i^.Id;

    result_32 := op1_32  and op2_32;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, result_32, BX_INSTR_TEST32);
end;

procedure BX_CPU_C.TEST_EdId(I:PBxInstruction_tag);
var
  op2_32, op1_32, result_32:Bit32u;
begin

    (* op2 is imm32 *)
    op2_32 := i^.Id;

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    result_32 := op1_32  and op2_32;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, result_32, BX_INSTR_TEST32);
end;

