unit PNGimport;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, head, ExtCtrls, StdCtrls, Grids, ComCtrls, Menus, PNGimage;

type
  TPNGimportThread = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;

  end;

  TForm94 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Edit1: TEdit;
    Button1: TButton;
    Edit2: TEdit;
    Button2: TButton;
    Edit3: TEdit;
    Button3: TButton;
    Label8: TLabel;
    Label9: TLabel;
    ComboBox1: TComboBox;
    Panel4: TPanel;
    ProgressBar1: TProgressBar;
    ListBox1: TListBox;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    OpenDialog1: TOpenDialog;
    OpenDialog2: TOpenDialog;
    Button8: TButton;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure ListBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button8Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }

    // Xoffset, Yoffset: smallint;

    PNGimortThread: TPNGimportThread;
  end;

var
  Form94: TForm94;
  PNGR, PNGG, PNGB: array [0 .. 255] of byte;
  PNGXs, PNGYs: array of smallint;
  PNGFormat: array of boolean;
  PNGTrans: array of boolean;
  PNGColor: array of Cardinal;

  PNGFileName: array of string;
  ImportPNGIDxname, ImportPNGGRPname: string;
  ImportPNGFileNum: Integer;
  PNGimportProgress: Integer;

procedure setPNGimportprogress;
procedure DisablePNGimportForm;
procedure enablePNGimportForm;
procedure PNGimportError;
procedure PNGimportSuccess;
procedure PNGimportNoIDXGRPfile;
function ImportPNG(bufbmp: Pntbitmap; xs, ys: smallint; Palpha, Poridata: Pbyte)
  : Integer;
function MatchCol(col: Cardinal): byte;

implementation

uses
  PNGimportModify;
{$R *.dfm}

procedure TPNGimportThread.Execute;
var
  PNGpic: TPngObject;
  bufbmp: Tbitmap;
  alpha: array of byte;
  offset: array of Integer;
  oriGRP, tempGRP: array of Tgrppic;
  i, i2, datalen: Integer;
  idx, grp, orilen, param, len, fh: Integer;
