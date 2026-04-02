unit picedit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, head, PNGimage, JPEG, Spin, math,
  clipbrd, FileCtrl, GIFimg, ComCtrls;

type

  TForm4 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    ScrollBox1: TScrollBox;
    Image2: TImage;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Panel3: TPanel;
    Image1: TImage;
    panel4: TPanel;
    Button1: TButton;
    OpenDialog1: TOpenDialog;
    SpinEdit1: TSpinEdit;
    Label1: TLabel;
    SpinEdit2: TSpinEdit;
    Label2: TLabel;
    SpinEdit3: TSpinEdit;
    Label3: TLabel;
    CheckBox1: TCheckBox;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    SaveDialog1: TSaveDialog;
    Button8: TButton;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    Image4: TImage;
    Button9: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    Button10: TButton;
    Button11: TButton;
    Panel5: TPanel;
    ProgressBar1: TProgressBar;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);

    procedure Readnowpictobmp;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure bmptoimage;
    procedure drawSmallimg;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: integer);
    procedure Image1Click(Sender: TObject);
    procedure drawpos(X, Y: integer);
    procedure Image2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure SpinEdit2Change(Sender: TObject);
    procedure SpinEdit3Change(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure Image1MouseLeave(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure copypic(AFrom, ATo: integer);
    procedure savetodata(PBMP: pntbitmap);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Image2MouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: integer);
    procedure Button10Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure addlast;
    procedure Addone;
    procedure openfile(filename: string);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  PForm4 = ^TFOrm4;


var
  picdata: array of Tpicdata;
  picnum: integer;
  nowmainpicnum: integer = -1;
  nowsmallpicnum: integer = 0;
  bufpic, smallbufpic: Tbitmap;
  smallimgbuf: integer = -1;
  pictranscol: cardinal = $FFFFFF;
  CLIPTRANS: boolean = false;
  ID: integer;

function calPNG(Pdata: Pbyte): integer;


implementation

{$R *.dfm}

uses
  main;

procedure TForm4.Button10Click(Sender: TObject);
var
  a, b, temp, I: integer;
begin
  a := strtoint(Edit1.Text);
  b := strtoint(Edit2.Text);
  if a > b then
  begin
    temp := a;
    a := b;
    b := temp;
  end;
  for I := a to b do
  begin
    if (I < 0) or (I >= picnum) then
      continue;
    picdata[I].xs := SpinEdit2.Value;
    picdata[I].ys := SpinEdit3.Value;
  end;
end;

procedure TForm4.Button11Click(Sender: TObject);
begin
  Edit1.Text := '0';
  Edit2.Text := inttostr(picnum - 1);
end;

procedure TForm4.Button1Click(Sender: TObject);
begin
  OpenDialog1.Filter := 'Pic files (*.Pic)|*.Pic|All files (*.*)|*.*';
  if OpenDialog1.Execute then
  begin
    openfile(opendialog1.FileName);
  end;
end;

procedure TForm4.openfile(filename: string);
var
  I, PF: integer;
  offset: array of integer;
begin
  picnum := 0;
  PF := fileopen(filename, fmopenread);
  fileread(PF, picnum, 4);
  setlength(offset, picnum);
  fileread(PF, offset[0], picnum * 4);
  setlength(picdata, picnum);
  if picnum > 0 then
  begin
    fileread(PF, picdata[0].xs, 4);
    fileread(PF, picdata[0].ys, 4);
    fileread(PF, picdata[0].blackground, 4);
    picdata[0].datasize := max(offset[0] - picnum * 4 - 4 - 12, 0);
    setlength(picdata[0].data, picdata[0].datasize);
    if picdata[0].datasize > 0 then
      fileread(PF, picdata[0].data[0], picdata[0].datasize);
    try
      picdata[0].pictype := calPNG(@(picdata[0].data[0]));
    except
      picdata[0].pictype := 0;
    end;
    for I := 1 to picnum - 1 do
    begin
      fileread(PF, picdata[I].xs, 4);
      fileread(PF, picdata[I].ys, 4);
      fileread(PF, picdata[I].blackground, 4);
      picdata[I].datasize := max(offset[I] - offset[I - 1] - 12, 0);
      setlength(picdata[I].data, picdata[I].datasize);
      if picdata[I].datasize > 0 then
        fileread(PF, picdata[I].data[0], picdata[I].datasize);
      picdata[I].pictype := calPNG(@(picdata[I].data[0]));
    end;
    fileclose(PF);
  end;
  SpinEdit1.MaxValue := picnum - 1;
  SpinEdit2.Value := picdata[0].xs;
  SpinEdit3.Value := picdata[0].ys;
  if picdata[0].blackground = 1 then
    CheckBox1.Checked := true
  else
    CheckBox1.Checked := false;
  CLIPTRANS := false;
  nowmainpicnum := 0;
  nowsmallpicnum := 0;
  drawSmallimg;
  Image2.Canvas.Brush.Color := clwhite;
  Image2.Canvas.FillRect(Image2.Canvas.ClipRect);
  Readnowpictobmp;
  drawpos(picdata[0].xs, picdata[0].ys);
end;


procedure TForm4.Button2Click(Sender: TObject);
var
  MyFormat: Word;
  AData: THandle;
  APalette: HPALETTE;
begin
  if picnum > 0 then
  begin
    bufpic.SaveToClipBoardFormat(MyFormat, AData, APalette);
    ClipBoard.SetAsHandle(MyFormat, AData);
  end;
end;

procedure TForm4.Button3Click(Sender: TObject);
begin
  if picnum > 0 then
  begin
    if ClipBoard.HasFormat(CF_BITMAP) then
    begin
      bufpic.LoadFromClipboardFormat(CF_BITMAP,
        ClipBoard.GetAsHandle(CF_BITMAP), 0);
      CLIPTRANS := false;
      picdata[nowmainpicnum].xs := 0;
      picdata[nowmainpicnum].ys := 0;
      picdata[nowmainpicnum].blackground := 0;
      picdata[nowmainpicnum].pictype := 1;
      savetodata(@bufpic);
      drawSmallimg;
      Image2.Canvas.Brush.Color := clwhite;
      Image2.Canvas.FillRect(Image2.Canvas.ClipRect);
      Readnowpictobmp;
      drawpos(picdata[nowmainpicnum].xs, picdata[nowmainpicnum].ys);
    end;
  end;
end;

procedure TForm4.Button4Click(Sender: TObject);

begin
  addone;
  //T1.execute;
end;

procedure TForm4.Button5Click(Sender: TObject);
begin
  addlast;
  //T1.execute;
end;

procedure TForm4.Button6Click(Sender: TObject);
var
  I: integer;
begin
  if picnum > 0 then
  begin
    for I := nowmainpicnum to picnum - 2 do
      copypic(I + 1, I);
    dec(picnum);
    setlength(picdata, picnum);
    drawSmallimg;
    Image2.Canvas.Brush.Color := clwhite;
    Image2.Canvas.FillRect(Image2.Canvas.ClipRect);
    Readnowpictobmp;
    SpinEdit1.Value := nowmainpicnum;
    SpinEdit2.Value := picdata[nowmainpicnum].xs;
    SpinEdit3.Value := picdata[nowmainpicnum].ys;
    if picdata[nowmainpicnum].blackground = 1 then
      CheckBox1.Checked := true
    else
      CheckBox1.Checked := false;
    drawpos(picdata[nowmainpicnum].xs, picdata[nowmainpicnum].ys);
  end;
end;

procedure TForm4.Button7Click(Sender: TObject);
var
  picF: integer;
  filename: string;
begin
  if picnum > 0 then
  begin
    if picdata[nowmainpicnum].pictype = 1 then
      SaveDialog1.Filter := '*.PNG|*.Png'
    else
      SaveDialog1.Filter := '*.JPG|*.JPG';
    if SaveDialog1.Execute then
    begin
      filename := savedialog1.FileName;
      if picdata[nowmainpicnum].pictype = 1 then
        if not SameText(ExtractFileExt(SaveDialog1.filename), '.png') then
          filename := SaveDialog1.filename + '.png';
      if picdata[nowmainpicnum].pictype = 0 then
        if not(SameText(ExtractFileExt(SaveDialog1.filename),
            '.jpg') or SameText(ExtractFileExt(OpenDialog1.filename),
            '.jepg')) then
          filename := SaveDialog1.filename + '.jpg';
      picF := filecreate(filename);
      filewrite(picF, picdata[nowmainpicnum].data[0],
        picdata[nowmainpicnum].datasize);
      fileclose(picF);
    end;
  end;
end;

procedure TForm4.Button8Click(Sender: TObject);
var
  I, PF, pfka: integer;
  dir, filename: string;
  ka:smallint;
begin
  if picnum > 0 then
  begin
    if SelectFolderDialog(self.Handle,'选择保存文件夹', dir, dir) then
    begin
      if dir[length(dir)] <> '\' then
        dir := dir + '\';
      pfka:= filecreate(dir+'index.ka');
      for I := 0 to picnum - 1 do
      begin
        if picdata[I].pictype = 1 then
          filename := dir + inttostr(I) + '.png'
        else
          filename := dir + inttostr(I) + '.jpg';
        PF := filecreate(filename);
        filewrite(PF, picdata[I].data[0], picdata[I].datasize);
        fileclose(PF);
        ka:= picdata[I].xs;
        filewrite(pfka,ka,2);
        ka:= picdata[I].ys;
        filewrite(pfka,ka,2);
      end;
      fileclose(pfka);
    end;
  end;
end;

procedure TForm4.Button9Click(Sender: TObject);
var
  I, PF, len, headlen: integer;
  offset: array of integer;
  filename: string;
begin
  if picnum > 0 then
  begin
    SaveDialog1.Filter := '*.pic|*.pic';
    if SaveDialog1.Execute then
    begin
      filename := SaveDialog1.filename;
      if not SameText(ExtractFileExt(filename), '.pic') then
        filename := filename + '.pic';
      setlength(offset, picnum);
      headlen := picnum * 4 + 4;
      len := headlen;
      PF := filecreate(filename);
      filewrite(PF, picnum, 4);
      for I := 0 to picnum - 1 do
      begin
        inc(len, picdata[I].datasize + 12);
        offset[I] := len;
        filewrite(PF, offset[I], 4);
      end;
      for I := 0 to picnum - 1 do
      begin
        filewrite(PF, picdata[I].xs, 4);
        filewrite(PF, picdata[I].ys, 4);
        filewrite(PF, picdata[I].blackground, 4);
        filewrite(PF, picdata[I].data[0], picdata[I].datasize);
      end;
      fileclose(PF);
    end;
  end;

end;

procedure TForm4.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  picnum:= 0;
  setlength(picdata,picnum);
  CForm4 := true;
  bufpic.Free;
  smallbufpic.Free;
  Action := cafree;
end;

procedure TForm4.FormCreate(Sender: TObject);
begin
  bufpic := Tbitmap.create;
  // bufpic.Width := image2.Width;
  // bufpic.Height := image2.Height;
  smallbufpic := Tbitmap.create;
  smallbufpic.Width := Image1.Width;
  smallbufpic.Height := Image1.Height;
  
end;

procedure TForm4.FormResize(Sender: TObject);
begin
  Image2.Picture.Bitmap.Width := Image2.Width;
  Image2.Picture.Bitmap.Height := Image2.Height;
  // bufpic.Width := image2.Width;
  // bufpic.Height := image2.Height;
  if picnum > 0 then
  begin
    Image2.Canvas.Brush.Color := clwhite;
    Image2.Canvas.FillRect(Image1.Canvas.ClipRect);
    Readnowpictobmp;
    drawpos(picdata[nowmainpicnum].xs, picdata[nowmainpicnum].ys);
  end;
end;

procedure TForm4.Image1Click(Sender: TObject);
begin
  if picnum > 0 then
    if (smallimgbuf + nowsmallpicnum <> nowmainpicnum) and
      (smallimgbuf + nowsmallpicnum < picnum) then
    begin
      nowmainpicnum := smallimgbuf + nowsmallpicnum;
      SpinEdit1.Value := nowmainpicnum;
      Image2.Canvas.Brush.Color := clwhite;
      Image2.Canvas.FillRect(Image2.Canvas.ClipRect);
      Readnowpictobmp;
      SpinEdit2.Value := picdata[nowmainpicnum].xs;
      SpinEdit3.Value := picdata[nowmainpicnum].ys;
      if picdata[nowmainpicnum].blackground = 1 then
        CheckBox1.Checked := true
      else
        CheckBox1.Checked := false;
      drawpos(picdata[nowmainpicnum].xs, picdata[nowmainpicnum].ys);
    end;
end;

procedure TForm4.Image1MouseLeave(Sender: TObject);
begin
  smallimgbuf := -1;
end;

procedure TForm4.Image1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: integer);
var
  I, temp: integer;
