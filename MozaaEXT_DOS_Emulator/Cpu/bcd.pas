{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
procedure BX_CPU_C.DAS(I:PBxInstruction_tag);
var
  tmpCF, tmpAL:Bit8u;
begin

  (* ??? *)
  (* the algorithm for DAS is fashioned after the pseudo code in the
   * Pentium Processor Family Developer's Manual, volume 3.  It seems
   * to have changed from earlier processor's manuals.  I'm not sure
   * if this is a correction in the algorithm printed, or Intel has
   * changed the handling of instruction.  It might not even be
   * correct yet...
   *)

  tmpCF := 0;
  tmpAL := AL;

  (* DAS effect the following flags: A,C,S,Z,P *)

  if (((tmpAL  and $0F) > $09) or (get_AF()<>0)) then begin
    set_AF(1);
    tmpCF := Bool(AL < $06) or get_CF();
    AL := AL - $06;
    (*tmpCF := (AL < 0) or CF;*)
    end;
  if ( (tmpAL > $99) or (get_CF()<>0) ) then begin
    AL := AL - $60;
    tmpCF := 1;
    end;

  set_CF(tmpCF);
  set_SF(AL shr 7);
  set_ZF(Bool(AL=0));
  set_PF_base(AL);
end;

procedure BX_CPU_C.AAA(I:PBxInstruction_tag);
var
  ALcarry:Bit8u;
begin

  ALcarry := Bool(AL > $f9);

  (* AAA effects the following flags: A,C *)
  if ( ((AL  and $0f) > 9) or (get_AF()<>0)) then begin
    AL := (AL + 6)  and $0f;
    AH := AH + 1 + ALcarry;
    set_AF(1);
    set_CF(1);
    end
  else begin
    set_AF(0);
    set_CF(0);
    AL := AL  and $0f;
    end;
end;

procedure BX_CPU_C.AAS(I:PBxInstruction_tag);
var
  ALborrow:Bit8u;
begin

  (* AAS affects the following flags: A,C *)

  ALborrow := Bool(AL < 6);

  if ( ((AL  and $0F) > $09) or (get_AF()<>0) ) then begin
    AL := (AL - 6)  and $0f;
    AH := AH - 1 - ALborrow;
    set_AF(1);
    set_CF(1);
    end
  else begin
    set_CF(0);
    set_AF(0);
    AL := AL  and $0f;
    end;
end;

procedure BX_CPU_C.AAM(I:PBxInstruction_tag);
var
  al_, imm8:Bit8u;
begin

  imm8 := i^.Ib;

  al_ := AL;
  AH := al_ div imm8;
  AL := al_ mod imm8;

  (* AAM affects the following flags: S,Z,P *)
  set_SF(Bool((AH  and $80) > 0));
  set_ZF(Bool(AX=0));
  set_PF_base(AL); (* ??? *)
end;

procedure BX_CPU_C.AAD(I:PBxInstruction_tag);
var
  imm8:Bit8u;
begin

  imm8 := i^.Ib;

  AL := AH * imm8 + AL;
  AH := 0;

  (* AAD effects the following flags: S,Z,P *)
  set_SF(Bool(AL >= $80));
  set_ZF(Bool(AL = 0));
  set_PF_base(AL);
end;

  procedure
BX_CPU_C.DAA(I:PBxInstruction_tag);
var
  al_:Bit8u;
begin

  al_ := AL;

  // DAA affects the following flags: S,Z,A,P,C
  // ???

  if (((al_ and $0F) > $09) or (get_AF()<>0)) then begin
    al_ := al_ + $06;
    set_AF(1);
    end
  else
    set_AF(0);

  if ((al_ > $9F) or (get_CF()<>0)) then begin
    al_ := al_ + $60;
    set_CF(1);
    end;

  AL := al_;

  set_SF(al_ shr 7);
  set_ZF(Bool(al_=0));
  set_PF_base(al);
end;
