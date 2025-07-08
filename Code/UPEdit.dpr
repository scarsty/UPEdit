{
  Upwinded Editor(UPedit)
  An Editor--Special for All Heros in Kam Yung's Stories

  Created by Upwinded.L.
  ©2011 Upwinded.L. Some rights reserved.
}

{
  You can build it with delphi2010, with some parts supported by XLSreadwriteII.

  Anybody who gets this source code is able to modify or rebuild it anyway,
  but please keep this section when you want to spread a new version.

}

{
  你可以用delphi2010编译这些代码，其中一部分要用到XLSreadwriteII这个第三方控件。

  任何得到此代码的人都可以修改或者重新编译这段代码，但是请保留这段文字。
}

{ Upwinded.L.(281184040@qq.com), in 2011 April. }

program UPEdit;

// {$R UAC.res}

{$R *.RES}
{$R 'UPEditResource.res' 'UPEditResource.rc'}
// {$APPTYPE   CONSOLE}

uses
  Forms,
  windows,
  sysutils,
  classes,
  dialogs,
  inifiles,
  messages,
  SyncObjs,
  math,
  head in 'head.pas',
  Main in 'Main.pas' {MainForm},
  opendisplay in 'opendisplay.pas' {FlashForm},
  openprocess in 'openprocess.pas' {processForm},
  about in 'about.pas' {AboutBox},
  TAKEIN in 'TAKEIN.PAS' {Form1},
  grpedit in 'grpedit.pas' {Form2},
  grplist in 'grplist.pas' {Form3},
  picedit in 'picedit.pas' {Form4},
  Redit in 'Redit.pas' {Form5},
  Reditform in 'Reditform.pas' {Form6},
  KDEFedit in 'kdef\KDEFedit.pas' {Form7},
  setlanguage in 'setlanguage.pas' {Form8},
  newinstruct in 'kdef\newinstruct.pas' {Form9},
  WarEdit in 'WarEdit.pas' {Form10},
  WarMapEdit in 'WarMapEdit.pas' {Form11},
  SenceMapEdit in 'SenceMapEdit.pas' {Form12},
  MainMapEdit in 'MainMapEdit.pas' {Form13},
  Ict_1 in 'kdef\Ict_1.pas' {Form14},
  Ict_2 in 'kdef\Ict_2.pas' {Form15},
  Ict_3 in 'kdef\Ict_3.pas' {Form16},
  Ict_4 in 'kdef\Ict_4.pas' {Form17},
  Ict_5 in 'kdef\Ict_5.pas' {Form18},
  Ict_6 in 'kdef\Ict_6.pas' {Form19},
  Ict_8 in 'kdef\Ict_8.pas' {Form20},
  Ict_10 in 'kdef\Ict_10.pas' {Form21},
  Ict_16 in 'kdef\Ict_16.pas' {Form22},
  Ict_17 in 'kdef\Ict_17.pas' {Form23},
  Ict_19 in 'kdef\Ict_19.pas' {Form24},
  Ict_23 in 'kdef\Ict_23.pas' {Form25},
  Ict_25 in 'kdef\Ict_25.pas' {Form26},
  Ict_26 in 'kdef\Ict_26.pas' {Form27},
  Ict_27 in 'kdef\Ict_27.pas' {Form28},
  Ict_28 in 'kdef\Ict_28.pas' {Form29},
  Ict_31 in 'kdef\Ict_31.pas' {Form30},
  Ict_33 in 'kdef\Ict_33.pas' {Form31},
  ict_35 in 'kdef\ict_35.pas' {Form32},
  Ict_36 in 'kdef\Ict_36.pas' {Form33},
  Ict_37 in 'kdef\Ict_37.pas' {Form34},
  Ict_38 in 'kdef\Ict_38.pas' {Form35},
  Ict_41 in 'kdef\Ict_41.pas' {Form36},
  Ict_44 in 'kdef\Ict_44.pas' {Form37},
  Ict_68 in 'kdef\Ict_68.pas' {Form38},
  Ict_60 in 'kdef\Ict_60.pas' {Form39},
  Ict_69 in 'kdef\Ict_69.pas' {Form40},
  Ict_70 in 'kdef\Ict_70.pas' {Form41},
  ict_71 in 'kdef\ict_71.pas' {Form42},
  Ict_50_0 in 'kdef\Ict_50_0.pas' {Form43},
  New50Instruct in 'kdef\New50Instruct.pas' {Form44},
  Ict_50_1 in 'kdef\Ict_50_1.pas' {Form45},
  Ict_50_2 in 'kdef\Ict_50_2.pas' {Form46},
  Ict_50_3 in 'kdef\Ict_50_3.pas' {Form47},
  Ict_50_4 in 'kdef\Ict_50_4.pas' {Form48},
  Ict_50_8 in 'kdef\Ict_50_8.pas' {Form49},
  Ict_50_9 in 'kdef\Ict_50_9.pas' {Form50},
  Ict_50_10 in 'kdef\Ict_50_10.pas' {Form51},
  Ict_50_11 in 'kdef\Ict_50_11.pas' {Form52},
  Ict_50_12 in 'kdef\Ict_50_12.pas' {Form53},
  Ict_50_16 in 'kdef\Ict_50_16.pas' {Form54},
  Ict_50_17 in 'kdef\Ict_50_17.pas' {Form55},
  Ict_50_18 in 'kdef\Ict_50_18.pas' {Form56},
  Ict_50_19 in 'kdef\Ict_50_19.pas' {Form57},
  Ict_50_20 in 'kdef\Ict_50_20.pas' {Form58},
  Ict_50_21 in 'kdef\Ict_50_21.pas' {Form59},
  Ict_50_22 in 'kdef\Ict_50_22.pas' {Form60},
  Ict_50_23 in 'kdef\Ict_50_23.pas' {Form61},
  Ict_50_24 in 'kdef\Ict_50_24.pas' {Form62},
  Ict_50_25 in 'kdef\Ict_50_25.pas' {Form63},
  Ict_50_26 in 'kdef\Ict_50_26.pas' {Form64},
  Ict_50_27 in 'kdef\Ict_50_27.pas' {Form65},
  Ict_50_28 in 'kdef\Ict_50_28.pas' {Form66},
  Ict_50_29 in 'kdef\Ict_50_29.pas' {Form67},
  Ict_50_30 in 'kdef\Ict_50_30.pas' {Form68},
  Ict_50_31 in 'kdef\Ict_50_31.pas' {Form69},
  Ict_50_32 in 'kdef\Ict_50_32.pas' {Form70},
  Ict_50_33 in 'kdef\Ict_50_33.pas' {Form71},
  Ict_50_34 in 'kdef\Ict_50_34.pas' {Form72},
  Ict_50_35 in 'kdef\Ict_50_35.pas' {Form73},
  Ict_50_37 in 'kdef\Ict_50_37.pas' {Form74},
  Ict_50_38 in 'kdef\Ict_50_38.pas' {Form75},
  Ict_50_39 in 'kdef\Ict_50_39.pas' {Form76},
  Ict_50_40 in 'kdef\Ict_50_40.pas' {Form77},
  Ict_50_41 in 'kdef\Ict_50_41.pas' {Form78},
  Ict_50_42 in 'kdef\Ict_50_42.pas' {Form79},
  Ict_50_43 in 'kdef\Ict_50_43.pas' {Form80},
  Ict_50_44 in 'kdef\Ict_50_44.pas' {Form81},
  Ict_50_45 in 'kdef\Ict_50_45.pas' {Form82},
  Ict_50_46 in 'kdef\Ict_50_46.pas' {Form83},
  Ict_50_47 in 'kdef\Ict_50_47.pas' {Form84},
  Ict_50_48 in 'kdef\Ict_50_48.pas' {Form85},
  Replicatedlist in 'Replicatedlist.pas' {Form86},
  Update in 'Update.pas' {Form87},
  outputPNG in 'outputPNG.pas' {Form88},
  CYhead in 'CYhead.pas' {Form89},
  CYheadOutput in 'CYheadOutput.pas' {Form90},
  Lua in 'Lua.pas',
  TxtLeadin in 'TxtLeadin.pas' {Form91},
  FileRelation in 'FileRelation.pas' {Form92},
  outputMap in 'outputMap.pas' {Form93},
  mouse in 'mouse.pas',
  PNGimport in 'PNGimport.pas' {Form94},
  PNGimportModify in 'PNGimportModify.pas' {Form95},
  imagez in 'imagez.pas' {ImzForm},
  imzPNGedit in 'imzPNGedit.pas' {ImzPNGeditForm},
  ImzObject in 'ImzObject.pas',
  InstructGuide in 'kdef\InstructGuide.pas' {inctGuide},
  FightFrameForm in 'FightFrameForm.pas',
  xlsxio in 'xlsxio.pas';

