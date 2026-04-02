unit Ict_50_22;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm60 = class(TForm)
    Edit1: TEdit;
    ComboBox1: TComboBox;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    Button1: TButton;
    Button2: TButton;
    ComboBox2: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    procedure ComboBox1Select(Sender: TObject);
    procedure ComboBox2Select(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form60: TForm60;

implementation

{$R *.dfm}

procedure TForm60.ComboBox1Select(Sender: TObject);
begin
  if not checkbox1.Checked then
    edit1.Text := inttostr(combobox1.ItemIndex);
end;

procedure TForm60.ComboBox2Select(Sender: TObject);
begin
  if not checkbox3.Checked then
    edit3.Text := inttostr(combobox2.ItemIndex);

end;

end.
