unit head;

{$modeswitch autoderef}

interface

uses
  windows, Graphics, sysutils, inifiles, classes, SyncObjs, ShlObj, math, Dialogs
  {$IFDEF FPC}, md5{$ENDIF}
  ;

type

  TPNGObject = class(TBitmap)
  private
    FAlpha: array of array of Byte;
    function GetAlphaScanline(Index: Integer): PByteArray;
  public
    procedure CreateAlpha;
    procedure Draw(ACanvas: TCanvas; const ARect: TRect);
    procedure LoadFromStream(Stream: TStream); override;
    property AlphaScanline[Index: Integer]: PByteArray read GetAlphaScanline;
  end;

  Tbmpdata = record
    pixelperbit: Tpixelformat;
    height: integer;
    width: integer;
    data: array of array of byte;
  end;

  Pbmpdata = ^Tbmpdata;

  Pntbitmap = ^Tbitmap;

  TPicdata = record
    pictype: integer;
    xs: integer;
    ys: integer;
    blackground: integer;
    datasize: integer;
    data: array of byte;
  end;

  // R 文件结构 record
  TRdatasingle = record
    datatype: smallint;
    datalen: integer;
    data: array of byte;
  end;

  PRdatasingle = ^TRdatasingle;

  TRarray = record
    incnum: smallint;
    dataarray: array of TRdatasingle; // 成员
  end;

  TRdataline = record
    len: smallint;
    Rarray: array of TRarray; // 数组
  end;

  TRdata = record
    num: smallint;
    Rdataline: array of TRdataline; // 每行数据包含多个数组成员
  end;

  PRdata = ^TRdata;

  TRtype = record
    datanum: integer;
    namepos: integer;
    mappos: integer;
    Rdata: array of TRdata; // 每种类型的数据集合
  end;

  PRtype = ^TRtype;

  TRFile = record
    typenumber: integer;
    Rtype: array of TRtype;
  end;

  PRFile = ^TRFile;

  // R 文件配置结构 record
  TRtermini = record
    datanum: smallint;
    incnum: smallint;
    datalen: smallint;
    isstr: smallint;
    isname: smallint;
    quote: smallint;
    name: string;
    note: string;
  end;

  TRini = record
    Rterm: array of TRtermini;
  end;

  TWfile = record
    Wtype: TRtype;
  end;

  PWFile = ^TWfile;

  TWtermini = record
    datanum: smallint;
    incnum: smallint;
    datalen: smallint;
    isstr: smallint;
    isname: smallint;
    quote: smallint;
    name: string;
    note: string;
    ismapnum: smallint;
    labeltype: smallint;
    labelnum: smallint;
  end;

  TWini = record
    Wterm: array of TWtermini;
  end;

  // 事件配置结构 record
  TKDEFitem = record
    index: smallint;
    paramount: smallint;
    ifjump: smallint;
    yesjump: smallint;
    nojump: smallint;
    note: string;
  end;

  TKDEFini = record
    KDEFnum: integer;
    KDEFitem: array of TKDEFitem;
    talkarrange: integer;
  end;

  // 指令 record
  Tattrib = record
    attribnum: smallint; // 指令编号
    parcount: smallint; // 指令参数个数
    labelstatus: smallint; // -2:相对跳转 -1:label 源 >=0:跳转目标
    labelway: smallint; // 1:向后，-1:向前
    labelfrom: smallint;
    labelto: smallint;
    par: array of smallint;
  end;

  // 事件 record
  Tevent = record
    attribamount: smallint;
    attrib: array of Tattrib;
  end;

  TEventData = record
    datalen: integer;
    data: array of byte;
  end;

  TTalkStr = record
    len: integer;
    str: array of byte;
  end;

  PTalkStr = ^TTalkStr;

  Tkdef50 = record
    num: integer;
    other: string;
    sub: array of string;
  end;

  PeventData = ^TEventData;
  Pevent = ^Tevent;
  Pattrib = ^Tattrib;

  Teventcopy = record
    copyevent: integer;
    copyattrib: integer; // -1 不可复制，1 可复制
  end;

  TInstructGuideComboboxList = record
    Value: integer;
    str: string;
  end;

  TInstructGuideCombobox = record
    ListAmount: integer;
    List: array of TInstructGuideComboboxList;
  end;

  TInstructGuideComboboxes = record
    Amount: integer;
    Combobox: array of TInstructGuideCombobox;
  end;

  TInstructGuideParam = record
    QuoteLabel: string;
    QuoteType: integer;
    QuoteCount: integer;
  end;

  TInstructGuideIterm = record
    ParamAmount: integer;
    NeedGuide: integer;
    Param: array of TInstructGuideParam;
    GuideStr: string;
  end;

  TInstructGuide = record
    Amount: integer;
    Instruct: array of TInstructGuideIterm;
  end;

  TDini = record
    num: integer;
    attrib: array of string;
  end;

  T50memorylist = record
    num: integer;
    addr: array of cardinal;
    note: array of string;
  end;

  Tselect = record
    pos1: smallint;
    pos2: smallint;
    pos3: smallint;
    name: string;
    quote: smallint;
    note: string;
  end;

  TWselect = record
    pos1: smallint;
    pos2: smallint;
    pos3: smallint;
    name: string;
    quote: smallint;
    note: string;
    ismap: smallint;
    labeltype: smallint;
    labelnum: smallint;
    labelcount: smallint;
  end;

  TWarpos = record
    personnum: integer;
    x: integer;
    y: integer;
  end;

  Tgrppic = record
    size: integer;
    data: array of byte;
  end;

  Tmaplayer = record
    pic: array of array of smallint;
  end;

  Tmap = record
    layernum: integer;
    x: integer;
    y: integer;
    maplayer: array of Tmaplayer;
  end;

  Tsceneevent = record
    canwalk: smallint;
    num: smallint;
    event1: smallint;
    event2: smallint;
    event3: smallint;
    beginpic1: smallint;
    endpic: smallint;
    beginpic2: smallint;
    picdelay: smallint;
    xpos: smallint;
    ypos: smallint;
  end;

  Tmapevent = record
    sceneevent: array [0 .. 199] of Tsceneevent end;

    Pmapevent = ^Tmapevent;

    TDfile = record mapnum: integer;
    mapevent: array of Tmapevent;
  end;

  TGRPlistSection = record
    num: integer;
    tag: array of string;
    beginnum: array of integer;
    endnum: array of integer;
  end;

  Tposition = record
    x: integer;
    y: integer;
  end;

  Tmapstruct = record
    num: integer;
    map: array of Tmap;
  end;

  Pmapstruct = ^Tmapstruct;

  Pmap = ^Tmap;

  Tlist = record
    num: integer;
    data: array of smallint;
  end;

  TPNGdata = record
    data: array of byte;
  end;

  TPNGbuf = record
    width: integer;
    height: integer;
    data: array of array of byte;
    alpha: array of array of byte;
  end;

  TimzPng = record
    len: integer;
    x: smallint;
    y: smallint;
    frame: integer;
    framelen: array of integer;
    framedata: array of TPNGdata;
    PNG: array of TPNGbuf;
  end;

  PimzPNG = ^TimzPng;

  Timz = record
    PNGnum: integer;
    imzPNG: array of TimzPng;
  end;

  Pimz = ^Timz;

  TScenePNGbuf = record
    width: integer;
    height: integer;
    data: array of array of byte;
  end;

  PScenePNGbuf = ^TScenePNGbuf;

  TMapEditMode = (RLEMode, PNGZipMode, PNGPathMode);

  TPNGAlpha = record
    width: integer;
    height: integer;
    Apha: integer;
  end;

  PPNGAlpha = ^TPNGAlpha;