begin
  if picnum > 0 then
  begin
    temp := X div (Image1.Width div 6);
    if temp <> smallimgbuf then
    begin
      smallimgbuf := temp;

      Image1.Canvas.CopyRect(Image1.Canvas.ClipRect, smallbufpic.Canvas,
        smallbufpic.Canvas.ClipRect);
      for I := 0 to Image1.Height - 1 do
      begin
        Image1.Canvas.Pixels[temp * Image1.Width div 6, I] := clred;
        Image1.Canvas.Pixels[(temp + 1) * Image1.Width div 6 - 1, I] := clred;
      end;
      for I := (temp * Image1.Width div 6) to
        ((temp + 1) * Image1.Width div 6 - 1) do
      begin
        Image1.Canvas.Pixels[I, 0] := clred;
        Image1.Canvas.Pixels[I, Image1.Height - 1] := clred;
      end;
    end;
  end;

end;

procedure TForm4.Image2MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
var
  temppicbmp, tempbmp2: Tbitmap;
  I, ix, iy: integer;
  cancol: boolean;
  PNGrs: TPNGObject;
  JPGrs: TJpegimage;
  rs: TMemoryStream;
  tcol, bcol: cardinal;
  Csimple: boolean;
  Pdat: Pbytearray;
  PD: array of byte;
