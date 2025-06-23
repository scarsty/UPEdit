unit WarMapEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, head, ExtCtrls, StdCtrls,math, ComCtrls, IMZObject, inifiles, imagez;

type
  TForm11 = class(TForm)
    Panel1: TPanel;
    ComboBox1: TComboBox;
    Label1: TLabel;
    ComboBox2: TComboBox;
    StatusBar1: TStatusBar;
    Label2: TLabel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Label3: TLabel;
    Label4: TLabel;
    Button4: TButton;
    Timer1: TTimer;
    Label5: TLabel;
    Label6: TLabel;
    Panel2: TPanel;
    Image2: TImage;
    Panel3: TPanel;
    Image3: TImage;
    Panel4: TPanel;
    ScrollBox1: TScrollBox;
    Image1: TImage;
    Panel5: TPanel;
    CheckBox1: TCheckBox;
    RadioGroup1: TRadioGroup;
    Button5: TButton;
    Button6: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Image1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure Image1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Select(Sender: TObject);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ComboBox2Select(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure drawsquare(x,y: integer);
    procedure Button4Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure UpdatewarSmallImg;
    procedure CheckBox1Click(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure ReadWModeIni;
    procedure WriteWModeIni;
    procedure SetEditMode(EMode: TMapEditMode);
    procedure Button6Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    var
      ImzFile: TimzFile;
      WarEditMode: TMapEditMode;
      WarmapInitial: Boolean;

  end;

var
  waropbmp: Tbitmap;
  warbufbmp: Tbitmap;
  wargrp: array of Tgrppic;
  nowwargrpnum: integer;
  wargrpnum: integer;
  warlayer: integer;
  warmapfile: Tmapstruct;
  warcopymap: Tmap;
  warcopymapmode:integer;
  wartempx,wartempy: integer;
  warcenterx,warcentery: integer;
  warsmallbmp: Tbitmap;
  warstill: integer;
  warstillx,warstilly: integer;
  mousex,mousey: integer;
  needupdate: boolean;

  warPNGBuf: TScenePNGBuf;
  waropbmppng: Tbitmap;
  warbufbmppng: Tbitmap;
  //sceneeventnum: integer;

function readwardef(idx,grp:string; opmapstruct:Pmapstruct): integer;
function readWarmapgrp: integer;
procedure displaywarmap(waropMap: Pmap; waropbmp2:PNTbitmap; EMode: TMapEditMode; ImzFile: PImzFile);
procedure McoldrawRLE8(Ppic: Pbyte; len: integer; PBMP: PntBitMap; dx, dy: integer; canmove: boolean);

implementation

uses
   main,grplist;

{$R *.dfm}

procedure TForm11.SetEditMode(EMode: TMapEditMode);
begin
  //
  WarMapInitial := false;
  if EMode = RLEMode then
  begin
    if not (readWarmapgrp = 1) then
    begin
      showmessage('读取IDX或GRP文件错误！');
      WarMapInitial := false;
      RadioGroup1.ItemIndex := integer(WarEditMode);
      exit;
    end;
    WarPNGBuf.width := 0;
    WarPNGBuf.height := 0;
    setlength(WarPNGBuf.data, WarPNGBuf.height, WarPNGBuf.width * 4);

    WarMapInitial := true;
    //Warlock := false;
    needupdate := true;
  end
  else if EMode = IMZMode then
  begin
    if not imzFile.ReadImzFromFile(gamepath + WMAPIMZ) then
    begin
      showmessage('读取IMZ文件失败！');
      WarMapInitial := false;
      RadioGroup1.ItemIndex := integer(WarEditMode);
      exit;
    end;
    ImzFile.ReadAllPNG;
    WarPNGBuf.width := image1.width;
    WarPNGBuf.height := image1.height;
    setlength(warPNGBuf.data, warPNGBuf.height, warPNGBuf.width * 4);
    WarMapInitial := true;
    //scenelock := false;
    needupdate := true;
  end
  else if EMode = PNGMode then
  begin
    if not imzFile.ReadImzFromFolder(gamepath + WMAPPNGpath) then
    begin
      showmessage('读取IMZ文件夹失败！');
      warMapInitial := false;
      RadioGroup1.ItemIndex := integer(warEditMode);
      exit;
    end;
    ImzFile.ReadAllPNG;
    warPNGBuf.width := image1.width;
    warPNGBuf.height := image1.height;
    setlength(warPNGBuf.data, warPNGBuf.height, warPNGBuf.width * 4);
    warMapInitial := true;
    //scenelock := false;
    needupdate := true;
  end;
  WarEditMode := EMode;
  WriteWModeIni;
end;

procedure TForm11.ReadWModeIni;
var
  filename: string;
  ini: Tinifile;
begin
  //
  Filename := StartPath + iniFilename;
  try
    ini := TIniFile.Create(filename);
    WarEditMode := TMapEditMode(ini.ReadInteger('File','WarMode', integer(WarEditMode)));
  finally
    ini.Free;
  end;
end;

procedure TForm11.WriteWModeIni;
var
  filename: string;
  ini: Tinifile;
begin
  //
  Filename := StartPath + iniFilename;
  try
    ini := TIniFile.Create(filename);
    ini.WriteInteger('File','WarMode', integer(WarEditMode));
  finally
    ini.Free;
  end;
end;

procedure TForm11.Button1Click(Sender: TObject);
var
  Form3: TForm3;
  FormImz: TImzForm;
  I: integer;
begin

  if WarEditMode = RLEMode then
  begin
  if CForm3 then
  begin
    CFOrm3 := false;
    Form3 := TForm3.Create(application);
    Form3.WindowState := wsmaximized;
    MdiChildHandle[3] := Form3.Handle;
    Form3.WindowState := wsnormal;
    Form3.edit1.Text := gamepath + WarMapIDX;
    Form3.edit2.Text := gamepath + WarMapgrp;
    Form3.Button4.Click;
  end
  else
  begin
    for I := 0 to Mainform.MDIChildCount - 1 do
      if Mainform.MDIChildren[I].Handle = MdiChildHandle[3] then
      begin
        TForm3(Mainform.MDIChildren[I]).ComboBox1.ItemIndex := -1;
        TForm3(Mainform.MDIChildren[I]).edit1.Text := gamepath + WarMapIDX;
        TForm3(Mainform.MDIChildren[I]).edit2.Text := gamepath + WarMapgrp;
        TForm3(Mainform.MDIChildren[I]).Button4.Click;
        self.WindowState := wsnormal;
        Mainform.MDIChildren[I].BringToFront;
      end;
  end;
  end
  else if (WarEditMode = PNGMode) or (WarEditMode = IMZMode) then
  begin
  if CFormImz then
  begin
    CFormImz := false;
    FormImz := TImzForm.Create(application);
    MdiChildHandle[13] := FormImz.Handle;
    FormImz.WindowState := wsnormal;
    if WarEditMode = IMZMode then
    begin
      FormImz.Edit2.Text := gamepath + WmapIMZ;
      //FormImz.IMZeditMode := TIMZEditMode(0);
      FormIMZ.SetEditMode(TIMZEditMode(0));
    end
    else
    begin
      FormImz.Edit2.Text := gamepath + WmapPNGPATH;
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
        if WarEditMode = IMZMode then
        begin
          TImzForm(Mainform.MDIChildren[I]).Edit2.Text := gamepath + WmapIMZ;
          //TImzForm(Mainform.MDIChildren[I]).IMZeditMode := TIMZEditMode(0);
          TImzForm(Mainform.MDIChildren[I]).SetEditMode(TIMZEditMode(0));
        end
        else
        begin
          TImzForm(Mainform.MDIChildren[I]).Edit2.Text := gamepath + WmapPNGPATH;
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

procedure TForm11.Button2Click(Sender: TObject);
var
  I, temp, ix, iy: integer;
begin
  try
  inc(warmapfile.num);
  setlength(warmapfile.map, warmapfile.num);
  warmapfile.map[warmapfile.num - 1].layernum := warmapfile.map[combobox1.ItemIndex].layernum;
  warmapfile.map[warmapfile.num - 1].x := warmapfile.map[combobox1.ItemIndex].x;
  warmapfile.map[warmapfile.num - 1].y := warmapfile.map[combobox1.ItemIndex].y;
  setlength(warmapfile.map[warmapfile.num - 1].maplayer, warmapfile.map[warmapfile.num - 1].layernum);
  for I := 0 to warmapfile.map[warmapfile.num - 1].layernum - 1 do
  begin
    setlength(warmapfile.map[warmapfile.num - 1].maplayer[I].pic, warmapfile.map[warmapfile.num - 1].y,warmapfile.map[warmapfile.num - 1].x);
    for iy := 0 to warmapfile.map[warmapfile.num - 1].y - 1 do
      for ix := 0 to warmapfile.map[warmapfile.num - 1].x - 1 do
        warmapfile.map[warmapfile.num - 1].maplayer[I].pic[iy][ix] := warmapfile.map[combobox1.ItemIndex].maplayer[I].pic[iy][ix]
  end;
    combobox1.Items.Add(inttostr(warmapfile.num - 1));
    showmessage('添加贴图成功！已复制当前场景的到新场景！');
  except
    showmessage('添加失败');
  end;
end;

procedure TForm11.Button3Click(Sender: TObject);
var
  temp: integer;
begin
  try
  temp := combobox1.Items.Count;
  if combobox1.ItemHeight = warmapfile.num - 1 then
  begin
    combobox1.ItemIndex := warmapfile.num - 2;
    combobox1.OnSelect(sender);
  end;
  dec(warmapfile.num);
  combobox1.Items.Delete(temp - 1);
  setlength(warmapfile.map, warmapfile.num);
  showmessage('删除成功！');
  except
    showmessage('删除失败！');
  end;
end;

procedure TForm11.Button4Click(Sender: TObject);
var
  I,len,ix,iy,i2: integer;
  idx,grp: integer;
begin
try
  len := 0;
  idx := filecreate(gamepath + warmapdefidx);
  grp := filecreate(gamepath + warmapdefgrp);
  for I := 0 to warmapfile.num - 1 do
  begin
    for i2 := 0 to warmapfile.map[I].layernum - 1 do
      for Iy := 0 to warmapfile.map[I].y - 1 do
        filewrite(grp, warmapfile.map[I].maplayer[I2].pic[iy][0],2 *warmapfile.map[I].x);
    inc(len, warmapfile.map[I].layernum * warmapfile.map[I].x * warmapfile.map[I].y * 2);
    filewrite(idx,len,4);
  end;
  fileclose(idx);
  fileclose(grp);
  showmessage('保存成功！');
except
  showmessage('保存失败！');
end;
end;

procedure TForm11.Button5Click(Sender: TObject);
var
  FH: integer;
  I,I1,I2: integer;
begin
  opendialog1.Filter := 'War Module files (*.wmd)|*.wmd|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    if fileexists(opendialog1.FileName) then
    begin
      try
        combobox2.ItemIndex := 3;
        warlayer := 2;
        FH := fileopen(opendialog1.FileName, fmopenread);
        warcopymap.layernum := warmapfile.map[combobox2.ItemIndex].layernum;
        setlength(warcopymap.maplayer, warcopymap.layernum);
        fileseek(FH,0,0);
        fileread(FH, warcopymap.x, 4);
        fileread(FH, warcopymap.y, 4);
        for I := 0 to warcopymap.layernum - 1 do
        begin
          setlength(warcopymap.maplayer[I].pic,warcopymap.y,warcopymap.x);
          for I1 := 0 to warcopymap.y - 1 do
          begin
            fileread(FH, warcopymap.maplayer[I].pic[I1][0], warcopymap.x * 2);
          end;
        end;
        warcopymapmode := 1;
        nowwargrpnum := -1;
      finally
        fileclose(FH);
      end;
    end;
  end;
  warstill := 0;
  warstillx := -1;
end;

procedure TForm11.Button6Click(Sender: TObject);
var
  filename: string;
  I, I1, I2, ix, iy,FH,posx,posy: integer;
  wartempbmp: Tbitmap;
   PalSize:longint;
    pLogPalle:TMaxLogPalette;
    PalleEntry:TPaletteEntry;
    Palle:HPalette;
begin
  if warlayer <> 2 then
  begin
    showmessage('请选择操作图层为"全部"，然后用鼠标括出一块区域');
  end
  else
  begin
    savedialog1.Filter := 'War Module files (*.wmd)|*.wmd';
    if savedialog1.Execute then
    begin
      filename := SaveDialog1.filename;
      if not SameText(ExtractFileExt(SaveDialog1.filename), '.wmd') then
        filename := filename + '.wmd';
      //scenelock := true;
      try
        FH := filecreate(filename);
        fileseek(FH,0,0);
        filewrite(FH, warcopymap.x, 4);
        filewrite(FH, warcopymap.y, 4);
        for I := 0 to warcopymap.layernum - 1 do
        begin
          for I1 := 0 to warcopymap.y - 1 do
          begin
            filewrite(FH, warcopymap.maplayer[I].pic[I1][0], 2 * warcopymap.x);
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

        if WarEditMode = RLEMode then
        begin
          Wartempbmp.PixelFormat := pf8bit;
          Wartempbmp.Palette := Palle;
        end
        else
          wartempbmp.PixelFormat := pf32bit;

        wartempbmp.Width := (warcopymap.x + warcopymap.y) * 18 + 150;
        wartempbmp.height := (warcopymap.x + warcopymap.y) * 9 + 150;
        wartempbmp.Canvas.Brush.Color := clblack;
        wartempbmp.Canvas.FillRect(wartempbmp.Canvas.ClipRect);

        for I := 0 to warcopymap.layernum - 1 do
          for Ix := warcopymap.x - 1 downto 0 do
             for iy := warcopymap.y - 1 downto 0 do
               if (warcopymap.maplayer[I].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] > 0) or ((warcopymap.maplayer[I].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] = 0) and (I = 0)) then
               begin
                 posx := (warcopymap.x - ix) * 18 - (warcopymap.y - iy) * 18  + warcopymap.y * 18 + 75;
                 posy := (warcopymap.x - ix) * 9 + (warcopymap.y - Iy) * 9 + 110;

                 //McoldrawRLE8(@scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].data[0],scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].size,@scenetempbmp, posx,posy, true);
                 case WarEditMode of
                   RLEMode:
                     begin
                       if (Warcopymap.maplayer[I].pic[Warcopymap.y - iy - 1][Warcopymap.x - ix - 1] div 2 >= 0)
                       and (Warcopymap.maplayer[I].pic[Warcopymap.y - iy - 1][Warcopymap.x - ix - 1] div 2 < Wargrpnum)
                       and (Wargrp[Warcopymap.maplayer[I].pic[Warcopymap.y - iy - 1][Warcopymap.x - ix - 1] div 2].size >= 8)
                       then
                         McoldrawRLE8(@Wargrp[Warcopymap.maplayer[I].pic[Warcopymap.y - iy - 1][Warcopymap.x - ix - 1] div 2].data[0],Wargrp[Warcopymap.maplayer[I].pic[Warcopymap.y - iy - 1][Warcopymap.x - ix - 1] div 2].size, @Wartempbmp, posx,posy, true);
                     end;
                   IMZMode, PNGMode:
                     begin
                       //imzFile.DrawImztocanvasEx(image5.Canvas, @imzFIle.imzFile, tempint, 0, 0, 0);
                       ImzFile.SceneQuickDraw(@Wartempbmp, Warcopymap.maplayer[I].pic[Warcopymap.y - iy - 1][Warcopymap.x - ix - 1] div 2, posx, posy);
                     end;
                 end;
               end;

        Wartempbmp.SaveToFile(filename + '.bmp');
      finally
        Wartempbmp.Free;
      end;

    end;
  end;
  warstill := 0;
  warstillx := -1;
