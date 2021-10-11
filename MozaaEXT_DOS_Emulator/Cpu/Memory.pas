
unit Memory;

interface

uses config;

type
  PBX_MEM_C = ^BX_MEM_C;

  BX_MEM_C = class
  public
    vector: array of bit8u;
    len:    size_t;
    megabytes: size_t;  // (len in Megabytes)

    constructor Create(memsize: size_t);
    destructor Free;
    //procedure  init_memory(memsize:integer);
    procedure read_physical(addr: Bit32u; len: word; const data_2: Pointer);
    procedure write_physical(addr: Bit32u; len: word; Data: Pointer);
    procedure load_ROM(path: string; romaddress: Bit32u);
    function get_memory_in_k: Bit32u;
  end;

var
  sysmemory: BX_MEM_C;

implementation

uses cpu, vga;

constructor BX_MEM_C.Create(memsize: size_t);
var
  I: longword;
begin
  SetLength(vector, memsize);
  len := memsize;
  megabytes := Trunc(len / (1024 * 1024));
  I   := $c0000;
  while I <> $c0000 + $40000 do
    begin
    Self.vector[I] := $ff;
    Inc(I);
    end;
end;

destructor BX_MEM_C.Free;
begin
  SetLength(vector, 0);
end;

procedure BX_MEM_C.load_ROM(path: string; romaddress: Bit32u);
var
  fp: file of bit8u;
  NumReaded: integer;
  I:  Bit32u;
begin
  I := romaddress;
  AssignFile(fp, path);
  Reset(fp);
  while not EOF(fp) do
    begin
    Read(fp, vector[I]);
    Inc(I);
    end;
  CloseFile(fp);
end;

function BX_MEM_C.get_memory_in_k: Bit32u;
begin
  Result := megabytes * 1024;
end;

{$if BX_PROVIDE_CPU_MEMORY=1}
procedure BX_MEM_C.read_physical(addr: Bit32u; len: word; const data_2: Pointer);
var
  data_2_ptr: PBit8u;
  a20addr: Bit32u;
  data32: Bit32u;
  data16: Bit16u;
  data8: Bit8u;
  i: unsigned;
label
  read_one, inc_one;
begin
  a20addr := addr and bx_pc_system.a20_mask;

  if ((a20addr + len) <= Self.len) then
    begin
    // all of data_2 is within limits of physical memory
    if ((a20addr and $fff80000) <> $00080000) then
      begin
      if (len = 4) then
        begin
        if ((a20addr and $00000003) = 0) then
          begin
          // read 4-byte data_2 from aligned memory location

          data32 := PBit32u(@vector[a20addr])^;
{$if BX_BIG_ENDIAN=1}
          data32 := (data32 shl 24) or (data32 shr 24) or
            ((data32 and $00ff0000) shr 8) or ((data32 and $0000ff00) shl 8);
{$ifend}
          PBit32u(data_2)^ := data32;
          exit;
          end
        else
          begin

          data32 := PBit8u(@vector[(addr + 3) and bx_pc_system.a20_mask])^;
          data32 := data32 shl 8;
          data32 := data32 or PBit8u(@vector[(addr + 2) and bx_pc_system.a20_mask])^;
          data32 := data32 shl 8;
          data32 := data32 or PBit8u(@vector[(addr + 1) and bx_pc_system.a20_mask])^;
          data32 := data32 shl 8;
          data32 := data32 or PBit8u(@vector[addr and bx_pc_system.a20_mask])^;

          PBit32u(data_2)^ := data32;
          exit;
          end;
        end;
      if (len = 2) then
        begin
        if ((a20addr and $00000001) = 0) then
          begin
          // read 2-byte data_2 from aligned memory location

          data16 := PBit16u(@vector[a20addr])^;
{$if BX_BIG_ENDIAN=1}
          data16 := (data16 shr 8) or (data16 shl 8);
{$ifend}

          PBit16u(data_2)^ := data16;
          exit;
          end
        else
          begin

          data16 := PBit8u(@vector[(addr + 1) and bx_pc_system.a20_mask])^;
          data16 := data16 shl 8;
          data16 := data16 or PBit8u(@vector[addr and bx_pc_system.a20_mask])^;

          PBit16u(data_2)^ := data16;
          exit;
          end;
        end;
      if (len = 1) then
        begin

        data8 := PBit8u(@vector[a20addr])^;
        PBit8u(data_2)^ := data8;
        exit;
        end;
      // len = 3 case can just fall thru to special cases handling
      end;


