unit New50Instruct;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm44 = class(TForm)
    ListBox1: TListBox;
    button1: TButton;
    button2: TButton;
    procedure ListBox1DblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form44: TForm44;

implementation

{$R *.dfm}

procedure TForm44.ListBox1DblClick(Sender: TObject);
begin
  if listbox1.ItemIndex >= 0 then
  begin
    self.Close;
    self.ModalResult := mrOK;
  end;
end;

end.
