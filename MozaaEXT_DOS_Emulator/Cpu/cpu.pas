{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
{$include defines.pas}
unit cpu;

interface

uses CONFIG, Service, Math, Memory, SysUtils, jumpfar;

{$ifndef BX_CPU_H}
  {$define BX_CPU_H}
const

{$if BX_PROVIDE_CPU_MEMORY = 1}
  BX_INSTR_ADD8         = 1;
  BX_INSTR_ADD16        = 2;
  BX_INSTR_ADD32        = 3;

  BX_INSTR_SUB8         = 4;
  BX_INSTR_SUB16        = 5;
  BX_INSTR_SUB32        = 6;

  BX_INSTR_ADC8         = 7;
  BX_INSTR_ADC16        = 8;
  BX_INSTR_ADC32        = 9;

  BX_INSTR_SBB8         = 10;
  BX_INSTR_SBB16        = 11;
  BX_INSTR_SBB32        = 12;

  BX_INSTR_CMP8         = 13;
  BX_INSTR_CMP16        = 14;
  BX_INSTR_CMP32        = 15;

  BX_INSTR_INC8         = 16;
  BX_INSTR_INC16        = 17;
  BX_INSTR_INC32        = 18;

  BX_INSTR_DEC8         = 19;
  BX_INSTR_DEC16        = 20;
  BX_INSTR_DEC32        = 21;

  BX_INSTR_NEG8         = 22;
  BX_INSTR_NEG16        = 23;
  BX_INSTR_NEG32        = 24;

  BX_INSTR_XADD8        = 25;
  BX_INSTR_XADD16       = 26;
  BX_INSTR_XADD32       = 27;

  BX_INSTR_OR8          = 28;
  BX_INSTR_OR16         = 29;
  BX_INSTR_OR32         = 30;

  BX_INSTR_AND8         = 31;
  BX_INSTR_AND16        = 32;
  BX_INSTR_AND32        = 33;

  BX_INSTR_TEST8        = 34;
  BX_INSTR_TEST16       = 35;
  BX_INSTR_TEST32       = 36;

  BX_INSTR_XOR8         = 37;
  BX_INSTR_XOR16        = 38;
  BX_INSTR_XOR32        = 39;

  BX_INSTR_CMPS8        = 40;
  BX_INSTR_CMPS16       = 41;
  BX_INSTR_CMPS32       = 42;

  BX_INSTR_SCAS8        = 43;
  BX_INSTR_SCAS16       = 44;
  BX_INSTR_SCAS32       = 45;

  BX_INSTR_SHR8         = 46;
  BX_INSTR_SHR16        = 47;
  BX_INSTR_SHR32        = 48;

  BX_INSTR_SHL8         = 49;
  BX_INSTR_SHL16        = 50;
  BX_INSTR_SHL32        = 51;



  BX_LF_INDEX_KNOWN     = 0;
  BX_LF_INDEX_OSZAPC    = 1;
  BX_LF_INDEX_OSZAP     = 2;
  BX_LF_INDEX_P         = 3;

  BX_LF_MASK_OSZAPC     = $111111;
  BX_LF_MASK_OSZAP      = $222220;
  BX_LF_MASK_P          = $000030;
{$ifend} // BX_PROVIDE_CPU_MEMORY==1
  BxImmediate         =$000f; // bits 3..0: any immediate
  BxImmediate_Ib      =$0001; // 8 bits regardless
  BxImmediate_Ib_SE   =$0002; // sign extend to OS size
  BxImmediate_Iv      =$0003; // 16 or 32 depending on OS size
  BxImmediate_Iw      =$0004; // 16 bits regardless
  BxImmediate_IvIw    =$0005; // call_Ap
  BxImmediate_IwIb    =$0006; // enter_IwIb
  BxImmediate_O       =$0007; // mov_ALOb, mov_ObAL, mov_eAXOv, mov_OveAX
  BxImmediate_BrOff8  =$0008; // Relative branch offset byte
  BxImmediate_BrOff16 =$0009; // Relative branch offset word
  BxImmediate_BrOff32 =BxImmediate_Iv;

  BxPrefix          =$0010; // bit  4
  BxAnother         =$0020; // bit  5
  BxRepeatable      =$0040; // bit  6
  BxRepeatableZF    =$0080; // bit  7
  BxGroupN          =$0100; // bits 8
  BxGroup1          =BxGroupN;
  BxGroup2          =BxGroupN;
  BxGroup3          =BxGroupN;
  BxGroup4          =BxGroupN;
  BxGroup5          =BxGroupN;
  BxGroup6          =BxGroupN;
  BxGroup7          =BxGroupN;
  BxGroup8          =BxGroupN;
  BxGroup9          =BxGroupN;
  BxGroupa          =BxGroupN;

   BX_TASK_FROM_JUMP          = 10;
   BX_TASK_FROM_CALL_OR_INT   = 11;
   BX_TASK_FROM_IRET          = 12;
   BX_DE_EXCEPTION =  0; // Divide Error (fault)
   BX_DB_EXCEPTION =  1; // Debug (fault/trap)
   BX_BP_EXCEPTION =  3; // Breakpoint (trap)
   BX_OF_EXCEPTION =  4; // Overflow (trap)
   BX_BR_EXCEPTION =  5; // BOUND (fault)
   BX_UD_EXCEPTION =  6;
   BX_NM_EXCEPTION =  7;
   BX_DF_EXCEPTION =  8;
   BX_TS_EXCEPTION = 10;
   BX_NP_EXCEPTION = 11;
   BX_SS_EXCEPTION = 12;
   BX_GP_EXCEPTION = 13;
   BX_PF_EXCEPTION = 14;
   BX_MF_EXCEPTION = 16;
   BX_AC_EXCEPTION = 17;

   BX_SREG_ES = 0;
   BX_SREG_CS = 1;
   BX_SREG_SS = 2;
   BX_SREG_DS = 3;
   BX_SREG_FS = 4;
   BX_SREG_GS = 5;

  // segment register encoding
   BX_SEG_REG_ES = 0;
   BX_SEG_REG_CS = 1;
   BX_SEG_REG_SS = 2;
   BX_SEG_REG_DS = 3;
   BX_SEG_REG_FS = 4;
   BX_SEG_REG_GS = 5;
   BX_SEG_REG_NULL = 8;
   //BX_NULL_SEG_REG(seg) ((seg) & BX_SEG_REG_NULL)  and BX_SEG_REG_NULL
   BX_READ       = 10;
   BX_WRITE      = 11;
   BX_RW         = 12;


  {$if BX_LITTLE_ENDIAN = $01}
   BX_REG8L_OFFSET = 0;
   BX_REG8H_OFFSET = 1;
   BX_REG16_OFFSET = 0;
  {$else} // BX_BIG_ENDIAN
   BX_REG8L_OFFSET = 3;
   BX_REG8H_OFFSET = 2;
   BX_REG16_OFFSET = 2;
  {$ifend} // ifdef BX_LITTLE_ENDIAN

   BX_8BIT_REG_AL = 0;
   BX_8BIT_REG_CL = 1;
   BX_8BIT_REG_DL = 2;
   BX_8BIT_REG_BL = 3;
   BX_8BIT_REG_AH = 4;
   BX_8BIT_REG_CH = 5;
   BX_8BIT_REG_DH = 6;
   BX_8BIT_REG_BH = 7;

   BX_16BIT_REG_AX = 0;
   BX_16BIT_REG_CX = 1;
   BX_16BIT_REG_DX = 2;
   BX_16BIT_REG_BX = 3;
   BX_16BIT_REG_SP = 4;
   BX_16BIT_REG_BP = 5;
   BX_16BIT_REG_SI = 6;
   BX_16BIT_REG_DI = 7;

   BX_32BIT_REG_EAX = 0;
   BX_32BIT_REG_ECX = 1;
   BX_32BIT_REG_EDX = 2;
   BX_32BIT_REG_EBX = 3;
   BX_32BIT_REG_ESP = 4;
   BX_32BIT_REG_EBP = 5;
   BX_32BIT_REG_ESI = 6;
   BX_32BIT_REG_EDI = 7;

   BX_MSR_P5_MC_ADDR  =	$0000;
   BX_MSR_MC_TYPE     = $0001;
   BX_MSR_TSC	        =	 $0010;
   BX_MSR_CESR		    =  $0011;
   BX_MSR_CTR0		    =  $0012;
   BX_MSR_CTR1		    =  $0013;
   BX_MSR_APICBASE		=  $001b;
   BX_MSR_EBL_CR_POWERON = $002a;
   BX_MSR_TEST_CTL	  =	 $0033;
   BX_MSR_BIOS_UPDT_TRIG = $0079;
   BX_MSR_BBL_CR_D0	  =  $0088;
   BX_MSR_BBL_CR_D1	  =  $0089;
   BX_MSR_BBL_CR_D2	  = $008a;
   BX_MSR_BBL_CR_D3	  = $008b;	// = BIOS_SIGN
   BX_MSR_PERFCTR0		= $00c1;
   BX_MSR_PERFCTR1		= $00c2;
   BX_MSR_MTRRCAP		  = $00fe;
   BX_MSR_BBL_CR_ADDR	= $0116;
   BX_MSR_BBL_DECC		= $0118;
   BX_MSR_BBL_CR_CTL	= $0119;
   BX_MSR_BBL_CR_TRIG	= $011a;
   BX_MSR_BBL_CR_BUSY	= $011b;
   BX_MSR_BBL_CR_CTL3	= $011e;
   BX_MSR_MCG_CAP		  = $0179;
   BX_MSR_MCG_STATUS	= $017a;
   BX_MSR_MCG_CTL		  = $017b;
   BX_MSR_EVNTSEL0		= $0186;
   BX_MSR_EVNTSEL1		= $0187;
   BX_MSR_DEBUGCTLMSR	= $01d9;
   BX_MSR_LASTBRANCHFROMIP	= $01db;
   BX_MSR_LASTBRANCHTOIP	= $01dc;
   BX_MSR_LASTINTOIP	= $01dd;
   BX_MSR_ROB_CR_BKUPTMPDR6	= $01e0;
   BX_MSR_MTRRPHYSBASE0	= $0200;
   BX_MSR_MTRRPHYSMASK0	= $0201;
   BX_MSR_MTRRPHYSBASE1	= $0202;

{$if defined(NEED_CPU_REG_SHORTCUTS)}     // ++++++++++++++++++++++++++++++++
  (* WARNING:
     Only BX_CPU_C member functions can use these shortcuts safely!
     Functions that use the shortcuts outside of BX_CPU_C might work
     when BX_USE_CPU_SMF=1 but will fail when BX_USE_CPU_SMF=0
     (for example in SMP mode).
  *)

  {$ifend}
  type

    bx_lf_flags_entry = record
      op1_8:Bit8u;
      op2_8:Bit8u;
      result_8:Bit8u;

      op1_16:Bit16u;
      op2_16:Bit16u;
      result_16:Bit16u;

      op1_32:Bit32u;
      op2_32:Bit32u;
      result_32:Bit32u;

      prev_CF:Bool;
      instr:Word;
    end;
    bx_flags_reg_t = record
       { 31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16
        ==|==|=====|==|==|==|==|==|==|==|==|==|==|==|==
         0| 0| 0| 0| 0| 0| 0| 0| 0| 0|ID|VP|VF|AC|VM|RF

        15|14|13|12|11|10| 9| 8| 7| 6| 5| 4| 3| 2| 1| 0
        ==|==|=====|==|==|==|==|==|==|==|==|==|==|==|==
         0|NT| IOPL|OF|DF|IF|TF|SF|ZF| 0|AF| 0|PF| 1|CF }


      // In order to get access to these fields from the Dynamic Translation
      // code, using only 8bit offsets, I needed to move these fields
      // together.
      cf:Bit32u;
      af:Bit32u;
      zf:Bit32u;
      sf:Bit32u;
      of_:Bit32u;

      bit1    :Bool;
      pf_byte :Bit8u;  { PF derived from last result byte when needed }
      bit3    :Bool;
      bit5    :Bool;
      tf      :Bool;
      if_     :Bool;
      df:Bool;
    {$if BX_CPU_LEVEL >= 2 }
      iopl:Bit8u;
      nt:Bool;
    {$ifend}
      bit15:Bool;
    {$if BX_CPU_LEVEL >= 3 }
      rf:Bool;
      vm:Bool;
    {$ifend}
    {$if BX_CPU_LEVEL >= 4 }
      ac:Bool;  // alignment check
      // Bool vif; // Virtual Interrupt Flag
      // Bool vip; // Virtual Interrupt Pending
      id:Bool;  // late model 486 and beyond had CPUID
    {$ifend}
    end;
    // +++++++++++++++++++++++++++++++++++++++++++++
    {$if BX_CPU_LEVEL >= 2} // Ever is > 286
    bx_cr0_t = record
      val32:Bit32u; // 32bit value of register

      // bitfields broken out for efficient access
    {$if BX_CPU_LEVEL >= 3}
      pg:Bool; // paging
    {$ifend}

    // CR0 notes:
    //   Each x86 level has its own quirks regarding how it handles
    //   reserved bits.  I used DOS DEBUG.EXE in real mode on the
    //   following processors, tried to clear bits 1..30, then tried
    //   to set bits 1..30, to see how these bits are handled.
    //   I found the following:
    //
    //   Processor    try to clear bits 1..30    try to set bits 1..30
    //   386          7FFFFFF0                   7FFFFFFE
    //   486DX2       00000010                   6005003E
    //   Pentium      00000010                   7FFFFFFE
    //   Pentium-II   00000010                   6005003E
    //
    // My assumptions:
    //   All processors: bit 4 is hardwired to 1 (not true on all clones)
    //   386: bits 5..30 of CR0 are also hardwired to 1
    //   Pentium: reserved bits retain value set using mov cr0, reg32
    //   486DX2/Pentium-II: reserved bits are hardwired to 0

    {$if BX_CPU_LEVEL >= 4 }
      cd:Bool; // cache disable
      nw:Bool; // no write-through
      am:Bool; // alignment mask
      wp:Bool; // write-protect
      ne:Bool; // numerics exception
    {$ifend}

      ts:Bool; // task switched
      em:Bool; // emulate math coprocessor
      mp:Bool; // monitor coprocessor
      pe:Bool; // protected mode enable
     end;
    {$ifend}

    {$if BX_CPU_LEVEL >= 5 }
    bx_regs_msr_t = record
      p5_mc_addr    :Bit8u;
      p5_mc_type    :Bit8u;
      tsc           :Bit8u;
      cesr          :Bit8u;
      ctr0          :Bit8u;
      ctr1          :Bit8u;
      apicbase      :Bit64u; 
      // TODO finish of the others
    end;
    {$ifend}

    pbx_selector_t = ^bx_selector_t;
    bx_selector_t = record // bx_selector_t
      value:Bit16u;   // the 16bit value of the selector
    {$if BX_CPU_LEVEL >= 2 }
                        // the following fields are extracted from the value field in protected
                        // mode only.  They're used for sake of efficiency
      index:Bit16u;     // 13bit index extracted from value in protected mode
      ti:Bit8u;         // table indicator bit extracted from value
      rpl:Bit8u;        // RPL extracted from value
    {$ifend}
    end;

    pbx_descriptor_t = ^bx_descriptor_t;
    bx_descriptor_t = record
      valid:Bool;         // 0 = invalid, 1 = valid */
      p:Bool;             // present */
      dpl:Bit8u;            // descriptor privilege level 0..3 */
      segmenttype:Bool;      // 0 = system/gate, 1 = data/code segment */
      type_:Bit8u;          { For system & gate descriptors, only
                              *  0 = invalid descriptor (reserved)
                              *  1 = 286 available Task State Segment (TSS)
                              *  2 = LDT descriptor
                              *  3 = 286 busy Task State Segment (TSS)
                              *  4 = 286 call gate
                              *  5 = task gate
                              *  6 = 286 interrupt gate
                              *  7 = 286 trap gate
                              *  8 = (reserved)
                              *  9 = 386 available TSS
                              * 10 = (reserved)
                              * 11 = 386 busy TSS
                              * 12 = 386 call gate
                              * 13 = (reserved)
                              * 14 = 386 interrupt gate
                              * 15 = 386 trap gate }
      // union // -- start include here
      case integer of
      0 :(
          segment : record
          executable      :Bool;    // 1=code, 0=data or stack segment */
          c_ed            :Bool;    // for code: 1=conforming, for data/stack: 1=expand down */
          r_w             :Bool;    // for code: readable?, for data/stack: writeable? */
          a               :Bool;    // accessed? */
          base            :Bit32u;     // base address: 286=24bits, 386=32bits */
          limit           :Bit32u;     // limit: 286=16bits, 386=20bits */
          limit_scaled    :Bit32u;    { for efficiency, this contrived field is set to
                                      * limit for byte granular, and
                                      * (limit << 12) | 0xfff for page granular seg's }
      {$if BX_CPU_LEVEL >= 3}
          g   :Bool;             // granularity: 0=byte, 1=4K (page) */
          d_b :Bool;           // default size: 0=16bit, 1=32bit */
          avl :Bool;           // available for use by system */
      {$ifend}
        end; // END 'segment' record type
      gate286 : record
        word_count    :Bit8u;    // 5bits (0..31) #words to copy from caller's stack
                                 // to called procedure's stack.  (call gates only)*/
        dest_selector :Bit16u;
        dest_offset   :Bit16u;
        end;
      taskgate:record            // type 5: Task Gate Descriptor
        tss_selector:Bit16u;    // TSS segment selector
        end;
    {$if BX_CPU_LEVEL >= 3}
      gate386:record
        dword_count   :Bit8u;    // 5bits (0..31) #dwords to copy from caller's stack
                                 // to called procedure's stack.  (call gates only)*/
        dest_selector :Bit16u;
        dest_offset   :Bit32u;
        end;
    {$ifend}
      tss286:record
        base          :Bit32u;          // 24 bit 286 TSS base  */
        limit         :Bit16u;         // 16 bit 286 TSS limit */
        end;
    {$if BX_CPU_LEVEL >= 3}
      tss386:record
        base          :Bit32u;          // 32 bit 386 TSS base  */
        limit         :Bit32u;         // 20 bit 386 TSS limit */
        limit_scaled  :Bit32u;  // Same notes as for 'segment' field
        g             :Bool;             // granularity: 0=byte, 1=4K (page) */
        avl           :Bool;           // available for use by system */
      end;
    {$ifend}
      ldt:record
        base          :Bit32u;                 // 286=24 386+ =32 bit LDT base */
        limit         :Bit16u;                // 286+ =16 bit LDT limit */
      end;
        );
  end;

  pbx_segment_reg_t = ^bx_segment_reg_t;
  bx_segment_reg_t = record
    selector:bx_selector_t;
    cache:bx_descriptor_t;
  end;


  //typedef void * (*BxVoidFPtr_t)(void); ++++++++++++++++++++++++

  BxVoidFPtr_t = procedure;

  //BX_CPU_C=class;

  PBxInstruction_tag = ^BxInstruction_tag;
  BxInstruction_tag = record
  // prefix stuff here...
  name            :array[0..10] of char;
  attr            :word; // attribute from fetchdecode
  b1              :word; // opcode1 byte
  rep_used        :word;
  modrm           :word; // mod-nnn-r/m byte
    mod_          :word;
    nnn           :word;
    rm            :word;
  displ16u        :Bit16u; // for 16-bit modrm forms
  displ32u        :Bit32u; // for 32-bit modrm forms
  seg             :word;
  sib             :word; // scale-index-base (2nd modrm byte)
    scale         :word;
    index         :word;
    base          :word;
  addr_displacement   :Bit32u; // address displacement
  rm_addr           :Bit32u;
  Id                :Bit32u;
  Iw                :Bit16u;
  Ib                :Bit8u;
  Ib2               :Bit8u; // for ENTER_IwIb
  Iw2               :Bit16u; // for JMP_Ap
  ilen              :word; // instruction length
  os_32, as_32      :word; // OperandSize/AddressSize is 32bit
  flags_in, flags_out  :word; // flags needed, flags modified

{$if BX_USE_CPU_SMF = 1}
  ResolveModrm  :procedure(Istruction:PBxInstruction_tag) of object;  // void (*ResolveModrm)(BxInstruction_tag *);
  execute       :procedure(Istruction:PBxInstruction_tag) of object;  // void (*execute)(BxInstruction_tag *);
{$else}
  void (BX_CPU_C::*ResolveModrm)(BxInstruction_tag *);
  void (BX_CPU_C::*execute)(BxInstruction_tag *);
{$ifend}

{$if BX_DYNAMIC_TRANSLATION = 1}
  DTResolveModrm:BxVoidFPtr_t;
{$ifend}

{$if BX_DYNAMIC_TRANSLATION = 1}
  DTAttr:word;
  DTFPtr:function(P:PBit8u;Instruction:PBxInstruction_tag):PBit8u; // Bit8u *(*DTFPtr)(Bit8u *, BxInstruction_tag *);
  DTMemRegsUsed:word;
{$ifend}
end;

  PBxInstruction_t2 = ^TBxInstruction_t2;
  TBxInstruction_t2 = procedure(i:PBxInstruction_tag) of object;

  PBxInstruction_t = ^TBxInstruction_t;
  TBxInstruction_t = procedure(i:PBxInstruction_tag) of object;

{$if BX_USE_CPU_SMF = 1}
  PBxExecutePtr_t = ^BxExecutePtr_t;
  BxExecutePtr_t=procedure(I:PBxInstruction_tag) of object; // typedef void (*BxExecutePtr_t)(BxInstruction_t *);
{$else}
  typedef void (BX_CPU_C::*BxExecutePtr_t)(BxInstruction_t *); // +++++++++++++++++++++++++
{$ifend}

{$if BX_DYNAMIC_TRANSLATION = 1}
  //typedef Bit8u * (*BxDTASResolveModrm_t)(Bit8u *, BxInstruction_t *, unsigned, unsigned); // +++++++++++++
{$ifend}

{$if BX_DYNAMIC_TRANSLATION = 1}
// Arrays of function pointers which handle a specific
// mod-rm address format
{extern BxDTASResolveModrm_t  BxDTResolve32Mod0[];
extern BxDTASResolveModrm_t  BxDTResolve32Mod1or2[];
extern BxDTASResolveModrm_t  BxDTResolve32Mod0Base[];
extern BxDTASResolveModrm_t  BxDTResolve32Mod1or2Base[];
extern BxDTASResolveModrm_t  BxDTResolve16Mod1or2[];
extern BxDTASResolveModrm_t  BxDTResolve16Mod0[];}
{$ifend}

{$if BX_CPU_LEVEL < 2}
  // no GDTR or IDTR register in an 8086
{$else}
  bx_global_segment_reg_t = record
    base            :Bit32u;        // base address: 24bits=286,32bits=386
    limit           :Bit16u;        // limit, 16bits
  end;
{$ifend}

{$if BX_USE_TLB = 1}
  bx_TLB_entry = record
    lpf             :Bit32u;    // linear page frame
    ppf             :Bit32u;    // physical page frame
    pte_addr        :Bit32u;    // Page Table Address for updating A & D bits
    combined_access :Bit32u;
  end;
{$ifend}  // #if BX_USE_TLB

{$if BX_BIG_ENDIAN = 1}
bx_gen_reg_t = record
  case integer of
    0:(
        erx:Bit32u;
        word:record
          word_filler:Bit16u;
          case integer of
            0:(
               rx:Bit16u;
               byte:record
                 rh:Bit8u;
                 rl:Bit8u;
               end;
              );
        end;
      );
  end;
{$else}
  bx_gen_reg_t = record
    case integer of
      0:(
          erx:Bit32u;
        );
      1:
        (
         rx:Bit16u;
        );
      2:
        (
         rl:Bit8u;
         rh:Bit8u;
        );
      // word_filler:Bit16u; -> Implementarlo nella struttura??? (Da codice originale)
    end;
{$ifend}

  bx_apic_type_t = (APIC_TYPE_NONE, APIC_TYPE_IOAPIC, APIC_TYPE_LOCAL_APIC);

  BxDTShim_t = Procedure;

  PBxOpcodeInfo_t = ^BxOpcodeInfo_t;
  BxOpcodeInfo_t = record
    name:array[0..15] of char;
    Attr:Bit16u;
    //BxExecutePtr_t ExecutePtr;
    ExecutePtr:BxExecutePtr_t;
    AnotherArray:PBxOpcodeInfo_t;
  end;

{ --------------------------------------------------------------------------------- }

const
 BX_MAX_TIMERS=16;
 BX_NULL_TIMER_HANDLE = 10000; // set uninitialized timer handles to this
type

  PCS_OP = (PCS_CLEAR, PCS_SET, PCS_TOGGLE );
  bx_timer_handler_t = procedure(this_ptr:Pointer) of object;

Jump_Exception=class(Exception)
end;

pbx_pc_system_c = ^bx_pc_system_c;
bx_pc_system_c = class
public

  timer:array [0..BX_MAX_TIMERS] of record
    period:Bit64u;
    remaining:Bit64u;
    active:Bool;
    continuous:Bool;
    triggered:Bool;
    funct:bx_timer_handler_t;
    this_ptr:Pointer;
    end;
  num_timers:unsigned;
  num_cpu_ticks_in_period:Bit64u;
  num_cpu_ticks_left:Bit64u;

  DRQ:array[0..8] of Bool;  // DMA Request
  DACK:array[0..8] of Bool; // DMA Acknowlege
  TC:bool;      // Terminal Count
  HRQ:bool;     // Hold Request
  HLDA:bool;    // Hold Acknowlege
  //Boolean INTR;    // Interrupt


    // Address line 20 control:
    //   1 = enabled: extended memory is accessible
    //   0 = disabled: A20 address line is forced low to simulate
    //       an 8088 address map
  enable_a20:Bool;

    // start out masking physical memory addresses to:
    //   8086:      20 bits
    //    286:      24 bits
    //    386:      32 bits
    // when A20 line is disabled, mask physical memory addresses to:
    //    286:      20 bits
    //    386:      20 bits
    //
  a20_mask:Bit32u;
  COUNTER_INTERVAL:Bit64u;
  counter:Bit64u;
  counter_timer_index:integer;

  constructor Create;
  procedure set_DRQ(channel:unsigned; val:bool);
  procedure set_DACK(channel:unsigned; val:bool);
  procedure set_TC(val:bool);   // set the Terminal Count line
  procedure set_HRQ(val:bool);  // set the Hold ReQuest line
  procedure raise_HLDA; // raise the HoLD Acknowlege line
  procedure set_INTR(value:bool); // set the INTR line to value

  //function IntEnabled:Integer;
  //function InterruptSignal( operation:PCS_OP ):Integer;
  function ResetSignal( operation:PCS_OP ):Integer;
  function IAC:Bit8u;

  procedure   init_ips(ips:Bit32u);
  procedure   timer_handler;
  function ticks_remaining(index:Integer):Int64;
  function    register_timer( this_ptr:Pointer; funct:bx_timer_handler_t; useconds:Bit32u; continuous:Bool;active:Bool):Integer;
  procedure start_timers;
  procedure activate_timer( timer_index:unsigned; useconds:Bit32u; continuous:Bool );
  procedure deactivate_timer( timer_index:unsigned );
  procedure tickn(n:Bit64u);

  function register_timer_ticks(this_ptr:Pointer; funct:bx_timer_handler_t; Instructions:Bit64u; continuous:Bool; active:Bool):Integer;
  procedure activate_timer_ticks(timer_index:unsigned; instructions:Bit64u; continuous:Bool);
  procedure counter_timer_handler(this_ptr:Pointer);
  //procedure wait_for_event();

  function time_usec:Bit64u;
  function time_ticks:Bit64u;

  procedure dma_write8(phy_addr:Bit32u; channel:unsigned; verify:Bool);
  procedure dma_read8(phy_addr:Bit32u; channel:unsigned);
  procedure dma_write16(phy_addr:Bit32u; channel:unsigned; verify:Bool);
  procedure dma_read16(phy_addr:Bit32u; channel:unsigned);

  function inp(addr:Bit16u; io_len:unsigned):Bit32u;
  procedure outp(addr:Bit16u; value:Bit32u; io_len:unsigned);
  procedure set_enable_a20(value:Bit8u);
  function get_enable_a20:Bool;
  procedure exit;
  procedure expire_ticks;
end;

  PBX_CPU_C = ^BX_CPU_C;
  BX_CPU_C = class
  public
    fake_start:byte;
    FIP:Bit16u;
    name:array[0..64] of char;

    gen_reg:array[0..8] of bx_gen_reg_t;
    eip:Bit32u;    // instruction pointer
    curr_exception:array[0..2] of Bit8u;
    {$if BX_CPU_LEVEL > 0}
        // so that we can back up when handling faults, exceptions, etc.
        // we need to store the value of the instruction pointer, before
        // each fetch/execute cycle.
      prev_eip:Bit32u;
    {$ifend}
       // A few pointer to functions for use by the dynamic translation
       // code.  Keep them close to the gen_reg declaration, so I can
       // use an 8bit offset to access them.
    {$if BX_DYNAMIC_TRANSLATION = 1} // not yet supported
      BxDTShim_t DTWrite8vShim;
      BxDTShim_t DTWrite16vShim;
      BxDTShim_t DTWrite32vShim;
      BxDTShim_t DTRead8vShim;
      BxDTShim_t DTRead16vShim;
      BxDTShim_t DTRead32vShim;
      BxDTShim_t DTReadRMW8vShim;
      BxDTShim_t DTReadRMW16vShim;
      BxDTShim_t DTReadRMW32vShim;
      BxDTShim_t DTWriteRMW8vShim;
      BxDTShim_t DTWriteRMW16vShim;
      BxDTShim_t DTWriteRMW32vShim;
      BxDTShim_t DTSetFlagsOSZAPCPtr;
      BxDTShim_t DTIndBrHandler;
      BxDTShim_t DTDirBrHandler;
    {$ifend}
    lf_flags_status           :Bit32u;
    lf_pf                     :Bool;
    eflags                    :bx_flags_reg_t;
    oszapc                    :bx_lf_flags_entry;
    oszap                     :bx_lf_flags_entry;
    prev_esp                  :Bit32u;
    inhibit_mask:word;

    // user segment register set
    sregs:array[0..10] of bx_segment_reg_t;

    // system segment registers
  {$if BX_CPU_LEVEL >= 2}
    gdtr                      :bx_global_segment_reg_t; // global descriptor table register
    idtr                      :bx_global_segment_reg_t; // interrupt descriptor table register
  {$ifend}
    ldtr                      :bx_segment_reg_t;        // interrupt descriptor table register
    tr                        :bx_segment_reg_t;        // task register


    // debug registers 0-7 (unimplemented)
  {$if BX_CPU_LEVEL >= 3}
    dr0                       :Bit32u;
    dr1                       :Bit32u;
    dr2                       :Bit32u;
    dr3                       :Bit32u;
    dr6                       :Bit32u;
    dr7                       :Bit32u;
  {$ifend}
    // TR3 - TR7 (Test Register 3-7), unimplemented */

    // Control registers
  {$if BX_CPU_LEVEL >= 2}
    cr0                       :bx_cr0_t;
    cr1                       :Bit32u;
    cr2                       :Bit32u;
    cr3                       :Bit32u;
  {$ifend}

  {$if BX_CPU_LEVEL >= 4}
    cr4                       :Bit32u;
  {$ifend}

  {$if BX_CPU_LEVEL >= 5}
    msr                       :bx_regs_msr_t;
  {$ifend}

  EXT                         :Bool;  // 1 if processing external interrupt or exception
                                        // or if not related to current instruction,
                                        // 0 if current CS:IP caused exception */
  errorno                     :Word;               // signal exception during instruction emulation */

  debug_trap                  :Bit32u;             // holds DR6 value to be set as well
  async_event                 :Bool;
  INTR                        :Bool;

                                        // wether this CPU is the BSP always set for UP */
  bsp:Bool;
  // for accessing registers by index number
  _16bit_base_reg             :array[0..8] of PBit16u;
  _16bit_index_reg            :array[0..8] of PBit16u;
  empty_register              :Bit32u;

  // for decoding instructions; accessing seg reg's by index
  sreg_mod00_rm16             :array[0..8] of Word;
  sreg_mod01_rm16             :array[0..8] of Word;
  sreg_mod10_rm16             :array[0..8] of Word;
  sreg_mod01_rm32             :array[0..8] of Word;
  sreg_mod10_rm32             :array[0..8] of Word;
  sreg_mod0_base32            :array[0..8] of Word;
  sreg_mod1or2_base32         :array[0..8] of Word;

  save_cs                     :bx_segment_reg_t;
  save_ss                     :bx_segment_reg_t;
  save_eip                    :Bit32u;
  save_esp                    :Bit32u;

  //Inserire il codice per gestire le eccezzioni

  // For prefetch'ing instructions
  bytesleft                 :Bit32u;
  fetch_ptr                 :PBit8u;
  prev_linear_page           :Bit32u;
  prev_phy_page             :Bit32u;
  max_phy_addr              :Bit32u;

{$if BX_DEBUGGER = 1}
  break_point:Bit8u;
{$if MAGIC_BREAKPOINT = 1}
  magic_break:Bit8u;
{$ifend}
  stop_reason:Bit8u;
  trace:Bit8u;
  trace_reg:Bit8u;
  mode_break:Bit8u;		//BW
  debug_vm:Bool;		// BW contains current mode
  show_eip:Bit8u;		// BW record eip at special instr f.ex eip
  show_flag:Bit8u;		// BW shows instr class executed
  //guard_found:bx_guard_found_t;
{$ifend}

  // for paging
{$if BX_USE_TLB = 1}
  TLB : record
    entry:array[0..BX_TLB_SIZE] of bx_TLB_entry;
  end;
{$ifend}

  address_xlation : record
    paddress1   :Bit32u;  // physical address after translation of 1st len1 bytes of data
    paddress2   :Bit32u;  // physical address after translation of 2nd len2 bytes of data
    len1        :Bit32u;       // number of bytes in page 1
    len2        :Bit32u;       // number of bytes in page 2
    pages       :Word;     // number of pages access spans (1 or 2)
  end;
  fake_end:byte;
  prog:LongWord;

  function GetIP:Bit16u; // (* (Bit16u *) (((Bit8u *) &BX_CPU_THIS_PTR eip) + BX_REG16_OFFSET))
  procedure SetIP(IPValue:Bit16u);
  // for lazy flags processing
  function get_OF:Bool; // OK
  function get_SF:Bool; // OK
  function get_ZF:Bool; // OK
  function get_AF:Bool; // OK
  function get_PF:Bool; // OK
  function get_CF:Bool; // OK

  function BX_READ_16BIT_REG(index:Word):Bit16u;
  function BX_READ_32BIT_REG(index:Word):Bit32u;

  function CPL:Bit8u;
  constructor Create;
  destructor  Destroy; override;

  // prototypes for CPU instructions...
  function BX_READ_8BIT_REG(index:Word):Bit8u;
  procedure BX_WRITE_8BIT_REG(index:Word; val:Bit8u);
  procedure BX_WRITE_16BIT_REG(index:Word; val:Bit16u);
  procedure ADD_EbGb(i:PBxInstruction_tag);
  procedure ADD_EdGd(I:PBxInstruction_tag);
  procedure ADD_GbEb(I:PBxInstruction_tag);
  procedure ADD_GdEd(I:PBxInstruction_tag);
  procedure ADD_ALIb(I:PBxInstruction_tag);
  procedure ADD_EAXId(I:PBxInstruction_tag);
  procedure OR_EbGb(I:PBxInstruction_tag);
  procedure OR_EdGd(I:PBxInstruction_tag);
  procedure OR_EwGw(I:PBxInstruction_tag);
  procedure OR_GbEb(I:PBxInstruction_tag);
  procedure OR_GdEd(I:PBxInstruction_tag);
  procedure OR_GwEw(I:PBxInstruction_tag);
  procedure OR_ALIb(I:PBxInstruction_tag);
  procedure OR_EAXId(I:PBxInstruction_tag);
  procedure OR_AXIw(I:PBxInstruction_tag);

  procedure PUSH_CS(I:PBxInstruction_tag);
  procedure PUSH_DS(I:PBxInstruction_tag);
  procedure POP_DS(I:PBxInstruction_tag);
  procedure PUSH_ES(I:PBxInstruction_tag);
  procedure POP_ES(I:PBxInstruction_tag);
  procedure PUSH_FS(I:PBxInstruction_tag);
  procedure POP_FS(I:PBxInstruction_tag);
  procedure PUSH_GS(I:PBxInstruction_tag);
  procedure POP_GS(I:PBxInstruction_tag);
  procedure PUSH_SS(I:PBxInstruction_tag);
  procedure POP_SS(I:PBxInstruction_tag);

  procedure ADC_EbGb(I:PBxInstruction_tag);
  procedure ADC_EdGd(I:PBxInstruction_tag);
  procedure ADC_GbEb(I:PBxInstruction_tag);
  procedure ADC_GdEd(I:PBxInstruction_tag);
  procedure ADC_ALIb(I:PBxInstruction_tag);
  procedure ADC_EAXId(I:PBxInstruction_tag);
  procedure SBB_EbGb(I:PBxInstruction_tag);
  procedure SBB_EdGd(I:PBxInstruction_tag);
  procedure SBB_GbEb(I:PBxInstruction_tag);
  procedure SBB_GdEd(I:PBxInstruction_tag);
  procedure SBB_ALIb(I:PBxInstruction_tag);
  procedure SBB_EAXId(I:PBxInstruction_tag);

  procedure AND_EbGb(I:PBxInstruction_tag);
  procedure AND_EdGd(I:PBxInstruction_tag);
  procedure AND_EwGw(I:PBxInstruction_tag);
  procedure AND_GbEb(I:PBxInstruction_tag);
  procedure AND_GdEd(I:PBxInstruction_tag);
  procedure AND_GwEw(I:PBxInstruction_tag);
  procedure AND_ALIb(I:PBxInstruction_tag);
  procedure AND_EAXId(I:PBxInstruction_tag);
  procedure AND_AXIw(I:PBxInstruction_tag);
  procedure DAA(I:PBxInstruction_tag);
  procedure SUB_EbGb(I:PBxInstruction_tag);
  procedure SUB_EdGd(I:PBxInstruction_tag);
  procedure SUB_GbEb(I:PBxInstruction_tag);
  procedure SUB_GdEd(I:PBxInstruction_tag);
  procedure SUB_ALIb(I:PBxInstruction_tag);
  procedure SUB_EAXId(I:PBxInstruction_tag);
  procedure DAS(I:PBxInstruction_tag);

  procedure XOR_EbGb(I:PBxInstruction_tag);
  procedure XOR_EdGd(I:PBxInstruction_tag);
  procedure XOR_EwGw(I:PBxInstruction_tag);
  procedure XOR_GbEb(I:PBxInstruction_tag);
  procedure XOR_GdEd(I:PBxInstruction_tag);
  procedure XOR_GwEw(I:PBxInstruction_tag);
  procedure XOR_ALIb(I:PBxInstruction_tag);
  procedure XOR_EAXId(I:PBxInstruction_tag);
  procedure XOR_AXIw(I:PBxInstruction_tag);
  procedure AAA(I:PBxInstruction_tag);
  procedure CMP_EbGb(I:PBxInstruction_tag);
  procedure CMP_EdGd(I:PBxInstruction_tag);
  procedure CMP_GbEb(I:PBxInstruction_tag);
  procedure CMP_GdEd(I:PBxInstruction_tag);
  procedure CMP_ALIb(I:PBxInstruction_tag);
  procedure CMP_EAXId(I:PBxInstruction_tag);
  procedure AAS(I:PBxInstruction_tag);

  procedure PUSHAD32(I:PBxInstruction_tag);
  procedure PUSHAD16(I:PBxInstruction_tag);
  procedure POPAD32(I:PBxInstruction_tag);
  procedure POPAD16(I:PBxInstruction_tag);
  procedure BOUND_GvMa(I:PBxInstruction_tag);
  procedure ARPL_EwGw(I:PBxInstruction_tag);
  procedure PUSH_Id(I:PBxInstruction_tag);
  procedure PUSH_Iw(I:PBxInstruction_tag);
  procedure IMUL_GdEdId(I:PBxInstruction_tag);
  procedure INSB_YbDX(I:PBxInstruction_tag);
  procedure INSW_YvDX(I:PBxInstruction_tag);
  procedure OUTSB_DXXb(I:PBxInstruction_tag);
  procedure OUTSW_DXXv(I:PBxInstruction_tag);

  procedure TEST_EbGb(I:PBxInstruction_tag);
  procedure TEST_EdGd(I:PBxInstruction_tag);
  procedure TEST_EwGw(I:PBxInstruction_tag);
  procedure XCHG_EbGb(I:PBxInstruction_tag);
  procedure XCHG_EdGd(I:PBxInstruction_tag);
  procedure XCHG_EwGw(I:PBxInstruction_tag);
  procedure MOV_EbGb(I:PBxInstruction_tag);
  procedure MOV_EdGd(I:PBxInstruction_tag);
  procedure MOV_EwGw(I:PBxInstruction_tag);
  procedure MOV_GbEb(I:PBxInstruction_tag);
  procedure MOV_GdEd(I:PBxInstruction_tag);
  procedure MOV_GwEw(I:PBxInstruction_tag);
  procedure MOV_EwSw(I:PBxInstruction_tag);
  procedure LEA_GdM(I:PBxInstruction_tag);
  procedure LEA_GwM(I:PBxInstruction_tag);
  procedure MOV_SwEw(I:PBxInstruction_tag);
(*  procedure POP_Ev(I:PBxInstruction_tag);*)

  procedure CBW(I:PBxInstruction_tag);
  procedure CWD(I:PBxInstruction_tag);
  procedure CALL32_Ap(I:PBxInstruction_tag);
  procedure CALL16_Ap(I:PBxInstruction_tag);
  procedure FWAIT(I:PBxInstruction_tag);
  procedure PUSHF_Fv(I:PBxInstruction_tag);
  procedure POPF_Fv(I:PBxInstruction_tag);
  procedure SAHF(I:PBxInstruction_tag);
  procedure LAHF(I:PBxInstruction_tag);

  procedure MOV_ALOb(I:PBxInstruction_tag);
  procedure MOV_EAXOd(I:PBxInstruction_tag);
  procedure MOV_AXOw(I:PBxInstruction_tag);
  procedure MOV_ObAL(I:PBxInstruction_tag);
  procedure MOV_OdEAX(I:PBxInstruction_tag);
  procedure MOV_OwAX(I:PBxInstruction_tag);
  procedure MOVSB_XbYb(I:PBxInstruction_tag);
  procedure MOVSW_XvYv(I:PBxInstruction_tag);
  procedure CMPSB_XbYb(I:PBxInstruction_tag);
  procedure CMPSW_XvYv(I:PBxInstruction_tag);
  procedure TEST_ALIb(I:PBxInstruction_tag);
  procedure TEST_EAXId(I:PBxInstruction_tag);
  procedure TEST_AXIw(I:PBxInstruction_tag);
  procedure STOSB_YbAL(I:PBxInstruction_tag);
  procedure STOSW_YveAX(I:PBxInstruction_tag);
  procedure LODSB_ALXb(I:PBxInstruction_tag);
  procedure LODSW_eAXXv(I:PBxInstruction_tag);
  procedure SCASB_ALXb(I:PBxInstruction_tag);
  procedure SCASW_eAXXv(I:PBxInstruction_tag);

  procedure RETnear32(I:PBxInstruction_tag);
  procedure RETnear16(I:PBxInstruction_tag);
  procedure LES_GvMp(I:PBxInstruction_tag);
  procedure LDS_GvMp(I:PBxInstruction_tag);
  procedure MOV_EbIb(I:PBxInstruction_tag);
  procedure MOV_EdId(I:PBxInstruction_tag);
  procedure MOV_EwIw(I:PBxInstruction_tag);
  procedure ENTER_IwIb(I:PBxInstruction_tag);
  procedure LEAVE(I:PBxInstruction_tag);
  procedure RETfar32(I:PBxInstruction_tag);
  procedure RETfar16(I:PBxInstruction_tag);

  procedure INT1(I:PBxInstruction_tag);
  procedure INT3(I:PBxInstruction_tag);
  procedure INT_Ib(I:PBxInstruction_tag);
  procedure INTO(I:PBxInstruction_tag);
  procedure IRET32(I:PBxInstruction_tag);
  procedure IRET16(I:PBxInstruction_tag);

  procedure AAM(I:PBxInstruction_tag);
  procedure AAD(I:PBxInstruction_tag);
  procedure SALC(I:PBxInstruction_tag);
  procedure XLAT(I:PBxInstruction_tag);

  procedure LOOPNE_Jb(I:PBxInstruction_tag);
  procedure LOOPE_Jb(I:PBxInstruction_tag);
  procedure LOOP_Jb(I:PBxInstruction_tag);
  procedure JCXZ_Jb(I:PBxInstruction_tag);
  procedure IN_ALIb(I:PBxInstruction_tag);
  procedure IN_eAXIb(I:PBxInstruction_tag);
  procedure OUT_IbAL(I:PBxInstruction_tag);
  procedure OUT_IbeAX(I:PBxInstruction_tag);
  procedure CALL_Aw(I:PBxInstruction_tag);
  procedure CALL_Ad(I:PBxInstruction_tag);
  procedure JMP_Jd(I:PBxInstruction_tag);
  procedure JMP_Jw(I:PBxInstruction_tag);
  procedure JMP_Ap(I:PBxInstruction_tag);
  procedure IN_ALDX(I:PBxInstruction_tag);
  procedure IN_eAXDX(I:PBxInstruction_tag);
  procedure OUT_DXAL(I:PBxInstruction_tag);
  procedure OUT_DXeAX(I:PBxInstruction_tag);

  procedure HLT(I:PBxInstruction_tag);
  procedure CMC(I:PBxInstruction_tag);
  procedure CLC(I:PBxInstruction_tag);
  procedure STC(I:PBxInstruction_tag);
  procedure CLI(I:PBxInstruction_tag);
  procedure STI(I:PBxInstruction_tag);
  procedure CLD(I:PBxInstruction_tag);
  procedure STD(I:PBxInstruction_tag);


  procedure LAR_GvEw(I:PBxInstruction_tag);
  procedure LSL_GvEw(I:PBxInstruction_tag);
  procedure CLTS(I:PBxInstruction_tag);
  procedure INVD(I:PBxInstruction_tag);
  procedure WBINVD(I:PBxInstruction_tag);

  procedure MOV_CdRd(I:PBxInstruction_tag);
  procedure MOV_DdRd(I:PBxInstruction_tag);
  procedure MOV_RdCd(I:PBxInstruction_tag);
  procedure MOV_RdDd(I:PBxInstruction_tag);
  procedure MOV_TdRd(I:PBxInstruction_tag);
  procedure MOV_RdTd(I:PBxInstruction_tag);

  procedure JCC_Jd(I:PBxInstruction_tag);
  procedure JCC_Jw(I:PBxInstruction_tag);

  procedure SETO_Eb(I:PBxInstruction_tag);
  procedure SETNO_Eb(I:PBxInstruction_tag);
  procedure SETB_Eb(I:PBxInstruction_tag);
  procedure SETNB_Eb(I:PBxInstruction_tag);
  procedure SETZ_Eb(I:PBxInstruction_tag);
  procedure SETNZ_Eb(I:PBxInstruction_tag);
  procedure SETBE_Eb(I:PBxInstruction_tag);
  procedure SETNBE_Eb(I:PBxInstruction_tag);
  procedure SETS_Eb(I:PBxInstruction_tag);
  procedure SETNS_Eb(I:PBxInstruction_tag);
  procedure SETP_Eb(I:PBxInstruction_tag);
  procedure SETNP_Eb(I:PBxInstruction_tag);
  procedure SETL_Eb(I:PBxInstruction_tag);
  procedure SETNL_Eb(I:PBxInstruction_tag);
  procedure SETLE_Eb(I:PBxInstruction_tag);
  procedure SETNLE_Eb(I:PBxInstruction_tag);

  procedure CPUID(I:PBxInstruction_tag);
  procedure BT_EvGv(I:PBxInstruction_tag);
  procedure SHLD_EdGd(I:PBxInstruction_tag);
  procedure SHLD_EwGw(I:PBxInstruction_tag);


  procedure BTS_EvGv(I:PBxInstruction_tag);

  procedure SHRD_EwGw(I:PBxInstruction_tag);
  procedure SHRD_EdGd(I:PBxInstruction_tag);

  procedure IMUL_GdEd(I:PBxInstruction_tag);

  procedure LSS_GvMp(I:PBxInstruction_tag);
  procedure BTR_EvGv(I:PBxInstruction_tag);
  procedure LFS_GvMp(I:PBxInstruction_tag);
  procedure LGS_GvMp(I:PBxInstruction_tag);
  procedure MOVZX_GdEb(I:PBxInstruction_tag);
  procedure MOVZX_GwEb(I:PBxInstruction_tag);
  procedure MOVZX_GdEw(I:PBxInstruction_tag);
  procedure MOVZX_GwEw(I:PBxInstruction_tag);
  procedure BTC_EvGv(I:PBxInstruction_tag);
  procedure BSF_GvEv(I:PBxInstruction_tag);
  procedure BSR_GvEv(I:PBxInstruction_tag);
  procedure MOVSX_GdEb(I:PBxInstruction_tag);
  procedure MOVSX_GwEb(I:PBxInstruction_tag);
  procedure MOVSX_GdEw(I:PBxInstruction_tag);
  procedure MOVSX_GwEw(I:PBxInstruction_tag);

  procedure BSWAP_EAX(I:PBxInstruction_tag);
  procedure BSWAP_ECX(I:PBxInstruction_tag);
  procedure BSWAP_EDX(I:PBxInstruction_tag);
  procedure BSWAP_EBX(I:PBxInstruction_tag);
  procedure BSWAP_ESP(I:PBxInstruction_tag);
  procedure BSWAP_EBP(I:PBxInstruction_tag);
  procedure BSWAP_ESI(I:PBxInstruction_tag);
  procedure BSWAP_EDI(I:PBxInstruction_tag);

  procedure ADD_EbIb(I:PBxInstruction_tag);
  procedure ADC_EbIb(I:PBxInstruction_tag);
  procedure SBB_EbIb(I:PBxInstruction_tag);
  procedure SUB_EbIb(I:PBxInstruction_tag);
  procedure CMP_EbIb(I:PBxInstruction_tag);

  procedure XOR_EbIb(I:PBxInstruction_tag);
  procedure OR_EbIb(I:PBxInstruction_tag);
  procedure AND_EbIb(I:PBxInstruction_tag);
  procedure ADD_EdId(I:PBxInstruction_tag);
  procedure OR_EdId(I:PBxInstruction_tag);
  procedure OR_EwIw(I:PBxInstruction_tag);
  procedure ADC_EdId(I:PBxInstruction_tag);
  procedure SBB_EdId(I:PBxInstruction_tag);
  procedure AND_EdId(I:PBxInstruction_tag);
  procedure AND_EwIw(I:PBxInstruction_tag);
  procedure SUB_EdId(I:PBxInstruction_tag);
  procedure XOR_EdId(I:PBxInstruction_tag);
  procedure XOR_EwIw(I:PBxInstruction_tag);
  procedure CMP_EdId(I:PBxInstruction_tag);

  procedure ROL_Eb(I:PBxInstruction_tag);
  procedure ROR_Eb(I:PBxInstruction_tag);
  procedure RCL_Eb(I:PBxInstruction_tag);
  procedure RCR_Eb(I:PBxInstruction_tag);
  procedure SHL_Eb(I:PBxInstruction_tag);
  procedure SHR_Eb(I:PBxInstruction_tag);
  procedure SAR_Eb(I:PBxInstruction_tag);

  procedure ROL_Ed(I:PBxInstruction_tag);
  procedure ROL_Ew(I:PBxInstruction_tag);
  procedure ROR_Ed(I:PBxInstruction_tag);
  procedure ROR_Ew(I:PBxInstruction_tag);
  procedure RCL_Ed(I:PBxInstruction_tag);
  procedure RCL_Ew(I:PBxInstruction_tag);
  procedure RCR_Ed(I:PBxInstruction_tag);
  procedure RCR_Ew(I:PBxInstruction_tag);
  procedure SHL_Ed(I:PBxInstruction_tag);
  procedure SHL_Ew(I:PBxInstruction_tag);
  procedure SHR_Ed(I:PBxInstruction_tag);
  procedure SHR_Ew(I:PBxInstruction_tag);
  procedure SAR_Ed(I:PBxInstruction_tag);
  procedure SAR_Ew(I:PBxInstruction_tag);   

  procedure TEST_EbIb(I:PBxInstruction_tag);
  procedure NOT_Eb(I:PBxInstruction_tag);
  procedure NEG_Eb(I:PBxInstruction_tag);
  procedure MUL_ALEb(I:PBxInstruction_tag);
  procedure IMUL_ALEb(I:PBxInstruction_tag);
  procedure DIV_ALEb(I:PBxInstruction_tag);
  procedure IDIV_ALEb(I:PBxInstruction_tag);

  procedure TEST_EdId(I:PBxInstruction_tag);
  procedure TEST_EwIw(I:PBxInstruction_tag);
  procedure NOT_Ed(I:PBxInstruction_tag);
  procedure NOT_Ew(I:PBxInstruction_tag);
  procedure NEG_Ed(I:PBxInstruction_tag);
  procedure MUL_EAXEd(I:PBxInstruction_tag);
  procedure IMUL_EAXEd(I:PBxInstruction_tag);
  procedure DIV_EAXEd(I:PBxInstruction_tag);
  procedure IDIV_EAXEd(I:PBxInstruction_tag);

  procedure INC_Eb(I:PBxInstruction_tag);
  procedure DEC_Eb(I:PBxInstruction_tag);

  procedure INC_Ed(I:PBxInstruction_tag);
  procedure DEC_Ed(I:PBxInstruction_tag);
  procedure CALL_Ed(I:PBxInstruction_tag);
  procedure CALL_Ew(I:PBxInstruction_tag);
  procedure CALL32_Ep(I:PBxInstruction_tag);
  procedure CALL16_Ep(I:PBxInstruction_tag);
  procedure JMP_Ed(I:PBxInstruction_tag);
  procedure JMP_Ew(I:PBxInstruction_tag);
  procedure JMP32_Ep(I:PBxInstruction_tag);
  procedure JMP16_Ep(I:PBxInstruction_tag);
  procedure PUSH_Ed(I:PBxInstruction_tag);
  procedure PUSH_Ew(I:PBxInstruction_tag);

  procedure SLDT_Ew(I:PBxInstruction_tag);
  procedure STR_Ew(I:PBxInstruction_tag);
  procedure LLDT_Ew(I:PBxInstruction_tag);
  procedure LTR_Ew(I:PBxInstruction_tag);
  procedure VERR_Ew(I:PBxInstruction_tag);
  procedure VERW_Ew(I:PBxInstruction_tag);

  procedure SGDT_Ms(I:PBxInstruction_tag);
  procedure SIDT_Ms(I:PBxInstruction_tag);
  procedure LGDT_Ms(I:PBxInstruction_tag);
  procedure LIDT_Ms(I:PBxInstruction_tag);
  procedure SMSW_Ew(I:PBxInstruction_tag);
  procedure LMSW_Ew(I:PBxInstruction_tag);


  procedure BT_EvIb(I:PBxInstruction_tag);
  procedure BTS_EvIb(I:PBxInstruction_tag);
  procedure BTR_EvIb(I:PBxInstruction_tag);
  procedure BTC_EvIb(I:PBxInstruction_tag);

  procedure ESC0(I:PBxInstruction_tag);
  procedure ESC1(I:PBxInstruction_tag);
  procedure ESC2(I:PBxInstruction_tag);
  procedure ESC3(I:PBxInstruction_tag);
  procedure ESC4(I:PBxInstruction_tag);
  procedure ESC5(I:PBxInstruction_tag);
  procedure ESC6(I:PBxInstruction_tag);
  procedure ESC7(I:PBxInstruction_tag);

(*  procedure fpu_print_regs;*)

  procedure CMPXCHG_XBTS(I:PBxInstruction_tag);
  procedure CMPXCHG_IBTS(I:PBxInstruction_tag);
  procedure CMPXCHG_EbGb(I:PBxInstruction_tag);
  procedure CMPXCHG_EdGd(I:PBxInstruction_tag);
  procedure CMPXCHG8B(I:PBxInstruction_tag);
  procedure XADD_EbGb(I:PBxInstruction_tag);
  procedure XADD_EdGd(I:PBxInstruction_tag);
  procedure RETnear32_Iw(I:PBxInstruction_tag);
  procedure RETnear16_Iw(I:PBxInstruction_tag);
  procedure RETfar32_Iw(I:PBxInstruction_tag);
  procedure RETfar16_Iw(I:PBxInstruction_tag);

  procedure LOADALL(I:PBxInstruction_tag);
  procedure CMOV_GdEd(I:PBxInstruction_tag);
  procedure CMOV_GwEw(I:PBxInstruction_tag);

  procedure ADD_EwGw(I:PBxInstruction_tag);
  procedure ADD_GwEw(I:PBxInstruction_tag);
  procedure ADD_AXIw(I:PBxInstruction_tag);
  procedure ADC_EwGw(I:PBxInstruction_tag);
  procedure ADC_GwEw(I:PBxInstruction_tag);
  procedure ADC_AXIw(I:PBxInstruction_tag);
  procedure SBB_EwGw(I:PBxInstruction_tag);
  procedure SBB_GwEw(I:PBxInstruction_tag);
  procedure SBB_AXIw(I:PBxInstruction_tag);
  procedure SBB_EwIw(I:PBxInstruction_tag);
  procedure SUB_EwGw(I:PBxInstruction_tag);
  procedure SUB_GwEw(I:PBxInstruction_tag);
  procedure SUB_AXIw(I:PBxInstruction_tag);
  procedure CMP_EwGw(I:PBxInstruction_tag);
  procedure CMP_GwEw(I:PBxInstruction_tag);
  procedure CMP_AXIw(I:PBxInstruction_tag);
  procedure CWDE(I:PBxInstruction_tag);
  procedure CDQ(I:PBxInstruction_tag);
  procedure XADD_EwGw(I:PBxInstruction_tag);
  procedure ADD_EwIw(I:PBxInstruction_tag);
  procedure ADC_EwIw(I:PBxInstruction_tag);
  procedure SUB_EwIw(I:PBxInstruction_tag);
  procedure CMP_EwIw(I:PBxInstruction_tag);
  procedure NEG_Ew(I:PBxInstruction_tag);
  procedure INC_Ew(I:PBxInstruction_tag);
  procedure DEC_Ew(I:PBxInstruction_tag);
  procedure CMPXCHG_EwGw(I:PBxInstruction_tag);
  procedure MUL_AXEw(I:PBxInstruction_tag);
  procedure IMUL_AXEw(I:PBxInstruction_tag);
  procedure DIV_AXEw(I:PBxInstruction_tag);
  procedure IDIV_AXEw(I:PBxInstruction_tag);
  procedure IMUL_GwEwIw(I:PBxInstruction_tag);
  procedure IMUL_GwEw(I:PBxInstruction_tag);
  procedure NOP(I:PBxInstruction_tag);
  procedure MOV_RLIb(I:PBxInstruction_tag);
  procedure MOV_RHIb(I:PBxInstruction_tag);
  procedure MOV_RXIw(I:PBxInstruction_tag);
  procedure MOV_ERXId(I:PBxInstruction_tag);
  procedure INC_RX(I:PBxInstruction_tag);
  procedure DEC_RX(I:PBxInstruction_tag);
  procedure INC_ERX(I:PBxInstruction_tag);
  procedure DEC_ERX(I:PBxInstruction_tag);
  procedure PUSH_RX(I:PBxInstruction_tag);
  procedure POP_RX(I:PBxInstruction_tag);
  procedure PUSH_ERX(I:PBxInstruction_tag);
  procedure POP_ERX(I:PBxInstruction_tag);
  procedure POP_Ew(I:PBxInstruction_tag);
  procedure POP_Ed(I:PBxInstruction_tag);
  procedure XCHG_RXAX(I:PBxInstruction_tag);
  procedure XCHG_ERXEAX(I:PBxInstruction_tag);

  // mch added
  procedure INVLPG(Instruction:PBxInstruction_tag);
//  procedure wait_for_interrupt();
  procedure RSM(I:PBxInstruction_tag);

  procedure WRMSR(I:PBxInstruction_tag);
  procedure RDTSC(I:PBxInstruction_tag);
  procedure RDMSR(I:PBxInstruction_tag);
  procedure SetCR0(val_32:Bit32u);
(*  procedure dynamic_translate;
  procedure dynamic_init;*)
  function FetchDecode(iptr:PBit8u; out instruction:BxInstruction_tag; out remain:Word;const is_32:Bool):Word;
  procedure UndefinedOpcode(Instruction:PBxInstruction_tag);
  procedure BxError(I:PBxInstruction_tag);
  procedure BxResolveError(I:PBxInstruction_tag);

  procedure Resolve16Mod0Rm0(I:PBxInstruction_tag);
  procedure Resolve16Mod0Rm1(I:PBxInstruction_tag);
  procedure Resolve16Mod0Rm2(I:PBxInstruction_tag);
  procedure Resolve16Mod0Rm3(I:PBxInstruction_tag);
  procedure Resolve16Mod0Rm4(I:PBxInstruction_tag);
  procedure Resolve16Mod0Rm5(I:PBxInstruction_tag);
  procedure Resolve16Mod0Rm7(I:PBxInstruction_tag);

  procedure Resolve16Mod1or2Rm0(I:PBxInstruction_tag);
  procedure Resolve16Mod1or2Rm1(I:PBxInstruction_tag);
  procedure Resolve16Mod1or2Rm2(I:PBxInstruction_tag);
  procedure Resolve16Mod1or2Rm3(I:PBxInstruction_tag);
  procedure Resolve16Mod1or2Rm4(I:PBxInstruction_tag);
  procedure Resolve16Mod1or2Rm5(I:PBxInstruction_tag);
  procedure Resolve16Mod1or2Rm6(I:PBxInstruction_tag);
  procedure Resolve16Mod1or2Rm7(I:PBxInstruction_tag);

  procedure Resolve32Mod0Rm0(I:PBxInstruction_tag);
  procedure Resolve32Mod0Rm1(I:PBxInstruction_tag);
  procedure Resolve32Mod0Rm2(I:PBxInstruction_tag);
  procedure Resolve32Mod0Rm3(I:PBxInstruction_tag);
  procedure Resolve32Mod0Rm6(I:PBxInstruction_tag);
  procedure Resolve32Mod0Rm7(I:PBxInstruction_tag);

  procedure Resolve32Mod1or2Rm0(I:PBxInstruction_tag);
  procedure Resolve32Mod1or2Rm1(I:PBxInstruction_tag);
  procedure Resolve32Mod1or2Rm2(I:PBxInstruction_tag);
  procedure Resolve32Mod1or2Rm3(I:PBxInstruction_tag);
  procedure Resolve32Mod1or2Rm5(I:PBxInstruction_tag);
  procedure Resolve32Mod1or2Rm6(I:PBxInstruction_tag);
  procedure Resolve32Mod1or2Rm7(I:PBxInstruction_tag);

  procedure Resolve32Mod0Base0(I:PBxInstruction_tag);
  procedure Resolve32Mod0Base1(I:PBxInstruction_tag);
  procedure Resolve32Mod0Base2(I:PBxInstruction_tag);
  procedure Resolve32Mod0Base3(I:PBxInstruction_tag);
  procedure Resolve32Mod0Base4(I:PBxInstruction_tag);
  procedure Resolve32Mod0Base5(I:PBxInstruction_tag);
  procedure Resolve32Mod0Base6(I:PBxInstruction_tag);
  procedure Resolve32Mod0Base7(I:PBxInstruction_tag);

  procedure Resolve32Mod1or2Base0(I:PBxInstruction_tag);
  procedure Resolve32Mod1or2Base1(I:PBxInstruction_tag);
  procedure Resolve32Mod1or2Base2(I:PBxInstruction_tag);
  procedure Resolve32Mod1or2Base3(I:PBxInstruction_tag);
  procedure Resolve32Mod1or2Base4(I:PBxInstruction_tag);
  procedure Resolve32Mod1or2Base5(I:PBxInstruction_tag);
  procedure Resolve32Mod1or2Base6(I:PBxInstruction_tag);
  procedure Resolve32Mod1or2Base7(I:PBxInstruction_tag);
  procedure cpu_loop;
  procedure prefetch;

(*  procedure REP(P:Pointer);
  procedure REP_ZF(P:Pointer; rep_prefix:Word);

  procedure atexit;

  // now for some ancillary functions...
  //procedure decode_exgx16(need_fetch:Word);
  //procedure decode_exgx32(mod_rm:Word);*)

  procedure revalidate_prefetch_q;
  procedure invalidate_prefetch_q;

  procedure write_virtual_checks(seg:pbx_segment_reg_t; offset:Bit32u; length:Bit32u);

  procedure read_virtual_checks(seg:pbx_segment_reg_t;  offset:Bit32u; length:Word);

  procedure write_virtual_byte(s:Word; offset:Bit32u; data:PBit8u);
  procedure write_virtual_word(s:Word; offset:Bit32u; data:PBit16u);
  procedure write_virtual_dword(s:Word; offset:Bit32u; data:PBit32u);
  procedure read_virtual_byte(s:Word; offset:Bit32u; data:PBit8u);
  procedure read_virtual_word(s:Word; offset:Bit32u; data:PBit16u);
  procedure read_virtual_dword(s:Word; offset:Bit32u; data:PBit32u);

  procedure read_RMW_virtual_byte(s:Word; offset:Bit32u; data:PBit8u);
  procedure read_RMW_virtual_word(s:Word; offset:Bit32u; data:PBit16u);
  procedure read_RMW_virtual_dword(s:Word; offset:Bit32u; data:PBit32u);
  procedure write_RMW_virtual_byte(val8:Bit8u);
  procedure write_RMW_virtual_word(val16:Bit16u);
  procedure write_RMW_virtual_dword(val32:Bit32u);

  procedure access_linear(const laddress:Bit32u; const length:unsigned; const pl:unsigned; rw:unsigned; data:Pointer);
  function itranslate_linear(laddress:Bit32u; pl:unsigned):Bit32u;
  function dtranslate_linear(laddress:Bit32u; pl:unsigned; rw:unsigned):Bit32u;
  procedure TLB_flush;
  procedure TLB_clear;
  procedure TLB_init;
  procedure set_INTR(value:Bool);
  function strseg(seg:Pbx_segment_reg_t):PChar;
  procedure interrupt(vector:Bit8u; is_INT:Bool; is_error_code:Bool;error_code:Bit16u);

{$if BX_CPU_LEVEL >= 2}
  procedure exception(vector:unsigned;error_code:Bit16u;is_INT:Bool);
{$ifend}
  function int_number(seg:pbx_segment_reg_t):Integer;
  procedure shutdown_cpu;
  procedure enable_paging;
  procedure disable_paging;
  procedure CR3_change(value32:Bit32u);
  procedure reset(source:unsigned);

  procedure jump_protected(Istr:PBxInstruction_tag; cs_raw:Bit16u; disp32:Bit32u);
  procedure call_protected(I:PBxInstruction_tag; cs_raw:Bit16u; disp32:Bit32u);
  procedure return_protected(I:PBxInstruction_tag; pop_bytes:Bit16u);
  procedure iret_protected(I:PBxInstruction_tag);
  procedure validate_seg_regs;
  procedure stack_return_to_v86(new_eip:Bit32u; raw_cs_selector:Bit32u;flags32:Bit32u);
  procedure stack_return_from_v86(I:PBxInstruction_tag);
  procedure init_v8086_mode;
  (*procedure v8086_message;*)
  procedure task_switch(tss_selector:pbx_selector_t; tss_descriptor:pbx_descriptor_t;source:unsigned;
                     dword1:Bit32u; dword2:Bit32u);
  procedure get_SS_ESP_from_TSS(pl:unsigned; ss:PBit16u; esp:PBit32u);
  procedure write_flags(flags:Bit16u; change_IOPL:Bool; change_IF:Bool);
  procedure write_eflags(eflags_raw:Bit32u; change_IOPL:Bool ; change_IF:Bool;change_VM:Bool; change_RF:Bool);
  function read_flags:Bit16u;
  function read_eflags:Bit32u;

  function inp8(addr:Bit16u):Bit8u;
  procedure outp8(addr:Bit16u; value:Bit8u);
  function inp16(addr:Bit16u):Bit16u;
  procedure outp16(addr:Bit16u; value:Bit16u);
  function inp32(addr:Bit16u):Bit32u;
  procedure outp32(addr:Bit16u; value:Bit32u);
  function allow_io(addr:Bit16u; len:unsigned):Bool;
  procedure    enter_protected_mode;
  procedure    enter_real_mode;
  procedure    parse_selector(raw_selector:Bit16u; selector:pbx_selector_t);
  procedure    parse_descriptor(dword1:Bit32u;dword2:Bit32u;temp:pbx_descriptor_t);
  procedure    load_ldtr(selector:pbx_selector_t; descriptor:pbx_descriptor_t);
  procedure    load_cs(selector:pbx_selector_t; descriptor:pbx_descriptor_t; cpl:Bit8u);
  procedure    load_ss(selector:pbx_selector_t; descriptor:pbx_descriptor_t; cpl:Bit8u);
  procedure    fetch_raw_descriptor(selector:pbx_selector_t;
                               dword1:pBit32u; dword2:pBit32u; exception_no:Bit8u);
  procedure    load_seg_reg(seg:pbx_segment_reg_t; new_value:Bit16u);
  function     fetch_raw_descriptor2(selector:pbx_selector_t; dword1:pBit32u; dword2:pBit32u):Bool;
  procedure    push_16(value16:Bit16u);
  procedure    push_32(value32:Bit32u);
  procedure    pop_16(value16_ptr:pBit16u);
  procedure    pop_32(value32_ptr:pBit32u);
  function     can_push(descriptor:pbx_descriptor_t; esp:Bit32u; bytes:Bit32u ):Bool;
  function     can_pop(bytes:Bit32u):Bool ;
  procedure    sanity_checks;

(*  procedure    debug(offset:Bit32u);*)

  procedure set_CF(val:Bool);
  procedure set_AF(val:Bool);
  procedure set_SF(val:Bool);
  procedure set_OF(val:Bool);
  procedure set_PF(val:Bool);
  procedure set_PF_base(val:Bit8u);

{$if BX_CPU_LEVEL >= 2}
   function real_mode:Bool;
{$ifend}
{$if BX_CPU_LEVEL >= 3}
  function v8086_mode:Bool;
{$ifend}
{$if BX_SUPPORT_APIC = 1}
  bx_local_apic_c local_apic;
  Bool int_from_local_apic;
{$ifend}

  procedure init(addrspace:BX_MEM_C);
  procedure set_ZF(val:Bool);

  procedure SET_FLAGS_OSZAPC_8(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word);
  procedure SET_FLAGS_OSZAPC_8_CF(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word; last_CF:Bool);
  procedure SET_FLAGS_OSZAP_8(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word);
  procedure SET_FLAGS_OSZAPC_16(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word);
  procedure SET_FLAGS_OSZAP_16(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word);
  procedure SET_FLAGS_OSZAPC_16_CF(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word; last_CF:Bool);
  procedure SET_FLAGS_OSZAP_32(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word);
  procedure SET_FLAGS_OSZAPC_32(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word);
  procedure SET_FLAGS_OSZAPC_32_CF(op1:Bit32u; op2:Bit32u; result:Bit32u; ins:Word; last_CF:Bool);
  procedure SET_FLAGS_OxxxxC(new_of, new_cf:Bool);

  procedure BX_WRITE_32BIT_REG(index:Word; val:bit32u);
  procedure Prova(Valore:PInteger);

  property AL :bit8u read gen_reg[0].rl write gen_reg[0].rl;
  property CL :bit8u read gen_reg[1].rl write gen_reg[1].rl;
  property DL :bit8u read gen_reg[2].rl write gen_reg[2].rl;
  property BL :bit8u read gen_reg[3].rl write gen_reg[3].rl;
  property AH :bit8u read gen_reg[0].rh write gen_reg[0].rh;
  property CH :bit8u read gen_reg[1].rh write gen_reg[1].rh;
  property DH :bit8u read gen_reg[2].rh write gen_reg[2].rh;
  property BH :bit8u read gen_reg[3].rh write gen_reg[3].rh;

  property AX :bit16u read gen_reg[0].rx write gen_reg[0].rx;
  property CX :bit16u read gen_reg[1].rx write gen_reg[1].rx;
  property DX :bit16u read gen_reg[2].rx write gen_reg[2].rx;
  property BX :bit16u read gen_reg[3].rx write gen_reg[3].rx;
  property SP :bit16u read gen_reg[4].rx write gen_reg[4].rx;
  property BP :bit16u read gen_reg[5].rx write gen_reg[5].rx;
  property SI :bit16u read gen_reg[6].rx write gen_reg[6].rx;
  property DI :bit16u read gen_reg[7].rx write gen_reg[7].rx;
  property EAX:bit32u read gen_reg[0].erx write gen_reg[0].erx;
  property ECX:bit32u read gen_reg[1].erx write gen_reg[1].erx;
  property EDX:bit32u read gen_reg[2].erx write gen_reg[2].erx;
  property EBX:bit32u read gen_reg[3].erx write gen_reg[3].erx;
  property ESP:bit32u read gen_reg[4].erx write gen_reg[4].erx;
  property EBP:bit32u read gen_reg[5].erx write gen_reg[5].erx;
  property ESI:bit32u read gen_reg[6].erx write gen_reg[6].erx;
  property EDI:bit32u read gen_reg[7].erx write gen_reg[7].erx;

  property IP:Bit16u read GetIP write SetIP;

  property IOPL:Bit8u read eflags.iopl write eflags.iopl;

  end; // BX_CPU_C
{$endif}

const COUNTER_INTERVAL:Bit64u = 100000;

var
  ips_count:Int64;
  m_ips:double;
  stoprun:boolean=True;

  bx_cpu:BX_CPU_C;
  BxResolve16mod0       :array[0..7] of TBxInstruction_t;
  BxResolve16mod1or2    :array[0..7] of TBxInstruction_t;
  BxResolve32mod0       :array[0..7] of TBxInstruction_t;
  BxResolve32mod1or2    :array[0..7] of TBxInstruction_t;
  BxResolve32mod0Base   :array[0..7] of TBxInstruction_t;
  BxResolve32mod1or2Base:array[0..7] of TBxInstruction_t;
  BxOpcodeInfoG1EbIb    :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG1Ew      :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG1Ed      :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG2Eb      :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG2Ew      :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG2Ed      :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG3Eb      :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG3Ew      :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG3Ed      :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG4        :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG5w       :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG5d       :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG6        :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG7        :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG8EvIb    :array[0..7] of BxOpcodeInfo_t;
  BxOpcodeInfoG9        :array[0..7] of BxOpcodeInfo_t;

  BxOpcodeInfo          :array[0..1028] of BxOpcodeInfo_t;

  bx_pc_system:bx_pc_system_c;

  procedure InitSystem;

var
  savejump:jmp_buf;
implementation

uses Iodev,dma,pic,cmos,{$if BX_USE_NEW_PIT=1} pit_wrap{$else} pit,
  Service_fpu {$ifend},
     gui32,keyboard,Forms;

var
  bx_dma:bx_dma_c;

{$include InitSystem.pas}

function bx_pc_system_c.ticks_remaining(index:Integer):Int64;
begin
	Result:=timer[index].remaining;
end;

procedure bx_pc_system_c.tickn(n:Bit64u);
begin
  ips_count := ips_count + n;
    if (num_cpu_ticks_left > n) then
      begin
        dec(num_cpu_ticks_left, n);
        exit;
      end;
    while (n >= num_cpu_ticks_left) do
      begin
        n := n - num_cpu_ticks_left;
        num_cpu_ticks_left := 0;
        timer_handler();
      end;
end;

  // constructor
constructor bx_pc_system_c.Create;
var
  I:Word;
begin

  //Self^.put('SYS');

  num_timers := 0;
  // set ticks period and remaining to max Bit32u value
  num_cpu_ticks_left := Bit32u(-1);
  num_cpu_ticks_in_period := num_cpu_ticks_left;
  m_ips := 0.0;

  for I:=0 to 8 do //for (unsigned int i:=0; i < 8; i++)
    begin
      DRQ[i] := 0;
      DACK[i] := 0;
    end;
  TC := 0;
  HRQ := 0;
  HLDA := 0;

  enable_a20 := 1;
  //set_INTR (0);

{$if BX_CPU_LEVEL < 2}
  a20_mask   :=    $fffff;
{$elseif BX_CPU_LEVEL = 2}
  a20_mask   :=   $ffffff;
{$else} (* 386+ *)
  a20_mask   := $ffffffff;
{$ifend}

  counter := 0;
  init_ips(CPU_SPEED);
  COUNTER_INTERVAL:=100000;
  counter_timer_index := register_timer_ticks(Self, Self.counter_timer_handler, COUNTER_INTERVAL, 1, 1);
end;

procedure bx_pc_system_c.init_ips(ips:Bit32u);
begin
  // parameter 'ips' is the processor speed in Instructions-Per-Second
  m_ips := ips / 1000000.0;
  //BX_DEBUG(Format('ips := %u', [ips]));
end;

procedure bx_pc_system_c.raise_HLDA;
begin
  HLDA := 1;
  bx_devices.raise_hlda();
  HLDA := 0;
end;

  procedure
bx_pc_system_c.set_DRQ(channel:unsigned; val:bool);
begin
  if (channel > 7) then
    BX_PANIC(('set_DRQ() channel > 7'));
  DRQ[channel] := val;
  bx_devices.drq(channel, val);
end;

procedure bx_pc_system_c.set_HRQ(val:bool);
begin
  HRQ := val;
  if (val)<>0 then
    bx_cpu.async_event := 1
  else
    HLDA := 0; // ??? needed?
end;

  procedure
bx_pc_system_c.set_TC(val:bool);
begin
  TC := val;
end;

  procedure
bx_pc_system_c.set_DACK(channel:unsigned; val:Bool);
begin
  DACK[channel] := val;
end;

procedure bx_pc_system_c.dma_write8(phy_addr:Bit32u; channel:unsigned; verify:Bool);
var
  data_byte:Bit8u;
begin
  // DMA controlled xfer of byte from I/O to Memory

  bx_devices.dma_write8(channel, @data_byte);
  if (verify=0) then begin
    sysmemory.write_physical(phy_addr, 1, @data_byte);

    //BX_DBG_DMA_REPORT(phy_addr, 1, BX_WRITE, data_byte);
    end;
end;

procedure bx_pc_system_c.dma_read8(phy_addr:Bit32u; channel:unsigned);
var
  data_byte:Bit8u;
begin
  // DMA controlled xfer of byte from Memory to I/O

  sysmemory.read_physical(phy_addr, 1, @data_byte);
  bx_devices.dma_read8(channel, @data_byte);

  //BX_DBG_DMA_REPORT(phy_addr, 1, BX_READ, data_byte);
end;

procedure bx_pc_system_c.dma_write16(phy_addr:Bit32u; channel:unsigned; verify:Bool);
var
  data_word:Bit16u;
begin
  // DMA controlled xfer of word from I/O to Memory

  bx_devices.dma_write16(channel, @data_word);
  if (verify=0) then begin
    sysmemory.write_physical(phy_addr, 2, @data_word);

    //BX_DBG_DMA_REPORT(phy_addr, 2, BX_WRITE, data_word);
    end;
end;

procedure bx_pc_system_c.dma_read16(phy_addr:Bit32u; channel:unsigned);
var
  data_word:Bit16u;
begin
  // DMA controlled xfer of word from Memory to I/O

  sysmemory.read_physical(phy_addr, 2, @data_word);
  bx_devices.dma_read16(channel, @data_word);

  //BX_DBG_DMA_REPORT(phy_addr, 2, BX_READ, data_word);
end;

procedure bx_pc_system_c.set_INTR(value:bool);
begin
	if(1=0) then
	  BX_INFO(Format('pc_system: Setting INTR:=%d on bootstrap processor %d', [value, BX_BOOTSTRAP_PROCESSOR]));
  //INTR := value;
  bx_cpu.set_INTR(value);
end;

//
// Read from the IO memory address space
//

function bx_pc_system_c.inp(addr:Bit16u; io_len:unsigned):Bit32u;
var
  ret:Bit32u;
begin

  ret := bx_devices.inp(addr, io_len);

  Result:= ret ;
end;

//
// Write to the IO memory address space.
//

procedure bx_pc_system_c.outp(addr:Bit16u; value:Bit32u; io_len:unsigned);
begin
  bx_devices.outp(addr, value, io_len);
end;

procedure bx_pc_system_c.set_enable_a20(value:Bit8u);
begin
{$if BX_CPU_LEVEL < 2}
    BX_PANIC(('set_enable_a20() called: 8086 emulation'));
{$else}

{$if BX_SUPPORT_A20=1}
  if (value)<>0 then begin
    enable_a20 := 1;
{$if BX_CPU_LEVEL = 2}
    a20_mask   := $ffffff;   (* 286: enable all 24 address lines *)
{$else} (* 386+ *)
    a20_mask   := $ffffffff; (* 386: enable all 32 address lines *)
{$ifend}
    end
  else begin
    enable_a20 := 0;
    a20_mask   := $ffefffff;   (* mask off A20 address line *)
    end;

  //BX_DBG_A20_REPORT(value);

  BX_DEBUG(Format('A20: set() := %u', [enable_a20]));
{$else}
  BX_DEBUG(('set_enable_a20: ignoring: SUPPORT_A20 := 0'));
{$ifend}  // #if BX_SUPPORT_A20

{$ifend}
end;

function bx_pc_system_c.get_enable_a20:Bool;
begin
{$if BX_SUPPORT_A20=1}
  BX_INFO(Format('A20: get() := %u',[enable_a20]));

  if (enable_a20)<>0 then begin Result:=1; exit; end
  else begin Result:=0; exit; end;
{$else}
  BX_INFO(('get_enable_a20: ignoring: SUPPORT_A20 := 0'));
  return(1);
{$ifend}  // #if BX_SUPPORT_A20
end;

function bx_pc_system_c.ResetSignal( operation:PCS_OP ):Integer;
begin
  //UNUSED( operation );
  // Reset the processor.

  BX_ERROR(( '# bx_pc_system_c.ResetSignal() called' ));
  {for (int i:=0; i<BX_SMP_PROCESSORS; i++)
    BX_CPU(i)^.reset(BX_RESET_SOFTWARE);}
  Result:=0;
end;

function bx_pc_system_c.IAC:Bit8u;
begin
  Result:=bx_pic.IAC();
end;

procedure bx_pc_system_c.exit;
begin
{  if bx_devices.hard_drive) then
    bx_devices.hard_drive^.close_harddrive();}
  //BX_INFO(Format('Last time is %d',[bx_cmos.s.timeval])); !!! MANCA
  //bx_gui.exit();
end;


//
// bochs timer support
//

procedure bx_pc_system_c.timer_handler;
var
  min:Bit64u;
  i:unsigned;
  delta:Bit64u;
begin

  //  BX_ERROR(( 'Time handler ptime := %d', bx_pc_system.time_ticks() ));

  delta := num_cpu_ticks_in_period - num_cpu_ticks_left;
{$if BX_TIMER_DEBUG=1}
  if (num_cpu_ticks_left <> 0)
    BX_PANIC(('timer_handler: ticks_left!:=0'));
{$ifend}

  for i:=0 to num_timers do
    begin
      timer[i].triggered := 0;
      if (timer[i].active)<>0 then begin
      timer[i].remaining := timer[i].remaining - delta;
      if (timer[i].remaining = 0) then begin
        timer[i].triggered := 1;
        // reset remaining period for triggered timer
        timer[i].remaining := timer[i].period;

        // if triggered timer is one-shot, deactive
        if (timer[i].continuous=0) then
          timer[i].active := 0;
        end;
      end;
    end;

  min := LongWord(-1); // max number in Bit64u range
  for i:=0 to num_timers do
    begin
    if ((timer[i].active<>0) and (timer[i].remaining < min)) then
      min := timer[i].remaining;
    end;
  num_cpu_ticks_left := min;
  num_cpu_ticks_in_period := num_cpu_ticks_left;

  for  i:=0 to num_timers do begin
    // call requested timer function.  It may request a different
    // timer period or deactivate, all cases handled below
    if (timer[i].triggered)<>0 then begin
      timer[i].funct(timer[i].this_ptr);
      end;
    end;
end;

procedure bx_pc_system_c.expire_ticks;
var
  i:unsigned;
  ticks_delta:Bit64u;
begin

  ticks_delta := num_cpu_ticks_in_period - num_cpu_ticks_left;
  if (ticks_delta = 0) then exit; // no ticks occurred since
  for i:=0 to num_timers do begin
    if (timer[i].active)<>0 then begin
      timer[i].remaining := timer[i].remaining - ticks_delta; // must be >= 1 here
      end;
    end;

  // set new period to number of ticks left
  num_cpu_ticks_in_period := num_cpu_ticks_left;
end;

function bx_pc_system_c.register_timer( this_ptr:Pointer; funct:bx_timer_handler_t; useconds:Bit32u; continuous:Bool;active:Bool):Integer;
var
  instructions:Bit64u;
begin

  if (num_timers >= BX_MAX_TIMERS) then begin
    BX_PANIC(('register_timer: too many registered timers.'));
    end;

  if (this_ptr = NULL) then
    BX_PANIC(('register_timer: this_ptr is NULL'));
  if (@funct = nil) then
    BX_PANIC(('register_timer: funct is NULL'));

  // account for ticks up to now
  expire_ticks();

  // convert useconds to number of instructions
  instructions := Trunc(useconds * m_ips);
  if((useconds<>0) and (instructions=0)) then instructions := 1;

  Result:= register_timer_ticks(this_ptr, funct, instructions, continuous, active);
end;

function bx_pc_system_c.register_timer_ticks(this_ptr:Pointer; funct:bx_timer_handler_t; Instructions:Bit64u; continuous:Bool; active:Bool):Integer;
var
  i:Word;
begin

  if (num_timers >= BX_MAX_TIMERS) then begin
    BX_PANIC(('register_timer: too many registered timers.'));
    end;

  if (this_ptr = NULL) then
    BX_PANIC(('register_timer: this_ptr is NULL'));
  if (@funct = NULL) then
    BX_PANIC(('register_timer: funct is NULL'));

  i := num_timers;
  inc(num_timers);
  timer[i].period    := instructions;
  timer[i].remaining := instructions;
  timer[i].active    := active;
  timer[i].funct     := funct;
  timer[i].continuous := continuous;
  timer[i].this_ptr   := this_ptr;

  if (active)<>0 then begin
    if (num_cpu_ticks_in_period = 0) then begin
      // no active timers
      num_cpu_ticks_in_period := instructions;
      num_cpu_ticks_left      := instructions;
      end
  else begin
      if (instructions < num_cpu_ticks_left) then begin
        num_cpu_ticks_in_period := instructions;
        num_cpu_ticks_left      := instructions;
        end;
      end;
    end;

  // return timer id
  Result:=i;
end;

procedure bx_pc_system_c.counter_timer_handler(this_ptr:Pointer);
begin
   Inc(Self.counter);
end;

function bx_pc_system_c.time_usec:Bit64u;
begin
  Result:= Trunc(time_ticks() / m_ips );
end;

function bx_pc_system_c.time_ticks:Bit64u;
begin
      Result:= (counter + 1) * COUNTER_INTERVAL
	    - ticks_remaining(counter_timer_index)
	    + (Bit64u(num_cpu_ticks_in_period) - Bit64u(num_cpu_ticks_left));
end;

procedure bx_pc_system_c.start_timers;
begin
end;

procedure bx_pc_system_c.activate_timer_ticks (timer_index:unsigned; instructions:Bit64u; continuous:Bool);
begin
  if (timer_index >= num_timers) then
    BX_PANIC(('activate_timer(): bad timer index given'));

  // set timer continuity to new value (1:=continuous, 0:=one-shot)
  timer[timer_index].continuous := continuous;

  timer[timer_index].active := 1;
  timer[timer_index].remaining := instructions;

  if (num_cpu_ticks_in_period = 0) then begin
    // no active timers
    num_cpu_ticks_in_period := instructions;
    num_cpu_ticks_left      := instructions;
    end
  else begin
    if (instructions < num_cpu_ticks_left) then begin
      num_cpu_ticks_in_period := instructions;
      num_cpu_ticks_left      := instructions;
      end;
    end;
end;

procedure bx_pc_system_c.activate_timer( timer_index:unsigned; useconds:Bit32u; continuous:Bool);
var
  instructions:Bit64u;
begin

  if (timer_index >= num_timers) then
    BX_PANIC(('activate_timer(): bad timer index given'));

  // account for ticks up to now
  expire_ticks();

  // set timer continuity to new value (1:=continuous, 0:=one-shot)
  timer[timer_index].continuous := continuous;

  // if useconds := 0, use default stored in period field
  // else set new period from useconds
  if (useconds=0) then
    instructions := timer[timer_index].period
  else begin
    // convert useconds to number of instructions
    instructions := Trunc(useconds * m_ips);
    if(instructions=0) then instructions := 1;
    timer[timer_index].period := instructions;
    end;

  timer[timer_index].active := 1;
  timer[timer_index].remaining := instructions;

  if (num_cpu_ticks_in_period = 0) then begin
    // no active timers
    num_cpu_ticks_in_period := instructions;
    num_cpu_ticks_left      := instructions;
    end
  else begin
    if (instructions < num_cpu_ticks_left) then begin
      num_cpu_ticks_in_period := instructions;
      num_cpu_ticks_left      := instructions;
      end;
    end;
end;

procedure bx_pc_system_c.deactivate_timer( timer_index:unsigned );
begin
  if (timer_index >= num_timers) then
    BX_PANIC(('deactivate_timer(): bad timer index given'));

  timer[timer_index].active := 0;
end;

procedure BX_CPU_C.Prova(Valore:PInteger);
begin

end;

{$include flags.pas}
{$include paging.pas}
{$include arith8.pas}
{$include arith16.pas}
{$include arith32.pas}
{$include Logical8.pas}
{$include Logical16.pas}
{$include Logical32.pas}
{$include Mult8.pas}
{$include Mult16.pas}
{$include Mult32.pas}
{$include Stack_pro.pas}
{$include Proc_ctrl.pas}
{$include Bit.pas}
{$include segment_ctrl_pro.pas}
{$include tasking.pas}
{$include init.pas}
{$include protect_ctrl_pro.pas}
{$include resolve16.pas}
{$include resolve32.pas}
{$include data_xfer8.pas}
{$include stack16.pas}
{$include soft_int.pas}
{$include ctrl_xfer8.pas}
{$include flag_ctrl.pas}
{$include io_pro.pas}
{$include segment_ctrl.pas}
{$include flag_ctrl_pro.pas}
{$include io.pas}
{$include data_xfer32.pas}
{$include data_xfer16.pas}
{$include shift8.pas}
{$include shift32.pas}
{$include bcd.pas}
{$include ctrl_xfer16.pas}
{$include ctrl_xfer32.pas}
{$include ctrl_xfer_pro.pas}
{$include protect_ctrl.pas}
{$include shift16.pas}
{$include stack32.pas}
{$include vm8086.pas}
{$include string.pas}
{$include fetchunit.pas}
{$include exception.pas}
{$include fpu.pas}

function BX_CPU_C.get_SF:Bool;
begin
  case ( (lf_flags_status shr 16) and $00000f ) of
    BX_LF_INDEX_KNOWN:
      begin
        Result:=eflags.sf;
        exit;
      end;
    BX_LF_INDEX_OSZAPC:
      begin
        case oszapc.instr of
          BX_INSTR_ADD8,
          BX_INSTR_ADC8,
          BX_INSTR_SUB8,
          BX_INSTR_SBB8,
          BX_INSTR_CMP8,
          BX_INSTR_NEG8,
          BX_INSTR_XADD8,
          BX_INSTR_OR8,
          BX_INSTR_AND8,
          BX_INSTR_TEST8,
          BX_INSTR_XOR8,
          BX_INSTR_CMPS8,
          BX_INSTR_SCAS8,
          BX_INSTR_SHR8,
          BX_INSTR_SHL8:
            begin
              eflags.sf := Word(oszapc.result_8 >= $80);
            end;
          BX_INSTR_ADD16,
          BX_INSTR_ADC16,
          BX_INSTR_SUB16,
          BX_INSTR_SBB16,
          BX_INSTR_CMP16,
          BX_INSTR_NEG16,
          BX_INSTR_XADD16,
          BX_INSTR_OR16,
          BX_INSTR_AND16,
          BX_INSTR_TEST16,
          BX_INSTR_XOR16,
          BX_INSTR_CMPS16,
          BX_INSTR_SCAS16,
          BX_INSTR_SHR16,
          BX_INSTR_SHL16:
            begin
              eflags.sf := Word(oszapc.result_16 >= $8000);
              
            end;
          BX_INSTR_ADD32,
          BX_INSTR_ADC32,
          BX_INSTR_SUB32,
          BX_INSTR_SBB32,
          BX_INSTR_CMP32,
          BX_INSTR_NEG32,
          BX_INSTR_XADD32,
          BX_INSTR_OR32,
          BX_INSTR_AND32,
          BX_INSTR_TEST32,
          BX_INSTR_XOR32,
          BX_INSTR_CMPS32,
          BX_INSTR_SCAS32,
          BX_INSTR_SHR32,
          BX_INSTR_SHL32:
            begin
              eflags.sf := Word(oszapc.result_32 >= $80000000);
              
            end;
          else
            BX_PANIC(('get_SF: OSZAPC: unknown instr'));
        end; //case oszapc.instr of
        lf_flags_status := lf_flags_status and $f0ffff;
        Result:=(eflags.sf);
      end; //BX_LF_INDEX_OSZAPC
      BX_LF_INDEX_OSZAP:
        begin
          case oszap.instr of
            BX_INSTR_INC8, BX_INSTR_DEC8:
              begin
                eflags.sf := Word(oszap.result_8 >= $80);

              end;
            BX_INSTR_INC16, BX_INSTR_DEC16:
              begin
                eflags.sf := Word(oszap.result_16 >= $8000);
                
              end;
            BX_INSTR_INC32, BX_INSTR_DEC32:
              begin
                eflags.sf := Word(oszap.result_32 >= $80000000);
                
              end;  
            else
              BX_PANIC(('get_SF: OSZAP: unknown instr'));
          end;  //case oszap.instr of
          lf_flags_status := lf_flags_status and $f0ffff;
          Result:=(eflags.sf);
        end; //BX_LF_INDEX_OSZAP
    else
      begin
        BX_PANIC(('get_SF: unknown case'));
        Result:=0;
        
      end;
  end;
end;

function BX_CPU_C.get_ZF:Bool;
begin
  case ( (lf_flags_status shr 12) and $00000f ) of
    BX_LF_INDEX_KNOWN:
      begin
        Result:=eflags.zf;
      end;
    BX_LF_INDEX_OSZAPC:
      begin
        case oszapc.instr of
          BX_INSTR_ADD8,
          BX_INSTR_ADC8,
          BX_INSTR_SUB8,
          BX_INSTR_SBB8,
          BX_INSTR_CMP8,
          BX_INSTR_NEG8,
          BX_INSTR_XADD8,
          BX_INSTR_OR8,
          BX_INSTR_AND8,
          BX_INSTR_TEST8,
          BX_INSTR_XOR8,
          BX_INSTR_CMPS8,
          BX_INSTR_SCAS8,
          BX_INSTR_SHR8,
          BX_INSTR_SHL8:
            begin
              eflags.zf := Word(oszapc.result_8 = 0);
            end;
          BX_INSTR_ADD16,
          BX_INSTR_ADC16,
          BX_INSTR_SUB16,
          BX_INSTR_SBB16,
          BX_INSTR_CMP16,
          BX_INSTR_NEG16,
          BX_INSTR_XADD16,
          BX_INSTR_OR16,
          BX_INSTR_AND16,
          BX_INSTR_TEST16,
          BX_INSTR_XOR16,
          BX_INSTR_CMPS16,
          BX_INSTR_SCAS16,
          BX_INSTR_SHR16,
          BX_INSTR_SHL16:
            begin
              eflags.zf := Word(oszapc.result_16 = 0);
            end;
          BX_INSTR_ADD32,
          BX_INSTR_ADC32,
          BX_INSTR_SUB32,
          BX_INSTR_SBB32,
          BX_INSTR_CMP32,
          BX_INSTR_NEG32,
          BX_INSTR_XADD32,
          BX_INSTR_OR32,
          BX_INSTR_AND32,
          BX_INSTR_TEST32,
          BX_INSTR_XOR32,
          BX_INSTR_CMPS32,
          BX_INSTR_SCAS32,
          BX_INSTR_SHR32,
          BX_INSTR_SHL32:
            begin
              eflags.zf := Word(oszapc.result_32 = 0);
            end;
          else
            BX_PANIC(('get_ZF: OSZAPC: unknown instr'));
       end;
      lf_flags_status := lf_flags_status and $ff0fff;
      Result:=eflags.zf;
    end;
    BX_LF_INDEX_OSZAP:
      begin
        case oszap.instr of
          BX_INSTR_INC8,
          BX_INSTR_DEC8:
            begin
              eflags.zf := Word(oszap.result_8 = 0);
            end;
          BX_INSTR_INC16,
          BX_INSTR_DEC16:
            begin
              eflags.zf := Word(oszap.result_16 = 0);
            end;
          BX_INSTR_INC32,
          BX_INSTR_DEC32:
            begin
              eflags.zf := Word(oszap.result_32 = 0);
            end;
          else
            BX_PANIC(('get_ZF: OSZAP: unknown instr'));
        end;
        lf_flags_status := lf_flags_status and $ff0fff;
        Result:= eflags.zf;
      end;
    else
      BX_PANIC(('get_ZF: unknown case'));
      Result:=0;
  end;
end;

function BX_CPU_C.get_AF:Bool;
var
  Cond:Boolean;
begin
  case ( (lf_flags_status shr 8) and $00000f ) of
    BX_LF_INDEX_KNOWN:
      Result := eflags.af;
    BX_LF_INDEX_OSZAPC:
      begin
        case oszapc.instr of
          BX_INSTR_ADD8,
          BX_INSTR_ADC8,
          BX_INSTR_SUB8,
          BX_INSTR_SBB8,
          BX_INSTR_CMP8,
          BX_INSTR_XADD8,
          BX_INSTR_CMPS8,
          BX_INSTR_SCAS8:
            begin
              eflags.af := ((oszapc.op1_8 xor oszapc.op2_8) xor oszapc.result_8) and $10;
            end;
          BX_INSTR_ADD16,
          BX_INSTR_ADC16,
          BX_INSTR_SUB16,
          BX_INSTR_SBB16,
          BX_INSTR_CMP16,
          BX_INSTR_XADD16,
          BX_INSTR_CMPS16,
          BX_INSTR_SCAS16:
            begin
              eflags.af := ((oszapc.op1_16 xor oszapc.op2_16) xor oszapc.result_16) and $10;
            end;
          BX_INSTR_ADD32,
          BX_INSTR_ADC32,
          BX_INSTR_SUB32,
          BX_INSTR_SBB32,
          BX_INSTR_CMP32,
          BX_INSTR_XADD32,
          BX_INSTR_CMPS32,
          BX_INSTR_SCAS32:
            begin
              eflags.af := ((oszapc.op1_32 xor oszapc.op2_32) xor oszapc.result_32) and $10;
            end;
          BX_INSTR_NEG8:
            begin
              eflags.af := Word((oszapc.op1_8 and $0f) > 0);
            end;
          BX_INSTR_NEG16:
            begin
              eflags.af := Word((oszapc.op1_16 and $0f) > 0);
            end;
          BX_INSTR_NEG32:
            begin
              eflags.af := Word((oszapc.op1_32 and $0f) > 0);
            end;
          BX_INSTR_OR8,
          BX_INSTR_OR16,
          BX_INSTR_OR32,
          BX_INSTR_AND8,
          BX_INSTR_AND16,
          BX_INSTR_AND32,
          BX_INSTR_TEST8,
          BX_INSTR_TEST16,
          BX_INSTR_TEST32,
          BX_INSTR_XOR8,
          BX_INSTR_XOR16,
          BX_INSTR_XOR32,
          BX_INSTR_SHR8,
          BX_INSTR_SHR16,
          BX_INSTR_SHR32,
          BX_INSTR_SHL8,
          BX_INSTR_SHL16,
          BX_INSTR_SHL32:
            begin
              eflags.af := 0;
            end;
          else
            BX_PANIC((Format('get_AF: OSZAPC: unknown instr %u',[oszapc.instr])));
        end;
        lf_flags_status := lf_flags_status and $fff0ff;
        Result:= eflags.af;
      end;
    BX_LF_INDEX_OSZAP:
      begin
        case oszap.instr of
          BX_INSTR_INC8:
            begin
              eflags.af := Word((oszap.result_8 and $0f) = 0);
            end;
          BX_INSTR_INC16:
            begin
              eflags.af := Word((oszap.result_16 and $0f) = 0);
            end;
          BX_INSTR_INC32:
            begin
              eflags.af := Word((oszap.result_32 and $0f) = 0);
            end;
          BX_INSTR_DEC8:
            begin
              eflags.af := Word((oszap.result_8 and $0f) = $0f);
            end;
          BX_INSTR_DEC16:
            begin
              eflags.af := Word((oszap.result_16 and $0f) = $0f);
            end;
          BX_INSTR_DEC32:
            begin
              eflags.af := Word((oszap.result_32 and $0f) = $0f);
            end;
          else
            BX_PANIC(Format('get_AF: OSZAP: unknown instr %u', [oszap.instr]));
        end;
      lf_flags_status := lf_flags_status and $fff0ff;
      Result:=eflags.af;
     end;
    else
      begin
        BX_PANIC(('get_AF: unknown case'));
        Result:=0;
      end;
   end;
end;

function BX_CPU_C.get_OF:Bool;
var
  op1_b7, op2_b7, result_b7:Bit8u;
  op1_b15, op2_b15, result_b15:Bit16u;
  op1_b31, op2_b31, result_b31:Bit32u;
  cond:Boolean;
begin
  case ( (lf_flags_status shr 20) and $00000f ) of
    BX_LF_INDEX_KNOWN:
      Result:=eflags.of_;
    BX_LF_INDEX_OSZAPC:
    begin
    case (oszapc.instr) of
      BX_INSTR_ADD8,BX_INSTR_ADC8,BX_INSTR_XADD8:
        begin
          op1_b7    := oszapc.op1_8 and $80;
          op2_b7    := oszapc.op2_8 and $80;
          result_b7 := oszapc.result_8 and $80;
          Cond:=(op1_b7 = op2_b7) and ((result_b7 xor op2_b7)<>0);
          eflags.of_ :=Word(Cond);

        end;
      BX_INSTR_ADD16,BX_INSTR_ADC16,BX_INSTR_XADD16:
        begin
          op1_b15 := oszapc.op1_16 and $8000;
          op2_b15 := oszapc.op2_16 and $8000;
          result_b15 := oszapc.result_16 and $8000;
          Cond:=(op1_b15 = op2_b15) and ((result_b15 xor op2_b15)<>0);
          eflags.of_ :=  Word(Cond);

        end;
      BX_INSTR_ADD32,BX_INSTR_ADC32,BX_INSTR_XADD32:
        begin
          op1_b31 := oszapc.op1_32 and $80000000;
          op2_b31 := oszapc.op2_32 and $80000000;
          result_b31 := oszapc.result_32 and $80000000;
          Cond:=(op1_b31 = op2_b31) and ((result_b31 xor op2_b31)<>0);
          eflags.of_ := Word(Cond);

        end;
      BX_INSTR_SUB8,BX_INSTR_SBB8,BX_INSTR_CMP8,BX_INSTR_CMPS8,BX_INSTR_SCAS8:
        begin
          op1_b7 := oszapc.op1_8 and $80;
          op2_b7 := oszapc.op2_8 and $80;
          result_b7 := oszapc.result_8 and $80;
          Cond:=((op1_b7 xor op2_b7)<>0) and ((op1_b7 xor result_b7)<>0);
          eflags.of_ := Word(Cond);

        end;
      BX_INSTR_SUB16,BX_INSTR_SBB16,BX_INSTR_CMP16,BX_INSTR_CMPS16,BX_INSTR_SCAS16:
        begin
          op1_b15 := oszapc.op1_16 and $8000;
          op2_b15 := oszapc.op2_16 and $8000;
          result_b15 := oszapc.result_16 and $8000;
          Cond:=((op1_b15 xor op2_b15)<>0) and ((op1_b15 xor result_b15)<>0);
          eflags.of_ :=  Word(Cond);

        end;
      BX_INSTR_SUB32,BX_INSTR_SBB32,BX_INSTR_CMP32,BX_INSTR_CMPS32,BX_INSTR_SCAS32:
        begin
          op1_b31 := oszapc.op1_32 and $80000000;
          op2_b31 := oszapc.op2_32 and $80000000;
          result_b31 := oszapc.result_32 and $80000000;
          Cond:=((op1_b31 xor op2_b31)<>0) and ((op1_b31 xor result_b31)<>0);
          eflags.of_ := Word(Cond);

        end;
      BX_INSTR_NEG8:
        begin
          eflags.of_ := Word((oszapc.op1_8 = $80));
          
        end;
      BX_INSTR_NEG16:
        begin
          eflags.of_ := Word(oszapc.op1_16 = $8000);
          
        end;
      BX_INSTR_NEG32:
        begin
          eflags.of_ := Word((oszapc.op1_32 = $80000000));
          
        end;
      BX_INSTR_OR8, BX_INSTR_OR16,BX_INSTR_OR32,BX_INSTR_AND8,BX_INSTR_AND16,BX_INSTR_AND32,BX_INSTR_TEST8,
        BX_INSTR_TEST16,BX_INSTR_TEST32,BX_INSTR_XOR8,BX_INSTR_XOR16,BX_INSTR_XOR32:
        begin
          eflags.of_ := 0;
          
        end;
      BX_INSTR_SHR8:
        begin
          if (oszapc.op2_8 = 1) then
            eflags.of_ := Word((oszapc.op1_8 >= $80));

        end;
      BX_INSTR_SHR16:
        begin
          if (oszapc.op2_16 = 1) then
            eflags.of_ := Word((oszapc.op1_16 >= $8000));

        end;
      BX_INSTR_SHR32:
        begin
          if (oszapc.op2_32 = 1) then
            eflags.of_ := Word((oszapc.op1_32 >= $80000000));
          
        end;
      BX_INSTR_SHL8:
        begin
          if (oszapc.op2_8 = 1) then eflags.of_ :=Word(((oszapc.op1_8 xor oszapc.result_8) and $80) > 0);
          
        end;
      BX_INSTR_SHL16:
        begin
          if (oszapc.op2_16 = 1) then eflags.of_ :=  Word(((oszapc.op1_16 xor oszapc.result_16) and $8000) > 0);
          
        end;
      BX_INSTR_SHL32:
        begin
          if (oszapc.op2_32 = 1) then eflags.of_ :=Word(((oszapc.op1_32 xor oszapc.result_32) and $80000000) > 0);

        end;
      else
        BX_PANIC('get_OF: OSZAPC: unknown instr');
    end;
    lf_flags_status := lf_flags_status and $0fffff;
    Result:=eflags.of_;
    end;

    BX_LF_INDEX_OSZAP:
      begin
      case oszap.instr of
        BX_INSTR_INC8:
          begin
            eflags.of_ := Word(oszap.result_8 = $80);
            
          end;
        BX_INSTR_INC16:
          begin
            eflags.of_ := Word(oszap.result_16 = $8000);
            
          end;
        BX_INSTR_INC32:
          begin
            eflags.of_ := Word(oszap.result_32 = $80000000);
            
          end;
        BX_INSTR_DEC8:
          begin
            eflags.of_ := Word(oszap.result_8 = $7F);

          end;
        BX_INSTR_DEC16:
          begin
            eflags.of_ := Word(oszap.result_16 = $7FFF);
            
          end;
        BX_INSTR_DEC32:
          begin
            eflags.of_ := Word(oszap.result_32 = $7FFFFFFF);

          end;
        else
          BX_PANIC('get_OF: OSZAP: unknown instr');
        end;
      lf_flags_status := lf_flags_status and $0fffff;
      Result:= eflags.of_;
    end;
  end;
end;

function BX_CPU_C.get_PF:Bool;
begin
  case Word((lf_flags_status shr 4) and $00000f ) of
    BX_LF_INDEX_KNOWN:
      begin
        Result:=lf_pf;
      end;
    BX_LF_INDEX_OSZAPC:
      begin
      case oszapc.instr of
        BX_INSTR_ADD8,
        BX_INSTR_ADC8,
        BX_INSTR_SUB8,
        BX_INSTR_SBB8,
        BX_INSTR_CMP8,
        BX_INSTR_NEG8,
        BX_INSTR_XADD8,
        BX_INSTR_OR8,
        BX_INSTR_AND8,
        BX_INSTR_TEST8,
        BX_INSTR_XOR8,
        BX_INSTR_CMPS8,
        BX_INSTR_SCAS8,
        BX_INSTR_SHR8,
        BX_INSTR_SHL8:
          begin
            lf_pf := bx_parity_lookup[oszapc.result_8];

          end;
        BX_INSTR_ADD16,
        BX_INSTR_ADC16,
        BX_INSTR_SUB16,
        BX_INSTR_SBB16,
        BX_INSTR_CMP16,
        BX_INSTR_NEG16,
        BX_INSTR_XADD16,
        BX_INSTR_OR16,
        BX_INSTR_AND16,
        BX_INSTR_TEST16,
        BX_INSTR_XOR16,
        BX_INSTR_CMPS16,
        BX_INSTR_SCAS16,
        BX_INSTR_SHR16,
        BX_INSTR_SHL16:
          begin
            lf_pf := bx_parity_lookup[Bit8u(oszapc.result_16)];
            
          end;
        BX_INSTR_ADD32,
        BX_INSTR_ADC32,
        BX_INSTR_SUB32,
        BX_INSTR_SBB32,
        BX_INSTR_CMP32,
        BX_INSTR_NEG32,
        BX_INSTR_XADD32,
        BX_INSTR_OR32,
        BX_INSTR_AND32,
        BX_INSTR_TEST32,
        BX_INSTR_XOR32,
        BX_INSTR_CMPS32,
        BX_INSTR_SCAS32,
        BX_INSTR_SHR32,
        BX_INSTR_SHL32:
          begin
            lf_pf := bx_parity_lookup[Bit8u(oszapc.result_32)];
            
          end;
        else
          BX_PANIC(('get_PF: OSZAPC: unknown instr'));
       end;
       lf_flags_status := lf_flags_status and $ffff0f;
       Result:=lf_pf;
       
     end;
    BX_LF_INDEX_OSZAP:
      begin
        case oszap.instr of
          BX_INSTR_INC8, BX_INSTR_DEC8:
            begin
              lf_pf := bx_parity_lookup[oszap.result_8];
              
            end;
          BX_INSTR_INC16, BX_INSTR_DEC16:
            begin
              lf_pf := bx_parity_lookup[Bit8u(oszap.result_16)];
              
            end;
          BX_INSTR_INC32, BX_INSTR_DEC32:
            begin
              lf_pf := bx_parity_lookup[Bit8u(oszap.result_32)];
              
            end;
          else
            BX_PANIC(('get_PF: OSZAP: unknown instr'));
        end;  //case oszap.instr of
        lf_flags_status := lf_flags_status and $ffff0f;
        Result:=lf_pf;
        
      end;    //BX_LF_INDEX_OSZAP
    BX_LF_INDEX_P:
      begin
        lf_pf := bx_parity_lookup[eflags.pf_byte];
        lf_flags_status := lf_flags_status and $ffff0f;
        Result:=lf_pf;
        
      end;  //case BX_LF_INDEX_P:
    else
      begin
        BX_PANIC(('get_PF: unknown case'));
        Result:=0;
      end;
  end; //case Word((lf_flags_status shr 4) and $00000f ) of
end;

function BX_CPU_C.BX_READ_16BIT_REG(index:Word):Bit16u;
begin
  Result:=gen_reg[index].rx;
end;

function BX_CPU_C.BX_READ_32BIT_REG(index:Word):Bit32u;
begin
  Result:=gen_reg[index].erx;
end;

function BX_CPU_C.get_CF:Bool;
var
  c:Word;
  cond:Boolean;
begin
  case lf_flags_status and $00000f of
    BX_LF_INDEX_KNOWN:
      begin
        Result:=eflags.cf;
      end;

    BX_LF_INDEX_OSZAPC:
      begin
        case oszapc.instr of
          BX_INSTR_ADD8,
          BX_INSTR_XADD8:
            begin
              eflags.cf := Word(oszapc.result_8 < oszapc.op1_8);
            end;
          BX_INSTR_ADD16,
          BX_INSTR_XADD16:
            begin
              eflags.cf := Word(oszapc.result_16 < oszapc.op1_16);
            end;
          BX_INSTR_ADD32,
          BX_INSTR_XADD32:
            begin
              eflags.cf := Word(oszapc.result_32 < oszapc.op1_32);
            end;
          BX_INSTR_ADC8:
            begin
              cond := (oszapc.result_8 < oszapc.op1_8) or ((oszapc.prev_CF<>0) and (oszapc.result_8 = oszapc.op1_8));
              eflags.cf := Word(cond);
            end;
          BX_INSTR_ADC16:
            begin
              cond := (oszapc.result_16 < oszapc.op1_16) or ((oszapc.prev_CF<>0) and (oszapc.result_16 = oszapc.op1_16));
              eflags.cf := Word(Cond);
            end;
          BX_INSTR_ADC32:
            begin
              cond := (oszapc.result_32 < oszapc.op1_32) or ((oszapc.prev_CF<>0) and (oszapc.result_32 = oszapc.op1_32));
              eflags.cf := Word(Cond);
            end;
          BX_INSTR_SUB8,
          BX_INSTR_CMP8,
          BX_INSTR_CMPS8,
          BX_INSTR_SCAS8:
            begin
              eflags.cf := Word(oszapc.op1_8 < oszapc.op2_8);
            end;
          BX_INSTR_SUB16,
          BX_INSTR_CMP16,
          BX_INSTR_CMPS16,
          BX_INSTR_SCAS16:
            begin
              eflags.cf := Word(oszapc.op1_16 < oszapc.op2_16);
            end;
          BX_INSTR_SUB32,
          BX_INSTR_CMP32,
          BX_INSTR_CMPS32,
          BX_INSTR_SCAS32:
            begin
              eflags.cf := Word(oszapc.op1_32 < oszapc.op2_32);
            end;
          BX_INSTR_SBB8:
            begin
              cond := (oszapc.op1_8 < oszapc.result_8) or ((oszapc.op2_8 = $ff) and (oszapc.prev_CF<>0));
              eflags.cf := Word(Cond);
            end;
          BX_INSTR_SBB16:
            begin
              Cond := (oszapc.op1_16 < oszapc.result_16) or ((oszapc.op2_16 = $ffff) and (oszapc.prev_CF<>0));
              eflags.cf := Word(Cond);
            end;
          BX_INSTR_SBB32:
            begin
              Cond :=(oszapc.op1_32 < oszapc.result_32) or ((oszapc.op2_32 = $ffffffff) and (oszapc.prev_CF<>0));
              eflags.cf := Word(cond);
            end;
          BX_INSTR_NEG8:
            begin
              eflags.cf := Word(oszapc.op1_8 <> 0);
            end;
          BX_INSTR_NEG16:
            begin
              eflags.cf := Word(oszapc.op1_16 <> 0);
            end;
          BX_INSTR_NEG32:
            begin
              eflags.cf := Word(oszapc.op1_32 <> 0);
            end;
          BX_INSTR_OR8,
          BX_INSTR_OR16,
          BX_INSTR_OR32,
          BX_INSTR_AND8,
          BX_INSTR_AND16,
          BX_INSTR_AND32,
          BX_INSTR_TEST8,
          BX_INSTR_TEST16,
          BX_INSTR_TEST32,
          BX_INSTR_XOR8,
          BX_INSTR_XOR16,
          BX_INSTR_XOR32:
            begin
              eflags.cf := 0;
            end;
          BX_INSTR_SHR8:
            begin
              eflags.cf := (oszapc.op1_8 shr (oszapc.op2_8 - 1)) and $01;
            end;
          BX_INSTR_SHR16:
            begin
              eflags.cf := (oszapc.op1_16 shr (oszapc.op2_16 - 1)) and $01;
            end;
          BX_INSTR_SHR32:
            begin
              eflags.cf := (oszapc.op1_32 shr (oszapc.op2_32 - 1)) and $01;
            end;
          BX_INSTR_SHL8:
            begin
              if oszapc.op2_8 <= 8 then
                eflags.cf := (oszapc.op1_8 shr (8 - oszapc.op2_8)) and $01
              else
                eflags.cf := 0;
            end;
        BX_INSTR_SHL16:
          begin
            if oszapc.op2_16 <= 16 then
              eflags.cf := (oszapc.op1_16 shr (16 - oszapc.op2_16)) and $01
            else
              eflags.cf := 0;
          end;
        BX_INSTR_SHL32:
          begin
            eflags.cf := (oszapc.op1_32 shr (32 - oszapc.op2_32)) and $01;
          end;
        else
          BX_PANIC(Format('get_CF: OSZAPC: unknown instr %u',[oszapc.instr]));
      end;
      lf_flags_status := lf_flags_status and $fffff0;
      Result:= eflags.cf;
    end;
    else
      begin
        BX_PANIC(('get_CF: unknown case'));
        Result:=0;
      end;
  end;
end;

{$i '..\bios.dat'}
{$i '..\vbios.dat'}
constructor BX_CPU_C.Create;
const
  MByte = 1024 * 1024;
begin
  {$ifdef RECORD_VM}
  inherited Create(LongWord(@fake_start),LongWord(@fake_end),idCPU);
  {$endif}
  bx_pc_system:=bx_pc_system_c.Create;
  sysmemory:=BX_MEM_C.Create(MEMORYMB * MByte);
//  sysmemory.load_ROM(BIOSFILE,$f0000);
//  sysmemory.load_ROM(VGAROMFILE,$c0000);
move(dbios,memory.sysmemory.vector[$f0000],65536);//65536
move(vbios,memory.sysmemory.vector[$c0000],32768);//32768
end;

destructor BX_CPU_C.Destroy;
begin
  DoneLogFiles;
  {$ifdef RECORD_VM}
  inherited;
  {$endif}
end;

function BX_CPU_C.real_mode:Bool;
begin
  Result:=Bool(cr0.pe=0);
end;

function BX_CPU_C.v8086_mode:Bool;
begin
  result:=eflags.vm;
end;

function BX_CPU_C.CPL:Bit8u;
begin
  Result:=sregs[BX_SEG_REG_CS].selector.rpl;
end;

{$include Access.pas}

function BX_CPU_C.strseg(seg:Pbx_segment_reg_t):PChar;
var
  S:String;
begin
  if (seg = @sregs[0]) then Result:='ES'
  else if (seg = @sregs[1]) then Result:='CS'
  else if (seg = @sregs[2]) then Result:='SS'
  else if (seg = @sregs[3]) then Result:='DS'
  else if (seg = @sregs[4]) then Result:='FS'
  else if (seg = @sregs[5]) then Result:='GS'
  else begin
    BX_ERROR(('undefined segment passed to strseg()!'));
    Result:='??';
    end;
end;

procedure BX_CPU_C.write_RMW_virtual_byte(val8:Bit8u);
begin
{$if BX_CPU_LEVEL >= 3 }
  if (cr0.pg <> 0) then
    begin
    // BX_CPU_THIS_PTR address_xlation.pages must be 1
      sysmemory.write_physical(address_xlation.paddress1, 1, @val8);
    end
  else
{$ifend}
    begin
      sysmemory.write_physical(address_xlation.paddress1, 1, @val8);
    end;
end;

function BX_CPU_C.BX_READ_8BIT_REG(index:Word):Bit8u;
begin
  if Index < 4 then
    Result:=gen_reg[Index].rl
  else
    Result:=gen_reg[index - 4].rh;
end;

procedure BX_CPU_C.BX_WRITE_8BIT_REG(index:Word; val:Bit8u);
begin
  if index < 4 then
    gen_reg[index].rl := val
  else
    gen_reg[index-4].rh := val;
end;

procedure BX_CPU_C.BX_WRITE_16BIT_REG(index:Word; val:Bit16u);
begin
  gen_reg[index].rx := val;
end;

procedure BX_CPU_C.invalidate_prefetch_q;
begin
  bytesleft:=0;
end;

procedure BX_CPU_C.revalidate_prefetch_q;
var
  new_linear_addr, new_linear_page, new_linear_offset:Bit32u;
  new_phy_addr:Bit32u;
begin

  new_linear_addr := Self.sregs[BX_SEG_REG_CS].cache.segment.base + Self.eip;

  new_linear_page := new_linear_addr  and $fffff000;
  if (new_linear_page = Self.prev_linear_page) then begin
    // same linear address, old linear^.physical translation valid
    new_linear_offset := new_linear_addr  and $00000fff;
    new_phy_addr := Self.prev_phy_page or new_linear_offset;
{$if BX_PCI_SUPPORT=1}
    if (new_phy_addr >= $000C0000) and (new_phy_addr <= $000FFFFF)) then begin
      Self.bytesleft := $4000 - (new_phy_addr  and $3FFF);
      Self.fetch_ptr := bx_pci.i440fx_fetch_ptr(new_phy_addr);
      end
  else begin
      Self.bytesleft := (Self.max_phy_addr - new_phy_addr) + 1;
      Self.fetch_ptr := PBit8u(Integer(Self.sysmemory.vector) + new_phy_addr);
      end;
{$else}
    Self.bytesleft := (Self.max_phy_addr - new_phy_addr) + 1;
    Self.fetch_ptr := @sysmemory.vector[new_phy_addr];
{$ifend}
    end
  else begin
    Self.bytesleft := 0; // invalidate prefetch Q
    end;
end;

function BX_CPU_C.GetIP:Bit16u;
begin
  Result:=PBit16u(Integer(@Self.eip) + BX_REG16_OFFSET)^; //(* (Bit16u *) (((Bit8u *) &BX_CPU_THIS_PTR eip) + BX_REG16_OFFSET))
end;

procedure BX_CPU_C.SetIP(IPValue:Bit16u);
begin
  PBit16u(Integer(@Self.eip) + BX_REG16_OFFSET)^:=IPValue;
end;

procedure Confronta(var RecPascal,RecC:recstate;var fpout:textfile;var Errori:LongWord);
begin
  if (RecPascal.a0 <> RecC.a0) or
     (RecPascal.a1 <> RecC.a1) or
     (RecPascal.a2 <> RecC.a2) or
     (RecPascal.a3 <> RecC.a3) or
     (RecPascal.a4 <> RecC.a4) or
     (RecPascal.a5 <> RecC.a5) or
     (RecPascal.a6 <> RecC.a6) or
     (RecPascal.a7 <> RecC.a7) or
     (RecPascal.a8 <> RecC.a8) or
     (RecPascal.a9 <> RecC.a9) then
       begin
         WriteLn(fpout,Format('P %d;[%x];%x;%x;%x;%x;%x;%x;%x;%x;',
          [RecPascal.a0,RecPascal.a1,RecPascal.a2,RecPascal.a3,RecPascal.a4,RecPascal.a5,RecPascal.a6,RecPascal.a7,RecPascal.a8,RecPascal.a9]));
         WriteLn(fpout,Format('C %d;[%x];%x;%x;%x;%x;%x;%x;%x;%x;',
          [RecC.a0,RecC.a1,RecC.a2,RecC.a3,RecC.a4,RecC.a5,RecC.a6,RecC.a7,RecC.a8,RecC.a9]));
         WriteLn(fpout,'-------------------------------------------------');
         Inc(Errori);
       end;
end;

procedure BX_CPU_C.cpu_loop;
var
  ret:unsigned;
  i:BxInstruction_tag;
  maxisize:Word;
  fetch_ptr:PBit8u;
  is_32:Bool;
  fakeword:word;
  remain, j:unsigned;
  FetchBuffer:array[0..16] of Bit8u;
  temp_ptr:PBit8u;
  vector:Bit8u;
  Rxp,Rxc:recstate;
  TotWrites:LongWord;
  ReachEOF, must_jump:Boolean;
  ips_count,ips_count5,CountRound:longword;
{$ifdef MSWINDOWS}
  time_instr_start,time_instr_end,time_instr_diff:int64;
  time_instr_start5,time_instr_end5,time_instr_diff5:int64;
  time_instr_sum, count_read,TotFileSize,Fine:int64;
  time_max:bit32u;
  time_perc:single;
{$endif}
  NumRead:Integer;

{$ifdef USE_TIME_PROFILER}
  S1,S2,S3:String;
  RecSourcePrf:TRecProfiler;
{$endif}

  label main_cpu_loop,handle_async_event,async_events_processed,fetch_decode_OK,repeat_loop,repeat_done;
  label repeat_not_done,debugger_check,theend,begin_cpu_loop;
begin
  TotWrites:=0;
  ips_count:=0;
{$ifdef COMPILE_WIN32}
  count_read:=0;
  Fine:=BX_READ_AFTER*int64(sizeof(rxp));
{$endif}
  CountRound:=0;
  must_jump:=False;

  {$if BX_LOG_ENABLED=1}
  AssignFile(OutLogTxt,changefileext(paramstr(0),'.log'));
  Rewrite(OutLogTxt);
  FilesLog:=FileOpen('C:\bochs-1.4.1\merge\C.bin',fmOpenRead);
  //FilesLog:=FileOpen('e:\C.bin',fmOpenRead);
  TotFileSize:=Trunc(FileSeek(FilesLog,int64(0),2)/sizeof(rxc))+BX_READ_AFTER;
  FileSeek(FilesLog,0,0);
  {$ifend}
  //(procedure) setjmp( Self.jmp_buf_env );

  // not sure if these two are used during the async handling... --bbd
  FillChar(i,SizeOf(i),0);
  Prog:=0;
  begin_cpu_loop:
  reloop:=False;
  setjmp(savejump);
  self.prev_eip := self.EIP; // commit new EIP
  self.prev_esp := self.ESP; // commit new ESP
  

{$ifdef COMPILE_WIN32}
  time_instr_start:=GetTickCount;
  time_instr_start5:=GetTickCount;
  ips_count5:=0;
  time_max:=0;
  time_instr_sum:=0;
{$endif}

main_cpu_loop:

  // ???
  self.EXT := 0;
  self.errorno := 0;

  // First check on events which occurred for previous instructions
  // (traps) and ones which are asynchronous to the CPU
  // (hardware interrupts).
  if (self.async_event)<>0 then
    goto handle_async_event;

async_events_processed:
  // added so that all debugging/tracing code uses the correct EIP even in the
  // instruction just after a trap/interrupt.  If you use the prev_eip that was
  // set before handle_async_event, traces and breakpoints fail to show the
  // first instruction of int/trap handlers.
  self.prev_eip := self.EIP; // commit new EIP
  self.prev_esp := self.ESP; // commit new ESP

  // Now we can handle things which are synchronous to instruction
  // execution.
  if (self.eflags.rf)<>0 then begin
    self.eflags.rf := 0;
    end;

  // We have ignored processing of external interrupts and
  // debug events on this boundary.  Reset the mask so they
  // will be processed on the next boundary.
  self.inhibit_mask := 0;

  is_32 := self.sregs[BX_SEG_REG_CS].cache.segment.d_b;

  if (self.bytesleft = 0) then begin
    self.prefetch();
    end;
  fetch_ptr := self.fetch_ptr;

  maxisize := 16;
  if (self.bytesleft < 16) then
    maxisize := self.bytesleft;
  ret := self.FetchDecode(fetch_ptr, i, maxisize, is_32);
    
  if (ret)<>0 then begin
    if (@i.Resolvemodrm<>nil) then begin
      // call method on BX_CPU_C object
      i.Resolvemodrm(@i);
      end;
    inc(self.fetch_ptr,i.ilen);
    Dec(self.bytesleft,i.ilen);
fetch_decode_OK:

    if (i.rep_used<>0) and ((i.attr and BxRepeatable)<>0) then begin
repeat_loop:
      if (i.attr and BxRepeatableZF)<>0 then begin
        if (i.as_32)<>0 then begin
          if (self.ECX <> 0) then begin
             i.execute(@i);
             if Reloop then goto begin_cpu_loop;
            //ECX -:= 1; ????
            self.ECX:=self.ECX-1;
            end;
          if (i.rep_used=$f3) and ((self.get_ZF()=0)) then goto repeat_done;
          if (i.rep_used=$f2) and ((self.get_ZF()<>0)) then goto repeat_done;
          if (self.ECX = 0) then goto repeat_done;
          goto repeat_not_done;
          end
        else begin
          if (self.CX <> 0) then begin
             i.execute(@i);
             if Reloop then goto begin_cpu_loop;
            self.CX:=self.CX-1;
            end;
          if (i.rep_used=$f3) and ((self.get_ZF()=0)) then goto repeat_done;
          if (i.rep_used=$f2) and ((self.get_ZF()<>0)) then goto repeat_done;
          if (self.CX = 0) then goto repeat_done;
          goto repeat_not_done;
          end;
        end
      else begin // normal repeat, no concern for ZF
        if (i.as_32)<>0 then begin
          if (self.ECX <> 0) then begin
             i.execute(@i);
             if Reloop then goto begin_cpu_loop;
            self.ECX:=self.ECX-1;
            end;
          if (self.ECX = 0) then goto repeat_done;
          goto repeat_not_done;
          end
        else begin // 16bit addrsize
          if (self.CX <> 0) then begin
             i.execute(@i);
             if Reloop then goto begin_cpu_loop;
            self.CX:=self.CX-1;
            end;
          if (self.CX = 0) then goto repeat_done;
          goto repeat_not_done;
          end;
        end;
      // shouldn't get here from above
repeat_not_done:
{$if REGISTER_IADDR=1}
      REGISTER_IADDR(self.eip + self.sregs[BX_SREG_CS].cache.u.segment.base);
{$ifend}

  inc(ips_count);
  dec(bx_pc_system.num_cpu_ticks_left);
    if (bx_pc_system.num_cpu_ticks_left = 0) then
      begin
        bx_pc_system.timer_handler();
      end;

      if (self.async_event)<>0 then begin
        self.invalidate_prefetch_q();
        goto debugger_check;
      end;
      goto repeat_loop;


repeat_done:
      self.eip := self.eip + i.ilen;
      end
  else begin
      // non repeating instruction
      self.eip := self.eip + i.ilen;
      {$ifdef TEST_READ_CACHE}
      FillChar(i,Sizeof(i),0);
      ReadNode(@I);
      assert(@i<>nil);
      {$endif}
      {$ifndef RELEASE_VERSION}

      {$ifdef USE_TIME_PROFILER}
      if Prog mod TIME_PROF_STEP = 0 then
        begin
          recProfiler.Progress:=Prog;
          recProfiler.Timing:=GetTickCount;
          Write(fpProfiler,recProfiler);
          if not eof(LastFile) then
            begin
              Read(LastFile,RecSourcePrf);
              S1:=Format('Before : Prg = %d Timing = %d',[RecSourcePrf.Progress,RecSourcePrf.Timing]));
              S2:=Format('After  : Prg = %d Timing = %d',[recProfiler.Progress,recProfiler.Timing]));
              S3:=Format('Diff   : Prg = %d Timing = %d',[RecSourcePrf.Progress-recProfiler.Progress,
              recProfiler.Timing,RecSourcePrf.Timing]);
              WriteLn(ProfilerResult,S1);
              WriteLn(ProfilerResult,S2);
              WriteLn(ProfilerResult,S3);
              WriteLn(ProfilerResult,'-----------------------------------------');
            end;
        end;
      {$endif}

      Application.ProcessMessages;
      if prog >= 203591552 then
        begin
              i.execute(@i );
             if Reloop then goto begin_cpu_loop;
        end
      else
        begin
             i.execute(@i);
             if Reloop then goto begin_cpu_loop;
        end;
      {$else}
        i.execute(@i);
             if Reloop then goto begin_cpu_loop;
      {$endif}
      {$ifdef RECORD_VM}
      WriteNode;
      {$endif}
      {$ifdef SHOW_IPS_CPU}
      if ips_count >= BX_MAX_IPS then
        begin
        try
          //TimeCpu.LblLogRead.Caption:=IntToStr(Prog);
         except
         vuoto;
         end;
          ips_count:=0;
        end;
      {$endif}
      Inc(ips_count);

      {$if BX_LOG_ENABLED=1}
      if Prog >= BX_READ_AFTER then
         begin
          Rxp.a0 := prog;
          Rxp.a1 := bx_cpu.eip;
          Rxp.a2 := bx_cpu.gen_reg[0].erx;//bx_cpu.gen_reg[0].erx;
          Rxp.a3 := bx_cpu.gen_reg[1].erx;
          Rxp.a4 := bx_cpu.gen_reg[2].erx;
          Rxp.a5 := bx_cpu.gen_reg[3].erx;
          Rxp.a6 := bx_cpu.gen_reg[4].erx;
          Rxp.a7 := bx_cpu.gen_reg[5].erx;
          Rxp.a8 := bx_cpu.gen_reg[6].erx;
          Rxp.a9 := bx_cpu.oszap.instr;

          if (not ReachEOF) and (TotWrites < BX_MAX_ERRORS) then
            begin
              NumRead:=FileRead(FilesLog,rxc,SizeOf(rxc));
              if numread < SizeOf(rxc) then
                begin
                  Writeln('EOF FILE REACHED...EXITING');
                  goto theend;
                end;
              Confronta(Rxp,Rxc,OutLogTxt,totWrites);
            end;
          end;
      {$ifend}
      Inc(Prog);
      end;

    self.prev_eip := self.EIP; // commit new EIP
    self.prev_esp := self.ESP; // commit new ESP
{$if REGISTER_IADDR=1}
    REGISTER_IADDR(self.eip + self.sregs[BX_SREG_CS].cache.u.segment.base);
{$ifend}

  inc(ips_count);
  dec(bx_pc_system.num_cpu_ticks_left);
    if (bx_pc_system.num_cpu_ticks_left = 0) then
      begin
        bx_pc_system.timer_handler();
      end;

