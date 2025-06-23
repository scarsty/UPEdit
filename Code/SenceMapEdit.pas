unit SenceMapEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,head, iniFiles, ExtCtrls, ComCtrls, StdCtrls,math, Spin, ImzObject, ImageZ;

type

  TForm12 = class(TForm)
    Panel1: TPanel;
    StatusBar1: TStatusBar;
    Button1: TButton;
    ComboBox1: TComboBox;
    Label1: TLabel;
    ComboBox2: TComboBox;
    Label2: TLabel;
    ComboBox3: TComboBox;
    Label14: TLabel;
    GroupBox1: TGroupBox;
    Label15: TLabel;
    Label16: TLabel;
    当前空中: TLabel;
    Label17: TLabel;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    CheckBox1: TCheckBox;
    Timer1: TTimer;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Panel4: TPanel;
    Image2: TImage;
    Panel5: TPanel;
    Image3: TImage;
    Panel6: TPanel;
    Image4: TImage;
    Panel7: TPanel;
    Image5: TImage;
    Button7: TButton;
    Button8: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Timer2: TTimer;
    Button9: TButton;
    Button10: TButton;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel10: TPanel;
    ScrollBox1: TScrollBox;
    Panel2: TPanel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    Edit9: TEdit;
    Edit10: TEdit;
    Edit11: TEdit;
    Button2: TButton;
    Panel3: TPanel;
    Label22: TLabel;
    Edit12: TEdit;
    Button6: TButton;
    Image1: TImage;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    SpinEdit1: TSpinEdit;
    Label23: TLabel;
    Button11: TButton;
    Button12: TButton;
    RadioGroup1: TRadioGroup;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Image1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure Image1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure Button1Click(Sender: TObject);
    procedure drawsquare(x,y: integer);
    procedure ComboBox3Select(Sender: TObject);
    procedure ComboBox2Select(Sender: TObject);
    procedure ComboBox1Select(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure displayscenemap(sceneopMap: Pmap; sceneopbmp2:PNTbitmap);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Edit12KeyPress(Sender: TObject; var Key: Char);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Updatesmallimg(pointx,pointy, axp, ayp: integer);
    procedure Timer2Timer(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure CheckBox3Click(Sender: TObject);
    procedure CheckBox4Click(Sender: TObject);
    procedure drawsquare2(x,y: integer;sceneopbmp2 :PNTbitmap);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure readundoini;
    procedure writeundoini;
    procedure SpinEdit1Change(Sender: TObject);
    procedure initialundomap(sMap: Pmap; sMapEvent: PmapEvent; LastCount: integer);
    procedure undo;
    procedure redo;
    function Addundosave: boolean;
    procedure Button11Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure SetEditMode(EMode: TMapEditMode);
    procedure RadioGroup1Click(Sender: TObject);
    procedure writeSModeini(EMode: TMapEditMode);
  private
    { Private declarations }
  public
    { Public declarations }
    ScenemapInitial: boolean;
    ImzFile: TimzFile;
    ScenePalle : Cardinal;
    SceneEditMode: TMapEditMode;
  end;

procedure readDini;
function readscenegrp(idx,grp: string): integer;
function readDAndS(index:integer): integer;
procedure McoldrawRLE8(Ppic: Pbyte; len: integer; PBMP: PntBitMap; dx, dy: integer; canmove: boolean);
procedure copyscenemap(source,destination:Pmap);
procedure copyscenemapevent(source,destination:Pmapevent);

var

  undoAmount: integer = 10; //默认撤销次数
  undotimes : integer = 0;
  undoSavetimes: integer = 1;

  nowscenegrpnum: integer;
  scenelayer: integer;
  scenegrp: array of Tgrppic;

  scenemapfile : Tmapstruct;
  scenemapbackup : array of Tmap;
  scenemapeventbackup : array of Tmapevent;

  ScenePNGBuf: TScenePNGBuf;
  sceneopbmp: Tbitmap;
  scenebufbmp: Tbitmap;
  sceneopbmppng: Tbitmap;
  scenebufbmppng: Tbitmap;
  tempeventnum: integer;

  scenegrpnum: integer;

  scenecopymap: Tmap;
  scenecopymapmode:integer;
  scenetempx,scenetempy: integer;
  scenecenterx,scenecentery: integer;
  scenesmallbmp: Tbitmap;
  scenestill: integer;
  scenestillx,scenestilly: integer;
  evtx,evty: integer;
  evtnum: integer;
  candraw: boolean = false;
  mousex,mousey: integer;
  scenelock :boolean= true;
  needupdate : boolean;

  highselect: boolean = false; //批量海拔设置选择区域
  highendx: integer = -1;
  highendy: integer = -1;
  eventpictime: integer = 0;

implementation

uses
   main,grplist,kdefedit;

{$R *.dfm}

procedure TForm12.Button10Click(Sender: TObject);
var
  FH: integer;
  I,I1,I2: integer;
begin
  scenelock := true;
  opendialog1.Filter := 'Scene Module files (*.smd)|*.smd|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    if fileexists(opendialog1.FileName) then
    begin
      try
        combobox3.ItemIndex := 7;
        scenelayer := 6;
        FH := fileopen(opendialog1.FileName, fmopenread);
        scenecopymap.layernum := scenemapfile.map[combobox2.ItemIndex].layernum;
        setlength(scenecopymap.maplayer, scenecopymap.layernum);
        fileseek(FH,0,0);
        fileread(FH, scenecopymap.x, 4);
        fileread(FH, scenecopymap.y, 4);
        for I := 0 to scenecopymap.layernum - 1 do
        begin
          setlength(scenecopymap.maplayer[I].pic,scenecopymap.y,scenecopymap.x);
          for I1 := 0 to scenecopymap.y - 1 do
          begin
            fileread(FH, scenecopymap.maplayer[I].pic[I1][0], scenecopymap.x * 2);
          end;
        end;

      finally
        fileclose(FH);
      end;
    end;
  end;
  scenelock := false;
  scenestill := 0;
  scenestillx := -1;
end;

procedure TForm12.Button11Click(Sender: TObject);
begin
  undo;
end;

procedure TForm12.Button12Click(Sender: TObject);
begin
  redo;
end;

procedure TForm12.Button1Click(Sender: TObject);
var
  Form3: TForm3;
  FormImz: TImzForm;
  I: integer;
begin
  if SceneEditMode = RLEMode then
  begin
  if CForm3 then
  begin
    CFOrm3 := false;
    Form3 := TForm3.Create(application);
    Form3.WindowState := wsmaximized;
    MdiChildHandle[3] := Form3.Handle;
    Form3.WindowState := wsnormal;
    Form3.edit1.Text := gamepath + SMapIDX;
    Form3.edit2.Text := gamepath + SMapgrp;
    Form3.Button4.Click;
  end
  else
  begin
    for I := 0 to Mainform.MDIChildCount - 1 do
      if Mainform.MDIChildren[I].Handle = MdiChildHandle[3] then
      begin
        TForm3(Mainform.MDIChildren[I]).ComboBox1.ItemIndex := -1;
        TForm3(Mainform.MDIChildren[I]).edit1.Text := gamepath + SMapIDX;
        TForm3(Mainform.MDIChildren[I]).edit2.Text := gamepath + SMapgrp;
        TForm3(Mainform.MDIChildren[I]).Button4.Click;
        self.WindowState := wsnormal;
        Mainform.MDIChildren[I].BringToFront;
      end;
  end;
  end
  else
  begin
  if CFormImz then
  begin
    CFormImz := false;
    FormImz := TImzForm.Create(application);
    MdiChildHandle[13] := FormImz.Handle;
    FormImz.WindowState := wsnormal;
    if SceneEditMode = IMZMode then
    begin
      FormImz.Edit2.Text := gamepath + SmapIMZ;
      //FormImz.IMZeditMode := TIMZEditMode(0);
      FormIMZ.SetEditMode(TIMZEditMode(0));
    end
    else
    begin
      FormImz.Edit2.Text := gamepath + SmapPNGPATH;
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
        if SceneEditMode = IMZMode then
        begin
          TImzForm(Mainform.MDIChildren[I]).Edit2.Text := gamepath + SmapIMZ;
          //TImzForm(Mainform.MDIChildren[I]).IMZeditMode := TIMZEditMode(0);
          TImzForm(Mainform.MDIChildren[I]).SetEditMode(TIMZEditMode(0));
        end
        else
        begin
          TImzForm(Mainform.MDIChildren[I]).Edit2.Text := gamepath + SmapPNGPATH;
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

procedure TForm12.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  setlength(scenegrp, 0);
  scenemapfile.num := 0;
  setlength(scenemapfile.map,0);
  ImzFile.ReleaseAllPNG;
  ImzFile.free;
  setlength(ScenePNGBuf.data, 0, 0);
  sceneopbmppng.Free;
  scenebufbmppng.Free;
  sceneopbmp.Free;
  scenebufbmp.Free;
  CForm12 := true;
  action := cafree;
end;

procedure readDini;
var
  filename: string;
  ini: Tinifile;
  I: integer;
begin
  Filename := StartPath + iniFilename;
  try
    ini := TIniFile.Create(filename);
    Dini.num := ini.ReadInteger('D_Modify','num', 0);
    setlength(Dini.attrib, Dini.num);
    for I := 0 to Dini.num - 1 do
      Dini.attrib[I] := ini.ReadString('D_Modify','attrib'+inttostr(I),'');
  finally
    ini.Free;
  end;

end;

procedure TForm12.readundoini;
var
  filename: string;
  ini: Tinifile;
begin
  Filename := StartPath + iniFilename;
  try
    ini := TIniFile.Create(filename);
    undoAmount := ini.ReadInteger('Run','undoAmount',undoAmount);
    SceneEditMode := TMapEditMode(ini.ReadInteger('File','SceneMode', integer(SceneEditMode)));
  finally
    ini.Free;
  end;
end;

procedure TForm12.writeundoini;
var
  filename: string;
  ini: Tinifile;
  I: integer;
begin
  Filename := StartPath + iniFilename;
  try
    ini := TIniFile.Create(filename);
    ini.WriteInteger('Run', 'undoAmount', undoAmount);
  finally
    ini.Free;
  end;
end;

procedure TForm12.writeSModeini(EMode: TMapEditMode);
var
  filename: string;
  ini: Tinifile;
  I: integer;
begin
  Filename := StartPath + iniFilename;
  try
    ini := TIniFile.Create(filename);
    ini.WriteInteger('File', 'SceneMode', integer(EMode));
  finally
    ini.Free;
  end;
end;

procedure TForm12.initialundomap(sMap: Pmap; sMapEvent: PmapEvent;LastCount: integer);
var
  I: integer;
begin
  if LastCount < undoAmount then
  begin
    for I := LastCount to undoAmount - 1 do
    begin
      copyscenemap(sMap,@(SceneMapBackup[I]));
      copyscenemapevent(sMapEvent,@(SceneMapEventBackup[I]));
    end;
  end;

end;

procedure TForm12.RadioGroup1Click(Sender: TObject);
begin
  setEditMode(TMapEditMode(RadioGroup1.ItemIndex));
end;

procedure TForm12.SetEditMode(EMode: TMapEditMode);
begin
  //

  if EMode = RLEMode then
  begin
    {sceneopbmp.PixelFormat := pf8bit;
    scenebufbmp.PixelFormat := pf8bit;
    scenesmallbmp.PixelFormat := pf8bit;
    sceneopbmp.Palette := ScenePalle;
    scenebufbmp.Palette := ScenePalle;
    scenesmallbmp.Palette := ScenePalle;}
    if not (readscenegrp(gamepath + Smapidx, gamepath + smapgrp) = 1) then
    begin
      showmessage('读取IDX或GRP文件错误！');
      SceneMapInitial := false;
      RadioGroup1.ItemIndex := integer(SceneEditMode);
      exit;
    end;
    ScenePNGBuf.width := 0;
    ScenePNGBuf.height := 0;
    setlength(ScenePNGBuf.data, ScenePNGBuf.height, ScenePNGBuf.width * 4);

    SceneMapInitial := true;
    scenelock := false;
    needupdate := true;

  end
  else if EMODE = IMZMode then
  begin

    {sceneopbmp.ReleasePalette;
    scenebufbmp.ReleasePalette;
    scenesmallbmp.ReleasePalette;
    sceneopbmp.PixelFormat := pf32bit;
    scenebufbmp.PixelFormat := pf32bit;
    scenesmallbmp.PixelFormat := pf32bit;   }


    if not imzFile.ReadImzFromFile(@imzFIle.imzFile, gamepath + SMAPIMZ) then
    begin
      showmessage('读取IMZ文件失败！');
      SceneMapInitial := false;
      RadioGroup1.ItemIndex := integer(SceneEditMode);
      exit;
    end;
    ImzFile.ReadAllPNG;
    ScenePNGBuf.width := image1.width;
    ScenePNGBuf.height := image1.height;
    setlength(ScenePNGBuf.data, ScenePNGBuf.height, ScenePNGBuf.width * 4);
    SceneMapInitial := true;
    scenelock := false;
    needupdate := true;
  end
  else if EMode = PNGMode then
  begin
   { sceneopbmp.PixelFormat := pf32bit;
    scenebufbmp.PixelFormat := pf32bit;
    scenesmallbmp.PixelFormat := pf32bit;
    sceneopbmp.ReleasePalette;
    scenebufbmp.ReleasePalette;
    scenesmallbmp.ReleasePalette;       }

    if not imzFile.ReadImzFromFolder(@imzFIle.imzFile, gamepath + SMAPPNGpath) then
    begin
      showmessage('读取IMZ文件夹失败！');
      SceneMapInitial := false;
      RadioGroup1.ItemIndex := integer(SceneEditMode);
      exit;
    end;
    ImzFile.ReadAllPNG;
    ScenePNGBuf.width := image1.width;
    ScenePNGBuf.height := image1.height;
    setlength(ScenePNGBuf.data, ScenePNGBuf.height, ScenePNGBuf.width * 4);
    SceneMapInitial := true;
    scenelock := false;
    needupdate := true;
  end;
  SceneEditMode := Emode;
  writeSModeini(EMode);
end;

procedure TForm12.undo;
begin
  //
  if undotimes < 0 then
    undotimes := 0;
  if undotimes < undosavetimes - 1 then
  begin
    inc(undotimes);
    copyscenemap(@(SceneMapBackup[undotimes]),@(scenemapfile.map[combobox2.ItemIndex]));
    copyscenemapevent(@SceneMapeventBackup[undotimes],@(DFile.mapevent[combobox2.ItemIndex]));
    needupdate := true;
  end;
end;

procedure TForm12.redo;
begin
  //
  if (undotimes > 0) and (undotimes < undosavetimes) then
  begin
    dec(undotimes);
    copyscenemap(@(SceneMapBackup[undotimes]),@(scenemapfile.map[combobox2.ItemIndex]));
    copyscenemapevent(@SceneMapeventBackup[undotimes],@(DFile.mapevent[combobox2.ItemIndex]));
    needupdate := true;
  end;
end;

function TForm12.Addundosave: boolean;
var
  tempmap: array of Tmap;
  tempmapevent: array of TMapevent;
  I,newtimes : integer;
begin
  //
  setlength(tempmap, undoAmount);
  setlength(tempmapevent, undoAmount);
  if undotimes < 0 then
    undotimes := 0;

  if undosavetimes < undoAmount then
  begin
    newtimes := undosavetimes - undotimes + 1;
    for I := undotimes to undosavetimes - 1 do
    begin
      copyscenemap(@scenemapbackup[I],@tempMap[1 + I - undotimes]);
      copyscenemapevent(@scenemapeventbackup[I],@tempMapevent[1 + I - undotimes]);
    end;
    copyscenemap(@(scenemapfile.map[combobox2.ItemIndex]), @tempMap[0]);
    copyscenemapevent(@(DFile.mapevent[combobox2.ItemIndex]), @tempMapevent[0]);
    for I := 0 to undoAmount - 1 do
    begin
      copyscenemap(@tempMap[I], @scenemapbackup[I]);
      copyscenemapevent(@tempMapEvent[I], @scenemapeventbackup[I]);
    end;
  end
  else if undosavetimes >= undoAmount then
  begin
    newtimes := undosavetimes - undotimes + 1;
    if newtimes > undoAmount then
    begin
      newtimes := undoAmount;
      for I := undotimes to undoAmount - 2 do
      begin
        copyscenemap(@scenemapbackup[I],@tempMap[I - undotimes + 1]);
        copyscenemapevent(@scenemapeventbackup[I],@tempMapevent[1 + I - undotimes]);
      end;
    end
    else
    begin
      for I := undotimes to undoAmount - 1 do
      begin
        copyscenemap(@scenemapbackup[I],@tempMap[I - undotimes + 1]);
        copyscenemapevent(@scenemapeventbackup[I],@tempMapevent[1 + I - undotimes]);
      end;
    end;

    copyscenemap(@(scenemapfile.map[combobox2.ItemIndex]), @tempMap[0]);
    copyscenemapevent(@(DFile.mapevent[combobox2.ItemIndex]), @tempMapevent[0]);
    for I := 0 to undoAmount - 1 do
    begin
      copyscenemap(@tempMap[I], @scenemapbackup[I]);
      copyscenemapevent(@tempMapEvent[I], @scenemapeventbackup[I]);
    end;
  end;
  undosavetimes := newtimes;
  undotimes := 0;
  setlength(tempmap, 0);
  setlength(tempmapevent, 0);
end;

procedure TForm12.FormCreate(Sender: TObject);
var
  I1,I: integer;
   PalSize:longint;
    pLogPalle:TMaxLogPalette;
    PalleEntry:TPaletteEntry;
    Palle:HPalette;
  tempstr: string;
begin
  SceneEditMode := RLEMode;
  ImzFile := TimzFile.create;
  ScenemapInitial := false;
  timer1.Enabled := true;
  timer2.Enabled := true;
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
     ScenePalle := Palle;
     needupdate := false;
     scenelock :=true;
  except
    showmessage('调色板设置失败！');
    //self.Close;
    //exit;
  end;

  for i1 := 0 to RFilenum - 1 do
  begin
    try
      tempstr := displayname(RFilenote[i1]);
    except
      tempstr := inttostr(i1);
    end;
    combobox1.Items.Add(tempstr);
  end;

  tempeventnum:= -1;
  evtx := -1;
  evty := -1;
  scenelayer := -1;
  combobox1.ItemIndex := 0;
  nowscenegrpnum := 0;
  scenecopymapmode := 0;

  sceneopbmppng := Tbitmap.Create;
  sceneopbmppng.Width := image1.Width;
  sceneopbmppng.Height := image1.Height;
  sceneopbmppng.Canvas.Font.Size := 8;
  sceneopbmppng.Canvas.Font.Color := clyellow;
  sceneopbmppng.PixelFormat := pf32bit;

  scenebufbmppng := Tbitmap.Create;
  scenebufbmppng.Width := image1.Width;
  scenebufbmppng.Height := image1.Height;
  scenebufbmppng.Canvas.Font.Size := 8;
  scenebufbmppng.Canvas.Font.Color := clyellow;
  scenebufbmppng.PixelFormat := pf32bit;

  sceneopbmp := Tbitmap.Create;
  sceneopbmp.Width := image1.Width;
  sceneopbmp.Height := image1.Height;
  sceneopbmp.Canvas.Brush.Style := bsclear;
  sceneopbmp.Canvas.Font.Size := 8;
  sceneopbmp.Canvas.Font.Color := clyellow;
  sceneopbmp.PixelFormat := pf8bit;
  sceneopbmp.Palette := Palle;
  image1.Canvas.Brush.Style := bsclear;
  scenebufbmp := Tbitmap.Create;
  scenebufbmp.Width := image1.Width;
  scenebufbmp.Height := image1.Height;
  scenebufbmp.Canvas.Brush.Style := bsclear;
  scenebufbmp.PixelFormat := pf8bit;
  scenebufbmp.Palette := Palle;
  scenesmallbmp := Tbitmap.Create;
  scenesmallbmp.Canvas.Brush.Color :=clwhite;//$707030;
  scenesmallbmp.PixelFormat := pf8bit;
  scenesmallbmp.Palette := Palle;
  scenesmallbmp.Canvas.Brush.Color :=clwhite;//$707030;
  scenesmallbmp.Width := 500;
  scenesmallbmp.Height := 500;
  
  if not  (readDAndS(combobox1.ItemIndex) = 1) then
  begin
    showmessage('场景地图编辑器打开失败！场景文件错误或找不到！可能是游戏路径设置问题，或者ini配置问题！');
    self.Close;
    exit;
  end;
  combobox2.Clear;


  for I := 0 to scenemapfile.num - 1 do
    combobox2.Items.Add(CalRname(3,I));
  combobox2.ItemIndex := 0;

    // FreeMem(pLogPalle,PalSize);

  try
  //copyscenemap(@scenemapfile.map[0], @scenemapbackup);
  Readundoini;

  spinedit1.Value := undoAmount - 1;
  setlength(scenemapbackup, undoAmount);
  setlength(scenemapEventbackup, undoAmount);

  initialundomap(@scenemapfile.map[0], @Dfile.mapevent[0],0);
  undotimes := 0;
  undoSavetimes := 1;
 except
   showmessage('场景地图编辑器打开失败！错误！');
   self.Close;
   exit;
 end;

  try
  Radiogroup1.ItemIndex := integer(SceneEditMode);
  self.SetEditMode(SceneEditMode);

  {if not (readscenegrp(gamepath + Smapidx, gamepath + smapgrp) = 1) then
  begin
    showmessage('IDX或GRP文件错误！');
    exit;
  end;}

  if SceneEditMode = RLEMode then
  begin
    displayscenemap(@scenemapfile.map[0], @sceneopbmp);
    scenebufbmp.Canvas.CopyRect(scenebufbmp.Canvas.ClipRect, sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
    image1.Canvas.CopyRect(image1.ClientRect,sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
  end
  else
  begin
    displayscenemap(@scenemapfile.map[0], @sceneopbmppng);
    scenebufbmppng.Canvas.CopyRect(scenebufbmppng.Canvas.ClipRect, sceneopbmppng.Canvas,sceneopbmppng.Canvas.ClipRect);
    image1.Canvas.CopyRect(image1.ClientRect,sceneopbmppng.Canvas,sceneopbmppng.Canvas.ClipRect);
  end;
  //scenebufbmp.Canvas.CopyRect(scenebufbmp.Canvas.ClipRect, sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
  //image1.Canvas.CopyRect(image1.ClientRect,sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
  scenelock := false;
  except
    showmessage('场景地图编辑器打开失败！场景地图数据错误！');
    self.Close;
    exit;
  end;

  ScenemapInitial := true;
end;

procedure TForm12.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if not ScenemapInitial then
    exit;
  if (key = 90) and (ssCtrl in Shift) and not(ssAlt in Shift) and not(ssShift in Shift)  then
  begin
    undo;
    //copyscenemap( @scenemapbackup,@scenemapfile.map[combobox2.ItemIndex]);
    needupdate := true;
  end
  else if (key = 90) and (ssCtrl in Shift) and not(ssAlt in Shift) and (ssShift in Shift) then
  begin
    redo;
    needupdate := true;
  end;
end;

procedure TForm12.Image1DragDrop(Sender, Source: TObject; X, Y: Integer);
begin
  if not ScenemapInitial then
    exit;
  if Scenelayer = 6 then
    exit;

  if IMZDrag then
  begin
    //showmessage('imzdrag');
    if SceneEditMode <> RLEMode then
      nowscenegrpnum := imzdragint;
  end
  else
  begin
    //showmessage('grpdrag');
    if SceneEditMode = RLEMode then
      nowscenegrpnum := movelock;
  end;

  scenecopymapmode := 0;
  self.BringToFront;

end;

procedure TForm12.Image1DragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  //
end;

procedure TForm12.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  ix,iy: integer;
  I,temp,i1,i2: integer;
  canevtnum: boolean;
begin
  if not ScenemapInitial then
    exit;
  if scenelock then
    exit;
  scenelock := true;
  if checkbox1.Checked then
  begin
    if scenelayer = 3 then
    begin
      if scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx] >= 0 then
      begin
        temp := scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx];

       { for ix := 0 to scenemapfile.map[combobox2.ItemIndex].x - 1 do
          for iy := 0 to scenemapfile.map[combobox2.ItemIndex].y - 1 do
            if  scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[iy][ix] > temp then
              dec(scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[iy][ix]);

        for I := 0 to 198 do
          if I > temp then
          begin
            Dfile.mapevent[combobox2.ItemIndex].sceneevent[I - 1] := Dfile.mapevent[combobox2.ItemIndex].sceneevent[I];
            Dfile.mapevent[combobox2.ItemIndex].sceneevent[I - 1].num := I- 1;
          end;}
        Addundosave;
        //copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup);
        scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx] := -1;
        needupdate := true;
        copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup[0]);
        copyscenemapevent(@Dfile.mapevent[combobox2.ItemIndex], @scenemapeventbackup[0]);
     // displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmp);
     // scenebufbmp.Canvas.CopyRect(scenebufbmp.Canvas.ClipRect, sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
      //image1.Canvas.CopyRect(image1.ClientRect,sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
      end;
    end
    else if (scenelayer >= 0) and (scenelayer < 3) then
    begin
      if scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx] > 0 then
      begin
        Addundosave;
        //copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup);
        scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx] := 0;
        needupdate := true;
        Updatesmallimg(image1.Width DIV 2,image1.Height div 2 - 31 * 18, scenetempx, scenetempy);
        copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup[0]);
        copyscenemapevent(@Dfile.mapevent[combobox2.ItemIndex], @scenemapeventbackup[0]);
       // displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmp);
      //  scenebufbmp.Canvas.CopyRect(scenebufbmp.Canvas.ClipRect, sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
       // image1.Canvas.CopyRect(image1.ClientRect,sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
      end;
    end;
  end
  else if scenelayer = 3 then
    begin
      if button = mbleft then
      begin
        if (scenetempx >= 0) and (scenetempx < scenemapfile.map[combobox2.ItemIndex].x) and (scenetempy >=0) and (scenetempy < scenemapfile.map[combobox2.ItemIndex].y) then
          if  scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx] >= 0 then
          begin

            evtx := scenetempx;
            evty := scenetempy;
            edit1.Text := inttostr(Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].canwalk);
            edit2.Text := inttostr(Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].num);
            edit3.Text := inttostr(Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].event1);
            edit4.Text := inttostr(Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].event2);
            edit5.Text := inttostr(Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].event3);
            edit6.Text := inttostr(Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].beginpic1);
            edit7.Text := inttostr(Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].endpic);
            edit8.Text := inttostr(Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].beginpic2);
            edit9.Text := inttostr(Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].picdelay);
            edit10.Text := inttostr(Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].xpos);
            edit11.Text := inttostr(Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].ypos);
          end;
      end
      else if button = mbright then
      begin
        if (scenetempx >= 0) and (scenetempx < scenemapfile.map[combobox2.ItemIndex].x) and (scenetempy >=0) and (scenetempy < scenemapfile.map[combobox2.ItemIndex].y) then
        begin
          if (scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx] < 0) then
          begin
            //canevtnum := true;
            for I1 := 0 to 200 - 1 do
            begin
              canevtnum := true;
              for ix := 0 to scenemapfile.map[combobox2.ItemIndex].x - 1 do
                for iy := 0 to scenemapfile.map[combobox2.ItemIndex].y - 1 do
                  if scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[iy][ix] = i1 then
                    canevtnum := false;
              if canevtnum then
                break;
            end;
            if canevtnum then
              evtnum := i1
            else
              evtnum := -1;
          if evtnum <> -1 then
            Addundosave;
            //copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup);
          scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx] := evtnum;
          Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].ypos := scenetempy;
          Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].xpos := scenetempx;
          Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].event1 := -1;
          Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].event2 := -1;
          Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].event3 := -1;
          Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].beginpic1 := 0;
          Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].endpic := 0;
          Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].beginpic2 := 0;
          Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].picdelay := 0;
          Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]].num := evtnum;
        //  displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmp);
         // scenebufbmp.Canvas.CopyRect(scenebufbmp.Canvas.ClipRect, sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
        //  image1.Canvas.CopyRect(image1.ClientRect,sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
          needupdate := true;
          copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup[0]);
          copyscenemapevent(@Dfile.mapevent[combobox2.ItemIndex], @scenemapeventbackup[0]);
          end;
        end;
      end;
  end
  else if scenelayer = 4 then
  begin
      highselect:= false;
      highendx:= -1;
      highendy:= -1;
      scenestill := 1;
      scenestillx := scenetempx;
      scenestilly := scenetempy;

  end
  else if scenelayer = 5 then
  begin
    highselect:= false;
    highendx:= -1;
    highendy:= -1;
    scenestill := 1;
    scenestillx := scenetempx;
    scenestilly := scenetempy;
    
  end
  else
  begin
    if button = mbright then
    begin
      if (scenetempx >= 0) and (scenetempx < scenemapfile.map[combobox2.ItemIndex].x) and (scenetempy >=0) and (scenetempy < scenemapfile.map[combobox2.ItemIndex].y) then
      begin

        if scenelayer = 6 then
        begin
          Addundosave;
          //copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup);
          for I := 0 to 2 do
            for Ix := 0 to scenecopymap.x - 1 do
              for iy := 0 to scenecopymap.y - 1 do
                if (scenetempx - ix >= 0) and (scenetempx-ix < scenemapfile.map[combobox2.ItemIndex].x) and (scenetempy-iy >=0) and (-iy + scenetempy < scenemapfile.map[combobox2.ItemIndex].y) then
                  scenemapfile.map[combobox2.ItemIndex].maplayer[I].pic[scenetempy - iy][scenetempx - ix] := scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1];
          for I := 4 to 5 do
            for Ix := 0 to scenecopymap.x - 1 do
              for iy := 0 to scenecopymap.y - 1 do
                if (scenetempx - ix >= 0) and (scenetempx-ix < scenemapfile.map[combobox2.ItemIndex].x) and (scenetempy-iy >=0) and (-iy + scenetempy < scenemapfile.map[combobox2.ItemIndex].y) then
                  scenemapfile.map[combobox2.ItemIndex].maplayer[I].pic[scenetempy - iy][scenetempx - ix] := scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1];
          needupdate := true;
          Updatesmallimg(image1.Width DIV 2,image1.Height div 2 - 31 * 18, scenetempx, scenetempy);
          copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup[0]);
          copyscenemapevent(@Dfile.mapevent[combobox2.ItemIndex], @scenemapeventbackup[0]);
        end
        else if (scenelayer >= 0) and (nowscenegrpnum >= 0) then
        begin
          Addundosave;
          //copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup);
          scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx] := 2 * nowscenegrpnum;
          needupdate := true;
          //displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmp);
          //waropbmp.PixelFormat := pf32bit;
          //warbufbmp.PixelFormat := pf32bit;
          //scenebufbmp.Canvas.CopyRect(scenebufbmp.Canvas.ClipRect, sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
          //image1.Canvas.CopyRect(image1.ClientRect,sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
          Updatesmallimg(image1.Width DIV 2,image1.Height div 2 - 31 * 18, scenetempx, scenetempy);
          copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup[0]);
          copyscenemapevent(@Dfile.mapevent[combobox2.ItemIndex], @scenemapeventbackup[0]);
        end
        else if (scenelayer >= 0) and (scenecopymapmode = 1) then
        begin
          Addundosave;
          //copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup);
          for Ix := 0 to scenecopymap.x - 1 do
            for iy := 0 to scenecopymap.y - 1 do
              if (scenetempx - ix >= 0) and (scenetempx-ix < scenemapfile.map[combobox2.ItemIndex].x) and (scenetempy-iy >=0) and (-iy + scenetempy < scenemapfile.map[combobox2.ItemIndex].y) then
                scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy - iy][scenetempx - ix] := scenecopymap.maplayer[scenelayer].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1];
          needupdate := true;
          Updatesmallimg(image1.Width DIV 2,image1.Height div 2 - 31 * 18, scenetempx, scenetempy);
          copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup[0]);
          copyscenemapevent(@Dfile.mapevent[combobox2.ItemIndex], @scenemapeventbackup[0]);
          //displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmp);
          //waropbmp.PixelFormat := pf32bit;
          //warbufbmp.PixelFormat := pf32bit;
          //scenebufbmp.Canvas.CopyRect(scenebufbmp.Canvas.ClipRect, sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
          //image1.Canvas.CopyRect(image1.ClientRect,sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
        end;
      end;
    end
    else if (button = mbleft) and (scenetempx >= 0) and (scenetempx < scenemapfile.map[combobox2.ItemIndex].x) and (scenetempy >=0) and (scenetempy < scenemapfile.map[combobox2.ItemIndex].y) then
    begin
      scenestill := 1;
      scenestillx := scenetempx;
      scenestilly := scenetempy;
      needupdate := true;
    end;
  end;


  scenelock := false;
