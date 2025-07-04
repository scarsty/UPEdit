unit WarEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, head, inifiles, ExtCtrls, StdCtrls, math, ComCtrls, Spin, IMZObject,
  comobj,
  System.IOUtils,
  // VCL.FlexCel.Core, FlexCel.XlsAdapter{, XLSFonts4, XLSReadWriteII4, SheetData4};
  xlsxio;

type

  TForm10 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    ListBox1: TListBox;
    Button1: TButton;
    ComboBox1: TComboBox;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Panel3: TPanel;
    Label1: TLabel;
    StatusBar1: TStatusBar;
    StatusBar2: TStatusBar;
    ScrollBox1: TScrollBox;
    Panel4: TPanel;
    SpinEdit1: TSpinEdit;
    Label2: TLabel;
    Image1: TImage;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Button5: TButton;
    Button6: TButton;
    Button11: TButton;
    Button12: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
    procedure displayW;
    procedure FormResize(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ComboBox1Select(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure CheckBox1Click(Sender: TObject);
    procedure countwarpos;
    procedure drawwarpoint(posx, posy: integer; color: cardinal);
    procedure drawwarpos;
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
    procedure ListBox1Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
    procedure ReadWModeIni;
    procedure displaywareditmap(waropMap: Pmap; waropbmp2: PNTbitmap);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  var
    ImzFile: TimzFile;
    WarEditMode: TMapEditMode;

  end;

var
  warFile: TWfile;
  wselect: array of TWSelect;
  poseditmap: tbitmap;
  wareditgrp: array of Tgrppic;
  wareditmapfile: Tmapstruct;
  autowarfriend: boolean = false;
  warfriendnum: integer;
  warfriend: array of Twarpos;
  warenemynum: integer;
  warenemy: array of Twarpos;
  wareditbmp: tbitmap;
  iswarmapperson: boolean = false;
  warmappersontype: integer;
  warmappersonnum: integer;
  warselectcontinue: integer;
  warsmallmapsize: integer;
  warexcelopname: string = '战斗数据';

  strings: array [0 .. 9999] of array [0 .. 9999] of ansistring;

procedure readWini;
function readW(grp: string; PWF: PWFile): boolean;
procedure CalWnamePos(PWF: PWFile);
function calWname(index: integer): widestring;
procedure readWareditgrp;
procedure addnewWdata(PWF: PWFile; PWD: PRData);

implementation

uses
  main, Redit, ReditForm, warmapedit;

{$R *.dfm}

procedure addnewWdata(PWF: PWFile; PWD: PRData);
var
  i3, i4, i5, temp: integer;
begin

  if PWF.Wtype.datanum < 0 then
    PWF.Wtype.datanum := 0;
  inc(PWF.Wtype.datanum);
  Setlength(PWF.Wtype.Rdata, PWF.Wtype.datanum);

  temp := 0;
  for i3 := 0 to Wtypedataitem - 1 do
    if Wini.Wterm[i3].datanum > 0 then
      inc(temp);
  PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].num := temp;
  Setlength(PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline, PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].num);

  temp := -1;
  for i3 := 0 to Wtypedataitem - 1 do
  begin
    if Wini.Wterm[i3].datanum > 0 then
    begin
      inc(temp);
      PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].len := Wini.Wterm[i3].datanum;
      Setlength(PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray, Wini.Wterm[i3].datanum);
      for i4 := 0 to Wini.Wterm[i3].datanum - 1 do
      begin
        PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].incnum := Wini.Wterm[i3].incnum;
        Setlength(PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray, PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].incnum);
        for i5 := 0 to Wini.Wterm[i3].incnum - 1 do
        begin
          PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datatype := Wini.Wterm[i3 + i5].isstr;
          PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen := Wini.Wterm[i3 + i5].datalen;
          if PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen >= 0 then
            Setlength(PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].data, PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen)
          else
          begin
            PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen := 0;
            Setlength(PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].data, PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen);
          end;
          if PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen > 0 then
            zeromemory(@PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].data[0], PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray
              [i5].datalen);
        end;
      end;
    end;
  end;

  if PWD <> nil then
    copyRdata(PWD, @PWF.Wtype.Rdata[PWF.Wtype.datanum - 1]);

end;

procedure TForm10.ReadWModeIni;
var
  filename: string;
  ini: Tinifile;
begin
  //
  filename := StartPath + iniFilename;
  try
    ini := Tinifile.Create(filename);
    WarEditMode := TMapEditMode(ini.ReadInteger('File', 'WarMode', integer(WarEditMode)));
  finally
    ini.Free;
  end;
end;

procedure readWini;
var
  iniF: Tinifile;
  iniFilename1, tempstr: string;
  strlist: Tstringlist;
  i1, i2: integer;
  strnum: integer;

begin
  try
    iniFilename1 := StartPath + iniFilename;
    iniF := Tinifile.Create(iniFilename1);
    // Wtypenumber := iniF.ReadInteger('W_Modify','TypeNumber',0);
    // edit1.Text := inttostr(typenumber);

    // setlength(Wini, Wtypenumber);
    // setlength(Wtypedataitem, Wtypenumber);
    // setlength(Wtypename, Wtypenumber);
    strlist := Tstringlist.Create;
    // Wtypename[I1] := iniF.ReadString('W_Modify', 'typename' + inttostr(i1), '');
    Wtypedataitem := iniF.ReadInteger('W_Modify', 'typedataitem', 0);
    warselectcontinue := iniF.ReadInteger('W_Modify', 'selectcontinue', 0);
    if Wtypedataitem > 0 then
    begin
      Setlength(Wini.Wterm, Wtypedataitem);
      for i1 := 0 to Wtypedataitem - 1 do
      begin
        strlist.Clear;
        tempstr := iniF.ReadString('W_Modify', 'data(' + inttostr(i1) + ')', '');
        if tempstr <> '' then
        begin
          strnum := ExtractStrings([' '], [], Pwidechar(tempstr), strlist);
          if strnum = 11 then
          begin
            with Wini.Wterm[i1] do
            begin
              datanum := strtoint64(strlist.strings[0]);
              incnum := strtoint64(strlist.strings[1]);
              datalen := strtoint64(strlist.strings[2]);
              isstr := strtoint64(strlist.strings[3]);
              isname := strtoint64(strlist.strings[4]);
              quote := strtoint64(strlist.strings[5]);
              name := strlist.strings[6];
              note := strlist.strings[7];
              ismapnum := strtoint64(strlist.strings[8]);
              labeltype := strtoint64(strlist.strings[9]);
              labelnum := strtoint64(strlist.strings[10]);
            end;
          end;
        end;
      end;

    end;

    strlist.Free;

    iniF.Free;
  except
    // showmessage('读取ini文件错误！');
    exit;
  end;
end;

function readW(grp: string; PWF: PWFile): boolean;
var
  offset: array of integer;
  i1, i2, i3, i4, i5: integer;
  size, F, temp, filelen: integer;
