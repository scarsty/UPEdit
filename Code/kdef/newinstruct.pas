unit newinstruct;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, head;

type
  TForm9 = class(TForm)
    RadioGroup1: TRadioGroup;
    RadioGroup2: TRadioGroup;
    ListBox1: TListBox;
    Button1: TButton;
    Button2: TButton;
    procedure ListBox1Click(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form9: TForm9;

implementation

uses
  KDEFedit;

{$R *.dfm}

procedure TForm9.ListBox1Click(Sender: TObject);
begin
  if listbox1.ItemIndex > 0 then
  begin
    if kdefini.KDEFitem[listbox1.ItemIndex - 1].ifjump = 1 then
    begin
      radiogroup1.Visible := true;
      radiogroup2.Visible := true;
      radiogroup1.ItemIndex := 0;
      radiogroup2.ItemIndex := 0;
    end
    else
    begin
      radiogroup1.Visible := false;
      radiogroup2.Visible := false;
    end;
  end
  else
  begin
    radiogroup1.Visible := false;
    radiogroup2.Visible := false;
  end;
end;

procedure TForm9.ListBox1DblClick(Sender: TObject);
begin
  if listbox1.ItemIndex >= 0 then
  begin
    self.Close;
    self.ModalResult := mrOK;
  end;
end;

end.
