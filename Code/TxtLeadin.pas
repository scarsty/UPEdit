unit TxtLeadin;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, lua, head, StdCtrls,math, shellAPI, ExtCtrls;

type

  Plua_state = Lua_state;

  TForm91 = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    OpenDialog1: TOpenDialog;
    Label3: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Label3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  PForm91 = ^TForm91;

procedure openScript(filename: string);
function ExecScript(filename, functionname: pansichar): integer;

function lua_GBKtoUnicode(L: lua_state): integer; cdecl;
function lua_BIG5toUnicode(L: lua_state): integer; cdecl;
function lua_UnicodetoGBK(L: lua_state): integer; cdecl;
function lua_UnicodetoBIG5(L: lua_state): integer; cdecl;

function lua_getRname(L: lua_state): integer; cdecl;
function lua_getRnamepos(L: lua_state): integer; cdecl;
function lua_getWname(L: lua_state): integer; cdecl;
function lua_getWnamepos(L: lua_state): integer; cdecl;

function lua_createbyte(L: lua_state): integer; cdecl;
function lua_getfilelen(L: lua_state): integer; cdecl;
function lua_loadfile(L: lua_state): integer; cdecl;
function lua_savefile(L: lua_state): integer; cdecl;

function lua_gettalkname(L: lua_state): integer; cdecl;
function lua_getkdefname(L: lua_state): integer; cdecl;
function lua_showmessage(L: lua_state): integer; cdecl;
function lua_showinteger(L: lua_state): integer; cdecl;

function Lua_getgamecode(L: lua_state): integer; cdecl;
function Lua_gettxtname(L: lua_state): integer; cdecl;

function lua_createdata(L: lua_state): integer; cdecl;
function lua_copydata(L: lua_state): integer; cdecl;

function lua_getU32(L: lua_state): integer; cdecl;
function lua_get32(L: lua_state): integer; cdecl;
function lua_getU16(L: lua_state): integer; cdecl;
function lua_get16(L: lua_state): integer; cdecl;
function lua_getU8(L: lua_state): integer; cdecl;
function lua_get8(L: lua_state): integer; cdecl;

function lua_setU32(L: lua_state): integer; cdecl;
function lua_set32(L: lua_state): integer; cdecl;
function lua_setU16(L: lua_state): integer; cdecl;
function lua_set16(L: lua_state): integer; cdecl;
function lua_setU8(L: lua_state): integer; cdecl;
function lua_set8(L: lua_state): integer; cdecl;

function lua_strlength(L: lua_state): integer; cdecl;
function lua_strsize(L: lua_state): integer; cdecl;
function lua_Ansistrsize(L: lua_state): integer; cdecl;
function lua_cmpdata(L: lua_state): integer; cdecl;

function lua_inttostr(L: lua_state): integer; cdecl;
function lua_strtoint(L: lua_state): integer; cdecl;

function Lua_getxor(L: lua_state): integer; cdecl;

var

  lua_script: lua_state;
  txtname: string;

implementation

uses Main;

{$R *.dfm}

procedure TForm91.Button1Click(Sender: TObject);
begin
  if opendialog1.Execute then
  begin
    edit1.Text := opendialog1.FileName;
  end;
end;

procedure TForm91.Button2Click(Sender: TObject);
begin
  txtname := edit1.Text;
  openscript(StartPath +'lua.txt');
end;

procedure TForm91.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CForm91 := true;
  action := cafree;
end;

procedure TForm91.FormCreate(Sender: TObject);
begin
  txtname := '';
end;

procedure TForm91.Label3Click(Sender: TObject);
begin
  ShellExecute(Application.Handle, nil, 'http://www.upwinded.com/bbs' , nil, nil, SW_SHOWNORMAL);
end;

