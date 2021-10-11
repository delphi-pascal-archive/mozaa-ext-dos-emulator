{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
procedure BX_CPU_C.SUB_EAXId(i:PBxInstruction_tag);
var
  op1_32, op2_32, diff_32:Bit32u;
begin

    op1_32 := gen_reg[0].erx;

    op2_32 := i^.Id;

    diff_32 := op1_32 - op2_32;

    (* now write diff back to destination *)
    gen_reg[0].erx := diff_32;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, diff_32, BX_INSTR_SUB32);
end;


procedure BX_CPU_C.CMP_EdGd(i:PBxInstruction_tag);
var
  op1_32, op2_32, diff_32:Bit32u;
begin

    (* op2_32 is a register, i^.rm_addr is an index of a register *)
    op2_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    diff_32 := op1_32 - op2_32;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, diff_32, BX_INSTR_CMP32);
end;


procedure BX_CPU_C.CMP_GdEd(i:PBxInstruction_tag);
var
  op1_32, op2_32, diff_32:Bit32u;
begin

    (* op1_32 is a register, i^.rm_addr is an index of a register *)
    op1_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op2_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_32 := BX_READ_32BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op2_32);
      end;

    diff_32 := op1_32 - op2_32;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, diff_32, BX_INSTR_CMP32);
end;

procedure BX_CPU_C.CMP_EAXId(i:PBxInstruction_tag);
var
  op1_32, op2_32, diff_32:Bit32u;
begin

    op1_32 := gen_reg[0].erx;

    op2_32 := i^.Id;

    diff_32 := op1_32 - op2_32;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, diff_32, BX_INSTR_CMP32);
end;


procedure BX_CPU_C.CWDE(i:PBxInstruction_tag);
begin
  (* CBW: no flags are effected *)

    gen_reg[0].erx := Bit16s(gen_reg[0].rx);
end;

procedure BX_CPU_C.CDQ(i:PBxInstruction_tag);
begin
  (* CWD: no flags are affected *)

    if (gen_reg[0].erx and $80000000)<>0 then begin
      gen_reg[2].erx := $FFFFFFFF;
      end
    else begin
      gen_reg[2].erx := $00000000;
      end;
end;

// Some info on the opcodes at begin0F,A6end; and begin0F,A7end;
// On 386 steps A0-B0:
//   beginOF,A6end; = XBTS
//   beginOF,A7end; = IBTS
// On 486 steps A0-B0:
//   beginOF,A6end; = CMPXCHG 8
//   beginOF,A7end; = CMPXCHG 16|32
//
// On 486 >= B steps, and further processors, the
// CMPXCHG instructions were moved to opcodes:
//   beginOF,B0end; = CMPXCHG 8
//   beginOF,B1end; = CMPXCHG 16|32

procedure BX_CPU_C.CMPXCHG_XBTS(i:PBxInstruction_tag);
begin
  BX_INFO(('CMPXCHG_XBTS:'));
  UndefinedOpcode(i);
end;

procedure BX_CPU_C.CMPXCHG_IBTS(i:PBxInstruction_tag);
begin
  BX_INFO(('CMPXCHG_IBTS:'));
  UndefinedOpcode(i);
end;


procedure BX_CPU_C.XADD_EdGd(i:PBxInstruction_tag);
var
  op2_32, op1_32, sum_32:Bit32u;
begin
{$if (BX_CPU_LEVEL >= 4) or (BX_CPU_LEVEL_HACKED >= 4)}


    (* XADD dst(r/m), src(r)
     * temp <-- src + dst         | sum = op2 + op1
     * src  <-- dst               | op2 = op1
     * dst  <-- tmp               | op1 = sum
     *)

    (* op2 is a register, i^.rm_addr is an index of a register *)
    op2_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op1 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    sum_32 := op1_32 + op2_32;

    (* now write sum back to destination *)
    if (i^.mod_ = $c0) then begin
      // and write destination into source
      // Note: if both op1 @ op2 are registers, the last one written
      //       should be the sum, as op1 @ op2 may be the same register.
      //       For example:  XADD AL, AL
      BX_WRITE_32BIT_REG(i^.nnn, op1_32);
      BX_WRITE_32BIT_REG(i^.rm, sum_32);
      end
    else begin
      write_RMW_virtual_dword(sum_32);
      (* and write destination into source *)
      BX_WRITE_32BIT_REG(i^.nnn, op1_32);
      end;


    SET_FLAGS_OSZAPC_32(op1_32, op2_32, sum_32, BX_INSTR_XADD32);
{$else}

{$ifend}
end;



procedure BX_CPU_C.ADD_EdId(i:PBxInstruction_tag);
var
  op1_32, op2_32, diff_32, sum_32:Bit32u;
begin

    op2_32 := i^.Id;

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    sum_32 := op1_32 + op2_32;

    (* now write sum back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, sum_32);
      end
    else begin
      write_RMW_virtual_dword(sum_32);
      end;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, sum_32, BX_INSTR_ADD32);
end;

procedure BX_CPU_C.ADC_EdId(i:PBxInstruction_tag);
var
  temp_CF:Bool;
  op1_32, op2_32, diff_32, sum_32:Bit32u;
begin

  temp_CF := get_CF();

    op2_32 := i^.Id;

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    sum_32 := op1_32 + op2_32 + temp_CF;

    (* now write sum back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, sum_32);
      end
    else begin
      write_RMW_virtual_dword(sum_32);
      end;

    SET_FLAGS_OSZAPC_32_CF(op1_32, op2_32, sum_32, BX_INSTR_ADC32,
                              temp_CF);
end;


procedure BX_CPU_C.SUB_EdId(i:PBxInstruction_tag);
var
  op1_32, op2_32, diff_32, sum_32:Bit32u;
begin

    op2_32 := i^.Id;

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
    else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    diff_32 := op1_32 - op2_32;

    (* now write diff back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, diff_32);
      end
    else begin
      write_RMW_virtual_dword(diff_32);
      end;

    SET_FLAGS_OSZAPC_32(op1_32, op2_32, diff_32, BX_INSTR_SUB32);
end;

