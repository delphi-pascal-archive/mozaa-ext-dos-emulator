{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.MUL_AXEw(I:PBxInstruction_tag);
var
  op1_16, op2_16, product_16h, product_16l:Bit16u;
  product_32:Bit32u;
  temp_flag:Bool;
begin

    op1_16 := AX;

    (* op2 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;

    product_32 := (Bit32u(op1_16)) * (Bit32u(op2_16));

    product_16l := (product_32  and $FFFF);
    product_16h := product_32 shr 16;

    (* now write product back to destination *)

    AX := product_16l;
    DX := product_16h;

    (* set eflags:
     * MUL affects the following flags: C,O
     *)

    temp_flag := Bool(product_16h <> 0);
    SET_FLAGS_OxxxxC(temp_flag, temp_flag);
end;

procedure BX_CPU_C.IMUL_AXEw(I:PBxInstruction_tag);
var
  op1_16, op2_16:Bit16s;
  product_32:Bit32s;
  product_16h, product_16l:Bit16u;
begin

    op1_16 := AX;

    (* op2 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, PBit16u(@op2_16));
      end;

    product_32 := (Bit32s(op1_16)) * (Bit32s(op2_16));

    product_16l := (product_32  and $FFFF);
    product_16h := product_32 shr 16;

    (* now write product back to destination *)

    AX := product_16l;
    DX := product_16h;

    (* set eflags:
     * IMUL affects the following flags: C,O
     * IMUL r/m16: condition for clearing CF  and OF:
     *   DX:AX := sign-extend of AX
     *)

    if (DX=$ffff) and Boolean(AX and $8000) then begin
      SET_FLAGS_OxxxxC(0, 0);
      end
  else if ( (DX=$0000) and (AX < $8000) ) then begin
      SET_FLAGS_OxxxxC(0, 0);
      end
  else begin
      SET_FLAGS_OxxxxC(1, 1);
      end;
end;


procedure BX_CPU_C.DIV_AXEw(I:PBxInstruction_tag);
var
  op2_16, remainder_16, quotient_16l:Bit16u;
  op1_32, quotient_32:Bit32u;
begin

    op1_32 := (Bit32u(DX) shl 16) or Bit32u(AX);

    (* op2 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;

    if (op2_16 = 0) then begin
      exception2([BX_DE_EXCEPTION, 0, 0]);
      end;
    quotient_32 := op1_32 div op2_16;
    remainder_16 := op1_32 mod op2_16;
    quotient_16l := quotient_32 and $FFFF;

    if (quotient_32 <> quotient_16l) then begin
      exception2([BX_DE_EXCEPTION, 0, 0]);
      end;

    (* set EFLAGS:
     * DIV affects the following flags: O,S,Z,A,P,C are undefined
     *)

{$if INTEL_DIV_FLAG_BUG = 1}
    set_CF(1);
{$ifend}

    (* now write quotient back to destination *)

    AX := quotient_16l;
    DX := remainder_16;
end;


procedure BX_CPU_C.IDIV_AXEw(I:PBxInstruction_tag);
var
  op2_16, remainder_16, quotient_16l:Bit16s;
  op1_32, quotient_32:Bit32s;
begin

    op1_32 := (Bit32u(DX) shl 16) or (Bit32u(AX));

    (* op2 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, PBit16u(@op2_16));
      end;

    if (op2_16 = 0) then begin
      exception2([BX_DE_EXCEPTION, 0, 0]);
      end;
    quotient_32 := op1_32 div op2_16;
    remainder_16 := op1_32 mod op2_16;
    quotient_16l := quotient_32 and $FFFF;

    if (quotient_32 <> quotient_16l) then begin
      exception2([BX_DE_EXCEPTION, 0, 0]);
      end;

    (* set EFLAGS:
     * IDIV affects the following flags: O,S,Z,A,P,C are undefined
     *)

{$if INTEL_DIV_FLAG_BUG = 1}
    set_CF(1);
{$ifend}

    (* now write quotient back to destination *)

    AX := quotient_16l;
    DX := remainder_16;
end;


  procedure
BX_CPU_C.IMUL_GwEwIw(I:PBxInstruction_tag);
var
  product_16l:Bit16u;
  op2_16, op3_16:Bit16s;
  product_32:Bit32s;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('IMUL_GvEvIv() unsupported on 8086!'));
{$else}



    op3_16 := i^.Iw;

    (* op2 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, PBit16u(@op2_16));
      end;

    product_32 := op2_16 * op3_16;

    product_16l := (product_32  and $FFFF);

    (* now write product back to destination *)
    BX_WRITE_16BIT_REG(i^.nnn, product_16l);

    (* set eflags:
     * IMUL affects the following flags: C,O
     * IMUL r16,r/m16,imm16: condition for clearing CF  and OF:
     *   result exactly fits within r16
     *)

    if (product_32 > -32768)  and (product_32 < 32767) then begin
      SET_FLAGS_OxxxxC(0, 0);
      end
  else begin
      SET_FLAGS_OxxxxC(1, 1);
      end;
{$ifend}
end;

procedure BX_CPU_C.IMUL_GwEw(I:PBxInstruction_tag);
var
  product_16l:Bit16u;
  op1_16, op2_16:Bit16s;
  product_32:Bit32s;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('IMUL_GvEv() unsupported on 8086!'));
{$else}

    (* op2 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, PBit16u(@op2_16));
      end;

    op1_16 := BX_READ_16BIT_REG(i^.nnn);

    product_32 := op1_16 * op2_16;

    product_16l := (product_32  and $FFFF);

    (* now write product back to destination *)
    BX_WRITE_16BIT_REG(i^.nnn, product_16l);

    (* set eflags:
     * IMUL affects the following flags: C,O
     * IMUL r16,r/m16,imm16: condition for clearing CF  and OF:
     *   result exactly fits within r16
     *)

    if (product_32 > -32768) and (product_32 < 32767) then begin
      SET_FLAGS_OxxxxC(0, 0);
      end
  else begin
      SET_FLAGS_OxxxxC(1, 1);
      end;
{$ifend}
end;