begin
  freeonterminate := true;
  Synchronize(DisablePNGimportForm);

  PNGimportProgress := 0;
  Synchronize(setPNGimportprogress);

  PNGpic := TPngObject.Create;
  bufbmp := Tbitmap.Create;

  SetLength(tempGRP, ImportPNGFileNum);
  try
    for i := 0 to ImportPNGFileNum - 1 do
    begin
      try
        if PNGFormat[i] then
        begin
          if fileexists(PNGFileName[i]) then
          begin
            fh := fileopen(PNGFileName[i], fmopenread);
            tempGRP[i].size := fileseek(fh, 0, 2);
            fileseek(fh, 0, 0);
            SetLength(tempGRP[i].data, tempGRP[i].size);
            fileread(fh, tempGRP[i].data[0], tempGRP[i].size);
            fileclose(fh);
          end
          else
          begin
            tempGRP[i].size := 0;
            SetLength(tempGRP[i].data, 0);
          end;
        end
        else
        begin
          PNGpic.LoadFromFile(PNGFileName[i]);
          PNGpic.Canvas.Lock;
          bufbmp.Canvas.Lock;
          bufbmp.Width := PNGpic.Width;
          bufbmp.Height := PNGpic.Height;
          bufbmp.Canvas.Brush.Color := clblack;
          bufbmp.Canvas.FillRect(bufbmp.Canvas.ClipRect);
          PNGpic.Draw(bufbmp.Canvas, bufbmp.Canvas.ClipRect);
          bufbmp.PixelFormat := pf24bit;
          SetLength(alpha, bufbmp.Width * bufbmp.Height);
          for i2 := 0 to bufbmp.Height - 1 do
          begin
            if PNGpic.AlphaScanline[i2] <> nil then
              CopyMemory(@alpha[i2 * bufbmp.Width], PNGpic.AlphaScanline[i2], bufbmp.Width)
            else
              fillchar(alpha[i2 * bufbmp.Width], bufbmp.Width, $FF);
          end;
          SetLength(tempGRP[i].data, (bufbmp.Width + 2) * bufbmp.Height * 2 + 20);

          tempGRP[i].size := ImportPNG(@bufbmp, PNGXs[i], PNGYs[i], @alpha[0], @tempGRP[i].data[0]);
          bufbmp.Canvas.unLock;
          PNGpic.Canvas.unLock;
          if tempGRP[i].size > 0 then
          begin
            SetLength(tempGRP[i].data, tempGRP[i].size);
          end
          else
          begin
            tempGRP[i].size := 0;
            SetLength(tempGRP[i].data, 0);
          end;
        end;

        PNGimportProgress := round((i + 1) / ImportPNGFileNum) * 100;
        Synchronize(setPNGimportprogress);

      except
        Synchronize(PNGimportError);
        // PNGpic.Destroy;
        // bufbmp.Free;
        Synchronize(enablePNGimportForm);
        exit;
      end;

    end;
  finally
    PNGpic.Destroy;
    bufbmp.Free;
  end;

  if fileexists(ImportPNGIDxname) and fileexists(ImportPNGIDxname) then
  begin
    try
      try
        idx := fileopen(ImportPNGIDxname, fmopenread);
        grp := fileopen(ImportPNGGRPname, fmopenread);
        orilen := fileseek(idx, 0, 2);
        fileseek(idx, 0, 0);
        orilen := orilen shr 2;
        SetLength(oriGRP, orilen);
        SetLength(offset, orilen);
        fileread(idx, offset[0], orilen shl 2);
        param := 0;
        fileseek(grp, 0, 0);
        for i := 0 to orilen - 1 do
        begin
          oriGRP[i].size := offset[i] - param;
          param := offset[i];
          if oriGRP[i].size > 0 then
          begin
            SetLength(oriGRP[i].data, oriGRP[i].size);
            fileread(grp, oriGRP[i].data[0], oriGRP[i].size);
          end;
        end;
      except
        fileclose(idx);
        fileclose(grp);
        PNGimportProgress := 0;
        Synchronize(setPNGimportprogress);
        Synchronize(enablePNGimportForm);
        exit;
      end;
    finally
      fileclose(idx);
      fileclose(grp);
    end;
  end
  else
  begin
    Synchronize(PNGimportNoIDXGRPfile);
    PNGimportProgress := 0;
    Synchronize(setPNGimportprogress);
    Synchronize(enablePNGimportForm);
    exit;
  end;

  len := 0;
  idx := filecreate(ImportPNGIDxname);
  grp := filecreate(ImportPNGGRPname);
  for i := 0 to orilen - 1 do
  begin
    inc(len, oriGRP[i].size);
    filewrite(idx, len, 4);
    if oriGRP[i].size > 0 then
      filewrite(grp, oriGRP[i].data[0], oriGRP[i].size);
  end;
  for i := 0 to ImportPNGFileNum - 1 do
  begin
    inc(len, tempGRP[i].size);
    filewrite(idx, len, 4);
    if tempGRP[i].size > 0 then
      filewrite(grp, tempGRP[i].data[0], tempGRP[i].size);
  end;

  fileclose(idx);
  fileclose(grp);

  Synchronize(PNGimportSuccess);
  PNGimportProgress := 0;
  Synchronize(setPNGimportprogress);
  Synchronize(enablePNGimportForm);
end;

procedure PNGimportNoIDXGRPfile;
begin
  ShowMessage('原IDX或GRP文件不存在！无法保存！');
end;

procedure PNGimportSuccess;
begin
  ShowMessage('成功！');
end;

procedure PNGimportError;
begin
  ShowMessage('出现错误！');
end;

procedure DisablePNGimportForm;
begin
  Form94.Enabled := false;
end;

procedure enablePNGimportForm;
begin
  Form94.Enabled := true;
end;

procedure setPNGimportprogress;
begin
  Form94.ProgressBar1.Position := PNGimportProgress;
