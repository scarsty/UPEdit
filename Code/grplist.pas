unit grplist;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, head, Menus, FileCtrl, PNGimage, about,inifiles, math;

type

  TForm3 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    ScrollBar2: TScrollBar;
    Image1: TImage;
    Button1: TButton;
    Edit1: TEdit;
    Button2: TButton;
    Edit2: TEdit;
    OpenDialog1: TOpenDialog;
    Edit3: TEdit;
    Button3: TButton;
    Button4: TButton;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    ComboBox1: TComboBox;
    Label1: TLabel;
    PNG1: TMenuItem;
    Label2: TLabel;
    ComboBox2: TComboBox;
    RadioGroup1: TRadioGroup;
    Button5: TButton;
    PNG2: TMenuItem;
    PNGRLE81: TMenuItem;
    GroupBox1: TGroupBox;
    Button6: TButton;
    Panel3: TPanel;
    Image2: TImage;
    ColorDialog1: TColorDialog;
    N7: TMenuItem;
    Button7: TButton;
    Panel4: TPanel;
    Image3: TImage;
    GroupBox2: TGroupBox;
    Button9: TButton;
    Button8: TButton;
    Button10: TButton;
    Label3: TLabel;
    Label4: TLabel;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Label5: TLabel;
    Label6: TLabel;
    ComboBox3: TComboBox;
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormResize(Sender: TObject);

    procedure FormCreate(Sender: TObject);
    //function judgeWH: Trect;
    procedure display;
    procedure ScrollBar2Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure PNG1Click(Sender: TObject);
    procedure Image1StartDrag(Sender: TObject; var DragObject: TDragObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ComboBox2Change(Sender: TObject);
    procedure displaygrplist;
    procedure RadioGroup1Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure PNG2Click(Sender: TObject);
    procedure PNGRLE81Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Image2Click(Sender: TObject);
    procedure Image3Click(Sender: TObject);
    procedure N7Click(Sender: TObject);
    procedure Drawsquare(x, y: integer);
    procedure Button8Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  PForm3 = ^TForm3;

var

  grplistselect : integer = 0;
  filenum: integer = 0;
  nowpic: integer = -1;
  bufbmp, bufbmp2, bufbmp3: Tbitmap;
  Form3initial: boolean = false;

  temppic: integer = -1;
  copynum: integer = -1;
  grplistcopydata: array of byte;

  toeditbmp: Tbitmap;
  xmove,ymove: integer;
  needdraw: boolean = false;
  movelock : integer;
  beginpic: integer;
  endpic: integer;
  piccount: integer;

  GR, GG, GB: array[0..255] of byte;
  grppic: array of Tgrppic;
  grpcollen: integer;

  GRPlistBackGround: Cardinal;
  GRPlistTextCol: Cardinal;

  grplistlinenum: integer = 0;
  grplistlinepicnum: integer = 10;
  grplistsquareH: integer = 100;
  grplistsquareW: integer;
  grplisttitleH: integer = 10;

procedure drawRLE8(Ppic: Pbyte; len: integer; PBMP: PntBitMap; dx, dy: integer; canmove: boolean);
procedure copyGRP(AFrom, Ato:integer);
procedure MEMdrawRLE8(Ppic: Pbyte; len: integer; PBMP: PntBitMap; dx, dy: integer; canmove: boolean);
procedure DataDrawRLE8(Ppic: Pbyte; len: integer; PBMP: Pbmpdata; dx, dy: integer; canmove: boolean);

implementation

{$R *.dfm}

uses
  main, takein, grpedit, outputPNG;

procedure TForm3.Drawsquare(x, y: integer);
var
  Ix, iy: integer;
begin
  //
  iy := y;
  for Ix := x to x + grplistsquarew - 1 do
  begin
    image1.Canvas.Pixels[ix, iy] := grplisttextcol;
    image1.Canvas.Pixels[ix, iy + grplistsquareH] := grplisttextcol;
  end;
  ix := x;
  for Iy := y to y + grplistsquareh - 1 do
  begin
    image1.Canvas.Pixels[ix, iy] := grplisttextcol;
    image1.Canvas.Pixels[ix + grplistsquareW, iy] := grplisttextcol;
  end;
end;

procedure TForm3.Button10Click(Sender: TObject);
var
  BeginGrpset, EndGrpset, I, offsetpos, temp, setint: integer;
begin
  try
    BeginGrpset := strtoint(edit4.Text);
    EndGrpset := strtoint(edit5.Text);
    setint := strtoint(edit7.Text);
  except
    exit;
  end;
  offsetpos := 6;
  if BeginGrpset > EndGrpset then
  begin
    temp := BeginGrpset;
    BeginGrpset := EndGrpset;
    EndGrpset := temp;
  end;
  for I := BeginGrpset to EndGrpset do
  begin
    if (I < 0) then
      continue;
    if (I >= filenum) then
      break;
    if grppic[I].size < 8 then
      continue;
    if calPNG(@grppic[I].data[0]) = 1 then
      continue;
    case Combobox3.ItemIndex of
      0: PSmallint(@grppic[I].data[offsetpos])^ := setint;
      1: PSmallint(@grppic[I].data[offsetpos])^ := PSmallint(@grppic[I].data[offsetpos])^ + setint;
      2: PSmallint(@grppic[I].data[offsetpos])^ := PSmallint(@grppic[I].data[offsetpos])^ - setint;
      3: PSmallint(@grppic[I].data[offsetpos])^ := PSmallint(@grppic[I].data[offsetpos])^ * setint;
      4: PSmallint(@grppic[I].data[offsetpos])^ := PSmallint(@grppic[I].data[offsetpos])^ div setint;
    end;
  end;
end;

procedure TForm3.Button1Click(Sender: TObject);
begin
  opendialog1.Filter := 'Idx files (*.Idx)|*.Idx|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    edit1.Text := opendialog1.FileName;
  end;
end;

procedure TForm3.Button2Click(Sender: TObject);
begin
  opendialog1.Filter := 'Grp files (*.Grp)|*.Grp|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    edit2.Text := opendialog1.FileName;
  end;
end;

procedure TForm3.Button3Click(Sender: TObject);
var
  H, len, i:integer;
   //PalSize:longint;
  //  pLogPalle:TMaxLogPalette;
   // PalleEntry:TPaletteEntry;
   // Palle:HPalette;
begin

  grpcollen := 256;
  opendialog1.Filter := 'Col files (*.Col)|*.Col|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    edit3.Text := opendialog1.FileName;
    H := FIleopen(edit3.Text, fmopenread);
    len := fileseek(H, 0, 2);
    fileseek(H,0,0);

    for I := 0 to grpcollen - 1 do
    begin
      fileread(H, GR[I], 1);
      fileread(H, GG[I], 1);
      fileread(H, GB[I], 1);
      GB[I] := GB[I] shl 2;
      GG[I] := GG[I] shl 2;
      GR[I] := GR[I] shl 2;
    end;
    fileclose(H);
   {
   PalSize:=sizeof(TLogPalette) + 256 * sizeof(TPaletteEntry);
     //pLogPalle:=MemAlloc(PalSize);
     //getmem(Plogpalle, palsize);
     pLogPalle.palVersion:=$0300;
     pLogPalle.palNumEntries:=256;
     //
     for i:=0 to GRPCOLLEN do
     begin
     pLogPalle.palPalEntry[i].peRed:=GR[I];
     pLogPalle.palPalEntry[i].peGreen:=GG[I];
     pLogPalle.palPalEntry[i].peBlue:=GB[I];
     pLogPalle.palPalEntry[i].peFlags:=PC_EXPLICIT;
     end;
   //
     Palle:=CreatePalette(pLogPalette(@plogpalle)^);
     BUFBMP.Palette := PALLE; }
  end;
end;

procedure TForm3.Button4Click(Sender: TObject);
begin
  displaygrplist;
end;

procedure TForm3.Button5Click(Sender: TObject);
var
  I, len: integer;
  idx, grp: integer;
begin
  len := 0;
  idx := filecreate(edit1.Text);
  grp := filecreate(edit2.Text);
  for I := 0 to filenum - 1 do
  begin
    inc(len, GRPpic[I].size);
    filewrite(idx, len, 4);
    if GRPpic[I].size > 0 then
      filewrite(grp, GRPpic[I].data[0], GRPpic[I].size);
  end;
  fileclose(idx);
  fileclose(grp);
end;

procedure TForm3.Button6Click(Sender: TObject);
var
  //tempcol1: cardinal;
  //tempstr:string;
  ini: Tinifile;
begin
  {//canvas的颜色顺序是BGR,而游戏中顺序是RGB
  tempcol1 := (GRPlistBackGround and $FF0000) shr 16 + GRPlistBackGround and $FF00 + (GRPlistBackGround and $FF) shl 16;
  tempstr := inputbox('自定义颜色','请以十六进制方式输入（RGB）',Format('%x',[tempcol1]));
  if strtoint('$' + tempstr) <> tempcol1 then
  begin
    tempcol1 := strtoint('$' + tempstr);
    GRPlistBackGround := (tempcol1 and $FF0000) shr 16 + tempcol1 and $FF00 + (tempcol1 and $FF) shl 16;
    image2.Canvas.Brush.Color := grpLISTBACKGROUND;
    image2.Canvas.FillRect(image2.Canvas.ClipRect);
    try
      ini := Tinifile.Create(StartPath + iniFilename);
      ini.Writeinteger('file','GRPListBackGround',GRPListBackGround);
    finally
      ini.Free;
    end;
  end; }
  colordialog1.Color := grpLISTBACKGROUND;
  if colordialog1.Execute then
  begin
    grplistbackground := colordialog1.Color;
    image2.Canvas.Brush.Color := grpLISTBACKGROUND;
    image2.Canvas.FillRect(image2.Canvas.ClipRect);
    display;
    try
      ini := Tinifile.Create(StartPath + iniFilename);
      ini.Writeinteger('file','GRPListBackGround',GRPListBackGround);
    finally
      ini.Free;
    end;
  end;

end;

procedure TForm3.Button7Click(Sender: TObject);
var
  //tempcol1: cardinal;
  //tempstr:string;
  ini: Tinifile;
begin
{  //canvas的颜色顺序是BGR,而游戏中顺序是RGB
  tempcol1 := (GRPlistTextCol and $FF0000) shr 16 + GRPlistTextCol and $FF00 + (GRPlistTextCol and $FF) shl 16;
  tempstr := inputbox('自定义颜色','请以十六进制方式输入（RGB）',Format('%x',[tempcol1]));
  if strtoint('$' + tempstr) <> tempcol1 then
  begin
    tempcol1 := strtoint('$' + tempstr);
    GRPlistTextCol := (tempcol1 and $FF0000) shr 16 + tempcol1 and $FF00 + (tempcol1 and $FF) shl 16;
    image3.Canvas.Brush.Color := GRPlistTextCol;
    image3.Canvas.FillRect(image3.Canvas.ClipRect);
    try
      ini := Tinifile.Create(StartPath + iniFilename);
      ini.Writeinteger('file','GRPlistTextCol',GRPlistTextCol);
    finally
      ini.Free;
    end;
  end; }
  colordialog1.Color := GRPlistTextCol;
  if colordialog1.Execute then
  begin
    grplisttextcol := colordialog1.Color;
    image3.Canvas.Brush.Color := GRPlistTextCol;
    image3.Canvas.FillRect(image3.Canvas.ClipRect);
    display;
    try
      ini := Tinifile.Create(StartPath + iniFilename);
      ini.Writeinteger('file','GRPlistTextCol',GRPlistTextCol);
    finally
      ini.Free;
    end;
  end;

end;

procedure TForm3.Button8Click(Sender: TObject);
var
  BeginGrpset, EndGrpset, I, offsetpos, temp, setint: integer;
begin
  try
    BeginGrpset := strtoint(edit4.Text);
    EndGrpset := strtoint(edit5.Text);
    setint := strtoint(edit6.Text);
  except
    exit;
  end;
  offsetpos := 4;
  if BeginGrpset > EndGrpset then
  begin
    temp := BeginGrpset;
    BeginGrpset := EndGrpset;
    EndGrpset := temp;
  end;
  for I := BeginGrpset to EndGrpset do
  begin
    if (I < 0) then
      continue;
    if (I >= filenum) then
      break;
    if grppic[I].size < 8 then
      continue;
    if calPNG(@grppic[I].data[0]) = 1 then
      continue;
    case Combobox3.ItemIndex of
      0: PSmallint(@grppic[I].data[offsetpos])^ := setint;
      1: PSmallint(@grppic[I].data[offsetpos])^ := PSmallint(@grppic[I].data[offsetpos])^ + setint;
      2: PSmallint(@grppic[I].data[offsetpos])^ := PSmallint(@grppic[I].data[offsetpos])^ - setint;
      3: PSmallint(@grppic[I].data[offsetpos])^ := PSmallint(@grppic[I].data[offsetpos])^ * setint;
      4: PSmallint(@grppic[I].data[offsetpos])^ := PSmallint(@grppic[I].data[offsetpos])^ div setint;
    end;
  end;
end;

procedure TForm3.Button9Click(Sender: TObject);
begin
  Button8Click(sender);
  Button10Click(sender);
end;

procedure TForm3.displaygrplist;
var
  ScoH: integer;
  I, I2: integer;
  offset: array of integer;
  idx,grp, filelen, param: integer;
begin
  if not(fileexists(edit1.Text) and fileexists(edit2.Text)) then
  begin
    filenum := 0;
    setlength(GRPpic, 0);
    bufbmp.Canvas.Brush.Style := bsSolid;
    bufbmp.Canvas.Brush.Color := CLWHITE;//$74A89C;//$FCFCFC;//usualtrans;
    bufbmp.Canvas.FillRect(bufbmp.Canvas.ClipRect);
    bufbmp2.Canvas.CopyRect(bufbmp2.Canvas.ClipRect,bufbmp.Canvas,bufbmp.Canvas.ClipRect);
    image1.Canvas.CopyRect(image1.Canvas.ClipRect,bufbmp.Canvas,bufbmp.Canvas.ClipRect);
    scrollbar2.max := 0;
    showmessage('idx或grp文件不存在！');
    exit;
  end;
  idx := fileopen(edit1.Text, fmopenread);
  filelen := fileseek(idx, 0, 2);
  fileseek(idx, 0, 0);
  if filelen mod 4 <> 0 then
  begin
    filenum := 0;
    setlength(GRPpic, 0);
    scrollbar2.max := 0;
    bufbmp.Canvas.Brush.Style := bsSolid;
    bufbmp.Canvas.Brush.Color := CLWHITE;//$74A89C;//$FCFCFC;//usualtrans;
    bufbmp.Canvas.FillRect(bufbmp.Canvas.ClipRect);
    bufbmp2.Canvas.CopyRect(bufbmp2.Canvas.ClipRect,bufbmp.Canvas,bufbmp.Canvas.ClipRect);
    image1.Canvas.CopyRect(image1.Canvas.ClipRect,bufbmp.Canvas,bufbmp.Canvas.ClipRect);
    showmessage('idx文件错误！');
    exit;
  end;

  try
  filenum := filelen div 4;
  setlength(offset, filenum);
  fileread(idx, offset[0], filelen);
  fileclose(idx);
  param := 0;
  setlength(grppic, filenum);
  grp := fileopen(edit2.Text, fmopenread);
  fileseek(grp,0,0);

  for I := 0 to filenum - 1 do
  begin
    grppic[i].size := offset[i] - param;
    param := offset[i];
    if GRPpic[I].size > 0 then
    begin
      setlength(GRPpic[i].data, grppic[i].size);
      fileread(grp, GRPpic[i].data[0], GRPpic[i].size);
    end
    else
    begin
      grppic[i].size := 0;
      setlength(GRPpic[i].data, grppic[i].size);
    end;

  end;
  fileclose(grp);
  except
    filenum := 0;
    setlength(GRPpic, 0);
    scrollbar2.max := 0;
    bufbmp.Canvas.Brush.Style := bsSolid;
    bufbmp.Canvas.Brush.Color := CLWHITE;//$74A89C;//$FCFCFC;//usualtrans;
    bufbmp.Canvas.FillRect(bufbmp.Canvas.ClipRect);
    bufbmp2.Canvas.CopyRect(bufbmp2.Canvas.ClipRect,bufbmp.Canvas,bufbmp.Canvas.ClipRect);
    image1.Canvas.CopyRect(image1.Canvas.ClipRect,bufbmp.Canvas,bufbmp.Canvas.ClipRect);
    showmessage('grp文件错误！');

    fileclose(grp);
    fileclose(idx);
    exit;
  end;
  combobox2.Clear;
  combobox2.Items.Add('全部');
  combobox2.ItemIndex := 0;
  beginpic := 0;
  endpic := filenum - 1;
  for I := 0 to grplistnum - 1 do
  begin
    if gamepath + grplistgrp[I] = edit2.Text then
    begin
      if grplistSection[I].num > 0 then
      begin
        piccount := I;
        for I2 := 0 to grplistSection[I].num - 1 do
          combobox2.Items.Add(grplistSection[I].tag[I2]);
      end;
      break;
    end;
  end;
  ScoH := max((filenum - 1), 0) div grplistlinepicnum;
  scrollbar2.max := ScoH;
  scrollbar2.Position := 0;
  nowpic := 0;
  //nowpic := scrollbar2.position * linepic;
  try
    display;
  except
    showmessage('错误！');
    exit;
  end;
  Form3initial := true;
end;

procedure TForm3.ComboBox1Change(Sender: TObject);
var
  temp: integer;
  namestr, opstr: string;
begin
  if ComboBox1.ItemIndex < 0 then
    exit;
  if ComboBox1.ItemIndex < grplistnum then
  begin
    if grplistnum > 0 then
    begin
      edit1.Text := gamepath + grplistidx[combobox1.itemindex];
      edit2.Text := gamepath + grplistgrp[combobox1.itemindex];
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
    edit1.Text := gamepath + opstr;
    opstr := fightgrp;
    opstr := stringreplace(opstr, '***', namestr,[rfReplaceAll]);
    edit2.Text := gamepath + opstr;
  end;

  Button4Click(Sender);
end;

procedure TForm3.ComboBox2Change(Sender: TObject);
begin
  if combobox2.ItemIndex = 0 then
  begin
    beginpic := 0;
    endpic := filenum - 1;
  end
  else
  begin
    beginpic := grplistsection[piccount].beginnum[combobox2.ItemIndex - 1];
    if grplistsection[piccount].endnum[combobox2.ItemIndex - 1] = -2 then
      endpic := filenum - 1
    else
      endpic := grplistsection[piccount].endnum[combobox2.ItemIndex - 1] - 1;
  end;
  scrollbar2.max := max((endpic - beginpic), 0) div grplistlinepicnum;
  scrollbar2.Position := 0;
  nowpic := beginpic;
  display;
end;

procedure TForm3.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  filenum := 0;
  copynum := -1;
  setlength(grplistcopydata, 0);
  setlength(grppic, filenum);
  CFOrm3 := true;
  bufbmp.Free;
  bufbmp2.Free;
  bufbmp3.Free;
  Form3initial := false;
  action := cafree;
end;

procedure TForm3.FormCreate(Sender: TObject);
var
  H,len,I: integer;
  filename: string;
  // PalSize:longint;
  //  pLogPalle:TMaxLogPalette;
  //  PalleEntry:TPaletteEntry;
 //   Palle:HPalette;
begin

  grplistsquareW := image1.Width div grplistlinepicnum;
  image2.Canvas.Brush.Color := GRPlistBackGround;
  image2.Canvas.FillRect(image2.Canvas.ClipRect);

  image3.Canvas.Brush.Color := GRPlistTextCol;
  image3.Canvas.FillRect(image3.Canvas.ClipRect);

  copynum := -1;

  filename := gamepath + palette;
  if fileexists(filename) then
  begin
    edit3.Text := FileName;
    H := FIleopen(edit3.Text, fmopenread);
    len := fileseek(H, 0, 2);
    fileseek(H,0,0);
    //grpcollen := len div 3;
    grpcollen := 256;
    for I := 0 to 256 - 1 do
    begin
      fileread(H, GR[I], 1);
      fileread(H, GG[I], 1);
      fileread(H, GB[I], 1);
      GB[I] := GB[I] shl 2;
      GG[I] := GG[I] shl 2;
      GR[I] := GR[I] shl 2;
    end;
    fileclose(H);
  end;
 { PalSize:=sizeof(TLogPalette) + 256 * sizeof(TPaletteEntry);
     //pLogPalle:=MemAlloc(PalSize);
     //getmem(Plogpalle, palsize);
     pLogPalle.palVersion:=$0300;
     pLogPalle.palNumEntries:=256;
     //
     for i:=0 to 255 do
     begin
     pLogPalle.palPalEntry[i].peRed:=GR[I];
     pLogPalle.palPalEntry[i].peGreen:=GG[I];
     pLogPalle.palPalEntry[i].peBlue:=GB[I];
     pLogPalle.palPalEntry[i].peFlags:=PC_EXPLICIT;
     end;
   //
     Palle:=CreatePalette(pLogPalette(@plogpalle)^);
      bufbmp := TBitmap.Create;
     BUFBMP.PixelFormat := pf8bit;
     BUFBMP.Palette := palle;    }

  bufbmp := TBitmap.Create;
  BUFBMP.PixelFormat := pf24bit;
  bufbmp.Canvas.Brush.Color := GRPlistBackGround; //usualtrans;
  bufbmp.Canvas.FillRect(bufbmp.Canvas.ClipRect);
  bufbmp.Canvas.Font.Color := GRPlisttextcol;//clyellow;
  bufbmp.Canvas.Font.Size := 10;
  bufbmp.Canvas.Font.Name := '宋体';
  bufbmp.Canvas.Brush.Style := bsclear;

  bufbmp2 := Tbitmap.Create;
  bufbmp2.PixelFormat := pf24bit;
  bufbmp2.Width := bufbmp.Width;
  bufbmp2.Height := bufbmp.Height;

  bufbmp3 := Tbitmap.Create;
  bufbmp3.PixelFormat := pf24bit;

  combobox1.Items.Clear;
  if grplistnum > 0 then
    for I := 0 to grplistnum - 1 do
      combobox1.Items.Add(displayname(grplistname[I]));
  if fightgrpnum > 0 then
    for I := 0 to fightgrpnum - 1 do
      combobox1.Items.Add(displayname(fightname + inttostr(I)));
  Radiogroup1.ItemIndex := grplistselect;
end;

procedure TForm3.FormResize(Sender: TObject);
begin
  image1.Picture.Bitmap.Width := image1.Width;
  image1.Picture.Bitmap.Height := image1.Height;
  bufbmp.Width := image1.Width;
  bufbmp.Height := image1.Height;
  bufbmp2.Width := bufbmp.Width;
  bufbmp2.Height := bufbmp.Height;
  grplistsquareW := image1.Width div grplistlinepicnum;
  if Form3Initial then
    display;
end;

procedure TForm3.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Form3initial and (button = mbLeft) and (temppic <= endpic{filenum}) and (temppic >= 0) then
  begin
    image1.BeginDrag(true);
  end;
end;

procedure TForm3.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  ix, iy, sx, sy, caltemppic, temph:integer;
begin
  //
  if needdraw then
  begin
    display;
    needdraw := false;
    temppic := -1;
  end;

  if Form3initial then
  begin

    sx := X div grplistsquarew;
    sy := Y div grplistsquareh;

    //y div squareh;
  //grplistlinenum
 // grplistline

  caltemppic := sx + sy * grplistlinepicnum + nowpic;

  if (caltemppic > endpic) then
    caltemppic := -1;
  //showmessage(inttostr(caltemppic) + ' ' + inttostr(temppic));
  if (caltemppic <> temppic) then
  begin
    //showmessage(inttostr(sx));

    if  (Sx < grplistlinepicnum) and (caltemppic <= endpic) and (caltemppic >= 0) then
    begin

      temppic := caltemppic;

      image1.Canvas.CopyRect(image1.Canvas.ClipRect, bufbmp2.Canvas, bufbmp2.Canvas.ClipRect);
      Drawsquare(sx * grplistsquarew, sy * grplistsquareh);

      {for ix := sx * grplistsquarew to (sx + 1) * grplistsquarew - 1 do
      begin
        image1.Canvas.Pixels[ix, temph - grplistline[sy]] := GRPListTextCol;
        image1.Canvas.Pixels[ix, temph] := GRPListTextCol;
      end;
      for iy := temph - grplistline[sy] to temph do
      begin
        image1.Canvas.Pixels[sx * squarew  - scrollbar1.Position, iy] := GRPListTextCol;
        image1.Canvas.Pixels[sx * squarew  - scrollbar1.Position + squarew, iy] := GRPListTextCol;
      end;}

    end
    else
    begin


      temppic := -1;
      image1.Canvas.CopyRect(image1.Canvas.ClipRect, bufbmp2.Canvas, bufbmp2.Canvas.ClipRect);
    end;

  end;
  end;

end;

procedure TForm3.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  tempx,tempy: integer;
  mpos: TPoint;
begin
  if (temppic < filenum) and (Button = mbRight) and Form3initial then
  begin
    if copynum >= 0 then
      n4.Enabled := true
    else
      n4.Enabled := false;
    movelock := temppic;
    if mainform.panel2.Visible then
      tempx := mainform.Panel2.Width
    else
      tempx := 0;

    if mainform.Panel1.Visible then
      tempy := mainform.Panel1.Height
    else
      tempy := 0;
    if temppic < 0 then
    begin
      N1.Enabled := false;
      PNG2.Enabled := false;
      PNGRLE81.Enabled := false;
      N3.Enabled := false;
      N4.Enabled := false;
      N2.Enabled := false;
      N7.Enabled := false;
    end
    else
    begin
      N1.Enabled := true;
      PNG2.Enabled := true;
      PNGRLE81.Enabled := true;
      N3.Enabled := true;
      N2.Enabled := true;
      N7.Enabled := true;
    end;
    //popupmenu1.Popup(x + self.Left + tempx + mainform.Left,y + panel1.Height + self.Top + tempy + mainform.Top);
    getcursorpos(mpos);
    //self.enabled := false;
    popupmenu1.Popup(mpos.X,mpos.Y);

  end;
end;

procedure TForm3.Image1StartDrag(Sender: TObject; var DragObject: TDragObject);
begin
  movelock := temppic;
  //image1.BeginDrag(true);
end;

procedure TForm3.Image2Click(Sender: TObject);
begin
  Button6Click(sender);
end;

procedure TForm3.Image3Click(Sender: TObject);
begin
  Button7Click(sender);
end;

procedure drawRLE8(Ppic: Pbyte; len: integer; PBMP: PntBitMap; dx, dy: integer; canmove: boolean);
var
  state,i, iy, ix, linesize, temp: integer;
  pw,ph,xs,ys: integer;
  //tempgrpbmp: Tbitmap;
 // tempcolor: array of array of byte;
begin
  //

 { tempgrpbmp := TBitmap.Create;
  tempgrpbmp.Width := PBMP.Width;
  tempgrpbmp.Height := PBMP.Height;
  tempgrpbmp.PixelFormat := pf24bit;
  tempgrpbmp.Canvas.CopyRect(tempgrpbmp.Canvas.ClipRect, PBMP.Canvas, PBMP.Canvas.ClipRect);
  setlength(tempcolor, tempgrpbmp.Height, tempgrpbmp.Width * 3);
  for I := 0 to tempgrpbmp.Height - 1 do
    copymemory(@tempcolor[I][0],tempgrpbmp.ScanLine[I],tempgrpbmp.Width * 3);   }

  if len >8 then
  begin
  pw := Psmallint((Ppic))^;
  Inc(Ppic, 2);
  ph := Psmallint((Ppic))^;
  Inc(Ppic, 2);
  xs := Psmallint((Ppic))^;
  Inc(Ppic, 2);
  ys := Psmallint((Ppic))^;
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
        //if ((iy + dy) in [0..tempgrpbmp.Height - 1]) and (ix in [0..tempgrpbmp.width - 1]) then
       // begin
          //tempcolor[iy + dy][ix * 3] := GB[temp];
          //tempcolor[iy + dy][ix * 3 + 1] := GG[temp];
          //tempcolor[iy + dy][ix * 3 + 2] := GR[temp];
          PBMP.canvas.Pixels[ix, iy + dy] := (GB[temp] shl 16) or (GG[temp] shl 8) or GR[temp];
        //end;
        dec(state);
        inc(ix);
      end;


    end;
    inc(Ppic, linesize);
  end;
  end;

end;
{
function TForm3.judgeWH: Trect;
var
  Dw,dh, i, iy, ix, tempx, tempy, tempw, temppic, lines: integer;
begin
  dw := 0;
  dh := 0;
  iy := 0;
  ix := 0;
  temppic := nowpic;
  lines := 0;
  while iy < image1.height do
  begin
    inc(lines);
    tempx := 0;
    for I := 0 to linepic - 1 do
    begin
      tempw := (Psmallint(@(grppic[I + temppic].data[0])))^;
      inc(tempx, tempw);
      if tempw > dw then
        dw := tempw;
      tempy := (Psmallint(@(grppic[I + temppic].data[2])))^;
      if tempy > dh then
        dh := tempy;
    end;
    iy := dh * lines;
  end;
  if dw * linepic - image1.width >0 then
    scrollbar1.max := dw * linepic - image1.width;
  result.top := dh;
  result.left := dw;
  result.bottom := lines;
end;
}

procedure TForm3.N1Click(Sender: TObject);
var
  i, tempslt: integer;
  tempstr: string;
  PNGrs: TPNGObject;
  temprs: Tmemorystream;
begin
  drawbmp:= Tbitmap.Create;
  drawbmp.PixelFormat := pf24bit;
  temppic := movelock;
  if (grppic[temppic].size >= 8) and (calPNG(@(grppic[temppic].data[0])) = 1) then
  begin
    if Radiogroup1.ItemIndex = 0 then
    begin
    tempslt := messagebox(self.Handle,'此图片为PNG格式，是否想存为RLE8格式？选择“是”保存为RLE8格式；选择“否”用一个PNG替换；选择“取消”结束当前操作。','提示', MB_YESNOCANCEL);
    if tempslt = IDNo then
    begin
      opendialog1.Filter := 'PNG files (*.Png)|*.Png|All files (*.*)|*.*';
      tempstr := opendialog1.Title;
      opendialog1.Title := '选择一个PNG图片替换当前';
      if opendialog1.Execute then
      begin
        tempslt := fileopen(opendialog1.FileName, fmopenread);
        grppic[temppic].size := fileseek(tempslt,0,2);
        setlength(grppic[temppic].data, grppic[temppic].size);
        fileseek(tempslt,0,0);
        fileread(tempslt, grppic[temppic].data[0], grppic[temppic].size);
        fileclose(tempslt);
      end;
      opendialog1.Title := tempstr;
      display;
      exit;
    end
    else if tempslt = IDYes then
    begin
      PNGrs := TPNGObject.Create;
      temprs := Tmemorystream.Create;
      temprs.SetSize(grppic[temppic].size);
      temprs.Position := 0;
      temprs.Write(grppic[temppic].data[0],grppic[temppic].size);
      temprs.Position := 0;
      PNGrs.LoadFromStream(temprs);
      drawbmp.Width := PNGrs.Width;
      drawbmp.height := PNGrs.height;
      xmove := 0;
      ymove := 0;
      drawbmp.Canvas.Brush.Color := usualtrans;
      drawbmp.Canvas.FillRect(drawbmp.Canvas.ClipRect);
      PNGrs.Draw(drawbmp.Canvas,drawbmp.Canvas.ClipRect);
      PNGrs.Free;
      temprs.Free;
    end
    else if tempslt = IDCancel then
      exit
    else
      exit;
    end
    else if Radiogroup1.ItemIndex = 1 then
    begin
      opendialog1.Filter := 'PNG files (*.Png)|*.Png|All files (*.*)|*.*';
      tempstr := opendialog1.Title;
      opendialog1.Title := '选择一个PNG图片替换当前';
      if opendialog1.Execute then
      begin
        tempslt := fileopen(opendialog1.FileName, fmopenread);
        grppic[temppic].size := fileseek(tempslt,0,2);
        setlength(grppic[temppic].data, grppic[temppic].size);
        fileseek(tempslt,0,0);
        fileread(tempslt, grppic[temppic].data[0], grppic[temppic].size);
        fileclose(tempslt);
      end;
      opendialog1.Title := tempstr;
      display;
      exit;
    end
    else if Radiogroup1.ItemIndex = 2 then
    begin
      PNGrs := TPNGObject.Create;
      temprs := Tmemorystream.Create;
      temprs.SetSize(grppic[temppic].size);
      temprs.Position := 0;
      temprs.Write(grppic[temppic].data[0],grppic[temppic].size);
      temprs.Position := 0;
      PNGrs.LoadFromStream(temprs);
      drawbmp.Width := PNGrs.Width;
      drawbmp.height := PNGrs.height;
      xmove := 0;
      ymove := 0;
      drawbmp.Canvas.Brush.Color := usualtrans;
      drawbmp.Canvas.FillRect(drawbmp.Canvas.ClipRect);
      PNGrs.Draw(drawbmp.Canvas,drawbmp.Canvas.ClipRect);
      PNGrs.Free;
      temprs.Free;
    end;

  end
  else if (grppic[temppic].size >= 8) then
  begin
    try
      drawbmp.Width := (Psmallint(@(grppic[temppic].data[0])))^;
      drawbmp.Height := (Psmallint(@(grppic[temppic].data[2])))^;
      xmove := (Psmallint(@(grppic[temppic].data[4])))^;
      Ymove := (Psmallint(@(grppic[temppic].data[6])))^;
    except
      drawbmp.Width := 0;
      drawbmp.Height := 0;
      xmove := 0;
      Ymove := 0;
    end;
    drawbmp.Canvas.Brush.Color := usualtrans;
    drawbmp.Canvas.FillRect(drawbmp.Canvas.ClipRect);
    try
      drawRLE8(@(grppic[temppic].data[0]),grppic[temppic].size,@drawbmp,0,0,false);
    except
      //
    end;
  end
  else
  begin
    drawbmp.Width := 0;
    drawbmp.Height := 0;
    xmove := 0;
    Ymove := 0;
  end;

  edittype := grp;
  tempcollen := 256;//collen;
  collen := 256;//grpcollen;
  for I := 0 to 255 do
  begin
    copymemory(@TEMPR[0],@R[0],256);
    copymemory(@TEMPB[0],@B[0],256);
    copymemory(@TEMPG[0],@G[0],256);
    copymemory(@R[0],@GR[0],256);
    copymemory(@B[0],@GB[0],256);
    copymemory(@G[0],@GG[0],256);
  end;

  Form2.Initial;
  //Form2.Visible := false;
  //Application.CreateForm(TFORM2,Form2);

  Form2.Panel2.Visible := true;
  Form2.Drawpallet;
  Form2.Edit1.Text := inttostr(drawbmp.Width);
  Form2.Edit2.Text := inttostr(drawbmp.Height);
  Form2.Edit3.Text := inttostr(xmove);
  FOrm2.Edit4.Text := inttostr(ymove);
  Form2.Caption := form2title + ' - ' + inttostr(temppic);
  Form2.ShowModal;
  display;
  temppic := -1;
end;


procedure TForm3.N2Click(Sender: TObject);
var
  I: Integer;
begin
  temppic := movelock;
  if filenum = 1 then
    showmessage('只剩一张图片，不可以删除')
  else if temppic = filenum - 1 then
  begin
    dec(filenum);
    setlength(GRPpic, filenum);
  end
  else if temppic < filenum - 1 then
  begin
    for I := temppic to filenum - 2 do
      copygrp(I + 1, I);
    dec(filenum);
    setlength(GRPpic, filenum);
  end;
  temppic := -1;

  if combobox2.ItemIndex = 0 then
  begin
    //beginpic := 0;
    endpic := filenum - 1;
  end
  else
  begin
    //beginpic := grplistsection[piccount].beginnum[combobox2.ItemIndex - 1];
    if grplistsection[piccount].endnum[combobox2.ItemIndex - 1] = -2 then
      endpic := filenum - 1
    else
      endpic := grplistsection[piccount].endnum[combobox2.ItemIndex - 1];
  end;
  scrollbar2.max := max((endpic - beginpic), 0) div grplistlinepicnum;
  //scrollbar2.Position := 0;
  //nowpic := beginpic;
  //scrollbar2.max := filenum div linepic;
  display;
end;

procedure TForm3.N3Click(Sender: TObject);
var
  I1,I2: integer;
  FormH, temphandle: cardinal;
  tempdata: array of byte;
  tempquit: boolean;
  tempbuf: TCopyDataStruct;
  //tempstr: Ansistring;
  tempchar: PAnsichar;
begin
  temppic := movelock;
  //copynum := temppic;
  GRPpic[temppic].size := max(GRPpic[temppic].size,0);
  copynum := GRPpic[temppic].size;
  setlength(tempdata, GRPpic[temppic].size + 1);
  setlength(grplistcopydata, GRPpic[temppic].size);
  tempdata[0] := 1;
  Pinteger(@tempdata[1])^ := GRPpic[temppic].size;
  if GRPpic[temppic].size > 0 then
  begin
    copymemory(@Tempdata[5], @GRPpic[temppic].data[0], GRPpic[temppic].size);
    copymemory(@grplistcopydata[0], @GRPpic[temppic].data[0], GRPpic[temppic].size);
  end;
  temphandle := 0;
  tempquit := true;
  getmem(tempchar, GRPpic[temppic].size + 5);

  tempbuf.dwData := GRPpic[temppic].size + 5;
  tempbuf.cbData := GRPpic[temppic].size + 5;
  tempbuf.lpData := tempchar;
  copymemory(tempchar,@tempdata[0], GRPpic[temppic].size + 5);
  while (tempquit) do
  begin
    FormH := 0;
    try
    FormH := FindWindowEx(0,temphandle, 'TUPeditMainForm', nil);
    if FormH = 0 then
    begin
      tempquit := false;
    end
    else
    begin
      temphandle := FormH;
      if FormH <> mainform.Handle then
      begin
        sendmessage(Formh, WM_COPYDATA, 0, integer(@tempbuf));
      end;
    end;
    except

    end;
  end;
end;

procedure TForm3.N4Click(Sender: TObject);
begin
  temppic := movelock;
  //copyGRP(copynum, temppic);
  GRPpic[temppic].size := length(grplistcopydata);
  setlength(GRPpic[temppic].data, GRPpic[temppic].size);
  if GRPpic[temppic].size > 0 then
    copymemory(@GRPpic[temppic].data[0], @grplistcopydata[0], GRPpic[temppic].size);
  temppic := -1;
  display;
end;

procedure TForm3.N5Click(Sender: TObject);
var
  I, len: integer;
  idx, grp: integer;
begin
  len := 0;
  idx := filecreate(edit1.Text);
  grp := filecreate(edit2.Text);
  for I := 0 to filenum - 1 do
  begin
    inc(len, GRPpic[I].size);
    filewrite(idx, len, 4);
    if GRPpic[I].size > 0 then
      filewrite(grp, GRPpic[I].data[0], GRPpic[I].size);
  end;
  fileclose(idx);
  fileclose(grp);
end;

procedure TForm3.N6Click(Sender: TObject);
var
  I: integer;
begin

  inc(filenum);
  setlength(GRPpic, filenum);
  GRPpic[filenum - 1].size := 8;
  setlength(GRPpic[filenum - 1].data, GRPpic[filenum - 1].size);
  for I := 0 to GRPpic[filenum - 1].size - 1 do
    GRPpic[filenum - 1].data[I] := 0;
  temppic := -1;

  if combobox2.ItemIndex = 0 then
  begin
    //beginpic := 0;
    endpic := filenum - 1;
  end
  else
  begin
    //beginpic := grplistsection[piccount].beginnum[combobox2.ItemIndex - 1];
    if grplistsection[piccount].endnum[combobox2.ItemIndex - 1] = -2 then
      endpic := filenum - 1
    else
      endpic := grplistsection[piccount].endnum[combobox2.ItemIndex - 1];
  end;
  scrollbar2.max := max((endpic - beginpic), 0) div grplistlinepicnum;
  //scrollbar2.Position := 0;
  //nowpic := beginpic;
  //scrollbar2.max := filenum div linepic;
  display;
end;

procedure TForm3.N7Click(Sender: TObject);
var
  I: Integer;
begin
  temppic := movelock;
  inc(filenum);
  setlength(GRPpic, filenum);
  for I := filenum - 2 downto temppic do
  begin
    copygrp(I, I + 1);
  end;

  GRPpic[temppic].size := 0;
  setlength(GRPpic[temppic].data, GRPpic[temppic].size);
  temppic := -1;

  if combobox2.ItemIndex = 0 then
  begin
    //beginpic := 0;
    endpic := filenum - 1;
  end
  else
  begin
    //beginpic := grplistsection[piccount].beginnum[combobox2.ItemIndex - 1];
    if grplistsection[piccount].endnum[combobox2.ItemIndex - 1] = -2 then
      endpic := filenum - 1
    else
      endpic := grplistsection[piccount].endnum[combobox2.ItemIndex - 1];
  end;
  scrollbar2.max := max((endpic - beginpic), 0) div grplistlinepicnum;
  //scrollbar2.Position := 0;
  //nowpic := beginpic;
  //scrollbar2.max := filenum div linepic;
  display;
end;

procedure TForm3.PNG1Click(Sender: TObject);
{var
  I, PF : integer;
  dir,filename: string;
  Savebufbmp: Tbitmap;
  PNGrs: TPNGimage;
  ix,iy: integer;
  Pdat:Pbytearray;
begin
  //
  if SelectDirectory('选择保存文件夹',dir,Dir) then
  begin
    if dir[length(dir)] <> '\' then
      dir :=dir + '\';
    savebufbmp := Tbitmap.Create;
    for I := 0 to filenum - 1 do
    begin
      if grppic[I].size > 8 then
      begin
        savebufbmp.Width := (Psmallint(@(grppic[I].data[0])))^;
        savebufbmp.height := (Psmallint(@(grppic[I].data[2])))^;
        savebufbmp.Canvas.Brush.Color := usualtrans;
        savebufbmp.Canvas.FillRect(savebufbmp.Canvas.ClipRect);
        drawRLE8(@(grppic[I].data[0]),grppic[I].size,@savebufbmp,0,0,false);
        PNGrs := TPNGimage.create;
        PNGrs.Assign(savebufbmp);
        PNGrs.CreateAlpha;
        for iy := 0 to savebufbmp.Height - 1 do
        begin
          Pdat := PNGrs.AlphaScanline[iy];
          for ix := 0 to savebufbmp.Width - 1 do
            if savebufbmp.Canvas.Pixels[ix, iy] = usualtrans then
              Pdat[ix] := 0;
        end;
        filename := dir + inttostr(I) +'.png';
        PNGrs.SaveToFile(filename);
        PNGrs.Free;
      end;
    end;
    showmessage('保存成功');
  end;}

begin
  colfilename := edit3.Text;
  grpfilename := edit2.Text;
  idxfilename := edit1.Text;
  Form88.showmodal;
end;

procedure TForm3.PNG2Click(Sender: TObject);
var
  tempstr: string;
  tempslt: integer;
begin
  temppic := movelock;
  opendialog1.Filter := 'PNG files (*.Png)|*.Png|All files (*.*)|*.*';
  tempstr := opendialog1.Title;
  opendialog1.Title := '选择一个PNG图片替换当前';
  if opendialog1.Execute then
  begin
    tempslt := fileopen(opendialog1.FileName, fmopenread);
    grppic[temppic].size := fileseek(tempslt,0,2);
    setlength(grppic[temppic].data, grppic[temppic].size);
    fileseek(tempslt,0,0);
    fileread(tempslt, grppic[temppic].data[0], grppic[temppic].size);
    fileclose(tempslt);
    display;
  end;
  opendialog1.Title := tempstr;

end;

procedure TForm3.PNGRLE81Click(Sender: TObject);
var
  tempstr: string;
  tempslt, I: integer;
  PNGrs:TPNGObject;
  tempbmp:Tbitmap;
  rs:Tmemorystream;
begin
  temppic := movelock;
  opendialog1.Filter := 'PNG files (*.Png)|*.Png|All files (*.*)|*.*';
  tempstr := opendialog1.Title;
  opendialog1.Title := '选择一个PNG图片替换当前';
  if opendialog1.Execute then
  begin
    try
    tempcollen := collen;
    collen := grpcollen;
    for I := 0 to 255 do
    begin
      tempR[I] := R[I];
      tempB[I] := B[I];
      tempG[I] := G[I];
      R[I] := GR[I];
      B[I] := GB[I];
      G[I] := GG[I];
      {opymemory(@TEMPR[0],@R[0],256);
      copymemory(@TEMPB[0],@B[0],256);
      copymemory(@TEMPG[0],@G[0],256);
      copymemory(@R[0],@GR[0],256);
      copymemory(@B[0],@GB[0],256);
      copymemory(@G[0],@GG[0],256); }
    end;
    tempslt := fileopen(opendialog1.FileName, fmopenread);
    grppic[temppic].size := fileseek(tempslt,0,2);
    setlength(grppic[temppic].data, grppic[temppic].size);
    fileseek(tempslt,0,0);
    fileread(tempslt, grppic[temppic].data[0], grppic[temppic].size);
    fileclose(tempslt);
    rs := Tmemorystream.Create;
    rs.setsize(grppic[temppic].size);
    rs.Position := 0;
    rs.Write(grppic[temppic].data[0], grppic[temppic].size);
    rs.Position := 0;
    PNGrs := TPNGObject.Create;
    PNGrs.LoadFromStream(rs);

    tempbmp := TBitmap.Create;
    tempbmp.Width := PNGrs.Width;
    tempbmp.Height := PNGrs.Height;
    tempbmp.Canvas.Brush.Color := usualtrans;
    tempbmp.Canvas.FillRect(tempbmp.Canvas.ClipRect);
    PNGrs.Draw(tempbmp.Canvas, tempbmp.Canvas.ClipRect);

    setlength(grppic[temppic].data, (2 + tempbmp.Width) * tempbmp.Height * 2 + 20);
    grppic[temppic].size := PicToRLE8(@grppic[temppic].data[0], tempbmp.Width, tempbmp.Height,0,0,@tempbmp, tempbmp.Canvas.ClipRect, true, usualtrans);
    setlength(grppic[temppic].data, grppic[temppic].size);

    finally

      for I := 0 to 255 do
      begin
        R[I] := tempR[I];
        B[I] := tempB[I];
        G[I] := tempG[I];
      end;
      collen := tempcollen;
      PNGrs.Destroy;
      tempbmp.Free;
      rs.Free;
    end;
    display;
  end;
  opendialog1.Title := tempstr;
end;

procedure TForm3.RadioGroup1Click(Sender: TObject);
var
  ini: Tinifile;
begin
  GRPlistselect := RadioGroup1.ItemIndex;
  try
    ini := Tinifile.Create(StartPath + iniFilename);
    ini.Writeinteger('file','GRPselect',GRPlistselect);
  finally
    ini.Free;
  end;
end;

procedure TForm3.ScrollBar2Change(Sender: TObject);
begin
  nowpic := scrollbar2.Position * grplistlinepicnum + beginpic;
  display;
end;

procedure TForm3.display;
var
  I, I2, ix, iy, x, y, hd, wd, h: integer;
  titleheight: integer;
  temprs: Tmemorystream;
  PNGrs: TPNGObject;
  tempPNGnum: integer;
  tempbmpdata: Tbmpdata;
  tempw,temph,totalh, tempd: integer;
begin
  //
  //Arect := JudgeWH;

  if filenum <= 0 then
    exit;
  tempPNGnum := 0;
  titleheight := 12;
  bufbmp.Canvas.Brush.Style := bsSolid;
  bufbmp.Canvas.Brush.Color := GRPlistBackGround;//$74A89C;//$FCFCFC;//usualtrans;
  bufbmp.Canvas.FillRect(bufbmp.Canvas.ClipRect);
  bufbmp.Canvas.Font.Color := GRPListTextCol;//clyellow;
  bufbmp.Canvas.Font.Size := 10;
  bufbmp.Canvas.Font.Name := '宋体';


  iy := 0;
  //grplistlinenum := 0;
  //totalh:= 0;
  ix := 0;
  h := 0;
  grplistlinenum := 0;
  grplistsquareW := image1.Width div grplistlinepicnum;
  PNGrs := TPNGObject.Create;
  temprs := TmemoryStream.Create;
  for I := nowpic to endpic do
  begin
    if ix = grplistlinepicnum then
    begin
      ix := 0;
      inc(iy);
      h := h + grplistsquareH;
    end;
    grplistlinenum := iy;
    if h >= bufbmp.Height then
      break;
    hd := 0;
    wd := 0;
    if grppic[I].size >= 8 then
    begin
      if calpng(@(grppic[i].data[0])) <> 1 then
      begin
        temph := Psmallint(@(grppic[i].data[2]))^;
        tempw := Psmallint(@(grppic[i].data[0]))^;
        if (temph > 0) and (tempw > 0) then
        begin
          bufbmp3.Width := tempw;
          bufbmp3.Height := temph;
          bufbmp3.Canvas.Brush.Style := bssolid;
          bufbmp3.Canvas.Brush.Color := GRPlistBackGround;
          bufbmp3.Canvas.FillRect(bufbmp3.Canvas.ClipRect);
          tempbmpdata.pixelperbit := bufbmp3.PixelFormat;
          tempbmpdata.height := bufbmp3.Height;
          tempbmpdata.width := bufbmp3.Width;
          setlength(tempbmpdata.data, tempbmpdata.height, tempbmpdata.width * 3);
          for i2 := 0 to bufbmp3.Height - 1 do
            copymemory(@tempbmpdata.data[i2][0], bufbmp3.ScanLine[i2], tempbmpdata.width * 3);
          DatadrawRLE8(@(grppic[I].data[0]), grppic[I].size, @tempbmpdata, 0, 0, false);
          for i2 := 0 to bufbmp3.Height - 1 do
            copymemory(bufbmp3.ScanLine[i2], @tempbmpdata.data[i2][0], tempbmpdata.width * 3);
          if (temph <= grplistsquareh - grplisttitleh) and (tempw <= grplistsquarew) then
          begin
            hd := temph;
            wd := tempw;
          end
          else
          begin
            if ((tempw / grplistsquarew) > (temph / (grplistsquareh - grplisttitleh))) then
            begin
              wd := grplistsquarew;
              hd := max(Round(temph / (tempw / grplistsquarew)), 1);
            end
            else
            begin
              wd := max(Round(tempw / (temph / (grplistsquareh - grplisttitleh))), 1);
              hd := grplistsquareh - grplisttitleh;
            end;
          end;
          x := ix * grplistsquareW;
          y := iy * grplistsquareH + grplisttitleh;
          bufbmp.Canvas.StretchDraw(Rect(x, y, x + wd, y + hd) , bufbmp3);
        end;
      end
      else
      begin
        try
          temph := grppic[i].data[20] shl 24 + grppic[i].data[21] shl 16 + grppic[i].data[22] shl 8 + grppic[i].data[23];
          tempw := grppic[i].data[16] shl 24 + grppic[i].data[17] shl 16 + grppic[i].data[18] shl 8 + grppic[i].data[19];
        except
          temph := 0;
          tempw := 0;
        end;
        if (temph > 0) and (tempw > 0) then
        begin
          if (temph <= grplistsquareh - grplisttitleh) and (tempw <= grplistsquarew) then
          begin
            hd := temph;
            wd := tempw;
          end
          else
          begin
            if ((tempw / grplistsquarew) > (temph / (grplistsquareh - grplisttitleh))) then
            begin
              wd := grplistsquarew;
              hd := max(Round(temph / (tempw / grplistsquarew)), 1);
            end
            else
            begin
              wd := max(Round(tempw / (temph / (grplistsquareh - grplisttitleh))), 1);
              hd := grplistsquareh - grplisttitleh;
            end;
          end;
          x := ix * grplistsquareW;
          y := iy * grplistsquareH + grplisttitleh;
          //bufbmp.Canvas.StretchDraw(Rect(x, y, x + wd, y + hd) , bufbmp3);
          temprs.Clear;
          temprs.SetSize(grppic[i].size);
          temprs.Position := 0;
          temprs.Write(grppic[i].data[0],grppic[i].size);
          temprs.Position := 0;
          PNGrs.LoadFromStream(temprs);
          PNGrs.Draw(bufbmp.Canvas, Rect(x, y, x + wd, y + hd));
          temprs.SetSize(0);
        end;
      end;
    end;

    Bufbmp.Canvas.Lock;
    Bufbmp.Canvas.Brush.Style := bsclear;
    Bufbmp.Canvas.TextOut(ix * grplistsquareW, iy * grplistsquareH, inttostr(I));
    Bufbmp.Canvas.Brush.Style := bssolid;
    Bufbmp.Canvas.UnLock;

    inc(ix);
  end;

  temprs.Free;
  PNGrs.Destroy;
  setlength(tempbmpdata.data,0,0);
  bufbmp2.Canvas.CopyRect(bufbmp2.Canvas.ClipRect,bufbmp.Canvas,bufbmp.Canvas.ClipRect);
  Scrollbar2.LargeChange := max(1, grplistlinenum - 1);
  image1.Canvas.CopyRect(image1.Canvas.ClipRect,bufbmp2.Canvas,bufbmp2.Canvas.ClipRect);
end;

procedure copyGRP(AFrom, Ato:integer);
begin
  GRPpic[ATo].size := GRPpic[AFrom].size;
  setlength(GRPpic[ATo].data, GRPpic[ATo].size);
  CopyMemory(@GRPpic[ATo].data[0] ,@GRPpic[AFrom].data[0], GRPpic[AFrom].size);
end;

procedure MEMdrawRLE8(Ppic: Pbyte; len: integer; PBMP: PntBitMap; dx, dy: integer; canmove: boolean);
var
  state,i, iy, ix, linesize, temp: integer;
  pw,ph,xs,ys: integer;
  Pbuf: Pbyte;
begin
  //

  if len > 8 then
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
    I := 0;
    while I < linesize do
    begin
      if state = 2 then
      begin
        temp := (Ppic + I)^;
        ix := ix + temp;
        state := 1;
        inc(I);
      end
      else if state = 1 then
      begin
        temp := (Ppic + I)^;
        state := 2 + temp;
        inc(I);
      end
      else if state > 2 then
      begin
        temp := (Ppic + I)^;
        try
          if iy + dy < PBMP.Height then
          begin
            Pbuf := Pbmp.ScanLine[iy + dy];
            if ix + state - 2 < PBMP.Width then
              copymemory((Pbuf + ix), (Ppic + I), state - 2)
            else if ix < PBMP.Width then
              copymemory((Pbuf + ix), (Ppic + I), PBMP.Width - ix);
          end;
        except
          //showmessage('cuowu');
        end;
        inc(ix, state - 2);
        inc(I ,state - 2);
        state := 2;

       { if (iy + dy >= 0) and (iy + dy < Pbmp.Height) and (ix >=0) and (ix < Pbmp.Width) then
        begin
        Pbuf := Pbmp.ScanLine[iy + dy];
        (Pbuf + ix)^ := temp;
      //  (Pbuf + 3 * ix)^ := McolB[temp];
       // (Pbuf + 3 * ix + 1)^ := McolG[temp];
       // (Pbuf + 3 * ix + 2)^ := McolR[temp];
        //PBMP.canvas.Pixels[ix, iy + dy] := (McolB[temp] shl 16) or (McolG[temp] shl 8) or McolR[temp];

        end;
        dec(state);
        inc(ix);  }
      end;
    end;
    inc(Ppic, linesize);
  end;
  end;

end;

procedure DataDrawRLE8(Ppic: Pbyte; len: integer; PBMP: Pbmpdata; dx, dy: integer; canmove: boolean);
var
  state,i, iy, ix, linesize, temp: integer;
  pw,ph,xs,ys: integer;
  Pbuf: Pbyte;
begin
  //

  if len > 8 then
  begin
  pw := Psmallint((Ppic))^;
  Inc(Ppic, 2);
  ph := Psmallint((Ppic))^;
  Inc(Ppic, 2);
  xs := Psmallint((Ppic))^;
  Inc(Ppic, 2);
  ys := Psmallint((Ppic))^;
  Inc(Ppic, 2);


  if canmove then
  begin
    dy := dy - ys;
    dx := dx - xs;
  end;

  //在屏幕外
  if (dx > Pbmp.width) or (dx + pw < 0) or (dy > Pbmp.height) or (dy + ph < 0) then
    exit;

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
        //if ((iy + dy) in [0..tempgrpbmp.Height - 1]) and (ix in [0..tempgrpbmp.width - 1]) then
       // begin
          //tempcolor[iy + dy][ix * 3] := GB[temp];
          //tempcolor[iy + dy][ix * 3 + 1] := GG[temp];
          //tempcolor[iy + dy][ix * 3 + 2] := GR[temp];
          //PBMP.canvas.Pixels[ix, iy + dy] := (GB[temp] shl 16) or (GG[temp] shl 8) or GR[temp];
          if PBMP.pixelperbit = pf24bit then
          begin
            if (iy + dy >= 0) and (iy + dy <PBMP.height) and (ix >= 0) and (ix <PBMP.width) then
            begin
              PBmp.data[iy + dy][ix * 3] := GB[temp];
              PBmp.data[iy + dy][ix * 3 + 1] := GG[temp];
              PBmp.data[iy + dy][ix * 3 + 2] := GR[temp];
            end;
          end
          else if PBMP.pixelperbit = pf8bit then
          begin
            if (iy + dy >= 0) and (iy + dy <PBMP.height) and (ix >= 0) and (ix <PBMP.width) then
              PBmp.data[iy + dy][ix] := temp;
          end
          else if PBMP.pixelperbit = pf32bit then
          begin
            if (iy + dy >= 0) and (iy + dy <PBMP.height) and (ix >= 0) and (ix <PBMP.width) then
            begin
              PBmp.data[iy + dy][ix * 4 ] := GB[temp];
              PBmp.data[iy + dy][ix * 4 + 1] := GG[temp];
              PBmp.data[iy + dy][ix * 4 + 2 ] := GR[temp];
              PBmp.data[iy + dy][ix * 4 + 3 ] := 0;
            end;
          end;

        //end;
        dec(state);
        inc(ix);
      end;


    end;
    inc(Ppic, linesize);
  end;
  end;

end;

end.
