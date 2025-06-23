unit outputPNG;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, head, PNGimage, FileCtrl, inifiles;

type
  TPNGThread = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

  TForm88 = class(TForm)
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    ProgressBar1: TProgressBar;
    Label1: TLabel;
    Button5: TButton;
    Label2: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form88: TForm88;
  dir: string;
  nowPNGpos: integer = 0;
  outputing: boolean = false;
  ID: integer;
    outputPNGthread: TPNGThread;
  colfilename, grpfilename, idxfilename: string;
    Savebufbmp: Tbitmap;
      PNGrs: TPNGObject;
  showmsg: boolean;
  outputPNGindexName: string;

procedure endPNGprocess;
procedure updateprocess;
procedure initialPNGthread;
procedure outputPNGshowerror;
procedure check;
procedure mustexit;


implementation

uses
  grplist;

{$R *.dfm}

procedure TPNGThread.Execute;
var
  I, PF, FH : integer;
  tx,ty: smallint;
  filename: string;
  Savebufbmp: Tbitmap;
  PNGrs: TPNGObject;
  ix,iy: integer;
  Pdat:Pbytearray;
  Pd: array of byte;
begin
  freeonterminate := true;
  savebufbmp := Tbitmap.Create;
  savebufbmp.PixelFormat := pf24bit;
  PNGrs := TPNGObject.create;
  NowPNGpos := 0;
  Synchronize(initialPNGthread);
  FH := filecreate(dir + outputPNGindexName, fmopenreadwrite);
  for I := 0 to filenum - 1 do
  begin
    savebufbmp.Canvas.Lock;
    tx := 0;
    ty := 0;
    try
      if grppic[I].size > 8 then
      begin

        if calPNG(@(grppic[I].data[0])) = 1 then
        begin
          filename := dir + inttostr(I) +'.png';
          PF := filecreate(filename);
          filewrite(PF,grppic[I].data[0],grppic[I].size);
          fileclose(PF);
        end
        else
        begin
          tx := (Psmallint(@(grppic[I].data[4])))^;
          ty := (Psmallint(@(grppic[I].data[6])))^;
          savebufbmp.Width := (Psmallint(@(grppic[I].data[0])))^;
          savebufbmp.height := (Psmallint(@(grppic[I].data[2])))^;
          if (savebufbmp.Width * savebufbmp.Height > 1) then
          begin
            savebufbmp.Canvas.Brush.Color := usualtrans;
            savebufbmp.Canvas.FillRect(savebufbmp.Canvas.ClipRect);
            drawRLE8(@(grppic[I].data[0]),grppic[I].size,@savebufbmp,0,0,false);

            setlength(Pd, savebufbmp.Width * 3);

            PNGrs.Assign(savebufbmp);
            PNGrs.CreateAlpha;
            for iy := 0 to savebufbmp.Height - 1 do
            begin
              copymemory(@PD[0],savebufbmp.ScanLine[iy],savebufbmp.Width * 3);
              Pdat := PNGrs.AlphaScanline[iy];
              for ix := 0 to savebufbmp.Width - 1 do
                if {savebufbmp.Canvas.Pixels[ix, iy] =} usualtrans = PD[ix * 3] shl 16 + PD[ix * 3+1] shl 8 + PD[ix * 3+2] then
                  Pdat[ix] := 0;
            end;
           filename := dir + inttostr(I) +'.png';
           PNGrs.SaveToFile(filename);
          end;
        end;

      end;
    except

    end;
    NowPNGpos := I + 1;
    Synchronize(updateprocess);
    savebufbmp.Canvas.Unlock;
    filewrite(FH, tx, 2);
    filewrite(FH, ty, 2);
    if not outputing then
    begin
      synchronize(mustexit);
      outputing := false;
      savebufbmp.Free;
      PNGrs.Free;
      setlength(PD, 0);
      fileclose(FH);
      exit;
    end;
  end;
  outputing := false;
  Synchronize(endPNGprocess);
  PNGrs.Free;
  savebufbmp.Free;
  setlength(PD, 0);
  fileclose(FH);
end;

procedure initialPNGthread;
begin
  Form88.progressbar1.max := filenum;
  Form88.ProgressBar1.Min := 0;
  Form88.ProgressBar1.Position := 0;
  Form88.Label1.Caption := '进度0/' + inttostr(filenum);
  nowPNGpos := 0;
end;

procedure mustexit;
begin
  Form88.ProgressBar1.Position := 0;
  Form88.Label1.Caption := '进度';
  if showmsg then
    showmessage('终止导出！');
end;

procedure outputPNGshowerror;
begin
  showmessage('导出错误！');
end;

procedure check;
begin
  showmessage(inttostr(ID));
end;

procedure updateprocess;
begin
  Form88.ProgressBar1.Position := nowPNGpos;
  Form88.Label1.Caption := '进度'+ inttostr(nowPNGpos) + '/' + inttostr(filenum);
end;

procedure endPNGprocess;
begin
  Form88.ProgressBar1.Position := 0;
  showmessage('导出完成！');
  Form88.Label1.Caption := '进度';
end;

procedure TForm88.Button1Click(Sender: TObject);
begin
  Dir := Edit1.Text;
  if SelectFolderDialog(self.handle, '选择保存文件夹','',Dir) then
  begin
    if dir[length(dir)] <> '\' then
      dir :=dir + '\';
    edit1.Text := dir;
  end;
end;

procedure TForm88.Button2Click(Sender: TObject);
begin
  showmsg := false;
  outputing := false;
  self.Close;
end;

procedure TForm88.Button3Click(Sender: TObject);
var
  ini: Tinifile;
begin
  if not outputing then
  begin
    outputing := true;
    dir := edit1.Text;
    if not DirectoryExists(dir) then
      ForceDirectories(dir);
    try
      ini := TiniFile.Create(StartPath + iniFileName);
      outputPNGindexName := ini.ReadString('File', 'ImzIndexFileName', 'index.ka');
    finally
      ini.Free;
    end;
    outputPNGthread := TPNGThread.Create(false);
  end
  else
    showmessage('正在导出PNG图片中！请耐心等待，稍后再进行操作！');
end;

procedure TForm88.Button4Click(Sender: TObject);
begin
  if outputing then
  begin
    try
    //outputPNGthread.DoTerminate;
    //TerminateThread(outputPNGthread.ThreadID, 0);
    //outputPNGthread.Terminate;
    showmsg := true;
    outputing := false;
   // Form88.ProgressBar1.Position := 0;
   // Form88.Label1.Caption := '进度';
    except
      showmessage('出错了！！');
    end;
  end;

end;

procedure TForm88.Button5Click(Sender: TObject);
begin
  self.close;
end;

procedure TForm88.FormCreate(Sender: TObject);
begin
  Edit1.Text := StartPath;
  dir := edit1.Text;
end;

end.
