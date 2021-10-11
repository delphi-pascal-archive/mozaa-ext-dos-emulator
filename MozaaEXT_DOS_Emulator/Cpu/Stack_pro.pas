{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)

procedure BX_CPU_C.push_16(value16:Bit16u);
var
  temp_ESP:Bit32u;
begin

{$if BX_CPU_LEVEL >= 2}
  if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
{$if BX_CPU_LEVEL >= 3}
    if (sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
      temp_ESP := ESP
    else
{$ifend}
      temp_ESP := SP;
    if (can_push(@sregs[BX_SEG_REG_SS].cache, temp_ESP, 2)=0) then begin
      BX_PANIC(('push_16(): can''t push on stack'));
      exception2([BX_SS_EXCEPTION, 0, 0]);
      exit;
      end;

    (* access within limits *)
    write_virtual_word(BX_SEG_REG_SS, temp_ESP - 2, @value16);
    if (sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
      ESP := ESP - 2
    else
      SP := SP -2;
    exit;
    end
  else
{$ifend}
    begin (* real mod_e *)
    if (sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then begin
      if (ESP = 1) then
        BX_PANIC(('CPU shutting down due to lack of stack space, ESP=1'));
      ESP := ESP - 2;
      temp_ESP := ESP;
      end
  else begin
      if (SP = 1) then
        BX_PANIC(('CPU shutting down due to lack of stack space, SP=1'));
      SP := SP -2;
      temp_ESP := SP;
      end;

    write_virtual_word(BX_SEG_REG_SS, temp_ESP, @value16);
    exit;
    end;
end;

{$if BX_CPU_LEVEL >= 3}
  (* push 32 bit operand size *)
procedure BX_CPU_C.push_32(value32:Bit32u);
begin
  (* must use StackAddrSize, and either ESP or SP accordingly *)
  if (sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then begin (* StackAddrSize := 32 *)
    (* 32bit stack size: pushes use SS:ESP  *)
    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if (can_push(@sregs[BX_SEG_REG_SS].cache, ESP, 4)=0) then begin
        BX_PANIC(('push_32(): push outside stack limits'));
        (* #SS(0) *)
        end;
      end
  else begin (* real mod_e *)
      if ((ESP>=1) and (ESP<=3)) then begin
        BX_PANIC(Format('push_32: ESP:=%08x',[ESP]));
        end;
      end;

    write_virtual_dword(BX_SEG_REG_SS, ESP-4, @value32);
    ESP:=ESP-4;
    (* will return after error anyway *)
    exit;
    end
  else begin (* 16bit stack size: pushes use SS:SP  *)
    if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
      if (can_push(@sregs[BX_SEG_REG_SS].cache, SP, 4)=0) then begin
        BX_PANIC(('push_32(): push outside stack limits'));
        (* #SS(0) *)
        end;
      end
  else begin (* real mod_e *)
      if ((SP>=1) and (SP<=3)) then begin
        BX_PANIC(Format('push_32: SP:=%08x',[SP]));
        end;
      end;

    write_virtual_dword(BX_SEG_REG_SS, Bit16u(SP-4), @value32);
    SP:=SP-4;
    (* will return after error anyway *)
    exit;
    end;
end;
{$ifend} (* BX_CPU_LEVEL >= 3 *)

procedure BX_CPU_C.pop_16(value16_ptr:pBit16u);
var
  temp_ESP:Bit32u;
begin

{$if BX_CPU_LEVEL >= 3}
  if (sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
    temp_ESP := ESP
  else
{$ifend}
    temp_ESP := SP;

{$if BX_CPU_LEVEL >= 2}
  if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
    if ( can_pop(2)=0) then begin
      BX_INFO(('pop_16(): can''t pop from stack'));
      exception2([BX_SS_EXCEPTION, 0, 0]);
      exit;
      end;
    end;
{$ifend}


  (* access within limits *)
  read_virtual_word(BX_SEG_REG_SS, temp_ESP, value16_ptr);

  if (sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
    ESP:=ESP+2
  else
    SP:=SP+2;
end;

{$if BX_CPU_LEVEL >= 3}
procedure  BX_CPU_C.pop_32(value32_ptr:pBit32u);
var
  temp_ESP:Bit32u;
begin

  (* 32 bit stack mod_e: use SS:ESP *)
  if (sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then
    temp_ESP := ESP
  else
    temp_ESP := SP;

  (* 16 bit stack mod_e: use SS:SP *)
  if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then begin
    if Boolean( can_pop(4)=0) then begin
      BX_PANIC(('pop_32(): can''t pop from stack'));
      exception2([BX_SS_EXCEPTION, 0, 0]);
      exit;
      end;
    end;

  (* access within limits *)
  read_virtual_dword(BX_SEG_REG_SS, temp_ESP, value32_ptr);

  if (sregs[BX_SEG_REG_SS].cache.segment.d_b=1) then
    ESP:=ESP+4
  else
    SP:=SP+4;
end;
{$ifend}



{$if BX_CPU_LEVEL >= 2}
function BX_CPU_C.can_push(descriptor:pbx_descriptor_t; esp:Bit32u; bytes:Bit32u ):Bool;
var
  expand_down_limit:Bit32u;
begin
  if ( real_mode() )<>0 then begin (* code not needed ??? *)
    BX_PANIC(('can_push(): called in real mod_e'));
    Result:=0;
    exit; (* never gets here *)
    end;

  // small stack compares against 16-bit SP
  if (descriptor^.segment.d_b=0) then
    esp := esp and $0000ffff;


  if (descriptor^.valid=0) then begin
    BX_PANIC(('can_push(): SS invalidated.'));
    Result:=0;
    exit;
    end;

  if (descriptor^.p=0) then begin
    BX_PANIC(('can_push(): not present'));
    Result:=0;
    exit;
    end;


  if (descriptor^.segment.c_ed)<>0 then begin (* expand down segment *)

    if (descriptor^.segment.d_b)<>0 then
      expand_down_limit := $ffffffff
    else
      expand_down_limit := $0000ffff;

    if (esp=0) then begin
      BX_PANIC(('can_push(): esp:=0, wraparound?'));
      Result:=0;
      exit;
      end;

    if (esp < bytes) then begin
      BX_PANIC(('can_push(): expand-down: esp < N'));
      Result:=0;
      exit;
      end;
    if ( (esp - bytes) <= descriptor^.segment.limit_scaled ) then begin
      BX_PANIC(('can_push(): expand-down: esp-N < limit'));
      Result:=0;
      exit;
      end;
    if ( esp > expand_down_limit ) then begin
      BX_PANIC(('can_push(): esp > expand-down-limit'));
      Result:=0;
      exit;
      end;
      Result:=1;
      exit;
    end
  else begin (* normal (expand-up) segment *)
    if (descriptor^.segment.limit_scaled=0) then begin
      BX_PANIC(('can_push(): found limit of 0'));
      Result:=0;
      exit;
      end;

    // Look at case where esp=0.  Possibly, it's an intentional wraparound
    // If so, limit must be the maximum for the given stack size
    if (esp=0) then begin
      if ((descriptor^.segment.d_b <> 0) and (descriptor^.segment.limit_scaled=$ffffffff)) then
        begin
          Result:=1;
          Exit;
        end;
      if ((descriptor^.segment.d_b=0) and (descriptor^.segment.limit_scaled>=$ffff)) then
        begin
          Result:=1;
          Exit;
        end;
      BX_PANIC(Format('can_push(): esp:=0, normal, wraparound? limit:=%08x',[descriptor^.segment.limit_scaled]));
      Result:=0;
      end;

    if (esp < bytes) then begin
      BX_INFO(('can_push(): expand-up: esp < N'));
      Result:=0;
      exit;
      end;
    if ((esp-1) > descriptor^.segment.limit_scaled) then begin
      BX_INFO(('can_push(): expand-up: SP > limit'));
      Result:=0;
      exit;
      end;
    (* all checks pass *)
    Result:=1;
    Exit;
    end;
end;
{$ifend}


{$if BX_CPU_LEVEL >= 2}
function BX_CPU_C.can_pop(bytes:Bit32u):Bool ;
var
  temp_ESP, expand_down_limit:Bit32u;
begin

  (* ??? *)
  if (real_mode())<>0 then BX_PANIC(('can_pop(): called in real mod_e?'));

  if (sregs[BX_SEG_REG_SS].cache.segment.d_b)<>0 then begin (* Big bit set: use ESP *)
    temp_ESP := ESP;
    expand_down_limit := $FFFFFFFF;
    end
  else begin (* Big bit clear: use SP *)
    temp_ESP := SP;
    expand_down_limit := $FFFF;
    end;

  if (sregs[BX_SEG_REG_SS].cache.valid=0) then begin
    BX_PANIC(('can_pop(): SS invalidated.'));
    Result:=0; (* never gets here *)
    Exit;
    end;

  if (sregs[BX_SEG_REG_SS].cache.p=0) then begin (* ??? *)
    BX_PANIC(('can_pop(): SS.p := 0'));
    Result:=0; (* never gets here *)
    Exit;
    end;


  if (sregs[BX_SEG_REG_SS].cache.segment.c_ed)<>0 then begin (* expand down segment *)
    if ( temp_ESP = expand_down_limit ) then begin
      BX_PANIC(('can_pop(): found SP:=ffff'));
      Result:=0; (* never gets here *)
      Exit;
      end;
    if ( ((expand_down_limit - temp_ESP) + 1) >= bytes ) then
      begin
        Result:=1;
        Exit;
      end;
    Result:=0;
    Exit;
    end
  else begin (* normal (expand-up) segment *)
    if (sregs[BX_SEG_REG_SS].cache.segment.limit_scaled=0) then begin
      BX_PANIC(('can_pop(): SS.limit := 0'));
      end;
    if ( temp_ESP = expand_down_limit ) then begin
      BX_PANIC(('can_pop(): found SP:=ffff'));
    Result:=0;
    Exit;
      end;
    if ( temp_ESP > sregs[BX_SEG_REG_SS].cache.segment.limit_scaled ) then begin
      BX_PANIC(('can_pop(): eSP > SS.limit'));
    Result:=0;
    Exit;
      end;
    if ( ((sregs[BX_SEG_REG_SS].cache.segment.limit_scaled - temp_ESP) + 1) >= bytes ) then
      begin
        Result:=1;
        Exit;
      end;
    Result:=0;
    Exit;
    end;
end;
{$ifend}