begin
  if picnum > 0 then
  begin
    if SpeedButton1.Down then
    begin
      picdata[nowmainpicnum].xs := X;
      picdata[nowmainpicnum].ys := Y;
      SpinEdit2.Value := picdata[nowmainpicnum].xs;
      SpinEdit3.Value := picdata[nowmainpicnum].ys;
      Image2.Canvas.Brush.Color := clwhite;
      Image2.Canvas.FillRect(Image2.Canvas.ClipRect);
      Image2.Canvas.CopyRect(bufpic.Canvas.ClipRect, bufpic.Canvas,
        bufpic.Canvas.ClipRect);
      drawpos(picdata[nowmainpicnum].xs, picdata[nowmainpicnum].ys);
    end
    else if SpeedButton2.Down then
    begin
      if (X < bufpic.Width) and (Y < bufpic.Height) then
      begin
        Csimple := true;
        tcol := bufpic.Canvas.Pixels[X, Y];
        temppicbmp := Tbitmap.create;
        // picdata[nowmainpicnum].pictype := 1;
        rs := TMemoryStream.create;
        // rs.SetSize(picdata[nowMainpicnum].datasize);
        rs.Position := 0;
        rs.write(picdata[nowmainpicnum].data[0],
          picdata[nowmainpicnum].datasize);
        if picdata[nowmainpicnum].pictype = 0 then
        begin
          rs.Position := 0;
          JPGrs := TJpegimage.create;
          JPGrs.LoadFromStream(rs);
          temppicbmp.Width := JPGrs.Width;
          temppicbmp.Height := JPGrs.Height;
          temppicbmp.Assign(JPGrs);
          // bufpic.Canvas.CopyRect(pictempbmp.Canvas.ClipRect,pictempbmp.Canvas,pictempbmp.Canvas.ClipRect);
          JPGrs.Free;
          // pictempbmp.Free;
        end
        else if picdata[nowmainpicnum].pictype = 1 then
        begin
          rs.Position := 0;
          PNGrs := TPNGObject.create;
          PNGrs.LoadFromStream(rs);
          temppicbmp.Width := PNGrs.Width;
          temppicbmp.Height := PNGrs.Height;
          PNGrs.Draw(temppicbmp.Canvas, PNGrs.Canvas.ClipRect);
          // PNGrs.free;
        end;
        rs.Free;

      //  for I := 0 to $FFFFFF do
       //   if I <> tcol then
       //   begin
      //      bcol := I;
       //     break;
       //   end;

        if picdata[nowmainpicnum].pictype = 1 then
        begin
          tempbmp2 := Tbitmap.create;
          tempbmp2.Width := temppicbmp.Width;
          tempbmp2.Height := temppicbmp.Height;
          tempbmp2.Canvas.Brush.Color := bcol;
          tempbmp2.Canvas.FillRect(tempbmp2.Canvas.ClipRect);
          PNGrs.Draw(tempbmp2.Canvas, PNGrs.Canvas.ClipRect);
          tempbmp2.PixelFormat := pf24bit;
          // PNGrs.free;
          setlength(PD, tempbmp2.Width * 3);
          for iy := 0 to tempbmp2.Height - 1 do
          begin
            Pdat := PNGrs.AlphaScanline[iy];
            copymemory(@PD[0],tempbmp2.ScanLine[iy],tempbmp2.Width * 3);
            for ix := 0 to tempbmp2.Width - 1 do

              if ({tempbmp2.Canvas.Pixels[ix, iy]} PD[ix * 3] shl 16 + PD[ix * 3 + 1] shl 8 + PD[ix * 3 + 2] = tcol) then
              begin
                if Pdat[ix]<>0 then
                  Pdat[ix] := 0;
                //tempbmp2.Canvas.Pixels[ix, iy] := bcol;
              end;
          end;
          rs := TMemoryStream.create;
          rs.Position := 0;
          PNGrs.SaveToStream(rs);
          rs.Position := 0;
          setlength(picdata[nowmainpicnum].data, rs.Size);
          picdata[nowmainpicnum].datasize := rs.Size;
          rs.Read(picdata[nowmainpicnum].data[0],
            picdata[nowmainpicnum].datasize);
          rs.Free;
          // cliptrans := true;
          // pictranscol := bcol;
          // savetodata(@tempbmp2);
          Image2.Canvas.Brush.Color := clwhite;
          Image2.Canvas.FillRect(Image2.Canvas.ClipRect);
          drawSmallimg;
          Readnowpictobmp;
          // image2.Canvas.CopyRect(bufpic.Canvas.ClipRect, bufpic.Canvas, bufpic.Canvas.ClipRect);
          drawpos(picdata[nowmainpicnum].xs, picdata[nowmainpicnum].ys);
          tempbmp2.Free;
          PNGrs.Free;
        end
        else
        begin
          CLIPTRANS := true;
          pictranscol := tcol;
          picdata[nowmainpicnum].pictype := 1;
          savetodata(@temppicbmp);
          drawSmallimg;
          Image2.Canvas.Brush.Color := clwhite;
          Image2.Canvas.FillRect(Image2.Canvas.ClipRect);
          Readnowpictobmp;
          // image2.Canvas.CopyRect(bufpic.Canvas.ClipRect, bufpic.Canvas, bufpic.Canvas.ClipRect);
          drawpos(picdata[nowmainpicnum].xs, picdata[nowmainpicnum].ys);
        end;
        temppicbmp.Free;
        setlength(PD, 0);
      end;

    end;
  end;
