unit imzPNGedit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, imagez, ExtCtrls, StdCtrls, Spin, PNGimage, Math, Head;

type
  TImzPNGeditForm = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    ScrollBox1: TScrollBox;
    Panel4: TPanel;
    Image1: TImage;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Button2: TButton;
    SpinEdit1: TSpinEdit;
    Label3: TLabel;
    Button1: TButton;
    Image2: TImage;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    OpenDialog1: TOpenDialog;
    Button8: TButton;
    procedure Button2Click(Sender: TObject);
    procedure Initial(EMode: TImzEditMode);
    procedure Button1Click(Sender: TObject);
    procedure DrawPNG(count: integer);
    procedure Image2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SpinEdit1Change(Sender: TObject);
    procedure DrawMove;
    procedure Button5Click(Sender: TObject);
    procedure Edit1KeyPress(Sender: TObject; var Key: Char);
    procedure Edit2KeyPress(Sender: TObject; var Key: Char);
    procedure Button7Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DrawprePNG;
    procedure DrawprePNGtoImage(count: integer; Rct: Trect);
    procedure Button4Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  const
    maxprepic = 5;
    MinWidth = 200;
    MinHeight = 200;
  public
    { Public declarations }
    imzPNG: PimzPNG;
    tempimzPNG: TimzPNG;
    framenum: integer;
    preindex: integer;
    PNG :TpngObject;
  end;

implementation

{$R *.dfm}

procedure TImzPNGeditForm.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  tempint: integer;
begin
  if Button = mbLeft then
  begin
    tempint := x div (Image1.Width div maxprepic);
    if tempint < maxprepic then
    begin
      if (tempimzPNG.frame > 0) and (tempint + preindex <= tempimzPNG.frame) then
      begin
        framenum := tempint + preindex;
        spinedit1.Value := framenum;
        DrawPNG(Framenum - 1);
      end;
    end;
  end;
end;

procedure TImzPNGeditForm.DrawprePNG;
var
  I, w: integer;
begin
  Image1.Canvas.Brush.Style := bssolid;
  Image1.Canvas.Brush.Color := clwhite;
  Image1.Canvas.FillRect(Image1.Canvas.ClipRect);
  w := image1.Width div maxprepic;
  Image1.Canvas.Font.Color := clred;
  Image1.Canvas.Brush.Style := bsclear;
  for I := 0 to maxprepic - 1 do
  begin
    DrawprePNGtoImage(preindex + I - 1, Rect(I * W, 0, I * W + W, Image1.Height));
    if ((preindex + I) > 0) and ((preindex + I) <= tempimzPNG.frame) then
      Image1.Canvas.TextOut(I * W, 0, inttostr(preindex + I));
  end;
end;

procedure TImzPNGeditForm.DrawprePNGtoImage(count: integer; Rct: Trect);
var
  temprs: Tmemorystream;
  rh, rw: integer;
begin
  //
  if (count >= 0) and (count < tempimzPNG.frame) then
  begin
    try
      temprs := Tmemorystream.Create;
      temprs.SetSize(tempimzPNG.framelen[count]);
      temprs.Position := 0;
      temprs.Write(tempimzPNG.framedata[Count].data[0], tempimzPNG.framelen[count]);
      temprs.Position := 0;

      PNG.LoadFromStream(temprs);

      if PNG.Width < (rct.Right - rct.Left) then
        rct.Right := rct.Left + PNG.Width;
      if PNG.Height < (rct.Bottom - rct.Top) then
        rct.Bottom := rct.Top + PNG.Height;
      PNG.Draw(image1.Canvas, rct);

    finally
      //PNG.Free;
      temprs.Free;
    end;
  end;

end;


procedure TImzPNGeditForm.Image2MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  tempimzPNG.x := x;
  tempimzPNG.y := y;
  edit1.Text := inttostr(tempimzPNG.x);
  edit2.Text := inttostr(tempimzPNG.y);
  DrawPNG(framenum - 1);
end;

procedure TImzPNGeditForm.Initial(EMode: TImzEditMode);
var
  I: integer;