var

  Updatepath: string;
  gamepath: string;
  palette: string;
  grplistnum: integer;
  grplistidx: array of string;
  grplistgrp: array of string;
  grplistname: array of string;
  GRPlistSection: array of TGRPlistSection;

  fightgrpnum: integer;
  fightidx: string;
  fightgrp: string;
  fightname: string;

  checkupdate: integer;

  RFilenum: integer;
  Rfilename: array of string;
  Rfilenote: array of string;
  Ridxfilename: array of string;
  datacode: integer = 1; // 0gbk,1big5,2utf16le,3utf8
  talkcode: integer = 1;
  talkinvert: integer = 0; // 非 0 表示需要取反
  language: integer;

  inicode: integer;
  list_begin_num: integer;
  talkidx, talkgrp: string;
  useR: TRFile;
  kdefidx, kdefgrp: string;
  nameidx, namegrp: string;
  // 战斗相关数据文件
  useW: TWfile;
  Wini: TWini;
  Wtypedataitem: integer;
  wardata: string;
  headpicname: string;
  warmapgrp, warmapidx: string;
  WarMAPDefGRP, WarMAPDefidx: string;
  Mcollen: integer;
  McolR: array [0 .. 255] of byte;
  McolB: array [0 .. 255] of byte;
  McolG: array [0 .. 255] of byte;
  Dfile: TDfile;

  Mmapfilegrp, Mmapfileidx: string;
  Mearth, Msurface, Mbuilding, Mbuildx, Mbuildy: string;

  K50memorylist: T50memorylist;

  CForm1: boolean = true;
  CFOrm3: boolean = true;
  CForm4: boolean = true;
  CForm5: boolean = true;
  CForm7: boolean = true;
  CForm10: boolean = true;
  CForm11: boolean = true;
  CForm12: boolean = true;
  CForm13: boolean = true;
  CForm86: boolean = true;
  CForm89: boolean = true; // 测试头像
  CForm91: boolean = true; // 脚本浏览
  CForm94: boolean = true; // PNG 批量导入
  CFormImz: boolean = true; // IMZ 编辑

  DownloadUpdate: boolean = false;

  MdiChildHandle: array [0 .. 20] of cardinal;

  Smapidx, Smapgrp: string;

  Smapimz, Mmapimz, Wmapimz: string;

  SmapPNGpath, MmapPNGpath, WmapPNGpath: string;

  scenenum: integer;
  Sidx, Sgrp, Didx, Dgrp: array of string;
  Dini: TDini;

  processint: integer;

  Leave: string;
  Effect: string;
  Match: string;
  Exp: string;

  usualtrans: cardinal = $707030;

  appfirstrun: boolean;

  fmcursor: integer = 1;

  GameVersion: integer = 0; // 0, 原版； 1，水浒

  StartPath: string;

  iniFileName: string = 'Upedit.ini';

