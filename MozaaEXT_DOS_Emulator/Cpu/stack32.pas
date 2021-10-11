{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.POP_Ed(I:PBxInstruction_tag);
var
  val32:Bit32u;
begin

  pop_32(@val32);

  if (i^.mod_ = $c0) then begin
    BX_WRITE_32BIT_REG(i^.rm, val32);
    end
  else begin
    // Note: there is one little weirdism here.  When 32bit addressing
    // is used, it is possible to use ESP in the mod_rm addressing.
    // If used, the value of ESP after the pop is used to calculate
    // the address.
    if ((i^.as_32<>0) and (i^.mod_<>$c0) and (i^.rm=4) and (i^.base=4)) then begin
      // call method on BX_CPU_C object
      i^.Resolvemodrm(i);
      end;
    write_virtual_dword(i^.seg, i^.rm_addr, @val32);
    end;
end;

procedure BX_CPU_C.PUSH_ERX(I:PBxInstruction_tag);
begin
  push_32(self.gen_reg[i^.b1  and $07].erx);
end;

procedure BX_CPU_C.POP_ERX(I:PBxInstruction_tag);
var
  erx:Bit32u;
begin

  pop_32(@erx);
  self.gen_reg[i^.b1  and $07].erx := erx;
end;

procedure BX_CPU_C.PUSH_CS(I:PBxInstruction_tag);
begin
  if (i^.os_32)<>0 then
    push_32(self.sregs[BX_SEG_REG_CS].selector.value)
  else
    push_16(self.sregs[BX_SEG_REG_CS].selector.value);
end;

procedure BX_CPU_C.PUSH_DS(I:PBxInstruction_tag);
begin
  if (i^.os_32)<>0 then
    push_32(self.sregs[BX_SEG_REG_DS].selector.value)
  else
    push_16(self.sregs[BX_SEG_REG_DS].selector.value);
end;

procedure BX_CPU_C.PUSH_ES(I:PBxInstruction_tag);
begin
  if (i^.os_32)<>0 then
    push_32(self.sregs[BX_SEG_REG_ES].selector.value)
  else
    push_16(self.sregs[BX_SEG_REG_ES].selector.value);
end;

procedure BX_CPU_C.PUSH_FS(I:PBxInstruction_tag);
begin
  if (i^.os_32)<>0 then
    push_32(self.sregs[BX_SEG_REG_FS].selector.value)
  else
    push_16(self.sregs[BX_SEG_REG_FS].selector.value);
end;

procedure BX_CPU_C.PUSH_GS(I:PBxInstruction_tag);
begin
  if (i^.os_32)<>0 then
    push_32(self.sregs[BX_SEG_REG_GS].selector.value)
  else
    push_16(self.sregs[BX_SEG_REG_GS].selector.value);
end;

procedure BX_CPU_C.PUSH_SS(I:PBxInstruction_tag);
begin
  if (i^.os_32)<>0 then
    push_32(self.sregs[BX_SEG_REG_SS].selector.value)
  else
    push_16(self.sregs[BX_SEG_REG_SS].selector.value);
end;

procedure BX_CPU_C.POP_DS(I:PBxInstruction_tag);
var
  ds:Bit32u;
  ds_16:Bit16u;
begin
  if (i^.os_32)<>0 then begin
    pop_32(@ds);
    load_seg_reg(@self.sregs[BX_SEG_REG_DS], Bit16u(ds));
    end
  else begin
    pop_16(@ds_16);
    load_seg_reg(@self.sregs[BX_SEG_REG_DS], ds_16);
    end;
end;

procedure BX_CPU_C.POP_ES(I:PBxInstruction_tag);
var
  es:Bit32u;
  es_16:Bit16u;
begin
  if (i^.os_32)<>0 then begin
    pop_32(@es);
    load_seg_reg(@self.sregs[BX_SEG_REG_ES], Bit16u(es));
    end
  else begin
    pop_16(@es_16);
    load_seg_reg(@self.sregs[BX_SEG_REG_ES], es_16);
    end;
end;

procedure BX_CPU_C.POP_FS(I:PBxInstruction_tag);
var
  fs:Bit32u;
  fs_16:Bit16u;
begin
  if (i^.os_32)<>0 then begin
    pop_32(@fs);
    load_seg_reg(@self.sregs[BX_SEG_REG_FS], Bit16u(fs));
    end
  else begin
    pop_16(@fs);
    load_seg_reg(@self.sregs[BX_SEG_REG_FS], fs);
    end;
end;

procedure BX_CPU_C.POP_GS(I:PBxInstruction_tag);
var
  gs:Bit32u;
  gs_16:Bit16u;
begin
  if (i^.os_32)<>0 then begin
    pop_32(@gs);
    load_seg_reg(@self.sregs[BX_SEG_REG_GS], Bit16u(gs));
    end
  else begin
    pop_16(@gs);
    load_seg_reg(@self.sregs[BX_SEG_REG_GS], gs);
    end;
end;

procedure BX_CPU_C.POP_SS(I:PBxInstruction_tag);
var
  ss:Bit32u;
  ss_16:Bit16u;
begin
  if (i^.os_32)<>0 then begin
    pop_32(@ss);
    load_seg_reg(@self.sregs[BX_SEG_REG_SS], Bit16u(ss));
    end
  else begin
    pop_16(@ss);
    load_seg_reg(@self.sregs[BX_SEG_REG_SS], ss);
    end;

  // POP SS inhibits interrupts, debug exceptions and single-step
  // trap exceptions until the execution boundary following the
  // next instruction is reached.
  // Same code as MOV_SwEw()
  self.inhibit_mask := self.inhibit_mask or BX_INHIBIT_INTERRUPTS or BX_INHIBIT_DEBUG;
  self.async_event := 1;
end;

procedure BX_CPU_C.PUSHAD32(I:PBxInstruction_tag);
var
  temp_ESP:Bit32u;
  esp_:Bit32u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('PUSHAD: not supported on an 8086'));
{$else}

  if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
    temp_ESP := ESP
  else
    temp_ESP := SP;


    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if ( can_push(@self.sregs[BX_SEG_REG_SS].cache, temp_ESP, 32)=0) then begin
        BX_PANIC(('PUSHAD(): stack doesn''t have enough room!'));
        exception2([BX_SS_EXCEPTION, 0, 0]);
        exit;
        end;
      end
  else begin
      if (temp_ESP < 32) then
        BX_PANIC(('pushad: eSP < 32'));
      end;

    esp_ := ESP;

    (* ??? optimize this by using virtual write, all checks passed *)
    push_32(EAX);
    push_32(ECX);
    push_32(EDX);
    push_32(EBX);
    push_32(esp_);
    push_32(EBP);
    push_32(ESI);
    push_32(EDI);
{$ifend}
end;