begin
  //
  if EMode = zPNGmode then
  begin
    Button5.Enabled := false;
    Button6.Enabled := false;
    Button7.Enabled := false;
    Button8.Enabled := false;
  end
  else
  begin
    Button5.Enabled := true;
    Button6.Enabled := true;
    Button7.Enabled := true;
    Button8.Enabled := true;
  end;

  tempimzPNG.len := imzPNG.len;
  tempimzPNG.x := imzPNG.x;
  tempimzPNG.y := imzPNG.y;
  tempimzPNG.frame := imzPNG.frame;
  setlength(tempimzPNG.framelen, tempimzPNG.frame);
  setlength(tempimzPNG.framedata, tempimzPNG.frame);
  for I := 0 to tempimzPNG.frame - 1 do
  begin
    tempimzPNG.framelen[I] := imzPNG.framelen[I];
    setlength(tempimzPNG.framedata[I].data, tempimzPNG.framelen[I]);
    copymemory(@tempimzPNG.framedata[I].data[0], @imzPNG.framedata[I].data[0], tempimzPNG.framelen[I]);
  end;

  Edit1.Text := inttostr(tempimzPNG.x);
  Edit2.Text := inttostr(tempimzPNG.y);

  image2.Width := MinWidth;
  image2.Height := MinHeight;
  image2.Picture.Bitmap.Width := Image2.Width;
  Image2.Picture.Bitmap.Height := Image2.Height;

  if tempimzPNG.frame > 0 then
  begin
    framenum := 1;
    preindex := 1;
    spinedit1.MaxValue := tempimzPNG.frame;
    spinedit1.MinValue := 1;
    spinedit1.Value := 1;
    DrawPNG(0);
    DrawPrePNG;
  end
  else
  begin
    framenum := -1;
    preindex := -1;
    spinedit1.MinValue := -1;
    spinedit1.MaxValue := -1;
    spinedit1.Value := -1;
  end;

end;

procedure TImzPNGeditForm.SpinEdit1Change(Sender: TObject);
begin
  if Spinedit1.Value > Spinedit1.MaxValue then
    Spinedit1.Value := Spinedit1.MaxValue;
  if Spinedit1.Value < Spinedit1.MinValue then
    Spinedit1.Value := Spinedit1.MinValue;
  if (Spinedit1.Value > 0) and (Spinedit1.Value <= tempimzPNG.frame) then
  begin
    framenum := Spinedit1.Value;
    DrawPNG(framenum - 1);
  end;
end;

procedure TImzPNGeditForm.DrawMove;
var
  i: integer;
begin
  for I := 0 to Image2.Width - 1 do
    Image2.Canvas.Pixels[I, tempimzPNG.y] := clred;
  for I := 0 to Image2.Height - 1 do
    Image2.Canvas.Pixels[tempimzPNG.x, I] := clred;
end;

procedure TImzPNGeditForm.DrawPNG(count: integer);
var

  temprs: Tmemorystream;
  rh, rw: integer;
begin
  //
  image2.Canvas.Brush.Color := clwhite;
  image2.Canvas.FillRect(image2.Canvas.ClipRect);
  if (count >= 0) and (count < tempimzPNG.frame) then
  begin
    try
      temprs := Tmemorystream.Create;
      temprs.SetSize(tempimzPNG.framelen[count]);
      temprs.Position := 0;
      temprs.Write(tempimzPNG.framedata[Count].data[0],tempimzPNG.framelen[count]);
      temprs.Position := 0;
      PNG.LoadFromStream(temprs);

      image2.Width := Max(PNG.Width, MinWidth);
      image2.Height := Max(PNG.Height, MinHeight);
      image2.Picture.Bitmap.Width := Image2.Width;
      Image2.Picture.Bitmap.Height := Image2.Height;

      image2.Canvas.Brush.Color := clwhite;
      image2.Canvas.FillRect(image2.Canvas.ClipRect);

      PNG.Draw(image2.Canvas, PNG.Canvas.ClipRect);

    finally

      temprs.Free;
    end;
  end;
  DrawMove;
end;

procedure TImzPNGeditForm.Edit1KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    Button2Click(Sender);
  end;
end;

procedure TImzPNGeditForm.Edit2KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    Button2Click(Sender);
  end;
