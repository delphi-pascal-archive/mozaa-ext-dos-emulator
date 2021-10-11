{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.ROL_Eb(I:PBxInstruction_tag);
var
  op1_8, result_8:Bit8u;
  count:word;
begin

  if (i^.b1 = $c0) then
    count := i^.Ib
  else if (i^.b1 = $d0) then
    count := 1
  else // $d2
    count := CL;

  count := count and $07; // use only lowest 3 bits

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  if Boolean(count) then begin
    result_8 := (op1_8 shl count)or(op1_8 shr (8 - count));

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_8BIT_REG(i^.rm, result_8);
      end
  else begin
      write_RMW_virtual_byte(result_8);
      end;

    (* set eflags:
     * ROL count affects the following flags: C
     *)

    set_CF(result_8  and $01);
    if (count = 1) then
      set_OF(Bool(((op1_8 or result_8) and $80) > 0));
    end;
end;

procedure BX_CPU_C.ROR_Eb(I:PBxInstruction_tag);
var
  op1_8, result_8:Bit8u;
  result_b7:Bit8u;
  count:unsigned;
begin

  if (i^.b1 = $c0) then
    count := i^.Ib
  else if (i^.b1 = $d0) then
    count := 1
  else // $d2
    count := CL;


  count := count and $07; (* use only bottom 3 bits *)

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  if Boolean(count) then begin
    result_8 := (op1_8 shr count)or(op1_8 shl (8 - count));

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_8BIT_REG(i^.rm, result_8);
      end
  else begin
      write_RMW_virtual_byte(result_8);
      end;

    (* set eflags:
     * ROR count affects the following flags: C
     *)
    result_b7 := result_8  and $80;

    set_CF(Bool(result_b7 <> 0));
    if (count = 1) then
      set_OF(Bool(((op1_8 or result_8)  and $80) > 0));
    end;
end;

procedure BX_CPU_C.RCL_Eb(I:PBxInstruction_tag);
var
  op1_8, result_8:Bit8u;
  count:unsigned;
begin

  if (i^.b1 = $c0) then
    count := i^.Ib
  else if (i^.b1 = $d0) then
    count := 1
  else // $d2
    count := CL;

  count := (count and $1F) mod 9;


  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  if Boolean(count) then begin
    result_8 := (op1_8 shl count) or
             (get_CF() shl (count - 1)) or
             (op1_8 shr (9 - count));

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_8BIT_REG(i^.rm, result_8);
      end
  else begin
      write_RMW_virtual_byte(result_8);
      end;

    (* set eflags:
     * RCL count affects the following flags: C
     *)
    if (count = 1) then
      set_OF(Bool(((op1_8 or result_8)  and $80) > 0));
    set_CF(Bool((op1_8 shr (8 - count))  and $01));
    end;
end;

procedure BX_CPU_C.RCR_Eb(I:PBxInstruction_tag);
var
  op1_8, result_8:Bit8u;
  count:unsigned;
begin

  if (i^.b1 = $c0) then
    count := i^.Ib
  else if (i^.b1 = $d0) then
    count := 1
  else // $d2
    count := CL;

  count := ( count  and $1F ) mod 9;

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  if Boolean(count) then begin
    result_8 := (op1_8 shr count) or
             (get_CF() shl (8 - count)) or
             (op1_8 shl (9 - count));

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_8BIT_REG(i^.rm, result_8);
      end
  else begin
      write_RMW_virtual_byte(result_8);
      end;

    (* set eflags:
     * RCR count affects the following flags: C
     *)

    set_CF((op1_8 shr (count - 1))  and $01);
    if (count = 1) then
      set_OF(Bool(((op1_8 or result_8)  and $80) > 0));
    end;
end;

procedure BX_CPU_C.SHL_Eb(I:PBxInstruction_tag);
var
  op1_8, result_8:Bit8u;
  count:unsigned;
begin

  if (i^.b1 = $c0) then
    count := i^.Ib
  else if (i^.b1 = $d0) then
    count := 1
  else // $d2
    count := CL;

  count := count and $1F;

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  if Boolean(count=0) then exit;

  result_8 := (op1_8 shl count);

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_RMW_virtual_byte(result_8);
    end;

  SET_FLAGS_OSZAPC_8(op1_8, count, result_8, BX_INSTR_SHL8);
end;

procedure BX_CPU_C.SHR_Eb(I:PBxInstruction_tag);
var
  op1_8, result_8:Bit8u;
  count:unsigned;
begin

  if (i^.b1 = $c0) then
    count := i^.Ib
  else if (i^.b1 = $d0) then
    count := 1
  else // $d2
    count := CL;

  count := count and $1F;

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  if Boolean(count=0) then exit;

  result_8 := (op1_8 shr count);

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_RMW_virtual_byte(result_8);
    end;

  SET_FLAGS_OSZAPC_8(op1_8, count, result_8, BX_INSTR_SHR8);
end;

procedure BX_CPU_C.SAR_Eb(I:PBxInstruction_tag);
var
  op1_8, result_8:Bit8u;
  count:unsigned;
begin

  if (i^.b1 = $c0) then
    count := i^.Ib
  else if (i^.b1 = $d0) then
    count := 1
  else // $d2
    count := CL;

  count := count and $1F;

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  if Boolean(count=0) then exit;

  if (count < 8) then begin
    if Boolean(op1_8 and $80) then begin
      result_8 := (op1_8 shr count)or($ff shl (8 - count));
      end
  else begin
      result_8 := (op1_8 shr count);
      end;
    end
  else begin
    if Boolean(op1_8 and $80) then begin
      result_8 := $ff;
      end
  else begin
      result_8 := 0;
      end;
    end;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_RMW_virtual_byte(result_8);
    end;

  (* set eflags:
   * SAR count affects the following flags: S,Z,P,C
   *)

  if (count < 8) then begin
    set_CF((op1_8 shr (count - 1))  and $01);
    end
  else begin
    if Boolean(op1_8 and $80) then begin
      set_CF(1);
      end
  else begin
      set_CF(0);
      end;
    end;

  set_ZF(Bool(result_8 = 0));
  set_SF(result_8 shr 7);
  if (count = 1) then
    set_OF(0);
  set_PF_base(result_8);
end;
