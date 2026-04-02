unit grpedit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Buttons, StdCtrls, clipbrd, head, math;

type

  Tedittype = (pic, grp);

  TForm2 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    ScrollBox1: TScrollBox;
    Image1: TImage;
    Image2: TImage;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    Button1: TButton;
    Button2: TButton;
    ComboBox1: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    CheckBox1: TCheckBox;
    Button6: TButton;
    Button7: TButton;
    Button9: TButton;
    Button8: TButton;
    SpeedButton3: TSpeedButton;
    Label7: TLabel;
    Panel5: TPanel;
    Image3: TImage;
    Label8: TLabel;
    SpeedButton4: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure display;
    procedure Drawpallet;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Drawmove;
    procedure CheckBox1Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure Initial;
   // procedure Create(AOwner: TComponent); overload;
  private
    { Private declarations }
  public
    { Public declarations }
    tempindex: integer;
  end;

var
  Form2: TForm2;
  drawbmp: Tbitmap;
  edittype: Tedittype;
  zoom: integer = 1;
  tempBitMaP: TBitmap;
  nowcol: cardinal = $FFFFFF;
  tempB,tempG,tempR: array[0..255] of byte;
  tempcollen: integer;

  form2title: string = '贴图编辑';


procedure  RotateBitmap90Degrees(ABitmap:   TBitmap);
procedure  RotateBitmap270Degrees(ABitmap:   TBitmap);

implementation

{$R *.dfm}

uses
  takein, grplist;

procedure TForm2.Button1Click(Sender: TObject);
var
  MyFormat : Word;
  AData : THandle;
  APalette : HPALETTE;
begin
  drawbmp.SaveToClipBoardFormat(MyFormat, AData, APalette);
  ClipBoard.SetAsHandle(MyFormat,AData);
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  if clipboard.HasFormat(CF_BITMAP) then
    drawbmp.LoadFromClipboardFormat(cf_BitMap,ClipBoard.GetAsHandle(cf_Bitmap),0);
  display;
end;

procedure TForm2.Button3Click(Sender: TObject);
var
  I: integer;
begin
  if edittype = pic then
  begin
    can.Canvas.CopyRect(rect(takex,takey,picwidth + takex, picheight + takey), drawbmp.Canvas, drawbmp.Canvas.ClipRect);
  end
  else if edittype = grp then
  begin
    setlength(grppic[temppic].data, (drawbmp.Width + 2) * drawbmp.Height * 2 + 20);
    grppic[temppic].size := pictoRLE8(@(grppic[temppic].data[0]),drawbmp.Width, drawbmp.Height, xmove, ymove, @DrawBMP, drawbmp.Canvas.ClipRect, true, usualtrans);
    //setlength(grppic[temppic].data,grppic[temppic].size);
    needdraw := true;
    for I := 0 to 255 do
    begin
      //R[I] := tempR[I];
      //B[I] := tempB[I];
      //G[I] := tempG[I];
      copymemory(@R[0],@tempR[0],256);
      copymemory(@B[0],@tempB[0],256);
      copymemory(@G[0],@tempG[0],256);
    end;
    collen := tempcollen;
  end;
  self.Close;
end;

procedure TForm2.Button4Click(Sender: TObject);
var
  tempcol1: cardinal;
  tempstr:string;
begin
  //canvas的颜色顺序是BGR,而游戏中顺序是RGB
  tempcol1 := (nowcol and $FF0000) shr 16 + nowcol and $FF00 + (nowcol and $FF) shl 16;
  tempstr := inputbox('自定义颜色','请以十六进制方式输入（RGB）',Format('%x',[tempcol1]));
  if strtoint('$' + tempstr) <> tempcol1 then
  begin
    tempcol1 := strtoint('$' + tempstr);
    nowcol := (tempcol1 and $FF0000) shr 16 + tempcol1 and $FF00 + (tempcol1 and $FF) shl 16;
    image3.Canvas.Brush.Color := nowcol;
    image3.Canvas.FillRect(image3.Canvas.ClipRect);
  end;
