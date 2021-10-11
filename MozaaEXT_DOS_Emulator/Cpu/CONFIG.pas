
{$include defines.pas}
unit CONFIG;

interface

uses Windows;

var
  CPU_SPEED:     longint = 700000;   // 500000
  HDD_NUM_CYL:   word = 306;
  HDD_SECTOR_PER_TRACK: word = 17;
  HDD_NUM_HEADS: word = 4;
  BX_C_PRESENT:  longint = $01;
  HDD_FILE_DISK: string = 'C:\mozaa_hdd_file.img';
  HDD_READ_ONLY:integer = 0;
  BX_BOOT_DRIVE:integer = 0; 
const

  VK_RETURN = 13;
  KEYEVENTF_KEYUP = 2;
  CR   = #13;
  NULL = nil;
  BX_BOOT_FLOPPYA = 0;
  BX_BOOT_DISKC = 1;
  BX_INSTRUMENTATION = $00;
  BX_SIM_ID = $00;
  BX_X86_DEBUGGER = $00;
  BX_SUPPORT_TASKING = $01;
  BX_SUPPORT_A20 = $01;
  BX_SUPPORT_FPU = $01;
  BX_CPU_LEVEL = $05;// Set to maximum cpu option
  BX_CPU_LEVEL_HACKED = $05;
  BX_USE_CPU_SMF = $01;
  BX_USE_FD_SMF = $01;
  BX_DYNAMIC_TRANSLATION = $00;
  BX_USE_TLB = $01;
  BX_BIG_ENDIAN = $00;
  BX_LITTLE_ENDIAN = $01;
  BX_SUPPORT_APIC = $00;
  REGISTER_IADDR = $00;
  BX_BOOTSTRAP_PROCESSOR = $01;
  BX_DBG_ASYNC_INTR = $01;
  BX_USE_DMA_SMF = $01;  // DMA
  BX_USE_PIC_SMF = $01;  // PIC
  BX_USE_KEY_SMF = $01;
  BX_DMA_FLOPPY_IO = $01;
  BX_SPLIT_HD_SUPPORT = 00;
  BX_CDROM_PRESENT = 0;
  LOWLEVEL_CDROM = 0;
  BX_USE_HD_SMF = $01;
  BX_PIC_DEBUG = $00;
  BX_PIT_DEBUG = $00;
  BX_CMOS_DEBUG = $00;
  BX_TIMER_DEBUG = $00;
  BX_USE_IDLE_HACK = $00;
  BX_PORT_E9_HACK = $01;
  BX_USE_SPECIFIED_TIME0 = $00;
  dbgunsupported_io = $00;

  // APIC -  Da implementare
  APIC_BASE_ADDR = $fee00000;  // default APIC address
  // FINE - APIC -  Da implementare

  BX_INHIBIT_INTERRUPTS = $01;
  BX_INHIBIT_DEBUG = $02;
  BX_PROVIDE_CPU_MEMORY = $01;
  BX_DEBUGGER      = $00;
  MAGIC_BREAKPOINT = $01;
  BX_SHADOW_RAM    = $00;

  BX_TLB_SIZE = 1024;

  BX_USE_MEM_SMF     = $01;
  BX_USE_UM_SMF      = $01;
  BX_USE_CMOS_SMF    = $01;
  BX_USE_VGA_SMF     = $01;
  BX_SMP_PROCESSORS  = $01;
  BX_PCI_SUPPORT     = $00;
  BX_IODEBUG_SUPPORT = $00;
  BX_USE_PCI_SMF     = $01;
  BX_USE_PIT_SMF     = $01;

  BX_SUPPORT_PAGING = $01;
  BX_SUPPORT_VBE    = $01;

  BX_PF_EXCEPTION    = $100;
  INTEL_DIV_FLAG_BUG = $01;
  VGA_TRACE_FEATURE  = $01;

  SHOW_EXIT_STATUS      = $01;
  BX_SUPPORT_V8086_MODE = $01;

  SUPPORT440FX     = $01;
  DUMP_FULL_I440FX = $00;

  BX_NUM_CMOS_REGS = 64;

  //Options

  Options_cmos_time      = $01;
  Options_cmos_use_image = $00;

  BX_MOUSE_ENABLED = $00;
  SEEK_SET = $00;
  CONNER_CFA540A = $00;

  BX_FLOPPY_NONE = 10; // floppy not present
  BX_FLOPPY_LAST = 14; // last one

  BX_EJECTED  = 10;
  BX_INSERTED = 11;
  BX_GET_FLOPPYB_TYPE = BX_FLOPPY_NONE;
  BX_FLOPPY_INSERTED = BX_INSERTED;

  BX_RESET_SOFTWARE = 10;
  BX_RESET_HARDWARE = 11;

  BX_DEBUG_FLOPPY  = $00;
  BX_GUI_ENABLED   = $01;
  BX_INFO_ENABLED  = $00;
  BX_DEBUG_ENABLED = $00;
  BX_ERROR_ENABLED = $00;
  BX_LOG_ENABLED   = $00;

  BX_DEBUG_TO_FILE = $00;
  BX_USE_NEW_PIT   = $01;

  BX_READ_AFTER = 83890000;

  BX_MAX_ERRORS = 2000000;
  BX_MAX_IPS    = 1900000;
  BX_MAX_IPS_REFRESH = 3000;

  KEYBOARD_DELAY = 20000;
  KEYBOARD_PASTE_DELAY = 100000;

  BX_USE_REALTIME_PIT = $00;

  BX_BOOT_A     = $01;
  BX_NEW_HDD_SUPPORT = 1;
  BX_D_PRESENT  = 0;
  BX_DEBUG_HDD  = 0;

