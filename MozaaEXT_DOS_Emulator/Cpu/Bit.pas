{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
procedure BX_CPU_C.SETO_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETO: not available on < 386'));
{$else}

  if (get_OF())<>0 then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETNO_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETNO: not available on < 386'));
{$else}

  if (get_OF()=0) then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETB_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETB: not available on < 386'));
{$else}

  if (get_CF())<>0 then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETNB_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETNB: not available on < 386'));
{$else}

  if (get_CF()=0) then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETZ_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETZ: not available on < 386'));
{$else}

  if (get_ZF())<>0 then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETNZ_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETNZ: not available on < 386'));
{$else}

  if (get_ZF()=0) then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETBE_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETBE: not available on < 386'));
{$else}

  if ((get_CF()<>0) or (get_ZF()<>0)) then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETNBE_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETNBE: not available on < 386'));
{$else}

  if ((get_CF()=0) and (get_ZF()=0)) then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETS_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETS: not available on < 386'));
{$else}

  if (get_SF())<>0 then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETNS_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETNL: not available on < 386'));
{$else}

  if (get_SF()=0) then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETP_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETP: not available on < 386'));
{$else}

  if (get_PF())<>0 then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETNP_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETNP: not available on < 386'));
{$else}

  if (get_PF() = 0) then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETL_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETL: not available on < 386'));
{$else}

  if (get_SF() <> get_OF()) then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETNL_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETNL: not available on < 386'));
{$else}

  if (get_SF() = get_OF()) then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETLE_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETLE: not available on < 386'));
{$else}

  if ((get_ZF()<>0) or (get_SF() <> get_OF())) then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.SETNLE_Eb(I:PBxInstruction_tag);
var
  result_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('SETNLE: not available on < 386'));
{$else}

  if ((get_ZF()=0) and (get_SF()=get_OF())) then
    result_8 := 1
  else
    result_8 := 0;

  (* now write result back to destination *)
  if (i^.mod_ = $c0) then begin
    BX_WRITE_8BIT_REG(i^.rm, result_8);
    end
  else begin
    write_virtual_byte(i^.seg, i^.rm_addr, @result_8);
    end;
{$ifend}
end;

procedure BX_CPU_C.BSF_GvEv(I:PBxInstruction_tag);
var
  op1_32, op2_32:Bit32u;
  op1_16, op2_16:Bit16u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('BSF_GvEv(): not supported on < 386'));
{$else}

  if (i^.os_32)<>0 then begin (* 32 bit operand size mod_e *)
    (* for 32 bit operand size mod_e *)

    (* op2_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op2_32);
      end;

    if (op2_32 = 0) then begin
      set_ZF(1);
      (* op1_32 undefined *)
      exit;
      end;

    op1_32 := 0;
    while (op2_32 and $01) = 0 do begin
      Inc(op1_32);   //op1_32++
      op2_32:=op2_32 shr 1;
      end;
    set_ZF(0);

    (* now write result back to destination *)
    BX_WRITE_32BIT_REG(i^.nnn, op1_32);
    end
  else begin (* 16 bit operand size mod_e *)

    (* op2_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;

    if (op2_16 = 0) then begin
      set_ZF(1);
      (* op1_16 undefined *)
      exit;
      end;

    op1_16 := 0;
    while (op2_16 and $01) = 0 do begin
      Inc(op1_16); //op1_16++
      op2_16 := op2_16 shr 1;
      end;
    set_ZF(0);

    (* now write result back to destination *)
    BX_WRITE_16BIT_REG(i^.nnn, op1_16);
    end;
{$ifend}
end;

procedure BX_CPU_C.BSR_GvEv(I:PBxInstruction_tag);
var
  op1_32, op2_32:Bit32u;
  op1_16, op2_16:Bit16u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('BSR_GvEv(): not supported on < 386'));
{$else}

  if (i^.os_32)<>0 then begin (* 32 bit operand size mod_e *)
    (* for 32 bit operand size mod_e *)

    (* op2_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op2_32);
      end;

    if (op2_32 = 0) then begin
      set_ZF(1);
      (* op1_32 undefined *)
      exit;
      end;

    op1_32 := 31;
    while ((op2_32  and $80000000) = 0) do begin
      Dec(op1_32);
      op2_32 := op2_32 shl 1;
      end;
    set_ZF(0);

    (* now write result back to destination *)
    BX_WRITE_32BIT_REG(i^.nnn, op1_32);
    end
  else begin (* 16 bit operand size mod_e *)

    (* op2_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op2_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op2_16);
      end;

    if (op2_16 = 0) then begin
      set_ZF(1);
      (* op1_16 undefined *)
      exit;
      end;

    op1_16 := 15;
    while ( (op2_16  and $8000) = 0 ) do begin
      Dec(op1_16);
      op2_16 := op2_16 shl 1;
      end;
    set_ZF(0);

    (* now write result back to destination *)
    BX_WRITE_16BIT_REG(i^.nnn, op1_16);
    end;
{$ifend}
end;