end;

procedure TForm12.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  mousex := x;
  mousey := y;
end;

procedure TForm12.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  lx,ly,sx,sy, temp,I,Ix,Iy: integer;
begin
  if not ScenemapInitial then
    exit;
  if scenelock then
    exit;
  scenelock := true;
  if not checkbox1.Checked then
  begin
  if ((scenelayer < 3) and (scenelayer >= 0)) or (scenelayer = 6) then
  begin
  if button = mbleft then
  begin
    scenestill := 0;
    if SceneEditMode = RLEMode then
      scenebufbmp.Canvas.CopyRect(scenebufbmp.Canvas.ClipRect, sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect)
    else
      scenebufbmppng.Canvas.CopyRect(scenebufbmppng.Canvas.ClipRect, sceneopbmppng.Canvas,sceneopbmppng.Canvas.ClipRect);

    if (scenelayer <> 6) and (scenestillx = scenetempx) and (scenestilly = scenetempy) then
    begin
      if (scenetempx >= 0) and (scenetempx < scenemapfile.map[combobox2.ItemIndex].x) and (scenetempy >=0) and (scenetempy < scenemapfile.map[combobox2.ItemIndex].y) then
      begin
        if (scenelayer >= 0) then
        begin
          nowscenegrpnum := scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx] div 2;
          scenecopymapmode := 0;
        end;
      end;
    end
    else
    begin
      if scenelayer >= 0 then
      begin
         lx := scenetempx;
         ly := scenetempy;
      if (scenetempx >= scenemapfile.map[combobox2.ItemIndex].x)  then
        lx := scenemapfile.map[combobox2.ItemIndex].x - 1
      else if (scenetempx < 0) then
        lx := 0;
      if (scenetempy >= scenemapfile.map[combobox2.ItemIndex].y)  then
        ly := scenemapfile.map[combobox2.ItemIndex].y - 1
      else if (scenetempy < 0) then
        ly := 0;
      if (scenestillx >= 0) and (scenestillx < scenemapfile.map[combobox2.ItemIndex].x) and (scenestilly >=0) and (scenestilly < scenemapfile.map[combobox2.ItemIndex].y) then
      begin
       // if (lx <> scenestillx) or (ly <> scenestilly) then
        //begin
          sx := scenestillx;
          sy := scenestilly;
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

          scenecopymapmode := 1;
          nowscenegrpnum := -1;
          scenecopymap.layernum := scenemapfile.map[combobox2.ItemIndex].layernum;
          scenecopymap.x := lx - sx + 1;
          scenecopymap.y := ly - sy + 1;
          setlength(scenecopymap.maplayer, scenecopymap.layernum);

          for I := 0 to scenecopymap.layernum - 1 do
          begin
            setlength(scenecopymap.maplayer[I].pic,scenecopymap.y,scenecopymap.x);
            for ix := sx to lx do
              for iy := sy to ly do
              begin
                scenecopymap.maplayer[I].pic[iy - sy][ix- sx] := scenemapfile.map[combobox2.ItemIndex].maplayer[I].pic[iy][ix];
              end;

          end;

          //setlength(warcopymap.x)

        end;
        end;
      //end;
    end;
  end;
  end
  else if (scenelayer <= 5) and (scenelayer >= 4) then
  begin
    scenestill := 0;

    if (scenetempx = scenestillx) and (scenetempy = scenestilly) then
    begin
      if (scenetempx >= 0) and (scenetempx < scenemapfile.map[combobox2.ItemIndex].x) and (scenetempy >=0) and (scenetempy < scenemapfile.map[combobox2.ItemIndex].y) then
      begin
        Addundosave;
        //copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup);
        if button = mbright then
          dec(scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx])
        else if button = mbleft then
          inc(scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]);
        edit12.Text := inttostr(scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenetempy][scenetempx]);
        needupdate := true;
        copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup[0]);
        copyscenemapevent(@Dfile.mapevent[combobox2.ItemIndex], @scenemapeventbackup[0]);
      end;
    end
    else
    begin
      highendx := scenetempx;
      highendy := scenetempy;
      if (scenetempx >= scenemapfile.map[combobox2.ItemIndex].x)  then
        highendx := scenemapfile.map[combobox2.ItemIndex].x - 1
      else if (scenetempx < 0) then
        highendx := 0;
      if (scenetempy >= scenemapfile.map[combobox2.ItemIndex].y)  then
        highendy := scenemapfile.map[combobox2.ItemIndex].y - 1
      else if (scenetempy < 0) then
        highendy := 0;
      highselect := true;
    end;
                                      
  end;
  end;
  scenelock := false;