end;

procedure TForm4.Image2MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: integer);
begin
  if picnum > 0 then
  begin
    if SpeedButton2.Down then
    begin
      if (X < bufpic.Width) and (Y < bufpic.Height) then
      begin
        Image4.Canvas.Brush.Color := bufpic.Canvas.Pixels[X, Y];
        Image4.Canvas.FillRect(Image4.Canvas.ClipRect);
      end;
    end;
  end;
end;

procedure TForm4.Readnowpictobmp;
var
  PNGrs: TPNGObject;
  JPGrs: TJpegimage;
  rs: TMemoryStream;
  // pictempbmp:Tbitmap;
begin
  //
  CLIPTRANS := false;
  bufpic.Canvas.Brush.Color := clwhite;
  bufpic.Canvas.FillRect(bufpic.Canvas.ClipRect);
  rs := TMemoryStream.create;
  // rs.SetSize(picdata[nowMainpicnum].datasize);
  rs.Position := 0;
  rs.write(picdata[nowmainpicnum].data[0], picdata[nowmainpicnum].datasize);
  if picdata[nowmainpicnum].pictype = 0 then
  begin
    rs.Position := 0;
    JPGrs := TJpegimage.create;
    JPGrs.LoadFromStream(rs);
    bufpic.Width := JPGrs.Width;
    bufpic.Height := JPGrs.Height;
    bufpic.Assign(JPGrs);
    // bufpic.Canvas.CopyRect(pictempbmp.Canvas.ClipRect,pictempbmp.Canvas,pictempbmp.Canvas.ClipRect);
    JPGrs.Free;
    // pictempbmp.Free;
  end
  else if picdata[nowmainpicnum].pictype = 1 then
  begin
    rs.Position := 0;
    PNGrs := TPNGObject.create;
    PNGrs.LoadFromStream(rs);
    bufpic.Width := PNGrs.Width;
    bufpic.Height := PNGrs.Height;
    PNGrs.Draw(bufpic.Canvas, PNGrs.Canvas.ClipRect);
    PNGrs.Free;
  end;
  rs.Free;

  Image2.Canvas.CopyRect(bufpic.Canvas.ClipRect, bufpic.Canvas,
    bufpic.Canvas.ClipRect);

end;

procedure TForm4.SpinEdit1Change(Sender: TObject);
var
  temp: integer;