procedure processon(Tfm: TComponentClass; var fm);
var
  processstr: string;
  tempprocess: integer;
  fntCol: byte;
  // alpha: byte;
  amp: msg;
const
  amount = 84;
begin
  try

    Application.CreateForm(Tfm, fm);
  // setclasslong(cardinal(fm), gcl_hcursor,fmcursor);
  except
    messagebox(Application.Handle, Pwidechar('创建第' + inttostr(processint + 1) + '个窗体失败了，可能是ini文件没有配置正确！'), '错误！', MB_OK);
  end;
  inc(processint);
  // FlashForm{.image1}.Canvas.CopyRect(FlashForm{.image1}.Canvas.ClipRect,opendisbmp.Canvas,opendisbmp.Canvas.ClipRect);
  tempprocess := Round(processint * 100 / amount);
  processstr := 'UPedit已载入' + inttostr(tempprocess) + '% ';
  fntCol := processint * 255 div amount;
  // alpha := processint * 255 div amount;
  processform.Label3.Caption := processstr;
  processform.Label2.Caption := processstr;
  processform.Label1.Caption := processstr;
  // processform.Label1.Font.Color := processform.Label1.Font.Color + 100 div amount * $10101;
  processform.Label2.Width := Round(tempprocess / 100 * processform.Label3.Width);
  processform.Label1.Width := Round(tempprocess / 100 * processform.Label3.Width);
  processform.Label2.Visible := true;
  processform.Label1.Visible := true;
  if tempprocess <> 100 then
    processform.Left := Screen.Width div 2 - processform.Label3.Width div 2;
  // FlashForm{.image1}.Canvas.TextOut(100, 100, processstr);
  FlashForm.SetFormAlpha(fntCol { alpha } );
  FlashForm.Refresh;
  processform.Refresh;
  while (PeekMessage(amp, Application.Handle, 0, 0, PM_REMOVE)) do
  begin
    // 消息转换
    TranslateMessage(amp);
    DispatchMessage(amp);
  end;
