{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.BxError(I:PBxInstruction_tag);
begin
  // extern void dump_core();
  BX_INFO(Format('BxError: instruction with op1=0x%x',[i^.b1]));
  BX_INFO(Format('nnn was %u',[i^.nnn]));

  BX_INFO(('WARNING: Encountered an unknown instruction (signalling illegal instruction):'));
  // dump_core();

  Self.UndefinedOpcode(i);
end;

function BX_CPU_C.FetchDecode(iptr:PBit8u; out instruction:BxInstruction_tag; out remain:Word;const is_32:Bool):Word;
var
  b1, b2, ilen, attr:unsigned;
  imm_mod_e, offset:unsigned;
  rm:unsigned;
  imm32u:Bit32u;
  sib, base:unsigned;
  displ16u:Bit16u;
  OpcodeInfoPtr:PBxOpcodeInfo_t;
  saveBxInfo:PBxOpcodeInfo_t;
  temp8s:Bit8s;
  imm16u:Bit16u;
  label fetch_b1, another_byte, modrm_done, get_8bit_displ, get_32bit_displ, end_proc;
begin
  // remain must be at least 1
  ilen:=1;
  instruction.as_32 := is_32;
  instruction.os_32 := instruction.as_32;
  instruction.Resolvemodrm := NULL;
  instruction.seg := BX_SEG_REG_NULL;
  instruction.rep_used := 0;


fetch_b1:
  b1 := iptr^;
  inc(iptr);

another_byte:
  offset := instruction.os_32 shl 9; // * 512
  attr := BxOpcodeInfo[b1+offset].Attr;
   instruction.attr := attr;

  if (attr and BxAnother)<>0 then begin
    if (attr  and BxPrefix)<>0 then begin
      case b1 of
        $66: // OpSize
          begin
          instruction.os_32 := Word(is_32=0);
          if (ilen < remain) then begin
            inc(ilen);
            goto fetch_b1;
            end;
          Result:=0;
          exit;
          end;

        $67: // AddrSize
          begin
          instruction.as_32 := Word(is_32=0);
          if (ilen < remain) then begin
            inc(ilen);
            goto fetch_b1;
            end;
          Result:=0;
          exit;
          end;

        $f2,$f3: // REPNE/REPNZ
          begin
          instruction.rep_used := b1;
          if (ilen < remain) then begin
            Inc(ilen);
            goto fetch_b1;
            end;
          Result:=0;
          exit;
          end;

        $2e: // CS:
          begin
          instruction.seg := BX_SEG_REG_CS;
          inc(ilen); goto fetch_b1;
          end;
        $26: // ES:
          begin
          instruction.seg := BX_SEG_REG_ES;
          inc(ilen); goto fetch_b1;
          end;
        $36: // SS:
          begin
          instruction.seg := BX_SEG_REG_SS;
          inc(ilen); goto fetch_b1;
          end;
        $3e: // DS:
          begin
          instruction.seg := BX_SEG_REG_DS;
          inc(ilen); goto fetch_b1;
          end;
        $64: // FS:
          begin
          instruction.seg := BX_SEG_REG_FS;
          inc(ilen); goto fetch_b1;
          end;
        $65: // GS:
          begin
          instruction.seg := BX_SEG_REG_GS;
          inc(ilen); goto fetch_b1;
          end;
        $f0: // LOCK:
          begin
          inc(ilen); goto fetch_b1;
          end;

        else
          BX_PANIC(Format('fetch_decode: prefix default := $%02x',[b1]));
        end;
      end;
    // opcode requires another byte
    if (ilen < remain) then begin
      inc(ilen);
      b2 := iptr^;
      inc(iptr);
      if (b1 = $0f) then begin
        // 2-byte prefix
        b1 := $100 or b2;
        goto another_byte;
        end;
      end
  else
      begin
        result:=0;
        exit;
      end;

    // Parse mod_-nnn-rm and related bytes
    instruction.modrm := b2;
    instruction.rm := b2 and $07;
    rm := instruction.rm;
    instruction.mod_   := b2  and $c0; // leave unshifted
    instruction.nnn   := (b2 shr 3)  and $07;
    if (instruction.mod_ = $c0) then begin // mod_ = 11b
      goto modrm_done;
      end;
    if (instruction.as_32)<>0 then begin
      // 32-bit addressing mod_es; note that mod_=11b handled above
      if (rm <> 4) then begin // no s-i-b byte
{$if BX_DYNAMIC_TRANSLATION = 1}
        instruction.DTMemRegsUsed := 1 shl rm; // except for mod_:=00b rm:=100b
{$ifend}
        if (instruction.mod_ = $00) then begin // mod_ = 00b
          instruction.Resolvemodrm := BxResolve32mod0[rm];
{$if BX_DYNAMIC_TRANSLATION = 1}
          instruction.DTResolvemod_rm := (BxprocedureFPtr_t) BxDTResolve32mod_0[rm];
{$ifend}
          if (instruction.seg and BX_SEG_REG_NULL)<>0 then
            instruction.seg := BX_SEG_REG_DS;
          if (rm = 5) then begin
            if ((ilen+3) < remain) then begin
              imm32u := iptr^;
              inc(iptr);
              imm32u := imm32u or (iptr^ shl 8);
              inc(iptr);
              imm32u := imm32u or (iptr^ shl 16);
              inc(iptr);
              imm32u := imm32u or (iptr^ shl 24);
              inc(iptr);
              instruction.rm_addr := imm32u;
              //inc(iptr);
              Inc(ilen,4);
{$if BX_DYNAMIC_TRANSLATION = 1}
              instruction.DTMemRegsUsed := 0;
{$ifend}
              goto modrm_done;
              end
            else begin
              Result:=0;
              exit;
              end;
            end;
          // mod_=00b, rm!:=4, rm!:=5
          goto modrm_done;
          end;
        if (instruction.mod_ = $40) then begin // mod_ = 01b
          instruction.Resolvemodrm := BxResolve32mod1or2[rm];
{$if BX_DYNAMIC_TRANSLATION = 1}
          instruction.DTResolvemod_rm := (BxprocedureFPtr_t) BxDTResolve32mod_1or2[rm];
{$ifend}
          if (instruction.seg and BX_SEG_REG_NULL)<>0 then
            instruction.seg := Self.sreg_mod01_rm32[rm];
get_8bit_displ:
          if (ilen < remain) then begin
            // 8 sign extended to 32
            instruction.displ32u := Bit8s(iptr^);
            inc(iptr);
            inc(ilen);
            goto modrm_done;
            end
          else begin
            result:=0;
            exit;
            end;
          end;
        // (mod_ = $80) mod_ = 10b
        instruction.Resolvemodrm := BxResolve32mod1or2[rm];
{$if BX_DYNAMIC_TRANSLATION = 1}
        instruction.DTResolvemod_rm := (BxprocedureFPtr_t) BxDTResolve32mod_1or2[rm];
{$ifend}
        if (instruction.seg and BX_SEG_REG_NULL)<>0 then
          instruction.seg := Self.sreg_mod10_rm32[rm];
get_32bit_displ:
        if ((ilen+3) < remain) then begin
          imm32u := iptr^;
          inc(iptr);
          imm32u := imm32u or (iptr^ shl 8);
          inc(iptr);
          imm32u := imm32u or (iptr^ shl 16);
          inc(iptr);
          imm32u := imm32u or (iptr^ shl 24);
          inc(iptr);
          instruction.displ32u := imm32u;
          inc(ilen,4);
          goto modrm_done;
          end
        else begin
            result:=0;
            exit;
          end;
        end
      else begin // mod_!:=11b, rm=4, s-i-b byte follows
        if (ilen < remain) then begin
          sib := iptr^;
          inc(iptr);
          inc(ilen);
          end
        else begin
            result:=0;
            exit;
          end;
        instruction.sib   := sib;
        instruction.base  := sib and $07; sib := sib shr 3;
        base := instruction.base;
        instruction.index := sib  and $07; sib := sib shr 3;
        instruction.scale := sib;
{$if BX_DYNAMIC_TRANSLATION=1}
        if (instruction.index = $04) // 100b
          instruction.DTMemRegsUsed := 0;
        else
          instruction.DTMemRegsUsed := 1shlinstruction.index;
{$ifend}
        if (instruction.mod_ = $00) then begin // mod_=00b, rm=4
          instruction.Resolvemodrm := BxResolve32mod0Base[base];
{$if BX_DYNAMIC_TRANSLATION=1}
          instruction.DTResolvemod_rm := (BxprocedureFPtr_t) BxDTResolve32mod_0Base[base];
{$ifend}
          if (instruction.seg and BX_SEG_REG_NULL)<>0 then
            instruction.seg := Self.sreg_mod0_base32[base];
          if (instruction.base = $05) then begin
            goto get_32bit_displ;
            end;
          // mod_=00b, rm=4, base!:=5
{$if BX_DYNAMIC_TRANSLATION=1}
          instruction.DTMemRegsUsed |:= 1shlbase;
{$ifend}
          goto modrm_done;
          end;
{$if BX_DYNAMIC_TRANSLATION=1}
        // for remaining 32bit cases
        instruction.DTMemRegsUsed := instruction.DTMemRegsUsed or (1 shl base);
{$ifend}
        if (instruction.mod_ = $40) then begin // mod_=01b, rm=4
          instruction.Resolvemodrm := BxResolve32mod1or2Base[base];
{$if BX_DYNAMIC_TRANSLATION=1}
          instruction.DTResolvemod_rm := (BxprocedureFPtr_t) BxDTResolve32mod_1or2Base[base];
{$ifend}
          if (instruction.seg and BX_SEG_REG_NULL)<>0 then
            instruction.seg := Self.sreg_mod1or2_base32[base];
          goto get_8bit_displ;
          end;
        // (instruction.mod_ = $80),  mod_=10b, rm=4
        instruction.Resolvemodrm := BxResolve32mod1or2Base[base];
{$if BX_DYNAMIC_TRANSLATION=1}
        instruction.DTResolvemod_rm := (BxprocedureFPtr_t) BxDTResolve32mod_1or2Base[base];
{$ifend}
        if (instruction.seg and BX_SEG_REG_NULL)<>0 then
          instruction.seg := Self.sreg_mod1or2_base32[base];
        goto get_32bit_displ;
        end;
      end
  else begin
      // 16-bit addressing mod_es, mod_=11b handled above
      if (instruction.mod_ = $40) then begin // mod_ = 01b
        instruction.Resolvemodrm := BxResolve16mod1or2[rm];
{$if BX_DYNAMIC_TRANSLATION=1}
        instruction.DTResolvemod_rm := (BxprocedureFPtr_t) BxDTResolve16mod_1or2[rm];
{$ifend}
        if (instruction.seg and BX_SEG_REG_NULL)<>0 then
          instruction.seg := Self.sreg_mod01_rm16[rm];
{$if BX_DYNAMIC_TRANSLATION=1}
        instruction.DTMemRegsUsed := BxMemRegsUsed16[rm];
{$ifend}
        if (ilen < remain) then begin
          // 8 sign extended to 16
          instruction.displ16u := Bit8s(iptr^);
          inc(iptr);
          inc(ilen);
          goto modrm_done;
          end
        else begin
          result:=0;
          exit;
          end;
        end;
      if (instruction.mod_ = $80) then begin // mod_ = 10b
        instruction.Resolvemodrm := BxResolve16mod1or2[rm];
{$if BX_DYNAMIC_TRANSLATION=1}
        instruction.DTResolvemod_rm := (BxprocedureFPtr_t) BxDTResolve16mod_1or2[rm];
{$ifend}
        if (instruction.seg and BX_SEG_REG_NULL)<>0 then
          instruction.seg := Self.sreg_mod10_rm16[rm];
{$if BX_DYNAMIC_TRANSLATION=1}
        instruction.DTMemRegsUsed := BxMemRegsUsed16[rm];
{$ifend}
        if ((ilen+1) < remain) then begin
          displ16u := iptr^;
          inc(iptr);
          displ16u := displ16u or (iptr^ shl 8);
          inc(iptr);
          instruction.displ16u := displ16u;
          inc(ilen,2);
          goto modrm_done;
          end
        else begin
          result:=0;
          exit;
          end;
        end;
      // mod_ must be 00b at this point
      instruction.Resolvemodrm := BxResolve16mod0[rm];
{$if BX_DYNAMIC_TRANSLATION=1}
      instruction.DTResolvemod_rm := (BxprocedureFPtr_t) BxDTResolve16mod_0[rm];
{$ifend}
      if (instruction.seg and BX_SEG_REG_NULL)<>0 then
        instruction.seg := Self.sreg_mod00_rm16[rm];
      if (rm = $06) then begin
        if ((ilen+1) < remain) then begin
          displ16u := iptr^;
          inc(iptr);
          displ16u := displ16u or (iptr^ shl 8);
          inc(iptr);
          instruction.rm_addr := displ16u;
          inc(ilen,2);
          goto modrm_done;
          end
        else begin
          result:=0;
          exit;
          end;
        end;
      // mod_:=00b rm!:=6
{$if BX_DYNAMIC_TRANSLATION=1}
      instruction.DTMemRegsUsed := BxMemRegsUsed16[rm];
{$ifend}
      end;

modrm_done:
    if (attr and BxGroupN) <> 0 then begin

      OpcodeInfoPtr := BxOpcodeInfo[b1+offset].AnotherArray;
      instruction.execute := PBxOpcodeInfo_t(Integer(OpcodeInfoPtr) + (instruction.nnn * sizeof(BxOpcodeInfo_t)))^.ExecutePtr;
      StrCopy(instruction.name,PBxOpcodeInfo_t(Integer(OpcodeInfoPtr) + (instruction.nnn * sizeof(BxOpcodeInfo_t)))^.Name);
      // get additional attributes from group table
      attr := attr or PBxOpcodeInfo_t(Integer(OpcodeInfoPtr) + (instruction.nnn * sizeof(BxOpcodeInfo_t)))^.Attr;
      instruction.attr := attr;
{$if BX_DYNAMIC_TRANSLATION=1}
      instruction.DTAttr := 0; // for now
{$ifend}
      end
  else begin
      instruction.execute := BxOpcodeInfo[b1+offset].ExecutePtr;
      StrCopy(instruction.name,BxOpcodeInfo[b1+offset].Name);
{$if BX_DYNAMIC_TRANSLATION=1}
      instruction.DTAttr := BxDTOpcodeInfo[b1+offset].DTAttr;
      instruction.DTFPtr := BxDTOpcodeInfo[b1+offset].DTASFPtr;
{$ifend}
      end;
    end
  else begin
    // Opcode does not require a mod_RM byte.
    // Note that a 2-byte opcode (0F XX) will jump to before
    // the if() above after fetching the 2nd byte, so this path is
    // taken in all cases if a mod_rm byte is NOT required.
    instruction.execute := BxOpcodeInfo[b1+offset].ExecutePtr;
{$if BX_DYNAMIC_TRANSLATION=1}
    instruction.DTAttr := BxDTOpcodeInfo[b1+offset].DTAttr;
    instruction.DTFPtr := BxDTOpcodeInfo[b1+offset].DTASFPtr;
{$ifend}
    end;


  imm_mod_e := attr  and BxImmediate;

  if (imm_mod_e)<>0 then begin
    case imm_mod_e of
      BxImmediate_Ib:
        begin
        if (ilen < remain) then begin
          instruction.Ib := iptr^;
          inc(ilen);
          end
        else begin
          Result:=0; exit;
          end;
        end;
      BxImmediate_Ib_SE: // Sign extend to OS size
        begin
        if (ilen < remain) then begin
          temp8s := iptr^;
          if (instruction.os_32)<>0 then
            instruction.Id := Bit32s(temp8s)
          else
            instruction.Iw := Bit16s(temp8s);
          inc(ilen);
          end
        else begin
          Result:=0; exit;
          end;
        end;
      BxImmediate_Iv, // same as BxImmediate_BrOff32
      BxImmediate_IvIw: // CALL_Ap
        begin
        if (instruction.os_32)<>0 then begin
          if ((ilen+3) < remain) then begin
            imm32u := iptr^;
            inc(iptr);
            imm32u := imm32u or (iptr^ shl 8);
            inc(iptr);
            imm32u := imm32u or (iptr^ shl 16);
            inc(iptr);
            imm32u := imm32u or (iptr^ shl 24);
            instruction.Id := imm32u;
            Inc(ilen,4);
            end
          else begin
            Result:=0; exit;
            end;
          end
        else begin
          if ((ilen+1) < remain) then begin
            imm16u := iptr^;
            inc(iptr);
            imm16u := imm16u or (iptr^ shl 8);
            instruction.Iw := imm16u;
            inc(ilen,2);
            end
          else begin
            Result:=0; exit;
            end;
          end;
        if (imm_mod_e <> BxImmediate_IvIw) then goto end_proc;
          //break;
        inc(iptr);
        // Get Iw for BxImmediate_IvIw
        if ((ilen+1) < remain) then begin
          imm16u := iptr^;
          inc(iptr);
          imm16u := imm16u or (iptr^ shl 8);
          instruction.Iw2 := imm16u;
          inc(ilen,2);
          end
        else begin
          Result:=0; exit;
          end;
        end;
      BxImmediate_O:
        begin
        if (instruction.as_32)<>0 then begin
          // fetch 32bit address into Id
          if ((ilen+3) < remain) then begin
            imm32u := iptr^;
            inc(iptr);
            imm32u := imm32u or (iptr^ shl 8);
            inc(iptr);
            imm32u := imm32u or (iptr^ shl 16);
            inc(iptr);
            imm32u := imm32u or (iptr^ shl 24);
            instruction.Id := imm32u;
            inc(ilen,4);
            end
          else begin
            Result:=0; exit;
            end;
          end
        else begin
          // fetch 16bit address into Id
          if ((ilen+1) < remain) then begin
            imm32u := iptr^;
            inc(iptr);
            imm32u := imm32u or (iptr^ shl 8);
            instruction.Id := imm32u;
            inc(ilen,2);
            end
          else begin
            Result:=0; exit;
            end;
          end;
        end;
      BxImmediate_Iw,
      BxImmediate_IwIb:
        begin
        if ((ilen+1) < remain) then begin
          imm16u := iptr^;
          inc(iptr);
          imm16u := imm16u or (iptr^ shl 8);
          instruction.Iw := imm16u;
          inc(ilen,2);
          end
        else begin
          result:=0;
          exit;
          end;
        if (imm_mod_e = BxImmediate_Iw) then goto end_proc;
        inc(iptr);
        if (ilen < remain) then begin
          instruction.Ib2 := iptr^;
          inc(iptr);
          inc(ilen);
          end
        else begin
          Result:=0; exit;
          end;
        end;
      BxImmediate_BrOff8:
        begin
        if (ilen < remain) then begin
          temp8s := iptr^;
          instruction.Id := temp8s;
          inc(ilen);
          end
        else begin
          Result:=0; exit;
          end;
        end;
      BxImmediate_BrOff16:
        begin
        if ((ilen+1) < remain) then begin
          imm16u := iptr^;
          inc(iptr);
          imm16u := imm16u or (iptr^ shl 8);
          {$R-}
          instruction.Id := Bit16s(imm16u);
          inc(ilen,2);
          end
        else begin
          Result:=0; exit;
          end;
        end;
      else
        begin
        BX_INFO(Format('b1 was %x',[b1]));
          BX_PANIC(Format('fetchdecode: imm_mod_e := %u',[imm_mod_e]));
        end;
      end;
    end;

end_proc:
  instruction.b1 := b1;
  instruction.ilen := ilen;
  //instruction.flags_in  := 0; // for now
  //instruction.flags_out := 0; // for now
  Result:=1;
end;

procedure BX_CPU_C.BxResolveError(I:PBxInstruction_tag);
begin
  BX_PANIC(Format('BxResolveError: instruction with op1:=$%x',[i^.b1]));
end;