begin
  result := false;
  if fileexists(grp) then
  begin
    try
      PWF.Wtype.datanum := 0;
      PWF.Wtype.namepos := -1;
      PWF.Wtype.mappos := -1;
      Setlength(PWF.Wtype.Rdata, 0);
      F := fileopen(grp, fmopenread);
      size := 0;
      for i2 := 0 to Wtypedataitem - 1 do
      begin
        if Wini.Wterm[i2].datanum > 0 then
          for i3 := i2 to i2 + Wini.Wterm[i2].incnum - 1 do
          begin
            inc(size, Wini.Wterm[i2].datanum * Wini.Wterm[i3].datalen);
          end;
      end;

      filelen := fileseek(F, 0, 2);
      fileseek(F, 0, 0);
      size := filelen div size;
      PWF.Wtype.datanum := 0;
      Setlength(PWF.Wtype.Rdata, PWF.Wtype.datanum);

      for i2 := 0 to size - 1 do
      begin
        addnewWdata(PWF, nil);
      end;

      for i2 := 0 to PWF.Wtype.datanum - 1 do
      begin
        // temp := 0;
        // for i3 := 0 to Wtypedataitem - 1 do
        // if Wini.Wterm[i3].datanum > 0 then
        // inc(temp);
        // PWF.Wtype.Rdata[i2].num := temp;
        // setlength(PWF.Wtype.Rdata[i2].Rdataline, temp);
        temp := -1;
        for i3 := 0 to Wtypedataitem - 1 do
        begin
          if Wini.Wterm[i3].datanum > 0 then
          begin
            inc(temp);
            if (i3 = 0) and (Wini.Wterm[i3].isname = 1) then
              PWF.Wtype.namepos := temp;
            // PWF.Wtype.Rdata[i2].Rdataline[temp].len := Wini.wterm[i3].datanum;
            // setlength(PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray, Wini.wterm[i3].datanum);
            // setlength(Rfile[i1].Rdata[i2].Rdataline[i3].datatype, Rini[i1].Rterm[i3].incnum);
            // setlength(Rfile[i1].Rdata[i2].Rdataline[i3].Rarray, Rini[i1].Rterm[i3].incnum);
            for i4 := 0 to Wini.Wterm[i3].datanum - 1 do
            begin
              // PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray[i4].incnum := wini.Wterm[i3].incnum;
              // setlength(PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray[i4].dataarray, wini.Wterm[i3].incnum);
              for i5 := 0 to Wini.Wterm[i3].incnum - 1 do
              begin
                // PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].datalen := Wini.Wterm[i3 + i5].datalen;
                // PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].datatype := Wini.Wterm[i3 + i5].isstr;
                // setlength(PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].Data, Wini.Wterm[i3 + i5].datalen);
                if PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].datalen > 0 then
                  fileread(F, PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].data[0], Wini.Wterm[i3 + i5].datalen);
              end;
            end;
          end;
        end;
      end;

      fileclose(F);

      result := true;
    except
      // showmessage('读取文件错误！');
      fileclose(F);
      exit;
    end;
  end;
end;

procedure TForm10.countwarpos;
var
  warmax, tempwar, I: integer;
begin

  autowarfriend := false;
  for I := 0 to ListBox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = 7) and (ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3]) >= 0) then
      autowarfriend := true;
  end;

  if autowarfriend then
    tempwar := 7
  else
    tempwar := 5;
  // 队友数据
  warmax := 0;
  for I := 0 to ListBox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = tempwar) then
      if warmax < wselect[I].labelcount then
        warmax := wselect[I].labelcount;
  end;
  warfriendnum := warmax;
  Setlength(warfriend, warfriendnum);

  for I := 0 to ListBox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = tempwar) then
      warfriend[wselect[I].labelcount - 1].personnum := ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3]);
  end;

  for I := 0 to ListBox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = 1) and (wselect[I].labeltype = 1) and (wselect[I].labelcount <= warmax) then
      warfriend[wselect[I].labelcount - 1].X := ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3]);
  end;

  for I := 0 to ListBox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = 2) and (wselect[I].labeltype = 1) and (wselect[I].labelcount <= warmax) then
      warfriend[wselect[I].labelcount - 1].Y := ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3]);
  end;

  // 敌人数据
  warmax := 0;
  tempwar := 6;
  for I := 0 to ListBox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = tempwar) then
      if warmax < wselect[I].labelcount then
        warmax := wselect[I].labelcount;
  end;

  warenemynum := warmax;
  Setlength(warenemy, warenemynum);

  for I := 0 to ListBox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = tempwar) then
      warenemy[wselect[I].labelcount - 1].personnum := ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3]);
  end;

  for I := 0 to ListBox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = 3) and (wselect[I].labeltype = 2) and (wselect[I].labelcount <= warmax) then
      warenemy[wselect[I].labelcount - 1].X := ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3]);
  end;

  for I := 0 to ListBox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = 4) and (wselect[I].labeltype = 2) and (wselect[I].labelcount <= warmax) then
      warenemy[wselect[I].labelcount - 1].Y := ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3]);
  end;
  drawwarpos;

end;

procedure TForm10.Button11Click(Sender: TObject);
var
  filename: string;
  i2, i3, i4, i5: integer;
  temp, temp2: integer;
  xls: plxw_workbook;
  sheet: plxw_worksheet;
begin
  SaveDialog1.Filter := 'excel文件|*.xlsx';
  if SaveDialog1.Execute then
  begin
    try
      filename := SaveDialog1.filename;
      if not SameText(ExtractFileExt(filename), '.xlsx') then
        filename := filename + '.xlsx';
      xls := workbook_new(pansichar(UnicodeToMulti(Pwidechar(filename), 65001)));
      sheet := workbook_add_worksheet(xls, 'Sheet1');
      temp := 1;
      for i2 := 0 to Wtypedataitem - 1 do
      begin
        for i3 := 0 to Wini.Wterm[i2].datanum - 1 do
          for i4 := 0 to Wini.Wterm[i2].incnum - 1 do
          begin
            if i3 > 0 then
            begin
              worksheet_write_string(sheet, 0, temp - 1, pansichar(UnicodeToMulti(Pwidechar(displaystr(Wini.Wterm[i2 + i4].name + inttostr(i3))), 65001)), nil)
              // xls.SetCellValue(1, temp, displaystr(Wini.Wterm[i2 + i4].name + inttostr(i3)));
              // XLSReadWriteII41.Sheets[0].AsString[temp, 0] := displaystr(Wini.Wterm[i2 + i4].name + inttostr(i3));
            end
            else
              worksheet_write_string(sheet, 0, temp - 1, pansichar(UnicodeToMulti(Pwidechar(displaystr(Wini.Wterm[i2 + i4].name)), 65001)), nil);
            // xls.SetCellValue(1, temp, displaystr(Wini.Wterm[i2 + i4].name));
            // XLSReadWriteII41.Sheets[0].AsString[temp, 0] := displaystr(Wini.Wterm[i2 + i4].name);
            inc(temp);
          end;
      end;

      for i2 := 0 to warFile.Wtype.datanum - 1 do
      begin
        temp := 1;
        for i3 := 0 to warFile.Wtype.Rdata[i2].num - 1 do
          for i4 := 0 to warFile.Wtype.Rdata[i2].Rdataline[i3].len - 1 do
            for i5 := 0 to warFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
            begin
              if warFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].datatype = 1 then
                worksheet_write_string(sheet, i2 + 1, temp - 1, pansichar(UnicodeToMulti(Pwidechar(displaystr(readRDataStr(@warFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]))),
                  65001)), nil)
                // xls.SetCellValue(i2+2, temp, displaystr(readRDataStr(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5])))
                // XLSReadWriteII41.Sheets[0].AsString[temp, i2 + 1]:= displaystr(readRDataStr(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]))
              else
                worksheet_write_number(sheet, i2 + 1, temp - 1, ReadRDataInt(@warFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]), nil);
              // xls.SetCellValue(i2+2, temp, readRDataInt(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]));
              // XLSReadWriteII41.Sheets[0].Asinteger[temp, i2 + 1] := readRDataInt(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]);
              inc(temp);
            end;
      end;

      // XLSReadWriteII41.Write;
      // XLSReadWriteII41.Free;
      // ExcelApp:=Unassigned;
      // xls.Save(FileName);
      workbook_close(xls);
      showmessage('导出Excel成功！');
    except
      showmessage('导出Excel错误！');
      exit;
    end;
  end;

end;

procedure TForm10.Button12Click(Sender: TObject);
var
  i2, i3, i4, i5: integer;
  temp: integer;
  // XLSReadWriteII41 : TXLSReadWriteII4;
  // xls: TXlsFile;
  XF: integer;
  // cell: TCellValue;
  xls: xlsxioreader;
  sheet: xlsxioreadersheet;
  value: pansichar;
  i1: integer;
