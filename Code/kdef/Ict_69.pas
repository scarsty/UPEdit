unit Ict_69;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, head;

type
  TForm40 = class(TForm)
    Label1: TLabel;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    Label2: TLabel;
    ComboBox3: TComboBox;
    Label3: TLabel;
    Button1: TButton;
    Button2: TButton;
    procedure ComboBox1Select(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form40: TForm40;

implementation

uses
  kdefedit,Redit;

{$R *.dfm}

procedure TForm40.ComboBox1Select(Sender: TObject);
var
  I: integer;
begin
  if combobox1.ItemIndex >= 0 then
  begin
    combobox2.Clear;
    for I := 0 to useR.Rtype[combobox1.ItemIndex + 1].datanum - 1 do
      combobox2.Items.Add(CalRname(combobox1.ItemIndex + 1, I));
    combobox2.ItemIndex := 0;
  end;
end;

procedure TForm40.FormCreate(Sender: TObject);
var
  I: integer;
begin
  try
  combobox1.Clear;
  for I := 1 to 4 do
    combobox1.Items.Add(displayname(typename[i]));
  except
    exit;
  end;
end;

end.
