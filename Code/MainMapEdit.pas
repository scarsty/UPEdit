unit MainMapEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,head, ExtCtrls, StdCtrls,math, ComCtrls, IMZObject, iniFiles, imagez;

type
  TForm13 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    ComboBox1: TComboBox;
    Label1: TLabel;
    GroupBox1: TGroupBox;
    Button2: TButton;
    Timer1: TTimer;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Panel3: TPanel;
    Image2: TImage;
    Panel4: TPanel;
    Image3: TImage;
    Panel5: TPanel;
    Image4: TImage;
    Panel6: TPanel;
    Image5: TImage;
    Button3: TButton;
    Panel2: TPanel;
    Panel7: TPanel;
    Panel9: TPanel;
    ScrollBar2: TScrollBar;
    StatusBar1: TStatusBar;
    ScrollBar1: TScrollBar;
    RadioGroup1: TRadioGroup;
    CheckBox1: TCheckBox;
    Image1: TImage;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Button5: TButton;
    Button6: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
    procedure ComboBox1Select(Sender: TObject);
    procedure Image1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure Image1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure displayMmap(MmapopMap: Pmap; Mmapopbmp2:PNTbitmap);
    procedure FormResize(Sender: TObject);
    procedure ScrollBar2Change(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Timer1Timer(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure UpdateMainSmallBmp;
    procedure ReadMModeIni;
    procedure WriteMModeIni;
    procedure SetEditMode(EMode: TMapEditMode);
    procedure CheckBox1Click(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure Panel9Resize(Sender: TObject);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure calcopymap(Map: PMap; Rect: TRect);
    procedure calbackcopymap(Map: PMap; Rect: TRect);
    procedure copymap(Dest, Source: PMap);
    procedure drawsquare(x,y: integer);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    var
      ImzFile: TimzFile;
      MMapEditMode: TMapEditMode;
      MMapInitial: boolean;
  end;

var
  MMApopbmp: Tbitmap;
  MMApbufbmp: Tbitmap;
  MMApgrp: array of Tgrppic;
  MMApgrpnum: integer;
  nowMMApgrpnum: integer;
  MMAplayer: integer;
  MMApfile: Tmapstruct;
  MMApcopymap: Tmap;
  MMApcopymapmode:integer;
  MMAptempx,MMAptempy: integer;
  MMApcenterx,MMApcentery: integer;
  MMApsmallbmp: Tbitmap;
  MMApstill: integer;
  MMApstillx,MMApstilly: integer;
  //sceneeventnum: integer;
  mousex,mousey: integer;
  needupdate: boolean;
  qbuildx,qbuildy: integer;

  MMapPNGBuf: TScenePNGBuf;
  MMapopbmppng: Tbitmap;
  MMapbufbmppng: Tbitmap;


function readMmapfile: integer;
function readMmapGRP: integer;
procedure McoldrawRLE8(Ppic: Pbyte; len: integer; PBMP: PntBitMap; dx, dy: integer; canmove: boolean);

implementation

uses
  main, grplist, outputMap;

{$R *.dfm}

procedure TForm13.SetEditMode(EMode: TMapEditMode);
begin
  //
  MmapInitial :=false;

  if EMode = RLEMode then
  begin
    if not (readMmapGRP = 1) then
    begin
      showmessage('读取IDX或GRP文件错误！');
      MMapInitial := false;
      RadioGroup1.ItemIndex := integer(MMapEditMode);
      exit;
    end;
    MMapPNGBuf.width := 0;
    MMapPNGBuf.height := 0;
    setlength(MMapPNGBuf.data, MMapPNGBuf.height, MMapPNGBuf.width * 4);

    MMapInitial := true;
    //Warlock := false;
    needupdate := true;
  end
  else if EMode = IMZMode then
  begin
    if not imzFile.ReadImzFromFile(gamepath + MMAPIMZ) then
    begin
      showmessage('读取IMZ文件失败！');
      MMapInitial := false;
      RadioGroup1.ItemIndex := integer(MMapEditMode);
      exit;
    end;
    ImzFile.ReadAllPNG;
    MMapPNGBuf.width := image1.width + 400;
    MMapPNGBuf.height := image1.height + 200;
    setlength(MMapPNGBuf.data, MMapPNGBuf.height, MMapPNGBuf.width * 4);
    MMapInitial := true;
    //scenelock := false;
    needupdate := true;
  end
  else if EMode = PNGMode then
  begin
    if not imzFile.ReadImzFromFolder(gamepath + MMAPPNGpath) then
    begin
      showmessage('读取IMZ文件夹失败！');
      MMapInitial := false;
      RadioGroup1.ItemIndex := integer(MMapEditMode);
      exit;
    end;
    ImzFile.ReadAllPNG;
    MMapPNGBuf.width := image1.width + 400;
    MMapPNGBuf.height := image1.height + 200;
    setlength(MMapPNGBuf.data, MMapPNGBuf.height, MMapPNGBuf.width * 4);
    MMapInitial := true;
    //scenelock := false;
    needupdate := true;
  end;
  MMapEditMode := EMode;
  WriteMModeIni;
end;

procedure TForm13.RadioGroup1Click(Sender: TObject);
begin
  setEditMode(TMapEditMode(RadioGroup1.ItemIndex));
end;

procedure TForm13.ReadMModeIni;
var
  filename: string;
  ini: Tinifile;
begin
  //
  Filename := StartPath + iniFilename;
  try
    ini := TIniFile.Create(filename);
    MMapEditMode := TMapEditMode(ini.ReadInteger('File','MMapMode', integer(MMapEditMode)));
  finally
    ini.Free;
  end;
end;

procedure TForm13.WriteMModeIni;
var
  filename: string;
  ini: Tinifile;
begin
  //
  Filename := StartPath + iniFilename;
  try
    ini := TIniFile.Create(filename);
    ini.WriteInteger('File','MMapMode', integer(MMapEditMode));
  finally
    ini.Free;
  end;
end;

procedure TForm13.Button1Click(Sender: TObject);
var
  Form3: TForm3;
  I: integer;
  FormImz: TImzForm;
begin
  if MMapEditMode = RLEMode then
  begin
  if CForm3 then
  begin
    CFOrm3 := false;
    Form3 := TForm3.Create(application);
    Form3.WindowState := wsmaximized;
    MdiChildHandle[3] := Form3.Handle;
    Form3.WindowState := wsnormal;
    Form3.edit1.Text := gamepath + MMapfileIDX;
    Form3.edit2.Text := gamepath + MMapfilegrp;
    Form3.Button4.Click;
  end
  else
  begin
    for I := 0 to Mainform.MDIChildCount - 1 do
      if Mainform.MDIChildren[I].Handle = MdiChildHandle[3] then
      begin
        TForm3(Mainform.MDIChildren[I]).ComboBox1.ItemIndex := -1;
        TForm3(Mainform.MDIChildren[I]).edit1.Text := gamepath + MMapfileIDX;
        TForm3(Mainform.MDIChildren[I]).edit2.Text := gamepath + MMapfilegrp;
        TForm3(Mainform.MDIChildren[I]).Button4.Click;
        self.WindowState := wsnormal;
        Mainform.MDIChildren[I].BringToFront;
      end;
  end;
  end
  else if (MMapEditMode = PNGMode) or (MMapEditMode = IMZMode) then
  begin
  if CFormImz then
  begin
    CFormImz := false;
    FormImz := TImzForm.Create(application);
    MdiChildHandle[13] := FormImz.Handle;
    FormImz.WindowState := wsnormal;
    if MMapEditMode = IMZMode then
    begin
      FormImz.Edit2.Text := gamepath + MmapIMZ;
      //FormImz.IMZeditMode := TIMZEditMode(0);
      FormIMZ.SetEditMode(TIMZEditMode(0));
    end
    else
    begin
      FormImz.Edit2.Text := gamepath + MmapPNGPATH;
      //FormImz.IMZeditMode := TIMZEditMode(1);
      FormIMZ.SetEditMode(TIMZEditMode(1));
    end;
    FormImz.Button5.Click;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if Mainform.MDIChildren[I].Handle = MdiChildHandle[13] then
      begin
        if MMapEditMode = IMZMode then
        begin
          TImzForm(Mainform.MDIChildren[I]).Edit2.Text := gamepath +MmapIMZ;
          //TImzForm(Mainform.MDIChildren[I]).IMZeditMode := TIMZEditMode(0);
          TImzForm(Mainform.MDIChildren[I]).SetEditMode(TIMZEditMode(0));
        end
        else
        begin
          TImzForm(Mainform.MDIChildren[I]).Edit2.Text := gamepath + MmapPNGPATH;
          //TImzForm(Mainform.MDIChildren[I]).IMZeditMode := TIMZEditMode(1);
          TImzForm(Mainform.MDIChildren[I]).SetEditMode(TIMZEditMode(1));
        end;
        TImzForm(Mainform.MDIChildren[I]).Button5.Click;
        TImzForm(Mainform.MDIChildren[I]).WindowState := wsnormal;
        TImzForm(Mainform.MDIChildren[I]).BringToFront;
      end;
  end;
  end;
end;

procedure TForm13.Button2Click(Sender: TObject);
var
  ix,iy,grp,I: integer;
begin
  //
 // MMApfile.num := 1;
 // setlength(Mmapfile.map, Mmapfile.num);
 // Mmapfile.map[0].layernum := 5;
 // setlength(Mmapfile.map[0].maplayer, Mmapfile.map[0].layernum);
 // Mmapfile.map[0].x := 480;
 // Mmapfile.map[0].y := 480;
 // for I := 0 to Mmapfile.map[0].layernum - 1 do
  //  setlength(Mmapfile.map[0].maplayer[I].pic, Mmapfile.map[0].y, Mmapfile.map[0].x);
  try
  grp := filecreate(gamepath + Mearth);
  for iy := 0 to Mmapfile.map[0].y - 1 do
    filewrite(grp, Mmapfile.map[0].maplayer[0].pic[iy][0], Mmapfile.map[0].x * 2);
  fileclose(grp);

  grp := filecreate(gamepath + Msurface);
  for iy := 0 to Mmapfile.map[0].y - 1 do
    filewrite(grp, Mmapfile.map[0].maplayer[1].pic[iy][0], Mmapfile.map[0].x * 2);
  fileclose(grp);

  grp := filecreate(gamepath + Mbuilding);
  for iy := 0 to Mmapfile.map[0].y - 1 do
    filewrite(grp, Mmapfile.map[0].maplayer[2].pic[iy][0], Mmapfile.map[0].x * 2);
  fileclose(grp);

  grp := filecreate(gamepath + Mbuildx);
  for iy := 0 to Mmapfile.map[0].y - 1 do
    filewrite(grp, Mmapfile.map[0].maplayer[3].pic[iy][0], Mmapfile.map[0].x * 2);
  fileclose(grp);

  grp := filecreate(gamepath + Mbuildy);
  for iy := 0 to Mmapfile.map[0].y - 1 do
    filewrite(grp, Mmapfile.map[0].maplayer[4].pic[iy][0], Mmapfile.map[0].x * 2);
  fileclose(grp);

  showmessage('保存大地图成功！');
  except
    showmessage('保存失败！');
  end;
end;

procedure TForm13.Button3Click(Sender: TObject);
begin
  outMMapEditMode := MMapEditMode;
  outImzFile := @self.ImzFile;
  Form93.ShowModal;
end;

procedure TForm13.Button5Click(Sender: TObject);
var
  FH: integer;
  I,I1,I2: integer;
begin
  opendialog1.Filter := 'Main Map Module files (*.mmd)|*.mmd|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    if fileexists(opendialog1.FileName) then
    begin
      try
        combobox1.ItemIndex := 5;
        Mmaplayer := 4;
        FH := fileopen(opendialog1.FileName, fmopenread);
        Mmapcopymap.layernum := Mmapfile.map[0].layernum;
        setlength(Mmapcopymap.maplayer, Mmapcopymap.layernum);
        fileseek(FH,0,0);
        fileread(FH, Mmapcopymap.x, 4);
        fileread(FH, Mmapcopymap.y, 4);
        for I := 0 to Mmapcopymap.layernum - 1 do
        begin
          setlength(Mmapcopymap.maplayer[I].pic,Mmapcopymap.y,Mmapcopymap.x);
          for I1 := 0 to Mmapcopymap.y - 1 do
          begin
            fileread(FH, Mmapcopymap.maplayer[I].pic[I1][0], Mmapcopymap.x * 2);
          end;
        end;
        Mmapcopymapmode := 1;
        nowMmapgrpnum := -1;
      finally
        fileclose(FH);
      end;
    end;
  end;
  Mmapstill := 0;
  Mmapstillx := -1;
  Mmapstilly := -1;
end;

procedure TForm13.Button6Click(Sender: TObject);
var
  filename: string;
  I, I1, I2, ix, iy,FH,posx,posy: integer;
  wartempbmp: Tbitmap;
   PalSize:longint;
    pLogPalle:TMaxLogPalette;
    PalleEntry:TPaletteEntry;
    Palle:HPalette;
begin
  if Mmaplayer <> 4 then
  begin
    showmessage('请选择操作图层为"全部"，然后用鼠标括出一块区域');
  end
  else
  begin
    savedialog1.Filter := 'Main Map Module files (*.mmd)|*.mmd';
    if savedialog1.Execute then
    begin
      filename := SaveDialog1.filename;
      if not SameText(ExtractFileExt(SaveDialog1.filename), '.mmd') then
        filename := filename + '.mmd';
      //scenelock := true;
      try
        FH := filecreate(filename);
        fileseek(FH,0,0);
        filewrite(FH, Mmapcopymap.x, 4);
        filewrite(FH, Mmapcopymap.y, 4);
        for I := 0 to Mmapcopymap.layernum - 1 do
        begin
          for I1 := 0 to Mmapcopymap.y - 1 do
          begin
            filewrite(FH, Mmapcopymap.maplayer[I].pic[I1][0], 2 * Mmapcopymap.x);
          end;
        end;

      finally
        fileclose(FH);
      end;
      try
        wartempbmp := Tbitmap.Create;

        PalSize:=sizeof(TLogPalette) + 256 * sizeof(TPaletteEntry);

        pLogPalle.palVersion:=$0300;
        pLogPalle.palNumEntries:=256;
     //
     for i:=0 to 255 do
     begin
       pLogPalle.palPalEntry[i].peRed:=McolR[I];
       pLogPalle.palPalEntry[i].peGreen:=McolG[I];
       pLogPalle.palPalEntry[i].peBlue:=McolB[I];
       pLogPalle.palPalEntry[i].peFlags:=PC_EXPLICIT;
     end;
   //
       Palle:=CreatePalette(pLogPalette(@plogpalle)^);

        if MmapEditMode = RLEMode then
        begin
          Wartempbmp.PixelFormat := pf8bit;
          Wartempbmp.Palette := Palle;
        end
        else
          wartempbmp.PixelFormat := pf32bit;

        wartempbmp.Width := (Mmapcopymap.x + Mmapcopymap.y) * 18 + 150;
        wartempbmp.height := (Mmapcopymap.x + Mmapcopymap.y) * 9 + 150;
        wartempbmp.Canvas.Brush.Color := clblack;
        wartempbmp.Canvas.FillRect(wartempbmp.Canvas.ClipRect);

        for I := 0 to 2 do
          for Ix := Mmapcopymap.x - 1 downto 0 do
             for iy := Mmapcopymap.y - 1 downto 0 do
               if (Mmapcopymap.maplayer[I].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1] > 0) or ((Mmapcopymap.maplayer[I].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1] = 0) and (I = 0)) then
               begin
                 posx := (Mmapcopymap.x - ix) * 18 - (Mmapcopymap.y - iy) * 18  + Mmapcopymap.y * 18 + 75;
                 posy := (Mmapcopymap.x - ix) * 9 + (Mmapcopymap.y - Iy) * 9 + 110;

                 //McoldrawRLE8(@scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].data[0],scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].size,@scenetempbmp, posx,posy, true);
                 case MmapEditMode of
                   RLEMode:
                     begin
                       if (Mmapcopymap.maplayer[I].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1] div 2 >= 0)
                       and (Mmapcopymap.maplayer[I].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1] div 2 < Mmapgrpnum)
                       and (Mmapgrp[Mmapcopymap.maplayer[I].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1] div 2].size >= 8)
                       then
                         McoldrawRLE8(@Mmapgrp[Mmapcopymap.maplayer[I].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1] div 2].data[0],Mmapgrp[Mmapcopymap.maplayer[I].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1] div 2].size, @Wartempbmp, posx,posy, true);
                     end;
                   IMZMode, PNGMode:
                     begin
                       //imzFile.DrawImztocanvasEx(image5.Canvas, @imzFIle.imzFile, tempint, 0, 0, 0);
                       ImzFile.SceneQuickDraw(@Wartempbmp, Mmapcopymap.maplayer[I].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1] div 2, posx, posy);
                     end;
                 end;
               end;

        Wartempbmp.SaveToFile(filename + '.bmp');
      finally
        Wartempbmp.Free;
      end;

    end;
  end;
  Mmapstill := 0;
  Mmapstillx := -1;