function MultiToUnicode(str: PAnsiChar; codepage: integer): widestring;
function UnicodeToMulti(str: PWideChar; codepage: integer): Ansistring;
function UnicodeToMulti(const str: string; codepage: integer): Ansistring; overload;
function MultiToUtf8(str: PAnsiChar; codepagein, codepageout: integer): utf8string;
function readOutstr(str: Pointer; len: integer): widestring;
function writeinstr(str: widestring; data: Pointer; len: integer): Pointer;
function TToS(mTraditional: string): string;
function SToT(mSimplified: string): string;
function displaystr(str: string): string;
function displaybackstr(str: string): string;
function displayname(str: string): string;
procedure readMcol;
procedure read50memory;
function hashMySelf: string;
function hashFile(Filename: string): string;
function calPNG(Pdata: Pbyte): integer;
function SelectFolderDialog(const Handle: integer; const Caption: string; const InitFolder: string; var SelectedFolder: string): boolean;
procedure WriteRDataStr(RDataSingle: PRdatasingle; data: widestring);
procedure WriteRDataInt(RDataSingle: PRdatasingle; data: int64);
function ReadRDataInt(RDataSingle: PRdatasingle): int64;
function ReadRDataStr(RDataSingle: PRdatasingle): widestring;

function ReadTalkStr(ATalkStr: PTalkStr): widestring;
procedure WriteTalkStr(ATalkStr: PTalkStr; str: widestring);

function ReadFile(const filename: string): Ansistring;
procedure WriteFile(const filename: string; const data: Ansistring);

implementation

procedure TPNGObject.CreateAlpha;
var
  y: Integer;
begin
  SetLength(FAlpha, Height);
  for y := 0 to Height - 1 do
    SetLength(FAlpha[y], Width);
end;

function TPNGObject.GetAlphaScanline(Index: Integer): PByteArray;
begin
  if (Index < 0) or (Index >= Length(FAlpha)) or (Length(FAlpha[Index]) = 0) then
    Result := nil
  else
    Result := @FAlpha[Index][0];
end;

