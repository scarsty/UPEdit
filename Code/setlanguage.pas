unit setlanguage;

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
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form8: TForm8;

implementation

{$R *.dfm}

procedure TForm8.Button1Click(Sender: TObject);
var
  Filename:string;
  ini: TiniFile;
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
  ini.WriteInteger('run','talkcode',talkcode);
  ini.WriteInteger('run','talkinvert',talkinvert);
  ini.WriteInteger('run','datacode',datacode);
  ini.writeInteger('run','checkupdate',checkupdate);

  ini.Free;
  self.Close;
end;

procedure TForm8.Button2Click(Sender: TObject);
begin
  self.Close;
end;

end.
