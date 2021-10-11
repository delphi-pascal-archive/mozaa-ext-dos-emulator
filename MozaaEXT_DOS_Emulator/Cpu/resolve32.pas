{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.Resolve32mod0Rm0(I:PBxInstruction_tag);
begin
  i^.rm_addr := EAX;
end;
  procedure
BX_CPU_C.Resolve32mod0Rm1(I:PBxInstruction_tag);
begin
  i^.rm_addr := ECX;
end;
  procedure
BX_CPU_C.Resolve32mod0Rm2(I:PBxInstruction_tag);
begin
  i^.rm_addr := EDX;
end;
  procedure
BX_CPU_C.Resolve32mod0Rm3(I:PBxInstruction_tag);
begin
  i^.rm_addr := EBX;
end;
  procedure
BX_CPU_C.Resolve32mod0Rm6(I:PBxInstruction_tag);
begin
  i^.rm_addr := ESI;
end;
  procedure
BX_CPU_C.Resolve32mod0Rm7(I:PBxInstruction_tag);
begin
  i^.rm_addr := EDI;
end;


procedure BX_CPU_C.Resolve32mod1or2Rm0(I:PBxInstruction_tag);
begin
  i^.rm_addr := EAX + i^.displ32u;
end;
  procedure
BX_CPU_C.Resolve32mod1or2Rm1(I:PBxInstruction_tag);
begin
  i^.rm_addr := ECX + i^.displ32u;
end;
  procedure
BX_CPU_C.Resolve32mod1or2Rm2(I:PBxInstruction_tag);
begin
  i^.rm_addr := EDX + i^.displ32u;
end;
  procedure
BX_CPU_C.Resolve32mod1or2Rm3(I:PBxInstruction_tag);
begin
  i^.rm_addr := EBX + i^.displ32u;
end;
  procedure
BX_CPU_C.Resolve32mod1or2Rm5(I:PBxInstruction_tag);
begin
  i^.rm_addr := EBP + i^.displ32u;
end;
  procedure
BX_CPU_C.Resolve32mod1or2Rm6(I:PBxInstruction_tag);
begin
  i^.rm_addr := ESI + i^.displ32u;
end;
  procedure
BX_CPU_C.Resolve32mod1or2Rm7(I:PBxInstruction_tag);
begin
  i^.rm_addr := EDI + i^.displ32u;
end;

  procedure
BX_CPU_C.Resolve32mod0Base0(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := EAX + scaled_index;
end;
  procedure
BX_CPU_C.Resolve32mod0Base1(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := ECX + scaled_index;
end;

procedure BX_CPU_C.Resolve32mod0Base2(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := EDX + scaled_index;
end;

procedure BX_CPU_C.Resolve32mod0Base3(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := EBX + scaled_index;
end;

procedure BX_CPU_C.Resolve32mod0Base4(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := ESP + scaled_index;
end;

procedure BX_CPU_C.Resolve32mod0Base5(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := i^.displ32u + scaled_index;
end;

procedure BX_CPU_C.Resolve32mod0Base6(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := ESI + scaled_index;
end;

procedure BX_CPU_C.Resolve32mod0Base7(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := EDI + scaled_index;
end;

procedure BX_CPU_C.Resolve32mod1or2Base0(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := EAX + scaled_index + i^.displ32u;
end;

procedure BX_CPU_C.Resolve32mod1or2Base1(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := ECX + scaled_index + i^.displ32u;
end;

procedure BX_CPU_C.Resolve32mod1or2Base2(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := EDX + scaled_index + i^.displ32u;
end;

procedure BX_CPU_C.Resolve32mod1or2Base3(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := EBX + scaled_index + i^.displ32u;
end;

procedure BX_CPU_C.Resolve32mod1or2Base4(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := ESP + scaled_index + i^.displ32u;
end;

procedure BX_CPU_C.Resolve32mod1or2Base5(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := EBP + scaled_index + i^.displ32u;
end;

procedure BX_CPU_C.Resolve32mod1or2Base6(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := ESI + scaled_index + i^.displ32u;
end;

procedure BX_CPU_C.Resolve32mod1or2Base7(I:PBxInstruction_tag);
var
  scaled_index:Bit32u;
begin

  if (i^.index <> 4) then
    scaled_index := BX_READ_32BIT_REG(i^.index) shl i^.scale
  else
    scaled_index := 0;
  i^.rm_addr := EDI + scaled_index + i^.displ32u;
end;
