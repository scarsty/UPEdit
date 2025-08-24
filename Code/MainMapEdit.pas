unit MainMapEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, head, ExtCtrls, StdCtrls, math, ComCtrls, IMZObject, iniFiles, imagez;

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
    procedure Image1DragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure Image1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure displayMmap(MmapopMap: Pmap; Mmapopbmp2: PNTbitmap);
    procedure FormResize(Sender: TObject);
    procedure ScrollBar2Change(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Timer1Timer(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure UpdateMainSmallBmp;
    procedure ReadMModeIni;
    procedure WriteMModeIni;
    procedure SetEditMode(EMode: TMapEditMode);
    procedure CheckBox1Click(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure Panel9Resize(Sender: TObject);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure calcopymap(Map: Pmap; Rect: TRect);
    procedure calbackcopymap(Map: Pmap; Rect: TRect);
    procedure copymap(Dest, Source: Pmap);
    procedure drawsquare(X, Y: Integer);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  var
    ImzFile: TimzFile;
    MMapEditMode: TMapEditMode;
    MMapInitial: Boolean;
  end;

var
  MMApopbmp: Tbitmap;
  MMApbufbmp: Tbitmap;
  MMApgrp: array of Tgrppic;
  MMApgrpnum: Integer;
  nowMMApgrpnum: Integer;
  MMAplayer: Integer;
  MMApfile: Tmapstruct;
  MMApcopymap: Tmap;
  MMApcopymapmode: Integer;
  MMAptempx, MMAptempy: Integer;
  MMApcenterx, MMApcentery: Integer;
  MMApsmallbmp: Tbitmap;
  MMApstill: Integer;
  MMApstillx, MMApstilly: Integer;
  // sceneeventnum: integer;
  mousex, mousey: Integer;
  needupdate: Boolean;
  qbuildx, qbuildy: Integer;

  MMapPNGBuf: TScenePNGBuf;
  MMapopbmppng: Tbitmap;
  MMapbufbmppng: Tbitmap;

function readMmapfile: Integer;
function readMmapGRP: Integer;
procedure McoldrawRLE8(Ppic: Pbyte; len: Integer; PBMP: PNTbitmap; dx, dy: Integer; canmove: Boolean);

implementation

uses
  main, grplist, outputMap;

{$R *.dfm}

procedure TForm13.SetEditMode(EMode: TMapEditMode);
begin
  //
  MMapInitial := false;

  if EMode = RLEMode then
  begin
    if not(readMmapGRP = 1) then
    begin
      showmessage('读取IDX或GRP文件错误！');
      MMapInitial := false;
      RadioGroup1.ItemIndex := Integer(MMapEditMode);
      exit;
    end;
    MMapPNGBuf.width := 0;
    MMapPNGBuf.height := 0;
    setlength(MMapPNGBuf.data, MMapPNGBuf.height, MMapPNGBuf.width * 4);

    MMapInitial := true;
    // Warlock := false;
    needupdate := true;
  end
  else if EMode = IMZMode then
  begin
    if not ImzFile.ReadImzFromFile(gamepath + MMAPIMZ) then
    begin
      showmessage('读取IMZ文件失败！');
      MMapInitial := false;
      RadioGroup1.ItemIndex := Integer(MMapEditMode);
      exit;
    end;
    ImzFile.ReadAllPNG;
    MMapPNGBuf.width := Image1.width + 400;
    MMapPNGBuf.height := Image1.height + 200;
    setlength(MMapPNGBuf.data, MMapPNGBuf.height, MMapPNGBuf.width * 4);
    MMapInitial := true;
    // scenelock := false;
    needupdate := true;
  end
  else if EMode = PNGMode then
  begin
    if not ImzFile.ReadImzFromFolder(gamepath + MMAPPNGpath) then
    begin
      showmessage('读取IMZ文件夹失败！');
      MMapInitial := false;
      RadioGroup1.ItemIndex := Integer(MMapEditMode);
      exit;
    end;
    ImzFile.ReadAllPNG;
    MMapPNGBuf.width := Image1.width + 400;
    MMapPNGBuf.height := Image1.height + 200;
    setlength(MMapPNGBuf.data, MMapPNGBuf.height, MMapPNGBuf.width * 4);
    MMapInitial := true;
    // scenelock := false;
    needupdate := true;
  end;
  MMapEditMode := EMode;
  WriteMModeIni;
end;

procedure TForm13.RadioGroup1Click(Sender: TObject);
begin
  SetEditMode(TMapEditMode(RadioGroup1.ItemIndex));
end;

procedure TForm13.ReadMModeIni;
var
  filename: string;
  ini: Tinifile;
begin
  //
  filename := StartPath + iniFilename;
  try
    ini := Tinifile.Create(filename);
    MMapEditMode := TMapEditMode(ini.ReadInteger('File', 'MMapMode', Integer(MMapEditMode)));
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
  filename := StartPath + iniFilename;
  try
    ini := Tinifile.Create(filename);
    ini.WriteInteger('File', 'MMapMode', Integer(MMapEditMode));
  finally
    ini.Free;
  end;
end;

procedure TForm13.Button1Click(Sender: TObject);
var
  Form3: TForm3;
  i: Integer;
  FormImz: TImzForm;
begin
  if MMapEditMode = RLEMode then
  begin
    if CForm3 then
    begin
      CForm3 := false;
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
      for i := 0 to Mainform.MDIChildCount - 1 do
        if Mainform.MDIChildren[i].Handle = MdiChildHandle[3] then
        begin
          TForm3(Mainform.MDIChildren[i]).ComboBox1.ItemIndex := -1;
          TForm3(Mainform.MDIChildren[i]).edit1.Text := gamepath + MMapfileIDX;
          TForm3(Mainform.MDIChildren[i]).edit2.Text := gamepath + MMapfilegrp;
          TForm3(Mainform.MDIChildren[i]).Button4.Click;
          self.WindowState := wsnormal;
          Mainform.MDIChildren[i].BringToFront;
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
        FormImz.edit2.Text := gamepath + MMAPIMZ;
        // FormImz.IMZeditMode := TIMZEditMode(0);
        FormImz.SetEditMode(TIMZEditMode(0));
      end
      else
      begin
        FormImz.edit2.Text := gamepath + MMAPPNGpath;
        // FormImz.IMZeditMode := TIMZEditMode(1);
        FormImz.SetEditMode(TIMZEditMode(1));
      end;
      FormImz.Button5.Click;
    end
    else
    begin
      for i := 0 to self.MDIChildCount - 1 do
        if Mainform.MDIChildren[i].Handle = MdiChildHandle[13] then
        begin
          if MMapEditMode = IMZMode then
          begin
            TImzForm(Mainform.MDIChildren[i]).edit2.Text := gamepath + MMAPIMZ;
            // TImzForm(Mainform.MDIChildren[I]).IMZeditMode := TIMZEditMode(0);
            TImzForm(Mainform.MDIChildren[i]).SetEditMode(TIMZEditMode(0));
          end
          else
          begin
            TImzForm(Mainform.MDIChildren[i]).edit2.Text := gamepath + MMAPPNGpath;
            // TImzForm(Mainform.MDIChildren[I]).IMZeditMode := TIMZEditMode(1);
            TImzForm(Mainform.MDIChildren[i]).SetEditMode(TIMZEditMode(1));
          end;
          TImzForm(Mainform.MDIChildren[i]).Button5.Click;
          TImzForm(Mainform.MDIChildren[i]).WindowState := wsnormal;
          TImzForm(Mainform.MDIChildren[i]).BringToFront;
        end;
    end;
  end;
end;

procedure TForm13.Button2Click(Sender: TObject);
var
  ix, iy, grp, i: Integer;
begin
  //
  // MMApfile.num := 1;
  // setlength(Mmapfile.map, Mmapfile.num);
  // Mmapfile.map[0].layernum := 5;
  // setlength(Mmapfile.map[0].maplayer, Mmapfile.map[0].layernum);
  // Mmapfile.map[0].x := 480;
  // Mmapfile.map[0].y := 480;
  // for I := 0 to Mmapfile.map[0].layernum - 1 do
  // setlength(Mmapfile.map[0].maplayer[I].pic, Mmapfile.map[0].y, Mmapfile.map[0].x);
  try
    grp := filecreate(gamepath + Mearth);
    for iy := 0 to MMApfile.Map[0].Y - 1 do
      filewrite(grp, MMApfile.Map[0].maplayer[0].pic[iy][0], MMApfile.Map[0].X * 2);
    fileclose(grp);

    grp := filecreate(gamepath + Msurface);
    for iy := 0 to MMApfile.Map[0].Y - 1 do
      filewrite(grp, MMApfile.Map[0].maplayer[1].pic[iy][0], MMApfile.Map[0].X * 2);
    fileclose(grp);

    grp := filecreate(gamepath + Mbuilding);
    for iy := 0 to MMApfile.Map[0].Y - 1 do
      filewrite(grp, MMApfile.Map[0].maplayer[2].pic[iy][0], MMApfile.Map[0].X * 2);
    fileclose(grp);

    grp := filecreate(gamepath + Mbuildx);
    for iy := 0 to MMApfile.Map[0].Y - 1 do
      filewrite(grp, MMApfile.Map[0].maplayer[3].pic[iy][0], MMApfile.Map[0].X * 2);
    fileclose(grp);

    grp := filecreate(gamepath + Mbuildy);
    for iy := 0 to MMApfile.Map[0].Y - 1 do
      filewrite(grp, MMApfile.Map[0].maplayer[4].pic[iy][0], MMApfile.Map[0].X * 2);
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
  FH: Integer;
  i, i1, i2: Integer;
begin
  OpenDialog1.Filter := 'Main Map Module files (*.mmd)|*.mmd|All files (*.*)|*.*';
  if OpenDialog1.Execute then
  begin
    if fileexists(OpenDialog1.filename) then
    begin
      try
        ComboBox1.ItemIndex := 5;
        MMAplayer := 4;
        FH := fileopen(OpenDialog1.filename, fmopenread);
        MMApcopymap.layernum := MMApfile.Map[0].layernum;
        setlength(MMApcopymap.maplayer, MMApcopymap.layernum);
        fileseek(FH, 0, 0);
        fileread(FH, MMApcopymap.X, 4);
        fileread(FH, MMApcopymap.Y, 4);
        for i := 0 to MMApcopymap.layernum - 1 do
        begin
          setlength(MMApcopymap.maplayer[i].pic, MMApcopymap.Y, MMApcopymap.X);
          for i1 := 0 to MMApcopymap.Y - 1 do
          begin
            fileread(FH, MMApcopymap.maplayer[i].pic[i1][0], MMApcopymap.X * 2);
          end;
        end;
        MMApcopymapmode := 1;
        nowMMApgrpnum := -1;
      finally
        fileclose(FH);
      end;
    end;
  end;
  MMApstill := 0;
  MMApstillx := -1;
  MMApstilly := -1;
end;

procedure TForm13.Button6Click(Sender: TObject);
var
  filename: string;
  i, i1, i2, ix, iy, FH, posx, posy: Integer;
  wartempbmp: Tbitmap;
  PalSize: longint;
  pLogPalle: TMaxLogPalette;
  PalleEntry: TPaletteEntry;
  Palle: HPalette;
begin
  if MMAplayer <> 4 then
  begin
    showmessage('请选择操作图层为"全部"，然后用鼠标括出一块区域');
  end
  else
  begin
    SaveDialog1.Filter := 'Main Map Module files (*.mmd)|*.mmd';
    if SaveDialog1.Execute then
    begin
      filename := SaveDialog1.filename;
      if not SameText(ExtractFileExt(SaveDialog1.filename), '.mmd') then
        filename := filename + '.mmd';
      // scenelock := true;
      try
        FH := filecreate(filename);
        fileseek(FH, 0, 0);
        filewrite(FH, MMApcopymap.X, 4);
        filewrite(FH, MMApcopymap.Y, 4);
        for i := 0 to MMApcopymap.layernum - 1 do
        begin
          for i1 := 0 to MMApcopymap.Y - 1 do
          begin
            filewrite(FH, MMApcopymap.maplayer[i].pic[i1][0], 2 * MMApcopymap.X);
          end;
        end;

      finally
        fileclose(FH);
      end;
      try
        wartempbmp := Tbitmap.Create;

        PalSize := sizeof(TLogPalette) + 256 * sizeof(TPaletteEntry);

        pLogPalle.palVersion := $0300;
        pLogPalle.palNumEntries := 256;
        //
        for i := 0 to 255 do
        begin
          pLogPalle.palPalEntry[i].peRed := McolR[i];
          pLogPalle.palPalEntry[i].peGreen := McolG[i];
          pLogPalle.palPalEntry[i].peBlue := McolB[i];
          pLogPalle.palPalEntry[i].peFlags := PC_EXPLICIT;
        end;
        //
        Palle := CreatePalette(pLogPalette(@pLogPalle)^);

        if MMapEditMode = RLEMode then
        begin
          wartempbmp.PixelFormat := pf8bit;
          wartempbmp.Palette := Palle;
        end
        else
          wartempbmp.PixelFormat := pf32bit;

        wartempbmp.width := (MMApcopymap.X + MMApcopymap.Y) * 18 + 150;
        wartempbmp.height := (MMApcopymap.X + MMApcopymap.Y) * 9 + 150;
        wartempbmp.Canvas.Brush.Color := clblack;
        wartempbmp.Canvas.FillRect(wartempbmp.Canvas.ClipRect);

        for i := 0 to 2 do
          for ix := MMApcopymap.X - 1 downto 0 do
            for iy := MMApcopymap.Y - 1 downto 0 do
              if (MMApcopymap.maplayer[i].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1] > 0) or ((MMApcopymap.maplayer[i].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1] = 0) and (i = 0))
              then
              begin
                posx := (MMApcopymap.X - ix) * 18 - (MMApcopymap.Y - iy) * 18 + MMApcopymap.Y * 18 + 75;
                posy := (MMApcopymap.X - ix) * 9 + (MMApcopymap.Y - iy) * 9 + 110;

                // McoldrawRLE8(@scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].data[0],scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].size,@scenetempbmp, posx,posy, true);
                case MMapEditMode of
                  RLEMode:
                    begin
                      if (MMApcopymap.maplayer[i].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1] div 2 >= 0) and
                        (MMApcopymap.maplayer[i].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1] div 2 < MMApgrpnum) and
                        (MMApgrp[MMApcopymap.maplayer[i].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1] div 2].size >= 8) then
                        McoldrawRLE8(@MMApgrp[MMApcopymap.maplayer[i].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1] div 2].data[0],
                          MMApgrp[MMApcopymap.maplayer[i].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1] div 2].size, @wartempbmp, posx, posy, true);
                    end;
                  IMZMode, PNGMode:
                    begin
                      // imzFile.DrawImztocanvasEx(image5.Canvas, @imzFIle.imzFile, tempint, 0, 0, 0);
                      ImzFile.SceneQuickDraw(@wartempbmp, MMApcopymap.maplayer[i].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1] div 2, posx, posy);
                    end;
                end;
              end;

        wartempbmp.SaveToFile(filename + '.bmp');
      finally
        wartempbmp.Free;
      end;

    end;
  end;
  MMApstill := 0;
  MMApstillx := -1;
