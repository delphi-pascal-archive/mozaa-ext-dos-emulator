{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)


(* the device id and stepping id are loaded into DH  and DL upon processor
   startup.  for device id: 3 := 80386, 4 := 80486.  just make up a
   number for the stepping (revision) id. *)
const
  BX_DEVICE_ID    = 3;
  BX_STEPPING_ID  = 0;

procedure BX_CPU_C.init(addrspace:BX_MEM_C);
begin
  BX_DEBUG(( 'Init $Id: init.cc,v 1.15 2002/03/27 16:04:05 bdenney Exp $'));
  // BX_CPU_C constructor
  Self.set_INTR(0);
  // in SMP mod_e, the prefix of the CPU will be changed to [CPUn] in
  // bx_local_apic_c.set_id as soon as the apic ID is assigned.

  (* hack for the following fields.  Its easier to decode mod_-rm bytes if
     you can assume there's always a base  and index register used.  For
     mod_es which don't really use them, point to an empty (zeroed) register.
   *)
  empty_register := 0;

  // 16bit address mod_e base register, used for mod_-rm decoding

  _16bit_base_reg[0] := @gen_reg[BX_16BIT_REG_BX].rx;
  _16bit_base_reg[1] := @gen_reg[BX_16BIT_REG_BX].rx;
  _16bit_base_reg[2] := @gen_reg[BX_16BIT_REG_BP].rx;
  _16bit_base_reg[3] := @gen_reg[BX_16BIT_REG_BP].rx;
  _16bit_base_reg[4] := PBit16u(@empty_register);
  _16bit_base_reg[5] := PBit16u(@empty_register);
  _16bit_base_reg[6] := @gen_reg[BX_16BIT_REG_BP].rx;
  _16bit_base_reg[7] := @gen_reg[BX_16BIT_REG_BX].rx;

  // 16bit address mod_e index register, used for mod_-rm decoding
  _16bit_index_reg[0] := @gen_reg[BX_16BIT_REG_SI].rx;
  _16bit_index_reg[1] := @gen_reg[BX_16BIT_REG_DI].rx;
  _16bit_index_reg[2] := @gen_reg[BX_16BIT_REG_SI].rx;
  _16bit_index_reg[3] := @gen_reg[BX_16BIT_REG_DI].rx;
  _16bit_index_reg[4] := @gen_reg[BX_16BIT_REG_SI].rx;
  _16bit_index_reg[5] := @gen_reg[BX_16BIT_REG_DI].rx;
  _16bit_index_reg[6] := PBit16u(@empty_register);
  _16bit_index_reg[7] := PBit16u(@empty_register);

  // for decoding instructions: access to seg reg's via index number
  sreg_mod00_rm16[0] := BX_SEG_REG_DS;
  sreg_mod00_rm16[1] := BX_SEG_REG_DS;
  sreg_mod00_rm16[2] := BX_SEG_REG_SS;
  sreg_mod00_rm16[3] := BX_SEG_REG_SS;
  sreg_mod00_rm16[4] := BX_SEG_REG_DS;
  sreg_mod00_rm16[5] := BX_SEG_REG_DS;
  sreg_mod00_rm16[6] := BX_SEG_REG_DS;
  sreg_mod00_rm16[7] := BX_SEG_REG_DS;

  sreg_mod01_rm16[0] := BX_SEG_REG_DS;
  sreg_mod01_rm16[1] := BX_SEG_REG_DS;
  sreg_mod01_rm16[2] := BX_SEG_REG_SS;
  sreg_mod01_rm16[3] := BX_SEG_REG_SS;
  sreg_mod01_rm16[4] := BX_SEG_REG_DS;
  sreg_mod01_rm16[5] := BX_SEG_REG_DS;
  sreg_mod01_rm16[6] := BX_SEG_REG_SS;
  sreg_mod01_rm16[7] := BX_SEG_REG_DS;

  sreg_mod10_rm16[0] := BX_SEG_REG_DS;
  sreg_mod10_rm16[1] := BX_SEG_REG_DS;
  sreg_mod10_rm16[2] := BX_SEG_REG_SS;
  sreg_mod10_rm16[3] := BX_SEG_REG_SS;
  sreg_mod10_rm16[4] := BX_SEG_REG_DS;
  sreg_mod10_rm16[5] := BX_SEG_REG_DS;
  sreg_mod10_rm16[6] := BX_SEG_REG_SS;
  sreg_mod10_rm16[7] := BX_SEG_REG_DS;

  // the default segment to use for a one-byte mod_rm with mod_=01b
  // and rm=i
  //
  sreg_mod01_rm32[0] := BX_SEG_REG_DS;
  sreg_mod01_rm32[1] := BX_SEG_REG_DS;
  sreg_mod01_rm32[2] := BX_SEG_REG_DS;
  sreg_mod01_rm32[3] := BX_SEG_REG_DS;
  sreg_mod01_rm32[4] := BX_SEG_REG_NULL;
    // this entry should never be accessed
    // (escape to 2-byte)
  sreg_mod01_rm32[5] := BX_SEG_REG_SS;
  sreg_mod01_rm32[6] := BX_SEG_REG_DS;
  sreg_mod01_rm32[7] := BX_SEG_REG_DS;

  // the default segment to use for a one-byte mod_rm with mod_=10b
  // and rm=i
  //
  sreg_mod10_rm32[0] := BX_SEG_REG_DS;
  sreg_mod10_rm32[1] := BX_SEG_REG_DS;
  sreg_mod10_rm32[2] := BX_SEG_REG_DS;
  sreg_mod10_rm32[3] := BX_SEG_REG_DS;
  sreg_mod10_rm32[4] := BX_SEG_REG_NULL;
    // this entry should never be accessed
    // (escape to 2-byte)
  sreg_mod10_rm32[5] := BX_SEG_REG_SS;
  sreg_mod10_rm32[6] := BX_SEG_REG_DS;
  sreg_mod10_rm32[7] := BX_SEG_REG_DS;


  // the default segment to use for a two-byte mod_rm with mod_=00b
  // and base=i
  //
  sreg_mod0_base32[0] := BX_SEG_REG_DS;
  sreg_mod0_base32[1] := BX_SEG_REG_DS;
  sreg_mod0_base32[2] := BX_SEG_REG_DS;
  sreg_mod0_base32[3] := BX_SEG_REG_DS;
  sreg_mod0_base32[4] := BX_SEG_REG_SS;
  sreg_mod0_base32[5] := BX_SEG_REG_DS;
  sreg_mod0_base32[6] := BX_SEG_REG_DS;
  sreg_mod0_base32[7] := BX_SEG_REG_DS;

  // the default segment to use for a two-byte mod_rm with
  // mod_=01b or mod_=10b and base=i
  sreg_mod1or2_base32[0] := BX_SEG_REG_DS;
  sreg_mod1or2_base32[1] := BX_SEG_REG_DS;
  sreg_mod1or2_base32[2] := BX_SEG_REG_DS;
  sreg_mod1or2_base32[3] := BX_SEG_REG_DS;
  sreg_mod1or2_base32[4] := BX_SEG_REG_SS;
  sreg_mod1or2_base32[5] := BX_SEG_REG_SS;
  sreg_mod1or2_base32[6] := BX_SEG_REG_DS;
  sreg_mod1or2_base32[7] := BX_SEG_REG_DS;

