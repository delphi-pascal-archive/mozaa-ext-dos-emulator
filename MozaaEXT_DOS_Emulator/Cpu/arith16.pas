{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
procedure BX_CPU_C.INC_RX(i:PBxInstruction_tag);
var
  rx:Bit16u;
begin
  Inc(gen_reg[i^.b1 and $07].rx);
  rx := gen_reg[i^.b1 and $07].rx;
  SET_FLAGS_OSZAP_16(0, 0, rx, BX_INSTR_INC16);
end;

procedure BX_CPU_C.DEC_RX(i:PBxInstruction_tag);
var
  rx:Bit16u;
begin
  Dec(gen_reg[i^.b1 and $07].rx);
  rx := gen_reg[i^.b1 and $07].rx;
  SET_FLAGS_OSZAP_16(0, 0, rx, BX_INSTR_DEC16);
end;

procedure BX_CPU_C.ADD_EwGw(i:PBxInstruction_tag);
var
  op2_16, op1_16, sum_16:Bit16u;
begin

    (* op2_16 is a register, i^.rm_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    sum_16 := op1_16 + op2_16;

    (* now write sum back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, sum_16);
      end
    else begin
      write_virtual_word(i^.seg, i^.rm_addr, @sum_16);
      end;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, sum_16, BX_INSTR_ADD16);
end;


procedure BX_CPU_C.ADD_GwEw(i:PBxInstruction_tag);
var
  op1_16, op2_16, sum_16:Bit16u;
begin

    (* op1_16 is a register, i^.rm_addr is an index of a register *)
    op1_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op2_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;

    sum_16 := op1_16 + op2_16;
    (* now write sum back to destination *)

    BX_WRITE_16BIT_REG(i^.nnn, sum_16);

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, sum_16, BX_INSTR_ADD16);
end;


procedure BX_CPU_C.ADD_AXIw(i:PBxInstruction_tag);
var
  op1_16, op2_16, sum_16:Bit16u;
begin

    op1_16 := AX;

    op2_16 := i^.Iw;

    sum_16 := op1_16 + op2_16;

    (* now write sum back to destination *)
    AX := sum_16;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, sum_16, BX_INSTR_ADD16);
end;

procedure BX_CPU_C.ADC_EwGw(i:PBxInstruction_tag);
var
  temp_CF:Bool;
  op2_16, op1_16, sum_16:Bit16u;