end;

procedure TImzPNGeditForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  PNG.destroy;
end;

procedure TImzPNGeditForm.FormCreate(Sender: TObject);
begin
  PNG := TPNGObject.Create;
end;

procedure TImzPNGeditForm.Button1Click(Sender: TObject);
var
  I: integer;
begin
  //
  tempimzPNG.len := 2 * 2 + 4 + tempimzPNG.frame * 2 * 4;
  for I := 0 to tempimzPNG.frame - 1 do
  begin
    inc(tempimzPNG.len, tempimzPNG.framelen[I]);
  end;
  imzPNG.len := tempimzPNG.len;
  imzPNG.x := tempimzPNG.x;
  imzPNG.y := tempimzPNG.y;
  imzPNG.frame := tempimzPNG.frame;
  setlength(imzPNG.framelen, imzPNG.frame);
  setlength(imzPNG.framedata, imzPNG.frame);
  for I := 0 to imzPNG.frame - 1 do
  begin
    imzPNG.framelen[I] := tempimzPNG.framelen[I];
    setlength(imzPNG.framedata[I].data, imzPNG.framelen[I]);
    copymemory(@imzPNG.framedata[I].data[0], @tempimzPNG.framedata[I].data[0], imzPNG.framelen[I]);
  end;
  self.Close;
end;

procedure TImzPNGeditForm.Button2Click(Sender: TObject);
var
  tempint: integer;
begin
  try
    tempint := tempimzPNG.x;
    tempimzPNG.x := strtoint(edit1.Text);
  except
    tempimzPNG.x := tempint;
  end;

  try
    tempint := tempimzPNG.y;
    tempimzPNG.y := strtoint(edit2.Text);
  except
    tempimzPNG.y := tempint;
  end;

  DrawPNG(framenum - 1);
end;

procedure TImzPNGeditForm.Button3Click(Sender: TObject);
begin
  if tempimzPNG.frame > 0 then
  begin
    dec(preindex);
    if preindex <= 0 then
      preindex := 1;
    DrawPrePNG;
  end;
end;

procedure TImzPNGeditForm.Button4Click(Sender: TObject);
begin
  if tempimzPNG.frame > 0 then
  begin
    inc(preindex);
    if preindex > tempimzPNG.frame then
      preindex := tempimzPNG.frame;
    DrawPrePNG;
  end;
end;

procedure TImzPNGeditForm.Button5Click(Sender: TObject);
var
  I, FH: integer;
begin
  opendialog1.FileName := '';
  opendialog1.Filter := '*.png|*.png|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    if tempimzPNG.frame <= 0 then
    begin
      tempimzPNG.frame := 0;
      Framenum := 1;
      preindex := 1;
    end;

    inc(tempimzPNG.frame);
    setlength(tempimzPNG.framelen, tempimzPNG.frame);
    setlength(tempimzPNG.framedata, tempimzPNG.frame);
    for I := tempimzPNG.frame - 2 downto framenum - 1 do
    begin
      tempimzPNG.framelen[I + 1] := tempimzPNG.framelen[I];
      setlength(tempimzPNG.framedata[I + 1].data, tempimzPNG.framelen[I + 1]);
      copymemory(@tempimzPNG.framedata[I + 1].data[0], @tempimzPNG.framedata[I].data[0], tempimzPNG.framelen[I + 1]);
    end;
    FH := fileopen(opendialog1.FileName, fmopenread);
    tempimzPNG.framelen[framenum - 1] := fileseek(FH, 0, 2);
    fileseek(FH, 0, 0);
    setlength(tempimzPNG.framedata[Framenum - 1].data, tempimzPNG.framelen[framenum - 1]);
    fileread(FH, tempimzPNG.framedata[Framenum - 1].data[0], tempimzPNG.framelen[framenum - 1]);
    Fileclose(FH);

    spinedit1.MaxValue := tempimzPNG.frame;
    spinedit1.minValue := 1;
    spinedit1.Value := framenum;

    DrawPNG(Framenum - 1);
    DrawPrePNG;
  end;
end;

procedure TImzPNGeditForm.Button6Click(Sender: TObject);
var
  I, FH: integer;