begin

  OpenDialog1.Filter := 'excel表格文件|*.xlsx';
  if OpenDialog1.Execute then
  begin
    try
      // XLSReadWriteII41 := TXLSReadWriteII4.Create(self);
      // XLSReadWriteII41.Clear;
      // XLSReadWriteII41.Filename := opendialog1.Filename;
      // XLSReadWriteII41.Read;
      // xls := TXlsFile.Create (opendialog1.Filename);
      // xls.ActiveSheetByName := 'Sheet1';
      xls := xlsxioread_open(pansichar(UnicodeToMulti(Pwidechar(OpenDialog1.filename), 936)));
      sheet := xlsxioread_sheet_open(xls, 'Sheet1', XLSXIOREAD_SKIP_EMPTY_ROWS);
      i2 := 0;
      // while True do
      // begin
      // xf:=-1;
      // if i2>xls.RowCount then
      // break;
      // cell := xls.GetCellValueIndexed(i2, 1, XF);
      // if cell.IsEmpty then
      // if XLSReadWriteII41.Sheets[0].AsString[0,i2] = '' then
      // break;
      // inc(i2);
      // end;
      i1 := 0;
      while (xlsxioread_sheet_next_row(sheet) <> 0) do
      begin
        i1 := 0;
        while true do
        begin
          value := xlsxioread_sheet_next_cell(sheet);
          if value = nil then
            break;
          strings[i2][i1] := value;
          inc(i1);
        end;
        inc(i2);
      end;

      warFile.Wtype.datanum := 0;
      Setlength(warFile.Wtype.Rdata, warFile.Wtype.datanum);

      for i3 := 0 to i2 - 2 do
      begin
        addnewWdata(@warFile, nil);
      end;

      for i2 := 0 to warFile.Wtype.datanum - 1 do
      begin
        temp := 0;
        for i3 := 0 to warFile.Wtype.Rdata[i2].num - 1 do
        begin
          for i4 := 0 to warFile.Wtype.Rdata[i2].Rdataline[i3].len - 1 do
          begin
            for i5 := 0 to warFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
            begin
              // WriteRDataStr(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], displaybackstr(XLSReadWriteII41.Sheets[0].AsString[temp, i2 + 1]));
              // showmessage(xls.GetStringFromCell(temp+1,i2+1));
              // cell := xls.GetCellValueIndexed(i2+2, temp+1, XF);
              // WriteRDataStr(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], cell.ToSimpleString);
              // value := xlsxioread_sheet_next_cell(sheet);
              WriteRDataStr(@warFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], utf8toansi(strings[i2 + 1][temp]));
              inc(temp);
            end;
          end;
        end;
      end;

      // xls.Free;
      // XLSReadWriteII41.Free;
      xlsxioread_sheet_close(sheet);
      xlsxioread_close(xls);

      CalWnamePos(@warFile);
      ComboBox1.Clear;
      for i2 := 0 to warFile.Wtype.datanum - 1 do
        ComboBox1.Items.Add(calWname(i2));
      ComboBox1.ItemIndex := 0;

      ComboBox1Select(Sender);

      showmessage('导入Excel成功！');
    except
      showmessage('导入Excel错误！');
      exit;
    end;
  end;
end;

procedure TForm10.Button1Click(Sender: TObject);
var
  I: integer;
  wareditbufbmp: tbitmap;
begin
  readW(gamepath + wardata, @warFile);
  CalWnamePos(@warFile);
  ComboBox1.Clear;
  for I := 0 to warFile.Wtype.datanum - 1 do
    ComboBox1.Items.Add(calWname(I));
  ComboBox1.ItemIndex := 0;
  displayW;

  if CheckBox1.Checked then
  begin
    try
      if (ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[warFile.Wtype.mappos].Rarray[0].dataarray[0]) >= 0) and
        (ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[warFile.Wtype.mappos].Rarray[0].dataarray[0]) < wareditmapfile.num) then
        displaywareditmap(@wareditmapfile.map[ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[warFile.Wtype.mappos].Rarray[0].dataarray[0])], @poseditmap)
      else
      begin
        poseditmap.Canvas.Brush.color := clBlack;
        poseditmap.Canvas.Brush.Style := bsSolid;
        poseditmap.Canvas.FillRect(poseditmap.Canvas.ClipRect);
      end;
      wareditbufbmp := tbitmap.Create;
      wareditbufbmp.Width := Image1.Width;
      wareditbufbmp.Height := Image1.Height;
      wareditbufbmp.Canvas.StretchDraw(wareditbufbmp.Canvas.ClipRect, poseditmap);
      Image1.Canvas.CopyRect(Image1.Canvas.ClipRect, wareditbufbmp.Canvas, wareditbufbmp.Canvas.ClipRect);
      wareditbufbmp.Free;
      wareditbmp.Canvas.CopyRect(wareditbmp.Canvas.ClipRect, Image1.Canvas, Image1.Canvas.ClipRect);
      countwarpos;
    except

    end;
  end;
  countwarpos;
end;

procedure TForm10.Button2Click(Sender: TObject);
var
  i1, i2, i3, i4, i5, F: integer;
begin
  F := filecreate(gamepath + wardata);
  for i1 := 0 to warFile.Wtype.datanum - 1 do
    for i2 := 0 to warFile.Wtype.Rdata[i1].num - 1 do
      for i3 := 0 to warFile.Wtype.Rdata[i1].Rdataline[i2].len - 1 do
        for i4 := 0 to warFile.Wtype.Rdata[i1].Rdataline[i2].Rarray[i3].incnum - 1 do
        begin
          if warFile.Wtype.Rdata[i1].Rdataline[i2].Rarray[i3].dataarray[i4].datalen > 0 then
            filewrite(F, warFile.Wtype.Rdata[i1].Rdataline[i2].Rarray[i3].dataarray[i4].data[0], warFile.Wtype.Rdata[i1].Rdataline[i2].Rarray[i3].dataarray[i4].datalen);
        end;

  fileclose(F);

  try
    readW(gamepath + wardata, @useW);
  except

  end;
end;

procedure TForm10.Button3Click(Sender: TObject);
begin
  if MessageBox(Self.Handle, '是否添加项到最后，以当前值为缺省值？', '添加项到最后', MB_OKCANCEL) = 1 then
  begin
    if warFile.Wtype.datanum < 0 then
    begin
      warFile.Wtype.datanum := 0;
      Setlength(warFile.Wtype.Rdata, warFile.Wtype.datanum);
    end;
    addnewWdata(@warFile, nil);
    if (warFile.Wtype.datanum > 1) and (ComboBox1.ItemIndex >= 0) then
      copyRdata(@warFile.Wtype.Rdata[ComboBox1.ItemIndex], @warFile.Wtype.Rdata[warFile.Wtype.datanum - 1]);
    ComboBox1.Items.Add(calWname(warFile.Wtype.datanum - 1));
    ComboBox1.ItemIndex := warFile.Wtype.datanum - 1;
    displayW;
    countwarpos;
  end;
end;

procedure TForm10.Button4Click(Sender: TObject);
var
  temp: integer;
  arrg: boolean;
begin
  if warFile.Wtype.datanum = 1 then
    showmessage('只剩最后一项，请不要删除！')
  else
  begin
    if MessageBox(Self.Handle, '是否删除最后一项？', '删除最后一项', MB_OKCANCEL) = 1 then
    begin
      temp := ComboBox1.ItemIndex;
      arrg := false;
      if temp = warFile.Wtype.datanum - 1 then
        arrg := true;
      dec(warFile.Wtype.datanum);
      Setlength(warFile.Wtype.Rdata, warFile.Wtype.datanum);
      ComboBox1.Items.Delete(warFile.Wtype.datanum);
      ComboBox1.ItemIndex := temp;
      if arrg then
        displayW;
      ListBox1Click(Sender);
      countwarpos;
    end;
  end;
end;

procedure TForm10.Button5Click(Sender: TObject);
var
  ExcelApp: Variant;
  i2, i3, i4, i5: integer;
  temp: integer;
