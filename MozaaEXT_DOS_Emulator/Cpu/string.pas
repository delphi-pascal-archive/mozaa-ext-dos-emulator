{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.MOVSB_XbYb(I:PBxInstruction_tag);
var
  seg:unsigned;
  temp8:Bit8u;
  esi_, edi_:Bit32u;
  si_, di_:Bit16u;
begin

  if (i^.seg and BX_SEG_REG_NULL)=0 then begin
    seg := i^.seg;
    end
  else begin
    seg := BX_SEG_REG_DS;
    end;

{$if BX_CPU_LEVEL >= 3}
  if (i^.as_32)<>0 then begin

    esi_ := ESI;
    edi_ := EDI;

    read_virtual_byte(seg, esi_, @temp8);

    write_virtual_byte(BX_SEG_REG_ES, edi_, @temp8);

    if (Self.eflags.df)<>0 then begin
      (* decrement ESI, EDI *)
      dec(esi_);
      dec(edi_);
      end
  else begin
      (* increment ESI, EDI *)
      inc(esi_);
      inc(edi_);
      end;

    ESI := esi_;
    EDI := edi_;
    end

  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    begin (* 16 bit address mod_e *)

    si_ := SI;
    di_ := DI;

    read_virtual_byte(seg, si_, @temp8);

    write_virtual_byte(BX_SEG_REG_ES, di_, @temp8);

    if (Self.eflags.df)<>0 then begin
      (* decrement SI, DI *)
      dec(si_);
      dec(di_);
      end
  else begin
      (* increment SI, DI *)
      inc(si_);
      inc(di_);
      end;

    SI := si_;
    DI := di_;
    end;
end;

procedure BX_CPU_C.MOVSW_XvYv(I:PBxInstruction_tag);
var
  seg:unsigned;
  temp32:Bit32u;

  esi_, edi_:Bit32u;
  temp16:Bit16u;
  si_, di_:Bit16u;
begin


  if ((i^.seg and BX_SEG_REG_NULL)=0) then begin
    seg := i^.seg;
    end
  else begin
    seg := BX_SEG_REG_DS;
    end;

{$if BX_CPU_LEVEL >= 3}
  if (i^.as_32)<>0 then begin

    esi_ := ESI;
    edi_ := EDI;

    if (i^.os_32)<>0 then begin
      read_virtual_dword(seg, esi_, @temp32);

      write_virtual_dword(BX_SEG_REG_ES, edi_, @temp32);

      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        dec(esi_,4);
        dec(edi_,4);
        end
      else begin
        (* increment ESI *)
        inc(esi_,4);
        inc(edi_,4);
        end;
      end (* if Boolean(i^.os_32) ... *)
    else begin (* 16 bit opsize mod_e *)

      read_virtual_word(seg, esi_, @temp16);

      write_virtual_word(BX_SEG_REG_ES, edi_, @temp16);

      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        dec(esi_,2);
        dec(edi_,2);
        end
      else begin
        (* increment ESI *)
        inc(esi_,2);
        inc(edi_,2);
        end;
      end;

    ESI := esi_;
    EDI := edi_;
    end

  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    begin (* 16bit address mod_e *)

    si_ := SI;
    di_ := DI;

{$if BX_CPU_LEVEL >= 3}
    if (i^.os_32)<>0 then begin

      read_virtual_dword(seg, si_, @temp32);

      write_virtual_dword(BX_SEG_REG_ES, di_, @temp32);

      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        dec(si_,4);
        dec(di_,4);
        end
      else begin
        (* increment ESI *)
        inc(si_,4);
        inc(di_,4);
        end;
      end (* if Boolean(i^.os_32) ... *)
    else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
      begin (* 16 bit opsize mod_e *)

      read_virtual_word(seg, si_, @temp16);

      write_virtual_word(BX_SEG_REG_ES, di_, @temp16);

      if (Self.eflags.df)<>0 then begin
        (* decrement SI, DI *)
        dec(si_,2);
        dec(di_,2);
        end
      else begin
        (* increment SI, DI *)
        inc(si_,2);
        inc(di_,2);
        end;
      end;

    SI := si_;
    DI := di_;
    end;
end;

procedure BX_CPU_C.CMPSB_XbYb(I:PBxInstruction_tag);
var
  seg:unsigned;
  op1_8, op2_8, diff_8:Bit8u;
  esi_, edi_:Bit32u;
  si_, di_:Bit16u;
begin

  if ((i^.seg and BX_SEG_REG_NULL)=0) then begin
    seg := i^.seg;
    end
  else begin
    seg := BX_SEG_REG_DS;
    end;

{$if BX_CPU_LEVEL >= 3}
  if (i^.as_32)<>0 then begin

    esi_ := ESI;
    edi_ := EDI;

    read_virtual_byte(seg, esi_, @op1_8);

    read_virtual_byte(BX_SEG_REG_ES, edi_, @op2_8);

    diff_8 := op1_8 - op2_8;

    SET_FLAGS_OSZAPC_8(op1_8, op2_8, diff_8, BX_INSTR_CMPS8);

    if (Self.eflags.df)<>0 then begin
      (* decrement ESI *)
      dec(esi_);
      dec(edi_);
      end
  else begin
      (* increment ESI *)
      inc(esi_);
      inc(edi_);
      end;

    EDI := edi_;
    ESI := esi_;
    end
  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    begin (* 16bit address mod_e *)

    si_ := SI;
    di_ := DI;

    read_virtual_byte(seg, si_, @op1_8);

    read_virtual_byte(BX_SEG_REG_ES, di_, @op2_8);

    diff_8 := op1_8 - op2_8;

    SET_FLAGS_OSZAPC_8(op1_8, op2_8, diff_8, BX_INSTR_CMPS8);

    if (Self.eflags.df)<>0 then begin
      (* decrement ESI *)
      dec(si_);
      dec(di_);
      end
  else begin
      (* increment ESI *)
      inc(si_);
      inc(di_);
      end;

    DI := di_;
    SI := si_;
    end;
end;

procedure BX_CPU_C.CMPSW_XvYv(I:PBxInstruction_tag);
var
  seg:unsigned;
  op1_32, op2_32, diff_32:Bit32u;
  esi_, edi_:Bit32u;
  op1_16, op2_16, diff_16:Bit16u;
  si_, di_:Bit16u;
begin

  if ((i^.seg and BX_SEG_REG_NULL)=0) then begin
    seg := i^.seg;
    end
  else begin
    seg := BX_SEG_REG_DS;
    end;

{$if BX_CPU_LEVEL >= 3}
  if (i^.as_32)<>0 then begin

    esi_ := ESI;
    edi_ := EDI;


    if (i^.os_32)<>0 then begin
      read_virtual_dword(seg, esi_, @op1_32);

      read_virtual_dword(BX_SEG_REG_ES, edi_, @op2_32);

      diff_32 := op1_32 - op2_32;

      SET_FLAGS_OSZAPC_32(op1_32, op2_32, diff_32, BX_INSTR_CMPS32);

      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        dec(esi_,4);
        dec(edi_,4);
        //esi_ -:= 4;
        //edi_ -:= 4;
        end
      else begin
        (* increment ESI *)
        inc(esi_,4);
        inc(edi_,4);
        //esi_ +:= 4;
        //edi_ +:= 4;
        end;
      end
  else begin (* 16 bit opsize *)

      read_virtual_word(seg, esi_, @op1_16);

      read_virtual_word(BX_SEG_REG_ES, edi_, @op2_16);

      diff_16 := op1_16 - op2_16;

      SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_INSTR_CMPS16);

      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        dec(esi_,2);
        dec(edi_,2);
        end
      else begin
        (* increment ESI *)
        inc(esi_,2);
        inc(edi_,2);
        end;
      end;


    EDI := edi_;
    ESI := esi_;
    end
  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    begin (* 16 bit address mod_e *)

    si_ := SI;
    di_ := DI;

