{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.MUL_ALEb(I:PBxInstruction_tag);
var
  op2, op1:Bit8u;
  product_16:Bit16u;
  temp_flag:Bool;
begin

  op1 := AL;

  (* op2 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op2 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op2);
    end;

  product_16 := op1 * op2;

  (* set EFLAGS:
   * MUL affects the following flags: C,O
   *)

  temp_flag := Bool((product_16  and $FF00) <> 0);
  SET_FLAGS_OxxxxC(temp_flag, temp_flag);

  (* now write product back to destination *)

  AX := product_16;
end;

procedure BX_CPU_C.IMUL_ALEb(I:PBxInstruction_tag);
var
  op2, op1:Bit8u;
  product_16:Bit16u;
  upper_bits:Bit16u;
begin

  op1 := AL;

  (* op2 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op2 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, PBit8u(@op2));
    end;

  product_16 := op1 * op2;

  (* now write product back to destination *)

  AX := product_16;

  (* set EFLAGS:
   * IMUL affects the following flags: C,O
   * IMUL r/m8: condition for clearing CF  and OF:
   *   AL := sign-extend of AL to 16 bits
   *)
  upper_bits := AX and $ff80;
  if (upper_bits=$ff80) or (upper_bits=$0000) then begin
    SET_FLAGS_OxxxxC(0, 0);
    end
  else begin
    SET_FLAGS_OxxxxC(1, 1);
    end;
end;

procedure BX_CPU_C.DIV_ALEb(I:PBxInstruction_tag);
var
  op2, quotient_8l, remainder_8:Bit8u;
  quotient_16, op1:Bit16u;
begin

  op1 := AX;

  (* op2 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op2 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op2);
    end;

  if (op2 = 0) then begin
    exception2([BX_DE_EXCEPTION, 0, 0]);
    end;
  quotient_16 := Trunc(op1 / op2);
  remainder_8 := op1 mod op2;
  quotient_8l := quotient_16 and $FF;

  if (quotient_16 <> quotient_8l) then begin
    exception2([BX_DE_EXCEPTION, 0, 0]);
    end;

  (* set EFLAGS:
   * DIV affects the following flags: O,S,Z,A,P,C are undefined
   *)

{$if INTEL_DIV_FLAG_BUG = 1}
    set_CF(1);
{$ifend}

  (* now write quotient back to destination *)

  AL := quotient_8l;
  AH := remainder_8;
end;

procedure BX_CPU_C.IDIV_ALEb(I:PBxInstruction_tag);
var
  op2, quotient_8l, remainder_8:Bit8s;
  quotient_16, op1:Bit16s;
begin
  op1 := AX;

  (* op2 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op2 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, PBit8u(@op2));
    end;

  if (op2 = 0) then begin
    exception2([BX_DE_EXCEPTION, 0, 0]);
    end;

  quotient_16 := Trunc(op1 / op2);
  remainder_8 := op1 mod op2;
  quotient_8l := quotient_16 and $FF;

  if (quotient_16 <> quotient_8l) then begin
    BX_INFO(Format('quotient_16: %04x, remainder_8: %02x, quotient_8l: %02x',[quotient_16, remainder_8, quotient_8l]));
    AL := quotient_8l;
    AH := remainder_8;
    BX_INFO(Format('AH: %02x, AL: %02x',[AH, AL]));
    exception2([BX_DE_EXCEPTION, 0, 0]);
    end;

  (* set EFLAGS:
   * DIV affects the following flags: O,S,Z,A,P,C are undefined
   *)

{$if INTEL_DIV_FLAG_BUG = 1}
    set_CF(1);
{$ifend}

  (* now write quotient back to destination *)

  AL := quotient_8l;
  AH := remainder_8;
end;

