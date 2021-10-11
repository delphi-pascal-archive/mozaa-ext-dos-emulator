{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.decode_exgx32(mod_rm:Word);
var
  mod_, rm, ss:unsigned;
  sib, base, index:unsigned;
  displ32, index_reg_val, base_reg_val:Bit32u;
  displ8:Bit8u;
begin

  (* NOTES:
   * seg_reg_mod_01_base  and mod_10_base aren't correct???
   *)
  (* use 32bit addressing mod_es.  orthogonal base  and index registers,
     scaling available, etc. *)

  //BX_INSTR_mod_RM32(mod_rm);

  mod_ := mod_rm  and $c0;
  rm  := mod_rm  and $07;

  i^.nnn := (mod_rm shr 3)  and $07;

  if (mod_ = $c0) then begin (* mod_, reg, reg *)
    i^.rm_addr := rm;
    BX_CPU_THIS_PTR rm_type := BX_REGISTER_REF;
#if BX_WEIRDISMS
    i^.seg_reg := NULL;
{$ifend}
    end;
  else begin (* mod_ !:= 3 *)
    BX_CPU_THIS_PTR rm_type := BX_MEMORY_REF;
    if (rm !:= 4) then begin (* rm !:= 100b, no s-i-b byte *)
      // one byte mod_rm
      if (mod_ = $00) then begin
        if (i^.seg_reg)
          i^.seg_reg := i^.seg_reg;
        else
          i^.seg_reg :=  and BX_CPU_THIS_PTR ds;
        if (rm = 5) then begin // no reg, 32-bit displacement
          i^.rm_addr := fetch_next_dword();
          end;
        else begin
          // else reg indirect, no displacement
          i^.rm_addr := BX_READ_32BIT_REG(rm);
          end;
        exit;
        end;
      if (mod_ = $40) then begin
        if (i^.seg_reg)
          i^.seg_reg := i^.seg_reg;
        else
          i^.seg_reg := BX_CPU_THIS_PTR sreg_mod_01_rm32[rm];
        // reg, 8-bit displacement, sign extend
        displ8 := fetch_next_byte();
        i^.rm_addr := BX_READ_32BIT_REG(rm);
        i^.rm_addr +:= ((Bit8s) displ8);
        exit;
        end;
      // mod_ = $80
      if (i^.seg_reg)
        i^.seg_reg := i^.seg_reg;
      else
        i^.seg_reg := BX_CPU_THIS_PTR sreg_mod_10_rm32[rm];
      // reg, 32-bit displacement
      displ32 := fetch_next_dword();
      i^.rm_addr := BX_READ_32BIT_REG(rm);
      i^.rm_addr +:= displ32;
      exit;
      end
  else begin (* rm = 4, s-i-b byte follows *)
      sib := fetch_next_byte();
      BX_INSTR_SIB32(sib);
      base  := sib  and $07; sib shr= 3;
      index := sib  and $07; sib shr= 3;
      ss    := sib;

      if (mod_ = $00) then begin
        if (i^.seg_reg)
          i^.seg_reg := i^.seg_reg;
        else
          i^.seg_reg := BX_CPU_THIS_PTR sreg_mod_00_base32[base];
        if (base !:= 5) (* base !:= 101b, no displacement *)
          base_reg_val := BX_READ_32BIT_REG(base);
        else begin
          BX_INSTR_SIB_mod_0_base5(ss);
          base_reg_val := fetch_next_dword();
          end;
        index_reg_val := 0;
        if (index !:= 4) then begin
          index_reg_val := BX_READ_32BIT_REG(index);
          index_reg_val shl= ss;
          end;
#ifdef BX_INSTR_SIB_mod_0_IND4
        else begin
          BX_INSTR_SIB_mod_0_IND4();
          end;
{$ifend}
        i^.rm_addr := base_reg_val + index_reg_val;
        exit;
        end;
      if (mod_ = $40) then begin
        if (i^.seg_reg)
          i^.seg_reg := i^.seg_reg;
        else
          i^.seg_reg := BX_CPU_THIS_PTR sreg_mod_01_base32[base];
        displ8 := fetch_next_byte();
        base_reg_val := BX_READ_32BIT_REG(base);
        index_reg_val := 0;
        if (index !:= 4) then begin
          index_reg_val := BX_READ_32BIT_REG(index);
          index_reg_val shl= ss;
          end;
#ifdef BX_INSTR_SIB_mod_1_IND4
        else begin
          BX_INSTR_SIB_mod_1_IND4();
          end;
{$ifend}
        i^.rm_addr := base_reg_val + index_reg_val + (Bit8s) displ8;
        exit;
        end;

      // mod_ = $80
      if (i^.seg_reg)
        i^.seg_reg := i^.seg_reg;
      else
        i^.seg_reg := BX_CPU_THIS_PTR sreg_mod_10_base32[base];
      displ32 := fetch_next_dword();
      base_reg_val := BX_READ_32BIT_REG(base);
      index_reg_val := 0;
      if (index !:= 4) then begin
        index_reg_val := BX_READ_32BIT_REG(index);
        index_reg_val shl= ss;
        end;
#ifdef BX_INSTR_SIB_mod_2_IND4
      else begin
        BX_INSTR_SIB_mod_2_IND4();
        end;
{$ifend}
      i^.rm_addr := base_reg_val + index_reg_val + displ32;
      exit;
      end;
    end; (* if (mod_ !:= 3) *)
end;