end;

function readMmapGRP: Integer;
var
  offset: array of Integer;
  i, idx, grp, temp: Integer;
begin
  result := 1;
  try
    idx := fileopen(gamepath + MMapfileIDX, fmopenread);
    grp := fileopen(gamepath + MMapfilegrp, fmopenread);
    temp := fileseek(idx, 0, 2);
    MMApgrpnum := temp div 4;
    setlength(MMApgrp, temp div 4);
    setlength(offset, temp div 4 + 1);
    fileseek(idx, 0, 0);
    fileread(idx, offset[1], temp);
    offset[0] := 0;
    fileseek(grp, 0, 0);
    for i := 0 to ((temp div 4) - 1) do
    begin
      MMApgrp[i].size := offset[i + 1] - offset[i];
      if MMApgrp[i].size < 0 then
        MMApgrp[i].size := 0;
      setlength(MMApgrp[i].data, MMApgrp[i].size);
      if MMApgrp[i].size > 0 then
        fileread(grp, MMApgrp[i].data[0], MMApgrp[i].size);
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
  if CheckBox1.Checked then
  begin
    Panel7.Visible := true;
    needupdate := true;
  end
  else
  begin
    Panel7.Visible := false;
  end;
end;

procedure TForm13.ComboBox1Select(Sender: TObject);
var
  i: Integer;
begin
  MMAplayer := ComboBox1.ItemIndex - 1;
  if MMAplayer = 3 then
  begin
    qbuildx := 0;
    qbuildy := 0;
  end;
  if MMAplayer = 4 then
  begin
    MMApcopymapmode := 1;
    nowMMApgrpnum := -1;
    MMApcopymap.layernum := MMApfile.Map[0].layernum;
    setlength(MMApcopymap.maplayer, MMApcopymap.layernum);
    MMApcopymap.X := 1;
    MMApcopymap.Y := 1;
    for i := 0 to 2 do
    begin
      setlength(MMApcopymap.maplayer[i].pic, MMApcopymap.Y, MMApcopymap.X);
      MMApcopymap.maplayer[i].pic[0][0] := 0;
    end;
    for i := 3 to 4 do
    begin
      setlength(MMApcopymap.maplayer[i].pic, MMApcopymap.Y, MMApcopymap.X);
      MMApcopymap.maplayer[i].pic[0][0] := -1;
    end;
  end;
end;

procedure TForm13.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  MMApopbmp.Free;
  MMApbufbmp.Free;
  setlength(MMApgrp, 0);
  setlength(MMApfile.Map, 0);
  setlength(MMApcopymap.maplayer, 0);
  ImzFile.ReleaseAllPNG;
  ImzFile.Free;
  setlength(MMapPNGBuf.data, 0, 0);
  MMapbufbmppng.Free;
  MMapopbmppng.Free;
  CForm13 := true;
  Action := cafree;
end;

procedure TForm13.FormCreate(Sender: TObject);
var
  i: Integer;
  PalSize: longint;
  pLogPalle: TMaxLogPalette;
  PalleEntry: TPaletteEntry;
  Palle: HPalette;