begin
  if (picnum > 0) and (SpinEdit1.Text <> '') then
  begin
    SpinEdit1.MaxValue := picnum - 1;
    temp := nowmainpicnum;
    nowmainpicnum := SpinEdit1.Value;
    if nowmainpicnum >= picnum then
      nowmainpicnum := picnum - 1;
    if nowmainpicnum < 0 then
      nowmainpicnum := 0;
    if temp <> nowmainpicnum then
    begin
      nowsmallpicnum := nowmainpicnum;
      bufpic.Canvas.FillRect(bufpic.Canvas.ClipRect);
      Image2.Canvas.FillRect(Image2.Canvas.ClipRect);
      Readnowpictobmp;
      drawSmallimg;
    end;
    SpinEdit1.Value := nowmainpicnum;
  end;
end;

procedure TForm4.SpinEdit2Change(Sender: TObject);
begin
  if picnum > 0 then
  begin
    picdata[nowmainpicnum].xs := SpinEdit2.Value;
    Image2.Canvas.CopyRect(bufpic.Canvas.ClipRect, bufpic.Canvas,
      bufpic.Canvas.ClipRect);
    drawpos(picdata[nowmainpicnum].xs, picdata[nowmainpicnum].ys);
    SpinEdit2.Value := picdata[nowmainpicnum].xs;
  end;
end;

procedure TForm4.SpinEdit3Change(Sender: TObject);
begin
  if picnum > 0 then
  begin
    picdata[nowmainpicnum].ys := SpinEdit3.Value;
    Image2.Canvas.CopyRect(bufpic.Canvas.ClipRect, bufpic.Canvas,
      bufpic.Canvas.ClipRect);
    drawpos(picdata[nowmainpicnum].xs, picdata[nowmainpicnum].ys);
    SpinEdit3.Value := picdata[nowmainpicnum].ys;
  end;
end;

function calPNG(Pdata: Pbyte): integer;
begin
  result := 0;
  try
  if ((Pcardinal(Pdata))^ = $474E5089) and
    ((Pcardinal(Pdata + 4))^ = $0A1A0A0D) then
    result := 1;

  except
    result := 0;
  end;
end;

procedure TForm4.CheckBox1Click(Sender: TObject);
begin
  if picnum > 0 then
    if CheckBox1.Checked then
      picdata[nowmainpicnum].blackground := 1
    else
      picdata[nowmainpicnum].blackground := 0;

end;

procedure TForm4.BitBtn1Click(Sender: TObject);
var
  temp: integer;
begin
  if picnum > 0 then
  begin
    temp := nowsmallpicnum;
    dec(nowsmallpicnum);
    if nowsmallpicnum >= picnum then
      nowsmallpicnum := picnum - 1;
    if nowsmallpicnum < 0 then
      nowsmallpicnum := 0;
    if temp <> nowsmallpicnum then
      drawSmallimg;
    // spinedit1.Value := nowsmallpicnum;
  end;

end;

procedure TForm4.BitBtn2Click(Sender: TObject);
var
  temp: integer;
begin
  if picnum > 0 then
  begin
    temp := nowsmallpicnum;
    inc(nowsmallpicnum);
    if nowsmallpicnum >= picnum then
      nowsmallpicnum := picnum - 1;
    if nowsmallpicnum < 0 then
      nowsmallpicnum := 0;
    if temp <> nowsmallpicnum then
      drawSmallimg;
    // spinedit1.Value := nowsmallpicnum;
  end;
end;

procedure TForm4.bmptoimage;
begin
  Image2.Canvas.CopyRect(bufpic.Canvas.ClipRect, bufpic.Canvas,
    bufpic.Canvas.ClipRect);
end;

procedure TForm4.drawSmallimg;
var
  PNGrs: TPNGObject;
  JPGrs: TJpegimage;
  rs: TMemoryStream;
  pictempbmp: Tbitmap;
  I: integer;
  xd, yd: integer;
  cenx, ceny: integer;
