program test;

uses
  Windows,
  Forms,
  CONFIG in 'Cpu\CONFIG.pas',
  Service in 'Service\Service.pas',
  jumpfar in 'Cpu\jumpfar.pas',
  cpu in 'Cpu\cpu.pas',
  SysUtils,
  Iodev in 'IODEV\Iodev.pas',
  dma in 'IODEV\dma.pas',
  PIC in 'IODEV\PIC.pas',
  Unmapped in 'IODEV\Unmapped.pas',
  cmos in 'IODEV\cmos.pas',
  PIT in 'IODEV\pit.pas',
  Memory in 'Cpu\Memory.pas',
  keyboard in 'IODEV\keyboard.pas',
  KeyMap in 'IODEV\KeyMap.pas',
  Scd in 'IODEV\Scd.pas',
  vga in 'IODEV\vga.pas',
  InitSystemNames in 'Cpu\InitSystemNames.pas',
  Gui32 in 'Gui32\Gui32.pas',
  VgaBitmap in 'Gui32\VgaBitmap.pas',
  floppy in 'IODEV\floppy.pas',
  pit_wrap in 'IODEV\pit_wrap.pas',
  pit82c54 in 'IODEV\pit82c54.pas',
  serv_param in 'Service\serv_param.pas',
  m2fMain in 'win32\m2fMain.pas' {fMain},
  thPerif in 'win32\thPerif.pas',
  HDD in 'IODEV\HDD.pas';

begin
  Application.Initialize;
  Application.Title := 'MozaaExt /Dark''s Mod/';
  Application.CreateForm(TfMain, fMain);
  fMain.Show;
  KT := TMessageThread.Create(False);
  KT.WaitFor;
end.
