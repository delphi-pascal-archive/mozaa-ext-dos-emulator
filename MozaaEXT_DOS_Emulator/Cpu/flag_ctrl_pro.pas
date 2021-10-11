{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.write_flags(flags:Bit16u; change_IOPL:Bool; change_IF:Bool);
begin
  Self.set_CF(flags  and $01);
  Self.set_PF((flags shr 2)  and $01);
  Self.set_AF((flags shr 4)  and $01);
  Self.set_ZF((flags shr 6)  and $01);
  Self.set_SF((flags shr 7)  and $01);

{$if 0=1}
// +++
if Boolean(Self.eflags.tf=0 @ and (flags@$0100))
  BX_DEBUG(( 'TF 0^.1' ));
else if Boolean(Self.eflags.tf @ and !(flags@$0100))
  BX_DEBUG(( 'TF 1^.0' ));
else if Boolean(Self.eflags.tf @ and (flags@$0100))
  BX_DEBUG(( 'TF 1^.1' ));
{$ifend}

  Self.eflags.tf := (flags shr 8)  and $01;
  if Boolean(Self.eflags.tf) then begin
    Self.async_event := 1;
    end;

  if Boolean(change_IF) then
    Self.eflags.if_ := (flags shr 9)  and $01;

  Self.eflags.df := (flags shr 10)  and $01;
  Self.set_OF((flags shr 11)  and $01);


{$if BX_CPU_LEVEL = 2}
  Self.eflags.iopl := 0;
  Self.eflags.nt := 0;
{$else}
  if Boolean(change_IOPL) then
    Self.eflags.iopl := (flags shr 12)  and $03;
  Self.eflags.nt := (flags shr 14)  and $01;
{$ifend}
end;


{$if BX_CPU_LEVEL >= 3}
procedure BX_CPU_C.write_eflags(eflags_raw:Bit32u; change_IOPL:Bool ; change_IF:Bool;change_VM:Bool; change_RF:Bool);
begin
  Self.set_CF(eflags_raw and $01);
  Self.set_PF((eflags_raw shr 2)  and $01);
  Self.set_AF((eflags_raw shr 4)  and $01);
  Self.set_ZF((eflags_raw shr 6)  and $01);
  Self.set_SF((eflags_raw shr 7)  and $01);

{$if 0=1}
// +++
if Boolean(Self.eflags.tf=0 @ and (eflags_raw@$0100))
  BX_DEBUG(( 'TF 0^.1' ));
else if Boolean(Self.eflags.tf @ and !(eflags_raw@$0100))
  BX_DEBUG(( 'TF 1^.0' ));
else if Boolean(Self.eflags.tf @ and (eflags_raw@$0100))
  BX_DEBUG(( 'TF 1^.1' ));
{$ifend}

  Self.eflags.tf := (eflags_raw shr 8)  and $01;
  if Boolean(Self.eflags.tf) then begin
    Self.async_event := 1;
    end;

  if Boolean(change_IF) then
    Self.eflags.if_ := (eflags_raw shr 9)  and $01;

  Self.eflags.df := (eflags_raw shr 10)  and $01;
  Self.set_OF((eflags_raw shr 11)  and $01);

  if Boolean(change_IOPL) then
    Self.eflags.iopl := (eflags_raw shr 12)  and $03;
  Self.eflags.nt := (eflags_raw shr 14)  and $01;

  if Boolean(change_VM) then begin
    Self.eflags.vm := (eflags_raw shr 17)  and $01;
{$if BX_SUPPORT_V8086_MODE = 0}
    if Boolean(Self.eflags.vm)
      BX_PANIC(('write_eflags: VM bit set: BX_SUPPORT_V8086_mod_E=0'));
{$ifend}
    end;
  if Boolean(change_RF) then begin
    Self.eflags.rf := (eflags_raw shr 16)  and $01;
    end;

{$if BX_CPU_LEVEL >= 4}
  Self.eflags.ac := (eflags_raw shr 18)  and $01;
  Self.eflags.id := (eflags_raw shr 21)  and $01;
{$ifend}

end;
{$ifend} (* BX_CPU_LEVEL >= 3 *)


function BX_CPU_C.read_flags:Bit16u;
var
  flags:Bit16u;
begin

  flags := (get_CF()) or (Self.eflags.bit1 shl 1) or ((get_PF()) shl 2) or (Self.eflags.bit3 shl 3) or
           (Bool(get_AF()>0) shl 4) or (Self.eflags.bit5 shl 5) or (Bool(get_ZF()>0) shl 6) or (Bool(get_SF()>0) shl 7) or
           (Self.eflags.tf shl 8) or (Self.eflags.if_ shl 9) or (Self.eflags.df shl 10) or (Bool(get_OF()>0) shl 11) or
           (Self.eflags.iopl shl 12) or (Self.eflags.nt shl 14) or (Self.eflags.bit15 shl 15);

  (* 8086: bits 12-15 always set to 1.
   * 286: in real mod_e, bits 12-15 always cleared.
   * 386+: real-mod_e: bit15 cleared, bits 14..12 are last loaded value
   *       protected-mod_e: bit 15 clear, bit 14 := last loaded, IOPL?
   *)
{$if BX_CPU_LEVEL < 2}
  flags := flags or $F000;  (* 8086 nature *)
{$elseif BX_CPU_LEVEL = 2}
  if Boolean(real_mode()) then begin
    flags := flags and $0FFF;  (* 80286 in real mod_e nature *)
    end;
{$else} (* 386+ *)
{$ifend}

  Result:=Flags;
end;


{$if BX_CPU_LEVEL >= 3}
function BX_CPU_C.read_eflags:Bit32u;
var
  eflags_raw:Bit32u;
begin

  eflags_raw :=
          (get_CF()) or
          (Self.eflags.bit1 shl 1) or
          ((get_PF()) shl 2) or
          (Self.eflags.bit3 shl 3) or
          (Bool(get_AF()>0) shl 4) or
          (Self.eflags.bit5 shl 5) or
          (Bool(get_ZF()>0) shl 6) or
          (Bool(get_SF()>0) shl 7) or
          (Self.eflags.tf shl 8) or
          (Self.eflags.if_ shl 9) or
          (Self.eflags.df shl 10) or
          (Bool(get_OF()>0) shl 11) or
          (Self.eflags.iopl shl 12) or
          (Self.eflags.nt shl 14) or
          (Self.eflags.bit15 shl 15) or
          (Self.eflags.rf shl 16) or
          (Self.eflags.vm shl 17)
{$if BX_CPU_LEVEL >= 4}
         or (Self.eflags.ac shl 18)
         or (Self.eflags.id shl 21)
{$ifend}
           ;

{$if 0=1}
  (*
   * 386+: real-mod_e: bit15 cleared, bits 14..12 are last loaded value
   *       protected-mod_e: bit 15 clear, bit 14 := last loaded, IOPL?
   *)
{$ifend}

  Result:=eflags_raw;
end;
{$ifend} (* BX_CPU_LEVEL >= 3 *)
