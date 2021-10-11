{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.Resolve16mod0Rm0(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(BX + SI);
end;

procedure BX_CPU_C.Resolve16mod0Rm1(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(BX + DI);
end;

procedure BX_CPU_C.Resolve16mod0Rm2(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(BP + SI);
end;

procedure BX_CPU_C.Resolve16mod0Rm3(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(BP + DI);
end;

procedure BX_CPU_C.Resolve16mod0Rm4(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(SI);
end;

procedure BX_CPU_C.Resolve16mod0Rm5(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(DI);
end;

procedure BX_CPU_C.Resolve16mod0Rm7(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(BX);
end;

procedure BX_CPU_C.Resolve16mod1or2Rm0(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(BX + SI + Bit16s(i^.displ16u));
end;

procedure BX_CPU_C.Resolve16mod1or2Rm1(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(BX + DI + Bit16s(i^.displ16u));
end;

procedure BX_CPU_C.Resolve16mod1or2Rm2(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(BP + SI + Bit16s(i^.displ16u));
end;

procedure BX_CPU_C.Resolve16mod1or2Rm3(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(BP + DI + Bit16s(i^.displ16u));
end;

procedure BX_CPU_C.Resolve16mod1or2Rm4(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(SI + Bit16s(i^.displ16u));
end;

procedure BX_CPU_C.Resolve16mod1or2Rm5(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(DI + Bit16s(i^.displ16u));
end;

procedure BX_CPU_C.Resolve16mod1or2Rm6(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(BP + Bit16s(i^.displ16u));
end;

procedure BX_CPU_C.Resolve16mod1or2Rm7(I:PBxInstruction_tag);
begin
  i^.rm_addr := Bit16u(BX + Bit16s(i^.displ16u));
end;