type

  precstate = ^recstate;

  recstate = record
    a0: longword;
    a1: longword;
    a2: longword;
    a3: longword;
    a4: longword;
    a5: longword;
    a6: longword;
    a7: longword;
    a8: longword;
    a9: longword;
  end;

  PBit8u    = ^byte;
  Bit8u     = byte;
  PBit8s    = ^shortint;
  Bit8s     = shortint;
  PBit16u   = ^word;
  Bit16u    = word;
  PBit16s   = ^smallint;
  Bit16s    = smallint;
  PBit32u   = ^longword;
  Bit32u    = longword;
  PBit32s   = ^integer;
  Bit32s    = integer;
  PBit64u   = ^Bit64u;
  Bit64u    = int64;
  PBit64s   = ^Bit64s;
  Bit64s    = int64;
  punsigned = ^unsigned;
  unsigned  = word;
  Bool      = word;
  Size_T    = longword;
  time_t    = longint;
  off_t     = Bit32u;
  ssize_t   = longword;
  puint8    = ^uint8;
  uint8     = bit8u;

  puint16 = ^uint16;
  uint16  = bit16u;

  puint32 = ^uint32;
  uint32  = bit32u;
  parray_memory = ^array_memory;
  array_memory = array[0..256 * 1024] of Bit8u;

  Char256 = array[0..256] of char;

  HDC     = longword;
  HBITMAP = longword;

  array_buffer_disk   = array[0..2048] of Bit8u;
  array_buffer_floppy = array[0..512 + 2] of Bit8u;


const
  bx_parity_lookup: array[0..255] of Bool = (
    1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
    0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
    0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
    1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
    0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
    1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
    1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
    0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
    0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
    1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
    1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
    0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
    1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
    0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
    0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
    1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1);

var
  ThreadGui, ThreadGuiID: THandle;
  LastMessage: array[0..128] of char;
  FilesLog:    integer;
  drawCS, KeyCS, MouseCS: RTL_CRITICAL_SECTION;
  StartEvent:  integer;
  OutLogTxt, LogFile: TextFile;
  EmsDir, WorkDir, KeybDir: string;
  WriteBXInfo: boolean = False;
  ReLoop:      boolean = False;
  ShowAgain:   boolean = False;
  MEMORYMB:    word = 7;
  DelphiWindow: THandle;

//GlobalDataFpuAddress:LongWord;

procedure OutError(const idxError: integer);

implementation

uses IniFiles, SysUtils;

procedure OutError(const idxError: integer);
begin
  Halt;
end;

function CheckFile(s: string): string;
begin
  Result := s;
  if not FileExists(s) then
    begin
    raise Exception.Create('Can''t find file: ' + s);
    end;
end;




end.
