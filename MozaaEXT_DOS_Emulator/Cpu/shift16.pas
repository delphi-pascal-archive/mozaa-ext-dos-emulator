{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.SHLD_EwGw(I:PBxInstruction_tag);
var
  op1_16, op2_16, result_16:Bit16u;
  temp_32, result_32:Bit32u;
  count:unsigned;
begin

  (* op1:op2 shl count.  result stored in op1 *)
  if Boolean(i^.b1 = $1a4) then
    count := i^.Ib
  else // $1a5
    count := CL;

  count := count and $1f; // use only 5 LSB's


    if Boolean(count=0) then exit; (* NOP *)
    // count is 1..31

    (* op1 is a register or memory reference *)
    if Boolean(i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    temp_32 := (op1_16 shl 16)or(op2_16); // double formed by op1:op2
    result_32 := temp_32 shl count;
    if Boolean(count > 16) then begin
      // hack to act like x86 SHLD when count > 16
      // actually shifting op1:op2:op2 shl count
      result_32 := result_32 or (op2_16 shl (count - 16));
      end;
    result_16 := result_32 shr 16;

    (* now write result back to destination *)
    if Boolean(i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, result_16);
      end
  else begin
      write_RMW_virtual_word(result_16);
      end;

    (* set eflags:
     * SHLD count affects the following flags: S,Z,P,C,O
     *)
    set_CF( (temp_32 shr (32 - count))  and $01 );
    if Boolean(count = 1) then
      set_OF(Bool(((op1_16 or result_16) and $8000) > 0));
    set_ZF(Bool(result_16 = 0));
    set_SF(result_16 shr 15);
    set_PF_base(Bit8u(result_16));
end;

procedure BX_CPU_C.SHRD_EwGw(I:PBxInstruction_tag);
var
  op1_16, op2_16, result_16:Bit16u;
  temp_32, result_32:Bit32u;
  count:unsigned;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('shrd_evgvib: not supported on < 386'));
{$else}

  if Boolean(i^.b1 = $1ac) then
    count := i^.Ib
  else // $1ad
    count := CL;
  count := count and $1F; (* use only 5 LSB's *)

  if Boolean(count=0) then exit; (* NOP *)

    // count is 1..31

    (* op1 is a register or memory reference *)
    if Boolean(i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    temp_32 := (op2_16 shl 16) or op1_16; // double formed by op2:op1
    result_32 := temp_32 shr count;
    if Boolean(count > 16) then begin
      // hack to act like x86 SHLD when count > 16
      // actually shifting op2:op2:op1 shr count
      result_32 := result_32 or (op2_16 shl (32 - count));
      end;
    result_16 := result_32;

    (* now write result back to destination *)
    if Boolean(i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, result_16);
      end
  else begin
      write_RMW_virtual_word(result_16);
      end;

    (* set eflags:
     * SHRD count affects the following flags: S,Z,P,C,O
     *)

    set_CF((temp_32 shr (count - 1))  and $01);
    set_ZF(Bool(result_16 = 0));
    set_SF(result_16 shr 15);
    (* for shift of 1, OF set if sign change occurred. *)
    if Boolean(count = 1) then
      set_OF(Bool(((op1_16 or result_16)  and $8000) > 0));
    set_PF_base(Bit8u(result_16));
{$ifend} (* BX_CPU_LEVEL >= 3 *)
end;

procedure BX_CPU_C.ROL_Ew(I:PBxInstruction_tag);
var
  op1_16, result_16:Bit16u;
  count:unsigned;
begin

  if Boolean( i^.b1 = $c1 ) then
    count := i^.Ib
  else if Boolean( i^.b1 = $d1 ) then
    count := 1
  else // $d3
    count := CL;

    count := count and $0f; // only use bottom 4 bits

    (* op1 is a register or memory reference *)
    if Boolean(i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    if Boolean(count) then begin
      result_16 := (op1_16 shl count)or(op1_16 shr (16 - count));

      (* now write result back to destination *)
      if Boolean(i^.mod_ = $c0) then begin
        BX_WRITE_16BIT_REG(i^.rm, result_16);
        end
      else begin
        write_RMW_virtual_word(result_16);
        end;

      (* set eflags:
       * ROL count affects the following flags: C
       *)

      set_CF(result_16  and $01);
      if Boolean(count = 1) then
        set_OF(Bool(((op1_16 or result_16)  and $8000) > 0));
      end;
end;

procedure BX_CPU_C.ROR_Ew(I:PBxInstruction_tag);
var
  op1_16, result_16, result_b15:Bit16u;
  count:unsigned;
begin

  if Boolean( i^.b1 = $c1 ) then
    count := i^.Ib
  else if Boolean( i^.b1 = $d1 ) then
    count := 1
  else // $d3
    count := CL;

    count := count and $0f;  // use only 4 LSB's

    (* op1 is a register or memory reference *)
    if Boolean(i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    if Boolean(count) then begin
      result_16 := (op1_16 shr count)or(op1_16 shl (16 - count));

      (* now write result back to destination *)
      if Boolean(i^.mod_ = $c0) then begin
        BX_WRITE_16BIT_REG(i^.rm, result_16);
        end
      else begin
        write_RMW_virtual_word(result_16);
        end;

      (* set eflags:
       * ROR count affects the following flags: C
       *)
      result_b15 := result_16  and $8000;

      set_CF(Bool(result_b15 <> 0));
      if Boolean(count = 1) then
        set_OF(Bool(((op1_16 or result_16)  and $8000) > 0));
      end;
end;

procedure BX_CPU_C.RCL_Ew(I:PBxInstruction_tag);
var
  op1_16, result_16:Bit16u;
  count:unsigned;
begin
  if Boolean( i^.b1 = $c1 ) then
    count := i^.Ib
  else if Boolean( i^.b1 = $d1 ) then
    count := 1
  else // $d3
    count := CL;

  count := count and $1F;

    (* op1 is a register or memory reference *)
    if Boolean(i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    count := count mod 17;

    if Boolean(count=0) then exit;

    if Boolean(count=1) then begin
      result_16 := (op1_16 shl 1) or get_CF();
      end
  else if Boolean(count=16) then begin
      result_16 := (get_CF() shl 15) or (op1_16 shr 1);
      end
  else begin // 2..15
      result_16 := (op1_16 shl count) or (get_CF() shl (count - 1)) or (op1_16 shr (17 - count));
      end;

    (* now write result back to destination *)
    if Boolean(i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, result_16);
      end
  else begin
      write_RMW_virtual_word(result_16);
      end;

    (* set eflags:
     * RCL count affects the following flags: C
     *)

    if Boolean(count = 1) then
      set_OF(Bool(((op1_16 or result_16)  and $8000) > 0));
    set_CF((op1_16 shr (16 - count))  and $01);
end;

procedure BX_CPU_C.RCR_Ew(I:PBxInstruction_tag);
var
  op1_16, result_16:Bit16u;
  count:unsigned;
begin

  if Boolean( i^.b1 = $c1 ) then
    count := i^.Ib
  else if Boolean( i^.b1 = $d1 ) then
    count := 1
  else // $d3
    count := CL;

  count := count  and $1F;

    (* op1 is a register or memory reference *)
    if Boolean(i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    count := count mod 17;
    if Boolean(count) then begin
      result_16 := (op1_16 shr count) or	(get_CF() shl (16 - count)) or (op1_16 shl (17 - count));

      (* now write result back to destination *)
      if Boolean(i^.mod_ = $c0) then begin
	BX_WRITE_16BIT_REG(i^.rm, result_16);
	end
      else begin
	write_RMW_virtual_word(result_16);
        end;

      (* set eflags:
       * RCR count affects the following flags: C
       *)

      set_CF((op1_16 shr (count - 1))  and $01);
      if Boolean(count = 1) then
        set_OF(Bool(((op1_16 or result_16)  and $8000) > 0));
      end;
end;

procedure BX_CPU_C.SHL_Ew(I:PBxInstruction_tag);
var
  op1_16, result_16:Bit16u;
  count:unsigned;
begin
  if Boolean( i^.b1 = $c1 ) then
    count := i^.Ib
  else if Boolean( i^.b1 = $d1 ) then
    count := 1
  else // $d3
    count := CL;

  count := count and $1F; (* use only 5 LSB's *)

    (* op1 is a register or memory reference *)
    if Boolean(i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    if Boolean(count=0) then exit;

    result_16 := (op1_16 shl count);

    (* now write result back to destination *)
    if Boolean(i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, result_16);
      end
  else begin
      write_RMW_virtual_word(result_16);
      end;

    SET_FLAGS_OSZAPC_16(op1_16, count, result_16, BX_INSTR_SHL16);
end;

procedure BX_CPU_C.SHR_Ew(I:PBxInstruction_tag);
var
  op1_16, result_16:Bit16u;
  count:unsigned;
begin
  if Boolean( i^.b1 = $c1 ) then
    count := i^.Ib
  else if Boolean( i^.b1 = $d1 ) then
    count := 1
  else // $d3
    count := CL;

  count := count and $1F; (* use only 5 LSB's *)

    (* op1 is a register or memory reference *)
    if Boolean(i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    if Boolean(count=0) then exit;

    result_16 := (op1_16 shr count);

    (* now write result back to destination *)
    if Boolean(i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, result_16);
      end
  else begin
      write_RMW_virtual_word(result_16);
      end;

    SET_FLAGS_OSZAPC_16(op1_16, count, result_16, BX_INSTR_SHR16);
end;

procedure BX_CPU_C.SAR_Ew(I:PBxInstruction_tag);
var
  op1_16, result_16:Bit16u;
  count:unsigned;
begin
  if Boolean( i^.b1 = $c1 ) then
    count := i^.Ib
  else if Boolean( i^.b1 = $d1 ) then
    count := 1
  else // $d3
    count := CL;

  count := count and $1F;  (* use only 5 LSB's *)

    (* op1 is a register or memory reference *)
    if Boolean(i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    if Boolean(count=0) then exit;

    if Boolean(count < 16) then begin
      if Boolean(op1_16  and $8000) then begin
	result_16 := (op1_16 shr count)or($ffff shl (16 - count));
	end
      else begin
	result_16 := (op1_16 shr count);
	end;
      end
  else begin
      if Boolean(op1_16  and $8000) then begin
	result_16 := $ffff;
	end
      else begin
	result_16 := 0;
	end;
      end;



    (* now write result back to destination *)
    if Boolean(i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, result_16);
      end
  else begin
      write_RMW_virtual_word(result_16);
      end;

    (* set eflags:
     * SAR count affects the following flags: S,Z,P,C
     *)
    if Boolean(count < 16) then begin
      set_CF((op1_16 shr (count - 1))  and $01);
      end
  else begin
      if Boolean(op1_16  and $8000) then begin
	set_CF(1);
	end
      else begin
	set_CF(0);
	end;
      end;

    set_ZF(Bool(result_16 = 0));
    set_SF(result_16 shr 15);
    if Boolean(count = 1) then
      set_OF(0);
    set_PF_base(Bit8u(result_16));
end;