begin
  MMapInitial := false;
  ImzFile := TimzFile.Create;

  ReadMModeIni;

  try
    PalSize := sizeof(TLogPalette) + 256 * sizeof(TPaletteEntry);
    // pLogPalle:=MemAlloc(PalSize);
    // getmem(Plogpalle, palsize);
    pLogPalle.palVersion := $0300;
    pLogPalle.palNumEntries := 256;
    //
    for i := 0 to 255 do
    begin
      pLogPalle.palPalEntry[i].peRed := McolR[i];
      pLogPalle.palPalEntry[i].peGreen := McolG[i];
      pLogPalle.palPalEntry[i].peBlue := McolB[i];
      pLogPalle.palPalEntry[i].peFlags := PC_EXPLICIT;
    end;
    //
    Palle := CreatePalette(pLogPalette(@pLogPalle)^);
  except
    showmessage('大地图编辑器打开失败！原因是调色板设置失败，可能是调色板文件未找到。请检查游戏路径以及ini文件设置！');
    self.Close;
    exit;
  end;

  nowMMApgrpnum := -1;
  MMAplayer := -1;

  MMapopbmppng := Tbitmap.Create;
  MMapopbmppng.width := Image1.width + 400;
  MMapopbmppng.height := Image1.height + 200;
  MMapopbmppng.Canvas.Font.size := 8;
  MMapopbmppng.Canvas.Font.Color := clyellow;
  MMapopbmppng.PixelFormat := pf32bit;

  MMapbufbmppng := Tbitmap.Create;
  MMapbufbmppng.width := Image1.width + 400;
  MMapbufbmppng.height := Image1.height + 200;
  MMapbufbmppng.Canvas.Font.size := 8;
  MMapbufbmppng.Canvas.Font.Color := clyellow;
  MMapbufbmppng.PixelFormat := pf32bit;

  SetEditMode(MMapEditMode);
  RadioGroup1.ItemIndex := Integer(MMapEditMode);
  if not( { (readMmapGRP = 1) and } (readMmapfile = 1)) then
  begin
    showmessage('大地图编辑器打开失败！地图文件数据错误或未找到。请检查游戏路径以及ini文件设置！');
    self.Close;
    exit;
  end;
  try
    qbuildx := -1;
    qbuildy := -1;
    MMApopbmp := Tbitmap.Create;
    MMApopbmp.width := Image1.width + 400;
    MMApopbmp.height := Image1.height + 200;
    MMApopbmp.PixelFormat := pf8bit;
    MMApopbmp.Palette := Palle;
    MMApbufbmp := Tbitmap.Create;
    MMApbufbmp.width := Image1.width + 400;
    MMApbufbmp.height := Image1.height + 200;
    MMApbufbmp.PixelFormat := pf8bit;
    MMApbufbmp.Palette := Palle;
    MMApsmallbmp := Tbitmap.Create;
    MMApsmallbmp.PixelFormat := pf8bit;
    MMApbufbmp.Palette := Palle;
    MMApsmallbmp.Canvas.Brush.Color := CLWHITE; // $707030;
    MMApsmallbmp.Palette := Palle;
    MMApsmallbmp.width := 500;
    MMApsmallbmp.height := 500;
    ScrollBar1.Min := 0;
    ScrollBar1.Max := Max(MMApfile.Map[0].X, MMApfile.Map[0].Y) - 1;
    ScrollBar2.Min := 0;
    ScrollBar2.Max := Max(MMApfile.Map[0].X, MMApfile.Map[0].Y) - 1;
    ScrollBar2.Position := ScrollBar2.Max div 2;
    ScrollBar1.Position := ScrollBar1.Max div 2;



    // displayMmap(@Mmapfile.map[0], @Mmapopbmp);
    // Mmapbufbmp.Canvas.CopyRect(Mmapbufbmp.Canvas.ClipRect, Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
    // image1.Canvas.CopyRect(image1.ClientRect,Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);

  except
    showmessage('大地图编辑打开失败！');
    self.Close;
    exit;
  end;
  Timer1.Enabled := true;

  MMapInitial := true;
end;

procedure TForm13.FormResize(Sender: TObject);
var
  temprect: TRect;
begin
  try
    if MMapEditMode <> RLEMode then
    begin
      MMapPNGBuf.width := Image1.width + 400;
      MMapPNGBuf.height := Image1.height + 200;
      setlength(MMapPNGBuf.data, MMapPNGBuf.height, MMapPNGBuf.width * 4);
      MMapbufbmppng.height := Image1.height + 200;
      MMapopbmppng.width := Image1.width + 400;
      MMapopbmppng.height := Image1.height + 200;
      MMapbufbmppng.width := Image1.width + 400;
    end;
    Image1.Picture.Bitmap.width := Image1.width;
    Image1.Picture.Bitmap.height := Image1.height;
    MMApbufbmp.height := Image1.height + 200;
    MMApopbmp.width := Image1.width + 400;
    MMApopbmp.height := Image1.height + 200;
    MMApbufbmp.width := Image1.width + 400;
    // displayMmap(@Mmapfile.map[0], @Mmapopbmp);
    // temprect := image1.Canvas.ClipRect;
    // temprect.Left :=temprect.Left + 200;
    // temprect.Right := temprect.Right + 200;
    // Mmapbufbmp.Canvas.CopyRect(Mmapbufbmp.Canvas.ClipRect, Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
    // image1.Canvas.CopyRect(image1.Canvas.ClipRect,Mmapopbmp.Canvas,temprect);
    needupdate := true;
  except

  end;
end;

procedure TForm13.Image1DragDrop(Sender, Source: TObject; X, Y: Integer);
begin
  if MMAplayer = 4 then
  begin
    showmessage('请选择其他图层再进行拖拽操作！');
    exit;
  end;
  if IMZDrag then
  begin
    // showmessage('imzdrag');
    if MMapEditMode <> RLEMode then
      nowMMApgrpnum := imzdragint;
  end
  else
  begin
    // showmessage('grpdrag');
    if MMapEditMode = RLEMode then
      nowMMApgrpnum := movelock;
  end;
  // nowMmapgrpnum := movelock;

  MMApcopymapmode := 0;
  self.BringToFront;
end;

procedure TForm13.Image1DragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  //
end;

procedure TForm13.Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  axp, ayp, posx, posy, pointx, pointy: Integer;
  temprect: TRect;
  ix, iy, i: Integer;
  tempmap: Tmap;
begin
  if Button = mbright then
  begin
    if (MMApcopymapmode <> 1) and (nowMMApgrpnum >= 0) and (MMAplayer < 2) and (MMAplayer >= 0) then
    begin
      MMApfile.Map[0].maplayer[MMAplayer].pic[MMAptempy][MMAptempx] := nowMMApgrpnum * 2;
      needupdate := true;
      UpdateMainSmallBmp;
    end
    else if (MMApcopymapmode <> 1) and (nowMMApgrpnum >= 0) and (MMAplayer = 2) then
    begin
      MMApfile.Map[0].maplayer[MMAplayer].pic[MMAptempy][MMAptempx] := nowMMApgrpnum * 2;
      needupdate := true;
      if nowMMApgrpnum > 0 then
      begin
        MMApfile.Map[0].maplayer[MMAplayer + 1].pic[MMAptempy][MMAptempx] := MMAptempx;
        MMApfile.Map[0].maplayer[MMAplayer + 2].pic[MMAptempy][MMAptempx] := MMAptempy;
      end
      else
      begin
        MMApfile.Map[0].maplayer[MMAplayer + 1].pic[MMAptempy][MMAptempx] := 0;
        MMApfile.Map[0].maplayer[MMAplayer + 2].pic[MMAptempy][MMAptempx] := 0;
      end;
      UpdateMainSmallBmp;
    end
    else if MMAplayer = 3 then
    begin
      if (qbuildx < 0) or (qbuildx >= MMApfile.Map[0].X) or (qbuildy < 0) or (qbuildy >= MMApfile.Map[0].Y) then
      begin
        qbuildx := 0;
        qbuildy := 0;
      end;
      MMApfile.Map[0].maplayer[3].pic[MMAptempy][MMAptempx] := qbuildx;
      MMApfile.Map[0].maplayer[4].pic[MMAptempy][MMAptempx] := qbuildy;
      UpdateMainSmallBmp;
      // qbuildx := Mmaptempx;
      // qbuildy := Mmaptempy;
    end
    else if (MMApcopymapmode = 1) and (nowMMApgrpnum < 0) and ((MMAplayer = 0) or (MMAplayer = 1)) then
    begin
      for ix := 0 to MMApcopymap.X - 1 do
        for iy := 0 to MMApcopymap.Y - 1 do
          if (MMAptempx - ix >= 0) and (MMAptempx - ix < MMApfile.Map[0].X) and (MMAptempy - iy >= 0) and (-iy + MMAptempy < MMApfile.Map[0].Y) then
            MMApfile.Map[0].maplayer[MMAplayer].pic[MMAptempy - iy][MMAptempx - ix] := MMApcopymap.maplayer[MMAplayer].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1];
      needupdate := true;
      UpdateMainSmallBmp;
      // Updatesmallimg(image1.Width DIV 2,image1.Height div 2 - 31 * 18, scenetempx, scenetempy);
      // copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup[0]);
      // copyscenemapevent(@Dfile.mapevent[combobox2.ItemIndex], @scenemapeventbackup[0]);
    end
    else if (MMApcopymapmode = 1) and (nowMMApgrpnum < 0) and (MMAplayer = 2) then
    begin
      copymap(@tempmap, @MMApcopymap);
      temprect.Left := MMAptempx - tempmap.X + 1;
      temprect.Right := MMAptempx;
      temprect.Top := MMAptempy - tempmap.Y + 1;
      temprect.Bottom := MMAptempy;
      calbackcopymap(@tempmap, temprect);
      for i := 2 to 4 do
        for ix := 0 to MMApcopymap.X - 1 do
          for iy := 0 to MMApcopymap.Y - 1 do
            if (MMAptempx - ix >= 0) and (MMAptempx - ix < MMApfile.Map[0].X) and (MMAptempy - iy >= 0) and (-iy + MMAptempy < MMApfile.Map[0].Y) then
              MMApfile.Map[0].maplayer[i].pic[MMAptempy - iy][MMAptempx - ix] := tempmap.maplayer[i].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1];
      setlength(tempmap.maplayer, 0);
      needupdate := true;
      UpdateMainSmallBmp;

    end
    else if (MMApcopymapmode = 1) and (nowMMApgrpnum < 0) and (MMAplayer = 4) then
    begin
      copymap(@tempmap, @MMApcopymap);
      temprect.Left := MMAptempx - tempmap.X + 1;
      temprect.Right := MMAptempx;
      temprect.Top := MMAptempy - tempmap.Y + 1;
      temprect.Bottom := MMAptempy;
      calbackcopymap(@tempmap, temprect);
      for i := 0 to 4 do
        for ix := 0 to MMApcopymap.X - 1 do
          for iy := 0 to MMApcopymap.Y - 1 do
            if (MMAptempx - ix >= 0) and (MMAptempx - ix < MMApfile.Map[0].X) and (MMAptempy - iy >= 0) and (-iy + MMAptempy < MMApfile.Map[0].Y) then
              MMApfile.Map[0].maplayer[i].pic[MMAptempy - iy][MMAptempx - ix] := tempmap.maplayer[i].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1];
      // 还需要修改引用建筑层
      setlength(tempmap.maplayer, 0);
      needupdate := true;
      UpdateMainSmallBmp;
    end;
  end
  else if Button = mbleft then
  begin
    if ((MMAplayer >= 0) and (MMAplayer <> 3)) or (MMAplayer = 4) then
    begin
      MMApstill := 1;
      MMApstillx := MMAptempx;
      MMApstilly := MMAptempy;
      needupdate := true;
    end
    else
    begin
      MMApstill := 0;
    end;
  end;
