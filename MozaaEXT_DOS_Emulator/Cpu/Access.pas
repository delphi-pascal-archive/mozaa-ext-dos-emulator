{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)
procedure BX_CPU_C.read_virtual_checks(seg:pbx_segment_reg_t;  offset:Bit32u; length:Word);
var
  upper_limit:Bit32u;
begin
  if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then
    begin
      if  seg.cache.valid=0 then
        begin
          BX_ERROR(Format('seg = %s', [strseg(@seg)]));
          BX_ERROR(Format('seg->selector.value = %x', [seg.selector.value]));
          BX_ERROR('read_virtual_checks: valid bit = 0');
          BX_ERROR(Format('CS: %x', [sregs[1].selector.value]));
          BX_ERROR(Format('IP: %x', [prev_eip]));
          //debug(BX_CPU_THIS_PTR eip);
          exception2([BX_GP_EXCEPTION, 0, 0]);
          exit;
        end;

    if seg.cache.p = 0 then
      begin  // not present
    	  BX_INFO('read_virtual_checks(): segment not present');
        exception2([int_number(seg), 0, 0]);
        exit;
      end;
      case seg.cache.type_ of
        0,1,    // read only
        10, 11, // execute/read
        14, 15: // execute/read-only, conforming
          begin
            if (offset > (seg.cache.segment.limit_scaled - length + 1)) or (length-1 > seg.cache.segment.limit_scaled) then
              begin
                BX_INFO('read_virtual_checks(): write beyond limit');
                exception(int_number(seg), 0, 0);
                exit;
              end;
          end;

        2,3: // read/write
          begin
            if (offset > (seg.cache.segment.limit_scaled - length + 1)) or (length-1 > seg.cache.segment.limit_scaled) then
              begin
                BX_INFO('read_virtual_checks(): write beyond limit');
                exception(int_number(seg), 0, 0);
              end;
          end;
        4,5: // read only, expand down
          begin
            if (seg.cache.segment.d_b)<>0 then
              upper_limit := $ffffffff
            else
              upper_limit := $0000ffff;

            if ( (offset <= seg.cache.segment.limit_scaled) or (offset > upper_limit)
               or ((upper_limit - offset) < (length - 1)) ) then
               begin
                BX_INFO(('read_virtual_checks(): write beyond limit'));
                exception(int_number(seg), 0, 0);
                exit;
               end;
          end;     
        6,7: // read write, expand down
          begin
            if (seg.cache.segment.d_b)<>0 then
              upper_limit := $ffffffff
            else
              upper_limit := $0000ffff;
            if ( (offset <= seg.cache.segment.limit_scaled) or (offset > upper_limit) or ((upper_limit - offset) < (length - 1)) ) then
              begin
                BX_INFO('read_virtual_checks(): write beyond limit');
                exception(int_number(seg), 0, 0);
                exit;
              end;
          end;
        8, 9, // execute only
        12, 13: // execute only, conforming
          begin
            // can't read or write an execute-only segment
        		BX_INFO(('read_virtual_checks(): execute only'));
            exit;
          end;
        end; //CASE
      end
      else
      begin
        if (offset > (seg.cache.segment.limit_scaled - length + 1)) or (length-1 > seg.cache.segment.limit_scaled) then
          begin
            //BX_ERROR(("read_virtual_checks() SEG EXCEPTION:  %x:%x + %x",
            //  (unsigned) seg->selector.value, (unsigned) offset, (unsigned) length));
            if (seg = @sregs[2]) then exception2([BX_SS_EXCEPTION, 0, 0])
            else exception(BX_GP_EXCEPTION, 0, 0);
        end;
      end;
end;

procedure BX_CPU_C.write_virtual_byte(s:Word; offset:Bit32u; data:PBit8u);
var
  laddr:Bit32u;
  seg:pbx_segment_reg_t;