end;

procedure TForm12.SpinEdit1Change(Sender: TObject);
var
  lastcount: integer;
begin
  lastcount := undoAmount;
  if spinedit1.Value > spinedit1.MaxValue then
    spinedit1.Value := spinedit1.MaxValue
  else if spinedit1.Value < spinedit1.MinValue then
    spinedit1.Value := spinedit1.MinValue;
  undoAmount := spinedit1.Value + 1;
  if undosavetimes > undoAmount then
    undosavetimes := undoAmount;
  //undoAmount := spinedit1.Value;
  writeundoini;
  setlength(scenemapbackup, spinedit1.Value + 1);
  setlength(scenemapeventbackup, spinedit1.Value + 1);
  initialundomap(@(scenemapfile.map[combobox2.ItemIndex]), @(Dfile.mapevent[combobox2.ItemIndex]),lastcount);
end;

procedure TForm12.Updatesmallimg(pointx,pointy, axp, ayp: integer);
begin

    if (scenetempx >= 0) and (scenetempy >= 0) and (scenetempx < scenemapfile.map[combobox2.ItemIndex].x) and (scenetempy < scenemapfile.map[combobox2.ItemIndex].y) then
    begin
      label18.Caption := inttostr(scenemapfile.map[combobox2.ItemIndex].maplayer[0].pic[scenetempy][scenetempx] div 2);
      label19.Caption := inttostr(scenemapfile.map[combobox2.ItemIndex].maplayer[1].pic[scenetempy][scenetempx] div 2);
      label20.Caption := inttostr(scenemapfile.map[combobox2.ItemIndex].maplayer[2].pic[scenetempy][scenetempx] div 2);
      if scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx] >= 0 then
        label21.Caption := inttostr(Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx]].beginpic1 div 2)
      else
        label21.Caption := '-1';
    end;

    image2.Canvas.Brush.Color :=clwhite;//$606060;
    image2.Canvas.FillRect(image2.Canvas.ClipRect);
    image3.Canvas.Brush.Color := clwhite;//$606060;
    image3.Canvas.FillRect(image3.Canvas.ClipRect);
    image4.Canvas.Brush.Color := clwhite;//$606060;
    image4.Canvas.FillRect(image4.Canvas.ClipRect);
    image5.Canvas.Brush.Color := clwhite;//$606060;
    image5.Canvas.FillRect(image5.Canvas.ClipRect);

    eventpictime := 0;

    if (scenetempx >= 0) and (scenetempx < scenemapfile.map[combobox2.ItemIndex].x) and (scenetempy >=0) and (scenetempy < scenemapfile.map[combobox2.ItemIndex].y) then
    begin
      scenesmallbmp.Canvas.Brush.Color :=clwhite;//$606060;
      scenesmallbmp.Canvas.FillRect(scenesmallbmp.Canvas.ClipRect);
      if scenemapfile.map[combobox2.ItemIndex].maplayer[0].pic[scenetempy][scenetempx] >= 0 then
      begin
       // scenesmallbmp.Width := image2.Width;
       // scenesmallbmp.Height := image2.Height;
        case SceneEditMode of
          RLEMode:
            begin
              if (scenemapfile.map[combobox2.ItemIndex].maplayer[0].pic[scenetempy][scenetempx] div 2 < scenegrpnum)
              and (scenemapfile.map[combobox2.ItemIndex].maplayer[0].pic[scenetempy][scenetempx] div 2 >= 0)
              and (scenegrp[scenemapfile.map[combobox2.ItemIndex].maplayer[0].pic[scenetempy][scenetempx] div 2].size >= 8) then
              begin
                McoldrawRLE8(@scenegrp[scenemapfile.map[combobox2.ItemIndex].maplayer[0].pic[scenetempy][scenetempx] div 2].data[0],scenegrp[scenemapfile.map[combobox2.ItemIndex].maplayer[0].pic[scenetempy][scenetempx] div 2].size,@scenesmallbmp, 0,0, false);
                image2.Canvas.CopyRect(image2.Canvas.ClipRect,scenesmallbmp.Canvas,image2.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              imzFile.DrawImztocanvas(image2.Canvas, @imzFIle.imzFile, scenemapfile.map[combobox2.ItemIndex].maplayer[0].pic[scenetempy][scenetempx] div 2, 0, 0, 0);
            end;
        end;
      end;
      scenesmallbmp.Canvas.Brush.Color :=clwhite;//$606060;
      scenesmallbmp.Canvas.FillRect(scenesmallbmp.Canvas.ClipRect);
      if scenemapfile.map[combobox2.ItemIndex].maplayer[1].pic[scenetempy][scenetempx] > 0 then
      begin
       // scenesmallbmp.Width := image3.Width;
        //scenesmallbmp.Height := image3.Height;
        case SceneEditMode of
          RLEMode:
            begin
              if (scenemapfile.map[combobox2.ItemIndex].maplayer[1].pic[scenetempy][scenetempx] div 2 < scenegrpnum)
              and (scenemapfile.map[combobox2.ItemIndex].maplayer[1].pic[scenetempy][scenetempx] div 2 >= 0)
              and (scenegrp[scenemapfile.map[combobox2.ItemIndex].maplayer[1].pic[scenetempy][scenetempx] div 2].size >= 8) then
              begin
                McoldrawRLE8(@scenegrp[scenemapfile.map[combobox2.ItemIndex].maplayer[1].pic[scenetempy][scenetempx] div 2].data[0],scenegrp[scenemapfile.map[combobox2.ItemIndex].maplayer[1].pic[scenetempy][scenetempx] div 2].size,@scenesmallbmp, 0,0, false);
                image3.Canvas.CopyRect(image3.Canvas.ClipRect,scenesmallbmp.Canvas,image3.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              imzFile.DrawImztocanvas(image3.Canvas, @imzFIle.imzFile, scenemapfile.map[combobox2.ItemIndex].maplayer[1].pic[scenetempy][scenetempx] div 2, 0, 0, 0);
            end;
        end;
        //McoldrawRLE8(@scenegrp[scenemapfile.map[combobox2.ItemIndex].maplayer[1].pic[scenetempy][scenetempx] div 2].data[0],scenegrp[scenemapfile.map[combobox2.ItemIndex].maplayer[1].pic[scenetempy][scenetempx] div 2].size,@scenesmallbmp, 0,0, false);
        //image3.Canvas.CopyRect(image3.Canvas.ClipRect,scenesmallbmp.Canvas,image3.Canvas.ClipRect);
      end;
      scenesmallbmp.Canvas.Brush.Color :=clwhite;//$606060;
      scenesmallbmp.Canvas.FillRect(scenesmallbmp.Canvas.ClipRect);
      if scenemapfile.map[combobox2.ItemIndex].maplayer[2].pic[scenetempy][scenetempx] > 0 then
      begin
        //scenesmallbmp.Width := image4.Width;
        //scenesmallbmp.Height := image4.Height;
        case SceneEditMode of
          RLEMode:
            begin
              if (scenemapfile.map[combobox2.ItemIndex].maplayer[2].pic[scenetempy][scenetempx] div 2 < scenegrpnum)
              and (scenemapfile.map[combobox2.ItemIndex].maplayer[2].pic[scenetempy][scenetempx] div 2 >= 0)
              and (scenegrp[scenemapfile.map[combobox2.ItemIndex].maplayer[2].pic[scenetempy][scenetempx] div 2].size >= 8) then
              begin
                McoldrawRLE8(@scenegrp[scenemapfile.map[combobox2.ItemIndex].maplayer[2].pic[scenetempy][scenetempx] div 2].data[0],scenegrp[scenemapfile.map[combobox2.ItemIndex].maplayer[2].pic[scenetempy][scenetempx] div 2].size,@scenesmallbmp, 0,0, false);
                image4.Canvas.CopyRect(image4.Canvas.ClipRect,scenesmallbmp.Canvas,image4.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              imzFile.DrawImztocanvas(image4.Canvas, @imzFIle.imzFile, scenemapfile.map[combobox2.ItemIndex].maplayer[2].pic[scenetempy][scenetempx] div 2, 0, 0, 0);
            end;
        end;

        //McoldrawRLE8(@scenegrp[scenemapfile.map[combobox2.ItemIndex].maplayer[2].pic[scenetempy][scenetempx] div 2].data[0],scenegrp[scenemapfile.map[combobox2.ItemIndex].maplayer[2].pic[scenetempy][scenetempx] div 2].size,@scenesmallbmp, 0,0, false);
        //image4.Canvas.CopyRect(image4.Canvas.ClipRect,scenesmallbmp.Canvas,image4.Canvas.ClipRect);

      end;
      scenesmallbmp.Canvas.Brush.Color :=clwhite;//$606060;
      scenesmallbmp.Canvas.FillRect(scenesmallbmp.Canvas.ClipRect);
      if scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx] >= 0 then
      begin
       // scenesmallbmp.Width := image5.Width;
       // scenesmallbmp.Height := image5.Height;
       case SceneEditMode of
          RLEMode:
            begin
              if (scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx] >= 0)
              and (scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx] < length(Dfile.mapevent[combobox2.ItemIndex].sceneevent))
              and (Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx]].beginpic1 div 2 < scenegrpnum)
              and (Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx]].beginpic1 div 2 >= 0)
              and (scenegrp[Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx]].beginpic1 div 2].size >= 8) then
              begin
                McoldrawRLE8(@scenegrp[Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx]].beginpic1 div 2].data[0],scenegrp[Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx]].beginpic1 div 2].size,@scenesmallbmp, 0,0, false);
                image5.Canvas.CopyRect(image5.Canvas.ClipRect,scenesmallbmp.Canvas,image5.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              imzFile.DrawImztocanvas(image5.Canvas, @imzFIle.imzFile, scenemapfile.map[combobox2.ItemIndex].maplayer[0].pic[scenetempy][scenetempx] div 2, 0, 0, 0);
            end;
        end;
        //McoldrawRLE8(@scenegrp[Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx]].beginpic1 div 2].data[0],scenegrp[Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx]].beginpic1 div 2].size,@scenesmallbmp, 0,0, false);
        //image5.Canvas.CopyRect(image5.Canvas.ClipRect,scenesmallbmp.Canvas,image5.Canvas.ClipRect);
      end;
    end;
end;

procedure TForm12.Timer1Timer(Sender: TObject);
var
  axp,ayp: integer;
  pointx,pointy,posx,posy,ix,iy, I: integer;
begin
  if not ScenemapInitial then
    exit;
  if not scenelock then
  begin
  pointx := image1.Width DIV 2;
  pointy := image1.Height div 2 - 31 * 18;
  //Axp := ((mousex - pointx) div 18 + (mouseY - pointy div 2 + 9) div 9) div 2;
  //Ayp := -((mousex - pointx) div 18 - (mouseY - pointy div 2 + 9) div 9) div 2;
  Axp := Round(((mousex - pointx) / 18 + (mouseY - pointy + 9) / 9) / 2);
  Ayp := Round(-((mousex - pointx) / 18 - (mouseY - pointy + 9) / 9) / 2);
  candraw := false;



  if (axp <> scenetempx) or (ayp <> scenetempy) then
  begin
    candraw := true;
    scenetempx := axp;
    scenetempy := ayp;
  end;
  if needupdate then
  begin
    needupdate := false;
    //Sceneopbmp.Canvas.Lock;
    if SceneEditMode = RLEMode then
    begin
      displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmp);
      scenebufbmp.Canvas.CopyRect(scenebufbmp.Canvas.ClipRect, sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
    end
    else
    begin
      displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmppng);
      scenebufbmppng.Canvas.CopyRect(scenebufbmppng.Canvas.ClipRect, sceneopbmppng.Canvas,sceneopbmppng.Canvas.ClipRect);
    end;
    //Sceneopbmp.Canvas.UnLock;


    if (scenelayer >=4) and (scenelayer <= 5) and (scenestill = 0) then
    begin
      if highselect then
      begin
        if (highendx <> scenestillx) or (highendy <> scenestilly) then
        begin
          if highendx < scenestillx then
          begin
            if highendy < scenestilly then
              for ix := highendx to scenestillx do
                for iy := highendy to scenestilly do
                begin
                  posx := ix * 18 - Iy * 18  + pointx;
                  posy := ix * 9 + Iy * 9 + pointy;
                  drawsquare(posx,posy);
                end
            else
            begin
              for ix := highendx to scenestillx do
                for iy := highendy downto scenestilly do
                begin
                  posx := ix * 18 - Iy * 18  + pointx;
                  posy := ix * 9 + Iy * 9 + pointy;
                  drawsquare(posx,posy);
                end;
            end;
          end
          else
          begin
            if highendy < scenestilly then
              for ix := highendx downto scenestillx do
                for iy := highendy to scenestilly do
                begin
                  posx := ix * 18 - Iy * 18  + pointx;
                  posy := ix * 9 + Iy * 9 + pointy;
                  drawsquare(posx,posy);
                end
            else
              for ix := highendx downto scenestillx do
                for iy := highendy downto scenestilly do
                begin
                  posx := ix * 18 - Iy * 18  + pointx;
                  posy := ix * 9 + Iy * 9 + pointy;
                  drawsquare(posx,posy);
                end;
          end;
        end;

      end;
    end;
    if SceneEditMOde = RLEMode then
      image1.Canvas.CopyRect(image1.ClientRect,scenebufbmp.Canvas,scenebufbmp.Canvas.ClipRect)
    else
      image1.Canvas.CopyRect(image1.ClientRect,scenebufbmppng.Canvas,scenebufbmppng.Canvas.ClipRect);
  end;
  if candraw then
  begin
    pointx := image1.Width DIV 2;
    pointy := image1.Height div 2 - 31 * 18;
    statusbar1.Canvas.Brush.Color := clbtnface;
    statusbar1.Canvas.FillRect(statusbar1.Canvas.ClipRect);
    statusbar1.Repaint;
    statusbar1.Canvas.TextOut(10,10,'X='+inttostr(axp) + ',Y='+inttostr(ayp));
    if SceneEditMode = RLEMode then
      scenebufbmp.Canvas.CopyRect(scenebufbmp.Canvas.ClipRect, sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect)
    else
      scenebufbmpPNG.Canvas.CopyRect(scenebufbmpPNG.Canvas.ClipRect, sceneopbmpPNG.Canvas, sceneopbmpPNG.Canvas.ClipRect);

    Updatesmallimg(pointx,pointy, axp, ayp);

    if ((scenelayer >= 0) and (scenelayer < 3)) or ((scenelayer >= 4) and (scenelayer <= 5)) then
    begin
    if (scenestill = 1) then
    begin
      if (scenetempx <> scenestillx) or (scenetempy <> scenestilly) then
      begin
        if scenetempx < scenestillx then
        begin
          if scenetempy < scenestilly then
            for ix := scenetempx to scenestillx do
              for iy := scenetempy to scenestilly do
              begin
                posx := ix * 18 - Iy * 18  + pointx;
                posy := ix * 9 + Iy * 9 + pointy;
                drawsquare(posx,posy);
              end
          else
          begin
            for ix := scenetempx to scenestillx do
              for iy := scenetempy downto scenestilly do
              begin
                posx := ix * 18 - Iy * 18  + pointx;
                posy := ix * 9 + Iy * 9 + pointy;
                drawsquare(posx,posy);
              end;
          end;
        end
        else
        begin
          if scenetempy < scenestilly then
            for ix := scenetempx downto scenestillx do
              for iy := scenetempy to scenestilly do
              begin
                posx := ix * 18 - Iy * 18  + pointx;
                posy := ix * 9 + Iy * 9 + pointy;
                drawsquare(posx,posy);
              end
          else
            for ix := scenetempx downto scenestillx do
              for iy := scenetempy downto scenestilly do
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
      if not checkbox1.Checked then
      begin
      if ((nowscenegrpnum > 0) and (scenelayer <> 6) and (scenelayer <> 5) and (scenelayer <> 4)) or ((nowscenegrpnum >= 0) and (scenelayer = 0))  then
      begin
        posx := axp * 18 - ayp * 18  + pointx;
        posy := axp * 9 + ayp * 9 + pointy;
        case SceneEditMode of
          RLEMode:
            begin
              if (nowscenegrpnum >= 0) and (nowscenegrpnum < scenegrpnum) and (scenegrp[nowscenegrpnum].size >= 8) then
                McoldrawRLE8(@scenegrp[nowscenegrpnum].data[0],scenegrp[nowscenegrpnum].size,@scenebufbmp, posx,posy, true);
            end;
          IMZMode, PNGMode:
            begin
              imzFile.DrawImztocanvasEx(scenebufbmpPNG.Canvas, @imzFIle.imzFile, nowscenegrpnum, 0, posx, posy);
              //ImzFile.SceneQuickDraw(@scenebufbmp, nowscenegrpnum, posx, posy);
            end;
        end;
      end
      else if (scenecopymapmode = 1) and (scenelayer >= 0) and (scenelayer <> 6) and (scenelayer <> 5) and (scenelayer <> 4) then
      begin
        if SceneEditMode <> RLEMode then
          for I := 0 to ScenePNGbuf.Height - 1 do
            copymemory(@ScenePNGbuf.data[I][0], scenebufbmpPNG.ScanLine[I], ScenePNGbuf.width * 4);
         for Ix := scenecopymap.x - 1 downto 0 do
           for iy := scenecopymap.y - 1 downto 0 do
             if (scenecopymap.maplayer[scenelayer].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] > 0) or ((scenecopymap.maplayer[scenelayer].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] = 0) and (scenelayer = 0)) then
             begin
               posx := (scenetempx - ix) * 18 - (scenetempy - iy) * 18  + pointx;
               posy := (scenetempx - ix) * 9 + (scenetempy - Iy) * 9 + pointy;
               //McoldrawRLE8(@scenegrp[scenecopymap.maplayer[scenelayer].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].data[0],scenegrp[scenecopymap.maplayer[scenelayer].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].size,@scenebufbmp, posx,posy, true);
               case SceneEditMode of
                 RLEMode:
                   begin
                     if (scenecopymap.maplayer[scenelayer].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2 >= 0)
                     and (scenecopymap.maplayer[scenelayer].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2 < scenegrpnum)
                     and (scenegrp[scenecopymap.maplayer[scenelayer].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].size >= 8)
                     then
                       McoldrawRLE8(@scenegrp[scenecopymap.maplayer[scenelayer].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].data[0],scenegrp[scenecopymap.maplayer[scenelayer].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].size,@scenebufbmp, posx,posy, true);
                   end;
                 IMZMode, PNGMode:
                   begin
                    //imzFile.DrawImztocanvasEx(image2.Canvas, @imzFIle.imzFile, nowscenegrpnum, 0, posx,posy);
                    //ImzFile.SceneQuickDraw(@scenebufbmpPNG, scenecopymap.maplayer[scenelayer].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2, posx, posy);
                     ImzFile.SceneQuickDrawBuf(@scenePNGbuf, scenecopymap.maplayer[scenelayer].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2, posx, posy);
                   end;
               end;
             end;
             //if (ix + scenetempx >= 0) and (ix + scenetempx < warmapfile.map[combobox1.ItemIndex].x) and (iy + wartempy >=0) and (iy + wartempy < warmapfile.map[combobox1.ItemIndex].y) then
              //warmapfile.map[combobox1.ItemIndex].maplayer[warlayer].pic[wartempy + iy][wartempx + ix] := warcopymap.maplayer[warlayer].pic[iy][ix];
        if SceneEditMode <> RLEMode then
          for I := 0 to ScenePNGbuf.Height - 1 do
            copymemory(scenebufbmpPNG.ScanLine[I], @ScenePNGbuf.data[I][0], ScenePNGbuf.width * 4);

      end;

      end;
    end;
    end
    else if (scenelayer = 6) then
    begin
      if scenestill = 1 then
      begin
        if scenetempx <= scenestillx then
        begin
          if scenetempy <= scenestilly then
            for ix := scenetempx to scenestillx do
              for iy := scenetempy to scenestilly do
              begin
                posx := ix * 18 - Iy * 18  + pointx;
                posy := ix * 9 + Iy * 9 + pointy;
                drawsquare(posx,posy);
              end
          else
          begin
            for ix := scenetempx to scenestillx do
              for iy := scenetempy downto scenestilly do
              begin
                posx := ix * 18 - Iy * 18  + pointx;
                posy := ix * 9 + Iy * 9 + pointy;
                drawsquare(posx,posy);
              end;
          end;
        end
        else
        begin
          if scenetempy <= scenestilly then
            for ix := scenetempx downto scenestillx do
              for iy := scenetempy to scenestilly do
              begin
                posx := ix * 18 - Iy * 18  + pointx;
                posy := ix * 9 + Iy * 9 + pointy;
                drawsquare(posx,posy);
              end
          else
            for ix := scenetempx downto scenestillx do
              for iy := scenetempy downto scenestilly do
              begin
                posx := ix * 18 - Iy * 18  + pointx;
                posy := ix * 9 + Iy * 9 + pointy;
                drawsquare(posx,posy);
              end;
        end;
      end
      else if scenestill = 0 then
      begin
        for I := 0 to 2 do
          for Ix := scenecopymap.x - 1 downto 0 do
             for iy := scenecopymap.y - 1 downto 0 do
               if (scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] > 0) or ((scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] = 0) and (I = 0)) then
               begin
                 posx := (scenetempx - ix) * 18 - (scenetempy - iy) * 18  + pointx;
                 posy := (scenetempx - ix) * 9 + (scenetempy - Iy) * 9 + pointy;
                 if I = 1 then
                   posy := posy - scenecopymap.maplayer[4].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1]
                 else if I = 2 then
                   posy := posy - scenecopymap.maplayer[5].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1];
                 //McoldrawRLE8(@scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].data[0],scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].size,@scenebufbmp, posx,posy, true);
                 case SceneEditMode of
                   RLEMode:
                     begin
                       if (scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2 >= 0)
                       and (scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2 < scenegrpnum)
                       and (scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].size >= 8)
                       then
                         McoldrawRLE8(@scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].data[0],scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].size,@scenebufbmp, posx,posy, true);
                     end;
                   IMZMode, PNGMode:
                     begin
                      //imzFile.DrawImztocanvasEx(image2.Canvas, @imzFIle.imzFile, nowscenegrpnum, 0, posx,posy);
                      ImzFile.SceneQuickDraw(@scenebufbmpPNG, scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2, posx, posy);
                     end;
                 end;
               end;
      end;
    end;


    if (scenelayer >=4) and (scenelayer <= 5) and (scenestill = 0) then
    begin
      if highselect then
      begin

        if (highendx <> scenestillx) or (highendy <> scenestilly) then
        begin
          if highendx < scenestillx then
          begin
            if highendy < scenestilly then
              for ix := highendx to scenestillx do
                for iy := highendy to scenestilly do
                begin
                  posx := ix * 18 - Iy * 18  + pointx;
                  posy := ix * 9 + Iy * 9 + pointy;
                  drawsquare(posx,posy);
                end
            else
            begin
              for ix := highendx to scenestillx do
                for iy := highendy downto scenestilly do
                begin
                  posx := ix * 18 - Iy * 18  + pointx;
                  posy := ix * 9 + Iy * 9 + pointy;
                  drawsquare(posx,posy);
                end;
            end;
          end
          else
          begin
            if highendy < scenestilly then
              for ix := highendx downto scenestillx do
                for iy := highendy to scenestilly do
                begin
                  posx := ix * 18 - Iy * 18  + pointx;
                  posy := ix * 9 + Iy * 9 + pointy;
                  drawsquare(posx,posy);
                end
            else
              for ix := highendx downto scenestillx do
                for iy := highendy downto scenestilly do
                begin
                  posx := ix * 18 - Iy * 18  + pointx;
                  posy := ix * 9 + Iy * 9 + pointy;
                  drawsquare(posx,posy);
                end;
          end;
        end;

      end;
    end;

    if SceneEditMOde = RLEMode then
      image1.Canvas.CopyRect(image1.ClientRect,scenebufbmp.Canvas,scenebufbmp.Canvas.ClipRect)
    else
      image1.Canvas.CopyRect(image1.ClientRect,scenebufbmppng.Canvas,scenebufbmppng.Canvas.ClipRect);
  end;
  end;
