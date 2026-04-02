unit InstructGuide;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls;

type
  TinctGuide = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Button1: TButton;
    Button2: TButton;
    RadioGroup1: TRadioGroup;
    procedure RadioGroup1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var

  GuidePanel: array of TPanel;
  GuideEdit: array of TEdit;
  GuideCombobox: array of TCombobox;
  GuideLabel: array of TLabel;
  GuideisCombobox: array of integer;

  guideyesjump: integer = -1;
  guidenojump: integer = -1;
  GuideJumpIndex: integer = 0;

implementation

{$R *.dfm}

procedure TinctGuide.RadioGroup1Click(Sender: TObject);
var
  tempstr: string;
begin
  if Panel3.Visible and (GuideJumpIndex <> RadioGroup1.ItemIndex) then
  begin
    GuideJumpIndex := RadioGroup1.ItemIndex;
    if (guideyesjump >= 0) and (guidenojump >= 0) then
    begin
      try
        tempstr := GuideEdit[GuideYesJump].Text;
        GuideEdit[GuideYesJump].Text := GuideEdit[GuideNoJump].Text;
        GuideEdit[GuideNoJump].Text := tempstr;
      except

      end;
    end;
  end;
end;

end.