begin
  smallbufpic.Canvas.Brush.Color := clwhite;
  smallbufpic.Canvas.FillRect(Image1.Canvas.ClipRect);
  rs := TMemoryStream.create;
  for I := 0 to 6 - 1 do
  begin
    if ((I + nowsmallpicnum) < picnum) then
    begin
      // rs.SetSize(picdata[nowMainpicnum + I].datasize);
      rs.Position := 0;
      rs.Write(picdata[nowsmallpicnum + I].data[0],
        picdata[nowsmallpicnum + I].datasize);
      if picdata[nowsmallpicnum + I].pictype = 0 then
      begin
        rs.Position := 0;
        JPGrs := TJpegimage.create;
        JPGrs.LoadFromStream(rs);
        pictempbmp := Tbitmap.create;
        pictempbmp.Width := JPGrs.Width;
        pictempbmp.Height := JPGrs.Height;
        pictempbmp.Assign(JPGrs);
        if (pictempbmp.Width > Image1.Width div 6) or
          (pictempbmp.Height > Image1.Height) then
        begin
          xd := pictempbmp.Width div (Image1.Width div 6) + 1;
          yd := pictempbmp.Height div Image1.Height + 1;
          cenx := ((Image1.Width div 6) - (pictempbmp.Width div max(xd, yd)))
            div 2;
          ceny := (Image1.Height - (pictempbmp.Height div max(xd, yd))) div 2;
          smallbufpic.Canvas.StretchDraw(Rect(I * (Image1.Width div 6) + cenx,
              ceny, I * (Image1.Width div 6) + pictempbmp.Width div max(xd,
                yd) + cenx, pictempbmp.Height div max(xd, yd) + ceny),
            pictempbmp);
        end
        else
        begin
          cenx := ((Image1.Width div 6) - pictempbmp.Width) div 2;
          ceny := (Image1.Height - pictempbmp.Height) div 2;
          smallbufpic.Canvas.CopyRect(Rect(I * (Image1.Width div 6) + cenx,
              ceny, I * (Image1.Width div 6) + pictempbmp.Width + cenx,
              pictempbmp.Height + ceny), pictempbmp.Canvas,
            pictempbmp.Canvas.ClipRect);
        end;
        JPGrs.Free;
        pictempbmp.Free;
      end
      else if picdata[nowsmallpicnum + I].pictype = 1 then
      begin
        rs.Position := 0;
        PNGrs := TPNGObject.create;
        PNGrs.LoadFromStream(rs);
        pictempbmp := Tbitmap.create;
        pictempbmp.Width := PNGrs.Width;
        pictempbmp.Height := PNGrs.Height;
        PNGrs.Draw(pictempbmp.Canvas, PNGrs.Canvas.ClipRect);
        if (pictempbmp.Width > Image1.Width div 6) or
          (pictempbmp.Height > Image1.Height) then
        begin
          xd := pictempbmp.Width div (Image1.Width div 6) + 1;
          yd := pictempbmp.Height div Image1.Height + 1;
          smallbufpic.Canvas.StretchDraw(Rect(I * (Image1.Width div 6), 0,
              I * (Image1.Width div 6) + pictempbmp.Width div max(xd, yd),
              pictempbmp.Height div max(xd, yd)), pictempbmp);
        end
        else
          smallbufpic.Canvas.CopyRect(Rect(I * (Image1.Width div 6), 0,
              I * (Image1.Width div 6) + pictempbmp.Width, pictempbmp.Height),
            pictempbmp.Canvas, pictempbmp.Canvas.ClipRect);
        PNGrs.Free;
        pictempbmp.Free;
      end;
    end;
  end;
  rs.Free;
  Image1.Canvas.CopyRect(Image1.Canvas.ClipRect, smallbufpic.Canvas,
    smallbufpic.Canvas.ClipRect);
end;

procedure TForm4.drawpos(X, Y: integer);
var
  I: integer;
begin
  //
  Image2.Canvas.CopyRect(bufpic.Canvas.ClipRect, bufpic.Canvas,
    bufpic.Canvas.ClipRect);
  Image2.Canvas.Pixels[X, Y] := clred;
  Image2.Canvas.Pixels[X - 1, Y] := clred;
  for I := 1 to 8 do
  begin
    Image2.Canvas.Pixels[X - 2 * I, Y - I] := clred;
    Image2.Canvas.Pixels[X - 2 * I - 1, Y - I] := clred;
    Image2.Canvas.Pixels[X + 2 * I - 1, Y - I] := clred;
    Image2.Canvas.Pixels[X + 2 * I, Y - I] := clred;
  end;
  Image2.Canvas.Pixels[X - 18, Y - 9] := clred;
  Image2.Canvas.Pixels[X + 17, Y - 9] := clred;
  for I := 1 to 8 do
  begin
    Image2.Canvas.Pixels[X - 19 + 2 * I, Y - 9 - I] := clred;
    Image2.Canvas.Pixels[X - 19 + 2 * I + 1, Y - 9 - I] := clred;
    Image2.Canvas.Pixels[X + 17 - 2 * I, Y - 9 - I] := clred;
    Image2.Canvas.Pixels[X + 17 - 2 * I + 1, Y - 9 - I] := clred;
  end;
  Image2.Canvas.Pixels[X, Y - 17] := clred;
  Image2.Canvas.Pixels[X - 1, Y - 17] := clred;

end;

procedure TForm4.savetodata(PBMP: pntbitmap);
var
  PNG: TPNGObject;
  ix, iy: integer;
  Pdat: Pbytearray;
  rs: TMemoryStream;
  PD: array of byte;
  temppicbmp: TBitmap;
begin
  //
  PNG := TPNGObject.create;
  // PNG.AssignHandle(bufpic.Handle, true, $FFFFFF);
  PNG.Assign(PBMP^);
  temppicbmp := TBitmap.Create;
  temppicbmp.Assign(PBMP^);
  temppicbmp.PixelFormat := pf24bit;
  // PNG.RemoveTransparency;
  // PNG.Transparent := false;
  // PNG.TransparentColor := $FFFFFF;
  // if PNG.TransparencyMode = ptmBit then
  if CLIPTRANS then
  begin
    PNG.CreateAlpha;
    setlength(PD, PNG.Width * 3);
    for iy := 0 to PNG.Height - 1 do
    begin
      Pdat := PNG.AlphaScanline[iy];
      copymemory(@PD[0],temppicbmp.ScanLine[iy], temppicbmp.Width * 3);
      for ix := 0 to PNG.Width - 1 do
        if PD[ix * 3] shl 16 + PD[ix * 3 + 1] shl 8 + PD[ix * 3 + 2]= pictranscol then
          Pdat[ix] := 0
        else
          Pdat[ix] := 255;
    end;
  end;
  rs := TMemoryStream.create;
  rs.Position := 0;
  PNG.SaveToStream(rs);
  picdata[nowmainpicnum].datasize := rs.Size;
  setlength(picdata[nowmainpicnum].data, picdata[nowmainpicnum].datasize);
  rs.Position := 0;
  rs.Read(picdata[nowmainpicnum].data[0], picdata[nowmainpicnum].datasize);
  // rs.SaveToFile('C:\abcd.png');
  setlength(PD, 0);
  rs.Free;
  PNG.Free;
  temppicbmp.Free;
  CLIPTRANS := false;
