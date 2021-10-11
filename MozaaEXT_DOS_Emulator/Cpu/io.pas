{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
procedure BX_CPU_C.INSB_YbDX(I:PBxInstruction_tag);
var
  value8:Bit8u;
begin
  Value8:=0;
  if ((self.cr0.pe <> 0) and ((self.eflags.vm <> 0) or (CPL>IOPL))) then begin
    if Boolean(self.allow_io(DX, 1)=0) then begin
      exception2([BX_GP_EXCEPTION, 0, 0]);
      end;
    end;

  if (i^.as_32 <> 0) then begin
    // Write a zero to memory, to trigger any segment or page
    // faults before reading from IO port.
    write_virtual_byte(BX_SEG_REG_ES, EDI, @value8);

    value8 := bx_pc_system.inp(DX, 1);

    (* no seg override possible *)
    write_virtual_byte(BX_SEG_REG_ES, EDI, @value8);

    if Boolean(self.eflags.df) then begin
      EDI := EDI - 1;
      end
  else begin
      EDI := EDI + 1;
      end;
    end
  else begin
    // Write a zero to memory, to trigger any segment or page
    // faults before reading from IO port.
    write_virtual_byte(BX_SEG_REG_ES, DI, @value8);

    value8 := bx_pc_system.inp(DX, 1);

    (* no seg override possible *)
    write_virtual_byte(BX_SEG_REG_ES, DI, @value8);

    if Boolean(self.eflags.df) then begin
      DI := DI - 1;
      end
  else begin
      DI := DI + 1;
      end;
    end;
end;

procedure BX_CPU_C.INSW_YvDX(I:PBxInstruction_tag);
  // input word/doubleword from port to string
var
  edi_:Bit32u;
  incr:Word;
  value32:Bit32u;
  value16:Bit16u;
begin
  if Boolean(i^.as_32) then
    edi_ := EDI
  else
    edi_ := DI;

  if Boolean(i^.os_32) then begin
    value32:=0;

    if (Boolean(self.cr0.pe) and (Boolean(self.eflags.vm) or (CPL>IOPL))) then begin
      if Boolean(self.allow_io(DX, 4)=0) then begin
        exception2([BX_GP_EXCEPTION, 0, 0]);
        end;
      end;

    // Write a zero to memory, to trigger any segment or page
    // faults before reading from IO port.
    write_virtual_dword(BX_SEG_REG_ES, edi, @value32);

    value32 := bx_pc_system.inp(DX, 4);

    (* no seg override allowed *)
    write_virtual_dword(BX_SEG_REG_ES, edi_, @value32);
    incr := 4;
    end
  else begin
    value16:=0;

    if (Boolean(self.cr0.pe) and (Boolean(self.eflags.vm) or (CPL>IOPL))) then begin
      if Boolean(self.allow_io(DX, 2)=0) then begin
        exception2([BX_GP_EXCEPTION, 0, 0]);
        end;
      end;

    // Write a zero to memory, to trigger any segment or page
    // faults before reading from IO port.
    write_virtual_word(BX_SEG_REG_ES, edi_, @value16);

    value16 := bx_pc_system.inp(DX, 2);

    (* no seg override allowed *)
    write_virtual_word(BX_SEG_REG_ES, edi_, @value16);
    incr := 2;
    end;

  if Boolean(i^.as_32) then begin
    if Boolean(self.eflags.df) then
      EDI := EDI - incr
    else
      EDI := EDI + incr;
    end
  else begin
    if Boolean(self.eflags.df) then
      DI := DI - incr
    else
      DI := DI + incr;
    end;
end;

procedure BX_CPU_C.OUTSB_DXXb(I:PBxInstruction_tag);
var
  seg:Word;
  value8:Bit8u;
  esi_:Bit32u;
begin

  if (Boolean(self.cr0.pe) and (Boolean(self.eflags.vm) or (CPL>IOPL))) then begin
    if Boolean(self.allow_io(DX, 1)=0) then begin
      exception2([BX_GP_EXCEPTION, 0, 0]);
      end;
    end;

  if Boolean((i^.seg and BX_SEG_REG_NULL)=0) then begin
    seg := i^.seg;
    end
  else begin
    seg := BX_SEG_REG_DS;
    end;

  if Boolean(i^.as_32) then
    esi_ := ESI
  else
    esi_ := SI;

  read_virtual_byte(seg, esi_, @value8);

  bx_pc_system.outp(DX, value8, 1);

  if Boolean(i^.as_32) then begin
    if Boolean(self.eflags.df) then
      ESI := ESI - 1
    else
      ESI := ESI + 1;
    end
  else begin
    if Boolean(self.eflags.df) then
      SI:=SI - 1
    else
      SI:=SI + 1
    end;
end;

procedure BX_CPU_C.OUTSW_DXXv(I:PBxInstruction_tag);
  // output word/doubleword string to port
var
  seg:Word;
  esi_:Bit32u;
  incr:Word;
  value32:Bit32u;
  value16:Bit16u;
begin

  if ((i^.seg and BX_SEG_REG_NULL)=0) then begin
    seg := i^.seg;
    end
  else begin
    seg := BX_SEG_REG_DS;
    end;

  if (i^.as_32)<>0 then
    esi_ := ESI
  else
    esi_ := SI;

  if (i^.os_32)<>0 then begin

    if ((self.cr0.pe<>0) and ((self.eflags.vm<>0) or (CPL>IOPL))) then begin
      if (( self.allow_io(DX, 4) )=0) then begin
        exception2([BX_GP_EXCEPTION, 0, 0]);
        end;
      end;

    read_virtual_dword(seg, esi_, @value32);

    bx_pc_system.outp(DX, value32, 4);
    incr := 4;
    end
  else begin

    if ((self.cr0.pe<>0) and ((self.eflags.vm<>0) or (CPL>IOPL))) then begin
      if ( self.allow_io(DX, 2)=0) then begin
        exception2([BX_GP_EXCEPTION, 0, 0]);
        end;
      end;

    read_virtual_word(seg, esi_, @value16);

    bx_pc_system.outp(DX, value16, 2); 
    incr := 2;
    end;

  if (i^.as_32)<>0 then begin
    if (self.eflags.df)<>0 then
      ESI := ESI - incr
    else
      ESI := ESI + incr;
    end
  else begin
    if (self.eflags.df)<>0 then
      SI := SI - incr
    else
      SI := SI + incr;
    end;
end;

procedure BX_CPU_C.IN_ALIb(I:PBxInstruction_tag);
var
  al_, imm8:Bit8u;
begin

  imm8 := i^.Ib;

  al_ := self.inp8(imm8);

  AL := al_;
end;

procedure BX_CPU_C.IN_eAXIb(I:PBxInstruction_tag);
var
  imm8:Bit8u;
  eax_:Bit32u;
  ax_:Bit16u;
begin

  imm8 := i^.Ib;

{$if BX_CPU_LEVEL > 2}
  if Boolean(i^.os_32) then begin

    eax_ := self.inp32(imm8);
    EAX := eax_;
    end
  else
{$ifend} (* BX_CPU_LEVEL > 2 *)
    begin

    ax_ := self.inp16(imm8);
    AX := ax_;
    end;
end;

procedure BX_CPU_C.OUT_IbAL(I:PBxInstruction_tag);
var
  al_, imm8:Bit8u;
begin

  imm8 := i^.Ib;

  al_ := AL;

  self.outp8(imm8, al_);
end;

procedure BX_CPU_C.OUT_IbeAX(I:PBxInstruction_tag);
var
  imm8:Bit8u;
begin

  imm8 := i^.Ib;

{$if BX_CPU_LEVEL > 2}
  if Boolean(i^.os_32) then begin
    self.outp32(imm8, EAX);
    end
  else
{$ifend} (* BX_CPU_LEVEL > 2 *)
    begin
    self.outp16(imm8, AX);
    end;
end;

procedure BX_CPU_C.IN_ALDX(I:PBxInstruction_tag);
var
  al_:Bit8u;
begin

  al_ := self.inp8(DX);

  AL := al_;
end;

procedure BX_CPU_C.IN_eAXDX(I:PBxInstruction_tag);
var
  eax_:Bit32u;
  ax_:Bit16u;
begin
{$if BX_CPU_LEVEL > 2}
  if Boolean(i^.os_32) then begin

    eax_ := self.inp32(DX);
    EAX := eax_;
    end
  else
{$ifend} (* BX_CPU_LEVEL > 2 *)
    begin

    ax_ := self.inp16(DX);
    AX := ax_;
    end;
end;

procedure BX_CPU_C.OUT_DXAL(I:PBxInstruction_tag);
var
  dx_:Bit16u;
  al_:Bit8u;
begin
  dx_ := DX;
  al_ := AL;

  self.outp8(dx_, al_);
end;

procedure BX_CPU_C.OUT_DXeAX(I:PBxInstruction_tag);
var
  dx_:Bit16u;
begin

  dx_ := DX;

{$if BX_CPU_LEVEL > 2}
  if Boolean(i^.os_32) then begin
    self.outp32(dx_, EAX);
    end
  else
{$ifend} (* BX_CPU_LEVEL > 2 *)
    begin
    self.outp16(dx_, AX);
    end;
end;