procedure openScript(filename: string);
begin
  try
    loadlualib;
    lua_script := lua_open;
    //luaL_openlibs(lua_script);
    luaopen_base(Lua_script);
    luaopen_table(Lua_script);
    luaopen_math(Lua_script);
    luaopen_string(Lua_script);
    //luaopen_io(lua_script);
  except
    lua_close(lua_script);
    showmessage('加载lua出错！');
    exit;
  end;
  try

  Lua_register(lua_script,'GBKtoUnicode' ,lua_GBKtoUnicode);
  Lua_register(lua_script,'BIG5toUnicode' ,lua_BIG5toUnicode);
  Lua_register(lua_script,'UnicodetoGBK', lua_UnicodetoGBK);
  Lua_register(lua_script,'UnicodetoBIG5', lua_UnicodetoBIG5);

  Lua_register(lua_script,'getRname' , lua_getRname);
  Lua_register(lua_script,'getRnamepos' , lua_getRnamepos);
  Lua_register(lua_script,'getWname' , lua_getWname);
  Lua_register(lua_script,'getWnamepos' , lua_getWnamepos);

  Lua_register(lua_script,'createbyte' , lua_createbyte);
  Lua_register(lua_script,'createdata' , lua_createdata);
  Lua_register(lua_script,'copydata' , lua_copydata);

  Lua_register(lua_script,'getU32' , lua_getU32);
  Lua_register(lua_script,'get32' , lua_get32);
  Lua_register(lua_script,'getU16' , lua_getU16);
  Lua_register(lua_script,'get16' , lua_get16);
  Lua_register(lua_script,'getU8' , lua_getU8);
  Lua_register(lua_script,'get8' , lua_get8);

  Lua_register(lua_script,'setU32' , lua_setU32);
  Lua_register(lua_script,'set32' , lua_set32);
  Lua_register(lua_script,'setU16' , lua_setU16);
  Lua_register(lua_script,'set16' , lua_set16);
  Lua_register(lua_script,'set8' , lua_set8);

  Lua_register(lua_script,'strlength' , lua_strlength);
  Lua_register(lua_script,'strsize' , lua_strsize);
  Lua_register(lua_script,'Ansistrsize' , lua_Ansistrsize);
  Lua_register(lua_script,'cmpdata' , lua_cmpdata);

  Lua_register(lua_script,'getfilelen' , lua_getfilelen);
  Lua_register(lua_script,'loadfile' , lua_loadfile);
  Lua_register(lua_script,'savefile' , lua_savefile);

  Lua_register(lua_script,'gettalkname' , lua_gettalkname);
  Lua_register(lua_script,'getkdefname' , lua_getkdefname);
  Lua_register(lua_script,'showmessage' , lua_showmessage);
  Lua_register(lua_script,'showinteger' , lua_showinteger);

  Lua_register(lua_script,'getgamecode', Lua_getgamecode);
  Lua_register(lua_script,'gettxtname', Lua_gettxtname);
  Lua_register(lua_script,'inttostr', lua_inttostr);
  Lua_register(lua_script,'strtoint', lua_strtoint);

  Lua_register(lua_script,'getxor', Lua_getxor);

  except
    showmessage('注册函数失败！');
    lua_close(lua_script);
    exit;
  end;

  try
  //luaL_loadfile(lua_script,Pansichar(ansistring(filename)));
  //lua_pcall(lua_script, 0, LUA_MULTRET, 0);
  //lua_getglobal(lua_script,'TxtLeadIn');
  //lua_pcall(lua_script,0,1,0);
  ExecScript(Pansichar(ansistring(filename)), 'TXTLeadIn');
  except
    //showmessage('运行lua出错');
    on E: Exception do
      showmessage('UPedit提示错误信息：' + E.ClassName+ ': '+ E.Message);

  end;
  lua_close(lua_script);
end;

function ExecScript(filename,functionname: pansichar): integer;
var
  Script: ansistring;
  widescript: string;
  Data: string;
  h: integer;
  len: integer;
  //TXTstringstream: Tstringstream;
  luahead: word;
begin
  if fileexists(filename) then
  begin
    h := fileopen(filename, fmopenread);
    len := fileseek(h, 0, 2);


    fileseek(h, 0, 0);
    fileread(h,luahead,2);
    if luahead = $FEFF then
    begin
      fileseek(h,2,0);
      setlength(widescript, len div 2 - 1);
      fileread(h, widescript[1], sizeof(widechar)*length(widescript));
      script := Ansistring(widescript);
    end
    else
    begin
      fileseek(h,0,0);
      setlength(Script, len);
      fileread(h, Script[1], len);
    end;

    fileclose(h);
    //writeln(script);
    lual_loadbuffer(Lua_script, @script[1], length(script), 'code');
    //lual_loadbuffer(Lua_script, @Ansistring(TXTstringstream.DataString)[1], length(TXTstringstream.DataString) * sizeof(widechar), 'code');
    //lual_loadfile(Lua_script, filename);
    lua_pcall(Lua_script, 0, 0, 0);
    //lua_dofile(Lua_script,pchar(filename[1]));
    lua_getglobal(Lua_script, functionname);
    //lua_dostring(Lua_script,'f2()');
    result := lua_pcall(Lua_script, 0, 1, 0);
    //writeln(result);
  end;

