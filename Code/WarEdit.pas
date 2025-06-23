unit WarEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, head, inifiles, ExtCtrls, StdCtrls, math, ComCtrls, Spin, IMZObject,
  comobj,
  System.IOUtils,
  //VCL.FlexCel.Core, FlexCel.XlsAdapter{, XLSFonts4, XLSReadWriteII4, SheetData4};
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
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure CheckBox1Click(Sender: TObject);
    procedure countwarpos;
    procedure drawwarpoint(posx,posy: integer;color: cardinal);
    procedure drawwarpos;
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ListBox1Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
    procedure ReadWModeIni;
    procedure displaywareditmap(waropMap: Pmap; waropbmp2:PNTbitmap);
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
  warenemy: array of TWarpos;
  wareditbmp: Tbitmap;
  iswarmapperson: boolean = false;
  warmappersontype: integer;
  warmappersonnum : integer;
  warselectcontinue: integer;
  warsmallmapsize: integer;
  warexcelopname : String = '战斗数据';

  strings: array [0..9999] of array [0..9999] of ansistring;

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
  I3, I4, I5, TEMP: integer;
begin

  if PWF.Wtype.datanum < 0 then
    PWF.Wtype.datanum := 0;
  Inc(PWF.Wtype.datanum);
  Setlength(PWF.Wtype.Rdata, PWF.Wtype.datanum);

  temp := 0;
  for i3 := 0 to Wtypedataitem - 1 do
    if Wini.Wterm[i3].datanum > 0 then
      inc(temp);
  PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].num := temp;
  setlength(PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline, PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].num);

  temp := -1;
  for I3 := 0 to Wtypedataitem - 1 do
  begin
    if Wini.Wterm[i3].datanum > 0 then
    begin
      inc(temp);
      PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].len := Wini.Wterm[i3].datanum;
      setlength(PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray, Wini.Wterm[i3].datanum);
      for I4 := 0 to Wini.Wterm[i3].datanum - 1 do
      begin
       PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].incnum :=  Wini.Wterm[i3].incnum;
        setlength(PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray, PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].incnum);
        for i5 := 0 to Wini.Wterm[i3].incnum - 1 do
        begin
          PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datatype := Wini.Wterm[i3 + i5].isstr;
          PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen := Wini.Wterm[i3 + i5].datalen;
          if PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen >= 0 then
            setlength(PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].data, PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen)
          else
          begin
            PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen := 0;
            setlength(PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].data, PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen);
          end;
          if PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen > 0 then
            zeromemory(@PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].data[0], PWF.Wtype.Rdata[PWF.Wtype.datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen);
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
  Filename := ExtractFilePath(Paramstr(0)) + iniFilename;
  try
    ini := TIniFile.Create(filename);
    WarEditMode := TMapEditMode(ini.ReadInteger('File','WarMode', integer(WarEditMode)));
  finally
    ini.Free;
  end;
end;

procedure readWini;
var
  iniF: Tinifile;
  inifilename, tempstr: string;
  strlist: Tstringlist;
  i1,i2: integer;
  strnum: integer;

begin
  //

  try
    inifilename := ExtractFilePath(Paramstr(0)) + 'UPedit.ini';
    iniF := TIniFile.Create(inifilename);
    //Wtypenumber := iniF.ReadInteger('W_Modify','TypeNumber',0);
    //edit1.Text := inttostr(typenumber);

      // setlength(Wini, Wtypenumber);
      // setlength(Wtypedataitem, Wtypenumber);
      // setlength(Wtypename, Wtypenumber);
      strlist := Tstringlist.Create;
        //Wtypename[I1] := iniF.ReadString('W_Modify', 'typename' + inttostr(i1), '');
        Wtypedataitem := iniF.ReadInteger('W_Modify', 'typedataitem', 0);
        warselectcontinue := iniF.ReadInteger('W_Modify', 'selectcontinue', 0);
        if Wtypedataitem > 0 then
        begin
          setlength(Wini.Wterm, Wtypedataitem);
          for i1 := 0 to Wtypedataitem - 1 do
          begin
            strlist.Clear;
            tempstr := iniF.ReadString('W_Modify','data(' + inttostr(i1) + ')','');
            if tempstr<>'' then
            begin
              strnum := ExtractStrings([' '], [], Pwidechar(tempstr), Strlist);
              if strnum = 11 then
              begin
                with Wini.Wterm[i1] do
                begin
                  datanum := strtoint64(strlist.Strings[0]);
                  incnum := strtoint64(strlist.Strings[1]);
                  datalen := strtoint64(strlist.Strings[2]);
                  isstr := strtoint64(strlist.Strings[3]);
                  isname := strtoint64(strlist.Strings[4]);
                  quote := strtoint64(strlist.Strings[5]);
                  name := strlist.Strings[6];
                  note := strlist.Strings[7];
                  ismapnum:= strtoint64(strlist.Strings[8]);
                  labeltype:= strtoint64(strlist.Strings[9]);
                  labelnum:= strtoint64(strlist.Strings[10]);
                end;
              end;
            end;
          end;

        end;

        strlist.free;


    iniF.free;
  except
    //showmessage('读取ini文件错误！');
    exit;
  end;
end;

function readW(grp: string; PWF: PWFile): boolean;
var
  offset: array of integer;
  i1,i2,i3,i4,i5: integer;
  size, F, temp, filelen: Integer;
begin
  result := false;
    if fileexists(grp) then
    begin

      try
        PWF.Wtype.datanum := 0;
        PWF.Wtype.namepos := -1;
        PWF.Wtype.mappos := -1;
        setlength(PWF.Wtype.Rdata, 0);
        F := fileopen(grp, fmopenread);
        size := 0;
        for i2 := 0 to Wtypedataitem - 1 do
        begin
          if wini.Wterm[i2].datanum > 0 then
          for i3 := i2 to i2 + wini.Wterm[i2].incnum - 1 do
          begin
            inc(size, wini.Wterm[i2].datanum * wini.Wterm[i3].datalen);
          end;
        end;

        filelen := fileseek(F,0,2);
        fileseek(F,0,0);
        size := filelen div size;
        PWF.Wtype.datanum := 0;
        setlength(PWF.Wtype.Rdata, PWF.Wtype.datanum);

        for i2 := 0 to size - 1 do
        begin
          AddNewWData(PWF, nil);
        end;

        for i2 := 0 to PWF.Wtype.datanum - 1 do
          begin
            //temp := 0;
            //for i3 := 0 to Wtypedataitem - 1 do
              //if Wini.Wterm[i3].datanum > 0 then
                //inc(temp);
            //PWF.Wtype.Rdata[i2].num := temp;
            //setlength(PWF.Wtype.Rdata[i2].Rdataline, temp);
            temp := -1;
            for I3 := 0 to Wtypedataitem - 1 do
            begin
              if Wini.Wterm[i3].datanum > 0 then
              begin
                inc(temp);
                if (i3 = 0) and (Wini.Wterm[i3].isname = 1) then
                  PWF.Wtype.namepos := temp;
                //PWF.Wtype.Rdata[i2].Rdataline[temp].len := Wini.wterm[i3].datanum;
                //setlength(PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray, Wini.wterm[i3].datanum);
               // setlength(Rfile[i1].Rdata[i2].Rdataline[i3].datatype, Rini[i1].Rterm[i3].incnum);
                //setlength(Rfile[i1].Rdata[i2].Rdataline[i3].Rarray, Rini[i1].Rterm[i3].incnum);
                for I4 := 0 to Wini.wterm[i3].datanum - 1 do
                begin
                  //PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray[i4].incnum := wini.Wterm[i3].incnum;
                  //setlength(PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray[i4].dataarray, wini.Wterm[i3].incnum);
                  for i5 := 0 to Wini.Wterm[i3].incnum - 1 do
                  begin
                    //PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].datalen := Wini.Wterm[i3 + i5].datalen;
                    //PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].datatype := Wini.Wterm[i3 + i5].isstr;
                    //setlength(PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].Data, Wini.Wterm[i3 + i5].datalen);
                    if PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].datalen > 0 then
                      fileread(F, PWF.Wtype.Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].Data[0], Wini.Wterm[i3 + i5].datalen);
                  end;
                end;
              end;
            end;
          end;

        fileclose(F);

        result := true;
      except
        //showmessage('读取文件错误！');
        fileclose(F);
        exit;
      end;
    end;
