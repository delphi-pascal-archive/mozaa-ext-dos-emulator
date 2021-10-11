{$include defines.pas}
unit Service;

interface

uses SysUtils, Gui32, Config;

type
  LogType = (DEVLOG, PCILOG);
  ExceptionType = (BX_GP_EXCEPTION);

procedure BX_PANIC(S: string);
procedure BX_INFO(S: string);
procedure BX_DEBUG(S: string);
procedure BX_ERROR(S: string);
procedure Put(S: string);
procedure putchar(C: integer);
procedure panic(S: string);
procedure bx_log_info(S: string);
procedure exception2(K: array of word);

procedure SetType(T: LogType);
procedure InitLogFiles;
procedure DoneLogFiles;
procedure Vuoto;
function CountLinesTxtFile(filename: string): longword;
function GetFileSize(const Name: string): longword;
procedure Blink(const s: string);

{$ifndef beep}
procedure Beep;
{$endif}

procedure WriteToConsole(s: string);

implementation

uses cpu, Windows;

{$ifndef beep}
procedure Beep;
begin
{$ifdef COMPILE_WIN32}
  MessageBeep(0);
{$endif}
end;

{$endif}

procedure Vuoto;
begin
end;

procedure InitLogFiles;
var
  WorkDir: string;
begin
  WorkDir := ExtractFilePath(ParamStr(0));
  AssignFile(LogFile, WorkDir + 'logs\log.txt');
  Rewrite(LogFile);
end;

procedure DoneLogFiles;
begin
  {$if BX_LOG_ENABLED=1}
  FileClose(FilesLog);
  {$ifend}
  {$if BX_DEBUG_TO_FILE=1}
  //CloseFile(LogFile);
  {$ifend}
end;

procedure BX_PANIC(S: string);
begin
  //WriteLn(LogFile,Format('PANIC message  : [%d], %s',[bx_cpu.prog,S]));
  //FormLog.OutLog.Items.Add(s);
{$ifndef NO_PANIC_ERR}
  //DoneLogFiles;
  //WriteLn('PANIC! : ' + S);
  //raise Exception.Create(Format('Panic message : %s on %d',[S,bx_cpu.prog]));
  //readln;
{$endif}
end;

procedure BX_INFO(S: string);
begin
  {$if BX_INFO_ENABLED=1}
  {$if BX_DEBUG_TO_FILE=1}
  WriteLn(LogFile, Format('INFO message  : [%d], %s', [bx_cpu.prog, S]));
  {$else}
   //FormLog.OutLog.Items.Add(Format('Info message  : [%d], %s',[bx_cpu.prog,S]));
  {$ifend}
  {$ifend}
end;

procedure BX_DEBUG(S: string);
begin
  exit;
end;

procedure BX_ERROR(S: string);
begin
  exit;
end;

procedure Put(S: string);
begin
  exit;
end;

procedure SetType(T: LogType);
begin
  exit;
end;

procedure putchar(C: integer);
begin
  exit;
end;

procedure panic(S: string);
begin
  exit;
end;

procedure bx_log_info(S: string);
begin
  exit;
end;

procedure exception2(K: array of word);
begin
  {$if BX_DEBUG_ENABLED=1}
  //FormLog.DebugList.Items.Add('Exception2');
  {$ifend}
  bx_cpu.Exception(K[0], K[1], K[2]);
end;

procedure WriteToConsole(s: string);
var
  wHandle:     THandle;
  CharWritten: cardinal;
begin
{$ifdef COMPILE_WIN32}
  s:=s + #13#10;
  wHandle:=GetStdHandle(STD_OUTPUT_HANDLE);
  WriteConsole(wHandle,@LastMessage,Length(LastMessage),CharWritten,nil);
{$endif}
end;

function CountLinesTxtFile(filename: string): longword;
var
  fp: TextFile;
  I:  longword;
  S:  string;
begin
  I := 0;
  assignfile(fp, filename);
  reset(fp);
  while not EOF(fp) do
    begin
    ReadLn(fp, S);
    Inc(I);
    end;
  closefile(fp);
  Result := I;
end;


function GetFileSize(const Name: string): longword;
var
  f: file;
begin
  assignfile(f, Name);
  reset(f);
  Result := FileSize(f);
  CloseFile(f);
end;

procedure Blink(const s: string);
begin
  SetWindowText(MainWnd, PChar(s));
end;


end.