begin

  temp_CF := get_CF();

    (* op2_16 is a register, i^.rm_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    sum_16 := op1_16 + op2_16 + temp_CF;

    (* now write sum back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, sum_16);
      end
    else begin
      write_RMW_virtual_word(sum_16);
      end;

    SET_FLAGS_OSZAPC_16_CF(op1_16, op2_16, sum_16, BX_INSTR_ADC16,
                              temp_CF);
end;

procedure BX_CPU_C.ADC_GwEw(i:PBxInstruction_tag);
var
  temp_CF:Bool;
  op2_16, op1_16, sum_16:Bit16u;
begin

  temp_CF := get_CF();


    (* op1_16 is a register, i^.rm_addr is an index of a register *)
    op1_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op2_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;

    sum_16 := op1_16 + op2_16 + temp_CF;

    (* now write sum back to destination *)
    BX_WRITE_16BIT_REG(i^.nnn, sum_16);

    SET_FLAGS_OSZAPC_16_CF(op1_16, op2_16, sum_16, BX_INSTR_ADC16,
                             temp_CF);
end;

procedure BX_CPU_C.ADC_AXIw(i:PBxInstruction_tag);
var
  temp_CF:Bool;
  op2_16, op1_16, sum_16:Bit16u;
begin

    temp_CF := get_CF();

    op1_16 := AX;

    op2_16 := i^.Iw;

    sum_16 := op1_16 + op2_16 + temp_CF;

    (* now write sum back to destination *)
    AX := sum_16;

    SET_FLAGS_OSZAPC_16_CF(op1_16, op2_16, sum_16, BX_INSTR_ADC16,
                           temp_CF);
end;

procedure BX_CPU_C.SBB_EwGw(i:PBxInstruction_tag);
var
  temp_CF:Bool;
  op2_16, op1_16, sum_16, diff_16:Bit16u;
begin

  temp_CF := get_CF();


    (* op2_16 is a register, i^.rm_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    diff_16 := op1_16 - (op2_16 + temp_CF);

    (* now write diff back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, diff_16);
      end
    else begin
      write_RMW_virtual_word(diff_16);
      end;

    SET_FLAGS_OSZAPC_16_CF(op1_16, op2_16, diff_16, BX_INSTR_SBB16,
                              temp_CF);
end;

procedure BX_CPU_C.SBB_GwEw(i:PBxInstruction_tag);
var
  temp_CF:Bool;
  op2_16, op1_16, sum_16, diff_16:Bit16u;
begin

  temp_CF := get_CF();

    (* op1_16 is a register, i^.rm_addr is an index of a register *)
    op1_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op2_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;

    diff_16 := op1_16 - (op2_16 + temp_CF);

    (* now write diff back to destination *)
    BX_WRITE_16BIT_REG(i^.nnn, diff_16);

    SET_FLAGS_OSZAPC_16_CF(op1_16, op2_16, diff_16, BX_INSTR_SBB16,
                              temp_CF);
end;

procedure BX_CPU_C.SBB_AXIw(i:PBxInstruction_tag);
var
  temp_CF:Bool;
  op2_16, op1_16, sum_16, diff_16:Bit16u;
begin

  temp_CF := get_CF();


    op1_16 := AX;

    op2_16 := i^.Iw;

    diff_16 := op1_16 - (op2_16 + temp_CF);

    (* now write diff back to destination *)
    AX := diff_16;

    SET_FLAGS_OSZAPC_16_CF(op1_16, op2_16, diff_16, BX_INSTR_SBB16,
                              temp_CF);
end;

procedure BX_CPU_C.SBB_EwIw(i:PBxInstruction_tag);
var
  temp_CF:Bool;
  op2_16, op1_16, sum_16, diff_16:Bit16u;
begin

  temp_CF := get_CF();

    op2_16 := i^.Iw;

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    diff_16 := op1_16 - (op2_16 + temp_CF);

    (* now write diff back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, diff_16);
      end
    else begin
      write_RMW_virtual_word(diff_16);
      end;

    SET_FLAGS_OSZAPC_16_CF(op1_16, op2_16, diff_16, BX_INSTR_SBB16,
                              temp_CF);
end;


procedure BX_CPU_C.SUB_EwGw(i:PBxInstruction_tag);
var
  op2_16, op1_16, diff_16:Bit16u;
begin

    (* op2_16 is a register, i^.rm_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    diff_16 := op1_16 - op2_16;

    (* now write diff back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, diff_16);
      end
    else begin
      write_RMW_virtual_word(diff_16);
      end;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_INSTR_SUB16);
end;

procedure BX_CPU_C.SUB_GwEw(i:PBxInstruction_tag);
var
  op2_16, op1_16, diff_16:Bit16u;
begin

    (* op1_16 is a register, i^.rm_addr is an index of a register *)
    op1_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op2_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;

    diff_16 := op1_16 - op2_16;

    (* now write diff back to destination *)
    BX_WRITE_16BIT_REG(i^.nnn, diff_16);

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_INSTR_SUB16);
end;

procedure BX_CPU_C.SUB_AXIw(i:PBxInstruction_tag);
var
  op1_16, op2_16, diff_16:Bit16u;
begin

    op1_16 := AX;

    op2_16 := i^.Iw;

    diff_16 := op1_16 - op2_16;


    (* now write diff back to destination *)
    AX := diff_16;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_INSTR_SUB16);
end;


procedure BX_CPU_C.CMP_EwGw(i:PBxInstruction_tag);
var
  op1_16, op2_16, diff_16:Bit16u;
begin

    (* op2_16 is a register, i^.rm_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    diff_16 := op1_16 - op2_16;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_INSTR_CMP16);
end;


procedure BX_CPU_C.CMP_GwEw(i:PBxInstruction_tag);
var
  op1_16, op2_16, diff_16:Bit16u;
begin

    (* op1_16 is a register, i^.rm_addr is an index of a register *)
    op1_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op2_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;

    diff_16 := op1_16 - op2_16;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_INSTR_CMP16);
end;

procedure BX_CPU_C.CMP_AXIw(i:PBxInstruction_tag);
var
  op1_16, op2_16, diff_16:Bit16u;
begin

    op1_16 := AX;

    op2_16 := i^.Iw;

    diff_16 := op1_16 - op2_16;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_INSTR_CMP16);
end;

procedure BX_CPU_C.CBW(i:PBxInstruction_tag);
begin
  (* CBW: no flags are effected *)

  AX := Bit8s(AL);
end;

procedure BX_CPU_C.CWD(i:PBxInstruction_tag);
begin
  (* CWD: no flags are affected *)

    if (AX and $8000)<>0 then begin
      DX := $FFFF;
      end
    else begin
      DX := $0000;
      end;
end;


procedure BX_CPU_C.XADD_EwGw(i:PBxInstruction_tag);
var
  op2_16, op1_16, sum_16:Bit16u;