end;

function ImportPNG(bufbmp: Pntbitmap; xs, ys: smallint; Palpha, Poridata: Pbyte)
  : Integer;
var
  bufcolor: array of array of byte;
  pw, ph: Integer;
  Pdata: Pbyte;
  tempint: Cardinal;
  ix, iy, i, i2, linesize, len: Integer;
  linebyte, state, trans, transcount, colnum: byte;
begin
  //
  Pdata := Poridata;

  pw := bufbmp.Width;
  ph := bufbmp.Height;

  len := 8;
  bufbmp.PixelFormat := pf24bit;
  SetLength(bufcolor, ph, pw * 3);
  for i := 0 to ph - 1 do
    CopyMemory(@bufcolor[i][0], bufbmp.ScanLine[i], pw * 3);

  (Psmallint(Pdata))^ := pw;
  (Psmallint(Pdata + 2))^ := ph;
  (Psmallint(Pdata + 4))^ := xs;
  (Psmallint(Pdata + 6))^ := ys;
  i := 8;

  for iy := 0 to ph - 1 do
  begin
    trans := 0; // 几次透明像素
    transcount := 0; // 透明像素个数
    // state
    // 为0是初始状态
    // 为1是透明像素状态
    // 为2是普通颜色像素状态
    state := 0;
    linebyte := 0;
    colnum := 0;
    linesize := i;
    inc(i);
    for ix := 0 to pw - 1 do
    begin
      tempint := bufcolor[iy][ix * 3] shl 16 + bufcolor[iy][ix * 3 + 1]
        shl 8 + bufcolor[iy][ix * 3 + 2];
      // tempint := tempcolor[iy][ix];
      // ShowMessage('y:'+inttostr(iy)+'x:'+inttostr(ix)+ 'alpha:'+inttostr((Palpha + iy * pw + ix)^));
      if ((Palpha + iy * pw + ix)^ = 0) then
      begin
        // ShowMessage('1');
        if state <> 1 then
        begin
          if colnum > 0 then
          begin
            // data[i] := transcount;
            // inc(i);

(Pdata + i)
            ^ := colnum;
            inc(i);
            for i2 := i to i + colnum - 1 do
            begin
              tempint := bufcolor[iy][(ix - colnum - i + i2) * 3]
                shl 16 + bufcolor[iy][(ix - colnum - i + i2) * 3 + 1]
                shl 8 + bufcolor[iy][(ix - colnum - i + i2) * 3 + 2];
              // tempint := tempcolor[iy][ix - colnum - I + i2];
(Pdata + i2)
              ^ := MatchCol(tempint);
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
            state := 1;
            inc(trans);
            inc(transcount);
            // inc(linebyte);
          end;
        end
        else
          inc(transcount);
      end
      else // 如果不是透明像素
      begin
        // ShowMessage('2');
        if state <> 2 then
        begin (Pdata + i)
          ^ := transcount;
          inc(linebyte);
          transcount := 0;
          inc(i);
          colnum := 1;
          state := 2;
        end
        else
        begin
          inc(colnum);
        end;

      end;
    end;
    if transcount = pw then
    begin (Pdata + linesize)
      ^ := 0;
    end
    else if colnum > 0 then
    begin
      // data[i] := transcount;
      // inc(i);
(Pdata + i)
      ^ := colnum;
      inc(i);
      for i2 := i to i + colnum - 1 do
      begin
        tempint := bufcolor[iy][(ix - colnum - i + i2) * 3] shl 16 + bufcolor
          [iy][(ix - colnum - i + i2) * 3 + 1] shl 8 + bufcolor[iy]
          [(ix - colnum - i + i2) * 3 + 2];
        // tempint := tempcolor[iy][ix - colnum - I + i2];
(Pdata + i2)
        ^ := MatchCol(tempint);
      end;
      inc(i, colnum);
      inc(linebyte, colnum + 1);
      // state := 0;
      inc(trans);
      // transcount := 0;