debugger_check:
{$if BX_GUI_ENABLED=1}
    if CountRound >= 200000 then
      begin
      //Emulator.Caption:=IntToStr(Prog);
      CountRound:=0;
    end;
    Inc(CountRound);
{$ifend}

    if stoprun then goto theend;
    goto main_cpu_loop;
    end
  else begin

    // read all leftover bytes in current page
    j:=0;
    while j < self.bytesleft do begin
      FetchBuffer[j] := fetch_ptr^;
      Inc(fetch_ptr);
      Inc(j);
      end;

    // get remaining bytes for prefetch in next page
    // prefetch() needs eip current
    self.eip := self.eip + self.bytesleft;
    remain := self.bytesleft;
    self.prefetch();

    if (self.bytesleft < 16) then begin
      // make sure (bytesleft - remain) below doesn't go negative
      BX_PANIC(('fetch_decode: bytesleft=0 after prefetch'));
      end;
    fetch_ptr := self.fetch_ptr;
    temp_ptr := fetch_ptr;

    // read leftover bytes in next page
    while j < 16 do begin
      FetchBuffer[j] := temp_ptr^;
      inc(temp_ptr);
      Inc(j);
      end;
    fakeword:=16;
    ret := self.FetchDecode(@FetchBuffer, i, fakeword, is_32);
    if (ret=0) then
      BX_PANIC(('fetchdecode: cross boundary: ret=0'));
    if (@i.Resolvemodrm)<>nil then begin
      i.Resolvemodrm(@i);
      end;
    remain := i.ilen - remain;

    // note: eip has already been advanced to beginning of page
    self.fetch_ptr := PBit8u(Integer(fetch_ptr) + remain);

    self.bytesleft := self.bytesleft - remain;
    //self.eip +:= remain;
    self.eip := self.prev_eip;
    goto fetch_decode_OK;
    end;



  //
  // This area is where we process special conditions and events.
  //

