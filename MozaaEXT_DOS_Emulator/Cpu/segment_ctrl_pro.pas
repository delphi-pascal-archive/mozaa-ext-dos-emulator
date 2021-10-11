{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
procedure BX_CPU_C.load_seg_reg(seg:pbx_segment_reg_t; new_value:Bit16u);
var
  index:Bit16u;
  ti:Bit8u;
  rpl:Bit8u;
  descriptor:bx_descriptor_t;
  dword1, dword2:Bit32u;
begin
{$if BX_CPU_LEVEL >= 3}
  if Boolean(v8086_mode()) then begin
    { ??? don't need to set all these fields }
    seg^.selector.value := new_value;
    seg^.selector.rpl := 3;
    seg^.cache.valid := 1;
    seg^.cache.p := 1;
    seg^.cache.dpl := 3;
    seg^.cache.segmenttype := 1; { regular segment }
    if (seg = @sregs[BX_SREG_CS]) then
      seg^.cache.segment.executable := 1 { code segment }
    else
      seg^.cache.segment.executable := 0; { data segment }
    seg^.cache.segment.c_ed := 0; { expand up }
    seg^.cache.segment.r_w := 1; { writeable }
    seg^.cache.segment.a := 1; { accessed }
    seg^.cache.segment.base := new_value shl 4;
    seg^.cache.segment.limit        := $ffff;
    seg^.cache.segment.limit_scaled := $ffff;
    seg^.cache.segment.g     := 0; { byte granular }
    seg^.cache.segment.d_b   := 0; { default 16bit size }
    seg^.cache.segment.avl   := 0;

    exit;
    end;
{$ifend}

{$if BX_CPU_LEVEL >= 2}
  if Boolean(Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0))) then begin
    if (seg = @sregs[BX_SREG_SS]) then begin

      if Boolean((new_value and $fffc) = 0) then begin { null selector }
        BX_PANIC(('load_seg_reg: SS: new_value := 0'));
        exception2([BX_GP_EXCEPTION, 0, 0]);
        exit;
        end;

      index := new_value shr 3;
      ti := (new_value shr 2) and $01;
      rpl := (new_value and $03);

      { examine AR byte of destination selector for legal values: }

      if (ti = 0) then begin { GDT }
        if ((index*8 + 7) >  gdtr.limit) then begin
          //BX_PANIC(('load_seg_reg: GDT: %s: index(%04x*8+7) > limit(%06x)',
             //strseg(seg), (unsigned) index, (unsigned)  gdtr.limit));
          exception2([BX_GP_EXCEPTION, new_value and $fffc, 0]);
          exit;
          end;
        access_linear( gdtr.base + index*8,     4, 0,
          BX_READ, @dword1);
        access_linear( gdtr.base + index*8 + 4, 4, 0,
          BX_READ, @dword2);
        end
      else begin { LDT }
        if ( ldtr.cache.valid=0) then begin { ??? }
          BX_ERROR(('load_seg_reg: LDT invalid'));
          exception2([BX_GP_EXCEPTION, new_value and $fffc, 0]);
          exit;
          end;
        if ((index*8 + 7) >  ldtr.cache.ldt.limit) then begin
          BX_ERROR(('load_seg_reg ss: LDT: index > limit'));
          exception2([BX_GP_EXCEPTION, new_value and $fffc, 0]);
          exit;
          end;
        access_linear( ldtr.cache.ldt.base + index*8,     4, 0,
          BX_READ, @dword1);
        access_linear( ldtr.cache.ldt.base + index*8 + 4, 4, 0,
          BX_READ, @dword2);
        end;

      { selector's RPL must := CPL, else #GP(selector) }
      if (rpl <> CPL) then begin
        BX_ERROR(('load_seg_reg(): rpl !:= CPL'));
        exception2([BX_GP_EXCEPTION, new_value and $fffc, 0]);
        exit;
        end;

      parse_descriptor(dword1, dword2, @descriptor);

      if (descriptor.valid=0) then begin
        BX_ERROR(('load_seg_reg(): valid bit cleared'));
        exception2([BX_GP_EXCEPTION, new_value and $fffc, 0]);
        exit;
        end;

      { AR byte must indicate a writable data segment else #GP(selector) }
      if Boolean((Word(descriptor.segmenttype=0) or descriptor.segment.executable or Bool(descriptor.segment.r_w=0 ))) then begin
        BX_ERROR(('load_seg_reg(): not writable data segment'));
        exception2([BX_GP_EXCEPTION, new_value and $fffc, 0]);
        end;

      { DPL in the AR byte must equal CPL else #GP(selector) }
      if (descriptor.dpl <> CPL) then begin
        BX_ERROR(('load_seg_reg(): dpl !:= CPL'));
        exception2([BX_GP_EXCEPTION, new_value and $fffc, 0]);
        end;

      { segment must be marked PRESENT else #SS(selector) }
      if (descriptor.p = 0) then begin
        BX_ERROR(('load_seg_reg(): not present'));
        exception2([BX_SS_EXCEPTION, new_value and $fffc, 0]);
        end;

      { load SS with selector, load SS cache with descriptor }
       sregs[BX_SEG_REG_SS].selector.value        := new_value;
       sregs[BX_SEG_REG_SS].selector.index        := index;
       sregs[BX_SEG_REG_SS].selector.ti           := ti;
       sregs[BX_SEG_REG_SS].selector.rpl          := rpl;
       sregs[BX_SEG_REG_SS].cache := descriptor;
       sregs[BX_SEG_REG_SS].cache.valid             := 1;

      { now set accessed bit in descriptor }
      dword2 := dword2 or $0100;
      if (ti = 0) then begin { GDT }
        access_linear( gdtr.base + index*8 + 4, 4, 0, BX_WRITE, @dword2);
        end
      else begin { LDT }
        access_linear( ldtr.cache.ldt.base + index*8 + 4, 4, 0, BX_WRITE, @dword2);
        end;

      exit;
      end
    else if ( (seg=@sregs[BX_SREG_DS]) or (seg=@sregs[BX_SREG_ES])
{$if BX_CPU_LEVEL >= 3}
           or (seg=@sregs[BX_SREG_FS]) or (seg=@sregs[BX_SREG_GS])
{$ifend}
            ) then begin


      if ((new_value and $fffc) = 0) then begin { null selector }
        seg^.selector.index := 0;
        seg^.selector.ti := 0;
        seg^.selector.rpl := 0;
        seg^.selector.value := 0;
        seg^.cache.valid := 0; { invalidate null selector }
        exit;
        end;

      index := new_value shr 3;
      ti := (new_value shr 2) and $01;
      rpl := (new_value and $03);

      { selector index must be within descriptor limits, else #GP(selector) }

      if (ti = 0) then begin { GDT }
        if ((index*8 + 7) >  gdtr.limit) then begin
          //BX_ERROR(('load_seg_reg: GDT: %s: index(%04x) > limit(%06x)',
          //   strseg(seg), (unsigned) index, (unsigned)  gdtr.limit));
          exception2([BX_GP_EXCEPTION, new_value and $fffc, 0]);
          exit;
          end;
        access_linear( gdtr.base + index*8,     4, 0,  BX_READ, @dword1);
        access_linear( gdtr.base + index*8 + 4, 4, 0,  BX_READ, @dword2);
        end
      else begin { LDT }
        if ( ldtr.cache.valid=0) then begin
          BX_ERROR(('load_seg_reg: LDT invalid'));
          exception2([BX_GP_EXCEPTION, new_value and $fffc, 0]);
          exit;
          end;
        if ((index*8 + 7) >  ldtr.cache.ldt.limit) then begin
          BX_ERROR(('load_seg_reg ds,es: LDT: index > limit'));
          exception2([BX_GP_EXCEPTION, new_value and $fffc, 0]);
          exit;
          end;
        access_linear( ldtr.cache.ldt.base + index*8,     4, 0, BX_READ, @dword1);
        access_linear( ldtr.cache.ldt.base + index*8 + 4, 4, 0, BX_READ, @dword2);
        end;

      parse_descriptor(dword1, dword2, @descriptor);

      if (descriptor.valid=0) then begin
        BX_ERROR(('load_seg_reg(): valid bit cleared'));
        exception2([BX_GP_EXCEPTION, new_value and $fffc, 0]);
        exit;
        end;

      { AR byte must indicate data or readable code segment else #GP(selector) } //!!!
(*      if ( descriptor.segment=0 or ((descriptor.segment.executable=1) and (descriptor.segment.r_w=0)) then begin
        BX_ERROR(('load_seg_reg(): not data or readable code'));
        exception(BX_GP_EXCEPTION, new_value @ $fffc, 0);
        exit;
        end;*)

      { If data or non-conforming code, then both the RPL and the CPL
       * must be less than or equal to DPL in AR byte else #GP(selector) }
      if (descriptor.segment.executable=0) or (descriptor.segment.c_ed=0) then begin
        if ((rpl > descriptor.dpl) or (CPL > descriptor.dpl)) then begin
          BX_ERROR(('load_seg_reg: RPL @ CPL must be <:= DPL'));
          exception2([BX_GP_EXCEPTION, new_value and $fffc, 0]);
          exit;
          end;
        end;

      { segment must be marked PRESENT else #NP(selector) }
      if (descriptor.p = 0) then begin
        BX_ERROR(('load_seg_reg: segment not present'));
        exception2([BX_NP_EXCEPTION, new_value and $fffc, 0]);
        exit;
        end;

      { load segment register with selector }
      { load segment register-cache with descriptor }
      seg^.selector.value        := new_value;
      seg^.selector.index        := index;
      seg^.selector.ti           := ti;
      seg^.selector.rpl          := rpl;
      seg^.cache := descriptor;
      seg^.cache.valid             := 1;

      if Boolean((dword2 and $0100)=0) then begin

        dword2 := dword2 or $0100;
        if (ti = 0) then begin { GDT }
          access_linear( gdtr.base + index*8 + 4, 4, 0, BX_WRITE, @dword2);
        end
        else begin { LDT }
         access_linear( ldtr.cache.ldt.base + index*8 + 4, 4, 0, BX_WRITE, @dword2);

        end;

      end;
      exit;
      end
    else begin
      BX_PANIC(('load_seg_reg(): invalid segment register passed!'));
      exit;
      end;
    end;

  { real mode }
  { seg^.limit := ; ??? different behaviours depening on seg reg. }
  { something about honoring previous values }

  { ??? }
  if (seg = @sregs[BX_SREG_CS]) then begin
     sregs[BX_SEG_REG_CS].selector.value := new_value;
     sregs[BX_SEG_REG_CS].cache.valid := 1;
     sregs[BX_SEG_REG_CS].cache.p := 1;
     sregs[BX_SEG_REG_CS].cache.dpl := 0;
     sregs[BX_SEG_REG_CS].cache.segmenttype := 1; { regular segment }
     sregs[BX_SEG_REG_CS].cache.segment.executable := 1; { code segment }
     sregs[BX_SEG_REG_CS].cache.segment.c_ed := 0; { expand up }
     sregs[BX_SEG_REG_CS].cache.segment.r_w := 1; { writeable }
     sregs[BX_SEG_REG_CS].cache.segment.a := 1; { accessed }
     sregs[BX_SEG_REG_CS].cache.segment.base := new_value shl 4;
     sregs[BX_SEG_REG_CS].cache.segment.limit        := $ffff;
     sregs[BX_SEG_REG_CS].cache.segment.limit_scaled := $ffff;
{$if BX_CPU_LEVEL >= 3}
     sregs[BX_SEG_REG_CS].cache.segment.g     := 0; { byte granular }
     sregs[BX_SEG_REG_CS].cache.segment.d_b   := 0; { default 16bit size }
     sregs[BX_SEG_REG_CS].cache.segment.avl   := 0;
{$ifend}
    end
  else begin { SS, DS, ES, FS, GS }
    seg^.selector.value := new_value;
    seg^.cache.valid := 1;
    seg^.cache.p := 1; // set this???
    seg^.cache.segment.base := new_value shl 4;
    seg^.cache.segmenttype := 1; { regular segment }
    seg^.cache.segment.a := 1; { accessed }
    { set G, D_B, AVL bits here ??? }
    end;
{$else} { 8086 }

  seg^.selector.value := new_value;
  seg^.cache.u.segment.base := new_value shl 4;
{$ifend}
end;

{$if BX_CPU_LEVEL >= 2}
procedure BX_CPU_C.parse_selector(raw_selector:Bit16u; selector:pbx_selector_t);
begin
  selector^.value  := raw_selector;
  selector^.index  := raw_selector shr 3;
  selector^.ti     := (raw_selector shr 2) and $01;
  selector^.rpl    := raw_selector and $03;
end;
{$ifend}

procedure BX_CPU_C.parse_descriptor(dword1:Bit32u;dword2:Bit32u;temp:pbx_descriptor_t);
var
  AR_byte:Bit8u;
begin

  AR_byte        := dword2 shr 8;
  temp^.p        := (AR_byte shr 7) and $01;
  temp^.dpl      := (AR_byte shr 5) and $03;
  temp^.segmenttype  := (AR_byte shr 4) and $01;
  temp^.type_     := (AR_byte and $0f);
  temp^.valid    := 0; { start out invalid }


  if Boolean(temp^.segmenttype) then begin { data/code segment descriptors }
    temp^.segment.executable := (AR_byte shr 3) and $01;
    temp^.segment.c_ed       := (AR_byte shr 2) and $01;
    temp^.segment.r_w        := (AR_byte shr 1) and $01;
    temp^.segment.a          := (AR_byte shr 0) and $01;

    temp^.segment.limit      := (dword1 and $ffff);
    temp^.segment.base       := (dword1 shr 16) or ((dword2 and $FF) shl 16);

{$if BX_CPU_LEVEL >= 3}
    temp^.segment.limit        := temp^.segment.limit or (dword2 and $000F0000);
    temp^.segment.g            :=  Word((dword2 and $00800000) > 0);
    temp^.segment.d_b          :=  Word((dword2 and $00400000) > 0);
    temp^.segment.avl          :=  Word((dword2 and $00100000) > 0);
    temp^.segment.base         :=temp^.segment.base or (dword2 and $FF000000);
    if Boolean(temp^.segment.g) then begin
      if ( (temp^.segment.executable=0) and (temp^.segment.c_ed<>0) ) then
        temp^.segment.limit_scaled := (temp^.segment.limit shl 12)
      else
        temp^.segment.limit_scaled := (temp^.segment.limit shl 12) or $0fff;
      end
    else
{$ifend}
      temp^.segment.limit_scaled := temp^.segment.limit;

    temp^.valid    := 1;
    end
  else begin // system @ gate segment descriptors
    case temp^.type_ of
      0, // reserved
      8, // reserved
      10, // reserved
      13: // reserved
        begin
          temp^.valid    := 0;
        end;
      1, // 286 TSS (available)
      3: // 286 TSS (busy)
        begin
          temp^.tss286.base  := (dword1 shr 16) or ((dword2 and $ff) shl 16);
          temp^.tss286.limit := (dword1 and $ffff);
          temp^.valid    := 1;
        end;
      2: // LDT descriptor
        begin
          temp^.ldt.base := (dword1 shr 16) or ((dword2 and $FF) shl 16);
{$if BX_CPU_LEVEL >= 3}
          temp^.ldt.base := temp^.ldt.base or (dword2 and $ff000000);
{$ifend}
        temp^.ldt.limit := (dword1 and $ffff);
        temp^.valid    := 1;
        end;
      4, // 286 call gate
      6, // 286 interrupt gate
      7: // 286 trap gate
        { word count only used for call gate }
        begin
          temp^.gate286.word_count := dword2 and $1f;
          temp^.gate286.dest_selector := dword1 shr 16;
          temp^.gate286.dest_offset   := dword1 and $ffff;
          temp^.valid := 1;
        end;
      5: // 286/386 task gate
        begin
          temp^.taskgate.tss_selector := dword1 shr 16;
          temp^.valid := 1;
        end;

{$if BX_CPU_LEVEL >= 3}
      9,  // 386 TSS (available)
      11: // 386 TSS (busy)
        begin
          temp^.tss386.base  := (dword1 shr 16) or ((dword2 and $ff) shl 16) or (dword2 and $ff000000);
          temp^.tss386.limit := (dword1 and $0000ffff) or (dword2 and $000f0000);
          temp^.tss386.g     := Bool((dword2 and $00800000) > 0);
          temp^.tss386.avl   := Bool((dword2 and $00100000) > 0);
          if Boolean(temp^.tss386.g) then
            temp^.tss386.limit_scaled := (temp^.tss386.limit shl 12) or $0fff
          else
            temp^.tss386.limit_scaled := temp^.tss386.limit;
          temp^.valid := 1;
        end;

      12, // 386 call gate
      14, // 386 interrupt gate
      15: // 386 trap gate
        begin
        // word count only used for call gate
          temp^.gate386.dword_count   := dword2 and $1f;
          temp^.gate386.dest_selector := dword1 shr 16;;
          temp^.gate386.dest_offset   := (dword2 and $ffff0000) or (dword1 and $0000ffff);
          temp^.valid := 1;
        end;
{$ifend}
      else
        begin
          //BX_PANIC(('parse_descriptor(): case %d unfinished', temp^.type_)); !!!
          temp^.valid    := 0;
        end;
      end;
    end;
end;

procedure BX_CPU_C.load_ldtr(selector:pbx_selector_t; descriptor:pbx_descriptor_t);
begin
  { check for null selector, if so invalidate LDTR }
  if ( (selector^.value and $fffc) =0 ) then begin
     ldtr.selector := selector^;
     ldtr.cache.valid := 0;
    exit;
    end;

  if (@descriptor=nil) then
    BX_PANIC(('load_ldtr(): descriptor := NULL!'));

   ldtr.cache := descriptor^; { whole structure copy }
   ldtr.selector := selector^;

  if ( ldtr.cache.ldt.limit < 7) then begin
    BX_PANIC(('load_ldtr(): ldtr.limit < 7'));
    end;

   ldtr.cache.valid := 1;
end;

procedure BX_CPU_C.load_cs(selector:pbx_selector_t; descriptor:pbx_descriptor_t; cpl:Bit8u);
begin
   sregs[BX_SEG_REG_CS].selector     := selector^;
   sregs[BX_SEG_REG_CS].cache        := descriptor^;

  { caller may request different CPL then in selector }
   sregs[BX_SEG_REG_CS].selector.rpl := cpl;
   sregs[BX_SEG_REG_CS].cache.valid := 1; { ??? }
  // (BW) Added cpl to the selector value.
   sregs[BX_SEG_REG_CS].selector.value := ($fffc and sregs[BX_SEG_REG_CS].selector.value) or cpl;
end;

procedure BX_CPU_C.load_ss(selector:pbx_selector_t; descriptor:pbx_descriptor_t; cpl:Bit8u);
begin
   sregs[BX_SEG_REG_SS].selector := selector^;
   sregs[BX_SEG_REG_SS].cache := descriptor^;
   sregs[BX_SEG_REG_SS].selector.rpl := cpl;

  if ( ( sregs[BX_SEG_REG_SS].selector.value and $fffc) = 0 ) then
    BX_PANIC(('load_ss(): null selector passed'));

  if Boolean( sregs[BX_SEG_REG_SS].cache.valid =0) then begin
    BX_PANIC(('load_ss(): invalid selector/descriptor passed.'));
    end;
end;

{$if BX_CPU_LEVEL >= 2}
procedure BX_CPU_C.fetch_raw_descriptor(selector:pbx_selector_t;
                               dword1:pBit32u; dword2:pBit32u; exception_no:Bit8u);
begin
  if (selector^.ti = 0) then begin { GDT }
    if ((selector^.index*8 + 7) >  gdtr.limit) then begin
      BX_INFO(('-----------------------------------'));
      BX_INFO(Format('selector^.index*8 + 7 := %x', [selector^.index*8 + 7]));
      BX_INFO(Format('gdtr.limit := %x', [gdtr.limit]));
      BX_INFO(('fetch_raw_descriptor: GDT: index > limit'));
      //debug( prev_eip);
      BX_INFO(('-----------------------------------'));
      exception2([exception_no, selector^.value and $fffc, 0]);
      exit;
    end;
    access_linear( gdtr.base + selector^.index*8, 4, 0,  BX_READ, dword1);
    access_linear( gdtr.base + selector^.index*8 + 4, 4, 0, BX_READ, dword2);
    end
  else begin { LDT }
    if ( ldtr.cache.valid=0) then begin
      BX_PANIC(('fetch_raw_descriptor: LDTR.valid:=0'));
      end;
    if ((selector^.index*8 + 7) >  ldtr.cache.ldt.limit) then begin
      BX_PANIC(('fetch_raw_descriptor: LDT: index > limit'));
      exception(exception_no, selector^.value and $fffc, 0);
      exit;
    end;
    access_linear( ldtr.cache.ldt.base + selector^.index*8, 4, 0, BX_READ, dword1);
    access_linear( ldtr.cache.ldt.base + selector^.index*8 + 4, 4, 0, BX_READ, dword2);
    end;
end;
{$ifend}

function BX_CPU_C.fetch_raw_descriptor2(selector:pbx_selector_t; dword1:pBit32u; dword2:pBit32u):Bool;
begin
  if (selector^.ti = 0) then begin { GDT }
    if ((selector^.index*8 + 7) >  gdtr.limit) then
      begin
        Result:=0;
        exit;
      end;
    access_linear( gdtr.base + selector^.index*8, 4, 0, BX_READ, dword1);
    access_linear( gdtr.base + selector^.index*8 + 4, 4, 0, BX_READ, dword2);
     Result:=1;
     exit;
    end
  else begin { LDT }
    if ((selector^.index*8 + 7) >  ldtr.cache.ldt.limit) then
      begin
        Result:=0;
        exit;
      end;
    access_linear( ldtr.cache.ldt.base + selector^.index*8,     4, 0, BX_READ, dword1);
    access_linear( ldtr.cache.ldt.base + selector^.index*8 + 4, 4, 0, BX_READ, dword2);
    Result:=1;
    exit;
    end;
end;

