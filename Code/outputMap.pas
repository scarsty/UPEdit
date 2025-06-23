unit outputMap;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, head, StdCtrls, ExtCtrls, imzObject;

type

  ToutMAPThread = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

  TForm93 = class(TForm)
    Button1: TButton;
    GroupBox1: TGroupBox;
    Button3: TButton;
    Panel3: TPanel;
    Image1: TImage;
    FontDialog1: TFontDialog;
    ColorDialog1: TColorDialog;
    Button2: TButton;
    Edit1: TEdit;
    Button4: TButton;
    SaveDialog1: TSaveDialog;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Button5: TButton;
    Memo1: TMemo;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    OutMAPThread: TOutMAPThread;
  public

  end;

var
  Form93: TForm93;
  outMAPfont: TFont;
  outMapcolor: cardinal = clyellow;
  outMAPFilename: string = 'MAP.bmp';
  outMAPzoom: integer = 100;
  outMMapEditMode: TMapEditMode;
  outImzFile: PImzFile;

  Mmapoutputname: Boolean = true;
  Mmapoutputlayer1: Boolean = true;
  Mmapoutputlayer2: Boolean = true;
  Mmapoutputlayer3: Boolean = true;

procedure outMapover;
procedure outMapcheck;
function CalRNameWithoutNum(datatype, index: integer): string;
procedure outMapcreatepal;//创建256调色板...

procedure outMapcreatebmp;//正在创建bmp...

procedure outMaplayer1;//'正在绘制地面层...');

procedure outMaplayer2;//('正在绘制表面层...');


procedure outMapcount;//('正在计算需要绘制的建筑顺序...');

procedure outMaplayer3;//('正在绘制建筑...');

procedure outMaplayer4;//('正在添加场景名称...');
procedure outMapzoompic;//'正在缩放...');

procedure outMapsave;//('正在保存bmp文件...');


implementation

uses
  MainMapEdit, main;

{$R *.dfm}


procedure ToutMAPThread.Execute;
var
  Mapbmp1: TBitmap;
  Mapbmp2: TBitmap;
 // tempMapdata: Tbmpdata;
  firstx,firsty, I,i1, i2, I3,ix, iy, Picwidth, picheight: integer;
  BuildingList, CenterList: array of TPosition;
  pos: TPosition;
  PalSize:longint;
    pLogPalle:TMaxLogPalette;
    PalleEntry:TPaletteEntry;
    Palle:HPalette;
    tempstr: string;
