{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.MUL_EAXEd(I:PBxInstruction_tag);
var
  op1_32, op2_32, product_32h, product_32l:Bit32u;
  product_64:Bit64u;
  temp_flag:Bool;
begin

    op1_32 := EAX;

    (* op2 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op2_32);
      end;

    product_64 := (Bit64u(op1_32)) * (Bit64u(op2_32));

    product_32l := Bit32u(product_64  and $FFFFFFFF);
    product_32h := Bit32u(product_64 shr 32);

    (* now write product back to destination *)

    EAX := product_32l;
    EDX := product_32h;

    (* set eflags:
     * MUL affects the following flags: C,O
     *)

    temp_flag := Word(product_32h <> 0);
    SET_FLAGS_OxxxxC(temp_flag, temp_flag);
end;

procedure BX_CPU_C.IMUL_EAXEd(I:PBxInstruction_tag);
var
  op1_32, op2_32:Bit32s;
  product_64:Bit64s;
  product_32h, product_32l:Bit32u;
begin

    op1_32 := EAX;

    (* op2 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, PBit32u (@op2_32));
      end;

    product_64 := Bit64s(op1_32) * Bit64s(op2_32);

    product_32l := Bit32u(product_64 and $FFFFFFFF);
    product_32h := Bit32u(product_64 shr 32);

    (* now write product back to destination *)

    EAX := product_32l;
    EDX := product_32h;

    (* set eflags:
     * IMUL affects the following flags: C,O
     * IMUL r/m16: condition for clearing CF  and OF:
     *   EDX:EAX := sign-extend of EAX
     *)

    if  (EDX=$ffffffff) and ((EAX and $80000000)<>0) then begin
      SET_FLAGS_OxxxxC(0, 0);
      end
  else if ( (EDX=$00000000) and (EAX < $80000000) ) then begin
      SET_FLAGS_OxxxxC(0, 0);
      end
  else begin
      SET_FLAGS_OxxxxC(1, 1);
      end;
end;

procedure BX_CPU_C.DIV_EAXEd(I:PBxInstruction_tag);
var
  op2_32, remainder_32, quotient_32l:Bit32u;
  op1_64, quotient_64:Bit64u;
begin

    op1_64 := (Bit64u(EDX) shl 32) + Bit64u(EAX);

    (* op2 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op2_32);
      end;

    if (op2_32 = 0) then begin
      exception2([BX_DE_EXCEPTION, 0, 0]);
      end;
    quotient_64 := op1_64 div op2_32;
    remainder_32 := Bit32u(op1_64 mod op2_32);
    quotient_32l := Bit32u(quotient_64 and $FFFFFFFF);

    if (quotient_64 <> quotient_32l) then begin
      exception2([BX_DE_EXCEPTION, 0, 0]);
      end;

    (* set EFLAGS:
     * DIV affects the following flags: O,S,Z,A,P,C are undefined
     *)

    (* now write quotient back to destination *)

    EAX := quotient_32l;
    EDX := remainder_32;
end;

procedure BX_CPU_C.IDIV_EAXEd(I:PBxInstruction_tag);
var
  op2_32, remainder_32, quotient_32l:Bit32s;
  op1_64, quotient_64:Bit64s;
begin

    op1_64 := (Bit64u(EDX) shl 32) or Bit64u(EAX);

    (* op2 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, (PBit32u(@op2_32)));
      end;

    if (op2_32 = 0) then begin
      exception2([BX_DE_EXCEPTION, 0, 0]);
      end;
    quotient_64 := op1_64 div op2_32;
    remainder_32 := Bit32s(op1_64 mod op2_32);
    quotient_32l := Bit32s(quotient_64 and $FFFFFFFF);

    if (quotient_64 <> quotient_32l) then begin
      exception2([BX_DE_EXCEPTION, 0, 0]);
      end;

    (* set EFLAGS:
     * IDIV affects the following flags: O,S,Z,A,P,C are undefined
     *)

    (* now write quotient back to destination *)

    EAX := quotient_32l;
    EDX := remainder_32;
end;

procedure BX_CPU_C.IMUL_GdEdId(I:PBxInstruction_tag);
var
  op2_32, op3_32, product_32:Bit32s;
  product_64:Bit64s;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('IMUL_GdEdId() unsupported on 8086!'));
{$else}

    op3_32 := i^.Id;

    (* op2 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, PBit32u(@op2_32));
      end;

    product_32 := op2_32 * op3_32;
    product_64 := Bit64s(op2_32) * Bit64s(op3_32);

    (* now write product back to destination *)
    BX_WRITE_32BIT_REG(i^.nnn, product_32);

    (* set eflags:
     * IMUL affects the following flags: C,O
     * IMUL r16,r/m16,imm16: condition for clearing CF  and OF:
     *   result exactly fits within r16
     *)

    if (product_64 = product_32) then begin
      SET_FLAGS_OxxxxC(0, 0);
      end
  else begin
      SET_FLAGS_OxxxxC(1, 1);
      end;
{$ifend}
end;

procedure BX_CPU_C.IMUL_GdEd(I:PBxInstruction_tag);
var
  op1_32, op2_32, product_32:Bit32s;
  product_64:Bit64s;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('IMUL_GvEv() unsupported on 8086!'));
{$else}

    (* op2 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, PBit32u(@op2_32));
      end;

    op1_32 := BX_READ_32BIT_REG(i^.nnn);

    product_32 := op1_32 * op2_32;
    product_64 := Bit64s(op1_32) * Bit64s(op2_32);

    (* now write product back to destination *)
    BX_WRITE_32BIT_REG(i^.nnn, product_32);

    (* set eflags:
     * IMUL affects the following flags: C,O
     * IMUL r16,r/m16,imm16: condition for clearing CF  and OF:
     *   result exactly fits within r16
     *)

    if (product_64 = product_32) then begin
      SET_FLAGS_OxxxxC(0, 0);
      end
  else begin
      SET_FLAGS_OxxxxC(1, 1);
      end;
{$ifend}
end;