end;

procedure TForm4.copypic(AFrom, ATo: integer);
begin
  //
  picdata[ATo].pictype := picdata[AFrom].pictype;
  picdata[ATo].xs := picdata[AFrom].xs;
  picdata[ATo].ys := picdata[AFrom].ys;
  picdata[ATo].blackground := picdata[AFrom].blackground;
  picdata[ATo].datasize := picdata[AFrom].datasize;
  setlength(picdata[ATo].data, picdata[ATo].datasize);
  move(picdata[AFrom].data[0], picdata[ATo].data[0], picdata[ATo].datasize);
end;

procedure TForm4.addlast;
var
  picF, I, i2: integer;
  picgif: Tbitmap;
  bufgif: Tgifimage;
  temp: boolean;
  temp2: cardinal;
begin
  if picnum > 0 then
  begin
     OpenDialog1.Filter := 'PNG,JPG,BMP,GIF|*.Png;*.jpg;*.jpeg;*.bmp;*.gif|All files (*.*)|*.*';
    if OpenDialog1.Execute then
    begin
      CLIPTRANS := false;
      if SameText(ExtractFileExt(OpenDialog1.filename), '.png') or SameText
        (ExtractFileExt(OpenDialog1.filename), '.jpg') or SameText
        (ExtractFileExt(OpenDialog1.filename), '.jpeg') then
      begin
        inc(picnum);
        setlength(picdata, picnum);
        picF := fileopen(OpenDialog1.filename, fmopenread);
        nowmainpicnum := picnum - 1;
        picdata[nowmainpicnum].datasize := fileseek(picF, 0, 2);
        fileseek(picF, 0, 0);
        setlength(picdata[nowmainpicnum].data, picdata[nowmainpicnum].datasize);
        fileread(picF, picdata[nowmainpicnum].data[0],
          picdata[nowmainpicnum].datasize);
        picdata[nowmainpicnum].xs := 0;
        picdata[nowmainpicnum].ys := 0;
        picdata[nowmainpicnum].blackground := 0;
        picdata[nowmainpicnum].pictype := calPNG(@(picdata[nowmainpicnum].data[0]));
        fileclose(picF);
      end
      else if SameText(ExtractFileExt(OpenDialog1.filename), '.bmp') then
      begin
        inc(picnum);
        setlength(picdata, picnum);
        nowmainpicnum := picnum - 1;
        bufpic.LoadFromFile('opendialog1.FileName');
        savetodata(@bufpic);
        picdata[nowmainpicnum].xs := 0;
        picdata[nowmainpicnum].ys := 0;
        picdata[nowmainpicnum].blackground := 0;
        picdata[nowmainpicnum].pictype := calPNG(@(picdata[nowmainpicnum].data[0]));
      end
      else if SameText(ExtractFileExt(OpenDialog1.filename), '.gif') then
      begin

        bufgif := Tgifimage.create;
        picgif := Tbitmap.create;
        bufgif.LoadFromFile(OpenDialog1.filename);
        picgif.Width := bufgif.Width;
        picgif.Height := bufgif.Height;
        picgif.Canvas.Brush.Color := bufgif.BackgroundColor;
        if (bufgif.Images.Count <= 10) or
          ((bufgif.Images.Count > 10) and (MessageBox(Self.Handle,
              'GIF包含图片大于10张，导入会花一段很长时间。确实要导入吗？', '插入图片', MB_OKCANCEL) = 1)) then
        begin
          //Image3.Canvas.Pixels[0, 0] := clblue;
          progressbar1.Min := 0;
          progressbar1.Max := bufgif.Images.Count;
          progressbar1.Position := 0;
          for i2 := 0 to bufgif.Images.Count - 1 do
          begin
            progressbar1.Position := progressbar1.Position + 1;
            Main.MainForm.Repaint;
            main.MainForm.Refresh;

            self.repaint;
            self.Refresh;
            picgif.Canvas.FillRect(picgif.Canvas.ClipRect);
            bufgif.Images[i2].Draw(picgif.Canvas, picgif.Canvas.ClipRect, true,
              true);
            inc(picnum);
            setlength(picdata, picnum);
            nowmainpicnum := picnum - 1;

            temp := CLIPTRANS;
            CLIPTRANS := true;
            temp2 := pictranscol;
            pictranscol := picgif.Canvas.Pixels[0, 0];
            savetodata(@picgif);
            CLIPTRANS := temp;
            pictranscol := temp2;
            picdata[nowmainpicnum].xs := 0;
            picdata[nowmainpicnum].ys := 0;
            picdata[nowmainpicnum].blackground := 0;
            picdata[nowmainpicnum].pictype := calPNG(@(picdata[nowmainpicnum].data[0]));

          end;
        end;
        bufgif.Free;
        picgif.Free;
      end;
      SpinEdit1.MaxValue := picnum - 1;
      nowsmallpicnum := picnum - 1;
      drawSmallimg;
      Image2.Canvas.Brush.Color := clwhite;
      Image2.Canvas.FillRect(Image2.Canvas.ClipRect);
      Readnowpictobmp;
      SpinEdit1.Value := nowmainpicnum;
      SpinEdit2.Value := picdata[nowmainpicnum].xs;
      SpinEdit3.Value := picdata[nowmainpicnum].ys;
      if picdata[nowmainpicnum].blackground = 1 then
        CheckBox1.Checked := true
      else
        CheckBox1.Checked := false;
      drawpos(picdata[nowmainpicnum].xs, picdata[nowmainpicnum].ys);
      progressbar1.Position := 0;
      //Image3.Canvas.Brush.Color := clwhite;
      //Image3.Canvas.FillRect(Image3.Canvas.ClipRect);
    end;
  end;
