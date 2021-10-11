{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
procedure BX_CPU_C.MOV_RLIb(I:PBxInstruction_tag);
begin
  Self.gen_reg[i^.b1  and $03].rl := i^.Ib;
end;

procedure BX_CPU_C.MOV_RHIb(I:PBxInstruction_tag);
begin
  Self.gen_reg[i^.b1  and $03].rh := i^.Ib;
end;

procedure BX_CPU_C.MOV_EbGb(I:PBxInstruction_tag);
var
  op2:Bit8u;
begin
  (* op2 is a register, op2_addr is an index of a register *)
  op2 := BX_READ_8BIT_REG(i^.nnn);

  (* now write op2 to op1 *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, op2);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @op2);
    end;
end;

procedure BX_CPU_C.MOV_GbEb(I:PBxInstruction_tag);
var
  op2:Bit8u;
begin

  if (i^.mod_ = $c0) then begin
    op2 := BX_READ_8BIT_REG(i^.rm);
    end
  else begin
    (* pointer, segment address pair *)
    read_virtual_byte(i^.seg, i^.rm_addr, @op2);
    end;

  BX_WRITE_8BIT_REG(i^.nnn, op2);
end;

procedure BX_CPU_C.MOV_ALOb(I:PBxInstruction_tag);
var
  temp_8:Bit8u;
  addr_32:Bit32u;
begin

  addr_32 := i^.Id;

  (* read from memory address *)
  if Boolean((i^.seg and BX_SEG_REG_NULL)=0) then begin
    read_virtual_byte(i^.seg, addr_32, @temp_8);
    end
  else begin
    read_virtual_byte(BX_SEG_REG_DS, addr_32, @temp_8);
    end;


  (* write to register *)
  AL := temp_8;
end;

procedure BX_CPU_C.MOV_ObAL(I:PBxInstruction_tag);
var
  temp_8:Bit8u;
  addr_32:Bit32u;
begin

  addr_32 := i^.Id;

  (* read from register *)
  temp_8 := AL;

  (* write to memory address *)
  if (i^.seg and BX_SEG_REG_NULL) = 0 then begin
    write_virtual_byte(i^.seg, addr_32, @temp_8);
    end
  else begin
    write_virtual_byte(BX_SEG_REG_DS, addr_32, @temp_8);
    end;
end;

procedure BX_CPU_C.MOV_EbIb(I:PBxInstruction_tag);
var
  op2:Bit8u;
begin

  op2 := i^.Ib;

  (* now write op2 back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, op2);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @op2);
    end;
end;

procedure BX_CPU_C.XLAT(I:PBxInstruction_tag);
var
  offset_32:Bit32u;
  al_:Bit8u;
begin

{$if BX_CPU_LEVEL >= 3}
  if (i^.as_32)<>0 then begin
    offset_32 := EBX + AL;
    end
  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    begin
    offset_32 := BX + AL;
    end;

  if Boolean((i^.seg and BX_SEG_REG_NULL)=0) then begin
    read_virtual_byte(i^.seg, offset_32, @al_);
    end
  else begin
    read_virtual_byte(BX_SEG_REG_DS, offset_32, @al_);
    end;
  AL := al_;
end;

procedure BX_CPU_C.XCHG_EbGb(I:PBxInstruction_tag);
var
  op2, op1:Bit8u;
begin

  (* op2 is a register, op2_addr is an index of a register *)
  op2 := BX_READ_8BIT_REG(i^.nnn);

  (* op1 is a register or memory reference *)
  if (i^.mod_ = $c0) then begin
    op1 := BX_READ_8BIT_REG(i^.rm);
    BX_WRITE_8BIT_REG(i^.rm, op2);
    end
  else begin
    (* pointer, segment address pair *)
    read_RMW_virtual_byte(i^.seg, i^.rm_addr, @op1);
    write_RMW_virtual_byte(op2);
    end;

  BX_WRITE_8BIT_REG(i^.nnn, op1);
end;