begin

  seg := @sregs[s];
  write_virtual_checks(seg, offset, 1);

  laddr := seg.cache.segment.base + offset;
  //BX_INSTR_MEM_DATA(laddr, 1, BX_WRITE);

  // all checks OK
  access_linear(laddr, 1, Word(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_WRITE, data);
end;

procedure BX_CPU_C.write_virtual_word(s:Word; offset:Bit32u; data:PBit16u);
var
  laddr:Bit32u;
  seg:pbx_segment_reg_t;
begin
  seg := @sregs[s];
  write_virtual_checks(seg, offset, 2);

  laddr := seg.cache.segment.base + offset;
  //BX_INSTR_MEM_DATA(laddr, 2, BX_WRITE);

  // all checks OK
  access_linear(laddr, 2, Word(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_WRITE, data);
end;

procedure BX_CPU_C.write_virtual_dword(s:Word; offset:Bit32u; data:PBit32u);
var
  laddr:Bit32u;
  seg:pbx_segment_reg_t;
begin
  seg := @sregs[s];
  write_virtual_checks(seg, offset, 4);

  laddr := seg.cache.segment.base + offset;
  //BX_INSTR_MEM_DATA(laddr, 4, BX_WRITE);

  // all checks OK
  access_linear(laddr, 4, Word(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_WRITE, data);
end;

procedure BX_CPU_C.read_virtual_byte(s:Word; offset:Bit32u; data:PBit8u);
var
  laddr:Bit32u;
  seg:pbx_segment_reg_t;
begin

    seg := @sregs[s];
    read_virtual_checks(seg, offset, 1);

    laddr := seg.cache.segment.base + offset;
    //BX_INSTR_MEM_DATA(laddr, 1, BX_WRITE);

    // all checks OK
    access_linear(laddr, 1, Word(CPL=3), BX_READ, data);
end;

procedure BX_CPU_C.read_virtual_word(s:Word; offset:Bit32u; data:PBit16u);
var
  laddr:Bit32u;
  seg:pbx_segment_reg_t;
begin
  if (s<0) or (s>high(sregs)) then
    BX_INFO('read_virtual_word error index');
  seg := @sregs[s];
  read_virtual_checks(seg, offset, 2);

  laddr := seg.cache.segment.base + offset;
  //BX_INSTR_MEM_DATA(laddr, 2, BX_WRITE);

  // all checks OK
  access_linear(laddr, 2, Word(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_READ, data);
end;

procedure BX_CPU_C.read_virtual_dword(s:Word; offset:Bit32u; data:PBit32u);
var
  laddr:Bit32u;
  seg:pbx_segment_reg_t;
begin
  seg := @sregs[s];
  read_virtual_checks(seg, offset, 4);

  laddr := seg.cache.segment.base + offset;
  //BX_INSTR_MEM_DATA(laddr, 4, BX_WRITE);

  // all checks OK
  access_linear(laddr, 4, Word(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_READ, data);
end;

procedure BX_CPU_C.read_RMW_virtual_byte(s:Word; offset:Bit32u; data:PBit8u);
var
  laddr:Bit32u;
  seg:Pbx_segment_reg_t;
begin

  seg := @sregs[s];
  write_virtual_checks(seg, offset, 1);

  laddr := seg.cache.segment.base + offset;
  // BX_INSTR_MEM_DATA(laddr, 1, BX_READ);

  // all checks OK
{$if BX_CPU_LEVEL >= 3}
  if ((cr0.pg))<>0 then
    access_linear(laddr, 1, Bool(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_RW, data)
  else
{$ifend}
    begin
      address_xlation.paddress1 := laddr;
      {BX_INSTR_LIN_READ(laddr, laddr, 1);
      BX_INSTR_LIN_WRITE(laddr, laddr, 1);} // BX_INSTRUMENTATION
      sysmemory.read_physical(laddr, 1, data);
    end;
end;

procedure BX_CPU_C.read_RMW_virtual_word(s:Word; offset:Bit32u; data:PBit16u);
var
  laddr:Bit32u;
  seg:Pbx_segment_reg_t;
begin
  seg := @sregs[s];
  write_virtual_checks(seg, offset, 2);

  laddr := seg.cache.segment.base + offset;
  //BX_INSTR_MEM_DATA(laddr, 2, BX_READ);

  // all checks OK
{$if BX_CPU_LEVEL >= 3}
  if (cr0.pg)<>0 then
    access_linear(laddr, 2, Word(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_RW, data)
  else
{$ifend}
    begin
      address_xlation.paddress1 := laddr;
      //BX_INSTR_LIN_READ(laddr, laddr, 2);
      //BX_INSTR_LIN_WRITE(laddr, laddr, 2);
      sysmemory.read_physical(laddr, 2, data);
    end;
end;

procedure BX_CPU_C.read_RMW_virtual_dword(s:Word; offset:Bit32u; data:PBit32u);
var
  laddr:Bit32u;
  seg:Pbx_segment_reg_t;
begin
  seg := @sregs[s];
  write_virtual_checks(seg, offset, 4);

  laddr := seg.cache.segment.base + offset;
  //BX_INSTR_MEM_DATA(laddr, 4, BX_READ);

  // all checks OK
{$if BX_CPU_LEVEL >= 3}
  if (cr0.pg)<>0 then
    access_linear(laddr, 4, Word(bx_cpu.sregs[BX_SEG_REG_CS].selector.rpl), BX_RW, data)
  else
{$ifend}
    begin
      address_xlation.paddress1 := laddr;
      //BX_INSTR_LIN_READ(laddr, laddr, 2);
      //BX_INSTR_LIN_WRITE(laddr, laddr, 2);
      sysmemory.read_physical(laddr, 4, data);
    end;
end;

procedure BX_CPU_C.write_RMW_virtual_word(val16:Bit16u);
begin
  //BX_INSTR_MEM_DATA(BX_CPU_THIS_PTR address_xlation.paddress1, 2, BX_WRITE);

{$if BX_CPU_LEVEL >= 3}
  if (cr0.pg)<>0 then
    begin
      if address_xlation.pages = 1 then
        sysmemory.write_physical(address_xlation.paddress1, 2, @val16)
    else
      begin
{$if BX_LITTLE_ENDIAN=$01}
        sysmemory.write_physical(address_xlation.paddress1, 1, @val16);
        sysmemory.write_physical(address_xlation.paddress2, 1, (PBit8u(LongInt(@val16) + 1)));
{$else}
        sysmemory.write_physical(address_xlation.paddress1, 1, (PBit8u(LongInt(@val16) + 1)));
        sysmemory.write_physical(address_xlation.paddress2, 1, @val16);
{$ifend}
      end;
    end
  else
{$ifend}
    begin
      sysmemory.write_physical(address_xlation.paddress1, 2, @val16);
    end;
end;

procedure BX_CPU_C.write_RMW_virtual_dword(val32:Bit32u);
begin
  //BX_INSTR_MEM_DATA(BX_CPU_THIS_PTR address_xlation.paddress1, 2, BX_WRITE);

{$if BX_CPU_LEVEL >= 3}
  if (cr0.pg)<>0 then
    begin
      if address_xlation.pages = 1 then
        sysmemory.write_physical(address_xlation.paddress1, 4, @val32)
    else
      begin
{$if BX_LITTLE_ENDIAN=$01}
        sysmemory.write_physical(address_xlation.paddress1, 1, @val32);
        sysmemory.write_physical(address_xlation.paddress2, 1, (PBit8u(LongInt(@val32) + address_xlation.len1)));
{$else}
        sysmemory.write_physical(address_xlation.paddress1, 1, (PBit8u(LongInt(@val32) + (4 - address_xlation.len1))));
        sysmemory.write_physical(address_xlation.paddress2, 1, @val32);
{$ifend}
      end;
    end
  else
{$ifend}
    begin
      sysmemory.write_physical(address_xlation.paddress1, 4, @val32);
    end;
end;

procedure BX_CPU_C.write_virtual_checks(seg:pbx_segment_reg_t; offset:Bit32u; length:Bit32u);
var
  upper_limit:Bit32u;
begin
  if (Bool((Self.cr0.pe<>0) and (Self.eflags.vm=0)))<>0 then
    begin
      if ( seg.cache.valid=0 ) then
        begin
          BX_ERROR(Format('seg = %s', [strseg(@seg)]));
          BX_ERROR(Format('seg->selector.value = %04x',[Word(seg.selector.value)]));
          BX_ERROR('write_virtual_checks: valid bit = 0');
	        BX_ERROR(Format('CS: %04x', [Word(sregs[1].selector.value)]));
      	  BX_ERROR(Format('IP: %04x', [Word(prev_eip)]));
          exception2([BX_GP_EXCEPTION, 0, 0]);
        end;

    if (seg.cache.p = 0) then
      begin // not present
    	  BX_INFO(('write_virtual_checks(): segment not present'));
        exception(int_number(seg), 0, 0);
        exit;
      end;

    case seg^.cache.type_ of
      0, 1,   // read only
      4, 5,   // read only, expand down
      8, 9,   // execute only
      10, 11, // execute/read
      12, 13, // execute only, conforming
      14, 15: // execute/read-only, conforming
        begin
      		BX_INFO('write_virtual_checks(): no write access to seg');
          exception(int_number(seg), 0, 0);
          exit;
        end;  

      2,3: // read/write
        begin
        	if (offset > seg^.cache.segment.limit_scaled - length + 1)
      	    or (length-1 > seg^.cache.segment.limit_scaled) then
          begin
      		  BX_INFO(('write_virtual_checks(): write beyond limit, r/w'));
            exception(int_number(seg), 0, 0);
            exit;
          end;
       end;

      6,7: // read write, expand down
        begin
          if ((seg^.cache.segment.d_b))<>0 then
            upper_limit := $ffffffff
          else
            upper_limit := $0000ffff;
          if ( (offset <= seg^.cache.segment.limit_scaled) or (offset > upper_limit) or
               ((upper_limit - offset) < (length - 1)) ) then
               begin
        		    BX_INFO(('write_virtual_checks(): write beyond limit, r/w ED'));
                exception(int_number(seg), 0, 0);
               end;
       end;
      else  // real mode
        begin
          if (offset > seg^.cache.segment.limit_scaled - length + 1) or (length-1 > seg^.cache.segment.limit_scaled) then
            begin
            //BX_INFO(("write_virtual_checks() SEG EXCEPTION:  %x:%x + %x",
              //(unsigned) seg->selector.value, (unsigned) offset, (unsigned) length));
            if (seg = @sregs[2]) then exception(BX_SS_EXCEPTION, 0, 0)
          else exception(BX_GP_EXCEPTION, 0, 0);
            end;
       end;
    end;
  end;
end;

