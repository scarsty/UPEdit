unit MAIN;

interface

uses SysUtils, Windows, Classes, Graphics, Controls, Menus,
  StdCtrls, Dialogs, Buttons, Messages, ExtCtrls, ComCtrls, StdActns,
  ActnList, ToolWin, ImgList, FileCtrl, inifiles, head, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, OleCtrls, SHDocVw, shellapi,
  AppEvnts, IdAntiFreezeBase, IdAntiFreeze, math, pngimage, Forms;

type

  TMyThead = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

  TUPeditMainForm = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    N2: TMenuItem;
    N5: TMenuItem;
    FileExitItem: TMenuItem;
    N3: TMenuItem;
    R1: TMenuItem;
    N4: TMenuItem;
    N9: TMenuItem;
    form1: TMenuItem;
    N1: TMenuItem;
    grp1: TMenuItem;
    pic1: TMenuItem;
    N11: TMenuItem;
    N13: TMenuItem;
    N15: TMenuItem;
    Help1: TMenuItem;
    HelpAboutItem: TMenuItem;
    N17: TMenuItem;
    N19: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    WebBrowser1: TWebBrowser;
    IdHTTP1: TIdHTTP;
    N20: TMenuItem;
    N21: TMenuItem;
    N22: TMenuItem;
    MOD1: TMenuItem;
    TrayIcon1: TTrayIcon;
    PopupMenu1: TPopupMenu;
    N24: TMenuItem;
    N25: TMenuItem;
    N26: TMenuItem;
    N27: TMenuItem;
    N28: TMenuItem;
    N29: TMenuItem;
    N30: TMenuItem;
    bug1: TMenuItem;
    N31: TMenuItem;
    N33: TMenuItem;
    N34: TMenuItem;
    Window1: TMenuItem;
    N6: TMenuItem;
    IdAntiFreeze1: TIdAntiFreeze;
    PNG1: TMenuItem;
    N7: TMenuItem;
    bug2: TMenuItem;
    IMZ1: TMenuItem;
    Panel3: TPanel;
    WebBrowser2: TWebBrowser;
    Button1: TButton;
    Panel4: TPanel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label2: TLabel;
    Label1: TLabel;

    procedure HelpAbout1Execute(Sender: TObject);
    procedure FileExit1Execute(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure grp1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure pic1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure R1Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure R2Click(Sender: TObject);
    procedure N7Click(Sender: TObject);
    procedure N8Click(Sender: TObject);
    procedure GRP2Click(Sender: TObject);
    procedure Pic2Click(Sender: TObject);
    procedure N9Click(Sender: TObject);
    procedure N10Click(Sender: TObject);
    procedure N11Click(Sender: TObject);
    procedure N12Click(Sender: TObject);
    procedure N13Click(Sender: TObject);
    procedure N14Click(Sender: TObject);
    procedure N15Click(Sender: TObject);
    procedure N16Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure N17Click(Sender: TObject);
    procedure N18Click(Sender: TObject);
    procedure N19Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure newthread;
    procedure BitBtn1Click(Sender: TObject);
    procedure N20Click(Sender: TObject);
    procedure N21Click(Sender: TObject);
    procedure N22Click(Sender: TObject);
    procedure N23Click(Sender: TObject);
    procedure N24Click(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure N25Click(Sender: TObject);
    procedure N28Click(Sender: TObject);
    procedure N29Click(Sender: TObject);
    procedure N30Click(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure bug1Click(Sender: TObject);
    procedure N31Click(Sender: TObject);
    procedure N32Click(Sender: TObject);
    procedure AppOnMessage(var Msg: tagMSG; var Handled: Boolean);
    procedure setpath;
    procedure N33Click(Sender: TObject);
    procedure N34Click(Sender: TObject);
    procedure PNG1Click(Sender: TObject);
    procedure bug2Click(Sender: TObject);
    procedure IMZ1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure WebBrowser1NewWindow2(ASender: TObject; var ppDisp: IDispatch; var Cancel: WordBool);
    procedure WebBrowser2BeforeNavigate2(ASender: TObject; const pDisp: IDispatch; var URL, Flags, TargetFrameName, PostData, Headers: OleVariant; var Cancel: WordBool);
    procedure Button1Click(Sender: TObject);
    procedure Label4MouseEnter(Sender: TObject);
    procedure Label4MouseLeave(Sender: TObject);
    procedure Label5MouseLeave(Sender: TObject);
    procedure Label5MouseEnter(Sender: TObject);
    procedure Label6MouseEnter(Sender: TObject);
    procedure Label6MouseLeave(Sender: TObject);
    procedure Label7MouseEnter(Sender: TObject);
    procedure Label7MouseLeave(Sender: TObject);
    procedure Label4Click(Sender: TObject);
    procedure Label5Click(Sender: TObject);
    procedure Label6Click(Sender: TObject);
    procedure Label7Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    MyThead: TMyThead;
    procedure Onmymessage(var t: TWmCopyData); message WM_COPYDATA;

  end;

procedure UPcheckUpdate;
procedure displayupdate;
procedure setwebbrowser;
procedure displayanoce;
procedure ifupdate;
procedure checkupdatefail;
procedure AppInitial;

var
  MainForm: TUPeditMainForm;
  canlink: integer;
  anoce: string;
  laststate: Twindowstate;
  mainhide: Boolean = false;
  topcolumn: Boolean = true;
  leftcolumn: Boolean = true;

  // 侧边栏
  // m_bNewWindow: boolean = false;
  // mainwebshow: boolean = false;
const
  titlestr: string = 'UPedit Formal Ver 1.xxx';
  Appname: string = 'UPedit Formal';
  WM_ABOUT: integer = 2000;

  FastButtonColor: Cardinal = clPurple;

implementation

{$R *.dfm}

uses Replicatedlist, takein, about, grplist, picedit, Redit, setlanguage, KDEFedit,
  warEdit, Update, warmapedit, sencemapedit, Mainmapedit, CYhead, TxtLeadin, FileRelation,
  Imagez, PNGimport;

procedure TUPeditMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  {
    if downloadupdate then
    begin
    AssignFile(DBat, 'UpdateUPedit.bat');
    Rewrite(DBat);
    Writeln(DBat,'@echo off');
    Writeln(DBat,'TASKKILL /F /IM /T '+ParamStr(0));
    Writeln(DBat,'del '+ParamStr(0)); //写入删除主程序的命令
    Writeln(DBat,'copy   UPedit.exe.tmp   UPedit.exe');
    Writeln(DBat,'del UPedit.exe.tmp');
    // Writeln(DBat,'start "" "' + ParamStr(0)+'"');

    Writeln(DBat,'del %0'); //删除BAT文件自身
    Writeln(DBat,'exit');
    CloseFile(DBat);
    application.Terminate;
    WinExec('UpdateUPedit.bat',SW_HIDE);
    end; }
  // DeleteCriticalSection(L);
  // MyThead.Free
  { if MyThead.Handle <> 0 then
    begin
    MyThead.Terminate;
    end; }
  try
    halt;
  except
    halt;
  end;
end;

procedure TUPeditMainForm.Onmymessage(var t: TWmCopyData);
var
  filename: string;
  // tempForm: ^TForm;
  FormImz: TImzForm;
  Form91: TForm91;
  form1: TForm1;
  FOrm3: TForm3;
  Form4: TForm4;
  tempstr: Ansistring;
  opentempstr: string;
  I, I2, I3: integer;
  tempdata: Pbyte;
begin
  tempstr := strpas(PAnsiChar(t.CopyDataStruct.lpData));
  tempdata := t.CopyDataStruct.lpData;
  if byte(tempstr[1]) = 1 then
  begin
    copynum := Pinteger(Pbyte(t.CopyDataStruct.lpData) + 1)^;
    // showmessage(inttostr(copynum));
    setlength(grplistcopydata, copynum);
    if copynum > 0 then
    begin
      copymemory(@grplistcopydata[0], (Pbyte(t.CopyDataStruct.lpData) + 5), copynum);
    end;
  end
  else if (length(tempstr) > 4) and (AnsiChar(tempstr[1]) = 'I') and (AnsiChar(tempstr[2]) = 'M') and (AnsiChar(tempstr[3]) = 'Z') and (byte(tempstr[4]) = 255) then
  begin
    if not CFormImz then
    begin
      for I := 0 to self.MDIChildCount - 1 do
        if self.MDIChildren[I].Handle = MdiChildHandle[13] then
        begin
          // self.MDIChildren[I].Show;
          FormImz := TImzForm(self.MDIChildren[I]);
          FormImz.IMZcanCopyPNG := true;
          try

            FormImz.imzcopypng.len := Pinteger(tempdata + 4)^;
            FormImz.imzcopypng.x := PSmallint(tempdata + 8)^;
            FormImz.imzcopypng.y := PSmallint(tempdata + 10)^;
            FormImz.imzcopypng.frame := max(0, Pinteger(tempdata + 12)^);
            setlength(FormImz.imzcopypng.framelen, FormImz.imzcopypng.frame);
            setlength(FormImz.imzcopypng.framedata, FormImz.imzcopypng.frame);
            I3 := 16;
            for I2 := 0 to FormImz.imzcopypng.frame - 1 do
            begin
              FormImz.imzcopypng.framelen[I2] := max(0, Pinteger(tempdata + I3)^);
              inc(I3, 4);
              setlength(FormImz.imzcopypng.framedata[I2].data, FormImz.imzcopypng.framelen[I2]);
              if FormImz.imzcopypng.framelen[I2] > 0 then
                copymemory(@FormImz.imzcopypng.framedata[I2].data[0], (tempdata + I3), FormImz.imzcopypng.framelen[I2]);
              inc(I3, FormImz.imzcopypng.framelen[I2]);
            end;
          except

            FormImz.IMZcanCopyPNG := false;
          end;

          Break;
        end;
    end;
  end
  else
  begin
    filename := widestring(tempstr);
    if fileexists(filename) then
    begin
      if SameText(ExtractFileExt(filename), '.pic') then
      begin
        if CForm4 then
        begin
          Form4 := TForm4.Create(application);
          CForm4 := false;
          MdiChildHandle[4] := Form4.Handle;
          Form4.openfile(filename);
          Form4.OpenDialog1.filename := filename;
        end
        else
        begin
          for I := 0 to self.MDIChildCount - 1 do
            if self.MDIChildren[I].Handle = MdiChildHandle[4] then
            begin
              self.MDIChildren[I].Show;
              Form4 := TForm4(self.MDIChildren[I]);

              // form4 := PForm4(tempform)^;
              Form4.openfile(filename);
              Form4.OpenDialog1.filename := filename;
              Break;
            end;
        end;

      end
      else if SameText(ExtractFileExt(filename), '.txt') then
      begin
        if CForm91 then
        begin
          CForm91 := false;
          Form91 := TForm91.Create(application);

          MdiChildHandle[11] := Form91.Handle;
          Form91.Edit1.Text := filename;
          Form91.OpenDialog1.filename := filename;
        end
        else
        begin
          for I := 0 to self.MDIChildCount - 1 do
            if self.MDIChildren[I].Handle = MdiChildHandle[11] then
            begin
              self.MDIChildren[I].Show;
              Form91 := TForm91(self.MDIChildren[I]);
              // Form91 := PForm91(tempform)^;
              Form91.Edit1.Text := filename;
              Form91.OpenDialog1.filename := filename;
              Break;
            end;
        end;
      end
      else if SameText(ExtractFileExt(filename), '.grp') then
      begin
        opentempstr := ChangeFileExt(filename, '.idx');
        if CForm3 then
        begin
          CForm3 := false;
          FOrm3 := TForm3.Create(application);
          FOrm3.WindowState := wsmaximized;
          MdiChildHandle[3] := FOrm3.Handle;
          FOrm3.Edit1.Text := opentempstr;
          FOrm3.Edit2.Text := filename;
          FOrm3.displaygrplist;
        end
        else
        begin
          for I := 0 to self.MDIChildCount - 1 do
            if self.MDIChildren[I].Handle = MdiChildHandle[3] then
            begin
              self.MDIChildren[I].Show;
              FOrm3 := TForm3(self.MDIChildren[I]);
              // Form3 := PForm3(tempform)^;
              FOrm3.ComboBox1.ItemIndex := -1;
              FOrm3.Edit1.Text := opentempstr;
              FOrm3.Edit2.Text := filename;
              FOrm3.displaygrplist;
              Break;
            end;
        end;
      end
      else if SameText(ExtractFileExt(filename), '.idx') then
      begin
        opentempstr := ChangeFileExt(filename, '.grp');
        if CForm3 then
        begin
          CForm3 := false;
          FOrm3 := TForm3.Create(application);
          FOrm3.WindowState := wsmaximized;
          MdiChildHandle[3] := FOrm3.Handle;
          FOrm3.Edit1.Text := filename;
          FOrm3.Edit2.Text := opentempstr;
          FOrm3.displaygrplist;
        end
        else
        begin
          for I := 0 to self.MDIChildCount - 1 do
            if self.MDIChildren[I].Handle = MdiChildHandle[3] then
            begin
              self.MDIChildren[I].Show;
              FOrm3 := TForm3(self.MDIChildren[I]);
              // Form3 := PForm3(tempform)^;
              FOrm3.Edit1.Text := filename;
              FOrm3.Edit2.Text := opentempstr;
              FOrm3.displaygrplist;
              FOrm3.ComboBox1.ItemIndex := -1;
              Break;
            end;
        end;
      end
      else if SameText(ExtractFileExt(filename), '.png') or SameText(ExtractFileExt(filename), '.jpg') or SameText(ExtractFileExt(filename), '.bmp') or SameText(ExtractFileExt(filename), '.gif') or
        SameText(ExtractFileExt(filename), '.jpeg') then
      begin
        if CForm1 then
        begin
          CForm1 := false;
          form1 := TForm1.Create(application);
          MdiChildHandle[2] := form1.Handle;
          picname := filename;
          form1.picdisplay;
        end
        else
        begin
          for I := 0 to self.MDIChildCount - 1 do
            if self.MDIChildren[I].Handle = MdiChildHandle[2] then
            begin
              self.MDIChildren[I].Show;
              form1 := TForm1(self.MDIChildren[I]);
              // Form1 :=PForm1(tempform)^;
              picname := filename;
              form1.picdisplay;
              Break;
            end;
        end;
      end
      else if SameText(ExtractFileExt(filename), '.imz') then
      begin
        if CFormImz then
        begin
          CFormImz := false;
          FormImz := TImzForm.Create(application);
          FormImz.Edit2.Text := filename;
          FormImz.Button5.Click;
          MdiChildHandle[13] := FormImz.Handle;
        end
        else
        begin
          for I := 0 to self.MDIChildCount - 1 do
            if self.MDIChildren[I].Handle = MdiChildHandle[13] then
            begin
              self.MDIChildren[I].Show;
              FormImz := TImzForm(self.MDIChildren[I]);
              FormImz.Edit2.Text := filename;
              FormImz.SetEditMode(zImzMode);
              FormImz.Button5.Click;
              Break;
            end;
        end;
      end;
    end;
  end;
  setlength(tempstr, 0);
end;

procedure TUPeditMainForm.FormCreate(Sender: TObject);
begin
  TrayIcon1.Hint := titlestr;
  TrayIcon1.Icon := Forms.application.Icon;
  Forms.application.OnMessage := self.AppOnMessage;
  // Application.OnMessage:=OnAppMessage;
  self.Caption := titlestr + ' - ' + gamepath;
  WebBrowser1.Cursor := fmcursor;
  N20.Checked := topcolumn;
  N21.Checked := leftcolumn;
  Panel1.Visible := topcolumn;
  Panel2.Visible := leftcolumn;
  DragAcceptFiles(self.Handle, true);
end;

procedure AppInitial;
var
  ini: Tinifile;
  filename: string;
  tempstr: widestring;
  strlist: Tstringlist;
  I, strnum, temp, I2: integer;
  inihead: word;
  Mnu: HMenu;
  tempchar: array [0 .. 1024] of char;
begin
  application.Title := Appname; // titlestr;  // application.

  Mnu := GetSystemMenu(application.Handle, false);
  AppendMenu(Mnu, MF_SEPARATOR, 0, nil);
  AppendMenu(Mnu, MF_STRING, WM_ABOUT, pchar('关于...'));

  try
    if paramcount > 0 then
    begin
      filename := paramstr(1);
      if filename.EndsWith('.ini') then
      begin
        StartPath := ExtractFilePath(filename);
        iniFilename := ExtractFileName(filename);
      end;
    end;
    if StartPath = '' then
      StartPath := GetCurrentDir + '\';
    filename := StartPath + iniFilename;
    temp := fileopen(filename, fmopenread);
    fileseek(temp, 0, 0);
    fileread(temp, inihead, 2);
    if inihead = $FEFF then
      inicode := 0
    else
      inicode := 1;
    fileclose(temp);
    ini := Tinifile.Create(filename);
    appfirstrun := ini.ReadBool('run', 'firstrun', true);
    updatepath := ini.ReadString('run', 'updatapath', StartPath);
    gamepath := ini.ReadString('run', 'gamepath', '\');
    if length(gamepath) > 0 then
      if gamepath[length(gamepath)] <> '\' then
        gamepath := gamepath + '\';
    datacode := ini.Readinteger('run', 'datacode', 1);
    talkcode := ini.Readinteger('run', 'talkcode', datacode);
    talkinvert := ini.Readinteger('run', 'talkinvert', talkinvert);
    palette := ini.ReadString('file', 'palette', '');
    language := ini.Readinteger('run', 'language', 0);
    grplistnum := ini.Readinteger('file', 'filenumber', 0);
    checkupdate := ini.Readinteger('run', 'checkupdate', 0);
    leftcolumn := ini.ReadBool('run', 'leftcolumn', false);
    topcolumn := ini.ReadBool('run', 'topcolumn', false);

    GameVersion := ini.Readinteger('run', 'GameVersion', GameVersion);

    talkidx := ini.ReadString('file', 'talkidx', '');
    talkgrp := ini.ReadString('file', 'talkgrp', '');
    kdefidx := ini.ReadString('file', 'kdefidx', '');
    kdefgrp := ini.ReadString('file', 'kdefgrp', '');
    nameidx := ini.ReadString('file', 'nameidx', '');
    namegrp := ini.ReadString('file', 'namegrp', '');
    wardata := ini.ReadString('file', 'WarDefine', '');
    headpicname := ini.ReadString('file', 'headpicname', '');

    warmapgrp := ini.ReadString('file', 'WarMAPGRP', '');
    warmapidx := ini.ReadString('file', 'WarMAPIDX', '');
    WMAPIMZ := ini.ReadString('file', 'WMAPIMZ', '');
    WMAPPNGPATH := ini.ReadString('file', 'WMAPPNGPATH', '');
    if length(WMAPPNGPATH) > 0 then
      if WMAPPNGPATH[length(WMAPPNGPATH)] <> '\' then
        WMAPPNGPATH := WMAPPNGPATH + '\';
    WarMAPDefGRP := ini.ReadString('file', 'WarMAPDefGRP', '');
    WarMAPDefIDX := ini.ReadString('file', 'WarMAPDefIDX', '');

    SMAPGRP := ini.ReadString('file', 'SMAPGRP', '');
    SMAPIDX := ini.ReadString('file', 'SMAPIDX', '');
    SMAPIMZ := ini.ReadString('file', 'SMAPIMZ', '');
    SMAPPNGPATH := ini.ReadString('file', 'SMAPPNGPATH', '');
    if length(SMAPPNGPATH) > 0 then
      if SMAPPNGPATH[length(SMAPPNGPATH)] <> '\' then
        SMAPPNGPATH := SMAPPNGPATH + '\';

    MMAPfileGRP := ini.ReadString('file', 'MMAPGRP', '');
    MMAPfileIDX := ini.ReadString('file', 'MMAPIDX', '');
    MMAPIMZ := ini.ReadString('file', 'MMAPIMZ', '');
    MMAPPNGPATH := ini.ReadString('file', 'MMAPPNGPATH', '');
    if length(MMAPPNGPATH) > 0 then
      if MMAPPNGPATH[length(MMAPPNGPATH)] <> '\' then
        MMAPPNGPATH := MMAPPNGPATH + '\';

    Leave := ini.ReadString('file', 'Leave', '');
    Effect := ini.ReadString('file', 'Effect', '');
    Match := ini.ReadString('file', 'Match', '');
    Exp := ini.ReadString('file', 'Exp', '');
    grplistselect := ini.Readinteger('file', 'GRPselect', 0);
    GRPListBackGround := ini.Readinteger('file', 'GRPListBackGround', clwhite);
    GRPListTextCol := ini.Readinteger('file', 'GRPListTextCol', clred);
    warsmallmapsize := ini.Readinteger('file', 'warsmallmapsize', 3);

    if grplistnum > 0 then
    begin
      setlength(grplistidx, grplistnum);
      setlength(grplistgrp, grplistnum);
      setlength(grplistname, grplistnum);
      setlength(grplistSection, grplistnum);
      strlist := Tstringlist.Create;
      for I := 0 to grplistnum - 1 do
      begin
        tempstr := ini.ReadString('file', 'file' + inttostr(I), '');
        strlist.Clear;
        // wtempstr := @tempstr;
        strnum := ExtractStrings([','], [], Pwidechar(tempstr), strlist);
        if strnum = 3 then
        begin
          grplistidx[I] := strlist.Strings[0];
          grplistgrp[I] := strlist.Strings[1];
          grplistname[I] := strlist.Strings[2];
        end;
        tempstr := ini.ReadString('file', 'Section' + inttostr(I), '');
        strlist.Clear;
        strnum := ExtractStrings([','], [], Pwidechar(tempstr), strlist);
        if ((strnum div 3) > 0) and (strnum mod 3 = 0) then
        begin
          grplistSection[I].num := strnum div 3;
          setlength(grplistSection[I].tag, grplistSection[I].num);
          setlength(grplistSection[I].beginnum, grplistSection[I].num);
          setlength(grplistSection[I].endnum, grplistSection[I].num);
          for I2 := 0 to grplistSection[I].num - 1 do
          begin
            grplistSection[I].tag[I2] := strlist.Strings[I2 * 3];
            grplistSection[I].beginnum[I2] := strtoint(strlist.Strings[I2 * 3 + 1]);
            if strlist.Strings[I2 * 3 + 2] = 'end' then
              grplistSection[I].endnum[I2] := -2
            else
              grplistSection[I].endnum[I2] := strtoint(strlist.Strings[I2 * 3 + 2]);
          end;
        end
        else
        begin
          grplistSection[I].num := 0;
        end;
      end;
      strlist.Free;
    end;
    strlist := Tstringlist.Create;
    strlist.Clear;
    tempstr := ini.ReadString('file', 'MMAPStruct', '');
    if tempstr <> '' then
    begin
      strnum := ExtractStrings([','], [], Pwidechar(tempstr), strlist);
      if strnum = 5 then
      begin
        Mearth := strlist.Strings[0];
        Msurface := strlist.Strings[1];
        Mbuilding := strlist.Strings[2];
        Mbuildx := strlist.Strings[3];
        Mbuildy := strlist.Strings[4];
      end;
    end;
    strlist.Clear;
    tempstr := ini.ReadString('file', 'RIDX', '');
    if tempstr <> '' then
    begin
      Rfilenum := ExtractStrings([','], [], Pwidechar(tempstr), strlist);
      temp := Rfilenum;
      if Rfilenum > 0 then
      begin
        setlength(Ridxfilename, Rfilenum);
        for I := 0 to Rfilenum - 1 do
          Ridxfilename[I] := strlist.Strings[I];
      end;
    end;
    strlist.Clear;
    tempstr := ini.ReadString('file', 'RGRP', '');
    if tempstr <> '' then
    begin
      Rfilenum := ExtractStrings([','], [], Pwidechar(tempstr), strlist);
      if temp > Rfilenum then
        temp := Rfilenum;
      if Rfilenum > 0 then
      begin
        setlength(Rfilename, Rfilenum);
        for I := 0 to Rfilenum - 1 do
          Rfilename[I] := strlist.Strings[I];
      end;
    end;
    strlist.Clear;
    tempstr := ini.ReadString('file', 'SIDX', '');
    if tempstr <> '' then
    begin
      Rfilenum := ExtractStrings([','], [], Pwidechar(tempstr), strlist);
      if temp > Rfilenum then
        temp := Rfilenum;
      if Rfilenum > 0 then
      begin
        setlength(SIDX, Rfilenum);
        for I := 0 to Rfilenum - 1 do
          SIDX[I] := strlist.Strings[I];
      end;
    end;
    strlist.Clear;
    tempstr := ini.ReadString('file', 'SGRP', '');
    if tempstr <> '' then
    begin
      Rfilenum := ExtractStrings([','], [], Pwidechar(tempstr), strlist);
      if temp > Rfilenum then
        temp := Rfilenum;
      if Rfilenum > 0 then
      begin
        setlength(SGRP, Rfilenum);
        for I := 0 to Rfilenum - 1 do
          SGRP[I] := strlist.Strings[I];
      end;
    end;
    strlist.Clear;
    tempstr := ini.ReadString('file', 'DIDX', '');
    if tempstr <> '' then
    begin
      Rfilenum := ExtractStrings([','], [], Pwidechar(tempstr), strlist);
      if temp > Rfilenum then
        temp := Rfilenum;
      if Rfilenum > 0 then
      begin
        setlength(DIDX, Rfilenum);
        for I := 0 to Rfilenum - 1 do
          DIDX[I] := strlist.Strings[I];
      end;
    end;
    strlist.Clear;
    tempstr := ini.ReadString('file', 'DGRP', '');
    if tempstr <> '' then
    begin
      Rfilenum := ExtractStrings([','], [], Pwidechar(tempstr), strlist);
      if temp > Rfilenum then
        temp := Rfilenum;
      if Rfilenum > 0 then
      begin
        setlength(DGRP, Rfilenum);
        for I := 0 to Rfilenum - 1 do
          DGRP[I] := strlist.Strings[I];
      end;
    end;
    strlist.Clear;
    tempstr := ini.ReadString('file', 'RecordNote', '');
    if tempstr <> '' then
    begin
      Rfilenum := ExtractStrings([','], [], Pwidechar(tempstr), strlist);
      if temp > Rfilenum then
        temp := Rfilenum;
      if Rfilenum > 0 then
      begin
        setlength(Rfilenote, Rfilenum);
        for I := 0 to Rfilenum - 1 do
          Rfilenote[I] := strlist.Strings[I];
      end;
    end;
    Rfilenum := temp;
    scenenum := temp;
    fightgrpnum := ini.Readinteger('file', 'fightnum', 0);
    strlist.Clear;
    tempstr := ini.ReadString('file', 'fightname', '');
    strnum := ExtractStrings([','], [], Pwidechar(tempstr), strlist);
    if strnum = 3 then
    begin
      fightidx := strlist.Strings[0];
      fightgrp := strlist.Strings[1];
      fightname := strlist.Strings[2];
    end;
    strlist.Free;
    ini.Free;
    Readini; // Rini
    readwini;
    readDini;
    read50memory; // 50指令内存表
    readMcol;
    readw(gamepath + wardata, @useW);
    if readR(gamepath + Ridxfilename[0], gamepath + Rfilename[0], @useR) then
      calnamepos(@useR);

  except
    showmessage('读取ini文件失败');
  end;

end;

procedure TUPeditMainForm.FormHide(Sender: TObject);
begin
  // self.Visible := false;
  self.Hide;
  self.WindowState := wsMinimized;
  mainhide := true;
  ShowWindow(Forms.application.Handle, SW_HIDE);
  // application.Terminate;
end;

procedure TUPeditMainForm.FormResize(Sender: TObject);
{ var
  ix, iy: integer;
  xparam, yparam: single;
  bparam, gparam, rparam: byte;
  formbmp: Tbitmap;
  bmpdata: array of array of byte; }
begin
  // Self.Constraints.MaxHeight := Screen.WorkAreaHeight;//不挡住任务栏
  Panel2.Width := 250;
  if (self.Width - 250) > 300 then
    Label2.Width := self.Width - 250
  else
    Label2.Width := 300;

  { if self.GlassFrame.Enabled then
    begin
    self.GlassFrame.Bottom := self.ClientHeight - panel1.Height;
    end; }
  { Image1.Picture.Bitmap.Width := Image1.Width;
    Image1.Picture.Bitmap.Height := Image1.Height;

    formbmp := Tbitmap.Create;
    try
    formbmp.Width := Image1.Width;
    formbmp.Height := Image1.Height;
    formbmp.PixelFormat := pf32bit;

    setlength(bmpdata, formbmp.Height, formbmp.Width * 4);
    for iy := 0 to formbmp.Height - 1 do
    begin
    Zeromemory(@bmpdata[iy][0], formbmp.Width shl 2);
    yparam := iy / formbmp.Height;
    for ix := 0 to formbmp.Width - 1 do
    begin
    xparam := 1 - ix / formbmp.Width;
    bparam := round((xparam - yparam + 1) / 2 * 255);
    gparam := round((1 - abs(xparam - yparam)) * 255);
    rparam := round((yparam - xparam + 1) / 2 * 255);
    bmpdata[iy][ix shl 2] := bparam;
    bmpdata[iy][ix shl 2 + 1] := gparam;
    bmpdata[iy][ix shl 2 + 2] := rparam;
    end;
    copymemory(formbmp.ScanLine[iy], @bmpdata[iy][0], formbmp.Width shl 2);

    end;
    Image1.Canvas.Draw(0, 0, formbmp);
    finally
    setlength(bmpdata, 0, 0);
    if formbmp <> nil then
    begin
    formbmp.Free;
    formbmp := nil;
    end;
    end; }
end;

procedure TUPeditMainForm.grp1Click(Sender: TObject);
var
  FOrm3: TForm3;
  I: integer;
begin
  if CForm3 then
  begin
    CForm3 := false;
    FOrm3 := TForm3.Create(application);
    FOrm3.WindowState := wsmaximized;
    MdiChildHandle[3] := FOrm3.Handle;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if self.MDIChildren[I].Handle = MdiChildHandle[3] then
        self.MDIChildren[I].Show;
  end;
end;

procedure TUPeditMainForm.GRP2Click(Sender: TObject);
var
  I: integer;
begin
  for I := 0 to self.MDIChildCount - 1 do
    if self.MDIChildren[I].Handle = MdiChildHandle[3] then
      self.MDIChildren[I].Show;
end;

procedure TUPeditMainForm.HelpAbout1Execute(Sender: TObject);
begin
  AboutBox.ShowModal;
end;

procedure TUPeditMainForm.IMZ1Click(Sender: TObject);
var
  I: integer;
  FormImz: TImzForm;
begin
  if CFormImz then
  begin
    CFormImz := false;
    FormImz := TImzForm.Create(application);
    MdiChildHandle[13] := FormImz.Handle;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if self.MDIChildren[I].Handle = MdiChildHandle[13] then
        self.MDIChildren[I].Show;
  end;
end;

procedure TUPeditMainForm.Label4Click(Sender: TObject);
begin
  R1Click(Sender);
end;

procedure TUPeditMainForm.Label4MouseEnter(Sender: TObject);
begin
  Label4.Font.Color := FastButtonColor;
end;

procedure TUPeditMainForm.Label4MouseLeave(Sender: TObject);
begin
  Label4.Font.Color := clBlack;
end;

procedure TUPeditMainForm.Label5Click(Sender: TObject);
begin
  if GameVersion = 1 then
  begin
    IMZ1Click(Sender);
  end
  else
    grp1Click(Sender);
end;

procedure TUPeditMainForm.Label5MouseEnter(Sender: TObject);
begin
  Label5.Font.Color := FastButtonColor;
end;

procedure TUPeditMainForm.Label5MouseLeave(Sender: TObject);
begin
  Label5.Font.Color := clBlack;
end;

procedure TUPeditMainForm.Label6Click(Sender: TObject);
begin
  N13Click(Sender);
end;

procedure TUPeditMainForm.Label6MouseEnter(Sender: TObject);
begin
  Label6.Font.Color := FastButtonColor;
end;

procedure TUPeditMainForm.Label6MouseLeave(Sender: TObject);
begin
  Label6.Font.Color := clBlack;
end;

procedure TUPeditMainForm.Label7Click(Sender: TObject);
begin
  N4Click(Sender);
end;

procedure TUPeditMainForm.Label7MouseEnter(Sender: TObject);
begin
  Label7.Font.Color := FastButtonColor;
end;

procedure TUPeditMainForm.Label7MouseLeave(Sender: TObject);
begin
  Label7.Font.Color := clBlack;
end;

procedure TUPeditMainForm.N10Click(Sender: TObject);
var
  I: integer;
begin
  for I := 0 to self.MDIChildCount - 1 do
    if self.MDIChildren[I].Handle = MdiChildHandle[5] then
      self.MDIChildren[I].Show;
end;

procedure TUPeditMainForm.N11Click(Sender: TObject);
var
  Form11: TForm11;
  I: integer;
begin
  if CForm11 then
  begin
    CForm11 := false;
    Form11 := TForm11.Create(application);
    MdiChildHandle[6] := Form11.Handle;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if self.MDIChildren[I].Handle = MdiChildHandle[6] then
        self.MDIChildren[I].Show;
  end;
end;

procedure TUPeditMainForm.N12Click(Sender: TObject);
var
  I: integer;
begin
  for I := 0 to self.MDIChildCount - 1 do
    if self.MDIChildren[I].Handle = MdiChildHandle[6] then
      self.MDIChildren[I].Show;
end;

procedure TUPeditMainForm.N13Click(Sender: TObject);
var
  Form12: TForm12;
  I: integer;
begin
  if CForm12 then
  begin
    CForm12 := false;
    Form12 := TForm12.Create(application);
    MdiChildHandle[7] := Form12.Handle;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if self.MDIChildren[I].Handle = MdiChildHandle[7] then
        self.MDIChildren[I].Show;
  end;
end;

procedure TUPeditMainForm.N14Click(Sender: TObject);
var
  I: integer;
begin
  for I := 0 to self.MDIChildCount - 1 do
    if self.MDIChildren[I].Handle = MdiChildHandle[7] then
      self.MDIChildren[I].Show;
end;

procedure TUPeditMainForm.N15Click(Sender: TObject);
var
  Form13: TForm13;
  I: integer;
begin
  if CForm13 then
  begin
    CForm13 := false;
    Form13 := TForm13.Create(application);
    MdiChildHandle[8] := Form13.Handle;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if self.MDIChildren[I].Handle = MdiChildHandle[8] then
        self.MDIChildren[I].Show;
  end;
end;

procedure TUPeditMainForm.N16Click(Sender: TObject);
var
  I: integer;
begin
  for I := 0 to self.MDIChildCount - 1 do
    if self.MDIChildren[I].Handle = MdiChildHandle[8] then
      self.MDIChildren[I].Show;
end;

procedure TUPeditMainForm.N17Click(Sender: TObject);
var
  Form86: TForm86;
  I: integer;
begin
  if CForm86 then
  begin
    CForm86 := false;
    Form86 := TForm86.Create(application);
    MdiChildHandle[9] := Form86.Handle;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if self.MDIChildren[I].Handle = MdiChildHandle[9] then
        self.MDIChildren[I].Show;
  end;
end;

procedure TUPeditMainForm.N18Click(Sender: TObject);
var
  I: integer;
begin
  for I := 0 to self.MDIChildCount - 1 do
    if self.MDIChildren[I].Handle = MdiChildHandle[9] then
      self.MDIChildren[I].Show;
end;

procedure TUPeditMainForm.N19Click(Sender: TObject);
begin
  Form87.ShowModal;
end;

procedure TUPeditMainForm.N1Click(Sender: TObject);
var
  form1: TForm1;
  I: integer;
begin
  if CForm1 then
  begin
    CForm1 := false;
    form1 := TForm1.Create(application);
    MdiChildHandle[2] := form1.Handle;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if self.MDIChildren[I].Handle = MdiChildHandle[2] then
        self.MDIChildren[I].Show;
  end;
end;

procedure TUPeditMainForm.N20Click(Sender: TObject);
var
  ini: Tinifile;
begin
  Panel1.Visible := not(Panel1.Visible);
  N20.Checked := Panel1.Visible;
  topcolumn := Panel1.Visible;
  try
    ini := Tinifile.Create(StartPath + iniFilename);
    ini.Writebool('run', 'topcolumn', topcolumn);
  finally
    ini.Free;
  end;
  FormResize(Sender);
end;

procedure TUPeditMainForm.N21Click(Sender: TObject);
var
  ini: Tinifile;
begin
  Panel2.Visible := not(Panel2.Visible);
  N21.Checked := Panel2.Visible;
  leftcolumn := Panel2.Visible;
  try
    ini := Tinifile.Create(StartPath + iniFilename);
    ini.Writebool('run', 'leftcolumn', leftcolumn);
  finally
    ini.Free;
  end;
  FormResize(Sender);
end;

procedure TUPeditMainForm.N22Click(Sender: TObject);
var
  Form89: TForm89;
  I: integer;
begin
  if CForm89 then
  begin
    CForm89 := false;
    Form89 := TForm89.Create(application);
    MdiChildHandle[10] := Form89.Handle;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if self.MDIChildren[I].Handle = MdiChildHandle[10] then
        self.MDIChildren[I].Show;
  end;
end;

procedure TUPeditMainForm.N23Click(Sender: TObject);
var
  I: integer;
begin
  for I := 0 to self.MDIChildCount - 1 do
    if self.MDIChildren[I].Handle = MdiChildHandle[10] then
      self.MDIChildren[I].Show;
end;

procedure TUPeditMainForm.N24Click(Sender: TObject);
begin
  halt(0);
end;

procedure TUPeditMainForm.N25Click(Sender: TObject);
begin

  self.Visible := true;
  // self.Show;
  Forms.application.Restore;
  if not Form87.Visible then
    Form87.ShowModal;

end;

procedure TUPeditMainForm.N28Click(Sender: TObject);
begin

  self.Visible := true;
  // self.Show;
  Forms.application.Restore;

  N2Click(Sender);
end;

procedure TUPeditMainForm.N29Click(Sender: TObject);
begin

  self.Visible := true;
  // self.Show;
  Forms.application.Restore;
  if not Form8.Visible then
    N5Click(Sender);
end;

procedure TUPeditMainForm.N2Click(Sender: TObject);
begin
  setpath;
end;

procedure TUPeditMainForm.setpath;
var
  dir: string;
  ini: Tinifile;
  filename: string;
  outdir: TArray<string>;
begin
  N28.Enabled := false;

  if SelectDirectory(gamepath, outdir) then
  begin
    gamepath := outdir[0];
    if gamepath[length(gamepath)] <> '\' then
      gamepath := gamepath + '\';

    MainForm.Caption := titlestr + ' - ' + gamepath;
    filename := StartPath + iniFilename;
    // gamepath := dir;
    ini := Tinifile.Create(filename);
    ini.WriteString('run', 'gamepath', gamepath);
    ini.Free;
    if readR(gamepath + Ridxfilename[0], gamepath + Rfilename[0], @useR) then
      calnamepos(@useR);
    readw(gamepath + wardata, @useW);
    readMcol;
  end;
  N28.Enabled := true;
end;

procedure TUPeditMainForm.N30Click(Sender: TObject);
begin
  self.Visible := true;
  Forms.application.Restore;
  if AboutBox.Visible = false then
    AboutBox.ShowModal;
end;

procedure TUPeditMainForm.N31Click(Sender: TObject);
var
  Form91: TForm91;
  I: integer;
begin
  if CForm91 then
  begin
    CForm91 := false;
    Form91 := TForm91.Create(application);
    MdiChildHandle[11] := Form91.Handle;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if self.MDIChildren[I].Handle = MdiChildHandle[11] then
        self.MDIChildren[I].Show;
  end;
end;

procedure TUPeditMainForm.N32Click(Sender: TObject);
var
  I: integer;
begin
  for I := 0 to self.MDIChildCount - 1 do
    if self.MDIChildren[I].Handle = MdiChildHandle[11] then
      self.MDIChildren[I].Show;
end;

procedure TUPeditMainForm.N33Click(Sender: TObject);
begin
  Form92.ShowModal;
end;

procedure TUPeditMainForm.N34Click(Sender: TObject);
begin
  self.Visible := true;
  // self.Show;
  Forms.application.Restore;
  if not Form92.Visible then
    Form92.ShowModal;
end;

procedure TUPeditMainForm.N4Click(Sender: TObject);
var
  Form7: TForm7;
  I: integer;
begin
  if CForm7 then
  begin
    CForm7 := false;
    Form7 := TForm7.Create(application);
    MdiChildHandle[1] := Form7.Handle;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if self.MDIChildren[I].Handle = MdiChildHandle[1] then
        self.MDIChildren[I].Show;
  end;
end;

procedure TUPeditMainForm.N5Click(Sender: TObject);
begin
  if talkcode = 1 then
    Form8.RadioGroup1.ItemIndex := 1
  else if talkcode = 2 then
    Form8.RadioGroup1.ItemIndex := 2
  else if talkcode = 3 then
    Form8.RadioGroup1.ItemIndex := 3
  else
    Form8.RadioGroup1.ItemIndex := 0;
  if datacode = 1 then
    Form8.RadioGroup2.ItemIndex := 1
  else if datacode = 2 then
    Form8.RadioGroup2.ItemIndex := 2
  else if datacode = 3 then
    Form8.RadioGroup2.ItemIndex := 3
  else
    Form8.RadioGroup2.ItemIndex := 0;
  if talkinvert = 1 then
    Form8.RadioGroup4.ItemIndex := 1
  else
    Form8.RadioGroup4.ItemIndex := 0;
  if checkupdate = 2 then
    Form8.RadioGroup3.ItemIndex := 1
  else if checkupdate = 1 then
    Form8.RadioGroup3.ItemIndex := 0
  else
    Form8.RadioGroup3.ItemIndex := 2;
  Form8.ShowModal;
end;

procedure TUPeditMainForm.N7Click(Sender: TObject);
var
  I: integer;
begin
  for I := 0 to self.MDIChildCount - 1 do
    if self.MDIChildren[I].Handle = MdiChildHandle[1] then
      self.MDIChildren[I].Show;
end;

procedure TUPeditMainForm.N8Click(Sender: TObject);
var
  I: integer;
begin
  for I := 0 to self.MDIChildCount - 1 do
    if self.MDIChildren[I].Handle = MdiChildHandle[2] then
      self.MDIChildren[I].Show;
end;

procedure TUPeditMainForm.N9Click(Sender: TObject);
var
  Form10: TForm10;
  I: integer;
begin
  if Cform10 then
  begin
    Form10 := TForm10.Create(application);
    Cform10 := false;
    MdiChildHandle[5] := Form10.Handle;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if self.MDIChildren[I].Handle = MdiChildHandle[5] then
        self.MDIChildren[I].Show;
  end;
end;

procedure TUPeditMainForm.pic1Click(Sender: TObject);
var
  Form4: TForm4;
  I: integer;
begin
  if CForm4 then
  begin
    Form4 := TForm4.Create(application);
    CForm4 := false;
    MdiChildHandle[4] := Form4.Handle;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if self.MDIChildren[I].Handle = MdiChildHandle[4] then
        self.MDIChildren[I].Show;
  end;
end;

procedure TUPeditMainForm.Pic2Click(Sender: TObject);
var
  I: integer;
begin
  for I := 0 to self.MDIChildCount - 1 do
    if self.MDIChildren[I].Handle = MdiChildHandle[4] then
      self.MDIChildren[I].Show;
end;

procedure TUPeditMainForm.PNG1Click(Sender: TObject);
var
  I: integer;
begin
  if CForm94 then
  begin
    CForm94 := false;
    Form94 := TForm94.Create(application);
    MdiChildHandle[12] := Form94.Handle;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if self.MDIChildren[I].Handle = MdiChildHandle[12] then
        self.MDIChildren[I].Show;
  end;
end;

procedure TUPeditMainForm.R1Click(Sender: TObject);
var
  Form5: TForm5;
  I: integer;
begin
  if CForm5 then
  begin
    CForm5 := false;
    Form5 := TForm5.Create(application);
    MdiChildHandle[0] := Form5.Handle;
  end
  else
  begin
    for I := 0 to self.MDIChildCount - 1 do
      if self.MDIChildren[I].Handle = MdiChildHandle[0] then
        self.MDIChildren[I].Show;
  end;
end;

procedure TUPeditMainForm.R2Click(Sender: TObject);
var
  I: integer;
begin
  for I := 0 to self.MDIChildCount - 1 do
    if self.MDIChildren[I].Handle = MdiChildHandle[0] then
      self.MDIChildren[I].Show;
end;

procedure TUPeditMainForm.TrayIcon1Click(Sender: TObject);
begin
  TrayIcon1DblClick(Sender);
end;

procedure TUPeditMainForm.TrayIcon1DblClick(Sender: TObject);
begin
  Forms.application.Restore;
  Forms.application.BringToFront;
  { if mainhide then
    begin
    mainhide := false;
    end
    else
    application.Restore; }
end;

procedure TUPeditMainForm.WebBrowser1NewWindow2(ASender: TObject; var ppDisp: IDispatch; var Cancel: WordBool);
begin
  // Cancel := true;
  // m_bNewWindow := true;
  ppDisp := WebBrowser2.DefaultInterface;
  // ShellExecute(Forms.Application.Handle, nil, PWidechar(webURL) , nil, nil, SW_SHOWNORMAL);
end;

procedure TUPeditMainForm.WebBrowser2BeforeNavigate2(ASender: TObject; const pDisp: IDispatch; var URL, Flags, TargetFrameName, PostData, Headers: OleVariant; var Cancel: WordBool);
begin
  Cancel := true;
  ShellExecute(Forms.application.Handle, nil, Pwidechar(widestring(URL)), nil, nil, SW_SHOWNORMAL);
end;

procedure TUPeditMainForm.AppOnMessage(var Msg: tagMSG; var Handled: Boolean);
var
  // FileName: String;
  filename: Array [0 .. 255] of char;
  num, I: integer;
  FormImz: TImzForm;
  Form91: TForm91;
  form1: TForm1;
  FOrm3: TForm3;
  Form4: TForm4;
  tempstr: Ansistring;
  opentempstr: string;

begin
  if IsChild(WebBrowser1.Handle, Msg.Hwnd) then
  begin
    if (Msg.Message = WM_RBUTTONDOWN) or (Msg.Message = WM_RBUTTONUP) then
    begin
      Handled := true;
      exit;
    end;
  end;

  case Msg.Message of
    WM_SYSCOMMAND:
      begin
        if Msg.wParam = WM_ABOUT then
        begin
          self.Visible := true;
          Forms.application.Restore;
          if AboutBox.Visible = false then
            AboutBox.ShowModal;
        end;
      end;
    WM_DropFiles:
      begin
        num := DragQueryFile(Msg.wParam, $FFFFFFFF, nil, 0);
        if num > 0 then
        begin
          DragQueryFile(Msg.wParam, 0, filename, 255);
          if fileexists(filename) then
          begin
            if SameText(ExtractFileExt(filename), '.pic') then
            begin
              if CForm4 then
              begin
                Form4 := TForm4.Create(application);
                CForm4 := false;
                MdiChildHandle[4] := Form4.Handle;
                Form4.openfile(filename);
                Form4.OpenDialog1.filename := filename;
              end
              else
              begin
                for I := 0 to self.MDIChildCount - 1 do
                  if self.MDIChildren[I].Handle = MdiChildHandle[4] then
                  begin
                    self.MDIChildren[I].Show;
                    Form4 := TForm4(self.MDIChildren[I]);

                    // form4 := PForm4(tempform)^;
                    Form4.openfile(filename);
                    Form4.OpenDialog1.filename := filename;
                    Break;
                  end;
              end;

            end
            else if SameText(ExtractFileExt(filename), '.txt') then
            begin
              if CForm91 then
              begin
                CForm91 := false;
                Form91 := TForm91.Create(application);

                MdiChildHandle[11] := Form91.Handle;
                Form91.Edit1.Text := filename;
                Form91.OpenDialog1.filename := filename;
              end
              else
              begin
                for I := 0 to self.MDIChildCount - 1 do
                  if self.MDIChildren[I].Handle = MdiChildHandle[11] then
                  begin
                    self.MDIChildren[I].Show;
                    Form91 := TForm91(self.MDIChildren[I]);
                    // Form91 := PForm91(tempform)^;
                    Form91.Edit1.Text := filename;
                    Form91.OpenDialog1.filename := filename;
                    Break;
                  end;
              end;
            end
            else if SameText(ExtractFileExt(filename), '.grp') then
            begin
              opentempstr := ChangeFileExt(filename, '.idx');
              if CForm3 then
              begin
                CForm3 := false;
                FOrm3 := TForm3.Create(application);
                FOrm3.WindowState := wsmaximized;
                MdiChildHandle[3] := FOrm3.Handle;
                FOrm3.Edit1.Text := opentempstr;
                FOrm3.Edit2.Text := filename;
                FOrm3.displaygrplist;
              end
              else
              begin
                for I := 0 to self.MDIChildCount - 1 do
                  if self.MDIChildren[I].Handle = MdiChildHandle[3] then
                  begin
                    self.MDIChildren[I].Show;
                    FOrm3 := TForm3(self.MDIChildren[I]);
                    // Form3 := PForm3(tempform)^;
                    FOrm3.Edit1.Text := opentempstr;
                    FOrm3.Edit2.Text := filename;
                    FOrm3.displaygrplist;
                    FOrm3.ComboBox1.ItemIndex := -1;
                    Break;
                  end;
              end;
            end
            else if SameText(ExtractFileExt(filename), '.idx') then
            begin
              opentempstr := ChangeFileExt(filename, '.grp');
              if CForm3 then
              begin
                CForm3 := false;
                FOrm3 := TForm3.Create(application);
                FOrm3.WindowState := wsmaximized;
                MdiChildHandle[3] := FOrm3.Handle;
                FOrm3.Edit1.Text := filename;
                FOrm3.Edit2.Text := opentempstr;
                FOrm3.displaygrplist;
              end
              else
              begin
                for I := 0 to self.MDIChildCount - 1 do
                  if self.MDIChildren[I].Handle = MdiChildHandle[3] then
                  begin
                    self.MDIChildren[I].Show;
                    FOrm3 := TForm3(self.MDIChildren[I]);
                    // Form3 := PForm3(tempform)^;
                    FOrm3.Edit1.Text := filename;
                    FOrm3.Edit2.Text := opentempstr;
                    FOrm3.displaygrplist;
                    FOrm3.ComboBox1.ItemIndex := -1;
                    Break;
                  end;
              end;
            end
            else if SameText(ExtractFileExt(filename), '.png') or SameText(ExtractFileExt(filename), '.jpg') or SameText(ExtractFileExt(filename), '.bmp') or SameText(ExtractFileExt(filename), '.gif')
              or SameText(ExtractFileExt(filename), '.jpeg') then
            begin
              if CForm1 then
              begin
                CForm1 := false;
                form1 := TForm1.Create(application);
                MdiChildHandle[2] := form1.Handle;
                picname := filename;
                form1.picdisplay;
              end
              else
              begin
                for I := 0 to self.MDIChildCount - 1 do
                  if self.MDIChildren[I].Handle = MdiChildHandle[2] then
                  begin
                    self.MDIChildren[I].Show;
                    form1 := TForm1(self.MDIChildren[I]);
                    // Form1 :=PForm1(tempform)^;
                    picname := filename;
                    form1.picdisplay;
                    Break;
                  end;
              end;
            end
            else if SameText(ExtractFileExt(filename), '.imz') then
            begin
              if CFormImz then
              begin
                CFormImz := false;
                FormImz := TImzForm.Create(application);
                FormImz.Edit2.Text := filename;
                FormImz.Button5.Click;
                MdiChildHandle[13] := FormImz.Handle;
              end
              else
              begin
                for I := 0 to self.MDIChildCount - 1 do
                  if self.MDIChildren[I].Handle = MdiChildHandle[13] then
                  begin
                    self.MDIChildren[I].Show;
                    FormImz := TImzForm(self.MDIChildren[I]);
                    FormImz.Edit2.Text := filename;
                    FormImz.SetEditMode(zImzMode);
                    FormImz.Button5.Click;
                    Break;
                  end;
              end;
            end;
          end;
        end;
      end;
  end;
end;

procedure TUPeditMainForm.BitBtn1Click(Sender: TObject);
var
  ini: Tinifile;
begin
  Panel2.Visible := not(Panel2.Visible);
  N21.Checked := Panel2.Visible;
  leftcolumn := Panel2.Visible;
  try
    ini := Tinifile.Create(StartPath + iniFilename);
    ini.Writebool('run', 'leftcolumn', leftcolumn);
  finally
    ini.Free;
  end;
  FormResize(Sender);
end;

procedure TUPeditMainForm.BitBtn2Click(Sender: TObject);
begin
  if Panel1.Visible then
    N20Click(Sender);
end;

procedure TUPeditMainForm.BitBtn3Click(Sender: TObject);
begin
  if Panel2.Visible then
    BitBtn1Click(Sender);
  BitBtn2Click(Sender);
end;

procedure TUPeditMainForm.bug1Click(Sender: TObject);
begin
  // ShellExecute(Forms.Application.Handle, nil, 'http://www.upwinded.com/bbs/forum.php' , nil, nil, SW_SHOWNORMAL);
end;

procedure TUPeditMainForm.bug2Click(Sender: TObject);
begin
  bug1Click(Sender);
end;

procedure TUPeditMainForm.Button1Click(Sender: TObject);
var
  temprs: TStringStream;
begin
  { try
    temprs := TStringStream.Create;


    //mainForm.idhttp1.Get('http://www.upwinded.com/upedit/news.txt', temprs);
    temprs.Position := 0;
    Label2.Caption := MultiToUnicode(temprs.Memory, 936);

    Webbrowser1.Refresh;
    except
    //Webbrowser1.Navigate('http://www.upwinded.com/upedit/upeditpage.html');
    end;
    temprs.Free; }
end;

procedure TUPeditMainForm.FileExit1Execute(Sender: TObject);
begin
  Close;
end;

procedure TUPeditMainForm.newthread;
begin
  MyThead := TMyThead.Create(false);
end;

procedure TMyThead.Execute;
var
  MYMD5, newVersionMD5: string;
  temprs: TStringStream;
begin
  freeonterminate := true;
  synchronize(UPcheckUpdate);
  MainForm.IdHTTP1 := TIdHTTP.Create(nil);
  temprs := TStringStream.Create;
  temprs.Clear;
  temprs.Position := 0;
  canlink := 0;
  { try
    mainForm.idhttp1.Get('http://www.upwinded.com/upedit/news.txt', temprs);
    canlink := 1;
    except

    canlink := -1;
    end; }
  temprs.Position := 0;
  // anoce := temprs.readString(temprs.Size);
  anoce := MultiToUnicode(temprs.Memory, 936);
  // anoce := temprs.ToString;
  // displayanoce;
  synchronize(displayanoce);
  synchronize(setwebbrowser);

  if checkupdate = 0 then
  begin
    temprs.Free;
    exit;
  end;
  temprs.Clear;
  temprs.Position := 0;
  // showmessage('http创建成功成功');
  { try
    mainForm.idhttp1.Get('http://www.upwinded.com/upedit/upversion.txt', temprs);
    except
    mainForm.idhttp1.Disconnect;
    if checkupdate = 1 then
    Synchronize(checkupdatefail);
    exit;
    end; }
  // showmessage('得到版本号成功');
  temprs.Position := 0;
  MYMD5 := hashmyself;
  newVersionMD5 := temprs.ReadString(length(MYMD5));
  temprs.Free;
  if CompareStr(MYMD5, newVersionMD5) <> 0 then
  begin
    // synchronize(ifupdate);
  end;
end;

procedure checkupdatefail;
begin
  showmessage('自动检测更新失败！如不需自动检测，请在“设置修改器配置”处取消。');
end;

procedure ifupdate;
begin
  if (MessageBox(application.Handle, '主程序有新版本！现在要更新吗？', '检测到更新', MB_OKCancel) = 1) then
  begin
    displayupdate;
  end;
end;

procedure displayupdate;
begin
  Form87.ShowModal;
end;

procedure setwebbrowser;
begin
  // mainForm.WebBrowser1.Navigate('http://www.upwinded.com/upedit/upeditpage.html');
end;

procedure UPcheckUpdate;
begin
  // showmessage('hash成功');
end;

procedure displayanoce;
begin
  MainForm.Label2.Caption := anoce;
end;

end.