end;

procedure TForm11.CheckBox1Click(Sender: TObject);
begin
  //
  if checkbox1.Checked then
  begin
    panel5.Visible := true;
    needupdate := true;
  end
  else
  begin
    panel5.Visible := false;
  end;
end;

procedure TForm11.ComboBox1Select(Sender: TObject);
begin
  if not WarmapInitial then
    exit;
  if combobox1.ItemIndex >= 0 then
  begin
    needupdate := false;
    displaywarmap(@warmapfile.map[combobox1.ItemIndex], @waropbmp, Wareditmode, @ImzFile);
    //waropbmp.PixelFormat := pf24bit;
    //warbufbmp.PixelFormat := pf24bit;
    case WarEditMode of
        RLEMode:
          begin
            warbufbmp.Canvas.CopyRect(warbufbmp.Canvas.ClipRect, waropbmp.Canvas,waropbmp.Canvas.ClipRect);
            image1.Canvas.CopyRect(image1.ClientRect,waropbmp.Canvas,waropbmp.Canvas.ClipRect);
          end;
        IMZMode, PNGMode:
          begin
            warbufbmppng.Canvas.CopyRect(warbufbmppng.Canvas.ClipRect, waropbmppng.Canvas,waropbmppng.Canvas.ClipRect);
            image1.Canvas.CopyRect(image1.ClientRect,waropbmppng.Canvas,waropbmppng.Canvas.ClipRect);
          end;
    end;
  end;