{$if BX_DYNAMIC_TRANSLATION <> 0}
  DTWrite8vShim := NULL;
  DTWrite16vShim := NULL;
  DTWrite32vShim := NULL;
  DTRead8vShim := NULL;
  DTRead16vShim := NULL;
  DTRead32vShim := NULL;
  DTReadRMW8vShim := (BxDTShim_t) DTASReadRMW8vShim;
  BX_DEBUG(( 'DTReadRMW8vShim is %x', (unsigned) DTReadRMW8vShim ));
  BX_DEBUG(( '@DTReadRMW8vShim is %x', (unsigned) @DTReadRMW8vShim ));
  DTReadRMW16vShim := NULL;
  DTReadRMW32vShim := NULL;
  DTWriteRMW8vShim := (BxDTShim_t) DTASWriteRMW8vShim;
  DTWriteRMW16vShim := NULL;
  DTWriteRMW32vShim := NULL;
  DTSetFlagsOSZAPCPtr := (BxDTShim_t) DTASSetFlagsOSZAPC;
  DTIndBrHandler := (BxDTShim_t) DTASIndBrHandler;
  DTDirBrHandler := (BxDTShim_t) DTASDirBrHandler;
{$ifend}

  //mem := addrspace;
  name:='CPU1';

  //BX_INSTR_INIT();
