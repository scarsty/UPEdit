unit Ict_50_20;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm58 = class(TForm)
    Edit1: TEdit;
    Label1: TLabel;
    Edit2: TEdit;
    Label2: TLabel;
    ComboBox1: TComboBox;
    CheckBox1: TCheckBox;
    Button1: TButton;
    Button2: TButton;
    procedure ComboBox1Select(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form58: TForm58;

implementation

{$R *.dfm}

procedure TForm58.ComboBox1Select(Sender: TObject);
begin
  if not checkbox1.Checked then
    edit2.Text := inttostr(combobox1.ItemIndex);
end;

end.