handle_async_event:

  if (self.debug_trap and $80000000)<>0 then begin
    // I made up the bitmask above to mean HALT state.
{$if BX_SMP_PROCESSORS=1}
    self.debug_trap := 0; // clear traps for after resume
    self.inhibit_mask := 0; // clear inhibits for after resume
    // for one processor, pass the time as quickly as possible until
    // an interrupt wakes up the CPU.
    while (True) do begin
      if ((self.INTR<>0) and (self.eflags.if_<>0)) then begin
        break;
        end;
  inc(ips_count);
  dec(bx_pc_system.num_cpu_ticks_left);
    if (bx_pc_system.num_cpu_ticks_left = 0) then
      begin
        bx_pc_system.timer_handler();
      end;
    end;
{$else}      (* BX_SMP_PROCESSORS <> 1 *)
    // for multiprocessor simulation, even if this CPU is halted we still
    // must give the others a chance to simulate.  If an interrupt has
    // arrived, then clear the HALT condition; otherwise just return from
    // the CPU loop with stop_reason STOP_CPU_HALTED.
    if self.INTR @ and self.eflags.if_) then begin
      // interrupt ends the HALT condition
      self.debug_trap := 0; // clear traps for after resume
      self.inhibit_mask := 0; // clear inhibits for after resume
      //bx_printf ('halt condition has been cleared in %s', name);
    end; else begin
      // HALT condition remains, return so other CPUs have a chance
      exit;
    end;
{$ifend}
  end;


  // Priority 1: Hardware Reset and Machine Checks
  //   RESET
  //   Machine Check
  // (bochs doesn't support these)

  // Priority 2: Trap on Task Switch
  //   T flag in TSS is set
  if (self.debug_trap and $00008000)<>0 then begin
    self.dr6 := self.dr6 or self.debug_trap;
    exception2([BX_DB_EXCEPTION, 0, 0]); // no error, not interrupt
    end;

  // Priority 3: External Hardware Interventions
  //   FLUSH
  //   STOPCLK
  //   SMI
  //   INIT
  // (bochs doesn't support these)

  // Priority 4: Traps on Previous Instruction
  //   Breakpoints
  //   Debug Trap Exceptions (TF flag set or data/IO breakpoint)
  if (self.debug_trap<>0) and ((self.inhibit_mask and BX_INHIBIT_DEBUG)=0) then begin
    // A trap may be inhibited on this boundary due to an instruction
    // which loaded SS.  If so we clear the inhibit_mask below
    // and don't execute this code until the next boundary.
    // Commit debug events to DR6
    self.dr6 := self.dr6 or  self.debug_trap;
    exception2([BX_DB_EXCEPTION, 0, 0]); // no error, not interrupt
    end;

  // Priority 5: External Interrupts
  //   NMI Interrupts
  //   Maskable Hardware Interrupts
  if (self.inhibit_mask  and BX_INHIBIT_INTERRUPTS)<>0 then begin
    // Processing external interrupts is inhibited on this
    // boundary because of certain instructions like STI.
    // inhibit_mask is cleared below, in which case we will have
    // an opportunity to check interrupts on the next instruction
    // boundary.
    end
  else if (self.INTR <> 0) and (self.eflags.if_ <> 0) and ((BX_DBG_ASYNC_INTR <> 0)) then begin

    // NOTE: similar code in .take_irq()
    vector := bx_pc_system.IAC(); // may set INTR with next interrupt
    //BX_DEBUG(('decode: interrupt %u',
    //                                   (unsigned) vector));
    self.errorno := 0;
    self.EXT   := 1; (* external event *)
    self.interrupt(vector, 0, 0, 0);
    //BX_INSTR_HWINTERRUPT(vector, self.sregs[BX_SEG_REG_CS].selector.value, self.eip);
    end
  else if (bx_pc_system.HRQ<>0) then begin
    // NOTE: similar code in .take_dma()
    // assert Hold Acknowledge (HLDA) and go into a bus hold state
    bx_pc_system.raise_HLDA;
    end;

  // Priority 6: Faults from fetching next instruction
  //   Code breakpoint fault
  //   Code segment limit violation (priority 7 on 486/Pentium)
  //   Code page fault (priority 7 on 486/Pentium)
  // (handled in main decode loop)

  // Priority 7: Faults from decoding next instruction
  //   Instruction length > 15 bytes
  //   Illegal opcode
  //   Coprocessor not available
  // (handled in main decode loop etc)

  // Priority 8: Faults on executing an instruction
  //   Floating point execution
  //   Overflow
  //   Bound error
  //   Invalid TSS
  //   Segment not present
  //   Stack fault
  //   General protection
  //   Data page fault
  //   Alignment check
  // (handled by rest of the code)


  if (self.eflags.tf)<>0 then begin
    // TF is set before execution of next instruction.  Schedule
    // a debug trap (#DB) after execution.  After completion of
    // next instruction, the code above will invoke the trap.
    self.debug_trap := self.debug_trap or $00004000; // BS flag in DR6
    end;

  if (self.INTR<>0) or (self.debug_trap<>0) or (bx_pc_system.HRQ<>0) or (self.eflags.tf<>0)=false then
    self.async_event := 0;
  goto async_events_processed;
  theend:
