{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.SHLD_EdGd(I:PBxInstruction_tag);
var
  op1_32, op2_32, result_32:Bit32u;
  count:unsigned;
begin

  (* op1:op2 shl count.  result stored in op1 *)

  if (i^.b1 = $1a4) then
    count := i^.Ib  and $1f
  else // $1a5
    count := CL  and $1f;

    if (count=0) then exit; (* NOP *)

    (* op1 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;
    op2_32 := BX_READ_32BIT_REG(i^.nnn);

    result_32 := (op1_32 shl count)or(op2_32 shr (32 - count));

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, result_32);
      end
  else begin
      write_RMW_virtual_dword(result_32);
      end;

    (* set eflags:
     * SHLD count affects the following flags: S,Z,P,C,O
     *)
    set_CF((op1_32 shr (32 - count))  and $01);
    if (count = 1) then
      set_OF(Bool(((op1_32 xor result_32)  and $80000000) > 0));
    set_ZF(Bool(result_32 = 0));
    set_PF_base(Bool(result_32));
    set_SF(result_32 shr 31);
end;

procedure BX_CPU_C.SHRD_EdGd(I:PBxInstruction_tag);
var
  op1_32, op2_32, result_32:Bit32u;
  count:unsigned;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('shrd_evgvib: not supported on < 386'));
{$else}

  if (i^.b1 = $1ac) then
    count := i^.Ib  and $1f
  else // $1ad
    count := CL  and $1f;

  if (count=0) then exit; (* NOP *)


    (* op1 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;
    op2_32 := BX_READ_32BIT_REG(i^.nnn);

    result_32 := (op2_32 shl (32 - count))or(op1_32 shr count);

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, result_32);
      end
  else begin
      write_RMW_virtual_dword(result_32);
      end;

    (* set eflags:
     * SHRD count affects the following flags: S,Z,P,C,O
     *)

    set_CF((op1_32 shr (count - 1)) and $01);
    set_ZF(Bool(result_32 = 0));
    set_SF(result_32 shr 31);
    (* for shift of 1, OF set if sign change occurred. *)
    if (count = 1) then
      set_OF(Bool(((op1_32 xor result_32) and $80000000) > 0));
    set_PF_base(result_32);
{$ifend} (* BX_CPU_LEVEL >= 3 *)
end;

procedure BX_CPU_C.ROL_Ed(I:PBxInstruction_tag);
var
  op1_32, result_32:Bit32u;
  count:unsigned;