procedure BX_CPU_C.BSWAP_EAX(I:PBxInstruction_tag);
var
  eax_, b0, b1, b2, b3:Bit32u;
begin
{$if (BX_CPU_LEVEL >= 4) or (BX_CPU_LEVEL_HACKED >= 4)}


  eax_ := EAX;
  b0  := eax_ and $ff; eax_ := eax_ shr 8;
  b1  := eax_ and $ff; eax_ := eax_ shr 8;
  b2  := eax_ and $ff; eax_ := eax_ shr 8;
  b3  := eax_;

  EAX := (b0 shl 24) or (b1 shl 16) or (b2 shl 8) or b3;
{$else}
  BX_PANIC(('BSWAP_EAX: not implemented CPU <= 3'));
{$ifend}
end;

procedure BX_CPU_C.BSWAP_ECX(I:PBxInstruction_tag);
var
  ecx_, b0, b1, b2, b3:Bit32u;
begin
{$if (BX_CPU_LEVEL >= 4) or (BX_CPU_LEVEL_HACKED >= 4)}

  ecx_ := ECX;
  b0  := ecx_  and $ff; ecx_ := ecx_ shr 8;
  b1  := ecx_  and $ff; ecx_ := ecx_ shr 8;
  b2  := ecx_  and $ff; ecx_ := ecx_ shr 8;
  b3  := ecx_;

  ECX := (b0 shl 24) or (b1 shl 16) or (b2 shl 8) or b3;
{$else}
  BX_PANIC(('BSWAP_ECX: not implemented CPU <= 3'));
{$ifend}
end;

procedure BX_CPU_C.BSWAP_EDX(I:PBxInstruction_tag);
var
  edx_, b0, b1, b2, b3:Bit32u;
begin
{$if (BX_CPU_LEVEL >= 4) or (BX_CPU_LEVEL_HACKED >= 4)}

  edx_ := EDX;
  b0  := edx_  and $ff; edx_ := edx_ shr 8;
  b1  := edx_  and $ff; edx_ := edx_ shr 8;
  b2  := edx_  and $ff; edx_ := edx_ shr 8;
  b3  := edx_;

  EDX := (b0 shl 24) or (b1 shl 16) or (b2 shl 8) or b3;
{$else}
  BX_PANIC(('BSWAP_EDX: not implemented CPU <= 3'));
{$ifend}
end;

procedure BX_CPU_C.BSWAP_EBX(I:PBxInstruction_tag);
var
  ebx_, b0, b1, b2, b3:Bit32u;