end;

procedure TForm11.ComboBox2Select(Sender: TObject);
var
  I: integer;
begin
  if not WarmapInitial then
    exit;
  warlayer := combobox2.ItemIndex - 1;
  if warlayer = 2 then
    if warcopymapmode = 0 then
    begin
      warcopymapmode := 1;
      nowwargrpnum := -1;
      if (warmapfile.num > combobox1.ItemIndex) and (combobox1.ItemIndex >= 1) then
      begin
        warcopymap.layernum := warmapfile.map[combobox1.ItemIndex].layernum;
      end
      else
        warcopymap.layernum := 2;
      warcopymap.x := 1;
      warcopymap.y := 1;
      setlength(warcopymap.maplayer, warcopymap.layernum);

      for I := 0 to warcopymap.layernum - 1 do
      begin
        setlength(warcopymap.maplayer[I].pic, warcopymap.y, warcopymap.x);
        warcopymap.maplayer[I].pic[0][0] := 0;
      end;

    end;

end;

procedure TForm11.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  waropbmp.Free;
  warbufbmp.Free;
  warsmallbmp.Free;
  warbufbmppng.Free;
  waropbmppng.Free;
  setlength(wargrp,0);
  setlength(warmapfile.map,0);
  setlength(warcopymap.maplayer,0);

  setlength(WarPNGBuf.data, 0, 0);
  ImzFile.ReleaseAllPNG;
  ImzFile.Free;
  CForm11 := true;
  action := cafree;
end;

procedure TForm11.FormCreate(Sender: TObject);
var
  I: integer;
   PalSize:longint;
    pLogPalle:TMaxLogPalette;
    PalleEntry:TPaletteEntry;
    Palle:HPalette;
begin
   ImzFile := TimzFile.Create;
   WarEditMode := RLEMode;
   WarmapInitial := false;
   try
     PalSize:=sizeof(TLogPalette) + 256 * sizeof(TPaletteEntry);
     //pLogPalle:=MemAlloc(PalSize);
     //getmem(Plogpalle, palsize);
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
    showmessage('调色板设置失败！');
  end;
  warlayer := -1;
  combobox2.ItemIndex := 0;
  warstill := 0;
  needupdate := false;
  statusbar1.Canvas.Brush.Style := bsclear;
  statusbar1.Canvas.Font.Size := 12;
  statusbar1.Canvas.Font.Color := clblack;

  warcopymapmode := 0;
  nowwargrpnum := -1;

  waropbmppng := Tbitmap.Create;
  waropbmppng.Width := image1.Width;
  waropbmppng.Height := image1.Height;
  waropbmppng.Canvas.Font.Size := 8;
  waropbmppng.Canvas.Font.Color := clyellow;
  waropbmppng.PixelFormat := pf32bit;

  warbufbmppng := Tbitmap.Create;
  warbufbmppng.Width := image1.Width;
  warbufbmppng.Height := image1.Height;
  warbufbmppng.Canvas.Font.Size := 8;
  warbufbmppng.Canvas.Font.Color := clyellow;
  warbufbmppng.PixelFormat := pf32bit;

  warsmallbmp := Tbitmap.Create;
  warsmallbmp.Canvas.Brush.Color := clwhite;//$707030;
  waropbmp := Tbitmap.Create;
  warbufbmp := Tbitmap.Create;
  waropbmp.Width := image1.Width;
  waropbmp.Height := image1.Height;
  warbufbmp.Width := image1.Width;
  warbufbmp.Height := image1.Height;
  warsmallbmp.PixelFormat := pf8bit;
  waropbmp.PixelFormat := pf8bit;
  warbufbmp.PixelFormat := pf8bit;
  warsmallbmp.Palette := palle;
  warsmallbmp.Height := 500;
  warsmallbmp.Width := 500;
  waropbmp.Palette := palle;
  warbufbmp.Palette := palle;
  warcenterx := image1.Width div 2;
  warcentery := image1.Height div 2;

  try
  if not ({(readWarmapgrp = 1) and }(readwardef(gamepath + warmapdefidx,gamepath + warmapdefgrp,@warmapfile) = 1)) then
  begin
    showmessage('战斗地图编辑器打开失败！原因可能是贴图或地图文件错误或不存在！请检查游戏路径设置，以及ini文件设置！');
    self.Close;
    exit;
  end;
  combobox1.Clear;
  for I := 0 to warmapfile.num - 1 do
    combobox1.Items.Add(inttostr(I));
  combobox1.ItemIndex := 0;
  except
    showmessage('战斗地图编辑器打开失败！原因可能是战斗数据文件错误或不存在！请检查游戏路径设置，以及ini文件设置！');
    self.Close;
    exit;
  end;
  try
  ReadWModeIni;
  Radiogroup1.ItemIndex := integer(WarEditMode);
  self.SetEditMode(WarEditMode);

  if WarEditMode = RLEMode then
  begin
    displaywarmap(@warmapfile.map[0], @waropbmp, Wareditmode, @ImzFile);
    warbufbmp.Canvas.CopyRect(warbufbmp.Canvas.ClipRect, waropbmp.Canvas,waropbmp.Canvas.ClipRect);
    image1.Canvas.CopyRect(image1.ClientRect,waropbmp.Canvas,waropbmp.Canvas.ClipRect);
  end
  else
  begin
    displaywarmap(@warmapfile.map[0], @waropbmpPng, Wareditmode, @ImzFile);
    warbufbmpPng.Canvas.CopyRect(warbufbmpPng.Canvas.ClipRect, waropbmpPng.Canvas,waropbmp.Canvas.ClipRect);
    image1.Canvas.CopyRect(image1.ClientRect, waropbmpPng.Canvas, waropbmpPng.Canvas.ClipRect);
  end;


  wartempx := -1;
  wartempy := -1;
  timer1.Enabled := true;
  except
    showmessage('战斗地图编辑器打开失败！原因可能是战斗地图文件错误！');
    self.Close;
    exit;
  end;
  WarmapInitial := true;
