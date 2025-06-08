unit head;

interface

uses
  windows,Graphics,sysutils, inifiles,classes,IdHashMessageDigest,SyncObjs,ShlObj, PNGimage, math, Dialogs;

type

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

  //R文件结构record
  TRdatasingle = record
    datatype: smallint;
    datalen: integer;
    data: array of byte;
  end;

  PRdatasingle = ^TRdatasingle;

  TRarray = record
    incnum: smallint;
    dataarray: array of TRdatasingle; //成员
  end;

  TRdataline = record
    len: smallint;
    Rarray: array of TRarray;    //个数
  end;

  TRdata = record
    num: smallint;
    Rdataline: Array of TRdataline; //每个人物或物品、场景等包括的成员
  end;

  PRdata = ^TRdata;

  TRtype = record
    datanum: integer;
    namepos: integer;
    mappos: integer;
    Rdata: array of TRdata; //每种类型数据的多少个
  end;

  PRtype = ^TRtype;

  TRFile = record
    typenumber: integer;
    Rtype:array of TRtype;
  end;

  PRFile = ^TRFile;

  //R文件配置文件record
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

  PWFile = ^TWFile;

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

  //事件配置文件record
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

  //指令record
  Tattrib = record
    attribnum: smallint; //指令序号
    parcount: smallint;    //指令参数个数
    labelstatus: smallint;  //-2:无跳转，-1:label，>=0:跳转源
    labelway: smallint;     //1向下，-1向前
    labelfrom: smallint;
    labelto: smallint;
    par: array of smallint;
  end;

  //事件record
  Tevent = record
    attribamount: smallint;
    attrib: array of TAttrib;
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

  PeventData = ^TeventData;
  Pevent = ^Tevent;
  Pattrib = ^Tattrib;

  Teventcopy = Record
    copyevent: integer;
    copyattrib: integer; //-1没复制，1可复制
  End;

  TInstructGuideComboboxList = Record
    Value: integer;
    Str: String;
  end;

  TInstructGuideCombobox = Record
    ListAmount: integer;
    List: array of TInstructGuideComboboxList;
  end;

  TInstructGuideComboboxes = Record
    Amount: integer;
    Combobox: array of TInstructGuideCombobox;
  end;

  TInstructGuideParam = Record
    QuoteLabel: String;
    QuoteType: integer;
    QuoteCount: integer;
  end;

  TInstructGuideIterm = Record
    ParamAmount: integer;
    NeedGuide: integer;
    Param: array of TInstructGuideParam;
    GuideStr: String;
  end;

  TInstructGuide = Record
    Amount: integer;
    Instruct: array of TInstructGuideIterm;
  end;

  TDini = record
    num: integer;
    attrib:array of string;
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
    event1:smallint;
    event2:smallint;
    event3:smallint;
    beginpic1: smallint;
    endpic:smallint;
    beginpic2:smallint;
    picdelay: smallint;
    xpos:smallint;
    ypos:smallint;
  end;

  Tmapevent = record
    sceneevent: array[0..199] of Tsceneevent
  end;

  Pmapevent = ^Tmapevent;

  TDfile = record
    mapnum: integer;
    mapevent: Array of Tmapevent;
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

  PimzPNG = ^TimzPNG;

  Timz = record
    PNGnum: integer;
    imzPNG: array of TimzPng;
  end;

  Pimz = ^Timz;

  TScenePNGbuf = record
    width: integer;
    Height: integer;
    data: array of array of byte;
  end;

  PScenePNGbuf = ^TScenePNGBuf;

  TMapEditMode = (RLEMode, IMZMode, PNGMode);

  TPNGAlpha = record
    Width: integer;
    Height: integer;
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
  GRPlistSection : array of TGRPlistsection;

  fightgrpnum: integer;
  fightidx: string;
  fightgrp: string;
  fightname: string;

  checkupdate: integer;

  RFilenum: integer;
  Rfilename: array of string;
  Rfilenote: array of string;
  Ridxfilename: array of string;
  datacode: integer = 1;
  talkcode: integer = 1;
  talkinvert: integer = 0;  //等于0则需要取反
  language: integer;

  inicode: integer;
  talkidx, talkgrp:string;
  useR: TRfile;
  kdefidx,kdefgrp: string;
  nameidx,namegrp: string;
  //战斗数据配置文件
  useW: TWfile;
  Wini: Twini;
  Wtypedataitem: integer;
  wardata:string;
  headpicname: string;
  warmapgrp,warmapidx: string;
  WarMAPDefGRP,WarMAPDefidx: string;
  Mcollen: integer;
  McolR: array[0..255] of byte;
  McolB: array[0..255] of byte;
  McolG: array[0..255] of byte;
  Dfile: TDfile;

  Mmapfilegrp,Mmapfileidx:string;
  Mearth,Msurface,Mbuilding,Mbuildx,Mbuildy: string;

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
  CForm89: boolean = true;//苍炎头像
  CForm91: boolean = true;//剧本导入
  CForm94: Boolean = true;//PNG批量导入
  CFormImz: Boolean = true;//IMZ编辑

  DownloadUpdate: boolean = false;

  MdiChildHandle: array[0..20] of Cardinal;

  Smapidx,Smapgrp: string;

  Smapimz, Mmapimz, Wmapimz: string;

  SmapPNGpath, MmapPNGpath, WmapPNGpath: string;

  scenenum: integer;
  Sidx,Sgrp,Didx,Dgrp: array of string;
  Dini: TDini;

  processint: integer;

  Leave:string;
  Effect:string;
  Match:string;
  Exp:string;

  usualtrans: cardinal = $707030;

  appfirstrun: boolean;

  fmcursor : integer = 1;

  GameVersion : integer = 0;  //0, 原版； 1，水浒