end;


function lua_GBKtoUnicode(L: lua_state): integer; cdecl;
var
  P: ansistring;
  str: string;
  P2: pbyte;
begin
  P := lua_tostring(L, 1);
  str := MultitoUnicode(Pansichar(P), 936);
  P2 := lua_newuserdata(L, length(str)*sizeof(widechar) + 2);
  copymemory(P2, @str[1], length(str)*sizeof(widechar) + 2);
  result := 1;
end;

function lua_BIG5toUnicode(L: lua_state): integer; cdecl;
var
  P: ansistring;
  str: string;
  P2: pbyte;
begin
  P := lua_tostring(L, 1);
  str := MultitoUnicode(Pansichar(P),950);
  P2 := lua_newuserdata(L, (length(str) + 1)*sizeof(widechar));
  copymemory(P2, @str[1], (length(str) + 1)*sizeof(widechar));
  result := 1;
end;

function lua_UnicodetoGBK(L: lua_state): integer; cdecl;
var
  P: Pbyte;
  str: ansistring;
begin

  P := lua_touserdata(L, 1);
  str := UnicodetoMulti(Pwidechar(P),936);
  lua_pushstring(L, @str[1]);
  result := 1;
end;

function lua_UnicodetoBIG5(L: lua_state): integer; cdecl;
var
  P: Pbyte;
  str: ansistring;
begin

  P := lua_touserdata(L, 1);
  str := UnicodetoMulti(Pwidechar(P),950);
  lua_pushstring(L, @str[1]);
  result := 1;
end;

//取得R数据名称，第一个参数为类别（数字，从0开始），第二个参数为序号
function lua_getRname(L: lua_state): integer; cdecl;
var
  I: integer;
  str: Ansistring;
  index, datatype: integer;
begin

  datatype := floor(lua_tonumber(L, 1));
  index := floor(lua_tonumber(L, 2));

  if (index >= 0) and (index < useR.Rtype[datatype].datanum) and (useR.Rtype[datatype].namepos >= 0) then
    str := AnsiString(readRDatastr(@useR.Rtype[datatype].Rdata[index].Rdataline[useR.Rtype[datatype].namepos].Rarray[0].dataarray[0]))
  else
    str := '';
  if str <> '' then  
    for I := 1 to length(str) - 1 do
      if str[I + 1] = '' then
      begin
        setlength(str, I);
        break;
      end;

  lua_pushstring(L, @str[1]);
  result := 1;
end;

//得到一个名字在R数据里的位置，第一个参数为类别(数字，从0开始)，第二个为名称，返回序号
function lua_getRnamepos(L: lua_state): integer; cdecl;
var
  I, index, datatype: integer;
  tempstr: string;
  namestr: AnsiString;
  namewstr: widestring;
begin
  datatype := floor(lua_tonumber(L, 1));
  namestr := lua_toString(L, 2);
  index := -1;
  namewstr := WideString(namestr);
  if useR.Rtype[datatype].namepos < 0 then
  begin
    Lua_pushnumber(L, index);
    result := 1;
    exit;
  end;
  for I := 0 to useR.Rtype[datatype].datanum - 1 do
  begin
    tempstr := displaystr(readRDatastr(@useR.Rtype[datatype].Rdata[I].Rdataline[useR.Rtype[datatype].namepos].Rarray[0].dataarray[0]));
    //showmessage(tempstr + ' ' + readoutstr(namestr));
    if tempstr = namewstr then
    begin
      index := I;
      break;
    end;
  end;

  Lua_pushnumber(L, index);
  result := 1;

end;

//取得W数据名称，唯一一个参数为序号，返回名称
function lua_getWname(L: lua_state): integer; cdecl;
var
  I: integer;
  str: Ansistring;
  index: integer;