procedure TPNGObject.Draw(ACanvas: TCanvas; const ARect: TRect);
begin
  ACanvas.StretchDraw(ARect, Self);
end;

procedure TPNGObject.LoadFromStream(Stream: TStream);
var
  PNG: TPortableNetworkGraphic;
begin
  PNG := TPortableNetworkGraphic.Create;
  try
    PNG.LoadFromStream(Stream);
    Self.Assign(PNG);
  finally
    PNG.Free;
  end;
end;

function calPNG(Pdata: Pbyte): integer;
begin
  result := 0;
  if ((Pcardinal(Pdata))^ = $474E5089) and ((Pcardinal(Pdata + 4))^ = $0A1A0A0D) then
    result := 1;

end;

function MultiToUnicode(str: PAnsiChar; codepage: integer): widestring;
var
  len: integer;
begin
  // codepage: 936 简体，950 繁体
  len := MultiByteToWideChar(codepage, 0, PAnsiChar(str), -1, nil, 0);
  setlength(result, len - 1);
  MultiByteToWideChar(codepage, 0, PAnsiChar(str), length(str), PWideChar(result), len + 1);
  // result := ' ' + result;
end;

// Unicode 转为多字节，预留扩展
function UnicodeToMulti(str: PWideChar; codepage: integer): Ansistring;
var
  len: integer;
begin
  len := WideCharToMultiByte(codepage, 0, PWideChar(str), -1, nil, 0, nil, nil);
  setlength(result, len);
  WideCharToMultiByte(codepage, 0, PWideChar(str), -1, PAnsiChar(result), len, nil, nil);
end;

function UnicodeToMulti(const str: string; codepage: integer): Ansistring; overload;
begin
  result := UnicodeToMulti(PWideChar(UnicodeString(str)), codepage);
end;

function MultiToUtf8(str: PAnsiChar; codepagein, codepageout: integer): utf8string;
var
  temp: widestring;
begin
  temp := MultiToUnicode(str, codepagein);
  result := temp;
end;

function readOutstr(str: Pointer; len: integer): widestring;
var
  tempAnsiString: Ansistring;
  i: integer;
begin
  case datacode of
    0:
      begin
        if len > 0 then
        begin
          setlength(tempAnsiString, len + 1);
          tempAnsiString[len + 1] := #0;
          Move(str^, tempAnsiString[1], len);
          result := MultiToUnicode(PAnsiChar(@tempAnsiString[1]), 936);
        end
        else
          result := '';
      end;
    1:
      begin
        if len > 0 then
        begin
          setlength(tempAnsiString, len + 1);
          tempAnsiString[len + 1] := #0;
          Move(str^, tempAnsiString[1], len);
          result := MultiToUnicode(PAnsiChar(@tempAnsiString[1]), 950);
        end
        else
          result := '';
      end;
    3:
      begin
        if len > 0 then
        begin
          setlength(tempAnsiString, len + 1);
          tempAnsiString[len + 1] := #0;
          Move(str^, tempAnsiString[1], len);
          result := MultiToUnicode(PAnsiChar(@tempAnsiString[1]), 65001);
        end
        else
          result := '';
      end;
  else
    begin
      if len >= sizeof(widechar) then
      begin
        setlength(result, len div sizeof(widechar)); // + 1);
        Move(str^, result[1], (len div sizeof(widechar)) * sizeof(widechar));
        // result[Len div 2 + 1] := #0;
        for i := 1 to len div sizeof(widechar) do
        begin
          if result[i] = #0 then
          begin
            setlength(result, i - 1);
            if i = 1 then
            begin
              result := '';
            end;
            break;
          end;
        end;
      end
      else
        result := '';
    end;
  end;
  tempAnsiString := '';
end;

function writeinstr(str: widestring; data: Pointer; len: integer): Pointer;
var
  tempAnsiString: Ansistring;
  len1, i: integer;
  function GB2Big(GB: string): string;
  var
    len: integer;
  begin
    len := length(GB);
    setlength(result, len);
    {$IFDEF DELPHI}
    LCMapString(GetUserDefaultLCID, $08000000, PChar(GB), len, PChar(result), len);
    {$ELSE}
    result := GB;
    {$ENDIF}
  end;