const
  iniFileName: string = 'Upedit.ini';

function MultiToUnicode(str: PAnsiChar; codepage: integer): widestring;
function UnicodeToMulti(str: PWideChar; codepage: integer): Ansistring;
function readOutstr(str: Pointer; Len: integer): WideString;
function writeinstr(str: WideString; Data: Pointer; Len: integer): Pointer;
function TToS(mTraditional: string): string;
function SToT(mSimplified: string): string;
function displaystr(str: string): string;
function displaybackstr(str: string): string;
function displayname(str: string): string;
procedure readMcol;
procedure read50memory;
function hashMySelf: string;
function hashFile(Filename: String): string;
function calPNG(Pdata: Pbyte): integer;
function SelectFolderDialog(const Handle:integer;const Caption:string;const InitFolder:string;var SelectedFolder:string):boolean;
procedure WriteRDataStr(RDataSingle: PRDataSingle; data: widestring);
procedure WriteRDataInt(RDataSingle: PRDataSingle; data: int64);
function ReadRDataInt(RDataSingle: PRDataSingle): int64;
function ReadRDataStr(RDataSingle: PRDataSingle): widestring;

function ReadTalkStr(ATalkStr: PTalkStr): widestring;
procedure WriteTalkStr(ATalkStr: PTalkStr; Str: widestring);

implementation


function calPNG(Pdata: Pbyte): integer;
begin
  result := 0;
  if ((Pcardinal(Pdata))^ = $474E5089) and
    ((Pcardinal(Pdata + 4))^ = $0A1A0A0D) then
    result := 1;

end;

function MultiToUnicode(str: PAnsiChar; codepage: integer): widestring;
var
  len: integer;
begin
  //codepage：936简体，950繁体
  len := MultiByteToWideChar(codepage, 0, PAnsiChar(str), -1, nil, 0);
  setlength(result, len - 1);
  MultiByteToWideChar(codepage, 0, PAnsiChar(str), length(str), pwidechar(result), len + 1);
  //result := ' ' + result;
end;

//unicode转为多字节, 扩展