begin
{$if (BX_CPU_LEVEL >= 4) or (BX_CPU_LEVEL_HACKED >= 4)}


    (* XADD dst(r/m), src(r)
     * temp <-- src + dst         | sum := op2 + op1
     * src  <-- dst               | op2 := op1
     * dst  <-- tmp               | op1 := sum
     *)

    (* op2 is a register, i^.rm_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    sum_16 := op1_16 + op2_16;

    (* now write sum back to destination *)
    if (i^.mod_ = $c0) then begin
      // and write destination into source
      // Note: if both op1 and op2 are registers, the last one written
      //       should be the sum, as op1 and op2 may be the same register.
      //       For example:  XADD AL, AL
      BX_WRITE_16BIT_REG(i^.nnn, op1_16);
      BX_WRITE_16BIT_REG(i^.rm, sum_16);
      end
    else begin
      write_RMW_virtual_word(sum_16);
      (* and write destination into source *)
      BX_WRITE_16BIT_REG(i^.nnn, op1_16);
      end;


    SET_FLAGS_OSZAPC_16(op1_16, op2_16, sum_16, BX_INSTR_XADD16);
{$else}
  BX_PANIC(('XADD_EvGv: not supported on < 80486'));
{$ifend}
end;

procedure BX_CPU_C.ADD_EwIw(i:PBxInstruction_tag);
var
  op2_16, op1_16, sum_16:Bit16u;
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

    sum_16 := op1_16 + op2_16;

    (* now write sum back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, sum_16);
      end
    else begin
      write_RMW_virtual_word(sum_16);
      end;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, sum_16, BX_INSTR_ADD16);
end;

procedure BX_CPU_C.ADC_EwIw(i:PBxInstruction_tag);
var
  temp_CF:Bool;
  op2_16, op1_16, sum_16:Bit16u;
begin

  temp_CF := get_CF();


    op2_16 := i^.Iw;

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    sum_16 := op1_16 + op2_16 + temp_CF;

    (* now write sum back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, sum_16);
      end
    else begin
      write_RMW_virtual_word(sum_16);
      end;

    SET_FLAGS_OSZAPC_16_CF(op1_16, op2_16, sum_16, BX_INSTR_ADC16,
                              temp_CF);
end;

procedure BX_CPU_C.SUB_EwIw(i:PBxInstruction_tag);
var
  op2_16, op1_16, diff_16:Bit16u;
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

    diff_16 := op1_16 - op2_16;

    (* now write diff back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, diff_16);
      end
    else begin
      write_RMW_virtual_word(diff_16);
      end;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_INSTR_SUB16);
end;

procedure BX_CPU_C.CMP_EwIw(i:PBxInstruction_tag);
var
  op2_16, op1_16, diff_16:Bit16u;
begin

    op2_16 := i^.Iw;

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    diff_16 := op1_16 - op2_16;

    SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_INSTR_CMP16);
end;

procedure BX_CPU_C.NEG_Ew(i:PBxInstruction_tag);
var
  op2_16, op1_16, diff_16:Bit16u;
begin

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    diff_16 := 0 - op1_16;

    (* now write diff back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, diff_16);
      end
    else begin
      write_RMW_virtual_word(diff_16);
      end;

    SET_FLAGS_OSZAPC_16(op1_16, 0, diff_16, BX_INSTR_NEG16);
end;

procedure BX_CPU_C.INC_Ew(i:PBxInstruction_tag);
var
  op1_16:Bit16u;
begin

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    inc(op1_16);

    (* now write sum back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, op1_16);
      end
    else begin
      write_RMW_virtual_word(op1_16);
      end;

    SET_FLAGS_OSZAP_16(0, 0, op1_16, BX_INSTR_INC16);
end;


procedure BX_CPU_C.DEC_Ew(i:PBxInstruction_tag);
var
  op1_16:Bit16u;
begin
    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    Dec(op1_16);

    (* now write sum back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, op1_16);
      end
    else begin
      write_RMW_virtual_word(op1_16);
      end;

    SET_FLAGS_OSZAP_16(0, 0, op1_16, BX_INSTR_DEC16);
end;

procedure BX_CPU_C.CMPXCHG_EwGw(i:PBxInstruction_tag);
var
  op2_16, op1_16, diff_16:Bit16u;
begin
{$if (BX_CPU_LEVEL >= 4) or (BX_CPU_LEVEL_HACKED >= 4)}

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    diff_16 := AX - op1_16;

    SET_FLAGS_OSZAPC_16(AX, op1_16, diff_16, BX_INSTR_CMP16);

    if (diff_16 = 0) then begin  // if accumulator := dest
      // ZF := 1
      set_ZF(1);
      // dest <-- src
      op2_16 := BX_READ_16BIT_REG(i^.nnn);

      if (i^.mod_ = $c0) then begin
        BX_WRITE_16BIT_REG(i^.rm, op2_16);
        end
      else begin
        write_RMW_virtual_word(op2_16);
        end;
      end
    else begin
      // ZF := 0
      set_ZF(0);
      // accumulator <-- dest
      AX := op1_16;
      end;

{$else}
  BX_PANIC(('CMPXCHG_EwGw:'));
{$ifend}
end;

