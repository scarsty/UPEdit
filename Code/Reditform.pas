unit Reditform;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, head;

type
  TForm6 = class(TForm)
    ComboBox1: TComboBox;
    Label1: TLabel;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Reditresult: integer;
  Form6: TForm6;
implementation

uses
  Redit;

{$R *.dfm}



procedure TForm6.FormCreate(Sender: TObject);
begin
  self.Cursor := fmcursor;
end;

end.
