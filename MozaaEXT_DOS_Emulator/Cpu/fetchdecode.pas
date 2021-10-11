{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

///////////////////////////
// prefix bytes
// opcode bytes
// mod_rm/sib
// address displacement
// immediate constant
///////////////////////////



// sign extended to osize:
//   6a push ib
//   6b imul gvevib
//   70..7f jo..jnle
//   83 G1 0..7 ADD..CMP Evib

// is 6b imul_gvevib sign extended?  don't think
//   I'm sign extending it properly in old decode/execute

//check all the groups.  Make sure to add duplicates rather
// than error.

// mark instructions as changing control transfer, then
// don't always load from fetch_ptr, etc.

// cant use immediate as another because of Group3 where
// some have immediate and some don't, and those won't
// be picked up by logic until indirection.

// get attr and execute ptr at same time

// maybe move 16bit only i's like  MOV_EwSw, MOV_SwEw
// to 32 bit mod_ules.

// use 0F as a prefix too?

//procedure BxResolveError(BxInstruction_t *);

{$if BX_DYNAMIC_TRANSLATION=1}
// For 16-bit address mod_e, this matrix describes the registers
// used to formulate the offset, indexed by the RM field.
// This info is needed by the dynamic translation code for dataflow.
static unsigned BxMemRegsUsed16[8] := begin
  (1 shl 3) or (1 shl 6), // BX + SI
  (1 shl 3) or (1 shl 7), // BX + DI
  (1 shl 5) or (1 shl 6), // BP + SI
  (1 shl 5) or (1 shl 7), // BP + DI
  (1 shl 6),          // SI
  (1 shl 7),          // DI
  (1 shl 5),          // BP
  (1 shl 3)           // BX
  end;;
{$ifend}

const

BxResolve16mod1or2:array[0..7] of Pointer = (
  @BX_CPU_C.Resolve16mod1or2Rm0,
  @BX_CPU_C.Resolve16mod1or2Rm1,
  @BX_CPU_C.Resolve16mod1or2Rm2,
  @BX_CPU_C.Resolve16mod1or2Rm3,
  @BX_CPU_C.Resolve16mod1or2Rm4,
  @BX_CPU_C.Resolve16mod1or2Rm5,
  @BX_CPU_C.Resolve16mod1or2Rm6,
  @BX_CPU_C.Resolve16mod1or2Rm7
  );

BxResolve32mod0:array[0..7] of Pointer = (
  @BX_CPU_C.Resolve32mod0Rm0,
  @BX_CPU_C.Resolve32mod0Rm1,
  @BX_CPU_C.Resolve32mod0Rm2,
  @BX_CPU_C.Resolve32mod0Rm3,
  NULL, // escape to 2-byte
  NULL, // d32, no registers used
  @BX_CPU_C.Resolve32mod0Rm6,
  @BX_CPU_C.Resolve32mod0Rm7
  );

BxResolve32mod1or2 : array[0..7] of Pointer = (
  @BX_CPU_C.Resolve32mod1or2Rm0,
  @BX_CPU_C.Resolve32mod1or2Rm1,
  @BX_CPU_C.Resolve32mod1or2Rm2,
  @BX_CPU_C.Resolve32mod1or2Rm3,
  NULL, // escape to 2-byte
  @BX_CPU_C.Resolve32mod1or2Rm5,
  @BX_CPU_C.Resolve32mod1or2Rm6,
  @BX_CPU_C.Resolve32mod1or2Rm7
  );

BxResolve32mod0Base:array[0..7] of Pointer = (
  @BX_CPU_C.Resolve32mod0Base0,
  @BX_CPU_C.Resolve32mod0Base1,
  @BX_CPU_C.Resolve32mod0Base2,
  @BX_CPU_C.Resolve32mod0Base3,
  @BX_CPU_C.Resolve32mod0Base4,
  @BX_CPU_C.Resolve32mod0Base5,
  @BX_CPU_C.Resolve32mod0Base6,
  @BX_CPU_C.Resolve32mod0Base7
  );

BxResolve32mod1or2Base:array[0..7] of Pointer = (
  @BX_CPU_C.Resolve32mod1or2Base0,
  @BX_CPU_C.Resolve32mod1or2Base1,
  @BX_CPU_C.Resolve32mod1or2Base2,
  @BX_CPU_C.Resolve32mod1or2Base3,
  @BX_CPU_C.Resolve32mod1or2Base4,
  @BX_CPU_C.Resolve32mod1or2Base5,
  @BX_CPU_C.Resolve32mod1or2Base6,
  @BX_CPU_C.Resolve32mod1or2Base7
);

static BxOpcodeInfo_t BxOpcodeInfoG1EbIb[8] := begin
  (* 0 *)  begin BxImmediate_Ib,  @BX_CPU_C.ADD_EbIb end;,
  (* 1 *)  begin BxImmediate_Ib,  @BX_CPU_C.OR_EbIb end;,
  (* 2 *)  begin BxImmediate_Ib,  @BX_CPU_C.ADC_EbIb end;,
  (* 3 *)  begin BxImmediate_Ib,  @BX_CPU_C.SBB_EbIb end;,
  (* 4 *)  begin BxImmediate_Ib,  @BX_CPU_C.AND_EbIb end;,
  (* 5 *)  begin BxImmediate_Ib,  @BX_CPU_C.SUB_EbIb end;,
  (* 6 *)  begin BxImmediate_Ib,  @BX_CPU_C.XOR_EbIb end;,
  (* 7 *)  begin BxImmediate_Ib,  @BX_CPU_C.CMP_EbIb end;
  end;; 

static BxOpcodeInfo_t BxOpcodeInfoG1Ew[8] := begin
  // attributes defined in main area
  (* 0 *)  begin 0,  @BX_CPU_C.ADD_EwIw end;,
  (* 1 *)  begin 0,  @BX_CPU_C.OR_EwIw end;,
  (* 2 *)  begin 0,  @BX_CPU_C.ADC_EwIw end;,
  (* 3 *)  begin 0,  @BX_CPU_C.SBB_EwIw end;,
  (* 4 *)  begin 0,  @BX_CPU_C.AND_EwIw end;,
  (* 5 *)  begin 0,  @BX_CPU_C.SUB_EwIw end;,
  (* 6 *)  begin 0,  @BX_CPU_C.XOR_EwIw end;,
  (* 7 *)  begin 0,  @BX_CPU_C.CMP_EwIw end;
  end;; 

static BxOpcodeInfo_t BxOpcodeInfoG1Ed[8] := begin
  // attributes defined in main area
  (* 0 *)  begin 0,  @BX_CPU_C.ADD_EdId end;,
  (* 1 *)  begin 0,  @BX_CPU_C.OR_EdId end;,
  (* 2 *)  begin 0,  @BX_CPU_C.ADC_EdId end;,
  (* 3 *)  begin 0,  @BX_CPU_C.SBB_EdId end;,
  (* 4 *)  begin 0,  @BX_CPU_C.AND_EdId end;,
  (* 5 *)  begin 0,  @BX_CPU_C.SUB_EdId end;,
  (* 6 *)  begin 0,  @BX_CPU_C.XOR_EdId end;,
  (* 7 *)  begin 0,  @BX_CPU_C.CMP_EdId end;
  end;;

static BxOpcodeInfo_t BxOpcodeInfoG2Eb[8] := begin
  // attributes defined in main area
  (* 0 *)  begin 0,  bx_cpu.ROL_Eb end;,
  (* 1 *)  begin 0,  bx_cpu.ROR_Eb end;,
  (* 2 *)  begin 0,  bx_cpu.RCL_Eb end;,
  (* 3 *)  begin 0,  bx_cpu.RCR_Eb end;,
  (* 4 *)  begin 0,  bx_cpu.SHL_Eb end;,
  (* 5 *)  begin 0,  bx_cpu.SHR_Eb end;,
  (* 6 *)  begin 0,  bx_cpu.SHL_Eb end;,
  (* 7 *)  begin 0,  bx_cpu.SAR_Eb end;
  end;;

static BxOpcodeInfo_t BxOpcodeInfoG2Ew[8] := begin
  // attributes defined in main area
  (* 0 *)  begin 0,  bx_cpu.ROL_Ew end;,
  (* 1 *)  begin 0,  bx_cpu.ROR_Ew end;,
  (* 2 *)  begin 0,  bx_cpu.RCL_Ew end;,
  (* 3 *)  begin 0,  bx_cpu.RCR_Ew end;,
  (* 4 *)  begin 0,  bx_cpu.SHL_Ew end;,
  (* 5 *)  begin 0,  bx_cpu.SHR_Ew end;,
  (* 6 *)  begin 0,  bx_cpu.SHL_Ew end;,
  (* 7 *)  begin 0,  bx_cpu.SAR_Ew end;
  end;;

static BxOpcodeInfo_t BxOpcodeInfoG2Ed[8] := begin
  // attributes defined in main area
  (* 0 *)  begin 0,  bx_cpu.ROL_Ed end;,
  (* 1 *)  begin 0,  bx_cpu.ROR_Ed end;,
  (* 2 *)  begin 0,  bx_cpu.RCL_Ed end;,
  (* 3 *)  begin 0,  bx_cpu.RCR_Ed end;,
  (* 4 *)  begin 0,  bx_cpu.SHL_Ed end;,
  (* 5 *)  begin 0,  bx_cpu.SHR_Ed end;,
  (* 6 *)  begin 0,  bx_cpu.SHL_Ed end;,
  (* 7 *)  begin 0,  bx_cpu.SAR_Ed end;
  end;;

static BxOpcodeInfo_t BxOpcodeInfoG3Eb[8] := begin
  (* 0 *)  begin BxImmediate_Ib,  bx_cpu.TEST_EbIb end;,
  (* 1 *)  begin BxImmediate_Ib,  bx_cpu.TEST_EbIb end;,
  (* 2 *)  begin 0,             bx_cpu.NOT_Eb end;,
  (* 3 *)  begin 0,             bx_cpu.NEG_Eb end;,
  (* 4 *)  begin 0,             bx_cpu.MUL_ALEb end;,
  (* 5 *)  begin 0,             bx_cpu.IMUL_ALEb end;,
  (* 6 *)  begin 0,             bx_cpu.DIV_ALEb end;,
  (* 7 *)  begin 0,             bx_cpu.IDIV_ALEb end;
  end;;

static BxOpcodeInfo_t BxOpcodeInfoG3Ew[8] := begin
  (* 0 *)  begin BxImmediate_Iw,  bx_cpu.TEST_EwIw end;,
  (* 1 *)  begin BxImmediate_Iw,  bx_cpu.TEST_EwIw end;,
  (* 2 *)  begin 0,             bx_cpu.NOT_Ew end;,
  (* 3 *)  begin 0,             bx_cpu.NEG_Ew end;,
  (* 4 *)  begin 0,             bx_cpu.MUL_AXEw end;,
  (* 5 *)  begin 0,             bx_cpu.IMUL_AXEw end;,
  (* 6 *)  begin 0,             bx_cpu.DIV_AXEw end;,
  (* 7 *)  begin 0,             bx_cpu.IDIV_AXEw end;
  end;;

static BxOpcodeInfo_t BxOpcodeInfoG3Ed[8] := begin
  (* 0 *)  begin BxImmediate_Iv,  bx_cpu.TEST_EdId end;,
  (* 1 *)  begin BxImmediate_Iv,  bx_cpu.TEST_EdId end;,
  (* 2 *)  begin 0,             bx_cpu.NOT_Ed end;,
  (* 3 *)  begin 0,             bx_cpu.NEG_Ed end;,
  (* 4 *)  begin 0,             bx_cpu.MUL_EAXEd end;,
  (* 5 *)  begin 0,             bx_cpu.IMUL_EAXEd end;,
  (* 6 *)  begin 0,             bx_cpu.DIV_EAXEd end;,
  (* 7 *)  begin 0,             bx_cpu.IDIV_EAXEd end;
  end;;

static BxOpcodeInfo_t BxOpcodeInfoG4[8] := begin
  (* 0 *)  begin 0,  bx_cpu.INC_Eb end;,
  (* 1 *)  begin 0,  bx_cpu.DEC_Eb end;,
  (* 2 *)  begin 0,  bx_cpu.BxError end;,
  (* 3 *)  begin 0,  bx_cpu.BxError end;,
  (* 4 *)  begin 0,  bx_cpu.BxError end;,
  (* 5 *)  begin 0,  bx_cpu.BxError end;,
  (* 6 *)  begin 0,  bx_cpu.BxError end;,
  (* 7 *)  begin 0,  bx_cpu.BxError end;
  end;;

static BxOpcodeInfo_t BxOpcodeInfoG5w[8] := begin
  // attributes defined in main area
  (* 0 *)  begin 0,  bx_cpu.INC_Ew end;,
  (* 1 *)  begin 0,  bx_cpu.DEC_Ew end;,
  (* 2 *)  begin 0,  bx_cpu.CALL_Ew end;,
  (* 3 *)  begin 0,  bx_cpu.CALL16_Ep end;,
  (* 4 *)  begin 0,  bx_cpu.JMP_Ew end;,
  (* 5 *)  begin 0,  bx_cpu.JMP16_Ep end;,
  (* 6 *)  begin 0,  bx_cpu.PUSH_Ew end;,
  (* 7 *)  begin 0,  bx_cpu.BxError end;
  end;;

static BxOpcodeInfo_t BxOpcodeInfoG5d[8] := begin
  // attributes defined in main area
  (* 0 *)  begin 0,  bx_cpu.INC_Ed end;,
  (* 1 *)  begin 0,  bx_cpu.DEC_Ed end;,
  (* 2 *)  begin 0,  bx_cpu.CALL_Ed end;,
  (* 3 *)  begin 0,  bx_cpu.CALL32_Ep end;,
  (* 4 *)  begin 0,  bx_cpu.JMP_Ed end;,
  (* 5 *)  begin 0,  bx_cpu.JMP32_Ep end;,
  (* 6 *)  begin 0,  bx_cpu.PUSH_Ed end;,
  (* 7 *)  begin 0,  bx_cpu.BxError end;
  end;;

static BxOpcodeInfo_t BxOpcodeInfoG6[8] := begin
  // attributes defined in main area
  (* 0 *)  begin 0,  bx_cpu.SLDT_Ew end;,
  (* 1 *)  begin 0,  bx_cpu.STR_Ew end;,
  (* 2 *)  begin 0,  bx_cpu.LLDT_Ew end;,
  (* 3 *)  begin 0,  bx_cpu.LTR_Ew end;,
  (* 4 *)  begin 0,  bx_cpu.VERR_Ew end;,
  (* 5 *)  begin 0,  bx_cpu.VERW_Ew end;,
  (* 6 *)  begin 0,  bx_cpu.BxError end;,
  (* 7 *)  begin 0,  bx_cpu.BxError end;
  end;;

static BxOpcodeInfo_t BxOpcodeInfoG7[8] := begin
  (* 0 *)  begin 0,  bx_cpu.SGDT_Ms end;,
  (* 1 *)  begin 0,  bx_cpu.SIDT_Ms end;,
  (* 2 *)  begin 0,  bx_cpu.LGDT_Ms end;,
  (* 3 *)  begin 0,  bx_cpu.LIDT_Ms end;,
  (* 4 *)  begin 0,  bx_cpu.SMSW_Ew end;,
  (* 5 *)  begin 0,  bx_cpu.BxError end;,
  (* 6 *)  begin 0,  bx_cpu.LMSW_Ew end;,
  (* 7 *)  begin 0,  bx_cpu.INVLPG end;
  end;;


static BxOpcodeInfo_t BxOpcodeInfoG8EvIb[8] := begin
  (* 0 *)  begin 0,  bx_cpu.BxError end;,
  (* 1 *)  begin 0,  bx_cpu.BxError end;,
  (* 2 *)  begin 0,  bx_cpu.BxError end;,
  (* 3 *)  begin 0,  bx_cpu.BxError end;,
  (* 4 *)  begin BxImmediate_Ib,  bx_cpu.BT_EvIb end;,
  (* 5 *)  begin BxImmediate_Ib,  bx_cpu.BTS_EvIb end;,
  (* 6 *)  begin BxImmediate_Ib,  bx_cpu.BTR_EvIb end;,
  (* 7 *)  begin BxImmediate_Ib,  bx_cpu.BTC_EvIb end;
  end;;

static BxOpcodeInfo_t BxOpcodeInfoG9[8] := begin
  (* 0 *)  begin 0,  bx_cpu.BxError end;,
  (* 1 *)  begin 0,  bx_cpu.CMPXCHG8B end;,
  (* 2 *)  begin 0,  bx_cpu.BxError end;,
  (* 3 *)  begin 0,  bx_cpu.BxError end;,
  (* 4 *)  begin 0,  bx_cpu.BxError end;,
  (* 5 *)  begin 0,  bx_cpu.BxError end;,
  (* 6 *)  begin 0,  bx_cpu.BxError end;,
  (* 7 *)  begin 0,  bx_cpu.BxError end;
  end;;


// 512 entries for 16bit mod_e
// 512 entries for 32bit mod_e

static BxOpcodeInfo_t BxOpcodeInfo[512*2] := begin
  // 512 entries for 16bit mod_e
  (* 00 *)  begin BxAnother,  bx_cpu.ADD_EbGb end;,
  (* 01 *)  begin BxAnother,  bx_cpu.ADD_EwGw end;,
  (* 02 *)  begin BxAnother,  bx_cpu.ADD_GbEb end;,
  (* 03 *)  begin BxAnother,  bx_cpu.ADD_GwEw end;,
  (* 04 *)  begin BxImmediate_Ib,  bx_cpu.ADD_ALIb end;,
  (* 05 *)  begin BxImmediate_Iv,  bx_cpu.ADD_AXIw end;,
  (* 06 *)  begin 0,  bx_cpu.PUSH_ES end;,
  (* 07 *)  begin 0,  bx_cpu.POP_ES end;,
  (* 08 *)  begin BxAnother,  bx_cpu.OR_EbGb end;,
  (* 09 *)  begin BxAnother,  bx_cpu.OR_EwGw end;,
  (* 0A *)  begin BxAnother,  bx_cpu.OR_GbEb end;,
  (* 0B *)  begin BxAnother,  bx_cpu.OR_GwEw end;,
  (* 0C *)  begin BxImmediate_Ib,  bx_cpu.OR_ALIb end;,
  (* 0D *)  begin BxImmediate_Iv,  bx_cpu.OR_AXIw end;,
  (* 0E *)  begin 0,  bx_cpu.PUSH_CS end;,
  (* 0F *)  begin BxAnother,  bx_cpu.BxError end;, // 2-byte escape
  (* 10 *)  begin BxAnother,  bx_cpu.ADC_EbGb end;,
  (* 11 *)  begin BxAnother,  bx_cpu.ADC_EwGw end;,
  (* 12 *)  begin BxAnother,  bx_cpu.ADC_GbEb end;,
  (* 13 *)  begin BxAnother,  bx_cpu.ADC_GwEw end;,
  (* 14 *)  begin BxImmediate_Ib,  bx_cpu.ADC_ALIb end;,
  (* 15 *)  begin BxImmediate_Iv,  bx_cpu.ADC_AXIw end;,
  (* 16 *)  begin 0,  bx_cpu.PUSH_SS end;,
  (* 17 *)  begin 0,  bx_cpu.POP_SS end;,
  (* 18 *)  begin BxAnother,  bx_cpu.SBB_EbGb end;,
  (* 19 *)  begin BxAnother,  bx_cpu.SBB_EwGw end;,
  (* 1A *)  begin BxAnother,  bx_cpu.SBB_GbEb end;,
  (* 1B *)  begin BxAnother,  bx_cpu.SBB_GwEw end;,
  (* 1C *)  begin BxImmediate_Ib,  bx_cpu.SBB_ALIb end;,
  (* 1D *)  begin BxImmediate_Iv,  bx_cpu.SBB_AXIw end;,
  (* 1E *)  begin 0,  bx_cpu.PUSH_DS end;,
  (* 1F *)  begin 0,  bx_cpu.POP_DS end;,
  (* 20 *)  begin BxAnother,  bx_cpu.AND_EbGb end;,
  (* 21 *)  begin BxAnother,  bx_cpu.AND_EwGw end;,
  (* 22 *)  begin BxAnother,  bx_cpu.AND_GbEb end;,
  (* 23 *)  begin BxAnother,  bx_cpu.AND_GwEw end;,
  (* 24 *)  begin BxImmediate_Ib,  bx_cpu.AND_ALIb end;,
  (* 25 *)  begin BxImmediate_Iv,  bx_cpu.AND_AXIw end;,
  (* 26 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // ES:
  (* 27 *)  begin 0,  bx_cpu.DAA end;,
  (* 28 *)  begin BxAnother,  bx_cpu.SUB_EbGb end;,
  (* 29 *)  begin BxAnother,  bx_cpu.SUB_EwGw end;,
  (* 2A *)  begin BxAnother,  bx_cpu.SUB_GbEb end;,
  (* 2B *)  begin BxAnother,  bx_cpu.SUB_GwEw end;,
  (* 2C *)  begin BxImmediate_Ib,  bx_cpu.SUB_ALIb end;,
  (* 2D *)  begin BxImmediate_Iv,  bx_cpu.SUB_AXIw end;,
  (* 2E *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // CS:
  (* 2F *)  begin 0,  bx_cpu.DAS end;,
  (* 30 *)  begin BxAnother,  bx_cpu.XOR_EbGb end;,
  (* 31 *)  begin BxAnother,  bx_cpu.XOR_EwGw end;,
  (* 32 *)  begin BxAnother,  bx_cpu.XOR_GbEb end;,
  (* 33 *)  begin BxAnother,  bx_cpu.XOR_GwEw end;,
  (* 34 *)  begin BxImmediate_Ib,  bx_cpu.XOR_ALIb end;,
  (* 35 *)  begin BxImmediate_Iv,  bx_cpu.XOR_AXIw end;,
  (* 36 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // SS:
  (* 37 *)  begin 0,  bx_cpu.AAA end;,
  (* 38 *)  begin BxAnother,  bx_cpu.CMP_EbGb end;,
  (* 39 *)  begin BxAnother,  bx_cpu.CMP_EwGw end;,
  (* 3A *)  begin BxAnother,  bx_cpu.CMP_GbEb end;,
  (* 3B *)  begin BxAnother,  bx_cpu.CMP_GwEw end;,
  (* 3C *)  begin BxImmediate_Ib,  bx_cpu.CMP_ALIb end;,
  (* 3D *)  begin BxImmediate_Iv,  bx_cpu.CMP_AXIw end;,
  (* 3E *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // DS:
  (* 3F *)  begin 0,  bx_cpu.AAS end;,
  (* 40 *)  begin 0,  bx_cpu.INC_RX end;,
  (* 41 *)  begin 0,  bx_cpu.INC_RX end;,
  (* 42 *)  begin 0,  bx_cpu.INC_RX end;,
  (* 43 *)  begin 0,  bx_cpu.INC_RX end;,
  (* 44 *)  begin 0,  bx_cpu.INC_RX end;,
  (* 45 *)  begin 0,  bx_cpu.INC_RX end;,
  (* 46 *)  begin 0,  bx_cpu.INC_RX end;,
  (* 47 *)  begin 0,  bx_cpu.INC_RX end;,
  (* 48 *)  begin 0,  bx_cpu.DEC_RX end;,
  (* 49 *)  begin 0,  bx_cpu.DEC_RX end;,
  (* 4A *)  begin 0,  bx_cpu.DEC_RX end;,
  (* 4B *)  begin 0,  bx_cpu.DEC_RX end;,
  (* 4C *)  begin 0,  bx_cpu.DEC_RX end;,
  (* 4D *)  begin 0,  bx_cpu.DEC_RX end;,
  (* 4E *)  begin 0,  bx_cpu.DEC_RX end;,
  (* 4F *)  begin 0,  bx_cpu.DEC_RX end;,
  (* 50 *)  begin 0,  bx_cpu.PUSH_RX end;,
  (* 51 *)  begin 0,  bx_cpu.PUSH_RX end;,
  (* 52 *)  begin 0,  bx_cpu.PUSH_RX end;,
  (* 53 *)  begin 0,  bx_cpu.PUSH_RX end;,
  (* 54 *)  begin 0,  bx_cpu.PUSH_RX end;,
  (* 55 *)  begin 0,  bx_cpu.PUSH_RX end;,
  (* 56 *)  begin 0,  bx_cpu.PUSH_RX end;,
  (* 57 *)  begin 0,  bx_cpu.PUSH_RX end;,
  (* 58 *)  begin 0,  bx_cpu.POP_RX end;,
  (* 59 *)  begin 0,  bx_cpu.POP_RX end;,
  (* 5A *)  begin 0,  bx_cpu.POP_RX end;,
  (* 5B *)  begin 0,  bx_cpu.POP_RX end;,
  (* 5C *)  begin 0,  bx_cpu.POP_RX end;,
  (* 5D *)  begin 0,  bx_cpu.POP_RX end;,
  (* 5E *)  begin 0,  bx_cpu.POP_RX end;,
  (* 5F *)  begin 0,  bx_cpu.POP_RX end;,
  (* 60 *)  begin 0,  bx_cpu.PUSHAD16 end;,
  (* 61 *)  begin 0,  bx_cpu.POPAD16 end;,
  (* 62 *)  begin BxAnother,  bx_cpu.BOUND_GvMa end;,
  (* 63 *)  begin BxAnother,  bx_cpu.ARPL_EwGw end;,
  (* 64 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // FS:
  (* 65 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // GS:
  (* 66 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // OS:
  (* 67 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // AS:
  (* 68 *)  begin BxImmediate_Iv,  bx_cpu.PUSH_Iw end;,
  (* 69 *)  begin BxAnotherorBxImmediate_Iv,  bx_cpu.IMUL_GwEwIw end;,
  (* 6A *)  begin BxImmediate_Ib_SE,  bx_cpu.PUSH_Iw end;,
  (* 6B *)  begin BxAnotherorBxImmediate_Ib_SE,  bx_cpu.IMUL_GwEwIw end;,
  (* 6C *)  begin BxRepeatable,  bx_cpu.INSB_YbDX end;,
  (* 6D *)  begin BxRepeatable,  bx_cpu.INSW_YvDX end;,
  (* 6E *)  begin BxRepeatable,  bx_cpu.OUTSB_DXXb end;,
  (* 6F *)  begin BxRepeatable,  bx_cpu.OUTSW_DXXv end;,
  (* 70 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 71 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 72 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 73 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 74 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 75 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 76 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 77 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 78 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 79 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 7A *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 7B *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 7C *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 7D *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 7E *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 7F *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jw end;,
  (* 80 *)  begin BxAnotherorBxGroup1, NULL, BxOpcodeInfoG1EbIb end;,
  (* 81 *)  begin BxAnotherorBxGroup1orBxImmediate_Iv, NULL, BxOpcodeInfoG1Ew end;,
  (* 82 *)  begin BxAnotherorBxGroup1,  NULL, BxOpcodeInfoG1EbIb end;,
  (* 83 *)  begin BxAnotherorBxGroup1orBxImmediate_Ib_SE, NULL, BxOpcodeInfoG1Ew end;,
  (* 84 *)  begin BxAnother,  bx_cpu.TEST_EbGb end;,
  (* 85 *)  begin BxAnother,  bx_cpu.TEST_EwGw end;,
  (* 86 *)  begin BxAnother,  bx_cpu.XCHG_EbGb end;,
  (* 87 *)  begin BxAnother,  bx_cpu.XCHG_EwGw end;,
  (* 88 *)  begin BxAnother,  bx_cpu.MOV_EbGb end;,
  (* 89 *)  begin BxAnother,  bx_cpu.MOV_EwGw end;,
  (* 8A *)  begin BxAnother,  bx_cpu.MOV_GbEb end;,
  (* 8B *)  begin BxAnother,  bx_cpu.MOV_GwEw end;,
  (* 8C *)  begin BxAnother,  bx_cpu.MOV_EwSw end;,
  (* 8D *)  begin BxAnother,  bx_cpu.LEA_GwM end;,
  (* 8E *)  begin BxAnother,  bx_cpu.MOV_SwEw end;,
  (* 8F *)  begin BxAnother,  bx_cpu.POP_Ew end;,
  (* 90 *)  begin 0,  bx_cpu.NOP end;,
  (* 91 *)  begin 0,  bx_cpu.XCHG_RXAX end;,
  (* 92 *)  begin 0,  bx_cpu.XCHG_RXAX end;,
  (* 93 *)  begin 0,  bx_cpu.XCHG_RXAX end;,
  (* 94 *)  begin 0,  bx_cpu.XCHG_RXAX end;,
  (* 95 *)  begin 0,  bx_cpu.XCHG_RXAX end;,
  (* 96 *)  begin 0,  bx_cpu.XCHG_RXAX end;,
  (* 97 *)  begin 0,  bx_cpu.XCHG_RXAX end;,
  (* 98 *)  begin 0,  bx_cpu.CBW end;,
  (* 99 *)  begin 0,  bx_cpu.CWD end;,
  (* 9A *)  begin BxImmediate_IvIw,  bx_cpu.CALL16_Ap end;,
  (* 9B *)  begin 0,  bx_cpu.FWAIT end;,
  (* 9C *)  begin 0,  bx_cpu.PUSHF_Fv end;,
  (* 9D *)  begin 0,  bx_cpu.POPF_Fv end;,
  (* 9E *)  begin 0,  bx_cpu.SAHF end;,
  (* 9F *)  begin 0,  bx_cpu.LAHF end;,
  (* A0 *)  begin BxImmediate_O,  bx_cpu.MOV_ALOb end;,
  (* A1 *)  begin BxImmediate_O,  bx_cpu.MOV_AXOw end;,
  (* A2 *)  begin BxImmediate_O,  bx_cpu.MOV_ObAL end;,
  (* A3 *)  begin BxImmediate_O,  bx_cpu.MOV_OwAX end;,
  (* A4 *)  begin BxRepeatable,  bx_cpu.MOVSB_XbYb end;,
  (* A5 *)  begin BxRepeatable,  bx_cpu.MOVSW_XvYv end;,
  (* A6 *)  begin BxRepeatableorBxRepeatableZF,  bx_cpu.CMPSB_XbYb end;,
  (* A7 *)  begin BxRepeatableorBxRepeatableZF,  bx_cpu.CMPSW_XvYv end;,
  (* A8 *)  begin BxImmediate_Ib,  bx_cpu.TEST_ALIb end;,
  (* A9 *)  begin BxImmediate_Iv,  bx_cpu.TEST_AXIw end;,
  (* AA *)  begin BxRepeatable,  bx_cpu.STOSB_YbAL end;,
  (* AB *)  begin BxRepeatable,  bx_cpu.STOSW_YveAX end;,
  (* AC *)  begin BxRepeatable,  bx_cpu.LODSB_ALXb end;,
  (* AD *)  begin BxRepeatable,  bx_cpu.LODSW_eAXXv end;,
  (* AE *)  begin BxRepeatableorBxRepeatableZF,  bx_cpu.SCASB_ALXb end;,
  (* AF *)  begin BxRepeatableorBxRepeatableZF,  bx_cpu.SCASW_eAXXv end;,
  (* B0 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RLIb end;,
  (* B1 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RLIb end;,
  (* B2 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RLIb end;,
  (* B3 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RLIb end;,
  (* B4 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RHIb end;,
  (* B5 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RHIb end;,
  (* B6 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RHIb end;,
  (* B7 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RHIb end;,
  (* B8 *)  begin BxImmediate_Iv,  bx_cpu.MOV_RXIw end;,
  (* B9 *)  begin BxImmediate_Iv,  bx_cpu.MOV_RXIw end;,
  (* BA *)  begin BxImmediate_Iv,  bx_cpu.MOV_RXIw end;,
  (* BB *)  begin BxImmediate_Iv,  bx_cpu.MOV_RXIw end;,
  (* BC *)  begin BxImmediate_Iv,  bx_cpu.MOV_RXIw end;,
  (* BD *)  begin BxImmediate_Iv,  bx_cpu.MOV_RXIw end;,
  (* BE *)  begin BxImmediate_Iv,  bx_cpu.MOV_RXIw end;,
  (* BF *)  begin BxImmediate_Iv,  bx_cpu.MOV_RXIw end;,
  (* C0 *)  begin BxAnotherorBxGroup2orBxImmediate_Ib, NULL, BxOpcodeInfoG2Eb end;,
  (* C1 *)  begin BxAnotherorBxGroup2orBxImmediate_Ib, NULL, BxOpcodeInfoG2Ew end;,
  (* C2 *)  begin BxImmediate_Iw,  bx_cpu.RETnear16_Iw end;,
  (* C3 *)  begin 0,             bx_cpu.RETnear16 end;,
  (* C4 *)  begin BxAnother,  bx_cpu.LES_GvMp end;,
  (* C5 *)  begin BxAnother,  bx_cpu.LDS_GvMp end;,
  (* C6 *)  begin BxAnotherorBxImmediate_Ib,  bx_cpu.MOV_EbIb end;,
  (* C7 *)  begin BxAnotherorBxImmediate_Iv,  bx_cpu.MOV_EwIw end;,
  (* C8 *)  begin BxImmediate_IwIb,  bx_cpu.ENTER_IwIb end;,
  (* C9 *)  begin 0,  bx_cpu.LEAVE end;,
  (* CA *)  begin BxImmediate_Iw,  bx_cpu.RETfar16_Iw end;,
  (* CB *)  begin 0,  bx_cpu.RETfar16 end;,
  (* CC *)  begin 0,  bx_cpu.INT3 end;,
  (* CD *)  begin BxImmediate_Ib,  bx_cpu.INT_Ib end;,
  (* CE *)  begin 0,  bx_cpu.INTO end;,
  (* CF *)  begin 0,  bx_cpu.IRET16 end;,
  (* D0 *)  begin BxAnotherorBxGroup2,  NULL, BxOpcodeInfoG2Eb end;,
  (* D1 *)  begin BxAnotherorBxGroup2,  NULL, BxOpcodeInfoG2Ew end;,
  (* D2 *)  begin BxAnotherorBxGroup2,  NULL, BxOpcodeInfoG2Eb end;,
  (* D3 *)  begin BxAnotherorBxGroup2,  NULL, BxOpcodeInfoG2Ew end;,
  (* D4 *)  begin BxImmediate_Ib,  bx_cpu.AAM end;,
  (* D5 *)  begin BxImmediate_Ib,  bx_cpu.AAD end;,
  (* D6 *)  begin 0,  bx_cpu.SALC end;,
  (* D7 *)  begin 0,  bx_cpu.XLAT end;,
  (* D8 *)  begin BxAnother,  bx_cpu.ESC0 end;,
  (* D9 *)  begin BxAnother,  bx_cpu.ESC1 end;,
  (* DA *)  begin BxAnother,  bx_cpu.ESC2 end;,
  (* DB *)  begin BxAnother,  bx_cpu.ESC3 end;,
  (* DC *)  begin BxAnother,  bx_cpu.ESC4 end;,
  (* DD *)  begin BxAnother,  bx_cpu.ESC5 end;,
  (* DE *)  begin BxAnother,  bx_cpu.ESC6 end;,
  (* DF *)  begin BxAnother,  bx_cpu.ESC7 end;,
  (* E0 *)  begin BxImmediate_BrOff8,  bx_cpu.LOOPNE_Jb end;,
  (* E1 *)  begin BxImmediate_BrOff8,  bx_cpu.LOOPE_Jb end;,
  (* E2 *)  begin BxImmediate_BrOff8,  bx_cpu.LOOP_Jb end;,
  (* E3 *)  begin BxImmediate_BrOff8,  bx_cpu.JCXZ_Jb end;,
  (* E4 *)  begin BxImmediate_Ib,  bx_cpu.IN_ALIb end;,
  (* E5 *)  begin BxImmediate_Ib,  bx_cpu.IN_eAXIb end;,
  (* E6 *)  begin BxImmediate_Ib,  bx_cpu.OUT_IbAL end;,
  (* E7 *)  begin BxImmediate_Ib,  bx_cpu.OUT_IbeAX end;,
  (* E8 *)  begin BxImmediate_BrOff16,  bx_cpu.CALL_Aw end;,
  (* E9 *)  begin BxImmediate_BrOff16,  bx_cpu.JMP_Jw end;,
  (* EA *)  begin BxImmediate_IvIw,  bx_cpu.JMP_Ap end;,
  (* EB *)  begin BxImmediate_BrOff8,  bx_cpu.JMP_Jw end;,
  (* EC *)  begin 0,  bx_cpu.IN_ALDX end;,
  (* ED *)  begin 0,  bx_cpu.IN_eAXDX end;,
  (* EE *)  begin 0,  bx_cpu.OUT_DXAL end;,
  (* EF *)  begin 0,  bx_cpu.OUT_DXeAX end;,
  (* F0 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // LOCK
  (* F1 *)  begin 0,  bx_cpu.INT1 end;,
  (* F2 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // REPNE/REPNZ
  (* F3 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // REP, REPE/REPZ
  (* F4 *)  begin 0,  bx_cpu.HLT end;,
  (* F5 *)  begin 0,  bx_cpu.CMC end;,
  (* F6 *)  begin BxAnotherorBxGroup3,  NULL, BxOpcodeInfoG3Eb end;,
  (* F7 *)  begin BxAnotherorBxGroup3,  NULL, BxOpcodeInfoG3Ew end;,
  (* F8 *)  begin 0,  bx_cpu.CLC end;,
  (* F9 *)  begin 0,  bx_cpu.STC end;,
  (* FA *)  begin 0,  bx_cpu.CLI end;,
  (* FB *)  begin 0,  bx_cpu.STI end;,
  (* FC *)  begin 0,  bx_cpu.CLD end;,
  (* FD *)  begin 0,  bx_cpu.STD end;,
  (* FE *)  begin BxAnotherorBxGroup4,  NULL, BxOpcodeInfoG4 end;,
  (* FF *)  begin BxAnotherorBxGroup5,  NULL, BxOpcodeInfoG5w end;,

  (* 0F 00 *)  begin BxAnotherorBxGroup6,  NULL, BxOpcodeInfoG6 end;,
  (* 0F 01 *)  begin BxAnotherorBxGroup7,  NULL, BxOpcodeInfoG7 end;,
  (* 0F 02 *)  begin BxAnother,  bx_cpu.LAR_GvEw end;,
  (* 0F 03 *)  begin BxAnother,  bx_cpu.LSL_GvEw end;,
  (* 0F 04 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 05 *)  begin 0,  bx_cpu.LOADALL end;,
  (* 0F 06 *)  begin 0,  bx_cpu.CLTS end;,
  (* 0F 07 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 08 *)  begin 0,  bx_cpu.INVD end;,
  (* 0F 09 *)  begin 0,  bx_cpu.WBINVD end;,
  (* 0F 0A *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 0B *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 0C *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 0D *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 0E *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 0F *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 10 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 11 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 12 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 13 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 14 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 15 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 16 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 17 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 18 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 19 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 1A *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 1B *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 1C *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 1D *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 1E *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 1F *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 20 *)  begin BxAnother,  bx_cpu.MOV_RdCd end;,
  (* 0F 21 *)  begin BxAnother,  bx_cpu.MOV_RdDd end;,
  (* 0F 22 *)  begin BxAnother,  bx_cpu.MOV_CdRd end;,
  (* 0F 23 *)  begin BxAnother,  bx_cpu.MOV_DdRd end;,
  (* 0F 24 *)  begin BxAnother,  bx_cpu.MOV_RdTd end;,
  (* 0F 25 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 26 *)  begin BxAnother,  bx_cpu.MOV_TdRd end;,
  (* 0F 27 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 28 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 29 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 2A *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 2B *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 2C *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 2D *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 2E *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 2F *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 30 *)  begin 0,  bx_cpu.WRMSR end;,
  (* 0F 31 *)  begin 0,  bx_cpu.RDTSC end;,
  (* 0F 32 *)  begin 0,  bx_cpu.RDMSR end;,
  (* 0F 33 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 34 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 35 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 36 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 37 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 38 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 39 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 3A *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 3B *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 3C *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 3D *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 3E *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 3F *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 40 *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 41 *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 42 *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 43 *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 44 *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 45 *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 46 *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 47 *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 48 *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 49 *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 4A *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 4B *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 4C *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 4D *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 4E *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 4F *)  begin BxAnother,  bx_cpu.CMOV_GwEw end;,
  (* 0F 50 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 51 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 52 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 53 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 54 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 55 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 56 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 57 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 58 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 59 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 5A *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 5B *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 5C *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 5D *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 5E *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 5F *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 60 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 61 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 62 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 63 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 64 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 65 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 66 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 67 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 68 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 69 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 6A *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 6B *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 6C *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 6D *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 6E *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 6F *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 70 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 71 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 72 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 73 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 74 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 75 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 76 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 77 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 78 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 79 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 7A *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 7B *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 7C *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 7D *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 7E *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 7F *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 80 *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 81 *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 82 *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 83 *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 84 *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 85 *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 86 *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 87 *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 88 *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 89 *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 8A *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 8B *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 8C *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 8D *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 8E *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 8F *)  begin BxImmediate_BrOff16,  bx_cpu.JCC_Jw end;,
  (* 0F 90 *)  begin BxAnother,  bx_cpu.SETO_Eb end;,
  (* 0F 91 *)  begin BxAnother,  bx_cpu.SETNO_Eb end;,
  (* 0F 92 *)  begin BxAnother,  bx_cpu.SETB_Eb end;,
  (* 0F 93 *)  begin BxAnother,  bx_cpu.SETNB_Eb end;,
  (* 0F 94 *)  begin BxAnother,  bx_cpu.SETZ_Eb end;,
  (* 0F 95 *)  begin BxAnother,  bx_cpu.SETNZ_Eb end;,
  (* 0F 96 *)  begin BxAnother,  bx_cpu.SETBE_Eb end;,
  (* 0F 97 *)  begin BxAnother,  bx_cpu.SETNBE_Eb end;,
  (* 0F 98 *)  begin BxAnother,  bx_cpu.SETS_Eb end;,
  (* 0F 99 *)  begin BxAnother,  bx_cpu.SETNS_Eb end;,
  (* 0F 9A *)  begin BxAnother,  bx_cpu.SETP_Eb end;,
  (* 0F 9B *)  begin BxAnother,  bx_cpu.SETNP_Eb end;,
  (* 0F 9C *)  begin BxAnother,  bx_cpu.SETL_Eb end;,
  (* 0F 9D *)  begin BxAnother,  bx_cpu.SETNL_Eb end;,
  (* 0F 9E *)  begin BxAnother,  bx_cpu.SETLE_Eb end;,
  (* 0F 9F *)  begin BxAnother,  bx_cpu.SETNLE_Eb end;,
  (* 0F A0 *)  begin 0,  bx_cpu.PUSH_FS end;,
  (* 0F A1 *)  begin 0,  bx_cpu.POP_FS end;,
  (* 0F A2 *)  begin 0,  bx_cpu.CPUID end;,
  (* 0F A3 *)  begin BxAnother,  bx_cpu.BT_EvGv end;,
  (* 0F A4 *)  begin BxAnotherorBxImmediate_Ib,  bx_cpu.SHLD_EwGw end;,
  (* 0F A5 *)  begin BxAnother,                 bx_cpu.SHLD_EwGw end;,
  (* 0F A6 *)  begin 0,  bx_cpu.CMPXCHG_XBTS end;,
  (* 0F A7 *)  begin 0,  bx_cpu.CMPXCHG_IBTS end;,
  (* 0F A8 *)  begin 0,  bx_cpu.PUSH_GS end;,
  (* 0F A9 *)  begin 0,  bx_cpu.POP_GS end;,
  (* 0F AA *)  begin 0,  bx_cpu.RSM end;,
  (* 0F AB *)  begin BxAnother,  bx_cpu.BTS_EvGv end;,
  (* 0F AC *)  begin BxAnotherorBxImmediate_Ib,  bx_cpu.SHRD_EwGw end;,
  (* 0F AD *)  begin BxAnother,                 bx_cpu.SHRD_EwGw end;,
  (* 0F AE *)  begin 0,  bx_cpu.BxError end;,
  (* 0F AF *)  begin BxAnother,  bx_cpu.IMUL_GwEw end;,
  (* 0F B0 *)  begin BxAnother,  bx_cpu.CMPXCHG_EbGb end;,
  (* 0F B1 *)  begin BxAnother,  bx_cpu.CMPXCHG_EwGw end;,
  (* 0F B2 *)  begin BxAnother,  bx_cpu.LSS_GvMp end;,
  (* 0F B3 *)  begin BxAnother,  bx_cpu.BTR_EvGv end;,
  (* 0F B4 *)  begin BxAnother,  bx_cpu.LFS_GvMp end;,
  (* 0F B5 *)  begin BxAnother,  bx_cpu.LGS_GvMp end;,
  (* 0F B6 *)  begin BxAnother,  bx_cpu.MOVZX_GwEb end;,
  (* 0F B7 *)  begin BxAnother,  bx_cpu.MOVZX_GwEw end;,
  (* 0F B8 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F B9 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F BA *)  begin BxAnotherorBxGroup8, NULL, BxOpcodeInfoG8EvIb end;,
  (* 0F BB *)  begin BxAnother,  bx_cpu.BTC_EvGv end;,
  (* 0F BC *)  begin BxAnother,  bx_cpu.BSF_GvEv end;,
  (* 0F BD *)  begin BxAnother,  bx_cpu.BSR_GvEv end;,
  (* 0F BE *)  begin BxAnother,  bx_cpu.MOVSX_GwEb end;,
  (* 0F BF *)  begin BxAnother,  bx_cpu.MOVSX_GwEw end;,
  (* 0F C0 *)  begin BxAnother,  bx_cpu.XADD_EbGb end;,
  (* 0F C1 *)  begin BxAnother,  bx_cpu.XADD_EwGw end;,
  (* 0F C2 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F C3 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F C4 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F C5 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F C6 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F C7 *)  begin BxAnotherorBxGroup9,  NULL, BxOpcodeInfoG9 end;,
  (* 0F C8 *)  begin 0,  bx_cpu.BSWAP_EAX end;,
  (* 0F C9 *)  begin 0,  bx_cpu.BSWAP_ECX end;,
  (* 0F CA *)  begin 0,  bx_cpu.BSWAP_EDX end;,
  (* 0F CB *)  begin 0,  bx_cpu.BSWAP_EBX end;,
  (* 0F CC *)  begin 0,  bx_cpu.BSWAP_ESP end;,
  (* 0F CD *)  begin 0,  bx_cpu.BSWAP_EBP end;,
  (* 0F CE *)  begin 0,  bx_cpu.BSWAP_ESI end;,
  (* 0F CF *)  begin 0,  bx_cpu.BSWAP_EDI end;,
  (* 0F D0 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D1 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D2 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D3 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D4 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D5 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D6 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D7 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D8 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D9 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F DA *)  begin 0,  bx_cpu.BxError end;,
  (* 0F DB *)  begin 0,  bx_cpu.BxError end;,
  (* 0F DC *)  begin 0,  bx_cpu.BxError end;,
  (* 0F DD *)  begin 0,  bx_cpu.BxError end;,
  (* 0F DE *)  begin 0,  bx_cpu.BxError end;,
  (* 0F DF *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E0 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E1 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E2 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E3 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E4 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E5 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E6 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E7 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E8 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E9 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F EA *)  begin 0,  bx_cpu.BxError end;,
  (* 0F EB *)  begin 0,  bx_cpu.BxError end;,
  (* 0F EC *)  begin 0,  bx_cpu.BxError end;,
  (* 0F ED *)  begin 0,  bx_cpu.BxError end;,
  (* 0F EE *)  begin 0,  bx_cpu.BxError end;,
  (* 0F EF *)  begin 0,  bx_cpu.BxError end;,
  (* 0F F0 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F1 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F2 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F3 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F4 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F5 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F6 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F7 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F8 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F9 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F FA *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F FB *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F FC *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F FD *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F FE *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F FF *)  begin 0,  bx_cpu.UndefinedOpcode end;,

  // 512 entries for 32bit mod_
  (* 00 *)  begin BxAnother,  bx_cpu.ADD_EbGb end;,
  (* 01 *)  begin BxAnother,  bx_cpu.ADD_EdGd end;,
  (* 02 *)  begin BxAnother,  bx_cpu.ADD_GbEb end;,
  (* 03 *)  begin BxAnother,  bx_cpu.ADD_GdEd end;,
  (* 04 *)  begin BxImmediate_Ib,  bx_cpu.ADD_ALIb end;,
  (* 05 *)  begin BxImmediate_Iv,  bx_cpu.ADD_EAXId end;,
  (* 06 *)  begin 0,  bx_cpu.PUSH_ES end;,
  (* 07 *)  begin 0,  bx_cpu.POP_ES end;,
  (* 08 *)  begin BxAnother,  bx_cpu.OR_EbGb end;,
  (* 09 *)  begin BxAnother,  bx_cpu.OR_EdGd end;,
  (* 0A *)  begin BxAnother,  bx_cpu.OR_GbEb end;,
  (* 0B *)  begin BxAnother,  bx_cpu.OR_GdEd end;,
  (* 0C *)  begin BxImmediate_Ib,  bx_cpu.OR_ALIb end;,
  (* 0D *)  begin BxImmediate_Iv,  bx_cpu.OR_EAXId end;,
  (* 0E *)  begin 0,  bx_cpu.PUSH_CS end;,
  (* 0F *)  begin BxAnother,  bx_cpu.BxError end;, // 2-byte escape
  (* 10 *)  begin BxAnother,  bx_cpu.ADC_EbGb end;,
  (* 11 *)  begin BxAnother,  bx_cpu.ADC_EdGd end;,
  (* 12 *)  begin BxAnother,  bx_cpu.ADC_GbEb end;,
  (* 13 *)  begin BxAnother,  bx_cpu.ADC_GdEd end;,
  (* 14 *)  begin BxImmediate_Ib,  bx_cpu.ADC_ALIb end;,
  (* 15 *)  begin BxImmediate_Iv,  bx_cpu.ADC_EAXId end;,
  (* 16 *)  begin 0,  bx_cpu.PUSH_SS end;,
  (* 17 *)  begin 0,  bx_cpu.POP_SS end;,
  (* 18 *)  begin BxAnother,  bx_cpu.SBB_EbGb end;,
  (* 19 *)  begin BxAnother,  bx_cpu.SBB_EdGd end;,
  (* 1A *)  begin BxAnother,  bx_cpu.SBB_GbEb end;,
  (* 1B *)  begin BxAnother,  bx_cpu.SBB_GdEd end;,
  (* 1C *)  begin BxImmediate_Ib,  bx_cpu.SBB_ALIb end;,
  (* 1D *)  begin BxImmediate_Iv,  bx_cpu.SBB_EAXId end;,
  (* 1E *)  begin 0,  bx_cpu.PUSH_DS end;,
  (* 1F *)  begin 0,  bx_cpu.POP_DS end;,
  (* 20 *)  begin BxAnother,  bx_cpu.AND_EbGb end;,
  (* 21 *)  begin BxAnother,  bx_cpu.AND_EdGd end;,
  (* 22 *)  begin BxAnother,  bx_cpu.AND_GbEb end;,
  (* 23 *)  begin BxAnother,  bx_cpu.AND_GdEd end;,
  (* 24 *)  begin BxImmediate_Ib,  bx_cpu.AND_ALIb end;,
  (* 25 *)  begin BxImmediate_Iv,  bx_cpu.AND_EAXId end;,
  (* 26 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // ES:
  (* 27 *)  begin 0,  bx_cpu.DAA end;,
  (* 28 *)  begin BxAnother,  bx_cpu.SUB_EbGb end;,
  (* 29 *)  begin BxAnother,  bx_cpu.SUB_EdGd end;,
  (* 2A *)  begin BxAnother,  bx_cpu.SUB_GbEb end;,
  (* 2B *)  begin BxAnother,  bx_cpu.SUB_GdEd end;,
  (* 2C *)  begin BxImmediate_Ib,  bx_cpu.SUB_ALIb end;,
  (* 2D *)  begin BxImmediate_Iv,  bx_cpu.SUB_EAXId end;,
  (* 2E *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // CS:
  (* 2F *)  begin 0,  bx_cpu.DAS end;,
  (* 30 *)  begin BxAnother,  bx_cpu.XOR_EbGb end;,
  (* 31 *)  begin BxAnother,  bx_cpu.XOR_EdGd end;,
  (* 32 *)  begin BxAnother,  bx_cpu.XOR_GbEb end;,
  (* 33 *)  begin BxAnother,  bx_cpu.XOR_GdEd end;,
  (* 34 *)  begin BxImmediate_Ib,  bx_cpu.XOR_ALIb end;,
  (* 35 *)  begin BxImmediate_Iv,  bx_cpu.XOR_EAXId end;,
  (* 36 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // SS:
  (* 37 *)  begin 0,  bx_cpu.AAA end;,
  (* 38 *)  begin BxAnother,  bx_cpu.CMP_EbGb end;,
  (* 39 *)  begin BxAnother,  bx_cpu.CMP_EdGd end;,
  (* 3A *)  begin BxAnother,  bx_cpu.CMP_GbEb end;,
  (* 3B *)  begin BxAnother,  bx_cpu.CMP_GdEd end;,
  (* 3C *)  begin BxImmediate_Ib,  bx_cpu.CMP_ALIb end;,
  (* 3D *)  begin BxImmediate_Iv,  bx_cpu.CMP_EAXId end;,
  (* 3E *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // DS:
  (* 3F *)  begin 0,  bx_cpu.AAS end;,
  (* 40 *)  begin 0,  bx_cpu.INC_ERX end;,
  (* 41 *)  begin 0,  bx_cpu.INC_ERX end;,
  (* 42 *)  begin 0,  bx_cpu.INC_ERX end;,
  (* 43 *)  begin 0,  bx_cpu.INC_ERX end;,
  (* 44 *)  begin 0,  bx_cpu.INC_ERX end;,
  (* 45 *)  begin 0,  bx_cpu.INC_ERX end;,
  (* 46 *)  begin 0,  bx_cpu.INC_ERX end;,
  (* 47 *)  begin 0,  bx_cpu.INC_ERX end;,
  (* 48 *)  begin 0,  bx_cpu.DEC_ERX end;,
  (* 49 *)  begin 0,  bx_cpu.DEC_ERX end;,
  (* 4A *)  begin 0,  bx_cpu.DEC_ERX end;,
  (* 4B *)  begin 0,  bx_cpu.DEC_ERX end;,
  (* 4C *)  begin 0,  bx_cpu.DEC_ERX end;,
  (* 4D *)  begin 0,  bx_cpu.DEC_ERX end;,
  (* 4E *)  begin 0,  bx_cpu.DEC_ERX end;,
  (* 4F *)  begin 0,  bx_cpu.DEC_ERX end;,
  (* 50 *)  begin 0,  bx_cpu.PUSH_ERX end;,
  (* 51 *)  begin 0,  bx_cpu.PUSH_ERX end;,
  (* 52 *)  begin 0,  bx_cpu.PUSH_ERX end;,
  (* 53 *)  begin 0,  bx_cpu.PUSH_ERX end;,
  (* 54 *)  begin 0,  bx_cpu.PUSH_ERX end;,
  (* 55 *)  begin 0,  bx_cpu.PUSH_ERX end;,
  (* 56 *)  begin 0,  bx_cpu.PUSH_ERX end;,
  (* 57 *)  begin 0,  bx_cpu.PUSH_ERX end;,
  (* 58 *)  begin 0,  bx_cpu.POP_ERX end;,
  (* 59 *)  begin 0,  bx_cpu.POP_ERX end;,
  (* 5A *)  begin 0,  bx_cpu.POP_ERX end;,
  (* 5B *)  begin 0,  bx_cpu.POP_ERX end;,
  (* 5C *)  begin 0,  bx_cpu.POP_ERX end;,
  (* 5D *)  begin 0,  bx_cpu.POP_ERX end;,
  (* 5E *)  begin 0,  bx_cpu.POP_ERX end;,
  (* 5F *)  begin 0,  bx_cpu.POP_ERX end;,
  (* 60 *)  begin 0,  bx_cpu.PUSHAD32 end;,
  (* 61 *)  begin 0,  bx_cpu.POPAD32 end;,
  (* 62 *)  begin BxAnother,  bx_cpu.BOUND_GvMa end;,
  (* 63 *)  begin BxAnother,  bx_cpu.ARPL_EwGw end;,
  (* 64 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // FS:
  (* 65 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // GS:
  (* 66 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // OS:
  (* 67 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // AS:
  (* 68 *)  begin BxImmediate_Iv,  bx_cpu.PUSH_Id end;,
  (* 69 *)  begin BxAnotherorBxImmediate_Iv,  bx_cpu.IMUL_GdEdId end;,
  (* 6A *)  begin BxImmediate_Ib_SE,  bx_cpu.PUSH_Id end;,
  (* 6B *)  begin BxAnotherorBxImmediate_Ib_SE,  bx_cpu.IMUL_GdEdId end;,
  (* 6C *)  begin BxRepeatable,  bx_cpu.INSB_YbDX end;,
  (* 6D *)  begin BxRepeatable,  bx_cpu.INSW_YvDX end;,
  (* 6E *)  begin BxRepeatable,  bx_cpu.OUTSB_DXXb end;,
  (* 6F *)  begin BxRepeatable,  bx_cpu.OUTSW_DXXv end;,
  (* 70 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 71 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 72 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 73 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 74 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 75 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 76 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 77 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 78 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 79 *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 7A *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 7B *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 7C *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 7D *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 7E *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 7F *)  begin BxImmediate_BrOff8,  bx_cpu.JCC_Jd end;,
  (* 80 *)  begin BxAnotherorBxGroup1,  NULL, BxOpcodeInfoG1EbIb end;,
  (* 81 *)  begin BxAnotherorBxGroup1orBxImmediate_Iv, NULL, BxOpcodeInfoG1Ed end;,
  (* 82 *)  begin BxAnotherorBxGroup1,  NULL, BxOpcodeInfoG1EbIb end;,
  (* 83 *)  begin BxAnotherorBxGroup1orBxImmediate_Ib_SE, NULL, BxOpcodeInfoG1Ed end;,
  (* 84 *)  begin BxAnother,  bx_cpu.TEST_EbGb end;,
  (* 85 *)  begin BxAnother,  bx_cpu.TEST_EdGd end;,
  (* 86 *)  begin BxAnother,  bx_cpu.XCHG_EbGb end;,
  (* 87 *)  begin BxAnother,  bx_cpu.XCHG_EdGd end;,
  (* 88 *)  begin BxAnother,  bx_cpu.MOV_EbGb end;,
  (* 89 *)  begin BxAnother,  bx_cpu.MOV_EdGd end;,
  (* 8A *)  begin BxAnother,  bx_cpu.MOV_GbEb end;,
  (* 8B *)  begin BxAnother,  bx_cpu.MOV_GdEd end;,
  (* 8C *)  begin BxAnother,  bx_cpu.MOV_EwSw end;,
  (* 8D *)  begin BxAnother,  bx_cpu.LEA_GdM end;,
  (* 8E *)  begin BxAnother,  bx_cpu.MOV_SwEw end;,
  (* 8F *)  begin BxAnother,  bx_cpu.POP_Ed end;,
  (* 90 *)  begin 0,  bx_cpu.NOP end;,
  (* 91 *)  begin 0,  bx_cpu.XCHG_ERXEAX end;,
  (* 92 *)  begin 0,  bx_cpu.XCHG_ERXEAX end;,
  (* 93 *)  begin 0,  bx_cpu.XCHG_ERXEAX end;,
  (* 94 *)  begin 0,  bx_cpu.XCHG_ERXEAX end;,
  (* 95 *)  begin 0,  bx_cpu.XCHG_ERXEAX end;,
  (* 96 *)  begin 0,  bx_cpu.XCHG_ERXEAX end;,
  (* 97 *)  begin 0,  bx_cpu.XCHG_ERXEAX end;,
  (* 98 *)  begin 0,  bx_cpu.CWDE end;,
  (* 99 *)  begin 0,  bx_cpu.CDQ end;,
  (* 9A *)  begin BxImmediate_IvIw,  bx_cpu.CALL32_Ap end;,
  (* 9B *)  begin 0,  bx_cpu.FWAIT end;,
  (* 9C *)  begin 0,  bx_cpu.PUSHF_Fv end;,
  (* 9D *)  begin 0,  bx_cpu.POPF_Fv end;,
  (* 9E *)  begin 0,  bx_cpu.SAHF end;,
  (* 9F *)  begin 0,  bx_cpu.LAHF end;,
  (* A0 *)  begin BxImmediate_O,  bx_cpu.MOV_ALOb end;,
  (* A1 *)  begin BxImmediate_O,  bx_cpu.MOV_EAXOd end;,
  (* A2 *)  begin BxImmediate_O,  bx_cpu.MOV_ObAL end;,
  (* A3 *)  begin BxImmediate_O,  bx_cpu.MOV_OdEAX end;,
  (* A4 *)  begin BxRepeatable,  bx_cpu.MOVSB_XbYb end;,
  (* A5 *)  begin BxRepeatable,  bx_cpu.MOVSW_XvYv end;,
  (* A6 *)  begin BxRepeatableorBxRepeatableZF,  bx_cpu.CMPSB_XbYb end;,
  (* A7 *)  begin BxRepeatableorBxRepeatableZF,  bx_cpu.CMPSW_XvYv end;,
  (* A8 *)  begin BxImmediate_Ib,  bx_cpu.TEST_ALIb end;,
  (* A9 *)  begin BxImmediate_Iv,  bx_cpu.TEST_EAXId end;,
  (* AA *)  begin BxRepeatable,  bx_cpu.STOSB_YbAL end;,
  (* AB *)  begin BxRepeatable,  bx_cpu.STOSW_YveAX end;,
  (* AC *)  begin BxRepeatable,  bx_cpu.LODSB_ALXb end;,
  (* AD *)  begin BxRepeatable,  bx_cpu.LODSW_eAXXv end;,
  (* AE *)  begin BxRepeatableorBxRepeatableZF,  bx_cpu.SCASB_ALXb end;,
  (* AF *)  begin BxRepeatableorBxRepeatableZF,  bx_cpu.SCASW_eAXXv end;,
  (* B0 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RLIb end;,
  (* B1 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RLIb end;,
  (* B2 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RLIb end;,
  (* B3 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RLIb end;,
  (* B4 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RHIb end;,
  (* B5 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RHIb end;,
  (* B6 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RHIb end;,
  (* B7 *)  begin BxImmediate_Ib,  bx_cpu.MOV_RHIb end;,
  (* B8 *)  begin BxImmediate_Iv,  bx_cpu.MOV_ERXId end;,
  (* B9 *)  begin BxImmediate_Iv,  bx_cpu.MOV_ERXId end;,
  (* BA *)  begin BxImmediate_Iv,  bx_cpu.MOV_ERXId end;,
  (* BB *)  begin BxImmediate_Iv,  bx_cpu.MOV_ERXId end;,
  (* BC *)  begin BxImmediate_Iv,  bx_cpu.MOV_ERXId end;,
  (* BD *)  begin BxImmediate_Iv,  bx_cpu.MOV_ERXId end;,
  (* BE *)  begin BxImmediate_Iv,  bx_cpu.MOV_ERXId end;,
  (* BF *)  begin BxImmediate_Iv,  bx_cpu.MOV_ERXId end;,
  (* C0 *)  begin BxAnotherorBxGroup2orBxImmediate_Ib, NULL, BxOpcodeInfoG2Eb end;,
  (* C1 *)  begin BxAnotherorBxGroup2orBxImmediate_Ib, NULL, BxOpcodeInfoG2Ed end;,
  (* C2 *)  begin BxImmediate_Iw,  bx_cpu.RETnear32_Iw end;,
  (* C3 *)  begin 0,             bx_cpu.RETnear32 end;,
  (* C4 *)  begin BxAnother,  bx_cpu.LES_GvMp end;,
  (* C5 *)  begin BxAnother,  bx_cpu.LDS_GvMp end;,
  (* C6 *)  begin BxAnotherorBxImmediate_Ib,  bx_cpu.MOV_EbIb end;,
  (* C7 *)  begin BxAnotherorBxImmediate_Iv,  bx_cpu.MOV_EdId end;,
  (* C8 *)  begin BxImmediate_IwIb,  bx_cpu.ENTER_IwIb end;,
  (* C9 *)  begin 0,  bx_cpu.LEAVE end;,
  (* CA *)  begin BxImmediate_Iw,  bx_cpu.RETfar32_Iw end;,
  (* CB *)  begin 0,  bx_cpu.RETfar32 end;,
  (* CC *)  begin 0,  bx_cpu.INT3 end;,
  (* CD *)  begin BxImmediate_Ib,  bx_cpu.INT_Ib end;,
  (* CE *)  begin 0,  bx_cpu.INTO end;,
  (* CF *)  begin 0,  bx_cpu.IRET32 end;,
  (* D0 *)  begin BxAnotherorBxGroup2,  NULL, BxOpcodeInfoG2Eb end;,
  (* D1 *)  begin BxAnotherorBxGroup2,  NULL, BxOpcodeInfoG2Ed end;,
  (* D2 *)  begin BxAnotherorBxGroup2,  NULL, BxOpcodeInfoG2Eb end;,
  (* D3 *)  begin BxAnotherorBxGroup2,  NULL, BxOpcodeInfoG2Ed end;,
  (* D4 *)  begin BxImmediate_Ib,  bx_cpu.AAM end;,
  (* D5 *)  begin BxImmediate_Ib,  bx_cpu.AAD end;,
  (* D6 *)  begin 0,  bx_cpu.SALC end;,
  (* D7 *)  begin 0,  bx_cpu.XLAT end;,
  (* D8 *)  begin BxAnother,  bx_cpu.ESC0 end;,
  (* D9 *)  begin BxAnother,  bx_cpu.ESC1 end;,
  (* DA *)  begin BxAnother,  bx_cpu.ESC2 end;,
  (* DB *)  begin BxAnother,  bx_cpu.ESC3 end;,
  (* DC *)  begin BxAnother,  bx_cpu.ESC4 end;,
  (* DD *)  begin BxAnother,  bx_cpu.ESC5 end;,
  (* DE *)  begin BxAnother,  bx_cpu.ESC6 end;,
  (* DF *)  begin BxAnother,  bx_cpu.ESC7 end;,
  (* E0 *)  begin BxImmediate_BrOff8,  bx_cpu.LOOPNE_Jb end;,
  (* E1 *)  begin BxImmediate_BrOff8,  bx_cpu.LOOPE_Jb end;,
  (* E2 *)  begin BxImmediate_BrOff8,  bx_cpu.LOOP_Jb end;,
  (* E3 *)  begin BxImmediate_BrOff8,  bx_cpu.JCXZ_Jb end;,
  (* E4 *)  begin BxImmediate_Ib,  bx_cpu.IN_ALIb end;,
  (* E5 *)  begin BxImmediate_Ib,  bx_cpu.IN_eAXIb end;,
  (* E6 *)  begin BxImmediate_Ib,  bx_cpu.OUT_IbAL end;,
  (* E7 *)  begin BxImmediate_Ib,  bx_cpu.OUT_IbeAX end;,
  (* E8 *)  begin BxImmediate_BrOff32,  bx_cpu.CALL_Ad end;,
  (* E9 *)  begin BxImmediate_BrOff32,  bx_cpu.JMP_Jd end;,
  (* EA *)  begin BxImmediate_IvIw,  bx_cpu.JMP_Ap end;,
  (* EB *)  begin BxImmediate_BrOff8,  bx_cpu.JMP_Jd end;,
  (* EC *)  begin 0,  bx_cpu.IN_ALDX end;,
  (* ED *)  begin 0,  bx_cpu.IN_eAXDX end;,
  (* EE *)  begin 0,  bx_cpu.OUT_DXAL end;,
  (* EF *)  begin 0,  bx_cpu.OUT_DXeAX end;,
  (* F0 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // LOCK:
  (* F1 *)  begin 0,  bx_cpu.INT1 end;,
  (* F2 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // REPNE/REPNZ
  (* F3 *)  begin BxPrefixorBxAnother,  bx_cpu.BxError end;, // REP,REPE/REPZ
  (* F4 *)  begin 0,  bx_cpu.HLT end;,
  (* F5 *)  begin 0,  bx_cpu.CMC end;,
  (* F6 *)  begin BxAnotherorBxGroup3,  NULL, BxOpcodeInfoG3Eb end;,
  (* F7 *)  begin BxAnotherorBxGroup3,  NULL, BxOpcodeInfoG3Ed end;,
  (* F8 *)  begin 0,  bx_cpu.CLC end;,
  (* F9 *)  begin 0,  bx_cpu.STC end;,
  (* FA *)  begin 0,  bx_cpu.CLI end;,
  (* FB *)  begin 0,  bx_cpu.STI end;,
  (* FC *)  begin 0,  bx_cpu.CLD end;,
  (* FD *)  begin 0,  bx_cpu.STD end;,
  (* FE *)  begin BxAnotherorBxGroup4,  NULL, BxOpcodeInfoG4 end;,
  (* FF *)  begin BxAnotherorBxGroup5,  NULL, BxOpcodeInfoG5d end;,

  (* 0F 00 *)  begin BxAnotherorBxGroup6,  NULL, BxOpcodeInfoG6 end;,
  (* 0F 01 *)  begin BxAnotherorBxGroup7,  NULL, BxOpcodeInfoG7 end;,
  (* 0F 02 *)  begin BxAnother,  bx_cpu.LAR_GvEw end;,
  (* 0F 03 *)  begin BxAnother,  bx_cpu.LSL_GvEw end;,
  (* 0F 04 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 05 *)  begin 0,  bx_cpu.LOADALL end;,
  (* 0F 06 *)  begin 0,  bx_cpu.CLTS end;,
  (* 0F 07 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 08 *)  begin 0,  bx_cpu.INVD end;,
  (* 0F 09 *)  begin 0,  bx_cpu.WBINVD end;,
  (* 0F 0A *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 0B *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 0C *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 0D *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 0E *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 0F *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 10 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 11 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 12 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 13 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 14 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 15 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 16 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 17 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 18 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 19 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 1A *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 1B *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 1C *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 1D *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 1E *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 1F *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 20 *)  begin BxAnother,  bx_cpu.MOV_RdCd end;,
  (* 0F 21 *)  begin BxAnother,  bx_cpu.MOV_RdDd end;,
  (* 0F 22 *)  begin BxAnother,  bx_cpu.MOV_CdRd end;,
  (* 0F 23 *)  begin BxAnother,  bx_cpu.MOV_DdRd end;,
  (* 0F 24 *)  begin BxAnother,  bx_cpu.MOV_RdTd end;,
  (* 0F 25 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 26 *)  begin BxAnother,  bx_cpu.MOV_TdRd end;,
  (* 0F 27 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 28 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 29 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 2A *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 2B *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 2C *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 2D *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 2E *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 2F *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 30 *)  begin 0,  bx_cpu.WRMSR end;,
  (* 0F 31 *)  begin 0,  bx_cpu.RDTSC end;,
  (* 0F 32 *)  begin 0,  bx_cpu.RDMSR end;,
  (* 0F 33 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 34 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 35 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 36 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 37 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 38 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 39 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 3A *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 3B *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 3C *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 3D *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 3E *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 3F *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 40 *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 41 *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 42 *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 43 *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 44 *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 45 *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 46 *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 47 *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 48 *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 49 *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 4A *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 4B *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 4C *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 4D *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 4E *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 4F *)  begin BxAnother,  bx_cpu.CMOV_GdEd end;,
  (* 0F 50 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 51 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 52 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 53 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 54 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 55 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 56 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 57 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 58 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 59 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 5A *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 5B *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 5C *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 5D *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 5E *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 5F *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 60 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 61 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 62 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 63 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 64 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 65 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 66 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 67 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 68 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 69 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 6A *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 6B *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 6C *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 6D *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 6E *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 6F *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 70 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 71 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 72 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 73 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 74 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 75 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 76 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 77 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 78 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 79 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 7A *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 7B *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 7C *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 7D *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 7E *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 7F *)  begin 0,  bx_cpu.BxError end;,
  (* 0F 80 *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 81 *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 82 *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 83 *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 84 *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 85 *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 86 *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 87 *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 88 *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 89 *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 8A *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 8B *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 8C *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 8D *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 8E *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 8F *)  begin BxImmediate_BrOff32,  bx_cpu.JCC_Jd end;,
  (* 0F 90 *)  begin BxAnother,  bx_cpu.SETO_Eb end;,
  (* 0F 91 *)  begin BxAnother,  bx_cpu.SETNO_Eb end;,
  (* 0F 92 *)  begin BxAnother,  bx_cpu.SETB_Eb end;,
  (* 0F 93 *)  begin BxAnother,  bx_cpu.SETNB_Eb end;,
  (* 0F 94 *)  begin BxAnother,  bx_cpu.SETZ_Eb end;,
  (* 0F 95 *)  begin BxAnother,  bx_cpu.SETNZ_Eb end;,
  (* 0F 96 *)  begin BxAnother,  bx_cpu.SETBE_Eb end;,
  (* 0F 97 *)  begin BxAnother,  bx_cpu.SETNBE_Eb end;,
  (* 0F 98 *)  begin BxAnother,  bx_cpu.SETS_Eb end;,
  (* 0F 99 *)  begin BxAnother,  bx_cpu.SETNS_Eb end;,
  (* 0F 9A *)  begin BxAnother,  bx_cpu.SETP_Eb end;,
  (* 0F 9B *)  begin BxAnother,  bx_cpu.SETNP_Eb end;,
  (* 0F 9C *)  begin BxAnother,  bx_cpu.SETL_Eb end;,
  (* 0F 9D *)  begin BxAnother,  bx_cpu.SETNL_Eb end;,
  (* 0F 9E *)  begin BxAnother,  bx_cpu.SETLE_Eb end;,
  (* 0F 9F *)  begin BxAnother,  bx_cpu.SETNLE_Eb end;,
  (* 0F A0 *)  begin 0,  bx_cpu.PUSH_FS end;,
  (* 0F A1 *)  begin 0,  bx_cpu.POP_FS end;,
  (* 0F A2 *)  begin 0,  bx_cpu.CPUID end;,
  (* 0F A3 *)  begin BxAnother,  bx_cpu.BT_EvGv end;,
  (* 0F A4 *)  begin BxAnotherorBxImmediate_Ib,  bx_cpu.SHLD_EdGd end;,
  (* 0F A5 *)  begin BxAnother,                 bx_cpu.SHLD_EdGd end;,
  (* 0F A6 *)  begin 0,  bx_cpu.CMPXCHG_XBTS end;,
  (* 0F A7 *)  begin 0,  bx_cpu.CMPXCHG_IBTS end;,
  (* 0F A8 *)  begin 0,  bx_cpu.PUSH_GS end;,
  (* 0F A9 *)  begin 0,  bx_cpu.POP_GS end;,
  (* 0F AA *)  begin 0,  bx_cpu.RSM end;,
  (* 0F AB *)  begin BxAnother,  bx_cpu.BTS_EvGv end;,
  (* 0F AC *)  begin BxAnotherorBxImmediate_Ib,  bx_cpu.SHRD_EdGd end;,
  (* 0F AD *)  begin BxAnother,                 bx_cpu.SHRD_EdGd end;,
  (* 0F AE *)  begin 0,  bx_cpu.BxError end;,
  (* 0F AF *)  begin BxAnother,  bx_cpu.IMUL_GdEd end;,
  (* 0F B0 *)  begin BxAnother,  bx_cpu.CMPXCHG_EbGb end;,
  (* 0F B1 *)  begin BxAnother,  bx_cpu.CMPXCHG_EdGd end;,
  (* 0F B2 *)  begin BxAnother,  bx_cpu.LSS_GvMp end;,
  (* 0F B3 *)  begin BxAnother,  bx_cpu.BTR_EvGv end;,
  (* 0F B4 *)  begin BxAnother,  bx_cpu.LFS_GvMp end;,
  (* 0F B5 *)  begin BxAnother,  bx_cpu.LGS_GvMp end;,
  (* 0F B6 *)  begin BxAnother,  bx_cpu.MOVZX_GdEb end;,
  (* 0F B7 *)  begin BxAnother,  bx_cpu.MOVZX_GdEw end;,
  (* 0F B8 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F B9 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F BA *)  begin BxAnotherorBxGroup8,  NULL, BxOpcodeInfoG8EvIb end;,
  (* 0F BB *)  begin BxAnother,  bx_cpu.BTC_EvGv end;,
  (* 0F BC *)  begin BxAnother,  bx_cpu.BSF_GvEv end;,
  (* 0F BD *)  begin BxAnother,  bx_cpu.BSR_GvEv end;,
  (* 0F BE *)  begin BxAnother,  bx_cpu.MOVSX_GdEb end;,
  (* 0F BF *)  begin BxAnother,  bx_cpu.MOVSX_GdEw end;,
  (* 0F C0 *)  begin BxAnother,  bx_cpu.XADD_EbGb end;,
  (* 0F C1 *)  begin BxAnother,  bx_cpu.XADD_EdGd end;,
  (* 0F C2 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F C3 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F C4 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F C5 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F C6 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F C7 *)  begin BxAnotherorBxGroup9,  NULL, BxOpcodeInfoG9 end;,
  (* 0F C8 *)  begin 0,  bx_cpu.BSWAP_EAX end;,
  (* 0F C9 *)  begin 0,  bx_cpu.BSWAP_ECX end;,
  (* 0F CA *)  begin 0,  bx_cpu.BSWAP_EDX end;,
  (* 0F CB *)  begin 0,  bx_cpu.BSWAP_EBX end;,
  (* 0F CC *)  begin 0,  bx_cpu.BSWAP_ESP end;,
  (* 0F CD *)  begin 0,  bx_cpu.BSWAP_EBP end;,
  (* 0F CE *)  begin 0,  bx_cpu.BSWAP_ESI end;,
  (* 0F CF *)  begin 0,  bx_cpu.BSWAP_EDI end;,
  (* 0F D0 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D1 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D2 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D3 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D4 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D5 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D6 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D7 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D8 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F D9 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F DA *)  begin 0,  bx_cpu.BxError end;,
  (* 0F DB *)  begin 0,  bx_cpu.BxError end;,
  (* 0F DC *)  begin 0,  bx_cpu.BxError end;,
  (* 0F DD *)  begin 0,  bx_cpu.BxError end;,
  (* 0F DE *)  begin 0,  bx_cpu.BxError end;,
  (* 0F DF *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E0 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E1 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E2 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E3 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E4 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E5 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E6 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E7 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E8 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F E9 *)  begin 0,  bx_cpu.BxError end;,
  (* 0F EA *)  begin 0,  bx_cpu.BxError end;,
  (* 0F EB *)  begin 0,  bx_cpu.BxError end;,
  (* 0F EC *)  begin 0,  bx_cpu.BxError end;,
  (* 0F ED *)  begin 0,  bx_cpu.BxError end;,
  (* 0F EE *)  begin 0,  bx_cpu.BxError end;,
  (* 0F EF *)  begin 0,  bx_cpu.BxError end;,
  (* 0F F0 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F1 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F2 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F3 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F4 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F5 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F6 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F7 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F8 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F F9 *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F FA *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F FB *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F FC *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F FD *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F FE *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  (* 0F FF *)  begin 0,  bx_cpu.UndefinedOpcode end;,
  end;;




  unsigned
BX_CPU_C.FetchDecode(Bit8u *iptr, BxInstruction_t *instruction,
                      unsigned remain, Boolean is_32)
begin
  // remain must be at least 1

  unsigned b1, b2, ilen:=1, attr;
  unsigned imm_mod_e, offset;

  instruction^.os_32 := instruction^.as_32 := is_32;
  instruction^.Resolvemod_rm := NULL;
  instruction^.seg := BX_SEG_REG_NULL;
  instruction^.rep_used := 0;


fetch_b1:
  b1 := *iptr++;

another_byte:
  offset := instruction^.os_32 shl 9; // * 512
  instruction^.attr := attr := BxOpcodeInfo[b1+offset].Attr;

  if Boolean(attr  and BxAnother) then begin
    if Boolean(attr  and BxPrefix) then begin
      switch (b1) then begin
        case $66: // OpSize
          instruction^.os_32 := !is_32;
          if Boolean(ilen < remain) then begin
            ilen++;
            goto fetch_b1;
            end;
          return(0);

        case $67: // AddrSize
          instruction^.as_32 := !is_32;
          if Boolean(ilen < remain) then begin
            ilen++;
            goto fetch_b1;
            end;
          return(0);

        case $f2: // REPNE/REPNZ
        case $f3: // REP/REPE/REPZ
          instruction^.rep_used := b1;
          if Boolean(ilen < remain) then begin
            ilen++;
            goto fetch_b1;
            end;
          return(0);
          break;

        case $2e: // CS:
          instruction^.seg := BX_SEG_REG_CS;
          ilen++; goto fetch_b1;
          break;
        case $26: // ES:
          instruction^.seg := BX_SEG_REG_ES;
          ilen++; goto fetch_b1;
          break;
        case $36: // SS:
          instruction^.seg := BX_SEG_REG_SS;
          ilen++; goto fetch_b1;
          break;
        case $3e: // DS:
          instruction^.seg := BX_SEG_REG_DS;
          ilen++; goto fetch_b1;
          break;
        case $64: // FS:
          instruction^.seg := BX_SEG_REG_FS;
          ilen++; goto fetch_b1;
          break;
        case $65: // GS:
          instruction^.seg := BX_SEG_REG_GS;
          ilen++; goto fetch_b1;
          break;
        case $f0: // LOCK:
          ilen++; goto fetch_b1;
          break;

        default:
BX_PANIC(('fetch_decode: prefix default := $%02x', b1));
        end;
      end;
    // opcode requires another byte
    if Boolean(ilen < remain) then begin
      ilen++;
      b2 := *iptr++;
      if Boolean(b1 = $0f) then begin
        // 2-byte prefix
        b1 := $100orb2;
        goto another_byte;
        end;
      end
  else
      return(0);

    // Parse mod_-nnn-rm and related bytes
    unsigned rm;
    instruction^.mod_rm := b2;
    rm :=
    instruction^.rm    := b2  and $07;
    instruction^.mod_   := b2  and $c0; // leave unshifted
    instruction^.nnn   := (b2 shr 3)  and 0