{$if BX_CPU_LEVEL >= 3}
    if (i^.os_32)<>0 then begin

      read_virtual_dword(seg, si_, @op1_32);

      read_virtual_dword(BX_SEG_REG_ES, di_, @op2_32);

      diff_32 := op1_32 - op2_32;

      SET_FLAGS_OSZAPC_32(op1_32, op2_32, diff_32, BX_INSTR_CMPS32);

      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        dec(si_,4);
        dec(di_,4);
        end
      else begin
        (* increment ESI *)
        inc(si_,4);
        inc(di_,4);
        end;
      end
  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
      begin (* 16 bit opsize *)

      read_virtual_word(seg, si_, @op1_16);

      read_virtual_word(BX_SEG_REG_ES, di_, @op2_16);

      diff_16 := op1_16 - op2_16;

      SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_INSTR_CMPS16);

      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        dec(si_,2);
        dec(di_,2);
        end
      else begin
        (* increment ESI *)
        inc(si_,2);
        inc(di_,2);
        end;
      end;


    DI := di_;
    SI := si_;
    end;
end;

procedure BX_CPU_C.SCASB_ALXb(I:PBxInstruction_tag);
var
  op1_8, op2_8, diff_8:Bit8u;
  edi_:Bit32u;
  di_:Bit16u;
begin


