unit Replicatedlist;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, head, math;

type
  TForm86 = class(TForm)
    ScrollBar1: TScrollBar;
    ComboBox1: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    ScrollBar2: TScrollBar;
    Label3: TLabel;
    Label4: TLabel;
    ScrollBar3: TScrollBar;
    Label5: TLabel;
    Label6: TLabel;
    ScrollBar4: TScrollBar;
    Label7: TLabel;
    Label8: TLabel;
    Edit1: TEdit;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    Edit2: TEdit;
    Edit3: TEdit;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure ScrollBar2Change(Sender: TObject);
    procedure ScrollBar3Change(Sender: TObject);
    procedure ScrollBar4Change(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure ComboBox2Change(Sender: TObject);
    procedure ComboBox3Change(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
    procedure Edit3Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function calRname(datatype, index: integer): widestring;

var
  {leavelist: array of Tlist;
  effectlist: array of Tlist;
  matchlist: array of Tlist;
  explist: array of Tlist;}
   leavelist: array[0..99] of smallint;
   effectlist: array[0..199] of smallint;
   matchlist: array[0..299] of smallint;
   explist: array[0..99] of smallint;
implementation

uses
  main, Redit;

{$R *.dfm}

procedure TForm86.Button1Click(Sender: TObject);
var
  F, Flen,I: integer;
begin

  try
    F := filecreate(gamepath + leave);
    filewrite(F, leavelist[0],200);
    fileclose(F);
  except
    fileclose(F);
  end;

  try
    F := filecreate(gamepath + effect);
    filewrite(F, effectlist[0],400);
    fileclose(F);
  except
    fileclose(F);
  end;

  try
    F := filecreate(gamepath + match);
    filewrite(F, matchlist[0],600);
    fileclose(F);
  except
    fileclose(F);
  end;

  try
    F := filecreate(gamepath + exp);
    filewrite(F, explist[0],200);
    fileclose(F);
  except
    fileclose(F);
  end;
end;

procedure TForm86.Button2Click(Sender: TObject);
begin
  self.close;
end;

procedure TForm86.ComboBox1Change(Sender: TObject);
begin
  leavelist[scrollbar1.Position] := combobox1.ItemIndex;
end;

procedure TForm86.ComboBox2Change(Sender: TObject);
begin
  Matchlist[scrollbar3.Position * 3] := combobox2.ItemIndex;
end;

procedure TForm86.ComboBox3Change(Sender: TObject);
begin
  Matchlist[scrollbar3.Position * 3 + 1] := combobox3.ItemIndex;
end;

procedure TForm86.Edit1Change(Sender: TObject);
begin
  try
    effectlist[scrollbar2.Position] := strtoint(edit1.Text);
  except
    effectlist[scrollbar2.Position] := 0;
  end;
end;

procedure TForm86.Edit2Change(Sender: TObject);
begin
  try
    matchlist[scrollbar3.Position * 3 + 2] := strtoint(edit2.Text);
  except
    matchlist[scrollbar3.Position * 3 + 2] := 0;
  end;
end;

procedure TForm86.Edit3Change(Sender: TObject);
begin
  try
    explist[scrollbar4.Position] := strtoint(edit3.Text);
  except
    explist[scrollbar4.Position] := 0;
  end;
end;

procedure TForm86.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CForm86 := true;
  action := cafree;
end;

procedure TForm86.FormCreate(Sender: TObject);
var
  F, Flen,I: integer;
begin

  try
    F := fileopen(gamepath + leave, fmopenread);
    Flen := fileseek(F,0,2);
    fileseek(F,0,0);
    Flen := min(200,Flen);
    fileread(F, leavelist[0],Flen);
    fileclose(F);
  except
    fileclose(F);
  end;

  try
    F := fileopen(gamepath + effect, fmopenread);
    Flen := fileseek(F,0,2);
    fileseek(F,0,0);
    Flen := min(400,Flen);
    fileread(F, effectlist[0],Flen);
    fileclose(F);
  except
    fileclose(F);
  end;

  try
    F := fileopen(gamepath + match, fmopenread);
    Flen := fileseek(F,0,2);
    fileseek(F,0,0);
    Flen := min(600,Flen);
    fileread(F, matchlist[0],Flen);
    fileclose(F);
  except
    fileclose(F);
  end;

  try
    F := fileopen(gamepath + exp, fmopenread);
    Flen := fileseek(F,0,2);
    fileseek(F,0,0);
    Flen := min(200,Flen);
    fileread(F, explist[0],Flen);
    fileclose(F);
  except
    fileclose(F);
  end;

 // combobox1.Clear;
  for I := 0 to useR.Rtype[1].datanum - 1 do
    combobox1.Items.Add(CalRname(1,I));
  for I := 0 to useR.Rtype[2].datanum - 1 do
    combobox2.Items.Add(CalRname(2,I));
  for I := 0 to useR.Rtype[4].datanum - 1 do
    combobox3.Items.Add(CalRname(4,I));
  combobox1.ItemIndex := max(0,leavelist[0]);
  edit1.Text := inttostr(effectlist[0]);
  combobox2.ItemIndex := max(0, matchlist[0]);
  combobox3.ItemIndex := max(0, matchlist[1]);
  edit2.Text := inttostr(matchlist[2]);
  edit3.Text := inttostr(explist[0]);

end;

procedure TForm86.ScrollBar1Change(Sender: TObject);
begin
  label2.Caption := inttostr(scrollbar1.Position);
  combobox1.ItemIndex := max(0, leavelist[scrollbar1.Position]);
end;

procedure TForm86.ScrollBar2Change(Sender: TObject);
begin
  label4.Caption := inttostr(scrollbar2.Position);
  edit1.Text := inttostr(effectlist[scrollbar2.Position]);
end;

procedure TForm86.ScrollBar3Change(Sender: TObject);
begin
  label6.Caption := inttostr(scrollbar3.Position);
  combobox2.ItemIndex := max(0, matchlist[scrollbar3.Position * 3]);
  combobox3.ItemIndex := max(0, matchlist[scrollbar3.Position * 3 + 1]);
  edit2.Text := inttostr(matchlist[scrollbar3.Position * 3 + 2]);
end;

procedure TForm86.ScrollBar4Change(Sender: TObject);
begin
  label8.Caption := inttostr(scrollbar4.Position);
  edit3.Text := inttostr(explist[scrollbar4.Position]);
end;

function calRname(datatype, index: integer): widestring;
var
  I: integer;
begin
  if (index >= 0) and (index < useR.Rtype[datatype].datanum) and (useR.Rtype[datatype].namepos >= 0) then
    result := inttostr(index) + (displaystr(readRDataStr(@useR.Rtype[datatype].Rdata[index].Rdataline[useR.Rtype[datatype].namepos].Rarray[0].dataarray[0])))
  else
    result := inttostr(index);
  for I := 1 to length(result) - 1 do
    if result[I + 1] = '' then
    begin
      setlength(result, I);
      break;
    end;
end;

end.