end;

procedure BX_CPU_C.reset(source:unsigned);
begin
  //UNUSED(source); // either BX_RESET_HARDWARE or BX_RESET_SOFTWARE

  // general registers
  EAX := 0; // processor passed test :-)
  EBX := 0; // undefined
  ECX := 0; // undefined
  EDX := (BX_DEVICE_ID shl 8) or BX_STEPPING_ID; // ???
  EBP := 0; // undefined
  ESI := 0; // undefined
  EDI := 0; // undefined
  ESP := 0; // undefined

  // all status flags at known values, use Self.eflags structure
  Self.lf_flags_status := $000000;
  Self.lf_pf := 0;

  // status and control flags register set
  Self.set_CF(0);
  Self.eflags.bit1 := 1;
  Self.set_PF(0);
  Self.eflags.bit3 := 0;
  Self.set_AF(0);
  Self.eflags.bit5 := 0;
  Self.set_ZF(0);
  Self.set_SF(0);
  Self.eflags.tf := 0;
  Self.eflags.if_ := 0;
  Self.eflags.df := 0;
  Self.set_OF(0);
{$if BX_CPU_LEVEL >= 2}
  Self.eflags.iopl := 0;
  Self.eflags.nt := 0;
{$ifend}
  Self.eflags.bit15 := 0;
{$if BX_CPU_LEVEL >= 3}
  Self.eflags.rf := 0;
  Self.eflags.vm := 0;
{$ifend}
{$if BX_CPU_LEVEL >= 4}
  Self.eflags.ac := 0;
{$ifend}

  Self.inhibit_mask := 0;
  Self.debug_trap := 0;

  (* instruction pointer *)
{$if BX_CPU_LEVEL < 2}
  Self.eip := $00000000;
  Self.prev_eip := Self.eip;
{$else} (* from 286 up *)
  Self.eip := $0000FFF0;
  Self.prev_eip := Self.eip;
{$ifend}


  (* CS (Code Segment) and descriptor cache *)
  (* Note: on a real cpu, CS initially points to upper memory.  After
   * the 1st jump, the descriptor base is zero'd out.  Since I'm just
   * going to jump to my BIOS, I don't need to do this.
   * For future reference:
   *   processor  cs_.selector   cs_.base    cs_.limit    EIP
   *        8086    FFFF          FFFF0        FFFF   0000
   *        286     F000         FF0000        FFFF   FFF0
   *        386+    F000       FFFF0000        FFFF   FFF0
   *)
  Self.sregs[BX_SEG_REG_CS].selector.value :=     $f000;
{$if BX_CPU_LEVEL >= 2}
  Self.sregs[BX_SEG_REG_CS].selector.index :=     $0000;
  Self.sregs[BX_SEG_REG_CS].selector.ti := 0;
  Self.sregs[BX_SEG_REG_CS].selector.rpl := 0;

  Self.sregs[BX_SEG_REG_CS].cache.valid :=     1;
  Self.sregs[BX_SEG_REG_CS].cache.p := 1;
  Self.sregs[BX_SEG_REG_CS].cache.dpl := 0;
  Self.sregs[BX_SEG_REG_CS].cache.segmentType := 1; (* data/code segment *)
  Self.sregs[BX_SEG_REG_CS].cache.type_ := 3; (* read/write access *)

  Self.sregs[BX_SEG_REG_CS].cache.segment.executable   := 1; (* data/stack segment *)
  Self.sregs[BX_SEG_REG_CS].cache.segment.c_ed         := 0; (* normal expand up *)
  Self.sregs[BX_SEG_REG_CS].cache.segment.r_w          := 1; (* writeable *)
  Self.sregs[BX_SEG_REG_CS].cache.segment.a            := 1; (* accessed *)
  Self.sregs[BX_SEG_REG_CS].cache.segment.base         := $000F0000;
  Self.sregs[BX_SEG_REG_CS].cache.segment.limit        :=     $FFFF;
  Self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled :=     $FFFF;
{$ifend}
{$if BX_CPU_LEVEL >= 3}
  Self.sregs[BX_SEG_REG_CS].cache.segment.g   := 0; (* byte granular *)
  Self.sregs[BX_SEG_REG_CS].cache.segment.d_b := 0; (* 16bit default size *)
  Self.sregs[BX_SEG_REG_CS].cache.segment.avl := 0;
{$ifend}


  (* SS (Stack Segment) and descriptor cache *)
  Self.sregs[BX_SEG_REG_SS].selector.value :=     $0000;
{$if BX_CPU_LEVEL >= 2}
  Self.sregs[BX_SEG_REG_SS].selector.index :=     $0000;
  Self.sregs[BX_SEG_REG_SS].selector.ti := 0;
  Self.sregs[BX_SEG_REG_SS].selector.rpl := 0;

  Self.sregs[BX_SEG_REG_SS].cache.valid :=     1;
  Self.sregs[BX_SEG_REG_SS].cache.p := 1;
  Self.sregs[BX_SEG_REG_SS].cache.dpl := 0;
  Self.sregs[BX_SEG_REG_SS].cache.segmentType := 1; (* data/code segment *)
  Self.sregs[BX_SEG_REG_SS].cache.type_ := 3; (* read/write access *)

  Self.sregs[BX_SEG_REG_SS].cache.segment.executable   := 0; (* data/stack segment *)
  Self.sregs[BX_SEG_REG_SS].cache.segment.c_ed         := 0; (* normal expand up *)
  Self.sregs[BX_SEG_REG_SS].cache.segment.r_w          := 1; (* writeable *)
  Self.sregs[BX_SEG_REG_SS].cache.segment.a            := 1; (* accessed *)
  Self.sregs[BX_SEG_REG_SS].cache.segment.base         := $00000000;
  Self.sregs[BX_SEG_REG_SS].cache.segment.limit        :=     $FFFF;
  Self.sregs[BX_SEG_REG_SS].cache.segment.limit_scaled :=     $FFFF;
{$ifend}
{$if BX_CPU_LEVEL >= 3}
  Self.sregs[BX_SEG_REG_SS].cache.segment.g   := 0; (* byte granular *)
  Self.sregs[BX_SEG_REG_SS].cache.segment.d_b := 0; (* 16bit default size *)
  Self.sregs[BX_SEG_REG_SS].cache.segment.avl := 0;
{$ifend}


  (* DS (Data Segment) and descriptor cache *)
  Self.sregs[BX_SEG_REG_DS].selector.value :=     $0000;
{$if BX_CPU_LEVEL >= 2}
  Self.sregs[BX_SEG_REG_DS].selector.index :=     $0000;
  Self.sregs[BX_SEG_REG_DS].selector.ti := 0;
  Self.sregs[BX_SEG_REG_DS].selector.rpl := 0;

  Self.sregs[BX_SEG_REG_DS].cache.valid :=     1;
  Self.sregs[BX_SEG_REG_DS].cache.p := 1;
  Self.sregs[BX_SEG_REG_DS].cache.dpl := 0;
  Self.sregs[BX_SEG_REG_DS].cache.segmentType := 1; (* data/code segment *)
  Self.sregs[BX_SEG_REG_DS].cache.type_ := 3; (* read/write access *)

  Self.sregs[BX_SEG_REG_DS].cache.segment.executable   := 0; (* data/stack segment *)
  Self.sregs[BX_SEG_REG_DS].cache.segment.c_ed         := 0; (* normal expand up *)
  Self.sregs[BX_SEG_REG_DS].cache.segment.r_w          := 1; (* writeable *)
  Self.sregs[BX_SEG_REG_DS].cache.segment.a            := 1; (* accessed *)
  Self.sregs[BX_SEG_REG_DS].cache.segment.base         := $00000000;
  Self.sregs[BX_SEG_REG_DS].cache.segment.limit        :=     $FFFF;
  Self.sregs[BX_SEG_REG_DS].cache.segment.limit_scaled :=     $FFFF;
{$ifend}
{$if BX_CPU_LEVEL >= 3}
  Self.sregs[BX_SEG_REG_DS].cache.segment.g   := 0; (* byte granular *)
  Self.sregs[BX_SEG_REG_DS].cache.segment.d_b := 0; (* 16bit default size *)
  Self.sregs[BX_SEG_REG_DS].cache.segment.avl := 0;
{$ifend}


  (* ES (Extra Segment) and descriptor cache *)
  Self.sregs[BX_SEG_REG_ES].selector.value :=     $0000;
{$if BX_CPU_LEVEL >= 2}
  Self.sregs[BX_SEG_REG_ES].selector.index :=     $0000;
  Self.sregs[BX_SEG_REG_ES].selector.ti := 0;
  Self.sregs[BX_SEG_REG_ES].selector.rpl := 0;

  Self.sregs[BX_SEG_REG_ES].cache.valid :=     1;
  Self.sregs[BX_SEG_REG_ES].cache.p := 1;
  Self.sregs[BX_SEG_REG_ES].cache.dpl := 0;
  Self.sregs[BX_SEG_REG_ES].cache.segmentType := 1; (* data/code segment *)
  Self.sregs[BX_SEG_REG_ES].cache.type_ := 3; (* read/write access *)

  Self.sregs[BX_SEG_REG_ES].cache.segment.executable   := 0; (* data/stack segment *)
  Self.sregs[BX_SEG_REG_ES].cache.segment.c_ed         := 0; (* normal expand up *)
  Self.sregs[BX_SEG_REG_ES].cache.segment.r_w          := 1; (* writeable *)
  Self.sregs[BX_SEG_REG_ES].cache.segment.a            := 1; (* accessed *)
  Self.sregs[BX_SEG_REG_ES].cache.segment.base         := $00000000;
  Self.sregs[BX_SEG_REG_ES].cache.segment.limit        :=     $FFFF;
  Self.sregs[BX_SEG_REG_ES].cache.segment.limit_scaled :=     $FFFF;
{$ifend}
{$if BX_CPU_LEVEL >= 3}
  Self.sregs[BX_SEG_REG_ES].cache.segment.g   := 0; (* byte granular *)
  Self.sregs[BX_SEG_REG_ES].cache.segment.d_b := 0; (* 16bit default size *)
  Self.sregs[BX_SEG_REG_ES].cache.segment.avl := 0;
{$ifend}


  (* FS and descriptor cache *)
{$if BX_CPU_LEVEL >= 3}
  Self.sregs[BX_SEG_REG_FS].selector.value :=     $0000;
  Self.sregs[BX_SEG_REG_FS].selector.index :=     $0000;
  Self.sregs[BX_SEG_REG_FS].selector.ti := 0;
  Self.sregs[BX_SEG_REG_FS].selector.rpl := 0;

  Self.sregs[BX_SEG_REG_FS].cache.valid :=     1;
  Self.sregs[BX_SEG_REG_FS].cache.p := 1;
  Self.sregs[BX_SEG_REG_FS].cache.dpl := 0;
  Self.sregs[BX_SEG_REG_FS].cache.segmentType := 1; (* data/code segment *)
  Self.sregs[BX_SEG_REG_FS].cache.type_ := 3; (* read/write access *)

  Self.sregs[BX_SEG_REG_FS].cache.segment.executable   := 0; (* data/stack segment *)
  Self.sregs[BX_SEG_REG_FS].cache.segment.c_ed         := 0; (* normal expand up *)
  Self.sregs[BX_SEG_REG_FS].cache.segment.r_w          := 1; (* writeable *)
  Self.sregs[BX_SEG_REG_FS].cache.segment.a            := 1; (* accessed *)
  Self.sregs[BX_SEG_REG_FS].cache.segment.base         := $00000000;
  Self.sregs[BX_SEG_REG_FS].cache.segment.limit        :=     $FFFF;
  Self.sregs[BX_SEG_REG_FS].cache.segment.limit_scaled :=     $FFFF;
  Self.sregs[BX_SEG_REG_FS].cache.segment.g   := 0; (* byte granular *)
  Self.sregs[BX_SEG_REG_FS].cache.segment.d_b := 0; (* 16bit default size *)
  Self.sregs[BX_SEG_REG_FS].cache.segment.avl := 0;
{$ifend}


  (* GS and descriptor cache *)
{$if BX_CPU_LEVEL >= 3}
  Self.sregs[BX_SEG_REG_GS].selector.value :=     $0000;
  Self.sregs[BX_SEG_REG_GS].selector.index :=     $0000;
  Self.sregs[BX_SEG_REG_GS].selector.ti := 0;
  Self.sregs[BX_SEG_REG_GS].selector.rpl := 0;

  Self.sregs[BX_SEG_REG_GS].cache.valid :=     1;
  Self.sregs[BX_SEG_REG_GS].cache.p := 1;
  Self.sregs[BX_SEG_REG_GS].cache.dpl := 0;
  Self.sregs[BX_SEG_REG_GS].cache.segmentType := 1; (* data/code segment *)
  Self.sregs[BX_SEG_REG_GS].cache.type_ := 3; (* read/write access *)

  Self.sregs[BX_SEG_REG_GS].cache.segment.executable   := 0; (* data/stack segment *)
  Self.sregs[BX_SEG_REG_GS].cache.segment.c_ed         := 0; (* normal expand up *)
  Self.sregs[BX_SEG_REG_GS].cache.segment.r_w          := 1; (* writeable *)
  Self.sregs[BX_SEG_REG_GS].cache.segment.a            := 1; (* accessed *)
  Self.sregs[BX_SEG_REG_GS].cache.segment.base         := $00000000;
  Self.sregs[BX_SEG_REG_GS].cache.segment.limit        :=     $FFFF;
  Self.sregs[BX_SEG_REG_GS].cache.segment.limit_scaled :=     $FFFF;
  Self.sregs[BX_SEG_REG_GS].cache.segment.g   := 0; (* byte granular *)
  Self.sregs[BX_SEG_REG_GS].cache.segment.d_b := 0; (* 16bit default size *)
  Self.sregs[BX_SEG_REG_GS].cache.segment.avl := 0;
{$ifend}


  (* GDTR (Global Descriptor Table Register) *)
{$if BX_CPU_LEVEL >= 2}
  Self.gdtr.base         := $00000000;  (* undefined *)
  Self.gdtr.limit        :=     $0000;  (* undefined *)
  (* ??? AR:=Present, Read/Write *)
{$ifend}

  (* IDTR (Interrupt Descriptor Table Register) *)
{$if BX_CPU_LEVEL >= 2}
  Self.idtr.base         := $00000000;
  Self.idtr.limit        :=     $03FF; (* always byte granular *) (* ??? *)
  (* ??? AR:=Present, Read/Write *)
{$ifend}

  (* LDTR (Local Descriptor Table Register) *)
{$if BX_CPU_LEVEL >= 2}
  Self.ldtr.selector.value :=     $0000;
  Self.ldtr.selector.index :=     $0000;
  Self.ldtr.selector.ti := 0;
  Self.ldtr.selector.rpl := 0;

  Self.ldtr.cache.valid   := 0; (* not valid *)
  Self.ldtr.cache.p       := 0; (* not present *)
  Self.ldtr.cache.dpl     := 0; (* field not used *)
  Self.ldtr.cache.segmentType := 0; (* system segment *)
  Self.ldtr.cache.type_    := 2; (* LDT descriptor *)

  Self.ldtr.cache.ldt.base      := $00000000;
  Self.ldtr.cache.ldt.limit     :=     $FFFF;
{$ifend}

  (* TR (Task Register) *)
{$if BX_CPU_LEVEL >= 2}
  (* ??? I don't know what state the TR comes up in *)
  Self.tr.selector.value :=     $0000;
  Self.tr.selector.index :=     $0000; (* undefined *)
  Self.tr.selector.ti    :=     0;
  Self.tr.selector.rpl   :=     0;

  Self.tr.cache.valid    := 0;
  Self.tr.cache.p        := 0;
  Self.tr.cache.dpl      := 0; (* field not used *)
  Self.tr.cache.segmentType  := 0;
  Self.tr.cache.type_     := 0; (* invalid *)
  Self.tr.cache.tss286.base             := $00000000; (* undefined *)
  Self.tr.cache.tss286.limit            :=     $0000; (* undefined *)
{$ifend}

  // DR0 - DR7 (Debug Registers)
{$if BX_CPU_LEVEL >= 3}
  Self.dr0 := 0;   (* undefined *)
  Self.dr1 := 0;   (* undefined *)
  Self.dr2 := 0;   (* undefined *)
  Self.dr3 := 0;   (* undefined *)
{$ifend}
{$if BX_CPU_LEVEL = 3}
  Self.dr6 := $FFFF1FF0;
  Self.dr7 := $00000400;
{$elseif BX_CPU_LEVEL = 4}
  Self.dr6 := $FFFF1FF0;
  Self.dr7 := $00000400;
{$elseif BX_CPU_LEVEL = 5}
  Self.dr6 := $FFFF0FF0;
  Self.dr7 := $00000400;
{$elseif BX_CPU_LEVEL = 6}
  Self.dr6 := $FFFF0FF0;
  Self.dr7 := $00000400;
{$else}
{$error 'DR6,7: CPU > 6'}
{$ifend}

{$if 0=1}
  (* test registers 3-7 (unimplemented) *)
  Self.tr3 := 0;   (* undefined *)
  Self.tr4 := 0;   (* undefined *)
  Self.tr5 := 0;   (* undefined *)
  Self.tr6 := 0;   (* undefined *)
  Self.tr7 := 0;   (* undefined *)
{$ifend}

{$if BX_CPU_LEVEL >= 2}
  // MSW (Machine Status Word), so called on 286
  // CR0 (Control Register 0), so called on 386+
  Self.cr0.ts := 0; // no task switch
  Self.cr0.em := 0; // emulate math coprocessor
  Self.cr0.mp := 0; // wait instructions not trapped
  Self.cr0.pe := 0; // real mod_e
  Self.cr0.val32 := 0;

{$if BX_CPU_LEVEL >= 3}
  Self.cr0.pg := 0; // paging disabled
  // no change to cr0.val32
{$ifend}

{$if BX_CPU_LEVEL >= 4}
  Self.cr0.cd := 1; // caching disabled
  Self.cr0.nw := 1; // not write-through
  Self.cr0.am := 0; // disable alignment check
  Self.cr0.wp := 0; // disable write-protect
  Self.cr0.ne := 0; // ndp exceptions through int 13H, DOS compat
  Self.cr0.val32 := Self.cr0.val32 or $60000000;
{$ifend}

  // handle reserved bits
{$if BX_CPU_LEVEL = 3}
  // reserved bits all set to 1 on 386
  Self.cr0.val32 := Self.cr0.val32 or $7ffffff0;
{$elseif BX_CPU_LEVEL >= 4}
  // bit 4 is hardwired to 1 on all x86
  Self.cr0.val32 := Self.cr0.val32 or $00000010;
{$ifend}
{$ifend} // CPU >= 2


{$if BX_CPU_LEVEL >= 3}
  Self.cr2 := 0;
  Self.cr3 := 0;
{$ifend}
{$if BX_CPU_LEVEL >= 4}
  Self.cr4 := 0;
{$ifend}

(* initialise MSR registers to defaults *)
{$if BX_CPU_LEVEL >= 5}
  (* APIC Address, APIC enabled and BSP is default, we'll fill in the rest later *)
  Self.msr.apicbase := (APIC_BASE_ADDR shl 12) + $900;
{$ifend}

  Self.EXT := 0;
  //BX_INTR := 0;

{$if BX_SUPPORT_PAGING = 1}
{$if BX_USE_TLB = 1}
  TLB_init();
{$ifend} // BX_USE_TLB
{$ifend} // BX_SUPPORT_PAGING

  Self.bytesleft := 0;
  Self.fetch_ptr := nil;
  Self.prev_linear_page := 0;
  Self.prev_phy_page := 0;
  Self.max_phy_addr := 0;

(*
#if BX_DEBUGGER
#ifdef MAGIC_BREAKPOINT
  Self.magic_break := 0;
{$ifend}
  Self.stop_reason := STOP_NO_REASON;
  Self.trace := 0;
{$ifend}*)

  // Init the Floating Point Unit

{$if BX_DYNAMIC_TRANSLATION = 1}
  dynamic_init();
{$ifend}

(*
#if (BX_SMP_PROCESSORS > 1)
  // notice if I'm the bootstrap processor.  If not, do the equivalent of
  // a HALT instruction.
  int apic_id := local_apic.get_id ();
  if (BX_BOOTSTRAP_PROCESSOR = apic_id)
  begin
    // boot normally
    Self.bsp := 1;
    Self.msr.apicbase |:= $0100;	// set bit 8 BSP
    BX_INFO(('CPU[%d] is the bootstrap processor', apic_id));
  end; else begin
    // it's an application processor, halt until IPI is heard.
    Self.bsp := 0;
    Self.msr.apicbase @:= ~$0100;	// clear bit 8 BSP
    BX_INFO(('CPU[%d] is an application processor. Halting until IPI.', apic_id));
    debug_trap |:= $80000000;
    async_event := 1;
  end;
{$ifend}*)
end;


procedure BX_CPU_C.sanity_checks;
var
  al_, cl_, dl_, bl_, ah_, ch_, dh_, bh_:Bit8u;
  ax_, cx_, dx_, bx_, sp_, bp_, si_, di_:Bit16u;
  eax_, ecx_, edx_, ebx_, esp_, ebp_, esi_, edi_:Bit32u;
begin

  EAX := $FFEEDDCC;
  ECX := $BBAA9988;
  EDX := $77665544;
  EBX := $332211FF;
  ESP := $EEDDCCBB;
  EBP := $AA998877;
  ESI := $66554433;
  EDI := $2211FFEE;

  al_ := AL;
  cl_ := CL;
  dl_ := DL;
  bl_ := BL;
  ah_ := AH;
  ch_ := CH;
  dh_ := DH;
  bh_ := BH;

  if ( (al_ <> (EAX  and $FF)) or (cl_ <> (ECX  and $FF)) or (dl_ <> (EDX  and $FF)) or (bl_ <> (EBX  and $FF)) or
       (ah_ <> ((EAX shr 8) and $FF)) or
       (ch_ <> ((ECX shr 8) and $FF)) or
       (dh_ <> ((EDX shr 8) and $FF)) or
       (bh_ <> ((EBX shr 8) and $FF))) then begin
    BX_PANIC(('problems using BX_READ_8BIT_REG()!'));
    end;

  ax_ := AX;
  cx_ := CX;
  dx_ := DX;
  bx_ := BX;
  sp_ := SP;
  bp_ := BP;
  si_ := SI;
  di_ := DI;

  if ( (ax_ <> (EAX  and $FFFF)) or
       (cx <> (ECX  and $FFFF)) or
       (dx_ <> (EDX  and $FFFF)) or
       (bx_ <> (EBX  and $FFFF)) or
       (sp_ <> (ESP  and $FFFF)) or
       (bp_ <> (EBP  and $FFFF)) or
       (si_ <> (ESI  and $FFFF)) or
       (di_ <> (EDI  and $FFFF))) then begin
    BX_PANIC(('problems using BX_READ_16BIT_REG()!'));
    end;


  eax_ := EAX;
  ecx_ := ECX;
  edx_ := EDX;
  ebx_ := EBX;
  esp_ := ESP;
  ebp_ := EBP;
  esi_ := ESI;
  edi_ := EDI;


  if ((sizeof(Bit8u) <> 1) or (sizeof(Bit8s) <> 1)) then
    BX_PANIC(('data type Bit8u or Bit8s is not of length 1 byte!'));
  if ((sizeof(Bit16u) <> 2) or (sizeof(Bit16s) <> 2)) then
    BX_PANIC(('data type Bit16u or Bit16s is not of length 2 bytes!'));
  if ((sizeof(Bit32u) <> 4) or (sizeof(Bit32s) <> 4)) then
    BX_PANIC(('data type Bit32u or Bit32s is not of length 4 bytes!'));

  BX_DEBUG(Format( '#(%x)all sanity checks passed!', [BX_SIM_ID] ));
end;

procedure BX_CPU_C.set_INTR(value:Bool);
begin
  Self.INTR := value;
  Self.async_event := 1;
end;