procedure BX_CPU_C.POPAD32(I:PBxInstruction_tag);
var
  edi_, esi_, ebp_, etmp_, ebx_, edx_, ecx_, eax_:Bit32u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('POPAD not supported on an 8086'));
{$else} (* 286+ *)

    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if Boolean( can_pop(32)=0) then begin
        BX_PANIC(('pop_ad: not enough bytes on stack'));
        exception2([BX_SS_EXCEPTION, 0, 0]);
        exit;
        end;
      end;

    (* ??? optimize this *)
    pop_32(@edi_);
    pop_32(@esi_);
    pop_32(@ebp_);
    pop_32(@etmp_); (* value for ESP discarded *)
    pop_32(@ebx_);
    pop_32(@edx_);
    pop_32(@ecx_);
    pop_32(@eax_);

    EDI := edi_;
    ESI := esi_;
    EBP := ebp_;
    EBX := ebx_;
    EDX := edx_;
    ECX := ecx_;
    EAX := eax_;
{$ifend}
end;

procedure BX_CPU_C.PUSH_Id(I:PBxInstruction_tag);
var
  imm32:Bit32u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('PUSH_Iv: not supported on 8086!'));
{$else}

    imm32 := i^.Id;

    push_32(imm32);
{$ifend}
end;

procedure BX_CPU_C.PUSH_Ed(I:PBxInstruction_tag);
var
  op1_32:Bit32u;
begin

    (* op1_32 is a register or memory reference *)
    if Boolean(i^.mod_ = $c0) then begin
      op1_32 := BX_READ_32BIT_REG(i^.rm);
      end
  else begin
      (* pointer, segment address pair *)
      read_virtual_dword(i^.seg, i^.rm_addr, @op1_32);
      end;

    push_32(op1_32);
end;

procedure BX_CPU_C.ENTER_IwIb(I:PBxInstruction_tag);
var
  frame_ptr32:Bit32u;
  frame_ptr16:Bit16u;
  level:Bit8u;
  first_time:Bit8u;
  bytes_to_push, temp_ESP:Bit32u;
  temp32:Bit32u;
  temp16:Bit16u;
begin
  first_time:=1;
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('ENTER_IwIb: not supported by 8086!'));
{$else}

  level := i^.Ib2;

  invalidate_prefetch_q();

  level := level mod 32;
(* ??? *)
  if ((first_time<>0) and (level>0)) then begin
    BX_ERROR(('enter() with level > 0. The emulation of this instruction may not be complete.  This warning will be printed only once per bochs run.'));
    first_time := 0;
  end;
