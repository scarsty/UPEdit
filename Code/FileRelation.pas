unit FileRelation;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, registry, shlobj, StdCtrls, head, main;

type
  TForm92 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    CheckBox6: TCheckBox;
    CheckBox7: TCheckBox;
    CheckBox8: TCheckBox;
    Label2: TLabel;
    CheckBox9: TCheckBox;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

procedure RegisterFileType(prefix: string; exepfad: string; index: integer);

var
  Form92: TForm92;

implementation

{$R *.dfm}

procedure RegisterFileType(prefix: string; exepfad: string; index: integer);
var
  reg: TRegistry;
  tempstr: string;
begin
  reg := TRegistry.Create;

  try

    reg.RootKey := HKEY_CLASSES_ROOT;

    //create a new key  --> .pci
    //reg.DeleteKey('.' + prefix);
    reg.CreateKey('.' + prefix);
    reg.OpenKey('.' + prefix, True);

    try

      //create a new value for this key --> pcifile

      reg.Writestring('', prefix + 'UPfile');

    finally

      reg.CloseKey;

    end;

    //create a new key --> pcifile
    //reg.DeleteKey(prefix + 'UPfile');
    reg.CreateKey(prefix + 'UPfile');

    reg.OpenKey(prefix + 'UPfile', True);

    try
      reg.Writestring('', prefix + ' - '+ Appname + '文件');
    finally
      reg.CloseKey;
    end;

    //create a new key pcifile\DefaultIcon

    reg.OpenKey(prefix + 'UPfile\DefaultIcon', True);

    //and create a value where the icon is stored --> c:\project1.exe,0

    try
      if index >= 0 then
        tempstr := ',' + inttostr(index)
      else
        tempstr := '';

      reg.Writestring('', exepfad + tempstr);

    finally

      reg.CloseKey;

    end;

    reg.OpenKey(prefix + 'UPfile\shell\open\command', True);

    //create value where exefile is stored --> c:\project1.exe "%1"

    try

      reg.Writestring('', '"' + exepfad + '" "%1"');

    finally

      reg.CloseKey;

    end;

    reg.OpenKey(prefix + 'UPfile\shell\open', True);
    try
      reg.Writestring('', '使用'+ Appname +'打开');
    finally
      reg.CloseKey;
    end;

    reg.RootKey := HKEY_CURRENT_USER;

    reg.DeleteKey('Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.' + prefix + '\UserChoice');
    //reg.CreateKey(prefix + 'UPfile');

    reg.OpenKey('Software\Classes\.' + prefix, True);
    try
      reg.Writestring('', prefix + 'UPfile');
    finally
      reg.CloseKey;
    end;

    reg.OpenKey('Software\Classes\' + prefix + 'UPfile', True);
    try
      reg.Writestring('', prefix + ' - '+ Appname + '文件');
    finally
      reg.CloseKey;
    end;

    reg.OpenKey('Software\Classes\' + prefix + 'UPfile\DefaultIcon', True);

    //and create a value where the icon is stored --> c:\project1.exe,0

    try
      if index >= 0 then
        tempstr := ',' + inttostr(index)
      else
        tempstr := '';

      reg.Writestring('', exepfad + tempstr);

    finally

      reg.CloseKey;

    end;

    reg.OpenKey('Software\Classes\' + prefix + 'UPfile\shell\open\command', True);

    //create value where exefile is stored --> c:\project1.exe "%1"

    try

      reg.Writestring('', '"' + exepfad + '" "%1"');

    finally

      reg.CloseKey;

    end;

    reg.OpenKey('Software\Classes\' + prefix + 'UPfile\shell\open', True);
    try
      reg.Writestring('', '使用'+ Appname +'打开');
    finally
      reg.CloseKey;
    end;

  finally

    reg.Free;

  end;

  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);

end;

procedure TForm92.Button1Click(Sender: TObject);
begin
  try
  try
  if checkbox1.Checked then
    RegisterFileType('grp', paramstr(0), 1);
  if checkbox2.Checked then
    RegisterFileType('idx', paramstr(0), 2);
  if checkbox3.Checked then
    RegisterFileType('pic', paramstr(0), 3);
  if checkbox4.Checked then
    RegisterFileType('txt', paramstr(0), 4);
  if checkbox5.Checked then
    RegisterFileType('bmp', paramstr(0), 5);
  if checkbox6.Checked then
    RegisterFileType('png', paramstr(0), 5);
  if checkbox7.Checked then
    RegisterFileType('jpg', paramstr(0), 5);
  if checkbox8.Checked then
    RegisterFileType('gif', paramstr(0), 5);
  if checkbox9.Checked then
    RegisterFileType('imz', paramstr(0), 5);
  except
    showmessage('设置失败，win7用户请以管理员身份运行!');
  end;
  finally
    self.Close;
  end;

end;

procedure TForm92.Button2Click(Sender: TObject);
begin
  self.Close;
end;

procedure TForm92.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  checkbox1.Checked := false;
  checkbox2.Checked := false;
  checkbox3.Checked := false;
  checkbox4.Checked := false;
  checkbox5.Checked := false;
  checkbox6.Checked := false;
  checkbox7.Checked := false;
  checkbox8.Checked := false;
  checkbox9.Checked := false;
end;

procedure TForm92.FormCreate(Sender: TObject);
begin
  self.Cursor := fmcursor;
end;

procedure TForm92.FormShow(Sender: TObject);
begin
  checkbox1.Checked := true;
  checkbox2.Checked := true;
  checkbox3.Checked := true;
  checkbox4.Checked := false;
  checkbox5.Checked := false;
  checkbox6.Checked := false;
  checkbox7.Checked := false;
  checkbox8.Checked := false;
  checkbox9.Checked := true;
end;

end.
