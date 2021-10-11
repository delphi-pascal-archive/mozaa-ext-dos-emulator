{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.PUSH_RX(I:PBxInstruction_tag);
begin
  push_16(Self.gen_reg[i^.b1  and $07].rx );
end;

procedure BX_CPU_C.POP_RX(I:PBxInstruction_tag);
var
  rx:Bit16u;
begin
  pop_16(@rx);
  Self.gen_reg[i^.b1  and $07].rx := rx;
end;

procedure BX_CPU_C.POP_Ew(I:PBxInstruction_tag);
var
  val16:Bit16u;
begin

  pop_16(@val16);

  if (i^.mod_ = $c0) then begin
    BX_WRITE_16BIT_REG(i^.rm, val16);
    end
  else begin
    // Note: there is one little weirdism here.  When 32bit addressing
    // is used, it is possible to use ESP in the mod_rm addressing.
    // If used, the value of ESP after the pop is used to calculate
    // the address.
    if ((i^.as_32<>0) and (i^.mod_<>$c0) and (i^.rm=4) and (i^.base=4)) then begin
      i^.Resolvemodrm(i);
      end;
    write_virtual_word(i^.seg, i^.rm_addr, @val16);
    end;
end;

procedure BX_CPU_C.PUSHAD16(I:PBxInstruction_tag);
var
  temp_ESP:Bit32u;
  sp_:Bit16u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('PUSHAD: not supported on an 8086'));
{$else}

  if (Self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
    temp_ESP := ESP
  else
    temp_ESP := SP;


{$if BX_CPU_LEVEL >= 2}
    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if (can_push(@Self.sregs[BX_SEG_REG_SS].cache, temp_ESP, 16)=0) then begin
        BX_PANIC(('PUSHA(): stack doesn''t have enough room!'));
        exception2([BX_SS_EXCEPTION, 0, 0]);
        exit;
        end;
      end
  else
{$ifend}
      begin
      if (temp_ESP < 16) then
        BX_PANIC(('pushad: eSP < 16'));
      end;

    sp_ := SP;

    (* ??? optimize this by using virtual write, all checks passed *)
    push_16(AX);
    push_16(CX);
    push_16(DX);
    push_16(BX);
    push_16(sp_);
    push_16(BP);
    push_16(SI);
    push_16(DI);
{$ifend}
end;

procedure BX_CPU_C.POPAD16(I:PBxInstruction_tag);
var
  di_, si_, bp_, tmp, bx_, dx_, cx_, ax_:Bit16u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('POPAD not supported on an 8086'));
{$else} (* 286+ *)

    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if (can_pop(16)=0) then begin
        BX_PANIC(('pop_a: not enough bytes on stack'));
        exception2([BX_SS_EXCEPTION, 0, 0]);
        exit;
        end;
      end;

    (* ??? optimize this *)
    pop_16(@di_);
    pop_16(@si_);
    pop_16(@bp_);
    pop_16(@tmp); (* value for SP discarded *)
    pop_16(@bx_);
    pop_16(@dx_);
    pop_16(@cx_);
    pop_16(@ax_);

    DI := di_;
    SI := si_;
    BP := bp_;
    BX := bx_;
    DX := dx_;
    CX := cx_;
    AX := ax_;
{$ifend}
end;

procedure BX_CPU_C.PUSH_Iw(I:PBxInstruction_tag);
var
  imm16:Bit16u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('PUSH_Iv: not supported on 8086!'));
{$else}

    imm16 := i^.Iw;

    push_16(imm16);
{$ifend}
end;

procedure BX_CPU_C.PUSH_Ew(I:PBxInstruction_tag);
var
  op1_16:Bit16u;
begin

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    push_16(op1_16);
end;