end;

procedure TForm2.Button5Click(Sender: TObject);
var
  tempw,temph, oriw,orih, ix, iy: integer;
begin
  tempw := strtoint(edit1.Text);
  temph := strtoint(edit2.Text);
  xmove := strtoint(edit3.text);
  ymove := strtoint(edit4.text);
  oriw := drawbmp.Width;
  orih := drawbmp.Height;
  drawbmp.Width := tempw;
  if tempw > oriw then
    for Ix := oriw to tempw - 1 do
      for iy := 0 to drawbmp.Height - 1 do
        drawbmp.Canvas.Pixels[ix, iy] := usualtrans;
  drawbmp.Height := temph;
  if temph > orih then
    for iy := orih to temph - 1 do
      for ix := 0 to drawbmp.Width - 1 do
        drawbmp.Canvas.Pixels[ix, iy] := usualtrans;
  display;
end;

procedure TForm2.Button6Click(Sender: TObject);
var
  tempbmp: TBitmap;
begin
  tempbmp := TBitmap.Create;
  tempbmp.Width := drawbmp.Width;
  tempbmp.Height := drawbmp.Height;
  tempbmp.Canvas.CopyRect(Rect(0,0,tempbmp.Width,tempbmp.Height), drawbmp.Canvas, Rect(drawbmp.Width - 1,0,-1,drawbmp.Height));
  drawbmp.Canvas.CopyRect(drawbmp.Canvas.ClipRect, tempbmp.Canvas, tempbmp.Canvas.ClipRect);
  tempbmp.Free;

  display;
end;

procedure TForm2.Button7Click(Sender: TObject);
var
  tempbmp: TBitmap;
begin
  tempbmp := TBitmap.Create;
  tempbmp.Width := drawbmp.Width;
  tempbmp.Height := drawbmp.Height;
  tempbmp.Canvas.CopyRect(Rect(0,0,tempbmp.Width,tempbmp.Height), drawbmp.Canvas, Rect(0,drawbmp.Height - 1,drawbmp.Width,-1));
  drawbmp.Canvas.CopyRect(drawbmp.Canvas.ClipRect, tempbmp.Canvas, tempbmp.Canvas.ClipRect);
  tempbmp.Free;
  display;
end;

procedure TForm2.Button8Click(Sender: TObject);
var
  tempint: integer;
begin
  RotateBitmap90Degrees(drawbmp);
  tempint := xmove;
  xmove := ymove;
  ymove := tempint;
  edit1.Text := inttostr(drawbmp.Width);
  edit2.text := inttostr(drawbmp.Height);
  edit3.Text := inttostr(xmove);
  edit4.Text := inttostr(ymove);
  display;
end;

procedure TForm2.Button9Click(Sender: TObject);
var
  tempint: integer;
begin
  RotateBitmap270Degrees(drawbmp);
  tempint := xmove;
  xmove := ymove;
  ymove := tempint;
  edit1.Text := inttostr(drawbmp.Width);
  edit2.text := inttostr(drawbmp.Height);
  edit3.Text := inttostr(xmove);
  edit4.Text := inttostr(ymove);
  display;
end;

procedure  RotateBitmap90Degrees(ABitmap: TBitmap);

const
    BITMAP_HEADER_SIZE   =   SizeOf(TBitmapFileHeader)   +
SizeOf(TBitmapInfoHeader);

var
    {   Things   that   end   in   R   are   for   the   rotated   image.   }
    PbmpInfoR:   PBitmapInfoHeader;
    bmpBuffer,   bmpBufferR:   PByte;
    MemoryStream,   MemoryStreamR:   TMemoryStream;
    PbmpBuffer,   PbmpBufferR:   PByte;
    PbmpBufferRFirstScanLine,   PbmpBufferColumnZero:   PByte;
    BytesPerPixel,   BytesPerScanLine,   BytesPerScanLineR:   Integer;
    X,   Y,   T:   Integer;

