unit Redit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, head, ExtCtrls, StdCtrls, inifiles, ComCtrls, comobj,
  {XLSFonts4, XLSReadWriteII4, SheetData4,} CheckLst, math,
  System.IOUtils,
  // VCL.FlexCel.Core, FlexCel.XlsAdapter;
  xlsxio;

type

  TForm5 = class(TForm)
    Panel1: TPanel;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Panel2: TPanel;
    ComboBox3: TComboBox;
    StatusBar1: TStatusBar;
    Button5: TButton;
    Button6: TButton;
    OpenDialog1: TOpenDialog;
    Panel3: TPanel;
    CheckListBox1: TCheckListBox;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    ComboBox4: TComboBox;
    Edit3: TEdit;
    Button10: TButton;
    Label5: TLabel;
    Button11: TButton;
    SaveDialog1: TSaveDialog;
    Button12: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);

    procedure displayR;
    procedure arrange;

    procedure ComboBox1Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

    procedure FormResize(Sender: TObject);
    procedure checklistbox1DblClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure checklistbox1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure RadioButton1Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Edit1KeyPress(Sender: TObject; var Key: Char);
    procedure Edit2KeyPress(Sender: TObject; var Key: Char);
    procedure Button11Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure changeRitem(idxnum, pos1, pos2, pos3: integer);
    procedure ComboBox2Select(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  RFile: TRFile;
  Rini: array of TRini;
  typenumber: integer;
  typename: array of string;
  typedataitem: array of integer;
  Rinitial: boolean = false;
  Rselect: array of Tselect;
  candisplayR: boolean = true;

  strings: array [0 .. 9999] of array [0 .. 9999] of ansistring;

procedure copyRdata(source, dest: PRdata);
function readR(idx, grp: string; PRF: PRfile): boolean;
function readDB(db: string; PRF: PRfile): boolean;
procedure readini;
procedure calnamepos(PRF: PRfile);
procedure saveR(idx, grp: string; PRF: PRfile);
procedure addnewRdata(PRF: PRfile; CRType: integer; PRD: PRdata);

implementation

{$R *.dfm}

uses
  main, ReditForm;

procedure TForm5.Button10Click(Sender: TObject);
var
  I, a, b, temp: integer;
begin
  if RadioButton1.Checked then
  begin
    for I := 0 to length(Rselect) - 1 do
      if CheckListBox1.Checked[I] then
      begin
        case ComboBox4.ItemIndex of
          0:
            begin
              WriteRDataStr(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3], Edit3.Text);
            end;
          1:
            begin
              if RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3].datatype = 0 then
                WriteRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3],
                  strtoint64(Edit3.Text) + ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3]));
            end;
          2:
            begin
              if RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3].datatype = 0 then
                WriteRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3],
                  ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3]) - strtoint64(Edit3.Text));
            end;
          3:
            begin
              if RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3].datatype = 0 then
                WriteRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3],
                  ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3]) * strtoint64(Edit3.Text));
            end;
          4:
            begin
              if RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3].datatype = 0 then
                WriteRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3],
                  ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3]) div strtoint64(Edit3.Text));
            end;
        end;
      end;
  end
  else if RadioButton2.Checked then
  begin
    a := strtoint64(Edit1.Text);
    b := strtoint64(Edit2.Text);
    if a > b then
    begin
      I := a;
      a := b;
      b := I;
    end;
    for I := a to b do
    begin
      case ComboBox4.ItemIndex of
        0:
          begin
            WriteRDataStr(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3], Edit3.Text);
          end;
        1:
          begin
            if RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3].datatype = 0 then
              WriteRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3],
                strtoint64(Edit3.Text) + ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3]));
          end;
        2:
          begin
            if RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3].datatype = 0 then
              WriteRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3],
                ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3]) - strtoint64(Edit3.Text));
          end;
        3:
          begin
            if RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3].datatype = 0 then
              WriteRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3],
                ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3]) * strtoint64(Edit3.Text));
          end;
        4:
          begin
            if RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3].datatype = 0 then
              WriteRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3],
                ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[I].pos1].Rarray[Rselect[I].pos2].dataarray[Rselect[I].pos3]) div strtoint64(Edit3.Text));
          end;
      end;
    end;
  end;
  temp := ComboBox2.ItemIndex;
  if (RFile.Rtype[ComboBox1.ItemIndex].namepos >= 0) and (RFile.Rtype[ComboBox1.ItemIndex].namepos < RFile.Rtype[ComboBox1.ItemIndex].Rdata[temp].num) then
    ComboBox2.Items.strings[temp] := inttostr(temp) + readRDatastr(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[temp].Rdataline[RFile.Rtype[ComboBox1.ItemIndex].namepos].Rarray[0].dataarray[0]);
  ComboBox2.ItemIndex := temp;
  displayR;
end;

procedure TForm5.Button11Click(Sender: TObject);
var
  filename: string;
  i1, i2, i3, i4, i5: integer;
  temp, temp2: integer;
  xls: plxw_workbook;
  sheet: plxw_worksheet;
begin
  SaveDialog1.Filter := 'excel文件|*.xlsx';
  if SaveDialog1.Execute then
  begin
    // try
    filename := SaveDialog1.filename;
    if not SameText(ExtractFileExt(filename), '.xlsx') then
      filename := filename + '.xlsx';
    xls := workbook_new(pansichar(UnicodeToMulti(pwidechar(filename), 65001)));

    for i1 := 0 to RFile.typenumber - 1 do
    begin
      sheet := workbook_add_worksheet(xls, pansichar(UnicodeToMulti(pwidechar(typename[i1]), 65001)));
      temp := 0;
      if i1 = 0 then
      begin

        temp2 := 0;
        for i2 := 0 to typedataitem[i1] - 1 do
          if Rini[i1].Rterm[i2].datanum > 0 then
            inc(temp2, Rini[i1].Rterm[i2].datanum * Rini[i1].Rterm[i2].incnum);

        for i2 := 0 to typedataitem[i1] - 1 do
          if Rini[i1].Rterm[i2].datanum > 0 then
            for i3 := 0 to Rini[i1].Rterm[i2].datanum - 1 do
              for i4 := 0 to Rini[i1].Rterm[i2].incnum - 1 do
              begin
                if i3 > 0 then
                begin
                  worksheet_write_string(sheet, temp, 0, pansichar(UnicodeToMulti(pwidechar(displaystr(Rini[i1].Rterm[i2 + i4].name + inttostr(i3))), 65001)), nil);
                end
                else
                begin
                  worksheet_write_string(sheet, temp, 0, pansichar(UnicodeToMulti(pwidechar(displaystr(Rini[i1].Rterm[i2 + i4].name)), 65001)), nil);
                end;
                inc(temp);
              end;

        for i2 := 0 to RFile.Rtype[i1].datanum - 1 do
        begin
          temp := 0;
          for i3 := 0 to RFile.Rtype[i1].Rdata[i2].num - 1 do
          begin
            for i4 := 0 to RFile.Rtype[i1].Rdata[i2].Rdataline[i3].len - 1 do
              for i5 := 0 to RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
              begin
                if RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].datatype = 1 then
                begin
                  worksheet_write_string(sheet, temp, i2 + 1, pansichar(UnicodeToMulti(pwidechar(readRDatastr(@RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5])), 65001)), nil)
                end
                else
                begin
                  worksheet_write_number(sheet, temp, i2 + 1, ReadRDataInt(@RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]), nil);
                end;
                inc(temp);
              end;
          end;
        end;

      end
      else
      begin

        temp2 := 0;
        for i2 := 0 to typedataitem[i1] - 1 do
          if Rini[i1].Rterm[i2].datanum > 0 then
            inc(temp2, Rini[i1].Rterm[i2].datanum * Rini[i1].Rterm[i2].incnum);
        for i2 := 0 to typedataitem[i1] - 1 do
        begin
          if Rini[i1].Rterm[i2].datanum > 0 then
            for i3 := 0 to Rini[i1].Rterm[i2].datanum - 1 do
              for i4 := 0 to Rini[i1].Rterm[i2].incnum - 1 do
              begin
                if i3 > 0 then
                begin
                  worksheet_write_string(sheet, 0, temp, pansichar(UnicodeToMulti(pwidechar(Rini[i1].Rterm[i2 + i4].name + inttostr(i3)), 65001)), nil)
                end
                else
                begin
                  worksheet_write_string(sheet, 0, temp, pansichar(UnicodeToMulti(pwidechar(Rini[i1].Rterm[i2 + i4].name), 65001)), nil);
                end;
                inc(temp);
              end;

        end;

        for i2 := 0 to RFile.Rtype[i1].datanum - 1 do
        begin
          temp := 0;
          for i3 := 0 to RFile.Rtype[i1].Rdata[i2].num - 1 do
            for i4 := 0 to RFile.Rtype[i1].Rdata[i2].Rdataline[i3].len - 1 do
              for i5 := 0 to RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
              begin
                if RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].datatype = 1 then
                begin
                  worksheet_write_string(sheet, i2 + 1, temp, pansichar(UnicodeToMulti(pwidechar(displaystr(readRDatastr(@RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]))),
                    65001)), nil)
                end
                else
                begin
                  temp2 := worksheet_write_number(sheet, i2 + 1, temp, ReadRDataInt(@RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]), nil);
                end;
                inc(temp);
              end;
        end;
      end;

    end;

    workbook_close(xls);

    showmessage('导出Excel成功！');
    // except
    // showmessage('导出Excel错误！');
    // exit;
    // end;
  end;