end;

procedure TForm10.countwarpos;
var
  warmax, tempwar,I:integer;
begin

  autowarfriend := false;
  for I := 0 to Listbox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = 7) and (ReadRDataInt(@warFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3]) >= 0) then
      autowarfriend := true;
  end;

  if autowarfriend then
    tempwar := 7
  else
    tempwar := 5;
  //队友数据
  warmax := 0;
  for I := 0 to Listbox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = tempwar)then
      if warmax < wselect[I].labelcount then
        warmax := wselect[I].labelcount;
  end;
  warfriendnum := warmax;
  setlength(warfriend, warfriendnum);

  for I := 0 to Listbox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = tempwar)then
      warfriend[wselect[I].labelcount - 1].personnum := ReadRDataInt(@warFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3]);
  end;

  for I := 0 to Listbox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = 1) and (wselect[I].labeltype = 1) and (wselect[I].labelcount <= warmax) then
      warfriend[wselect[I].labelcount - 1].x := ReadRDataInt(@warFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3]);
  end;

  for I := 0 to Listbox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = 2) and (wselect[I].labeltype = 1) and (wselect[I].labelcount <= warmax) then
      warfriend[wselect[I].labelcount - 1].y := ReadRDataInt(@warFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3]);
  end;

  //敌人数据
  warmax := 0;
  tempwar := 6;
  for I := 0 to Listbox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = tempwar)then
      if warmax < wselect[I].labelcount then
        warmax := wselect[I].labelcount;
  end;

  warenemynum := warmax;
  setlength(warenemy, warenemynum);

  for I := 0 to Listbox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = tempwar)then
      warenemy[wselect[I].labelcount - 1].personnum := ReadRDataInt(@warFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3]);
  end;

  for I := 0 to Listbox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = 3) and (wselect[I].labeltype = 2) and (wselect[I].labelcount <= warmax) then
      warenemy[wselect[I].labelcount - 1].x := ReadRDataInt(@warFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3]);
  end;

  for I := 0 to Listbox1.Items.Count - 1 do
  begin
    if (wselect[I].labelnum = 4) and (wselect[I].labeltype = 2) and (wselect[I].labelcount <= warmax) then
      warenemy[wselect[I].labelcount - 1].y := ReadRDataInt(@warFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[wselect[I].pos1].Rarray[wselect[I].pos2].dataarray[wselect[I].pos3]);
  end;
  drawwarpos;

end;



procedure TForm10.Button11Click(Sender: TObject);
var
  filename: string;
  i2,i3,i4,i5: integer;
  temp, temp2: integer;
  xls: plxw_workbook;
  sheet: plxw_worksheet;
begin
  savedialog1.Filter := 'excel文件|*.xlsx';
  if savedialog1.Execute then
  begin
    try
      filename := savedialog1.FileName;
      if not SameText(ExtractFileExt(FileName), '.xlsx') then
        FileName := FileName + '.xlsx';
      xls := workbook_new(pansichar(UnicodeToMulti(pwidechar(filename), 65001)));
      sheet := workbook_add_worksheet(xls, 'Sheet1');
      temp := 1;
      for i2 := 0 to Wtypedataitem - 1 do
      begin
        for i3 := 0 to Wini.Wterm[i2].datanum - 1 do
          for i4 := 0 to Wini.Wterm[i2].incnum - 1 do
          begin
            if i3 > 0 then
            begin
              worksheet_write_string(sheet, 0, temp-1,
                pansichar(UnicodeToMulti(pwidechar(displaystr(Wini.Wterm[i2 + i4].name + inttostr(i3))),65001)), nil)
              //xls.SetCellValue(1, temp, displaystr(Wini.Wterm[i2 + i4].name + inttostr(i3)));
//              XLSReadWriteII41.Sheets[0].AsString[temp, 0] := displaystr(Wini.Wterm[i2 + i4].name + inttostr(i3));
            end
            else
              worksheet_write_string(sheet, 0, temp-1,
                pansichar(UnicodeToMulti(pwidechar(displaystr(Wini.Wterm[i2 + i4].name)),65001)), nil);
            //xls.SetCellValue(1, temp, displaystr(Wini.Wterm[i2 + i4].name));
//              XLSReadWriteII41.Sheets[0].AsString[temp, 0] := displaystr(Wini.Wterm[i2 + i4].name);
            inc(temp);
          end;
      end;



      for i2 := 0 to WarFile.Wtype.datanum - 1 do
      begin
        temp := 1;
        for i3 := 0 to WarFile.Wtype.Rdata[i2].num - 1 do
          for I4 := 0 to WarFile.Wtype.Rdata[i2].Rdataline[i3].len - 1 do
            for i5 := 0 to WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
            begin
              if WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].datatype = 1 then
                worksheet_write_string(sheet, i2+1, temp-1,
                  pansichar(UnicodeToMulti(pwidechar(displaystr(readRDataStr(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]))),65001)), nil)
              //xls.SetCellValue(i2+2, temp, displaystr(readRDataStr(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5])))
//                XLSReadWriteII41.Sheets[0].AsString[temp, i2 + 1]:= displaystr(readRDataStr(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]))
              else
                worksheet_write_number(sheet, i2+1, temp-1,
                  readRDataInt(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]), nil);
              //xls.SetCellValue(i2+2, temp, readRDataInt(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]));
//                XLSReadWriteII41.Sheets[0].Asinteger[temp, i2 + 1] := readRDataInt(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]);
              inc(temp);
            end;
      end;


//      XLSReadWriteII41.Write;
//      XLSReadWriteII41.Free;
      //ExcelApp:=Unassigned;
      //xls.Save(FileName);
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
  i2,i3,i4,i5: integer;
  temp: integer;
//  XLSReadWriteII41 : TXLSReadWriteII4;
//xls: TXlsFile;
  XF: integer;
   //cell: TCellValue;
  xls: xlsxioreader;
  sheet: xlsxioreadersheet;
  value: pansichar;
  i1: integer;
begin

  opendialog1.Filter := 'excel表格文件|*.xlsx';
  if opendialog1.Execute then
  begin
    try