end;

function readMmapgrp: integer;
var
  offset: array of integer;
  I, idx, grp, temp: integer;
begin
  result := 1;
  try
  idx := fileopen(gamepath + Mmapfileidx, fmopenread);
  grp := fileopen(gamepath + Mmapfilegrp, fmopenread);
  temp := fileseek(idx,0,2);
  MMApgrpnum := temp div 4;
  setlength(Mmapgrp, temp div 4);
  setlength(offset, temp div 4 + 1);
  fileseek(idx,0,0);
  fileread(idx, offset[1], temp);
  offset[0] := 0;
  fileseek(grp,0,0);
  for I := 0 to ((temp div 4) - 1) do
  begin
    Mmapgrp[I].size := offset[I + 1]- offset[I];
    if Mmapgrp[I].size < 0 then
      Mmapgrp[I].size := 0;
    setlength(Mmapgrp[I].data, Mmapgrp[I].size);
    if Mmapgrp[I].size > 0 then
      fileread(grp, Mmapgrp[I].data[0], Mmapgrp[I].size);
  end;
  fileclose(idx);
  fileclose(grp);
  except
    result := 0;
    fileclose(idx);
    fileclose(grp);
  end;

end;

procedure TForm13.CheckBox1Click(Sender: TObject);
begin
  if checkbox1.Checked then
  begin
    panel7.Visible := true;
    needupdate := true;
  end
  else
  begin
    panel7.Visible := false;
  end;
end;

procedure TForm13.ComboBox1Select(Sender: TObject);
var
  I: integer;
begin
  Mmaplayer := combobox1.ItemIndex - 1;
  if Mmaplayer = 3 then
  begin
    qbuildx:= 0;
    qbuildy:= 0;
  end;
  if Mmaplayer = 4 then
  begin
    MMapcopymapmode := 1;
    nowMmapgrpnum := -1;
    mmapcopymap.layernum := MMapfile.map[0].layernum;
    setlength(mmapcopymap.maplayer, mmapcopymap.layernum);
    mmapcopymap.x := 1;
    mmapcopymap.y := 1;
    for I := 0 to 2 do
    begin
      setlength(mmapcopymap.maplayer[I].pic, mmapcopymap.y, mmapcopymap.x);
      mmapcopymap.maplayer[I].pic[0][0] := 0;
    end;
    for I := 3 to 4 do
    begin
      setlength(mmapcopymap.maplayer[I].pic, mmapcopymap.y, mmapcopymap.x);
      mmapcopymap.maplayer[I].pic[0][0] := -1;
    end;
  end;
end;

procedure TForm13.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  MMApopbmp.Free;
  MMApbufbmp.Free;
  setlength(MMApgrp,0);
  setlength(MMApfile.map,0);
  setlength(MMApcopymap.maplayer,0);
  ImzFile.ReleaseAllPNG;
  ImzFile.Free;
  setlength(MMapPNGBuf.data, 0, 0);
  MMapbufbmppng.Free;
  Mmapopbmppng.Free;
  CForm13 := true;
  action := cafree;
end;

procedure TForm13.FormCreate(Sender: TObject);
var
  I: integer;
   PalSize:longint;
    pLogPalle:TMaxLogPalette;
    PalleEntry:TPaletteEntry;
    Palle:HPalette;