end;

procedure TForm12.Timer2Timer(Sender: TObject);
var
  tempint: integer;
begin
  if not ScenemapInitial then
    exit;
  //事件层动作动画更新
  try

    if scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx] >= 0 then
    begin
       // scenesmallbmp.Width := image5.Width;
       // scenesmallbmp.Height := image5.Height;
      if Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx]].beginpic1 < Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx]].endpic then
      begin
        inc(eventpictime);
        tempint := Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx]].beginpic1 div 2 + eventpictime;
        if tempint > Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx]].endpic div 2 then
        begin
          tempint := Dfile.mapevent[combobox2.ItemIndex].sceneevent[scenemapfile.map[combobox2.ItemIndex].maplayer[3].pic[scenetempy][scenetempx]].beginpic1 div 2;
          eventpictime := 0;
        end;
        label21.Caption := inttostr(tempint);
        scenesmallbmp.Canvas.Brush.Color :=clwhite;//$606060;
        scenesmallbmp.Canvas.FillRect(scenesmallbmp.Canvas.ClipRect);

        //McoldrawRLE8(@scenegrp[tempint].data[0],scenegrp[tempint].size,@scenesmallbmp, 0,0, false);
        case SceneEditMode of
          RLEMode:
            begin
              if (tempint >= 0) and (tempint < scenegrpnum) and (scenegrp[tempint].size >= 8) then
              begin
                McoldrawRLE8(@scenegrp[tempint].data[0],scenegrp[tempint].size,@scenesmallbmp, 0,0, false);
                image5.Canvas.CopyRect(image5.Canvas.ClipRect,scenesmallbmp.Canvas,image5.Canvas.ClipRect);
              end;
            end;
          IMZMode, PNGMode:
            begin
              imzFile.DrawImztocanvasEx(image5.Canvas, @imzFIle.imzFile, tempint, 0, 0, 0);
              //ImzFile.SceneQuickDraw(@scenebufbmp, scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2, posx, posy);
            end;
        end;


      end;
    end;
  except

  end;