begin

  if (i^.b1 = $c1) then
    count := i^.Ib  and $1f
  else if (i^.b1 = $d1) then
    count := 1
  else // (i^.b1 = $d3)
    count := CL  and $1f;

    (* op1 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    if (count)<>0 then begin
      result_32 := (op1_32 shl count)or(op1_32 shr (32 - count));

      (* now write result back to destination *)
      if (i^.mod_ = $c0) then begin
        BX_WRITE_32BIT_REG(i^.rm, result_32);
        end
      else begin
        write_RMW_virtual_dword(result_32);
        end;

      (* set eflags:
       * ROL count affects the following flags: C
       *)

      set_CF(result_32  and $01);
      if (count = 1) then
        set_OF(Bool(((op1_32 xor result_32)  and $80000000) > 0));
      end;
end;

procedure BX_CPU_C.ROR_Ed(I:PBxInstruction_tag);
var
  op1_32, result_32, result_b31:Bit32u;
  count:unsigned;
begin

  if (i^.b1 = $c1) then
    count := i^.Ib  and $1f
  else if (i^.b1 = $d1) then
    count := 1
  else // (i^.b1 = $d3)
    count := CL  and $1f;

    (* op1 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    if (count)<>0 then begin
      result_32 := (op1_32 shr count)or(op1_32 shl (32 - count));

      (* now write result back to destination *)
      if (i^.mod_ = $c0) then begin
        BX_WRITE_32BIT_REG(i^.rm, result_32);
        end
      else begin
        write_RMW_virtual_dword(result_32);
        end;

      (* set eflags:
       * ROR count affects the following flags: C
       *)
      result_b31 := result_32  and $80000000;

      set_CF(Bool(result_b31 <> 0));
      if (count = 1) then
        set_OF(Bool(((op1_32 xor result_32)  and $80000000) > 0));
      end;
end;

procedure BX_CPU_C.RCL_Ed(I:PBxInstruction_tag);
var
  op1_32, result_32:Bit32u;
  count:unsigned;
begin

  if (i^.b1 = $c1) then
    count := i^.Ib  and $1f
  else if (i^.b1 = $d1) then
    count := 1
  else // (i^.b1 = $d3)
    count := CL  and $1f;


    (* op1 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    if (count=0) then exit;

    if (count=1) then begin
      result_32 := (op1_32 shl 1) or get_CF();
      end
  else begin
      result_32 := (op1_32 shl count) or
                (get_CF() shl (count - 1)) or
                (op1_32 shr (33 - count));
      end;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, result_32);
      end
  else begin
      write_RMW_virtual_dword(result_32);
      end;

    (* set eflags:
     * RCL count affects the following flags: C
     *)
    if (count = 1) then
      set_OF(Bool(((op1_32 xor result_32)  and $80000000) > 0));
    set_CF((op1_32 shr (32 - count))  and $01);
end;

procedure BX_CPU_C.RCR_Ed(I:PBxInstruction_tag);
var
  op1_32, result_32:Bit32u;
  count:unsigned;
begin

  if (i^.b1 = $c1) then
    count := i^.Ib  and $1f
  else if (i^.b1 = $d1) then
    count := 1
  else // (i^.b1 = $d3)
    count := CL  and $1f;


    (* op1 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    if (count=0) then exit;

    if (count=1) then begin
      result_32 := (op1_32 shr 1)or(get_CF() shl 31);
      end
  else begin
      result_32 := (op1_32 shr count) or
                (get_CF() shl (32 - count)) or
                (op1_32 shl (33 - count));
      end;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, result_32);
      end
  else begin
      write_RMW_virtual_dword(result_32);
      end;

    (* set eflags:
     * RCR count affects the following flags: C
     *)

    set_CF((op1_32 shr (count - 1))  and $01);
    if (count = 1) then
      set_OF(Bool(((op1_32 xor result_32)  and $80000000) > 0));
end;

procedure BX_CPU_C.SHL_Ed(I:PBxInstruction_tag);
var
  op1_32, result_32:Bit32u;
  count:unsigned;
begin

  if (i^.b1 = $c1) then
    count := i^.Ib  and $1f
  else if (i^.b1 = $d1) then
    count := 1
  else // (i^.b1 = $d3)
    count := CL  and $1f;

    (* op1 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    if (count=0) then exit;

    result_32 := (op1_32 shl count);

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, result_32);
      end
  else begin
      write_RMW_virtual_dword(result_32);
      end;

    SET_FLAGS_OSZAPC_32(op1_32, count, result_32, BX_INSTR_SHL32);
end;

procedure BX_CPU_C.SHR_Ed(I:PBxInstruction_tag);
var
  op1_32, result_32:Bit32u;
  count:unsigned;
begin

  if (i^.b1 = $c1) then
    count := i^.Ib  and $1f
  else if (i^.b1 = $d1) then
    count := 1
  else // (i^.b1 = $d3)
    count := CL  and $1f;

    (* op1 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    if (count=0) then exit;

    result_32 := (op1_32 shr count);

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, result_32);
      end
  else begin
      write_RMW_virtual_dword(result_32);
      end;

    SET_FLAGS_OSZAPC_32(op1_32, count, result_32, BX_INSTR_SHR32);
end;

procedure BX_CPU_C.SAR_Ed(I:PBxInstruction_tag);
var
  op1_32, result_32:Bit32u;
  count:unsigned;
begin

  if (i^.b1 = $c1) then
    count := i^.Ib  and $1f
  else if (i^.b1 = $d1) then
    count := 1
  else // (i^.b1 = $d3)
    count := CL  and $1f;

    (* op1 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    if (count=0) then exit;

    (* count < 32, since only lower 5 bits used *)
    if (op1_32 and $80000000)<>0 then begin
      result_32 := (op1_32 shr count) or ($ffffffff shl (32 - count));
      end
  else begin
      result_32 := (op1_32 shr count);
      end;

    (* now write result back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, result_32);
      end
  else begin
      write_RMW_virtual_dword(result_32);
      end;

    (* set eflags:
     * SAR count affects the following flags: S,Z,P,C
     *)

    set_CF((op1_32 shr (count - 1))  and $01);
    set_ZF(Bool(result_32 = 0));
    set_SF(result_32 shr 31);
    if (count = 1) then
      set_OF(0);
    set_PF_base(result_32);
end;
