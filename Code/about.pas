unit about;

{$modeswitch autoderef}

interface

uses Windows, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, opendisplay;

type
  TAboutBox = class(TForm)
    Panel1: TPanel;
    OKButton: TButton;
    ProgramIcon: TImage;
    ProductName: TLabel;
    Version: TLabel;
    Copyright: TLabel;
    Comments: TLabel;
    Label3: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    procedure Label1Click(Sender: TObject);
    procedure Label2Click(Sender: TObject);
    procedure ProgramIconClick(Sender: TObject);
    procedure Label3Click(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation

uses main;

{$R *.lfm}

procedure TAboutBox.FormCreate(Sender: TObject);
begin
  version.Caption := titlestr;
  self.Cursor := crDefault;
  self.Panel1.Cursor := crDefault;
end;

procedure TAboutBox.Label1Click(Sender: TObject);
begin
  ShellExecute(Application.Handle, nil, 'http://www.upwinded.com' , nil, nil, SW_SHOWNORMAL);
end;

procedure TAboutBox.Label2Click(Sender: TObject);
begin
  ShellExecute(Application.Handle, nil, 'http://www.upwinded.com' , nil, nil, SW_SHOWNORMAL);
end;

procedure TAboutBox.Label3Click(Sender: TObject);
begin
  ShellExecute(Application.Handle, nil, 'https://tiexuedanxin.net' , nil, nil, SW_SHOWNORMAL);
end;

procedure TAboutBox.OKButtonClick(Sender: TObject);
begin
  self.Close;
end;

procedure TAboutBox.ProgramIconClick(Sender: TObject);
begin
  ShellExecute(Application.Handle, nil, 'http://www.upwinded.com/' , nil, nil, SW_SHOWNORMAL);
  {FlashForm := TFlashForm.Create(application);
  FlashForm.ShowModal; }
end;

end.
 