function UnicodeToMulti(str: PWideChar; codepage: integer): Ansistring;
var
  len: integer;
begin
  len := WideCharToMultiByte(codepage, 0, PWideChar(str), -1, nil, 0, nil, nil);
  setlength(result, len);
  WideCharToMultiByte(codepage, 0, PWideChar(str), -1, pAnsichar(result), len, nil, nil);
end;

function readOutstr(str: Pointer; Len: integer): Widestring;
var
  tempAnsiString: AnsiString;
  I: integer;
begin
  case datacode of
    0:
      begin
        if Len > 0 then
        begin
          setlength(tempAnsiString, Len + 1);
          tempAnsiString[Len + 1] := #0;
          copymemory(@tempAnsiString[1], str, Len);
          result := MultiToUnicode(PAnsiChar(@tempAnsiString[1]), 936);
        end
        else
          result := '';
      end;
    1:
      begin
        if Len > 0 then
        begin
          setlength(tempAnsiString, Len + 1);
          tempAnsiString[Len + 1] := #0;
          copymemory(@tempAnsiString[1], str, Len);
          result := MultiToUnicode(PAnsiChar(@tempAnsiString[1]), 950);
        end
        else
          result := '';
      end;
    3:
      begin
        if Len > 0 then
        begin
          setlength(tempAnsiString, Len + 1);
          tempAnsiString[Len + 1] := #0;
          copymemory(@tempAnsiString[1], str, Len);
          result := MultiToUnicode(PAnsiChar(@tempAnsiString[1]), 65001);
        end
        else
          result := '';
      end;
    else
      begin
        if Len >= sizeof(widechar) then
        begin
          setlength(result, Len div sizeof(widechar));// + 1);
          copymemory(@result[1], str, (Len div sizeof(widechar)) * sizeof(widechar));
          //result[Len div 2 + 1] := #0;
          for I := 1 to Len div sizeof(widechar) do
          begin
            if Result[I] = #0 then
            begin
              setlength(Result, I - 1);
              if I = 1 then
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

function writeinstr(str: WideString; Data: Pointer; Len: integer): Pointer;
var
  tempAnsistring: AnsiString;
  len1,i:integer;
function GB2Big(GB: string): string;
var
Len: Integer;
begin
Len := Length(GB);
SetLength(Result, Len);
LCMapString(GetUserDefaultLCID, LCMAP_TRADITIONAL_CHINESE, PChar(GB), Len, PChar(Result), Len);
end;
begin
  case datacode of
    0:
      begin
        tempAnsistring := UnicodeToMulti(Pwidechar(str), 936);
        Zeromemory(Data, Len);
        if length(tempAnsiString) > 0 then
          copymemory(Data, @tempAnsiString[1], min(length(tempAnsiString), Len));
      end;
    1:
      begin
        tempAnsistring := UnicodeToMulti(pwidechar(gb2big(Pwidechar(str))), 950);
        Zeromemory(Data, Len);
        if length(tempAnsiString) > 0 then
          copymemory(Data, @tempAnsiString[1], min(length(tempAnsiString), Len));
      end;
    3:
      begin
        tempAnsistring := UnicodeToMulti(pwidechar(str), 65001);
        Zeromemory(Data, Len);
        if length(tempAnsiString) > 0 then
          copymemory(Data, @tempAnsiString[1], min(length(tempAnsiString), Len));
      end;
    else
      begin
        Zeromemory(Data, Len);
        if length(str) > 0 then
          copymemory(Data, @str[1], min(length(str) * sizeof(widechar), Len));
      end;
  end;
  tempAnsiString := '';
  result := Data;
end;

function TToS(mTraditional: string): string;
var
  L: Integer;
begin
  L := Length(mTraditional);
  SetLength(Result, L);
  LCMapString(GetUserDefaultLCID,
    LCMAP_SIMPLIFIED_CHINESE, PChar(mTraditional), L, @Result[1], L);
end;