//      XLSReadWriteII41 := TXLSReadWriteII4.Create(self);
//      XLSReadWriteII41.Clear;
//      XLSReadWriteII41.Filename := opendialog1.Filename;
//      XLSReadWriteII41.Read;
//xls := TXlsFile.Create (opendialog1.Filename);
//xls.ActiveSheetByName := 'Sheet1';
      xls := xlsxioread_open(pansichar(UnicodeToMulti(pwidechar(opendialog1.Filename), 936)));
      sheet := xlsxioread_sheet_open(xls, 'Sheet1', XLSXIOREAD_SKIP_EMPTY_ROWS);
      i2 := 0;
      //while True do
      //begin
      //xf:=-1;
      //if i2>xls.RowCount then
       //break;
      //cell := xls.GetCellValueIndexed(i2, 1, XF);
        //if cell.IsEmpty then
//        if XLSReadWriteII41.Sheets[0].AsString[0,i2] = '' then
          //break;
        //inc(i2);
      //end;
      i1:=0;
      while (xlsxioread_sheet_next_row(sheet) <> 0) do
      begin
        i1:=0;
        while true do
        begin
          value := xlsxioread_sheet_next_cell(sheet);
          if value = nil then
            break;
          strings[i2][i1]:=value;
          inc(i1);
        end;
        inc(i2);
      end;

      WarFile.Wtype.datanum := 0;
      setlength(WarFile.Wtype.Rdata, WarFile.Wtype.datanum);

      for i3 := 0 to I2 - 2 do
      begin
        AddNewWData(@WarFile, nil);
      end;

      for i2 := 0 to WarFile.Wtype.datanum - 1 do
      begin
        temp := 0;
        for i3 := 0 to WarFile.Wtype.Rdata[i2].num - 1 do
        begin
          for I4 := 0 to WarFile.Wtype.Rdata[i2].Rdataline[i3].len - 1 do
          begin
            for i5 := 0 to WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
            begin
              //WriteRDataStr(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], displaybackstr(XLSReadWriteII41.Sheets[0].AsString[temp, i2 + 1]));
              //showmessage(xls.GetStringFromCell(temp+1,i2+1));
              //cell := xls.GetCellValueIndexed(i2+2, temp+1, XF);
              //WriteRDataStr(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], cell.ToSimpleString);
              //value := xlsxioread_sheet_next_cell(sheet);
              WriteRDataStr(@WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], utf8toansi(strings[i2+1][temp]));
              inc(temp);
            end;
          end;
        end;
      end;

       //xls.Free;
//      XLSReadWriteII41.Free;
      xlsxioread_sheet_close(sheet);
      xlsxioread_close(xls);

      CalWNamepos(@warFile);
      combobox1.Clear;
      for I2 := 0 to warfile.Wtype.datanum - 1 do
        combobox1.Items.Add(CalWname(I2));
      combobox1.ItemIndex := 0;

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
  wareditbufbmp: TBitmap;
begin
  readW(gamepath + wardata,@warFile);
  CalWnamepos(@warFile);
  combobox1.Clear;
  for I := 0 to warfile.Wtype.datanum - 1 do
    combobox1.Items.Add(CalWname(I));
  combobox1.ItemIndex := 0;
  displayW;

   if checkbox1.Checked then
    begin
      try
        if (ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0]) >= 0)
        and (ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0]) < wareditmapfile.num) then
          displaywareditmap(@wareditmapfile.map[ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0])], @poseditmap)
        else
        begin
          poseditmap.Canvas.Brush.Color := clBlack;
          poseditmap.Canvas.Brush.Style := bsSolid;
          poseditmap.Canvas.FillRect(poseditmap.Canvas.ClipRect);
        end;
        wareditbufbmp := tbitmap.Create;
        wareditbufbmp.Width := image1.Width;
        wareditbufbmp.Height := image1.Height;
        wareditbufbmp.Canvas.StretchDraw(wareditbufbmp.Canvas.ClipRect, poseditmap);
        image1.Canvas.CopyRect(image1.Canvas.ClipRect, wareditbufbmp.Canvas, wareditbufbmp.Canvas.ClipRect);
        wareditbufbmp.free;
        wareditbmp.Canvas.CopyRect(wareditbmp.Canvas.ClipRect, image1.Canvas, image1.Canvas.ClipRect);
        countwarpos;
      except

      end;
    end;
  countwarpos;
end;

procedure TForm10.Button2Click(Sender: TObject);
var
  I1,I2,I3,I4,i5, F: integer;
begin
  F := filecreate(gamepath + wardata);
  for i1 := 0 to WarFile.Wtype.datanum - 1 do
    for I2 := 0 to warFile.Wtype.Rdata[i1].num - 1 do
      for i3 := 0 to warFile.Wtype.Rdata[i1].Rdataline[i2].len - 1 do
        for i4 := 0 to warFile.Wtype.Rdata[i1].Rdataline[i2].Rarray[i3].incnum - 1 do
        begin
          if warFile.Wtype.Rdata[i1].Rdataline[i2].Rarray[i3].dataarray[i4].dataLen > 0 then
            filewrite(F,warFile.Wtype.Rdata[i1].Rdataline[i2].Rarray[i3].dataarray[i4].Data[0], warFile.Wtype.Rdata[i1].Rdataline[i2].Rarray[i3].dataarray[i4].datalen);
        end;

  fileclose(F);

  try
    readw(gamepath + wardata, @useW);
  except

  end;
end;

procedure TForm10.Button3Click(Sender: TObject);
begin
  if MessageBox(Self.Handle, '是否添加项到最后，以当前值为缺省值？',  '添加项到最后', MB_OKCANCEL) = 1 then
  begin
    if warfile.Wtype.datanum < 0 then
    begin
      warfile.Wtype.datanum := 0;
      setlength(warfile.Wtype.Rdata, warfile.Wtype.datanum);
    end;
    AddnewWData(@warfile, nil);
    if (warfile.Wtype.datanum > 1) and (combobox1.ItemIndex >= 0) then
      copyRdata(@warfile.Wtype.Rdata[combobox1.ItemIndex],@warfile.Wtype.Rdata[warfile.Wtype.datanum - 1]);
    combobox1.Items.Add(CalWname(Warfile.Wtype.datanum - 1));
    combobox1.ItemIndex := Warfile.Wtype.datanum - 1;
    displayW;
    countwarpos;
  end;
end;

procedure TForm10.Button4Click(Sender: TObject);
var
  temp: integer;
  arrg:boolean;
begin
  if WarFile.Wtype.datanum = 1 then
    showmessage('只剩最后一项，请不要删除！')
  else
  begin
    if MessageBox(Self.Handle, '是否删除最后一项？',  '删除最后一项', MB_OKCANCEL) = 1 then
    begin
      temp := combobox1.ItemIndex;
      arrg := false;
      if temp = WarFIle.Wtype.datanum - 1 then
        arrg := true;
      dec(WarFIle.Wtype.datanum);
      setlength(Warfile.Wtype.Rdata, Warfile.Wtype.datanum);
      combobox1.Items.Delete(WarFIle.Wtype.datanum);
      combobox1.ItemIndex := temp;
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
  i2,i3,i4,i5: integer;
  temp: integer;