{$if BX_CPU_LEVEL >= 3}
  if (i^.as_32)<>0 then begin

    edi_ := EDI;

    op1_8 := AL;

    read_virtual_byte(BX_SEG_REG_ES, edi_, @op2_8);

    diff_8 := op1_8 - op2_8;

    SET_FLAGS_OSZAPC_8(op1_8, op2_8, diff_8, BX_INSTR_SCAS8);


    if (Self.eflags.df)<>0 then begin
      (* decrement ESI *)
      dec(edi_);
      end
  else begin
      (* increment ESI *)
      inc(edi_);
      end;

    EDI := edi_;
    end

  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    begin (* 16bit address mod_e *)

    di_ := DI;

    op1_8 := AL;

    read_virtual_byte(BX_SEG_REG_ES, di_, @op2_8);

    diff_8 := op1_8 - op2_8;

    SET_FLAGS_OSZAPC_8(op1_8, op2_8, diff_8, BX_INSTR_SCAS8);

    if (Self.eflags.df)<>0 then begin
      (* decrement ESI *)
      dec(di_);
      end
  else begin
      (* increment ESI *)
      inc(di_);
      end;

    DI := di_;
    end;
end;

procedure BX_CPU_C.SCASW_eAXXv(I:PBxInstruction_tag);
var
  edi_:Bit32u;
  op1_32, op2_32, diff_32:Bit32u;
  op1_16, op2_16, diff_16:Bit16u;
  di_:Bit16u;
begin
{$if BX_CPU_LEVEL >= 3}
  if (i^.as_32)<>0 then begin

    edi_ := EDI;

    if (i^.os_32)<>0 then begin

      op1_32 := EAX;
      read_virtual_dword(BX_SEG_REG_ES, edi_, @op2_32);

      diff_32 := op1_32 - op2_32;

      SET_FLAGS_OSZAPC_32(op1_32, op2_32, diff_32, BX_INSTR_SCAS32);

      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        dec(edi_,4);
        end
      else begin
        (* increment ESI *)
        inc(edi_,4);
        end;
      end
  else begin (* 16 bit opsize *)

      op1_16 := AX;
      read_virtual_word(BX_SEG_REG_ES, edi_, @op2_16);

      diff_16 := op1_16 - op2_16;

      SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_INSTR_SCAS16);

      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        dec(edi_,2);
        end
      else begin
        (* increment ESI *)
        inc(edi_,2);
        end;
      end;

    EDI := edi_;
    end
  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    begin (* 16bit address mod_e *)

    di_ := DI;

{$if BX_CPU_LEVEL >= 3}
    if (i^.os_32)<>0 then begin

      op1_32 := EAX;
      read_virtual_dword(BX_SEG_REG_ES, di_, @op2_32);

      diff_32 := op1_32 - op2_32;

      SET_FLAGS_OSZAPC_32(op1_32, op2_32, diff_32, BX_INSTR_SCAS32);

      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        dec(di_,4);
        end
      else begin
        (* increment ESI *)
        inc(di_,4);
        end;
      end
  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
      begin (* 16 bit opsize *)

      op1_16 := AX;
      read_virtual_word(BX_SEG_REG_ES, di_, @op2_16);

      diff_16 := op1_16 - op2_16;

      SET_FLAGS_OSZAPC_16(op1_16, op2_16, diff_16, BX_INSTR_SCAS16);

      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        dec(di_,2);
        end
      else begin
        (* increment ESI *)
        inc(di_,2);
        end;
      end;

    DI := di_;
    end;
end;

procedure BX_CPU_C.STOSB_YbAL(I:PBxInstruction_tag);
var
  al_:Bit8u;
  edi_:Bit32u;
  di_:Bit16u;
begin

{$if BX_CPU_LEVEL >= 3}
  if (i^.as_32)<>0 then begin

    edi_ := EDI;

    al_ := AL;
    write_virtual_byte(BX_SEG_REG_ES, edi_, @al_);

    if (Self.eflags.df)<>0 then begin
      (* decrement EDI *)
      dec(edi_);
      end
  else begin
      (* increment EDI *)
      inc(edi_);
      end;

    EDI := edi_;
    end
  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    begin (* 16bit address size *)

    di_ := DI;

    al_ := AL;
    write_virtual_byte(BX_SEG_REG_ES, di_, @al_);

    if (Self.eflags.df)<>0 then begin
      (* decrement EDI *)
      dec(di_);
      end
  else begin
      (* increment EDI *)
      inc(di_);
      end;

    DI := di_;
    end;
end;

procedure BX_CPU_C.STOSW_YveAX(I:PBxInstruction_tag);
var
  edi_:Bit32u;
  eax_:Bit32u;
  ax_:Bit16u;
  di_:Bit16u;
