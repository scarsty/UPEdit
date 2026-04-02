unit Ict_50_33;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, head;

type
  TForm71 = class(TForm)
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Label1: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    RadioGroup1: TRadioGroup;
    Edit3: TEdit;
    Button1: TButton;
    Button2: TButton;
    Edit4: TEdit;
    Label2: TLabel;
    Edit5: TEdit;
    Label3: TLabel;
    Edit6: TEdit;
    Label4: TLabel;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure initial(atrb: Pattrib);
    procedure Drawpallet;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form71: TForm71;

implementation

{$R *.dfm}

procedure TForm71.Drawpallet;
var
  ix, iy, i1, i2, i: integer;
  wide : integer;
  TEMPBMP: tbitmap;
begin
  wide := 12;
  tempbmp := tbitmap.Create;
  tempbmp.Width := 16;
  tempbmp.Height := 16;
  tempbmp.PixelFormat := pf24bit;
  //if edittype = pic then
 // begin
    for i := 0 to Mcollen - 1 do
    begin
      iy := i div 16;
      ix := i mod 16;
      for i1 := ix * wide to ix * wide + wide - 1 do
        for i2 := iy * wide to iy * wide + wide - 1 do
        begin
          TEMPBMP.canvas.pixels[i1, i2] := McolB[I] shl 16 + McolG[I] shl 8 + McolR[I];
          {pos := tempbmp.ScanLine[i2];
          (pos + i1 * 3)^ := R[I];
          (pos + i1 * 3 + 1)^ := G[I];
          (pos + i1 * 3 + 2)^ := B[I];}
        end;
    end;
    image1.Canvas.CopyRect(image1.Canvas.ClipRect, tempbmp.Canvas, tempbmp.Canvas.ClipRect);
 // end;
    TEMPBMP.Free;
end;

procedure TForm71.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  temp1,temp2,temp3: smallint;
begin

  if radiogroup1.ItemIndex = 0 then
  begin
    edit1.Text := inttostr((Y div 12 * 16) + x div 12);
    temp1 := strtoint(edit1.Text);
    temp2 := strtoint(edit2.Text);
    temp3 := temp2 shl 8 + temp1;
    edit3.Text := inttostr(temp3);
    image2.Canvas.Brush.Color := McolB[temp1] shl 16 + McolG[temp1] + McolR[temp1];
    image2.Canvas.FillRect(image2.Canvas.ClipRect);
  end
  else
  begin
    edit2.Text := inttostr((Y div 12 * 16) + x div 12);
    temp1 := strtoint(edit1.Text);
    temp2 := strtoint(edit2.Text);
    temp3 := temp2 shl 8 + temp1;
    edit3.Text := inttostr(temp3);
    image3.Canvas.Brush.Color := McolB[temp2] shl 16 + McolG[temp2] + McolR[temp2];
    image3.Canvas.FillRect(image3.Canvas.ClipRect);
  end;
end;

procedure TForm71.initial(atrb: Pattrib);
var
  I,temp2,temp1: integer;
begin
  //
  drawpallet;
  if atrb.par[2] and 1 > 0 then
    checkbox1.Checked := true
  else
    checkbox1.Checked := false;
  if atrb.par[2] and 2 > 0 then
    checkbox2.Checked := true
  else
    checkbox2.Checked := false;
  edit4.Text := inttostr(atrb.par[3]);
  edit5.Text := inttostr(atrb.par[4]);
  edit6.Text := inttostr(atrb.par[5]);
  edit3.Text := inttostr(atrb.par[6]);
  if atrb.par[2] and 4 > 0 then
  begin
    edit1.Text := inttostr(atrb.par[6] and $FF);
    edit2.Text := inttostr((atrb.par[6] shr 8) and $FF);
    checkbox3.Checked := true;
  end
  else
  begin
    edit1.Text := '0';
    edit2.Text := '0';
    checkbox3.Checked := false;
  end;
  temp2 := strtoint(edit2.Text);
  image3.Canvas.Brush.Color := McolB[temp2] shl 16 + McolG[temp2] + McolR[temp2];
  image3.Canvas.FillRect(image3.Canvas.ClipRect);
  temp1 := strtoint(edit1.Text);
  image2.Canvas.Brush.Color := McolB[temp1] shl 16 + McolG[temp1] + McolR[temp1];
  image2.Canvas.FillRect(image2.Canvas.ClipRect);
end;

end.