{$if BX_LITTLE_ENDIAN=1}
    data_2_ptr := PBit8u(data_2);
{$else} // BX_BIG_ENDIAN
    data_2_ptr := (Bit8u *) data_2 + (len - 1);
{$ifend}



    read_one:
      if ((a20addr and $fff80000) <> $00080000) then
        begin
        // addr *not* in range 00080000 .. 000FFFFF
        data_2_ptr^ := vector[a20addr];
      inc_one:
        if (len = 1) then
          begin
          exit;
          end;
        Dec(len);
        Inc(addr);
        a20addr := addr and bx_pc_system.a20_mask;
{$if BX_LITTLE_ENDIAN=1}
        Inc(data_2_ptr);
{$else} // BX_BIG_ENDIAN
      dec(data_2_ptr);
{$ifend}
        goto read_one;
        end;

    // addr in range 00080000 .. 000FFFFF
{$if BX_PCI_SUPPORT = 0}
    if ((a20addr <= $0009ffff) or (a20addr >= $000c0000)) then
      begin
      // regular memory 80000 .. 9FFFF, C0000 .. F0000
      data_2_ptr^ := vector[a20addr];
      goto inc_one;
      end;
    // VGA memory A0000 .. BFFFF
    data_2_ptr^ := bx_vga.mem_read(a20addr);
    //BX_DBG_UCMEM_REPORT(a20addr, 1, BX_READ, *data_2_ptr); // obsolete
    goto inc_one;
{$else}   // #if BX_PCI_SUPPORT = 0
    if (a20addr <= $0009ffff) then begin
      *data_2_ptr := vector[a20addr];
      goto inc_one;
      end;
    if (a20addr <= $000BFFFF) then begin
      // VGA memory A0000 .. BFFFF
      *data_2_ptr := BX_VGA_MEM_READ(a20addr);
      BX_DBG_UCMEM_REPORT(a20addr, 1, BX_READ, *data_2_ptr);
      goto inc_one;
      end;

    // a20addr in C0000 .. FFFFF
    if (!bx_options.Oi440FXSupport^.get ()) then begin
      *data_2_ptr := vector[a20addr];
      goto inc_one;
      end
  else begin
      switch (bx_devices.pci^.rd_memType(a20addr  and $FC000)) then begin
        case $0:   // Read from ShadowRAM
          *data_2_ptr := vector[a20addr];
          BX_INFO(('Reading from ShadowRAM %08x, data_2 %02x ', (unsigned) a20addr, *data_2_ptr));
          goto inc_one;

        case $1:   // Read from ROM
          *data_2_ptr := bx_pci.s.i440fx.shadow[(a20addr - $c0000)];
          //BX_INFO(('Reading from ROM %08x, data_2 %02x  ', (unsigned) a20addr, *data_2_ptr));
          goto inc_one;
        default:
          BX_PANIC(('.read_physical: default case'));
        end;
      end;
    goto inc_one;
{$ifend}// #if BX_PCI_SUPPORT = 0
    end
  else
    begin
    // some or all of data_2 is outside limits of physical memory

