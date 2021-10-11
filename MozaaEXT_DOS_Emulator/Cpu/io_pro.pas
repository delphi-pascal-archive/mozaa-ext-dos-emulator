{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
function BX_CPU_C.inp16(addr:Bit16u):Bit16u;
var
  ret16:Bit16u;
begin
  if (Boolean(Self.cr0.pe) and (Boolean(Self.eflags.vm) or (CPL>IOPL))) then begin
    if Boolean(Self.allow_io(addr, 2)=0) then begin
      // BX_INFO(('cpu_inp16: GP0()!'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      Result:=0;
      exit;
      end;
    end;

  ret16 := bx_pc_system.inp(addr, 2);
  Result:= ret16;
end;

procedure BX_CPU_C.outp16(addr:Bit16u;value:Bit16u);
begin
  (* If CPL <= IOPL, then all IO addresses are accessible.
   * Otherwise, must check the IO permission map on >286.
   * On the 286, there is no IO permissions map *)

  if (Boolean(Self.cr0.pe) and (Boolean(Self.eflags.vm) or (CPL>IOPL))) then begin
    if Boolean( Self.allow_io(addr, 2)=0) then begin
      // BX_INFO(('cpu_outp16: GP0()!'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      exit;
      end;
    end;

  bx_pc_system.outp(addr, value, 2);
end;

function BX_CPU_C.inp32(addr:Bit16u):Bit32u;
var
  ret32:Bit32u;
begin

  if (Boolean(Self.cr0.pe) and (Boolean(Self.eflags.vm) or (CPL>IOPL))) then begin
    if Boolean(Self.allow_io(addr, 4)=0) then begin
      // BX_INFO(('cpu_inp32: GP0()!'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      Result:=0;
      exit;
      end;
    end;

  ret32 := bx_pc_system.inp(addr, 4);
  Result:= ret32;
end;

procedure BX_CPU_C.outp32(addr:Bit16u; value:Bit32u);
begin
  (* If CPL <= IOPL, then all IO addresses are accessible.
   * Otherwise, must check the IO permission map on >286.
   * On the 286, there is no IO permissions map *)

  if (Boolean(Self.cr0.pe) and (Boolean(Self.eflags.vm) or (CPL>IOPL))) then begin
    if Boolean( Self.allow_io(addr, 4)=0) then begin
      // BX_INFO(('cpu_outp32: GP0()!'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      exit;
      end;
    end;

  bx_pc_system.outp(addr, value, 4);
end;

function BX_CPU_C.inp8(addr:Bit16u):Bit8u;
var
  ret8:Bit8u;
begin

  if (Boolean(Self.cr0.pe) and (Boolean(Self.eflags.vm) or (CPL>IOPL))) then begin
    if Boolean(Self.allow_io(addr, 1)=0) then begin
      // BX_INFO(('cpu_inp8: GP0()!'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      Result:=0;
      Exit;
      end;
    end;

  ret8 := bx_pc_system.inp(addr, 1);
  Result:=ret8;
end;

procedure BX_CPU_C.outp8(addr:Bit16u; value:Bit8u);
begin
  (* If CPL <= IOPL, then all IO addresses are accessible.
   * Otherwise, must check the IO permission map on >286.
   * On the 286, there is no IO permissions map *)

  if (Boolean(Self.cr0.pe) and (Boolean(Self.eflags.vm) or (CPL>IOPL))) then begin
    if Boolean( Self.allow_io(addr, 1)=0) then begin
      // BX_INFO(('cpu_outp8: GP0()!'));
      exception2([BX_GP_EXCEPTION, 0, 0]);
      exit;
      end;
    end;

  bx_pc_system.outp(addr, value, 1); 
end;


function BX_CPU_C.allow_io(addr:Bit16u; len:unsigned):Bool;
var
  io_base, permission16:Bit16u;
  bit_index, i:Word;
begin

  if ((Self.tr.cache.valid=0) or (Self.tr.cache.type_<>9)) then begin
    BX_INFO(('allow_io(): TR doesn''t point to a valid 32bit TSS'));
    Result:=0;
    exit;
    end;

  if (Self.tr.cache.tss386.limit_scaled < 103) then begin
    BX_PANIC(('allow_io(): TR.limit < 103'));
    end;

  access_linear(Self.tr.cache.tss386.base + 102, 2, 0, BX_READ,
                         @io_base);
  if (io_base <= 103) then begin
    {BX_INFO(('PE is %u', Self.cr0.pe));
    BX_INFO(('VM is %u', Self.eflags.vm));
    BX_INFO(('CPL is %u', CPL));
    BX_INFO(('IOPL is %u', IOPL));
    BX_INFO(('addr is %u', addr));
    BX_INFO(('len is %u', len));
    BX_PANIC(('allow_io(): TR:io_base <= 103'));}
    end;

  if (io_base > Self.tr.cache.tss386.limit_scaled) then begin
    BX_INFO(('allow_io(): CPL > IOPL: no IO bitmap defined #GP(0)'));
    Result:=0;
    Exit;
    end;

  access_linear(Self.tr.cache.tss386.base + io_base + addr div 8,
                   2, 0, BX_READ, @permission16);

  bit_index := addr  and $07;
  permission16 := permission16 shr bit_index;
  I:=0;
  while I < len do
    begin
    if Boolean(permission16 and $01) then
      begin
        Result:=0;
        Exit;
      end;
    permission16 := permission16 shr 1;
    Inc(I);
    end;

  Result:=1;
end;