begin
  if MessageBox(Self.Handle, '导出Excel需要本机已经安装Excel，并且导出时间较长，过程中请不要进行操作。确实要导出吗？',  '导出Excel', MB_OKCANCEL) = 1 then
  begin

    ExcelApp := CreateOleObject('Excel.Application');
    ExcelApp.Caption := 'UPedit导出Excel操作';
    excelapp.visible := true;
    ExcelApp.WorkBooks.Add;
//    ExcelApp.WorkSheets[2].name := '物品';
//    ExcelApp.Cells[1,4].Value := '第一行第四列';

    if integer(ExcelApp.workSheets.count) < 1 then
      ExcelApp.workSheets.add;

//    ExcelApp.workSheets[1].activate;
//    ExcelApp.WorkSheets[1].name := warExcelopname;

    temp := 1;
    ExcelApp.Caption := 'UPedit导出Excel操作中(' + warExcelopname +')';

    for i2 := 0 to Wtypedataitem - 1 do
      if Wini.Wterm[i2].datanum > 0 then
        for i3 := 0 to Wini.Wterm[i2].datanum - 1 do
          for i4 := 0 to Wini.Wterm[i2].incnum - 1 do
          begin
            if i3 > 0 then
            begin
//              ExcelApp.Cells[1, temp].value := displaystr(Wini.Wterm[i2 + i4].name + inttostr(i3));
            end
            else
//              ExcelApp.Cells[1, temp].value := displaystr(Wini.Wterm[i2 + i4].name);
//            inc(temp);
          end;
    for i2 := 0 to WarFile.Wtype.datanum - 1 do
    begin
      ExcelApp.Caption := 'UPedit导出Excel操作中(' + warExcelopname + ':' + inttostr(i2 + 1) + '/' + inttostr(WarFile.Wtype.datanum) + ')';
      temp := 1;
      for i3 := 0 to WarFile.Wtype.Rdata[i2].num - 1 do
        for I4 := 0 to WarFile.Wtype.Rdata[i2].Rdataline[i3].len - 1 do
          for i5 := 0 to WarFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
          begin
//            excelApp.Cells[i2 + 2, temp].value := displaystr(readRDatastr(@warFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]));
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
  i2,i3,i4,i5: integer;
  temp, temp2: integer;
begin
  if MessageBox(Self.Handle, '导入Excel需要本机已经安装Excel，并且导入时间较长，过程中请不要进行操作。确实要导入吗？',  '导入Excel', MB_OKCANCEL) = 1 then
  begin
    opendialog1.Filter := 'excel表格文件|*.xls;*.xlsx';
    if opendialog1.Execute then
    begin
      ExcelApp := CreateOleObject('Excel.Application');
      ExcelApp.Caption := 'UPedit导入Excel操作';
      excelapp.visible := true;
      ExcelApp.WorkBooks.Open( opendialog1.FileName );

//      ExcelApp.workSheets[1].activate;
      ExcelApp.Caption := 'UPedit导入Excel操作中(' + warExcelopname + ')';


      i2 := 2;
      while True do
      begin
//        if string(excelApp.cells[i2, 1].value) = '' then
          break;
        inc(i2);
      end;

      warFile.Wtype.datanum := 0;
      setlength(warFile.Wtype.Rdata, warFile.Wtype.datanum);
      warFile.Wtype.namepos := -1;
      warFile.Wtype.mappos := -1;

      for i3 := 1 to i2 - 2 do
      begin
        AddNewWData(@Warfile, nil);
      end;

      for i2 := 0 to warFile.Wtype.datanum - 1 do
      begin
        ExcelApp.Caption := 'UPedit导入Excel操作中(' + warExcelopname + ':' + inttostr(i2 + 1) + '/' + inttostr(Warfile.Wtype.datanum) + ')';
        temp := 0;
        for i3 := 0 to warFile.Wtype.Rdata[i2].num - 1 do
        begin
          if (i2 = 0) and (Wini.Wterm[i3].isname = 1) then
            warFile.Wtype.namepos := i3;
          if (i2 = 0) and (Wini.Wterm[i3].ismapnum = 1) then
            warFile.Wtype.mappos := i3;
          for I4 := 0 to warFile.Wtype.Rdata[i2].Rdataline[i3].len - 1 do
          begin
            for i5 := 0 to warFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
            begin
//              WriteRDataStr(@warFile.Wtype.Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], displaybackstr(excelApp.Cells[i2 + 2, temp + 1].value));
              inc(temp);
            end;
          end;
        end;

      end;

      ExcelApp.Caption := 'UPedit导入Excel完成！';
      ExcelApp := Unassigned;
      CalWNamepos(@warFile);
      combobox1.Clear;
      for I2 := 0 to warfile.Wtype.datanum - 1 do
        combobox1.Items.Add(CalWname(I2));
      combobox1.ItemIndex := 0;

      ComboBox1Select(Sender);
      excelApp.Quit;
      SetForegroundWindow(application.Handle);
      showmessage('导入Excel完成！');
    end;
  end;
end;

procedure TForm10.CheckBox1Click(Sender: TObject);
var
  wareditbufbmp:Tbitmap;
begin
  if checkbox1.Checked then
  begin
    try
      image1.Visible := true;

      wareditbufbmp := Tbitmap.Create;
      wareditbufbmp.Width := image1.Width;
      wareditbufbmp.Height := image1.Height;
      wareditbmp.Width := image1.Width;
      wareditbmp.Height := image1.Height;
      //poseditmap.Width := image1.Width;
      //poseditmap.Height := image1.Height;
      if (ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0]) >= 0)
      and (ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0]) < wareditmapfile.num) then
        displaywareditmap(@wareditmapfile.map[ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0])], @poseditmap)
      else
      begin
        poseditmap.Canvas.Brush.Color := clBlack;
        poseditmap.Canvas.Brush.Style := bsSolid;
        poseditmap.Canvas.FillRect(poseditmap.Canvas.ClipRect);
      end;
      //displaywareditmap(@wareditmapfile.map[ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0])], @poseditmap);
      wareditbufbmp.Canvas.StretchDraw(wareditbufbmp.Canvas.ClipRect,poseditmap);
      image1.Canvas.CopyRect(image1.Canvas.ClipRect, wareditbufbmp.Canvas, wareditbufbmp.Canvas.ClipRect);
      wareditbufbmp.free;
      wareditbmp.Canvas.CopyRect(wareditbmp.Canvas.ClipRect, image1.Canvas, image1.Canvas.ClipRect);
      ListBox1Click(Sender);
      countwarpos;
    except
      wareditbufbmp.free;
      exit;
    end;
  end
  else
  begin
    image1.visible := false;
  end;
end;

procedure TForm10.CheckBox2Click(Sender: TObject);
var
  iniF: Tinifile;
  inifilename, tempstr: string;

begin
  //
  if checkbox2.Checked then
    warselectcontinue := 1
  else
    warselectcontinue := 0;

  try
    inifilename := ExtractFilePath(Paramstr(0)) + 'UPedit.ini';
    iniF := TIniFile.Create(inifilename);
    iniF.Writeinteger('W_Modify','selectcontinue', warselectcontinue);
  finally
    iniF.Free;
  end;
end;

procedure TForm10.ComboBox1Select(Sender: TObject);
var
  wareditbufbmp: Tbitmap;