begin
  if MessageBox(Self.Handle, '导出Excel需要本机已经安装Excel，并且导出时间较长，过程中请不要进行操作。确实要导出吗？', '导出Excel', MB_OKCANCEL) = 1 then
  begin

    ExcelApp := CreateOleObject('Excel.Application');
    ExcelApp.Caption := 'UPedit导出Excel操作';
    ExcelApp.visible := true;
    ExcelApp.WorkBooks.Add;
    // ExcelApp.WorkSheets[2].name := '物品';
    // ExcelApp.Cells[1,4].Value := '第一行第四列';

    if integer(ExcelApp.workSheets.Count) < 1 then
      ExcelApp.workSheets.Add;

    // ExcelApp.workSheets[1].activate;
    // ExcelApp.WorkSheets[1].name := warExcelopname;

    temp := 1;
    ExcelApp.Caption := 'UPedit导出Excel操作中(' + warexcelopname + ')';

    for i2 := 0 to Wtypedataitem - 1 do
      if Wini.Wterm[i2].datanum > 0 then
        for i3 := 0 to Wini.Wterm[i2].datanum - 1 do
          for i4 := 0 to Wini.Wterm[i2].incnum - 1 do
          begin
            if i3 > 0 then
            begin
              // ExcelApp.Cells[1, temp].value := displaystr(Wini.Wterm[i2 + i4].name + inttostr(i3));
            end
            else
              // ExcelApp.Cells[1, temp].value := displaystr(Wini.Wterm[i2 + i4].name);
              // inc(temp);
          end;
    for i2 := 0 to warFile.Wtype.datanum - 1 do
    begin
      ExcelApp.Caption := 'UPedit导出Excel操作中(' + warexcelopname + ':' + inttostr(i2 + 1) + '/' + inttostr(warFile.Wtype.datanum) + ')';
      temp := 1;
      for i3 := 0 to warFile.Wtype.Rdata[i2].num - 1 do
        for i4 := 0 to warFile.Wtype.Rdata[i2].Rdataline[i3].len - 1 do
          for i5 := 0 to warFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
          begin
            // excelApp.Cells[i2 + 2, temp].value := displaystr(readRDatastr(@warFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]));
            inc(temp);
          end;
    end;

    ExcelApp.Caption := 'UPedit导出Excel完成！';
    ExcelApp := Unassigned;
    SetForegroundWindow(application.Handle);
    showmessage('导出Excel完成！请到Excel程序中保存文件！');
  end;
end;

procedure TForm10.Button6Click(Sender: TObject);
var
  ExcelApp: Variant;
  i2, i3, i4, i5: integer;
  temp, temp2: integer;
begin
  if MessageBox(Self.Handle, '导入Excel需要本机已经安装Excel，并且导入时间较长，过程中请不要进行操作。确实要导入吗？', '导入Excel', MB_OKCANCEL) = 1 then
  begin
    OpenDialog1.Filter := 'excel表格文件|*.xls;*.xlsx';
    if OpenDialog1.Execute then
    begin
      ExcelApp := CreateOleObject('Excel.Application');
      ExcelApp.Caption := 'UPedit导入Excel操作';
      ExcelApp.visible := true;
      ExcelApp.WorkBooks.Open(OpenDialog1.filename);

      // ExcelApp.workSheets[1].activate;
      ExcelApp.Caption := 'UPedit导入Excel操作中(' + warexcelopname + ')';

      i2 := 2;
      while true do
      begin
        // if string(excelApp.cells[i2, 1].value) = '' then
        break;
        inc(i2);
      end;

      warFile.Wtype.datanum := 0;
      Setlength(warFile.Wtype.Rdata, warFile.Wtype.datanum);
      warFile.Wtype.namepos := -1;
      warFile.Wtype.mappos := -1;

      for i3 := 1 to i2 - 2 do
      begin
        addnewWdata(@warFile, nil);
      end;

      for i2 := 0 to warFile.Wtype.datanum - 1 do
      begin
        ExcelApp.Caption := 'UPedit导入Excel操作中(' + warexcelopname + ':' + inttostr(i2 + 1) + '/' + inttostr(warFile.Wtype.datanum) + ')';
        temp := 0;
        for i3 := 0 to warFile.Wtype.Rdata[i2].num - 1 do
        begin
          if (i2 = 0) and (Wini.Wterm[i3].isname = 1) then
            warFile.Wtype.namepos := i3;
          if (i2 = 0) and (Wini.Wterm[i3].ismapnum = 1) then
            warFile.Wtype.mappos := i3;
          for i4 := 0 to warFile.Wtype.Rdata[i2].Rdataline[i3].len - 1 do
          begin
            for i5 := 0 to warFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
            begin
              // WriteRDataStr(@warFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], displaybackstr(excelApp.Cells[i2 + 2, temp + 1].value));
              inc(temp);
            end;
          end;
        end;

      end;

      ExcelApp.Caption := 'UPedit导入Excel完成！';
      ExcelApp := Unassigned;
      CalWnamePos(@warFile);
      ComboBox1.Clear;
      for i2 := 0 to warFile.Wtype.datanum - 1 do
        ComboBox1.Items.Add(calWname(i2));
      ComboBox1.ItemIndex := 0;

      ComboBox1Select(Sender);
      ExcelApp.Quit;
      SetForegroundWindow(application.Handle);
      showmessage('导入Excel完成！');
    end;
  end;
end;

procedure TForm10.CheckBox1Click(Sender: TObject);
var
  wareditbufbmp: tbitmap;
begin
  if CheckBox1.Checked then
  begin
    try
      Image1.visible := true;

      wareditbufbmp := tbitmap.Create;
      wareditbufbmp.Width := Image1.Width;
      wareditbufbmp.Height := Image1.Height;
      wareditbmp.Width := Image1.Width;
      wareditbmp.Height := Image1.Height;
      // poseditmap.Width := image1.Width;
      // poseditmap.Height := image1.Height;
      if (ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[warFile.Wtype.mappos].Rarray[0].dataarray[0]) >= 0) and
        (ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[warFile.Wtype.mappos].Rarray[0].dataarray[0]) < wareditmapfile.num) then
        displaywareditmap(@wareditmapfile.map[ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[warFile.Wtype.mappos].Rarray[0].dataarray[0])], @poseditmap)
      else
      begin
        poseditmap.Canvas.Brush.color := clBlack;
        poseditmap.Canvas.Brush.Style := bsSolid;
        poseditmap.Canvas.FillRect(poseditmap.Canvas.ClipRect);
      end;
      // displaywareditmap(@wareditmapfile.map[ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0])], @poseditmap);
      wareditbufbmp.Canvas.StretchDraw(wareditbufbmp.Canvas.ClipRect, poseditmap);
      Image1.Canvas.CopyRect(Image1.Canvas.ClipRect, wareditbufbmp.Canvas, wareditbufbmp.Canvas.ClipRect);
      wareditbufbmp.Free;
      wareditbmp.Canvas.CopyRect(wareditbmp.Canvas.ClipRect, Image1.Canvas, Image1.Canvas.ClipRect);
      ListBox1Click(Sender);
      countwarpos;
    except
      wareditbufbmp.Free;
      exit;
    end;
  end
  else
  begin
    Image1.visible := false;
  end;
end;

procedure TForm10.CheckBox2Click(Sender: TObject);
var
  iniF: Tinifile;
  iniFilename, tempstr: string;

begin
  //
  if CheckBox2.Checked then
    warselectcontinue := 1
  else
    warselectcontinue := 0;

  try
    iniFilename := StartPath + 'UPedit.ini';
    iniF := Tinifile.Create(iniFilename);
    iniF.Writeinteger('W_Modify', 'selectcontinue', warselectcontinue);
  finally
    iniF.Free;
  end;
end;

procedure TForm10.ComboBox1Select(Sender: TObject);
var
  wareditbufbmp: tbitmap;