end;

procedure TForm11.Image1DragDrop(Sender, Source: TObject; X, Y: Integer);
begin
  if not WarmapInitial then
    exit;
  if (warlayer = 2) then
    exit;
  if IMZDrag then
  begin
    //showmessage('imzdrag');
    if WarEditMode <> RLEMode then
      nowwargrpnum := imzdragint;
  end
  else
  begin
    //showmessage('grpdrag');
    if warEditMode = RLEMode then
      nowwargrpnum := movelock;
  end;

  warcopymapmode := 0;
  //拖拽放下后，贴图编号同步
  self.BringToFront;
end;

procedure TForm11.Image1DragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  //
end;

procedure TForm11.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  ix, iy, I: integer;
begin
  if not WarmapInitial then
    exit;
  if button = mbright then
  begin
  if (wartempx >= 0) and (wartempx < warmapfile.map[combobox1.ItemIndex].x) and (wartempy >=0) and (wartempy < warmapfile.map[combobox1.ItemIndex].y) then
  begin
    if (warlayer >= 0) and (nowwargrpnum >= 0) and (warlayer <> 2) then
    begin
      warmapfile.map[combobox1.ItemIndex].maplayer[warlayer].pic[wartempy][wartempx] := 2 * nowwargrpnum;
      displaywarmap(@warmapfile.map[combobox1.ItemIndex], @waropbmp, Wareditmode, @ImzFile);
      //waropbmp.PixelFormat := pf24bit;
      //warbufbmp.PixelFormat := pf24bit;
      case WarEditMode of
        RLEMode:
          begin
            warbufbmp.Canvas.CopyRect(warbufbmp.Canvas.ClipRect, waropbmp.Canvas,waropbmp.Canvas.ClipRect);
            image1.Canvas.CopyRect(image1.ClientRect,waropbmp.Canvas,waropbmp.Canvas.ClipRect);
          end;
        IMZMode, PNGMode:
          begin
            warbufbmppng.Canvas.CopyRect(warbufbmppng.Canvas.ClipRect, waropbmppng.Canvas, waropbmppng.Canvas.ClipRect);
            image1.Canvas.CopyRect(image1.ClientRect,waropbmppng.Canvas,waropbmppng.Canvas.ClipRect);
          end;
      end;

      UpdatewarSmallImg;
    end
    else if (warlayer >= 0) and (warcopymapmode = 1) and (warlayer <> 2) then
    begin
      for Ix := 0 to warcopymap.x - 1 do
        for iy := 0 to warcopymap.y - 1 do
          if (wartempx - ix >= 0) and (wartempx-ix < warmapfile.map[combobox1.ItemIndex].x) and (wartempy-iy >=0) and (-iy + wartempy < warmapfile.map[combobox1.ItemIndex].y) then
            warmapfile.map[combobox1.ItemIndex].maplayer[warlayer].pic[wartempy - iy][wartempx - ix] := warcopymap.maplayer[warlayer].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1];
      displaywarmap(@warmapfile.map[combobox1.ItemIndex], @waropbmp, Wareditmode, @ImzFile);
      //waropbmp.PixelFormat := pf24bit;
      //warbufbmp.PixelFormat := pf24bit;
      case WarEditMode of
        RLEMode:
          begin
            warbufbmp.Canvas.CopyRect(warbufbmp.Canvas.ClipRect, waropbmp.Canvas,waropbmp.Canvas.ClipRect);
            image1.Canvas.CopyRect(image1.ClientRect,waropbmp.Canvas,waropbmp.Canvas.ClipRect);
          end;
        IMZMode, PNGMode:
          begin
            warbufbmppng.Canvas.CopyRect(warbufbmppng.Canvas.ClipRect, waropbmppng.Canvas,waropbmppng.Canvas.ClipRect);
            image1.Canvas.CopyRect(image1.ClientRect,waropbmppng.Canvas,waropbmppng.Canvas.ClipRect);
          end;
      end;
      UpdatewarSmallImg;
    end
    else if (warlayer = 2) and (warcopymapmode = 1) then
    begin
      for Ix := 0 to warcopymap.x - 1 do
        for iy := 0 to warcopymap.y - 1 do
          for I := 0 to warmapfile.map[combobox1.ItemIndex].layernum - 1 do
            if (wartempx - ix >= 0) and (wartempx-ix < warmapfile.map[combobox1.ItemIndex].x) and (wartempy-iy >=0) and (-iy + wartempy < warmapfile.map[combobox1.ItemIndex].y) then
              warmapfile.map[combobox1.ItemIndex].maplayer[I].pic[wartempy - iy][wartempx - ix] := warcopymap.maplayer[I].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1];
      displaywarmap(@warmapfile.map[combobox1.ItemIndex], @waropbmp, Wareditmode, @ImzFile);
      //waropbmp.PixelFormat := pf24bit;
      //warbufbmp.PixelFormat := pf24bit;
      case WarEditMode of
        RLEMode:
          begin
            warbufbmp.Canvas.CopyRect(warbufbmp.Canvas.ClipRect, waropbmp.Canvas,waropbmp.Canvas.ClipRect);
            image1.Canvas.CopyRect(image1.ClientRect,waropbmp.Canvas,waropbmp.Canvas.ClipRect);
          end;
        IMZMode, PNGMode:
          begin
            warbufbmppng.Canvas.CopyRect(warbufbmppng.Canvas.ClipRect, waropbmppng.Canvas,waropbmppng.Canvas.ClipRect);
            image1.Canvas.CopyRect(image1.ClientRect,waropbmppng.Canvas,waropbmppng.Canvas.ClipRect);
          end;
      end;
      UpdatewarSmallImg;
    end;
  end;
  end
  else if (button = mbleft) and (wartempx >= 0) and (wartempx < warmapfile.map[combobox1.ItemIndex].x) and (wartempy >=0) and (wartempy < warmapfile.map[combobox1.ItemIndex].y) then
  begin
    warstill := 1;
    warstillx := wartempx;
    warstilly := wartempy;
    needupdate := true;
  end;
end;

procedure TForm11.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
 //
 mousex := x;
 mousey := y;
end;