{$if BX_LITTLE_ENDIAN=1}
    data_2_ptr := PBit8u(data_2);
{$else} // BX_BIG_ENDIAN
    data_2_ptr := PBit8u(data_2 + (len - 1));
{$ifend}

    for i := 0 to len do
      begin
{$if BX_PCI_SUPPORT = 0}
      if (a20addr < Self.len) then
        begin
        data_2_ptr^ := vector[a20addr];
        end
      else
        begin
        data_2_ptr^ := $ff;
        end;
{$else}   // BX_PCI_SUPPORT = 0
      if (a20addr < Self.len) then begin
        if ((a20addr >= $000C0000) and (a20addr <= $000FFFFF)) then begin
          if (not bx_options.Oi440FXSupport^.get ())
            *data_2_ptr := vector[a20addr];
          else begin
            switch (bx_devices.pci^.rd_memType(a20addr  and $FC000)) then begin
              case $0:   // Read from ROM
                *data_2_ptr := vector[a20addr];
                //BX_INFO(('Reading from ROM %08x, data_2 %02x ', (unsigned) a20addr, *data_2_ptr));
                break;

              case $1:   // Read from Shadow RAM
                *data_2_ptr := bx_pci.s.i440fx.shadow[(a20addr - $c0000)];
                BX_INFO(('Reading from ShadowRAM %08x, data_2 %02x  ', (unsigned) a20addr, *data_2_ptr));
                break;
              default:
                BX_PANIC(('read_physical: default case'));
              end; // Switch
            end;
          end;
        else begin
          *data_2_ptr := vector[a20addr];
          BX_INFO(('Reading from Norm %08x, data_2 %02x  ', (unsigned) a20addr, *data_2_ptr));
          end;
        end;
      else
        *data_2_ptr := $ff;
{$ifend}// BX_PCI_SUPPORT = 0
      Inc(addr);
      a20addr := addr and bx_pc_system.a20_mask;
{$if BX_LITTLE_ENDIAN=1}
      Inc(data_2_ptr);
{$else} // BX_BIG_ENDIAN
      dec(data_2_ptr);
{$ifend}
      end;
    exit;
    end;
end;

{$ifend}// #if BX_PROVIDE_CPU_MEMORY

procedure BX_MEM_C.write_physical(addr: Bit32u; len: word; Data: Pointer);
var
  data_ptr: PBit8u;
  a20addr: Bit32u;
  data32: Bit32u;
  data16: Bit16u;
  data8: Bit8u;
  i: unsigned;
label
  write_one, inc_one;
begin

  A20ADDR := addr and bx_pc_system.a20_mask;


  if ((A20ADDR + len) <= Self.len) then
    begin
    // all of data is within limits of physical memory
    if ((A20ADDR and $fff80000) <> $00080000) then
      begin
      if (len = 4) then
        begin
        if ((A20ADDR and $00000003) = 0) then
          begin
          // write 4byte data to aligned memory location

          data32 := PBit32u(Data)^;
{$if BX_BIG_ENDIAN=1}
          data32 := (data32 shl 24) or (data32 shr 24) or
            ((data32 and $00ff0000) shr 8) or ((data32 and $0000ff00) shl 8);
{$ifend}
          PBit32u(@vector[A20ADDR])^ := data32;
          //BX_DBG_DIRTY_PAGE(_A20ADDR_ shr 12);
          //BX_DYN_DIRTY_PAGE(A20ADDR shr 12);
          exit;
          end
        else
          begin

          data32 := PBit32u(Data)^;
          PBit8u(@vector[A20ADDR])^ := data32;
          data32 := data32 shr 8;
          PBit8u(@vector[(addr + 1) and bx_pc_system.a20_mask])^ := data32;
          data32 := data32 shr 8;
          PBit8u(@vector[(addr + 2) and bx_pc_system.a20_mask])^ := data32;
          data32 := data32 shr 8;
          PBit8u(@vector[(addr + 3) and bx_pc_system.a20_mask])^ := data32;
          // worst case, last byte is in different page; possible extra dirty page
          exit;
          end;
        end;
      if (len = 2) then
        begin
        if ((A20ADDR and $00000001) = 0) then
          begin
          // write 2-byte data to aligned memory location

          data16 := PBit16u(Data)^;
{$if BX_BIG_ENDIAN=1}
          data16 := (data16 shr 8) or (data16 shl 8);
{$ifend}
          PBit16u(@vector[A20ADDR])^ := data16;
          exit;
          end
        else
          begin

          data16 := PBit16u(Data)^;
          PBit8u(@vector[A20ADDR])^ := Bit8u(data16);
          PBit8u(@vector[(A20ADDR + 1) and bx_pc_system.a20_mask])^ := (data16 shr 8);
          exit;
          end;
        end;
      if (len = 1) then
        begin

        data8 := PBit8u(Data)^;
        PBit8u(@vector[A20ADDR])^ := data8;
        exit;
        end;
      // len = 3 case can just fall thru to special cases handling
      end;