end;




// boundaries of consideration:
//
//  * physical memory boundary: 1024k (1Megabyte) (increments of...)
//  * A20 boundary:             1024k (1Megabyte)
//  * page boundary:            4k
//  * ROM boundary:             2k (dont care since we are only reading)
//  * segment boundary:         any

procedure BX_CPU_C.prefetch;
var
  new_linear_addr:Bit32u;
  new_phy_addr:Bit32u;
  temp_eip, temp_limit:Bit32u;
begin
  // cs:eIP
  // prefetch QSIZE byte quantity aligned on corresponding boundary

  temp_eip   := Self.eip;
  temp_limit := Self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled;

  new_linear_addr := Self.sregs[BX_SEG_REG_CS].cache.segment.base + temp_eip;
  Self.prev_linear_page := new_linear_addr  and $fffff000;

{$if BX_SUPPORT_PAGING=1}
  if (Self.cr0.pg)<>0 then begin
    // aligned block guaranteed to be all in one page, same A20 address
    new_phy_addr := itranslate_linear(new_linear_addr, Bool(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl));
    new_phy_addr := new_phy_addr and bx_pc_system.a20_mask;
    end
  else
{$ifend} // BX_SUPPORT_PAGING
    begin
    new_phy_addr := new_linear_addr and bx_pc_system.a20_mask;
    end;

  if  (new_phy_addr >= sysmemory.len ) then begin
    // don't take this out if dynamic translation enabled,
    // otherwise you must make a check to see if bytesleft is 0 after
    // a call to prefetch() in the dynamic code.
    BX_ERROR(('prefetch: running in bogus memory'));
    end;

  // max physical address as confined by page boundary
  Self.prev_phy_page := new_phy_addr  and $fffff000;
  Self.max_phy_addr := Self.prev_phy_page or $00000fff;

  // check if segment boundary comes into play
  //if (temp_limit - temp_eip) < 4096) then begin
  //  end;

