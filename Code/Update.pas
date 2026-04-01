unit Update;

{$modeswitch autoderef}

{$H+}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, IdHTTP;

type
  TWorkMode = (wmRead, wmWrite);

  TZIPThread = class(TThread)
  protected
    procedure Execute; override;
  end;

  TEXEThread = class(TThread)
  protected
    procedure Execute; override;
  end;

  TAllFileThread = class(TThread)
  protected
    procedure Execute; override;
  end;

  TForm87 = class(TForm)
    ProgressBar1: TProgressBar;
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    IdHTTP1: TIdHTTP;
    Label1: TLabel;
    Button4: TButton;
    Button5: TButton;
    Label2: TLabel;
    Button6: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure IdHTTP1Work(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
    procedure IdHTTP1WorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
    procedure IdHTTP1WorkEnd(ASender: TObject; AWorkMode: TWorkMode);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure Button6Click(Sender: TObject);
  private
    EXEThread: TEXEThread;
    ZIPTHread: TZIPThread;
    AllFileThread: TAllFileThread;
  end;

procedure DownLoadZip;
procedure DownLoadExe;
procedure restart;
procedure resetprogressbar;
procedure resetprogressbarexe;
procedure showdownloaderror;
procedure Handlezip;
procedure resetprogressbarzip;
procedure OnDeCompress;
procedure Checkerror;
procedure CheckStep;

var
  Form87: TForm87;
  updatefilename: string;
  updaters: TMemoryStream;
  Downloading: boolean = false;
  needrestart: boolean = false;
  maxsize: int64 = 0;
  updateerror: boolean = false;
  canexit: boolean = true;
  threadexit: boolean = false;
  updatefilenum: integer = 0;
  filenamearray: array of string;
  newVersion: string = '';

implementation

// {$R *.lfm}

procedure TZIPThread.Execute;
begin
end;

procedure TEXEThread.Execute;
begin
end;

procedure TAllFileThread.Execute;
begin
end;

procedure TForm87.Button1Click(Sender: TObject);
begin
end;

procedure TForm87.FormCreate(Sender: TObject);
begin
  Downloading := false;
end;

procedure TForm87.Button2Click(Sender: TObject);
begin
end;

procedure TForm87.Button3Click(Sender: TObject);
begin
end;

procedure TForm87.IdHTTP1Work(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
begin
end;

procedure TForm87.IdHTTP1WorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
begin
  ProgressBar1.Max := 100;
  ProgressBar1.Position := 0;
end;

procedure TForm87.IdHTTP1WorkEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
end;

procedure TForm87.Button4Click(Sender: TObject);
begin
end;

procedure TForm87.Button5Click(Sender: TObject);
begin
end;

procedure TForm87.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TForm87.Button6Click(Sender: TObject);
begin
end;

procedure DownLoadZip;
begin
end;

procedure DownLoadExe;
begin
end;

procedure restart;
begin
end;

procedure resetprogressbar;
begin
end;

procedure resetprogressbarexe;
begin
end;

procedure showdownloaderror;
begin
end;

procedure Handlezip;
begin
end;

procedure resetprogressbarzip;
begin
end;

procedure OnDeCompress;
begin
end;

procedure Checkerror;
begin
end;

procedure CheckStep;
begin
end;

end.


