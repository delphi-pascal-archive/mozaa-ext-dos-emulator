{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.XOR_EwGw(I:PBxInstruction_tag);
var
  op2_16, op1_16, result_16:Bit16u;
begin

    (* op2_16 is a register, op2_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    result_16 := op1_16 xor op2_16;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, result_16);
      end
  else begin
      write_RMW_virtual_word(result_16);
      end;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, result_16, BX_INSTR_XOR16);
end;


  procedure
BX_CPU_C.XOR_GwEw(I:PBxInstruction_tag);
var
  op2_16, op1_16, result_16:Bit16u;
begin

    op1_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op2_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;

    result_16 := op1_16 xor op2_16;

    (* now write result back to destination *)
    BX_WRITE_16BIT_REG(i^.nnn, result_16);

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, result_16, BX_INSTR_XOR16);
end;


procedure BX_CPU_C.XOR_AXIw(I:PBxInstruction_tag);
var
  op1_16, op2_16, sum_16:Bit16u;
begin

    op1_16 := AX;

    op2_16 := i^.Iw;

    sum_16 := op1_16 xor op2_16;

    (* now write sum back to destination *)
    AX := sum_16;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, sum_16, BX_INSTR_XOR16);
end;

procedure BX_CPU_C.XOR_EwIw(I:PBxInstruction_tag);
var
  op2_16, op1_16, result_16:Bit16u;
begin

    op2_16 := i^.Iw;

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    result_16 := op1_16 xor op2_16;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, result_16);
      end
  else begin
      write_RMW_virtual_word(result_16);
      end;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, result_16, BX_INSTR_XOR16);
end;


procedure BX_CPU_C.OR_EwIw(I:PBxInstruction_tag);
var
  op2_16, op1_16, result_16:Bit16u;
begin

    op2_16 := i^.Iw;

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    result_16 := op1_16 or op2_16;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, result_16);
      end
  else begin
      write_RMW_virtual_word(result_16);
      end;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, result_16, BX_INSTR_OR16);
end;


procedure BX_CPU_C.NOT_Ew(I:PBxInstruction_tag);
var
  op1_16, result_16:Bit16u;
begin

    (* op1 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    result_16 := not op1_16; // ~

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, result_16);
      end
  else begin
      write_RMW_virtual_word(result_16);
      end;
end;


procedure BX_CPU_C.OR_EwGw(I:PBxInstruction_tag);
var
  op2_16, op1_16, result_16:Bit16u;
begin

    (* op2_16 is a register, op2_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    result_16 := op1_16 or op2_16;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, result_16);
      end
  else begin
      write_RMW_virtual_word(result_16);
      end;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, result_16, BX_INSTR_OR16);
end;


procedure BX_CPU_C.OR_GwEw(I:PBxInstruction_tag);
var
  op2_16, op1_16, result_16:Bit16u;
begin

    op1_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op2_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;

    result_16 := op1_16 or op2_16;

    (* now write result back to destination *)
    BX_WRITE_16BIT_REG(i^.nnn, result_16);

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, result_16, BX_INSTR_OR16);
end;

procedure BX_CPU_C.OR_AXIw(I:PBxInstruction_tag);
var
  op1_16, op2_16, sum_16:Bit16u;
begin

    op1_16 := AX;

    op2_16 := i^.Iw;

    sum_16 := op1_16 or op2_16;

    (* now write sum back to destination *)
    AX := sum_16;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, sum_16, BX_INSTR_OR16);
end;

procedure BX_CPU_C.AND_EwGw(I:PBxInstruction_tag);
var
  op2_16, op1_16, result_16:Bit16u;
begin

    (* op2_16 is a register, op2_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    result_16 := op1_16 and op2_16;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, result_16);
      end
  else begin
      write_RMW_virtual_word(result_16);
      end;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, result_16, BX_INSTR_AND16);
end;


procedure BX_CPU_C.AND_GwEw(I:PBxInstruction_tag);
var
  op2_16, op1_16, result_16:Bit16u;
begin

    op1_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op2_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;

    result_16 := op1_16 and op2_16;

    (* now write result back to destination *)
    BX_WRITE_16BIT_REG(i^.nnn, result_16);

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, result_16, BX_INSTR_AND16);
end;


  procedure
BX_CPU_C.AND_AXIw(I:PBxInstruction_tag);
var
  op1_16, op2_16, sum_16:Bit16u;
begin

    op1_16 := AX;

    op2_16 := i^.Iw;

    sum_16 := op1_16 and op2_16;

    (* now write sum back to destination *)
    AX := sum_16;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, sum_16, BX_INSTR_AND16);
end;

procedure BX_CPU_C.AND_EwIw(I:PBxInstruction_tag);
var
  op2_16, op1_16, result_16:Bit16u;
begin

    op2_16 := i^.Iw;

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    result_16 := op1_16 and op2_16;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, result_16);
      end
  else begin
      write_RMW_virtual_word(result_16);
      end;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, result_16, BX_INSTR_AND16);
end;


procedure BX_CPU_C.TEST_EwGw(I:PBxInstruction_tag);
var
  op2_16, op1_16, result_16:Bit16u;
begin

    (* op2_16 is a register, op2_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    result_16 := op1_16 and op2_16;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, result_16, BX_INSTR_TEST16);
end;

procedure BX_CPU_C.TEST_AXIw(I:PBxInstruction_tag);
var
  op2_16, op1_16, result_16:Bit16u;
begin

    op1_16 := AX;

    (* op2_16 is imm16 *)
    op2_16 := i^.Iw;

    result_16 := op1_16 and op2_16;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, result_16, BX_INSTR_TEST16);
end;

procedure BX_CPU_C.TEST_EwIw(I:PBxInstruction_tag);
var
  op2_16, op1_16, result_16:Bit16u;
begin

    (* op2_16 is imm16 *)
    op2_16 := i^.Iw;

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    result_16 := op1_16 and op2_16;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, result_16, BX_INSTR_TEST16);
end;