begin
  if ComboBox1.ItemIndex >= 0 then
  begin
    displayW;
    if CheckBox1.Checked then
    begin
      try
        if (ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[warFile.Wtype.mappos].Rarray[0].dataarray[0]) >= 0) and
          (ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[warFile.Wtype.mappos].Rarray[0].dataarray[0]) < wareditmapfile.num) then
          displaywareditmap(@wareditmapfile.map[ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[warFile.Wtype.mappos].Rarray[0].dataarray[0])], @poseditmap)
        else
        begin
          poseditmap.Canvas.Brush.color := clBlack;
          poseditmap.Canvas.Brush.Style := bsSolid;
          poseditmap.Canvas.FillRect(poseditmap.Canvas.ClipRect);
        end;
        // displaywareditmap(@wareditmapfile.map[ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0])], @poseditmap);
        wareditbufbmp := tbitmap.Create;
        wareditbufbmp.Width := Image1.Width;
        wareditbufbmp.Height := Image1.Height;
        wareditbufbmp.Canvas.StretchDraw(wareditbufbmp.Canvas.ClipRect, poseditmap);
        Image1.Canvas.CopyRect(Image1.Canvas.ClipRect, wareditbufbmp.Canvas, wareditbufbmp.Canvas.ClipRect);
        wareditbufbmp.Free;
        wareditbmp.Canvas.CopyRect(wareditbmp.Canvas.ClipRect, Image1.Canvas, Image1.Canvas.ClipRect);
        countwarpos;
      except
        exit;
      end;
    end;
  end;
end;

procedure TForm10.displayW;
var
  i1, i2, i3, i4, temp, temp2: integer;
  tempstr: string;
  labcount: array [1 .. 7] of integer;
  I: integer;
begin
  if ComboBox1.ItemIndex >= 0 then
  begin
    temp := 0;
    for i1 := 0 to warFile.Wtype.Rdata[ComboBox1.ItemIndex].num - 1 do
      inc(temp, warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].len * warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].Rarray[0].incnum);
    Setlength(wselect, temp);
    ListBox1.Clear;
    temp := -1;
    temp2 := 0;
    for i1 := 1 to 7 do
      labcount[i1] := 0;
    for i1 := 0 to warFile.Wtype.Rdata[ComboBox1.ItemIndex].num - 1 do
    begin
      for i2 := 0 to warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].len - 1 do
        for i3 := 0 to warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].Rarray[i2].incnum - 1 do
        begin
          tempstr := '';
          if warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].len > 1 then
            for i4 := ListBox1.Canvas.TextWidth(displayname(Wini.Wterm[temp2 + i3].name) + inttostr(i2 + 1)) div ListBox1.Canvas.TextWidth(' ') to 30 do
              tempstr := tempstr + ' '
          else
            for i4 := ListBox1.Canvas.TextWidth(displayname(Wini.Wterm[temp2 + i3].name)) div ListBox1.Canvas.TextWidth(' ') to 30 do
              tempstr := tempstr + ' ';
          if warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3].datatype = 0 then
          begin
            if (Wini.Wterm[temp2 + i3].quote <= 0) or (ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3]) < 0) or
              (ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3]) >= useR.Rtype[Wini.Wterm[temp2 + i3].quote].datanum) then
              if warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].len > 1 then
                ListBox1.Items.Add(displaystr(displayname(Wini.Wterm[temp2 + i3].name) + inttostr(i2 + 1) + tempstr +
                  inttostr(ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3]))))
              else
                ListBox1.Items.Add(displaystr(displayname(Wini.Wterm[temp2 + i3].name) + tempstr +
                  inttostr(ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3]))))
            else if warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].len > 1 then
              ListBox1.Items.Add(displaystr(displayname(Wini.Wterm[temp2 + i3].name) + inttostr(i2 + 1) + tempstr +
                inttostr(ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3])) +
                readRDataStr(@useR.Rtype[Wini.Wterm[temp2 + i3].quote].Rdata[ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3])
                ].Rdataline[useR.Rtype[Wini.Wterm[temp2 + i3].quote].namepos].Rarray[0].dataarray[0])))
            else
              ListBox1.Items.Add(displaystr(displayname(Wini.Wterm[temp2 + i3].name) + tempstr + inttostr(ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3])
                ) + readRDataStr(@useR.Rtype[Wini.Wterm[temp2 + i3].quote].Rdata[ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3])
                ].Rdataline[useR.Rtype[Wini.Wterm[temp2 + i3].quote].namepos].Rarray[0].dataarray[0])));
          end
          else if warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].len > 1 then
            ListBox1.Items.Add(displaystr(displayname(Wini.Wterm[temp2 + i3].name) + inttostr(i2 + 1) + tempstr + readRDataStr(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].Rarray[i2]
              .dataarray[i3])))
          else
            ListBox1.Items.Add(displaystr(displayname(Wini.Wterm[temp2 + i3].name) + tempstr + readRDataStr(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3])));
          // checklistbox1.Items.Add(Rini[combobox1.ItemIndex].Rterm[temp2 + i3].name + '          ' + (Pstring(@(RFile[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3].str[0])))^);        i4 := 2;
          inc(temp);
          wselect[temp].pos1 := i1;
          wselect[temp].pos2 := i2;
          wselect[temp].pos3 := i3;
          wselect[temp].quote := Wini.Wterm[temp2 + i3].quote;
          wselect[temp].note := Wini.Wterm[temp2 + i3].note;
          wselect[temp].ismap := Wini.Wterm[temp2 + i3].ismapnum;
          wselect[temp].labeltype := Wini.Wterm[temp2 + i3].labeltype;
          wselect[temp].labelnum := Wini.Wterm[temp2 + i3].labelnum;
          if wselect[temp].labelnum > 0 then
          begin
            inc(labcount[wselect[temp].labelnum]);
            wselect[temp].labelcount := labcount[wselect[temp].labelnum];
          end;
        end;
      inc(temp2, warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[i1].Rarray[0].incnum);
    end;
  end;
end;

procedure TForm10.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Setlength(wareditgrp, 0);
  Setlength(warFile.Wtype.Rdata, 0);
  Setlength(wselect, 0);
  poseditmap.Free;
  Setlength(wareditmapfile.map, 0);
  wareditbmp.Free;
  ImzFile.ReleaseAllPNG;
  ImzFile.Free;
  CForm10 := true;
  Action := cafree;

end;

procedure TForm10.FormCreate(Sender: TObject);
var
  I: integer;
  wareditbufbmp: tbitmap;
  PalSize: longint;
  pLogPalle: TMaxLogPalette;
  PalleEntry: TPaletteEntry;
  Palle: HPalette;