begin

  index := floor(lua_tonumber(L, 1));

  if (index >= 0) and (index < useW.Wtype.datanum) and (usew.Wtype.namepos >= 0) then
    str := AnsiString(readRDatastr(@useW.Wtype.Rdata[index].Rdataline[usew.Wtype.namepos].Rarray[0].dataarray[0]))
  else
    str := '';
  if str <> '' then
    for I := 1 to length(str) - 1 do
      if str[I + 1] = '' then
      begin
        setlength(str, I);
        break;
      end;

  lua_pushstring(L, @str[1]);
  result := 1;
end;

//得到一个名字在W数据里的位置，唯一的参数为名称，返回序号
function lua_getWnamepos(L: lua_state): integer; cdecl;
var
  I, index: integer;
  tempstr: string;
  namestr: Ansistring;
  namewstr: WideString;
begin
  namestr := lua_tostring(L, 1);
  index := -1;
  namewstr := widestring(namestr);
  if usew.Wtype.namepos < 0 then
  begin
    Lua_pushnumber(L, index);
    result := 1;
    exit;
  end;

  for I := 0 to useW.Wtype.datanum - 1 do
  begin
    tempstr := displaystr(readRDatastr(@useW.Wtype.Rdata[I].Rdataline[useW.Wtype.namepos].Rarray[0].dataarray[0]));
    if tempstr = namewstr then
    begin
      index := I;
      break;
    end;
  end;

  Lua_pushnumber(L, index);
  result := 1;

end;

//创建userdata
function lua_createbyte(L: lua_state): integer; cdecl;
var
  length, I: integer;
  P: Pbytearray;
begin
  length := floor(lua_tonumber(L,1));
  P := lua_newuserdata(L, length + 2);
  for I := 0 to length + 2 - 1 do
    P[I] := 0;
  result := 1;
end;

function lua_createdata(L: lua_state): integer; cdecl;
var
  Pori: Pbyte;
  P: Pbytearray;
  length,offset,I: integer;
begin
  Pori := lua_touserdata(L, 1);
  offset := floor(lua_tonumber(L, 2));
  length := floor(lua_tonumber(L, 3));
  P := lua_newuserdata(L, length + 2);
  for I := 0 to length - 1 do
    P[I] := (Pori + offset + I)^;
  P[length] := 0;
  P[length + 1] := 0;
  result := 1;
end;

function lua_getU32(L: lua_state): integer; cdecl;
var
  pori: Pbyte;
  offset: integer;
  output: cardinal;
begin
  Pori := lua_touserdata(L, 1);
  offset := floor(lua_tonumber(L,2));
  output := (Pcardinal(Pori + offset))^;
  lua_pushnumber(L, output);
  result := 1;
end;

function lua_get32(L: lua_state): integer; cdecl;
var
  pori: Pbyte;
  offset: integer;
  output: integer;
begin
  Pori := lua_touserdata(L, 1);
  offset := floor(lua_tonumber(L,2));
  output := (Pinteger(Pori + offset))^;
  lua_pushnumber(L, output);
  result := 1;
end;

function lua_getU16(L: lua_state): integer; cdecl;
var
  pori: Pbyte;
  offset: integer;
  output: word;
begin
  Pori := lua_touserdata(L, 1);
  offset := floor(lua_tonumber(L,2));
  output := (Pword(Pori + offset))^;
  lua_pushnumber(L, output);
  result := 1;
end;

function lua_get16(L: lua_state): integer; cdecl;
var
  pori: Pbyte;
  offset: integer;
  output: smallint;
begin
  Pori := lua_touserdata(L, 1);
  offset := floor(lua_tonumber(L,2));
  output := (Psmallint(Pori + offset))^;
  lua_pushnumber(L, output);
  result := 1;
end;

function lua_getU8(L: lua_state): integer; cdecl;
var
  pori: Pbyte;
  offset: integer;
  output: integer;
begin
  Pori := lua_touserdata(L, 1);
  offset := floor(lua_tonumber(L, 2));
  output := Pbyte(Pori + offset)^;
  lua_pushnumber(L, output);
  result := 1;
end;

function lua_get8(L: lua_state): integer; cdecl;
var
  pori: Pbyte;
  offset: integer;
  output: integer;
begin
  Pori := lua_touserdata(L, 1);
  offset := floor(lua_tonumber(L, 2));
  output := PShortint(Pori + offset)^;
  lua_pushnumber(L, output);
  result := 1;
end;