begin
  MMapInitial := false;
  ImzFile := TImzFile.Create;

  ReadMModeIni;

   try
     PalSize:=sizeof(TLogPalette) + 256 * sizeof(TPaletteEntry);
     //pLogPalle:=MemAlloc(PalSize);
   //  getmem(Plogpalle, palsize);
     pLogPalle.palVersion:=$0300;
     pLogPalle.palNumEntries:=256;
     //
     for i:=0 to 255 do
     begin
     pLogPalle.palPalEntry[i].peRed:=McolR[I];
     pLogPalle.palPalEntry[i].peGreen:=McolG[I];
     pLogPalle.palPalEntry[i].peBlue:=McolB[I];
     pLogPalle.palPalEntry[i].peFlags:=PC_EXPLICIT;
     end;
   //
     Palle:=CreatePalette(pLogPalette(@plogpalle)^);
  except
    showmessage('大地图编辑器打开失败！原因是调色板设置失败，可能是调色板文件未找到。请检查游戏路径以及ini文件设置！');
    self.Close;
    exit;
  end;

  nowMmapgrpnum := -1;
  Mmaplayer := -1;

  MMapopbmppng := Tbitmap.Create;
  MMapopbmppng.Width := image1.Width + 400;
  MMapopbmppng.Height := image1.Height + 200;
  MMapopbmppng.Canvas.Font.Size := 8;
  MMapopbmppng.Canvas.Font.Color := clyellow;
  MMapopbmppng.PixelFormat := pf32bit;

  MMapbufbmppng := Tbitmap.Create;
  MMapbufbmppng.Width := image1.Width + 400;
  MMapbufbmppng.Height := image1.Height + 200;
  MMapbufbmppng.Canvas.Font.Size := 8;
  MMapbufbmppng.Canvas.Font.Color := clyellow;
  MMapbufbmppng.PixelFormat := pf32bit;

  SetEditMode(MMapEditMode);
  RadioGroup1.ItemIndex := integer(MMapEditMode);
  if not ({(readMmapGRP = 1) and }(readMmapfile = 1)) then
  begin
    showmessage('大地图编辑器打开失败！地图文件数据错误或未找到。请检查游戏路径以及ini文件设置！');
    self.Close;
    exit;
  end;
  try
  qbuildx:= -1;
  qbuildy:= -1;
  Mmapopbmp := Tbitmap.Create;
  Mmapopbmp.Width := image1.Width+ 400;
  Mmapopbmp.Height := image1.Height + 200;
  Mmapopbmp.PixelFormat := pf8bit;
  Mmapopbmp.Palette := Palle;
  Mmapbufbmp := Tbitmap.Create;
  Mmapbufbmp.Width := image1.Width + 400;
  Mmapbufbmp.Height := image1.Height+ 200;
  Mmapbufbmp.PixelFormat := pf8bit;
  Mmapbufbmp.Palette := Palle;
  Mmapsmallbmp := Tbitmap.Create;
  Mmapsmallbmp.PixelFormat := pf8bit;
  Mmapbufbmp.Palette := Palle;
  Mmapsmallbmp.Canvas.Brush.Color := CLWHITE;//$707030;
  Mmapsmallbmp.Palette := Palle;
  Mmapsmallbmp.Width := 500;
  Mmapsmallbmp.Height := 500;
  scrollbar1.Min := 0;
  scrollbar1.Max := max(Mmapfile.map[0].x, Mmapfile.map[0].y) - 1;
  scrollbar2.Min := 0;
  scrollbar2.Max := max(Mmapfile.map[0].x, Mmapfile.map[0].y) - 1;
  scrollbar2.Position := scrollbar2.Max div 2;
  scrollbar1.Position := scrollbar1.Max div 2;



 // displayMmap(@Mmapfile.map[0], @Mmapopbmp);
//  Mmapbufbmp.Canvas.CopyRect(Mmapbufbmp.Canvas.ClipRect, Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
 // image1.Canvas.CopyRect(image1.ClientRect,Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);

   except
     showmessage('大地图编辑打开失败！');
     self.Close;
     exit;
   end;
   timer1.Enabled := true;

   MMapInitial := true;
end;

procedure TForm13.FormResize(Sender: TObject);
var
  temprect:Trect;
begin
  try
  if MMapEditMode <> RLEMode then
  begin
    MMapPNGBuf.width := image1.width + 400;
    MMapPNGBuf.height := image1.height + 200;
    setlength(MMapPNGBuf.data, MMapPNGBuf.height, MMapPNGBuf.width * 4);
    MmapbufbmpPNG.Height := image1.Height + 200;
    MmapopbmpPNG.Width := image1.Width + 400;
    MmapopbmpPNG.Height := image1.Height+ 200;
    MmapbufbmpPNG.Width := image1.Width + 400;
  end;
  image1.Picture.Bitmap.Width := image1.Width;
  image1.Picture.Bitmap.Height := image1.Height;
  Mmapbufbmp.Height := image1.Height+ 200;
  Mmapopbmp.Width := image1.Width + 400;
  Mmapopbmp.Height := image1.Height+ 200;
  Mmapbufbmp.Width := image1.Width + 400;
  //displayMmap(@Mmapfile.map[0], @Mmapopbmp);
  //temprect := image1.Canvas.ClipRect;
 // temprect.Left :=temprect.Left + 200;
  //temprect.Right := temprect.Right + 200;
  //Mmapbufbmp.Canvas.CopyRect(Mmapbufbmp.Canvas.ClipRect, Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
  //image1.Canvas.CopyRect(image1.Canvas.ClipRect,Mmapopbmp.Canvas,temprect);
   needupdate := true;
  except

  end;
end;

procedure TForm13.Image1DragDrop(Sender, Source: TObject; X, Y: Integer);
begin
  if MMaplayer = 4 then
  begin
    showmessage('请选择其他图层再进行拖拽操作！');
    exit;
  end;
  if IMZDrag then
  begin
    //showmessage('imzdrag');
    if MMapEditMode <> RLEMode then
      nowMMapgrpnum := imzdragint;
  end
  else
  begin
    //showmessage('grpdrag');
    if MMapEditMode = RLEMode then
      nowMMapgrpnum := movelock;
  end;
  //nowMmapgrpnum := movelock;

  MMapcopymapmode := 0;
  self.BringToFront;
end;

procedure TForm13.Image1DragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  //
end;

procedure TForm13.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  axp,ayp,posx,posy,pointx,pointy: integer;
  temprect: Trect;
  ix, iy, I: integer;
  tempmap: TMap;
begin
  if button = mbright then
  begin
    if (MMapcopymapmode <> 1) and (nowMmapgrpnum >= 0) and (mmaplayer < 2) and (Mmaplayer>=0) then
    begin
      Mmapfile.map[0].maplayer[mmaplayer].pic[Mmaptempy][Mmaptempx] := nowMmapgrpnum * 2;
      needupdate := true;
      UpdateMainSmallBmp;
    end
    else if (MMapcopymapmode <> 1) and (nowMmapgrpnum >= 0) and (mMAPLAYER = 2) then
    begin
      Mmapfile.map[0].maplayer[mmaplayer].pic[Mmaptempy][Mmaptempx] := nowMmapgrpnum * 2;
      needupdate := true;
      if nowMmapgrpnum > 0 then
      begin
        Mmapfile.map[0].maplayer[mmaplayer + 1].pic[Mmaptempy][Mmaptempx] := mMAPTEMPX;
        Mmapfile.map[0].maplayer[mmaplayer + 2].pic[Mmaptempy][Mmaptempx] := mMAPTEMPY;
      end
      else
      begin
        Mmapfile.map[0].maplayer[mmaplayer + 1].pic[Mmaptempy][Mmaptempx] := 0;
        Mmapfile.map[0].maplayer[mmaplayer + 2].pic[Mmaptempy][Mmaptempx] := 0;
      end;
      UpdateMainSmallBmp;
    end
    else if Mmaplayer = 3 then
    begin
      if (qbuildx < 0) or (qbuildx >= Mmapfile.map[0].x) or (qbuildy < 0) or (qbuildy >= Mmapfile.map[0].y) then
      begin
        qbuildx := 0;
        qbuildy := 0;
      end;
      Mmapfile.map[0].maplayer[3].pic[Mmaptempy][Mmaptempx] := qbuildx;
      Mmapfile.map[0].maplayer[4].pic[Mmaptempy][Mmaptempx] := qbuildy;
      UpdateMainSmallBmp;
     // qbuildx := Mmaptempx;
     // qbuildy := Mmaptempy;
    end
    else if (MMapcopymapmode = 1) and (nowMmapgrpnum < 0) and ((Mmaplayer = 0) or (Mmaplayer = 1)) then
    begin
      for Ix := 0 to Mmapcopymap.x - 1 do
        for iy := 0 to Mmapcopymap.y - 1 do
          if (Mmaptempx - ix >= 0) and (Mmaptempx-ix < Mmapfile.map[0].x) and (Mmaptempy-iy >=0) and (-iy + Mmaptempy < Mmapfile.map[0].y) then
            Mmapfile.map[0].maplayer[Mmaplayer].pic[Mmaptempy - iy][Mmaptempx - ix] := Mmapcopymap.maplayer[Mmaplayer].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1];
      needupdate := true;
      updateMainSmallBMP;
      //Updatesmallimg(image1.Width DIV 2,image1.Height div 2 - 31 * 18, scenetempx, scenetempy);
      //copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup[0]);
      //copyscenemapevent(@Dfile.mapevent[combobox2.ItemIndex], @scenemapeventbackup[0]);
    end
    else if (MMapcopymapmode = 1) and (nowMmapgrpnum < 0) and (mMAPLAYER = 2) then
    begin
      copymap(@tempmap, @Mmapcopymap);
      temprect.Left := Mmaptempx - tempMap.x + 1;
      temprect.Right := Mmaptempx;
      temprect.Top := Mmaptempy - tempMap.y + 1;
      temprect.Bottom := Mmaptempy;
      calbackcopymap(@tempmap, temprect);
      for I := 2 to 4 do
        for Ix := 0 to Mmapcopymap.x - 1 do
          for iy := 0 to Mmapcopymap.y - 1 do
            if (Mmaptempx - ix >= 0) and (Mmaptempx-ix < Mmapfile.map[0].x) and (Mmaptempy-iy >= 0) and (-iy + Mmaptempy < Mmapfile.map[0].y) then
              Mmapfile.map[0].maplayer[I].pic[Mmaptempy - iy][Mmaptempx - ix] := tempmap.maplayer[I].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1];
      setlength(tempmap.maplayer, 0);
      needupdate := true;
      updateMainSmallBMP;

    end
    else if (MMapcopymapmode = 1) and (nowMmapgrpnum < 0) and (mMAPLAYER = 4) then
    begin
      copymap(@tempmap, @Mmapcopymap);
      temprect.Left := Mmaptempx - tempMap.x + 1;
      temprect.Right := Mmaptempx;
      temprect.Top := Mmaptempy - tempMap.y + 1;
      temprect.Bottom := Mmaptempy;
      calbackcopymap(@tempmap, temprect);
      for I := 0 to 4 do
        for Ix := 0 to Mmapcopymap.x - 1 do
          for iy := 0 to Mmapcopymap.y - 1 do
            if (Mmaptempx - ix >= 0) and (Mmaptempx-ix < Mmapfile.map[0].x) and (Mmaptempy-iy >=0) and (-iy + Mmaptempy < Mmapfile.map[0].y) then
              Mmapfile.map[0].maplayer[I].pic[Mmaptempy - iy][Mmaptempx - ix] := tempmap.maplayer[I].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1];
      //还需要修改引用建筑层
      setlength(tempmap.maplayer, 0);
      needupdate := true;
      updateMainSmallBMP;
    end;
  end
  else if button = mbleft then       
  begin
    if ((Mmaplayer >= 0) and (Mmaplayer <> 3)) or (Mmaplayer = 4) then
    begin
      Mmapstill := 1;
      Mmapstillx := Mmaptempx;
      Mmapstilly := Mmaptempy;
      needupdate := true;
    end
    else
    begin
      Mmapstill := 0;
    end;
  end;
