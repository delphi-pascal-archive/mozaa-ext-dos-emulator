{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.FWAIT(i:PBxInstruction_tag);
begin
  if ( (Self.cr0.ts<>0) and (Self.cr0.mp<>0 )) then begin
    exception(BX_NM_EXCEPTION, 0, 0);
    end;
{$if BX_SUPPORT_FPU=1}
{$else}
  BX_INFO(('FWAIT not implemented'));
{$ifend}
end;

procedure BX_CPU_C.ESC0(i:PBxInstruction_tag);
begin
  if ( (Self.cr0.em<>0) or (Self.cr0.ts<>0) ) then begin
    exception(BX_NM_EXCEPTION, 0, 0);
    end;
{$if BX_SUPPORT_FPU=1}

{$else}
  BX_INFO(('ESC0 not implemented'));
{$ifend}
end;

procedure BX_CPU_C.ESC1(i:PBxInstruction_tag);
begin
  if ( (Self.cr0.em<>0) or (Self.cr0.ts<>0) ) then begin
    exception(BX_NM_EXCEPTION, 0, 0);
    end;
{$if BX_SUPPORT_FPU=1}
{$else}
  BX_INFO(('ESC0 not implemented'));
{$ifend}
end;

procedure BX_CPU_C.ESC2(i:PBxInstruction_tag);
begin
  if ( (Self.cr0.em<>0) or (Self.cr0.ts<>0) ) then begin
    exception(BX_NM_EXCEPTION, 0, 0);
    end;
{$if BX_SUPPORT_FPU=1}
{$else}
  BX_INFO(('ESC0 not implemented'));
{$ifend}
end;

procedure BX_CPU_C.ESC3(i:PBxInstruction_tag);
begin
  if ( (Self.cr0.em<>0) or (Self.cr0.ts<>0) ) then begin
    exception(BX_NM_EXCEPTION, 0, 0);
    end;
{$if BX_SUPPORT_FPU=1}
{$else}
  BX_INFO(('ESC0 not implemented'));
{$ifend}
end;

procedure BX_CPU_C.ESC4(i:PBxInstruction_tag);
begin
  if ( (Self.cr0.em<>0) or (Self.cr0.ts<>0) ) then begin
    exception(BX_NM_EXCEPTION, 0, 0);
    end;
{$if BX_SUPPORT_FPU=1}
{$else}
  BX_INFO(('ESC0 not implemented'));
{$ifend}
end;

procedure BX_CPU_C.ESC5(i:PBxInstruction_tag);
begin
  if ( (Self.cr0.em<>0) or (Self.cr0.ts<>0) ) then begin
    exception(BX_NM_EXCEPTION, 0, 0);
    end;
{$if BX_SUPPORT_FPU=1}
{$else}
  BX_INFO(('ESC0 not implemented'));
{$ifend}
end;

procedure BX_CPU_C.ESC6(i:PBxInstruction_tag);
begin
  if ( (Self.cr0.em<>0) or (Self.cr0.ts<>0) ) then begin
    exception(BX_NM_EXCEPTION, 0, 0);
    end;
{$if BX_SUPPORT_FPU=1}
{$else}
  BX_INFO(('ESC0 not implemented'));
{$ifend}
end;

procedure BX_CPU_C.ESC7(i:PBxInstruction_tag);
begin
  if ( (Self.cr0.em<>0) or (Self.cr0.ts<>0) ) then begin
    exception(BX_NM_EXCEPTION, 0, 0);
    end;
{$if BX_SUPPORT_FPU=1}
{$else}
  BX_INFO(('ESC0 not implemented'));
{$ifend}
end;
