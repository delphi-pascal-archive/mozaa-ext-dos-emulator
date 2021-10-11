{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.XCHG_ERXEAX(I:PBxInstruction_tag);
var
  temp32:Bit32u;
begin
  temp32 := EAX;
  EAX := self.gen_reg[i^.b1 and $07].erx;
  self.gen_reg[i^.b1 and $07].erx := temp32;
end;

procedure BX_CPU_C.MOV_ERXId(I:PBxInstruction_tag);
begin
  self.gen_reg[i^.b1  and $07].erx := i^.Id;
end;

procedure BX_CPU_C.MOV_EdGd(I:PBxInstruction_tag);
var
  op2_32:Bit32u;
begin

    (* op2_32 is a register, op2_addr is an index of a register *)
    op2_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op1_32 is a register or memory reference *)
    (* now write op2 to op1 *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, op2_32);
      end
  else begin
      write_virtual_dword(i^.seg, i^.rm_addr, @op2_32);
      end;
end;

procedure BX_CPU_C.MOV_GdEd(I:PBxInstruction_tag);
var
  op2_32:Bit32u;
begin

    if (i^.mod_ = $c0) then begin
      op2_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op2_32);
      end;

    BX_WRITE_32BIT_REG(i^.nnn, op2_32);
end;

procedure BX_CPU_C.LEA_GdM(I:PBxInstruction_tag);
begin
  if (i^.mod_ = $c0) then begin
    BX_PANIC(('LEA_GvM: op2 is a register'));
    UndefinedOpcode(i);
    exit;
    end;

    (* write effective address of op2 in op1 *)
    BX_WRITE_32BIT_REG(i^.nnn, i^.rm_addr);
end;

procedure BX_CPU_C.MOV_EAXOd(I:PBxInstruction_tag);
var
  temp_32:Bit32u;
  addr_32:Bit32u;
begin

  addr_32 := i^.Id;

  (* read from memory address *)

  if ((i^.seg and BX_SEG_REG_NULL)=0) then begin
    read_virtual_dword(i^.seg, addr_32, @temp_32);
    end
  else begin
    read_virtual_dword(BX_SEG_REG_DS, addr_32, @temp_32);
    end;

  (* write to register *)
  EAX := temp_32;
end;

procedure BX_CPU_C.MOV_OdEAX(I:PBxInstruction_tag);
var
  temp_32:Bit32u;
  addr_32:Bit32u;
begin

  addr_32 := i^.Id;

  (* read from register *)
  temp_32 := EAX;

  (* write to memory address *)
  if ((i^.seg and BX_SEG_REG_NULL)=0) then begin
    write_virtual_dword(i^.seg, addr_32, @temp_32);
    end
  else begin
    write_virtual_dword(BX_SEG_REG_DS, addr_32, @temp_32);
    end;
end;

procedure BX_CPU_C.MOV_EdId(I:PBxInstruction_tag);
var
  op2_32:Bit32u;
begin

    op2_32 := i^.Id;

    (* now write sum back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, op2_32);
      end
  else begin
      write_virtual_dword(i^.seg, i^.rm_addr, @op2_32);
      end;
end;

procedure BX_CPU_C.MOVZX_GdEb(I:PBxInstruction_tag);
var
  op2_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('MOVZX_GvEb: not supported on < 386'));
{$else}

  if (i^.mod_ = $c0) then begin
    op2_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op2_8);
    end;

    (* zero extend byte op2 into dword op1 *)
    BX_WRITE_32BIT_REG(i^.nnn, Bit32u(op2_8));
{$ifend} (* BX_CPU_LEVEL < 3 *)
end;

procedure BX_CPU_C.MOVZX_GdEw(I:PBxInstruction_tag);
var
  op2_16:Bit16u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('MOVZX_GvEw: not supported on < 386'));
{$else}

  if (i^.mod_ = $c0) then begin
    op2_16 := BX_READ_16BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
    end;

    (* zero extend word op2 into dword op1 *)
    BX_WRITE_32BIT_REG(i^.nnn, Bit32u(op2_16));
{$ifend} (* BX_CPU_LEVEL < 3 *)
end;

procedure BX_CPU_C.MOVSX_GdEb(I:PBxInstruction_tag);
var
  op2_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('MOVSX_GvEb: not supported on < 386'));
{$else}

  if (i^.mod_ = $c0) then begin
    op2_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op2_8);
    end;

    (* sign extend byte op2 into dword op1 *)
    BX_WRITE_32BIT_REG(i^.nnn, Bit8s(op2_8));
{$ifend} (* BX_CPU_LEVEL < 3 *)
end;

procedure BX_CPU_C.MOVSX_GdEw(I:PBxInstruction_tag);
var
  op2_16:Bit16u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('MOVSX_GvEw: not supported on < 386'));
{$else}

  if (i^.mod_ = $c0) then begin
    op2_16 := BX_READ_16BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
    end;

    (* sign extend word op2 into dword op1 *)
    BX_WRITE_32BIT_REG(i^.nnn, Bit16s(op2_16));
{$ifend} (* BX_CPU_LEVEL < 3 *)
end;

procedure BX_CPU_C.XCHG_EdGd(I:PBxInstruction_tag);
var
  op2_32, op1_32:Bit32u;
begin

    (* op2_32 is a register, op2_addr is an index of a register *)
    op2_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      BX_WRITE_32BIT_REG(i^.rm, op2_32);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      write_RMW_virtual_dword(op2_32);
      end;

    BX_WRITE_32BIT_REG(i^.nnn, op1_32);
end;

procedure BX_CPU_C.CMOV_GdEd(I:PBxInstruction_tag);
var
  condition:Bool;
  op2_32:Bit32u;
begin
{$if (BX_CPU_LEVEL >= 6) or (BX_CPU_LEVEL_HACKED >= 6) }
  // Note: CMOV accesses a memory source operand (read), regardless
  //       of whether condition is true or not.  Thus, exceptions may
  //       occur even if the MOV does not take place.


  switch (i^.b1) then begin
    // CMOV opcodes:
    case $140: condition := get_OF(); break;
    case $141: condition := !get_OF(); break;
    case $142: condition := get_CF(); break;
    case $143: condition := !get_CF(); break;
    case $144: condition := get_ZF(); break;
    case $145: condition := !get_ZF(); break;
    case $146: condition := get_CF() or get_ZF(); break;
    case $147: condition := !get_CF() @ and !get_ZF(); break;
    case $148: condition := get_SF(); break;
    case $149: condition := !get_SF(); break;
    case $14A: condition := get_PF(); break;
    case $14B: condition := !get_PF(); break;
    case $14C: condition := get_SF() !:= get_OF(); break;
    case $14D: condition := get_SF() = get_OF(); break;
    case $14E: condition := get_ZF() or (get_SF() !:= get_OF()); break;
    case $14F: condition := !get_ZF() @ and (get_SF() = get_OF()); break;
    default:
      condition := 0;
      BX_PANIC(('CMOV_GdEd: default case'));
    end;

  if (i^.mod_ = $c0) then begin
    op2_32 := BX_READ_32BIT_REG(i^.rm);
    end;
  else begin
    (* pointer, segment address pair *)
    read_virtual_dword(i^.seg, i^.rm_addr, @op2_32);
    end;

  if (condition) then begin
    BX_WRITE_32BIT_REG(i^.nnn, op2_32);
    end;
{$else}
  BX_PANIC(('cmov_gded called'));
{$ifend}
end;