begin
  case datacode of
    0:
      begin
        tempAnsiString := UnicodeToMulti(PWideChar(str), 936);
        if len > 0 then
          FillChar(data^, len, 0);
        if length(tempAnsiString) > 0 then
          Move(tempAnsiString[1], data^, min(length(tempAnsiString), len));
      end;
    1:
      begin
        tempAnsiString := UnicodeToMulti(PWideChar(str), 950);
        if len > 0 then
          FillChar(data^, len, 0);
        if length(tempAnsiString) > 0 then
          Move(tempAnsiString[1], data^, min(length(tempAnsiString), len));
      end;
    3:
      begin
        tempAnsiString := UnicodeToMulti(PWideChar(str), 65001);
        if len > 0 then
          FillChar(data^, len, 0);
        if length(tempAnsiString) > 0 then
          Move(tempAnsiString[1], data^, min(length(tempAnsiString), len));
      end;
  else
    begin
      if len > 0 then
        FillChar(data^, len, 0);
      if length(str) > 0 then
        Move(str[1], data^, min(length(str) * sizeof(widechar), len));
    end;
  end;
  tempAnsiString := '';
  result := data;
end;

function TToS(mTraditional: string): string;
var
  L: integer;
begin
  L := length(mTraditional);
  setlength(result, L);
  {$IFDEF DELPHI}
  LCMapString(GetUserDefaultLCID, $04000000, PChar(mTraditional), L, @result[1], L);
  {$ELSE}
  result := mTraditional;
  {$ENDIF}
end;

function SToT(mSimplified: string): string;
var
  L: integer;
begin
  L := length(mSimplified);
  setlength(result, L);
  {$IFDEF DELPHI}
  LCMapString(GetUserDefaultLCID, $08000000, PChar(mSimplified), L, @result[1], L);
  {$ELSE}
  result := mSimplified;
  {$ENDIF}
end;

// 统一字符串显示处理
function displaystr(str: string): string;
begin
  // if (inicode <> 0) and (language = 1)  then
  // str := Big5ToUnicode(PAnsiChar(AnsiString(str)), 936);
  { if (language = 1) then
    result := StoT(str)
    else if (language = 0) then
    result := TtoS(str)
    else
    result := str; }// UnicodeToBig5(Pwidechar(str));//StoT(str);//string(UnicodeToBig5(Pwidechar(widestring(str))));//GBtoBig5(Ansistring(str)); //StoT(widestring(str));//
  { if language = 1 then
    result := StoT(Str)
    else
    result := str; }
  result := str;
end;

function displayname(str: string): string;
begin
  result := displaystr(str);
end;

function displaybackstr(str: string): string;
begin
  // if (inicode <> 0) and (language = 1) then
  // str := UnicodeToBig5(Pwidechar(str), 936);
  { if (datacode = 1) then
    result := StoT(str)
    else if (datacode = 0) then
    result := TtoS(str)
    else
    result := str; }// Big5ToUnicode(PAnsiChar(Ansistring(str)));//TtoS(str);//Big5toGB(Ansistring(str));//TtoS(widestring(str));//
  result := str;
end;

procedure readMcol;
var
  H, i, len: integer;
begin
  try
    Mcollen := 256;
    H := FIleopen(gamepath + palette, fmopenread);
    len := fileseek(H, 0, 2);
    fileseek(H, 0, 0);
    for i := 0 to 256 - 1 do
    begin
      try
        fileread(H, McolR[i], 1);
        fileread(H, McolG[i], 1);
        fileread(H, McolB[i], 1);
        McolB[i] := McolB[i] shl 2;
        McolG[i] := McolG[i] shl 2;
        McolR[i] := McolR[i] shl 2;
      except
        McolB[i] := 0;
        McolG[i] := 0;
        McolR[i] := 0;
      end;
    end;
    fileclose(H);
  except
    exit;
  end;
end;

procedure read50memory;
var
  i, strnum: integer;
  ini: Tinifile;
  Filename: string;
  strlist: Tstringlist;
  tempstr: string;
