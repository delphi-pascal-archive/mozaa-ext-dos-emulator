{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)


procedure BX_CPU_C.enter_protected_mode;
begin
  BX_INFO(('processor switching into PROTECTED mod_e!!!'));
// debug(BX_CPU_THIS_PTR prev_eip);
  if Boolean(v8086_mode()) then BX_PANIC(('protect_ctrl: v8086 mod_e unsupported'));

  {if (bx_dbg.reset)
    BX_INFO(('processor switching into PROTECTED mod_e!!!'));}

if ((Self.sregs[BX_SEG_REG_CS].selector.rpl<>0) or (Self.sregs[BX_SEG_REG_SS].selector.rpl<>0)) then
  BX_PANIC(('enter_protected_mod_e: CS or SS rpl !:= 0'));
end;

procedure BX_CPU_C.enter_real_mode;
begin
// ???
  BX_INFO(('processor switching into REAL mod_e!!!'));
// debug(BX_CPU_THIS_PTR prev_eip);
  if Boolean(v8086_mode()) then BX_PANIC(('protect_ctrl: v8086 mod_e unsupported'));

  {if (bx_dbg.reset)
    BX_INFO(('processor switching into REAL mod_e!!!'));}

if ((Self.sregs[BX_SEG_REG_CS].selector.rpl<>0) or (Self.sregs[BX_SEG_REG_SS].selector.rpl<>0)) then
  BX_PANIC(('enter_real_mod_e: CS or SS rpl !:= 0'));
end;