(Pdata + linesize)
      ^ := linebyte;
    end
    else (Pdata + linesize)
      ^ := linebyte;
    inc(len, linebyte + 1);

  end;

  SetLength(bufcolor, 0, 0);
  result := len;
end;

function MatchCol(col: Cardinal): byte;
var
  i, min, now, minnum: Integer;
  tempB, tempG, tempR: byte;
begin
  minnum := -1;
  min := -1;
  if minnum < 0 then
    for i := 0 to 255 do
    begin
      tempB := (col and $FF0000) shr 16;
      tempG := (col and $FF00) shr 8;
      tempR := col and $FF;
      now := abs(tempB - PNGB[i]) + abs(tempG - PNGG[i]) + abs(tempR - PNGR[i]);
      if min < 0 then
      begin
        min := now;
        minnum := i;
      end
      else if min > now then
      begin
        min := now;
        minnum := i;
      end;
    end;
  result := minnum;
end;

procedure TForm94.Button1Click(Sender: TObject);
var
  H, len, i: Integer;
begin
  OpenDialog1.Filter := 'Col files (*.Col)|*.Col|All files (*.*)|*.*';
  if OpenDialog1.Execute then
  begin
    Edit1.Text := OpenDialog1.FileName;
    try
      H := fileopen(Edit1.Text, fmopenread);
      len := fileseek(H, 0, 2);
      fileseek(H, 0, 0);
      len := len div 4;
      for i := 0 to len - 1 do
      begin
        fileread(H, PNGR[i], 1);
        fileread(H, PNGG[i], 1);
        fileread(H, PNGB[i], 1);
        PNGB[i] := PNGB[i] shl 2;
        PNGG[i] := PNGG[i] shl 2;
        PNGR[i] := PNGR[i] shl 2;
      end;
    finally
      fileclose(H);
    end;
  end;
end;

procedure TForm94.Button2Click(Sender: TObject);
begin
  OpenDialog1.Filter := 'Idx files (*.Idx)|*.Idx|All files (*.*)|*.*';
  if OpenDialog1.Execute then
  begin
    Edit2.Text := OpenDialog1.FileName;
  end;
end;

procedure TForm94.Button3Click(Sender: TObject);
begin
  OpenDialog1.Filter := 'Grp files (*.Grp)|*.Grp|All files (*.*)|*.*';
  if OpenDialog1.Execute then
  begin
    Edit3.Text := OpenDialog1.FileName;
  end;
end;

procedure TForm94.Button4Click(Sender: TObject);
var
  i: Integer;
  setcontinue: boolean;
  tempx, tempy: Integer;
  tempformat: boolean;
  temptrans: boolean;
  tempcolor: Cardinal;
  PNGrs: TPngObject;
  PNGFormatStr: String;
