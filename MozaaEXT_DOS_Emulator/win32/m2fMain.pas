unit m2fMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ComCtrls, ToolWin, ActnMan, ActnCtrls, ActnMenus,
  ActnList, ExtCtrls, ImgList, Config, StdCtrls, Buttons, thPerif, floppy, inifiles;

type
  TfMain = class (TForm)
    MainMenu1: TMainMenu;
    StartEmulation1: TMenuItem;
    StopEmulation1: TMenuItem;
    Em1: TMenuItem;
    N1:  TMenuItem;
    N2:  TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N0C1: TMenuItem;
    N6: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure StartEmulation1Click(Sender: TObject);
    procedure StopEmulation1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure ListFilesDblClick(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure N4Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
  private
    WorkDir, EmulDir: string;
    IsStarted, LoadedConfig, IsMouseEnabled: boolean;
    StopEvent:    THandle;
    OriginalForm: TRect;
    THddLed:      TThPerif;
    procedure InitVars;
    procedure StopEmulation;
  public
    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMKeyDown(var Msg: TWMKeyDown); message WM_KEYDOWN;
    procedure WMKeyUp(var Msg: TWMKeyUp); message WM_KEYUP;
    procedure WMChar(var Msg: TWMChar); message WM_CHAR;

  end;

  TMessageThread = class (TThread)
    procedure Execute; override;
  end;

const
  MAX_TIME_WAIT = 5000;
  MB_SIZE = 1024 * 1024;

var
  fMain: TfMain;
  KT:    TMessageThread;

implementation

uses Gui32, cpu, iodev, InitSystemNames, Service, Memory;

{$R *.dfm}

{ TfMain }

procedure TfMain.InitVars;
begin
  IsStarted := False;
end;

procedure TfMain.FormCreate(Sender: TObject);
var
  ini: TIniFile;
begin
  ini      := Tinifile.Create(extractfilepath(application.ExeName) + 'emu.ini');
  BX_C_PRESENT := ini.ReadInteger('Hardware', 'BX_C_PRESENT', BX_C_PRESENT);
  HDD_NUM_CYL := ini.ReadInteger('Hardware', 'HDD_NUM_CYL', HDD_NUM_CYL);
  HDD_SECTOR_PER_TRACK := ini.ReadInteger('Hardware', 'HDD_SECTOR_PER_TRACK',
    HDD_SECTOR_PER_TRACK);
  HDD_NUM_HEADS := ini.ReadInteger('Hardware', 'HDD_NUM_HEADS', HDD_NUM_HEADS);
  HDD_FILE_DISK := ini.ReadString('Hardware', 'HDD_FILE_DISK', HDD_FILE_DISK);
  MEMORYMB := ini.ReadInteger('Hardware', 'MEMORYMB', MEMORYMB);
  CPU_SPEED := ini.ReadInteger('Hardware', 'CPU_SPEED', CPU_SPEED);
 HDD_READ_ONLY:=ini.ReadInteger('Hardware', 'HDD_READ_ONLY', HDD_READ_ONLY);
BX_BOOT_DRIVE:= ini.ReadInteger('Hardware', 'BX_BOOT_DRIVE', BX_BOOT_DRIVE); 
  ini.Free;
  IsMouseEnabled := False;
  InitVars;
end;

procedure StartEmulation;
var
  nf: string;
begin

  try
    try
      bx_cpu.cpu_loop;
    except
      on e: Exception do
        begin
        fMain.BoundsRect := fMain.OriginalForm;
        BX_PANIC(e.Message);
        end;
      end;
  finally
    DeleteCriticalSection(MouseCS);
    DeleteCriticalSection(drawCs);
    DeleteCriticalSection(KeyCs);
    TerminateEmul;
    Gui32Stop;
    bx_cpu.Free;
    bx_devices.Free;
    bx_pc_system.Free;
    sysmemory.Free;
    SetEvent(fMain.StopEvent);
    end;
end;


procedure TfMain.StartEmulation1Click(Sender: TObject);
var
  OldSize: TRect;
begin
  if isstarted then
    begin
    exit;
    end;
 if fileexists(HDD_FILE_DISK) then begin
copyfile(pchar(HDD_FILE_DISK),pchar(changefileext(HDD_FILE_DISK,'.undo')),false);
 end;
  OldSize := BoundsRect;
  MainWnd := Handle;
  stoprun := False;
  LastMessage := '';
  ips_count := 0;
  m_ips := 0;
  try
    Gui32Init(MainWnd, 0);
    bx_cpu     := BX_CPU_C.Create;
    bx_devices := bx_devices_c.Create;
    bx_devices.init(nil);
    bx_cpu.init(nil);
    InitSystem;
    InitNames;
    InitFont;
    fMain.IsStarted := True;
    OriginalForm    := BoundsRect;
    bx_cpu.reset(0);
    InitializeCriticalSection(drawCS);
    InitializeCriticalSection(KeyCS);
    InitializeCriticalSection(MouseCS);
    StartEvent := CreateEvent(nil, False, False, nil);
    StartEmulation;
  finally
    BoundsRect := OldSize;
    end;
end;

procedure TfMain.WMPaint(var Msg: TWMPaint);
var
  ps: PAINTSTRUCT;
  VideoDC, MemDC: HDC;
  OldObject: THandle;
begin
  if IsStarted then
    begin
    EnterCriticalSection(DrawCS);
    VideoDC := BeginPaint(Self.Handle, ps);
    MemDC   := CreateCompatibleDC(VideoDC);

    OldObject := SelectObject(MemDC, MemoryBitmap);

    StretchBlt(VideoDC, ps.rcPaint.left, ps.rcPaint.top, ps.rcPaint.right -
      ps.rcPaint.left + 1,
      ps.rcPaint.bottom - ps.rcPaint.top + 1, MemDC,
      ps.rcPaint.left div stretch_factor, ps.rcPaint.top div stretch_factor,
      (ps.rcPaint.right - ps.rcPaint.left + 1) div stretch_factor,
      (ps.rcPaint.bottom - ps.rcPaint.top + 1) div stretch_factor, SRCCOPY);

    SelectObject(MemDC, OldObject);

    DeleteDC(MemDC);
    EndPaint(Self.Handle, ps);
    leavecriticalsection(DrawCs);
    Msg.Result := 0;
    end
  else
    begin
    inherited;
    Msg.Result := 1;
    end;
end;

{ TRunner }

procedure TfMain.StopEmulation;
var
  _res: DWORD;
begin

  stoprun := True;
  _res    := WaitForSingleObject(StopEvent, MAX_TIME_WAIT);
  Invalidate;
  BoundsRect := OriginalForm;
  IsStarted  := False;
end;

procedure TfMain.StopEmulation1Click(Sender: TObject);
begin
  if isstarted then
    begin
    StopEmulation;
    end;
end;

procedure TfMain.WMKeyDown(var Msg: TWMKeyDown);
begin
  if IsStarted then
    begin
    EnterCriticalSection(KeyCS);
    enq_key_event(HiWord(Msg.KeyData) and $01FF, BX_KEY_PRESSED);
    leavecriticalsection(KeyCs);
    Msg.Result := 0;
    end
  else
    begin
    inherited;
    end;
end;

procedure TfMain.WMKeyUp(var Msg: TWMKeyUp);
begin
  if IsStarted then
    begin
    EnterCriticalSection(KeyCS);
    enq_key_event(HiWord(Msg.KeyData) and $01FF, BX_KEY_RELEASED);
    leavecriticalsection(KeyCs);
    Msg.Result := 0;
    end
  else
    begin
    inherited;
    end;
end;

procedure TfMain.WMChar(var Msg: TWMChar);
begin
  if IsStarted then
    begin
    Msg.Result := 0;
    end
  else
    begin
    inherited;
    end;
end;



{ TMessageThread }

procedure TMessageThread.Execute;
begin
  while not Application.Terminated do
    begin
    Synchronize(Application.ProcessMessages);
    end;
end;

procedure TfMain.Exit1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfMain.ListFilesDblClick(Sender: TObject);
begin
  StartEmulation;
end;

procedure TfMain.N2Click(Sender: TObject);
begin
  if not isstarted then
    begin
    move(fddc[0], fdd[0], 1474560);
    end
  else
    ShowMessage('Требуется остановить процесс эмуляции.');
end;

procedure TfMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  ini: TIniFile;
begin
  ini := Tinifile.Create(extractfilepath(application.ExeName) + 'emu.ini');
  ini.WriteInteger('Hardware', 'BX_C_PRESENT', BX_C_PRESENT);
  ini.WriteInteger('Hardware', 'HDD_NUM_CYL', HDD_NUM_CYL);
  ini.WriteInteger('Hardware', 'HDD_SECTOR_PER_TRACK', HDD_SECTOR_PER_TRACK);
  ini.WriteInteger('Hardware', 'HDD_NUM_HEADS', HDD_NUM_HEADS);
  ini.WriteInteger('Hardware', 'MEMORYMB', MEMORYMB);
  ini.WriteInteger('Hardware', 'CPU_SPEED', CPU_SPEED);
  ini.WriteString('Hardware', 'HDD_FILE_DISK', HDD_FILE_DISK);
  ini.WriteInteger('Hardware', 'HDD_READ_ONLY', HDD_READ_ONLY);
  ini.WriteInteger('Hardware', 'BX_BOOT_DRIVE', BX_BOOT_DRIVE);
  ini.Free;
end;

procedure TfMain.N4Click(Sender: TObject);
begin
    move(fddc[0], fdd[0], 1474560);
end;

procedure TfMain.N5Click(Sender: TObject);
begin
fillchar(fdd[0],1474560,0);
end;

procedure TfMain.N6Click(Sender: TObject);
begin
  if not isstarted then
    begin
 if fileexists(HDD_FILE_DISK) then begin
 copyfile(pchar(HDD_FILE_DISK),pchar(changefileext(HDD_FILE_DISK,'.undo')),false);
 end   else
    ShowMessage('Нет информации для востановления.');


    end
  else
    ShowMessage('Требуется остановить процесс эмуляции.');

end;

end.