begin
  Filename := ExtractFilePath(Paramstr(0)) + iniFileName;
  ini := Tinifile.Create(Filename);
  K50memorylist.num := ini.ReadInteger('50memory', 'memnum', 0);
  setlength(K50memorylist.addr, K50memorylist.num);
  setlength(K50memorylist.note, K50memorylist.num);
  for i := 0 to K50memorylist.num - 1 do
  begin
    strlist := Tstringlist.Create;
    tempstr := ini.ReadString('50memory', 'mem' + inttostr(i), '');
    strnum := ExtractStrings([' '], [], PChar(AnsiString(tempstr)), strlist);
    if strnum = 2 then
    begin
      K50memorylist.addr[i] := strtoint('$' + strlist.Strings[0]);
      K50memorylist.note[i] := strlist.Strings[1];
    end
    else
    begin
      K50memorylist.addr[i] := 0;
      K50memorylist.note[i] := '';
    end;
    strlist.Free;
  end;
end;

function hashMySelf: string;
var
  Digest: TMD5Digest;
begin
  {$IFDEF FPC}
  Digest := MD5File(Paramstr(0));
  result := MD5Print(Digest);
  {$ELSE}
  result := '';
  {$ENDIF}
end;

function hashFile(Filename: string): string;
var
  Digest: TMD5Digest;
begin
  {$IFDEF FPC}
  Digest := MD5File(Filename);
  result := MD5Print(Digest);
  {$ELSE}
  result := '';
  {$ENDIF}
end;

function SelectFolderDialog(const Handle: integer; const Caption: string; const InitFolder: string; var SelectedFolder: string): boolean;
begin
  SelectedFolder := InitFolder;
  Result := False;
end;

procedure WriteRDataStr(RDataSingle: PRdatasingle; data: widestring);
var
  tempint: int64;
begin
  //
  if RDataSingle.datatype = 0 then
  begin
    tempint := strtoint(data);
    WriteRDataInt(RDataSingle, tempint);
  end
  else if RDataSingle.datatype = 1 then
  begin
    if RDataSingle.datalen > 0 then
      writeinstr(data, @RDataSingle.data[0], RDataSingle.datalen);
  end;
end;

procedure WriteRDataInt(RDataSingle: PRdatasingle; data: int64);
var
  i: integer;
begin
  if RDataSingle.datalen = 1 then
  begin
    RDataSingle.data[0] := shortint(data);
  end
  else if RDataSingle.datalen = 2 then
  begin
    PSmallint(@RDataSingle.data[0])^ := smallint(data);
  end
  else if RDataSingle.datalen = 4 then
  begin
    PInteger(@RDataSingle.data[0])^ := integer(data);
  end
  else if RDataSingle.datalen = 8 then
  begin
    PInt64(@RDataSingle.data[0])^ := data;
  end
  else if RDataSingle.datalen = 3 then
  begin
    PSmallint(@RDataSingle.data[0])^ := smallint(data);
    RDataSingle.data[2] := 0;
  end
  else if (RDataSingle.datalen = 5) or (RDataSingle.datalen = 6) or (RDataSingle.datalen = 7) then
  begin
    PInteger(@RDataSingle.data[0])^ := integer(data);
    for i := 5 to RDataSingle.datalen do
    begin
      RDataSingle.data[i - 1] := 0;
    end;
  end
  else if RDataSingle.datalen > 8 then
  begin
    PInt64(@RDataSingle.data[0])^ := data;
    for i := 9 to RDataSingle.datalen do
    begin
      RDataSingle.data[i - 1] := 0;
    end;
  end;
end;

function ReadRDataInt(RDataSingle: PRdatasingle): int64;
begin
  result := 0;
  if RDataSingle.datalen = 1 then
  begin
    result := shortint(RDataSingle.data[0]);
  end
  else if (RDataSingle.datalen >= 2) and (RDataSingle.datalen < 4) then
  begin
    result := PSmallint(@RDataSingle.data[0])^
  end
  else if (RDataSingle.datalen >= 4) and (RDataSingle.datalen < 8) then
  begin
    result := PInteger(@RDataSingle.data[0])^;
  end
  else if RDataSingle.datalen >= 8 then
  begin
    result := PInt64(@RDataSingle.data[0])^;
  end
end;