end;

procedure TForm13.Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  mousex := X;
  mousey := Y;
end;

procedure TForm13.copymap(Dest, Source: Pmap);
var
  i: Integer;
  ix, iy: Integer;
begin
  //
  Dest.layernum := Source.layernum;
  Dest.X := Source.X;
  Dest.Y := Source.Y;
  setlength(Dest.maplayer, Dest.layernum);
  for i := 0 to Dest.layernum - 1 do
  begin
    setlength(Dest.maplayer[i].pic, Dest.Y, Dest.X);
    if Dest.X > 0 then
      for iy := 0 to Dest.Y - 1 do
        copymemory(@Dest.maplayer[i].pic[iy][0], @Source.maplayer[i].pic[iy][0], Dest.X * sizeof(smallint));
  end;
end;

procedure TForm13.calcopymap(Map: Pmap; Rect: TRect);
var
  ix, iy: Integer;
begin
  //
  for ix := 0 to Map.X - 1 do
    for iy := 0 to Map.Y - 1 do
    begin
      if (Map.maplayer[3].pic[iy][ix] = 0) and (Map.maplayer[4].pic[iy][ix] = 0) then
      begin
        Map.maplayer[3].pic[iy][ix] := -1;
        Map.maplayer[4].pic[iy][ix] := -1;
      end
      else if (Map.maplayer[3].pic[iy][ix] >= Rect.Left) and (Map.maplayer[3].pic[iy][ix] <= Rect.Right) and (Map.maplayer[4].pic[iy][ix] >= Rect.Top) and (Map.maplayer[4].pic[iy][ix] <= Rect.Bottom)
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

procedure TForm13.calbackcopymap(Map: Pmap; Rect: TRect);
var
  ix, iy: Integer;
begin
  //
  for ix := 0 to Map.X - 1 do
    for iy := 0 to Map.Y - 1 do
    begin
      if (Map.maplayer[3].pic[iy][ix] = -1) and (Map.maplayer[4].pic[iy][ix] = -1) then
      begin
        Map.maplayer[3].pic[iy][ix] := 0;
        Map.maplayer[4].pic[iy][ix] := 0;
      end
      else if (Map.maplayer[3].pic[iy][ix] >= 0) and (Map.maplayer[3].pic[iy][ix] < Map.X) and (Map.maplayer[4].pic[iy][ix] >= 0) and (Map.maplayer[4].pic[iy][ix] < Map.Y) and
        (Map.maplayer[2].pic[Map.maplayer[4].pic[iy][ix]][Map.maplayer[3].pic[iy][ix]] > 0) then
      begin
        Map.maplayer[3].pic[iy][ix] := Map.maplayer[3].pic[iy][ix] + Rect.Left;
        Map.maplayer[4].pic[iy][ix] := Map.maplayer[4].pic[iy][ix] + Rect.Top;
        if (Map.maplayer[3].pic[iy][ix] < 0) or (Map.maplayer[3].pic[iy][ix] >= MMApfile.Map[0].X) or (Map.maplayer[4].pic[iy][ix] < 0) or (Map.maplayer[4].pic[iy][ix] >= MMApfile.Map[0].Y) then
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

procedure TForm13.Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  axp, ayp, posx, posy, pointx, pointy: Integer;
  temprect: TRect;
  lx, ly, sx, sy, temp, ix, iy, i: Integer;
begin
  //
  if Button = mbleft then
  begin
    if ((MMAplayer < 3) and (MMAplayer >= 0)) or (MMAplayer = 4) then
    begin
      if (((MMApstillx <> MMAptempx) or (MMApstilly <> MMAptempy)) or (MMAplayer = 4)) and (MMApstill = 1) then
      begin
        // 拷贝地图
        MMApcopymapmode := 1;
        lx := MMAptempx;
        ly := MMAptempy;
        if (MMAptempx >= MMApfile.Map[0].X) then
          lx := MMApfile.Map[0].X - 1
        else if (MMAptempx < 0) then
          lx := 0;
        if (MMAptempy >= MMApfile.Map[0].Y) then
          ly := MMApfile.Map[0].Y - 1
        else if (MMAptempy < 0) then
          ly := 0;
        if (MMApstillx >= 0) and (MMApstillx < MMApfile.Map[0].X) and (MMApstilly >= 0) and (MMApstilly < MMApfile.Map[0].Y) then
        begin
          sx := MMApstillx;
          sy := MMApstilly;
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
          MMApcopymapmode := 1;
          nowMMApgrpnum := -1;
          MMApcopymap.layernum := MMApfile.Map[0].layernum;
          MMApcopymap.X := lx - sx + 1;
          MMApcopymap.Y := ly - sy + 1;
          setlength(MMApcopymap.maplayer, MMApcopymap.layernum);
          for i := 0 to MMApcopymap.layernum - 1 do
          begin
            setlength(MMApcopymap.maplayer[i].pic, MMApcopymap.Y, MMApcopymap.X);
            for ix := sx to lx do
              for iy := sy to ly do
              begin
                MMApcopymap.maplayer[i].pic[iy - sy][ix - sx] := MMApfile.Map[0].maplayer[i].pic[iy][ix];
              end;
          end;
          temprect.Left := sx;
          temprect.Right := lx;
          temprect.Top := sy;
          temprect.Bottom := ly;
          calcopymap(@MMApcopymap, temprect);
        end;
      end
      else if (MMAplayer >= 0) and (MMAplayer <= 2) then
      begin
        nowMMApgrpnum := MMApfile.Map[0].maplayer[MMAplayer].pic[MMAptempy][MMAptempx] div 2;
        needupdate := true;
      end;
    end
    else if MMAplayer = 3 then
    begin
      if MMApfile.Map[0].maplayer[2].pic[MMAptempy][MMAptempx] div 2 > 0 then
      begin
        qbuildx := MMAptempx;
        qbuildy := MMAptempy;
      end
      else
      begin
        qbuildx := 0;
        qbuildy := 0;
      end;
      MMApbufbmp.Canvas.CopyRect(MMApbufbmp.Canvas.ClipRect, MMApopbmp.Canvas, MMApopbmp.Canvas.ClipRect);
      pointx := Image1.width div 2;
      pointy := Image1.height div 2;
      axp := Round(((mousex - pointx) / 18 + (mousey - pointy + 9) / 9) / 2);
      ayp := Round(-((mousex - pointx) / 18 - (mousey - pointy + 9) / 9) / 2);
      posx := axp * 18 - ayp * 18 + pointx - 18 + 200;
      posy := axp * 9 + ayp * 9 + pointy - 9;
      MMApbufbmp.Canvas.Font.Color := clyellow;
      MMApbufbmp.Canvas.Font.size := 9;
      MMApbufbmp.Canvas.Brush.Style := bsclear;
      MMApbufbmp.Canvas.TextOut(posx, posy, '(' + inttostr(qbuildx) + ',' + inttostr(qbuildy) + ')');
      temprect := Image1.Canvas.ClipRect;
      temprect.Left := temprect.Left + 200;
      temprect.Right := temprect.Right + 200;
      Image1.Canvas.CopyRect(Image1.ClientRect, MMApbufbmp.Canvas, temprect);
    end;
    MMApstill := 0;
  end;
end;

procedure TForm13.Panel9Resize(Sender: TObject);
begin
  FormResize(Sender);
end;

procedure TForm13.ScrollBar1Change(Sender: TObject);
begin
  // displayMmap(@Mmapfile.map[0], @Mmapopbmp);
  // Mmapbufbmp.Canvas.CopyRect(Mmapbufbmp.Canvas.ClipRect, Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
  // image1.Canvas.CopyRect(image1.ClientRect,Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
  needupdate := true;
end;

procedure TForm13.ScrollBar2Change(Sender: TObject);
begin
  // displayMmap(@Mmapfile.map[0], @Mmapopbmp);
  // Mmapbufbmp.Canvas.CopyRect(Mmapbufbmp.Canvas.ClipRect, Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
  // image1.Canvas.CopyRect(image1.ClientRect,Mmapopbmp.Canvas,Mmapopbmp.Canvas.ClipRect);
  needupdate := true;
end;