begin

  ImzFile := TimzFile.Create;

  ReadWModeIni;

  iswarmapperson := false;
  autowarfriend := false;
  wareditbmp := tbitmap.Create;
  PalSize := sizeof(TLogPalette) + 256 * sizeof(TPaletteEntry);
  // pLogPalle:=MemAlloc(PalSize);
  // getmem(Plogpalle, palsize);
  pLogPalle.palVersion := $0300;
  pLogPalle.palNumEntries := 256;
  //
  for I := 0 to 255 do
  begin
    pLogPalle.palPalEntry[I].peRed := McolR[I];
    pLogPalle.palPalEntry[I].peGreen := McolG[I];
    pLogPalle.palPalEntry[I].peBlue := McolB[I];
    pLogPalle.palPalEntry[I].peFlags := PC_EXPLICIT;
  end;
  //
  Palle := CreatePalette(pLogPalette(@pLogPalle)^);

  SpinEdit1.value := warsmallmapsize;
  warsmallmapsize := SpinEdit1.value;
  Image1.Width := warsmallmapsize * 128;
  Image1.Height := warsmallmapsize * 128;

  readW(gamepath + wardata, @warFile);
  try
    wareditmapfile.num := 0;
    readwardef(gamepath + warmapdefidx, gamepath + warmapdefgrp, @wareditmapfile);
  except

  end;

  try
    case WarEditMode of
      RLEMode:
        begin
          readWareditgrp;
        end;
      IMZMode:
        begin
          if ImzFile.ReadImzFromFile(gamepath + WMAPIMZ) then
          begin
            ImzFile.ReadAllPNG;
          end;
        end;
      PNGMode:
        begin
          if ImzFile.ReadImzFromFolder(gamepath + WMAPPNGpath) then
            ImzFile.ReadAllPNG;
        end;
    end;
  except

  end;
  case WarEditMode of
    RLEMode:
      begin
        poseditmap := tbitmap.Create;
        poseditmap.Width := 2304;
        poseditmap.Height := 1152;
        poseditmap.PixelFormat := pf8bit;
        poseditmap.Palette := Palle;
      end;
    IMZMode, PNGMode:
      begin
        poseditmap := tbitmap.Create;
        poseditmap.Width := 2304;
        poseditmap.Height := 1152;
        poseditmap.PixelFormat := pf32bit;
        // poseditmap.Palette := palle;
      end;
  end;

  CalWnamePos(@warFile);
  ComboBox1.Clear;
  try
    for I := 0 to warFile.Wtype.datanum - 1 do
      ComboBox1.Items.Add(calWname(I));
    ComboBox1.ItemIndex := 0;
    displayW;
  except
    showmessage('打开战斗数据出错！');
    exit;
  end;
  try
    StatusBar1.Canvas.Brush.Style := bsclear;
    StatusBar1.Canvas.Font.size := 10;
    StatusBar1.Canvas.Font.color := clBlack;
    if (ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[warFile.Wtype.mappos].Rarray[0].dataarray[0]) >= 0) and
      (ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[warFile.Wtype.mappos].Rarray[0].dataarray[0]) < wareditmapfile.num) then
      displaywareditmap(@wareditmapfile.map[ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[warFile.Wtype.mappos].Rarray[0].dataarray[0])], @poseditmap)
    else
    begin
      poseditmap.Canvas.Brush.color := clBlack;
      poseditmap.Canvas.Brush.Style := bsSolid;
      poseditmap.Canvas.FillRect(poseditmap.Canvas.ClipRect);
    end;
    // displaywareditmap(@wareditmapfile.map[ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0])], @poseditmap);
    wareditbufbmp := tbitmap.Create;
    wareditbufbmp.Width := Image1.Width;
    wareditbufbmp.Height := Image1.Height;
    wareditbufbmp.Canvas.StretchDraw(wareditbufbmp.Canvas.ClipRect, poseditmap);
    Image1.Canvas.CopyRect(Image1.Canvas.ClipRect, wareditbufbmp.Canvas, wareditbufbmp.Canvas.ClipRect);
    wareditbufbmp.Free;
    wareditbmp.Width := Image1.Width;
    wareditbmp.Height := Image1.Height;
    wareditbmp.Canvas.CopyRect(wareditbmp.Canvas.ClipRect, Image1.Picture.Bitmap.Canvas, Image1.Picture.Bitmap.Canvas.ClipRect);

    if warselectcontinue = 1 then
      CheckBox2.Checked := true;
  except
    showmessage('显示战斗缩略图出错！');
  end;
  countwarpos;
end;

procedure TForm10.drawwarpos;
var
  pointx, pointy, posx, posy, I, ix, iy: integer;
begin
  pointx := Image1.Width DIV 2;
  pointy := Image1.Height div 2 - 31 * warsmallmapsize * 2;

  Image1.Picture.Bitmap.Canvas.CopyRect(Image1.Picture.Bitmap.Canvas.ClipRect, wareditbmp.Canvas, wareditbmp.Canvas.ClipRect);
  for I := 0 to warenemynum - 1 do
  begin
    if warenemy[I].personnum >= 0 then
    begin
      ix := warenemy[I].X;
      iy := warenemy[I].Y;
      posx := ix * warsmallmapsize - iy * warsmallmapsize + pointx;
      posy := ix * warsmallmapsize + iy * warsmallmapsize + pointy;
      drawwarpoint(posx, posy, clblue);
    end;
  end;

  for I := 0 to warfriendnum - 1 do
  begin
    if not(autowarfriend) or (warfriend[I].personnum >= 0) then
    begin
      ix := warfriend[I].X;
      iy := warfriend[I].Y;
      posx := ix * warsmallmapsize - iy * warsmallmapsize + pointx;
      posy := ix * warsmallmapsize + iy * warsmallmapsize + pointy;
      drawwarpoint(posx, posy, clred);
    end;
  end;

  if iswarmapperson then
  begin
    if warmappersontype = 1 then
    begin
      ix := warfriend[warmappersonnum].X;
      iy := warfriend[warmappersonnum].Y;
    end
    else if warmappersontype = 2 then
    begin
      ix := warenemy[warmappersonnum].X;
      iy := warenemy[warmappersonnum].Y;
    end;

    posx := ix * warsmallmapsize - iy * warsmallmapsize + pointx;
    posy := ix * warsmallmapsize + iy * warsmallmapsize + pointy;
    drawwarpoint(posx, posy, clyellow);
  end;
end;

procedure TForm10.drawwarpoint(posx, posy: integer; color: cardinal);
var
  I, i2: integer;
begin
  { image1.Canvas.Pixels[posx,posy] := color;
    image1.Canvas.Pixels[posx,posy - 1] := color;
    image1.Canvas.Pixels[posx + 1,posy - 1] := color;
    image1.Canvas.Pixels[posx - 1,posy - 2] := color;
    image1.Canvas.Pixels[posx ,posy - 2] := color;
    image1.Canvas.Pixels[posx + 1 ,posy - 2] := color;
    image1.Canvas.Pixels[posx + 2 ,posy - 2] := color;
    image1.Canvas.Pixels[posx - 2,posy - 3] := color;
    image1.Canvas.Pixels[posx - 1,posy - 3] := color;
    image1.Canvas.Pixels[posx ,posy - 3] := color;
    image1.Canvas.Pixels[posx + 1,posy - 3] := color;
    image1.Canvas.Pixels[posx + 2,posy - 3] := color;
    image1.Canvas.Pixels[posx + 3,posy - 3] := color;
    image1.Canvas.Pixels[posx - 1,posy - 4] := color;
    image1.Canvas.Pixels[posx ,posy - 4] := color;
    image1.Canvas.Pixels[posx + 1 ,posy - 4] := color;
    image1.Canvas.Pixels[posx + 2 ,posy - 4] := color;
    image1.Canvas.Pixels[posx,posy - 5] := color;
    image1.Canvas.Pixels[posx + 1,posy - 5] := color; }
  for I := 0 to warsmallmapsize do
  begin
    Image1.Canvas.Pixels[posx, posy - I] := color;
    Image1.Canvas.Pixels[posx, posy + I - 2 * warsmallmapsize] := color;
    for i2 := I downto 1 do
    begin
      Image1.Canvas.Pixels[posx + i2, posy - I] := color;
      Image1.Canvas.Pixels[posx - i2, posy - I] := color;
      Image1.Canvas.Pixels[posx + i2, posy + I - 2 * warsmallmapsize] := color;
      Image1.Canvas.Pixels[posx - i2, posy + I - 2 * warsmallmapsize] := color;
    end;
  end;
end;

procedure TForm10.FormResize(Sender: TObject);
begin
  ListBox1.Columns := ListBox1.Width div 400 + 1;
end;

procedure TForm10.Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
var
  tempint: integer;
  pointx, pointy, ayp, axp, ix, iy, I, i2: integer;