end;

function readscenegrp(idx,grp: string): integer;
var
  Fidx, Fgrp, I, Flen, temp: integer;
  offset: array of integer;
begin
  result := 1;
  if not (fileexists(idx) and fileexists(grp)) then
  begin
    result := 0;
    exit;
  end;
  try
  Fidx := fileopen(idx, fmopenread);
  Fgrp := fileopen(grp, fmopenread);
  temp := fileseek(Fidx,0,2);
  scenegrpnum := temp div 4;
  setlength(scenegrp, temp div 4);
  setlength(offset, temp div 4 + 1);
  fileseek(Fidx,0,0);
  fileread(Fidx, offset[1], temp);
  offset[0] := 0;
  fileseek(Fgrp,0,0);
  for I := 0 to (temp div 4) - 1 do
  begin
    scenegrp[I].size := offset[I + 1]- offset[I];
    if scenegrp[I].size > 0 then
    begin
      setlength(scenegrp[I].data, scenegrp[I].size);
      fileread(Fgrp, scenegrp[I].data[0], scenegrp[I].size);
    end
    else
    begin
      scenegrp[I].size := 0;
      setlength(scenegrp[I].data, scenegrp[I].size);
    end;
  end;
  fileclose(Fidx);
  fileclose(Fgrp);
  except
    fileclose(Fidx);
    fileclose(Fgrp);
    result := 0;
  end;
end;

procedure TForm12.Button2Click(Sender: TObject);
begin
  if ((evtx >= 0) and (evty >=0) and (evtx < scenemapfile.map[combobox2.ItemIndex].x)and (evty < scenemapfile.map[combobox2.ItemIndex].y)) or ((strtoint(edit10.Text) >= 0) and (strtoint(edit11.Text) >=0) and (strtoint(edit10.Text) < scenemapfile.map[combobox2.ItemIndex].x)and (strtoint(edit11.Text) < scenemapfile.map[combobox2.ItemIndex].y))  then
  begin
    Addundosave;
  end;
    //copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup);
  if (evtx >= 0) and (evty >=0) and (evtx < scenemapfile.map[combobox2.ItemIndex].x)and (evty < scenemapfile.map[combobox2.ItemIndex].y)  then
  begin

    tempeventnum:= scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[evty][evtx];
    scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[evty][evtx] := -1;

  end;
  evtx := strtoint(edit10.Text);
  evty := strtoint(edit11.Text);
  if (strtoint(edit10.Text) >= 0) and (strtoint(edit11.Text) >=0) and (strtoint(edit10.Text) < scenemapfile.map[combobox2.ItemIndex].x)and (strtoint(edit11.Text) < scenemapfile.map[combobox2.ItemIndex].y) then
  begin
    if tempeventnum >= 0 then
    begin
      scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[strtoint(edit11.Text)][strtoint(edit10.Text)] := tempeventnum;
      Dfile.mapevent[combobox2.ItemIndex].sceneevent[tempeventnum].canwalk := strtoint(edit1.Text);
      Dfile.mapevent[combobox2.ItemIndex].sceneevent[tempeventnum].num := strtoint(edit2.Text);
      Dfile.mapevent[combobox2.ItemIndex].sceneevent[tempeventnum].event1 := strtoint(edit3.Text);
      Dfile.mapevent[combobox2.ItemIndex].sceneevent[tempeventnum].event2 := strtoint(edit4.Text);
      Dfile.mapevent[combobox2.ItemIndex].sceneevent[tempeventnum].event3 := strtoint(edit5.Text);
      Dfile.mapevent[combobox2.ItemIndex].sceneevent[tempeventnum].beginpic1 := strtoint(edit6.Text);
      Dfile.mapevent[combobox2.ItemIndex].sceneevent[tempeventnum].endpic:= strtoint(edit7.Text);
      Dfile.mapevent[combobox2.ItemIndex].sceneevent[tempeventnum].beginpic2 := strtoint(edit8.Text);
      Dfile.mapevent[combobox2.ItemIndex].sceneevent[tempeventnum].picdelay := strtoint(edit9.Text);
      Dfile.mapevent[combobox2.ItemIndex].sceneevent[tempeventnum].xpos := strtoint(edit10.Text);
      Dfile.mapevent[combobox2.ItemIndex].sceneevent[tempeventnum].ypos := strtoint(edit11.Text);
      if SceneEditMode = RLEMode then
      begin
        displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmp);
        scenebufbmp.Canvas.CopyRect(scenebufbmp.Canvas.ClipRect, sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
        image1.Canvas.CopyRect(image1.ClientRect,sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
      end
      else
      begin
        displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmppng);
        scenebufbmppng.Canvas.CopyRect(scenebufbmppng.Canvas.ClipRect, sceneopbmppng.Canvas,sceneopbmppng.Canvas.ClipRect);
        image1.Canvas.CopyRect(image1.ClientRect,sceneopbmppng.Canvas,sceneopbmppng.Canvas.ClipRect);
      end;
    end;
  end;
  copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup[0]);
  copyscenemapevent(@Dfile.mapevent[combobox2.ItemIndex], @scenemapeventbackup[0]);
end;

procedure TForm12.Button3Click(Sender: TObject);
var
  I,len,ix,iy,i2: integer;
  idx,grp: integer;
begin
try
  len := 0;
  idx := filecreate(gamepath + Sidx[combobox1.ItemIndex]);
  grp := filecreate(gamepath + Sgrp[combobox1.ItemIndex]);
  for I := 0 to scenemapfile.num - 1 do
  begin
    for i2 := 0 to scenemapfile.map[I].layernum - 1 do
      for Iy := 0 to scenemapfile.map[I].y - 1 do
        filewrite(grp, scenemapfile.map[I].maplayer[I2].pic[iy][0],2 * scenemapfile.map[I].x);
    inc(len, scenemapfile.map[I].layernum * scenemapfile.map[I].x * scenemapfile.map[I].y * 2);
    filewrite(idx,len,4);
  end;
  fileclose(idx);
  fileclose(grp);

  len := 0;
  idx := filecreate(gamepath + Didx[combobox1.ItemIndex]);
  grp := filecreate(gamepath + Dgrp[combobox1.ItemIndex]);
  for I := 0 to Dfile.mapnum - 1 do
  begin
    filewrite(grp, Dfile.mapevent[i],22 * 200);
    inc(len, 200 * 11 * 2);
    filewrite(idx,len,4);
  end;
  fileclose(idx);
  fileclose(grp);

  showmessage('保存成功！');
except
  fileclose(idx);
  fileclose(grp);
  showmessage('保存失败！');
end;
end;

procedure TForm12.Button4Click(Sender: TObject);
var
  I, temp, ix, iy: integer;