function ReadRDataStr(RDataSingle: PRdatasingle): widestring;
begin
  result := '';
  if RDataSingle.datatype = 0 then
  begin
    result := inttostr(ReadRDataInt(RDataSingle));
  end
  else if RDataSingle.datatype = 1 then
  begin
    if RDataSingle.datalen > 0 then
    begin
      result := readOutstr(@RDataSingle.data[0], RDataSingle.datalen);
    end
    else
      result := '';
  end;
end;

function ReadTalkStr(ATalkStr: PTalkStr): widestring;
var
  tempAnsiString: Ansistring;
  i: integer;
begin
  case talkcode of
    0:
      begin
        if ATalkStr.len > 0 then
        begin
          setlength(tempAnsiString, ATalkStr.len + 1);
          tempAnsiString[ATalkStr.len + 1] := #0;
          Move(ATalkStr.str[0], tempAnsiString[1], ATalkStr.len);
          result := MultiToUnicode(PAnsiChar(@tempAnsiString[1]), 936);
        end
        else
          result := '';
      end;
    1:
      begin
        if ATalkStr.len > 0 then
        begin
          setlength(tempAnsiString, ATalkStr.len + 1);
          tempAnsiString[ATalkStr.len + 1] := #0;
          Move(ATalkStr.str[0], tempAnsiString[1], ATalkStr.len);
          result := MultiToUnicode(PAnsiChar(@tempAnsiString[1]), 950);
        end
        else
          result := '';
      end;
  else
    begin
      if ATalkStr.len >= sizeof(widechar) then
      begin
        setlength(result, ATalkStr.len div sizeof(widechar)); // + 1);
        // result[ATalkStr.Len div 2 + 1] := #0;
        Move(ATalkStr.str[0], result[1], (ATalkStr.len div sizeof(widechar)) * sizeof(widechar));
        for i := 1 to ATalkStr.len div sizeof(widechar) do
        begin
          if result[i] = #0 then
          begin
            setlength(result, i - 1);
            if i = 1 then
            begin
              result := '';
            end;
            break;
          end;
        end;
        // Result[ATalkStr.Len div 2 + 1] := #0;
        // result := MultiToUnicode(PAnsiChar(@tempAnsiString[1]), 950);
      end
      else
        result := '';
    end;
  end;
  tempAnsiString := '';
end;

procedure WriteTalkStr(ATalkStr: PTalkStr; str: widestring);
var
  tempAnsiString: Ansistring;
begin
  case talkcode of
    0:
      begin
        tempAnsiString := UnicodeToMulti(PWideChar(str), 936);
        ATalkStr.len := max(length(tempAnsiString), 0);
        setlength(ATalkStr.str, ATalkStr.len);
        if ATalkStr.len > 0 then
          Move(tempAnsiString[1], ATalkStr.str[0], ATalkStr.len);
      end;
    1:
      begin
        tempAnsiString := UnicodeToMulti(PWideChar(str), 950);
        ATalkStr.len := max(length(tempAnsiString), 0);
        setlength(ATalkStr.str, ATalkStr.len);
        if ATalkStr.len > 0 then
          Move(tempAnsiString[1], ATalkStr.str[0], ATalkStr.len);
      end;
  else
    begin
      ATalkStr.len := max(length(str) * sizeof(widechar), 0);
      setlength(ATalkStr.str, ATalkStr.len);
      if ATalkStr.len > 0 then
        Move(str[1], ATalkStr.str[0], ATalkStr.len);
    end;
  end;
  tempAnsiString := '';
end;

function ReadFile(const filename: string): Ansistring;
var
  H: integer;
  len: integer;
begin
  result := '';
  if not fileexists(filename) then
    exit;
  H := Fileopen(filename, fmopenread);
  if H < 0 then
    exit;
  len := fileseek(H, 0, 2);
  fileseek(H, 0, 0);
  if len > 0 then
  begin
    setlength(result, len);
    fileread(H, PAnsiChar(result)[0], len);
  end
  else
    result := '';
  fileclose(H);
end;  

procedure WriteFile(const filename: string; const data: Ansistring);
var
  H: integer;
begin
  H := Fileopen(filename, fmOpenWrite or fmShareDenyNone);
  if H < 0 then
    exit;
  fileseek(H, 0, 0);
  if length(data) > 0 then
    filewrite(H, PAnsiChar(data)[0], length(data));
  fileclose(H);
end;

end.









