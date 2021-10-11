{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.SAHF(I:PBxInstruction_tag);
begin
  set_SF((AH and $80) shr 7);
  set_ZF((AH and $40) shr 6);
  set_AF((AH and $10) shr 4);
  set_CF(AH  and $01);
  set_PF((AH and $04) shr 2);
end;

procedure BX_CPU_C.LAHF(I:PBxInstruction_tag);
begin
  AH :=IfThen(Boolean(get_SF()) , $80 , 0) or
       IfThen(Boolean(get_ZF()) , $40 , 0) or
       IfThen(Boolean(get_AF()) , $10 , 0) or
       IfThen(Boolean(get_PF()) , $04 , 0) or ($02) or IfThen(Boolean(get_CF()) , $01 , 0);
end;

procedure BX_CPU_C.CLC(I:PBxInstruction_tag);
begin
  set_CF(0);
end;

procedure BX_CPU_C.STC(I:PBxInstruction_tag);
begin
  set_CF(1);
end;

procedure BX_CPU_C.CLI(I:PBxInstruction_tag);
begin
{$if BX_CPU_LEVEL >= 2}
  if Boolean(Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0))) then begin
    if (CPL > IOPL) then begin
      //BX_INFO(('CLI: CPL > IOPL')); (* ??? *)
      exception2([BX_GP_EXCEPTION, 0, 0]);
      exit;
      end;
    end
{$if BX_CPU_LEVEL >= 3}
  else if Boolean(v8086_mode()) then begin
    if (IOPL <> 3) then begin
      //BX_INFO(('CLI: IOPL !:= 3')); (* ??? *)
      exception2([BX_GP_EXCEPTION, 0, 0]);
      exit;
      end;
    end;
{$ifend}
{$ifend}

  Self.eflags.if_ := 0;
end;

procedure BX_CPU_C.STI(I:PBxInstruction_tag);
begin
{$if BX_CPU_LEVEL >= 2}
  if Boolean(Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0))) then begin
    if (CPL > IOPL) then begin
      //BX_INFO(('STI: CPL > IOPL')); (* ??? *)
      exception(BX_GP_EXCEPTION, 0, 0);
      exit;
      end;
    end
{$if BX_CPU_LEVEL >= 3}
  else if Boolean(v8086_mode()) then begin
    if (IOPL <> 3) then begin
      //BX_INFO(('STI: IOPL !:= 3')); (* ??? *)
      exception(BX_GP_EXCEPTION, 0, 0);
      exit;
      end;
    end;
{$ifend}
{$ifend}

  if Boolean(Self.eflags.if_=0) then begin
    Self.eflags.if_ := 1;
    Self.inhibit_mask := Self.inhibit_mask or BX_INHIBIT_INTERRUPTS;
    Self.async_event := 1;
    end;
end;

procedure
BX_CPU_C.CLD(I:PBxInstruction_tag);
begin
  Self.eflags.df := 0;
end;

procedure BX_CPU_C.STD(I:PBxInstruction_tag);
begin
  Self.eflags.df := 1;
end;

procedure BX_CPU_C.CMC(I:PBxInstruction_tag);
begin
  set_CF(Word(get_CF()=0));
end;

procedure BX_CPU_C.PUSHF_Fv(I:PBxInstruction_tag);
begin
  if (Boolean(v8086_mode()) and (IOPL<3)) then begin
    exception2([BX_GP_EXCEPTION, 0, 0]);
    exit;
    end;

{$if BX_CPU_LEVEL >= 3}
  if Boolean(i^.os_32) then begin
    push_32(read_eflags()  and $00fcffff);
    end
  else
{$ifend}
    begin
    push_16(read_flags()); 
    end;
end;

procedure BX_CPU_C.POPF_Fv(I:PBxInstruction_tag);
var
  eflags:Bit32u;
  flags:Bit16u;
begin

{$if BX_CPU_LEVEL >= 3}
  if Boolean(v8086_mode()) then begin
    if (IOPL < 3) then begin
      //BX_INFO(('popf_fv: IOPL < 3'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      exit;
      end;
    if Boolean(i^.os_32) then begin
      BX_PANIC(('POPFD(): not supported in virtual mod_e'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      exit;
      end;
    end;

  if Boolean(i^.os_32) then begin

    pop_32(@eflags);

    eflags := eflags and $00277fd7;
    if Boolean(real_mode()=0) then begin
      write_eflags(eflags, (* change IOPL? *) Bool(CPL=0), (* change IF? *) Bool(CPL<=IOPL), 0, 0);
      end
  else begin (* real mod_e *)
      write_eflags(eflags, (* change IOPL? *) 1, (* change IF? *) 1, 0, 0);
      end;
    end
  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    begin (* 16 bit opsize *)

    pop_16(@flags);

    if Boolean(real_mode()=0) then begin
      write_flags(flags, (* change IOPL? *) Bool(CPL=0), (* change IF? *) Bool(CPL<=IOPL));
      end
  else begin (* real mod_e *)
      write_flags(flags, (* change IOPL? *) 1, (* change IF? *) 1); 
      end;
    end;
end;

procedure BX_CPU_C.SALC(I:PBxInstruction_tag);
begin
  if Boolean(get_CF) then begin
    AL := $ff;
    end
  else begin
    AL := $00;
    end;
end;
