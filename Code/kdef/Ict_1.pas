unit Ict_1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,head;

type
  TForm14 = class(TForm)
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    ComboBox3: TComboBox;
    Label3: TLabel;
    procedure ComboBox2Select(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form14: TForm14;

implementation

uses
  KDEFedit;

{$R *.dfm}

procedure TForm14.Button3Click(Sender: TObject);
var
  temp2, I: integer;
begin
  temp2 := combobox2.ItemIndex;
  WriteTalkStr(@talkstr[combobox2.ItemIndex], displaybackstr(edit1.Text));
  combobox2.Clear;
  for I := 0 to talkstrnum - 1 do
    combobox2.Items.Add(inttostr(I) +':' + displaystr(ReadTalkStr(@talkstr[I])));
  combobox2.ItemIndex := temp2;
end;

procedure TForm14.Button4Click(Sender: TObject);
begin
  inc(talkstrnum);
  setlength(talkstr, talkstrnum);
  Writetalkstr(@talkstr[talkstrnum - 1], WideString('請輸入對話內容，若為原版對話，每隔12個漢字加一個星號*'));
  combobox2.Items.Add(inttostr(talkstrnum - 1) +':' + displaystr(ReadTalkStr(@talkstr[talkstrnum - 1])));
  combobox2.ItemIndex := talkstrnum - 1;
  edit1.Text := displaystr(ReadTalkStr(@talkstr[talkstrnum - 1]));
end;

procedure TForm14.Button5Click(Sender: TObject);
var
  I: integer;
begin
  if talkstrnum <> 1 then
  begin
    dec(talkstrnum);
    setlength(talkstr, talkstrnum);
    combobox2.Items.Delete(talkstrnum);
    combobox2.ItemIndex := talkstrnum - 1;
    edit1.Text := displaystr(readTalkStr(@talkstr[talkstrnum - 1]));
  end
  else
    showmessage('只剩一个对话，不可删除');
end;

procedure TForm14.ComboBox2Select(Sender: TObject);
begin
  edit1.Text := displaystr(readTalkstr(@talkstr[combobox2.ItemIndex]));
end;

end.