begin
  if Button = mbleft then
  begin
    tempint := -1;
    if iswarmapperson then
    begin
      pointx := Image1.Width DIV 2;
      pointy := Image1.Height div 2 - 31 * warsmallmapsize * 2;
      ayp := Round((-X + pointx + Y - pointy + warsmallmapsize) / (warsmallmapsize * 2));
      axp := Round((X - pointx + Y - pointy + warsmallmapsize) / (warsmallmapsize * 2));
      if (axp in [0 .. 63]) and (ayp in [0 .. 63]) then
      begin
        iswarmapperson := false;
        tempint := -1;
        for I := 0 to warfriendnum - 1 do
          if (axp = warfriend[I].X) and (ayp = warfriend[I].Y) and (not(autowarfriend) or (warfriend[I].personnum >= 0)) then
          begin
            if (warmappersontype = 1) and (warmappersonnum = I) then
              break;
            warmappersontype := 1;
            iswarmapperson := true;
            warmappersonnum := I;
            break;
          end;
        if not(iswarmapperson) then
          for I := 0 to warenemynum - 1 do
            if (axp = warenemy[I].X) and (ayp = warenemy[I].Y) and (warenemy[I].personnum >= 0) then
            begin
              if (warmappersontype = 2) and (warmappersonnum = I) then
                break;
              warmappersontype := 2;
              iswarmapperson := true;
              warmappersonnum := I;
              break;
            end;
        if not(iswarmapperson) then
        begin
          if warmappersontype = 1 then // 友军
          begin
            for I := 0 to ListBox1.Count - 1 do
              if (warmappersonnum = wselect[I].labelcount - 1) and (wselect[I].labeltype = 1) then
                if (wselect[I].labelnum = 1) then
                  WriteRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3], axp)
                else if (wselect[I].labelnum = 2) then
                  WriteRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3], ayp);

          end
          else if warmappersontype = 2 then
          begin
            for I := 0 to ListBox1.Count - 1 do
            begin
              if (warmappersonnum = wselect[I].labelcount - 1) and (wselect[I].labeltype = 2) then
              begin
                if (wselect[I].labelnum = 3) then
                begin
                  WriteRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3], axp);
                end
                else if (wselect[I].labelnum = 4) then
                begin
                  WriteRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3], ayp);
                end;
              end;
            end;
          end;

          tempint := ListBox1.ItemIndex;
          displayW;
          ListBox1.ItemIndex := tempint;
          if CheckBox2.Checked then
          begin
            // ListBox1Click(Sender);
            iswarmapperson := true;
          end;
        end;
        countwarpos;
      end;
    end
    else
    begin
      tempint := -1;
      pointx := Image1.Width DIV 2;
      pointy := Image1.Height div 2 - 31 * warsmallmapsize * 2;
      ayp := Round((-X + pointx + Y - pointy + warsmallmapsize) / (warsmallmapsize * 2));
      axp := Round((X - pointx + Y - pointy + warsmallmapsize) / (warsmallmapsize * 2));

      for I := 0 to warfriendnum - 1 do
      begin
        if (warfriend[I].X = axp) and (warfriend[I].Y = ayp) and ((warfriend[I].personnum >= 0) or not(autowarfriend)) then
        begin
          tempint := I;
          warmappersontype := 1;
          break;
        end;
      end;

      if tempint < 0 then
        for I := 0 to warenemynum - 1 do
        begin
          if (warenemy[I].X = axp) and (warenemy[I].Y = ayp) and (warenemy[I].personnum >= 0) then
          begin
            tempint := I;
            warmappersontype := 2;
            break;
          end;
        end;
      // showmessage(inttostr(tempint));
      if tempint >= 0 then
      begin
        iswarmapperson := true;
        warmappersonnum := tempint;
      end;
      drawwarpos;
    end;
    // warmappersonnum : integer;
  end;
end;

procedure TForm10.Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
var
  pointx, pointy, ayp, axp, ix, iy, I: integer;
  tempstr: string;
begin
  pointx := Image1.Width DIV 2;
  pointy := Image1.Height div 2 - 31 * warsmallmapsize * 2;
  ayp := Round((-X + pointx + Y - pointy + warsmallmapsize) / (warsmallmapsize * 2));
  axp := Round((X - pointx + Y - pointy + warsmallmapsize) / (warsmallmapsize * 2));
  StatusBar1.Canvas.Brush.color := clbtnface;
  StatusBar1.Canvas.FillRect(StatusBar1.Canvas.ClipRect);
  StatusBar1.Repaint;
  tempstr := '';
  for I := 0 to warfriendnum - 1 do
  begin
    if (warfriend[I].X = axp) and (warfriend[I].Y = ayp) and (not(autowarfriend) or (warfriend[I].personnum >= 0)) then
    begin
      tempstr := ' 友军' + inttostr(I + 1);
      break;
    end;
  end;
  if tempstr = '' then
    for I := 0 to warenemynum - 1 do
    begin
      if (warenemy[I].X = axp) and (warenemy[I].Y = ayp) and (warenemy[I].personnum >= 0) then
      begin
        tempstr := ' 敌军' + inttostr(I + 1);
        break;
      end;
    end;
  StatusBar1.Canvas.Brush.color := clbtnface;
  StatusBar1.Canvas.FillRect(StatusBar1.Canvas.ClipRect);
  StatusBar1.Repaint;
  StatusBar1.Canvas.TextOut(10, 2, 'X=' + inttostr(axp) + ',Y=' + inttostr(ayp) + tempstr);
end;

procedure TForm10.ListBox1Click(Sender: TObject);
begin
  //
  if ListBox1.ItemIndex >= 0 then
  begin
    if wselect[ListBox1.ItemIndex].labelnum > 0 then
    begin
      if ((wselect[ListBox1.ItemIndex].labelnum = 1) and (wselect[ListBox1.ItemIndex].labeltype = 1) and (not(autowarfriend) or (warfriend[wselect[ListBox1.ItemIndex].labelcount - 1].personnum >= 0)))
        or ((wselect[ListBox1.ItemIndex].labelnum = 2) and (wselect[ListBox1.ItemIndex].labeltype = 1) and (not(autowarfriend) or (warfriend[wselect[ListBox1.ItemIndex].labelcount - 1].personnum >= 0)
        )) or ((wselect[ListBox1.ItemIndex].labelnum = 5) and not(autowarfriend)) or
        ((wselect[ListBox1.ItemIndex].labelnum = 7) and autowarfriend and
        (ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[ListBox1.ItemIndex].pos1].Rarray[wselect[ListBox1.ItemIndex].pos2].dataarray[wselect[ListBox1.ItemIndex].pos3]) >= 0))
      then
      begin
        iswarmapperson := true;
        warmappersontype := 1;
        warmappersonnum := wselect[ListBox1.ItemIndex].labelcount - 1;
      end
      else if ((wselect[ListBox1.ItemIndex].labelnum = 3) and (wselect[ListBox1.ItemIndex].labeltype = 2) and (warenemy[wselect[ListBox1.ItemIndex].labelcount - 1].personnum >= 0)) or
        ((wselect[ListBox1.ItemIndex].labelnum = 4) and (wselect[ListBox1.ItemIndex].labeltype = 2) and (warenemy[wselect[ListBox1.ItemIndex].labelcount - 1].personnum >= 0)) or
        ((wselect[ListBox1.ItemIndex].labelnum = 6) and (ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[ListBox1.ItemIndex].pos1].Rarray[wselect[ListBox1.ItemIndex].pos2]
        .dataarray[wselect[ListBox1.ItemIndex].pos3]) >= 0)) then
      begin
        iswarmapperson := true;
        warmappersontype := 2;
        warmappersonnum := wselect[ListBox1.ItemIndex].labelcount - 1;
      end
      else
        iswarmapperson := false;
    end
    else
      iswarmapperson := false;
    drawwarpos;

    StatusBar2.Canvas.Brush.color := clbtnface;
    StatusBar2.Canvas.FillRect(StatusBar1.Canvas.ClipRect);
    StatusBar2.Repaint;
    StatusBar2.Canvas.TextOut(10, 2, wselect[ListBox1.ItemIndex].note);
    // listbox1DBlclick(sender);
  end;
end;

procedure TForm10.ListBox1DblClick(Sender: TObject);
var
  temp, I, temp2: integer;