begin
  try
  inc(Dfile.mapnum);
  setlength(Dfile.mapevent,Dfile.mapnum);
  Dfile.mapevent[Dfile.mapnum - 1] := Dfile.mapevent[combobox2.ItemIndex];
  inc(scenemapfile.num);
  setlength(scenemapfile.map, scenemapfile.num);
  scenemapfile.map[scenemapfile.num - 1].layernum := scenemapfile.map[combobox2.ItemIndex].layernum;
  scenemapfile.map[scenemapfile.num - 1].x := scenemapfile.map[combobox2.ItemIndex].x;
  scenemapfile.map[scenemapfile.num - 1].y := scenemapfile.map[combobox2.ItemIndex].y;
  setlength(scenemapfile.map[scenemapfile.num - 1].maplayer, scenemapfile.map[scenemapfile.num - 1].layernum);
  for I := 0 to scenemapfile.map[scenemapfile.num - 1].layernum - 1 do
  begin
    setlength(scenemapfile.map[scenemapfile.num - 1].maplayer[I].pic, scenemapfile.map[scenemapfile.num - 1].y,scenemapfile.map[scenemapfile.num - 1].x);
    for iy := 0 to scenemapfile.map[scenemapfile.num - 1].y - 1 do
      for ix := 0 to scenemapfile.map[scenemapfile.num - 1].x - 1 do
        scenemapfile.map[scenemapfile.num - 1].maplayer[I].pic[iy][ix] := scenemapfile.map[combobox2.ItemIndex].maplayer[I].pic[iy][ix]
  end;
    combobox2.Items.Add(inttostr(scenemapfile.num - 1));
    showmessage('添加贴图成功！已复制当前场景的到新场景！');
  except
    showmessage('添加失败');
  end;
end;

procedure TForm12.Button5Click(Sender: TObject);
var
  temp: integer;
begin
  try
  dec(Dfile.mapnum);
  setlength(Dfile.mapevent,Dfile.mapnum);
  temp := combobox2.Items.Count;
  if combobox2.ItemHeight = scenemapfile.num - 1 then
  begin
    combobox2.ItemIndex := scenemapfile.num - 2;
    combobox2.OnSelect(sender);
  end;
  dec(scenemapfile.num);
  combobox2.Items.Delete(temp - 1);
  setlength(scenemapfile.map, scenemapfile.num);
  showmessage('删除最后一个场景成功！');
  except
    showmessage('删除失败！');
  end;
end;

procedure TForm12.Button6Click(Sender: TObject);
var
  temphigh, ix, iy: integer;
begin
  temphigh := strtoint(edit12.Text);
    if (scenelayer >=4) and (scenelayer <= 5) and (scenestill = 0) then
    begin
      if highselect then
      begin

        if (highendx <> scenestillx) or (highendy <> scenestilly) then
        begin
          Addundosave;
          //copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup);
          if highendx < scenestillx then
          begin
            if highendy < scenestilly then
            begin

              for ix := highendx to scenestillx do
                for iy := highendy to scenestilly do
                begin
                  scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[iy][ix] := temphigh;
                end;
            end
            else
            begin
              //copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup);
              for ix := highendx to scenestillx do
                for iy := highendy downto scenestilly do
                begin
                  scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[iy][ix] := temphigh;
                end;

            end;
          end
          else
          begin
            if highendy < scenestilly then
              for ix := highendx downto scenestillx do
                for iy := highendy to scenestilly do
                begin
                  scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[iy][ix] := temphigh;
                end
            else
              for ix := highendx downto scenestillx do
                for iy := highendy downto scenestilly do
                begin
                  scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[iy][ix] := temphigh;
                end;
          end;
          copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup[0]);
          copyscenemapevent(@Dfile.mapevent[combobox2.ItemIndex], @scenemapeventbackup[0]);
        end;

      end
      else if (scenestillx >= 0) and (scenestillx < scenemapfile.map[combobox2.ItemIndex].x) and (scenestilly >=0) and (scenestilly < scenemapfile.map[combobox2.ItemIndex].y) then
        scenemapfile.map[combobox2.ItemIndex].maplayer[scenelayer].pic[scenestilly][scenestillx] := temphigh;
      needupdate := true;
    end;
end;

procedure TForm12.Button7Click(Sender: TObject);
var
  FH: integer;
  I,I1,I2: integer;
begin
  scenelock := true;
  opendialog1.Filter := 'Map files (*.Map)|*.Map|All files (*.*)|*.*';
  if opendialog1.Execute then
  begin
    if fileexists(opendialog1.FileName) then
    begin
      try
        FH := fileopen(opendialog1.FileName, fmopenread);
        for I := 0 to scenemapfile.map[combobox2.ItemIndex].layernum - 1 do
        begin
          for I1 := 0 to scenemapfile.map[combobox2.ItemIndex].y - 1 do
          begin
            fileread(FH, scenemapfile.map[combobox2.ItemIndex].maplayer[I].pic[i1][0],scenemapfile.map[combobox2.ItemIndex].x * 2);
          end;
        end;
        fileclose(FH);
        for I := 0 to length(Dfile.mapevent[combobox2.itemindex].sceneevent) - 1 do
        begin
          Dfile.mapevent[combobox2.itemindex].sceneevent[I].canwalk := 0;
          Dfile.mapevent[combobox2.itemindex].sceneevent[I].num := -1;
          Dfile.mapevent[combobox2.itemindex].sceneevent[I].event1 := -1;
          Dfile.mapevent[combobox2.itemindex].sceneevent[I].event2 := -1;
          Dfile.mapevent[combobox2.itemindex].sceneevent[I].event3 := -1;
          Dfile.mapevent[combobox2.itemindex].sceneevent[I].beginpic1 := 0;
          Dfile.mapevent[combobox2.itemindex].sceneevent[I].endpic := 0;
          Dfile.mapevent[combobox2.itemindex].sceneevent[I].beginpic2 := 0;
          Dfile.mapevent[combobox2.itemindex].sceneevent[I].picdelay := 0;
          Dfile.mapevent[combobox2.itemindex].sceneevent[I].xpos := 0;
          Dfile.mapevent[combobox2.itemindex].sceneevent[I].ypos := 0;
        end;
        needupdate := false;
        scenelock := true;
        tempeventnum:= -1;
        evtx := -1;
        evty := -1;
      if SceneEditMode = RLEMode then
      begin
        displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmp);
        scenebufbmp.Canvas.CopyRect(scenebufbmp.Canvas.ClipRect, sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
        image1.Canvas.CopyRect(image1.ClientRect,sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
      end
      else
      begin
        displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmppng);
        scenebufbmppng.Canvas.CopyRect(scenebufbmppng.Canvas.ClipRect, sceneopbmppng.Canvas,sceneopbmppng.Canvas.ClipRect);
        image1.Canvas.CopyRect(image1.ClientRect,sceneopbmppng.Canvas,sceneopbmppng.Canvas.ClipRect);
      end;
      scenelock := false;
      except
        fileclose(FH);
        showmessage('地图错误！');
      end;
    end
    else
      showmessage('文件不存在！');
  end;
  scenelock := false;
end;

procedure TForm12.Button8Click(Sender: TObject);
var
  filename: string;
  I, I1, FH: integer;
begin
  scenelock := true;
  savedialog1.Filter := 'Map files (*.Map)|*.Map';
  if savedialog1.Execute then
  begin
    filename := SaveDialog1.filename;
    if not SameText(ExtractFileExt(SaveDialog1.filename), '.map') then
      filename := filename + '.map';
    FH := filecreate(filename);
    for I := 0 to scenemapfile.map[combobox2.ItemIndex].layernum - 1 do
    begin
      for I1 := 0 to scenemapfile.map[combobox2.ItemIndex].y - 1 do
      begin
        filewrite(FH, scenemapfile.map[combobox2.ItemIndex].maplayer[I].pic[I1][0], scenemapfile.map[combobox2.ItemIndex].x * 2);
      end;
    end;
    fileclose(FH);
  end;
  scenelock := false;
end;

procedure TForm12.Button9Click(Sender: TObject);
var
  filename: string;
  I, I1, I2, ix, iy,FH,posx,posy: integer;
  scenetempbmp: Tbitmap;
   PalSize:longint;
    pLogPalle:TMaxLogPalette;
    PalleEntry:TPaletteEntry;
    Palle:HPalette;
begin
  if scenelayer <> 6 then
  begin
    showmessage('请选择操作图层为"全部"，然后用鼠标括出一块区域');
  end
  else
  begin
    scenelock := true;
    savedialog1.Filter := 'Scene Module files (*.smd)|*.smd';
    if savedialog1.Execute then
    begin
      filename := SaveDialog1.filename;
      if not SameText(ExtractFileExt(SaveDialog1.filename), '.smd') then
        filename := filename + '.smd';
      //scenelock := true;
      try
        FH := filecreate(filename);
        fileseek(FH,0,0);
        filewrite(FH, scenecopymap.x, 4);
        filewrite(FH, scenecopymap.y, 4);
        for I := 0 to scenecopymap.layernum - 1 do
        begin
          for I1 := 0 to scenecopymap.y - 1 do
          begin
            filewrite(FH, scenecopymap.maplayer[I].pic[I1][0], 2*scenecopymap.x);
          end;
        end;

      finally
        fileclose(FH);
      end;
      try
        scenetempbmp := Tbitmap.Create;

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
        if SceneEditMode = RLEMode then
        begin
          scenetempbmp.PixelFormat := pf8bit;
          scenetempbmp.Palette := Palle;
        end
        else
          scenetempbmp.PixelFormat := pf32bit;

        scenetempbmp.Width := (scenecopymap.x + scenecopymap.y) * 18 + 150;
        scenetempbmp.height := (scenecopymap.x + scenecopymap.y) * 9 + 150;
        scenetempbmp.Canvas.Brush.Color := clblack;
        scenetempbmp.Canvas.FillRect(scenetempbmp.Canvas.ClipRect);

        for I := 0 to 2 do
          for Ix := scenecopymap.x - 1 downto 0 do
             for iy := scenecopymap.y - 1 downto 0 do
               if (scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] > 0) or ((scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] = 0) and (I = 0)) then
               begin
                 posx := (scenecopymap.x - ix) * 18 - (scenecopymap.y - iy) * 18  + scenecopymap.y * 18 + 75;
                 posy := (scenecopymap.x - ix) * 9 + (scenecopymap.y - Iy) * 9 + 110;
                 if I = 1 then
                   posy := posy - scenecopymap.maplayer[4].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1]
                 else if I = 2 then
                   posy := posy - scenecopymap.maplayer[5].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1];

                 //McoldrawRLE8(@scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].data[0],scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].size,@scenetempbmp, posx,posy, true);
                 case SceneEditMode of
                   RLEMode:
                     begin
                       if (scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2 >= 0)
                       and (scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2 < scenegrpnum)
                       and (scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].size >= 8)
                       then
                         McoldrawRLE8(@scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].data[0],scenegrp[scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2].size,@scenetempbmp, posx,posy, true);
                     end;
                   IMZMode, PNGMode:
                     begin
                       //imzFile.DrawImztocanvasEx(image5.Canvas, @imzFIle.imzFile, tempint, 0, 0, 0);
                       ImzFile.SceneQuickDraw(@scenetempbmp, scenecopymap.maplayer[I].pic[scenecopymap.y - iy - 1][scenecopymap.x - ix - 1] div 2, posx, posy);
                     end;
                 end;
               end;

        scenetempbmp.SaveToFile(filename + '.bmp');
      finally
        scenetempbmp.Free;
      end;

    end;
    scenelock := false;
  end;
  scenestill := 0;
  scenestillx := -1;
end;

procedure TForm12.CheckBox2Click(Sender: TObject);
begin
  if checkbox2.Checked then
  begin
    panel9.Visible := true;
    needupdate := true;
  end
  else
  begin
    panel9.Visible := false;
  end;
end;

procedure TForm12.CheckBox3Click(Sender: TObject);
begin
  needupdate := true;
end;

procedure TForm12.CheckBox4Click(Sender: TObject);
begin
  needupdate := true;
end;

procedure TForm12.ComboBox1Select(Sender: TObject);
var
  I: integer;