end;

procedure TForm5.Button12Click(Sender: TObject);
var
  i1, i2, i3, i4, i5: integer;
  temp: integer;
  // XLSReadWriteII41 : TXLSReadWriteII4;
  // xls: TXlsFile;
  xf: integer;
  // cell: TCellValue;
  xls: xlsxioreader;
  sheet: xlsxioreadersheet;
  value: pansichar;
  ic, ir: integer;
begin

  OpenDialog1.Filter := 'excel表格文件|*.xlsx';
  if OpenDialog1.Execute then
  begin
    // try
    // XLSReadWriteII41 := TXLSReadWriteII4.Create(self);
    // XLSReadWriteII41.Clear;
    // XLSReadWriteII41.Filename := opendialog1.Filename;
    // XLSReadWriteII41.Read;
    // xls := TXlsFile.Create (opendialog1.Filename);
    xls := xlsxioread_open(pansichar(UnicodeToMulti(pwidechar(OpenDialog1.filename), 65001)));
    RFile.typenumber := typenumber;
    for i1 := 0 to RFile.typenumber - 1 do
    begin
      // xls.ActiveSheetByName:=typename[i1];
      sheet := xlsxioread_sheet_open(xls, pansichar(ansitoutf8(typename[i1])), XLSXIOREAD_SKIP_EMPTY_ROWS);

      ir := 0;
      ic := 0;
      while (xlsxioread_sheet_next_row(sheet) <> 0) do
      begin
        ic := 0;
        while true do
        begin
          value := xlsxioread_sheet_next_cell(sheet);
          if value = nil then
            break;
          strings[ir][ic] := value;
          inc(ic);
        end;
        inc(ir);
      end;

      if i1 = 0 then
      begin

        i2 := 2;
        RFile.Rtype[i1].datanum := 0;
        setlength(RFile.Rtype[i1].Rdata, RFile.Rtype[i1].datanum);

        for i3 := 0 to i2 - 2 do
          addnewRdata(@RFile, i1, nil);

        for i2 := 0 to RFile.Rtype[i1].datanum - 1 do
        begin
          temp := 0;
          for i3 := 0 to typedataitem[i1] - 1 do
          begin
            if Rini[i1].Rterm[i3].datanum > 0 then
            begin
              for i4 := 0 to Rini[i1].Rterm[i3].datanum - 1 do
              begin
                for i5 := 0 to Rini[i1].Rterm[i3].incnum - 1 do
                begin
                  WriteRDataStr(@RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], displaybackstr(utf8toansi(strings[temp, i2 + 1])));
                  inc(temp);
                end;
              end;
            end;
          end;
        end;

      end
      else
      begin
        i2 := 1;
        RFile.Rtype[i1].datanum := 0;
        setlength(RFile.Rtype[i1].Rdata, RFile.Rtype[i1].datanum);
        i2 := ir;
        for i3 := 0 to i2 - 2 do
          addnewRdata(@RFile, i1, nil);
        for i2 := 0 to RFile.Rtype[i1].datanum - 1 do
        begin
          temp := 0;
          for i3 := 0 to RFile.Rtype[i1].Rdata[i2].num - 1 do
          begin
            for i4 := 0 to RFile.Rtype[i1].Rdata[i2].Rdataline[i3].len - 1 do
            begin
              for i5 := 0 to RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
              begin
                WriteRDataStr(@RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], displaybackstr(utf8toansi(strings[i2 + 1, temp])));
                inc(temp);
              end;
            end;
          end;
        end;

      end;
      xlsxioread_sheet_close(sheet);
    end;
    calnamepos(@RFile);
    ComboBox1.Clear;
    for i1 := 0 to RFile.typenumber - 1 do
      ComboBox1.Items.Add(typename[i1]);
    ComboBox1.ItemIndex := 0;
    arrange;
    displayR;
    xlsxioread_close(xls);
    showmessage('导入Excel成功！');
    // except on E: Exception
    // do
    // showmessage('导入Excel错误！' + E.ClassName+' error raised, with message : '+E.Message);
    // exit;
    // end;
  end;
end;

procedure TForm5.Button1Click(Sender: TObject);
var
  i1, i2: integer;
begin
  //
  if ComboBox3.ItemIndex >= 0 then
    if readR(Gamepath + RidxFilename[ComboBox3.ItemIndex], Gamepath + RFilename[ComboBox3.ItemIndex], @RFile) then
    begin
      calnamepos(@RFile);
      ComboBox1.Clear;
      for i1 := 0 to RFile.typenumber - 1 do
        ComboBox1.Items.Add(displaystr(typename[i1]));
      ComboBox1.ItemIndex := 0;
      arrange;
      displayR;
    end
    else
    begin
      RFile.typenumber := typenumber;
      setlength(RFile.Rtype, RFile.typenumber);
      ComboBox1.Clear;
      ComboBox2.Clear;
      for i1 := 0 to RFile.typenumber - 1 do
      begin
        ComboBox1.Items.Add(displaystr(typename[i1]));
        RFile.Rtype[i1].datanum := 0;
        setlength(RFile.Rtype[i1].Rdata, 0);
      end;
      calnamepos(@RFile);
      ComboBox1.ItemIndex := 0;
      showmessage('读取R文件失败！');
      arrange;
      displayR;
    end;