begin
  freeonterminate := true;
  try
    try
  //
  Synchronize(outMapcreatebmp);
  MApbmp1 := TBitmap.Create;
  MAPBMP1.Canvas.Lock;
  MAPBMP1.PixelFormat := pf8bit;
  MAPBMP1.Width := 17360;//17280;
  MAPBMP1.Height := 8700;//8640;

  Synchronize(outMapcreatepal);
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

  MAPBMP1.Palette := Palle;
  MAPBMP1.Canvas.Brush.Color := clblack;
  MAPBMP1.Canvas.FillRect(MAPBMP1.Canvas.ClipRect);
  //tempMapData.pixelperbit := pf24bit;
  //tempMapData.height := MAPBMP1.Height;
  //tempMapData.width := MAPBMP1.Width;
  //setlength(tempMAPdata.data, tempMAPdata.height, tempMAPdata.width * 3);

  firstx := MApBMP1.Width div 2 + 18;
  firsty := 30;

 // for I := 0 to MAPBMP1.Height - 1 do
  //  copymemory(@tempMapData.data[i][0], MAPBMP1.ScanLine[I], MAPBMP1.Width * 3);

  for I := 0 to 1 do
  begin
    if (I = 0) and (not Mmapoutputlayer1) then
      continue;
    if (I = 1) and (not Mmapoutputlayer2) then
      continue;

    if I = 0 then
      Synchronize(outMaplayer1)
    else
      Synchronize(outMaplayer2);
    for I1 := 0 to 480 - 1 do
    begin
      for i2 := I1 to 480 - 1 do
      begin
        if (I = 0) or (Mmapfile.map[0].maplayer[I].pic[I1][I2] div 2 > 0) then
        begin
          if outMMapEditMode = RLEMode then
          begin
            MColdrawRLE8(@Mmapgrp[Mmapfile.map[0].maplayer[I].pic[I1][I2] div 2].data[0],Mmapgrp[Mmapfile.map[0].maplayer[0].pic[I1][I2] div 2].size, @MAPBMP1, I2 * 18 - I1 * 18 + firstx, I1 * 9 + I2 * 9 + firsty, true);
          end
          else
          begin
            outImzFile.SceneQuickDraw(@MAPBMP1, Mmapfile.map[0].maplayer[I].pic[I1][I2] div 2, I2 * 18 - I1 * 18 + firstx, I1 * 9 + I2 * 9 + firsty);
          end;
        end;
        if (I = 0) or (Mmapfile.map[0].maplayer[I].pic[I2][I1] div 2 > 0) then
        begin
          if outMMapEditMode = RLEMode then
          begin
            MColdrawRLE8(@Mmapgrp[Mmapfile.map[0].maplayer[I].pic[I2][I1] div 2].data[0],Mmapgrp[Mmapfile.map[0].maplayer[0].pic[I2][I1] div 2].size, @MAPBMP1, I1 * 18 - I2 * 18 + firstx, I1 * 9 + I2 * 9 + firsty, true);
          end
          else
          begin
            outImzFile.SceneQuickDraw(@MAPBMP1, Mmapfile.map[0].maplayer[I].pic[I2][I1] div 2, I1 * 18 - I2 * 18 + firstx, I1 * 9 + I2 * 9 + firsty);
          end;
        end;
      end;
    end;
  end;

  if Mmapoutputlayer3 then
  begin
  Synchronize(outMapcount);
  I := 0;

  for i1 := 0 to 480 - 1 do
    for i2 := 0 to 480 - 1 do
      if Mmapfile.map[0].maplayer[2].pic[i1][I2] > 0 then
        inc(I);

  if I > 0 then
  begin
    //Synchronize(outMapcheck);
    setlength(BuildingList, I);
    setlength(CenterList, I);
    I3 := 0;
    for I1 := 0 to 480 - 1 do
      for i2 := 0 to 480 - 1 do
        if Mmapfile.map[0].maplayer[2].pic[i1][I2] div 2 > 0 then
        begin
          BuildingList[I3].x := i2;
          BuildingList[I3].y := i1;
          //CenterList[I3].x :=
          if outMMapEditMode = RLEMode then
          begin
          picwidth := 0;
          try
            Picwidth := (Psmallint(@Mmapgrp[Mmapfile.map[0].maplayer[2].pic[i1][i2] div 2].data[0]))^;
            Picheight := (Psmallint(@Mmapgrp[Mmapfile.map[0].maplayer[2].pic[i1][i2] div 2].data[2]))^;
          except
            Picheight := picwidth;
          end;
          end
          else
          begin
            try
              if outIMZFile.imzFile.imzPNG[Mmapfile.map[0].maplayer[2].pic[i1][i2] div 2].frame > 0 then
              begin
                Picwidth := outIMZFile.imzFile.imzPNG[Mmapfile.map[0].maplayer[2].pic[i1][i2] div 2].PNG[0].width; //(Psmallint(@Mmapgrp[Mmapfile.map[0].maplayer[2].pic[i1][i2] div 2].data[0]))^;
                Picheight := outIMZFile.imzFile.imzPNG[Mmapfile.map[0].maplayer[2].pic[i1][i2] div 2].PNG[0].height;//(Psmallint(@Mmapgrp[Mmapfile.map[0].maplayer[2].pic[i1][i2] div 2].data[2]))^;
              end
              else
              begin
                Picheight := 0;
                Picwidth := 0;
              end;
            except
              Picheight := 0;
              Picwidth := 0;
            end;
          end;
          CenterList[I3].x := i2 * 2 - (Picwidth+ 35) div 36 + 1;
          CenterList[I3].y := i1 * 2 - (Picheight+ 35) div 36 + 1;
          inc(I3);
        end;


    for i1 := 0 to I - 1 do
      for i2 := 0 to I - 2 do
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
    Synchronize(outMaplayer3);
    for i3 := 0 to I- 1 do
    begin
      ix := BuildingList[i3].x;
      iy := BuildingList[i3].y;
      I1 := ix * 18 - Iy * 18  + firstx;
      I2 := ix * 9 + Iy * 9 + firsty;
      if outMMapEditMode = RLEMode then
      begin
        McoldrawRLE8(@Mmapgrp[Mmapfile.map[0].maplayer[2].pic[Iy][ix] div 2].data[0],Mmapgrp[Mmapfile.map[0].maplayer[2].pic[Iy][ix] div 2].size,@MAPBMP1, i1, i2, true);
      end
      else
      begin
        outIMZFile.SceneQuickDraw(@MAPBMP1, Mmapfile.map[0].maplayer[2].pic[Iy][ix] div 2, i1, i2);
      end;
    end;

    setlength(BuildingList, 0);
    setlength(CenterList, 0);
  end;
  end;

 // for I := 0 to MAPBMP1.Height - 1 do
  //  copymemory(MAPBMP1.ScanLine[I], @tempMapData.data[i][0], MAPBMP1.Width * 3);

 // setlength(tempMapdata.data, 0, 0);
  if outmapzoom <> 100 then
  begin
    Synchronize(outMapzoompic);
    MAPBMP2 := TBITMAP.Create;
    MAPBMP2.Canvas.Lock;
    MAPBMP2.PixelFormat := pf8bit;
    MAPBMP2.Palette := Palle;
    MAPBMP2.Width := MAPBMP1.Width * outMAPzoom div 100;
    MAPBMP2.Height := MAPBMP1.Height * outMAPzoom div 100;

    //MAPBMP2.Canvas.Brush.Color := clblack;
    //MAPBMP2.Canvas.FillRect(MAPBMP2.Canvas.ClipRect);
    //MAPBMP1.Canvas.StretchDraw(Rect(0,0,MAPBMP1.Width * outMAPzoom div 100,MAPBMP1.Height * outMAPzoom div 100), MAPBMP1);
    MAPBMP2.Canvas.StretchDraw(MAPBMP2.Canvas.ClipRect, MAPBMP1);
    MAPBMP1.Width := MAPBMP2.Width; //MAPBMP1.Width * outMAPzoom div 100;
    MAPBMP1.Height := MAPBMP2.height;//MAPBMP1.Height * outMAPzoom div 100;
    MAPBMP1.Canvas.CopyRect(MAPBMP1.Canvas.ClipRect, MAPBMP2.Canvas, MAPBMP2.Canvas.ClipRect);
    MAPBMP2.Canvas.Unlock;
    MAPBMP2.Free;
  end;
  



  if Mmapoutputname then
  begin
    Synchronize(outMaplayer4);
    MAPBMP1.Canvas.Brush.Style := bsclear;
    MAPBMP1.Canvas.Font := outMapFont;
    MAPBMP1.Canvas.Font.Color := outMapColor;
    for I := 0 to useR.Rtype[3].datanum - 1 do
    begin
      tempstr := calRnameWithoutnum(3, I);
      ix := ReadRDataInt(@useR.Rtype[3].Rdata[I].Rdataline[6].Rarray[0].dataarray[0]);
      iy := ReadRDataInt(@useR.Rtype[3].Rdata[I].Rdataline[7].Rarray[0].dataarray[0]);
      if (ix > 0) and (iy > 0) then
        MAPBMP1.Canvas.TextOut((ix * 18 - Iy * 18  + firstx)* outMAPzoom div 100 - ROund(outmapfont.Size * 1.2), (ix * 9 + Iy * 9 + firsty) * outMAPzoom div 100 - Round(outmapfont.Size * 1.2), tempstr);
    end;
  end;

  Synchronize(outMapsave);

  Deletefile(outMAPfilename);
  MAPBMP1.SaveToFile(outMAPfilename);
  MAPBMP1.Canvas.Unlock;
  Synchronize(outMapover);

    except
      Form93.Enabled := true;
      Synchronize(outMapcheck);
      try
        MAPBMP1.Free;
        MAPBMP2.Free;
      except

      end;
    end;

   finally
     Form93.Enabled := true;
     MAPBMP1.Free;
     MAPBMP2.Free;
   end;

