 { ****************************************************************************** }
 { Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
 { ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
unit jumpfar;

interface

uses SysUtils;

type
  jmp_buf = record
    _ebx, _esi, _edi, _ebp, _esp, _eip: longint;
  end;

  pjmp_buf = ^jmp_buf;

function setjmp(var rec: jmp_buf): longint; stdcall;
procedure longjmp(const rec: jmp_buf; return_value: longint); stdcall;

implementation

    {$STACKFRAMES ON}
function setjmp(var rec: jmp_buf): longint; assembler;
    { [ebp+12]: [ebp+8]:@rec, [ebp+4]:eip', [ebp+0]:ebp' }
asm // free: eax, ecx, edx
    { push ebp; mov ebp,esp }
  mov  edx,rec
  mov[edx].jmp_buf._ebx,ebx    { ebx }
  mov[edx].jmp_buf._esi,esi    { esi }
  mov[edx].jmp_buf._edi,edi    { edi }
  mov  eax,[ebp]               { ebp (caller stack frame) }
  mov[edx].jmp_buf._ebp,eax
  lea  eax,[ebp+12] { esp [12]: [8]:@rec, [4]:eip, [0]:ebp }
  mov[edx].jmp_buf._esp,eax
  mov  eax,[ebp+4]
  mov[edx].jmp_buf._eip,eax
  xor  eax,eax
  { leave }
  { ret  4 }
end;

procedure longjmp(const rec: jmp_buf; return_value: longint); assembler;
{ [ebp+12]: return_value [ebp+8]:@rec, [ebp+4]:eip', [ebp+0]:ebp' }
asm
  { push ebp, mov ebp,esp }
  mov  edx,rec
  mov  ecx,return_value
  mov  ebx,[edx].jmp_buf._ebx  { ebx }
  mov  esi,[edx].jmp_buf._esi  { esi }
  mov  edi,[edx].jmp_buf._edi  { edi }
  mov  ebp,[edx].jmp_buf._ebp  { ebp }
  mov  esp,[edx].jmp_buf._esp  { esp }
  mov  eax,[edx].jmp_buf._eip  { eip }
  push eax
  mov  eax,ecx
  ret  0
end;
    {$STACKFRAMES OFF}
end.