begin
  if OpenDialog2.Execute then
  begin
    SetLength(PNGFormat, ListBox1.Items.Count + OpenDialog2.Files.Count);
    SetLength(PNGXs, ListBox1.Items.Count + OpenDialog2.Files.Count);
    SetLength(PNGYs, ListBox1.Items.Count + OpenDialog2.Files.Count);
    SetLength(PNGTrans, ListBox1.Items.Count + OpenDialog2.Files.Count);
    SetLength(PNGColor, ListBox1.Items.Count + OpenDialog2.Files.Count);
    SetLength(PNGFileName, ListBox1.Items.Count + OpenDialog2.Files.Count);

    setcontinue := true;
    Form95.CheckBox1.Visible := true;
    Form95.CheckBox1.Checked := false;
    Form95.CheckBox3.Checked := FALSE;
    for i := 0 to OpenDialog2.Files.Count - 1 do
    begin
      PNGFileName[ListBox1.Items.Count] := OpenDialog2.Files.Strings[i];
      if setcontinue then
      begin
        Form95.Edit1.Text := inttostr(0);
        Form95.Edit2.Text := inttostr(0);
        Form95.xoffset := 0;
        Form95.yoffset := 0;
        PNGimportModifybmp := Tbitmap.Create;
        if fileexists(PNGFileName[ListBox1.Items.Count]) then
        begin
          PNGrs := TPngObject.Create;
          PNGrs.LoadFromFile(PNGFileName[ListBox1.Items.Count]);
          PNGimportModifybmp.Width := PNGrs.Width;
          PNGimportModifybmp.Height := PNGrs.Height;
          PNGimportModifybmp.Canvas.Brush.Color := clWhite;
          PNGimportModifybmp.Canvas.FillRect(PNGimportModifybmp.Canvas.ClipRect);
          PNGrs.Draw(PNGimportModifybmp.Canvas, PNGimportModifybmp.Canvas.ClipRect);
          PNGrs.Destroy;
          Form95.Image1.Width := PNGimportModifybmp.Width;
          Form95.Image1.Height := PNGimportModifybmp.Height;
          Form95.Image1.Picture.Bitmap.Width := PNGimportModifybmp.Width;
          Form95.Image1.Picture.Bitmap.Height := PNGimportModifybmp.Height;
          Form95Active := true;
          Form95.DrawOffset;
          Form95Active := false;
        end
        else
        begin
          Form95.Image1.Width := 0;
          Form95.Image1.Height := 0;
          Form95.Image1.Picture.Bitmap.Width := 0;
          Form95.Image1.Picture.Bitmap.Height := 0;
        end;
        Form95Active := true;
        if Form95.ShowModal = mrOk then
        begin
          Form95Active := false;
          PNGXs[ListBox1.Items.Count] := Form95.xoffset;
          PNGYs[ListBox1.Items.Count] := Form95.yoffset;
          PNGFormat[ListBox1.Items.Count] := Form95.CheckBox3.Checked;
          PNGTrans[ListBox1.Items.Count] := Form95.CheckBox2.Checked;
          PNGColor[ListBox1.Items.Count] := Form95.ColorDialog1.Color;
          if Form95.CheckBox1.Checked then
          begin
            tempx := Form95.xoffset;
            tempy := Form95.yoffset;
            tempformat := Form95.CheckBox3.Checked;
            temptrans := Form95.CheckBox2.Checked;
            tempcolor := Form95.ColorDialog1.Color;
            setcontinue := false;
          end;
        end
        else
        begin
          Form95Active := false;
          PNGXs[ListBox1.Items.Count] := 0;
          PNGYs[ListBox1.Items.Count] := 0;
          PNGTrans[ListBox1.Items.Count] := false;
          PNGColor[ListBox1.Items.Count] := 0;
          PNGFormat[ListBox1.Items.Count] := false;
        end;
        PNGimportModifybmp.Free;
      end
      else
      begin
        PNGFormat[ListBox1.Items.Count] := tempformat;
        PNGXs[ListBox1.Items.Count] := tempx;
        PNGYs[ListBox1.Items.Count] := tempy;
        PNGTrans[ListBox1.Items.Count] := temptrans;
        PNGColor[ListBox1.Items.Count] := tempcolor;
      end;
      if PNGFormat[ListBox1.Items.Count] then
      begin
        PNGFormatStr :=  displayname('PNG');
         // + '  X偏移：' + inttostr(PNGXs[ListBox1.Items.Count]) + ' Y偏移：' + inttostr(PNGYs[ListBox1.Items.Count]));
      end
      else
      begin
        PNGFormatStr := displayname('RLE8' + '  X偏移：' + inttostr
        (PNGXs[ListBox1.Items.Count]) + ' Y偏移：' + inttostr(PNGYs[ListBox1.Items.Count]));
      end;
      ListBox1.Items.Add(OpenDialog2.Files.Strings[i] + '  ' + PNGFormatStr);

    end;
  end;
end;

procedure TForm94.Button5Click(Sender: TObject);
var
  PNGrs: TPngObject;
  PNGFormatStr: String;