procedure TForm13.UpdateMainSmallBmp;
begin
  try
    Image2.Canvas.Brush.Color := CLWHITE; // $606060;
    Image2.Canvas.FillRect(Image2.Canvas.ClipRect);
    Image3.Canvas.Brush.Color := CLWHITE; // $606060;
    Image3.Canvas.FillRect(Image3.Canvas.ClipRect);
    Image4.Canvas.Brush.Color := CLWHITE; // $606060;
    Image4.Canvas.FillRect(Image4.Canvas.ClipRect);
    Image5.Canvas.Brush.Color := CLWHITE; // $606060;
    Image5.Canvas.FillRect(Image5.Canvas.ClipRect);
    if (MMAptempx >= 0) and (MMAptempx < MMApfile.Map[0].X) and (MMAptempy >= 0) and (MMAptempy < MMApfile.Map[0].Y) then
    begin
      MMApsmallbmp.Canvas.Brush.Color := CLWHITE; // $606060;
      MMApsmallbmp.Canvas.FillRect(MMApsmallbmp.Canvas.ClipRect);
      if MMApfile.Map[0].maplayer[0].pic[MMAptempy][MMAptempx] > 0 then
      begin
        // Mmapsmallbmp.Width := image2.Width;
        // Mmapsmallbmp.Height := image2.Height;
        case MMapEditMode of
          RLEMode:
            begin
              if (MMApfile.Map[0].maplayer[0].pic[MMAptempy][MMAptempx] div 2 >= 0) and (MMApfile.Map[0].maplayer[0].pic[MMAptempy][MMAptempx] div 2 < MMApgrpnum) and
                (MMApgrp[MMApfile.Map[0].maplayer[0].pic[MMAptempy][MMAptempx] div 2].size >= 8) then
              begin
                McoldrawRLE8(@MMApgrp[MMApfile.Map[0].maplayer[0].pic[MMAptempy][MMAptempx] div 2].data[0], MMApgrp[MMApfile.Map[0].maplayer[0].pic[MMAptempy][MMAptempx] div 2].size, @MMApsmallbmp, 0,
                  0, false);
                Image2.Canvas.CopyRect(Image2.Canvas.ClipRect, MMApsmallbmp.Canvas, Image2.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              ImzFile.DrawImztocanvas(Image2.Canvas, @ImzFile.ImzFile, MMApfile.Map[0].maplayer[0].pic[MMAptempy][MMAptempx] div 2, 0, 0, 0);
            end;
        end;
      end;
      MMApsmallbmp.Canvas.Brush.Color := CLWHITE; // $606060;
      MMApsmallbmp.Canvas.FillRect(MMApsmallbmp.Canvas.ClipRect);

      if MMApfile.Map[0].maplayer[1].pic[MMAptempy][MMAptempx] > 0 then
      begin
        // Mmapsmallbmp.Width := image3.Width;
        // Mmapsmallbmp.Height := image3.Height;
        case MMapEditMode of
          RLEMode:
            begin
              if (MMApfile.Map[0].maplayer[1].pic[MMAptempy][MMAptempx] div 2 >= 0) and (MMApfile.Map[0].maplayer[1].pic[MMAptempy][MMAptempx] div 2 < MMApgrpnum) and
                (MMApgrp[MMApfile.Map[0].maplayer[1].pic[MMAptempy][MMAptempx] div 2].size >= 8) then
              begin
                McoldrawRLE8(@MMApgrp[MMApfile.Map[0].maplayer[1].pic[MMAptempy][MMAptempx] div 2].data[0], MMApgrp[MMApfile.Map[0].maplayer[1].pic[MMAptempy][MMAptempx] div 2].size, @MMApsmallbmp, 0,
                  0, false);
                Image3.Canvas.CopyRect(Image3.Canvas.ClipRect, MMApsmallbmp.Canvas, Image3.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              ImzFile.DrawImztocanvas(Image3.Canvas, @ImzFile.ImzFile, MMApfile.Map[0].maplayer[1].pic[MMAptempy][MMAptempx] div 2, 0, 0, 0);
            end;
        end;
      end;
      MMApsmallbmp.Canvas.Brush.Color := CLWHITE; // $606060;
      MMApsmallbmp.Canvas.FillRect(MMApsmallbmp.Canvas.ClipRect);
      if MMApfile.Map[0].maplayer[2].pic[MMAptempy][MMAptempx] > 0 then
      begin
        // Mmapsmallbmp.Width := image4.Width;
        // Mmapsmallbmp.Height := image4.Height;
        case MMapEditMode of
          RLEMode:
            begin
              if (MMApfile.Map[0].maplayer[2].pic[MMAptempy][MMAptempx] div 2 >= 0) and (MMApfile.Map[0].maplayer[2].pic[MMAptempy][MMAptempx] div 2 < MMApgrpnum) and
                (MMApgrp[MMApfile.Map[0].maplayer[2].pic[MMAptempy][MMAptempx] div 2].size >= 8) then
              begin
                McoldrawRLE8(@MMApgrp[MMApfile.Map[0].maplayer[2].pic[MMAptempy][MMAptempx] div 2].data[0], MMApgrp[MMApfile.Map[0].maplayer[2].pic[MMAptempy][MMAptempx] div 2].size, @MMApsmallbmp, 0,
                  0, false);
                Image4.Canvas.CopyRect(Image4.Canvas.ClipRect, MMApsmallbmp.Canvas, Image4.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              ImzFile.DrawImztocanvas(Image4.Canvas, @ImzFile.ImzFile, MMApfile.Map[0].maplayer[2].pic[MMAptempy][MMAptempx] div 2, 0, 0, 0);
            end;
        end;
      end;
      MMApsmallbmp.Canvas.Brush.Color := CLWHITE; // $606060;
      MMApsmallbmp.Canvas.FillRect(MMApsmallbmp.Canvas.ClipRect);
      if MMApfile.Map[0].maplayer[2].pic[MMApfile.Map[0].maplayer[4].pic[MMAptempy][MMAptempx]][MMApfile.Map[0].maplayer[3].pic[MMAptempy][MMAptempx]] > 0 then
      begin
        // Mmapsmallbmp.Width := image5.Width;
        // Mmapsmallbmp.Height := image5.Height;
        case MMapEditMode of
          RLEMode:
            begin
              if (MMApfile.Map[0].maplayer[4].pic[MMAptempy][MMAptempx] >= 0) and (MMApfile.Map[0].maplayer[4].pic[MMAptempy][MMAptempx] < MMApfile.Map[0].Y) and
                (MMApfile.Map[0].maplayer[3].pic[MMAptempy][MMAptempx] >= 0) and (MMApfile.Map[0].maplayer[3].pic[MMAptempy][MMAptempx] < MMApfile.Map[0].X) and
                (MMApfile.Map[0].maplayer[2].pic[MMApfile.Map[0].maplayer[4].pic[MMAptempy][MMAptempx]][MMApfile.Map[0].maplayer[3].pic[MMAptempy][MMAptempx]] div 2 >= 0) and
                (MMApfile.Map[0].maplayer[2].pic[MMApfile.Map[0].maplayer[4].pic[MMAptempy][MMAptempx]][MMApfile.Map[0].maplayer[3].pic[MMAptempy][MMAptempx]] div 2 < MMApgrpnum) and
                (MMApgrp[MMApfile.Map[0].maplayer[2].pic[MMApfile.Map[0].maplayer[4].pic[MMAptempy][MMAptempx]][MMApfile.Map[0].maplayer[3].pic[MMAptempy][MMAptempx]] div 2].size >= 8) then
              begin
                McoldrawRLE8(@MMApgrp[MMApfile.Map[0].maplayer[2].pic[MMApfile.Map[0].maplayer[4].pic[MMAptempy][MMAptempx]][MMApfile.Map[0].maplayer[3].pic[MMAptempy][MMAptempx]] div 2].data[0],
                  MMApgrp[MMApfile.Map[0].maplayer[2].pic[MMApfile.Map[0].maplayer[4].pic[MMAptempy][MMAptempx]][MMApfile.Map[0].maplayer[3].pic[MMAptempy][MMAptempx]] div 2].size, @MMApsmallbmp, 0,
                  0, false);
                Image5.Canvas.CopyRect(Image5.Canvas.ClipRect, MMApsmallbmp.Canvas, Image5.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              ImzFile.DrawImztocanvas(Image5.Canvas, @ImzFile.ImzFile, MMApfile.Map[0].maplayer[2].pic[MMApfile.Map[0].maplayer[4].pic[MMAptempy][MMAptempx]]
                [MMApfile.Map[0].maplayer[3].pic[MMAptempy][MMAptempx]] div 2, 0, 0, 0);
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
  axp, ayp: Integer;
  pointx, pointy, posx, posy, ix, iy, i: Integer;
  temprect: TRect;
  tempint: Integer;
  lx, ly, sx, sy, temp: Integer;
begin

  pointx := Image1.width div 2;
  pointy := Image1.height div 2;
  axp := Round(((mousex - pointx) / 18 + (mousey - pointy + 9) / 9) / 2);
  ayp := Round(-((mousex - pointx) / 18 - (mousey - pointy + 9) / 9) / 2);
  // Axp := (mousex - pointx + 2 * mousey - pointy * 2 + 18) div 36;
  // Ayp := (-mousex + pointx + 2 * mousey - pointy * 2 + 18) div 36;
  ix := axp;
  iy := ayp;
  axp := axp + ScrollBar1.Position + ScrollBar2.Position - MMApfile.Map[0].Y div 2;
  ayp := ayp + ScrollBar2.Position - ScrollBar1.Position + MMApfile.Map[0].Y div 2;

  if needupdate then
  begin
    try
      needupdate := false;
      temprect := Image1.Canvas.ClipRect;
      temprect.Left := temprect.Left + 200;
      temprect.Right := temprect.Right + 200;
      if MMapEditMode = RLEMode then
      begin
        displayMmap(@MMApfile.Map[0], @MMApopbmp);
        MMApbufbmp.Canvas.CopyRect(MMApbufbmp.Canvas.ClipRect, MMApopbmp.Canvas, MMApopbmp.Canvas.ClipRect);
        Image1.Canvas.CopyRect(Image1.ClientRect, MMApbufbmp.Canvas, temprect);
      end
      else
      begin
        displayMmap(@MMApfile.Map[0], @MMapopbmppng);
        MMapbufbmppng.Canvas.CopyRect(MMapbufbmppng.Canvas.ClipRect, MMapopbmppng.Canvas, MMapopbmppng.Canvas.ClipRect);
        Image1.Canvas.CopyRect(Image1.ClientRect, MMapbufbmppng.Canvas, temprect);
      end;
    except
      showmessage('更新地图错误！');
    end;
  end;
  if (axp <> MMAptempx) or (ayp <> MMAptempy) then
  begin
    try
      MMAptempx := axp;
      MMAptempy := ayp;

      StatusBar1.Canvas.Brush.Color := clbtnface;
      StatusBar1.Canvas.FillRect(StatusBar1.Canvas.ClipRect);
      StatusBar1.Repaint;
      StatusBar1.Canvas.TextOut(10, 10, 'X=' + inttostr(axp) + ',Y=' + inttostr(ayp));
      if MMapEditMode = RLEMode then
      begin
        MMApbufbmp.Canvas.CopyRect(MMApbufbmp.Canvas.ClipRect, MMApopbmp.Canvas, MMApopbmp.Canvas.ClipRect);
      end
      else
      begin
        MMapbufbmppng.Canvas.CopyRect(MMapbufbmppng.Canvas.ClipRect, MMapopbmppng.Canvas, MMapopbmppng.Canvas.ClipRect);
      end;
      axp := ix;
      ayp := iy;
      if (MMAptempx >= 0) and (MMAptempy >= 0) and (MMAptempx < MMApfile.Map[0].X) and (MMAptempy < MMApfile.Map[0].Y) then
      begin
        Label6.Caption := inttostr(MMApfile.Map[0].maplayer[0].pic[MMAptempy][MMAptempx] div 2);
        Label7.Caption := inttostr(MMApfile.Map[0].maplayer[1].pic[MMAptempy][MMAptempx] div 2);
        Label8.Caption := inttostr(MMApfile.Map[0].maplayer[2].pic[MMAptempy][MMAptempx] div 2);
        Label9.Caption := '(' + inttostr(MMApfile.Map[0].maplayer[3].pic[MMAptempy][MMAptempx]) + ',' + inttostr(MMApfile.Map[0].maplayer[4].pic[MMAptempy][MMAptempx]) + ')';
      end;

      UpdateMainSmallBmp;

      if MMApstill = 1 then
      begin
        if ((MMAplayer >= 0) and (MMAplayer < 3)) or (MMAplayer = 4) then
        begin
          if (MMAptempx <> MMApstillx) or (MMAptempy <> MMApstilly) then
          begin
            sx := axp;
            lx := axp + MMApstillx - MMAptempx;
            sy := ayp;
            ly := ayp + MMApstilly - MMAptempy;
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
                posx := ix * 18 - iy * 18 + pointx + 200;
                posy := ix * 9 + iy * 9 + pointy;
                drawsquare(posx, posy);
              end;
          end;
        end;
      end
      else if (nowMMApgrpnum >= 0) and (MMAplayer < 3) and (MMAplayer >= 0) then
      begin
        posx := axp * 18 - ayp * 18 + pointx + 200;
        posy := axp * 9 + ayp * 9 + pointy;
        if MMapEditMode = RLEMode then
        begin
          if (nowMMApgrpnum >= 0) and (nowMMApgrpnum < MMApgrpnum) and (MMApgrp[nowMMApgrpnum].size >= 8) then
            McoldrawRLE8(@MMApgrp[nowMMApgrpnum].data[0], MMApgrp[nowMMApgrpnum].size, @MMApbufbmp, posx, posy, true);
        end
        else
        begin
          ImzFile.SceneQuickDraw(@MMapbufbmppng, nowMMApgrpnum, posx, posy);
        end;

      end
      else if MMAplayer = 3 then
      begin
        if (qbuildx < 0) or (qbuildx >= MMApfile.Map[0].X) or (qbuildy < 0) or (qbuildy >= MMApfile.Map[0].Y) then
        begin
          qbuildx := 0;
          qbuildy := 0;
        end;
        posx := axp * 18 - ayp * 18 + pointx - 18 + 200;
        posy := axp * 9 + ayp * 9 + pointy - 9;
        if MMapEditMode = RLEMode then
        begin
          MMApbufbmp.Canvas.Font.Color := clyellow;
          MMApbufbmp.Canvas.Font.size := 9;
          MMApbufbmp.Canvas.Brush.Style := bsclear;
          MMApbufbmp.Canvas.TextOut(posx, posy, '(' + inttostr(qbuildx) + ',' + inttostr(qbuildy) + ')');
        end
        else
        begin
          MMapbufbmppng.Canvas.Font.Color := clyellow;
          MMapbufbmppng.Canvas.Font.size := 9;
          MMapbufbmppng.Canvas.Brush.Style := bsclear;
          MMapbufbmppng.Canvas.TextOut(posx, posy, '(' + inttostr(qbuildx) + ',' + inttostr(qbuildy) + ')');
        end;
      end
      else if (MMApcopymapmode = 1) then
      begin
        if MMAplayer = 4 then
        begin
          for i := 0 to 2 do
            for ix := MMApcopymap.X - 1 downto 0 do
              for iy := MMApcopymap.Y - 1 downto 0 do
                if (MMApcopymap.maplayer[i].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1] > 0) or ((MMApcopymap.maplayer[i].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1] = 0) and (i = 0))
                then
                begin
                  tempint := MMApcopymap.maplayer[i].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1] div 2;
                  posx := (axp - ix) * 18 - (ayp - iy) * 18 + pointx + 200;
                  posy := (axp - ix) * 9 + (ayp - iy) * 9 + pointy;
                  if MMapEditMode = RLEMode then
                  begin
                    if (tempint >= 0) and (tempint < MMApgrpnum) and (MMApgrp[tempint].size >= 8) then
                      McoldrawRLE8(@MMApgrp[tempint].data[0], MMApgrp[tempint].size, @MMApbufbmp, posx, posy, true);
                  end
                  else
                  begin
                    ImzFile.SceneQuickDraw(@MMapbufbmppng, tempint, posx, posy);
                  end;
                end;
        end
        else if (MMAplayer >= 0) and (MMAplayer < 3) then
        begin
          for ix := MMApcopymap.X - 1 downto 0 do
            for iy := MMApcopymap.Y - 1 downto 0 do
              if (MMApcopymap.maplayer[MMAplayer].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1] > 0) or
                ((MMApcopymap.maplayer[MMAplayer].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1] = 0) and (MMAplayer = 0)) then
              begin
                tempint := MMApcopymap.maplayer[MMAplayer].pic[MMApcopymap.Y - iy - 1][MMApcopymap.X - ix - 1] div 2;
                posx := (axp - ix) * 18 - (ayp - iy) * 18 + pointx + 200;
                posy := (axp - ix) * 9 + (ayp - iy) * 9 + pointy;
                if MMapEditMode = RLEMode then
                begin
                  if (tempint >= 0) and (tempint < MMApgrpnum) and (MMApgrp[tempint].size >= 8) then
                    McoldrawRLE8(@MMApgrp[tempint].data[0], MMApgrp[tempint].size, @MMApbufbmp, posx, posy, true);
                end
                else
                begin
                  ImzFile.SceneQuickDraw(@MMapbufbmppng, tempint, posx, posy);
                end;
              end;
        end;

      end;

      temprect := Image1.Canvas.ClipRect;
      temprect.Left := temprect.Left + 200;
      temprect.Right := temprect.Right + 200;
      if MMapEditMode = RLEMode then
      begin
        Image1.Canvas.CopyRect(Image1.ClientRect, MMApbufbmp.Canvas, temprect);
      end
      else
      begin
        Image1.Canvas.CopyRect(Image1.ClientRect, MMapbufbmppng.Canvas, temprect);
      end;
    except
      showmessage('主地图更改坐标错误！');
    end;
  end;