end;

procedure outMapover;
begin
  Form93.memo1.Lines.Add('导出完成！');
end;

procedure outMapcheck;
begin
  Form93.memo1.Lines.Add('导出错误，终止！');
end;

procedure outMapcreatepal;
begin
  Form93.memo1.Lines.Add('正在创建256调色板...');
end;

procedure outMapcreatebmp;
begin
  Form93.memo1.Lines.Add('正在创建bmp...');
end;

procedure outMaplayer1;
begin
  Form93.memo1.Lines.Add('正在绘制地面层...');
end;

procedure outMaplayer2;
begin
  Form93.memo1.Lines.Add('正在绘制表面层...');
end;

procedure outMapcount;
begin
  Form93.memo1.Lines.Add('正在计算需要绘制的建筑顺序...');
end;

procedure outMaplayer3;
begin
  Form93.memo1.Lines.Add('正在绘制建筑...');
end;

procedure outMaplayer4;
begin
  Form93.memo1.Lines.Add('正在添加场景名称...');
end;

procedure outMapzoompic;
begin
  Form93.memo1.Lines.Add('正在缩放...');
end;

procedure outMapsave;
begin
  Form93.memo1.Lines.Add('正在保存bmp文件...');
end;


procedure TForm93.Button1Click(Sender: TObject);
begin
   Mmapoutputlayer1 := Checkbox2.Checked;
   Mmapoutputlayer2 := Checkbox3.Checked;
   Mmapoutputlayer3 := Checkbox4.Checked;
   Mmapoutputname := Checkbox1.Checked and Mmapoutputlayer3;
   if not (Mmapoutputlayer1 or Mmapoutputlayer2 or Mmapoutputlayer3) then
   begin
     showmessage('未选择任何需要绘制的图层!');
     exit;
   end;
   if outMMapEditMode <> RLEMode then
   begin
     if MessageBox(Self.Handle, '因为是PNG模式，绘制速度相当慢，在绘制地面层时会卡住很长时间。确实要导出地图吗？',  '导出Excel', MB_OKCANCEL) <> 1 then
       exit;
   end;
   outMAPfilename := edit1.Text;
   outMAPzoom := strtoint(edit2.Text);
   if outMAPzoom > 100 then
     outMAPzoom := 100
   else if outMAPZoom < 0 then
     outMAPzoom := 50;
   if outMAPfilename = '' then
     outMAPfilename := 'MAP.bmp';
   Form93.Enabled := false;
   memo1.Clear;
   if outMMapEditMode <> RLEMode then
   begin
     Form93.memo1.Lines.Add('因为是PNG模式，绘制速度相当慢，在绘制地面层时会卡住很长时间!');
   end;

   OutMapThread := TOutMapThread.Create(false);