begin
{$if BX_CPU_LEVEL >= 3}
  if (i^.as_32)<>0 then begin

    edi_ := EDI;

    if (i^.os_32)<>0 then begin

        eax_ := EAX;
        write_virtual_dword(BX_SEG_REG_ES, edi_, @eax_);

        if (Self.eflags.df)<>0 then begin
          (* decrement EDI *)
          dec(edi_,4);
          end
        else begin
          (* increment EDI *)
          inc(edi_,4);
          end;
      end (* if Boolean(i^.os_32) ... *)
    else begin (* 16 bit opsize mod_e *)

        ax_ := AX;
        write_virtual_word(BX_SEG_REG_ES, edi_, @ax_);

        if (Self.eflags.df)<>0 then begin
          (* decrement EDI *)
          dec(edi_,2);
          end
        else begin
          (* increment EDI *)
          inc(edi_,2);
          end;
      end;

    EDI := edi_;
    end

  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    begin (* 16bit address size *)

    di_ := DI;

{$if BX_CPU_LEVEL >= 3}
    if (i^.os_32)<>0 then begin

        eax_ := EAX;
        write_virtual_dword(BX_SEG_REG_ES, di_, @eax_);

        if (Self.eflags.df)<>0 then begin
          (* decrement EDI *)
          dec(di_,4);
          end
        else begin
          (* increment EDI *)
          inc(di_,4);
          end;
      end  (* if Boolean(i^.os_32) ... *)
    else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
      begin (* 16 bit opsize mod_e *)
        ax_ := AX;
        write_virtual_word(BX_SEG_REG_ES, di_, @ax_);

        if (Self.eflags.df)<>0 then begin
          (* decrement EDI *)
          dec(di_,2);
          end
        else begin
          (* increment EDI *)
          inc(di_,2);
          end;
      end;

    DI := di_;
    end;
end;

procedure BX_CPU_C.LODSB_ALXb(I:PBxInstruction_tag);
var
  seg:unsigned;
  al_:Bit8u;
  esi_:Bit32u;
  si_:Bit16u;
begin

  if ((i^.seg and BX_SEG_REG_NULL)=0) then begin
    seg := i^.seg;
    end
  else begin
    seg := BX_SEG_REG_DS;
    end;

{$if BX_CPU_LEVEL >= 3}
  if (i^.as_32)<>0 then begin

    esi_ := ESI;

    read_virtual_byte(seg, esi_, @al_);

    AL := al_;
    if (Self.eflags.df)<>0 then begin
      (* decrement ESI *)
      dec(esi_);
      end
  else begin
      (* increment ESI *)
      inc(esi_);
      end;

    ESI := esi_;
    end
  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    begin (* 16bit address mod_e *)

    si_ := SI;

    read_virtual_byte(seg, si_, @al_);

    AL := al_;
    if (Self.eflags.df)<>0 then begin
      (* decrement ESI *)
      si_:=si-1;
      end
  else begin
      (* increment ESI *)
      si_:=si+1;
      end;

    SI := si_;
    end;
end;

procedure BX_CPU_C.LODSW_eAXXv(I:PBxInstruction_tag);
var
  seg:unsigned;
  esi_:Bit32u;
  eax_:Bit32u;
  ax_:Bit16u;
  si_:Bit16u;
begin

  if ((i^.seg and BX_SEG_REG_NULL)=0) then begin
    seg := i^.seg;
    end
  else begin
    seg := BX_SEG_REG_DS;
    end;

{$if BX_CPU_LEVEL >= 3}
  if (i^.as_32)<>0 then begin

    esi_ := ESI;

    if (i^.os_32)<>0 then begin

      read_virtual_dword(seg, esi_, @eax_);

      EAX := eax_;
      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        dec(esi_,4);
        end
      else begin
        inc(esi_,4);
        (* increment ESI *)
        end;
      end (* if Boolean(i^.os_32) ... *)
    else begin (* 16 bit opsize mod_e *)
      read_virtual_word(seg, esi_, @ax_);

      AX := ax_;
      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        dec(esi_,2);
        end
      else begin
        (* increment ESI *)
        inc(esi_,2);
        end;
      end;

    ESI := esi_;
    end
  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
    begin (* 16bit address mod_e *)
    si_ := SI;

{$if BX_CPU_LEVEL >= 3}
    if (i^.os_32)<>0 then begin

      read_virtual_dword(seg, si_, @eax_);

      EAX := eax_;
      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        si_:=si-4;
        end
      else begin
        si_:=si+4;
        (* increment ESI *)
        end;
      end
  else
{$ifend} (* BX_CPU_LEVEL >= 3 *)
      begin (* 16 bit opsize mod_e *)

      read_virtual_word(seg, si_, @ax_);

      AX := ax_;
      if (Self.eflags.df)<>0 then begin
        (* decrement ESI *)
        si_:=si-2;
        end
      else begin
        (* increment ESI *)
        si_ :=si+ 2;
        end;
      end;

    SI := si_;
    end;
end;