begin
  if not Scenemapinitial then
    exit;
  needupdate := false;
  scenelock := true;
  tempeventnum:= -1;
  evtx := -1;
  evty := -1;
  readDAndS(combobox1.ItemIndex);
  combobox2.Clear;
  for I := 0 to scenemapfile.num - 1 do
    combobox2.Items.Add(CalRname(3,I));
  combobox2.ItemIndex := 0;
      if SceneEditMode = RLEMode then
      begin
        displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmp);
        scenebufbmp.Canvas.CopyRect(scenebufbmp.Canvas.ClipRect, sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
        image1.Canvas.CopyRect(image1.ClientRect,sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
      end
      else
      begin
        displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmppng);
        scenebufbmppng.Canvas.CopyRect(scenebufbmppng.Canvas.ClipRect, sceneopbmppng.Canvas,sceneopbmppng.Canvas.ClipRect);
        image1.Canvas.CopyRect(image1.ClientRect,sceneopbmppng.Canvas,sceneopbmppng.Canvas.ClipRect);
      end;  scenelock := false;
  initialundomap(@scenemapfile.map[0], @Dfile.mapevent[0],0);
  undotimes := 0;
  undoSavetimes := 1;
end;

procedure TForm12.ComboBox2Select(Sender: TObject);
begin
  if not Scenemapinitial then
    exit;
  needupdate := false;
  scenelock := true;
  tempeventnum:= -1;
  evtx := -1;
  evty := -1;
      if SceneEditMode = RLEMode then
      begin
        displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmp);
        scenebufbmp.Canvas.CopyRect(scenebufbmp.Canvas.ClipRect, sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
        image1.Canvas.CopyRect(image1.ClientRect,sceneopbmp.Canvas,sceneopbmp.Canvas.ClipRect);
      end
      else
      begin
        displayscenemap(@scenemapfile.map[combobox2.ItemIndex], @sceneopbmppng);
        scenebufbmppng.Canvas.CopyRect(scenebufbmppng.Canvas.ClipRect, sceneopbmppng.Canvas,sceneopbmppng.Canvas.ClipRect);
        image1.Canvas.CopyRect(image1.ClientRect,sceneopbmppng.Canvas,sceneopbmppng.Canvas.ClipRect);
      end;
  scenelock := false;
  //copyscenemap(@scenemapfile.map[combobox2.ItemIndex], @scenemapbackup[0]);
  initialundomap(@scenemapfile.map[combobox2.ItemIndex], @Dfile.mapevent[combobox2.ItemIndex],0);
  undotimes := 0;
  undoSavetimes := 1;
end;

procedure TForm12.ComboBox3Select(Sender: TObject);
var
  I : integer;
begin
  needupdate := false;
  scenelock := true;
  scenelayer := combobox3.ItemIndex - 1;
  tempeventnum:= -1;
  evtx := -1;
  evty := -1;
  if scenelayer = 3 then
    panel2.Visible := true
  else
    panel2.Visible := false;
  if (scenelayer >= 4) and (scenelayer <= 5) then
    panel3.Visible := true
  else
    panel3.Visible := false;
  if scenelayer = 6 then
    if scenecopymapmode = 0 then
    begin
      scenecopymapmode := 1;
      nowscenegrpnum := -1;
      scenecopymap.layernum := scenemapfile.map[combobox2.ItemIndex].layernum;
      scenecopymap.x := 1;
      scenecopymap.y := 1;
      setlength(scenecopymap.maplayer, scenecopymap.layernum);

      for I := 0 to scenecopymap.layernum - 1 do
      begin
        setlength(scenecopymap.maplayer[I].pic,scenecopymap.y,scenecopymap.x);
        scenecopymap.maplayer[I].pic[0][0] := 0;
      end;

    end;
  scenelock := false;
  if checkbox4.Checked then
    needupdate := true;
end;

procedure TForm12.drawsquare(x,y: integer);
var
  I: integer;
  Pdata: Pbyte;
begin
  //
  if SceneEditMode = RLEMode then
  begin

  try
    Pdata := scenebufbmp.ScanLine[Y];


  (Pdata + x)^ := 23;

 (Pdata+ x - 1)^ := 23;

  for I := 1 to 8 do
  begin
    Pdata := scenebufbmp.ScanLine[Y - I];
   (Pdata + (X - 2 * I))^ := 23;
    (Pdata + (X - 2 * I - 1))^ := 23;
     (Pdata + (X + 2 * I))^ := 23;
     (Pdata + (X + 2 * I + 1))^ := 23;
  end;
   Pdata := scenebufbmp.ScanLine[Y - 9];
   (Pdata + (X - 18))^ := 23;
   (Pdata + (X + 17))^ := 23;

  for I := 1 to 8 do
  begin
     Pdata := scenebufbmp.ScanLine[Y - 9 - I];
     (Pdata + (X - 19 + 2 * I))^ := 23;
     (Pdata + (X - 19 + 2 * I + 1))^ := 23;
     (Pdata + (X+ 17- 2 * I))^ := 23;
     (Pdata + (X+ 17- 2 * I + 1))^ := 23;

  end;
    Pdata := scenebufbmp.ScanLine[Y - 17];
    (Pdata + x)^ := 23;
    (Pdata + x - 1)^ := 23;

  except
    exit;
  end;
  end
  else
  begin
    try
      Pdata := scenebufbmpPNG.ScanLine[Y];
      Pcardinal(Pdata + x * 4)^ := $FF0000;

 Pcardinal(Pdata+ x * 4- 1* 4)^ := $FF0000;

  for I := 1 to 8 do
  begin
    Pdata := scenebufbmpPNG.ScanLine[Y - I];
   Pcardinal(Pdata + (X - 2 * I)* 4)^ := $FF0000;
    Pcardinal(Pdata + (X - 2 * I - 1)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X + 2 * I)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X + 2 * I + 1)* 4)^ := $FF0000;
  end;
   Pdata := scenebufbmpPNG.ScanLine[Y - 9];
   Pcardinal(Pdata + (X - 18)* 4)^ := $FF0000;
   Pcardinal(Pdata + (X + 17)* 4)^ := $FF0000;

  for I := 1 to 8 do
  begin
     Pdata := scenebufbmpPNG.ScanLine[Y - 9 - I];
     Pcardinal(Pdata + (X - 19 + 2 * I)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X - 19 + 2 * I + 1)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X+ 17- 2 * I)* 4)^ := $FF0000;
     Pcardinal(Pdata + (X+ 17- 2 * I + 1)* 4)^ := $FF0000;

  end;
    Pdata := scenebufbmpPNG.ScanLine[Y - 17];
    Pcardinal(Pdata + x* 4)^ := $FF0000;
    Pcardinal(Pdata + x* 4 - 1* 4)^ := $FF0000;
    except
      exit;
    end;
  end;
end;

procedure TForm12.drawsquare2(x,y: integer;sceneopbmp2 :PNTbitmap);
var
  I: integer;
  Pdata: Pbyte;
begin
  //
  if SceneEditMode = RLEMode then
  begin
  try
  Pdata := sceneopbmp2.ScanLine[Y];
  (Pdata + x)^ := 83;

 (Pdata+ x - 1)^ := 83;

  for I := 1 to 8 do
  begin
    Pdata := sceneopbmp2.ScanLine[Y - I];
   (Pdata + (X - 2 * I))^ := 83;
    (Pdata + (X - 2 * I - 1))^ := 83;
     (Pdata + (X + 2 * I))^ := 83;
     (Pdata + (X + 2 * I + 1))^ := 83;

  end;
   Pdata := sceneopbmp2.ScanLine[Y - 9];
   (Pdata + (X - 18))^ := 83;
   (Pdata + (X + 17))^ := 83;

  for I := 1 to 8 do
  begin
     Pdata := sceneopbmp2.ScanLine[Y - 9 - I];
     (Pdata + (X - 19 + 2 * I))^ := 83;
     (Pdata + (X - 19 + 2 * I + 1))^ := 83;
     (Pdata + (X+ 17- 2 * I))^ := 83;
     (Pdata + (X+ 17- 2 * I + 1))^ := 83;

  end;
  Pdata := sceneopbmp2.ScanLine[Y - 17];
    (Pdata + x)^ := 83;
    (Pdata + x - 1)^ := 83;
  except
    exit;
  end;
  end
  else
  begin
  try
    Pdata := sceneopbmp2.ScanLine[Y];
  Pcardinal(Pdata + x* 4)^ := clpurple;

 Pcardinal(Pdata+ x* 4 - 1* 4)^ := clpurple;
                                 //
  for I := 1 to 8 do
  begin
    Pdata := sceneopbmp2.ScanLine[Y - I];
   Pcardinal(Pdata + (X - 2 * I)* 4)^ := clpurple;
    Pcardinal(Pdata + (X - 2 * I - 1)* 4)^ := clpurple;
     Pcardinal(Pdata + (X + 2 * I)* 4)^ := clpurple;
     Pcardinal(Pdata + (X + 2 * I + 1)* 4)^ := clpurple;

  end;
   Pdata := sceneopbmp2.ScanLine[Y - 9];
   Pcardinal(Pdata + (X - 18)* 4)^ := clpurple;
   Pcardinal(Pdata + (X + 17)* 4)^ := clpurple;

  for I := 1 to 8 do
  begin
     Pdata := sceneopbmp2.ScanLine[Y - 9 - I];
     Pcardinal(Pdata + (X - 19 + 2 * I)* 4)^ := clpurple;
     Pcardinal(Pdata + (X - 19 + 2 * I + 1)* 4)^ := clpurple;
     Pcardinal(Pdata + (X+ 17- 2 * I)* 4)^ := clpurple;
     Pcardinal(Pdata + (X+ 17- 2 * I + 1)* 4)^ := clpurple;

  end;
  Pdata := sceneopbmp2.ScanLine[Y - 17];
    Pcardinal(Pdata + x* 4)^ := clpurple;
    Pcardinal(Pdata + x* 4 - 1* 4)^ := clpurple;
  except
    exit;
  end;
  end;
end;

procedure TForm12.Edit12KeyPress(Sender: TObject; var Key: Char);
begin
  if key = #13 then
    Button6Click(Sender);
end;

function readDAndS(index:integer): integer;
var
  FDidx,FDgrp,FSidx,FSgrp,I,I2,Ix,Iy,filelen: integer;
begin
 {FDidx := fileopen(gamepath + Didx[index],fmopenread);
  filelen := fileseek(FDidx,0,2);
  Dfile.mapnum := filelen shr 2;
  if fileexists(gamepath + Didx[index]) then
    showmessage('you');
  showmessage(inttostr(filelen));
  setlength(Dfile.mapevent, Dfile.mapnum);
  setlength(offset, Dfile.mapnum + 1);
  offset[I] := 0;
  fileseek(FDidx,0,0);
  fileread(Fdidx, offset[1], filelen);
  fileclose(FDidx);}
  result := 1;
  try
  FDgrp := fileopen(gamepath + Dgrp[Index],fmopenread);
  filelen := fileseek(FDgrp, 0,2);
  fileseek(FDgrp,0,0);
  Dfile.mapnum := filelen div (200 *11*2);
  setlength(Dfile.mapevent, Dfile.mapnum);
  for I := 0 to Dfile.mapnum - 1 do
  begin
   // fileseek(FDgrp,offset[I],0);
    fileread(FDgrp, Dfile.mapevent[I].sceneevent[0], 200 * 11 * 2);
  end;
    fileclose(FDgrp);
  except
    fileclose(FDgrp);
    result := 0;
    exit;
  end;

 { FSidx:=fileopen(gamepath + Sidx[index], fmopenread);
  filelen := fileseek(FSidx,0,2);
  setlength(offset, Filelen shr 2);
  fileseek(FSidx,0,0);
  fileread(FSidx,offset[0],Filelen);
  fileclose(FSidx);
  scenemapfile.num := filelen shr 2;   }

  try

  FSgrp := fileopen(gamepath + Sgrp[Index], fmopenread);
  filelen := fileseek(FSgrp,0,2);
  scenemapfile.num := filelen div (64 * 64 * 6 * 2);
  setlength(scenemapfile.map, scenemapfile.num);
  fileseek(FSgrp,0,0);
  for I := 0 to scenemapfile.num - 1 do
  begin
    scenemapfile.map[I].layernum := 6;
    scenemapfile.map[I].x := 64;
    scenemapfile.map[I].y := 64;
    setlength(scenemapfile.map[I].maplayer,scenemapfile.map[I].layernum);
    for I2 := 0 to scenemapfile.map[I].layernum - 1 do
    begin
      setlength(scenemapfile.map[I].maplayer[I2].pic, scenemapfile.map[I].y, scenemapfile.map[I].x);
      for iy := 0 to scenemapfile.map[I].y - 1 do
        fileread(FSgrp, scenemapfile.map[I].maplayer[i2].pic[iy][0], scenemapfile.map[I].x * 2);
    end;
  end;
    fileclose(FSGrp);
  except
    //showmessage('地图错误！');
    fileclose(FSGrp);
    result := 0;
    exit;
  end;
end;

procedure TFOrm12.displayscenemap(sceneopMap: Pmap; sceneopbmp2: PNTbitmap);
VAR
  ix,iy, I, i2,posx,posy: integer;
  pointx,pointy: integer;