function lua_setU32(L: lua_state): integer; cdecl;
var
  Pori: Pbyte;
  offset: integer;
  output: cardinal;
begin
  Pori := lua_touserdata(L,1);
  offset := floor(lua_tonumber(L,2));
  output := floor(lua_tonumber(L,3));
  (Pcardinal(Pori + offset))^ := output;
  result := 0;
end;

function lua_set32(L: lua_state): integer; cdecl;
var
  Pori: Pbyte;
  offset: integer;
  output: integer;
begin
  Pori := lua_touserdata(L,1);
  offset := floor(lua_tonumber(L,2));
  output := floor(lua_tonumber(L,3));
  (Pinteger(Pori + offset))^ := output;
  result := 0;
end;

function lua_setU16(L: lua_state): integer; cdecl;
var
  Pori: Pbyte;
  offset: integer;
  output: word;
begin
  Pori := lua_touserdata(L,1);
  offset := floor(lua_tonumber(L,2));
  output := floor(lua_tonumber(L,3));
  (Pword(Pori + offset))^ := output;
  result := 0;
end;

function lua_set16(L: lua_state): integer; cdecl;
var
  Pori: Pbyte;
  offset: integer;
  output: smallint;
begin
  Pori := lua_touserdata(L,1);
  offset := floor(lua_tonumber(L,2));
  output := floor(lua_tonumber(L,3));
  (Psmallint(Pori + offset))^ := output;
  result := 0;
end;

function lua_setU8(L: lua_state): integer; cdecl;
var
  Pori: Pbyte;
  offset: integer;
  output: byte;
begin
  Pori := lua_touserdata(L,1);
  offset := floor(lua_tonumber(L,2));
  output := floor(lua_tonumber(L,3));
  (Pori + offset)^ := output;
  result := 0;
end;

function lua_set8(L: lua_state): integer; cdecl;
var
  Pori: Pbyte;
  offset: integer;
  output: Shortint;
begin
  Pori := lua_touserdata(L,1);
  offset := floor(lua_tonumber(L,2));
  output := floor(lua_tonumber(L,3));
  (Pori + offset)^ := output;
  result := 0;
end;

function lua_strlength(L: lua_state): integer; cdecl;
var
  Pstr: Pbyte;
  str: string;
  len: integer;
begin
  Pstr := lua_touserdata(L,1);
  str := widestring(Pwidechar(Pstr));
  len := length(str);
  lua_pushnumber(L, len);
  result := 1;
end;

function lua_strsize(L: lua_state): integer; cdecl;
var
  Pstr: Pbyte;
  str: string;
  len: integer;
begin
  Pstr := lua_touserdata(L,1);
  str := widestring(Pwidechar(Pstr));
  len := length(str) * sizeof(widechar);
  lua_pushnumber(L, len);
  result := 1;
end;

function lua_Ansistrsize(L: lua_state): integer; cdecl;
var
  str: Ansistring;
  len: integer;
begin
  str := lua_tostring(L,1);
  len := length(str);
  lua_pushnumber(L, len);
  result := 1;
end;

function lua_inttostr(L: lua_state): integer; cdecl;
var
  num: integer;
  str: WideString;
  P: Pbyte;
begin
  num := floor(lua_tonumber(L,1));
  str := inttostr(num);
  lua_pushstring(L, PAnsiChar(AnsiString(Str)));
  result := 1;
end;

function lua_strtoint(L: lua_state): integer; cdecl;
var
  num: integer;
  P: Pbyte;
begin
  P := lua_touserdata(L, 1);
  num := strtoint(widestring(Pwidechar(P)));
  lua_pushnumber(L, num);
  result := 1;
end;

function lua_cmpdata(L: lua_state): integer; cdecl;
var
  P1,p2: Pbyte;
  len, I, offset1, offset2, same: integer;
begin
   P1 :=  lua_touserdata(L, 1);
   offset1 := floor(lua_tonumber(L, 2));
   P2 :=  lua_touserdata(L, 3);
   offset2 := floor(lua_tonumber(L, 4));
   len :=  floor(lua_tonumber(L, 5));
   same := 0;
   for I := 0 to len - 1 do
     if (p1 + offset1 + I)^ <> (p2 + offset2 + I)^ then
       inc(same);
   lua_pushnumber(L,same);
   result := 1;
end;