function SToT(mSimplified: string): string;
var
  L: Integer;
begin
  L := Length(mSimplified);
  SetLength(Result, L);
  LCMapString(GetUserDefaultLCID,
    LCMAP_TRADITIONAL_CHINESE, PChar(mSimplified), L, @Result[1], L);
end;

//简体操作，显示则判断语言类型
function displaystr(str: string): string;
begin
//  if (inicode <> 0) and (language = 1)  then
  //  str := Big5ToUnicode(PAnsiChar(AnsiString(str)), 936);
  {if (language = 1) then
    result := StoT(str)
  else if (language = 0) then
    result := TtoS(str)
  else
    result := str;}//UnicodeToBig5(Pwidechar(str));//StoT(str);//string(UnicodeToBig5(Pwidechar(widestring(str))));//GBtoBig5(Ansistring(str)); //StoT(widestring(str));//
  {if language = 1 then
    result := StoT(Str)
  else
    result := str;}
  result := str;
end;

function displayname(str: string): string;
begin
  result := displaystr(str);
end;

function displaybackstr(str: string): string;
begin
 // if (inicode <> 0) and (language = 1) then
  //  str := UnicodeToBig5(Pwidechar(str), 936);
  {if (datacode = 1) then
    result := StoT(str)
  else if (datacode = 0) then
    result := TtoS(str)
  else
    result := str; }//Big5ToUnicode(PAnsiChar(Ansistring(str)));//TtoS(str);//Big5toGB(Ansistring(str));//TtoS(widestring(str));//
  result := str;
end;

procedure readMcol;
var
  H,I,len: integer;
begin
  try
    McolLen := 256;
    H := FIleopen(gamepath + palette, fmopenread);
    len := fileseek(H, 0, 2);
    fileseek(H,0,0);
    for I := 0 to 256 - 1 do
    begin
      try
      fileread(H, McolR[I], 1);
      fileread(H, McolG[I], 1);
      fileread(H, McolB[I], 1);
      McolB[I] := McolB[I] shl 2;
      McolG[I] := McolG[I] shl 2;
      McolR[I] := McolR[I] shl 2;
      except
        McolB[I] :=0;
        McolG[I] := 0;
        McolR[I] := 0;
      end;
    end;
    fileclose(H);
  except
    exit;
  end;
end;

procedure read50memory;
var
  I,strnum: integer;
  ini: Tinifile;
  filename: string;
  strlist: Tstringlist;
  tempstr: string;
begin
  Filename := ExtractFilePath(Paramstr(0)) + 'UPedit.ini';
  ini := TIniFile.Create(filename);
  K50memorylist.num := ini.ReadInteger('50memory','memnum',0);
  setlength(K50memorylist.addr, K50memorylist.num);
  setlength(K50memorylist.note, K50memorylist.num);
  for I := 0 to K50memorylist.num - 1 do
  begin
    strlist := Tstringlist.create;
    tempstr := ini.ReadString('50memory','mem' + inttostr(I),'');
    strnum := ExtractStrings([' '], [], Pwidechar(tempstr), Strlist);
    if strnum = 2 then
    begin
      K50memorylist.addr[I] := strtoint('$' + strlist.Strings[0]);
      K50memorylist.note[I] := strlist.Strings[1];
    end
    else
    begin
      K50memorylist.addr[I] := 0;
      K50memorylist.note[I] := '';
    end;
    strlist.Free;
  end;
end;

function hashMySelf: string;
var
  MyMD5: TIdHashMessageDigest5;
  FileStream: TFileStream;
begin
  MyMD5:=TIdHashMessageDigest5.Create;
  FileStream := TFileStream.Create(Paramstr(0),fmOpenRead or fmSharedenyNone);
  Result:=MYMD5.HashStreamAsHex(FileStream);
  FileStream.Free;
  MyMD5.Free;
end;

function hashFile(Filename: String): string;
var
  MyMD5: TIdHashMessageDigest5;
  FileStream: TFileStream;