end;

procedure TForm13.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  mousex := x;
  mousey := y;
end;

procedure TForm13.copymap(Dest, Source: PMap);
var
  I: integer;
  ix, iy: integer;
begin
  //
  Dest.layernum := Source.layernum;
  Dest.x := Source.x;
  Dest.y := Source.y;
  setlength(Dest.maplayer, Dest.layernum);
  for I := 0 to Dest.layernum - 1 do
  begin
    setlength(Dest.maplayer[I].pic, Dest.y, Dest.x);
    if Dest.x > 0 then
      for Iy := 0 to Dest.y - 1 do
        copymemory(@Dest.maplayer[I].pic[Iy][0], @Source.maplayer[I].pic[Iy][0], Dest.x * sizeof(smallint));
  end;
end;

procedure TForm13.calcopymap(Map: PMap; Rect: TRect);
var
  ix, iy: integer;
begin
  //
  for ix := 0 to Map.x - 1 do
    for iy := 0 to Map.y - 1 do
    begin
      if (Map.maplayer[3].pic[iy][ix] = 0) and (Map.maplayer[4].pic[iy][ix] = 0) then
      begin
        Map.maplayer[3].pic[iy][ix] := -1;
        Map.maplayer[4].pic[iy][ix] := -1;
      end
      else if (Map.maplayer[3].pic[iy][ix] >= Rect.Left) and (Map.maplayer[3].pic[iy][ix] <= Rect.Right)
      and (Map.maplayer[4].pic[iy][ix] >= Rect.Top) and (Map.maplayer[4].pic[iy][ix] <= Rect.Bottom)
      and (Map.maplayer[2].pic[Map.maplayer[4].pic[iy][ix] - Rect.Top][Map.maplayer[3].pic[iy][ix] - Rect.Left] > 0) then
      begin
        Map.maplayer[3].pic[iy][ix] := Map.maplayer[3].pic[iy][ix] - Rect.Left;
        Map.maplayer[4].pic[iy][ix] := Map.maplayer[4].pic[iy][ix] - Rect.Top;
      end
      else
      begin
        Map.maplayer[3].pic[iy][ix] := -1;
        Map.maplayer[4].pic[iy][ix] := -1;
      end;
    end;
end;

procedure TForm13.calbackcopymap(Map: PMap; Rect: TRect);
var
  ix, iy: integer;
begin
  //
  for ix := 0 to Map.x - 1 do
    for iy := 0 to Map.y - 1 do
    begin
      if (Map.maplayer[3].pic[iy][ix] = -1) and (Map.maplayer[4].pic[iy][ix] = -1) then
      begin
        Map.maplayer[3].pic[iy][ix] := 0;
        Map.maplayer[4].pic[iy][ix] := 0;
      end
      else if (Map.maplayer[3].pic[iy][ix] >= 0) and (Map.maplayer[3].pic[iy][ix] < Map.x)
      and (Map.maplayer[4].pic[iy][ix] >= 0) and (Map.maplayer[4].pic[iy][ix] < Map.y)
      and (Map.maplayer[2].pic[Map.maplayer[4].pic[iy][ix]][Map.maplayer[3].pic[iy][ix]] > 0) then
      begin
        Map.maplayer[3].pic[iy][ix] := Map.maplayer[3].pic[iy][ix] + Rect.Left;
        Map.maplayer[4].pic[iy][ix] := Map.maplayer[4].pic[iy][ix] + Rect.Top;
        if (Map.maplayer[3].pic[iy][ix] < 0) or (Map.maplayer[3].pic[iy][ix] >= Mmapfile.map[0].x)
        or (Map.maplayer[4].pic[iy][ix] < 0) or (Map.maplayer[4].pic[iy][ix] >= Mmapfile.map[0].y) then
        begin
          Map.maplayer[3].pic[iy][ix] := 0;
          Map.maplayer[4].pic[iy][ix] := 0;
        end;
      end
      else
      begin
        Map.maplayer[3].pic[iy][ix] := 0;
        Map.maplayer[4].pic[iy][ix] := 0;
      end;
    end;
end;

procedure TForm13.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  axp,ayp,posx,posy,pointx,pointy: integer;
  temprect: Trect;
  lx,ly,sx,sy, temp, ix, iy, I: integer;