begin
  if ListBox1.ItemIndex >= 0 then
  begin
    Form95.Edit1.Text := inttostr(PNGXs[ListBox1.ItemIndex]);
    Form95.Edit2.Text := inttostr(PNGYs[ListBox1.ItemIndex]);
    Form95.xoffset := PNGXs[ListBox1.ItemIndex];
    Form95.yoffset := PNGYs[ListBox1.ItemIndex];
    Form95.CheckBox3.Checked := PNGFormat[ListBox1.ItemIndex];
    PNGimportModifybmp := Tbitmap.Create;
    if fileexists(PNGFileName[ListBox1.ItemIndex]) then
    begin
      PNGrs := TPngObject.Create;
      PNGrs.LoadFromFile(PNGFileName[ListBox1.ItemIndex]);
      PNGimportModifybmp.Width := PNGrs.Width;
      PNGimportModifybmp.Height := PNGrs.Height;
      PNGimportModifybmp.Canvas.Brush.Color := clWhite;
      PNGimportModifybmp.Canvas.FillRect(PNGimportModifybmp.Canvas.ClipRect);
      PNGrs.Draw(PNGimportModifybmp.Canvas, PNGimportModifybmp.Canvas.ClipRect);
      PNGrs.Free;
      Form95.Image1.Width := PNGimportModifybmp.Width;
      Form95.Image1.Height := PNGimportModifybmp.Height;
      Form95.Image1.Picture.Bitmap.Width := PNGimportModifybmp.Width;
      Form95.Image1.Picture.Bitmap.Height := PNGimportModifybmp.Height;
      Form95Active := true;
      Form95.DrawOffset;
      Form95Active := false;
    end
    else
    begin
      Form95.Image1.Width := 0;
      Form95.Image1.Height := 0;
      Form95.Image1.Picture.Bitmap.Width := 0;
      Form95.Image1.Picture.Bitmap.Height := 0;
    end;
    Form95.CheckBox1.Visible := false;
    Form95Active := true;
    if Form95.ShowModal = mrOk then
    begin
      Form95Active := false;
      try
        PNGXs[ListBox1.ItemIndex] := Form95.xoffset;
      except
        PNGXs[ListBox1.ItemIndex] := 0;
      end;
      try
        PNGYs[ListBox1.ItemIndex] := Form95.yoffset;
      except
        PNGYs[ListBox1.ItemIndex] := 0;
      end;
      try
        PNGFormat[ListBox1.ItemIndex] := Form95.CheckBox3.Checked;
      except
        PNGFormat[ListBox1.ItemIndex] := true;
      end;
      if PNGFormat[ListBox1.ItemIndex] then
      begin
        PNGFormatStr := displayname('PNG');
         // + '  X偏移：' + inttostr(PNGXs[ListBox1.Items.Count]) + ' Y偏移：' + inttostr(PNGYs[ListBox1.Items.Count]));
      end
      else
      begin
        Form95Active := false;
        PNGFormatStr := displayname('RLE8' + '  X偏移：' + inttostr
        (PNGXs[ListBox1.Items.Count]) + ' Y偏移：' + inttostr(PNGYs[ListBox1.Items.Count]));
      end;
      ListBox1.Items.Add(OpenDialog2.Files.Strings[ListBox1.ItemIndex] + '  ' + PNGFormatStr);
        
    end;
    PNGimportModifybmp.Free;
  end;
end;

procedure TForm94.Button6Click(Sender: TObject);
var
  i, i2: Integer;
begin
  for i := ListBox1.Items.Count - 1 downto 0 do
  begin
    if ListBox1.Selected[i] then
    begin
      for i2 := i to ListBox1.Items.Count - 2 do
      begin
        PNGFormat[i2] := PNGFormat[i2 + 1];
        PNGXs[i2] := PNGXs[i2 + 1];
        PNGYs[i2] := PNGYs[i2 + 1];
        PNGFileName[i2] := PNGFileName[i2 + 1]
      end;
      ListBox1.Items.Delete(i);
      SetLength(PNGFormat, ListBox1.Items.Count);
      SetLength(PNGXs, ListBox1.Items.Count);
      SetLength(PNGYs, ListBox1.Items.Count);
      SetLength(PNGFileName, ListBox1.Items.Count);
    end;
  end;