begin
{$if (BX_CPU_LEVEL >= 4) or (BX_CPU_LEVEL_HACKED >= 4)}

  ebx_ := EBX;
  b0  := ebx_  and $ff; ebx_ := ebx_ shr 8;
  b1  := ebx_  and $ff; ebx_ := ebx_ shr 8;
  b2  := ebx_  and $ff; ebx_ := ebx_ shr 8;
  b3  := ebx_;

  EBX := (b0 shl 24) or (b1 shl 16) or (b2 shl 8) or b3;
{$else}
  BX_PANIC(('BSWAP_EBX: not implemented CPU <= 3'));
{$ifend}
end;

procedure BX_CPU_C.BSWAP_ESP(I:PBxInstruction_tag);
var
  esp_, b0, b1, b2, b3:Bit32u;
begin
{$if (BX_CPU_LEVEL >= 4) or (BX_CPU_LEVEL_HACKED >= 4)}

  esp_ := ESP;
  b0  := esp_  and $ff; esp_ := esp_ shr 8;
  b1  := esp_  and $ff; esp_ := esp_ shr 8;
  b2  := esp_  and $ff; esp_ := esp_ shr 8;
  b3  := esp_;

  ESP := (b0 shl 24) or (b1 shl 16) or (b2 shl 8) or b3;
{$else}
  BX_PANIC(('BSWAP_ESP: not implemented CPU <= 3'));
{$ifend}
end;

procedure BX_CPU_C.BSWAP_EBP(I:PBxInstruction_tag);
var
  ebp_, b0, b1, b2, b3:Bit32u;
begin
{$if (BX_CPU_LEVEL >= 4) or (BX_CPU_LEVEL_HACKED >= 4)}

  ebp_ := EBP;
  b0  := ebp_  and $ff; ebp_ := ebp_ shr 8;
  b1  := ebp_  and $ff; ebp_ := ebp_ shr 8;
  b2  := ebp_  and $ff; ebp_ := ebp_ shr 8;
  b3  := ebp_;

  EBP := (b0 shl 24) or (b1 shl 16) or (b2 shl 8) or b3;
{$else}
  BX_PANIC(('BSWAP_EBP: not implemented CPU <= 3'));
{$ifend}
end;

procedure BX_CPU_C.BSWAP_ESI(I:PBxInstruction_tag);
var
  esi_, b0, b1, b2, b3:Bit32u;
begin
{$if (BX_CPU_LEVEL >= 4) or (BX_CPU_LEVEL_HACKED >= 4)}

  esi_ := ESI;
  b0  := esi_  and $ff; esi_ := esi_ shr 8;
  b1  := esi_  and $ff; esi_ := esi_ shr 8;
  b2  := esi_  and $ff; esi_ := esi_ shr 8;
  b3  := esi_;

  ESI := (b0 shl 24) or (b1 shl 16) or (b2 shl 8) or b3;
{$else}
  BX_PANIC(('BSWAP_ESI: not implemented CPU <= 3'));
{$ifend}
end;

procedure BX_CPU_C.BSWAP_EDI(I:PBxInstruction_tag);
var
  edi_, b0, b1, b2, b3:Bit32u;
begin
{$if (BX_CPU_LEVEL >= 4) or (BX_CPU_LEVEL_HACKED >= 4)}


  edi_ := EDI;
  b0  := edi_  and $ff; edi_:=edi_ shr 8;
  b1  := edi_  and $ff; edi_:=edi_ shr 8;
  b2  := edi_  and $ff; edi_:=edi_ shr 8;
  b3  := edi_;

  EDI := (b0 shl 24) or (b1 shl 16) or (b2 shl 8) or b3;
{$else}
  BX_PANIC(('BSWAP_EDI: not implemented CPU <= 3'));
{$ifend}
Vuoto;
end;

