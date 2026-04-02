unit CYhead;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, head, PNGimage;

type
  TForm89 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Label3: TLabel;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    OpenDialog1: TOpenDialog;
    Image1: TImage;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure drawPNG(num: integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Button10Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

//var
 // Form89: TForm89;
var
  CYheadgrp: array of Tgrppic;
  CYheadnum: integer = 0;
  CYheadNownum: integer;



procedure drawRLE8(Ppic: Pbyte; len: integer; PBMP: PntBitMap; dx, dy: integer; canmove: boolean);

implementation

uses
  main, CYheadoutput;

{$R *.dfm}

procedure TForm89.Button10Click(Sender: TObject);
begin
  if CYheadnum > 0 then
    Form90.ShowModal;
end;

procedure TForm89.Button1Click(Sender: TObject);
begin
  opendialog1.Filter := 'HDgrp.idx or atm(b).idx file|HDgrp.Idx;atm.idx;atmb.idx|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    edit1.Text := opendialog1.FileName;
  end;
end;

procedure TForm89.Button2Click(Sender: TObject);
begin
  opendialog1.Filter := 'HDGrp.grp file or atm(b).grp|hdgrp.Grp;atm.grp;atmb.grp|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    edit2.Text := opendialog1.FileName;
  end;
end;

procedure TForm89.Button3Click(Sender: TObject);
var
  offset: array of integer;
  Fidx, Fgrp, filelen, I: integer;
  //filename: string;
begin
  Fidx := fileopen(edit1.text, fmopenread);
  filelen := fileseek(Fidx,0,2);
  CYheadnum := filelen shr 2;
  fileseek(Fidx, 0, 0);
  setlength(offset, CYheadnum);
  fileread(Fidx, offset[0], filelen);
  fileclose(Fidx);
  setlength(CYheadgrp, CYheadnum);
  Fgrp := fileopen(edit2.text, fmopenread);
  for I := 0 to CYheadnum - 1 do
  begin
    if I = 0 then
      filelen := offset[0]
    else
      filelen := offset[I] - offset[I - 1];
    CYheadgrp[I].size := filelen;
    setlength(CYheadgrp[I].data, filelen);
    fileread(Fgrp, CYheadgrp[I].data[0], filelen);
  end;
  fileclose(Fgrp);
  CYheadNownum := 1;
  label3.Caption := '当前编号：' + inttostr(CYheadNownum) +'/' + inttostr(CYheadnum);
  drawPNG(CYheadNownum - 1);
end;

procedure TForm89.Button4Click(Sender: TObject);
var
  Fidx, Fgrp, I, tempsize: integer;
begin
  try
  Fidx := filecreate(edit1.Text);
  Fgrp := filecreate(edit2.Text);
  tempsize := 0;
  for I := 0 to CYheadnum - 1 do
  begin
    inc(tempsize, CYheadgrp[I].size);
    filewrite(Fidx, tempsize, 4);
    filewrite(Fgrp, CYheadgrp[I].data[0], CYheadgrp[I].size);
  end;
  fileclose(Fidx);
  fileclose(Fgrp);
  showmessage('保存成功！');
  except
    showmessage('保存出错！');
  end;
end;

procedure TForm89.Button5Click(Sender: TObject);
begin
  if CYheadNum > 0 then
  begin
    if CYheadNownum > 1 then
      dec(CYheadNOwnum)
    else
      CYheadNownum := 1;
    label3.Caption := '当前编号：' + inttostr(CYheadNownum) +'/' + inttostr(CYheadnum);
    drawPNG(CYheadNownum - 1);
  end;
end;

procedure TForm89.Button6Click(Sender: TObject);
begin
  if CYheadNum > 0 then
  begin
    if CYheadNownum < CYheadNum then
      inc(CYheadNOwnum)
    else
      CYheadNownum := CYheadNum;
    label3.Caption := '当前编号：' + inttostr(CYheadNownum) +'/' + inttostr(CYheadnum);
    drawPNG(CYheadNownum - 1);
  end;
end;

procedure TForm89.Button7Click(Sender: TObject);
var
  FPNG: integer;
begin
  if CYheadnum <=0 then
    exit;
  opendialog1.Filter := 'PNG files|*.png|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    FPNG := fileopen(opendialog1.FileName, fmopenread);
    CYheadgrp[CYheadNownum - 1].size := fileseek(FPNG, 0, 2);
    fileseek(FPNG,0,0);
    setlength(CYheadgrp[CYheadNownum - 1].data, CYheadgrp[CYheadNownum - 1].size);
    fileread(FPNG,CYheadgrp[CYheadNownum - 1].data[0],CYheadgrp[CYheadNownum - 1].size);
    fileclose(FPNG);
    drawPNG(CYheadNownum - 1);
  end;
end;

procedure TForm89.Button8Click(Sender: TObject);
begin
  if CYheadNum > 0 then
  begin
    inc(CYheadNOwnum, 10);
    if CYheadNownum > CYheadNum then
      CYheadNownum := CYheadNum;
    label3.Caption := '当前编号：' + inttostr(CYheadNownum) +'/' + inttostr(CYheadnum);
    drawPNG(CYheadNownum - 1);
  end;
end;

procedure TForm89.Button9Click(Sender: TObject);
begin
  if CYheadNum > 0 then
  begin
    dec(CYheadNOwnum, 10);
    if CYheadNownum < 1 then
      CYheadNownum := 1;
    label3.Caption := '当前编号：' + inttostr(CYheadNownum) +'/' + inttostr(CYheadnum);
    drawPNG(CYheadNownum - 1);
  end;
end;

procedure TForm89.drawPNG(num: integer);
var
  rs: Tmemorystream;
  PNGrs: TPNGObject;
  tempCYbmp: Tbitmap;
begin
  //
  image1.Canvas.Brush.Color := clwhite;
  image1.Canvas.FillRect(image1.Canvas.ClipRect);
  rs := Tmemorystream.Create;
  rs.Clear;
  rs.Position := 0;
  rs.write(CYheadgrp[num].data[0],CYheadgrp[num].size);
  if rs.Size < 8 then
    exit;
  PNGrs := TPNGObject.Create;
  rs.Position := 0;


  if calPNG(rs.Memory)=1 then
  begin
    try
    PNGrs.LoadFromStream(rs);
    PNGrs.Draw(image1.Canvas, PNGrs.Canvas.ClipRect);
    PNGrs.Free;
    image1.Refresh;
    except
      showmessage('打开PNG图片出错了！');
      PNGrs.Free;
      rs.Free;
    end;
  end
  else
  begin
    try
    rs.Position := 0;
    tempCYbmp := Tbitmap.Create;
    tempCYbmp.Width := image1.Picture.Bitmap.Width;
    tempCYbmp.Height := image1.Picture.Bitmap.Height;
    drawRLE8(rs.Memory, rs.Size, @tempCYbmp, 0, 0, false);

    image1.Canvas.CopyRect(tempCYbmp.Canvas.ClipRect, tempCYbmp.Canvas, tempCYbmp.Canvas.ClipRect);
    tempCYbmp.Free;
    except
      showmessage('打开RLE8图片失败了！');
     tempCYbmp.Free;
     rs.Free;
    end;
  end;
  rs.Free;

end;

procedure TForm89.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CYheadnum := 0;
  setlength(CYheadgrp, CYheadnum);
  CForm89 := true;
  action := cafree;
end;

procedure TForm89.FormResize(Sender: TObject);
begin
  image1.Picture.Bitmap.Width := image1.Width;
  image1.Picture.Bitmap.Height := image1.Height;
end;



procedure drawRLE8(Ppic: Pbyte; len: integer; PBMP: PntBitMap; dx, dy: integer; canmove: boolean);
var
  state,i, iy, ix, linesize, temp: integer;
  pw,ph,xs,ys: integer;
begin
  //

  if len >8 then
  begin
  pw := Psmallint((Ppic))^;
  Inc(Ppic, 2);
  ph := Psmallint((Ppic))^;
  Inc(Ppic, 2);
  xs := Psmallint((Ppic))^ + 1;
  Inc(Ppic, 2);
  ys := Psmallint((Ppic))^ + 1;
  Inc(Ppic, 2);


  if canmove then
  begin
    dy := dy - ys;
    dx := dx - xs;
  end;

  for iy := 0 to ph - 1 do
  begin
    linesize := Ppic^;
    inc(Ppic);
    state := 2;
    ix := dx;
    for I := 0 to linesize - 1 do
    begin
      if state = 2 then
      begin
        temp := (Ppic + I)^;
        ix := ix + temp;
        state := 1;
      end
      else if state = 1 then
      begin
        temp := (Ppic + I)^;
        state := 2 + temp;
      end
      else if state > 2 then
      begin
        temp := (Ppic + I)^;
        PBMP.canvas.Pixels[ix, iy + dy] := (McolB[temp] shl 16) or (McolG[temp] shl 8) or McolR[temp];
        dec(state);
        inc(ix);
      end;


    end;
    inc(Ppic, linesize);
  end;
  end;

end;

end.