function lua_copydata(L: lua_state): integer; cdecl;
var
  P1,p2: Pbyte;
  len, I, offset1, offset2, same: integer;
begin
   P1 :=  lua_touserdata(L, 1);
   offset1 := floor(lua_tonumber(L, 2));
   P2 :=  lua_touserdata(L, 3);
   offset2 := floor(lua_tonumber(L, 4));
   len :=  floor(lua_tonumber(L, 5));
   same := 0;
   for I := 0 to len - 1 do
     (p1 + offset1 + I)^ := (p2 + offset2 + I)^;
   result := 0;
end;

function lua_getfilelen(L: lua_state): integer; cdecl;
var
  len, H: integer;
  filename: Ansistring;
begin
  filename := lua_tostring(L,1);
  try
    H := fileopen(widestring(filename), fmopenreadwrite);
    len := fileseek(H, 0, 2);
    fileclose(H);
  except
    len := 0;
  end;
  lua_pushnumber(L, len);
  result := 1;
end;

//读取文件，一个参数为buffer，第二个文件名，第三个偏移，第4个长度
function lua_loadfile(L: lua_state): integer; cdecl;
var
  P: Pbyte;
  filename: ansistring;
  offset,length: integer;
  Fhandle : integer;
begin
  P := lua_touserdata(L,1);
  filename := lua_tostring(L,2);
  offset := floor(lua_tonumber(L,3));
  length := floor(lua_tonumber(L,4));
  Fhandle := fileopen(widestring(filename), fmopenread);
  fileseek(Fhandle, offset, 0);
  fileread(Fhandle, P^, length);
  fileclose(Fhandle);
  result := 0;
end;

//保存文件，一个参数为buffer，第二个文件名，第三个偏移，第4个长度
function lua_savefile(L: lua_state): integer; cdecl;
var
  P: Pbyte;
  filename: ansistring;
  offset,length: integer;
  Fhandle : integer;
begin
  P := lua_touserdata(L,1);
  filename := lua_tostring(L,2);
  offset := floor(lua_tonumber(L,3));
  length := floor(lua_tonumber(L,4));
  Fhandle := fileopen(widestring(filename), fmopenreadwrite);
  fileseek(Fhandle, offset, 0);
  filewrite(Fhandle, P^, length);
  fileclose(Fhandle);
  result := 0;
end;

//得到对话文件的文件名，先返回idx，再返回grp
function lua_gettalkname(L: lua_state): integer; cdecl;
var
  grpname, idxname: ansistring;
begin
  idxname := Ansistring(gamepath + talkidx);
  grpname := Ansistring(gamepath + talkgrp);
  lua_pushstring(L,@idxname[1]);
  lua_pushstring(L,@grpname[1]);
  result := 2;
end;

//事件文件名称
function lua_getkdefname(L: lua_state): integer; cdecl;
var
  grpname, idxname: ansistring;
begin
  idxname := Ansistring(gamepath + kdefidx);
  grpname := Ansistring(gamepath + kdefgrp);
  lua_pushstring(L, @idxname[1]);
  lua_pushstring(L, @grpname[1]);
  result := 2;
end;

//显示文字
function lua_showmessage(L: lua_state): integer; cdecl;
var
  str: Ansistring;
begin
  str := Lua_tostring(L, 1);
  showmessage(widestring(str));
  //writeln(widestring(str));
  result := 0;
end;

function lua_showinteger(L: lua_state): integer; cdecl;
var
  int: integer;
begin
  int := floor(Lua_tonumber(L, 1));
  showmessage(inttostr(int));
  //writeln(widestring(str));
  result := 0;
end;


function Lua_getgamecode(L: lua_state): integer; cdecl;
begin
  lua_pushnumber(L, datacode);
  result := 1;
end;

//返回剧本名字
function Lua_gettxtname(L: lua_state): integer; cdecl;
begin
  lua_pushstring(L, Pansichar(Ansistring(txtname)));
  result := 1;
end;

function Lua_getxor(L: lua_state): integer; cdecl;
var
  str: ansistring;
  I, len: integer;
  P, p2: Pbyte;
begin
  str := lua_tostring(L,1);
  P := @str[1];
  len := length(str);

  P2 := lua_newuserdata(L,len);
  for I := 0 to len - 1 do
    (P2 + I)^ := (P + I)^ xor $FF;
  result := 1;
end;

end.