end;

procedure TForm5.Button2Click(Sender: TObject);
begin
  saveR(Gamepath + RidxFilename[ComboBox3.ItemIndex], Gamepath + RFilename[ComboBox3.ItemIndex], @RFile);
  if ComboBox3.ItemIndex = 0 then
    if readR(Gamepath + RidxFilename[0], Gamepath + RFilename[0], @useR) then
      calnamepos(@useR);
end;

procedure TForm5.Button3Click(Sender: TObject);
var
  temp: integer;
begin
  if MessageBox(Self.Handle, '是否添加项到最后，以当前值为缺省值？', '添加项到最后', MB_OKCANCEL) = 1 then
  begin
    addnewRdata(@RFile, ComboBox1.ItemIndex, nil);
    if RFile.Rtype[ComboBox1.ItemIndex].datanum > 1 then
    begin
      copyRdata(@(RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex]), @(RFile.Rtype[ComboBox1.ItemIndex].Rdata[RFile.Rtype[ComboBox1.ItemIndex].datanum - 1]));
    end;
    arrange;
    ComboBox2.ItemIndex := RFile.Rtype[ComboBox1.ItemIndex].datanum - 1;
    ComboBox2Select(Sender);
  end;
end;

procedure addnewRdata(PRF: PRfile; CRType: integer; PRD: PRdata);
var
  i3, i4, i5, temp: integer;
begin

  if PRF.Rtype[CRType].datanum < 0 then
    PRF.Rtype[CRType].datanum := 0;
  inc(PRF.Rtype[CRType].datanum);
  setlength(PRF.Rtype[CRType].Rdata, PRF.Rtype[CRType].datanum);

  temp := 0;
  for i3 := 0 to typedataitem[CRType] - 1 do
    if Rini[CRType].Rterm[i3].datanum > 0 then
      inc(temp);
  PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].num := temp;
  setlength(PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline, PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].num);

  temp := -1;
  for i3 := 0 to typedataitem[CRType] - 1 do
  begin
    if Rini[CRType].Rterm[i3].datanum > 0 then
    begin
      inc(temp);
      PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].len := Rini[CRType].Rterm[i3].datanum;
      setlength(PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray, Rini[CRType].Rterm[i3].datanum);
      for i4 := 0 to Rini[CRType].Rterm[i3].datanum - 1 do
      begin
        PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray[i4].incnum := Rini[CRType].Rterm[i3].incnum;
        setlength(PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray[i4].dataarray, PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray
          [i4].incnum);
        for i5 := 0 to Rini[CRType].Rterm[i3].incnum - 1 do
        begin
          PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datatype := Rini[CRType].Rterm[i3 + i5].isstr;
          PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen := Rini[CRType].Rterm[i3 + i5].datalen;
          if PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen >= 0 then
            setlength(PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].data,
              PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen)
          else
          begin
            PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen := 0;
            setlength(PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].data,
              PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen);
          end;
          if PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen > 0 then
            zeromemory(@PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].data[0],
              PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1].Rdataline[temp].Rarray[i4].dataarray[i5].datalen);
        end;
      end;
    end;
  end;

  if PRD <> nil then
    copyRdata(PRD, @PRF.Rtype[CRType].Rdata[PRF.Rtype[CRType].datanum - 1]);

end;

procedure TForm5.Button4Click(Sender: TObject);
var
  temp: integer;
  arrg: boolean;
begin
  if RFile.Rtype[ComboBox1.ItemIndex].datanum <= 1 then
    showmessage('存在的项目数量太少（小于1），请不要删除！')
  else
  begin
    if MessageBox(Self.Handle, '是否删除最后一项？', '删除最后一项', MB_OKCANCEL) = 1 then
    begin
      temp := ComboBox2.ItemIndex;
      arrg := false;
      if temp = RFile.Rtype[ComboBox1.ItemIndex].datanum - 1 then
        arrg := true;
      dec(RFile.Rtype[ComboBox1.ItemIndex].datanum);
      setlength(RFile.Rtype[ComboBox1.ItemIndex].Rdata, RFile.Rtype[ComboBox1.ItemIndex].datanum);
      arrange;
      ComboBox2.ItemIndex := temp;
      if arrg then
        displayR;
    end;
  end;
end;

procedure TForm5.Button5Click(Sender: TObject);
var
  ExcelApp: Variant;
  i1, i2, i3, i4, i5: integer;
  temp: integer;
begin
  if MessageBox(Self.Handle, '导出Excel需要本机已经安装Excel，并且导出时间较长，过程中请不要进行操作。确实要导出吗？', '导出Excel', MB_OKCANCEL) = 1 then
  BEGIN
    ExcelApp := CreateOleObject('Excel.Application');
    ExcelApp.Caption := 'UPedit导出Excel操作';
    ExcelApp.visible := true;
    ExcelApp.WorkBooks.Add;
    // ExcelApp.WorkSheets[2].name := '物品';
    // ExcelApp.Cells[1,4].Value := '第一行第四列';

    for i1 := integer(ExcelApp.workSheets.count) to RFile.typenumber - 1 do
    begin
      ExcelApp.workSheets.Add;
    end;

    for i1 := 0 to RFile.typenumber - 1 do
    begin
      // ExcelApp.workSheets[i1 + 1].activate;
      // ExcelApp.WorkSheets[i1 + 1].name := displaystr(typename[i1]);

      temp := 1;
      if i1 = 0 then
      begin
        ExcelApp.Caption := 'UPedit导出Excel操作中(' + displaystr(typename[i1]) + ')';
        for i2 := 0 to typedataitem[i1] - 1 do
          if Rini[i1].Rterm[i2].datanum > 0 then
            for i3 := 0 to Rini[i1].Rterm[i2].datanum - 1 do
              for i4 := 0 to Rini[i1].Rterm[i2].incnum - 1 do
              begin
                if i3 > 0 then
                begin
                  // ExcelApp.Cells[temp, 1].value := displaystr(Rini[i1].Rterm[i2 + i4].name + inttostr(i3));
                end
                else
                  // ExcelApp.Cells[temp, 1].value := displaystr(Rini[i1].Rterm[i2 + i4].name);
                  inc(temp);
              end;

        for i2 := 0 to RFile.Rtype[i1].datanum - 1 do
        begin
          ExcelApp.Caption := 'UPedit导出Excel操作中(' + displaystr(typename[i1]) + ':' + inttostr(i2 + 1) + '/' + inttostr(RFile.Rtype[i1].datanum) + ')';
          temp := 1;
          for i3 := 0 to RFile.Rtype[i1].Rdata[i2].num - 1 do
            for i4 := 0 to RFile.Rtype[i1].Rdata[i2].Rdataline[i3].len - 1 do
              for i5 := 0 to RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
              begin
                // excelApp.Cells[temp, i2 + 2].value := displaystr(readRDataStr(@RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]));
                inc(temp);
              end;
        end;
      end
      else
      begin
        ExcelApp.Caption := 'UPedit导出Excel操作中(' + displaystr(typename[i1]) + ')';
        for i2 := 0 to typedataitem[i1] - 1 do
          if Rini[i1].Rterm[i2].datanum > 0 then
            for i3 := 0 to Rini[i1].Rterm[i2].datanum - 1 do
              for i4 := 0 to Rini[i1].Rterm[i2].incnum - 1 do
              begin
                if i3 > 0 then
                begin
                  // ExcelApp.Cells[1, temp].value := displaystr(Rini[i1].Rterm[i2 + i4].name + inttostr(i3));
                end
                else
                  // ExcelApp.Cells[1, temp].value := displaystr(Rini[i1].Rterm[i2 + i4].name);
                  inc(temp);
              end;
        for i2 := 0 to RFile.Rtype[i1].datanum - 1 do
        begin
          ExcelApp.Caption := 'UPedit导出Excel操作中(' + displaystr(typename[i1]) + ':' + inttostr(i2 + 1) + '/' + inttostr(RFile.Rtype[i1].datanum) + ')';
          temp := 1;
          for i3 := 0 to RFile.Rtype[i1].Rdata[i2].num - 1 do
            for i4 := 0 to RFile.Rtype[i1].Rdata[i2].Rdataline[i3].len - 1 do
              for i5 := 0 to RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
              begin
                // excelApp.Cells[i2 + 2, temp].value := displaystr(readRDatastr(@RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5]));
                inc(temp);
              end;
        end;
      end;
    end;
    ExcelApp.Caption := 'UPedit导出Excel完成！';
    ExcelApp := Unassigned;
    SetForegroundWindow(application.Handle);
    showmessage('导出Excel完成！请到Excel程序中保存文件！');
  END;