end;

var
  MutexHandle, FileMutexHandle: THandle;
  pramstr: widestring;
  openfilename: string;
  paramtempstr: string;
  Form4: TForm4;
  Form91: TForm91;
  Form1: TForm1;
  FOrm3: TForm3;
  FormImz: TImzForm;
  Appbuf: TCopyDataStruct;
  Appstr: Ansistring;
  Appchar: PAnsichar;
  Apph, formh: HWND;
  ini: Tinifile;
  teststr: Ansistring;

begin
  Application.Title := Appname + ' Opening';

  FileMutexHandle := 0;
  FileMutexHandle := CreateMutex(nil, true, Pwidechar('UPeditOpenFileMutex'));
  if (FileMutexHandle <> 0) and (GetLastError = ERROR_ALREADY_EXISTS) then
  begin
    if (paramcount > 0) and fileexists(paramstr(paramcount)) then
    begin
      formh := findwindow('TUPeditMainForm', nil { Pwidechar(Appname) } );
      if formh <> 0 then
      begin
        Apph := findwindow('TApplication', Pwidechar(Appname));

        Appstr := Ansistring(paramstr(paramcount));
        getmem(Appchar, 200);

        Appbuf.dwData := 200;
        Appbuf.cbData := 200;
        Appbuf.lpData := Appchar;
        strpcopy(Appchar, Appstr);
        if Apph <> 0 then
          if IsIconic(Apph) then
            OpenIcon(Apph);
        SetForegroundWindow(Apph);
        // SetForegroundWindow(GetLastActivePopup(Formh));
        // SetActiveWindow(Formh);
        sendmessage(formh, WM_COPYDATA, 0, integer(@Appbuf));

        CloseHandle(FileMutexHandle);
        halt;
      end;
    end;

  end;

  pramstr := 'UPEdit';
  pramstr := StartPath + pramstr;
  pramstr := StringReplace(pramstr, '\', '-', [rfReplaceAll]);
  pramstr := StringReplace(pramstr, ':', '', [rfReplaceAll]);
  MutexHandle := 0;
  MutexHandle := CreateMutex(nil, true, Pwidechar(pramstr));
  if (MutexHandle <> 0) and (GetLastError = ERROR_ALREADY_EXISTS) then
  begin
    if messagebox(Application.Handle, '检测到已经运行了同一路径下的UPEdit编辑器程序，是否要运行多个？', 'UPedit提示', MB_OKCANCEL) <> 1 then
    begin
      CloseHandle(MutexHandle);
      halt;
    end;
  end;

  Application.Initialize;

  Screen.Cursors[fmcursor] := GetResourceAsAniCursor('Resource_1');
  Screen.Cursor := fmcursor;

  FlashForm := TFlashForm.Create(Application);
  FlashForm.Top := Screen.Height div 2 - FlashFormHeight div 2;
  FlashForm.Left := Screen.Width div 2 - FlashFormWidth div 2;
  FlashForm.Show;
  FlashForm.Refresh;

  processform := TprocessForm.Create(Application);
  processform.Top := Screen.Height div 2 + FlashFormHeight div 2 - 20;
  processform.Left := Screen.Width div 2 - processform.Label3.Width div 2;
  processform.Show;

  SetForegroundWindow(Application.Handle);

  AppInitial;
  // sendmessage
  // GetModuleFileName
  // FindWindow

  processint := 0;
  processform.Label1.Font.Color := $F010E5;
  processform.Label2.Font.Color := $801095;
  processon(TUPeditMainForm, MainForm);

  // L := TCriticalSection.Create;
  // MultiReadExclusiveWriteSynchronizer := TMultiReadExclusiveWriteSynchronizer.Create;
  // InitializeCriticalSection(L);

  processon(TAboutBox, AboutBox);
  processon(TForm2, Form2);
  processon(TForm6, Form6);
  processon(TForm8, Form8);
  processon(TForm9, Form9);
  processon(TForm14, Form14);
  processon(TForm15, Form15);
  processon(TForm16, Form16);
  processon(TForm17, Form17);
  processon(TForm18, Form18);
  processon(TForm19, Form19);
  processon(TForm20, Form20);
  processon(TForm21, Form21);
  processon(TForm22, Form22);
  processon(TForm23, Form23);
  processon(TForm24, Form24);
  processon(TForm25, Form25);
  processon(TForm26, Form26);
  processon(TForm27, Form27);
  processon(TForm28, Form28);
  processon(TForm29, Form29);
  processon(TForm30, Form30);
  processon(TForm31, Form31);
  processon(TForm32, Form32);
  processon(TForm33, Form33);
  processon(TForm34, Form34);
  processon(TForm35, Form35);
  processon(TForm36, Form36);
  processon(TForm37, Form37);
  processon(TForm38, Form38);
  processon(TForm39, Form39);
  processon(TForm40, Form40);
  processon(TForm41, Form41);
  processon(TForm42, Form42);
  processon(TForm43, Form43);
  processon(TForm44, Form44);
  processon(TForm45, Form45);
  processon(TForm46, Form46);
  processon(TForm47, Form47);
  processon(TForm48, Form48);
  processon(TForm49, Form49);
  processon(TForm50, Form50);
  processon(TForm51, Form51);
  processon(TForm52, Form52);
  processon(TForm53, Form53);
  processon(TForm54, Form54);
  processon(TForm55, Form55);
  processon(TForm56, Form56);
  processon(TForm57, Form57);
  processon(TForm58, Form58);
  processon(TForm59, Form59);
  processon(TForm60, Form60);
  processon(TForm61, Form61);
  processon(TForm62, Form62);
  processon(TForm63, Form63);
  processon(TForm64, Form64);
  processon(TForm65, Form65);
  processon(TForm66, Form66);
  processon(TForm67, Form67);
  processon(TForm68, Form68);
  processon(TForm69, Form69);
  processon(TForm70, Form70);
  processon(TForm71, Form71);
  processon(TForm72, Form72);
  processon(TForm73, Form73);
  processon(TForm74, Form74);
  processon(TForm75, Form75);
  processon(TForm76, Form76);
  processon(TForm77, Form77);
  processon(TForm78, Form78);
  processon(TForm79, Form79);
  processon(TForm80, Form80);
  processon(TForm81, Form81);
  processon(TForm82, Form82);
  processon(TForm83, Form83);
  processon(TForm84, Form84);
  processon(TForm85, Form85);
  processon(TForm87, Form87);
  processon(TForm88, Form88);
  processon(TForm90, Form90);
  processon(TForm92, Form92);
  processon(TForm93, Form93);
  processon(TForm95, Form95);
  processon(TFightFrameForm, FightFrameForm1);

  processform.Visible := false;
  processform.Close;
  FlashForm.Visible := false;
  FlashForm.Close;

  MainForm.Show;
  MainForm.newthread;

  if paramcount > 0 then
  begin
    if fileexists(paramstr(paramcount)) then
    begin
      if SameText(ExtractFileExt(paramstr(paramcount)), '.pic') then
      begin
        CForm4 := false;
        Form4 := TForm4.Create(Application);
        MdiChildHandle[4] := Form4.Handle;
        Form4.openfile(paramstr(paramcount));
        Form4.OpenDialog1.FileName := paramstr(paramcount);
      end
      else if SameText(ExtractFileExt(paramstr(paramcount)), '.txt') then
      begin
        CForm91 := false;
        Form91 := TForm91.Create(Application);
        MdiChildHandle[11] := Form91.Handle;
        Form91.Edit1.Text := paramstr(paramcount);
        Form91.OpenDialog1.FileName := paramstr(paramcount);
      end
      else if SameText(ExtractFileExt(paramstr(paramcount)), '.grp') then
      begin
        paramtempstr := ChangeFileExt(paramstr(paramcount), '.idx');
        CFOrm3 := false;
        FOrm3 := TForm3.Create(Application);
        FOrm3.WindowState := wsmaximized;
        MdiChildHandle[3] := FOrm3.Handle;
        FOrm3.Edit1.Text := paramtempstr;
        FOrm3.Edit2.Text := paramstr(paramcount);
        FOrm3.displaygrplist;
      end
      else if SameText(ExtractFileExt(paramstr(paramcount)), '.idx') then
      begin
        paramtempstr := ChangeFileExt(paramstr(paramcount), '.grp');
        CFOrm3 := false;
        FOrm3 := TForm3.Create(Application);
        FOrm3.WindowState := wsmaximized;
        MdiChildHandle[3] := FOrm3.Handle;
        FOrm3.Edit1.Text := paramstr(paramcount);
        FOrm3.Edit2.Text := paramtempstr;
        FOrm3.displaygrplist;
      end
      else if SameText(ExtractFileExt(paramstr(paramcount)), '.png') or SameText(ExtractFileExt(paramstr(paramcount)), '.jpg') or SameText(ExtractFileExt(paramstr(paramcount)), '.bmp') or
        SameText(ExtractFileExt(paramstr(paramcount)), '.gif') or SameText(ExtractFileExt(paramstr(paramcount)), '.jpeg') then
      begin
        CForm1 := false;
        Form1 := TForm1.Create(Application);
        MdiChildHandle[2] := Form1.Handle;
        picname := paramstr(paramcount);
        Form1.picdisplay;
      end
      else if SameText(ExtractFileExt(paramstr(paramcount)), '.imz') then
      begin
        CFormImz := false;
        FormImz := TImzForm.Create(Application);
        FormImz.Edit2.Text := paramstr(paramcount);
        FormImz.Button5.Click;
        MdiChildHandle[13] := FormImz.Handle;
      end;
    end;
  end;

  if (gamepath = '') and (appfirstrun) then
  begin
    MainForm.setpath;
    appfirstrun := false;
    try
      ini := Tinifile.Create(StartPath + iniFileName);
      ini.WriteBool('run', 'firstrun', appfirstrun);
    finally
      ini.Free;
    end;
  end;

  Application.Run;

end.
