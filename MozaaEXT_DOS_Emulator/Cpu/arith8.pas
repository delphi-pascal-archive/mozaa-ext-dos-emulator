{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
procedure BX_CPU_C.ADD_EbGb(i:PBxInstruction_tag);
var
  op2, op1, sum:Bit8u;
begin
  // op2 is a register, i^.rm_addr is an index of a register
  op2 := BX_READ_8BIT_REG(i^.nnn);

  // op1 is a register or memory reference
  if i^.mod_ = $c0 then
    begin
      op1 := BX_READ_8BIT_REG(i^.rm);
    end
  else
    begin
      read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1);
    end;

  sum := op1 + op2;

  // now write sum back to destination
  if i^.mod_ = $c0 then
    begin
      BX_WRITE_8BIT_REG(i^.rm, sum);
    end
  else
    begin
      write_RMW_virtual_byte(sum);
    end;

  SET_FLAGS_OSZAPC_8(op1, op2, sum, BX_INSTR_ADD8);
end;

procedure BX_CPU_C.ADD_GbEb(i:PBxInstruction_tag);
var
  op1, op2, sum:Bit8u;
begin


  (* op1 is a register, i^.rm_addr is an index of a register *)
  op1 := BX_READ_8BIT_REG(i^.nnn);

  (* op2 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op2 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op2);
    end;

  sum := op1 + op2;

  (* now write sum back to destination, which is a register *)
  BX_WRITE_8BIT_REG(i^.nnn, sum);

  SET_FLAGS_OSZAPC_8(op1, op2, sum, BX_INSTR_ADD8);
end;


procedure BX_CPU_C.ADD_ALIb(i:PBxInstruction_tag);
var
  op1, op2, sum:Bit8u;
begin

  op1 := AL; //AL

  op2 := i^.Ib;

  sum := op1 + op2;

  (* now write sum back to destination, which is a register *)
  gen_reg[0].rl := sum; //AL

  SET_FLAGS_OSZAPC_8(op1, op2, sum, BX_INSTR_ADD8);
end;


procedure BX_CPU_C.ADC_EbGb(i:PBxInstruction_tag);
var
  op2, op1, sum:Bit8u;
  temp_CF:Bool;
begin

  temp_CF := get_CF();


  (* op2 is a register, i^.rm_addr is an index of a register *)
  op2 := BX_READ_8BIT_REG(i^.nnn);

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1);
    end;

  sum := op1 + op2 + temp_CF;


  (* now write sum back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, sum);
    end
  else begin
    write_RMW_virtual_byte(sum);
    end;

  SET_FLAGS_OSZAPC_8_CF(op1, op2, sum, BX_INSTR_ADC8, temp_CF);
end;


procedure BX_CPU_C.ADC_GbEb(i:PBxInstruction_tag);
var
  op2, op1, sum:Bit8u;
  temp_CF:Bool;
begin

  temp_CF := get_CF();


  (* op1 is a register, i^.rm_addr is an index of a register *)
  op1 := BX_READ_8BIT_REG(i^.nnn);

  (* op2 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op2 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op2);
    end;

  sum := op1 + op2 + temp_CF;

  SET_FLAGS_OSZAPC_8_CF(op1, op2, sum, BX_INSTR_ADC8,
                           temp_CF);

  (* now write sum back to destination, which is a register *)
  BX_WRITE_8BIT_REG(i^.nnn, sum);
end;


procedure BX_CPU_C.ADC_ALIb(i:PBxInstruction_tag);
var
  op2, op1, sum:Bit8u;
  temp_CF:Bool;
begin

  temp_CF := get_CF();


  op1 := AL;

  op2 := i^.Ib;

  sum := op1 + op2 + temp_CF;

  (* now write sum back to destination, which is a register *)
  AL := sum;

  SET_FLAGS_OSZAPC_8_CF(op1, op2, sum, BX_INSTR_ADC8,
                           temp_CF);
end;