end;

procedure TForm5.Button6Click(Sender: TObject);
var
  ExcelApp: Variant;
  i1, i2, i3, i4, i5: integer;
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
      // ExcelApp.WorkBooks.Add;
      ExcelApp.WorkBooks.Open(OpenDialog1.filename);

      // ExcelApp.WorkSheets[2].name := '物品';
      // ExcelApp.Cells[1,4].Value := '第一行第四列';
      RFile.typenumber := typenumber;
      for i1 := 0 to RFile.typenumber - 1 do
      begin
        // ExcelApp.WorkSheets[i1 + 1].name := typename[i1];
        // ExcelApp.workSheets[i1 + 1].activate;
        ExcelApp.Caption := 'UPedit导入Excel操作中(' + displaystr(typename[i1]) + ')';
        if i1 = 0 then
        begin

          i2 := 2;
          while true do
          begin
            // if String(excelApp.Cells[1, i2].value) = '' then
            break;
            inc(i2);
          end;

          RFile.Rtype[i1].datanum := 0;
          setlength(RFile.Rtype[i1].Rdata, RFile.Rtype[i1].datanum);

          for i3 := 1 to i2 - 2 do
          begin
            addnewRdata(@RFile, i1, nil);
          end;

          // setlength(Rfile.Rtype[i1].Rdata, RFile.Rtype[i1].datanum);
          for i2 := 0 to RFile.Rtype[i1].datanum - 1 do
          begin
            ExcelApp.Caption := 'UPedit导入Excel操作中(' + displaystr(typename[i1]) + ':' + inttostr(i2 + 1) + '/' + inttostr(RFile.Rtype[i1].datanum) + ')';
            // temp := 0;
            // for i3 := 0 to typedataitem[i1] - 1 do
            // if Rini[i1].Rterm[i3].datanum > 0 then
            // inc(temp);
            // RFile.Rtype[i1].Rdata[i2].num := temp;
            // setlength(RFile.Rtype[i1].Rdata[i2].Rdataline, temp);
            temp := 0;
            for i3 := 0 to typedataitem[i1] - 1 do
            begin
              if Rini[i1].Rterm[i3].datanum > 0 then
              begin
                // RFIle.Rtype[i1].Rdata[i2].Rdataline[temp].len := Rini[i1].Rterm[i3].datanum;
                // setlength(RFile.Rtype[i1].Rdata[i2].Rdataline[temp].Rarray, Rini[i1].Rterm[i3].datanum);
                // setlength(Rfile[i1].Rdata[i2].Rdataline[i3].datatype, Rini[i1].Rterm[i3].incnum);
                // setlength(Rfile[i1].Rdata[i2].Rdataline[i3].Rarray, Rini[i1].Rterm[i3].incnum);
                for i4 := 0 to Rini[i1].Rterm[i3].datanum - 1 do
                begin
                  // RFile.Rtype[i1].Rdata[i2].Rdataline[temp].Rarray[i4].incnum :=  Rini[i1].Rterm[i3].incnum;
                  // setlength(RFile.Rtype[i1].Rdata[i2].Rdataline[temp].Rarray[i4].dataarray, Rini[i1].Rterm[i3].incnum);
                  for i5 := 0 to Rini[i1].Rterm[i3].incnum - 1 do
                  begin
                    // RFile.Rtype[i1].Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].datatype := Rini[i1].Rterm[i3 + i5].isstr;
                    // RFile.Rtype[i1].Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].datalen := Rini[i1].Rterm[i3 + i5].datalen;
                    if RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].datatype = 0 then
                    begin
                      // fileread(F, PRF.Rtype[i1].Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].number, Rini[i1].Rterm[i3 + i5].datalen)
                      try
                        // WriteRDataInt(@RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], strtoint64(string(excelApp.Cells[temp + 1, i2 + 2].value)));
                      except
                        WriteRDataInt(@RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], 0);
                      end;
                    end
                    else
                    begin
                      // setlength(Rfile[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].str, Rini[i1].Rterm[i3 + i5].datalen);
                      // fileread(F, Rfile[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].str[0], Rini[i1].Rterm[i3 + i5].datalen);
                      // setlength(RFile.Rtype[i1].Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].str,Rini[i1].Rterm[i3 + i5].datalen);
                      // WriteRDataStr(@RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], displaybackstr(excelApp.Cells[temp + 1, i2 + 2].value));
                      // Rfile[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].str := TtoS(Rfile[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].str);
                    end;
                    inc(temp);
                  end;
                end;

              end;
            end;
          end;

        end
        else
        begin

          i2 := 2;
          while true do
          begin
            // if string(excelApp.cells[i2, 1].value) = '' then
            // break;
            inc(i2);
          end;

          RFile.Rtype[i1].datanum := 0;
          setlength(RFile.Rtype[i1].Rdata, RFile.Rtype[i1].datanum);

          for i3 := 1 to i2 - 2 do
          begin
            addnewRdata(@RFile, i1, nil);
          end;

          for i2 := 0 to RFile.Rtype[i1].datanum - 1 do
          begin
            ExcelApp.Caption := 'UPedit导入Excel操作中(' + displaystr(typename[i1]) + ':' + inttostr(i2 + 1) + '/' + inttostr(RFile.Rtype[i1].datanum) + ')';

            // temp2 := 0;
            // for i3 := 0 to typedataitem[i1] - 1 do
            // if Rini[i1].Rterm[i3].datanum > 0 then
            // inc(temp2);
            // RFIle.Rtype[i1].Rdata[i2].num := temp2;
            // setlength(RFile.Rtype[i1].Rdata[i2].Rdataline, RFIle.Rtype[i1].Rdata[i2].num);
            temp := 0;
            for i3 := 0 to RFile.Rtype[i1].Rdata[i2].num - 1 do
            begin
              // setlength(RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray, Rini[i1].Rterm[i3].datanum);
              // RFile.Rtype[i1].Rdata[i2].Rdataline[i3].len := Rini[i1].Rterm[i3].datanum;
              for i4 := 0 to RFile.Rtype[i1].Rdata[i2].Rdataline[i3].len - 1 do
              begin
                // RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].incnum := Rini[i1].Rterm[i3].incnum;
                // setlength(RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray, Rini[i1].Rterm[i3].incnum);
                for i5 := 0 to RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
                begin
                  // RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].datatype := Rini[i1].Rterm[i3 + i5].isstr;
                  // RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].datalen := Rini[i1].Rterm[i3 + i5].datalen;
                  if RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].datatype = 1 then
                    // WriteRDataStr(@RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], displaybackstr(excelApp.Cells[i2 + 2, temp + 1].value))
                  else
                  begin
                    // edit4.Text := inttostr(i1) + ' ' + inttostr(i2) + ' ' + inttostr(i3) + ' ' + inttostr(i4) + ' ' + inttostr(i5) + ' '+ inttostr(temp2)+ ' ' + inttostr(typenumber);
                    try
                      // WriteRDataInt(@RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], strtoint64(string(excelApp.Cells[i2 + 2, temp + 1].value)));
                    except
                      WriteRDataInt(@RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5], 0);
                    end;
                  end;
                  inc(temp);
                end;
              end;
            end;
          end;

          { for i2 := 0 to RFIle.Rtype[i1].datanum - 1 do
            begin
            temp := 1;
            for i3 := 0 to RFile.Rtype[i1].Rdata[i2].num - 1 do
            for I4 := 0 to RFile.Rtype[i1].Rdata[i2].Rdataline[i3].len - 1 do
            for i5 := 0 to RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
            begin
            if RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].datatype = 1 then
            excelApp.Cells[i2 + 2, temp].value := string(RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].str)
            else
            excelApp.Cells[i2 + 2, temp].value := inttostr(RFile.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].number);
            inc(temp);
            end;
            end;
            end; }
        end;

      end;
      ExcelApp.Caption := 'UPedit导入Excel完成！';
      ExcelApp := Unassigned;
      calnamepos(@RFile);
      ComboBox1.Clear;
      for i1 := 0 to RFile.typenumber - 1 do
        ComboBox1.Items.Add(typename[i1]);
      ComboBox1.ItemIndex := 0;
      arrange;
      displayR;
      // excelApp.Quit;
      SetForegroundWindow(application.Handle);
      showmessage('导入Excel完成！');
    end;
  end;