end;

procedure TForm94.Button7Click(Sender: TObject);
begin
  self.Close;
end;

procedure TForm94.Button8Click(Sender: TObject);
begin
  ImportPNGFileNum := ListBox1.Items.Count;
  if ImportPNGFileNum > 0 then
  begin
    ImportPNGIDxname := Edit2.Text;
    ImportPNGGRPname := Edit3.Text;
    PNGimortThread := TPNGimportThread.Create(false);
  end
  else
  begin
    ShowMessage('没有可以导入的PNG文件！');
  end;
end;

procedure TForm94.ComboBox1Change(Sender: TObject);
var
  temp: Integer;
  namestr, opstr: string;
begin
  if ComboBox1.ItemIndex < grplistnum then
  begin
    if grplistnum > 0 then
    begin
      Edit2.Text := gamepath + grplistidx[ComboBox1.ItemIndex];
      Edit3.Text := gamepath + grplistgrp[ComboBox1.ItemIndex];
    end;
  end
  else
  begin
    temp := ComboBox1.ItemIndex;
    if grplistnum > 0 then
      temp := temp - grplistnum;
    if temp < 10 then
      namestr := '00' + inttostr(temp)
    else if temp < 100 then
      namestr := '0' + inttostr(temp)
    else
      namestr := inttostr(temp);
    opstr := fightidx;
    opstr := StringReplace(opstr, '***', namestr, [rfReplaceAll]);
    Edit2.Text := gamepath + opstr;
    opstr := fightgrp;
    opstr := StringReplace(opstr, '***', namestr, [rfReplaceAll]);
    Edit3.Text := gamepath + opstr;

  end;
end;

procedure TForm94.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ImportPNGFileNum := 0;
  SetLength(PNGFormat, 0);
  SetLength(PNGXs, 0);
  SetLength(PNGYs, 0);
  CForm94 := true;
  Action := cafree;
end;

procedure TForm94.FormCreate(Sender: TObject);
var
  H, len, i: Integer;
  colname: string;
begin
  ImportPNGFileNum := 0;
  SetLength(PNGFormat, 0);
  SetLength(PNGXs, 0);
  SetLength(PNGYs, 0);

  colname := gamepath + palette;
  if fileexists(colname) then
  begin
    Edit1.Text := colname;
    try
      H := fileopen(Edit1.Text, fmopenread);
      len := fileseek(H, 0, 2);
      fileseek(H, 0, 0);
      len := len div 3;
      for i := 0 to len - 1 do
      begin
        fileread(H, PNGR[i], 1);
        fileread(H, PNGG[i], 1);
        fileread(H, PNGB[i], 1);
        PNGB[i] := PNGB[i] shl 2;
        PNGG[i] := PNGG[i] shl 2;
        PNGR[i] := PNGR[i] shl 2;
      end;
    finally
      fileclose(H);
    end;
  end;

  ComboBox1.Items.Clear;
  if grplistnum > 0 then
    for i := 0 to grplistnum - 1 do
      ComboBox1.Items.Add(displayname(grplistname[i]));
  if fightgrpnum > 0 then
    for i := 0 to fightgrpnum - 1 do
      ComboBox1.Items.Add(displayname(fightname + inttostr(i)));

end;

procedure TForm94.ListBox1DblClick(Sender: TObject);
begin
  Button5Click(Sender);
end;

procedure TForm94.ListBox1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  mpos: TPoint;
begin
  if Button = mbRight then
  begin
    getcursorpos(mpos);
    PopupMenu1.Popup(mpos.X, mpos.Y);
  end;
end;

procedure TForm94.N1Click(Sender: TObject);
begin
  Button5Click(Sender);
end;

procedure TForm94.N2Click(Sender: TObject);
begin
  Button6Click(Sender);
end;

procedure TForm94.N3Click(Sender: TObject);
begin
  Button4Click(Sender);
end;

end.
