{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
Boolean BX_CPU_C.get_CF(procedure)
begin
  switch ( BX_CPU_THIS_PTR lf_flags_status  and $00000f ) then begin
    case BX_LF_INDEX_KNOWN:
      return(BX_CPU_THIS_PTR eflags.cf);

    case BX_LF_INDEX_OSZAPC:
      switch (BX_CPU_THIS_PTR oszapc.instr) then begin
        case BX_INSTR_ADD8:
        case BX_INSTR_XADD8:
          BX_CPU_THIS_PTR eflags.cf := (BX_CPU_THIS_PTR oszapc.result_8 <
                              BX_CPU_THIS_PTR oszapc.op1_8);
          break;
        case BX_INSTR_ADD16:
        case BX_INSTR_XADD16:
          BX_CPU_THIS_PTR eflags.cf := (BX_CPU_THIS_PTR oszapc.result_16 <
                              BX_CPU_THIS_PTR oszapc.op1_16);
          break;
        case BX_INSTR_ADD32:
        case BX_INSTR_XADD32:
          BX_CPU_THIS_PTR eflags.cf := (BX_CPU_THIS_PTR oszapc.result_32 <
                              BX_CPU_THIS_PTR oszapc.op1_32);
          break;
        case BX_INSTR_ADC8:
          BX_CPU_THIS_PTR eflags.cf :=
            (BX_CPU_THIS_PTR oszapc.result_8 <
             BX_CPU_THIS_PTR oszapc.op1_8) or
            (BX_CPU_THIS_PTR oszapc.prev_CF @@
             BX_CPU_THIS_PTR oszapc.result_8 =
             BX_CPU_THIS_PTR oszapc.op1_8);
          break;
        case BX_INSTR_ADC16:
          BX_CPU_THIS_PTR eflags.cf :=
            (BX_CPU_THIS_PTR oszapc.result_16 <
             BX_CPU_THIS_PTR oszapc.op1_16) or
            (BX_CPU_THIS_PTR oszapc.prev_CF @@
             BX_CPU_THIS_PTR oszapc.result_16 =
             BX_CPU_THIS_PTR oszapc.op1_16);
          break;
        case BX_INSTR_ADC32:
          BX_CPU_THIS_PTR eflags.cf :=
            (BX_CPU_THIS_PTR oszapc.result_32 <
             BX_CPU_THIS_PTR oszapc.op1_32) or
            (BX_CPU_THIS_PTR oszapc.prev_CF @@
             BX_CPU_THIS_PTR oszapc.result_32 =
             BX_CPU_THIS_PTR oszapc.op1_32);
          break;
        case BX_INSTR_SUB8:
        case BX_INSTR_CMP8:
        case BX_INSTR_CMPS8:
        case BX_INSTR_SCAS8:
          BX_CPU_THIS_PTR eflags.cf := (BX_CPU_THIS_PTR oszapc.op1_8 <
                              BX_CPU_THIS_PTR oszapc.op2_8);
          break;
        case BX_INSTR_SUB16:
        case BX_INSTR_CMP16:
        case BX_INSTR_CMPS16:
        case BX_INSTR_SCAS16:
          BX_CPU_THIS_PTR eflags.cf := (BX_CPU_THIS_PTR oszapc.op1_16 <
                              BX_CPU_THIS_PTR oszapc.op2_16);
          break;
        case BX_INSTR_SUB32:
        case BX_INSTR_CMP32:
        case BX_INSTR_CMPS32:
        case BX_INSTR_SCAS32:
          BX_CPU_THIS_PTR eflags.cf := (BX_CPU_THIS_PTR oszapc.op1_32 <
                              BX_CPU_THIS_PTR oszapc.op2_32);
          break;
        case BX_INSTR_SBB8:
          BX_CPU_THIS_PTR eflags.cf :=
            (BX_CPU_THIS_PTR oszapc.op1_8 <
             BX_CPU_THIS_PTR oszapc.result_8) or
            ((BX_CPU_THIS_PTR oszapc.op2_8=$ff) @@
             BX_CPU_THIS_PTR oszapc.prev_CF);
          break;
        case BX_INSTR_SBB16:
          BX_CPU_THIS_PTR eflags.cf :=
            (BX_CPU_THIS_PTR oszapc.op1_16 <
             BX_CPU_THIS_PTR oszapc.result_16) or
            ((BX_CPU_THIS_PTR oszapc.op2_16=$ffff) @@
             BX_CPU_THIS_PTR oszapc.prev_CF);
          break;
        case BX_INSTR_SBB32:
          BX_CPU_THIS_PTR eflags.cf :=
            (BX_CPU_THIS_PTR oszapc.op1_32 <
             BX_CPU_THIS_PTR oszapc.result_32) or
            ((BX_CPU_THIS_PTR oszapc.op2_32=$ffffffff) @@
             BX_CPU_THIS_PTR oszapc.prev_CF);
          break;
        case BX_INSTR_NEG8:
          BX_CPU_THIS_PTR eflags.cf :=
            BX_CPU_THIS_PTR oszapc.op1_8 !:= 0;
          break;
        case BX_INSTR_NEG16:
          BX_CPU_THIS_PTR eflags.cf :=
            BX_CPU_THIS_PTR oszapc.op1_16 !:= 0;
          break;
        case BX_INSTR_NEG32:
          BX_CPU_THIS_PTR eflags.cf :=
            BX_CPU_THIS_PTR oszapc.op1_32 !:= 0;
          break;
        case BX_INSTR_OR8:
        case BX_INSTR_OR16:
        case BX_INSTR_OR32:
        case BX_INSTR_AND8:
        case BX_INSTR_AND16:
        case BX_INSTR_AND32:
        case BX_INSTR_TEST8:
        case BX_INSTR_TEST16:
        case BX_INSTR_TEST32:
        case BX_INSTR_XOR8:
        case BX_INSTR_XOR16:
        case BX_INSTR_XOR32:
          BX_CPU_THIS_PTR eflags.cf := 0;
          break;
        case BX_INSTR_SHR8:
          BX_CPU_THIS_PTR eflags.cf :=
            (BX_CPU_THIS_PTR oszapc.op1_8 >>
              (BX_CPU_THIS_PTR oszapc.op2_8 - 1))  and $01;
          break;
        case BX_INSTR_SHR16:
          BX_CPU_THIS_PTR eflags.cf :=
            (BX_CPU_THIS_PTR oszapc.op1_16 >>
              (BX_CPU_THIS_PTR oszapc.op2_16 - 1))  and $01;
          break;
        case BX_INSTR_SHR32:
          BX_CPU_THIS_PTR eflags.cf :=
            (BX_CPU_THIS_PTR oszapc.op1_32 >>
              (BX_CPU_THIS_PTR oszapc.op2_32 - 1))  and $01;
          break;
        case BX_INSTR_SHL8:
          if (BX_CPU_THIS_PTR oszapc.op2_8 <= 8) then begin
            BX_CPU_THIS_PTR eflags.cf :=
              (BX_CPU_THIS_PTR oszapc.op1_8 >>
                (8 - BX_CPU_THIS_PTR oszapc.op2_8))  and $01;
            end;
          else begin
            BX_CPU_THIS_PTR eflags.cf := 0;
            end;
          break;
        case BX_INSTR_SHL16:
          if (BX_CPU_THIS_PTR oszapc.op2_16 <= 16) then begin
            BX_CPU_THIS_PTR eflags.cf :=
              (BX_CPU_THIS_PTR oszapc.op1_16 >>
                (16 - BX_CPU_THIS_PTR oszapc.op2_16))  and $01;
            end;
          else begin
            BX_CPU_THIS_PTR eflags.cf := 0;
            end;
          break;
        case BX_INSTR_SHL32:
          BX_CPU_THIS_PTR eflags.cf :=
            (BX_CPU_THIS_PTR oszapc.op1_32 >>
              (32 - BX_CPU_THIS_PTR oszapc.op2_32))  and $01;
          break;
        default:
          BX_PANIC(('get_CF: OSZAPC: unknown instr %u',
            (unsigned) BX_CPU_THIS_PTR oszapc.instr));
        end;
      BX_CPU_THIS_PTR lf_flags_status @:= $fffff0;
      return(BX_CPU_THIS_PTR eflags.cf);

    default:
      BX_PANIC(('get_CF: unknown case'));
      return(0);
    end;
end;


  Boolean
BX_CPU_C.get_AF(procedure)
begin
  switch ( (BX_CPU_THIS_PTR lf_flags_status>>8)  and $00000f ) then begin
    case BX_LF_INDEX_KNOWN:
      return(BX_CPU_THIS_PTR eflags.af);

    case BX_LF_INDEX_OSZAPC:
      switch (BX_CPU_THIS_PTR oszapc.instr) then begin
        case BX_INSTR_ADD8:
        case BX_INSTR_ADC8:
        case BX_INSTR_SUB8:
        case BX_INSTR_SBB8:
        case BX_INSTR_CMP8:
        case BX_INSTR_XADD8:
        case BX_INSTR_CMPS8:
        case BX_INSTR_SCAS8:
          BX_CPU_THIS_PTR eflags.af :=
            ((BX_CPU_THIS_PTR oszapc.op1_8 ^
              BX_CPU_THIS_PTR oszapc.op2_8) ^
             BX_CPU_THIS_PTR oszapc.result_8)  and $10;
          break;
        case BX_INSTR_ADD16:
        case BX_INSTR_ADC16:
        case BX_INSTR_SUB16:
        case BX_INSTR_SBB16:
        case BX_INSTR_CMP16:
        case BX_INSTR_XADD16:
        case BX_INSTR_CMPS16:
        case BX_INSTR_SCAS16:
          BX_CPU_THIS_PTR eflags.af :=
            ((BX_CPU_THIS_PTR oszapc.op1_16 ^
              BX_CPU_THIS_PTR oszapc.op2_16) ^
             BX_CPU_THIS_PTR oszapc.result_16)  and $10;
          break;
        case BX_INSTR_ADD32:
        case BX_INSTR_ADC32:
        case BX_INSTR_SUB32:
        case BX_INSTR_SBB32:
        case BX_INSTR_CMP32:
        case BX_INSTR_XADD32:
        case BX_INSTR_CMPS32:
        case BX_INSTR_SCAS32:
          BX_CPU_THIS_PTR eflags.af :=
            ((BX_CPU_THIS_PTR oszapc.op1_32 ^
              BX_CPU_THIS_PTR oszapc.op2_32) ^
             BX_CPU_THIS_PTR oszapc.result_32)  and $10;
          break;
        case BX_INSTR_NEG8:
          BX_CPU_THIS_PTR eflags.af :=
            (BX_CPU_THIS_PTR oszapc.op1_8  and $0f) > 0;
          break;
        case BX_INSTR_NEG16:
          BX_CPU_THIS_PTR eflags.af :=
            (BX_CPU_THIS_PTR oszapc.op1_16  and $0f) > 0;
          break;
        case BX_INSTR_NEG32:
          BX_CPU_THIS_PTR eflags.af :=
            (BX_CPU_THIS_PTR oszapc.op1_32  and $0f) > 0;
          break;
        case BX_INSTR_OR8:
        case BX_INSTR_OR16:
        case BX_INSTR_OR32:
        case BX_INSTR_AND8:
        case BX_INSTR_AND16:
        case BX_INSTR_AND32:
        case BX_INSTR_TEST8:
        case BX_INSTR_TEST16:
        case BX_INSTR_TEST32:
        case BX_INSTR_XOR8:
        case BX_INSTR_XOR16:
        case BX_INSTR_XOR32:
        case BX_INSTR_SHR8:
        case BX_INSTR_SHR16:
        case BX_INSTR_SHR32:
        case BX_INSTR_SHL8:
        case BX_INSTR_SHL16:
        case BX_INSTR_SHL32:
          BX_CPU_THIS_PTR eflags.af := 0;
          (* undefined *)
          break;
        default:
          BX_PANIC(('get_AF: OSZAPC: unknown instr %u',
            (unsigned) BX_CPU_THIS_PTR oszapc.instr));
        end;
      BX_CPU_THIS_PTR lf_flags_status @:= $fff0ff;
      return(BX_CPU_THIS_PTR eflags.af);

    case BX_LF_INDEX_OSZAP:
      switch (BX_CPU_THIS_PTR oszap.instr) then begin
        case BX_INSTR_INC8:
          BX_CPU_THIS_PTR eflags.af :=
            (BX_CPU_THIS_PTR oszap.result_8  and $0f) = 0;
          break;
        case BX_INSTR_INC16:
          BX_CPU_THIS_PTR eflags.af :=
            (BX_CPU_THIS_PTR oszap.result_16  and $0f) = 0;
          break;
        case BX_INSTR_INC32:
          BX_CPU_THIS_PTR eflags.af :=
            (BX_CPU_THIS_PTR oszap.result_32  and $0f) = 0;
          break;
        case BX_INSTR_DEC8:
          BX_CPU_THIS_PTR eflags.af :=
            (BX_CPU_THIS_PTR oszap.result_8  and $0f) = $0f;
          break;
        case BX_INSTR_DEC16:
          BX_CPU_THIS_PTR eflags.af :=
            (BX_CPU_THIS_PTR oszap.result_16  and $0f) = $0f;
          break;
        case BX_INSTR_DEC32:
          BX_CPU_THIS_PTR eflags.af :=
            (BX_CPU_THIS_PTR oszap.result_32  and $0f) = $0f;
          break;
        default:
          BX_PANIC(('get_AF: OSZAP: unknown instr %u',
            (unsigned) BX_CPU_THIS_PTR oszap.instr));
        end;
      BX_CPU_THIS_PTR lf_flags_status @:= $fff0ff;
      return(BX_CPU_THIS_PTR eflags.af);

    default:
      BX_PANIC(('get_AF: unknown case'));
      return(0);
    end;
end;


  Boolean
BX_CPU_C.get_ZF(procedure)
begin
  switch ( (BX_CPU_THIS_PTR lf_flags_status>>12)  and $00000f ) then begin
    case BX_LF_INDEX_KNOWN:
      return(BX_CPU_THIS_PTR eflags.zf);

    case BX_LF_INDEX_OSZAPC:
      switch (BX_CPU_THIS_PTR oszapc.instr) then begin
        case BX_INSTR_ADD8:
        case BX_INSTR_ADC8:
        case BX_INSTR_SUB8:
        case BX_INSTR_SBB8:
        case BX_INSTR_CMP8:
        case BX_INSTR_NEG8:
        case BX_INSTR_XADD8:
        case BX_INSTR_OR8:
        case BX_INSTR_AND8:
        case BX_INSTR_TEST8:
        case BX_INSTR_XOR8:
        case BX_INSTR_CMPS8:
        case BX_INSTR_SCAS8:
        case BX_INSTR_SHR8:
        case BX_INSTR_SHL8:
          BX_CPU_THIS_PTR eflags.zf := (BX_CPU_THIS_PTR oszapc.result_8 = 0);
          break;
        case BX_INSTR_ADD16:
        case BX_INSTR_ADC16:
        case BX_INSTR_SUB16:
        case BX_INSTR_SBB16:
        case BX_INSTR_CMP16:
        case BX_INSTR_NEG16:
        case BX_INSTR_XADD16:
        case BX_INSTR_OR16:
        case BX_INSTR_AND16:
        case BX_INSTR_TEST16:
        case BX_INSTR_XOR16:
        case BX_INSTR_CMPS16:
        case BX_INSTR_SCAS16:
        case BX_INSTR_SHR16:
        case BX_INSTR_SHL16:
          BX_CPU_THIS_PTR eflags.zf := (BX_CPU_THIS_PTR oszapc.result_16 = 0);
          break;
        case BX_INSTR_ADD32:
        case BX_INSTR_ADC32:
        case BX_INSTR_SUB32:
        case BX_INSTR_SBB32:
        case BX_INSTR_CMP32:
        case BX_INSTR_NEG32:
        case BX_INSTR_XADD32:
        case BX_INSTR_OR32:
        case BX_INSTR_AND32:
        case BX_INSTR_TEST32:
        case BX_INSTR_XOR32:
        case BX_INSTR_CMPS32:
        case BX_INSTR_SCAS32:
        case BX_INSTR_SHR32:
        case BX_INSTR_SHL32:
          BX_CPU_THIS_PTR eflags.zf := (BX_CPU_THIS_PTR oszapc.result_32 = 0);
          break;
        default:
          BX_PANIC(('get_ZF: OSZAPC: unknown instr'));
        end;
      BX_CPU_THIS_PTR lf_flags_status @:= $ff0fff;
      return(BX_CPU_THIS_PTR eflags.zf);

    case BX_LF_INDEX_OSZAP:
      switch (BX_CPU_THIS_PTR oszap.instr) then begin
        case BX_INSTR_INC8:
        case BX_INSTR_DEC8:
          BX_CPU_THIS_PTR eflags.zf := (BX_CPU_THIS_PTR oszap.result_8 = 0);
          break;
        case BX_INSTR_INC16:
        case BX_INSTR_DEC16:
          BX_CPU_THIS_PTR eflags.zf := (BX_CPU_THIS_PTR oszap.result_16 = 0);
          break;
        case BX_INSTR_INC32:
        case BX_INSTR_DEC32:
          BX_CPU_THIS_PTR eflags.zf := (BX_CPU_THIS_PTR oszap.result_32 = 0);
          break;
        default:
          BX_PANIC(('get_ZF: OSZAP: unknown instr'));
        end;
      BX_CPU_THIS_PTR lf_flags_status @:= $ff0fff;
      return(BX_CPU_THIS_PTR eflags.zf);

    default:
      BX_PANIC(('get_ZF: unknown case'));
      return(0);
    end;
end;


  Boolean
BX_CPU_C.get_SF(procedure)
begin
  switch ( (BX_CPU_THIS_PTR lf_flags_status>>16)  and $00000f ) then begin
    case BX_LF_INDEX_KNOWN:
      return(BX_CPU_THIS_PTR eflags.sf);

    case BX_LF_INDEX_OSZAPC:
      switch (BX_CPU_THIS_PTR oszapc.instr) then begin
        case BX_INSTR_ADD8:
        case BX_INSTR_ADC8:
        case BX_INSTR_SUB8:
        case BX_INSTR_SBB8:
        case BX_INSTR_CMP8:
        case BX_INSTR_NEG8:
        case BX_INSTR_XADD8:
        case BX_INSTR_OR8:
        case BX_INSTR_AND8:
        case BX_INSTR_TEST8:
        case BX_INSTR_XOR8:
        case BX_INSTR_CMPS8:
        case BX_INSTR_SCAS8:
        case BX_INSTR_SHR8:
        case BX_INSTR_SHL8:
          BX_CPU_THIS_PTR eflags.sf :=
            (BX_CPU_THIS_PTR oszapc.result_8 >= $80);
          break;
        case BX_INSTR_ADD16:
        case BX_INSTR_ADC16:
        case BX_INSTR_SUB16:
        case BX_INSTR_SBB16:
        case BX_INSTR_CMP16:
        case BX_INSTR_NEG16:
        case BX_INSTR_XADD16:
        case BX_INSTR_OR16:
        case BX_INSTR_AND16:
        case BX_INSTR_TEST16:
        case BX_INSTR_XOR16:
        case BX_INSTR_CMPS16:
        case BX_INSTR_SCAS16:
        case BX_INSTR_SHR16:
        case BX_INSTR_SHL16:
          BX_CPU_THIS_PTR eflags.sf :=
            (BX_CPU_THIS_PTR oszapc.result_16 >= $8000);
          break;
        case BX_INSTR_ADD32:
        case BX_INSTR_ADC32:
        case BX_INSTR_SUB32:
        case BX_INSTR_SBB32:
        case BX_INSTR_CMP32:
        case BX_INSTR_NEG32:
        case BX_INSTR_XADD32:
        case BX_INSTR_OR32:
        case BX_INSTR_AND32:
        case BX_INSTR_TEST32:
        case BX_INSTR_XOR32:
        case BX_INSTR_CMPS32:
        case BX_INSTR_SCAS32:
        case BX_INSTR_SHR32:
        case BX_INSTR_SHL32:
          BX_CPU_THIS_PTR eflags.sf :=
            (BX_CPU_THIS_PTR oszapc.result_32 >= $80000000);
          break;
        default:
          BX_PANIC(('get_SF: OSZAPC: unknown instr'));
        end;
      BX_CPU_THIS_PTR lf_flags_status @:= $f0ffff;
      return(BX_CPU_THIS_PTR eflags.sf);

    case BX_LF_INDEX_OSZAP:
      switch (BX_CPU_THIS_PTR oszap.instr) then begin
        case BX_INSTR_INC8:
        case BX_INSTR_DEC8:
          BX_CPU_THIS_PTR eflags.sf :=
            (BX_CPU_THIS_PTR oszap.result_8 >= $80);
          break;
        case BX_INSTR_INC16:
        case BX_INSTR_DEC16:
          BX_CPU_THIS_PTR eflags.sf :=
            (BX_CPU_THIS_PTR oszap.result_16 >= $8000);
          break;
        case BX_INSTR_INC32:
        case BX_INSTR_DEC32:
          BX_CPU_THIS_PTR eflags.sf :=
            (BX_CPU_THIS_PTR oszap.result_32 >= $80000000);
          break;
        default:
          BX_PANIC(('get_SF: OSZAP: unknown instr'));
        end;
      BX_CPU_THIS_PTR lf_flags_status @:= $f0ffff;
      return(BX_CPU_THIS_PTR eflags.sf);

    default:
      BX_PANIC(('get_SF: unknown case'));
      return(0);
    end;
end;

  Boolean
BX_CPU_C.get_OF(procedure)
begin
  Bit8u op1_b7, op2_b7, result_b7;
  Bit16u op1_b15, op2_b15, result_b15;
  Bit32u op1_b31, op2_b31, result_b31;

  switch ( (BX_CPU_THIS_PTR lf_flags_status>>20)  and $00000f ) then begin
    case BX_LF_INDEX_KNOWN:
      return(BX_CPU_THIS_PTR eflags.of);

    case BX_LF_INDEX_OSZAPC:
      switch (BX_CPU_THIS_PTR oszapc.instr) then begin
        case BX_INSTR_ADD8:
        case BX_INSTR_ADC8:
        case BX_INSTR_XADD8:
          op1_b7 := BX_CPU_THIS_PTR oszapc.op1_8  and $80;
          op2_b7 := BX_CPU_THIS_PTR oszapc.op2_8  and $80;
          result_b7 := BX_CPU_THIS_PTR oszapc.result_8  and $80;

          BX_CPU_THIS_PTR eflags.of :=  (op1_b7 = op2_b7) @ and (result_b7 or op2_b7);
          break;
        case BX_INSTR_ADD16:
        case BX_INSTR_ADC16:
        case BX_INSTR_XADD16:
          op1_b15 := BX_CPU_THIS_PTR oszapc.op1_16  and $8000;
          op2_b15 := BX_CPU_THIS_PTR oszapc.op2_16  and $8000;
          result_b15 := BX_CPU_THIS_PTR oszapc.result_16  and $8000;

          BX_CPU_THIS_PTR eflags.of :=  (op1_b15 = op2_b15) @ and (result_b15 or op2_b15);
          break;
        case BX_INSTR_ADD32:
        case BX_INSTR_ADC32:
        case BX_INSTR_XADD32:
          op1_b31 := BX_CPU_THIS_PTR oszapc.op1_32  and $80000000;
          op2_b31 := BX_CPU_THIS_PTR oszapc.op2_32  and $80000000;
          result_b31 := BX_CPU_THIS_PTR oszapc.result_32  and $80000000;

          BX_CPU_THIS_PTR eflags.of :=  (op1_b31 = op2_b31) @ and (result_b31 or op2_b31);
          break;
        case BX_INSTR_SUB8:
        case BX_INSTR_SBB8:
        case BX_INSTR_CMP8:
        case BX_INSTR_CMPS8:
        case BX_INSTR_SCAS8:
          op1_b7 := BX_CPU_THIS_PTR oszapc.op1_8  and $80;
          op2_b7 := BX_CPU_THIS_PTR oszapc.op2_8  and $80;
          result_b7 := BX_CPU_THIS_PTR oszapc.result_8  and $80;

          BX_CPU_THIS_PTR eflags.of :=  (op1_b7 or op2_b7) @ and (op1_b7 or result_b7);
          break;
        case BX_INSTR_SUB16:
        case BX_INSTR_SBB16:
        case BX_INSTR_CMP16:
        case BX_INSTR_CMPS16:
        case BX_INSTR_SCAS16:
          op1_b15 := BX_CPU_THIS_PTR oszapc.op1_16  and $8000;
          op2_b15 := BX_CPU_THIS_PTR oszapc.op2_16  and $8000;
          result_b15 := BX_CPU_THIS_PTR oszapc.result_16  and $8000;

          BX_CPU_THIS_PTR eflags.of :=  (op1_b15 or op2_b15) @ and (op1_b15 or result_b15);
          break;
        case BX_INSTR_SUB32:
        case BX_INSTR_SBB32:
        case BX_INSTR_CMP32:
        case BX_INSTR_CMPS32:
        case BX_INSTR_SCAS32:
          op1_b31 := BX_CPU_THIS_PTR oszapc.op1_32  and $80000000;
          op2_b31 := BX_CPU_THIS_PTR oszapc.op2_32  and $80000000;
          result_b31 := BX_CPU_THIS_PTR oszapc.result_32  and $80000000;

          BX_CPU_THIS_PTR eflags.of :=  (op1_b31 or op2_b31) @ and (op1_b31 or result_b31);
          break;
        case BX_INSTR_NEG8:
          BX_CPU_THIS_PTR eflags.of :=
            (BX_CPU_THIS_PTR oszapc.op1_8 = $80);
          break;
        case BX_INSTR_NEG16:
          BX_CPU_THIS_PTR eflags.of :=
            (BX_CPU_THIS_PTR oszapc.op1_16 = $8000);
          break;
        case BX_INSTR_NEG32:
          BX_CPU_THIS_PTR eflags.of :=
            (BX_CPU_THIS_PTR oszapc.op1_32 = $80000000);
          break;
        case BX_INSTR_OR8:
        case BX_INSTR_OR16:
        case BX_INSTR_OR32:
        case BX_INSTR_AND8:
        case BX_INSTR_AND16:
        case BX_INSTR_AND32:
        case BX_INSTR_TEST8:
        case BX_INSTR_TEST16:
        case BX_INSTR_TEST32:
        case BX_INSTR_XOR8:
        case BX_INSTR_XOR16:
        case BX_INSTR_XOR32:
          BX_CPU_THIS_PTR eflags.of := 0;
          break;
        case BX_INSTR_SHR8:
          if (BX_CPU_THIS_PTR oszapc.op2_8 = 1)
            BX_CPU_THIS_PTR eflags.of :=
              (BX_CPU_THIS_PTR oszapc.op1_8 >= $80);
          break;
        case BX_INSTR_SHR16:
          if (BX_CPU_THIS_PTR oszapc.op2_16 = 1)
            BX_CPU_THIS_PTR eflags.of :=
              (BX_CPU_THIS_PTR oszapc.op1_16 >= $8000);
          break;
        case BX_INSTR_SHR32:
          if (BX_CPU_THIS_PTR oszapc.op2_32 = 1)
            BX_CPU_THIS_PTR eflags.of :=
              (BX_CPU_THIS_PTR oszapc.op1_32 >= $80000000);
          break;
        case BX_INSTR_SHL8:
          if (BX_CPU_THIS_PTR oszapc.op2_8 = 1)
            BX_CPU_THIS_PTR eflags.of :=
              ((BX_CPU_THIS_PTR oszapc.op1_8 ^
                BX_CPU_THIS_PTR oszapc.result_8)  and $80) > 0;
          break;
        case BX_INSTR_SHL16:
          if (BX_CPU_THIS_PTR oszapc.op2_16 = 1)
            BX_CPU_THIS_PTR eflags.of :=
              ((BX_CPU_THIS_PTR oszapc.op1_16 ^
                BX_CPU_THIS_PTR oszapc.result_16)  and $8000) > 0;
          break;
        case BX_INSTR_SHL32:
          if (BX_CPU_THIS_PTR oszapc.op2_32 = 1)
            BX_CPU_THIS_PTR eflags.of :=
              ((BX_CPU_THIS_PTR oszapc.op1_32 ^
                BX_CPU_THIS_PTR oszapc.result_32)  and $80000000) > 0;
          break;
        default:
          BX_PANIC(('get_OF: OSZAPC: unknown instr'));
        end;
      BX_CPU_THIS_PTR lf_flags_status @:= $0fffff;
      return(BX_CPU_THIS_PTR eflags.of);

    case BX_LF_INDEX_OSZAP:
      switch (BX_CPU_THIS_PTR oszap.instr) then begin
        case BX_INSTR_INC8:
          BX_CPU_THIS_PTR eflags.of :=
            BX_CPU_THIS_PTR oszap.result_8 = $80;
          break;
        case BX_INSTR_INC16:
          BX_CPU_THIS_PTR eflags.of :=
            BX_CPU_THIS_PTR oszap.result_16 = $8000;
          break;
        case BX_INSTR_INC32:
          BX_CPU_THIS_PTR eflags.of :=
            BX_CPU_THIS_PTR oszap.result_32 = $80000000;
          break;
        case BX_INSTR_DEC8:
          BX_CPU_THIS_PTR eflags.of :=
            BX_CPU_THIS_PTR oszap.result_8 = $7F;
          break;
        case BX_INSTR_DEC16:
          BX_CPU_THIS_PTR eflags.of :=
            BX_CPU_THIS_PTR oszap.result_16 = $7FFF;
          break;
        case BX_INSTR_DEC32:
          BX_CPU_THIS_PTR eflags.of :=
            BX_CPU_THIS_PTR oszap.result_32 = $7FFFFFFF;
          break;
        default:
          BX_PANIC(('get_OF: OSZAP: unknown instr'));
        end;
      BX_CPU_THIS_PTR lf_flags_status @:= $0fffff;
      return(BX_CPU_THIS_PTR eflags.of);

    default:
      BX_PANIC(('get_OF: unknown case'));
      return(0);
    end;
end;

  Boolean
BX_CPU_C.get_PF(procedure)
begin
  switch ( (BX_CPU_THIS_PTR lf_flags_status>>4)  and $00000f ) then begin
    case BX_LF_INDEX_KNOWN:
      return(BX_CPU_THIS_PTR lf_pf);
    case BX_LF_INDEX_OSZAPC:
      switch (BX_CPU_THIS_PTR oszapc.instr) then begin
        case BX_INSTR_ADD8:
        case BX_INSTR_ADC8:
        case BX_INSTR_SUB8:
        case BX_INSTR_SBB8:
        case BX_INSTR_CMP8:
        case BX_INSTR_NEG8:
        case BX_INSTR_XADD8:
        case BX_INSTR_OR8:
        case BX_INSTR_AND8:
        case BX_INSTR_TEST8:
        case BX_INSTR_XOR8:
        case BX_INSTR_CMPS8:
        case BX_INSTR_SCAS8:
        case BX_INSTR_SHR8:
        case BX_INSTR_SHL8:
          BX_CPU_THIS_PTR lf_pf :=
            bx_parity_lookup[BX_CPU_THIS_PTR oszapc.result_8];
          break;
        case BX_INSTR_ADD16:
        case BX_INSTR_ADC16:
        case BX_INSTR_SUB16:
        case BX_INSTR_SBB16:
        case BX_INSTR_CMP16:
        case BX_INSTR_NEG16:
        case BX_INSTR_XADD16:
        case BX_INSTR_OR16:
        case BX_INSTR_AND16:
        case BX_INSTR_TEST16:
        case BX_INSTR_XOR16:
        case BX_INSTR_CMPS16:
        case BX_INSTR_SCAS16:
        case BX_INSTR_SHR16:
        case BX_INSTR_SHL16:
          BX_CPU_THIS_PTR lf_pf :=
            bx_parity_lookup[(Bit8u) BX_CPU_THIS_PTR oszapc.result_16];
          break;
        case BX_INSTR_ADD32:
        case BX_INSTR_ADC32:
        case BX_INSTR_SUB32:
        case BX_INSTR_SBB32:
        case BX_INSTR_CMP32:
        case BX_INSTR_NEG32:
        case BX_INSTR_XADD32:
        case BX_INSTR_OR32:
        case BX_INSTR_AND32:
        case BX_INSTR_TEST32:
        case BX_INSTR_XOR32:
        case BX_INSTR_CMPS32:
        case BX_INSTR_SCAS32:
        case BX_INSTR_SHR32:
        case BX_INSTR_SHL32:
          BX_CPU_THIS_PTR lf_pf :=
            bx_parity_lookup[(Bit8u) BX_CPU_THIS_PTR oszapc.result_32];
          break;
        default:
          BX_PANIC(('get_PF: OSZAPC: unknown instr'));
        end;
      BX_CPU_THIS_PTR lf_flags_status @:= $ffff0f;
      return(BX_CPU_THIS_PTR lf_pf);

    case BX_LF_INDEX_OSZAP:
      switch (BX_CPU_THIS_PTR oszap.instr) then begin
        case BX_INSTR_INC8:
        case BX_INSTR_DEC8:
          BX_CPU_THIS_PTR lf_pf :=
            bx_parity_lookup[BX_CPU_THIS_PTR oszap.result_8];
          break;
        case BX_INSTR_INC16:
        case BX_INSTR_DEC16:
          BX_CPU_THIS_PTR lf_pf :=
            bx_parity_lookup[(Bit8u) BX_CPU_THIS_PTR oszap.result_16];
          break;
        case BX_INSTR_INC32:
        case BX_INSTR_DEC32:
          BX_CPU_THIS_PTR lf_pf :=
            bx_parity_lookup[(Bit8u) BX_CPU_THIS_PTR oszap.result_32];
          break;
        default:
          BX_PANIC(('get_PF: OSZAP: unknown instr'));
        end;
      BX_CPU_THIS_PTR lf_flags_status @:= $ffff0f;
      return(BX_CPU_THIS_PTR lf_pf);

    case BX_LF_INDEX_P:
      BX_CPU_THIS_PTR lf_pf := bx_parity_lookup[BX_CPU_THIS_PTR eflags.pf_byte];
      BX_CPU_THIS_PTR lf_flags_status @:= $ffff0f;
      return(BX_CPU_THIS_PTR lf_pf);

    default:
      BX_PANIC(('get_PF: unknown case'));
      return(0);
    end;
end;

