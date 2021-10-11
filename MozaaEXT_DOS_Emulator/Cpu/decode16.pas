{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

(*Bit16u *aaa[8] := begin
   @BX,
   @BX,
   @BP,
   @BP,
   @SI,
   @DI,
   @BP,
   @BX,
  end;;*)

{static Bit16u *bbb[8] := begin
   and SI,
   and DI,
   and SI,
   and DI,
  (Bit16u *)  and BX_CPU_THIS_PTR empty_register,
  (Bit16u *)  and BX_CPU_THIS_PTR empty_register,
  (Bit16u *)  and BX_CPU_THIS_PTR empty_register,
  (Bit16u *)  and BX_CPU_THIS_PTR empty_register
  end;;}

const
  BX_WEIRDISMS = $00;
procedure BX_CPU_C.decode_exgx16(need_fetch:Word);
var
  displ8:Bit8u;
  displ16:Bit16u;
  mod_, rm:Word;
begin


{$if BX_WEIRDISMS = 01}
    i^.seg_reg := NULL;
{$ifend}

  //or 76or543or210
  //ormod_ortttor rm

  //BX_INSTR_mod_RM16(mod_rm); !!!
  i^.nnn := (mod_rm shr 3) and $07;
  mod_ := mod_rm  and $c0;
  rm := mod_rm  and $07;

  if (mod_ = $c0) then begin
    i^.rm_addr := rm;
    BX_CPU_THIS_PTR rm_type := BX_REGISTER_REF;
    exit;
    end;
  else begin // mod_ !:= 3
    BX_CPU_THIS_PTR rm_type := BX_MEMORY_REF;

    if (mod_ = $40) then begin
      displ8 := fetch_next_byte();
      i^.rm_addr := (Bit16u) (*aaa[rm] + *bbb[rm] + (Bit8s) displ8);
      if (i^.seg_reg = NULL)
        i^.seg_reg := BX_CPU_THIS_PTR sreg_mod_01_rm16[rm];
      else
        i^.seg_reg := i^.seg_reg;
      exit;
      end;
    if (mod_ = $80) then begin
      displ16 := fetch_next_word();
      i^.rm_addr := (Bit16u) (*aaa[rm] + *bbb[rm] + (Bit16s) displ16);
      if (i^.seg_reg = NULL)
        i^.seg_reg := BX_CPU_THIS_PTR sreg_mod_10_rm16[rm];
      else
        i^.seg_reg := i^.seg_reg;
      exit;
      end;

    // mod_ = $00
    if (rm=6)
      i^.rm_addr := fetch_next_word();
    else
      i^.rm_addr := (Bit16u) (*aaa[rm] + *bbb[rm]);

    if (i^.seg_reg = NULL)
      i^.seg_reg := BX_CPU_THIS_PTR sreg_mod_00_rm16[rm];
    else
      i^.seg_reg := i^.seg_reg;
    exit;
    end;
end;
