unit PNGimportModify;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TForm95 = class(TForm)
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    Button2: TButton;
    ScrollBox1: TScrollBox;
    Image1: TImage;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Button3: TButton;
    ColorDialog1: TColorDialog;
    CheckBox3: TCheckBox;
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Edit1Change(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
    procedure DrawOffset;
    procedure ScrollBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    xoffset,yoffset: integer;
  end;

var
  Form95: TForm95;
  PNGimportModifybmp: TBitmap;
  PNGImportModifyTransColor: Cardinal = 0;
  Form95active: Boolean = false;

implementation

{$R *.dfm}

procedure TForm95.Edit1Change(Sender: TObject);
var
  temp: integer;
begin
  temp := xoffset;
  try
    xoffset := strtoint(edit1.Text);
    DrawOffset;
  except
    xoffset := temp;
  end;
end;

procedure TForm95.Edit2Change(Sender: TObject);
var
  temp: integer;
begin
  temp := yoffset;
  try
    yoffset := strtoint(edit2.Text);
    DrawOffset;
  except
    yoffset := temp;
  end;
end;

procedure TForm95.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  xoffset := x;
  yoffset := y;
  Edit1.Text := inttostr(x);
  Edit2.Text := IntToStr(y);
  DrawOffset;
end;

procedure TForm95.ScrollBox1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  xoffset := x - image1.Left;
  yoffset := y - image1.Top;
  Edit1.Text := inttostr(xoffset);
  Edit2.Text := IntToStr(yoffset);
  DrawOffset;
end;

procedure TForm95.Button3Click(Sender: TObject);
begin
  if ColorDialog1.Execute then
  begin
    PNGImportModifyTransColor := ColorDialog1.Color;
  end;
end;

procedure TForm95.DrawOffset;
var
  I: integer;
begin
  //
  if not Form95active then
    exit;
  self.Image1.Picture.Bitmap.Width := self.Image1.Width;
  self.Image1.Picture.Bitmap.Height := self.Image1.Height;
  self.Image1.Canvas.CopyRect(self.Image1.Canvas.ClipRect, PNGimportModifybmp.Canvas, PNGimportModifybmp.Canvas.ClipRect);
  for I := 0 to self.Image1.Picture.Bitmap.Width - 1 do
    self.Image1.Canvas.Pixels[I, yoffset] := clRed;
  for I := 0 to self.Image1.Picture.Bitmap.Height - 1 do
    self.Image1.Canvas.Pixels[xoffset, I] := clRed;
end;

end.