end;

procedure TForm5.Button7Click(Sender: TObject);
var
  I: integer;
begin
  CheckListBox1.DoubleBuffered := false;
  for I := 0 to length(Rselect) - 1 do
    CheckListBox1.Checked[I] := true;
  CheckListBox1.DoubleBuffered := true;
end;

procedure TForm5.Button8Click(Sender: TObject);
var
  I: integer;
begin
  CheckListBox1.DoubleBuffered := false;
  for I := 0 to length(Rselect) - 1 do
    CheckListBox1.Checked[I] := false;
  CheckListBox1.DoubleBuffered := true;
end;

procedure TForm5.Button9Click(Sender: TObject);
var
  I: integer;
begin
  CheckListBox1.DoubleBuffered := false;
  for I := 0 to length(Rselect) - 1 do
    CheckListBox1.Checked[I] := not(CheckListBox1.Checked[I]);
  CheckListBox1.DoubleBuffered := true;
end;

procedure TForm5.ComboBox1Change(Sender: TObject);
begin
  arrange;
  displayR;
end;

procedure TForm5.ComboBox2Select(Sender: TObject);
begin
  if ComboBox2.ItemIndex >= 0 then
    displayR;
end;

procedure TForm5.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  setlength(RFile.Rtype, 0);
  CForm5 := true;
  Action := cafree;
end;

procedure TForm5.FormCreate(Sender: TObject);
var
  i1: integer;
begin
  for i1 := 0 to RFilenum - 1 do
  begin
    ComboBox3.Items.Add(displaystr(RFilenote[i1]));
  end;
  ComboBox3.ItemIndex := 0;
  Button1Click(Sender);
  StatusBar1.Canvas.Brush.Style := bsclear;
  StatusBar1.Canvas.Font.Color := clblack;
  StatusBar1.Canvas.Font.Size := 10;
end;

procedure TForm5.FormResize(Sender: TObject);
begin
  CheckListBox1.Columns := CheckListBox1.Width div 400 + 1;
end;

procedure TForm5.RadioButton1Click(Sender: TObject);
begin
  RadioButton1.Checked := true;
  RadioButton2.Checked := false;
end;

procedure TForm5.checklistbox1Click(Sender: TObject);
begin
  if (CheckListBox1.ItemIndex < length(Rselect)) and (CheckListBox1.ItemIndex >= 0) then
  begin
    // edit1.Text := inttostr(length(Rselect)) + ' ' + inttostr(checklistbox1.ItemIndex);
    StatusBar1.Canvas.Brush.Color := clbtnface;
    StatusBar1.Canvas.FillRect(StatusBar1.Canvas.ClipRect);
    StatusBar1.Repaint;
    StatusBar1.Canvas.TextOut(5, 5, Rselect[CheckListBox1.ItemIndex].note);
  end;
  // checkListBox1.Repaint;
end;

procedure TForm5.checklistbox1DblClick(Sender: TObject);
var
  I, temp, temp2: integer;
  tempstr: string;
