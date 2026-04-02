unit Ict_50_23;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm61 = class(TForm)
    Label1: TLabel;
    ComboBox1: TComboBox;
    CheckBox1: TCheckBox;
    Edit1: TEdit;
    CheckBox2: TCheckBox;
    Edit2: TEdit;
    Label2: TLabel;
    CheckBox3: TCheckBox;
    Edit3: TEdit;
    Label3: TLabel;
    CheckBox4: TCheckBox;
    Edit4: TEdit;
    Label4: TLabel;
    CheckBox5: TCheckBox;
    Edit5: TEdit;
    Label5: TLabel;
    Button1: TButton;
    Button2: TButton;
    Label6: TLabel;
    procedure ComboBox1Select(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form61: TForm61;

implementation

{$R *.dfm}

procedure TForm61.ComboBox1Select(Sender: TObject);
begin
  if not checkbox1.Checked then
    edit1.Text := inttostr(combobox1.ItemIndex);
end;

end.
