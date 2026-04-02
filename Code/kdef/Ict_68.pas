unit Ict_68;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, head, PNGimage, StdCtrls, ExtCtrls, math;

type
  TForm38 = class(TForm)
    ComboBox1: TComboBox;
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    Image1: TImage;
    Image2: TImage;
    RadioGroup1: TRadioGroup;
    Edit1: TEdit;
    Image3: TImage;
    Image4: TImage;
    Edit2: TEdit;
    Edit3: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    Label4: TLabel;
    ComboBox4: TComboBox;
    Label5: TLabel;
    Label6: TLabel;
    Edit4: TEdit;
    ComboBox5: TComboBox;
    Label7: TLabel;
    Button3: TButton;
    Edit5: TEdit;
    Button4: TButton;
    Button5: TButton;
    ListBox1: TListBox;
    Edit6: TEdit;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    procedure initial(atrb:Pattrib);
    procedure drawhead(num: integer);
    procedure FormCreate(Sender: TObject);
    procedure Drawpallet;
    procedure Image2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ComboBox1Change(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure ComboBox5Select(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
  private
    { Private declarations }
  public

    { Public declarations }
  end;

var
  Form38: TForm38;
  headpicnum: integer;

implementation

uses
  kdefedit, picedit;

{$R *.dfm}
procedure TForm38.FormCreate(Sender: TObject);
var
  I,F: integer;
begin
  try
    if not fileexists(gamepath + headpicname) then
      exit;
    F := fileopen(gamepath + headpicname, fmopenread);
    fileread(F, headpicnum, 4);
    combobox1.Clear;
    for I := 0 to headpicnum - 1 do
      combobox1.Items.Add(inttostr(I));
    fileclose(F);
  except
    exit;
  end;

end;

procedure TForm38.Image2MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  temp1,temp2,temp3: smallint;
begin
  if radiogroup1.ItemIndex = 0 then
  begin
    edit1.Text := inttostr((Y div 12 * 16) + x div 12);
    temp1 := strtoint(edit1.Text);
    temp2 := strtoint(edit2.Text);
    temp3 := temp2 shl 8 + temp1;
    edit3.Text := inttostr(temp3);
    image3.Canvas.Brush.Color := McolB[temp1] shl 16 + McolG[temp1] + McolR[temp1];
    image3.Canvas.FillRect(image3.Canvas.ClipRect);
  end
  else
  begin
    edit2.Text := inttostr((Y div 12 * 16) + x div 12);
    temp1 := strtoint(edit1.Text);
    temp2 := strtoint(edit2.Text);
    temp3 := temp2 shl 8 + temp1;
    edit3.Text := inttostr(temp3);
    image4.Canvas.Brush.Color := McolB[temp2] shl 16 + McolG[temp2] + McolR[temp2];
    image4.Canvas.FillRect(image4.Canvas.ClipRect);
  end;
end;

procedure TForm38.initial(atrb:Pattrib);
var
  I,F: integer;
begin
  //
  try
    F := fileopen(gamepath + headpicname, fmopenread);
    fileread(F, headpicnum, 4);
    combobox1.Clear;
    for I := 0 to headpicnum - 1 do
      combobox1.Items.Add(inttostr(I));
    fileclose(F);
  except
    exit;
  end;
  combobox2.Clear;
  listbox1.Clear;
  combobox2.Items.Add('-2默认值');
  for I := 0 to namestrnum - 1 do
  begin
    combobox2.Items.Add(inttostr(I)+ ':' + displaystr(readTalkStr(@namestr[I])));
    listbox1.Items.Add(inttostr(I)+ ':' + displaystr(readTalkStr(@namestr[I])));
  end;
  combobox5.clear;
  for I := 0 to talkstrnum - 1 do
    combobox5.Items.Add(inttostr(I)+ ':' + displaystr(readTalkStr(@talkstr[I])));
  drawpallet;
  combobox1.ItemIndex := atrb.par[1];
  if atrb.par[3] >= 0 then
    combobox2.ItemIndex := atrb.par[3] + 1
  else
    combobox2.ItemIndex := 0;
  if combobox1.ItemIndex >= 0 then
    drawhead(combobox1.ItemIndex);
  combobox5.ItemIndex := atrb.par[2];
  combobox3.ItemIndex := atrb.par[4];
  combobox4.ItemIndex := atrb.par[5];
  edit3.Text := inttostr(atrb.par[6]);
  edit1.Text := inttostr(atrb.par[6] and $FF);
  edit2.Text := inttostr((atrb.par[6] shr 8) and $FF);
  edit4.Text := inttostr(atrb.par[7]);
  if combobox5.ItemIndex >= 0 then
    edit5.Text := displaystr(readTalkStr(@talkstr[combobox5.ItemIndex]));
  if listbox1.ItemIndex >= 0 then
    edit6.Text := displaystr(readTalkStr(@namestr[listbox1.ItemIndex]));
  image3.Canvas.Brush.Color := McolB[strtoint(edit1.Text)] shl 16 + McolG[strtoint(edit1.Text)] + McolR[strtoint(edit1.Text)];
  image3.Canvas.FillRect(image3.Canvas.ClipRect);
    image4.Canvas.Brush.Color := McolB[strtoint(edit2.Text)] shl 16 + McolG[strtoint(edit2.Text)] + McolR[strtoint(edit2.Text)];
    image4.Canvas.FillRect(image4.Canvas.ClipRect);
end;

procedure TForm38.ListBox1Click(Sender: TObject);
begin
  if listbox1.ItemIndex >= 0 then
    edit6.Text := displaystr(readTalkStr(@namestr[listbox1.ItemIndex]));
end;

procedure TForm38.Button3Click(Sender: TObject);
begin
  inc(talkstrnum);
  setlength(talkstr, talkstrnum);
  WriteTalkStr(@talkstr[talkstrnum - 1], widestring('請輸入對話內容，若為原版對話，每隔12個漢字加一個星號*'));
  combobox5.Items.Add(inttostr(talkstrnum - 1) +':' +displaystr(ReadTalkStr(@talkstr[talkstrnum - 1])));
  combobox5.ItemIndex := talkstrnum - 1;
  edit5.Text := displaystr(readTalkStr(@talkstr[talkstrnum - 1]));
end;

procedure TForm38.Button4Click(Sender: TObject);
var
  temp2, I: integer;
begin
  temp2 := combobox5.ItemIndex;
  WriteTalkStr(@talkstr[combobox5.ItemIndex].str, displaybackstr(edit5.Text));
  combobox5.Clear;
  for I := 0 to talkstrnum - 1 do
    combobox5.Items.Add(inttostr(I) +':' +displaystr(readTalkStr(@talkstr[I])));
  combobox5.ItemIndex := temp2;
end;

procedure TForm38.Button5Click(Sender: TObject);
var
  I: integer;
begin
  if talkstrnum <> 1 then
  begin
    dec(talkstrnum);
    setlength(talkstr, talkstrnum);
    combobox5.Items.Delete(talkstrnum);
    combobox5.ItemIndex := talkstrnum - 1;
    edit5.Text := displaystr(ReadTalkStr(@talkstr[talkstrnum - 1]));
  end
  else
    showmessage('只剩一个对话，不可删除');
end;

procedure TForm38.Button6Click(Sender: TObject);
begin
  inc(namestrnum);
  setlength(namestr, namestrnum);
  WriteTalkStr(@namestr[namestrnum - 1], widestring(edit6.Text));
  listbox1.Items.Add(inttostr(namestrnum - 1)+ ':' + displaystr(readtalkstr(@namestr[namestrnum - 1])));
  listbox1.ItemIndex := namestrnum - 1;
  combobox2.Items.Add(inttostr(namestrnum - 1)+ ':' + displaystr(readtalkstr(@namestr[namestrnum - 1])))
end;

procedure TForm38.Button7Click(Sender: TObject);
var
  I,temp1,temp2: integer;
begin
  if listbox1.ItemIndex >= 0 then
  begin
    WriteTalkStr(@namestr[listbox1.ItemIndex], widestring(edit6.Text));
    temp1 := combobox2.ItemIndex;
    temp2 := listbox1.ItemIndex;
    combobox2.Clear;
   // listbox1.Clear;
    listbox1.Items.Strings[listbox1.ItemIndex] :=  inttostr(listbox1.ItemIndex) + ':' + displaystr(readTalkstr(@namestr[listbox1.ItemIndex]));
    combobox2.Items.Add('-2默认值');
    for I := 0 to namestrnum - 1 do
    begin
      combobox2.Items.Add(inttostr(I)+ ':' + displaystr(readtalkstr(@namestr[I])));
     // listbox1.Items.Add(inttostr(I)+ ':' + displaystr(readoutstr(namestr[I].str)));
    end;
    combobox2.ItemIndex := temp1;
    listbox1.ItemIndex := temp2;
  end;
end;

procedure TForm38.Button8Click(Sender: TObject);
var
  Fidx, Fgrp, I, i2, len: integer;
  talkoffset: array of integer;
  tdata: array of byte;
begin
  Fidx := filecreate(gamepath + nameidx);
  Fgrp := filecreate(gamepath + namegrp);
  setlength(talkoffset, namestrnum);
  len := 0;
  for I := 0 to namestrnum - 1 do
  begin
    talkoffset[I] := max(namestr[I].len, 0);
    inc(len, talkoffset[I]);
    setlength(tdata, talkoffset[I]);
    if talkoffset[I] > 0 then
      copymemory(@tdata[0], @namestr[I].str[0], talkoffset[I]);
    if talkinvert = 0 then
    begin
      for i2 := 0 to talkoffset[I] - 1 do
      begin
        tdata[i2] := tdata[i2] xor $FF;
        if tdata[i2] = $FF then
          tdata[i2] := 0;
      end;
    end;
    filewrite(Fidx, len, 4);
    if talkoffset[I] > 0 then
      filewrite(Fgrp, tdata[0], talkoffset[I]);
  end;
  fileclose(Fidx);
  fileclose(Fgrp);
end;

procedure TForm38.ComboBox1Change(Sender: TObject);
begin
  drawhead(combobox1.ItemIndex);
end;

procedure TForm38.ComboBox5Select(Sender: TObject);
begin
  edit5.Text := displaystr(readtalkstr(@talkstr[combobox5.ItemIndex]));
end;

procedure TForm38.drawhead(num: integer);
var
  data:array of byte;
  F, offset, len: integer;
  PNG:TPNGObject;
  rs:Tmemorystream;
begin
  //
  try
  image1.Canvas.Brush.Color := clwhite;
  image1.Canvas.FillRect(image1.Canvas.ClipRect);
  F := fileopen(gamepath + headpicname, fmopenread);
  if num = 0 then
  begin
    offset := headpicnum * 4 + 4;
    fileseek(F, 4, 0);
    fileread(F, len, 4);
    offset := 12 + offset;
    len := len - offset;
  end
  else
  begin
    fileseek(F, 4*num, 0);
    fileread(F, offset, 4);
    fileread(F, len, 4);
    offset := offset + 12;
    len := len - offset;
  end;
  setlength(data, len);
  fileseek(F,offset,0);
  fileread(F,data[0],len);
  fileclose(F);
  rs := TmemoryStream.Create;
  rs.Position := 0;
  rs.write(data[0], len);
  rs.Position := 0;
  PNG := TpngObject.Create;
  PNG.LoadFromStream(rs);
  rs.Free;
  PNG.Draw(image1.Canvas,PNG.Canvas.ClipRect);
  PNG.Free;
  image1.Refresh;
  except
    exit;
  end;
end;

procedure TForm38.Drawpallet;
var
  ix, iy, i: integer;
  wide : integer;
  tempbmp: TBitmap;
begin
  wide := 12;
  tempbmp := tbitmap.Create;
  tempbmp.Width :=  16;
  tempbmp.Height :=  16;
  //tempbmp.PixelFormat := pf24bit;
  //if edittype = pic then
 // begin
    for i := 0 to Mcollen - 1 do
    begin
      iy := i div 16;
      ix := i mod 16;

          tempbmp.canvas.pixels[ix, iy] := McolB[I] shl 16 + McolG[I] shl 8 + McolR[I];
          {pos := tempbmp.ScanLine[i2];
          (pos + i1 * 3)^ := R[I];
          (pos + i1 * 3 + 1)^ := G[I];
          (pos + i1 * 3 + 2)^ := B[I];}

    end;
    image2.Canvas.CopyRect(image2.Canvas.ClipRect, tempbmp.Canvas, tempbmp.Canvas.ClipRect);
 // end;
   tempbmp.Free;
end;

end.