begin
  if (CheckListBox1.ItemIndex < length(Rselect)) and (CheckListBox1.ItemIndex >= 0) then
  begin
    temp := CheckListBox1.ItemIndex;
    if Rselect[CheckListBox1.ItemIndex].quote < 0 then
    begin
      if RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[CheckListBox1.ItemIndex].pos1].Rarray[Rselect[CheckListBox1.ItemIndex].pos2].dataarray
        [Rselect[CheckListBox1.ItemIndex].pos3].datatype = 0 then
        WriteRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[CheckListBox1.ItemIndex].pos1].Rarray[Rselect[CheckListBox1.ItemIndex].pos2].dataarray
          [Rselect[CheckListBox1.ItemIndex].pos3],
          strtoint64(InputBox('修改', '修改此项数值', inttostr(ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[CheckListBox1.ItemIndex].pos1].Rarray
          [Rselect[CheckListBox1.ItemIndex].pos2].dataarray[Rselect[CheckListBox1.ItemIndex].pos3])))))
      else
      begin
        WriteRDataStr(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[CheckListBox1.ItemIndex].pos1].Rarray[Rselect[CheckListBox1.ItemIndex].pos2].dataarray
          [Rselect[CheckListBox1.ItemIndex].pos3],
          displaybackstr(InputBox('修改', '修改此项字符串', displaystr(readRDatastr(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[CheckListBox1.ItemIndex].pos1].Rarray
          [Rselect[CheckListBox1.ItemIndex].pos2].dataarray[Rselect[CheckListBox1.ItemIndex].pos3])))));
        // showmessage(inttostr(length(tempstr)));
        // Setlength(RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].str, RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].datalen + 2);
        // RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].str := tempstr;
        // Setlength(RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].str, RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].datalen + 2);
        // copymemory(pointer(RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].str))
        // if sizeof(tempstr) < RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].datalen then
        // zeromemory((pbyte(RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].str) + sizeof(tempstr)), RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].datalen - sizeof(tempstr));
        // zeromemory((pbyte(RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].str) + RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].datalen), 2);

        // showmessage(inttostr(RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].datalen));
        // fillchar(RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].str, RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].datalen + 2, #0);
        // RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].str := writeinstr(displaybackstr(InputBox('修改','修改此项字符串', displaystr(readoutstr(RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].str)))));
        // Setlength(RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].str, RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].datalen + 2);
        // RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].str[RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].datalen + 1] := #0;
        // RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].str[RFile.Rtype[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[Rselect[checklistbox1.ItemIndex].pos1].Rarray[Rselect[checklistbox1.ItemIndex].pos2].dataarray[Rselect[checklistbox1.ItemIndex].pos3].datalen + 2] := #0;
      end;
    end
    else
    begin
      Form6.ComboBox1.Clear;
      Form6.ComboBox1.Items.Add('-1');
      for I := 0 to RFile.Rtype[Rselect[CheckListBox1.ItemIndex].quote].datanum - 1 do
        Form6.ComboBox1.Items.Add(displaystr(inttostr(I) + readRDatastr(@RFile.Rtype[Rselect[CheckListBox1.ItemIndex].quote].Rdata[I].Rdataline[RFile.Rtype[Rselect[CheckListBox1.ItemIndex].quote]
          .namepos].Rarray[0].dataarray[0])));
      Form6.ComboBox1.ItemIndex := ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[CheckListBox1.ItemIndex].pos1].Rarray
        [Rselect[CheckListBox1.ItemIndex].pos2].dataarray[Rselect[CheckListBox1.ItemIndex].pos3]) + 1;
      Form6.Label1.Caption := typename[Rselect[CheckListBox1.ItemIndex].quote];
      Reditresult := Form6.ShowModal;
      if Reditresult = mrOK then
        WriteRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[Rselect[CheckListBox1.ItemIndex].pos1].Rarray[Rselect[CheckListBox1.ItemIndex].pos2].dataarray
          [Rselect[CheckListBox1.ItemIndex].pos3], Form6.ComboBox1.ItemIndex - 1);
      // Form6.Free;
    end;
    // displayR;
    changeRitem(temp, Rselect[temp].pos1, Rselect[temp].pos2, Rselect[temp].pos3);
    temp2 := ComboBox2.ItemIndex;
    if RFile.Rtype[ComboBox1.ItemIndex].namepos = Rselect[temp].pos1 then
    begin
      ComboBox2.Items.strings[temp2] := inttostr(temp2) + readRDatastr(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[temp2].Rdataline[Rselect[temp].pos1].Rarray[0].dataarray[0]);
    end;
    ComboBox2.ItemIndex := temp2;
    // checklistbox1.ItemIndex := temp;
  end;
end;

function readR(idx, grp: string; PRF: PRfile): boolean;
var
  offset: array of integer;
  I, i1, i2, i3, i4, i5: integer;
  Size, F, temp, templen: integer;
begin
  result := false;
  if grp.EndsWith('.db') then
  begin
    result := readDB(grp, PRF);
  end;
  if fileexists(idx) and fileexists(grp) then
  begin
    try
      PRF.typenumber := typenumber;
      setlength(PRF.Rtype, PRF.typenumber);
      for I := 0 to PRF.typenumber - 1 do
      begin
        PRF.Rtype[I].datanum := 0;
        PRF.Rtype[I].namepos := -1;
        PRF.Rtype[I].mappos := -1;
        setlength(PRF.Rtype[I].Rdata, 0);
      end;
      F := fileopen(idx, fmopenread);
      setlength(offset, PRF.typenumber);
      fileread(F, offset[0], PRF.typenumber * 4);
      fileclose(F);

      F := fileopen(grp, fmopenread);

      for i1 := 0 to PRF.typenumber - 1 do
      begin
        PRF.Rtype[i1].namepos := -1;
        Size := 0;
        for i2 := 0 to typedataitem[i1] - 1 do
        begin
          if Rini[i1].Rterm[i2].datanum > 0 then
            for i3 := 0 to Rini[i1].Rterm[i2].incnum - 1 do
            begin
              inc(Size, Rini[i1].Rterm[i2].datanum * Rini[i1].Rterm[i2 + i3].datalen);
            end;
        end;
        if i1 = 0 then
        begin
          templen := max(offset[i1] div Size, 1);
        end
        else
          templen := max((offset[i1] - offset[i1 - 1]) div Size, 1);
        for i2 := 0 to templen - 1 do
        begin
          addnewRdata(PRF, i1, nil);
        end;

        if i1 <> 0 then
          fileseek(F, offset[i1 - 1], 0);
        // setlength(PRF.Rtype[i1].Rdata, PRF.Rtype[i1].datanum);
        for i2 := 0 to PRF.Rtype[i1].datanum - 1 do
        begin
          // temp := 0;
          // for i3 := 0 to typedataitem[i1] - 1 do
          // if Rini[i1].Rterm[i3].datanum > 0 then
          // inc(temp);
          // PRF.Rtype[i1].Rdata[i2].num := temp;
          // setlength(PRF.Rtype[i1].Rdata[i2].Rdataline, temp);
          temp := -1;
          for i3 := 0 to typedataitem[i1] - 1 do
          begin
            if Rini[i1].Rterm[i3].datanum > 0 then
            begin
              inc(temp);
              if (i3 = 0) and (Rini[i1].Rterm[i3].isname = 1) then
                PRF.Rtype[i1].namepos := temp;

              // PRF.Rtype[i1].Rdata[i2].Rdataline[temp].len := Rini[i1].Rterm[i3].datanum;
              // setlength(PRF.Rtype[i1].Rdata[i2].Rdataline[temp].Rarray, Rini[i1].Rterm[i3].datanum);
              // setlength(Rfile[i1].Rdata[i2].Rdataline[i3].datatype, Rini[i1].Rterm[i3].incnum);
              // setlength(Rfile[i1].Rdata[i2].Rdataline[i3].Rarray, Rini[i1].Rterm[i3].incnum);
              for i4 := 0 to Rini[i1].Rterm[i3].datanum - 1 do
              begin
                // PRF.Rtype[i1].Rdata[i2].Rdataline[temp].Rarray[i4].incnum :=  Rini[i1].Rterm[i3].incnum;
                // setlength(PRF.Rtype[i1].Rdata[i2].Rdataline[temp].Rarray[i4].dataarray, Rini[i1].Rterm[i3].incnum);
                for i5 := 0 to Rini[i1].Rterm[i3].incnum - 1 do
                begin
                  // PRF.Rtype[i1].Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].datatype := Rini[i1].Rterm[i3 + i5].isstr;
                  // PRF.Rtype[i1].Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].datalen := Rini[i1].Rterm[i3 + i5].datalen;
                  // setlength(PRF.Rtype[i1].Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].data, Rini[i1].Rterm[i3 + i5].datalen);
                  if Rini[i1].Rterm[i3 + i5].datalen > 0 then
                    fileread(F, PRF.Rtype[i1].Rdata[i2].Rdataline[temp].Rarray[i4].dataarray[i5].data[0], Rini[i1].Rterm[i3 + i5].datalen);
                end;
              end;

            end;
          end;
        end;
      end;
      fileclose(F);

      result := true;
    except
      exit;
    end;
  end;
