unit FightFrameForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TFightFrameForm = class(TForm)
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    content: ansistring;
  end;

var
  FightFrameForm1: TFightFrameForm;

implementation

{$R *.dfm}

procedure TFightFrameForm.Button1Click(Sender: TObject);
var
  value: integer;
begin
  content := '';
  value := strtoint(Edit1.Text);
  if value <> 0 then
    content := content + '0, ' + IntToStr(value) + #10;
  value := strtoint(Edit2.Text);
  if value <> 0 then
    content := content + '1, ' + IntToStr(value) + #10;
  value := strtoint(Edit3.Text);
  if value <> 0 then
    content := content + '2, ' + IntToStr(value) + #10;
  value := strtoint(Edit4.Text);
  if value <> 0 then
    content := content + '3, ' + IntToStr(value) + #10;
  value := strtoint(Edit5.Text);
  if value <> 0 then
    content := content + '4, ' + IntToStr(value) + #10;
  close;
end;

procedure TFightFrameForm.Button2Click(Sender: TObject);
begin
  content := '';
  close;
end;

procedure TFightFrameForm.FormShow(Sender: TObject);
var
  strs: Tstringlist;
  strnum, i, index, value: integer;
  str: string;
begin
  strs := Tstringlist.Create;
  str := content;
  strnum := ExtractStrings([',', #10], [], pchar(str), strs);

  Edit1.Text := '0';
  Edit2.Text := '0';
  Edit3.Text := '0';
  Edit4.Text := '0';
  Edit5.Text := '0';

  for i := 0 to strnum div 2 - 1 do
  begin
    index := strs.Strings[i * 2].ToInteger;
    value := strs.Strings[i * 2 + 1].ToInteger;
    case index of
      0:
        Edit1.Text := IntToStr(value);
      1:
        Edit2.Text := IntToStr(value);
      2:
        Edit3.Text := IntToStr(value);
      3:
        Edit4.Text := IntToStr(value);
      4:
        Edit5.Text := IntToStr(value);
    end;
  end;
  strs.Free;
end;

end.
