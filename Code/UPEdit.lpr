program UPEdit;

{$codepage utf8}

{
  Upwinded Editor(UPedit)
  An Editor--Special for All Heros in Kam Yung's Stories

  Created by Upwinded.L.
  ©2011 Upwinded.L. Some rights reserved.

  Converted to Lazarus/LCL
}

{$mode delphi}{$H+}

uses
  {$IFDEF LCL}
  Interfaces, // this includes the LCL widgetset
  {$ENDIF}
  Forms,
  Windows,
  SysUtils,
  Classes,
  Dialogs,
  IniFiles,
  Messages,
  SyncObjs,
  Math,
  head,
  Main,
  openprocess,
  about,
  TAKEIN,
  grpedit,
  grplist,
  picedit,
  Redit,
  Reditform,
  setlanguage,
  WarEdit,
  WarMapEdit,
  SenceMapEdit,
  MainMapEdit,
  Replicatedlist,
  Update,
  outputPNG,
  CYhead,
  CYheadOutput,
  Lua,
  TxtLeadin,
  FileRelation,
  outputMap,
  mouse,
  PNGimport,
  PNGimportModify,
  imagez,
  imzPNGedit,
  ImzObject,
  FightFrameForm,
  xlsxio,
  libzip,
  SQLite3,
  SQLite3Utils,
  SQLite3Wrap;

// {$R *.res}
// {$R 'UPEditResource.res' 'UPEditResource.rc'}

procedure CreateMainForm;
begin
  Application.CreateForm(TUPeditMainForm, MainForm);
end;

type
  TAppExceptionLogger = class
    procedure HandleException(Sender: TObject; E: Exception);
  end;

var
  AppExceptionLogger: TAppExceptionLogger;

{$IFDEF WINDOWS}
function SetProcessDPIAware: BOOL; stdcall; external 'user32.dll' name 'SetProcessDPIAware';

procedure EnableHighDpiAwareness;
begin
  // 兼容 Lazarus/FPC：启用进程 DPI 感知，避免系统位图缩放导致整窗体发糊。
  SetProcessDPIAware;
end;
{$ENDIF}

procedure AppendRuntimeLog(const Msg: string);
var
  logPath: string;
  F: TextFile;
begin
  logPath := ExtractFilePath(ParamStr(0)) + 'upedit_runtime_error.log';
  AssignFile(F, logPath);
  if FileExists(logPath) then
    Append(F)
  else
    Rewrite(F);
  try
    Writeln(F, FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' | ' + Msg);
  finally
    CloseFile(F);
  end;
end;

procedure TAppExceptionLogger.HandleException(Sender: TObject; E: Exception);
begin
  AppendRuntimeLog(E.ClassName + ': ' + E.Message);
  MessageBox(0, PChar(E.ClassName + ': ' + E.Message), 'UPEdit Runtime Error', MB_ICONWARNING or MB_OK);
end;

begin
  Application.Title:='UPEdit - Upwinded Editor';
  {$IFDEF WINDOWS}
  EnableHighDpiAwareness;
  {$ENDIF}
  Application.Initialize;
  AppExceptionLogger := TAppExceptionLogger.Create;
  Application.OnException := AppExceptionLogger.HandleException;
  CreateMainForm;
  Application.Run;
  AppExceptionLogger.Free;
end.