begin
  //
  if Button = mbLeft then
  begin
    if ((mmaplayer < 3) and (Mmaplayer>=0)) or (Mmaplayer = 4) then
    begin
      if (((Mmapstillx <> MMAptempx) or (Mmapstilly <> MMAptempy)) or (Mmaplayer = 4)) and (MmapStill = 1) then
      begin
        //拷贝地图
        Mmapcopymapmode := 1;
        lx := Mmaptempx;
        ly := Mmaptempy;
        if (Mmaptempx >= Mmapfile.map[0].x)  then
          lx := Mmapfile.map[0].x - 1
        else if (Mmaptempx < 0) then
          lx := 0;
        if (Mmaptempy >= Mmapfile.map[0].y)  then
          ly := Mmapfile.map[0].y - 1
        else if (Mmaptempy < 0) then
          ly := 0;
        if (Mmapstillx >= 0) and (Mmapstillx < Mmapfile.map[0].x) and (Mmapstilly >=0) and (Mmapstilly < Mmapfile.map[0].y) then
        begin
          sx := MMapstillx;
          sy := MMapstilly;
          if sx > lx then
          begin
            temp := lx;
            lx := sx;
            sx := temp;
          end;
          if sy > ly then
          begin
            temp := ly;
            ly := sy;
            sy := temp;
          end;
          Mmapcopymapmode := 1;
          nowMmapgrpnum := -1;
          Mmapcopymap.layernum := Mmapfile.map[0].layernum;
          Mmapcopymap.x := lx - sx + 1;
          Mmapcopymap.y := ly - sy + 1;
          setlength(Mmapcopymap.maplayer, Mmapcopymap.layernum);
          for I := 0 to Mmapcopymap.layernum - 1 do
          begin
            setlength(Mmapcopymap.maplayer[I].pic, Mmapcopymap.y, Mmapcopymap.x);
            for ix := sx to lx do
              for iy := sy to ly do
              begin
                Mmapcopymap.maplayer[I].pic[iy - sy][ix - sx] := Mmapfile.map[0].maplayer[I].pic[iy][ix];
              end;
          end;
          temprect.Left := sx;
          temprect.Right := lx;
          temprect.Top := sy;
          temprect.Bottom := ly;
          calcopymap(@Mmapcopymap, temprect);
        end;
      end
      else if (Mmaplayer >= 0) and (Mmaplayer <= 2)  then
      begin
        nowMmapgrpnum := Mmapfile.map[0].maplayer[mmaplayer].pic[Mmaptempy][Mmaptempx] div 2;
        needupdate := true;
      end;
    end
    else if Mmaplayer = 3 then
    begin
      if Mmapfile.map[0].maplayer[2].pic[Mmaptempy][Mmaptempx] div 2 > 0 then
      begin
        qbuildx := Mmaptempx;
        qbuildy := Mmaptempy;
      end
      else
      begin
        qbuildx := 0;
        qbuildy := 0;
      end;
      Mmapbufbmp.Canvas.CopyRect(Mmapbufbmp.Canvas.ClipRect, Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
      pointx := image1.Width DIV 2;
      pointy := image1.Height div 2;
      Axp := Round(((mousex - pointx) / 18 + (mouseY - pointy + 9) / 9) / 2);
      Ayp := Round(-((mousex - pointx) / 18 - (mouseY - pointy + 9) / 9) / 2);
      posx := axp * 18 - ayp * 18  + pointx - 18 + 200;
      posy := axp * 9 + ayp * 9 + pointy - 9;
      Mmapbufbmp.Canvas.Font.Color := clyellow;
      Mmapbufbmp.Canvas.Font.Size := 9;
      Mmapbufbmp.Canvas.Brush.Style := bsclear;
      Mmapbufbmp.Canvas.TextOut(posx,posy, '('+inttostr(qbuildx)+','+inttostr(qbuildy)+')');
      temprect := image1.Canvas.ClipRect;
      temprect.Left :=temprect.Left + 200;
      temprect.Right := temprect.Right + 200;
      image1.Canvas.CopyRect(image1.ClientRect,Mmapbufbmp.Canvas,temprect);
    end;
    Mmapstill := 0;
  end;
end;

procedure TForm13.Panel9Resize(Sender: TObject);
begin
  FormResize(Sender);
end;

procedure TForm13.ScrollBar1Change(Sender: TObject);
begin
  //displayMmap(@Mmapfile.map[0], @Mmapopbmp);
  //Mmapbufbmp.Canvas.CopyRect(Mmapbufbmp.Canvas.ClipRect, Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
 // image1.Canvas.CopyRect(image1.ClientRect,Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
 needupdate := true;
end;

procedure TForm13.ScrollBar2Change(Sender: TObject);
begin
  //displayMmap(@Mmapfile.map[0], @Mmapopbmp);
  //Mmapbufbmp.Canvas.CopyRect(Mmapbufbmp.Canvas.ClipRect, Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
 // image1.Canvas.CopyRect(image1.ClientRect,Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
  needupdate := true;
end;

procedure TForm13.UpdateMainSmallBmp;
begin
  try
  image2.Canvas.Brush.Color :=CLWHITE;//$606060;
    image2.Canvas.FillRect(image2.Canvas.ClipRect);
    image3.Canvas.Brush.Color := CLWHITE;//$606060;
    image3.Canvas.FillRect(image3.Canvas.ClipRect);
    image4.Canvas.Brush.Color := CLWHITE;//$606060;
    image4.Canvas.FillRect(image4.Canvas.ClipRect);
    image5.Canvas.Brush.Color := CLWHITE;//$606060;
    image5.Canvas.FillRect(image5.Canvas.ClipRect);
    if (Mmaptempx >= 0) and (Mmaptempx < Mmapfile.map[0].x) and (Mmaptempy >=0) and (Mmaptempy < Mmapfile.map[0].y) then
    begin
      Mmapsmallbmp.Canvas.Brush.Color :=CLWHITE;//$606060;
      Mmapsmallbmp.Canvas.FillRect(Mmapsmallbmp.Canvas.ClipRect);
      if Mmapfile.map[0].maplayer[0].pic[Mmaptempy][Mmaptempx] > 0 then
      begin
       // Mmapsmallbmp.Width := image2.Width;
       // Mmapsmallbmp.Height := image2.Height;
        case MMapEditMode of
          RLEMode:
            begin
              if (Mmapfile.map[0].maplayer[0].pic[Mmaptempy][Mmaptempx] div 2 >= 0) and (Mmapfile.map[0].maplayer[0].pic[Mmaptempy][Mmaptempx] div 2 < Mmapgrpnum) and (Mmapgrp[Mmapfile.map[0].maplayer[0].pic[Mmaptempy][Mmaptempx] div 2].size >= 8) then
              begin
                McoldrawRLE8(@Mmapgrp[Mmapfile.map[0].maplayer[0].pic[Mmaptempy][Mmaptempx] div 2].data[0],Mmapgrp[Mmapfile.map[0].maplayer[0].pic[Mmaptempy][Mmaptempx] div 2].size,@Mmapsmallbmp, 0,0, false);
                image2.Canvas.CopyRect(image2.Canvas.ClipRect,Mmapsmallbmp.Canvas,image2.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              imzFile.DrawImztocanvas(image2.Canvas, @imzFIle.imzFile, Mmapfile.map[0].maplayer[0].pic[Mmaptempy][Mmaptempx] div 2, 0, 0, 0);
            end;
        end;
      end;
      Mmapsmallbmp.Canvas.Brush.Color := CLWHITE;//$606060;
      Mmapsmallbmp.Canvas.FillRect(Mmapsmallbmp.Canvas.ClipRect);

      if Mmapfile.map[0].maplayer[1].pic[Mmaptempy][Mmaptempx] > 0 then
      begin
       // Mmapsmallbmp.Width := image3.Width;
       // Mmapsmallbmp.Height := image3.Height;
        case MMapEditMode of
          RLEMode:
            begin
              if (Mmapfile.map[0].maplayer[1].pic[Mmaptempy][Mmaptempx] div 2 >= 0) and (Mmapfile.map[0].maplayer[1].pic[Mmaptempy][Mmaptempx] div 2 < Mmapgrpnum) and (Mmapgrp[Mmapfile.map[0].maplayer[1].pic[Mmaptempy][Mmaptempx] div 2].size >= 8) then
              begin
                McoldrawRLE8(@Mmapgrp[Mmapfile.map[0].maplayer[1].pic[Mmaptempy][Mmaptempx] div 2].data[0],Mmapgrp[Mmapfile.map[0].maplayer[1].pic[Mmaptempy][Mmaptempx] div 2].size,@Mmapsmallbmp, 0,0, false);
                image3.Canvas.CopyRect(image3.Canvas.ClipRect, Mmapsmallbmp.Canvas,image3.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              imzFile.DrawImztocanvas(image3.Canvas, @imzFIle.imzFile, Mmapfile.map[0].maplayer[1].pic[Mmaptempy][Mmaptempx] div 2, 0, 0, 0);
            end;
        end;
      end;
      Mmapsmallbmp.Canvas.Brush.Color := CLWHITE;//$606060;
      Mmapsmallbmp.Canvas.FillRect(Mmapsmallbmp.Canvas.ClipRect);
      if Mmapfile.map[0].maplayer[2].pic[Mmaptempy][Mmaptempx] > 0 then
      begin
       // Mmapsmallbmp.Width := image4.Width;
       // Mmapsmallbmp.Height := image4.Height;
        case MMapEditMode of
          RLEMode:
            begin
              if (Mmapfile.map[0].maplayer[2].pic[Mmaptempy][Mmaptempx] div 2 >= 0) and (Mmapfile.map[0].maplayer[2].pic[Mmaptempy][Mmaptempx] div 2 < Mmapgrpnum) and (Mmapgrp[Mmapfile.map[0].maplayer[2].pic[Mmaptempy][Mmaptempx] div 2].size >= 8) then
              begin
                McoldrawRLE8(@Mmapgrp[Mmapfile.map[0].maplayer[2].pic[Mmaptempy][Mmaptempx] div 2].data[0],Mmapgrp[Mmapfile.map[0].maplayer[2].pic[Mmaptempy][Mmaptempx] div 2].size,@Mmapsmallbmp, 0,0, false);
                image4.Canvas.CopyRect(image4.Canvas.ClipRect,Mmapsmallbmp.Canvas,image4.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              imzFile.DrawImztocanvas(image4.Canvas, @imzFIle.imzFile, Mmapfile.map[0].maplayer[2].pic[Mmaptempy][Mmaptempx] div 2, 0, 0, 0);
            end;
        end;
      end;
      Mmapsmallbmp.Canvas.Brush.Color := CLWHITE;//$606060;
      Mmapsmallbmp.Canvas.FillRect(Mmapsmallbmp.Canvas.ClipRect);
      if Mmapfile.map[0].maplayer[2].pic[Mmapfile.map[0].maplayer[4].pic[Mmaptempy][Mmaptempx]][Mmapfile.map[0].maplayer[3].pic[Mmaptempy][Mmaptempx]] > 0 then
      begin
       // Mmapsmallbmp.Width := image5.Width;
        //Mmapsmallbmp.Height := image5.Height;
        case MMapEditMode of
          RLEMode:
            begin
              if (Mmapfile.map[0].maplayer[4].pic[Mmaptempy][Mmaptempx] >= 0)
              and (Mmapfile.map[0].maplayer[4].pic[Mmaptempy][Mmaptempx] < MMApfile.map[0].y)
              and (Mmapfile.map[0].maplayer[3].pic[Mmaptempy][Mmaptempx] >= 0)
              and (Mmapfile.map[0].maplayer[3].pic[Mmaptempy][Mmaptempx] < MMApfile.map[0].x)
              and (Mmapfile.map[0].maplayer[2].pic[Mmapfile.map[0].maplayer[4].pic[Mmaptempy][Mmaptempx]][Mmapfile.map[0].maplayer[3].pic[Mmaptempy][Mmaptempx]] div 2 >= 0)
              and (Mmapfile.map[0].maplayer[2].pic[Mmapfile.map[0].maplayer[4].pic[Mmaptempy][Mmaptempx]][Mmapfile.map[0].maplayer[3].pic[Mmaptempy][Mmaptempx]] div 2 < mmapgrpnum)
              and (Mmapgrp[Mmapfile.map[0].maplayer[2].pic[Mmapfile.map[0].maplayer[4].pic[Mmaptempy][Mmaptempx]][Mmapfile.map[0].maplayer[3].pic[Mmaptempy][Mmaptempx]] div 2].size >= 8) then
              begin
                McoldrawRLE8(@Mmapgrp[Mmapfile.map[0].maplayer[2].pic[Mmapfile.map[0].maplayer[4].pic[Mmaptempy][Mmaptempx]][Mmapfile.map[0].maplayer[3].pic[Mmaptempy][Mmaptempx]] div 2].data[0],Mmapgrp[Mmapfile.map[0].maplayer[2].pic[Mmapfile.map[0].maplayer[4].pic[Mmaptempy][Mmaptempx]][Mmapfile.map[0].maplayer[3].pic[Mmaptempy][Mmaptempx]] div 2].size,@Mmapsmallbmp, 0,0, false);
                image5.Canvas.CopyRect(image5.Canvas.ClipRect,Mmapsmallbmp.Canvas,image5.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              imzFile.DrawImztocanvas(image5.Canvas, @imzFIle.imzFile, Mmapfile.map[0].maplayer[2].pic[Mmapfile.map[0].maplayer[4].pic[Mmaptempy][Mmaptempx]][Mmapfile.map[0].maplayer[3].pic[Mmaptempy][Mmaptempx]] div 2, 0, 0, 0);
            end;
        end;
      end;
    end;
  except
    showmessage('更新贴图出错!');
  end;
end;

procedure TForm13.Timer1Timer(Sender: TObject);
var
  axp,ayp: integer;
  pointx,pointy,posx,posy,ix,iy, I: integer;
  temprect: Trect;
  tempint: integer;
  lx, ly, sx, sy, temp: integer;
begin

  pointx := image1.Width DIV 2;
  pointy := image1.Height div 2;
  Axp := Round(((mousex - pointx) / 18 + (mouseY - pointy + 9) / 9) / 2);
  Ayp := Round(-((mousex - pointx) / 18 - (mouseY - pointy + 9) / 9) / 2);
  //Axp := (mousex - pointx + 2 * mousey - pointy * 2 + 18) div 36;
  //Ayp := (-mousex + pointx + 2 * mousey - pointy * 2 + 18) div 36;
  ix := axp;
  iy := ayp;
  Axp := AXP + scrollbar1.Position + scrollbar2.Position - Mmapfile.map[0].y div 2;
  Ayp := AYP + scrollbar2.Position - scrollbar1.Position + Mmapfile.map[0].y div 2;

  if needupdate then
  begin
    try
    needupdate := false;
    temprect := image1.Canvas.ClipRect;
    temprect.Left :=temprect.Left + 200;
    temprect.Right := temprect.Right + 200;
    if MMapEditMode = RLEMode then
    begin
      displayMmap(@Mmapfile.map[0], @Mmapopbmp);
      Mmapbufbmp.Canvas.CopyRect(Mmapbufbmp.Canvas.ClipRect, Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
      image1.Canvas.CopyRect(image1.ClientRect,Mmapbufbmp.Canvas,temprect);
    end
    else
    begin
      displayMmap(@Mmapfile.map[0], @MmapopbmpPNG);
      MmapbufbmpPNG.Canvas.CopyRect(MmapbufbmpPNG.Canvas.ClipRect, MmapopbmpPNG.Canvas, MmapopbmpPNG.Canvas.ClipRect);
      image1.Canvas.CopyRect(image1.ClientRect,MmapbufbmpPNG.Canvas, temprect);
    end;
    except
    showmessage('更新地图错误！');
    end;
  end;
  if (axp <> Mmaptempx) or (ayp <> Mmaptempy) then
  begin
    try
    Mmaptempx := axp;
    Mmaptempy := ayp;

    statusbar1.Canvas.Brush.Color := clbtnface;
    statusbar1.Canvas.FillRect(statusbar1.Canvas.ClipRect);
    statusbar1.Repaint;
    statusbar1.Canvas.TextOut(10,10,'X='+inttostr(AXP) + ',Y='+inttostr(AYP));
    if MMapEditMode = RLEMode then
    begin
      Mmapbufbmp.Canvas.CopyRect(Mmapbufbmp.Canvas.ClipRect, Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
    end
    else
    begin
      Mmapbufbmppng.Canvas.CopyRect(Mmapbufbmppng.Canvas.ClipRect, Mmapopbmppng.Canvas,Mmapopbmppng.Canvas.ClipRect);
    end;
    axp := ix;
    ayp := iy;
    if (Mmaptempx >= 0) and (Mmaptempy >= 0) and (Mmaptempx < Mmapfile.map[0].x) and (Mmaptempy < Mmapfile.map[0].y) then
    begin
      label6.Caption := inttostr(Mmapfile.map[0].maplayer[0].pic[Mmaptempy][Mmaptempx] div 2);
      label7.Caption := inttostr(Mmapfile.map[0].maplayer[1].pic[Mmaptempy][Mmaptempx] div 2);
      label8.Caption := inttostr(Mmapfile.map[0].maplayer[2].pic[Mmaptempy][Mmaptempx] div 2);
      label9.Caption := '(' + inttostr(Mmapfile.map[0].maplayer[3].pic[Mmaptempy][Mmaptempx]) + ',' + inttostr(Mmapfile.map[0].maplayer[4].pic[Mmaptempy][Mmaptempx]) + ')' ;
    end;


    UpdateMainSmallBmp;

    if MmapStill = 1 then
    begin
      if ((MmapLayer >= 0) and (MmapLayer < 3)) or (MmapLayer = 4) then
      begin
        if (Mmaptempx <> Mmapstillx) or (Mmaptempy <> Mmapstilly) then
        begin
          sx := axp;
          lx := axp + Mmapstillx - Mmaptempx;
          sy := ayp;
          ly := ayp + Mmapstilly - Mmaptempy;
          if lx < sx then
          begin
            temp := sx;
            sx := lx;
            lx := temp;
          end;
          if ly < sy then
          begin
            temp := sy;
            sy := ly;
            ly := temp;
          end;
          for ix := sx to lx do
            for iy := sy to ly do
            begin
              posx := ix * 18 - iy * 18  + pointx+ 200;
              posy := ix * 9 + iy * 9 + pointy;
              drawsquare(posx,posy);
            end;
        end;
      end;
    end
    else if (nowMmapgrpnum >= 0) and (Mmaplayer < 3) and (Mmaplayer >= 0) then
    begin
      posx := axp * 18 - ayp * 18  + pointx+ 200;
      posy := axp * 9 + ayp * 9 + pointy;
      if MMapEditMode = RLEMode then
      begin
        if (nowMmapgrpnum >= 0) and (nowMmapgrpnum < Mmapgrpnum) and (Mmapgrp[nowMmapgrpnum].size >= 8) then
          McoldrawRLE8(@Mmapgrp[nowMmapgrpnum].data[0],Mmapgrp[nowMmapgrpnum].size,@Mmapbufbmp, posx,posy, true);
      end
      else
      begin
        ImzFile.SceneQuickDraw(@Mmapbufbmppng, nowMmapgrpnum, posx, posy);
      end;

    end
    else if Mmaplayer = 3 then
    begin
      if (qbuildx < 0) or (qbuildx >= Mmapfile.map[0].x) or (qbuildy < 0) or (qbuildy >= Mmapfile.map[0].y) then
      begin
        qbuildx := 0;
        qbuildy := 0;
      end;
      posx := axp * 18 - ayp * 18  + pointx - 18 + 200;
      posy := axp * 9 + ayp * 9 + pointy - 9;
      if MMapEditMode = RLEMode then
      begin
        Mmapbufbmp.Canvas.Font.Color := clyellow;
        Mmapbufbmp.Canvas.Font.Size := 9;
        Mmapbufbmp.Canvas.Brush.Style := bsclear;
        Mmapbufbmp.Canvas.TextOut(posx,posy, '('+inttostr(qbuildx)+','+inttostr(qbuildy)+')');
      end
      else
      begin
        Mmapbufbmppng.Canvas.Font.Color := clyellow;
        Mmapbufbmppng.Canvas.Font.Size := 9;
        Mmapbufbmppng.Canvas.Brush.Style := bsclear;
        Mmapbufbmppng.Canvas.TextOut(posx,posy, '('+inttostr(qbuildx)+','+inttostr(qbuildy)+')');
      end;
    end
    else if (Mmapcopymapmode = 1) then
    begin
      if Mmaplayer = 4 then
      begin
        for I := 0 to 2 do
          for Ix := Mmapcopymap.x - 1 downto 0 do
            for iy := Mmapcopymap.y - 1 downto 0 do
              if (Mmapcopymap.maplayer[I].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1] > 0) or ((Mmapcopymap.maplayer[I].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1] = 0) and (I = 0)) then
              begin
                tempint := Mmapcopymap.maplayer[I].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1] div 2;
                posx := (axp - ix) * 18 - (ayp - iy) * 18  + pointx + 200;
                posy := (axp - ix) * 9 + (ayp - Iy) * 9 + pointy;
                if MMapEditMode = RLEMode then
                begin
                  if (tempint >= 0) and (tempint  < Mmapgrpnum) and (Mmapgrp[tempint ].size >= 8) then
                    McoldrawRLE8(@Mmapgrp[tempint].data[0],Mmapgrp[tempint].size,@Mmapbufbmp, posx,posy, true);
                end
                else
                begin
                  ImzFile.SceneQuickDraw(@Mmapbufbmppng, tempint , posx, posy);
                end;
              end;
      end
      else if (MmapLayer >= 0) and (Mmaplayer < 3) then
      begin
        for Ix := Mmapcopymap.x - 1 downto 0 do
          for iy := Mmapcopymap.y - 1 downto 0 do
            if (Mmapcopymap.maplayer[MmapLayer].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1] > 0)  or ((Mmapcopymap.maplayer[MmapLayer].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1] = 0) and (Mmaplayer = 0)) then
            begin
              tempint := Mmapcopymap.maplayer[MmapLayer].pic[Mmapcopymap.y - iy - 1][Mmapcopymap.x - ix - 1] div 2;
              posx := (axp - ix) * 18 - (ayp - iy) * 18  + pointx + 200;
              posy := (axp - ix) * 9 + (ayp - Iy) * 9 + pointy;
              if MMapEditMode = RLEMode then
              begin
                if (tempint >= 0) and (tempint  < Mmapgrpnum) and (Mmapgrp[tempint ].size >= 8) then
                  McoldrawRLE8(@Mmapgrp[tempint].data[0],Mmapgrp[tempint].size,@Mmapbufbmp, posx,posy, true);
              end
              else
              begin
                ImzFile.SceneQuickDraw(@Mmapbufbmppng, tempint , posx, posy);
              end;
            end;
      end;

    end;

    temprect := image1.Canvas.ClipRect;
    temprect.Left :=temprect.Left + 200;
    temprect.Right := temprect.Right + 200;
    if MMapEditMode = RLEMode then
    begin
      image1.Canvas.CopyRect(image1.ClientRect,Mmapbufbmp.Canvas,temprect);
    end
    else
    begin
      image1.Canvas.CopyRect(image1.ClientRect,Mmapbufbmppng.Canvas,temprect);
    end;
    except
      showmessage('主地图更改坐标错误！');
    end;
  end;
end;

function readMmapfile: integer;
var
  ix,iy,grp,I: integer;
begin
  //
  result := 1;
  try
  MMApfile.num := 1;
  setlength(Mmapfile.map, Mmapfile.num);
  Mmapfile.map[0].layernum := 5;
  setlength(Mmapfile.map[0].maplayer, Mmapfile.map[0].layernum);
  Mmapfile.map[0].x := 480;
  Mmapfile.map[0].y := 480;
  for I := 0 to Mmapfile.map[0].layernum - 1 do
    setlength(Mmapfile.map[0].maplayer[I].pic, Mmapfile.map[0].y, Mmapfile.map[0].x);

  grp := fileopen(gamepath + Mearth, fmopenread);
  for iy := 0 to Mmapfile.map[0].y - 1 do
    fileread(grp, Mmapfile.map[0].maplayer[0].pic[iy][0], Mmapfile.map[0].x * 2);
  fileclose(grp);

  grp := fileopen(gamepath + Msurface, fmopenread);
  for iy := 0 to Mmapfile.map[0].y - 1 do
    fileread(grp, Mmapfile.map[0].maplayer[1].pic[iy][0], Mmapfile.map[0].x * 2);
  fileclose(grp);

  grp := fileopen(gamepath + Mbuilding, fmopenread);
  for iy := 0 to Mmapfile.map[0].y - 1 do
    fileread(grp, Mmapfile.map[0].maplayer[2].pic[iy][0], Mmapfile.map[0].x * 2);
  fileclose(grp);

  grp := fileopen(gamepath + Mbuildx, fmopenread);
  for iy := 0 to Mmapfile.map[0].y - 1 do
    fileread(grp, Mmapfile.map[0].maplayer[3].pic[iy][0], Mmapfile.map[0].x * 2);
  fileclose(grp);

  grp := fileopen(gamepath + Mbuildy, fmopenread);
  for iy := 0 to Mmapfile.map[0].y - 1 do
    fileread(grp, Mmapfile.map[0].maplayer[4].pic[iy][0], Mmapfile.map[0].x * 2);
  fileclose(grp);
  except
    result := 0;
    fileclose(grp);
  end;
end;



procedure McoldrawRLE8(Ppic: Pbyte; len: integer; PBMP: PntBitMap; dx, dy: integer; canmove: boolean);
var
  state,i, iy, ix, linesize, temp, size: integer;
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
  size := 8;

  if canmove then
  begin
    dy := dy - ys;
    dx := dx - xs;
  end;

  if (dx > Pbmp.width) or (dx + pw < 0) or (dy > Pbmp.height) or (dy + ph < 0) then
    exit;
  //if (dx < 0)  or ((dx + pw) >= pbmp.Width) or (dy < 0)  or ((dy + ph) >= pbmp.Height) then
    //exit;

  for iy := 0 to ph - 1 do
  begin
    linesize := Ppic^;
    inc(Ppic);
    inc(size);
    if size >= len then
      exit;
    if size + linesize >= len then
      exit;
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
          //Pbuf := Pbmp.ScanLine[iy + dy];
          //copymemory((Pbuf + ix), (Ppic + I), state - 2);
          if (iy + dy < PBMP.Height)and (iy + dy >= 0) then
          begin
            Pbuf := Pbmp.ScanLine[iy + dy];
            if ix + state - 2 < PBMP.Width then
              copymemory((Pbuf + ix), (Ppic + I), state - 2)
            else if ix < PBMP.Width then
              copymemory((Pbuf + ix), (Ppic + I), PBMP.Width - ix);
          end;
        except

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

procedure TFOrm13.displayMmap(MmapopMap: Pmap; Mmapopbmp2:PNTbitmap);
VAR
  ix,iy, I, i2,posx,posy,K: integer;
  pointx,pointy, MX, MY,I3: integer;
   Picwidth, picheight: smallint;
  pos: TPosition;
  BuildingList, CenterList: array[0..1000] of TPosition;
begin
  pointx := MmapOPBMP2.Width DIV 2;
  pointy := (Mmapopbmp2.Height - 200) div 2;
  if MMapEditMode = RLEMode then
  begin
    Mmapopbmp2.Canvas.Brush.Color := clblack;
    Mmapopbmp2.Canvas.FillRect(Mmapopbmp2.Canvas.ClipRect);
  end
  else
  begin
    for I := 0 to MMapPNGbuf.Height - 1 do
      fillchar(MMapPNGbuf.data[I][0], MMapPNGbuf.width * 4, #0);
  end;

  MX := scrollbar1.Position + scrollbar2.Position - Mmapfile.map[0].y div 2;
  MY := scrollbar2.Position - scrollbar1.Position + Mmapfile.map[0].y div 2;
  //地面层
  for I := -(Mmapopbmp2.Height div 36)  to (Mmapopbmp2.Height div 36) do
  begin
    for I2 := 1 to (Mmapopbmp2.Width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := I + I2;
      iy := I - I2;
      posx := ix * 18 - Iy * 18  + pointx;
      posy := ix * 9 + Iy * 9 + pointy;
      if (iy + my >= 0) and (iy + my < Mmapopmap.y)and (ix + mx >= 0) and (ix + mx < Mmapopmap.x) then
      if (Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2 >= 0) then
      begin
        if MMapEditMode = RLEMode then
        begin
          if (Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2 >= 0) and (Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2 < mmapgrpnum) and (Mmapgrp[Mmapopmap.maplayer[0].pic[Iy +My][ix + Mx] div 2].size >= 8) then
            McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[0].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);
        end
        else
        begin
          ImzFile.SceneQuickDrawBuf(@MmapPNGBuf, Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2, posx, posy);
        end;
      end;
    end;
    for I2 := 0 downto - (Mmapopbmp2.Width div 72) - 1  do
    begin
      if needupdate then
        exit;
      ix := I + I2;
      iy := I - I2;
      posx := ix * 18 - Iy * 18  + pointx;
      posy := ix * 9 + Iy * 9 + pointy;
      if (iy + my >= 0) and (iy + my < Mmapopmap.y)and (ix + mx >= 0) and (ix + mx < Mmapopmap.x) then
      if (Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2 >= 0) then
      begin
        if MMapEditMode = RLEMode then
        begin
          if (Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2 >= 0) and (Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2 < mmapgrpnum) and (Mmapgrp[Mmapopmap.maplayer[0].pic[Iy +My][ix + Mx] div 2].size >= 8) then
            McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[0].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);
        end
        else
        begin
          ImzFile.SceneQuickDrawBuf(@MmapPNGBuf, Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2, posx, posy);
        end;
      end;
    end;
    for I2 := 1 to (Mmapopbmp2.Width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := I + I2 +1;
      iy := I - I2;
      posx := ix * 18 - Iy * 18  + pointx;
      posy := ix * 9 + Iy * 9 + pointy;
      if (iy + my >= 0) and (iy + my < Mmapopmap.y)and (ix + mx >= 0) and (ix + mx < Mmapopmap.x) then
      if (Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2 >= 0) then
      begin
        if MMapEditMode = RLEMode then
        begin
          if (Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2 >= 0) and (Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2 < mmapgrpnum) and (Mmapgrp[Mmapopmap.maplayer[0].pic[Iy +My][ix + Mx] div 2].size >= 8) then
            McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[0].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);
        end
        else
        begin
          ImzFile.SceneQuickDrawBuf(@MmapPNGBuf, Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2, posx, posy);
        end;
      end;
    end;
    for I2 := 0 downto -(Mmapopbmp2.Width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := I + I2 + 1;
      iy := I - I2;
      posx := ix * 18 - Iy * 18  + pointx;
      posy := ix * 9 + Iy * 9 + pointy;
      if (iy + my >= 0) and (iy + my < Mmapopmap.y)and (ix + mx >= 0) and (ix + mx < Mmapopmap.x) then
      if (Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2 >= 0) then
      begin
        if MMapEditMode = RLEMode then
        begin
          if (Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2 >= 0) and (Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2 < mmapgrpnum) and (Mmapgrp[Mmapopmap.maplayer[0].pic[Iy +My][ix + Mx] div 2].size >= 8) then
            McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[0].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);
        end
        else
        begin
          ImzFile.SceneQuickDrawBuf(@MmapPNGBuf, Mmapopmap.maplayer[0].pic[Iy + My][ix +Mx] div 2, posx, posy);
        end;
      end;
    end;
  end;
  //表面层
  K := 0;
  for I :=  -(Mmapopbmp2.Height div 36)  to (Mmapopbmp2.Height div 36 + 2) do
  begin
    for I2 := 1 to (Mmapopbmp2.Width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := I + I2;
      iy := I - I2;
      posx := ix * 18 - Iy * 18  + pointx;
      posy := ix * 9 + Iy * 9 + pointy;
      if (iy + my >= 0) and (iy + my < Mmapopmap.y)and (ix + mx >= 0) and (ix + mx < Mmapopmap.x) then
      begin
      if (Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2 > 0) then
      begin
        if MMapEditMode = RLEMode then
        begin
          if (Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2 >= 0) and (Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2 < mmapgrpnum) and (Mmapgrp[Mmapopmap.maplayer[1].pic[Iy +My][ix + Mx] div 2].size >= 8) then
            McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[1].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);
        end
        else
        begin
          ImzFile.SceneQuickDrawBuf(@MmapPNGBuf, Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2, posx, posy);
        end;
      end;
     // if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 > 0) then
     //   McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);

        if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] > 0) then
        begin
          BuildingList[k].x := ix;
          BuildingList[k].y := iy;
          if MMapEditMode = RLEMode then
          begin
            if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 >= 0) and (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 < mmapgrpnum) and (Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size >= 8) then
              Picwidth := (Psmallint(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0]))^
            else
              Picwidth := 0;
          end
          else
          begin
            try
              if ImzFile.imzFile.imzPNG[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].frame > 0 then
              begin
                Picwidth := ImzFile.imzFile.imzPNG[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].PNG[0].width;
              end
              else
                PicWidth := 0;
            except
              PicWidth := 0;
            end;
          end;
          //根据图片的宽度计算图的中点，为避免出现小数，实际是中点坐标的2倍
          CenterList[k].x := ix * 2 - (Picwidth + 35) div 36 + 1;
          CenterList[k].y := iy * 2 - (Picwidth + 35) div 36 + 1;
          k := k + 1;
        end;
      end;
    end;

    for I2 := 0 downto -(Mmapopbmp2.Width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := I + I2;
      iy := I - I2;
      posx := ix * 18 - Iy * 18  + pointx;
      posy := ix * 9 + Iy * 9 + pointy;
      if (iy + my >= 0) and (iy + my < Mmapopmap.y)and (ix + mx >= 0) and (ix + mx < Mmapopmap.x) then
      begin
      if (Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2 > 0) then
      begin
        if MMapEditMode = RLEMode then
        begin
          if (Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2 >= 0) and (Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2 < mmapgrpnum) and (Mmapgrp[Mmapopmap.maplayer[1].pic[Iy +My][ix + Mx] div 2].size >= 8) then
            McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[1].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);
        end
        else
        begin
          ImzFile.SceneQuickDrawBuf(@MmapPNGBuf, Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2, posx, posy);
        end;
      end;
     //  if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 > 0) then
     //   McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);

      if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] > 0) then
        begin
          BuildingList[k].x := ix;
          BuildingList[k].y := iy;
          if MMapEditMode = RLEMode then
          begin
            Picwidth := 0;
            if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 >= 0) and (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 < mmapgrpnum) and (Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size >= 8) then
              Picwidth := (Psmallint(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0]))^;
          end
          else
          begin
            try
              if ImzFile.imzFile.imzPNG[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].frame > 0 then
              begin
                Picwidth := ImzFile.imzFile.imzPNG[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].PNG[0].width;
              end
              else
                PicWidth := 0;
            except
              PicWidth := 0;
            end;
          end;
          //根据图片的宽度计算图的中点，为避免出现小数，实际是中点坐标的2倍
          CenterList[k].x := ix * 2 - (Picwidth+ 35) div 36 + 1;
          CenterList[k].y := iy * 2 - (Picwidth + 35) div 36 + 1;
          k := k + 1;
        end;
      end;
    end;

    for I2 := 1 to (Mmapopbmp2.Width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := I + I2 +1;
      iy := I - I2;
      posx := ix * 18 - Iy * 18  + pointx;
      posy := ix * 9 + Iy * 9 + pointy;
      if (iy + my >= 0) and (iy + my < Mmapopmap.y)and (ix + mx >= 0) and (ix + mx < Mmapopmap.x) then
      begin
      if (Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2 > 0) then
      begin
        if MMapEditMode = RLEMode then
        begin
          if (Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2 >= 0) and (Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2 < mmapgrpnum) and (Mmapgrp[Mmapopmap.maplayer[1].pic[Iy +My][ix + Mx] div 2].size >= 8) then
            McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[1].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);
        end
        else
        begin
          ImzFile.SceneQuickDrawBuf(@MmapPNGBuf, Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2, posx, posy);
        end;
      end;
     // if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 > 0) then
     //   McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);

      if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] > 0) then
        begin
          BuildingList[k].x := ix;
          BuildingList[k].y := iy;
          if MMapEditMode = RLEMode then
          begin
            Picwidth := 0;
            if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 >= 0) and (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 < mmapgrpnum) and (Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size >= 8) then
              Picwidth := (Psmallint(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0]))^;
          end
          else
          begin
            try
              if ImzFile.imzFile.imzPNG[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].frame > 0 then
              begin
                Picwidth := ImzFile.imzFile.imzPNG[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].PNG[0].width;
              end;
            except
              PicWidth := 0;
            end;
          end;

          //根据图片的宽度计算图的中点，为避免出现小数，实际是中点坐标的2倍

          CenterList[k].x := ix * 2 - (Picwidth + 35) div 36 + 1;
          CenterList[k].y := iy * 2 - (Picwidth + 35) div 36 + 1;
          k := k + 1;
        end;
      end;
    end;

    for I2 := 0 downto -(Mmapopbmp2.Width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := I + I2 + 1;
      iy := I - I2;
      posx := ix * 18 - Iy * 18  + pointx;
      posy := ix * 9 + Iy * 9 + pointy;
      if (iy + my >= 0) and (iy + my < Mmapopmap.y)and (ix + mx >= 0) and (ix + mx < Mmapopmap.x) then
      begin
      if (Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2 > 0) then
      begin
        if MMapEditMode = RLEMode then
        begin
          if (Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2 >= 0) and (Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2 < mmapgrpnum) and (Mmapgrp[Mmapopmap.maplayer[1].pic[Iy +My][ix + Mx] div 2].size >= 8) then
            McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[1].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);
        end
        else
        begin
          ImzFile.SceneQuickDrawBuf(@MmapPNGBuf, Mmapopmap.maplayer[1].pic[Iy + My][ix +Mx] div 2, posx, posy);
        end;
      end;
       //if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 > 0) then
      //  McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);

        if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] > 0) then
        begin
          BuildingList[k].x := ix;
          BuildingList[k].y := iy;
          if MMapEditMode = RLEMode then
          begin
            Picwidth := 0;
            picheight := 0;
            if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 >= 0) and (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 < mmapgrpnum) and (Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size >= 8) then
            begin
              Picwidth := (Psmallint(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0]))^;
              picheight := (Psmallint(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[2]))^;
            end;
          end
          else
          begin
            try
              if ImzFile.imzFile.imzPNG[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].frame > 0 then
              begin
                Picwidth := ImzFile.imzFile.imzPNG[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].PNG[0].width;
                picheight := ImzFile.imzFile.imzPNG[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].PNG[0].height;
              end;
            except
              PicWidth := 0;
              picheight := 0;
            end;
          end;
          //根据图片的宽度计算图的中点，为避免出现小数，实际是中点坐标的2倍
          CenterList[k].x := ix * 2 - (Picwidth+ 35) div 36 + 1;
          CenterList[k].y := iy * 2 - (Picheight+ 35) div 36 + 1;
          k := k + 1;
        end;
      end;
    end;
  end;

   for i := 0 to k - 1 do
    for i2 := 0 to k - 2 do
    begin
      if CenterList[i2].x + CenterList[i2].y > CenterList[i2 + 1].x + CenterList[i2 + 1].y then
      begin
        pos := BuildingList[i2];
        BuildingList[i2] := BuildingList[i2 + 1];
        BuildingList[i2 + 1] := pos;
        pos := CenterList[i2];
        CenterList[i2] := CenterList[i2 + 1];
        CenterList[i2 + 1] := pos;
      end;
    end;

  for i := 0 to K- 1 do
  begin
    ix := BuildingList[i].x;
    iy := BuildingList[i].y;
    posx := ix * 18 - Iy * 18  + pointx;
    posy := ix * 9 + Iy * 9 + pointy;
    if MMapEditMode = RLEMode then
    begin
      if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 >= 0) and (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 < mmapgrpnum) and (Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size >= 8) then
        McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);
    end
    else
    begin
      ImzFile.SceneQuickDrawBuf(@MmapPNGBuf, Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2, posx, posy);
    end;
  end;

  if (MMapEditMode = IMZMode) or (MMapEditMode = PNGMode) then
  begin
    MMapopbmp2.Canvas.Lock;
    for I := 0 to MMapPNGbuf.Height - 1 do
      copymemory(MMapopbmp2.ScanLine[I], @MMapPNGbuf.data[I][0], MMapPNGbuf.Width * 4);
    MMapopbmp2.Canvas.UnLock;
  end;

 // if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 > 0) then
  //  McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);

  {
  for i := 0 to min(waropmap.x ,waropmap.y) - 1 do
  begin
    for ix := I to waropmap.x - 1 do
    begin
      if needupdate then
        exit;
      posx := ix * 18 - I * 18  + pointx;
      posy := ix * 9 + I * 9 + pointy;
      for I2 := 0 to waropmap.layernum - 1 do
        if (waropmap.maplayer[I2].pic[I][ix] div 2 > 0) or (I2 = 0)  then
          McoldrawRLE8(@wargrp[waropmap.maplayer[I2].pic[I][ix] div 2].data[0],wargrp[waropmap.maplayer[I2].pic[I][ix] div 2].size,waropbmp2, posx, posy, true);
    end;
    for Iy := I + 1 to waropmap.y - 1 do
    begin
      if needupdate then
        exit;
      posx := i * 18 - Iy * 18  + pointx;
      posy := i * 9 + Iy * 9 + pointy;
      for I2 := 0 to waropmap.layernum - 1 do
        if (waropmap.maplayer[I2].pic[Iy][i] div 2 > 0) or (I2 = 0) then
          McoldrawRLE8(@wargrp[waropmap.maplayer[I2].pic[Iy][i] div 2].data[0],wargrp[waropmap.maplayer[I2].pic[Iy][i] div 2].size,waropbmp2, posx, posy, true);
    end;
  end;}