end;

function readDB(db: string; PRF: PRfile): boolean;

begin

end;

procedure TForm5.Edit2KeyPress(Sender: TObject; var Key: Char);
var
  NumEdit1: dWord;
begin
  If Key = #13 then
  begin
    Button1Click(Sender);
  end
  else
  begin
    NumEdit1 := GetWindowLong(Edit2.Handle, GWL_STYLE);
    SetWindowLong(Edit2.Handle, GWL_STYLE, NumEdit1 or ES_NUMBER);
  end;
end;

procedure TForm5.changeRitem(idxnum, pos1, pos2, pos3: integer);
var
  I: integer;
  tempstr: string;
begin
  tempstr := '';
  for I := CheckListBox1.Canvas.TextWidth(displaystr(Rselect[idxnum].name)) div CheckListBox1.Canvas.TextWidth(' ') to 30 do
    tempstr := tempstr + ' ';
  if RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[pos1].Rarray[pos2].dataarray[pos3].datatype = 0 then
  begin
    if (Rselect[idxnum].quote < 0) or (ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[pos1].Rarray[pos2].dataarray[pos3]) < 0) or
      (ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[pos1].Rarray[pos2].dataarray[pos3]) >= RFile.Rtype[Rselect[idxnum].quote].datanum) then
      CheckListBox1.Items.strings[idxnum] :=
        (displaystr(Rselect[idxnum].name) + tempstr + inttostr(ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[pos1].Rarray[pos2].dataarray[pos3])))
    else
      CheckListBox1.Items.strings[idxnum] :=
        (displaystr(Rselect[idxnum].name + tempstr + inttostr(ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[pos1].Rarray[pos2].dataarray[pos3])) +
        readRDatastr(@RFile.Rtype[Rselect[idxnum].quote].Rdata[ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[pos1].Rarray[pos2].dataarray[pos3])
        ].Rdataline[RFile.Rtype[Rselect[idxnum].quote].namepos].Rarray[0].dataarray[0])))
  end
  else
    CheckListBox1.Items.strings[idxnum] :=
      (displaystr((Rselect[idxnum].name) + tempstr + readRDatastr(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[pos1].Rarray[pos2].dataarray[pos3])));

end;

procedure TForm5.displayR;
var
  i1, i2, i3, i4, i5, temp, temp2, t1, t2: integer;
  tempstr: string;
begin
  if candisplayR then
  begin
    try
      CheckListBox1.Clear;
      temp := 0;
      t1 := ComboBox1.ItemIndex;
      t2 := ComboBox2.ItemIndex;
      if (t1 >= 0) and (t2 >= 0) then
        for i1 := 0 to RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].num - 1 do
          inc(temp, RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].len * RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray[0].incnum);
      setlength(Rselect, temp);
      temp := -1;
      temp2 := 0;
      for i1 := 0 to RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].num - 1 do
      begin
        for i2 := 0 to RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].len - 1 do
        begin
          for i3 := 0 to RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray[i2].incnum - 1 do
          begin
            tempstr := '';
            i5 := RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].len;
            if i5 <= 1 then
              for i4 := CheckListBox1.Canvas.TextWidth(displaystr(Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].name)) div CheckListBox1.Canvas.TextWidth(' ') to 30 do
                tempstr := tempstr + ' '
            else
              for i4 := CheckListBox1.Canvas.TextWidth(displaystr(Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].name) + inttostr(i2)) div CheckListBox1.Canvas.TextWidth(' ') to 30 do
                tempstr := tempstr + ' ';
            if RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3].datatype = 0 then
            begin
              if i5 <= 1 then
              begin
                if (Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].quote < 0) or (ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3]) < 0) or
                  (ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3]) >= RFile.Rtype[Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].quote]
                  .datanum) then
                  CheckListBox1.Items.Add(displaystr((Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].name) + tempstr +
                    inttostr(ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3]))))
                else
                  CheckListBox1.Items.Add(displaystr((Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].name) + tempstr +
                    inttostr(ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3])) +
                    readRDatastr(@RFile.Rtype[Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].quote].Rdata[ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray
                    [i2].dataarray[i3])].Rdataline[RFile.Rtype[Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].quote].namepos].Rarray[0].dataarray[0])));
              end
              else
              begin
                if (Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].quote < 0) or (ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3]) < 0) or
                  (ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3]) >= RFile.Rtype[Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].quote]
                  .datanum) then
                begin
                  CheckListBox1.Items.Add(displaystr((Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].name) + inttostr(i2) + tempstr +
                    inttostr(ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3]))));
                end
                else
                begin
                  CheckListBox1.Items.Add(displaystr((Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].name) + inttostr(i2) + tempstr +
                    inttostr(ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3])) +
                    readRDatastr(@RFile.Rtype[Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].quote].Rdata[ReadRDataInt(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray
                    [i2].dataarray[i3])].Rdataline[RFile.Rtype[Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].quote].namepos].Rarray[0].dataarray[0])));
                end;
              end;
            end
            else
            begin
              if i5 <= 1 then
                CheckListBox1.Items.Add(displaystr((Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].name) + tempstr + readRDatastr(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline
                  [i1].Rarray[i2].dataarray[i3])))
                // checklistbox1.Items.Add(Rini[combobox1.ItemIndex].Rterm[temp2 + i3].name + '          ' + (Pstring(@(RFile[combobox1.ItemIndex].Rdata[combobox2.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3].str[0])))^);        i4 := 2;
              else
                CheckListBox1.Items.Add(displaystr((Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].name) + inttostr(i2) + tempstr +
                  readRDatastr(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray[i2].dataarray[i3])))
            end;
            inc(temp);
            Rselect[temp].pos1 := i1;
            Rselect[temp].pos2 := i2;
            Rselect[temp].pos3 := i3;
            Rselect[temp].name := Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].name;
            if i5 > 1 then
              Rselect[temp].name := Rselect[temp].name + inttostr(i2);
            Rselect[temp].quote := Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].quote;
            Rselect[temp].note := Rini[ComboBox1.ItemIndex].Rterm[temp2 + i3].note;
          end;
        end;
        inc(temp2, RFile.Rtype[ComboBox1.ItemIndex].Rdata[ComboBox2.ItemIndex].Rdataline[i1].Rarray[0].incnum);
      end;
    except

    end;
  end;

end;

procedure TForm5.Edit1KeyPress(Sender: TObject; var Key: Char);
var
  NumEdit1: dWord;
begin
  If Key = #13 then
  begin
    Button1Click(Sender);
  end
  else
  begin
    NumEdit1 := GetWindowLong(Edit1.Handle, GWL_STYLE);
    SetWindowLong(Edit1.Handle, GWL_STYLE, NumEdit1 or ES_NUMBER);
  end;
end;

procedure TForm5.arrange;
var
  I, temp, temp2: integer;
  tempstr: string;
