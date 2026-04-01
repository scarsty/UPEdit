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

begin
  Application.Title:='UPEdit - Upwinded Editor';
  Application.Initialize;
  CreateMainForm;
  Application.Run;
end.