begin
  if combobox1.ItemIndex >= 0 then
  begin
    displayW;
    if checkbox1.Checked then
    begin
      try
        if (ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0]) >= 0)
        and (ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0]) < wareditmapfile.num) then
          displaywareditmap(@wareditmapfile.map[ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0])], @poseditmap)
        else
        begin
          poseditmap.Canvas.Brush.Color := clBlack;
          poseditmap.Canvas.Brush.Style := bsSolid;
          poseditmap.Canvas.FillRect(poseditmap.Canvas.ClipRect);
        end;
        //displaywareditmap(@wareditmapfile.map[ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0])], @poseditmap);
        wareditbufbmp := tbitmap.Create;
        wareditbufbmp.Width := image1.Width;
        wareditbufbmp.Height := image1.Height;
        wareditbufbmp.Canvas.StretchDraw(wareditbufbmp.Canvas.ClipRect,poseditmap);
        image1.Canvas.CopyRect(image1.Canvas.ClipRect, wareditbufbmp.Canvas, wareditbufbmp.Canvas.ClipRect);
        wareditbufbmp.free;
        wareditbmp.Canvas.CopyRect(wareditbmp.Canvas.ClipRect, image1.Canvas, image1.Canvas.ClipRect);
        countwarpos;
      except
        exit;
      end;
    end;
  end;
end;

procedure TForm10.displayW;
var
  I1, I2,I3,I4, temp, temp2: integer;
  tempstr: string;
  labcount: array[1..7] of integer;
  I: Integer;
begin
  if combobox1.ItemIndex >= 0 then
  begin
    temp := 0;
    for i1 := 0 to WarFile.Wtype.Rdata[combobox1.ItemIndex].num - 1 do
      inc(temp, WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].len * WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].Rarray[0].incnum);
    setlength(Wselect, temp);
    listbox1.Clear;
    temp := -1;
    temp2 := 0;
    for I1 := 1 to 7 do
      labcount[I1] := 0;
    for i1 := 0 to warfile.Wtype.Rdata[combobox1.ItemIndex].num - 1 do
    begin
      for i2 := 0 to warfile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].len - 1 do
        for i3 := 0 to warfile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].Rarray[i2].incnum - 1 do
        begin
          tempstr := '';
          if warfile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].len > 1 then
            for i4 := listbox1.Canvas.TextWidth(displayname(wini.Wterm[temp2 + i3].name) + inttostr(i2 + 1)) div listbox1.Canvas.TextWidth(' ') to 30 do
              tempstr := tempstr + ' '
          else
            for i4 := listbox1.Canvas.TextWidth(displayname(wini.Wterm[temp2 + i3].name)) div listbox1.Canvas.TextWidth(' ') to 30 do
              tempstr := tempstr + ' ';
          if WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3].datatype = 0 then
          begin
            if (Wini.Wterm[temp2 + i3].quote <= 0) or (ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3]) < 0) or (ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3]) >= useR.Rtype[Wini.Wterm[temp2 + i3].quote].datanum) then
              if warfile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].len > 1 then
                listbox1.Items.Add(displaystr(displayname(Wini.Wterm[temp2 + i3].name) + inttostr(i2 + 1) + tempstr + inttostr(ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3]))))
              else
                listbox1.Items.Add(displaystr(displayname(Wini.Wterm[temp2 + i3].name) + tempstr + inttostr(ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3]))))
            else
              if warfile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].len > 1 then
                listbox1.Items.Add(displaystr(displayname(Wini.Wterm[temp2 + i3].name)+ inttostr(i2 + 1) + tempstr + inttostr(ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3])) + ReadRDataStr(@useR.Rtype[Wini.Wterm[temp2 + i3].quote].Rdata[ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3])].Rdataline[useR.Rtype[Wini.Wterm[temp2 + i3].quote].namepos].Rarray[0].dataarray[0])))
              else
                listbox1.Items.Add(displaystr(displayname(Wini.Wterm[temp2 + i3].name) + tempstr + inttostr(ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3])) + ReadRDataStr(@useR.Rtype[Wini.Wterm[temp2 + i3].quote].Rdata[ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3])].Rdataline[useR.Rtype[Wini.Wterm[temp2 + i3].quote].namepos].Rarray[0].dataarray[0])));
          end
          else
            if warfile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].len > 1 then
              listbox1.Items.Add(displaystr(displayname(Wini.Wterm[temp2 + i3].name)+ inttostr(i2 + 1) +   tempstr + readRDataStr(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3])))
            else
              listbox1.Items.Add(displaystr(displayname(Wini.Wterm[temp2 + i3].name) +   tempstr + readRDatastr(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3])));
            //checklistbox1.Items.Add(Rini[combobox1.ItemIndex].Rterm[temp2 + i3].name + '          ' + (Pstring(@(RFile[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3].str[0])))^);        i4 := 2;
          inc(temp);
          Wselect[temp].pos1 := i1;
          Wselect[temp].pos2 := i2;
          Wselect[temp].pos3 := i3;
          Wselect[temp].quote := Wini.Wterm[temp2 + i3].quote;
          Wselect[temp].note := Wini.Wterm[temp2 + i3].note;
          Wselect[temp].ismap := Wini.Wterm[temp2 + i3].ismapnum;
          Wselect[temp].labeltype := Wini.Wterm[temp2 + i3].labeltype;
          Wselect[temp].labelnum := Wini.Wterm[temp2 + i3].labelnum;
          if Wselect[temp].labelnum > 0 then
          begin
            inc(labcount[Wselect[temp].labelnum]);
            Wselect[temp].labelcount := labcount[Wselect[temp].labelnum];
          end;
        end;
      inc(temp2,WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[i1].Rarray[0].incnum);
    end;
  end;
end;

procedure TForm10.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  setlength(wareditgrp,0);
  setlength(warFile.Wtype.Rdata,0);
  setlength(wselect,0);
  poseditmap.Free;
  setlength(wareditmapfile.map,0);
  wareditbmp.Free;
  ImzFile.ReleaseAllPNG;
  ImzFile.Free;
  CForm10 := true;
  action := cafree;

end;

procedure TForm10.FormCreate(Sender: TObject);
var
  I: integer;
  wareditbufbmp: Tbitmap;
   PalSize:longint;
    pLogPalle:TMaxLogPalette;
    PalleEntry:TPaletteEntry;
    Palle:HPalette;