begin
  //
  candisplayR := false;
  ComboBox2.Clear;
  temp := -1;
  temp2 := -1;
  for I := 0 to typedataitem[ComboBox1.ItemIndex] - 1 do
  begin
    if Rini[ComboBox1.ItemIndex].Rterm[I].datanum > 0 then
      inc(temp2);
    if Rini[ComboBox1.ItemIndex].Rterm[I].isname = 1 then
    begin
      temp := temp2;
      break;
    end;
  end;
  // edit1.Text := RFile[1].Rdata[0].Rdataline[4].Rarray[0].dataarray[0].str;
  // edit1.text := inttostr(combobox1.itemindex);
  for I := 0 to RFile.Rtype[ComboBox1.ItemIndex].datanum - 1 do
  begin
    if temp < 0 then
      ComboBox2.Items.Add(inttostr(I))
    else
    begin
      // tempstr := Pchar(RFile[combobox1.ItemIndex].Rdata[I].Rdataline[temp].Rarray[0].dataarray[0].str[0])
      // combobox2.Items.Add(inttostr(I)+ (Pstring(@(RFile[combobox1.ItemIndex].Rdata[I].Rdataline[temp].Rarray[0].dataarray[0].str[0])))^)
      ComboBox2.Items.Add(displaystr(inttostr(I) + readRDatastr(@RFile.Rtype[ComboBox1.ItemIndex].Rdata[I].Rdataline[temp].Rarray[0].dataarray[0])));
    end;
  end;
  ComboBox2.ItemIndex := 0;
  candisplayR := true;
end;

procedure readini;
var
  iniF: Tinifile;
  inifilename, tempstr: string;
  strlist: Tstringlist;
  i1, i2: integer;
  strnum, diff: integer;
begin
  //

  try
    inifilename := ExtractFilePath(Paramstr(0)) + 'UPedit.ini';
    iniF := Tinifile.Create(inifilename);
    typenumber := iniF.ReadInteger('R_Modify', 'TypeNumber', 0);
    // edit1.Text := inttostr(typenumber);
    if typenumber > 0 then
    begin
      setlength(Rini, typenumber);
      setlength(typedataitem, typenumber);
      setlength(typename, typenumber);
      strlist := Tstringlist.Create;
      for i1 := 0 to typenumber - 1 do
      begin
        typename[i1] := iniF.ReadString('R_Modify', 'typename' + inttostr(i1), '');
        typedataitem[i1] := iniF.ReadInteger('R_Modify', 'typedataitem' + inttostr(i1), 0);
        if typedataitem[i1] > 0 then
        begin
          setlength(Rini[i1].Rterm, typedataitem[i1]);
          diff := 0;
          for i2 := 0 to typedataitem[i1] - 1 do
          begin
            strlist.Clear;
            tempstr := iniF.ReadString('R_Modify', 'data(' + inttostr(i1) + ',' + inttostr(i2) + ')', '');
            if tempstr <> '' then
            begin
              strnum := ExtractStrings([' '], [], pwidechar(tempstr), strlist);
              if strnum = 8 then
              begin
                with Rini[i1].Rterm[i2] do
                begin
                  datanum := strtoint64(strlist.strings[0]);
                  incnum := strtoint64(strlist.strings[1]);
                  datalen := strtoint64(strlist.strings[2]);
                  isstr := strtoint64(strlist.strings[3]);
                  isname := strtoint64(strlist.strings[4]);
                  quote := strtoint64(strlist.strings[5]);
                  name := strlist.strings[6];
                  note := strlist.strings[7] + '(' + inttostr(diff) + ')';
                  diff := diff + datalen div 2 * datanum;
                end;
              end;
            end;
          end;

        end;
      end;
      strlist.free;

    end;
    iniF.free;
  except
    // showmessage('读取ini文件错误！');
    exit;
  end;
end;

procedure copyRdata(source, dest: PRdata);
var
  i1, i2, i3: integer;
begin
  dest.num := source.num;
  setlength(dest.Rdataline, dest.num);
  for i1 := 0 to source.num - 1 do
  begin
    dest.Rdataline[i1].len := source.Rdataline[i1].len;
    setlength(dest.Rdataline[i1].Rarray, source.Rdataline[i1].len);
    for i2 := 0 to source.Rdataline[i1].len - 1 do
    begin
      dest.Rdataline[i1].Rarray[i2].incnum := source.Rdataline[i1].Rarray[i2].incnum;
      setlength(dest.Rdataline[i1].Rarray[i2].dataarray, source.Rdataline[i1].Rarray[i2].incnum);
      for i3 := 0 to source.Rdataline[i1].Rarray[i2].incnum - 1 do
      begin
        dest.Rdataline[i1].Rarray[i2].dataarray[i3].datalen := source.Rdataline[i1].Rarray[i2].dataarray[i3].datalen;
        dest.Rdataline[i1].Rarray[i2].dataarray[i3].datatype := source.Rdataline[i1].Rarray[i2].dataarray[i3].datatype;
        dest.Rdataline[i1].Rarray[i2].dataarray[i3].datalen := max(dest.Rdataline[i1].Rarray[i2].dataarray[i3].datalen, 0);
        setlength(dest.Rdataline[i1].Rarray[i2].dataarray[i3].data, dest.Rdataline[i1].Rarray[i2].dataarray[i3].datalen);
        // dest.Rdataline[i1].Rarray[i2].dataarray[i3].str := source.Rdataline[i1].Rarray[i2].dataarray[i3].str;
        if dest.Rdataline[i1].Rarray[i2].dataarray[i3].datalen > 0 then
          copymemory(@dest.Rdataline[i1].Rarray[i2].dataarray[i3].data[0], @source.Rdataline[i1].Rarray[i2].dataarray[i3].data[0], dest.Rdataline[i1].Rarray[i2].dataarray[i3].datalen);
      end;
    end;
  end;
end;

procedure calnamepos(PRF: PRfile);
var
  i1, i2, temp: integer;
begin
  for i1 := 0 to PRF.typenumber - 1 do
  begin
    PRF.Rtype[i1].namepos := -1;
    temp := -1;
    for i2 := 0 to typedataitem[i1] - 1 do
    begin
      if Rini[i1].Rterm[i2].datanum > 0 then
        inc(temp);
      if Rini[i1].Rterm[i2].isname = 1 then
      begin
        PRF.Rtype[i1].namepos := temp;
        break;
      end;
    end;
  end;
end;

procedure saveR(idx, grp: string; PRF: PRfile);
var
  i1, i2, i3, i4, i5: integer;
  offset: array of integer;
  F: integer;
begin
  //
  setlength(offset, PRF.typenumber);
  F := filecreate(grp);
  offset[0] := 0;
  for i1 := 0 to PRF.typenumber - 1 do
  begin
    if i1 > 0 then
      offset[i1] := offset[i1 - 1];
    for i2 := 0 to PRF.Rtype[i1].datanum - 1 do
    begin
      for i3 := 0 to PRF.Rtype[i1].Rdata[i2].num - 1 do
      begin
        for i4 := 0 to PRF.Rtype[i1].Rdata[i2].Rdataline[i3].len - 1 do
        begin
          for i5 := 0 to PRF.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].incnum - 1 do
          begin
            if PRF.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].datalen > 0 then
              filewrite(F, PRF.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].data[0], PRF.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].datalen);
            inc(offset[i1], PRF.Rtype[i1].Rdata[i2].Rdataline[i3].Rarray[i4].dataarray[i5].datalen);
          end;
        end;
      end;
    end;
  end;
  fileclose(F);
  F := filecreate(idx);
  fileseek(F, 0, 0);

  filewrite(F, offset[0], PRF.typenumber * 4);

  fileclose(F);

end;

end.