end;

procedure TForm13.drawsquare(x,y: integer);
var
  I: integer;
  Pdata: Pbyte;
begin
  //
  if MmapEditMode = RLEMode then
  begin

  try
    Pdata := Mmapbufbmp.ScanLine[Y];


  (Pdata + x)^ := 23;

 (Pdata+ x - 1)^ := 23;

  for I := 1 to 8 do
  begin
    Pdata := Mmapbufbmp.ScanLine[Y - I];
   (Pdata + (X - 2 * I))^ := 23;
    (Pdata + (X - 2 * I - 1))^ := 23;
     (Pdata + (X + 2 * I))^ := 23;
     (Pdata + (X + 2 * I + 1))^ := 23;
  end;
   Pdata := Mmapbufbmp.ScanLine[Y - 9];
   (Pdata + (X - 18))^ := 23;
   (Pdata + (X + 17))^ := 23;

  for I := 1 to 8 do
  begin
     Pdata := Mmapbufbmp.ScanLine[Y - 9 - I];
     (Pdata + (X - 19 + 2 * I))^ := 23;
     (Pdata + (X - 19 + 2 * I + 1))^ := 23;
     (Pdata + (X+ 17- 2 * I))^ := 23;
     (Pdata + (X+ 17- 2 * I + 1))^ := 23;

  end;
    Pdata := Mmapbufbmp.ScanLine[Y - 17];
    (Pdata + x)^ := 23;
    (Pdata + x - 1)^ := 23;

  except
    exit;
  end;
  end
  else
  begin
    try
      Pdata := MmapbufbmpPNG.ScanLine[Y];
      Pcardinal(Pdata + x * 4)^ := $FF0000;

 Pcardinal(Pdata+ x * 4- 1* 4)^ := $FF0000;

  for I := 1 to 8 do
  begin
    Pdata := MmapbufbmpPNG.ScanLine[Y - I];
   Pcardinal(Pdata + (X - 2 * I)* 4)^ := $FF0000;
    Pcardinal(Pdata + (X - 2 * I - 1)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X + 2 * I)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X + 2 * I + 1)* 4)^ := $FF0000;
  end;
   Pdata := MmapbufbmpPNG.ScanLine[Y - 9];
   Pcardinal(Pdata + (X - 18)* 4)^ := $FF0000;
   Pcardinal(Pdata + (X + 17)* 4)^ := $FF0000;

  for I := 1 to 8 do
  begin
     Pdata := MmapbufbmpPNG.ScanLine[Y - 9 - I];
     Pcardinal(Pdata + (X - 19 + 2 * I)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X - 19 + 2 * I + 1)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X+ 17- 2 * I)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X+ 17- 2 * I + 1)* 4)^ := $FF0000;

  end;
    Pdata := MmapbufbmpPNG.ScanLine[Y - 17];
    Pcardinal(Pdata + x* 4)^ := $FF0000;
    Pcardinal(Pdata + x* 4 - 1* 4)^ := $FF0000;
    except
      exit;
    end;
  end;
end;

end.