procedure BX_CPU_C.BT_EvGv(I:PBxInstruction_tag);
var
  op1_addr:Bit32u;
  op1_32, op2_32, index:Bit32u;
  displacement32:Bit32s;
  op2_16, op1_16:Bit16u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('BT_EvGv: not available on <386'));
{$else}

  if (i^.os_32)<>0 then begin (* 32 bit operand size mod_e *)
    (* for 32 bit operand size mod_e *)

    (* op2_32 is a register, op2_addr is an index of a register *)
    op2_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      op2_32 := op2_32 and $1f;
      set_CF((op1_32 shr op2_32) and $01);
      exit;
      end;

    index := op2_32  and $1f;
    //displacement32 := Bit32s(op2_32 and $ffffffe0) / 32; !!!
    displacement32 := Bit32s(op2_32 and $ffffffe0) div 32;
    op1_addr := i^.rm_addr + 4 * displacement32;

    (* pointer, segment address pair *)
    read_virtual_dword(i^.seg, op1_addr, @op1_32);

    set_CF((op1_32 shr index)  and $01);
    end
  else begin (* 16 bit operand size mod_e *)

    (* op2_16 is a register, op2_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      op2_16 := op2_16 and $0f;
      set_CF((op1_16 shr op2_16)  and $01);
      exit;
      end;

    index := op2_16  and $0f;
    //displacement32 := ((Bit16s(op2_16@$fff0)) / 16; !!!
    displacement32 := Bit16s(op2_16 and $fff0) div 16;
    op1_addr := i^.rm_addr + 2 * displacement32;

    (* pointer, segment address pair *)
    read_virtual_word(i^.seg, op1_addr, @op1_16);

    set_CF((op1_16 shr index)  and $01);
    end;
{$ifend}
end;

procedure BX_CPU_C.BTS_EvGv(I:PBxInstruction_tag);
var
  op1_addr:Bit32u;
  op1_32, op2_32, bit_i, index:Bit32u;
  displacement32:Bit32s;

  op1_16, op2_16:Bit16u;
begin
{$if BX_CPU_LEVEL < 3 }
  BX_PANIC(('BTS_EvGv: not available on <386'));
{$else}

  if (i^.os_32)<>0 then begin (* 32 bit operand size mod_e *)
    (* for 32 bit operand size mod_e *)

    (* op2_32 is a register, op2_addr is an index of a register *)
    op2_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      op2_32 := op2_32 and $1f;
      set_CF((op1_32 shr op2_32) and $01);
      op1_32 := op1_32 or (Bit32u(1) shl op2_32);

      (* now write diff back to destination *)
      BX_WRITE_32BIT_REG(i^.rm, op1_32);
      exit;
      end;

    index := op2_32  and $1f;
    //displacement32 := ((Bit32s((op2_32@$ffffffe0)) / 32; !!!
    displacement32 := Bit32s(op2_32 and $ffffffe0) div 32;
    op1_addr := i^.rm_addr + 4 * displacement32;

    (* pointer, segment address pair *)
    read_RMW_virtual_dword(i^.seg, op1_addr, @op1_32);

    bit_i := (op1_32 shr index)  and $01;
    op1_32 := op1_32 or (Bit32u(1) shl index);

    write_RMW_virtual_dword(op1_32);

    set_CF(bit_i);
    end
  else begin (* 16 bit operand size mod_e *)

    (* op2_16 is a register, op2_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      op2_16 := op2_16 and $0f;
      set_CF((op1_16 shr op2_16)  and $01);
      op1_16 := op1_16 or (Bit16u(1) shl op2_16);

      (* now write diff back to destination *)
      BX_WRITE_16BIT_REG(i^.rm, op1_16);
      exit;
      end;

    index := op2_16 and $0f;
    //displacement32 := ((Bit16s(op2_16 @$fff0)) / 16;
    displacement32 := Bit16s(op2_16 and $fff0) div 16;
    op1_addr := i^.rm_addr + 2 * displacement32;

    (* pointer, segment address pair *)
    read_RMW_virtual_word(i^.seg, op1_addr, @op1_16);

    bit_i := (op1_16 shr index)  and $01;
    op1_16 := op1_16 or (Bit16u(1) shl index);

    write_RMW_virtual_word(op1_16);

    set_CF(bit_i);
    end;
{$ifend}
end;

  procedure
BX_CPU_C.BTR_EvGv(I:PBxInstruction_tag);
var
  op1_addr:Bit32u;
  op1_32, op2_32, index, temp_cf:Bit32u;
  displacement32:Bit32s;
  op2_16, op1_16:Bit16u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('BTR_EvGv: not available on <386'));
{$else}

  if (i^.os_32)<>0 then begin (* 32 bit operand size mod_e *)
    (* for 32 bit operand size mod_e *)

    (* op2_32 is a register, op2_addr is an index of a register *)
    op2_32 := BX_READ_32BIT_REG(i^.nnn);

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      op2_32 := op2_32 and $1f;
      set_CF((op1_32 shr op2_32) and $01);
      op1_32 := op1_32 and not (Bit32u(1) shl op2_32);

      (* now write diff back to destination *)
      BX_WRITE_32BIT_REG(i^.rm, op1_32);
      exit;
      end;

    index := op2_32  and $1f;
    //displacement32 := (Bit32s(op2_32 and $ffffffe0)) / 32;
    displacement32 := (Bit32s(op2_32 and $ffffffe0)) div 32;
    op1_addr := i^.rm_addr + 4 * displacement32;

    (* pointer, segment address pair *)
    read_RMW_virtual_dword(i^.seg, op1_addr, @op1_32);

    temp_cf := (op1_32 shr index)  and $01;
    //op1_32 @:= ~(((Bit32u) 1) shl index); !!!
    op1_32 := op1_32 and not (Bit32u(1) shl index);

    (* now write back to destination *)
    write_RMW_virtual_dword(op1_32);

    set_CF(temp_cf);
    end
  else begin (* 16 bit operand size mod_e *)

    (* op2_16 is a register, op2_addr is an index of a register *)
    op2_16 := BX_READ_16BIT_REG(i^.nnn);

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      op2_16 := op2_16 and $0f;
      set_CF((op1_16 shr op2_16)  and $01);
      //op1_16 @:= ~(((Bit16u) 1) shl op2_16); !!!
      op1_16 := op1_16 and not (Bit16u(1) shl op2_16);

      (* now write diff back to destination *)
      BX_WRITE_16BIT_REG(i^.rm, op1_16);
      exit;
      end;

    index := op2_16 and $0f;
    //displacement32 := (Bit16s(op2_16 and $fff0)) / 16; !!!
    displacement32 := (Bit16s(op2_16 and $fff0)) div 16;
    op1_addr := i^.rm_addr + 2 * displacement32;

    (* pointer, segment address pair *)
    read_RMW_virtual_word(i^.seg, op1_addr, @op1_16);

    temp_cf := (op1_16 shr index)  and $01;
    //op1_16 @:= ~(((Bit16u) 1) shl index); !!!
    op1_16 := op1_16 and not (Bit16u(1) shl index); 

    (* now write back to destination *)
    write_RMW_virtual_word(op1_16);

    set_CF(temp_cf);
    end;
{$ifend}
end;

procedure BX_CPU_C.BTC_EvGv(I:PBxInstruction_tag);
var
  op1_addr:Bit32u;
  op1_32, op2_32, index_32, temp_CF:Bit32u;
  displacement32:Bit32s;
  op1_16, op2_16, index_16, temp_CF_16:Bit16u;
  displacement16:Bit16s;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('BTC_EvGv: not available on <386'));
{$else}

  if (i^.os_32)<>0 then begin (* 32 bit operand size mod_e *)
    (* for 32 bit operand size mod_e *)

    op2_32 := BX_READ_32BIT_REG(i^.nnn);
    index_32 := op2_32  and $1f;

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      op1_addr := 0; // keep compiler happy
      end
  else begin
      //displacement32 := Bit32s(op2_32  and $ffffffe0)) / 32;
      displacement32 := Bit32s(op2_32 and $ffffffe0) div 32;
      op1_addr := i^.rm_addr + 4 * displacement32;
      read_RMW_virtual_dword(i^.seg, op1_addr, @op1_32);
      end;

    temp_CF := (op1_32 shr index_32)  and $01;
    //op1_32 @:= ~(((Bit32u) 1) shl index_32);  (* clear out bit *) !!!
    op1_32 := op1_32 and not (Bit32u(1) shl index_32);
    op1_32 := op1_32 or (Bit32u(temp_CF=0) shl index_32); (* set to complement *)

    (* now write diff back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, op1_32);
      end
  else begin
      write_RMW_virtual_dword(op1_32);
      end;
    set_CF(temp_CF);
    end
  else begin (* 16 bit operand size mod_e *)

    op2_16 := BX_READ_16BIT_REG(i^.nnn);
    index_16 := op2_16  and $0f;

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      op1_addr := 0; // keep compiler happy
      end
  else begin
      //displacement16 := ((Bit16s(op2_16  and $fff0)) / 16;
      displacement16 := (Bit16s(op2_16  and $fff0)) div 16;
      op1_addr := i^.rm_addr + 2 * displacement16;
      read_RMW_virtual_word(i^.seg, op1_addr, @op1_16);
      end;

    temp_CF_16 := (op1_16 shr index_16)  and $01;
    //op1_16 := op1_16 and ~(((Bit16u) 1) shl index_16);  (* clear out bit *) !!!
    op1_16 := op1_16 and not (Bit16u(1) shl index_16);
    op1_16 := op1_16 or (Bit16u(temp_CF_16=0) shl index_16); (* set to complement *)

    (* now write diff back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, op1_16);
      end
  else begin
      write_RMW_virtual_word(op1_16);
      end;
    set_CF(temp_CF);
    end;
{$ifend}
end;

