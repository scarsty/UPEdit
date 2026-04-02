unit Ict_70;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, head;

type
  TForm41 = class(TForm)
    Image1: TImage;
    Edit1: TEdit;
    Image2: TImage;
    Edit2: TEdit;
    Image3: TImage;
    RadioGroup1: TRadioGroup;
    Edit3: TEdit;
    Label1: TLabel;
    Button1: TButton;
    Button2: TButton;
    ComboBox1: TComboBox;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Drawpallet;
    procedure initial(atrb: Pattrib);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form41: TForm41;

implementation

uses
  kdefedit;

{$R *.dfm}

procedure TForm41.Drawpallet;
var
  ix, iy, i1, i2, i: integer;
  wide : integer;
  tempbmp:TBitmap;
begin
  wide := 12;
  tempbmp := tbitmap.Create;
  tempbmp.Width := 16;
  tempbmp.Height := 16;
  //tempbmp.PixelFormat := pf24bit;
  //if edittype = pic then
 // begin
    for i := 0 to 256 - 1 do
    begin
      iy := i div 16;
      ix := i mod 16;
      try
        tempbmp.canvas.pixels[ix, iy] := McolB[I] shl 16 + McolG[I] shl 8 + McolR[I];
          {pos := tempbmp.ScanLine[i2];
          (pos + i1 * 3)^ := R[I];
          (pos + i1 * 3 + 1)^ := G[I];
          (pos + i1 * 3 + 2)^ := B[I];}
      except

      end;

    end;
    image1.Canvas.CopyRect(image1.Canvas.ClipRect, tempbmp.Canvas, tempbmp.Canvas.ClipRect);
 // end;
   tempbmp.Free;
end;

procedure TForm41.FormCreate(Sender: TObject);
begin
  drawpallet;
end;

procedure TForm41.Image1MouseDown(Sender: TObject; Button: TMouseButton;
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

procedure TForm41.initial(atrb: Pattrib);
var
  I,temp2,temp1: integer;
begin
  //
  drawpallet;
  combobox1.Clear;
  for I := 0 to talkstrnum - 1 do
    combobox1.Items.Add(inttostr(I)+':'+ displaystr(readtalkstr(@talkstr[I])));
  combobox1.ItemIndex := atrb.par[1];
  edit3.Text := inttostr(atrb.par[2]);
  edit1.Text := inttostr(atrb.par[2] and $FF);
  edit2.Text := inttostr((atrb.par[2] shr 8) and $FF);
  temp2 := strtoint(edit2.Text);
  image3.Canvas.Brush.Color := McolB[temp2] shl 16 + McolG[temp2] + McolR[temp2];
  image3.Canvas.FillRect(image3.Canvas.ClipRect);
  temp1 := strtoint(edit1.Text);
  image2.Canvas.Brush.Color := McolB[temp1] shl 16 + McolG[temp1] + McolR[temp1];
  image2.Canvas.FillRect(image2.Canvas.ClipRect);
end;

end.
