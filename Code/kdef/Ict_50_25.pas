unit Ict_50_25;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,head;

type
  TForm63 = class(TForm)
    ComboBox1: TComboBox;
    Edit1: TEdit;
    Label1: TLabel;
    Edit2: TEdit;
    Label2: TLabel;
    Edit3: TEdit;
    Label3: TLabel;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Button1: TButton;
    Button2: TButton;
    ComboBox2: TComboBox;
    Label4: TLabel;
    procedure ComboBox2Select(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form63: TForm63;

implementation

{$R *.dfm}

procedure TForm63.ComboBox2Select(Sender: TObject);
begin
  if combobox2.ItemIndex >= 0 then
  begin
    edit1.Text := Format('%x', [K50memorylist.addr[combobox2.ItemIndex]]);
  end;
end;

end.
