unit TAKEIN;

interface

uses Windows, Classes, SysUtils, Graphics, Forms, Controls, StdCtrls, ExtCtrls, Dialogs,
  PNGimage, JPEG, Buttons, ComCtrls, head, Gifimg, math;

type

  TPICTYPE = (NONE, JPG, BMP, PNG);

  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Edit1: TEdit;
    Button1: TButton;
    Edit2: TEdit;
    Button2: TButton;
    Edit3: TEdit;
    Button3: TButton;
    Button4: TButton;
    OpenDialog1: TOpenDialog;
    ScrollBox1: TScrollBox;
    Image1: TImage;
    GroupBox1: TGroupBox;
    SpeedButton1: TSpeedButton;
    Edit4: TEdit;
    Label1: TLabel;
    CheckBox1: TCheckBox;
    Button5: TButton;
    Edit5: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    Edit6: TEdit;
    Label4: TLabel;
    Edit7: TEdit;
    Label5: TLabel;
    Edit8: TEdit;
    Button6: TButton;
    Edit9: TEdit;
    Label6: TLabel;
    Label7: TLabel;
    Edit10: TEdit;
    UpDown1: TUpDown;
    UpDown2: TUpDown;
    Timer1: TTimer;
    Button7: TButton;
    ComboBox1: TComboBox;
    Label8: TLabel;
    Panel4: TPanel;
    Label9: TLabel;
    Label10: TLabel;
    Label12: TLabel;
    ProgressBar1: TProgressBar;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    procedure CheckBox1Click(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure UpDown1Click(Sender: TObject; Button: TUDBtnType);
    procedure UpDown2Click(Sender: TObject; Button: TUDBtnType);
    procedure Drawsquare;
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Timer1Timer(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure picdisplay;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  PForm1 = ^TFOrm1;

var
  picname: string;
  can: Tbitmap;
  transcol: cardinal;
  collen: integer = 0;
  pictype: Tpictype;
  cantrans: boolean;
  R,G,B:array[0..255] of byte;
  grppicnum: integer;
  picwidth,picheight,picx,picy: integer;
  takex,takey: integer;
  still : integer = 0;
  tempx, tempy: integer;
  isgif: boolean = false;
  GIF: Tgifimage;
  GIFtranscol: array of cardinal;

function pictoRLE8(Pdata: Pbyte; pw,ph,xs,ys: integer; PBMP: Pntbitmap; Arect: Trect;cantrans: boolean; trancol: cardinal): integer;
function MatchCol(col: cardinal): byte;
function findwidth24pf(Pdata: Pbyte; width: integer; trancol: cardinal): integer;

implementation

{$R *.dfm}

uses
  main, grpedit, grplist;

procedure TForm1.Button1Click(Sender: TObject);
var
  H, len, i:integer;
begin
  opendialog1.Filter := 'Col files (*.Col)|*.Col|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    edit1.Text := opendialog1.FileName;
    H := FIleopen(edit1.Text, fmopenread);
    len := fileseek(H, 0, 2);
    fileseek(H,0,0);
    collen := 256;
    for I := 0 to collen - 1 do
    begin
      fileread(H, R[I], 1);
      fileread(H, G[I], 1);
      fileread(H, B[I], 1);
      B[I] := B[I] shl 2;
      G[I] := G[I] shl 2;
      R[I] := R[I] shl 2;
    end;
    fileclose(H);
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  opendialog1.Filter := 'Idx files (*.Idx)|*.Idx|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    edit2.Text := opendialog1.FileName;
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  opendialog1.Filter := 'Grp files (*.Grp)|*.Grp|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    edit3.Text := opendialog1.FileName;
  end;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  opendialog1.Filter := 'JPG,PNG,BMP,GIF|*.Jpeg;*.Jpg;*.bmp;*.PNG;*.gif|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    picname := opendialog1.FileName;
    picdisplay;
  end;
end;

procedure TForm1.picdisplay;
var
  PNG: TPNGObject;
  JPEG: Tjpegimage;
  bmp: Tbitmap;
  i, i2,ix,iy:integer;
  cancol: boolean;
  PD: array of byte;
begin
  pictype := none;
    cantrans := true;
    if SameText(ExtractFileExt(picName), '.png') then
    begin
      PNG := TPNGObject.Create;
      PNG.LoadFromFile(picname);

      BMP := Tbitmap.Create;
      BMP.Assign(PNG);
      BMP.PixelFormat := pf24bit;
      setlength(PD, bmp.Width * 3);
      //showmessage('打开成功');
      for I := 0 to $FFFFFF do
      begin
        cancol := true;
        for iy := 0 to bmp.Height - 1 do
        begin
          copymemory(@PD[0],bmp.ScanLine[Iy],bmp.Width * 3);
          for ix := 0 to bmp.Width - 1 do
          begin
            if PD[ix * 3] shl 16 + PD[ix * 3 + 1] shl 8 + PD[ix * 3 + 2] = $ffffff - I then
              cancol := false;
            if not (cancol) then
              break;
          end;
          if not (cancol) then
            break;
        end;
        if cancol then
        begin
          transcol := $ffffff - I;
          break;
        end;
      end;
      can.Width := PNG.Width;
      can.Height := PNG.Height;
      can.Canvas.Brush.Color := transcol;
      can.Canvas.FillRect(can.Canvas.ClipRect);
      PNG.Draw(can.Canvas,can.Canvas.ClipRect);
      PNG.Destroy;
      CHECKBOX1.Checked := TRUE;
      GROUPBOX1.Visible := TRUE;
      if isgif then
        gif.Free;
      isGif := false;
      //gif.Free;
    end
    else if SameText(ExtractFileExt(picName), '.jpg') or SameText(ExtractFileExt(picName), '.jpeg') then
    begin
      JPEG := Tjpegimage.Create;
      JPEG.LoadFromFile(picname);
      can.Assign(jpeg);
      transcol := can.Canvas.Pixels[0,0];
      jpeg.Free;
      if isgif then
        gif.Free;
      isGif := false;
    end
    else if SameText(ExtractFileExt(picName), '.bmp') then
    begin
      bmp := Tbitmap.Create;
      BMP.LoadFromFile(picname);
      can.Assign(bmp);
      transcol := can.Canvas.Pixels[0,0];
      bmp.Free;
      if isgif then
        gif.Free;
      isGif := false;
    end
    else if SameText(ExtractFileExt(picName), '.gif') then
    begin
      GIF.free;
      GIF := Tgifimage.Create;

      GIF.LoadFromFile(picname);
      setlength(giftranscol, gif.Images.Count);
      can.Width := gif.Width;
      can.Height := gif.Height;
      for I := gif.Images.Count - 1 downto 0 do
      begin
     //   can.Canvas.Brush.Color := gif.BackgroundColor;
      //  can.Canvas.fillrect(can.Canvas.ClipRect);
      //  gif.Images[I].Draw(can.Canvas, can.Canvas.ClipRect, true, true);
       { for I2 := 0 to $FFFFFF do
        begin
          cancol := true;
          for ix := 0 to CAN.Width - 1 do
          begin
            for iy := 0 to CAN.Height - 1 do
            begin
              if can.Canvas.Pixels[ix, iy] = $ffffff - I then
                cancol := false;
              if not (cancol) then
                break;
            end;
            if not (cancol) then
              break;
          end;
          if cancol then
          begin
            giftranscol[I] := $ffffff - I2;
            break;
          end;
        end; }
        giftranscol[I] := gif.DrawBackgroundColor;// BackgroundColor;//can.Canvas.Pixels[0,0];
      end;

      transcol := giftranscol[0];
      CHECKBOX1.Checked := TRUE;
      GROUPBOX1.Visible := TRUE;

      CAN.Canvas.Brush.Color := TRANSCOL;
      CAN.Canvas.FillRect(CAN.Canvas.ClipRect);
      gif.Images[0].Draw(can.Canvas, can.Canvas.ClipRect, true, true);
      isgif := true;
    end;
    edit4.Text :=  Format('%x', [transcol]);
    image1.Height := can.Height;
    image1.Width := can.Width;
    image1.Picture.Bitmap.Width := image1.Width;
    image1.Picture.Bitmap.Height := image1.Height;
    image1.Canvas.CopyRect(image1.Canvas.ClipRect, can.Canvas, can.Canvas.ClipRect);
    picwidth := image1.Width;
    picheight := image1.Height;
    takex := 0;
    takey := 0;
    picx := 0;
    picy := 0;
    edit5.Text := inttostr(picheight);
    edit6.Text := inttostr(picwidth);
    edit7.Text := inttostr(picx);
    edit8.Text := inttostr(picy);
    edit9.Text := inttostr(takex);
    edit10.Text := inttostr(takey);
    drawsquare;
    updown1.Max := image1.Picture.Bitmap.Width - picwidth;
    updown2.Max := image1.Picture.Bitmap.Height - picheight;
    updown1.Position := 0;
    updown2.Position := 0;
    if isgif and (gif.Images.Count > 1) then
      showmessage('GIF图片只显示第一帧，所有帧设置同第一帧，都可导入！');
end;

procedure TForm1.Button5Click(Sender: TObject);
var
  data: array of byte;
  len, i2: integer;
  idx,grp, filelen: integer;
  idxdata, grpdata: array of byte;
  I: Integer;
begin
  try
  if not (fileexists(edit2.Text) and fileexists(edit3.Text)) then
  begin
    showmessage('GRP或IDX文件不存在！');
    exit;
  end;
  if ISGIF then
  BEGIN
    progressbar1.Min := 0;
    progressbar1.Max := gif.Images.Count;
    progressbar1.Position := 0;
    for I := 0 to gif.Images.Count - 1 do
    begin
      progressbar1.Position := progressbar1.Position + 1;
      Main.MainForm.Refresh;
      main.MainForm.Refresh;
      self.repaint;
      self.Refresh;
      can.Canvas.Brush.Color := giftranscol[I];//gif.BackgroundColor; //
      can.Canvas.FillRect(can.Canvas.ClipRect);
      gif.Images[I].Draw(can.Canvas, can.Canvas.ClipRect, true, true);
      setlength(data, picwidth * picheight * 2 + 8);
      transcol := giftranscol[I];//gif.BackgroundColor;//
      len := pictoRLE8(@data[0], picwidth,picheight,picx,picy,@can,rect(takex,takey,takex + picwidth, takey + picheight),checkbox1.Checked, transcol);
      idx := fileopen(edit2.Text, fmopenread);
      filelen := fileseek(idx, 0, 2);
      setlength(idxdata, filelen);
      fileseek(idx, 0, 0);
      fileread(idx, idxdata[0], filelen);
      fileclose(idx);

      idx := filecreate(edit2.Text);
      filewrite(idx, idxdata[0], filelen);
      i2 := len + (Pinteger(@idxdata[filelen - 4]))^;
      filewrite(idx, i2, 4);
      fileclose(idx);

      grp := fileopen(edit3.Text, fmopenread);
      filelen := fileseek(grp, 0, 2);
      setlength(grpdata, filelen);
      fileseek(grp, 0, 0);
      fileread(grp, grpdata[0], filelen);
      fileclose(grp);

      grp := filecreate(edit3.Text);
      filewrite(grp, grpdata[0], filelen);
      filewrite(grp, data[0], len);
      fileclose(grp);

    end;

  END
  ELSE
  begin
  setlength(data, picwidth * picheight * 2 + 8);
  transcol := strtoint('$' + edit4.Text);
  len := pictoRLE8(@data[0], picwidth,picheight,picx,picy,@can,rect(takex,takey,takex + picwidth, takey + picheight),checkbox1.Checked, transcol);
  idx := fileopen(edit2.Text, fmopenread);
  filelen := fileseek(idx, 0, 2);
  setlength(idxdata, filelen);
  fileseek(idx, 0, 0);
  fileread(idx, idxdata[0], filelen);
  fileclose(idx);

  idx := filecreate(edit2.Text);
  filewrite(idx, idxdata[0], filelen);
  i2 := len + (Pinteger(@idxdata[filelen - 4]))^;
  filewrite(idx, i2, 4);
  fileclose(idx);

  grp := fileopen(edit3.Text, fmopenread);
  filelen := fileseek(grp, 0, 2);
  setlength(grpdata, filelen);
  fileseek(grp, 0, 0);
  fileread(grp, grpdata[0], filelen);
  fileclose(grp);

  grp := filecreate(edit3.Text);
  filewrite(grp, grpdata[0], filelen);
  filewrite(grp, data[0], len);
  fileclose(grp);
  setlength(data, 0);
  setlength(grpdata, 0);
  end;
    setlength(data, 0);
    setlength(grpdata, 0);
    messagebox(0, '导入成功！', '成功！', MB_OK or MB_iconasterisk);
    progressbar1.Position := 0;
  except
    progressbar1.Position := 0;
    messagebox(0, '导入失败！', '提示！', MB_OK or MB_ICONHAND);
    setlength(data, 0);
    setlength(grpdata, 0);
    exit;

  end;
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  picheight := strtoint(edit5.Text);
  picwidth := strtoint(edit6.Text);
  picx := strtoint(edit7.Text);
  picy := strtoint(edit8.Text);
  updown1.Max := image1.Picture.Bitmap.Width - picwidth;
  updown2.Max := image1.Picture.Bitmap.Height - picheight;
  if (picheight + strtoint(edit10.Text) - 1) >= image1.Height then
  begin
    picheight := image1.Height - strtoint(edit10.Text);
    edit5.Text := inttostr(picheight);
  end;
  if (picwidth + strtoint(edit9.Text) - 1) >= image1.Width then
  begin
    picwidth := image1.Width - strtoint(edit9.Text);
    edit6.Text := inttostr(picwidth);
  end;
  drawsquare;
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  drawbmp:= Tbitmap.Create;
  drawbmp.PixelFormat := pf24bit;
  drawbmp.Width := picwidth;
  drawbmp.Height := picheight;
  drawbmp.Canvas.CopyRect(drawbmp.Canvas.ClipRect, can.Canvas,rect(takex,takey,picwidth + takex, picheight + takey));
  edittype := pic;
  Form2.Caption := Form2title;
  Form2.Initial;
  Form2.Drawpallet;
  form2.Visible := false;
  Form2.ShowModal;
  image1.Canvas.CopyRect(image1.Canvas.ClipRect, can.Canvas, can.Canvas.ClipRect);
  drawsquare;
end;

procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  if checkbox1.Checked then
    groupbox1.Visible := true
  else
    groupbox1.Visible := false;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
var
  temp: integer;
  namestr, opstr: string;
begin
  if ComboBox1.ItemIndex < grplistnum then
  begin
    if grplistnum > 0 then
    begin
      edit2.Text := gamepath + grplistidx[combobox1.itemindex];
      edit3.Text := gamepath + grplistgrp[combobox1.itemindex];
    end;
  end
  else
  begin
    temp := combobox1.ItemIndex;
    if grplistnum > 0 then
      temp := temp - grplistnum;

    if temp < 10 then
      namestr := '00'+inttostr(temp)
    else if temp < 100 then
      namestr := '0' + inttostr(temp)
    else
      namestr := inttostr(temp);
    opstr := fightidx;
    opstr := StringReplace(opstr,'***',namestr,[rfReplaceAll]);
    edit2.Text := gamepath + opstr;
    opstr := fightgrp;
    opstr := stringreplace(opstr, '***', namestr,[rfReplaceAll]);
    edit3.Text := gamepath + opstr;

  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CForm1 := true;
  Action := caFree;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  H, len, I: integer;
  colname: string;
begin
  can := Tbitmap.Create;
  self.Width := 800;
  self.Height := 600;
  self.WindowState := wsmaximized;
  colname := gamepath + palette;
  if fileexists(colname) then
  begin
    edit1.Text := colname;
    H := FIleopen(edit1.Text, fmopenread);
    len := fileseek(H, 0, 2);
    fileseek(H,0,0);
    collen := len div 3;
    for I := 0 to collen - 1 do
    begin
      fileread(H, R[I], 1);
      fileread(H, G[I], 1);
      fileread(H, B[I], 1);
      B[I] := B[I] shl 2;
      G[I] := G[I] shl 2;
      R[I] := R[I] shl 2;
    end;
    fileclose(H);
  end;
  combobox1.Items.Clear;
  if grplistnum > 0 then
    for I := 0 to grplistnum - 1 do
      combobox1.Items.Add(displayname(grplistname[I]));


  if fightgrpnum > 0 then
    for I := 0 to fightgrpnum - 1 do
      combobox1.Items.Add(displayname(fightname + inttostr(I)));
  //delete
end;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
VAR
  i: INTEGER;
begin
  if checkbox1.Checked and speedbutton1.Down then
  BEGIN
    edit4.Text := Format('%x', [can.Canvas.Pixels[x,y]]);
    if ISGIF then
      for I := 0 to GIF.Images.Count - 1 do
        GIFTRANSCOL[i] := can.Canvas.Pixels[x,y];
  END
  else
  begin
    tempx := x;
    tempy := y;
    still := 1;
  end;
end;

procedure TForm1.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if still = 1 then
  begin
    takex := x - tempx + takex;
    takey := y - tempy + takey;
    tempx := x;
    tempy := y;
    if takex + picwidth > image1.Picture.Bitmap.Width then
      takex := image1.Picture.Bitmap.Width - picwidth;
    if takey + picheight > image1.Picture.Bitmap.Height then
      takey := image1.Picture.Bitmap.Height - picheight;
    if takex < 0 then
      takex := 0;
    if takey < 0 then
      takey := 0;
    edit9.Text := inttostr(takex);
    edit10.Text := inttostr(takey);
    updown1.Position := takex;
    updown2.Position := takey;
    //drawsquare;
  end;
end;

procedure TForm1.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  still := 0;
  drawsquare;
end;

function MatchCol(col: cardinal): byte;
var
  I, min, now, minnum: integer;
  tempB, tempG, tempR: byte;
begin
  minnum := -1;
  min := -1;
  {for I := 0 to collen - 1 do
  begin
    min := -1;
    minnum := -1;
    tempB := (col and $FF0000) shr 16;
    tempG := (col and $FF00) shr 8;
    tempR := col and $FF;
    if (abs(tempB - B[I])< 50) and (abs(tempG - G[I])< 50) and (abs(tempR - R[I])< 50) then
    begin
      now :=  abs(tempB - B[I]) + abs(tempG - G[I]) + abs(tempR - R[I]);
      if min < 0 then
      begin
        min := now;
        minnum := i;
      end
      else if min > now then
      begin
        min := now;
        minnum := I;
      end;
    end;
  end;  }
  if minnum < 0 then
    for I := 0 to collen - 1 do
    begin
      tempB := (col and $FF0000) shr 16;
      tempG := (col and $FF00) shr 8;
      tempR := col and $FF;
      now :=  abs(tempB - B[I]) + abs(tempG - G[I]) + abs(tempR - R[I]);
      if min < 0 then
      begin
        min := now;
        minnum := i;
      end
      else if min > now then
      begin
        min := now;
        minnum := I;
      end;
    end;
  result := minnum;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if still = 1 then
    drawsquare;
end;

procedure TForm1.UpDown1Click(Sender: TObject; Button: TUDBtnType);
var
  temp: integer;
begin
  if button = btNext then
  begin
    temp := strtoint(edit9.Text);
    inc(temp);
    if temp >= image1.width then
      temp := image1.Width - 1;
    edit9.Text := inttostr(temp);
    takex:= temp;
  end
  else if button = btprev then
  begin
    temp := strtoint(edit9.Text);
    dec(temp);
    if temp < 0 then
      temp := 0;

    edit9.Text := inttostr(temp);
    //edit9.Text := inttostr(temp);
    //edit9.Text := inttostr(image1.Width);
    takex:= temp;
  end;
  drawsquare;
end;

procedure TForm1.UpDown2Click(Sender: TObject; Button: TUDBtnType);
var
  temp: integer;
begin
  if button = btNext then
  begin
    temp := strtoint(edit10.Text);
    inc(temp);
    if temp >= image1.Picture.Bitmap.height then
      dec(temp);
    edit10.Text := inttostr(temp);
    takey:= temp;
  end
  else if button = btprev then
  begin
    temp := strtoint(edit10.Text);
    dec(temp);
    if temp < 0 then
      temp := 0;
    edit10.Text := inttostr(temp);
    takey:= temp;
  end;
  drawsquare;
end;

procedure TForm1.Drawsquare;
var
  ix, iy: integer;
begin
  image1.Canvas.CopyRect(image1.Canvas.ClipRect, can.Canvas, can.Canvas.ClipRect);
  for Ix := takex to takex + picwidth - 1 do
  begin
    image1.canvas.pixels[ix, takey] := clpurple;
    image1.canvas.pixels[ix, takey + picheight - 1] := clpurple;
  end;
  for iy := takey to takeY + picheight - 1 do
  begin
    image1.canvas.pixels[takex, iy] := clpurple;
    image1.canvas.pixels[takex + picwidth - 1, iy] := clpurple;
  end;

end;

function pictoRLE8(Pdata: Pbyte; pw, ph, xs, ys: integer; PBMP: Pntbitmap; Arect: Trect;cantrans: boolean; trancol: cardinal): integer;
var
  trans, state, linebyte, transcount, colnum: byte;
  len, iy, ix, I, i2, linesize, bytesize: integer;
  tempint: cardinal;
  pictempbmp: Tbitmap;
  tempcolor: array of array of byte;
  tempwidth: array of integer;
  leastwidth, templeastwidth: integer;
begin
  //
  len := 8;


  (Psmallint(Pdata))^ := pw;
  (Psmallint(Pdata + 2))^ := ph;
  (Psmallint(Pdata + 4))^ := xs;
  (Psmallint(Pdata + 6))^ := ys;

  result := len;
  if (pw <= 0) or (ph <= 0) then
    exit;

  pictempbmp := TBitmap.Create;
  pictempbmp.Width := PBMP.Width;
  pictempbmp.Height := PBMP.Height;
  pictempbmp.PixelFormat := pf24bit;
  pictempbmp.Canvas.CopyRect(pictempbmp.Canvas.ClipRect, PBMP.Canvas, PBMP.Canvas.ClipRect);

  setlength(tempcolor, pictempbmp.Height, pictempbmp.Width * 3);
  for I := 0 to pictempbmp.Height - 1 do
    copymemory(@tempcolor[I][0], pictempbmp.ScanLine[I], pictempbmp.Width * 3);

  if not cantrans then
  begin
    pw := min(253, pw);
    Arect.Right := Arect.Left + pw;
  end
  else
  begin
    leastwidth := findwidth24pf(@tempcolor[0][0], pw, trancol);
    for I := 1 to ph - 1 do
    begin
      templeastwidth := findwidth24pf(@tempcolor[I][0], pw, trancol);
      if templeastwidth < leastwidth then
        leastwidth := templeastwidth;
    end;
    pw := leastwidth;
    Arect.Right := Arect.Left + pw;
  end;
  (Psmallint(Pdata))^ := pw;

  //inc(Pdata, 8);
  I := 8;
  if cantrans then
  begin
    for Iy := Arect.Top to Arect.Bottom - 1 do
    begin
      trans := 0;//几次透明像素
      transcount := 0;//透明像素个数
      //state
      //为0是初始状态
      //为1是透明像素状态
      //为2是普通颜色像素状态
      state := 0;
      linebyte := 0;
      colnum := 0;
      linesize := i;
      bytesize := 0;
      inc(i);
      for ix := Arect.Left to Arect.Right - 1 do
      begin
        tempint := tempcolor[iy][ix * 3] shl 16 + tempcolor[iy][ix * 3 + 1] shl 8 + tempcolor[iy][ix * 3 + 2];
        //tempint := tempcolor[iy][ix];
        if (tempint = trancol) then
        begin
          if state <> 1 then
          begin
            if colnum > 0 then
            begin
              //data[i] := transcount;
              //inc(i);
              (Pdata+ i)^ := colnum;
              inc(i);
              for i2 := I to I + colnum - 1 do
              begin
                tempint := tempcolor[iy][(ix - colnum - I + i2)* 3] shl 16 + tempcolor[iy ][(ix - colnum - I + i2)* 3 + 1]shl 8 + tempcolor[iy ][(ix - colnum - I + i2)* 3 + 2];
                //tempint := tempcolor[iy][ix - colnum - I + i2];
                (Pdata + i2)^ := matchcol(tempint);
              end;
              inc(i, colnum);
              inc(linebyte, colnum + 1);
              state := 1;
              colnum := 0;
              inc(trans);
              transcount := 1;
            end
            else
            begin
              if transcount = 255 then
              begin
                (PDATA + I)^ := transcount;
                (PDATA + I + 1)^ := 0;
                inc(I, 2);
                inc(linebyte, 2);
                transcount := 0;
              end;
              state := 1;
              inc(trans);
              inc(transcount);
              //inc(linebyte);
            end;
          end
          else
          begin
            if transcount = 255 then
            begin
              (PDATA + I)^ := transcount;
              (PDATA + I + 1)^ := 0;
              inc(I, 2);
              inc(linebyte, 2);
              transcount := 0;
              inc(trans);
            end;
            inc(transcount);
          end;
        end
        else//如果不是透明像素
        begin
          if state <> 2 then
          begin
            (PDATA + I)^ := transcount;
            inc(linebyte);
            transcount := 0;
            inc(i);
            colnum := 1;
            state := 2;
          end
          else
          begin
            if colnum = 255 then
            begin
              (Pdata+ i)^ := colnum;
              inc(i);
              for i2 := I to I + colnum - 1 do
              begin
                tempint := tempcolor[iy][(ix - colnum - I + i2)* 3] shl 16 + tempcolor[iy ][(ix - colnum - I + i2)* 3 + 1]shl 8 + tempcolor[iy ][(ix - colnum - I + i2)* 3 + 2];
                //tempint := tempcolor[iy][ix - colnum - I + i2];
                (Pdata + i2)^ := matchcol(tempint);
              end;
              inc(i, colnum);
              inc(linebyte, colnum + 1);
              colnum := 0;
              inc(trans);
              transcount := 0;
              (Pdata+ i)^ := transcount;
              inc(i);
            end;
            inc(colnum);
          end;
        end;
      end;
      if colnum > 0 then
      begin
        //data[i] := transcount;
        //inc(i);
        (Pdata + i)^ := colnum;
        inc(i);
        for i2 := I to I + colnum - 1 do
        begin
          tempint := tempcolor[iy ][(ix - colnum - I + i2)* 3] shl 16 + tempcolor[iy ][(ix - colnum - I + i2)* 3 + 1] shl 8 + tempcolor[iy][(ix - colnum - I + i2)* 3 + 2];
          // tempint := tempcolor[iy][ix - colnum - I + i2];
          (Pdata + i2)^ := matchcol(tempint);
        end;
        inc(i, colnum);
        inc(linebyte, colnum + 1);
        //state := 0;
        inc(trans);
        //transcount := 0;
        (Pdata + linesize)^ := linebyte;
      end
      else
        (Pdata + linesize)^ := linebyte;
      inc(len, linebyte + 1);

    end;
  end
  else
  begin
    inc(len, (pw + 3)* ph);
    for iy := Arect.Top to Arect.Bottom - 1 do
    begin
      (Pdata+i)^ := pw + 2;
      (Pdata + i + 1)^ := 0;
      (Pdata + i + 2)^ := pw;
      inc(i, 3);
      for ix := takex to takex + picwidth - 1 do
      begin
         tempint := tempcolor[iy ][ix* 3] shl 16 + tempcolor[iy ][ix* 3 + 1] shl 8 + tempcolor[iy ][ix* 3 + 2];
        //tempint := tempcolor[iy][ix];
        (Pdata + i)^ := matchcol(tempint);
        inc(i);
      end;
    end;
  end;
  setlength(tempcolor,0,0);
  pictempbmp.Free;
  result := len;
end;

function findwidth24pf(Pdata: Pbyte; width: integer; trancol: cardinal): integer;
var
  ix, linesize, state, bytesize: integer;
  tempcol: cardinal;
  findnext: boolean;
begin
  findnext := false;
  if width <= 168 then
  begin
    result := width;
    exit;
  end;
  linesize := 0;
  state := 0;
  for ix := 0 to width - 1 do
  begin
    tempcol := (Pdata + ix * 3)^ shl 16 + (Pdata + ix * 3 + 1)^ shl 8 + (Pdata + ix * 3 + 2)^;
    if (state = 0) and (tempcol = trancol) then
    begin
      state := 1;
      inc(linesize);
      bytesize := 1;
    end
    else if (state = 0) and (tempcol <> trancol) then
    begin
      state := 2;
      inc(linesize, 3);
      bytesize := 1;
    end
    else if (state = 1) and (tempcol = trancol) then
    begin
      if bytesize = 255 then
      begin
        bytesize := 1;
        inc(linesize, 2);
        if linesize > 255 then
        begin
          findnext := true;
          break;
        end;
      end
      else
        inc(bytesize);
    end
    else if (state = 1) and (tempcol <> trancol) then
    begin
      state := 2;
      bytesize := 1;
      inc(linesize, 2);
      if linesize > 255 then
      begin
        findnext := true;
        break;
      end;
    end
    else if (state = 2) and (tempcol = trancol) then
    begin
      state := 1;
      bytesize := 1;
      inc(linesize, 1);
      if linesize > 255 then
      begin
        findnext := true;
        break;
      end;
    end
    else if (state = 2) and (tempcol <> trancol) then
    begin
      if bytesize = 255 then
      begin
        bytesize := 1;
        inc(linesize, 3);
        if linesize > 255 then
        begin
          findnext := true;
          break;
        end;
      end
      else
      begin
        inc(bytesize);
        inc(linesize);
        if linesize > 255 then
        begin
          findnext := true;
          break;
        end;
      end;
    end;
  end;
  if findnext then
    result := findwidth24pf(Pdata, width - 1, trancol)
  else
    result := width;
end;

end.