procedure BX_CPU_C.BT_EvIb(I:PBxInstruction_tag);
var
  op1_32:Bit32u;
  op2_8:Bit8u;
  op1_16:Bit16u;
  op2_8_8:Bit8u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('BT_EvIb: not available on <386'));
{$else}

  if (i^.os_32)<>0 then begin (* 32 bit operand size mod_e *)
    (* for 32 bit operand size mod_e *)

    op2_8 := i^.Ib;
    //op2_8 %:= 32; !!!
    op2_8 := op2_8 mod 32;

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    set_CF((op1_32 shr op2_8)  and $01);
    end
  else begin (* 16 bit operand size mod_e *)

    op2_8_8 := i^.Ib;
    op2_8_8 := op2_8_8 mod 16;

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    set_CF((op1_16 shr op2_8_8)  and $01);
    end;
{$ifend}
end;

procedure BX_CPU_C.BTS_EvIb(I:PBxInstruction_tag);
var
  op1_32, temp_CF:Bit32u;
  op2_8:Bit8u;
  op1_16, temp_CF_16:Bit16u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('BTS_EvIb: not available on <386'));
{$else}

  if (i^.os_32)<>0 then begin (* 32 bit operand size mod_e *)
    (* for 32 bit operand size mod_e *)

    op2_8 := i^.Ib;
    //op2_8 %:= 32; !!!
    op2_8 := op2_8 mod 32;

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    temp_CF := (op1_32 shr op2_8) and $01;
    op1_32 := op1_32 or (Bit32u(1) shl op2_8);

    (* now write diff back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, op1_32);
      end
  else begin
      write_RMW_virtual_dword(op1_32);
      end;
    set_CF(temp_CF);
    end
  else begin (* 16 bit operand size mod_e *)

    op2_8 := i^.Ib;
    //op2_8 %:= 16; !!!
    op2_8 := op2_8 mod 16;

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    temp_CF := (op1_16 shr op2_8)  and $01;
    op1_16 := op1_16 or (Bit16u(1) shl op2_8);

    (* now write diff back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, op1_16);
      end
  else begin
      write_RMW_virtual_word(op1_16);
      end;
    set_CF(temp_CF);
    end;
{$ifend}
end;