begin
  opendialog1.FileName := '';
  opendialog1.Filter := '*.png|*.png|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    if tempimzPNG.frame <= 0 then
    begin
      tempimzPNG.frame := 0;
      Framenum := 1;
      preindex := 1;
    end;
    inc(tempimzPNG.frame);
    setlength(tempimzPNG.framelen, tempimzPNG.frame);
    setlength(tempimzPNG.framedata, tempimzPNG.frame);

    FH := fileopen(opendialog1.FileName, fmopenread);
    tempimzPNG.framelen[tempimzPNG.frame - 1] := fileseek(FH, 0, 2);
    fileseek(FH, 0, 0);
    setlength(tempimzPNG.framedata[tempimzPNG.frame - 1].data, tempimzPNG.framelen[tempimzPNG.frame - 1]);
    fileread(FH, tempimzPNG.framedata[tempimzPNG.frame - 1].data[0], tempimzPNG.framelen[tempimzPNG.frame - 1]);
    Fileclose(FH);
    framenum := tempimzPNG.frame;
    spinedit1.MaxValue := tempimzPNG.frame;
    spinedit1.minValue := 1;
    spinedit1.Value := framenum;

    DrawPNG(Framenum - 1);
    DrawPrePNG;
  end;
end;

procedure TImzPNGeditForm.Button7Click(Sender: TObject);
var
  I: integer;
begin
  if tempimzPNG.frame <= 0 then
    exit;
  if tempimzPNG.frame = 1 then
  begin
    showmessage('最后一帧了');
    exit;
  end;
  for I := framenum - 1 to tempimzPNG.frame - 2 do
  begin
    tempimzPNG.framelen[I] := tempimzPNG.framelen[I + 1];
    setlength(tempimzPNG.framedata[I].data, tempimzPNG.framelen[I]);
    copymemory(@tempimzPNG.framedata[I].data[0], @tempimzPNG.framedata[I + 1].data[0], tempimzPNG.framelen[I]);
  end;
  dec(tempimzPNG.frame);
  if tempimzPNG.frame > 0 then
  begin
    spinedit1.MaxValue := tempimzPNG.frame;
    spinedit1.minValue := 1;
    if Framenum > tempimzPNG.frame then
      dec(Framenum);
    if Preindex > tempimzPNG.frame then
      dec(Preindex);
    spinedit1.Value := framenum;
    DrawPNG(Framenum - 1);
    DrawPrePNG;
  end
  else
  begin
    spinedit1.minValue := -1;
    spinedit1.MaxValue := -1;
    spinedit1.Value := -1;
    framenum := -1;
    preindex := -1;

    Image2.Width := MinWidth;
    Image2.Height := MinHeight;
    image2.Picture.Bitmap.Width := Image2.Width;
    Image2.Picture.Bitmap.Height := Image2.Height;

    DrawPNG(Framenum - 1);
    DrawPrePNG;
  end;

end;

procedure TImzPNGeditForm.Button8Click(Sender: TObject);
var
  FH: integer;
begin

  opendialog1.FileName := '';
  opendialog1.Filter := '*.png|*.png|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    if tempImzPNG.frame <= 0 then
    begin
      tempImzPNG.frame := 1;
      Framenum := 1;
      preindex := 1;
      setlength(tempImzPNG.framelen, tempImzPNG.frame);
      setlength(tempImzPNG.framedata, tempImzPNG.frame);
    end;
    try
      FH := fileopen(opendialog1.FileName, fmopenread);
      tempImzPNG.framelen[Framenum - 1] := fileseek(FH, 0, 2);
      fileseek(FH, 0, 0);
      setlength(tempImzPNG.framedata[Framenum - 1].data, tempImzPNG.framelen[Framenum - 1]);
      fileread(FH, tempImzPNG.framedata[Framenum - 1].data[0], tempImzPNG.framelen[Framenum - 1]);

      spinedit1.MaxValue := tempimzPNG.frame;
      spinedit1.minValue := 1;
      spinedit1.Value := framenum;

      DrawPNG(Framenum - 1);
      DrawPrePNG;
    finally
      fileclose(FH);
    end;
  end;
end;

end.
