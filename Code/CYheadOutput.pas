unit CYheadOutput;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls,FileCtrl, head, PNGimage;

type

  TCYheadThread = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

  TForm90 = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    ProgressBar1: TProgressBar;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form90: TForm90;
  cyheadDIR: string;
  nowoutputnum: integer;
  CYheadoutputing: boolean = false;
  CYheadthread : TCYheadthread;
  showmsg :boolean;

procedure updateprocess;
procedure mustexit;
procedure outputPNGshowerror;
procedure initialCYheadthread;
procedure endPNGprocess;

implementation

uses
  CYhead;

{$R *.dfm}

procedure TForm90.Button1Click(Sender: TObject);
begin
  if SelectDirectory('选择保存文件夹','',CYheadDir) then
  begin
    if CYheaddir[length(CYheaddir)] <> '\' then
      CYheaddir :=CYheaddir + '\';
    edit1.Text := CYheaddir;
  end;
end;

procedure updateprocess;
begin
  Form90.ProgressBar1.Position := nowoutputnum;
  Form90.Label1.Caption := '进度'+ inttostr(nowoutputnum) + '/' + inttostr(CYheadnum);
end;

procedure TForm90.Button2Click(Sender: TObject);
begin
  showmsg := false;
  CYheadoutputing := false;
  self.Close;
end;

procedure TForm90.Button3Click(Sender: TObject);
begin
  if not CYheadoutputing then
  begin
    CYheadoutputing := true;
    CYheaddir := edit1.Text;
    CYheadthread := TCYheadThread.Create(false);
  end
  else
    showmessage('正在导出PNG图片中！请耐心等待，稍后再进行操作！');
end;

procedure TForm90.Button4Click(Sender: TObject);
begin
  if CYheadoutputing then
  begin
    try
    showmsg := true;
    CYheadoutputing := false;
    except
      showmessage('出错了！！');
    end;
  end;
end;

procedure TForm90.FormCreate(Sender: TObject);
begin
  Edit1.Text := StartPath;
  CYheaddir := edit1.Text;
  self.Cursor := fmcursor;
end;

procedure mustexit;
begin
  Form90.ProgressBar1.Position := 0;
  Form90.Label1.Caption := '进度';
  if showmsg then
    showmessage('终止导出！');
end;

procedure outputPNGshowerror;
begin
  showmessage('导出错误！');
end;

procedure initialCYheadthread;
begin
  Form90.progressbar1.max := CYheadnum;
  Form90.ProgressBar1.Min := 0;
  Form90.ProgressBar1.Position := 0;
  Form90.Label1.Caption := '进度0/' + inttostr(CYheadnum);
  nowoutputnum := 0;
end;

procedure TCYheadThread.Execute;
var
  I, PF : integer;
  filename: string;
  Savebufbmp: Tbitmap;
  PNGrs: TPNGObject;
  ix,iy: integer;
  Pdat:Pbytearray;
  PD: array of byte;
begin
  freeonterminate := true;
  savebufbmp := Tbitmap.Create;
  PNGrs := TPNGObject.create;
  savebufbmp.PixelFormat := pf24bit;
  Synchronize(initialCYheadthread);

    for I := 0 to CYheadnum - 1 do
    begin
      savebufbmp.Canvas.Lock;
      try
      if CYheadgrp[I].size > 8 then
      begin
        if calPNG(@CYheadgrp[I].data[0])=0  then
        begin
        savebufbmp.Width := (Psmallint(@(CYheadgrp[I].data[0])))^;
        savebufbmp.height := (Psmallint(@(CYheadgrp[I].data[2])))^;
        savebufbmp.Canvas.Brush.Color := usualtrans;
        savebufbmp.Canvas.FillRect(savebufbmp.Canvas.ClipRect);
        drawRLE8(@(CYheadgrp[I].data[0]),CYheadgrp[I].size,@savebufbmp,0,0,false);

        setlength(Pd, savebufbmp.Width * 3);

        PNGrs.Assign(savebufbmp);
        PNGrs.CreateAlpha;
        for iy := 0 to savebufbmp.Height - 1 do
        begin
          Pdat := PNGrs.AlphaScanline[iy];
          copymemory(@PD[0],savebufbmp.ScanLine[iy],savebufbmp.Width * 3);
          for ix := 0 to savebufbmp.Width - 1 do
            if {savebufbmp.Canvas.Pixels[ix, iy] =} PD[ix * 3] shl 16 + PD[ix * 3+1] shl 8 + PD[ix * 3+2] = usualtrans then
              Pdat[ix] := 0;
        end;
        filename := CYheaddir + '苍炎头像'+ inttostr(I + 1) +'.png';
        PNGrs.SaveToFile(filename);

        end
        else
        begin
          filename := CYheaddir + '苍炎头像'+ inttostr(I + 1) +'.png';
          PF := filecreate(filename);
          filewrite(PF, CYheadgrp[I].data[0],CYheadgrp[I].size);
          fileclose(PF);
        end;
      end;
      except

      end;
      Nowoutputnum := I + 1;
      Synchronize(updateprocess);
      savebufbmp.Canvas.Unlock;
      if not CYheadoutputing then
      begin
        synchronize(mustexit);
        CYheadoutputing := false;
        savebufbmp.Free;
        PNGrs.Free;
        setlength(PD,0);
        exit;
      end;
    end;
  CYheadoutputing := false;
  Synchronize(endPNGprocess);
  PNGrs.Free;
  savebufbmp.Free;
  setlength(PD,0);
end;

procedure endPNGprocess;
begin
  showmessage('导出完成！');
  Form90.ProgressBar1.Position := 0;
  Form90.Label1.Caption := '进度';
end;

end.