procedure BX_CPU_C.BTC_EvIb(I:PBxInstruction_tag);
var
  op1_32, temp_CF:Bit32u;
  op2_8:Bit8u;
  op1_16, temp_CF_8:Bit16u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('BTC_EvIb: not available on <386'));
{$else}

  if (i^.os_32)<>0 then begin (* 32 bit operand size mod_e *)
    (* for 32 bit operand size mod_e *)

    op2_8 := i^.Ib;
    //op2_8 %:= 32; !!!
    op2_8 := op2_8 mod 32;

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    temp_CF := (op1_32 shr op2_8)  and $01;

    //op1_32 := op1_32 and ~(((Bit32u) 1) shl op2_8);  (* clear out bit *) !!!
    op1_32 := op1_32 and not (Bit32u(1) shl op2_8);
    op1_32 := op1_32 or (Bit32u(not temp_CF) shl op2_8); (* set to complement *)

    (* now write diff back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, op1_32);
      end
  else begin
      write_RMW_virtual_dword(op1_32);
      end;
    set_CF(temp_CF);
    end
  else begin (* 16 bit operand size mod_e *)


    op2_8 := i^.Ib;
    //op2_8 %:= 16; !!!
    op2_8:=op2_8 mod 16;

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    temp_CF := (op1_16 shr op2_8)  and $01;
    //op1_16 := op1_16 and ~(((Bit16u) 1) shl op2_8);  (* clear out bit *) !!!
    op1_16 := op1_16 and not (Bit16u(1) shl op2_8);
    op1_16 := op1_16 or (Bit16u(not temp_CF) shl op2_8); (* set to complement *)

    (* now write diff back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, op1_16);
      end
  else begin
      write_RMW_virtual_word(op1_16);
      end;
    set_CF(temp_CF);
    end;
{$ifend}
end;