procedure BX_CPU_C.SBB_EbGb(i:PBxInstruction_tag);
var
  op2_8, op1_8, diff_8:Bit8u;
  temp_CF:Bool;
begin

  temp_CF := get_CF();


  (* op2 is a register, i^.rm_addr is an index of a register *)
  op2_8 := BX_READ_8BIT_REG(i^.nnn);

  (* op1_8 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  diff_8 := op1_8 - (op2_8 + temp_CF);

  (* now write diff back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, diff_8);
    end
  else begin
    write_RMW_virtual_byte(diff_8);
    end;

  SET_FLAGS_OSZAPC_8_CF(op1_8, op2_8, diff_8, BX_INSTR_SBB8,
                           temp_CF);
end;


procedure BX_CPU_C.SBB_GbEb(i:PBxInstruction_tag);
var
  op1_8, op2_8, diff_8:Bit8u;
  temp_CF:Bool;
begin

  temp_CF := get_CF();


  (* op1 is a register, i^.rm_addr is an index of a register *)
  op1_8 := BX_READ_8BIT_REG(i^.nnn);

  (* op2 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op2_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op2_8);
    end;

  diff_8 := op1_8 - (op2_8 + temp_CF);

  (* now write diff back to destination, which is a register *)
  BX_WRITE_8BIT_REG(i^.nnn, diff_8);

  SET_FLAGS_OSZAPC_8_CF(op1_8, op2_8, diff_8, BX_INSTR_SBB8,
                           temp_CF);
end;


procedure BX_CPU_C.SBB_ALIb(i:PBxInstruction_tag);
var
  op1_8, op2_8, diff_8:Bit8u;
  temp_CF:Bool;
begin

  temp_CF := get_CF();


  op1_8 := AL;

  op2_8 := i^.Ib;

  diff_8 := op1_8 - (op2_8 + temp_CF);

  (* now write diff back to destination, which is a register *)
  AL := diff_8;

  SET_FLAGS_OSZAPC_8_CF(op1_8, op2_8, diff_8, BX_INSTR_SBB8,
                           temp_CF);
end;

procedure BX_CPU_C.SBB_EbIb(i:PBxInstruction_tag);
var
  op1_8, op2_8, diff_8:Bit8u;
  temp_CF:Bool;
begin

  temp_CF := get_CF();

  op2_8 := i^.Ib;

  (* op1_8 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  diff_8 := op1_8 - (op2_8 + temp_CF);

  (* now write diff back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, diff_8);
    end
  else begin
    write_RMW_virtual_byte(diff_8);
    end;

  SET_FLAGS_OSZAPC_8_CF(op1_8, op2_8, diff_8, BX_INSTR_SBB8,
                           temp_CF);
end;



procedure BX_CPU_C.SUB_EbGb(i:PBxInstruction_tag);
var
  op2_8, op1_8, diff_8:Bit8u;
begin

  (* op2 is a register, i^.rm_addr is an index of a register *)
  op2_8 := BX_READ_8BIT_REG(i^.nnn);

  (* op1_8 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  diff_8 := op1_8 - op2_8;

  (* now write diff back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, diff_8);
    end
  else begin
    write_RMW_virtual_byte(diff_8);
    end;

  SET_FLAGS_OSZAPC_8(op1_8, op2_8, diff_8, BX_INSTR_SUB8);
end;


procedure BX_CPU_C.SUB_GbEb(i:PBxInstruction_tag);
var
  op1_8, op2_8, diff_8:Bit8u;
begin

  (* op1 is a register, i^.rm_addr is an index of a register *)
  op1_8 := BX_READ_8BIT_REG(i^.nnn);

  (* op2 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op2_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op2_8);
    end;

  diff_8 := op1_8 - op2_8;

  (* now write diff back to destination, which is a register *)
  BX_WRITE_8BIT_REG(i^.nnn, diff_8);

  SET_FLAGS_OSZAPC_8(op1_8, op2_8, diff_8, BX_INSTR_SUB8);
end;

procedure BX_CPU_C.SUB_ALIb(i:PBxInstruction_tag);
var
  op1_8, op2_8, diff_8:Bit8u;
begin

  op1_8 := AL;

  op2_8 := i^.Ib;

  diff_8 := op1_8 - op2_8;

  (* now write diff back to destination, which is a register *)
  AL := diff_8;

  SET_FLAGS_OSZAPC_8(op1_8, op2_8, diff_8, BX_INSTR_SUB8);
end;

procedure BX_CPU_C.CMP_EbGb(i:PBxInstruction_tag);
var
  op1_8, op2_8, diff_8:Bit8u;
begin

  (* op2 is a register, i^.rm_addr is an index of a register *)
  op2_8 := BX_READ_8BIT_REG(i^.nnn);

  (* op1_8 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  diff_8 := op1_8 - op2_8;

  SET_FLAGS_OSZAPC_8(op1_8, op2_8, diff_8, BX_INSTR_CMP8);
end;


procedure BX_CPU_C.CMP_GbEb(i:PBxInstruction_tag);
var
  op1_8, op2_8, diff_8:Bit8u;
begin

  (* op1 is a register, i^.rm_addr is an index of a register *)
  op1_8 := BX_READ_8BIT_REG(i^.nnn);

  (* op2 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op2_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op2_8);
    end;

  diff_8 := op1_8 - op2_8;

  SET_FLAGS_OSZAPC_8(op1_8, op2_8, diff_8, BX_INSTR_CMP8);
end;

procedure BX_CPU_C.CMP_ALIb(i:PBxInstruction_tag);
var
  op1_8, op2_8, diff_8:Bit8u;
begin

  op1_8 := AL;

  op2_8 := i^.Ib;

  diff_8 := op1_8 - op2_8;

  SET_FLAGS_OSZAPC_8(op1_8, op2_8, diff_8, BX_INSTR_CMP8);
end;


procedure BX_CPU_C.XADD_EbGb(i:PBxInstruction_tag);
var
  op2, op1, sum:Bit8u;
begin
{$if (BX_CPU_LEVEL >= 4) or (BX_CPU_LEVEL_HACKED >= 4)}

  (* XADD dst(r/m8), src(r8)
   * temp <-- src + dst         | sum = op2 + op1
   * src  <-- dst               | op2 = op1
   * dst  <-- tmp               | op1 = sum
   *)

  (* op2 is a register, i^.rm_addr is an index of a register *)
  op2 := BX_READ_8BIT_REG(i^.nnn);

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1);
    end;

  sum := op1 + op2;

  (* now write sum back to destination *)
  if (i^.mod_ = $c0) then begin
    // and write destination into source
    // Note: if both op1 @ op2 are registers, the last one written
    //       should be the sum, as op1 @ op2 may be the same register.
    //       For example:  XADD AL, AL
    BX_WRITE_8BIT_REG(i^.nnn, op1);
    BX_WRITE_8BIT_REG(i^.rm, sum);
    end
  else begin
    write_RMW_virtual_byte(sum);
    (* and write destination into source *)
    BX_WRITE_8BIT_REG(i^.nnn, op1);
    end;


  SET_FLAGS_OSZAPC_8(op1, op2, sum, BX_INSTR_XADD8);
{$else}
  BX_PANIC(('XADD_EbGb: not supported on < 80486'));
{$ifend}
end;

procedure BX_CPU_C.ADD_EbIb(i:PBxInstruction_tag);
var
  op2, op1, sum:Bit8u;
begin

  op2 := i^.Ib;

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1);
    end;

  sum := op1 + op2;

  (* now write sum back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, sum);
    end
  else begin
    write_RMW_virtual_byte(sum);
    end;

  SET_FLAGS_OSZAPC_8(op1, op2, sum, BX_INSTR_ADD8);
end;

procedure BX_CPU_C.ADC_EbIb(i:PBxInstruction_tag);
var
  op2, op1, sum:Bit8u;
  temp_CF:Bool;
begin

  temp_CF := get_CF();

  op2 := i^.Ib;

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1);
    end;

  sum := op1 + op2 + temp_CF;

  (* now write sum back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, sum);
    end
  else begin
    write_RMW_virtual_byte(sum);
    end;

  SET_FLAGS_OSZAPC_8_CF(op1, op2, sum, BX_INSTR_ADC8,
                           temp_CF);
end;

procedure BX_CPU_C.SUB_EbIb(i:PBxInstruction_tag);
var
  op2_8, op1_8, diff_8:Bit8u;
begin

  op2_8 := i^.Ib;

  (* op1_8 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  diff_8 := op1_8 - op2_8;

  (* now write diff back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, diff_8);
    end
  else begin
    write_RMW_virtual_byte(diff_8);
    end;

  SET_FLAGS_OSZAPC_8(op1_8, op2_8, diff_8, BX_INSTR_SUB8);
end;

procedure BX_CPU_C.CMP_EbIb(i:PBxInstruction_tag);
var
  op2_8, op1_8, diff_8:Bit8u;
begin

  op2_8 := i^.Ib;

  (* op1_8 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  diff_8 := op1_8 - op2_8;

  SET_FLAGS_OSZAPC_8(op1_8, op2_8, diff_8, BX_INSTR_CMP8);
end;


procedure BX_CPU_C.NEG_Eb(i:PBxInstruction_tag);
var
  op1_8, diff_8:Bit8u;
begin

  (* op1_8 is a register or memory reference *)
  if (i^.mod_ = $c0) then  begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  diff_8 := 0 - op1_8;

  (* now write diff back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, diff_8);
    end
  else begin
    write_RMW_virtual_byte(diff_8);
    end;

  SET_FLAGS_OSZAPC_8(op1_8, 0, diff_8, BX_INSTR_NEG8);
end;


procedure BX_CPU_C.INC_Eb(i:PBxInstruction_tag);
var
  op1:Bit8u;
begin

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1);
    end;


  Inc(op1);

  (* now write sum back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, op1);
    end
  else begin
    write_RMW_virtual_byte(op1);
    end;

  SET_FLAGS_OSZAP_8(0, 0, op1, BX_INSTR_INC8);
end;

procedure BX_CPU_C.DEC_Eb(i:PBxInstruction_tag);
var
  op1_8:Bit8u;
begin

  (* op1_8 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  Dec(op1_8);

  (* now write sum back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, op1_8);
    end
  else begin
    write_RMW_virtual_byte(op1_8);
    end;

  SET_FLAGS_OSZAP_8(0, 0, op1_8, BX_INSTR_DEC8);
end;


procedure BX_CPU_C.CMPXCHG_EbGb(i:PBxInstruction_tag);
var
  op2_8, op1_8, diff_8:Bit8u;
begin
{$if (BX_CPU_LEVEL >= 4) or (BX_CPU_LEVEL_HACKED >= 4)}

  (* op1_8 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1_8 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1_8);
    end;

  diff_8 := AL - op1_8;

  SET_FLAGS_OSZAPC_8(AL, op1_8, diff_8, BX_INSTR_CMP8);

  if (diff_8 = 0) then begin  // if accumulator = dest
    // ZF = 1
    set_ZF(1);
    // dest <-- src
    op2_8 := BX_READ_8BIT_REG(i^.nnn);

    if (i^.mod_ = $c0) then begin
      BX_WRITE_8BIT_REG(i^.rm, op2_8);
      end
    else begin
      write_RMW_virtual_byte(op2_8);
      end;
    end
  else begin
    // ZF = 0
    set_ZF(0);
    // accumulator <-- dest
    AL := op1_8;
    end;

{$else}
  BX_PANIC(('CMPXCHG_EbGb:'));
{$ifend}
end;

