{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.BOUND_GvMa(I:PBxInstruction_tag);
var
  bound_min, bound_max:Bit32s;
  op1_32:Bit32s;
  bound_min_16, bound_max_16:Bit16s;
  op1_16:Bit16s;
begin
if BX_CPU_LEVEL < 2 then
  BX_PANIC(('BOUND_GvMa: not supported on 8086!'))
else
begin

  if (i^.mod_ = $c0) then begin
    (* undefined opcode exception *)
    BX_PANIC(('bound: op2 must be mem ref'));
    UndefinedOpcode(i);
    end;

  if Boolean(i^.os_32) then begin

    op1_32 := BX_READ_32BIT_REG(i^.nnn);

    read_virtual_dword(i^.seg, i^.rm_addr, PBit32u(@bound_min));
    read_virtual_dword(i^.seg, i^.rm_addr+4, PBit32u(@bound_max));

    (* ??? *)
    if ( (op1_32 < bound_min) or (op1_32 > bound_max) ) then begin
      BX_INFO(('BOUND: fails bounds test'));
      exception2([5, 0, 0]);
      end;
    end
  else begin

    op1_16 := BX_READ_16BIT_REG(i^.nnn);

    read_virtual_word(i^.seg, i^.rm_addr, PBit16u(@bound_min_16));
    read_virtual_word(i^.seg, i^.rm_addr+2, PBit16u(@bound_max_16));

    (* ??? *)
    if ( (op1_16 < bound_min_16) or (op1_16 > bound_max_16) ) then begin
      BX_INFO(('BOUND: fails bounds test'));
      exception2([5, 0, 0]);
      end;
    end;

end;
end;

procedure BX_CPU_C.INT1(I:PBxInstruction_tag);
begin
  // This is an undocumented instrucion (opcode $f1)
  // which is useful for an ICE system.

{$if BX_DEBUGGER=1}
  BX_CPU_THIS_PTR show_flag |:= Flag_int;
{$ifend}

  interrupt(1, 1, 0, 0);
{  BX_INSTR_FAR_BRANCH(BX_INSTR_IS_INT,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value,
                      BX_CPU_THIS_PTR eip);}
end;

  procedure
BX_CPU_C.INT3(I:PBxInstruction_tag);
begin
  // INT 3 is not IOPL sensitive

{$if BX_DEBUGGER = 1}
  BX_CPU_THIS_PTR show_flag |:= Flag_int;
{$ifend}

//BX_PANIC(('INT3: bailing'));
   interrupt(3, 1, 0, 0);
  {BX_INSTR_FAR_BRANCH(BX_INSTR_IS_INT,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value,
                      BX_CPU_THIS_PTR eip);}
end;

procedure BX_CPU_C.INT_Ib(I:PBxInstruction_tag);
var
  imm8:Bit8u;
begin

{$if BX_DEBUGGER=1}
  BX_CPU_THIS_PTR show_flag |:= Flag_int;
{$ifend}

  imm8 := i^.Ib;

  if Boolean((v8086_mode()<>0) and (IOPL<3)) then begin
    //BX_INFO(('int_ib: v8086: IOPL<3'));
    exception2([BX_GP_EXCEPTION, 0, 0]);
    end;

{$if SHOW_EXIT_STATUS=1}
if ( (imm8 = $21) and (AH = $4c) ) then begin
  BX_INFO(Format('INT 21/4C called AL:=$%02x, BX:=$%04x',[AL,BX]));
  end;
{$ifend}

  interrupt(imm8, 1, 0, 0); 
(*  BX_INSTR_FAR_BRANCH(BX_INSTR_IS_INT,
                      BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value,
                      BX_CPU_THIS_PTR eip);*)
end;

procedure BX_CPU_C.INTO(I:PBxInstruction_tag);
begin

{$if BX_DEBUGGER=1}
  BX_CPU_THIS_PTR show_flag |:= Flag_int;
{$ifend}

  (* ??? is this IOPL sensitive ? *)
  if Boolean(v8086_mode()) then BX_PANIC(('soft_int: v8086 mod_e unsupported'));

  if Boolean(get_OF()) then begin
     interrupt(4, 1, 0, 0); 
    {BX_INSTR_FAR_BRANCH(BX_INSTR_IS_INT,
                        BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].selector.value,
                        BX_CPU_THIS_PTR eip);}
    end;
end;