//if Boolean(self.sregs[BX_SEG_REG_SS].cache.u.segment.d_b @ and i^.os_32=0) then begin
//  BX_INFO(('enter(): stacksize!:=opsize: I'm unsure of the code for this'));
//  BX_PANIC(('         The Intel manuals are a mess on this one!'));
//  end;

  if ( Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)) )<>0 then begin

    if (level = 0) then begin
      if (i^.os_32)<>0 then
        bytes_to_push := 4 + i^.Iw
      else
        bytes_to_push := 2 + i^.Iw;
      end
  else begin (* level > 0 *)
      if (i^.os_32)<>0 then
        bytes_to_push := 4 + (level-1)*4 + 4 + i^.Iw
      else
        bytes_to_push := 2 + (level-1)*2 + 2 + i^.Iw;
      end;
    if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
      temp_ESP := ESP
    else
      temp_ESP := SP;
    if ( can_push(@self.sregs[BX_SEG_REG_SS].cache, temp_ESP, bytes_to_push)=0) then begin
      BX_PANIC(('ENTER: not enough room on stack!'));
      exception2([BX_SS_EXCEPTION, 0, 0]);
      end;
    end;

  if (i^.os_32)<>0 then
    push_32(EBP)
  else
    push_16(BP);

  // can just do frame_ptr32 := ESP for either case ???
  if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
    frame_ptr32 := ESP
  else
    frame_ptr32 := SP;

  if (level > 0) then begin
    (* do level-1 times *)
    while (level>0) do begin
      if (i^.os_32)<>0 then begin

        if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then begin (* 32bit stacksize *)
          EBP := EBP - 4;
          read_virtual_dword(BX_SEG_REG_SS, EBP, @temp32);
          ESP := ESP - 4;
          write_virtual_dword(BX_SEG_REG_SS, ESP, @temp32);
          end
        else begin (* 16bit stacksize *)
          BP := BP - 4;
          read_virtual_dword(BX_SEG_REG_SS, BP, @temp32);
          SP := SP - 4;
          write_virtual_dword(BX_SEG_REG_SS, SP, @temp32);
          end;
        end
      else begin (* 16bit opsize *)

        if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then begin (* 32bit stacksize *)
          EBP := EBP - 2;
          read_virtual_word(BX_SEG_REG_SS, EBP, @temp16);
          ESP := ESP - 2;
          write_virtual_word(BX_SEG_REG_SS, ESP, @temp16);
          end
        else begin (* 16bit stacksize *)
          BP := BP - 2;
          read_virtual_word(BX_SEG_REG_SS, BP, @temp16);
          SP := SP - 2;
          write_virtual_word(BX_SEG_REG_SS, SP, @temp16);
          end;
        end;
        Dec(level);
      end; (* while (--level) *)

    (* push(frame pointer) *)
    if (i^.os_32)<>0 then begin
      if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then begin (* 32bit stacksize *)
        ESP := ESP - 4;
        write_virtual_dword(BX_SEG_REG_SS, ESP, @frame_ptr32);
        end
      else begin
        SP := SP - 4;
        write_virtual_dword(BX_SEG_REG_SS, SP, @frame_ptr32);
        end;
      end
  else begin (* 16bit opsize *)
      if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then begin (* 32bit stacksize *)
        frame_ptr16 := frame_ptr32;
        ESP := ESP - 2;
        write_virtual_word(BX_SEG_REG_SS, ESP, @frame_ptr16);
        end
      else begin
        frame_ptr16 := frame_ptr32;
        SP := SP - 2;
        write_virtual_word(BX_SEG_REG_SS, SP, @frame_ptr16);
        end;
      end;
    end; (* if Boolean(level > 0) ... *)

  if (i^.os_32)<>0 then
    EBP := frame_ptr32
  else
    BP := frame_ptr32;

  if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then begin (* 32bit stacksize *)
    ESP := ESP - i^.Iw;
    end
  else begin (* 16bit stack *)
    SP := SP - i^.Iw;
    end;
{$ifend}
end;

procedure BX_CPU_C.LEAVE(I:PBxInstruction_tag);
var
  temp_EBP:Bit32u;
  temp32:Bit32u;
  temp16:Bit16u;
begin
{$if BX_CPU_LEVEL < 2}
  BX_PANIC(('LEAVE: not supported by 8086!'));
{$else}
  invalidate_prefetch_q();

{$if BX_CPU_LEVEL >= 3}
  if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
    temp_EBP := EBP
  else
{$ifend}
    temp_EBP := BP;

  if ( Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)) )<>0 then begin
    if (self.sregs[BX_SEG_REG_SS].cache.segment.c_ed)<>0 then begin (* expand up *)
      if (temp_EBP <= self.sregs[BX_SEG_REG_SS].cache.segment.limit_scaled) then begin
        BX_PANIC(('LEAVE: BP > self.sregs[BX_SEG_REG_SS].limit'));
        exception2([BX_SS_EXCEPTION, 0, 0]);
        exit;
        end;
      end
  else begin (* normal *)
      if (temp_EBP > self.sregs[BX_SEG_REG_SS].cache.segment.limit_scaled) then begin
        BX_PANIC(('LEAVE: BP > self.sregs[BX_SEG_REG_SS].limit'));
        exception2([BX_SS_EXCEPTION, 0, 0]);
        exit;
        end;
      end;
    end;


  // delete frame
{$if BX_CPU_LEVEL >= 3}
  if (self.sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
    ESP := EBP
  else
{$ifend}
    SP := BP;

  // restore frame pointer
{$if BX_CPU_LEVEL >= 3}
  if (i^.os_32)<>0 then begin

    pop_32(@temp32);
    EBP := temp32;
    end
  else
{$ifend}
    begin

    pop_16(@temp16);
    BP := temp16;
    end;
{$ifend}
end;