begin
  if (ListBox1.ItemIndex < length(wselect)) and (ListBox1.ItemIndex >= 0) then
  begin
    temp := ListBox1.ItemIndex;
    if wselect[ListBox1.ItemIndex].quote <= 0 then
    begin
      if warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[ListBox1.ItemIndex].pos1].Rarray[wselect[ListBox1.ItemIndex].pos2].dataarray[wselect[ListBox1.ItemIndex].pos3].datatype = 0 then
        WriteRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[ListBox1.ItemIndex].pos1].Rarray[wselect[ListBox1.ItemIndex].pos2].dataarray[wselect[ListBox1.ItemIndex].pos3],
          strtoint64(InputBox('修改', '修改此项数值', inttostr(ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[ListBox1.ItemIndex].pos1].Rarray[wselect[ListBox1.ItemIndex].pos2]
          .dataarray[wselect[ListBox1.ItemIndex].pos3])))))
      else
        WriteRDataStr(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[ListBox1.ItemIndex].pos1].Rarray[wselect[ListBox1.ItemIndex].pos2].dataarray[wselect[ListBox1.ItemIndex].pos3],
          displaybackstr(InputBox('修改', '修改此项字符串', displaystr(readRDataStr(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[ListBox1.ItemIndex].pos1].Rarray[wselect[ListBox1.ItemIndex]
          .pos2].dataarray[wselect[ListBox1.ItemIndex].pos3])))));
    end
    else
    begin
      Form6.ComboBox1.Clear;
      Form6.ComboBox1.Items.Add('-1');
      for I := 0 to useR.Rtype[wselect[ListBox1.ItemIndex].quote].datanum - 1 do
        Form6.ComboBox1.Items.Add(displaystr(inttostr(I) + readRDataStr(@useR.Rtype[wselect[ListBox1.ItemIndex].quote].Rdata[I].Rdataline[useR.Rtype[wselect[ListBox1.ItemIndex].quote].namepos].Rarray
          [0].dataarray[0])));
      Form6.ComboBox1.ItemIndex := ReadRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[ListBox1.ItemIndex].pos1].Rarray[wselect[ListBox1.ItemIndex].pos2].dataarray
        [wselect[ListBox1.ItemIndex].pos3]) + 1;
      Form6.Label1.Caption := typename[wselect[ListBox1.ItemIndex].quote];
      if Form6.ShowModal = mrOK then
        WriteRDataInt(@warFile.Wtype.Rdata[ComboBox1.ItemIndex].Rdataline[wselect[ListBox1.ItemIndex].pos1].Rarray[wselect[ListBox1.ItemIndex].pos2].dataarray[wselect[ListBox1.ItemIndex].pos3],
          Form6.ComboBox1.ItemIndex - 1);
      // Form6.Free;
    end;
    if wselect[ListBox1.ItemIndex].pos1 = warFile.Wtype.namepos then
    begin
      temp2 := ComboBox1.ItemIndex;
      ComboBox1.Items.strings[temp2] := inttostr(temp2) + readRDataStr(@warFile.Wtype.Rdata[temp2].Rdataline[warFile.Wtype.namepos].Rarray[0].dataarray[0]);
      ComboBox1.ItemIndex := temp2;
    end;
    displayW;
    ListBox1.ItemIndex := temp;
    ListBox1Click(Sender);
    if wselect[temp].ismap > 0 then
      CheckBox1Click(Sender);
    if wselect[temp].labelnum > 0 then
      countwarpos;
  end;
end;

procedure TForm10.SpinEdit1Change(Sender: TObject);
var
  ini: Tinifile;
begin
  if SpinEdit1.value > 20 then
    SpinEdit1.value := 20;
  if SpinEdit1.value < 1 then
    SpinEdit1.value := 1;
  warsmallmapsize := SpinEdit1.value;
  Image1.Width := 128 * warsmallmapsize;
  Image1.Height := 128 * warsmallmapsize;
  Image1.Picture.Bitmap.Width := Image1.Width;
  Image1.Picture.Bitmap.Height := Image1.Height;
  CheckBox1Click(Sender);
  try
    ini := Tinifile.Create(StartPath + iniFilename);
    ini.Writeinteger('file', 'warsmallmapsize', warsmallmapsize);
  finally
    ini.Free;
  end;
end;

procedure CalWnamePos(PWF: PWFile);
var
  temp, I: integer;
begin
  PWF.Wtype.namepos := -1;
  temp := -1;
  for I := 0 to Wtypedataitem - 1 do
  begin
    if Wini.Wterm[I].datanum > 0 then
    begin
      inc(temp);
      if Wini.Wterm[I].isname = 1 then
      begin
        PWF.Wtype.namepos := temp;
      end;
      if Wini.Wterm[I].ismapnum = 1 then
      begin
        PWF.Wtype.mappos := temp;
      end;
    end;
  end;
end;

function calWname(index: integer): widestring;
var
  I: integer;
begin
  if (index >= 0) and (index < warFile.Wtype.datanum) and (warFile.Wtype.namepos >= 0) then
    result := inttostr(index) + widestring(displaystr(readRDataStr(@warFile.Wtype.Rdata[index].Rdataline[warFile.Wtype.namepos].Rarray[0].dataarray[0])))
  else
    result := inttostr(index);
  for I := 1 to length(result) - 1 do
    if result[I + 1] = '' then
    begin
      Setlength(result, I);
      break;
    end;
end;

procedure readWareditgrp;
var
  offset: array of integer;
  I, idx, grp, temp: integer;
begin
  try

    idx := fileopen(gamepath + warmapidx, fmopenread);
    grp := fileopen(gamepath + warmapgrp, fmopenread);
    temp := fileseek(idx, 0, 2);
    Setlength(wareditgrp, temp shr 2);
    Setlength(offset, temp shr 2 + 1);
    fileseek(idx, 0, 0);
    fileread(idx, offset[1], temp);
    offset[0] := 0;
    fileseek(grp, 0, 0);
    for I := 0 to temp shr 2 - 1 do
    begin
      wareditgrp[I].size := offset[I + 1] - offset[I];
      if wareditgrp[I].size > 0 then
      begin
        Setlength(wareditgrp[I].data, wareditgrp[I].size);
        fileread(grp, wareditgrp[I].data[0], wareditgrp[I].size);
      end
      else
      begin
        wareditgrp[I].size := 0;
        Setlength(wareditgrp[I].data, wareditgrp[I].size);
      end;
    end;

    fileclose(idx);
    fileclose(grp);

  except
    // showmessage('错误');
    try
      fileclose(idx);
    except

    end;

    try
      fileclose(grp);
    except

    end;

    exit;
  end;

end;

procedure TForm10.displaywareditmap(waropMap: Pmap; waropbmp2: PNTbitmap);
VAR
  ix, iy, I, i2, posx, posy: integer;
  pointx, pointy: integer;
begin
  pointx := waropbmp2.Width DIV 2;
  pointy := waropbmp2.Height div 2 - 31 * 18;
  waropbmp2.Canvas.Brush.color := clBlack;
  waropbmp2.Canvas.FillRect(waropbmp2.Canvas.ClipRect);
  for I := 0 to min(waropMap.X, waropMap.Y) - 1 do
  begin
    for ix := I to waropMap.X - 1 do
    begin
      posx := ix * 18 - I * 18 + pointx;
      posy := ix * 9 + I * 9 + pointy;
      for i2 := 0 to waropMap.layernum - 1 do
        if (waropMap.maplayer[i2].pic[I][ix] div 2 > 0) or (i2 = 0) then
        begin
          case WarEditMode of
            RLEMode:
              begin
                McoldrawRLE8(@wareditgrp[waropMap.maplayer[i2].pic[I][ix] div 2].data[0], wareditgrp[waropMap.maplayer[i2].pic[I][ix] div 2].size, waropbmp2, posx, posy, true);
              end;
            IMZMode, PNGMode:
              begin
                ImzFile.SceneQuickDraw(waropbmp2, waropMap.maplayer[i2].pic[I][ix] div 2, posx, posy);
              end;
          end;
        end;
    end;
    for iy := I + 1 to waropMap.Y - 1 do
    begin
      posx := I * 18 - iy * 18 + pointx;
      posy := I * 9 + iy * 9 + pointy;
      for i2 := 0 to waropMap.layernum - 1 do
        if (waropMap.maplayer[i2].pic[iy][I] div 2 > 0) or (i2 = 0) then
        begin
          case WarEditMode of
            RLEMode:
              begin
                McoldrawRLE8(@wareditgrp[waropMap.maplayer[i2].pic[iy][I] div 2].data[0], wareditgrp[waropMap.maplayer[i2].pic[iy][I] div 2].size, waropbmp2, posx, posy, true);
              end;
            IMZMode, PNGMode:
              begin
                ImzFile.SceneQuickDraw(waropbmp2, waropMap.maplayer[i2].pic[iy][I] div 2, posx, posy);
              end;
          end;
        end;
    end;
  end;
end;

end.