begin
  MyMD5:=TIdHashMessageDigest5.Create;
  FileStream := TFileStream.Create(Filename,fmOpenRead or fmSharedenyNone);
  Result:=MYMD5.HashStreamAsHex(FileStream);
  FileStream.Free;
  MyMD5.Free;
end;

function SelectFolderDialog(const Handle:integer;const Caption:string;const InitFolder:string;var SelectedFolder:string):boolean;
var
  BInfo: _browseinfoW;
  Buffer: array[0..MAX_PATH] of Char;
  ID: IShellFolder;
  Eaten, Attribute: Cardinal;
  ItemID: PItemidlist;
begin
  with BInfo do
  begin
    HwndOwner := Handle;
    lpfn := nil;
    lpszTitle := Pchar(Caption);
    ulFlags := BIF_RETURNONLYFSDIRS+BIF_NEWDIALOGSTYLE;
    SHGetDesktopFolder(ID);
    ID.ParseDisplayName(0,nil,'\',Eaten,ItemID,Attribute);
    pidlRoot := ItemID;
    GetMem(pszDisplayName, MAX_PATH);
  end;

  FreeMem(Binfo.pszDisplayName);
  if SHGetPathFromIDList(SHBrowseForFolder(BInfo),  Buffer) then
  begin
    SelectedFolder := Buffer;
    if Length(SelectedFolder)<>3 then
      SelectedFolder := SelectedFolder;
    result := True;
  end
  else begin
    SelectedFolder := '';
    result := False;
  end;

end;

procedure WriteRDataStr(RDataSingle: PRDataSingle; data: widestring);
var
  tempint: int64;
begin
  //
  if RDataSingle^.Datatype = 0 then
  begin
    tempint := strtoint(data);
    WriteRdataInt(RDataSingle, tempint);
  end
  else if RDataSingle^.Datatype = 1 then
  begin
    if RdataSingle.DataLen > 0 then
      WriteinStr(data, @RdataSingle.Data[0], RdataSingle.DataLen);
  end;
end;

procedure WriteRDataInt(RDataSingle: PRDataSingle; data: int64);
var
  I: integer;
begin
  if RDataSingle^.Datalen = 1 then
  begin
    RdataSingle.data[0] := shortint(data);
  end
  else if RDataSingle^.Datalen = 2 then
  begin
    PSmallint(@RdataSingle.data[0])^ := smallint(data);
  end
  else if RDataSingle^.Datalen = 4 then
  begin
    PInteger(@RdataSingle.data[0])^ := integer(data);
  end
  else if RDataSingle^.Datalen = 8 then
  begin
    PInt64(@RdataSingle.data[0])^ := data;
  end
  else if RDataSingle^.Datalen = 3 then
  begin
    PSmallint(@RdataSingle.data[0])^ := smallint(data);
    RdataSingle.data[2] := 0;
  end
  else if (RDataSingle^.Datalen = 5) or (RDataSingle^.Datalen = 6) or (RDataSingle^.Datalen = 7) then
  begin
    Pinteger(@RdataSingle.data[0])^ := integer(data);
    for I := 5 to RDataSingle^.Datalen do
    begin
      RdataSingle.data[I - 1] := 0;
    end;
  end
  else if RDataSingle^.Datalen > 8 then
  begin
    Pint64(@RdataSingle.data[0])^ := data;
    for I := 9 to RDataSingle^.Datalen do
    begin
      RdataSingle.data[I - 1] := 0;
    end;
  end;
end;

function ReadRDataInt(RDataSingle: PRDataSingle): int64;
begin
  result := 0;
  if RDataSingle^.Datalen = 1 then
  begin
    result := shortint(RdataSingle.data[0]);
  end
  else if (RDataSingle^.Datalen >= 2) and (RDataSingle^.Datalen < 4) then
  begin
    result := PSmallint(@RdataSingle.data[0])^
  end
  else if (RDataSingle^.Datalen >= 4) and (RDataSingle^.Datalen < 8) then
  begin
    result := PInteger(@RdataSingle.data[0])^;
  end
  else if RDataSingle^.Datalen >= 8 then
  begin
    result := PInt64(@RdataSingle.data[0])^;
  end
end;

function ReadRDataStr(RDataSingle: PRDataSingle): widestring;
begin
  result := '';
  if RDataSingle.Datatype = 0 then
  begin
    result := inttostr(ReadRDataInt(RDataSingle));
  end
  else if RDataSingle.Datatype = 1 then
  begin
    if RDataSingle.DataLen > 0 then
    begin
      result := readoutstr(@RDataSingle.Data[0], RDataSingle.DataLen);
    end
    else
      result := '';
  end;
end;

function ReadTalkStr(ATalkStr: PTalkStr): widestring;
var
  tempAnsiString: AnsiString;
  I: integer;
begin
  case talkcode of
    0:
      begin
        if ATalkStr.Len > 0 then
        begin
          setlength(tempAnsiString, ATalkStr.Len + 1);
          tempAnsiString[ATalkStr.Len + 1] := #0;
          copymemory(@tempAnsiString[1], @ATalkStr.str[0], ATalkStr.Len);
          result := MultiToUnicode(PAnsiChar(@tempAnsiString[1]), 936);
        end
        else
          result := '';
      end;
    1:
      begin
        if ATalkStr.Len > 0 then
        begin
          setlength(tempAnsiString, ATalkStr.Len + 1);
          tempAnsiString[ATalkStr.Len + 1] := #0;
          copymemory(@tempAnsiString[1], @ATalkStr.str[0], ATalkStr.Len);
          result := MultiToUnicode(PAnsiChar(@tempAnsiString[1]), 950);
        end
        else
          result := '';
      end;
    else
      begin
        if ATalkStr.Len >= sizeof(widechar) then
        begin
          setlength(result, ATalkStr.Len div sizeof(widechar));// + 1);
          //result[ATalkStr.Len div 2 + 1] := #0;
          copymemory(@Result[1], @ATalkStr.str[0], (ATalkStr.Len div sizeof(widechar)) * sizeof(widechar));
          for I := 1 to ATalkStr.Len div sizeof(widechar) do
          begin
            if Result[I] = #0 then
            begin
              setlength(Result, I - 1);
              if I = 1 then
              begin
                result := '';
              end;
              break;
            end;
          end;
          //Result[ATalkStr.Len div 2 + 1] := #0;
          //result := MultiToUnicode(PAnsiChar(@tempAnsiString[1]), 950);
        end
        else
          result := '';
      end;
  end;
  tempAnsiString := '';
end;

procedure WriteTalkStr(ATalkStr: PTalkStr; Str: widestring);
var
  tempAnsistring: AnsiString;
begin
  case talkcode of
    0:
      begin
        tempAnsistring := UnicodeToMulti(Pwidechar(str), 936);
        ATalkStr.len := max(length(tempAnsistring), 0);
        setlength(ATalkStr.str, ATalkStr.len);
        if ATalkStr.len > 0 then
          copymemory(@ATalkStr.str[0], @tempAnsiString[1], ATalkStr.len);
      end;
    1:
      begin
        tempAnsistring := UnicodeToMulti(Pwidechar(str), 950);
        ATalkStr.len := max(length(tempAnsistring), 0);
        setlength(ATalkStr.str, ATalkStr.len);
        if ATalkStr.len > 0 then
          copymemory(@ATalkStr.str[0], @tempAnsiString[1], ATalkStr.len);
      end;
    else
      begin
        ATalkStr.len := max(length(Str) * sizeof(WideChar), 0);
        setlength(ATalkStr.str, ATalkStr.len);
        if ATalkStr.len > 0 then
          copymemory(@ATalkStr.str[0], @Str[1], ATalkStr.len);
      end;
  end;
  tempAnsiString := '';
end;

end.
