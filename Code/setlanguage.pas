unit setlanguage;

{$modeswitch autoderef}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, head, StdCtrls, iniFiles, ExtCtrls, math;

type
  TForm8 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    RadioGroup1: TRadioGroup;
    RadioGroup2: TRadioGroup;
    RadioGroup3: TRadioGroup;
    RadioGroup4: TRadioGroup;
    Label2: TLabel;
    Edit1: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form8: TForm8;

implementation

{$R *.lfm}

procedure TForm8.Button1Click(Sender: TObject);
var
  Filename:string;
  ini: TiniFile;
  TileScale: integer;
begin
  talkcode := max(RadioGroup1.ItemIndex, 0);
  datacode := max(RadioGroup2.ItemIndex, 0);
  talkinvert := max(RadioGroup4.ItemIndex, 0);
  if RadioGroup3.ItemIndex = 0 then
    checkupdate := 1
  else if RadioGroup3.ItemIndex = 1 then
    checkupdate := 2
  else
    checkupdate := 0;

  Filename := StartPath + iniFilename;
  ini := TIniFile.Create(filename);
  TileScale := StrToIntDef(Edit1.Text, 1);
  if TileScale < 1 then
    TileScale := 1
  else if TileScale > 8 then
    TileScale := 8;
  ini.WriteInteger('run','talkcode',talkcode);
  ini.WriteInteger('run','talkinvert',talkinvert);
  ini.WriteInteger('run','datacode',datacode);
  ini.writeInteger('run','checkupdate',checkupdate);
  ini.WriteInteger('run','TileScale', TileScale);

  ini.Free;
  self.Close;
end;

procedure TForm8.Button2Click(Sender: TObject);
begin
  self.Close;
end;

procedure TForm8.FormCreate(Sender: TObject);
var
  Filename: string;
  ini: TIniFile;
begin
  Filename := StartPath + iniFilename;
  ini := TIniFile.Create(filename);
  try
    Edit1.Text := IntToStr(ini.ReadInteger('run', 'TileScale', 1));
  finally
    ini.Free;
  end;
end;

end.