{$if BX_PCI_SUPPORT = 1}
  if (new_phy_addr >= $000C0000) and (new_phy_addr <= $000FFFFF)) then begin
    Self.bytesleft := $4000 - (new_phy_addr  and $3FFF);
    Self.fetch_ptr := bx_pci.i440fx_fetch_ptr(new_phy_addr);
  end else begin
    Self.bytesleft := (Self.max_phy_addr - new_phy_addr) + 1;
    Self.fetch_ptr := Self.sysmemory.vector[new_phy_addr];
  end;
{$else}
  Self.bytesleft := (Self.max_phy_addr - new_phy_addr) + 1;
  Self.fetch_ptr := @sysmemory.vector[new_phy_addr];
{$ifend}
end;


//static double sigh_scale_factor := pow(2.0, -31.0);
//static double sigl_scale_factor := pow(2.0, -63.0);

{procedure BX_CPU_C::fpu_print_regs()
begin
  Bit32u reg;
  reg := i387.soft.cwd;
  fprintf(stderr, 'cwd            $%-8x\t%d\n', (unsigned) reg, (int) reg);
  reg := i387.soft.swd;
  fprintf(stderr, 'swd            $%-8x\t%d\n', (unsigned) reg, (int) reg);
  reg := i387.soft.twd;
  fprintf(stderr, 'twd            $%-8x\t%d\n', (unsigned) reg, (int) reg);
  reg := i387.soft.fip;
  fprintf(stderr, 'fip            $%-8x\t%d\n', (unsigned) reg, (int) reg);
  reg := i387.soft.fcs;
  fprintf(stderr, 'fcs            $%-8x\t%d\n', (unsigned) reg, (int) reg);
  reg := i387.soft.foo;
  fprintf(stderr, 'foo            $%-8x\t%d\n', (unsigned) reg, (int) reg);
  reg := i387.soft.fos;
  fprintf(stderr, 'fos            $%-8x\t%d\n', (unsigned) reg, (int) reg);
  // print stack too
  for (int i:=0; i<8; i++) then begin
    FPU_REG *fpr := @st(i);
    double f1 := pow(2.0, (($7fff@fpr^.exp) - EXTENDED_Ebias));
    if (fpr^.exp  and SIGN_Negative) f1 := -f1;
    double f2 := ((double)fpr^.sigh * sigh_scale_factor);
    double f3 := ((double)fpr^.sigl * sigl_scale_factor);
    double f := f1*(f2+f3);
    fprintf(stderr, 'st%d            %.10f (raw $%04x%08x%08x)\n', i, f, $ffff@fpr^.exp, fpr^.sigh, fpr^.sigl);
  end;
end;}

end.

