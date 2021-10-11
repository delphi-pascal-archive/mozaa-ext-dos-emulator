{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
procedure BX_CPU_C.JCXZ_Jb(I:PBxInstruction_tag);
var
  temp_ECX:Bit32u;
  new_EIP:Bit32u;
begin
  if (i^.as_32)<>0 then
    temp_ECX := ECX
  else
    temp_ECX := CX;

  if ( temp_ECX = 0 ) then begin

    new_EIP := EIP + Bit32s(i^.Id);
    if (i^.os_32=0) then
      new_EIP := new_EIP and $0000ffff;
{$if BX_CPU_LEVEL >= 2}
    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if ( new_EIP > Self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled ) then begin
        BX_PANIC(('jcxz_jb: offset outside of CS limits'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        end;
      end;
{$ifend}
    EIP := new_EIP;
    {BX_INSTR_CNEAR_BRANCH_TAKEN(new_EIP);}
    revalidate_prefetch_q(); 
    end;
end;

procedure BX_CPU_C.LOOPNE_Jb(I:PBxInstruction_tag);
var
  count, new_EIP:Bit32u;
begin

{$if BX_CPU_LEVEL >= 3}
  if (i^.as_32)<>0 then
    count := ECX
  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    count := CX;

  count:=count-1;
  if ( (count<>0) and (get_ZF()=0) ) then begin

    new_EIP := EIP + Bit32s(i^.Id);
    if (i^.os_32=0) then
      new_EIP := new_EIP and $0000ffff;
    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if (new_EIP > Self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled) then begin
        BX_PANIC(('loopne_jb: offset outside of CS limits'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        end;
      end;
    Self.eip := new_EIP;
    //BX_INSTR_CNEAR_BRANCH_TAKEN(new_EIP);
    revalidate_prefetch_q(); 
    end;

  if (i^.as_32)<>0 then
    ECX:=ECX-1
  else
    CX:=CX-1;
end;

procedure BX_CPU_C.LOOPE_Jb(I:PBxInstruction_tag);
var
  count, new_EIP:Bit32u;
begin

{$if BX_CPU_LEVEL >= 3}
  if (i^.as_32)<>0 then
    count := ECX
  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    count := CX;

  count:=count-1;
  if ( (count<>0) and (get_ZF<>0)) then begin

    new_EIP := EIP + Bit32s(i^.Id);
    if (i^.os_32=0) then
      new_EIP := new_EIP and $0000ffff;
    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if (new_EIP > Self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled) then begin
        BX_PANIC(('loope_jb: offset outside of CS limits'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        end;
      end;
    Self.eip := new_EIP;
    //BX_INSTR_CNEAR_BRANCH_TAKEN(new_EIP);
    revalidate_prefetch_q(); 
    end;
  if (i^.as_32)<>0 then
    ECX:=ECX - 1
  else
    CX:=CX-1;
end;

procedure BX_CPU_C.LOOP_Jb(I:PBxInstruction_tag);
var
  count, new_EIP:Bit32u;
begin

{$if BX_CPU_LEVEL >= 3}
  if (i^.as_32)<>0 then
    count := ECX
  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    count := CX;

  count:=count-1;
  if (count <> 0) then begin

    new_EIP := EIP + Bit32s(i^.Id);
    if (i^.os_32=0) then
      new_EIP := new_EIP and $0000ffff;
    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if (new_EIP > Self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled) then begin
        BX_PANIC(('loop_jb: offset outside of CS limits'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        end;
      end;
    Self.eip := new_EIP;
    //BX_INSTR_CNEAR_BRANCH_TAKEN(new_EIP);
    revalidate_prefetch_q();
    end;

  if (i^.as_32)<>0 then
    ECX:=ECX-1
  else
    CX:=CX-1;
end;