procedure TForm11.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  lx,ly,sx,sy, temp,I,Ix,Iy: integer;
begin
  if not WarmapInitial then
    exit;
  if button = mbleft then
  begin
    warstill := 0;
    warbufbmp.Canvas.CopyRect(warbufbmp.Canvas.ClipRect, waropbmp.Canvas,waropbmp.Canvas.ClipRect);
    if (warlayer <> 2) and (warstillx = wartempx) and (warstilly = wartempy) then
    begin
      if (wartempx >= 0) and (wartempx < warmapfile.map[combobox1.ItemIndex].x) and (wartempy >=0) and (wartempy < warmapfile.map[combobox1.ItemIndex].y) then
      begin
        if (warlayer >= 0) then
        begin
          nowwargrpnum := warmapfile.map[combobox1.ItemIndex].maplayer[warlayer].pic[wartempy][wartempx] div 2;
          warcopymapmode := 0;
        end;
      end;
    end
    else
    begin
      if warlayer >= 0 then
      begin
         lx := wartempx;
         ly := wartempy;
      if (wartempx >= warmapfile.map[combobox1.ItemIndex].x)  then
        lx := warmapfile.map[combobox1.ItemIndex].x - 1
      else if (wartempx < 0) then
        lx := 0;
      if (wartempy >= warmapfile.map[combobox1.ItemIndex].y)  then
        ly := warmapfile.map[combobox1.ItemIndex].y - 1
      else if (wartempy < 0) then
        ly := 0;
      if (warstillx >= 0) and (warstillx < warmapfile.map[combobox1.ItemIndex].x) and (warstilly >=0) and (warstilly < warmapfile.map[combobox1.ItemIndex].y) then
      begin
        if ((lx <> warstillx) or (ly <> warstilly)) or (warlayer = 2) then
        begin
          sx := warstillx;
          sy := warstilly;
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

          warcopymapmode := 1;
          nowwargrpnum := -1;
          warcopymap.layernum := warmapfile.map[combobox1.ItemIndex].layernum;
          warcopymap.x := lx - sx + 1;
          warcopymap.y := ly - sy + 1;
          setlength(warcopymap.maplayer, warcopymap.layernum);

          for I := 0 to warcopymap.layernum - 1 do
          begin
            setlength(warcopymap.maplayer[I].pic,warcopymap.y,warcopymap.x);
            for ix := sx to lx do
              for iy := sy to ly do
              begin
                warcopymap.maplayer[I].pic[iy - sy][ix- sx] := warmapfile.map[combobox1.ItemIndex].maplayer[I].pic[iy][ix];
              end;

          end;

        end;
        end;
      end;
    end;
  end;
end;

procedure TForm11.RadioGroup1Click(Sender: TObject);
begin
  //
  setEditMode(TMapEditMode(RadioGroup1.ItemIndex));
end;