end;

function readMmapfile: Integer;
var
  ix, iy, grp, i: Integer;
begin
  //
  result := 1;
  try
    MMApfile.num := 1;
    setlength(MMApfile.Map, MMApfile.num);
    MMApfile.Map[0].layernum := 5;
    setlength(MMApfile.Map[0].maplayer, MMApfile.Map[0].layernum);
    MMApfile.Map[0].X := 480;
    MMApfile.Map[0].Y := 480;
    for i := 0 to MMApfile.Map[0].layernum - 1 do
      setlength(MMApfile.Map[0].maplayer[i].pic, MMApfile.Map[0].Y, MMApfile.Map[0].X);

    grp := fileopen(gamepath + Mearth, fmopenread);
    for iy := 0 to MMApfile.Map[0].Y - 1 do
      fileread(grp, MMApfile.Map[0].maplayer[0].pic[iy][0], MMApfile.Map[0].X * 2);
    fileclose(grp);

    grp := fileopen(gamepath + Msurface, fmopenread);
    for iy := 0 to MMApfile.Map[0].Y - 1 do
      fileread(grp, MMApfile.Map[0].maplayer[1].pic[iy][0], MMApfile.Map[0].X * 2);
    fileclose(grp);

    grp := fileopen(gamepath + Mbuilding, fmopenread);
    for iy := 0 to MMApfile.Map[0].Y - 1 do
      fileread(grp, MMApfile.Map[0].maplayer[2].pic[iy][0], MMApfile.Map[0].X * 2);
    fileclose(grp);

    grp := fileopen(gamepath + Mbuildx, fmopenread);
    for iy := 0 to MMApfile.Map[0].Y - 1 do
      fileread(grp, MMApfile.Map[0].maplayer[3].pic[iy][0], MMApfile.Map[0].X * 2);
    fileclose(grp);

    grp := fileopen(gamepath + Mbuildy, fmopenread);
    for iy := 0 to MMApfile.Map[0].Y - 1 do
      fileread(grp, MMApfile.Map[0].maplayer[4].pic[iy][0], MMApfile.Map[0].X * 2);
    fileclose(grp);
  except
    result := 0;
    fileclose(grp);
  end;
end;

procedure McoldrawRLE8(Ppic: Pbyte; len: Integer; PBMP: PNTbitmap; dx, dy: Integer; canmove: Boolean);
var
  State, i, iy, ix, linesize, temp, size: Integer;
  pw, ph, xs, ys: Integer;
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

    if (dx > PBMP.width) or (dx + pw < 0) or (dy > PBMP.height) or (dy + ph < 0) then
      exit;
    // if (dx < 0)  or ((dx + pw) >= pbmp.Width) or (dy < 0)  or ((dy + ph) >= pbmp.Height) then
    // exit;

    for iy := 0 to ph - 1 do
    begin
      linesize := Ppic^;
      Inc(Ppic);
      Inc(size);
      if size >= len then
        exit;
      if size + linesize >= len then
        exit;
      State := 2;
      ix := dx;
      i := 0;
      while i < linesize do
      begin
        if State = 2 then
        begin
          temp := (Ppic + i)^;
          ix := ix + temp;
          State := 1;
          Inc(i);
        end
        else if State = 1 then
        begin
          temp := (Ppic + i)^;
          State := 2 + temp;
          Inc(i);
        end
        else if State > 2 then
        begin
          temp := (Ppic + i)^;
          try
            // Pbuf := Pbmp.ScanLine[iy + dy];
            // copymemory((Pbuf + ix), (Ppic + I), state - 2);
            if (iy + dy < PBMP.height) and (iy + dy >= 0) then
            begin
              Pbuf := PBMP.ScanLine[iy + dy];
              if ix + State - 2 < PBMP.width then
                copymemory((Pbuf + ix), (Ppic + i), State - 2)
              else if ix < PBMP.width then
                copymemory((Pbuf + ix), (Ppic + i), PBMP.width - ix);
            end;
          except

          end;
          Inc(ix, State - 2);
          Inc(i, State - 2);
          State := 2;

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
            inc(ix); }
        end;
      end;
      Inc(Ppic, linesize);
    end;
  end;