end;

function CalRNameWithoutNum(datatype, index: integer): string;
begin

  if (index >= 0) and (index < useR.Rtype[datatype].datanum) and (useR.Rtype[datatype].namepos >= 0) then
    result := displaystr(readRdatastr(@useR.Rtype[datatype].Rdata[index].Rdataline[useR.Rtype[datatype].namepos].Rarray[0].dataarray[0]))
  else
    result := '';
end;

procedure TForm93.Button2Click(Sender: TObject);
begin
  Fontdialog1.Font.Assign(outMAPfont);
  if Fontdialog1.Execute then
  begin
    outMAPfont.Assign(Fontdialog1.Font);
    outMAPcolor := outMAPfont.Color;
    image1.Canvas.Brush.Color := outMAPfont.Color;
    image1.Canvas.FillRect(image1.Canvas.ClipRect);
  end;
end;

procedure TForm93.Button3Click(Sender: TObject);
begin
  colordialog1.Color := outMAPcolor;
  if colordialog1.Execute then
  begin
    outMAPcolor := colordialog1.color;
    outMAPfont.Color := outMAPcolor;
    image1.Canvas.Brush.Color := outMAPfont.Color;
    image1.Canvas.FillRect(image1.Canvas.ClipRect);
  end;
end;

procedure TForm93.Button4Click(Sender: TObject);
begin
  savedialog1.FileName := edit1.Text;
  if savedialog1.Execute then
  begin
    edit1.Text := savedialog1.FileName;
    if not SameText(ExtractFileExt(SaveDialog1.filename), '.bmp') then
      edit1.Text := SaveDialog1.filename + '.bmp';

  end;
end;

procedure TForm93.Button5Click(Sender: TObject);
begin

  self.Close;
end;

procedure TForm93.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  memo1.Clear;
end;

procedure TForm93.FormCreate(Sender: TObject);
begin
  outmapfont := TFOnt.Create;
  savedialog1.InitialDir := StartPath;
  Edit1.Text := StartPath + Edit1.Text;
  outmapfont.Assign(self.Font);
  outmapfont.Color := outmapcolor;
  Checkbox1.Checked := Mmapoutputname;
end;

procedure TForm93.Image1Click(Sender: TObject);
begin
  Button3Click(sender);
end;

end.