procedure BX_CPU_C.BTR_EvIb(I:PBxInstruction_tag);
var
  op1_32, temp_CF:Bit32u;
  op2_8:Bit8u;
  op1_16, temp_CF_8:Bit16u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('BTR_EvIb: not available on <386'));
{$else}

  if (i^.os_32)<>0 then begin (* 32 bit operand size mod_e *)
    (* for 32 bit operand size mod_e *)

    op2_8 := i^.Ib;
    //op2_8 %:= 32; !!!
    op2_8 := op2_8 mod 32;

    (* op1_32 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    temp_CF := (op1_32 shr op2_8)  and $01;
    //op1_32 := op1_32 and ~(((Bit32u) 1) shl op2_8); !!!
    op1_32 := op1_32 and not (Bit32u(1) shl op2_8);

    (* now write diff back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_32BIT_REG(i^.rm, op1_32);
      end
  else begin
      write_RMW_virtual_dword(op1_32);
      end;
    set_CF(temp_CF);
    end
  else begin (* 16 bit operand size mod_e *)

    op2_8 := i^.Ib;
    op2_8 :=op2_8 mod 16; // % !!!

    (* op1_16 is a register or memory reference *)
    if (i^.mod_ = $c0) then begin
      op1_16 := BX_READ_16BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_RMW_virtual_word(i^.seg, i^.rm_addr, @op1_16);
      end;

    temp_CF := (op1_16 shr op2_8)  and $01;
    //op1_16 := op1_16 and ~(((Bit16u) 1) shl op2_8); !!!
    op1_16 := op1_16 and not (Bit16u(1) shl op2_8);

    (* now write diff back to destination *)
    if (i^.mod_ = $c0) then begin
      BX_WRITE_16BIT_REG(i^.rm, op1_16);
      end
  else begin
      write_RMW_virtual_word(op1_16);
      end;
    set_CF(temp_CF);
    end;
{$ifend}
end;