end;

procedure TForm4.addone;
var
  I, i2, picF: integer;
  picgif: Tbitmap;
  bufgif: Tgifimage;
  temp: boolean;
  temp2: cardinal;
begin
  if picnum > 0 then
  begin
    OpenDialog1.Filter := 'PNG,JPG,BMP,GIF|*.Png;*.jpg;*.jpeg;*.bmp;*.gif|All files (*.*)|*.*';
    if OpenDialog1.Execute then
    begin
      CLIPTRANS := false;
      if SameText(ExtractFileExt(OpenDialog1.filename), '.png') or SameText
        (ExtractFileExt(OpenDialog1.filename), '.jpg') or SameText
        (ExtractFileExt(OpenDialog1.filename), '.jpeg') then
      begin
        inc(picnum);
        setlength(picdata, picnum);
        for I := nowmainpicnum to picnum - 2 do
        begin
          copypic(picnum - 2 + nowmainpicnum - I,
            picnum - 1 + nowmainpicnum - I);
        end;
        picF := fileopen(OpenDialog1.filename, fmopenread);
        picdata[nowmainpicnum].datasize := fileseek(picF, 0, 2);
        fileseek(picF, 0, 0);
        setlength(picdata[nowmainpicnum].data, picdata[nowmainpicnum].datasize);
        fileread(picF, picdata[nowmainpicnum].data[0],
          picdata[nowmainpicnum].datasize);
        picdata[nowmainpicnum].xs := 0;
        picdata[nowmainpicnum].ys := 0;
        picdata[nowmainpicnum].blackground := 0;
        picdata[nowmainpicnum].pictype := calPNG(@(picdata[nowmainpicnum].data[0]));
        fileclose(picF);
      end
      else if SameText(ExtractFileExt(OpenDialog1.filename), '.bmp') then
      begin
        inc(picnum);
        setlength(picdata, picnum);
        for I := nowmainpicnum to picnum - 2 do
        begin
          copypic(picnum - 2 + nowmainpicnum - I,
            picnum - 1 + nowmainpicnum - I);
        end;
        bufpic.LoadFromFile(OpenDialog1.filename);
        savetodata(@bufpic);
        picdata[nowmainpicnum].xs := 0;
        picdata[nowmainpicnum].ys := 0;
        picdata[nowmainpicnum].blackground := 0;
        picdata[nowmainpicnum].pictype := calPNG(@(picdata[nowmainpicnum].data[0]));
      end
      else if SameText(ExtractFileExt(OpenDialog1.filename), '.gif') then
      begin
        bufgif := Tgifimage.create;
        picgif := Tbitmap.create;
        bufgif.LoadFromFile(OpenDialog1.filename);
        picgif.Width := bufgif.Width;
        picgif.Height := bufgif.Height;
        picgif.Canvas.Brush.Color := bufgif.BackgroundColor;
        if (bufgif.Images.Count <= 10) or
          ((bufgif.Images.Count > 10) and (MessageBox(Self.Handle,
              'GIF包含图片大于10张，导入会花一段很长时间。确实要导入吗？', '插入图片', MB_OKCANCEL) = 1)) then
        begin
          progressbar1.Min := 0;
          progressbar1.Max := bufgif.Images.Count;
          progressbar1.Position := 0;
          for i2 := bufgif.Images.Count - 1 downto 0 do
          begin
            progressbar1.Position := progressbar1.Position + 1;
            Main.MainForm.Repaint;
            main.MainForm.Refresh;
            self.repaint;
            self.Refresh;
            picgif.Canvas.FillRect(picgif.Canvas.ClipRect);
            bufgif.Images[i2].Draw(picgif.Canvas, picgif.Canvas.ClipRect, true,
              true);
            inc(picnum);
            setlength(picdata, picnum);
            for I := nowmainpicnum to picnum - 2 do
            begin
              copypic(picnum - 2 + nowmainpicnum - I,
                picnum - 1 + nowmainpicnum - I);
            end;

            temp := CLIPTRANS;
            CLIPTRANS := true;
            temp2 := pictranscol;
            pictranscol := picgif.Canvas.Pixels[0, 0];
            savetodata(@picgif);
            CLIPTRANS := temp;
            pictranscol := temp2;
            picdata[nowmainpicnum].xs := 0;
            picdata[nowmainpicnum].ys := 0;
            picdata[nowmainpicnum].blackground := 0;
            picdata[nowmainpicnum].pictype := calPNG(@(picdata[nowmainpicnum].data[0]));

          end;
        end;
        bufgif.Free;
        picgif.Free;
      end;
      SpinEdit1.MaxValue := picnum - 1;
      drawSmallimg;
      SpinEdit1.Value := nowmainpicnum;
      Image2.Canvas.Brush.Color := clwhite;
      Image2.Canvas.FillRect(Image2.Canvas.ClipRect);
      Readnowpictobmp;
      SpinEdit2.Value := picdata[nowmainpicnum].xs;
      SpinEdit3.Value := picdata[nowmainpicnum].ys;
      if picdata[nowmainpicnum].blackground = 1 then
        CheckBox1.Checked := true
      else
        CheckBox1.Checked := false;
      drawpos(picdata[nowmainpicnum].xs, picdata[nowmainpicnum].ys);
      progressbar1.Position := 0;
      //Image3.Canvas.Brush.Color := clwhite;
      //Image3.Canvas.FillRect(Image3.Canvas.ClipRect);
    end;
  end;
end;

end.
