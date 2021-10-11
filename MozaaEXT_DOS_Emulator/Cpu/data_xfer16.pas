{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.MOV_RXIw(I:PBxInstruction_tag);
begin
  self.gen_reg[i^.b1 and $07].rx := i^.Iw;
end;

procedure BX_CPU_C.XCHG_RXAX(I:PBxInstruction_tag);
var
  temp16:Bit16u;
begin

  temp16 := AX;
  AX := self.gen_reg[i^.b1  and $07].rx;
  self.gen_reg[i^.b1  and $07].rx := temp16;
end;

procedure BX_CPU_C.MOV_EwGw(I:PBxInstruction_tag);
var
  op2_16:Bit16u;
begin

    (* op2_16 is a register, op2_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1_16 is a register or memory reference *)
    (* now write op2 to op1 *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, op2_16);
      end
  else begin
      write_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;
end;

procedure BX_CPU_C.MOV_GwEw(I:PBxInstruction_tag);
var
  op2_16:Bit16u;
begin

    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;

    BX_WRITE_16BIT_REG(i^.nnn, op2_16);
end;

procedure BX_CPU_C.MOV_EwSw(I:PBxInstruction_tag);
var
  seg_reg:Bit16u;
begin

{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('MOV_EwSw: incomplete for CPU < 3'));
{$ifend}

  seg_reg := self.sregs[i^.nnn].selector.value;

  if (i^.mod_ = $c0) then begin
    // ??? BX_WRITE_16BIT_REG(mem_addr, seg_reg);
    if ( i^.os_32 )<>0 then begin
      BX_WRITE_32BIT_REG(i^.rm, seg_reg);
      end
  else begin
      BX_WRITE_16BIT_REG(i^.rm, seg_reg);
      end;
    end
  else begin
    write_virtual_word(i^.seg, i^.rm_addr, @seg_reg);
    end;
end;

procedure BX_CPU_C.MOV_SwEw(I:PBxInstruction_tag);
var
  op2_16:Bit16u;
begin

{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('MOV_SwEw: incomplete for CPU < 3'));
{$ifend}

  if (i^.mod_ = $c0) then begin
    op2_16 := BX_READ_16BIT_REG(i^.rm);
    end
  else begin
    read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
    end;

  load_seg_reg(@self.sregs[i^.nnn], op2_16);

  if (i^.nnn = BX_SEG_REG_SS) then begin
    // MOV SS inhibits interrupts, debug exceptions and single-step
    // trap exceptions until the execution boundary following the
    // next instruction is reached.
    // Same code as POP_SS()
    self.inhibit_mask := self.inhibit_mask or BX_INHIBIT_INTERRUPTS or BX_INHIBIT_DEBUG;
    self.async_event := 1;
    end;
end;

procedure BX_CPU_C.LEA_GwM(I:PBxInstruction_tag);
begin
  if (i^.mod_ = $c0) then begin
    BX_PANIC(('LEA_GvM: op2 is a register'));
    UndefinedOpcode(i);
    exit;
    end;

    BX_WRITE_16BIT_REG(i^.nnn, Bit16u(i^.rm_addr));
end;

procedure BX_CPU_C.MOV_AXOw(I:PBxInstruction_tag);
var
  temp_16:Bit16u;
  addr_32:Bit32u;
begin

  addr_32 := i^.Id;

  (* read from memory address *)

  if ((i^.seg and BX_SEG_REG_NULL)=0) then begin
    read_virtual_word(i^.seg, addr_32, @temp_16);
    end
  else begin
    read_virtual_word(BX_SEG_REG_DS, addr_32, @temp_16);
    end;

  (* write to register *)
  AX := temp_16;
end;

procedure BX_CPU_C.MOV_OwAX(I:PBxInstruction_tag);
var
  temp_16:Bit16u;
  addr_32:Bit32u;
begin

  addr_32 := i^.Id;

  (* read from register *)
  temp_16 := AX;

  (* write to memory address *)
  if ((i^.seg and BX_SEG_REG_NULL)=0) then begin
    write_virtual_word(i^.seg, addr_32, @temp_16);
    end
  else begin
    write_virtual_word(BX_SEG_REG_DS, addr_32, @temp_16);
    end;
end;

procedure BX_CPU_C.MOV_EwIw(I:PBxInstruction_tag);
var
  op2_16:Bit16u;
begin

    op2_16 := i^.Iw;

    (* now write sum back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, op2_16);
      end
  else begin
      write_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;
end;

procedure BX_CPU_C.MOVZX_GwEb(I:PBxInstruction_tag);
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

    (* zero extend byte op2 into word op1 *)
    BX_WRITE_16BIT_REG(i^.nnn, (Bit16u(op2_8)));
{$ifend} (* BX_CPU_LEVEL < 3 *)
end;

procedure BX_CPU_C.MOVZX_GwEw(I:PBxInstruction_tag);
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

    (* normal move *)
    BX_WRITE_16BIT_REG(i^.nnn, op2_16);
{$ifend} (* BX_CPU_LEVEL < 3 *)
end;

procedure BX_CPU_C.MOVSX_GwEb(I:PBxInstruction_tag);
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

    (* sign extend byte op2 into word op1 *)
    BX_WRITE_16BIT_REG(i^.nnn, (Bit8s(op2_8)));
{$ifend} (* BX_CPU_LEVEL < 3 *)
end;

procedure BX_CPU_C.MOVSX_GwEw(I:PBxInstruction_tag);
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

    (* normal move *)
    BX_WRITE_16BIT_REG(i^.nnn, op2_16);
{$ifend} (* BX_CPU_LEVEL < 3 *)
end;

procedure BX_CPU_C.XCHG_EwGw(I:PBxInstruction_tag);
var
  op2_16, op1_16:Bit16u;
begin

//#ifdef MAGIC_BREAKPOINT
{$if BX_DEBUGGER=01}
  // (mch) Magic break point
  if (i^.nnn = 3 @ and i^.mod_ = $c0 @ and i^.rm = 3) then begin
    self.magic_break := 1;
    end;
{$ifend}
//{$ifend}

    (* op2_16 is a register, op2_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      BX_WRITE_16BIT_REG(i^.rm, op2_16);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      write_RMW_virtual_word(op2_16);
      end;

    BX_WRITE_16BIT_REG(i^.nnn, op1_16);
end;

procedure BX_CPU_C.CMOV_GwEw(I:PBxInstruction_tag);
begin
{$if (BX_CPU_LEVEL >= 6) or (BX_CPU_LEVEL_HACKED >= 6)}
  // Note: CMOV accesses a memory source operand (read), regardless
  //       of whether condition is true or not.  Thus, exceptions may
  //       occur even if the MOV does not take place.

  Boolean condition;
  Bit16u op2_16;

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
      BX_PANIC(('CMOV_GwEw: default case'));
    end;

  if (i^.mod_ = $c0) then begin
    op2_16 := BX_READ_16BIT_REG(i^.rm);
    end;
  else begin
    (* pointer, segment address pair *)
    read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
    end;

  if (condition) then begin
    BX_WRITE_16BIT_REG(i^.nnn, op2_16);
    end;
{$else}
  BX_PANIC(('cmov_gwew called'));
{$ifend}
end;
