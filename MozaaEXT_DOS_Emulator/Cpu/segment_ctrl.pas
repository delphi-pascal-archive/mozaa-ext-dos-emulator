{ ****************************************************************************** }
{ Mozaa 0.95 - Virtual PC emulator - developed by Massimiliano Boidi 2003 - 2004 }
{ ****************************************************************************** }

{ For any question write to info@mozaa.org }

(* **** *)


procedure BX_CPU_C.LES_GvMp(I:PBxInstruction_tag);
var
  es:Bit16u;
  reg_32:Bit32u;
  reg_16, es_16:Bit16u;
begin
  if (i^.mod_ = $c0) then begin
    // (BW) NT seems to use this when booting.
    BX_INFO(('invalid use of LES, must use memory reference!'));
    UndefinedOpcode(i);
    end;

{$if BX_CPU_LEVEL > 2}
  if Boolean(i^.os_32) then begin

    read_virtual_dword(i^.seg, i^.rm_addr, @reg_32);
    read_virtual_word(i^.seg, i^.rm_addr + 4, @es);

    load_seg_reg(@Self.sregs[BX_SEG_REG_ES], es);

    BX_WRITE_32BIT_REG(i^.nnn, reg_32);
    end
  else
{$ifend} (* BX_CPU_LEVEL > 2 *)
    begin (* 16 bit mod_e *)

    read_virtual_word(i^.seg, i^.rm_addr, @reg_16);
    read_virtual_word(i^.seg, i^.rm_addr + 2, @es_16);

    load_seg_reg(@Self.sregs[BX_SEG_REG_ES], es_16);

    BX_WRITE_16BIT_REG(i^.nnn, reg_16);
    end;
end;

procedure BX_CPU_C.LDS_GvMp(I:PBxInstruction_tag);
var
  ds:Bit16u;
  reg_32:Bit32u;
  reg_16, ds_16:Bit16u;
begin
  if (i^.mod_ = $c0) then begin
    BX_PANIC(('invalid use of LDS, must use memory reference!'));
    UndefinedOpcode(i);
    end;

{$if BX_CPU_LEVEL > 2}
  if Boolean(i^.os_32) then begin

    read_virtual_dword(i^.seg, i^.rm_addr, @reg_32);
    read_virtual_word(i^.seg, i^.rm_addr + 4, @ds);

    load_seg_reg(@Self.sregs[BX_SEG_REG_DS], ds);

    BX_WRITE_32BIT_REG(i^.nnn, reg_32);
    end
  else
{$ifend} (* BX_CPU_LEVEL > 2 *)
    begin (* 16 bit mod_e *)

    read_virtual_word(i^.seg, i^.rm_addr, @reg_16);
    read_virtual_word(i^.seg, i^.rm_addr + 2, @ds_16);

    load_seg_reg(@Self.sregs[BX_SEG_REG_DS], ds_16);

    BX_WRITE_16BIT_REG(i^.nnn, reg_16);
    end;
end;

procedure BX_CPU_C.LFS_GvMp(I:PBxInstruction_tag);
var
  reg_32:Bit32u;
  fs,fs_16:Bit16u;
  reg_16:Bit16u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('lfs_gvmp: not supported on 8086'));
{$else} (* 386+ *)

  if (i^.mod_ = $c0) then begin
    BX_PANIC(('invalid use of LFS, must use memory reference!'));
    UndefinedOpcode(i);
    end;

  if Boolean(i^.os_32) then begin

    read_virtual_dword(i^.seg, i^.rm_addr, @reg_32);
    read_virtual_word(i^.seg, i^.rm_addr + 4, @fs);

    load_seg_reg(@Self.sregs[BX_SEG_REG_FS], fs);

    BX_WRITE_32BIT_REG(i^.nnn, reg_32);
    end
  else begin (* 16 bit operand size *)

    read_virtual_word(i^.seg, i^.rm_addr, @reg_16);
    read_virtual_word(i^.seg, i^.rm_addr + 2, @fs_16);

    load_seg_reg(@Self.sregs[BX_SEG_REG_FS], fs_16);

    BX_WRITE_16BIT_REG(i^.nnn, reg_16);
    end;
{$ifend}
end;

procedure BX_CPU_C.LGS_GvMp(I:PBxInstruction_tag);
var
  reg_32:Bit32u;
  gs,gs_16:Bit16u;
  reg_16:Bit16u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('lgs_gvmp: not supported on 8086'));
{$else} (* 386+ *)

  if (i^.mod_ = $c0) then begin
    BX_PANIC(('invalid use of LGS, must use memory reference!'));
    UndefinedOpcode(i);
    end;

  if Boolean(i^.os_32) then begin

    read_virtual_dword(i^.seg, i^.rm_addr, @reg_32);
    read_virtual_word(i^.seg, i^.rm_addr + 4, @gs);

    load_seg_reg(@Self.sregs[BX_SEG_REG_GS], gs);

    BX_WRITE_32BIT_REG(i^.nnn, reg_32);
    end
  else begin (* 16 bit operand size *)

    read_virtual_word(i^.seg, i^.rm_addr, @reg_16);
    read_virtual_word(i^.seg, i^.rm_addr + 2, @gs_16);

    load_seg_reg(@Self.sregs[BX_SEG_REG_GS], gs_16);

    BX_WRITE_16BIT_REG(i^.nnn, reg_16);
    end;
{$ifend}
end;

procedure BX_CPU_C.LSS_GvMp(I:PBxInstruction_tag);
var
  reg_32:Bit32u;
  reg_16:Bit16u;
  ss_raw,ss_raw_16:Bit16u;
begin
{$if BX_CPU_LEVEL < 3}
  BX_PANIC(('lss_gvmp: not supported on 8086'));
{$else} (* 386+ *)

  if (i^.mod_ = $c0) then begin
    BX_PANIC(('invalid use of LSS, must use memory reference!'));
    UndefinedOpcode(i);
    end;

  if Boolean(i^.os_32) then begin

    read_virtual_dword(i^.seg, i^.rm_addr, @reg_32);
    read_virtual_word(i^.seg, i^.rm_addr + 4, @ss_raw);

    load_seg_reg(@Self.sregs[BX_SEG_REG_SS], ss_raw);

    BX_WRITE_32BIT_REG(i^.nnn, reg_32);
    end
  else begin (* 16 bit operand size *)

    read_virtual_word(i^.seg, i^.rm_addr, @reg_16);
    read_virtual_word(i^.seg, i^.rm_addr + 2, @ss_raw_16);

    load_seg_reg(@Self.sregs[BX_SEG_REG_SS], ss_raw_16);

    BX_WRITE_16BIT_REG(i^.nnn, reg_16);
    end;
{$ifend}
end;