begin

  ImzFile := TimzFile.Create;

  ReadWModeIni;

  iswarmapperson := false;
  autowarfriend := false;
  wareditbmp := Tbitmap.Create;
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

  spinedit1.Value := warsmallmapsize;
  warsmallmapsize := spinedit1.Value;
  image1.Width := warsmallmapsize * 128;
  image1.height := warsmallmapsize * 128;

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
          if ImzFIle.ReadImzFromFile(gamepath + WMAPIMZ) then
          begin
            ImzFile.ReadAllPNG;
          end;
        end;
      PNGMode:
        begin
          if ImzFIle.ReadImzFromFolder(gamepath + WMAPPNGpath) then
            ImzFile.ReadAllPNG;
        end;
    end;
  except

  end;
  case WarEditMode of
    RLEMode:
      begin
        poseditmap:= tbitmap.Create;
        poseditmap.Width := 2304;
        poseditmap.Height := 1152;
        poseditmap.PixelFormat := pf8bit;
        poseditmap.Palette := palle;
      end;
    IMZMode, PNGMode:
      begin
        poseditmap:= tbitmap.Create;
        poseditmap.Width := 2304;
        poseditmap.Height := 1152;
        poseditmap.PixelFormat := pf32bit;
        //poseditmap.Palette := palle;
      end;
  end;

  CalWnamepos(@warFile);
  combobox1.Clear;
  try
    for I := 0 to warfile.Wtype.datanum - 1 do
      combobox1.Items.Add(CalWname(I));
    combobox1.ItemIndex := 0;
    displayW;
  except
    showmessage('打开战斗数据出错！');
    exit;
  end;
  try
  statusbar1.Canvas.Brush.Style := bsclear;
  statusbar1.Canvas.Font.Size := 10;
  statusbar1.Canvas.Font.Color := clblack;
  if (ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0]) >= 0)
  and (ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0]) < wareditmapfile.num) then
    displaywareditmap(@wareditmapfile.map[ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0])], @poseditmap)
  else
  begin
    poseditmap.Canvas.Brush.Color := clBlack;
    poseditmap.Canvas.Brush.Style := bsSolid;
    poseditmap.Canvas.FillRect(poseditmap.Canvas.ClipRect);
  end;
  //displaywareditmap(@wareditmapfile.map[ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[warfile.Wtype.mappos].Rarray[0].dataarray[0])], @poseditmap);
  wareditbufbmp := tbitmap.Create;
  wareditbufbmp.Width := image1.Width;
  wareditbufbmp.Height := image1.Height;
  wareditbufbmp.Canvas.StretchDraw(wareditbufbmp.Canvas.ClipRect,poseditmap);
  image1.Canvas.CopyRect(image1.Canvas.ClipRect, wareditbufbmp.Canvas, wareditbufbmp.Canvas.ClipRect);
  wareditbufbmp.free;
  wareditbmp.Width := image1.Width;
  wareditbmp.Height := image1.Height;
  wareditbmp.Canvas.CopyRect(wareditbmp.Canvas.ClipRect, image1.Picture.Bitmap.Canvas, image1.Picture.Bitmap.Canvas.ClipRect);

  if warselectcontinue = 1 then
    checkbox2.Checked := true;
  except
    showmessage('显示战斗缩略图出错！');
  end;
  countwarpos;
end;

procedure TForm10.drawwarpos;
var
  pointx,pointy,posx,posy,i,ix,iy: integer;
begin
  pointx := image1.Width DIV 2;
  pointy := image1.Height div 2 - 31 * warsmallmapsize * 2;

  image1.Picture.Bitmap.Canvas.CopyRect(image1.Picture.Bitmap.Canvas.ClipRect, wareditbmp.Canvas, wareditbmp.Canvas.ClipRect);
  for I := 0 to warenemynum - 1 do
  begin
    if warenemy[I].personnum >= 0 then
    begin
      ix := warenemy[I].x;
      iy := warenemy[I].y;
      posx := ix * warsmallmapsize - Iy * warsmallmapsize + pointx;
      posy := ix * warsmallmapsize + Iy * warsmallmapsize + pointy;
      drawwarpoint(posx,posy,clblue);
    end;
  end;

  for I := 0 to warfriendnum - 1 do
  begin
    if not(autowarfriend) or (warfriend[I].personnum >= 0) then
    begin
      ix := warfriend[I].x;
      iy := warfriend[I].y;
      posx := ix * warsmallmapsize - Iy * warsmallmapsize + pointx;
      posy := ix * warsmallmapsize + Iy * warsmallmapsize + pointy;
      drawwarpoint(posx,posy,clred);
    end;
  end;

  if iswarmapperson then
  begin
    if warmappersontype = 1 then
    begin
      ix := warfriend[warmappersonnum].x;
      iy := warfriend[warmappersonnum].y;
    end
    else if warmappersontype = 2 then
    begin
      ix := warenemy[warmappersonnum].x;
      iy := warenemy[warmappersonnum].y;
    end;

    posx := ix * warsmallmapsize - Iy * warsmallmapsize + pointx;
    posy := ix * warsmallmapsize + Iy * warsmallmapsize + pointy;
    drawwarpoint(posx,posy,clyellow);
  end;
end;

procedure TForm10.drawwarpoint(posx,posy: integer;color: cardinal);
var
  I, I2: integer;
begin
{  image1.Canvas.Pixels[posx,posy] := color;
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
  for I := 0 to warsmallmapsize  do
  begin
    image1.Canvas.Pixels[posx,posy - I] := color;
    image1.Canvas.Pixels[posx,posy + I - 2 * warsmallmapsize] := color;
    for I2 := I downto 1 do
    begin
      image1.Canvas.Pixels[posx+I2,posy - I] := color;
      image1.Canvas.Pixels[posx-I2,posy - I] := color;
      image1.Canvas.Pixels[posx + I2,posy + I - 2 * warsmallmapsize ] := color;
      image1.Canvas.Pixels[posx - I2,posy + I - 2 * warsmallmapsize ] := color;
    end;
  end;
end;

procedure TForm10.FormResize(Sender: TObject);
begin
  listbox1.Columns := listbox1.Width div 400 +1;
end;

procedure TForm10.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  tempint: integer;
  pointx,pointy,ayp,axp,ix,iy, I,I2: integer;
begin
  if Button = mbleft then
  begin
    tempint := -1;
    if iswarmapperson then
    begin
      pointx := image1.Width DIV 2;
      pointy := image1.Height div 2 - 31 * warsmallmapsize * 2;
      Ayp := Round((-x + pointx + y -  pointy + warsmallmapsize) / (warsmallmapsize * 2));
      Axp := ROund((x - pointx + y -  pointy + warsmallmapsize) / (warsmallmapsize * 2));
      if (axp in [0..63]) and (ayp in [0..63])  then
      begin
        iswarmapperson := false;
        tempint := -1;
        for I := 0 to warfriendnum - 1 do
          if (axp = warfriend[I].x) and (ayp = warfriend[I].y) and (not(autowarfriend) or (warfriend[I].personnum >= 0)) then
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
            if (axp = warenemy[I].x) and (ayp = warenemy[I].y) and ( warenemy[I].personnum >= 0) then
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
          if warmappersontype = 1 then  //友军
          begin
            for I := 0 to ListBox1.Count - 1 do
              if (warmappersonnum = Wselect[I].labelcount - 1) and (Wselect[I].labeltype = 1) then
                if (Wselect[I].labelnum = 1) then
                  WriteRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[Wselect[I].pos1].Rarray[Wselect[I].pos2].dataarray[Wselect[I].pos3], axp)
                else if (Wselect[I].labelnum = 2) then
                  WriteRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[Wselect[I].pos1].Rarray[Wselect[I].pos2].dataarray[Wselect[I].pos3], ayp);

          end
          else if warmappersontype = 2 then
          begin
            for I := 0 to ListBox1.Count - 1 do
            begin
              if (warmappersonnum = Wselect[I].labelcount - 1) and (Wselect[I].labeltype = 2) then
              begin
                if (Wselect[I].labelnum = 3) then
                begin
                  WriteRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[Wselect[I].pos1].Rarray[Wselect[I].pos2].dataarray[Wselect[I].pos3], axp);
                end
                else if (Wselect[I].labelnum = 4) then
                begin
                  WriteRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[Wselect[I].pos1].Rarray[Wselect[I].pos2].dataarray[Wselect[I].pos3], ayp);
                end;
              end;
            end;
          end;

          tempint := listbox1.ItemIndex;
          displayW;
          listbox1.ItemIndex := tempint;
          if checkbox2.Checked then
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
      pointx := image1.Width DIV 2;
      pointy := image1.Height div 2 - 31 * warsmallmapsize * 2;
      Ayp := Round((-x + pointx + y -  pointy + warsmallmapsize) / (warsmallmapsize * 2));
      Axp := ROund((x - pointx + y -  pointy + warsmallmapsize) / (warsmallmapsize * 2));

      for I := 0 to warfriendnum - 1 do
      begin
        if (warfriend[I].x = axp) and (warfriend[I].y = ayp) and ((warfriend[I].personnum >= 0) or not(autowarfriend)) then
        begin
          tempint := I;
          warmappersontype := 1;
          break;
        end;
      end;

      if tempint < 0 then
        for I := 0 to warenemynum - 1 do
        begin
          if (warenemy[I].x = axp) and (warenemy[I].y = ayp) and (warenemy[I].personnum >= 0) then
          begin
            tempint := I;
            warmappersontype := 2;
            break;
          end;
        end;
      //showmessage(inttostr(tempint));
      if tempint >= 0 then
      begin
        iswarmapperson := true;
        warmappersonnum := tempint;
      end;
      drawwarpos;
    end;
    //warmappersonnum : integer;
  end;