end;

procedure TForm13.displayMmap(MmapopMap: Pmap; Mmapopbmp2: PNTbitmap);
var
  ix, iy, i, i2, posx, posy, k: Integer;
  pointx, pointy, MX, MY, I3: Integer;
  Picwidth, picheight: smallint;
  pos: TPosition;
  BuildingList, CenterList: array [0 .. 1000] of TPosition;
begin
  pointx := Mmapopbmp2.width div 2;
  pointy := (Mmapopbmp2.height - 200) div 2;
  if MMapEditMode = RLEMode then
  begin
    Mmapopbmp2.Canvas.Brush.Color := clblack;
    Mmapopbmp2.Canvas.FillRect(Mmapopbmp2.Canvas.ClipRect);
  end
  else
  begin
    for i := 0 to MMapPNGBuf.height - 1 do
      fillchar(MMapPNGBuf.data[i][0], MMapPNGBuf.width * 4, #0);
  end;

  MX := ScrollBar1.Position + ScrollBar2.Position - MMApfile.Map[0].Y div 2;
  MY := ScrollBar2.Position - ScrollBar1.Position + MMApfile.Map[0].Y div 2;
  // 地面层
  for i := -(Mmapopbmp2.height div 36) to (Mmapopbmp2.height div 36) do
  begin
    for i2 := 1 to (Mmapopbmp2.width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := i + i2;
      iy := i - i2;
      posx := ix * 18 - iy * 18 + pointx;
      posy := ix * 9 + iy * 9 + pointy;
      if (iy + MY >= 0) and (iy + MY < MmapopMap.Y) and (ix + MX >= 0) and (ix + MX < MmapopMap.X) then
        if (MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2 >= 0) then
        begin
          if MMapEditMode = RLEMode then
          begin
            if (MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2 >= 0) and (MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2 < MMApgrpnum) and
              (MMApgrp[MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2].size >= 8) then
              McoldrawRLE8(@MMApgrp[MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2].data[0], MMApgrp[MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2].size, Mmapopbmp2, posx, posy, true);
          end
          else
          begin
            ImzFile.SceneQuickDrawBuf(@MMapPNGBuf, MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2, posx, posy);
          end;
        end;
    end;
    for i2 := 0 downto -(Mmapopbmp2.width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := i + i2;
      iy := i - i2;
      posx := ix * 18 - iy * 18 + pointx;
      posy := ix * 9 + iy * 9 + pointy;
      if (iy + MY >= 0) and (iy + MY < MmapopMap.Y) and (ix + MX >= 0) and (ix + MX < MmapopMap.X) then
        if (MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2 >= 0) then
        begin
          if MMapEditMode = RLEMode then
          begin
            if (MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2 >= 0) and (MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2 < MMApgrpnum) and
              (MMApgrp[MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2].size >= 8) then
              McoldrawRLE8(@MMApgrp[MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2].data[0], MMApgrp[MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2].size, Mmapopbmp2, posx, posy, true);
          end
          else
          begin
            ImzFile.SceneQuickDrawBuf(@MMapPNGBuf, MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2, posx, posy);
          end;
        end;
    end;
    for i2 := 1 to (Mmapopbmp2.width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := i + i2 + 1;
      iy := i - i2;
      posx := ix * 18 - iy * 18 + pointx;
      posy := ix * 9 + iy * 9 + pointy;
      if (iy + MY >= 0) and (iy + MY < MmapopMap.Y) and (ix + MX >= 0) and (ix + MX < MmapopMap.X) then
        if (MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2 >= 0) then
        begin
          if MMapEditMode = RLEMode then
          begin
            if (MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2 >= 0) and (MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2 < MMApgrpnum) and
              (MMApgrp[MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2].size >= 8) then
              McoldrawRLE8(@MMApgrp[MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2].data[0], MMApgrp[MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2].size, Mmapopbmp2, posx, posy, true);
          end
          else
          begin
            ImzFile.SceneQuickDrawBuf(@MMapPNGBuf, MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2, posx, posy);
          end;
        end;
    end;
    for i2 := 0 downto -(Mmapopbmp2.width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := i + i2 + 1;
      iy := i - i2;
      posx := ix * 18 - iy * 18 + pointx;
      posy := ix * 9 + iy * 9 + pointy;
      if (iy + MY >= 0) and (iy + MY < MmapopMap.Y) and (ix + MX >= 0) and (ix + MX < MmapopMap.X) then
        if (MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2 >= 0) then
        begin
          if MMapEditMode = RLEMode then
          begin
            if (MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2 >= 0) and (MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2 < MMApgrpnum) and
              (MMApgrp[MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2].size >= 8) then
              McoldrawRLE8(@MMApgrp[MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2].data[0], MMApgrp[MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2].size, Mmapopbmp2, posx, posy, true);
          end
          else
          begin
            ImzFile.SceneQuickDrawBuf(@MMapPNGBuf, MmapopMap.maplayer[0].pic[iy + MY][ix + MX] div 2, posx, posy);
          end;
        end;
    end;
  end;
  // 表面层
  k := 0;
  for i := -(Mmapopbmp2.height div 36) to (Mmapopbmp2.height div 36 + 2) do
  begin
    for i2 := 1 to (Mmapopbmp2.width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := i + i2;
      iy := i - i2;
      posx := ix * 18 - iy * 18 + pointx;
      posy := ix * 9 + iy * 9 + pointy;
      if (iy + MY >= 0) and (iy + MY < MmapopMap.Y) and (ix + MX >= 0) and (ix + MX < MmapopMap.X) then
      begin
        if (MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2 > 0) then
        begin
          if MMapEditMode = RLEMode then
          begin
            if (MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2 >= 0) and (MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2 < MMApgrpnum) and
              (MMApgrp[MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2].size >= 8) then
              McoldrawRLE8(@MMApgrp[MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2].data[0], MMApgrp[MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2].size, Mmapopbmp2, posx, posy, true);
          end
          else
          begin
            ImzFile.SceneQuickDrawBuf(@MMapPNGBuf, MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2, posx, posy);
          end;
        end;
        // if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 > 0) then
        // McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);

        if (MmapopMap.maplayer[2].pic[iy + MY][ix + MX] > 0) then
        begin
          BuildingList[k].X := ix;
          BuildingList[k].Y := iy;
          if MMapEditMode = RLEMode then
          begin
            if (MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2 >= 0) and (MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2 < MMApgrpnum) and
              (MMApgrp[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].size >= 8) then
              Picwidth := (Psmallint(@MMApgrp[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].data[0]))^
            else
              Picwidth := 0;
          end
          else
          begin
            try
              if ImzFile.ImzFile.imzPNG[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].frame > 0 then
              begin
                Picwidth := ImzFile.ImzFile.imzPNG[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].PNG[0].width;
              end
              else
                Picwidth := 0;
            except
              Picwidth := 0;
            end;
          end;
          // 根据图片的宽度计算图的中点，为避免出现小数，实际是中点坐标的2倍
          CenterList[k].X := ix * 2 - (Picwidth + 35) div 36 + 1;
          CenterList[k].Y := iy * 2 - (Picwidth + 35) div 36 + 1;
          k := k + 1;
        end;
      end;
    end;

    for i2 := 0 downto -(Mmapopbmp2.width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := i + i2;
      iy := i - i2;
      posx := ix * 18 - iy * 18 + pointx;
      posy := ix * 9 + iy * 9 + pointy;
      if (iy + MY >= 0) and (iy + MY < MmapopMap.Y) and (ix + MX >= 0) and (ix + MX < MmapopMap.X) then
      begin
        if (MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2 > 0) then
        begin
          if MMapEditMode = RLEMode then
          begin
            if (MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2 >= 0) and (MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2 < MMApgrpnum) and
              (MMApgrp[MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2].size >= 8) then
              McoldrawRLE8(@MMApgrp[MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2].data[0], MMApgrp[MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2].size, Mmapopbmp2, posx, posy, true);
          end
          else
          begin
            ImzFile.SceneQuickDrawBuf(@MMapPNGBuf, MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2, posx, posy);
          end;
        end;
        // if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 > 0) then
        // McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);

        if (MmapopMap.maplayer[2].pic[iy + MY][ix + MX] > 0) then
        begin
          BuildingList[k].X := ix;
          BuildingList[k].Y := iy;
          if MMapEditMode = RLEMode then
          begin
            Picwidth := 0;
            if (MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2 >= 0) and (MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2 < MMApgrpnum) and
              (MMApgrp[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].size >= 8) then
              Picwidth := (Psmallint(@MMApgrp[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].data[0]))^;
          end
          else
          begin
            try
              if ImzFile.ImzFile.imzPNG[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].frame > 0 then
              begin
                Picwidth := ImzFile.ImzFile.imzPNG[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].PNG[0].width;
              end
              else
                Picwidth := 0;
            except
              Picwidth := 0;
            end;
          end;
          // 根据图片的宽度计算图的中点，为避免出现小数，实际是中点坐标的2倍
          CenterList[k].X := ix * 2 - (Picwidth + 35) div 36 + 1;
          CenterList[k].Y := iy * 2 - (Picwidth + 35) div 36 + 1;
          k := k + 1;
        end;
      end;
    end;

    for i2 := 1 to (Mmapopbmp2.width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := i + i2 + 1;
      iy := i - i2;
      posx := ix * 18 - iy * 18 + pointx;
      posy := ix * 9 + iy * 9 + pointy;
      if (iy + MY >= 0) and (iy + MY < MmapopMap.Y) and (ix + MX >= 0) and (ix + MX < MmapopMap.X) then
      begin
        if (MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2 > 0) then
        begin
          if MMapEditMode = RLEMode then
          begin
            if (MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2 >= 0) and (MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2 < MMApgrpnum) and
              (MMApgrp[MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2].size >= 8) then
              McoldrawRLE8(@MMApgrp[MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2].data[0], MMApgrp[MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2].size, Mmapopbmp2, posx, posy, true);
          end
          else
          begin
            ImzFile.SceneQuickDrawBuf(@MMapPNGBuf, MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2, posx, posy);
          end;
        end;
        // if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 > 0) then
        // McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);

        if (MmapopMap.maplayer[2].pic[iy + MY][ix + MX] > 0) then
        begin
          BuildingList[k].X := ix;
          BuildingList[k].Y := iy;
          if MMapEditMode = RLEMode then
          begin
            Picwidth := 0;
            if (MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2 >= 0) and (MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2 < MMApgrpnum) and
              (MMApgrp[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].size >= 8) then
              Picwidth := (Psmallint(@MMApgrp[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].data[0]))^;
          end
          else
          begin
            try
              if ImzFile.ImzFile.imzPNG[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].frame > 0 then
              begin
                Picwidth := ImzFile.ImzFile.imzPNG[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].PNG[0].width;
              end;
            except
              Picwidth := 0;
            end;
          end;
          // 根据图片的宽度计算图的中点，为避免出现小数，实际是中点坐标的2倍
          CenterList[k].X := ix * 2 - (Picwidth + 35) div 36 + 1;
          CenterList[k].Y := iy * 2 - (Picwidth + 35) div 36 + 1;
          k := k + 1;
        end;
      end;
    end;

    for i2 := 0 downto -(Mmapopbmp2.width div 72) - 1 do
    begin
      if needupdate then
        exit;
      ix := i + i2 + 1;
      iy := i - i2;
      posx := ix * 18 - iy * 18 + pointx;
      posy := ix * 9 + iy * 9 + pointy;
      if (iy + MY >= 0) and (iy + MY < MmapopMap.Y) and (ix + MX >= 0) and (ix + MX < MmapopMap.X) then
      begin
        if (MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2 > 0) then
        begin
          if MMapEditMode = RLEMode then
          begin
            if (MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2 >= 0) and (MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2 < MMApgrpnum) and
              (MMApgrp[MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2].size >= 8) then
              McoldrawRLE8(@MMApgrp[MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2].data[0], MMApgrp[MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2].size, Mmapopbmp2, posx, posy, true);
          end
          else
          begin
            ImzFile.SceneQuickDrawBuf(@MMapPNGBuf, MmapopMap.maplayer[1].pic[iy + MY][ix + MX] div 2, posx, posy);
          end;
        end;
        // if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 > 0) then
        // McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);

        if (MmapopMap.maplayer[2].pic[iy + MY][ix + MX] > 0) then
        begin
          BuildingList[k].X := ix;
          BuildingList[k].Y := iy;
          if MMapEditMode = RLEMode then
          begin
            Picwidth := 0;
            picheight := 0;
            if (MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2 >= 0) and (MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2 < MMApgrpnum) and
              (MMApgrp[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].size >= 8) then
            begin
              Picwidth := (Psmallint(@MMApgrp[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].data[0]))^;
              picheight := (Psmallint(@MMApgrp[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].data[2]))^;
            end;
          end
          else
          begin
            try
              if ImzFile.ImzFile.imzPNG[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].frame > 0 then
              begin
                Picwidth := ImzFile.ImzFile.imzPNG[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].PNG[0].width;
                picheight := ImzFile.ImzFile.imzPNG[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].PNG[0].height;
              end;
            except
              Picwidth := 0;
              picheight := 0;
            end;
          end;
          // 根据图片的宽度计算图的中点，为避免出现小数，实际是中点坐标的2倍
          CenterList[k].X := ix * 2 - (Picwidth + 35) div 36 + 1;
          CenterList[k].Y := iy * 2 - (picheight + 35) div 36 + 1;
          k := k + 1;
        end;
      end;
    end;
  end;
  // 建筑层
  for i := 0 to k - 1 do
    for i2 := 0 to k - 2 do
    begin
      if CenterList[i2].X + CenterList[i2].Y > CenterList[i2 + 1].X + CenterList[i2 + 1].Y then
      begin
        pos := BuildingList[i2];
        BuildingList[i2] := BuildingList[i2 + 1];
        BuildingList[i2 + 1] := pos;
        pos := CenterList[i2];
        CenterList[i2] := CenterList[i2 + 1];
        CenterList[i2 + 1] := pos;
      end;
    end;

  for i := 0 to k - 1 do
  begin
    ix := BuildingList[i].X;
    iy := BuildingList[i].Y;
    posx := ix * 18 - iy * 18 + pointx;
    posy := ix * 9 + iy * 9 + pointy;
    if MMapEditMode = RLEMode then
    begin
      if (MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2 >= 0) and (MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2 < MMApgrpnum) and
        (MMApgrp[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].size >= 8) then
        McoldrawRLE8(@MMApgrp[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].data[0], MMApgrp[MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2].size, Mmapopbmp2, posx, posy, true);
    end
    else
    begin
      ImzFile.SceneQuickDrawBuf(@MMapPNGBuf, MmapopMap.maplayer[2].pic[iy + MY][ix + MX] div 2, posx, posy);
    end;
  end;

  if (MMapEditMode = IMZMode) or (MMapEditMode = PNGMode) then
  begin
    Mmapopbmp2.Canvas.Lock;
    for i := 0 to MMapPNGBuf.height - 1 do
      copymemory(Mmapopbmp2.ScanLine[i], @MMapPNGBuf.data[i][0], MMapPNGBuf.width * 4);
    Mmapopbmp2.Canvas.UnLock;
  end;

  // if (Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2 > 0) then
  // McoldrawRLE8(@Mmapgrp[Mmapopmap.maplayer[2].pic[Iy + My][ix +Mx] div 2].data[0],Mmapgrp[Mmapopmap.maplayer[2].pic[Iy +My][ix + Mx] div 2].size,Mmapopbmp2, posx, posy, true);

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
    end; }
end;

procedure TForm13.drawsquare(X, Y: Integer);
var
  i: Integer;
  Pdata: Pbyte;
begin
  //
  if MMapEditMode = RLEMode then
  begin

    try
      Pdata := MMApbufbmp.ScanLine[Y];

      (Pdata + X)^ := 23;

      (Pdata + X - 1)^ := 23;

      for i := 1 to 8 do
      begin
        Pdata := MMApbufbmp.ScanLine[Y - i];
        (Pdata + (X - 2 * i))^ := 23;
        (Pdata + (X - 2 * i - 1))^ := 23;
        (Pdata + (X + 2 * i))^ := 23;
        (Pdata + (X + 2 * i + 1))^ := 23;
      end;
      Pdata := MMApbufbmp.ScanLine[Y - 9];
      (Pdata + (X - 18))^ := 23;
      (Pdata + (X + 17))^ := 23;

      for i := 1 to 8 do
      begin
        Pdata := MMApbufbmp.ScanLine[Y - 9 - i];
        (Pdata + (X - 19 + 2 * i))^ := 23;
        (Pdata + (X - 19 + 2 * i + 1))^ := 23;
        (Pdata + (X + 17 - 2 * i))^ := 23;
        (Pdata + (X + 17 - 2 * i + 1))^ := 23;

      end;
      Pdata := MMApbufbmp.ScanLine[Y - 17];
      (Pdata + X)^ := 23;
      (Pdata + X - 1)^ := 23;

    except
      exit;
    end;
  end
  else
  begin
    try
      Pdata := MMapbufbmppng.ScanLine[Y];
      Pcardinal(Pdata + X * 4)^ := $FF0000;

      Pcardinal(Pdata + X * 4 - 1 * 4)^ := $FF0000;

      for i := 1 to 8 do
      begin
        Pdata := MMapbufbmppng.ScanLine[Y - i];
        Pcardinal(Pdata + (X - 2 * i) * 4)^ := $FF0000;
        Pcardinal(Pdata + (X - 2 * i - 1) * 4)^ := $FF0000;
        Pcardinal(Pdata + (X + 2 * i) * 4)^ := $FF0000;
        Pcardinal(Pdata + (X + 2 * i + 1) * 4)^ := $FF0000;
      end;
      Pdata := MMapbufbmppng.ScanLine[Y - 9];
      Pcardinal(Pdata + (X - 18) * 4)^ := $FF0000;
      Pcardinal(Pdata + (X + 17) * 4)^ := $FF0000;

      for i := 1 to 8 do
      begin
        Pdata := MMapbufbmppng.ScanLine[Y - 9 - i];
        Pcardinal(Pdata + (X - 19 + 2 * i) * 4)^ := $FF0000;
        Pcardinal(Pdata + (X - 19 + 2 * i + 1) * 4)^ := $FF0000;
        Pcardinal(Pdata + (X + 17 - 2 * i) * 4)^ := $FF0000;
        Pcardinal(Pdata + (X + 17 - 2 * i + 1) * 4)^ := $FF0000;

      end;
      Pdata := MMapbufbmppng.ScanLine[Y - 17];
      Pcardinal(Pdata + X * 4)^ := $FF0000;
      Pcardinal(Pdata + X * 4 - 1 * 4)^ := $FF0000;
    except
      exit;
    end;
  end;
end;

end.
