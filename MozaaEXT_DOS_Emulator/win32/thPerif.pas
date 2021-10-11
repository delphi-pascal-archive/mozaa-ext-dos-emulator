unit thPerif;

interface

uses Classes, ExtCtrls, SyncObjs;

type

  TSignalProcedure = procedure(AOnOff: boolean);

  TThPerif = class (TThread)
  public
    PSign: PByte;
    EventBitmap: PByte;
    Crit:  TCriticalSection;
    EventSignal: TEvent;
    constructor Init(AProc: TSignalProcedure);
  protected
    SignalProcedure: TSignalProcedure;
    procedure Execute; override;
  end;

implementation

uses SysUtils, Windows;

{ TThPerif }

constructor TThPerif.Init(AProc: TSignalProcedure);
begin
  SignalProcedure := AProc;
  Crit := TCriticalSection.Create;
  inherited Create(False);
end;

procedure TThPerif.Execute;
begin
  while True do
    begin
    EventSignal.WaitFor(INFINITE);
    SignalProcedure(True);
    SignalProcedure(False);
    end;
end;

end.