end;

procedure TForm10.Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  pointx,pointy,ayp,axp,ix,iy,I: integer;
  tempstr: string;
begin
  pointx := image1.Width DIV 2;
  pointy := image1.Height div 2 - 31 * warsmallmapsize* 2;
  Ayp := Round((-x + pointx + y -  pointy + warsmallmapsize) / (warsmallmapsize * 2));
  Axp := ROund((x - pointx + y -  pointy + warsmallmapsize) / (warsmallmapsize * 2));
  statusbar1.Canvas.Brush.Color := clbtnface;
  statusbar1.Canvas.FillRect(statusbar1.Canvas.ClipRect);
  statusbar1.Repaint;
  tempstr := '';
  for I := 0 to warfriendnum - 1 do
  begin
    if (warfriend[I].x = axp) and (warfriend[I].y = ayp) and (not(autowarfriend) or (warfriend[I].personnum >=0)) then
    begin
      tempstr := ' 友军' + inttostr(I + 1);
      break;
    end;
  end;
  if tempstr = '' then
    for I := 0 to warenemynum - 1 do
    begin
      if (warenemy[I].x = axp) and (warenemy[I].y = ayp) and (warenemy[I].personnum >= 0) then
      begin
        tempstr := ' 敌军' + inttostr(I + 1);
        break;
      end;
    end;
  statusbar1.Canvas.Brush.Color := clbtnface;
  statusbar1.Canvas.FillRect(statusbar1.Canvas.ClipRect);
  statusbar1.Repaint;
  statusbar1.Canvas.TextOut(10,2,'X='+ inttostr(axp) +',Y=' + inttostr(ayp) + tempstr);
end;

procedure TForm10.ListBox1Click(Sender: TObject);
begin
  //
  if listbox1.ItemIndex >= 0 then
  begin
    if Wselect[listbox1.ItemIndex].labelnum > 0 then
    begin
      if ((Wselect[listbox1.ItemIndex].labelnum = 1) and (Wselect[listbox1.ItemIndex].labeltype = 1) and (not(autowarfriend) or (Warfriend[Wselect[listbox1.ItemIndex].labelcount - 1].personnum >= 0))) or ((Wselect[listbox1.ItemIndex].labelnum = 2) and (Wselect[listbox1.ItemIndex].labeltype = 1) and (not(autowarfriend) or (Warfriend[Wselect[listbox1.ItemIndex].labelcount - 1].personnum >= 0))) or ((Wselect[listbox1.ItemIndex].labelnum = 5) and not(autowarfriend)) or ((Wselect[listbox1.ItemIndex].labelnum = 7) and autowarfriend and (ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[wselect[listbox1.ItemIndex].pos1].Rarray[Wselect[listbox1.ItemIndex].pos2].dataarray[Wselect[listbox1.ItemIndex].pos3]) >= 0)) then
      begin
        iswarmapperson := true;
        warmappersontype := 1;
        warmappersonnum := Wselect[listbox1.ItemIndex].labelcount - 1;
      end
      else if ((Wselect[listbox1.ItemIndex].labelnum = 3) and (Wselect[listbox1.ItemIndex].labeltype = 2) and (Warenemy[Wselect[listbox1.ItemIndex].labelcount - 1].personnum >= 0)) or ((Wselect[listbox1.ItemIndex].labelnum = 4) and (Wselect[listbox1.ItemIndex].labeltype = 2)and (Warenemy[Wselect[listbox1.ItemIndex].labelcount - 1].personnum >= 0)) or ((Wselect[listbox1.ItemIndex].labelnum = 6) and (ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[wselect[listbox1.ItemIndex].pos1].Rarray[Wselect[listbox1.ItemIndex].pos2].dataarray[Wselect[listbox1.ItemIndex].pos3]) >= 0))  then
      begin
        iswarmapperson := true;
        warmappersontype := 2;
        warmappersonnum := Wselect[listbox1.ItemIndex].labelcount - 1;
      end
      else
        iswarmapperson := false;
    end
    else
      iswarmapperson := false;
    drawwarpos;

    statusbar2.Canvas.Brush.Color := clbtnface;
    statusbar2.Canvas.FillRect(statusbar1.Canvas.ClipRect);
    statusbar2.Repaint;
    statusbar2.Canvas.TextOut(10,2,Wselect[listbox1.ItemIndex].note);
    //listbox1DBlclick(sender);
  end;
end;

procedure TForm10.ListBox1DblClick(Sender: TObject);
var
  temp, I, temp2: integer;
