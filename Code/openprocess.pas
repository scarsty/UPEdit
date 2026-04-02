unit openprocess;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, opendisplay, StdCtrls;

type
  TprocessForm = class(TForm)
    Label3: TLabel;
    Label2: TLabel;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  processForm: TprocessForm;
  processint: integer;

implementation

{$R *.dfm}

procedure TprocessForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := cafree;
end;

procedure TprocessForm.FormCreate(Sender: TObject);
begin
  processint := 0;
  //self.Top := screen.Height div 2 + FlashFormHeight div 2 - 45;
  self.Left := screen.Width div 2 - self.label3.Width div 2;
  self.Label1.Font.Color := $601070;
  self.Label2.Font.Color := $601070;
  self.Label3.Font.Color := $601070;

end;

end.
