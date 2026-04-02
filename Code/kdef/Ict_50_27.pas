unit Ict_50_27;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, head;

type
  TForm65 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    ComboBox1: TComboBox;
    Label1: TLabel;
    Edit1: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    Edit2: TEdit;
    CheckBox1: TCheckBox;
    ComboBox2: TComboBox;
    procedure ComboBox1Select(Sender: TObject);
    procedure ComboBox2Select(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form65: TForm65;

implementation

uses
  kdefedit;

{$R *.dfm}

procedure TForm65.ComboBox1Select(Sender: TObject);
var
 I: integer;
begin
  if combobox1.ItemIndex >= 0 then
  begin
    combobox2.Clear;
    for I := 0 to useR.Rtype[combobox1.ItemIndex + 1].datanum - 1 do
      combobox2.Items.Add(CalRname(combobox1.ItemIndex + 1, I));
  end;
end;

procedure TForm65.ComboBox2Select(Sender: TObject);
begin

  if not checkbox1.Checked then
    edit2.Text := inttostr(combobox2.ItemIndex);
end;

end.