begin
  if (listbox1.ItemIndex < length(Wselect)) and (listbox1.ItemIndex >= 0) then
  begin
    temp := listbox1.ItemIndex;
    if Wselect[listbox1.ItemIndex].quote <= 0 then
    begin
      if WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[wselect[listbox1.ItemIndex].pos1].Rarray[Wselect[listbox1.ItemIndex].pos2].dataarray[Wselect[listbox1.ItemIndex].pos3].datatype = 0 then
        WriteRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[wselect[listbox1.ItemIndex].pos1].Rarray[Wselect[listbox1.ItemIndex].pos2].dataarray[Wselect[listbox1.ItemIndex].pos3], strtoint64(InputBox('修改','修改此项数值', inttostr(ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[Wselect[listbox1.ItemIndex].pos1].Rarray[Wselect[listbox1.ItemIndex].pos2].dataarray[Wselect[listbox1.ItemIndex].pos3])))))
      else
        WriteRDataStr(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[Wselect[listbox1.ItemIndex].pos1].Rarray[Wselect[listbox1.ItemIndex].pos2].dataarray[Wselect[listbox1.ItemIndex].pos3], displaybackstr(InputBox('修改','修改此项字符串', displaystr(readRDataStr(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[Wselect[listbox1.ItemIndex].pos1].Rarray[Wselect[listbox1.ItemIndex].pos2].dataarray[Wselect[listbox1.ItemIndex].pos3])))));
    end
    else
    begin
      Form6.ComboBox1.Clear;
      Form6.ComboBox1.Items.Add('-1');
      for I := 0 to useR.Rtype[Wselect[listbox1.ItemIndex].quote].datanum - 1 do
        Form6.ComboBox1.Items.Add(displaystr(inttostr(I) + readRDatastr(@useR.Rtype[Wselect[listbox1.ItemIndex].quote].Rdata[I].Rdataline[useR.Rtype[Wselect[listbox1.ItemIndex].quote].namepos].Rarray[0].dataarray[0])));
      Form6.ComboBox1.ItemIndex := ReadRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[Wselect[listbox1.ItemIndex].pos1].Rarray[Wselect[listbox1.ItemIndex].pos2].dataarray[Wselect[listbox1.ItemIndex].pos3]) + 1;
      Form6.Label1.Caption := typename[Wselect[listbox1.ItemIndex].quote];
      if Form6.ShowModal = mrOK then
        WriteRDataInt(@WarFile.Wtype.Rdata[combobox1.ItemIndex].Rdataline[Wselect[listbox1.ItemIndex].pos1].Rarray[Wselect[listbox1.ItemIndex].pos2].dataarray[Wselect[listbox1.ItemIndex].pos3], Form6.ComboBox1.ItemIndex - 1);
      //Form6.Free;
    end;
    if Wselect[listbox1.ItemIndex].pos1 = WarFile.Wtype.namepos  then
    begin
      temp2 := combobox1.ItemIndex;
      combobox1.Items.Strings[temp2] := inttostr(temp2) +  ReadRDataStr(@WarFile.Wtype.Rdata[temp2].Rdataline[WarFile.Wtype.namepos].Rarray[0].dataarray[0]);
      combobox1.ItemIndex := temp2;
    end;
    displayW;
    listbox1.ItemIndex := temp;
    ListBox1Click(Sender);
    if wselect[temp].ismap > 0 then
      checkbox1click(sender);
    if wselect[temp].labelnum > 0 then
      countwarpos;
  end;
end;

procedure TForm10.SpinEdit1Change(Sender: TObject);
var
  ini: Tinifile;
begin
  if spinedit1.Value > 20 then
    spinedit1.Value := 20;
  if spinedit1.Value < 1 then
    spinedit1.Value := 1;
  warsmallmapsize := spinedit1.Value;
  image1.Width := 128 * warsmallmapsize;
  image1.Height := 128 * warsmallmapsize;
  image1.Picture.Bitmap.Width := image1.Width;
  image1.Picture.Bitmap.Height := image1.Height;
  CheckBox1Click(Sender);
  try
    ini := Tinifile.Create(ExtractFilePath(Paramstr(0)) + 'UPedit.ini');
    ini.Writeinteger('file','warsmallmapsize',warsmallmapsize);
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
    if wini.Wterm[I].datanum > 0 then
    begin
      inc(temp);
      if wini.Wterm[I].isname = 1 then
      begin
        PWF.Wtype.namepos := temp;
      end;
      if wini.Wterm[I].ismapnum = 1 then
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
  if (index >= 0) and (index < WarFile.Wtype.datanum) and (WarFile.Wtype.namepos >= 0) then
    result := inttostr(index) + widestring(displaystr(readRDatastr(@WarFile.Wtype.Rdata[index].Rdataline[WarFile.Wtype.namepos].Rarray[0].dataarray[0])))
  else
    result := inttostr(index);
  for I := 1 to length(result) - 1 do
    if result[I + 1] = '' then
    begin
      setlength(result, I);
      break;
    end;
end;

procedure readWareditgrp;
var
  offset: array of integer;
  I, idx, grp,temp: integer;
begin
  try

  idx := fileopen(gamepath + warmapidx, fmopenread);
  grp := fileopen(gamepath + warmapgrp, fmopenread);
  temp := fileseek(idx,0,2);
  setlength(wareditgrp, temp shr 2);
  setlength(offset, temp shr 2 + 1);
  fileseek(idx,0,0);
  fileread(idx, offset[1], temp);
  offset[0] := 0;
  fileseek(grp,0,0);
  for I := 0 to temp shr 2 - 1 do
  begin
    wareditgrp[I].size := offset[I + 1]- offset[I];
    if wareditgrp[I].size > 0 then
    begin
      setlength(wareditgrp[I].data, wareditgrp[I].size);
      fileread(grp, wareditgrp[I].data[0], wareditgrp[I].size);
    end
    else
    begin
      wareditgrp[I].size := 0;
      setlength(wareditgrp[I].data, wareditgrp[I].size);
    end;
  end;

  fileclose(idx);
  fileclose(grp);

  except
    //showmessage('错误');
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

procedure TForm10.displaywareditmap(waropMap: Pmap; waropbmp2:PNTbitmap);
VAR
  ix,iy, I, i2,posx,posy: integer;
  pointx,pointy: integer;
begin
  pointx := WAROPBMP2.Width DIV 2;
  pointy := waropbmp2.Height div 2 - 31 * 18;
  waropbmp2.Canvas.Brush.Color := clblack;
  waropbmp2.Canvas.FillRect(waropbmp2.Canvas.ClipRect);
  for i := 0 to min(waropmap.x ,waropmap.y) - 1 do
  begin
    for ix := I to waropmap.x - 1 do
    begin
      posx := ix * 18 - I * 18  + pointx;
      posy := ix * 9 + I * 9 + pointy;
      for I2 := 0 to waropmap.layernum - 1 do
        if (waropmap.maplayer[I2].pic[I][ix] div 2 > 0) or (I2 = 0)  then
        begin
          case WarEditMode of
            RLEMode:
              begin
                McoldrawRLE8(@wareditgrp[waropmap.maplayer[I2].pic[I][ix] div 2].data[0],wareditgrp[waropmap.maplayer[I2].pic[I][ix] div 2].size,waropbmp2, posx, posy, true);
              end;
            IMZMode, PNGMode:
              begin
                ImzFile.SceneQuickDraw(waropbmp2, waropmap.maplayer[I2].pic[I][ix] div 2, posx, posy);
              end;
          end;
       end;
    end;
    for Iy := I + 1 to waropmap.y - 1 do
    begin
      posx := i * 18 - Iy * 18  + pointx;
      posy := i * 9 + Iy * 9 + pointy;
      for I2 := 0 to waropmap.layernum - 1 do
        if (waropmap.maplayer[I2].pic[Iy][i] div 2 > 0) or (I2 = 0) then
        begin
          case WarEditMode of
            RLEMode:
              begin
                McoldrawRLE8(@wareditgrp[waropmap.maplayer[I2].pic[Iy][i] div 2].data[0],wareditgrp[waropmap.maplayer[I2].pic[Iy][i] div 2].size,waropbmp2, posx, posy, true);
              end;
            IMZMode, PNGMode:
              begin
                ImzFile.SceneQuickDraw(waropbmp2, waropmap.maplayer[I2].pic[Iy][i] div 2, posx, posy);
              end;
          end;
        end;
    end;
  end;
end;

end.