procedure TForm11.UpdatewarSmallImg;
begin
    image2.Canvas.Brush.Color :=CLWHITE;//$606060;
    image2.Canvas.FillRect(image2.Canvas.ClipRect);
    image3.Canvas.Brush.Color := CLWHITE;//$606060;
    image3.Canvas.FillRect(image3.Canvas.ClipRect);
    if (wartempx >= 0) and (wartempx < warmapfile.map[combobox1.ItemIndex].x) and (wartempy >=0) and (wartempy < warmapfile.map[combobox1.ItemIndex].y) then
    begin
      warsmallbmp.Canvas.Brush.Color := CLWHITE;//$606060;
      warsmallbmp.Canvas.FillRect(warsmallbmp.Canvas.ClipRect);
      if warmapfile.map[combobox1.ItemIndex].maplayer[0].pic[wartempy][wartempx] >= 0 then
      begin
        //warsmallbmp.Width := image2.Width;
       // warsmallbmp.Height := image2.Height;
        case WarEditMode of
          RLEMode:
            begin
              if (warmapfile.map[combobox1.ItemIndex].maplayer[0].pic[wartempy][wartempx] div 2 >= 0)
              and (warmapfile.map[combobox1.ItemIndex].maplayer[0].pic[wartempy][wartempx] div 2 < wargrpnum)
              and (wargrp[warmapfile.map[combobox1.ItemIndex].maplayer[0].pic[wartempy][wartempx] div 2].size >= 8) then
              begin
                McoldrawRLE8(@wargrp[warmapfile.map[combobox1.ItemIndex].maplayer[0].pic[wartempy][wartempx] div 2].data[0],wargrp[warmapfile.map[combobox1.ItemIndex].maplayer[0].pic[wartempy][wartempx] div 2].size,@warsmallbmp, 0,0, false);
                image2.Canvas.CopyRect(image2.Canvas.ClipRect,warsmallbmp.Canvas,image2.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              imzFile.DrawImztocanvas(image2.Canvas, @imzFIle.imzFile, warmapfile.map[combobox1.ItemIndex].maplayer[0].pic[wartempy][wartempx] div 2, 0, 0, 0);
            end;
        end;
      end;
      warsmallbmp.Canvas.Brush.Color := CLWHITE;//$606060;
      warsmallbmp.Canvas.FillRect(warsmallbmp.Canvas.ClipRect);
      if warmapfile.map[combobox1.ItemIndex].maplayer[1].pic[wartempy][wartempx] > 0 then
      begin
        //warsmallbmp.Width := image3.Width;
       // warsmallbmp.Height := image3.Height;
        case WarEditMode of
          RLEMode:
            begin
              if (warmapfile.map[combobox1.ItemIndex].maplayer[1].pic[wartempy][wartempx] div 2 >= 0)
              and (warmapfile.map[combobox1.ItemIndex].maplayer[1].pic[wartempy][wartempx] div 2 < wargrpnum)
              and (wargrp[warmapfile.map[combobox1.ItemIndex].maplayer[1].pic[wartempy][wartempx] div 2].size >= 8) then
              begin
                McoldrawRLE8(@wargrp[warmapfile.map[combobox1.ItemIndex].maplayer[1].pic[wartempy][wartempx] div 2].data[0],wargrp[warmapfile.map[combobox1.ItemIndex].maplayer[1].pic[wartempy][wartempx] div 2].size,@warsmallbmp, 0,0, false);
                image3.Canvas.CopyRect(image3.Canvas.ClipRect,warsmallbmp.Canvas,image3.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              imzFile.DrawImztocanvas(image3.Canvas, @imzFIle.imzFile, warmapfile.map[combobox1.ItemIndex].maplayer[1].pic[wartempy][wartempx] div 2, 0, 0, 0);
            end;
        end;
      end;

    end;
end;

procedure TForm11.Timer1Timer(Sender: TObject);
var
  axp,ayp: integer;
  pointx,pointy,posx,posy,ix,iy, I: integer;
begin
  if not WarmapInitial then
    exit;
  pointx := image1.Width DIV 2;
  pointy := image1.Height div 2 - 31 * 18;
  //Axp := ((mousex - pointx) div 18 + (mouseY - pointy div 2 + 9) div 9) div 2;
  //Ayp := -((mousex - pointx) div 18 - (mouseY - pointy div 2 + 9) div 9) div 2;
  Axp := Round(((mousex - pointx) / 18 + (mouseY - pointy + 9) / 9) / 2);
  Ayp := Round(-((mousex - pointx) / 18 - (mouseY - pointy + 9) / 9) / 2);
  if needupdate then
  begin
    needupdate := false;
    displaywarmap(@warmapfile.map[combobox1.ItemIndex], @waropbmp, Wareditmode, @ImzFile);
    case WarEditMode of
        RLEMode:
          begin
            warbufbmp.Canvas.CopyRect(warbufbmp.Canvas.ClipRect, waropbmp.Canvas,waropbmp.Canvas.ClipRect);
            image1.Canvas.CopyRect(image1.ClientRect,waropbmp.Canvas,waropbmp.Canvas.ClipRect);
          end;
        IMZMode, PNGMode:
          begin
            warbufbmppng.Canvas.CopyRect(warbufbmppng.Canvas.ClipRect, waropbmppng.Canvas,waropbmppng.Canvas.ClipRect);
            image1.Canvas.CopyRect(image1.ClientRect,waropbmppng.Canvas,waropbmppng.Canvas.ClipRect);
          end;
      end;
  end;
  if (axp <> wartempx) or (ayp <> wartempy) then
  begin
    wartempx := axp;
    wartempy := ayp;

    statusbar1.Canvas.Brush.Color := clbtnface;
    statusbar1.Canvas.FillRect(statusbar1.Canvas.ClipRect);
    statusbar1.Repaint;
    statusbar1.Canvas.TextOut(10,10,'X='+inttostr(axp) + ',Y='+inttostr(ayp));
    if WarEditMode = RLEMode then
    begin
      warbufbmp.Canvas.CopyRect(warbufbmp.Canvas.ClipRect, waropbmp.Canvas,waropbmp.Canvas.ClipRect);
    end
    else if (WarEditMode = IMZMode) or (WarEditMode = PNGMode) then
    begin
      warbufbmppng.Canvas.CopyRect(warbufbmppng.Canvas.ClipRect, waropbmppng.Canvas, waropbmppng.Canvas.ClipRect);
    end;

    if (wartempx >= 0) and (wartempy >= 0) and (wartempx < warmapfile.map[combobox1.ItemIndex].x) and (wartempy < warmapfile.map[combobox1.ItemIndex].y) then
    begin
      label5.Caption := inttostr(warmapfile.map[combobox1.ItemIndex].maplayer[0].pic[wartempy][wartempx] div 2);
      label6.Caption := inttostr(warmapfile.map[combobox1.ItemIndex].maplayer[1].pic[wartempy][wartempx] div 2);
    end;

    UpdatewarSmallImg;

    if warstill = 1 then
    begin
      if (wartempx <> warstillx) or (wartempy <> warstilly) then
      begin
        if wartempx < warstillx then
        begin
          if wartempy < warstilly then
            for ix := wartempx to warstillx do
              for iy := wartempy to warstilly do
              begin
                posx := ix * 18 - Iy * 18  + pointx;
                posy := ix * 9 + Iy * 9 + pointy;
                drawsquare(posx,posy);
              end
          else
          begin
            for ix := wartempx to warstillx do
              for iy := wartempy downto warstilly do
              begin
                posx := ix * 18 - Iy * 18  + pointx;
                posy := ix * 9 + Iy * 9 + pointy;
                drawsquare(posx,posy);
              end;
          end;
        end
        else
        begin
          if wartempy < warstilly then
            for ix := wartempx downto warstillx do
              for iy := wartempy to warstilly do
              begin
                posx := ix * 18 - Iy * 18  + pointx;
                posy := ix * 9 + Iy * 9 + pointy;
                drawsquare(posx,posy);
              end
          else
            for ix := wartempx downto warstillx do
              for iy := wartempy downto warstilly do
              begin
                posx := ix * 18 - Iy * 18  + pointx;
                posy := ix * 9 + Iy * 9 + pointy;
                drawsquare(posx,posy);
              end;
        end;
      end;
    end
    else
    begin
      if (nowwargrpnum > 0) or ((nowwargrpnum >= 0) and (warlayer = 0)) then
      begin
        posx := axp * 18 - ayp * 18  + pointx;
        posy := axp * 9 + ayp * 9 + pointy;
        case WarEditMode of
          RLEMode:
            begin
              if (nowwargrpnum < wargrpnum) and (wargrp[nowwargrpnum].size >= 8) then
                McoldrawRLE8(@wargrp[nowwargrpnum].data[0],wargrp[nowwargrpnum].size,@warbufbmp, posx,posy, true);
            end;
          PNGMode, IMZMode:
            begin
              Imzfile.DrawImztocanvasEx(warbufbmpPNG.Canvas, @imzFIle.imzFile, nowwargrpnum, 0, posx, posy);
            end;
        end;
      end
      else if (warcopymapmode = 1) and (warlayer >= 0) and (warlayer <> 2)  then
      begin
        if WarEditMode <> RLEMode then
          for I := 0 to WarPNGbuf.Height - 1 do
            copymemory(@warPNGbuf.data[I][0], warbufbmpPNG.ScanLine[I], warPNGbuf.width * 4);
         for Ix := warcopymap.x - 1 downto 0 do
           for iy := warcopymap.y - 1 downto 0 do
             if (warcopymap.maplayer[warlayer].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] > 0) or ((warcopymap.maplayer[warlayer].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] = 0) and (warlayer = 0)) then
             begin
               posx := (wartempx - ix) * 18 - (wartempy - iy) * 18  + pointx;
               posy := (wartempx - ix) * 9 + (wartempy - Iy) * 9 + pointy;
               case WarEditMode of
                 RLEMode:
                   begin
                     if (warcopymap.maplayer[warlayer].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] div 2 >= 0)
                     and (warcopymap.maplayer[warlayer].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] div 2 < wargrpnum)
                     and (wargrp[warcopymap.maplayer[warlayer].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] div 2].size >= 8) then
                       McoldrawRLE8(@wargrp[warcopymap.maplayer[warlayer].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] div 2].data[0],wargrp[warcopymap.maplayer[warlayer].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] div 2].size,@warbufbmp, posx,posy, true);
                   end;
                 PNGMode, IMZMode:
                   begin
                     ImzFile.SceneQuickDrawBuf(@warPNGbuf, warcopymap.maplayer[warlayer].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] div 2, posx, posy);
                   end;
               end;

             end;
             //if (ix + wartempx >= 0) and (ix + wartempx < warmapfile.map[combobox1.ItemIndex].x) and (iy + wartempy >=0) and (iy + wartempy < warmapfile.map[combobox1.ItemIndex].y) then
              //warmapfile.map[combobox1.ItemIndex].maplayer[warlayer].pic[wartempy + iy][wartempx + ix] := warcopymap.maplayer[warlayer].pic[iy][ix];
        if WarEditMode <> RLEMode then
          for I := 0 to warPNGbuf.Height - 1 do
            copymemory(warbufbmpPNG.ScanLine[I], @warPNGbuf.data[I][0], warPNGbuf.width * 4);
      end
      else if (warcopymapmode = 1) and (warlayer = 2) then
      begin
        if WarEditMode <> RLEMode then
          for I := 0 to WarPNGbuf.Height - 1 do
            copymemory(@warPNGbuf.data[I][0], warbufbmpPNG.ScanLine[I], warPNGbuf.width * 4);
        for Ix := warcopymap.x - 1 downto 0 do
           for iy := warcopymap.y - 1 downto 0 do
             for I := 0 to warcopymap.layernum - 1 do
             if (warcopymap.maplayer[I].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] > 0) or ((warcopymap.maplayer[I].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] = 0) and (I = 0)) then
             begin
               posx := (wartempx - ix) * 18 - (wartempy - iy) * 18  + pointx;
               posy := (wartempx - ix) * 9 + (wartempy - Iy) * 9 + pointy;
               case WarEditMode of
                 RLEMode:
                   begin
                     if (warcopymap.maplayer[I].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] div 2 >= 0)
                     and (warcopymap.maplayer[I].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] div 2 < wargrpnum)
                     and (wargrp[warcopymap.maplayer[I].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] div 2].size >= 8) then
                       McoldrawRLE8(@wargrp[warcopymap.maplayer[I].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] div 2].data[0],wargrp[warcopymap.maplayer[I].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] div 2].size,@warbufbmp, posx,posy, true);
                   end;
                 PNGMode, IMZMode:
                   begin
                     ImzFile.SceneQuickDrawBuf(@warPNGbuf, warcopymap.maplayer[I].pic[warcopymap.y - iy - 1][warcopymap.x - ix - 1] div 2, posx, posy);
                   end;
               end;

             end;
        if WarEditMode <> RLEMode then
          for I := 0 to warPNGbuf.Height - 1 do
            copymemory(warbufbmpPNG.ScanLine[I], @warPNGbuf.data[I][0], warPNGbuf.width * 4);
      end;
    end;
    if WarEditMode = RLEMode then
      image1.Canvas.CopyRect(image1.ClientRect,warbufbmp.Canvas,warbufbmp.Canvas.ClipRect)
    else
    begin
      image1.Canvas.CopyRect(image1.ClientRect,warbufbmppng.Canvas,warbufbmppng.Canvas.ClipRect);
    end;
  end;
end;

function readwardef(idx,grp:string; opmapstruct:Pmapstruct): integer;
var
  I,I2,ix,iy,F,FF, wFlen:integer;
  offset: array of integer;
