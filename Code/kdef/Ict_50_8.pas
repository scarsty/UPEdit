unit Ict_50_8;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm49 = class(TForm)
    Edit2: TEdit;
    Edit1: TEdit;
    ComboBox1: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Button1: TButton;
    Button2: TButton;
    CheckBox1: TCheckBox;
    procedure ComboBox1Select(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form49: TForm49;

implementation

{$R *.dfm}

procedure TForm49.ComboBox1Select(Sender: TObject);
begin
  if not checkbox1.Checked then
    edit2.Text := inttostr(combobox1.ItemIndex);
end;

end.