begin
    {
        Don 't   *ever*   call   GetDIBSizes!   It   screws   up   your   bitmap.
        I 'll   be   posting   about   that   shortly.
    }

    MemoryStream   :=   TMemoryStream.Create;

    {
      To   do:   Put   in   a   SetSize,   which   will   eliminate   any   reallocation
      overhead.
    }

    ABitmap.SaveToStream(MemoryStream);

    {
      Don 't   need   you   anymore.   We 'll   make   a   new   one   when   the   time   comes.
    }
    ABitmap.Free;

    bmpBuffer   :=   MemoryStream.Memory;

    {   Set   PbmpInfoR   to   point   to   the   source   bitmap 's   info   header.   }
    {   Boy,   these   headers   are   getting   annoying.   }
    Inc(   bmpBuffer,   SizeOf(TBitmapFileHeader)   );
    PbmpInfoR   :=   PBitmapInfoHeader(bmpBuffer);

    {   Set   bmpBuffer   to   point   to   the   original   bitmap   bits.   }
    Inc(bmpBuffer,   SizeOf(PbmpInfoR^));
    {   Set   the   ColumnZero   pointer   to   point   to,   uh,   column   zero.   }
    PbmpBufferColumnZero   :=   bmpBuffer;

    with   PbmpInfoR^   do
    begin
        BytesPerPixel   :=   biBitCount   shr   3;
        {   ScanLines   are   DWORD   aligned.   }
        BytesPerScanLine   :=   ((((biWidth   *   biBitCount)   +   31)   div   32)   *   SizeOf(DWORD));
        BytesPerScanLineR   :=   ((((biHeight   *   biBitCount)   +   31)   div   32)   *   SizeOf(DWORD));

        {   The   TMemoryStream   that   will   hold   the   rotated   bits.   }
        MemoryStreamR   :=   TMemoryStream.Create;
        {
          Set   size   for   rotated   bitmap.   Might   be   different   from   source   size
          due   to   DWORD   aligning.
        }
        MemoryStreamR.SetSize(BITMAP_HEADER_SIZE     +   BytesPerScanLineR   *   biWidth);
    end;

    {   Copy   the   headers   from   the   source   bitmap.   }
    MemoryStream.Seek(0,   soFromBeginning);
    MemoryStreamR.CopyFrom(MemoryStream,   BITMAP_HEADER_SIZE);

    {   Here 's   the   buffer   we 're   going   to   rotate.   }
    bmpBufferR   :=   MemoryStreamR.Memory;
    {   Skip   the   headers,   yadda   yadda   yadda...   }
    Inc(bmpBufferR,   BITMAP_HEADER_SIZE);

    {
      Set   up   PbmpBufferRFirstScanLine   and   advance   it   to   end   of   the   first   scan
      line   of   bmpBufferR.
    }
    PbmpBufferRFirstScanLine   :=   bmpBufferR;
    Inc(PbmpBufferRFirstScanLine,   (PbmpInfoR^.biHeight   -   1)   *   BytesPerPixel);

    {   Here 's   the   meat.   Loop   through   the   pixels   and   rotate   appropriately.   }

    {   Remember   that   DIBs   have   their   origins   opposite   from   DDBs.   }
    for   Y   :=   1   to   PbmpInfoR^.biHeight   do
    begin
        PbmpBuffer   :=   PbmpBufferColumnZero;
        PbmpBufferR   :=   PbmpBufferRFirstScanLine;

        for   X   :=   1   to   PbmpInfoR^.biWidth   do
        begin
            for   T   :=   1   to   BytesPerPixel   do
            begin
                PbmpBufferR^   :=   PbmpBuffer^;
                Inc(PbmpBufferR);
                Inc(PbmpBuffer);
            end;
            Dec(PbmpBufferR,   BytesPerPixel);
            Inc(PbmpBufferR,   BytesPerScanLineR);
        end;

        Inc(PbmpBufferColumnZero,   BytesPerScanLine);
        Dec(PbmpBufferRFirstScanLine,   BytesPerPixel);
    end;

    {   Done   with   the   source   bits.   }
    MemoryStream.Free;

    {   Now   set   PbmpInfoR   to   point   to   the   rotated   bitmap 's   info   header.   }
    PbmpBufferR   :=   MemoryStreamR.Memory;
    Inc(   PbmpBufferR,   SizeOf(TBitmapFileHeader)   );
    PbmpInfoR   :=   PBitmapInfoHeader(PbmpBufferR);

    {   Swap   the   width   and   height   of   the   rotated   bitmap 's   info   header.   }
    with   PbmpInfoR^   do
    begin
        T   :=   biHeight;
        biHeight   :=   biWidth;
        biWidth   :=   T;
    end;

    ABitmap   :=   TBitmap.Create;

    {   Spin   back   to   the   very   beginning.   }
    MemoryStreamR.Seek(0,   soFromBeginning);
    ABitmap.LoadFromStream(MemoryStreamR);

    MemoryStreamR.Free;
end;

procedure  RotateBitmap270Degrees(ABitmap:   TBitmap);

const
    BITMAP_HEADER_SIZE   =   SizeOf(TBitmapFileHeader)   +
SizeOf(TBitmapInfoHeader);

var
    {   Things   that   end   in   R   are   for   the   rotated   image.   }
    PbmpInfoR:   PBitmapInfoHeader;
    bmpBuffer,   bmpBufferR:   PByte;
    MemoryStream,   MemoryStreamR:   TMemoryStream;
    PbmpBuffer,   PbmpBufferR:   PByte;
    PbmpBufferRFirstScanLine,   PbmpBufferColumnZero:   PByte;
    BytesPerPixel,   BytesPerScanLine,   BytesPerScanLineR:   Integer;
    X,   Y,   T:   Integer;

begin
    {
        Don 't   *ever*   call   GetDIBSizes!   It   screws   up   your   bitmap.
        I 'll   be   posting   about   that   shortly.
    }

    MemoryStream   :=   TMemoryStream.Create;

    {
      To   do:   Put   in   a   SetSize,   which   will   eliminate   any   reallocation
      overhead.
    }

    ABitmap.SaveToStream(MemoryStream);

    {
      Don 't   need   you   anymore.   We 'll   make   a   new   one   when   the   time   comes.
    }
    ABitmap.Free;

    bmpBuffer   :=   MemoryStream.Memory;

    {   Set   PbmpInfoR   to   point   to   the   source   bitmap 's   info   header.   }
    {   Boy,   these   headers   are   getting   annoying.   }
    Inc(   bmpBuffer,   SizeOf(TBitmapFileHeader)   );
    PbmpInfoR   :=   PBitmapInfoHeader(bmpBuffer);

    {   Set   bmpBuffer   to   point   to   the   original   bitmap   bits.   }
    Inc(bmpBuffer,   SizeOf(PbmpInfoR^));
    {   Set   the   ColumnZero   pointer   to   point   to,   uh,   column   zero.   }
     PbmpBufferRFirstScanLine :=   bmpBuffer;

    with   PbmpInfoR^   do
    begin
        BytesPerPixel   :=   biBitCount   shr   3;
        {   ScanLines   are   DWORD   aligned.   }
        BytesPerScanLine   :=   ((((biWidth   *   biBitCount)   +   31)   div   32)   *   SizeOf(DWORD));
        BytesPerScanLineR   :=   ((((biHeight   *   biBitCount)   +   31)   div   32)   *   SizeOf(DWORD));

        {   The   TMemoryStream   that   will   hold   the   rotated   bits.   }
        MemoryStreamR   :=   TMemoryStream.Create;
        {
          Set   size   for   rotated   bitmap.   Might   be   different   from   source   size
          due   to   DWORD   aligning.
        }
        MemoryStreamR.SetSize(BITMAP_HEADER_SIZE     +   BytesPerScanLineR   *   biWidth);
    end;

    {   Copy   the   headers   from   the   source   bitmap.   }
    MemoryStream.Seek(0,   soFromBeginning);
    MemoryStreamR.CopyFrom(MemoryStream,   BITMAP_HEADER_SIZE);

    {   Here 's   the   buffer   we 're   going   to   rotate.   }
    bmpBufferR   :=   MemoryStreamR.Memory;
    {   Skip   the   headers,   yadda   yadda   yadda...   }
    Inc(bmpBufferR,   BITMAP_HEADER_SIZE);

    {
      Set   up   PbmpBufferRFirstScanLine   and   advance   it   to   end   of   the   first   scan
      line   of   bmpBufferR.
    }
    PbmpBufferColumnZero   :=   bmpBufferR;
    Inc(PbmpBufferColumnZero,   (PbmpInfoR^.biWidth   -   1)   *   BytesPerScanLineR);

    {   Here 's   the   meat.   Loop   through   the   pixels   and   rotate   appropriately.   }

    {   Remember   that   DIBs   have   their   origins   opposite   from   DDBs.   }
    for   Y   :=   1   to   PbmpInfoR^.biHeight   do
    begin
        PbmpBufferR   :=   PbmpBufferColumnZero;
        PbmpBuffer   :=   PbmpBufferRFirstScanLine;

        for   X   :=   1   to   PbmpInfoR^.biWidth   do
        begin
            for   T   :=   1   to   BytesPerPixel   do
            begin
                PbmpBufferR^   :=  PbmpBuffer^;
                Inc(PbmpBufferR);
                Inc(PbmpBuffer);
            end;
            Dec(PbmpBufferR,   BytesPerPixel);
            dec(PbmpBufferR,   BytesPerScanLineR);
            //dec(PbmpBuffer,  BytesPerPixel * 2);
        end;

        Inc(PbmpBufferColumnZero,  BytesPerPixel );
        inc(PbmpBufferRFirstScanLine,   BytesPerScanLine);
    end;

    {   Done   with   the   source   bits.   }
    MemoryStream.Free;

    {   Now   set   PbmpInfoR   to   point   to   the   rotated   bitmap 's   info   header.   }
    PbmpBufferR   :=   MemoryStreamR.Memory;
    Inc(   PbmpBufferR,   SizeOf(TBitmapFileHeader)   );
    PbmpInfoR   :=   PBitmapInfoHeader(PbmpBufferR);

    {   Swap   the   width   and   height   of   the   rotated   bitmap 's   info   header.   }
    with   PbmpInfoR^   do
    begin
        T   :=   biHeight;
        biHeight   :=   biWidth;
        biWidth   :=   T;
    end;

    ABitmap   :=   TBitmap.Create;

    {   Spin   back   to   the   very   beginning.   }
    MemoryStreamR.Seek(0,   soFromBeginning);
    ABitmap.LoadFromStream(MemoryStreamR);

    MemoryStreamR.Free;
end;



procedure TForm2.CheckBox1Click(Sender: TObject);
begin
  display;
end;

procedure TForm2.ComboBox1Change(Sender: TObject);
begin
  case combobox1.ItemIndex of
    0:
      zoom := 1;
    1:
      zoom := 2;
    2:
      zoom := 4;
    3:
      zoom := 8;
    4:
      zoom := 16;
  end;
  display;
end;

procedure TForm2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  drawbmp.Free;
  tempBitMaP.Free;
  //Action := caFree;
end;

procedure TForm2.Initial;
begin
  tempindex := 0;
  image1.Width := drawbmp.Width;
  image1.Picture.Bitmap.Width := drawbmp.Width;
  image1.Height := drawbmp.Height;
  image1.Picture.Bitmap.Height := drawbmp.Height;
  if edittype = grp then
  begin
    panel2.Visible := true;
    label7.Caption := '为与游戏调色板颜色区分，透明色仍使用墨绿色背景。';
    speedbutton4.Visible := true;
  end
  else
  begin
    label7.Caption := '';
    speedbutton4.Visible := false;
  end;

  zoom := 1;
  display;
  image2.Canvas.Brush.Color := clwhite;
  image2.Canvas.FillRect(image2.Canvas.ClipRect);
  Drawpallet;
  image3.Canvas.Brush.Color := nowcol;
  image3.Canvas.FillRect(image3.Canvas.ClipRect);
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  //self.Visible := false;
end;

procedure TForm2.FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  ComboBox1.SetFocus;
  Combobox1.ItemIndex := max(Combobox1.ItemIndex - 1, 0);
  ComboBox1Change(Sender);
  Handled := true;
end;

procedure TForm2.FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  ComboBox1.SetFocus;
  Combobox1.ItemIndex := Combobox1.ItemIndex + 1;
  ComboBox1Change(Sender);
  Handled := true;
end;

procedure TForm2.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i1,i2,ix,iy: integer;
  PD: array of byte;
  tempcol: cardinal;
begin
  if speedbutton2.Down then
  begin
    nowcol := image1.Canvas.Pixels[x,y];
    image3.Canvas.Brush.Color := nowcol;
    image3.Canvas.FillRect(image3.Canvas.ClipRect);
  end
  else if speedbutton1.Down then
  begin
    drawbmp.Canvas.Pixels[x div zoom, y div zoom] := nowcol;
    //display;
    ix := x div zoom;
    iy := y div zoom;
    for i1 := ix * zoom to ix * zoom + zoom - 1 do
      for i2 := iy * zoom to iy * zoom + zoom - 1 do
        image1.Canvas.Pixels[i1, i2] := nowcol;
  end
  else if speedbutton3.Down then
  begin
    if button = mbLeft then
    begin
      nowcol := image1.Canvas.Pixels[x,y];
      image3.Canvas.Brush.Color := nowcol;
      image3.Canvas.FillRect(image3.Canvas.ClipRect);
    end
    else if button = mbRight then
    begin
      drawbmp.Canvas.Pixels[x div zoom, y div zoom] := nowcol;
      //display;
      ix := x div zoom;
      iy := y div zoom;
      for i1 := ix * zoom to ix * zoom + zoom - 1 do
        for i2 := iy * zoom to iy * zoom + zoom - 1 do
          image1.Canvas.Pixels[i1, i2] := nowcol;
    end;
  end
  else if speedbutton4.Down then
  begin
    tempcol := image1.Canvas.Pixels[x,y];
    tempcol := tempcol and $FFFFFF;
    setlength(PD, drawbmp.Width * 3);
    for Iy := 0 to drawbmp.height - 1 do
    begin
      copymemory(@PD[0],drawbmp.ScanLine[iy], drawbmp.Width * 3);
      for Ix := 0 to drawbmp.Width - 1 do
        if tempcol = (PD[ix * 3] shl 16 + PD[ix * 3 + 1] shl 8 + PD[ix * 3 + 2]) then
        begin
          PD[ix * 3] := byte(usualtrans shr 16 and $FF);
          PD[ix * 3 + 1] := byte(usualtrans shr 8 and $FF);
          PD[ix * 3 + 2] := byte(usualtrans and $FF);
        end;
      copymemory(drawbmp.ScanLine[iy],@PD[0], drawbmp.Width * 3);
    end;
    setlength(PD, 0);
    image1.Canvas.CopyRect(image1.Canvas.ClipRect, drawbmp.Canvas,drawbmp.Canvas.ClipRect);
  end;
end;

procedure TForm2.Image2MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if ((y div 16) * 12 + x div 16 < collen) then
  begin
    nowcol := image2.Canvas.Pixels[x,y];
    image3.Canvas.Brush.Color := nowcol;
    image3.Canvas.FillRect(image3.Canvas.ClipRect);
  end;
end;

procedure TForm2.SpeedButton3Click(Sender: TObject);
begin
  if SpeedButton3.Down then
  begin
    image1.Hint := '鼠标左键拾取，右键绘图';
    image1.ShowHint := true;
  end
  else
  begin
    image1.Hint := '';
    image1.ShowHint := false;
  end;
end;

procedure TForm2.display;
var
  ix, iy, i1, i2: integer;
  tempcol: cardinal;
  Pos, pos2: Pbyte;
  c1,c2,c3: byte;
begin
  //
  image1.Width := drawbmp.Width * zoom;
  image1.Picture.Bitmap.Width := drawbmp.Width * zoom;
  image1.Height := drawbmp.Height * zoom;
  image1.Picture.Bitmap.Height := drawbmp.Height * zoom;
  {tempbitmap := Tbitmap.Create;
  tempbitmap.width := image1.Picture.Bitmap.Width;
  tempbitmap.height := image1.Picture.Bitmap.Height;
  tempbitmap.PixelFormat := pf24bit;
  drawbmp.PixelFormat := pf24bit;
  for ix := 0 to drawbmp.Width - 1 do
    for iy := 0 to drawbmp.Height - 1 do
    begin
      pos := drawbmp.ScanLine[iY];
      pos := pos + iX * 3;
      c1 := (pos)^;
      c2 := (pos + 1)^;
      c3 := (pos + 2)^;
      for i1 := ix * zoom to ix * zoom + zoom - 1 do
         for i2 := iy * zoom to iy * zoom + zoom - 1 do
         begin
           pos := tempbitmap.ScanLine[i2];
           pos := pos + i1 * 3;
           (pos)^ := c1;
           (pos + 1)^ := c2;
           (pos + 2)^ := c3;
           //tempbitmap.Canvas.Pixels[i1,  i2] := tempcol;
           //(tempbitmap.ScanLine[i2] + i1)^ := tempcol;
         end;
    end;
  image1.Canvas.CopyRect(image1.Canvas.ClipRect, tempbitmap.canvas, tempbitmap.canvas.cliprect);
  tempbitmap.Free; }
  image1.Canvas.CopyRect(image1.Canvas.ClipRect,drawbmp.Canvas,drawbmp.Canvas.ClipRect);
  if (edittype = grp) and (checkbox1.Checked) then
    Drawmove;
end;

procedure TForm2.Drawmove;
var
  ix,iy: integer;
  i1,i2: integer;
begin
  for Ix := 0 to drawbmp.Width - 1 do
    for i1 := 0 to zoom - 1 do
      for i2 := 0 to zoom - 1 do
        image1.Canvas.Pixels[ix * zoom + i1, ymove * zoom + i2] := clred;
  for Iy := 0 to drawbmp.Height - 1 do
    for i1 := 0 to zoom - 1 do
      for i2 := 0 to zoom - 1 do
        image1.Canvas.Pixels[xmove * zoom + i1, iy * zoom + i2] := clred;
end;

procedure TForm2.Drawpallet;
var
  ix, iy, i: integer;
  wide : integer;
  tempbmp: TBitmap;
begin
  wide := 1;
  //tempbmp := tbitmap.Create;
  //tempbmp.Width := wide * 16;
  //tempbmp.Height := wide * 16;
  //tempbmp.PixelFormat := pf24bit;
  //if edittype = pic then
 // begin
 tempbmp := TBitmap.Create;
 tempbmp.Width := 16;
 tempbmp.Height := 16;
    for i := 0 to collen - 1 do
    begin
      iy := i div 16;
      ix := i mod 16;
      tempbmp.canvas.pixels[ix, iy] := B[I] shl 16 + G[I] shl 8 + R[I];
          {pos := tempbmp.ScanLine[i2];
          (pos + i1 * 3)^ := R[I];
          (pos + i1 * 3 + 1)^ := G[I];
          (pos + i1 * 3 + 2)^ := B[I];}
    end;
    image2.Canvas.CopyRect(image2.Canvas.ClipRect, tempbmp.Canvas, tempbmp.Canvas.ClipRect);
    //image2.Canvas.CopyRect(image1.Canvas.ClipRect, tempbmp.Canvas, tempbmp.Canvas.ClipRect);
 // end;
   tempbmp.Free;
end;

end.