begin
  //
  result := 1;
  try
  F:=fileopen(idx, fmopenread);
  wflen := fileseek(F,0,2);
  setlength(offset, wFlen shr 2);
  fileseek(F,0,0);
  fileread(F,offset[0],wFlen);
  fileclose(F);
  opmapstruct.num := 0;
  for I := 0 to wflen shr 2 - 1 do
    if offset[I] > 0 then
      inc(opmapstruct.num)
    else
      break;
  except
    fileclose(F);
    result := 0;
    //showmessage('idx错误！');
    exit;
  end;
  try
  setlength(opmapstruct.map, opmapstruct.num);
  FF := fileopen(grp, fmopenread);
  fileseek(FF,0,0);
  for I := 0 to opmapstruct.num - 1 do
  begin
    if i = 0 then
      fileseek(F,0,0)
    else
     fileseek(F,offset[I - 1],0);
    opmapstruct.map[I].layernum := 2;
    opmapstruct.map[I].x := 64;
    opmapstruct.map[I].y := 64;
    setlength(opmapstruct.map[I].maplayer,opmapstruct.map[I].layernum);
    for I2 := 0 to opmapstruct.map[I].layernum - 1 do
    begin
      setlength(opmapstruct.map[I].maplayer[I2].pic, opmapstruct.map[I].y, opmapstruct.map[I].x);
      for iy := 0 to opmapstruct.map[I].y - 1 do
        fileread(FF, opmapstruct.map[I].maplayer[i2].pic[iy][0], opmapstruct.map[I].x * 2);
    end;
  end;
    fileclose(FF);
  except
    fileclose(FF);
    //showmessage('地图错误！');
    result := 0;
    exit;
  end;
end;

function readWarmapgrp: integer;
var
  offset: array of integer;
  I, idx, grp,temp: integer;
begin
  try
  idx := fileopen(gamepath + warmapidx, fmopenread);
  grp := fileopen(gamepath + warmapgrp, fmopenread);
  temp := fileseek(idx,0,2);
  wargrpnum := temp div 4;
  setlength(wargrp, temp div 4);
  setlength(offset, temp div 4 + 1);
  fileseek(idx,0,0);
  fileread(idx, offset[1], temp);
  offset[0] := 0;
  fileseek(grp,0,0);
  for I := 0 to temp div 4 - 1 do
  begin
    wargrp[I].size := offset[I + 1]- offset[I];
    if wargrp[I].size < 0 then
      wargrp[I].size := 0;
    setlength(wargrp[I].data, wargrp[I].size);
    if wargrp[I].size > 0 then
      fileread(grp, wargrp[I].data[0], wargrp[I].size);
  end;
  fileclose(idx);
  fileclose(grp);
  result := 1;
  except
    fileclose(idx);
    fileclose(grp);
    result := 0;
   // showmessage('错误');
  end;

end;

procedure displaywarmap(waropMap: Pmap; waropbmp2:PNTbitmap; EMode: TMapEditMode; ImzFile: PImzFile);
VAR
  ix,iy, I, i2,posx,posy: integer;
  pointx,pointy: integer;