{$if BX_LITTLE_ENDIAN=1}
    data_ptr := PBit8u(Data);
{$else} // BX_BIG_ENDIAN
  data_ptr := PBit8u(data) + (len - 1);
{$ifend}

    write_one:
      if ((A20ADDR and $fff80000) <> $00080000) then
        begin
        // addr *not* in range 00080000 .. 000FFFFF
        vector[A20ADDR] := data_ptr^;
      inc_one:
        if (len = 1) then
          begin
          exit;
          end;
        Dec(len);
        Inc(addr);
        A20ADDR := addr and bx_pc_system.a20_mask;
{$if BX_LITTLE_ENDIAN=1}
        Inc(data_ptr);
{$else} // BX_BIG_ENDIAN
      dec(data_ptr);
{$ifend}
        goto write_one;
        end;

    // addr in range 00080000 .. 000FFFFF

    if (A20ADDR <= $0009ffff) then
      begin
      // regular memory 80000 .. 9FFFF
      vector[A20ADDR] := data_ptr^;
      goto inc_one;
      end;
    if (A20ADDR <= $000bffff) then
      begin
      // VGA memory A0000 .. BFFFF
      bx_vga.mem_write(A20ADDR, data_ptr^);
      goto inc_one;
      end;
    // adapter ROM     C0000 .. DFFFF
    // ROM BIOS memory E0000 .. FFFFF
    // (ignore write)
    //BX_INFO(('ROM lock %08x: len:=%u',
    //  (unsigned) _A20ADDR_, (unsigned) len));
{$if BX_PCI_SUPPORT = 0}
{$if BX_SHADOW_RAM=1}
    // Write it since its in shadow RAM
    vector[A20ADDR] := data_ptr^;
{$else}
    // ignore write to ROM
{$ifend}
{$else}
    // Write Based on 440fx Programming
    if (bx_options.Oi440FXSupport^.get () @@
        ((_A20ADDR_ >= $C0000) @ and (_A20ADDR_ <= $FFFFF))) then begin
      switch (bx_devices.pci^.wr_memType(_A20ADDR_  and $FC000)) then begin
        case $0:   // Writes to ShadowRAM
//        BX_INFO(('Writing to ShadowRAM %08x, len %u ! ', (unsigned) _A20ADDR_, (unsigned) len));
          vector[_A20ADDR_] := *data_ptr;
          BX_DBG_DIRTY_PAGE(_A20ADDR_ shr 12);
          BX_DYN_DIRTY_PAGE(_A20ADDR_ shr 12);
          goto inc_one;

        case $1:   // Writes to ROM, Inhibit
//        bx_pci.s.i440fx.shadow[(_A20ADDR_ - $c0000)] := *data_ptr;
//        BX_INFO(('Writing to ROM %08x, Data %02x ! ', (unsigned) _A20ADDR_, *data_ptr));
          goto inc_one;
        default:
          BX_PANIC(('write_physical: default case'));
          goto inc_one;
        end;
      end;
{$ifend}
    goto inc_one;
    end

  else
    begin
    // some or all of data is outside limits of physical memory

{$if BX_LITTLE_ENDIAN=1}
    data_ptr := PBit8u(Data);
{$else} // BX_BIG_ENDIAN
  data_ptr := (Bit8u *) data + (len - 1);
{$ifend}

    for i := 0 to len do
      begin
      if (A20ADDR < Self.len) then
        begin
        vector[A20ADDR] := data_ptr^;
        end;
      // otherwise ignore byte, since it overruns memory
      Inc(addr);
      A20ADDR := addr and bx_pc_system.a20_mask;
{$if BX_LITTLE_ENDIAN=1}
      Inc(data_ptr);
{$else} // BX_BIG_ENDIAN
      dec(data_ptr);
{$ifend}
      end;
    exit;
    end;
end;

end.