begin
    //sceneopbmp2.IgnorePalette := true;

  //if SceneEditMOde <> RLEMode then
    //sceneopbmp2.IgnorePalette := true;

  if SceneEDitMode <> RLEMode then
    for I := 0 to ScenePNGbuf.Height - 1 do
      fillchar(ScenePNGbuf.data[I][0], ScenePNGbuf.width * 4, #0);

  pointx := sceneOPBMP2.Width DIV 2;
  pointy := sceneopbmp2.Height div 2 - 31 * 18;
  sceneopbmp2.Canvas.Brush.Style := bssolid;
  sceneopbmp2.Canvas.Brush.Color := clblack;
  sceneopbmp2.Canvas.FillRect(sceneopbmp2.Canvas.ClipRect);
  for i := 0 to min(sceneopmap.x ,sceneopmap.y) - 1 do
  begin

    for ix := I to sceneopmap.x - 1 do
    begin
      if needupdate = true then
        exit;
      posx := ix * 18 - I * 18  + pointx;
      posy := ix * 9 + I * 9 + pointy;
      try
      if (sceneopmap.maplayer[0].pic[I][ix] div 2 >= 0) and ((scenelayer = 6) or (not checkbox4.Checked) or (checkbox4.Checked and (0 = scenelayer))) then
        //McoldrawRLE8(@scenegrp[sceneopmap.maplayer[0].pic[I][ix] div 2].data[0],scenegrp[sceneopmap.maplayer[0].pic[I][ix] div 2].size,sceneopbmp2, posx, posy, true);
        case SceneEditMode of
          RLEMode:
            begin
              if (sceneopmap.maplayer[0].pic[I][ix] div 2 >= 0)
              and (sceneopmap.maplayer[0].pic[I][ix] div 2 >= 0)
              and (scenegrp[sceneopmap.maplayer[0].pic[I][ix] div 2].size >= 8)
              then
                McoldrawRLE8(@scenegrp[sceneopmap.maplayer[0].pic[I][ix] div 2].data[0],scenegrp[sceneopmap.maplayer[0].pic[I][ix] div 2].size,sceneopbmp2, posx, posy, true);
            end;
          IMZMode, PNGMode:
            begin
              //imzFile.DrawImztocanvas(sceneopbmp2.Canvas, @imzFIle.imzFile, sceneopmap.maplayer[0].pic[I][ix] div 2, posx, posy, 0);
              //ImzFile.SceneQuickDraw(sceneopbmp2, sceneopmap.maplayer[0].pic[I][ix] div 2, posx, posy);
              ImzFile.SceneQuickDrawBuf(@ScenePNGbuf, sceneopmap.maplayer[0].pic[I][ix] div 2, posx, posy);
              //ImzFile.SceneQuickDraw(sceneopbmp2, sceneopmap.maplayer[0].pic[I][ix] div 2, posx, posy);

            end;
        end;
      if (sceneopmap.maplayer[1].pic[I][ix] div 2 > 0) and ((scenelayer = 6) or (not checkbox4.Checked) or (checkbox4.Checked and (1 = scenelayer))) then
        //McoldrawRLE8(@scenegrp[sceneopmap.maplayer[1].pic[I][ix] div 2].data[0],scenegrp[sceneopmap.maplayer[1].pic[I][ix] div 2].size,sceneopbmp2, posx, posy - sceneopmap.maplayer[4].pic[I][ix], true);
        case SceneEditMode of
          RLEMode:
            begin
              if (sceneopmap.maplayer[1].pic[I][ix] div 2 >= 0)
              and (sceneopmap.maplayer[1].pic[I][ix] div 2 >= 0)
              and (scenegrp[sceneopmap.maplayer[1].pic[I][ix] div 2].size >= 8)
              then
                McoldrawRLE8(@scenegrp[sceneopmap.maplayer[1].pic[I][ix] div 2].data[0],scenegrp[sceneopmap.maplayer[1].pic[I][ix] div 2].size, sceneopbmp2, posx, posy - sceneopmap.maplayer[4].pic[I][ix], true);
            end;
          IMZMode, PNGMode:
            begin
              //imzFile.DrawImztocanvasEx(image5.Canvas, @imzFIle.imzFile, tempint, 0, 0, 0);
              ImzFile.SceneQuickDrawBuf(@ScenePNGbuf, sceneopmap.maplayer[1].pic[I][ix] div 2, posx, posy - sceneopmap.maplayer[4].pic[I][ix]);
              //ImzFile.SceneQuickDraw(sceneopbmp2, sceneopmap.maplayer[1].pic[I][ix] div 2, posx, posy - sceneopmap.maplayer[4].pic[I][ix]);

            end;
        end;
      if (sceneopmap.maplayer[2].pic[I][ix] div 2 > 0) and ((scenelayer = 6) or (not checkbox4.Checked) or (checkbox4.Checked and (2 = scenelayer))) then
        //McoldrawRLE8(@scenegrp[sceneopmap.maplayer[2].pic[I][ix] div 2].data[0],scenegrp[sceneopmap.maplayer[2].pic[I][ix] div 2].size,sceneopbmp2, posx, posy - sceneopmap.maplayer[5].pic[I][ix], true);
        case SceneEditMode of
          RLEMode:
            begin
              if (sceneopmap.maplayer[2].pic[I][ix] div 2 >= 0)
              and (sceneopmap.maplayer[2].pic[I][ix] div 2 >= 0)
              and (scenegrp[sceneopmap.maplayer[2].pic[I][ix] div 2].size >= 8)
              then
                McoldrawRLE8(@scenegrp[sceneopmap.maplayer[2].pic[I][ix] div 2].data[0],scenegrp[sceneopmap.maplayer[2].pic[I][ix] div 2].size,sceneopbmp2, posx, posy - sceneopmap.maplayer[5].pic[I][ix], true);
            end;
          IMZMode, PNGMode:
            begin
              //imzFile.DrawImztocanvasEx(image5.Canvas, @imzFIle.imzFile, tempint, 0, 0, 0);
              ImzFile.SceneQuickDrawBuf(@ScenePNGbuf, sceneopmap.maplayer[2].pic[I][ix] div 2, posx, posy - sceneopmap.maplayer[5].pic[I][ix]);
              //ImzFile.SceneQuickDraw(sceneopbmp2, sceneopmap.maplayer[2].pic[I][ix] div 2, posx, posy - sceneopmap.maplayer[5].pic[I][ix]);

            end;
        end;
      if (sceneopmap.maplayer[3].pic[I][ix] >= 0) and (Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[I][ix]].beginpic1 > 0) and ((scenelayer = 6) or (not checkbox4.Checked) or (checkbox4.Checked and (3 = scenelayer))) then
        //McoldrawRLE8(@scenegrp[Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[I][ix]].beginpic1 div 2].data[0],scenegrp[Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[I][ix]].beginpic1 div 2].size,sceneopbmp2, posx, posy - sceneopmap.maplayer[4].pic[I][ix], true);
        case SceneEditMode of
          RLEMode:
            begin
              if (sceneopmap.maplayer[3].pic[I][ix] div 2 >= 0)
              and (sceneopmap.maplayer[3].pic[I][ix] div 2 < length(Dfile.mapevent[combobox2.itemindex].sceneevent))
              and (Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[I][ix]].beginpic1 div 2 >= 0)
              and (Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[I][ix]].beginpic1 div 2 < scenegrpnum)
              and (scenegrp[Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[I][ix]].beginpic1 div 2].size >= 8)
              then
                McoldrawRLE8(@scenegrp[Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[I][ix]].beginpic1 div 2].data[0],scenegrp[Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[I][ix]].beginpic1 div 2].size,sceneopbmp2, posx, posy - sceneopmap.maplayer[4].pic[I][ix], true);
            end;
          IMZMode, PNGMode:
            begin
              //imzFile.DrawImztocanvasEx(image5.Canvas, @imzFIle.imzFile, tempint, 0, 0, 0);
              ImzFile.SceneQuickDrawBuf(@ScenePNGbuf, Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[I][ix]].beginpic1 div 2, posx, posy - sceneopmap.maplayer[4].pic[I][ix]);
              //ImzFile.SceneQuickDraw(sceneopbmp2, Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[I][ix]].beginpic1 div 2, posx, posy - sceneopmap.maplayer[4].pic[I][ix]);

            end;
        end;
      except

      end;
    end;
    for Iy := I + 1 to sceneopmap.y - 1 do
    begin
      if needupdate = true then
        exit;
      posx := i * 18 - Iy * 18  + pointx;
      posy := i * 9 + Iy * 9 + pointy;
      try
      if (sceneopmap.maplayer[0].pic[Iy][i] div 2 >= 0) and ((scenelayer = 6) or (not checkbox4.Checked) or (checkbox4.Checked and (0 = scenelayer))) then
        //McoldrawRLE8(@scenegrp[sceneopmap.maplayer[0].pic[Iy][i] div 2].data[0],scenegrp[sceneopmap.maplayer[0].pic[Iy][i] div 2].size,sceneopbmp2, posx, posy, true);
        case SceneEditMode of
          RLEMode:
            begin
              if (sceneopmap.maplayer[0].pic[Iy][i] div 2 >= 0)
              and (sceneopmap.maplayer[0].pic[Iy][i] div 2 >= 0)
              and (scenegrp[sceneopmap.maplayer[0].pic[Iy][i] div 2].size >= 8)
              then
                McoldrawRLE8(@scenegrp[sceneopmap.maplayer[0].pic[Iy][i] div 2].data[0],scenegrp[sceneopmap.maplayer[0].pic[Iy][i] div 2].size,sceneopbmp2, posx, posy, true);
            end;
          IMZMode, PNGMode:
            begin
              //imzFile.DrawImztocanvasEx(image5.Canvas, @imzFIle.imzFile, tempint, 0, 0, 0);
              ImzFile.SceneQuickDrawBuf(@ScenePNGbuf, sceneopmap.maplayer[0].pic[Iy][i] div 2, posx, posy);
              //ImzFile.SceneQuickDraw(sceneopbmp2, sceneopmap.maplayer[0].pic[Iy][i] div 2, posx, posy);

            end;
        end;
      if (sceneopmap.maplayer[1].pic[Iy][i] div 2 > 0) and ((scenelayer = 6) or (not checkbox4.Checked) or (checkbox4.Checked and (1 = scenelayer))) then
        //McoldrawRLE8(@scenegrp[sceneopmap.maplayer[1].pic[Iy][i] div 2].data[0],scenegrp[sceneopmap.maplayer[1].pic[Iy][i] div 2].size,sceneopbmp2, posx, posy - sceneopmap.maplayer[4].pic[Iy][i], true);
        case SceneEditMode of
          RLEMode:
            begin
              if (sceneopmap.maplayer[1].pic[Iy][i] div 2 >= 0)
              and (sceneopmap.maplayer[1].pic[Iy][i] div 2 >= 0)
              and (scenegrp[sceneopmap.maplayer[1].pic[Iy][i] div 2].size >= 8)
              then
                McoldrawRLE8(@scenegrp[sceneopmap.maplayer[1].pic[Iy][i] div 2].data[0],scenegrp[sceneopmap.maplayer[1].pic[Iy][i] div 2].size,sceneopbmp2, posx, posy - sceneopmap.maplayer[4].pic[Iy][i], true);
            end;
          IMZMode, PNGMode:
            begin
              //imzFile.DrawImztocanvasEx(image5.Canvas, @imzFIle.imzFile, tempint, 0, 0, 0);
              ImzFile.SceneQuickDrawBuf(@ScenePNGbuf, sceneopmap.maplayer[1].pic[Iy][i] div 2, posx, posy - sceneopmap.maplayer[4].pic[Iy][i]);
              //ImzFile.SceneQuickDraw(sceneopbmp2, sceneopmap.maplayer[1].pic[Iy][i] div 2, posx, posy - sceneopmap.maplayer[4].pic[Iy][i]);

            end;
        end;
      if (sceneopmap.maplayer[2].pic[Iy][i] div 2 > 0) and ((scenelayer = 6) or (not checkbox4.Checked) or (checkbox4.Checked and (2 = scenelayer))) then
        //McoldrawRLE8(@scenegrp[sceneopmap.maplayer[2].pic[Iy][i] div 2].data[0],scenegrp[sceneopmap.maplayer[2].pic[Iy][i] div 2].size,sceneopbmp2, posx, posy - sceneopmap.maplayer[5].pic[Iy][i], true);
        case SceneEditMode of
          RLEMode:
            begin
              if (sceneopmap.maplayer[2].pic[Iy][i] div 2 >= 0)
              and (sceneopmap.maplayer[2].pic[Iy][i] div 2 >= 0)
              and (scenegrp[sceneopmap.maplayer[2].pic[Iy][i] div 2].size >= 8)
              then
                McoldrawRLE8(@scenegrp[sceneopmap.maplayer[2].pic[Iy][i] div 2].data[0],scenegrp[sceneopmap.maplayer[2].pic[Iy][i] div 2].size,sceneopbmp2, posx, posy - sceneopmap.maplayer[5].pic[Iy][i], true);
            end;
          IMZMode, PNGMode:
            begin
              //imzFile.DrawImztocanvasEx(image5.Canvas, @imzFIle.imzFile, tempint, 0, 0, 0);
              ImzFile.SceneQuickDrawBuf(@ScenePNGbuf, sceneopmap.maplayer[2].pic[Iy][i] div 2, posx, posy - sceneopmap.maplayer[5].pic[Iy][i]);
              //ImzFile.SceneQuickDraw(sceneopbmp2, sceneopmap.maplayer[2].pic[Iy][i] div 2, posx, posy - sceneopmap.maplayer[5].pic[Iy][i]);

            end;
        end;
      if (sceneopmap.maplayer[3].pic[Iy][i] >= 0) and (Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[Iy][i]].beginpic1 > 0) and ((scenelayer = 6) or (not checkbox4.Checked) or (checkbox4.Checked and (3 = scenelayer))) then
        //McoldrawRLE8(@scenegrp[Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[Iy][i]].beginpic1 div 2].data[0],scenegrp[Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[Iy][i]].beginpic1 div 2].size, sceneopbmp2, posx, posy - sceneopmap.maplayer[4].pic[Iy][i], true);
        case SceneEditMode of
          RLEMode:
            begin
              if (sceneopmap.maplayer[3].pic[Iy][i] div 2 >= 0)
              and (sceneopmap.maplayer[3].pic[Iy][i] div 2 < length(Dfile.mapevent[combobox2.itemindex].sceneevent))
              and (Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[Iy][i]].beginpic1 div 2 >= 0)
              and (Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[Iy][i]].beginpic1 div 2 < scenegrpnum)
              and (scenegrp[Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[Iy][i]].beginpic1 div 2].size >= 8)
              then
                McoldrawRLE8(@scenegrp[Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[Iy][i]].beginpic1 div 2].data[0],scenegrp[Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[Iy][i]].beginpic1 div 2].size,sceneopbmp2, posx, posy - sceneopmap.maplayer[4].pic[Iy][i], true);
            end;
          IMZMode, PNGMode:
            begin
              //imzFile.DrawImztocanvasEx(image5.Canvas, @imzFIle.imzFile, tempint, 0, 0, 0);
              ImzFile.SceneQuickDrawBuf(@ScenePNGbuf, Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[Iy][i]].beginpic1 div 2, posx, posy - sceneopmap.maplayer[4].pic[Iy][i]);
              //ImzFile.SceneQuickDraw(sceneopbmp2, Dfile.mapevent[combobox2.itemindex].sceneevent[sceneopmap.maplayer[3].pic[Iy][i]].beginpic1 div 2, posx, posy - sceneopmap.maplayer[4].pic[Iy][i]);
            end;
        end;
      except

      end;
    end;
  end;

  if SceneEDitMode <> RLEMode then
  begin
    sceneopbmp2.Canvas.Lock;
    for I := 0 to ScenePNGbuf.Height - 1 do
      copymemory(sceneopbmp2.ScanLine[I], @ScenePNGbuf.data[I][0], ScenePNGbuf.Width * 4);
    sceneopbmp2.Canvas.UnLock;
  end;
  evtnum := -1;
  for Ix := 0 to sceneopmap.x - 1 do
    for iy := 0 to sceneopmap.y - 1 do
      if sceneopmap.maplayer[3].pic[Iy][ix] >= 0 then
      begin
        posx := ix * 18 - Iy * 18  + pointx;
        posy := ix * 9 + Iy * 9 + pointy;
        evtnum := max(evtnum, sceneopmap.maplayer[3].pic[Iy][ix]);
        sceneopbmp2.Canvas.Brush.Style := bsclear;
        sceneopbmp2.Canvas.TextOut(posx - 5, posy - 18, '['+inttostr(sceneopmap.maplayer[3].pic[Iy][ix]) + ']');
      end;
  inc(evtnum);
  if checkbox3.Checked then
  begin
    for ix := 0 to sceneopmap.x - 1 do
      for iy := 0 to sceneopmap.y - 1 do
      begin
        posx := ix * 18 - Iy * 18  + pointx;
        posy := ix * 9 + Iy * 9 + pointy;
        drawsquare2(posx,posy, sceneopbmp2);
      end;
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

procedure copyscenemap(source,destination:Pmap);
var
  I,I1: integer;
begin
  destination.layernum := source.layernum;
  destination.x := source.x;
  destination.y := source.y;
  setlength(destination.maplayer, destination.layernum);
  for I := 0 to destination.layernum - 1 do
  begin
    setlength(destination.maplayer[I].pic, destination.y,destination.x);
    for i1 := 0 to destination.y - 1 do
      copymemory(@(destination.maplayer[I].pic[i1][0]), @(source.maplayer[I].pic[i1][0]), destination.x * 2);
  end;
end;

procedure copyscenemapevent(source,destination:Pmapevent);
var
  I: integer;
begin
  //
  for I := 0 to 200 - 1 do
    copymemory(@(destination.sceneevent[I]), @(source.sceneevent[I]), sizeof(Tsceneevent));
end;

end.