begin
  if EMode <> RLEMode then
    for I := 0 to warPNGbuf.Height - 1 do
      fillchar(warPNGbuf.data[I][0], warPNGbuf.width * 4, #0);

  pointx := WAROPBMP2.Width DIV 2;
  pointy := waropbmp2.Height div 2 - 31 * 18;
  waropbmp2.Canvas.Brush.Color := clblack;
  waropbmp2.Canvas.FillRect(waropbmp2.Canvas.ClipRect);
  for i := 0 to min(waropmap.x ,waropmap.y) - 1 do
  begin
    for ix := I to waropmap.x - 1 do
    begin
      if needupdate then
        exit;
      posx := ix * 18 - I * 18  + pointx;
      posy := ix * 9 + I * 9 + pointy;
      for I2 := 0 to waropmap.layernum - 1 do
      begin
        try
          if (waropmap.maplayer[I2].pic[I][ix] div 2 > 0) or (I2 = 0)  then
          begin
            case EMode of
              RLEMode:
                begin
                  if (waropmap.maplayer[I2].pic[I][ix] div 2 < wargrpnum) and (waropmap.maplayer[I2].pic[I][ix] div 2 >= 0) and (wargrp[waropmap.maplayer[I2].pic[I][ix] div 2].size >= 8) then
                    McoldrawRLE8(@wargrp[waropmap.maplayer[I2].pic[I][ix] div 2].data[0],wargrp[waropmap.maplayer[I2].pic[I][ix] div 2].size,waropbmp2, posx, posy, true);
                end;
              IMZMode, PNGMode:
                begin
                  ImzFile.SceneQuickDrawBuf(@warPNGbuf, waropmap.maplayer[I2].pic[I][ix] div 2, posx, posy);
                end;
            end;
          end;
        except

        end;
      end;
    end;
    for Iy := I + 1 to waropmap.y - 1 do
    begin
      if needupdate then
        exit;
      posx := i * 18 - Iy * 18  + pointx;
      posy := i * 9 + Iy * 9 + pointy;
      for I2 := 0 to waropmap.layernum - 1 do
      begin
        try
          if (waropmap.maplayer[I2].pic[Iy][i] div 2 > 0) or (I2 = 0) then
          begin
            case EMode of
              RLEMode:
                begin
                  if (waropmap.maplayer[I2].pic[Iy][i] div 2 < wargrpnum) and (waropmap.maplayer[I2].pic[Iy][i] div 2 >= 0) and (wargrp[waropmap.maplayer[I2].pic[Iy][i] div 2].size >= 8) then
                    McoldrawRLE8(@wargrp[waropmap.maplayer[I2].pic[Iy][i] div 2].data[0],wargrp[waropmap.maplayer[I2].pic[Iy][i] div 2].size,waropbmp2, posx, posy, true);
                end;
              IMZMode, PNGMode:
                begin
                  ImzFile.SceneQuickDrawBuf(@warPNGbuf, waropmap.maplayer[I2].pic[Iy][i] div 2, posx, posy);
                end;
            end;
          end;
        except

        end;
      end;
    end;
  end;
  if EMode <> RLEMode then
  begin
    warbufbmppng.Canvas.Lock;
    for I := 0 to warPNGbuf.Height - 1 do
      copymemory(warbufbmppng.ScanLine[I], @warPNGbuf.data[I][0], warPNGbuf.Width * 4);
    warbufbmppng.Canvas.UnLock;
    waropbmppng.Canvas.CopyRect(waropbmppng.Canvas.ClipRect, warbufbmppng.Canvas, warbufbmppng.Canvas.ClipRect);
  end;

end;

procedure McoldrawRLE8(Ppic: Pbyte; len: integer; PBMP: PntBitMap; dx, dy: integer; canmove: boolean);
var
  state,i, iy, ix, linesize, temp: integer;
  pw,ph,xs,ys: integer;
  Pbuf: Pbyte;
begin
  //
  try
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

  if (dx > Pbmp.width) or (dx + pw < 0) or (dy > Pbmp.height) or (dy + ph < 0) then
    exit;
  //if (dx < 0)  or ((dx + pw) >= pbmp.Width) or (dy < 0)  or ((dy + ph) >= pbmp.Height) then
    //exit;

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
          //Pbuf := Pbmp.ScanLine[iy + dy];
          //copymemory((Pbuf + ix), (Ppic + I), state - 2);
          if (iy + dy < PBMP.Height)and (iy + dy >= 0) then
          begin
            Pbuf := Pbmp.ScanLine[iy + dy];
            if ix < 0 then
            begin
              if ix + state - 2 < PBMP.Width then
              begin
                copymemory(Pbuf, (Ppic + I - ix), state - 2 + ix);
              end
              else
              begin
                copymemory((Pbuf), (Ppic + I - ix), PBMP.Width);
              end;
            end
            else if ix + state - 2 < PBMP.Width then
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
  except

  end;
end;

procedure TForm11.drawsquare(x,y: integer);
var
  I: integer;
  Pdata: Pbyte;
begin
  //
  if WarEditMode = RLEMode then
  begin
  try
  Pdata := warbufbmp.ScanLine[Y];
  (Pdata + x)^ := 23;
 { (Pdata + X * 3)^ := 0;
  (Pdata + X * 3 +1)^ := 0;
  (Pdata + X * 3 +2)^ := $FF;  }
 // Pdata := warbufbmp.ScanLine[Y];
 (Pdata+ x - 1)^ := 23;
{  (Pdata + X * 3 - 3)^ := 0;
  (Pdata + X * 3 -2)^ := 0;
  (Pdata + X * 3 -1)^ := $FF; }
  //warbufbmp.Canvas.Pixels[X, Y] := clred;
  //warbufbmp.Canvas.Pixels[X - 1, Y] := clred;
  for I := 1 to 8 do
  begin
    Pdata := warbufbmp.ScanLine[Y - I];
   (Pdata + (X - 2 * I))^ := 23;
    (Pdata + (X - 2 * I - 1))^ := 23;
     (Pdata + (X + 2 * I))^ := 23;
     (Pdata + (X + 2 * I + 1))^ := 23;
  {  (Pdata + (X - 2 * I) * 3)^ := 0;
    (Pdata + (X - 2 * I) * 3 +1)^ := 0;
    (Pdata + (X - 2 * I) * 3 +2)^ := $FF;
    (Pdata + (X - 2 * I - 1) * 3)^ := 0;
    (Pdata + (X - 2 * I - 1) * 3 +1)^ := 0;
    (Pdata + (X - 2 * I - 1) * 3 +2)^ := $FF;
    (Pdata + (X + 2 * I - 1) * 3)^ := 0;
    (Pdata + (X + 2 * I - 1) * 3 +1)^ := 0;
    (Pdata + (X + 2 * I - 1) * 3 +2)^ := $FF;
    (Pdata + (X + 2 * I) * 3)^ := 0;
    (Pdata + (X + 2 * I) * 3 +1)^ := 0;
    (Pdata + (X + 2 * I) * 3 +2)^ := $FF;  }
    //warbufbmp.Canvas.Pixels[X - 2 * I, Y - I] := clred;
    //warbufbmp.Canvas.Pixels[X - 2 * I - 1, Y - I] := clred;
    //warbufbmp.Canvas.Pixels[X + 2 * I - 1, Y - I] := clred;
   // warbufbmp.Canvas.Pixels[X + 2 * I, Y - I] := clred;
  end;
   Pdata := warbufbmp.ScanLine[Y - 9];
   (Pdata + (X - 18))^ := 23;
   (Pdata + (X + 17))^ := 23;
   { (Pdata + (X - 18) * 3)^ := 0;
    (Pdata + (X - 18) * 3 +1)^ := 0;
    (Pdata + (X - 18) * 3 +2)^ := $FF;
    (Pdata + (X + 17) * 3)^ := 0;
    (Pdata + (X + 17) * 3 +1)^ := 0;
    (Pdata + (X + 17) * 3 +2)^ := $FF;  }
  //warbufbmp.Canvas.Pixels[X - 18, Y - 9] := clred;
  //warbufbmp.Canvas.Pixels[X + 17, Y - 9] := clred;
  for I := 1 to 8 do
  begin
     Pdata := warbufbmp.ScanLine[Y - 9 - I];
     (Pdata + (X - 19 + 2 * I))^ := 23;
     (Pdata + (X - 19 + 2 * I + 1))^ := 23;
     (Pdata + (X+ 17- 2 * I))^ := 23;
     (Pdata + (X+ 17- 2 * I + 1))^ := 23;
     {
    (Pdata + (X - 19 + 2 * I) * 3)^ := 0;
    (Pdata + (X - 19 + 2 * I) * 3 +1)^ := 0;
    (Pdata + (X - 19 + 2 * I) * 3 +2)^ := $FF;
    (Pdata + (X - 19 + 2 * I + 1) * 3)^ := 0;
    (Pdata + (X - 19 + 2 * I + 1) * 3 +1)^ := 0;
    (Pdata + (X - 19 + 2 * I + 1) * 3 +2)^ := $FF;
    (Pdata + (X + 17 - 2 * I) * 3)^ := 0;
    (Pdata + (X + 17 - 2 * I) * 3 +1)^ := 0;
    (Pdata + (X + 17 - 2 * I) * 3 +2)^ := $FF;
    (Pdata + (X + 17 - 2 * I + 1) * 3)^ := 0;
    (Pdata + (X + 17 - 2 * I + 1) * 3 +1)^ := 0;
    (Pdata + (X + 17 - 2 * I + 1) * 3 +2)^ := $FF;   }
    //warbufbmp.Canvas.Pixels[X - 19 + 2 * I, Y - 9 - I] := clred;
    //warbufbmp.Canvas.Pixels[X - 19 + 2 * I + 1, Y - 9 - I] := clred;
    //warbufbmp.Canvas.Pixels[X + 17 - 2 * I, Y - 9 - I] := clred;
    //warbufbmp.Canvas.Pixels[X + 17 - 2 * I + 1, Y - 9 - I] := clred;
  end;
  Pdata := warbufbmp.ScanLine[Y - 17];
    (Pdata + x)^ := 23;
    (Pdata + x - 1)^ := 23;
    {
    (Pdata + (X) * 3)^ := 0;
    (Pdata + (X) * 3 +1)^ := 0;
    (Pdata + (X) * 3 +2)^ := $FF;
    (Pdata + (X - 1) * 3)^ := 0;
    (Pdata + (X - 1) * 3 +1)^ := 0;
    (Pdata + (X - 1) * 3 +2)^ := $FF;}
 // warbufbmp.Canvas.Pixels[X, Y - 17] := clred;
 // warbufbmp.Canvas.Pixels[X - 1, Y - 17] := clred;

  except
    exit;
  end;
  end
  else
  begin
    try
      Pdata := warbufbmpPNG.ScanLine[Y];
      Pcardinal(Pdata + x * 4)^ := $FF0000;

 Pcardinal(Pdata+ x * 4- 1* 4)^ := $FF0000;

  for I := 1 to 8 do
  begin
    Pdata := warbufbmpPNG.ScanLine[Y - I];
   Pcardinal(Pdata + (X - 2 * I)* 4)^ := $FF0000;
    Pcardinal(Pdata + (X - 2 * I - 1)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X + 2 * I)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X + 2 * I + 1)* 4)^ := $FF0000;
  end;
   Pdata := warbufbmpPNG.ScanLine[Y - 9];
   Pcardinal(Pdata + (X - 18)* 4)^ := $FF0000;
   Pcardinal(Pdata + (X + 17)* 4)^ := $FF0000;

  for I := 1 to 8 do
  begin
     Pdata := warbufbmpPNG.ScanLine[Y - 9 - I];
     Pcardinal(Pdata + (X - 19 + 2 * I)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X - 19 + 2 * I + 1)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X+ 17- 2 * I)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X+ 17- 2 * I + 1)* 4)^ := $FF0000;

  end;
    Pdata := warbufbmpPNG.ScanLine[Y - 17];
    Pcardinal(Pdata + x* 4)^ := $FF0000;
    Pcardinal(Pdata + x* 4 - 1* 4)^ := $FF0000;
    except
      exit;
    end;
  end;
end;


end.
