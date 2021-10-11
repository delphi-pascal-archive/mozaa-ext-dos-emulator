{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

// Notes:
//
// The high bits of the 32bit eip image are ignored by
// the IRET to VM.  The high bits of the 32bit esp image
// are loaded into ESP.  A subsequent push uses
// only the low 16bits since it's in VM.  In neither case
// did a protection fault occur during actual tests.  This
// is contrary to the Intel docs which claim a #GP for
// eIP out of code limits.
//
// IRET to VM does affect IOPL, IF, VM, and RF


{$if BX_SUPPORT_V8086_MODE = 1}


{$if BX_CPU_LEVEL >= 3}

procedure BX_CPU_C.stack_return_to_v86(new_eip:Bit32u; raw_cs_selector:Bit32u;flags32:Bit32u);
var
  temp_ESP, new_esp, esp_laddr:Bit32u;
  raw_es_selector, raw_ds_selector, raw_fs_selector,
         raw_gs_selector, raw_ss_selector:Bit16u;
begin


  // Must be 32bit effective opsize, VM is in upper 16bits of eFLAGS
  // CPL := 0 to get here

  // ----------------
  //or   orOLD GSoreSP+32
  //or   orOLD FSoreSP+28
  //or   orOLD DSoreSP+24
  //or   orOLD ESoreSP+20
  //or   orOLD SSoreSP+16
  //or OLD ESP    oreSP+12
  //orOLD EFLAGS  oreSP+8
  //or   orOLD CSoreSP+4
  //or OLD EIP    oreSP+0
  // ----------------

  if Boolean(Self.sregs[BX_SEG_REG_SS].cache.segment.d_b) then
    temp_ESP := ESP
  else
    temp_ESP := SP;

  // top 36 bytes of stack must be within stack limits, else #GP(0)
  if Boolean( can_pop(36)=0) then begin
    BX_PANIC(('iret: VM: top 36 bytes not within limits'));
    exception2([BX_SS_EXCEPTION, 0, 0]);
    exit;
    end;

  if Boolean( new_eip  and $ffff0000 ) then begin
    BX_INFO(('IRET to V86-mod_e: ignoring upper 16-bits'));
    new_eip := new_eip  and $ffff;
    end;

  esp_laddr := Self.sregs[BX_SEG_REG_SS].cache.segment.base +
              temp_ESP;

  // load SS:ESP from stack
  access_linear(esp_laddr + 12, 4, 0, BX_READ, @new_esp);
  access_linear(esp_laddr + 16, 2, 0, BX_READ, @raw_ss_selector);

  // load ES,DS,FS,GS from stack
  access_linear(esp_laddr + 20, 2, 0, BX_READ, @raw_es_selector);
  access_linear(esp_laddr + 24, 2, 0, BX_READ, @raw_ds_selector);
  access_linear(esp_laddr + 28, 2, 0, BX_READ, @raw_fs_selector);
  access_linear(esp_laddr + 32, 2, 0, BX_READ, @raw_gs_selector);

  write_eflags(flags32, (*change IOPL*) 1, (*change IF*) 1,
                  (*change VM*) 1, (*change RF*) 1);

  // load CS:EIP from stack; already read and passed as args
  Self.sregs[BX_SEG_REG_CS].selector.value := raw_cs_selector;
  EIP := new_eip;

  Self.sregs[BX_SEG_REG_ES].selector.value := raw_es_selector;
  Self.sregs[BX_SEG_REG_DS].selector.value := raw_ds_selector;
  Self.sregs[BX_SEG_REG_FS].selector.value := raw_fs_selector;
  Self.sregs[BX_SEG_REG_GS].selector.value := raw_gs_selector;
  Self.sregs[BX_SEG_REG_SS].selector.value := raw_ss_selector;
  ESP := new_esp; // Full 32bits are loaded.

  init_v8086_mode(); 
end;

procedure BX_CPU_C.stack_return_from_v86(I:PBxInstruction_tag);
var
  times:Bit32u;
  eip_, ecs_raw, eflags:Bit32u;
  ip_, cs_raw, flags:Bit16u;
begin
  Inc(Times);
  if Boolean(times<100) then begin
    BX_ERROR(('stack_return_from_v86 may not be implemented right!'));
  end else if Boolean(times=100) then begin
    BX_ERROR(('stack_return_from_v86 called 100 times. I won''t print this error any more'));
  end;
  //exception2([BX_GP_EXCEPTION, 0, 0]);

{$if 1=1}
  if Boolean(IOPL <> 3) then begin
    // trap to virtual 8086 monitor
    BX_ERROR(('stack_return_from_v86: IOPL !:= 3'));
    exception2([BX_GP_EXCEPTION, 0, 0]);
    end;

  if Boolean(i^.os_32) then begin

// ??? should be some stack checks here
    pop_32(@eip_);
    pop_32(@ecs_raw);
    pop_32(@eflags);

    load_seg_reg(@Self.sregs[BX_SEG_REG_CS], Bit16u(ecs_raw));
    Self.eip := eip_;
    write_eflags(eflags, (*IOPL*) Bool(CPL=0), (*IF*) 1, (*VM*) 0, (*RF*) 1);
    end
  else begin

// ??? should be some stack checks here
    pop_16(@ip_);
    pop_16(@cs_raw);
    pop_16(@flags);

    load_seg_reg(@Self.sregs[BX_SEG_REG_CS], cs_raw);
    Self.eip := Bit32u(ip_);
    write_flags(flags, (*IOPL*) Bool(CPL=0), (*IF*) 1);
    end;
{$ifend}
end;

procedure BX_CPU_C.init_v8086_mode;
begin
  Self.sregs[BX_SEG_REG_CS].cache.valid                  := 1;
  Self.sregs[BX_SEG_REG_CS].cache.p                      := 1;
  Self.sregs[BX_SEG_REG_CS].cache.dpl                    := 3;
  Self.sregs[BX_SEG_REG_CS].cache.segmentType                := 1;
  Self.sregs[BX_SEG_REG_CS].cache.segment.executable   := 1;
  Self.sregs[BX_SEG_REG_CS].cache.segment.c_ed         := 0;
  Self.sregs[BX_SEG_REG_CS].cache.segment.r_w          := 1;
  Self.sregs[BX_SEG_REG_CS].cache.segment.a            := 1;
  Self.sregs[BX_SEG_REG_CS].cache.segment.base         :=
    Self.sregs[BX_SEG_REG_CS].selector.value shl 4;
  Self.sregs[BX_SEG_REG_CS].cache.segment.limit        := $ffff;
  Self.sregs[BX_SEG_REG_CS].cache.segment.limit_scaled := $ffff;
  Self.sregs[BX_SEG_REG_CS].cache.segment.g            := 0;
  Self.sregs[BX_SEG_REG_CS].cache.segment.d_b          := 0;
  Self.sregs[BX_SEG_REG_CS].cache.segment.avl          := 0;
  Self.sregs[BX_SEG_REG_CS].selector.rpl                 := 3;

  Self.sregs[BX_SEG_REG_SS].cache.valid                  := 1;
  Self.sregs[BX_SEG_REG_SS].cache.p                      := 1;
  Self.sregs[BX_SEG_REG_SS].cache.dpl                    := 3;
  Self.sregs[BX_SEG_REG_SS].cache.segmentType                := 1;
  Self.sregs[BX_SEG_REG_SS].cache.segment.executable   := 0;
  Self.sregs[BX_SEG_REG_SS].cache.segment.c_ed         := 0;
  Self.sregs[BX_SEG_REG_SS].cache.segment.r_w          := 1;
  Self.sregs[BX_SEG_REG_SS].cache.segment.a            := 1;
  Self.sregs[BX_SEG_REG_SS].cache.segment.base         :=
    Self.sregs[BX_SEG_REG_SS].selector.value shl 4;
  Self.sregs[BX_SEG_REG_SS].cache.segment.limit        := $ffff;
  Self.sregs[BX_SEG_REG_SS].cache.segment.limit_scaled := $ffff;
  Self.sregs[BX_SEG_REG_SS].cache.segment.g            := 0;
  Self.sregs[BX_SEG_REG_SS].cache.segment.d_b          := 0;
  Self.sregs[BX_SEG_REG_SS].cache.segment.avl          := 0;
  Self.sregs[BX_SEG_REG_SS].selector.rpl                 := 3;

  Self.sregs[BX_SEG_REG_ES].cache.valid                  := 1;
  Self.sregs[BX_SEG_REG_ES].cache.p                      := 1;
  Self.sregs[BX_SEG_REG_ES].cache.dpl                    := 3;
  Self.sregs[BX_SEG_REG_ES].cache.segmentType                := 1;
  Self.sregs[BX_SEG_REG_ES].cache.segment.executable   := 0;
  Self.sregs[BX_SEG_REG_ES].cache.segment.c_ed         := 0;
  Self.sregs[BX_SEG_REG_ES].cache.segment.r_w          := 1;
  Self.sregs[BX_SEG_REG_ES].cache.segment.a            := 1;
  Self.sregs[BX_SEG_REG_ES].cache.segment.base         :=
    Self.sregs[BX_SEG_REG_ES].selector.value shl 4;
  Self.sregs[BX_SEG_REG_ES].cache.segment.limit        := $ffff;
  Self.sregs[BX_SEG_REG_ES].cache.segment.limit_scaled := $ffff;
  Self.sregs[BX_SEG_REG_ES].cache.segment.g            := 0;
  Self.sregs[BX_SEG_REG_ES].cache.segment.d_b          := 0;
  Self.sregs[BX_SEG_REG_ES].cache.segment.avl          := 0;
  Self.sregs[BX_SEG_REG_ES].selector.rpl                 := 3;

  Self.sregs[BX_SEG_REG_DS].cache.valid                  := 1;
  Self.sregs[BX_SEG_REG_DS].cache.p                      := 1;
  Self.sregs[BX_SEG_REG_DS].cache.dpl                    := 3;
  Self.sregs[BX_SEG_REG_DS].cache.segmentType                := 1;
  Self.sregs[BX_SEG_REG_DS].cache.segment.executable   := 0;
  Self.sregs[BX_SEG_REG_DS].cache.segment.c_ed         := 0;
  Self.sregs[BX_SEG_REG_DS].cache.segment.r_w          := 1;
  Self.sregs[BX_SEG_REG_DS].cache.segment.a            := 1;
  Self.sregs[BX_SEG_REG_DS].cache.segment.base         :=
    Self.sregs[BX_SEG_REG_DS].selector.value shl 4;
  Self.sregs[BX_SEG_REG_DS].cache.segment.limit        := $ffff;
  Self.sregs[BX_SEG_REG_DS].cache.segment.limit_scaled := $ffff;
  Self.sregs[BX_SEG_REG_DS].cache.segment.g            := 0;
  Self.sregs[BX_SEG_REG_DS].cache.segment.d_b          := 0;
  Self.sregs[BX_SEG_REG_DS].cache.segment.avl          := 0;
  Self.sregs[BX_SEG_REG_DS].selector.rpl                 := 3;

  Self.sregs[BX_SEG_REG_FS].cache.valid                  := 1;
  Self.sregs[BX_SEG_REG_FS].cache.p                      := 1;
  Self.sregs[BX_SEG_REG_FS].cache.dpl                    := 3;
  Self.sregs[BX_SEG_REG_FS].cache.segmentType                := 1;
  Self.sregs[BX_SEG_REG_FS].cache.segment.executable   := 0;
  Self.sregs[BX_SEG_REG_FS].cache.segment.c_ed         := 0;
  Self.sregs[BX_SEG_REG_FS].cache.segment.r_w          := 1;
  Self.sregs[BX_SEG_REG_FS].cache.segment.a            := 1;
  Self.sregs[BX_SEG_REG_FS].cache.segment.base         :=
    Self.sregs[BX_SEG_REG_FS].selector.value shl 4;
  Self.sregs[BX_SEG_REG_FS].cache.segment.limit        := $ffff;
  Self.sregs[BX_SEG_REG_FS].cache.segment.limit_scaled := $ffff;
  Self.sregs[BX_SEG_REG_FS].cache.segment.g            := 0;
  Self.sregs[BX_SEG_REG_FS].cache.segment.d_b          := 0;
  Self.sregs[BX_SEG_REG_FS].cache.segment.avl          := 0;
  Self.sregs[BX_SEG_REG_FS].selector.rpl                 := 3;

  Self.sregs[BX_SEG_REG_GS].cache.valid                  := 1;
  Self.sregs[BX_SEG_REG_GS].cache.p                      := 1;
  Self.sregs[BX_SEG_REG_GS].cache.dpl                    := 3;
  Self.sregs[BX_SEG_REG_GS].cache.segmentType                := 1;
  Self.sregs[BX_SEG_REG_GS].cache.segment.executable   := 0;
  Self.sregs[BX_SEG_REG_GS].cache.segment.c_ed         := 0;
  Self.sregs[BX_SEG_REG_GS].cache.segment.r_w          := 1;
  Self.sregs[BX_SEG_REG_GS].cache.segment.a            := 1;
  Self.sregs[BX_SEG_REG_GS].cache.segment.base         :=
    Self.sregs[BX_SEG_REG_GS].selector.value shl 4;
  Self.sregs[BX_SEG_REG_GS].cache.segment.limit        := $ffff;
  Self.sregs[BX_SEG_REG_GS].cache.segment.limit_scaled := $ffff;
  Self.sregs[BX_SEG_REG_GS].cache.segment.g            := 0;
  Self.sregs[BX_SEG_REG_GS].cache.segment.d_b          := 0;
  Self.sregs[BX_SEG_REG_GS].cache.segment.avl          := 0;
  Self.sregs[BX_SEG_REG_GS].selector.rpl                 := 3;
end;


{$ifend} (* BX_CPU_LEVEL >= 3 *)





{$else}  // BX_SUPPORT_V8086_mod_E

// non-support of v8086 mod_e

  procedure
BX_CPU_C.stack_return_to_v86(Bit32u new_eip, Bit32u raw_cs_selector, Bit32u flags32)
begin
  BX_INFO(('stack_return_to_v86: VM bit set in EFLAGS stack image'));
  v8086_message();
end;

  procedure
BX_CPU_C.stack_return_from_v86(procedure)
begin
  BX_INFO(('stack_return_from_v86:'));
  v8086_message();
end;

  procedure
BX_CPU_C.v8086_message(procedure)
begin
  BX_INFO(('Program compiled with BX_SUPPORT_V8086_mod_E := 0'));
  BX_INFO(('You need to rerun the configure script and recompile'));
  BX_INFO(('  to use virtual-8086 mod_e features.'));
  BX_PANIC(('Bummer!'));
end;
{$ifend} // BX_SUPPORT_V8086_mod_E
