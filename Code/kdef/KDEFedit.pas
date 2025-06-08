unit KDEFedit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, head, StdCtrls, iniFiles, Menus, ExtCtrls, ComCtrls, math, InstructGuide;

type
  TForm7 = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    ListBox1: TListBox;
    ComboBox2: TComboBox;
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Edit2: TEdit;
    Button4: TButton;
    ComboBox1: TComboBox;
    Button5: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    Button11: TButton;
    Button12: TButton;
    Button13: TButton;
    ListBox2: TListBox;
    Button15: TButton;
    Button16: TButton;
    Memo1: TMemo;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    Button14: TButton;
    Button17: TButton;
    Button18: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Button6: TButton;
    SaveDialog1: TSaveDialog;
    Button7: TButton;
    N6: TMenuItem;
    N7: TMenuItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button9Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure arrangetalktocombobox;
    function readtalk: Boolean;
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ComboBox1Select(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure savetalk;
    
    procedure Button8Click(Sender: TObject);
    function readkdefini: boolean;
    function readkdef: boolean;
    procedure arrangeKdef;
    procedure calevent(noworievent, nowevent: Pevent);
    procedure calKdef(noworievent, nowevent: Pevent);
    procedure ComboBox2Select(Sender: TObject);
    procedure displayevent;
    procedure Button12Click(Sender: TObject);
    procedure Button13Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure ListBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ListBox1Click(Sender: TObject);
    procedure Button14Click(Sender: TObject);
    procedure ListBox2DblClick(Sender: TObject);
    procedure Button15Click(Sender: TObject);
    procedure Button16Click(Sender: TObject);
    procedure Button17Click(Sender: TObject);
    procedure Button18Click(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    function EditIct(atrb:Pattrib): integer;
    function InstructGuide(atrb:Pattrib): integer;
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure N7Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    
  end;

var
  Kevent: array of TeventData;
  nowevent, noworievent, copyent, copyatrbent: Tevent;
  nowattrib: Tattrib;
  eventamount, noweventnum: integer;
  talkstr: array of Ttalkstr;
  talkstrnum: integer;
  InstructGuideini: TInstructGuide; //通用指令制导配置
  InstructGuideComboboxini: TInstructGuideComboboxes;
  KDEFini : TKDEFini;
  KDEF50: Tkdef50;
  labelnum: integer;
  eventcopy: Teventcopy;
  lastevent: integer;
  namestr:array of Ttalkstr;
  namestrnum: integer;

procedure Copyattrib(dest,source:Pattrib);
procedure Copyevent(dest,source:Pevent);
procedure clearIct(Ict: Pattrib);
procedure Addattrib(ent: Pevent; atrb: Pattrib; num: integer);
procedure AddIct(ent: Pevent; atrb: Pattrib; num: integer);
function calRname(datatype, index: integer): widestring;
function calattribname(atrb: Pattrib):widestring;
function CalInstructGuideName(atrb: Pattrib): widestring;
function GetInstructNeedGuide(atrb: Pattrib): Boolean;
function CalInstructGuideParamName(atrb: Pattrib; param: integer): widestring;
procedure deleteatrb(ent: Pevent; num: integer);
procedure saveevent(destent,sourceent:Pevent);
procedure SaveEventtoData(destent: Peventdata; sourceent:Pevent);
procedure SaveDataToEvent(destent: Pevent; sourceent:Peventdata);
function calWname(index: integer): widestring;
procedure readname;
function cutstr(str:widestring): widestring;
function E_getstr(bit,t,x: smallint): widestring;

implementation

{$R *.dfm}

uses
  Redit, newinstruct,waredit, Main, Ict_1,Ict_2, Ict_3,Ict_4,ict_5, ict_6,ict_8, ict_10,
  ict_16, ICt_17, ICT_19, ICT_23, ict_25, ict_26, ict_27, ict_28, ict_31,ict_33, ict_35,
  Ict_36, Ict_37, ict_38, ict_41, Ict_44, ict_60,ict_68, ict_69, ict_70,ict_71, Ict_50_0
  , new50instruct, Ict_50_1, Ict_50_2, Ict_50_3, Ict_50_4, ict_50_8, Ict_50_9, Ict_50_10
  , Ict_50_11, ict_50_12, Ict_50_16, Ict_50_17, Ict_50_18, Ict_50_19, Ict_50_20, Ict_50_21
  , ICT_50_22, Ict_50_23, Ict_50_24, Ict_50_25, Ict_50_26, Ict_50_27, Ict_50_28, Ict_50_29
  , Ict_50_30, Ict_50_31, Ict_50_32, Ict_50_33, Ict_50_34, Ict_50_35, ict_50_37, ict_50_38
  , Ict_50_39, Ict_50_40, Ict_50_41, Ict_50_42, Ict_50_43, Ict_50_44, Ict_50_45, Ict_50_46,
  Ict_50_47, Ict_50_48;

procedure TForm7.Button10Click(Sender: TObject);
var
  tempattrib: Tattrib;
  tempatrbnum, I, temp, temppos: integer;
  tempstr: widestring;
begin
  temppos := 0;
  FOrm9.RadioGroup1.Visible := false;
  Form9.RadioGroup2.Visible := false;
  Form9.RadioGroup1.ItemIndex := 0;
  Form9.RadioGroup2.ItemIndex := 0;
  Form9.ListBox1.Clear;
  Form9.ListBox1.Items.Add('-1(FFFF):事件结束');
  for I := 0 to kdefini.KDEFnum - 1 do
  begin
    temp := kdefini.KDEFitem[I].index;
    tempstr := inttostr(I) + '(' + Format('%x', [temp and $FFFF])+ '):';
    if kdefini.KDEFitem[I].note = '' then
      tempstr := tempstr + '未知指令'
    else
      tempstr := tempstr + displayname(kdefini.KDEFitem[I].note);
    FOrm9.ListBox1.Items.Add(tempstr);
  end;
  Form9.ListBox1.ItemIndex := 0;
  if Form9.ShowModal = mrOK then
  begin
    listbox2.Clear;
    if listbox1.ItemIndex < 0 then
      listbox1.ItemIndex := 0;
    tempattrib.attribnum := Form9.ListBox1.ItemIndex - 1;
    if tempattrib.attribnum >= 0 then
    begin
      tempattrib.parcount := kdefini.KDEFitem[ tempattrib.attribnum].paramount;
      setlength(tempattrib.par, tempattrib.parcount);
      for I := 0 to tempattrib.parcount - 1 do
      begin
        tempattrib.par[I] := 0;
      end;
      tempattrib.par[0] := tempattrib.attribnum;
      tempattrib.labelstatus := -2;
      if (kdefini.KDEFitem[ tempattrib.attribnum].ifjump = 1) then
      begin
        inc(labelnum);
        tempattrib.labelstatus := labelnum;
        if Form9.RadioGroup2.ItemIndex = 0 then
        begin
          if Form9.RadioGroup1.ItemIndex = 0 then
          begin
            tempattrib.labelway := 1;
           // tempattrib.par[kdefini.KDEFitem[tempattrib.attribnum].yesjump] :=
          end
          else
            tempattrib.labelway := -1;
        end
        else
        begin
          temppos := 1;
          if Form9.RadioGroup1.ItemIndex = 0 then
          begin
            tempattrib.labelway := 1;
            tempattrib.par[kdefini.KDEFitem[tempattrib.attribnum].yesjump] := -tempattrib.parcount;
          end
          else
          begin
            tempattrib.par[kdefini.KDEFitem[tempattrib.attribnum].Nojump] := -tempattrib.parcount;
            tempattrib.labelway := -1;
          end;
        end;
      end;
    end
    else
    begin
      tempattrib.parcount := 1;
      tempattrib.labelstatus := -2;
      setlength(tempattrib.par, 1);
      tempattrib.par[0] := tempattrib.attribnum;
    end;
    addIct(@nowevent,@tempattrib,listbox1.ItemIndex);
    temppos := temppos +listbox1.ItemIndex;
    displayevent;
    listbox1.Selected[temppos] := true;
    listbox1.ItemIndex := temppos;
    editIct(@nowevent.attrib[temppos]);
    displayevent;
    listbox1.Selected[temppos] := true;
    listbox1.ItemIndex := temppos;
    ListBox1Click(Sender);
  end;
end;

procedure TForm7.Button11Click(Sender: TObject);
var
  I: integer;
begin
  if nowevent.attribamount = 1 then
    showmessage('只剩一个指令，无法删除！')
  else if (listbox1.ItemIndex >= 0) and (nowevent.attrib[listbox1.ItemIndex].labelstatus <> -1) and (MessageBox(Self.Handle, Pwidechar(widestring('确实要删除指令:' + listbox1.Items.Strings[listbox1.ItemIndex] + ' 吗？')),  '删除指令', MB_OKCANCEL) = 1) then
  begin
    deleteatrb(@nowevent,listbox1.ItemIndex);
    saveeventtoData(@Kevent[combobox2.ItemIndex], @nowevent);
    savedatatoevent(@noworievent, @kevent[combobox2.ItemIndex]);
    //calkdef(@noworievent, @nowevent);
    calevent(@noworievent, @nowevent);
    displayevent;
    listbox2.Clear;
  end
  else if (listbox1.ItemIndex >= 0) and (nowevent.attrib[listbox1.ItemIndex].labelstatus = -1) then
  begin
    for I := 0 to nowevent.attribamount - 1 do
      if nowevent.attrib[listbox1.ItemIndex].labelfrom = nowevent.attrib[I].labelstatus then
        break;
    if (MessageBox(Self.Handle, Pwidechar(widestring('确实要删除指令:' + listbox1.Items.Strings[I] + ' 吗？')),  '删除指令', MB_OKCANCEL) = 1) then
    begin
      deleteatrb(@nowevent,I);
      //saveevent(@Kevent[combobox2.ItemIndex], @nowevent);
      //copyevent(@noworievent, @kevent[combobox2.ItemIndex]);
      saveeventtoData(@Kevent[combobox2.ItemIndex], @nowevent);
      savedatatoevent(@noworievent, @kevent[combobox2.ItemIndex]);
      //calkdef(@noworievent, @nowevent);
      calevent(@noworievent, @nowevent);
      displayevent;
      listbox2.Clear;
    end;
  end;
end;

procedure TForm7.Button12Click(Sender: TObject);
begin
  inc(eventamount);
  setlength(Kevent, eventamount);
  Kevent[eventamount - 1].datalen := 2;
  setlength(Kevent[eventamount - 1].data, Kevent[eventamount - 1].datalen);
  Psmallint(@Kevent[eventamount - 1].data[0])^ := -1;
  {Kevent[eventamount - 1].attribamount := 2;
  setlength(kevent[eventamount - 1].attrib, Kevent[eventamount - 1].attribamount);
  Kevent[eventamount - 1].attrib[0].attribnum := 0;
  Kevent[eventamount - 1].attrib[0].parcount := 1;
  Kevent[eventamount - 1].attrib[0].labelstatus := -2;
  setlength(Kevent[eventamount - 1].attrib[0].par, 1);
  Kevent[eventamount - 1].attrib[0].par[0] := 0;
  Kevent[eventamount - 1].attrib[1].attribnum := -1;
  Kevent[eventamount - 1].attrib[1].parcount := 1;
  Kevent[eventamount - 1].attrib[1].labelstatus := -2;
  setlength(Kevent[eventamount - 1].attrib[1].par, 1);
  Kevent[eventamount - 1].attrib[1].par[0] := -1;}
  combobox2.Items.Add(inttostr(eventamount - 1));
  showmessage('添加事件完成，编号' + inttostr(eventamount - 1));
end;

procedure TForm7.Button13Click(Sender: TObject);
begin
  if eventamount = 1 then
  begin
    showmessage('只剩一个事件，无法删除！');
    exit;
  end
  else if MessageBox(Self.Handle, '确实要删除最后一个事件吗？',  '删除事件', MB_OKCANCEL) = 1 then
  begin
    dec(eventamount);
    setlength(Kevent, eventamount);
    if combobox2.ItemIndex = eventamount then
    begin
      combobox2.itemIndex := eventamount - 1;
      {if lastevent >=0 then
      begin
        saveeventtodata(@Kevent[lastevent],@nowevent);
      end;}
      lastevent := combobox2.ItemIndex;
      //copyevent(@noworievent, @Kevent[combobox2.ItemIndex]);
      savedatatoevent(@noworievent, @Kevent[combobox2.ItemIndex]);
      //calkdef(@noworievent, @nowevent);
      calevent(@noworievent, @nowevent);
      displayevent;
      listbox2.Clear;
    end;
    combobox2.Items.Delete(eventamount);
  end;
end;

procedure TForm7.Button14Click(Sender: TObject);
var
  I2, temp, tempway, tempway2, temppar, tempstatus, tempstatus2: integer;
  tempattrb: Tattrib;
begin
  if listbox2.Items.Count > 0 then
  begin
    temp := listbox1.ItemIndex;
    if nowevent.attrib[temp].labelstatus = -1 then
    begin
      for i2 := 0 to nowevent.attribamount - 1 do
        if nowevent.attrib[i2].labelstatus = nowevent.attrib[temp].labelfrom then
        begin
          temp := I2;
          break;
        end;
    end;
    temppar := nowevent.attrib[temp].parcount;
    tempstatus := nowevent.attrib[temp].labelstatus;
    tempway := 0;
    if tempstatus >= 0 then
    begin
      if nowevent.attrib[temp].labelway > 0 then
      begin
        tempway := nowevent.attrib[temp].par[Kdefini.KDEFitem[nowevent.attrib[temp].attribnum].yesjump];
      end
      else
        tempway := nowevent.attrib[temp].par[Kdefini.KDEFitem[nowevent.attrib[temp].attribnum].nojump];
    end;
    copyattrib(@tempattrb, @nowevent.attrib[temp]);
    for i2 := 0 to nowevent.attrib[temp].parcount - 1 do
      nowevent.attrib[temp].par[i2] := strtoint(listbox2.Items.Strings[i2]);
    nowevent.attrib[temp].attribnum := nowevent.attrib[temp].par[0];
    if (nowevent.attrib[temp].attribnum >= 0) and (nowevent.attrib[temp].attribnum < Kdefini.KDEFnum) then
    begin
      nowevent.attrib[temp].parcount := Kdefini.KDEFitem[nowevent.attrib[temp].attribnum].paramount;
      setlength(nowevent.attrib[temp].par, nowevent.attrib[temp].parcount);
    end
    else
    begin
      nowevent.attrib[temp].parcount := 1;
      setlength(nowevent.attrib[temp].par, nowevent.attrib[temp].parcount);
    end;
    //copyattrib(@tempattrb, @nowevent.attrib[temp]);
    if nowevent.attrib[temp].attribnum <> tempattrb.attribnum then
    begin
      copyattrib(@tempattrb, @nowevent.attrib[temp]);
      tempattrb.labelstatus := -2;
      //tempattrb.labelway := 0;
      tempattrb.labelfrom := -2;
      tempattrb.labelto := -2;
      deleteatrb(@nowevent, temp);
      if (tempstatus <> -2) and (tempway >= 0) then
        addIct(@nowevent,@tempattrb, temp)
      else if (tempstatus <> -2) and (tempway < 0) then
        addIct(@nowevent,@tempattrb, temp - 1)
      else
        addIct(@nowevent, @tempattrb, temp);
    end;
    saveeventtodata(@Kevent[combobox2.ItemIndex], @nowevent);
    savedatatoevent(@noworievent, @kevent[combobox2.ItemIndex]);
    //calkdef(@noworievent, @nowevent);
    calevent(@noworievent, @nowevent);
    displayevent;

    tempway2 := 0;
    tempstatus2 := -2;
    if (tempattrb.attribnum >= 0) and (tempattrb.attribnum < Kdefini.KDEFnum) then
    begin
      if Kdefini.KDEFitem[tempattrb.attribnum].ifjump = 1 then
      begin
        if tempattrb.labelway >= 0 then
          tempway2 := tempattrb.par[kdefini.KDEFitem[tempattrb.attribnum].yesjump]
        else
          tempway2 := tempattrb.par[kdefini.KDEFitem[tempattrb.attribnum].nojump];
        tempstatus2 := 0;
      end;
    end;

    if (tempstatus >= 0) and  (tempstatus2 >= 0) and  (tempway < 0) and (tempway2 >= 0) then
      listbox1.Selected[temp - 1] := true
    else if (tempstatus >= 0) and  (tempstatus2 >= 0) and  (tempway >= 0) and (tempway2 < 0) then
      listbox1.Selected[temp + 1] := true
    else if (tempstatus >= 0) and  (tempstatus2 = -2 ) and  (tempway < 0) then
      listbox1.Selected[temp - 1] := true
    else if (tempstatus = -2) and  (tempstatus2 >= 0) and  (tempway2 < 0) then
      listbox1.Selected[temp + 1] := true
    else
      listbox1.Selected[temp] := true;

    //listbox2.Clear;
    ListBox1Click(Sender);
  end;
end;

procedure TForm7.Button15Click(Sender: TObject);
var
  tempattrb: Tattrib;
  I, temp, labelstatus: integer;
begin
  if listbox1.ItemIndex > 0 then
  begin
   // edit2.Text := inttostr(nowevent.attrib[listbox1.ItemIndex].labelway);
    if nowevent.attrib[listbox1.ItemIndex].labelstatus = -2 then
    begin
      if nowevent.attrib[listbox1.ItemIndex - 1].labelstatus = -1 then
      begin
        for I := 0 to nowevent.attribamount - 1 do
          if nowevent.attrib[I].labelstatus = nowevent.attrib[listbox1.ItemIndex - 1].labelfrom then
            if nowevent.attrib[I].labelway < 0 then
              inc(nowevent.attrib[I].par[Kdefini.KDEFitem[nowevent.attrib[I].attribnum].nojump], nowevent.attrib[listbox1.ItemIndex].parcount)
            else
              inc(nowevent.attrib[I].par[Kdefini.KDEFitem[nowevent.attrib[I].attribnum].yesjump], nowevent.attrib[listbox1.ItemIndex].parcount);

      end
      else if  nowevent.attrib[listbox1.ItemIndex - 1].labelstatus >= 0  then
      begin
        if nowevent.attrib[listbox1.ItemIndex - 1].labelway < 0 then
          dec(nowevent.attrib[listbox1.ItemIndex - 1].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex - 1].attribnum].nojump], nowevent.attrib[listbox1.ItemIndex].parcount)
        else
          dec(nowevent.attrib[listbox1.ItemIndex - 1].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex - 1].attribnum].yesjump], nowevent.attrib[listbox1.ItemIndex].parcount);
      end;
    end
    else if nowevent.attrib[listbox1.ItemIndex].labelstatus = -1 then
    begin
      if (nowevent.attrib[listbox1.ItemIndex - 1].labelstatus <> -1)  then
      begin
      for I := 0 to nowevent.attribamount - 1 do
        if nowevent.attrib[I].labelstatus = nowevent.attrib[listbox1.ItemIndex].labelfrom then
          if nowevent.attrib[I].labelway < 0 then
            dec(nowevent.attrib[I].par[Kdefini.KDEFitem[nowevent.attrib[I].attribnum].nojump], nowevent.attrib[listbox1.ItemIndex - 1].parcount)
          else
            dec(nowevent.attrib[I].par[Kdefini.KDEFitem[nowevent.attrib[I].attribnum].yesjump], nowevent.attrib[listbox1.ItemIndex - 1].parcount);

      end;
    end
    else if nowevent.attrib[listbox1.ItemIndex].labelstatus >= 0 then
    begin
      if (nowevent.attrib[listbox1.ItemIndex - 1].labelstatus >= 0) then
      begin
        if nowevent.attrib[listbox1.ItemIndex - 1].labelway < 0 then
          dec(nowevent.attrib[listbox1.ItemIndex - 1].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex - 1].attribnum].nojump], nowevent.attrib[listbox1.ItemIndex].parcount)
        else
          dec(nowevent.attrib[listbox1.ItemIndex - 1].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex - 1].attribnum].yesjump], nowevent.attrib[listbox1.ItemIndex].parcount);
        if nowevent.attrib[listbox1.ItemIndex].labelway < 0 then
          inc(nowevent.attrib[listbox1.ItemIndex].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex].attribnum].nojump], nowevent.attrib[listbox1.ItemIndex - 1].parcount)
        else
          inc(nowevent.attrib[listbox1.ItemIndex].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex].attribnum].yesjump], nowevent.attrib[listbox1.ItemIndex - 1].parcount);
      end
      else if nowevent.attrib[listbox1.ItemIndex - 1].labelstatus = -1 then
      begin
        for I := 0 to nowevent.attribamount - 1 do
          if nowevent.attrib[I].labelstatus = nowevent.attrib[listbox1.ItemIndex - 1].labelfrom then
            if nowevent.attrib[I].labelway < 0 then
              inc(nowevent.attrib[I].par[Kdefini.KDEFitem[nowevent.attrib[I].attribnum].nojump], nowevent.attrib[listbox1.ItemIndex].parcount)
            else
              inc(nowevent.attrib[I].par[Kdefini.KDEFitem[nowevent.attrib[I].attribnum].yesjump], nowevent.attrib[listbox1.ItemIndex].parcount);
      end
      else
      begin
         if nowevent.attrib[listbox1.ItemIndex].labelway < 0 then
          inc(nowevent.attrib[listbox1.ItemIndex].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex].attribnum].nojump], nowevent.attrib[listbox1.ItemIndex - 1].parcount)
        else
          inc(nowevent.attrib[listbox1.ItemIndex].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex].attribnum].yesjump], nowevent.attrib[listbox1.ItemIndex - 1].parcount);
      end;

    end;
    temp := listbox1.ItemIndex;
    copyattrib(@tempattrb,@nowevent.attrib[listbox1.ItemIndex]);
    copyattrib(@nowevent.attrib[listbox1.ItemIndex], @nowevent.attrib[listbox1.ItemIndex - 1]);
    copyattrib(@nowevent.attrib[listbox1.ItemIndex - 1], @tempattrb);
    displayevent;
    dec(temp);
    for I := 0 to nowevent.attribamount - 1 do
      if I = temp then
        listbox1.Selected[I] := true
      else
        listbox1.Selected[I] := false;
    ListBox1Click(Sender);
  end;
end;

procedure TForm7.Button16Click(Sender: TObject);
var
  tempattrb: Tattrib;
  I, temp: integer;
begin
  if (listbox1.ItemIndex >= 0) and (listbox1.ItemIndex < nowevent.attribamount - 1) then
  begin
    //edit2.Text := inttostr(nowevent.attrib[listbox1.ItemIndex].labelway);
    if nowevent.attrib[listbox1.ItemIndex].labelstatus = -2 then
    begin
      if nowevent.attrib[listbox1.ItemIndex + 1].labelstatus = -1 then
      begin
        for I := 0 to nowevent.attribamount - 1 do
          if nowevent.attrib[I].labelstatus = nowevent.attrib[listbox1.ItemIndex + 1].labelfrom then
            if nowevent.attrib[I].labelway < 0 then
              dec(nowevent.attrib[I].par[Kdefini.KDEFitem[nowevent.attrib[I].attribnum].nojump], nowevent.attrib[listbox1.ItemIndex].parcount)
            else
              dec(nowevent.attrib[I].par[Kdefini.KDEFitem[nowevent.attrib[I].attribnum].yesjump], nowevent.attrib[listbox1.ItemIndex].parcount);

      end
      else if nowevent.attrib[listbox1.ItemIndex + 1].labelstatus >= 0  then
      begin
        if nowevent.attrib[listbox1.ItemIndex + 1].labelway < 0 then
          inc(nowevent.attrib[listbox1.ItemIndex + 1].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex + 1].attribnum].nojump], nowevent.attrib[listbox1.ItemIndex].parcount)
        else
          inc(nowevent.attrib[listbox1.ItemIndex + 1].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex + 1].attribnum].yesjump], nowevent.attrib[listbox1.ItemIndex].parcount);
      end;
    end
    else if nowevent.attrib[listbox1.ItemIndex].labelstatus = -1 then
    begin
      if (nowevent.attrib[listbox1.ItemIndex + 1].labelstatus <> -1)  then
      begin
      for I := 0 to nowevent.attribamount - 1 do
        if nowevent.attrib[I].labelstatus = nowevent.attrib[listbox1.ItemIndex].labelfrom then
          if nowevent.attrib[I].labelway < 0 then
            inc(nowevent.attrib[I].par[Kdefini.KDEFitem[nowevent.attrib[I].attribnum].nojump], nowevent.attrib[listbox1.ItemIndex + 1].parcount)
          else
            inc(nowevent.attrib[I].par[Kdefini.KDEFitem[nowevent.attrib[I].attribnum].yesjump], nowevent.attrib[listbox1.ItemIndex + 1].parcount);

      end;
    end
    else if nowevent.attrib[listbox1.ItemIndex].labelstatus >= 0 then
    begin
      if (nowevent.attrib[listbox1.ItemIndex + 1].labelstatus >= 0) then
      begin
        if nowevent.attrib[listbox1.ItemIndex + 1].labelway < 0 then
          inc(nowevent.attrib[listbox1.ItemIndex + 1].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex+ 1].attribnum].nojump], nowevent.attrib[listbox1.ItemIndex].parcount)
        else
          inc(nowevent.attrib[listbox1.ItemIndex + 1].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex + 1].attribnum].yesjump], nowevent.attrib[listbox1.ItemIndex].parcount);
        if nowevent.attrib[listbox1.ItemIndex].labelway < 0 then
          dec(nowevent.attrib[listbox1.ItemIndex].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex].attribnum].nojump], nowevent.attrib[listbox1.ItemIndex + 1].parcount)
        else
          dec(nowevent.attrib[listbox1.ItemIndex].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex].attribnum].yesjump], nowevent.attrib[listbox1.ItemIndex + 1].parcount);
      end
      else if nowevent.attrib[listbox1.ItemIndex + 1].labelstatus = -1 then
      begin
        for I := 0 to nowevent.attribamount - 1 do
          if nowevent.attrib[I].labelstatus = nowevent.attrib[listbox1.ItemIndex + 1].labelfrom then
            if nowevent.attrib[I].labelway < 0 then
              dec(nowevent.attrib[I].par[Kdefini.KDEFitem[nowevent.attrib[I].attribnum].nojump], nowevent.attrib[listbox1.ItemIndex].parcount)
            else
              dec(nowevent.attrib[I].par[Kdefini.KDEFitem[nowevent.attrib[I].attribnum].yesjump], nowevent.attrib[listbox1.ItemIndex].parcount);
      end
      else
      begin
        if nowevent.attrib[listbox1.ItemIndex].labelway < 0 then
          dec(nowevent.attrib[listbox1.ItemIndex].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex].attribnum].nojump], nowevent.attrib[listbox1.ItemIndex + 1].parcount)
        else
          dec(nowevent.attrib[listbox1.ItemIndex].par[Kdefini.KDEFitem[nowevent.attrib[listbox1.ItemIndex].attribnum].yesjump], nowevent.attrib[listbox1.ItemIndex + 1].parcount);
      end;

    end;
    temp := listbox1.ItemIndex;
    copyattrib(@tempattrb,@nowevent.attrib[listbox1.ItemIndex]);
    copyattrib(@nowevent.attrib[listbox1.ItemIndex], @nowevent.attrib[listbox1.ItemIndex + 1]);
    copyattrib(@nowevent.attrib[listbox1.ItemIndex + 1], @tempattrb);
    displayevent;
    inc(temp);
    for I := 0 to nowevent.attribamount - 1 do
      if I = temp then
        listbox1.Selected[I] := true
      else
        listbox1.Selected[I] := false;
    ListBox1Click(Sender);
  end;
end;

procedure TForm7.Button17Click(Sender: TObject);
var
  I, I2: integer;
  tempstr: string;
begin
  //memo1.PasteFromClipboard;
  //memo1.CopyToClipboard;
  if nowevent.attribamount > 0 then
  begin
    memo1.Clear;
    memo1.Lines.Add(';KdefEvent' + inttostr(combobox2.ItemIndex));
    for I := 0 to nowevent.attribamount - 1 do
    begin
      tempstr := '';
      if nowevent.attrib[I].labelstatus <> -1 then
      begin
        for i2 := 0 to nowevent.attrib[I].parcount - 1 do
          tempstr := tempstr + inttostr(nowevent.attrib[I].par[I2]) + ' ';
      end;
      tempstr := tempstr +';' +listbox1.Items.Strings[I];
      memo1.Lines.Add(tempstr);
    end;
    memo1.SelectAll;
    memo1.CopyToClipboard;
  end;
end;

procedure TForm7.Button18Click(Sender: TObject);
var
  I,I2,I3,len,strnum,atrbnum: integer;
  strlist: TStringlist;
  tempstr: string;
  handlestr: widestring;
begin
  try
    saveeventtodata(@Kevent[combobox2.ItemIndex],@nowevent);
    strlist := Tstringlist.Create;
    memo1.Clear;
    memo1.PasteFromClipboard;
    atrbnum := 0;
    for I := 0 to memo1.Lines.Count - 1 do
    begin
      len := 0;
      handlestr := widestring(memo1.Lines.Strings[I]);
      for i2 := 1 to length(handlestr) do
      begin
        if handlestr[i2] = ';' then
          break;
        inc(len);
      end;
      if len > 0 then
      begin
        setlength(handlestr, len);
        strlist.Clear;
        strnum := ExtractStrings([' '], [], Pwidechar(handlestr), Strlist);
        if strnum > 0 then
        begin
          inc(atrbnum);
          noworievent.attribamount := atrbnum;
          setlength(noworievent.attrib, atrbnum);
          //setlength(noworievent.attrib[atrbnum - 1].par, strnum);
          noworievent.attrib[atrbnum - 1].attribnum := strtoint(strlist.Strings[0]);
          if (noworievent.attrib[atrbnum - 1].attribnum >= 0) and (noworievent.attrib[atrbnum - 1].attribnum < kdefini.KDEFnum) then
          begin
            noworievent.attrib[atrbnum - 1].parcount := Kdefini.KDEFitem[noworievent.attrib[atrbnum - 1].attribnum].paramount;
            //parcount := Kdefini.KDEFitem[noworievent.attrib[atrbnum - 1].attribnum].paramount;
          end
          else
          begin
            noworievent.attrib[atrbnum - 1].parcount := 1;
          end;
          setlength(noworievent.attrib[atrbnum - 1].par, noworievent.attrib[atrbnum - 1].parcount);
          for I3 := 0 to noworievent.attrib[atrbnum - 1].parcount - 1 do
          begin
            if i3 < strnum then
              noworievent.attrib[atrbnum-1].par[i3] := strtoint(strlist.Strings[i3])
            else
              noworievent.attrib[atrbnum-1].par[i3] := 0;
          end;
        end;
      end;
    end;
    strlist.Free;
    //calkdef(@noworievent, @nowevent);
    calevent(@noworievent, @nowevent);
    displayevent;
    listbox2.Clear;
  except
    showmessage('从剪切板复制失败！');
    strlist.Free;
    savedatatoevent(@noworievent, @Kevent[combobox2.ItemIndex]);
    //calkdef(@noworievent, @nowevent);
    calevent(@noworievent, @nowevent);
    displayevent;
    listbox2.Clear;
  end;
end;

procedure TForm7.Button1Click(Sender: TObject);
begin
  inc(talkstrnum);
  setlength(talkstr, talkstrnum);
  WriteTalkStr(@talkstr[talkstrnum - 1], widestring('請輸入對話內容，若為原版對話，每隔12個漢字加一個星號*'));
  //arrangetalktocombobox;
  combobox1.Items.Add(inttostr(talkstrnum - 1) + ':'+ readtalkstr(@talkstr[talkstrnum - 1]));
  combobox1.ItemIndex := talkstrnum - 1;
  edit1.Text := displaystr(readtalkstr(@talkstr[talkstrnum - 1]));
end;

procedure TForm7.Button2Click(Sender: TObject);
var
  temp2: integer;
begin
  temp2 := combobox1.ItemIndex;
  WriteTalkStr(@talkstr[temp2], widestring(edit1.Text));
  combobox1.Items.Strings[temp2] := inttostr(temp2) + ':'+ readtalkstr(@talkstr[temp2]);
  //arrangetalktocombobox;
  combobox1.ItemIndex := temp2;
end;

procedure TForm7.Button3Click(Sender: TObject);
begin
  if talkstrnum <> 1 then
  begin
    dec(talkstrnum);
    setlength(talkstr, talkstrnum);
    combobox1.Items.Delete(talkstrnum);
    combobox1.ItemIndex := talkstrnum - 1;
    edit1.Text := displaystr(readtalkstr(@talkstr[talkstrnum - 1]));
  end
  else
    showmessage('只剩一个对话，不可删除');
end;

procedure TForm7.Button4Click(Sender: TObject);
var
  next, len, I, I2, len2, Ncount, a: integer;
  Astr, Bstr, Cstr: widestring;
  ini: Tinifile;
begin
  Ncount := strtoint(edit2.Text);

  if Ncount <> Kdefini.talkarrange then
  begin
    Kdefini.talkarrange := Ncount;
    ini := Tinifile.Create(ExtractFilePath(Paramstr(0)) + iniFilename);
    ini.WriteInteger('Kdef','talkarrange', Kdefini.talkarrange);
    ini.Free;
  end;
  //去星号
  Cstr := widestring(edit1.Text);
  len := length(Cstr);
  len2 := len;
  for I := 1 to len do
  begin
    if Cstr[I] = '*' then
      dec(len2);
  end;
  setlength(Astr, len2);
  I2 := 1;
  for I := 1 to len do
  begin
    if Cstr[I] <> '*' then
    begin
      Astr[I2] := Cstr[I];
      inc(I2);
    end;
  end;

  if Ncount <= 0 then
  begin
    edit1.Text := Astr;
    exit;
  end;

  len := len2;
  len2 := len div Ncount + len;
  setlength(Bstr, len2);
  I2 := 1;
  for I := 1 to len do
  begin
    Bstr[I2] := Astr[I];
    inc(I2);
    if I mod Ncount = 0 then
    begin
      Bstr[I2] := '*';
      inc(I2);
    end;
  end;
  edit1.Text := Bstr;
end;

procedure TForm7.Button5Click(Sender: TObject);
var
  I1,I2,Fidx,Fgrp: integer;
  len: integer;
begin
  if eventamount <= 0 then
    exit;
  if MessageBox(Self.Handle, '确实要事件文件和对话文件吗？',  '保存文件', MB_OKCANCEL) = 1 then
  begin
    try
      if lastevent >=0 then
      begin
        //saveevent(@Kevent[lastevent],@nowevent);
        saveeventtodata(@Kevent[lastevent],@nowevent);
      end;
      //saveevent(@Kevent[combobox2.ItemIndex], @nowevent);
      Fidx := filecreate(gamepath + kdefidx);
      Fgrp := filecreate(gamepath + kdefgrp);
      len := 0;
      for I1 := 0 to eventamount - 1 do
      begin
        filewrite(Fgrp, Kevent[I1].data[0], Kevent[I1].datalen);
        inc(len, Kevent[I1].datalen);
        filewrite(Fidx,len, 4);
        {for i2 := 0 to Kevent[i1].attribamount - 1 do
        begin
          filewrite(Fgrp,kevent[i1].attrib[i2].par[0], Kevent[i1].attrib[i2].parcount * 2);
          inc(len, Kevent[i1].attrib[i2].parcount * 2);
        end;
        filewrite(Fidx,len, 4); }

      end;
      fileclose(Fidx);
      fileclose(Fgrp);
      savetalk;
      showmessage('保存事件文件和对话文件成功！');
    except
      showmessage('保存失败！');
      exit;
    end;
  end;
end;

procedure TForm7.Button6Click(Sender: TObject);
var
  I, FH: integer;
  filename, tempstr: string;
  tempUnicodehead: word;
  tempunicodenextline: cardinal;
begin
  SaveDialog1.Filter := '文本文件(*.txt)|*.txt';
  if savedialog1.Execute then
  begin
    filename := SaveDialog1.filename;
    if not SameText(ExtractFileExt(filename), '.txt') then
      filename := filename + '.txt';

    memo1.Clear;

    memo1.Lines.Add('对话文件——总数：' + inttostr(talkstrnum));
    memo1.Lines.Add(' ');
    for I := 0 to TalkStrnum - 1 do
    begin
      memo1.Lines.Add(inttostr(I) + ':' + displaystr(readtalkstr(@talkstr[I])));
      memo1.Lines.Add(' ');
    end;
    FH := filecreate(filename);
    tempUnicodehead := $FEFF;
    tempunicodenextline := $A000D;
    filewrite(FH, tempUnicodehead, 2);
    for I := 0 to memo1.Lines.Count - 1 do
    begin
      //tempstr := memo1.Lines.Strings[I];
      filewrite(FH, memo1.Lines.Strings[I][1], length(memo1.Lines.Strings[I]) * sizeof(widechar));
      filewrite(FH, tempunicodenextline, 4);
    end;
    fileclose(FH);
    memo1.Clear;
    tempstr := '';
  end;
end;

procedure TForm7.Button7Click(Sender: TObject);
var
  I, I2, FH: integer;
  temporievent, tempevent: Tevent;
  filename, tempstr: string;
  tempunicodehead: Word;
  tempunicodenextline: cardinal;
begin
  SaveDialog1.Filter := '文本文件(*.txt)|*.txt';
  if savedialog1.Execute then
  begin
    filename := SaveDialog1.filename;
    if not SameText(ExtractFileExt(filename), '.txt') then
      filename := filename + '.txt';
    memo1.Clear;
    memo1.Lines.Add('事件文件——总数：' + inttostr(eventamount));
    for I := 0 to eventamount - 1 do
    begin
      memo1.Lines.Add(' ');
      memo1.Lines.Add('事件:'+inttostr(I));
      try
        savedatatoevent(@temporievent, @kevent[I]);
        //calkdef(@temporievent,@tempevent);
        calevent(@temporievent,@tempevent);
        for I2 := 0 to tempevent.attribamount - 1 do
          memo1.Lines.Add(calattribname(@(tempevent.attrib[I2])));
      except
      end;
    end;
    //memo1.Lines.SaveToFile(filename);
    FH := filecreate(filename);
    tempUnicodehead := $FEFF;
    tempunicodenextline := $A000D;
    filewrite(FH, tempUnicodehead, 2);
    for I := 0 to memo1.Lines.Count - 1 do
    begin
      //tempstr := memo1.Lines.Strings[I];
      //filewrite(FH, tempstr[1], length(tempstr) * sizeof(widechar));
      try
        filewrite(FH, memo1.Lines.Strings[I][1], length(memo1.Lines.Strings[I]) * sizeof(widechar));
        filewrite(FH, tempunicodenextline, 4);
      except

      end;
    end;
    fileclose(FH);
    memo1.Lines.Clear;
    tempstr := '';
  end;
end;

procedure TForm7.Button8Click(Sender: TObject);
begin
  try
    savetalk;
    showmessage('保存成功！')
  except
    showmessage('保存失败！');
    exit;
  end;
end;

procedure TForm7.Button9Click(Sender: TObject);
begin
  self.Close;
end;

procedure TForm7.ComboBox1Select(Sender: TObject);
begin
  if talkstrnum <= 0 then
  begin
    talkstrnum := 0;
    exit;
  end;
  edit1.Text := displaystr(readtalkstr(@talkstr[combobox1.ItemIndex]));
end;

procedure TForm7.ComboBox2Select(Sender: TObject);
begin
  if eventamount <= 0 then
    exit;
  if lastevent >=0 then
  begin
    //saveevent(@Kevent[lastevent],@nowevent);
    saveeventtodata(@Kevent[lastevent], @nowevent);
  end;
  lastevent := combobox2.ItemIndex;
  //copyevent(@noworievent, @Kevent[combobox2.ItemIndex]);
  savedatatoevent(@noworievent, @Kevent[combobox2.ItemIndex]);
  //calkdef(@noworievent, @nowevent);
  calevent(@noworievent, @nowevent);
  //copyevent(@nowevent,@noworievent);
  displayevent;
  listbox2.Clear;
end;

procedure TForm7.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  talkstrnum := 0;
  setlength(talkstr, talkstrnum);
  eventamount := 0;
  setlength(Kevent, eventamount);
  CForm7 := true;
  action := cafree;
end;

procedure TForm7.FormCreate(Sender: TObject);
var
  ini: Tinifile;
begin
  //
  lastevent := -1;
  eventamount := 0;
  eventcopy.copyevent := -1;
  eventcopy.copyattrib := -1;
  ini := TIniFile.Create(ExtractFilePath(Paramstr(0)) + iniFileName);
  kdefini.talkarrange := ini.ReadInteger('Kdef','talkarrange',12);
  ini.Free;
  edit2.Text := inttostr(kdefini.talkarrange);
  //if readR(gamepath + Ridxfilename[0], gamepath + Rfilename[0], @useR) then
  //  calnamepos(@useR);
  if readw(gamepath + wardata,@useW) then
  begin
    CalWnamePos(@useW);
  end;
  readname;
  //读对话配置文件和事件文件
  if readkdefini and readkdef and readtalk then
  begin
    arrangekdef;
    combobox2.ItemIndex := 0;
    //copyevent(@noworievent, @kevent[0]);
    savedatatoevent(@noworievent, @kevent[0]);
    //calkdef(@noworievent, @nowevent);
    calevent(@noworievent, @nowevent);
    displayevent;

    lastevent := 0;
  end;

end;

procedure TForm7.ListBox1Click(Sender: TObject);
var
  I, i2, temp,tempindex: integer;
begin
  if listbox1.ItemIndex >= 0 then
  begin
    tempindex := listbox1.ItemIndex;
    temp := listbox1.ItemIndex;
    listbox2.Clear;
    if nowevent.attrib[temp].labelstatus = -1 then
    begin
      for i2 := 0 to nowevent.attribamount - 1 do
        if nowevent.attrib[i2].labelstatus = nowevent.attrib[temp].labelfrom then
        begin
          temp := I2;
          break;
        end;
    end;
    for i2 := 0 to nowevent.attrib[temp].parcount - 1 do
      listbox2.Items.Add(inttostr(nowevent.attrib[temp].par[i2]));
    for i2 := 0 to listbox1.Items.Count - 1 do
    begin
    if listbox1.Selected[i2] = true then
    if nowevent.attrib[i2].labelstatus = -1 then
    begin
      for I := 0 to nowevent.attribamount - 1 do
        if nowevent.attrib[I].labelstatus = nowevent.attrib[i2].labelfrom then
          listbox1.Selected[I] := true;
    end
    else if nowevent.attrib[i2].labelstatus >= 0 then
    begin
      for I := 0 to nowevent.attribamount - 1 do
        if (nowevent.attrib[I].labelstatus = -1) and (nowevent.attrib[I].labelfrom = nowevent.attrib[i2].labelstatus) then
          listbox1.Selected[I] := true;
    end;
    end;
    listbox1.ItemIndex := tempindex;
  end;
end;

procedure TForm7.ListBox1DblClick(Sender: TObject);
var
  temp: integer;
begin
  temp := listbox1.ItemIndex;
  temp := temp + editict(@nowevent.attrib[listbox1.ItemIndex]);
  saveeventtodata(@Kevent[combobox2.ItemIndex], @nowevent);
  savedatatoevent(@noworievent, @kevent[combobox2.ItemIndex]);
  calevent(@noworievent, @nowevent);
  displayevent;
  if (temp >= 0) and (temp < Listbox1.Items.Count) then
    listbox1.Selected[temp] := true;
  listbox1.ItemIndex := temp;
  ListBox1Click(Sender);
end;

procedure TForm7.ListBox1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  tempx, tempy: integer;
begin
  if (Button = mbRight) then
  begin
    if combobox1.ItemIndex < 0 then
      combobox1.ItemIndex := 0;
    if eventcopy.copyevent > 0 then
      N4.Enabled := true
    else
      N4.Enabled := false;
    if eventcopy.copyattrib > 0 then
      N3.Enabled := true
    else
      N3.Enabled := false;

    if mainform.panel2.Visible then
      tempx := mainform.Panel2.Width
    else
      tempx := 0;

    if mainform.Panel1.Visible then
      tempy := mainform.Panel1.Height
    else
      tempy := 0;

    popupmenu1.Popup(x + self.Left + tempx + mainform.Left, y + tempy + self.Top + mainform.Top);
  end;
end;

procedure TForm7.ListBox2DblClick(Sender: TObject);
var
  temp: smallint;
begin
  if (listbox2.ItemIndex >= 0) then
  begin
    if listbox2.Items[listbox2.ItemIndex] <> '' then
    begin
      try
        temp := strtoint(inputbox('修改','修改此项值', listbox2.Items[listbox2.ItemIndex]));
        listbox2.Items[listbox2.ItemIndex] := inttostr(temp);
      except
        exit;
      end;
    end;
  end;
end;

procedure TForm7.N1Click(Sender: TObject);
var
  I,temp: integer;
begin

  temp := 0;
  for I := 0 to listbox1.Items.Count - 1 do
  begin
    if listbox1.Selected[I] and (nowevent.attrib[I].labelstatus <> -1) then
      inc(temp);
  end;
  if temp > 0 then
  begin
    eventcopy.copyattrib := 1;
    copyatrbent.attribamount := temp;
    setlength(copyatrbent.attrib, temp);
    temp := 0;
    for I := 0 to listbox1.Items.Count - 1 do
      if listbox1.Selected[I] and (nowevent.attrib[I].labelstatus <> -1) then
      begin
        copyattrib(@copyatrbent.attrib[temp],@nowevent.attrib[I]);
        inc(temp);
      end;
  end;
  
end;

procedure TForm7.N2Click(Sender: TObject);
begin
  eventcopy.copyevent := 1;
  copyevent(@copyent, @nowevent);
end;

procedure TForm7.N3Click(Sender: TObject);
var
  I: integer;
begin
  if listbox1.ItemIndex < 0 then
    listbox1.ItemIndex := 0;
  for I := copyatrbent.attribamount - 1 downto 0 do
  begin
    addict(@nowevent, @copyatrbent.attrib[I], listbox1.itemindex);
  end;
  saveeventtodata(@Kevent[combobox2.ItemIndex], @nowevent);
  //copyevent(@noworievent, @kevent[combobox2.ItemIndex]);
  //calkdef(@noworievent, @nowevent);
  savedatatoevent(@noworievent, @Kevent[combobox2.ItemIndex]);
  calevent(@noworievent, @nowevent);
  displayevent;
  listbox2.Clear;
end;

procedure TForm7.N4Click(Sender: TObject);
begin
  if (eventcopy.copyevent > 0) and (MessageBox(Self.Handle, '确实要覆盖这个事件吗？',  '粘贴事件', MB_OKCANCEL) = 1) then
  begin
    copyevent(@nowevent,@copyent);
    saveeventtodata(@Kevent[combobox2.ItemIndex], @nowevent);
    //copyevent(@noworievent, @kevent[combobox2.ItemIndex]);
    //calkdef(@noworievent, @nowevent);
    savedatatoevent(@noworievent, @Kevent[combobox2.ItemIndex]);
    calevent(@noworievent, @nowevent);
    displayevent;
    listbox2.Clear;
  end;
end;

procedure TForm7.N6Click(Sender: TObject);
begin
  Button11Click(Sender);
end;

procedure TForm7.N7Click(Sender: TObject);
begin
  Button10Click(Sender);
end;

function TForm7.readtalk: Boolean;
var
  talkoffset: array of integer;
  filelen, F, I, i2,temp: integer;
  tdata: array of byte;
begin
  //
  result := false;
  if fileexists(gamepath + talkidx) and fileexists(gamepath +talkgrp) then
  begin
    try
      F := fileopen(gamepath + talkidx, fmopenread);
      filelen := fileseek(F,0,2);
      talkstrnum := filelen shr 2;
      setlength(talkoffset, filelen shr 2 + 1);
      fileseek(F,0,0);
      talkoffset[0] := 0;
      fileread(F,talkoffset[1], filelen);
      fileclose(F);
      F := fileopen(gamepath + talkgrp, fmopenread);
      setlength(talkstr, talkstrnum);
      for I := 0 to talkstrnum - 1 do
      begin
        talkstr[I].len := max(talkoffset[I + 1] - talkoffset[I], 0);
        setlength(tdata, talkstr[I].len);
        setlength(talkstr[I].str, talkstr[I].len);
        fileread(F, tdata[0], (talkoffset[I + 1] - talkoffset[I]));
        if Talkinvert = 0 then
          for i2 := 0 to (talkoffset[I + 1] - talkoffset[I] - 1)do
          begin
            tdata[i2] := tdata[i2] xor $FF;
            if tdata[i2] = $FF then
              tdata[i2] := 0;
          end;
        if talkstr[I].len > 0 then
          copymemory(@talkstr[I].str[0], @tdata[0],talkstr[I].len);
      end;
      fileclose(F);

      arrangetalktocombobox;

      combobox1.ItemIndex := 0;
      edit1.Text := displaystr(readTalkstr(@talkstr[0]));
      result := true;
    except
      showmessage('对话读取出错！');
      exit;
    end;
  end
  else
    showmessage('对话文件不存在！');
end;

procedure readname;
var
  talkoffset: array of integer;
  filelen, F, I, i2,temp: integer;
  tdata: array of byte;
begin
  //
  if fileexists(gamepath + nameidx) and fileexists(gamepath + namegrp) then
  begin
    try
      F := fileopen(gamepath + nameidx, fmopenread);
      filelen := fileseek(F,0,2);
      namestrnum := filelen shr 2;
      setlength(talkoffset, filelen shr 2 + 1);
      fileseek(F,0,0);
      talkoffset[0] := 0;
      fileread(F,talkoffset[1], filelen);
      fileclose(F);
      F := fileopen(gamepath + namegrp, fmopenread);
      setlength(namestr, filelen shr 2);
      for I := 0 to namestrnum - 1 do
      begin
        namestr[I].len := max(talkoffset[I + 1] - talkoffset[I], 0);
        setlength(tdata, namestr[I].len);
        setlength(namestr[I].str, namestr[I].len);
        fileread(F, tdata[0], (talkoffset[I + 1] - talkoffset[I]));
        if Talkinvert = 0 then
          for i2 := 0 to (talkoffset[I + 1] - talkoffset[I] - 1)do
          begin
            tdata[i2] := tdata[i2] xor $FF;
            if tdata[i2] = $FF then
              tdata[i2] := 0;
          end;
        if namestr[I].len > 0 then
          copymemory(@namestr[I].str[0], @tdata[0], namestr[I].len);
      end;
      fileclose(F);
    except
      showmessage('读取名字出错！');
      exit;
    end;
  end;
end;

procedure TForm7.arrangetalktocombobox;
var
  I: integer;
begin
  //对话添加到combobox
  combobox1.Clear;
  for I := 0 to talkstrnum - 1 do
  begin
    combobox1.Items.Add(inttostr(I) + ':'+ readtalkstr(@talkstr[I]));
  end;

end;

procedure TForm7.savetalk;
var
  Fidx, Fgrp, I, i2, len: integer;
  talkoffset: array of integer;
  tdata: array of byte;
begin
  Fidx := filecreate(gamepath + talkidx);
  Fgrp := filecreate(gamepath + talkgrp);
  setlength(talkoffset, talkstrnum);
  len := 0;
  for I := 0 to talkstrnum - 1 do
  begin
    talkoffset[I] := max(talkstr[I].len, 0);
    inc(len, talkoffset[I]);
    setlength(tdata, talkoffset[I]);
    if talkoffset[I] > 0 then
      copymemory(@tdata[0], @talkstr[I].str[0], talkoffset[I]);
    if talkinvert = 0 then
    begin
      for i2 := 0 to talkoffset[I] - 1 do
      begin
        tdata[i2] := tdata[i2] xor $FF;
        if tdata[i2] = $FF then
          tdata[i2] := 0;
      end;
    end;
    filewrite(Fidx, len, 4);
    if talkoffset[I] > 0 then
      filewrite(Fgrp, tdata[0], talkoffset[I]);
  end;
  fileclose(Fidx);
  fileclose(Fgrp);
end;

function TForm7.readkdefini: boolean;
var
  ini: Tinifile;
  filename, tempstr: string;
  i, I2, strnum, tempint: integer;
  strlist: Tstringlist;
begin
  result := false;
  try
    filename := ExtractFilePath(Paramstr(0)) + iniFileName;
    ini := TIniFile.Create(filename);
    kdefini.KDEFnum := ini.ReadInteger('KdefAttrib','number',0);
    if kdefini.KDEFnum < 0 then
      kdefini.KDEFnum := 0;
    setlength(Kdefini.KDEFitem, kdefini.KDEFnum);
    strlist := Tstringlist.Create;
    for I := 0 to kdefini.KDEFnum - 1 do
    begin
      tempstr := ini.ReadString('Kdefattrib', 'attrib'+inttostr(I),'');
      strlist.Clear;
      strnum := 0;
      if tempstr <> '' then
        strnum := ExtractStrings([' '], [], Pwidechar(tempstr), Strlist);
      if strnum = 6 then
      begin
        kdefini.KDEFitem[I].index := strtoint('$'+strlist.Strings[0]);
        kdefini.KDEFitem[I].paramount := strtoint(strlist.Strings[1]);
        kdefini.KDEFitem[I].ifjump := strtoint(strlist.Strings[2]);
        kdefini.KDEFitem[I].yesjump := strtoint(strlist.Strings[3]);
        kdefini.KDEFitem[I].nojump := strtoint(strlist.Strings[4]);
        kdefini.KDEFitem[I].note := strlist.Strings[5];
      end
      else
      begin
        Kdefini.KDEFitem[I].index := I;
        kdefini.KDEFitem[I].paramount := 1;
        kdefini.KDEFitem[I].ifjump := 0;
        kdefini.KDEFitem[I].note := '';
      end;
    end;

    kdef50.num := ini.ReadInteger('kdef50','num',0);
    kdef50.other := ini.ReadString('kdef50','other','');
    setlength(kdef50.sub, kdef50.num);
    for I := 0 to kdef50.num - 1 do
    begin
      kdef50.sub[I] := ini.ReadString('kdef50','sub' + inttostr(I), kdef50.other);
    end;

    InstructGuideini.Amount := kdefini.KDEFnum;
    if InstructGuideini.Amount < 0 then
      InstructGuideini.Amount := 0;
    setlength(InstructGuideini.Instruct, InstructGuideini.Amount);
    for I := 0 to InstructGuideini.Amount - 1 do
    begin
      InstructGuideini.Instruct[I].ParamAmount := kdefini.KDEFitem[I].paramount;
      if InstructGuideini.Instruct[I].ParamAmount < 0 then
        InstructGuideini.Instruct[I].ParamAmount := 0;
      setlength(InstructGuideini.Instruct[I].Param, InstructGuideini.Instruct[I].ParamAmount);

      InstructGuideini.Instruct[I].GuideStr := ini.ReadString('Kdefattrib', 'guidestring' + inttostr(I), '');
      if InstructGuideini.Instruct[I].GuideStr = '' then
        InstructGuideini.Instruct[I].NeedGuide := 0
      else
      begin
        InstructGuideini.Instruct[I].NeedGuide := 1;

        tempstr := ini.ReadString('Kdefattrib', 'guidelabel' + inttostr(I), '');
        strlist.Clear;
        strnum := 0;
        if tempstr <> '' then
          strnum := ExtractStrings([' '], [], Pwidechar(tempstr), Strlist);

        for I2 := 0 to min(InstructGuideini.Instruct[I].ParamAmount, strnum) - 1 do
        begin
          InstructGuideini.Instruct[I].Param[I2].QuoteLabel := strlist.Strings[I2];
        end;

        tempstr := ini.ReadString('Kdefattrib', 'guidequotetype' + inttostr(I), '');
        strlist.Clear;
        strnum := 0;
        if tempstr <> '' then
          strnum := ExtractStrings([' '], [], Pwidechar(tempstr), Strlist);

        for I2 := 0 to min(InstructGuideini.Instruct[I].ParamAmount, strnum) - 1 do
        begin
          try
            InstructGuideini.Instruct[I].Param[I2].QuoteType := Strtoint(strlist.Strings[I2]);
          except
            InstructGuideini.Instruct[I].Param[I2].QuoteType := 0;
          end;
        end;


        tempstr := ini.ReadString('Kdefattrib', 'guidequotecount' + inttostr(I), '');
        strlist.Clear;
        strnum := 0;
        if tempstr <> '' then
          strnum := ExtractStrings([' '], [], Pwidechar(tempstr), Strlist);

        for I2 := 0 to min(InstructGuideini.Instruct[I].ParamAmount, strnum) - 1 do
        begin
          try
            InstructGuideini.Instruct[I].Param[I2].QuoteCount := Strtoint(strlist.Strings[I2]);
          except
            InstructGuideini.Instruct[I].Param[I2].QuoteCount := 0;
          end;
        end;
      end;
    end;

    InstructGuideComboboxini.Amount := max(ini.Readinteger('KdefAttrib','GuideComboBoxAmount',0), 0);
    setlength(InstructGuideComboboxini.Combobox, InstructGuideComboboxini.Amount);
    for I := 0 to InstructGuideComboboxini.Amount - 1 do
    begin
      strlist.Clear;
      strnum := 0;
      tempstr := ini.ReadString('Kdefattrib', 'GuideComboBox' + inttostr(I), '');
      if tempstr <> '' then
        strnum := ExtractStrings([' '], [], Pwidechar(tempstr), Strlist);
      InstructGuideComboboxini.Combobox[I].ListAmount := max(strnum div 2, 0);
      setlength(InstructGuideComboboxini.Combobox[I].List, InstructGuideComboboxini.Combobox[I].ListAmount);
      for I2 := 0 to InstructGuideComboboxini.Combobox[I].ListAmount - 1 do
      begin
        try
          InstructGuideComboboxini.Combobox[I].List[I2].Value := Strtoint(strlist.Strings[I2 * 2]);
        except
          InstructGuideComboboxini.Combobox[I].List[I2].Value := 0;
        end;
        InstructGuideComboboxini.Combobox[I].List[I2].Str := strlist.Strings[I2 * 2 + 1];
      end;
    end;

    strlist.Free;
    ini.Free;
    result := true;
  except
    showmessage('读取指令配置文件失败！');
    exit;
  end;
end;

function TForm7.readkdef: boolean;
var
  offset: array of integer;
  I,Fidx, Fgrp,temp, len, amount: integer;
begin
  result := false;
  if fileexists(gamepath + kdefidx) and fileexists(gamepath + kdefgrp) then
  begin
    try
      Fidx := fileopen(gamepath + kdefidx, fmopenread);
      Fgrp := fileopen(gamepath + kdefgrp, fmopenread);
      len := fileseek(Fidx,0,2);
      fileseek(fidx,0,0);
      eventamount := len shr 2;
      setlength(offset,len shr 2 + 1);
      fileread(fidx,offset[1],len);
      fileclose(Fidx);
      offset[0] := 0;
      setlength(Kevent, eventamount);
      for I := 0 to len shr 2 - 1 do
      begin
        fileseek(fgrp,offset[I],0);
        temp := 0;
        amount := 0;
        Kevent[I].datalen := offset[I + 1] - offset[I];
        setlength(Kevent[I].data, Kevent[I].datalen);
        fileread(Fgrp, Kevent[I].data[0], Kevent[I].datalen);
       { while (temp < (offset[I + 1] - offset[I])) do
        begin
          inc(amount);
          setlength(Kevent[I].attrib, amount);
          fileread(Fgrp ,Kevent[I].attrib[amount - 1].attribnum, 2);
          inc(temp, 2);
          if Kevent[I].attrib[amount - 1].attribnum < Kdefini.KDEFnum then
          begin
            if (Kevent[I].attrib[amount - 1].attribnum >=0) then
            begin
              Kevent[I].attrib[amount - 1].parcount := kdefini.KDEFitem[Kevent[I].attrib[amount - 1].attribnum].paramount;
              setlength(Kevent[I].attrib[amount - 1].par, Kevent[I].attrib[amount - 1].parcount);
              Kevent[I].attrib[amount - 1].par[0] := Kevent[I].attrib[amount - 1].attribnum;
              if Kevent[I].attrib[amount - 1].parcount > 1 then
                fileread(Fgrp, Kevent[I].attrib[amount - 1].par[1], Kevent[I].attrib[amount - 1].parcount * 2 - 2);

            end
            else
            begin
              //kdefini.KDEFitem[Kevent[I].attrib[amount - 1].attribnum].paramount := -1;
              Kevent[I].attrib[amount - 1].parcount := 1;
              setlength(Kevent[I].attrib[amount - 1].par, Kevent[I].attrib[amount - 1].parcount);
              Kevent[I].attrib[amount - 1].par[0] := -1;
            end;
          end
          else
          begin
            Kevent[I].attrib[amount - 1].parcount := 1;
            setlength(Kevent[I].attrib[amount - 1].par, 1);
            Kevent[I].attrib[amount - 1].par[0] := Kevent[I].attrib[amount - 1].attribnum;
          end;
          inc(temp,Kevent[I].attrib[amount - 1].parcount * 2 - 2);
        end;}
        //Kevent[I].attribamount := amount;
      end;
      fileclose(Fgrp);
      result := true;
    except
      showmessage('读取事件文件失败！');
      exit;
    end;
  end
  else
    showmessage('事件文件不存在！');
end;

procedure TForm7.arrangekdef;
var
  I: integer;
begin
  //
  combobox2.Clear;
  for I := 0 to eventamount - 1 do
  begin
    combobox2.Items.Add(inttostr(I));
  end;

end;

procedure clearIct(Ict: Pattrib);
begin
  ict.attribnum := 0;
  ict.parcount := 0;
  ict.labelstatus := 0;
  ict.labelway := 0;
  ict.labelfrom := 0;
  ict.labelto := 0;
  setlength(ict.par, 0);
end;

//(修改中)显示第num个事件，并把num事件内容保存到noworievent 并且带有label地添加到nowevent
procedure TForm7.calevent(noworievent, nowevent: Pevent);
var
  I1, I2, I3, temp: integer;
  tempict: Tattrib;
begin
  copyevent(nowevent, noworievent);
  //labelnum := -1;
  temp := 0;
  for I1 := 0 to nowevent.attribamount - 1 do
  begin
    if kdefini.KDEFitem[nowevent.attrib[i1].attribnum].ifjump = 1 then
    begin
      nowevent.attrib[i1].labelstatus := temp;
      nowevent.attrib[i1].labelto := -1;
      inc(temp);
      if nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].yesjump] <> 0 then
      begin
        nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].nojump] := 0;
        nowevent.attrib[i1].labelway := 1;
      end
      else if nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].nojump] <> 0 then
      begin
        nowevent.attrib[i1].labelway := -1;
      end
      else
      begin
        nowevent.attrib[i1].labelway := 1;
      end;
    end
    else
    begin
      nowevent.attrib[i1].labelstatus := -2;
    end;
  end;
  labelnum := temp - 1;
  I1 := 0;
  while true do
  begin
    if I1 >= nowevent.attribamount then
      break;
    if (nowevent.attrib[I1].labelstatus >= 0) and (nowevent.attrib[I1].labelto < 0) then
    begin
      nowevent.attrib[I1].labelto := nowevent.attrib[I1].labelstatus;
      if nowevent.attrib[I1].par[kdefini.KDEFitem[nowevent.attrib[I1].attribnum].yesjump] <> 0 then
        temp := nowevent.attrib[I1].par[kdefini.KDEFitem[nowevent.attrib[I1].attribnum].yesjump]
      else if nowevent.attrib[I1].par[kdefini.KDEFitem[nowevent.attrib[I1].attribnum].nojump] <> 0 then
        temp := nowevent.attrib[I1].par[kdefini.KDEFitem[nowevent.attrib[I1].attribnum].nojump]
      else
      begin
        if nowevent.attrib[I1].labelway > 0 then
        begin
          temp := nowevent.attrib[I1].par[kdefini.KDEFitem[nowevent.attrib[I1].attribnum].yesjump];
          nowevent.attrib[I1].labelway := 1;
        end
        else if nowevent.attrib[I1].labelway < 0 then
        begin
          temp := nowevent.attrib[I1].par[kdefini.KDEFitem[nowevent.attrib[I1].attribnum].nojump];
          nowevent.attrib[I1].labelway := -1;
        end;
      end;

      if temp >= 0 then
      begin
        I2 := 0;
        I3 := I1 + 1;
        while (I2 < temp) do
        begin
          if I3 > nowevent.attribamount - 1 then
          begin
            break;
          end;
          if nowevent.attrib[I3].labelstatus <> -1 then
            inc(I2, nowevent.attrib[I3].parcount);
          inc(I3);
        end;
      end
      else
      begin
        I2 := 0;
        I3 := I1 + 1;
        while (I2 > temp) do
        begin
          dec(I3);
          if I3 < 0 then
          begin
            I3 := 0;
            break;
          end;
          if nowevent.attrib[I3].labelstatus <> -1 then
          begin
            dec(I2, nowevent.attrib[I3].parcount);
          end;
        end;
      end;
      if temp <> I2 then
      begin
        if nowevent.attrib[i1].labelway > 0 then
        begin
          nowevent.attrib[I1].par[kdefini.KDEFitem[nowevent.attrib[I1].attribnum].yesjump] := I2;
          nowevent.attrib[I1].par[kdefini.KDEFitem[nowevent.attrib[I1].attribnum].nojump] := 0;
        end
        else if nowevent.attrib[i1].labelway < 0 then
        begin
          nowevent.attrib[I1].par[kdefini.KDEFitem[nowevent.attrib[I1].attribnum].yesjump] := 0;
          nowevent.attrib[I1].par[kdefini.KDEFitem[nowevent.attrib[I1].attribnum].nojump] := I2;
        end;
      end;
      ClearICT(@tempIct);
      tempIct.labelstatus := -1;
      tempIct.labelfrom := nowevent.attrib[I1].labelstatus;
      AddIct(nowevent, @tempict, I3);
    end;

    inc(I1);
  end;

end;

//(原始)显示第num个事件，并把num事件内容保存到noworievent 并且带有label地添加到nowevent
procedure TForm7.calKdef(noworievent, nowevent: Pevent);
var
  I1,i2,i3,temp, attribnum, tempamount,bytenum, newattribnum: integer;
  tempevent1, tempevent2: Tevent;
  tempattrib: Tattrib;
  cancontinue: boolean;
begin
  //

  tempamount := noworievent.attribamount;
  tempamount := 0;
  for i1 := 0 to noworievent.attribamount - 1 do
  begin
    if (noworievent.attrib[i1].attribnum >= 0) and (noworievent.attrib[i1].attribnum < kdefini.KDEFnum) then
    begin
      if kdefini.KDEFitem[noworievent.attrib[i1].attribnum].ifjump = 1 then
        inc(tempamount);
    end;
  end;
  //setlength(nowevent.attrib, nowevent.attribamount);
  copyevent(nowevent,noworievent);
 // edit2.Text := inttostr(noworievent.attribamount) + ' '+ inttostr(tempamount) + ' ' + inttostr(kdefini.KDEFitem[noworievent.attrib[0].attribnum].ifjump);
  newattribnum := noworievent.attribamount + tempamount;
 // setlength(nowevent.attrib, nowevent.attribamount);
  cancontinue := true;
  for i1 := 0 to nowevent.attribamount - 1 do
    nowevent.attrib[i1].labelstatus := -2;
  tempamount := noworievent.attribamount;
  labelnum := -1;
  while cancontinue do
  begin
    cancontinue := false;
    for i1 := 0 to nowevent.attribamount - 1 do
    begin
      if (nowevent.attrib[i1].attribnum >= 0) and (nowevent.attrib[i1].attribnum < kdefini.KDEFnum) then
      begin
        if (nowevent.attrib[i1].labelstatus = -2) and (kdefini.KDEFitem[nowevent.attrib[i1].attribnum].ifjump = 1) then
        begin


          //若需添加标签，是则跳转
          if (nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].yesjump] <> 0) then
          begin
            nowevent.attrib[i1].labelstatus := nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].yesjump];
            if nowevent.attrib[i1].labelstatus > 0 then
            begin
              bytenum := 0;
              attribnum := 0;
              for i2 := I1 + 1 to nowevent.attribamount - 1 do
              begin
                if bytenum >= nowevent.attrib[i1].labelstatus then
                begin
                  break;
                end;
                if nowevent.attrib[i2].labelstatus <> -1 then
                begin
                  inc(bytenum, nowevent.attrib[i2].parcount);
                  inc(attribnum);
                end;
              end;
              cancontinue := true;
              inc(tempamount);
              if tempamount = newattribnum then
                cancontinue := false;
              inc(labelnum);
              tempattrib.attribnum := 0;
              tempattrib.parcount := 0;
              tempattrib.labelstatus := -1;
              tempattrib.labelfrom := labelnum;
              nowevent.attrib[i1].labelway := 1;
              nowevent.attrib[i1].labelstatus := labelnum;
              nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].yesjump] := bytenum;
              nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].Nojump] := 0;
              nowevent.attrib[i1].labelto := labelnum;
              addattrib(nowevent,@tempattrib,i1 + 1 + attribnum);
            end
            else
            begin
              bytenum := 0;
              attribnum := 0;
              for i2 := I1 downto 0 do
              begin
                if bytenum >= abs(nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].yesjump]) then
                begin
                  break;
                end;
                if nowevent.attrib[i1].labelstatus <> -1 then
                begin
                  inc(bytenum, nowevent.attrib[i2].parcount);
                  inc(attribnum);
                end;
              end;
              cancontinue := true;
              inc(tempamount);
              if tempamount = newattribnum then
                cancontinue := false;
              inc(labelnum);
              tempattrib.attribnum := 0;
              tempattrib.parcount := 0;
              tempattrib.labelstatus := -1;
              tempattrib.labelfrom := labelnum;
              nowevent.attrib[i1].labelway := 1;
              nowevent.attrib[i1].labelstatus := labelnum;
              nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].yesjump] := - bytenum;
              nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].Nojump] := 0;
              nowevent.attrib[i1].labelto := labelnum;
              addattrib(nowevent,@tempattrib,i1 + 1 - attribnum);
            end;
          end
          else if (nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].Nojump] <> 0) then
          begin
            nowevent.attrib[i1].labelstatus := nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].Nojump];
            if nowevent.attrib[i1].labelstatus > 0 then
            begin
              bytenum := 0;
              attribnum := 0;
              for i2 := I1 + 1 to nowevent.attribamount - 1 do
              begin
                if bytenum >= nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].Nojump] then
                begin
                  break;
                end;
                if nowevent.attrib[i2].labelstatus <> -1 then
                begin
                  inc(bytenum, nowevent.attrib[i2].parcount);
                  inc(attribnum);
                end;
              end;
              cancontinue := true;
              inc(tempamount);
              if tempamount = newattribnum then
                cancontinue := false;
              inc(labelnum);
              tempattrib.attribnum := 0;
              tempattrib.parcount := 0;
              tempattrib.labelstatus := -1;
              tempattrib.labelfrom := labelnum;
              nowevent.attrib[i1].labelway := -1;
              nowevent.attrib[i1].labelstatus := labelnum;
              nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].Nojump] := bytenum;
              nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].yesjump] := 0;
              nowevent.attrib[i1].labelto := labelnum;
              addattrib(nowevent,@tempattrib,i1 + 1 + attribnum);
            end
            else
            begin
              bytenum := 0;
              attribnum := 0;
              for i2 := I1 downto 0 do
              begin
                if bytenum >= abs(nowevent.attrib[i1].labelstatus) then
                begin
                  break;
                end;
                if nowevent.attrib[i2].labelstatus <> -1 then
                begin
                  inc(bytenum, nowevent.attrib[i2].parcount);
                  inc(attribnum);
                end;
              end;
              cancontinue := true;
              inc(tempamount);
              if tempamount = newattribnum then
                cancontinue := false;
              inc(labelnum);
              tempattrib.attribnum := 0;
              tempattrib.parcount := 0;
              tempattrib.labelstatus := -1;
              tempattrib.labelfrom := labelnum;
              nowevent.attrib[i1].labelway := -1;
              nowevent.attrib[i1].labelstatus := labelnum;
              nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].Nojump] := - bytenum;
              nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].yesjump] := 0;
              nowevent.attrib[i1].labelto := labelnum;
              addattrib(nowevent,@tempattrib,i1 + 1 - attribnum);
            end;
          end
          else
          begin
            cancontinue := true;
            inc(tempamount);
              if tempamount = newattribnum then
                cancontinue := false;
            inc(labelnum);
            tempattrib.attribnum := 0;
            tempattrib.parcount := 0;
            tempattrib.labelstatus := -1;
            tempattrib.labelfrom := labelnum;
            nowevent.attrib[i1].labelway := 1;
            nowevent.attrib[i1].labelstatus := labelnum;
            nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].Nojump] := 0;
            nowevent.attrib[i1].par[kdefini.KDEFitem[nowevent.attrib[i1].attribnum].yesjump] := 0;
            nowevent.attrib[i1].labelto := labelnum;
            addattrib(nowevent,@tempattrib,i1 + 1);
          end;
          //添加了标签重排
          break;
        end;
      end;
      //else

    end;
  end;
 // edit2.Text := edit2.Text +' '+ inttostr(labelnum);
end;

procedure TForm7.displayevent;
var
  I: integer;
begin
  //
  listbox1.Clear;
  //edit1.Text := inttostr(nowevent.attribamount) + ' ' + inttostr(Kevent[1].attrib[0].attribnum) + ' ' + inttostr(Kevent[1].attrib[1].attribnum);
  for I := 0 to nowevent.attribamount - 1 do
    listbox1.Items.Add(calattribname(@nowevent.attrib[I]));
end;

function TForm7.InstructGuide(atrb: Pattrib): integer;
var
  GuideForm: TinctGuide;
  I, I2: integer;
  panelWidth: integer;
  panelLeft: integer;
  tempway1, tempway2, tempstatus: integer;
const
  panelHeight: integer = 60;
  PanelLeftConst: integer = 10;
  formWidth: integer = 800;
  linepanelnum: integer = 4;
begin
  //
  result := 0;
  if (atrb.attribnum < 0) or (atrb.attribnum >= InstructGuideini.Amount) then
    exit;
  if atrb.parcount <= 1 then
    exit;
  if InstructGuideini.Instruct[atrb.attribnum].NeedGuide = 0 then
    exit;
  try
    panelWidth := formWidth div linepanelnum;
    panelLeft := PanelLeftConst;
    panelLeft := min(panelWidth div 4, panelLeft);
    Application.CreateForm(TinctGuide, GuideForm);
    if kdefini.KDEFitem[atrb.attribnum].ifjump = 0 then
      GuideForm.Panel3.Visible := false;
    GuideYesJump := kdefini.KDEFitem[atrb.attribnum].yesjump - 1;
    GuideNoJump := kdefini.KDEFitem[atrb.attribnum].nojump - 1;
    GuideForm.ClientWidth := formWidth;
    GuideForm.ClientHeight := panelHeight * ((atrb.parcount - 1) div linepanelnum + 1) + GuideForm.Panel1.Height;
    if GuideForm.Panel3.Visible then
      GuideForm.ClientHeight := GuideForm.ClientHeight + GuideForm.Panel3.Height;

    tempstatus := atrb.labelstatus;
    if tempstatus >= 0 then
    begin
      if atrb.labelway >= 0 then
      begin
        tempway1 := atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump];
      end
      else
      begin
        tempway1 := atrb.par[kdefini.KDEFitem[atrb.attribnum].nojump];
      end;
    end;

    setlength(GuidePanel, atrb.parcount - 1);
    setlength(GuideEdit, atrb.parcount - 1);
    setlength(GuideLabel, atrb.parcount - 1);
    setlength(GuideCombobox, atrb.parcount - 1);
    setlength(GuideisCombobox, atrb.parcount - 1);
    for I := 0 to atrb.parcount - 1 - 1 do
    begin
      GuidePanel[I] := TPanel.Create(GuideForm);
      GuidePanel[I].Parent := GuideForm.Panel2;
      GuidePanel[I].Caption := '';
      GuidePanel[I].Width := panelWidth;
      GuidePanel[I].Height := panelHeight;
      GuidePanel[I].Top := (I div linepanelnum) * panelHeight;
      GuidePanel[I].Left := (I mod linepanelnum) * panelWidth;
      GuidePanel[I].Visible := true;

      GuideLabel[I] := TLabel.Create(GuideForm);
      GuideLabel[I].Parent := GuidePanel[I];
      GuideLabel[I].Top := 0;
      GuideLabel[I].Left := panelLeft;
      GuideLabel[I].AutoSize := false;
      GuideLabel[I].Width := panelWidth - panelLeft * 2;
      GuideLabel[I].Caption := InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteLabel;
      GuideLabel[I].Visible := true;

      GuideCombobox[I] := TCombobox.Create(GuideForm);
      GuideCombobox[I].Parent := GuidePanel[I];
      GuideCombobox[I].Top := PanelHeight div 2;
      GuideCombobox[I].Left := panelLeft;
      GuideCombobox[I].Width := panelWidth - panelLeft * 2;
      GuideCombobox[I].Style := csDropDownList;

      GuideisCombobox[I] := 0;
      if (InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteType = 1)
      and (InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteCount >= 0)
      and (InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteCount < useR.typenumber) then
      begin
        GuideisCombobox[I] := InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteType;
        GuideCombobox[I].Items.Add('-2保持不变');
        GuideCombobox[I].Items.Add('-1无');
        for I2 := 0 to useR.Rtype[InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteCount].datanum - 1 do
        begin
          GuideCombobox[I].Items.Add(calrname(InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteCount, I2));
        end;
        GuideCombobox[I].ItemIndex := max(atrb.par[I + 1] + 2, 0);
      end
      else if (InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteType = 2) then
      begin
        GuideisCombobox[I] := InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteType;
        GuideCombobox[I].Items.Add('-2保持不变');
        GuideCombobox[I].Items.Add('-1无');
        for I2 := 0 to useW.Wtype.datanum - 1 do
        begin
          GuideCombobox[I].Items.Add(calWname(I2));
        end;
        GuideCombobox[I].ItemIndex := max(atrb.par[I + 1] + 2, 0);
      end
      else if (InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteType = 3) then
      begin
        GuideisCombobox[I] := InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteType;
        for I2 := 0 to talkstrnum - 1 do
          GuideCombobox[I].Items.Add(inttostr(I2) + readtalkstr(@talkstr[I2]));
        GuideCombobox[I].ItemIndex := max(atrb.par[I + 1], 0);
      end
      else if (InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteType = 4) then
      begin
        GuideisCombobox[I] := InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteType;
        for I2 := 0 to namestrnum - 1 do
          GuideCombobox[I].Items.Add(inttostr(I2) + readtalkstr(@namestr[I2]));
        GuideCombobox[I].ItemIndex := max(atrb.par[I + 1], 0);
      end
      else if (InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteType = 5) then
      begin
        if (InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteCount >= 0)
        and (InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteCount < InstructGuideComboboxini.Amount) then
        begin
          GuideisCombobox[I] := InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteType;
          for I2 := 0 to InstructGuideComboboxini.Combobox[InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteCount].ListAmount - 1 do
            GuideCombobox[I].Items.Add(inttostr(InstructGuideComboboxini.Combobox[InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteCount].List[I2].Value) + InstructGuideComboboxini.Combobox[InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteCount].List[I2].Str);
          GuideCombobox[I].ItemIndex := 0;
          for I2 := 0 to InstructGuideComboboxini.Combobox[InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteCount].ListAmount - 1 do
            if atrb.par[I + 1] = InstructGuideComboboxini.Combobox[InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteCount].List[I2].Value then
            begin
              GuideCombobox[I].ItemIndex := I2;
              break;
            end;
        end;
      end;

      GuideCombobox[I].Visible := (GuideisCombobox[I] <> 0);

      if not GuideCombobox[I].Visible then
      begin
        GuideEdit[I] := TEdit.Create(GuideForm);
        GuideEdit[I].Parent := GuidePanel[I];
        GuideEdit[I].Top := PanelHeight div 2;
        GuideEdit[I].Left := panelLeft;
        GuideEdit[I].Width := panelWidth - panelLeft * 2;
        GuideEdit[I].Text := inttostr(atrb.par[I + 1]);
      end;
    end;

    if GuideForm.Panel3.Visible then
    begin
      if atrb.labelway >= 0 then
        GuideForm.RadioGroup1.ItemIndex := 0
      else
        GuideForm.RadioGroup1.ItemIndex := 1;
      GuideJumpIndex := GuideForm.RadioGroup1.ItemIndex;
    end;

    GuideForm.Button1.Left := Panelwidth;
    GuideForm.Button2.Left := formwidth - Panelwidth - GuideForm.Button2.Width;

    if GuideForm.ShowModal = mrOK then
    begin
      for I := 0 to atrb.parcount - 1 - 1 do
      begin
        case GuideisCombobox[I] of
          0:
            begin
              try
                atrb.par[I + 1] := strtoint(GuideEdit[I].Text);
              except
                //atrb.par[I + 1] := 0;
              end;
            end;
          1, 2: atrb.par[I + 1] := max(GuideCombobox[I].ItemIndex, 0) - 2;
          3, 4: atrb.par[I + 1] := max(GuideCombobox[I].ItemIndex, 0);
          5:
            begin
              if GuideCombobox[I].ItemIndex >= 0 then
              begin
                try
                 atrb.par[I + 1] := InstructGuideComboboxini.Combobox[InstructGuideini.Instruct[atrb.attribnum].Param[I + 1].QuoteCount].List[GuideCombobox[I].ItemIndex].Value;
                except

                end;
              end;
            end;
        end;
      end;
      if GuideForm.Panel3.Visible then
      begin
        if (GuideForm.RadioGroup1.ItemIndex = 0) and (atrb.labelway < 0) then
        begin
          atrb.labelway := 1;
          //atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] := atrb.par[kdefini.KDEFitem[atrb.attribnum].nojump];
          atrb.par[kdefini.KDEFitem[atrb.attribnum].nojump] := 0;
        end
        else if (GuideForm.RadioGroup1.ItemIndex = 1) and (atrb.labelway > 0) then
        begin
          atrb.labelway := -1;
          //atrb.par[kdefini.KDEFitem[atrb.attribnum].nojump] := atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump];
          atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] := 0;
        end;

      end;

      tempway2 := 0;
      if tempstatus >= 0 then
      begin
        if atrb.labelway >= 0 then
        begin
          tempway2 := atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump];
        end
        else
        begin
          tempway2 := atrb.par[kdefini.KDEFitem[atrb.attribnum].nojump];
        end;
        if (tempway2 < 0) and (tempway1 >= 0) then
          result := 1
        else if (tempway2 >= 0) and (tempway1 < 0) then
          result := -1;
      end;

    end;
  finally
    if GuideForm <> nil then
    begin
      GuideForm.Close;
      GuideForm.Free;
      GuideForm := nil;
    end;
  end;
end;

function CalInstructGuideParamName(atrb: Pattrib; param: integer): widestring;
var
  I: integer;
begin
  //
  result := '[]';
  if (atrb.attribnum < 0) or (atrb.attribnum >= InstructGuideini.Amount) then
    exit;
  if InstructGuideini.Instruct[atrb.attribnum].NeedGuide = 0 then
    exit;
  if (param < 0) or (param >= InstructGuideini.Instruct[atrb.attribnum].ParamAmount) then
    exit;
  if InstructGuideini.Instruct[atrb.attribnum].Param[param].QuoteType = 0 then
    result := '[' + inttostr(atrb.par[param]) + ']'
  else if InstructGuideini.Instruct[atrb.attribnum].Param[param].QuoteType = 1 then
    result := '[' + calRname(InstructGuideini.Instruct[atrb.attribnum].Param[param].QuoteCount, atrb.par[param]) + ']'
  else if InstructGuideini.Instruct[atrb.attribnum].Param[param].QuoteType = 2 then
    result := '[' + calWname(atrb.par[param]) + ']'
  else if InstructGuideini.Instruct[atrb.attribnum].Param[param].QuoteType = 3 then
  begin
    if (atrb.par[param] >= 0) and (atrb.par[param] < talkstrnum) then
      result := '[' + readtalkstr(@talkstr[atrb.par[param]]) + ']';
  end
  else if InstructGuideini.Instruct[atrb.attribnum].Param[param].QuoteType = 4 then
  begin
    if (atrb.par[param] >= 0) and (atrb.par[param] < namestrnum) then
      result := '[' + readtalkstr(@namestr[atrb.par[param]]) + ']';
  end
  else if InstructGuideini.Instruct[atrb.attribnum].Param[param].QuoteType = 5 then
  begin
    if (InstructGuideini.Instruct[atrb.attribnum].Param[param].QuoteCount >= 0) and
       (InstructGuideini.Instruct[atrb.attribnum].Param[param].QuoteCount < InstructGuideComboboxini.Amount) then
    begin
      for I := 0 to InstructGuideComboboxini.Combobox[InstructGuideini.Instruct[atrb.attribnum].Param[param].QuoteCount].ListAmount - 1 do
      begin
        if atrb.par[param] = InstructGuideComboboxini.Combobox[InstructGuideini.Instruct[atrb.attribnum].Param[param].QuoteCount].List[I].Value then
        begin
          result := '[' + inttostr(InstructGuideComboboxini.Combobox[InstructGuideini.Instruct[atrb.attribnum].Param[param].QuoteCount].List[I].Value)
                    + InstructGuideComboboxini.Combobox[InstructGuideini.Instruct[atrb.attribnum].Param[param].QuoteCount].List[I].Str + ']';
          break;
        end;
      end;
    end;
  end;
end;

function CalInstructGuideName(atrb: Pattrib): widestring;
var
  I: integer;
  tempstr, tempstr1, tempstr2: String;
begin
  //
  result := '';
  if (atrb.attribnum < 0) or (atrb.attribnum >= InstructGuideini.Amount) then
    exit;
  if InstructGuideini.Instruct[atrb.attribnum].NeedGuide = 0 then
    exit;
  tempstr := InstructGuideini.Instruct[atrb.attribnum].GuideStr;
  for I := 0 to atrb.parcount - 1 do
  begin
    tempstr1 := '[Quote_Param_' + inttostr(I) + ']';
    tempstr2 := CalInstructGuideParamName(atrb, I);
    tempstr := StringReplace(tempstr, tempstr1, tempstr2, [rfReplaceAll]);
  end;
  if atrb.labelway <> 0 then
  begin
    if atrb.labelway > 0 then
      tempstr := tempstr + ';满足条件'
    else
      tempstr := tempstr + ';不满足条件';
    tempstr := tempstr + '则跳转Label' + inttostr(atrb.labelstatus);
  end;
  result := tempstr;
end;

function GetInstructNeedGuide(atrb: Pattrib): Boolean;
begin
  //
  result := false;
  if (atrb.attribnum < 0) or (atrb.attribnum >= InstructGuideini.Amount) then
    exit;
  if InstructGuideini.Instruct[atrb.attribnum].NeedGuide <> 0 then
    result := true;
end;

function calattribname(atrb: Pattrib): widestring;
var
  I, temp: integer;
  tempstr: widestring;
begin
  if atrb.labelstatus = -1 then
  begin
    result := ';Label'+ inttostr(atrb.labelfrom);
  end
  else if GetInstructNeedGuide(atrb) then
  begin
    result := '   '+ CalInstructGuideName(atrb);
  end
  else
  begin

    temp := atrb.attribnum;
    //result := '   '+ inttostr(atrb.attribnum) + '(' + Format('%x', [temp and $FFFF])+ '):';
    result := '   ['+ inttostr(atrb.attribnum) + ']:';
    case atrb.attribnum of
      -1:
        begin
          result := result + '事件结束';
        end;
      1:
        begin
          result := result + '[' + calRname(1, atrb.par[2]) + ']:';
          try
            result := result + displaystr(readtalkstr(@talkstr[word(atrb.par[1])]));
          except

          end;
        end;
      2:
        begin
          result := result + '得到物品['+ calRname(2, atrb.par[1]) + ']' + inttostr(atrb.par[2]) + '个';
        end;
      3:
        begin
          if atrb.par[1] = -2 then
            result := result + widestring('修改事件定义:当前场景')
          else
            result := result + widestring('修改事件定义:场景[') + calRname(3, atrb.par[1]) + widestring(']:');
          if atrb.par[2] = -2 then
            result := result + widestring('当前场景事件编号')
          else
            result := result + widestring('场景事件编号[')+ inttostr(atrb.par[2]) + ']';
        end;
      4:
        begin
          result := result + '是否使用物品[' + calRname(2, atrb.par[1]) +']？';
          if atrb.labelway > 0 then
            result := result + '是'
          else
            result := result + '否';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);
        end;
      5:
        begin
          result := result + '是否选择战斗？';
          if atrb.labelway > 0 then
            result := result + '是'
          else
            result := result + '否';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);
        end;
      6:
        begin
          result := result + '战斗[' + CalWname(atrb.par[1]) +']';
          if atrb.labelway > 0 then
            result := result + ' 胜'
          else
            result := result + ' 负';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);

        end;
      8:
        begin
          result := result + '改变大地图音乐(音乐编号' + inttostr(atrb.par[1]) + ')';
        end;
      9:
        begin
          result := result + '询问是否加入？';
          if atrb.labelway > 0 then
            result := result + '是'
          else
            result := result + '否';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);
        end;
      10:
        begin
          result := result + '加入队员[' + calRname(1,atrb.par[1]) + ']';
        end;
      11:
        begin
          result := result + '询问是否住宿？';
          if atrb.labelway > 0 then
            result := result + '是'
          else
            result := result + '否';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);
        end;
      16:
        begin
          result := result + '判断队伍是否有[' + calRname(1, atrb.par[1]) + ']?';
          if atrb.labelway > 0 then
            result := result + '是'
          else
            result := result + '否';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);
        end;
      17:
        begin
          result := result + '修改场景贴图:场景[' + calRname(3,atrb.par[1]) + ']层:' + inttostr(atrb.par[2]) + '坐标' + inttostr(atrb.par[3]) + '-' + inttostr(atrb.par[4]) + '贴图编号' + inttostr(atrb.par[5]);
        end;
      18:
        begin
          result := result + '判断是否有物品[' + calRname(2, atrb.par[1]) + ']';
          if atrb.labelway > 0 then
            result := result + '有'
          else
            result := result + '没有';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);
        end;
      19:
        begin
          result := result + '主角移动至' + inttostr(atrb.par[1]) + '-' + inttostr(atrb.par[2]);
        end;
      20:
        begin
          result := result + '判断队伍是否已满';
          if atrb.labelway > 0 then
            result := result + '已满'
          else
            result := result + '不满';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);
        end;
      21:
        begin
          result := result + '[' + calRname(1,atrb.par[1]) + ']离队';
        end;
      23:
        begin
          result := result + '设置人物[' + calRname(1, atrb.par[1])+ ']用毒能力[' + inttostr(atrb.par[2]) + ']';
        end;
      25:
        begin
          result := result + '场景移动' + inttostr(atrb.par[1]) + '-' + inttostr(atrb.par[2]) + '--' + inttostr(atrb.par[3]) + '-' + inttostr(atrb.par[4]);
        end;
      28:
        begin
          result := result + '判断['+calRname(1,atrb.par[1])+']道德' + inttostr(atrb.par[2]) + '-' + inttostr(atrb.par[3]);
          if atrb.labelway > 0 then
            result := result + '在范围内'
          else
            result := result + '不在范围内';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);
        end;
      29:
        begin
          result := result + '判断['+calRname(1,atrb.par[1])+']武力' + inttostr(atrb.par[2]) + '-' + inttostr(atrb.par[3]);
          if atrb.labelway > 0 then
            result := result + '在范围内'
          else
            result := result + '不在范围内';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);
        end;
      30:
        begin
           result :=result + '主角走动' + inttostr(atrb.par[1]) + '-' + inttostr(atrb.par[2]) + '--' + inttostr(atrb.par[3]) + '-' + inttostr(atrb.par[4]);
        end;
      31:
        begin
          result :=result + '判断银子是否够[' + inttostr(atrb.par[1]) + ']';
          if atrb.labelway > 0 then
            result := result + '是'
          else
            result := result + '否';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);
        end;
      32:
        begin
          result := result + '[' + calRname(2,atrb.par[1]) + ']增加[' + inttostr(atrb.par[2]) + ']个';
        end;
      33:
        begin
          result := result + '[' + calRname(1, atrb.par[1]) +']学会[' + calRname(4, atrb.par[2]) + ']';
        end;
      34:
        begin
          result := result + '[' + calRname(1,atrb.par[1]) + ']增加资质[' + inttostr(atrb.par[2]) + ']';
        end;
      35:
        begin
          result := result + '设置[' + calRname(1,atrb.par[1]) + ']武功[' + inttostr(atrb.par[2]) +']为[' + calRname(4, atrb.par[3]) + ']经验为' + inttostr(atrb.par[4]);
        end;
      36:
        begin
          if atrb.par[1] >= 256 then
          begin
            result := result + 'JMP是否为0?';
            if atrb.labelway > 0 then
              result := result + '是'
            else
              result := result + '否';
            result := result + '则跳转Label' + inttostr(atrb.labelstatus);
          end
          else
          begin
            result := result + '主角性别是否为[' + inttostr(atrb.par[1]) +']?';
            if atrb.labelway > 0 then
              result := result + '是'
            else
              result := result + '否';
            result := result + '则跳转Label' + inttostr(atrb.labelstatus);
          end;
        end;
      37:
        begin
          result := result + '增加道德' + inttostr(atrb.par[1]);
        end;
      38:
        begin
          result := result + '修改场景[' + calRname(3,atrb.par[1]) + ']层' + inttostr(atrb.par[2]) + '原贴图' + inttostr(atrb.par[3]) + '变为' + inttostr(atrb.par[4]);
        end;
      39:
        begin
          result := result + '打开场景[' + calRname(3,atrb.par[1]) + ']';
        end;
      40:
        begin
          result := result + '主角站立方向' + inttostr(atrb.par[1]);
        end;
      41:
        begin
          result := result + '[' + calRname(1,atrb.par[1]) + ']得到物品[' + calRname(2,atrb.par[2])+']数量[' + inttostr(atrb.par[3]) + ']';
        end;
      42:
        begin
          result := result + '队伍中是否有女性？';
          if atrb.labelway > 0 then
            result := result + '是'
          else
            result := result + '否';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);
        end;
      43:
        begin
          result := result + '是否有物品[' + calRname(2, atrb.par[1]) +']?';
          if atrb.labelway > 0 then
            result := result + '是'
          else
            result := result + '否';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);
        end;
      45:
        begin
          result := result + '['+ CalRname(1,atrb.par[1])+']增加轻功' + inttostr(atrb.par[2]);
        end;
      46:
        begin
          result := result + '['+ CalRname(1,atrb.par[1])+']增加内力' + inttostr(atrb.par[2]);
        end;
      47:
        begin
          result := result + '['+ CalRname(1,atrb.par[1])+']增加武功' + inttostr(atrb.par[2]);
        end;
      48:
        begin
          result := result + '['+ CalRname(1,atrb.par[1])+']增加生命' + inttostr(atrb.par[2]);
        end;
      49:
        begin
          result :=  result + '['+ CalRname(1,atrb.par[1])+']内力属性' + inttostr(atrb.par[2]);
        end;
      50:
        begin
          case atrb.par[1] of
            0:
              begin
                result := result + '变量赋值[x' + inttostr(atrb.par[2]) + ']=' + inttostr(atrb.par[3]);
              end;
            1:
              begin
                result := result + '数组变量赋值 数组' + inttostr(atrb.par[4]);
                if ((atrb.par[2] and 1) = 1) then
                  result := result  + '([X' + inttostr(atrb.par[5])+'])='
                else
                  result := result  + '(' + inttostr(atrb.par[5])+')=';
                if ((atrb.par[2] and 2) = 2) then
                  result := result  + '[X' + inttostr(atrb.par[6])+']'
                else
                  result := result  + inttostr(atrb.par[6]);
                if atrb.par[3] = 0 then
                  result := result + '(Int)'
                else
                  result := result + '(byte)';
              end;
            2:
              begin
                result := result + '数组变量取值' + '[X' + inttostr(atrb.par[6])+']=数组';
                result := result  + inttostr(atrb.par[4]);
                if ((atrb.par[2] and 1) = 1) then
                  result := result  + '([X' + inttostr(atrb.par[5])+'])'
                else
                  result := result  + '(' + inttostr(atrb.par[5])+')';
                if atrb.par[3] = 0 then
                  result := result + '(Int)'
                else
                  result := result + '(byte)';
              end;
            3:
              begin
                result := result + '四则运算 [X' + inttostr(atrb.par[4]) + ']=[X' + inttostr(atrb.par[5]) + ']';
                case atrb.par[3] of
                  0: result := result + '+';
                  1: result := result + '-';
                  2: result := result + '*';
                  3: result := result + '/';
                  4: result := result + 'mod';
                end;
                if ((atrb.par[2] and 1) = 0) then
                  result := result + inttostr(atrb.par[6])
                else
                  result := result + '[X' + inttostr(atrb.par[6])+']';
              end;
            4:
              begin
                result := result + '变量判断 ';
                case atrb.par[3] of
                  0:
                    begin
                      result := result + 'if [X' + inttostr(atrb.par[4]) + ']<';
                      if atrb.par[2] = 0 then
                        result := result + inttostr(atrb.par[5])
                      else
                        result := result +'[X' + inttostr(atrb.par[5]) +']';
                      result := result + ' then JMP=0，else JMP=1';
                    end;
                  1:
                    begin
                      result := result + 'if [X' + inttostr(atrb.par[4]) + ']<=';
                      if atrb.par[2] = 0 then
                        result := result + inttostr(atrb.par[5])
                      else
                        result := result +'[X' + inttostr(atrb.par[5]) +']';
                      result := result + ' then JMP=0，else JMP=1';
                    end;
                  2:
                    begin
                      result := result + 'if [X' + inttostr(atrb.par[4]) + ']=';
                      if atrb.par[2] = 0 then
                        result := result + inttostr(atrb.par[5])
                      else
                        result := result +'[X' + inttostr(atrb.par[5]) +']';
                      result := result + ' then JMP=0，else JMP=1';
                    end;
                  3:
                    begin
                      result := result + 'if [X' + inttostr(atrb.par[4]) + ']<>';
                      if atrb.par[2] = 0 then
                        result := result + inttostr(atrb.par[5])
                      else
                        result := result +'[X' + inttostr(atrb.par[5]) +']';
                      result := result + ' then JMP=0，else JMP=1';
                    end;
                  4:
                    begin
                      result := result + 'if [X' + inttostr(atrb.par[4]) + ']>=';
                      if atrb.par[2] = 0 then
                        result := result + inttostr(atrb.par[5])
                      else
                        result := result +'[X' + inttostr(atrb.par[5]) +']';
                      result := result + ' then JMP=0，else JMP=1';
                    end;
                  5:
                    begin
                      result := result + 'if [X' + inttostr(atrb.par[4]) + ']>';
                      if atrb.par[2] = 0 then
                        result := result + inttostr(atrb.par[5])
                      else
                        result := result +'[X' + inttostr(atrb.par[5]) +']';
                      result := result + ' then JMP=0，else JMP=1';
                    end;
                  6:
                    begin
                      result := result + ' JMP=0';
                    end;
                  7:
                    begin
                      result := result + ' JMP=1';
                    end;
                end;
              end;
            8:
              begin
                result := result + '读对话到字符串 str([X' + inttostr(atrb.par[4]) + ']=talk(';
                if atrb.par[2]=0 then
                  result := result + inttostr(atrb.par[3]) + ')'
                else
                  result := result + inttostr(atrb.par[3]) + '])';
              end;
            10:
              begin
                result := result + '取字符串长度 [X' + inttostr(atrb.par[3]) + ']=len(Str[X' + inttostr(atrb.par[2]) + ']';
              end;
            11:
              begin
                result := result + '字符串合并 Str[X' + inttostr(atrb.par[2]) + ']=Str[X' + inttostr(atrb.par[3]) + ']+Str[X' + inttostr(atrb.par[4]) + ']';
              end;
            12:
              begin
                result := result + '空格字符串 Str[X' + inttostr(atrb.par[3]) + ']=';
                if atrb.par[2]=0 then
                  result := result + inttostr(atrb.par[4]) +'个空格'
                else
                  result := result + '[X' + inttostr(atrb.par[4]) + ']个空格';
              end;
            16:
              begin
                result := result + '保存属性 ';
                case atrb.par[3] of
                  0: result := result + '人物';
                  1: result := result + '物品';
                  2: result := result + '场景';
                  3: result := result + '武功';
                end;
                if ((atrb.par[2] and 1) = 0) then
                begin
                  if CalRname(atrb.par[3], atrb.par[4]) = '' then
                    result := result + inttostr(atrb.par[4])
                  else
                    result := result +'[' + CalRname(atrb.par[3] + 1, atrb.par[4]) +']';
                end
                else
                begin
                  result := result + '[X' +  inttostr(atrb.par[4]) + ']';
                end;
                if ((atrb.par[2] and 2) = 0) then
                begin
                  result := result + '属性偏移' + inttostr(atrb.par[5]);
                end
                else
                  result := result + '属性偏移[X' +  inttostr(atrb.par[5]) + ']';
                if ((atrb.par[2] and 4) = 0) then
                begin
                  result := result + '=' + inttostr(atrb.par[6]);
                end
                else
                  result := result + '=[X' + inttostr(atrb.par[6]) + ']';
              end;
            17:
              begin
                result := result + '读取属性 ';
                case atrb.par[3] of
                  0: result := result + '人物';
                  1: result := result + '物品';
                  2: result := result + '场景';
                  3: result := result + '武功';
                end;
                result := result + '[X' + inttostr(atrb.par[6]) + ']=';
                if ((atrb.par[2] and 1) = 0) then
                begin
                  if CalRname(atrb.par[3], atrb.par[4]) = '' then
                    result := result + inttostr(atrb.par[4])
                  else
                    result := result +'[' + CalRname(atrb.par[3]+ 1, atrb.par[4]) +']';
                end
                else
                begin
                  result := result + '[X' +  inttostr(atrb.par[4]) + ']';
                end;
                if ((atrb.par[2] and 2) = 0) then
                begin
                  result := result + '属性偏移' + inttostr(atrb.par[5]);
                end
                else
                  result := result + '属性偏移[X' +  inttostr(atrb.par[5]) + ']';
              end;
            18:
              begin
                result := result + '保存队伍 队友';
                if ((atrb.par[2] and 1) = 0) then
                  result := result + inttostr(atrb.par[3])
                else
                  result := result + '[X' + inttostr(atrb.par[3]) + ']';
                if ((atrb.par[2] and 2) = 0) then
                  result := result + '=' + inttostr(atrb.par[4]) +calRname(1, atrb.par[4])
                else
                  result := result + '=[X' + inttostr(atrb.par[4]) + ']';
              end;
            19:
              begin
                result := result + '读取队伍 [X' + inttostr(atrb.par[4]) + ']=';
                if atrb.par[2] = 0 then
                  result := result + '队友' + inttostr(atrb.par[3])
                else
                  result := result + '队友[X' + inttostr(atrb.par[3]) + ']';
              end;
            20:
              begin
                result := result + '主角物品个数 [X' + inttostr(atrb.par[4]) + ']';
                if atrb.par[2] = 0 then
                  result := result + '=' + CalRname(2,atrb.par[3]) +'数量'
                else
                  result := result + '=物品编号[X' + inttostr(atrb.par[3]) + ']数量';
              end;
            21:
              begin
                result := result + '保存D*数据 ';
                if atrb.par[2] and 1 = 0 then
                  result := result + '场景' + inttostr(atrb.par[3])
                else
                  result := result + '场景[X' + inttostr(atrb.par[3]) + ']';
                if atrb.par[2] and 2 = 0 then
                  result := result + '场景事件' + inttostr(atrb.par[4])
                else
                  result := result + '场景事件[X' + inttostr(atrb.par[4]) + ']';
                if atrb.par[2] and 4 = 0 then
                  result := result + '属性' + inttostr(atrb.par[5])
                else
                  result := result + '属性[X' + inttostr(atrb.par[5]) + ']';
                result := result + '=';
                if atrb.par[2] and 8 = 0 then
                  result := result + inttostr(atrb.par[6])
                else
                  result := result + '[X' + inttostr(atrb.par[6]) + ']';
              end;
            22:
              begin
                result := result + '读取D*数据 ';
                result := result + '[X' + inttostr(atrb.par[6]) + ']';
                result := result + '=';
                if atrb.par[2] and 1 = 0 then
                  result := result + '场景' + inttostr(atrb.par[3])
                else
                  result := result + '场景[X' + inttostr(atrb.par[3]) + ']';
                if atrb.par[2] and 2 = 0 then
                  result := result + '场景事件' + inttostr(atrb.par[4])
                else
                  result := result + '场景事件[X' + inttostr(atrb.par[4]) + ']';
                if atrb.par[2] and 4 = 0 then
                  result := result + '属性' + inttostr(atrb.par[5])
                else
                  result := result + '属性[X' + inttostr(atrb.par[5]) + ']';
              end;
            23:
              begin
                result := result + '保存S*数据 ';
                if atrb.par[2] and 1 = 0 then
                  result := result + '场景' + inttostr(atrb.par[3])
                else
                  result := result + '场景[X' + inttostr(atrb.par[3]) + ']';
                if atrb.par[2] and 2 = 0 then
                  result := result + '层' + inttostr(atrb.par[4])
                else
                  result := result + '层[X' + inttostr(atrb.par[4]) + ']';
                if atrb.par[2] and 4 = 0 then
                  result := result + '坐标(' + inttostr(atrb.par[5])
                else
                  result := result + '坐标([X' + inttostr(atrb.par[5]) + ']';
                  if atrb.par[2] and 8 = 0 then
                  result := result + ',' + inttostr(atrb.par[6]) + ')'
                else
                  result := result + ',[X' + inttostr(atrb.par[6]) + '])';
                result := result + '=';
                if atrb.par[2] and 16 = 0 then
                  result := result + inttostr(atrb.par[7])
                else
                  result := result + '[X' + inttostr(atrb.par[7]) + ']';
              end;
            24:
              begin
                result := result + '读取S*数据 ';
                result := result + '[X' + inttostr(atrb.par[7]) + ']';
                result := result + '=';
                if atrb.par[2] and 1 = 0 then
                  result := result + '场景' + inttostr(atrb.par[3])
                else
                  result := result + '场景[X' + inttostr(atrb.par[3]) + ']';
                if atrb.par[2] and 2 = 0 then
                  result := result + '层' + inttostr(atrb.par[4])
                else
                  result := result + '层[X' + inttostr(atrb.par[4]) + ']';
                if atrb.par[2] and 4 = 0 then
                  result := result + '坐标(' + inttostr(atrb.par[5])
                else
                  result := result + '坐标([X' + inttostr(atrb.par[5]) + ']';
                if atrb.par[2] and 8 = 0 then
                  result := result + ',' + inttostr(atrb.par[6]) + ')'
                else
                  result := result + ',[X' + inttostr(atrb.par[6]) + '])';
              end;
            25:
              begin
                result := result + '保存给定地址数据[' + Format('%X' , [atrb.par[5] and $FFFF]) + '-' + Format('%X-' , [atrb.par[4] and $FFFF]) + e_getstr(1,atrb.par[2],atrb.par[7]) + ']=' + e_getstr(0, atrb.par[2], atrb.par[6]);
              end;
            26:
              begin
                result := result + '读取给定地址数据[X' + inttostr(atrb.par[6]) + ']=[' + Format('%X' , [atrb.par[5] and $FFFF]) + '-' + Format('%X-' , [atrb.par[4] and $FFFF]) + e_getstr(1,atrb.par[2],atrb.par[7]) + ']';
              end;
            27:
              begin
                result := result + '读取名称到字符串 Str' + inttostr(atrb.par[5]) + '=';
                case atrb.par[3] of
                  0: result := result + '人物';
                  1: result := result + '物品';
                  2: result := result + '场景';
                  3: result := result + '武功';
                end;
                result:= result + e_getstr(0, atrb.par[2],atrb.par[4]);
              end;
            28:
              begin
                result := result + '取当前人物战斗编号到[X' + inttostr(atrb.par[2]) + ']';
              end;
            29:
              begin
                result := result + '选择攻击目标 战斗序号' + e_getstr(0,atrb.par[2],atrb.par[3]) + '步数' + e_getstr(1,atrb.par[2],atrb.par[4]) + '返回值[X' + inttostr(atrb.par[5]) + ']';
                if atrb.par[6] = 0 then
                  result := result +'(显示)'
                else
                  result := result +'(不显示)';
              end;
            30:
              begin
                result := result + '读取人物战斗属性[X' + inttostr(atrb.par[5]) + ']=战斗序号' + e_getstr(0,atrb.par[2],atrb.par[3]) + '偏移'+e_getstr(1,atrb.par[2],atrb.par[4]);
              end;
            31:
              begin
                result := result + '保存人物战斗属性 战斗序号' + e_getstr(0,atrb.par[2],atrb.par[3]) + '偏移'+e_getstr(1,atrb.par[2],atrb.par[4]) + '=' + e_getstr(2,atrb.par[2],atrb.par[5]);
              end;
            32:
              begin
                result := result + '修改下一条指令 参数' + e_getstr(0, atrb.par[2],atrb.par[4]) + '=' + e_getstr(0,1,atrb.par[3]);
              end;
            33:
              begin
                result := result + '显示字符串 Str' + inttostr(atrb.par[3]) + '(' + e_getstr(0,atrb.par[2],atrb.par[4]) + ',' + e_getstr(1,atrb.par[2],atrb.par[5]) + ')Color' + e_getstr(2,atrb.par[2],atrb.par[6]);
              end;
            34:
              begin
                result := result + '处理背景 位置(' + e_getstr(0,atrb.par[2], atrb.par[3]) + ',' + e_getstr(1,atrb.par[2], atrb.par[4]) + ') 宽' + e_getstr(2,atrb.par[2], atrb.par[5]) + ' 高' + e_getstr(3,atrb.par[2], atrb.par[6]) + '(透明度' + e_getstr(4,atrb.par[2], atrb.par[7]) + ')';
              end;
            35:
              begin
                result := result + '读取键值 ' + e_getstr(0,1,atrb.par[2]) +'=键值 ' + e_getstr(0,1,atrb.par[3]) + '=鼠标X '  + e_getstr(0,1,atrb.par[4]) + '=鼠标Y '
              end;
            36:
              begin
                result := result + '显示字符串并等待击键 Str' + inttostr(atrb.par[3]) + '(' + e_getstr(0,atrb.par[2],atrb.par[4]) + ',' + e_getstr(1,atrb.par[2],atrb.par[5]) + ')Color' + e_getstr(2,atrb.par[2],atrb.par[6]);
              end;
            37:
              begin
                result := result + '延时' + e_getstr(0,atrb.par[2],atrb.par[3]);
              end;
            38:
              begin
                result := result + '随机数 ' + e_getstr(0,1,atrb.par[4]) +'=Random(' + e_getstr(0,atrb.par[2],atrb.par[3]) + ')';
              end;
            39:
              begin
                result := result + '菜单选择 菜单个数' + e_getstr(0,atrb.par[2],atrb.par[3]) + '字符串数组' + inttostr(atrb.par[4]) + ' 返回到'+ e_getstr(0,1,atrb.par[5]) + ' 显示位置(' + e_getstr(1,atrb.par[2],atrb.par[6]) + ',' + e_getstr(2,atrb.par[2],atrb.par[7]) +')';
              end;
            40:
              begin
                result := result + '菜单选择 菜单个数' + e_getstr(0,atrb.par[2] and $FF,atrb.par[3]) +'最大显示个数'+ inttostr((atrb.par[2] shr 8) and $FF) + ' 字符串数组' + inttostr(atrb.par[4]) + ' 返回到'+ e_getstr(0,1,atrb.par[5]) + ' 显示位置(' + e_getstr(1,atrb.par[2]and $FF,atrb.par[6]) + ',' + e_getstr(2,atrb.par[2]and $FF,atrb.par[7]) +')';
              end;
            41:
              begin
                result := result + '显示贴图';
                case atrb.par[3] of
                  0: result := result + '场景';
                  1: result := result + '头像';
                  2: result := result + '物品';
                end;
                result:= result + e_getstr(2,atrb.par[2],atrb.par[6]) + ' 位置(' + e_getstr(0,atrb.par[2],atrb.par[4]) + ',' + e_getstr(1,atrb.par[2],atrb.par[5]) + ')';
              end;
            42:
              begin
                result := result + '改变主地图坐标(' + e_getstr(0,atrb.par[2],atrb.par[3]) + ',' +e_getstr(1,atrb.par[2],atrb.par[4]) + ')';
              end;
            43:
              begin
                result := result + '调用其他事件 Call Sub' + e_getstr(0,atrb.par[2],atrb.par[3]) + '(' + e_getstr(1,atrb.par[2],atrb.par[4]) +',' + e_getstr(2,atrb.par[2],atrb.par[5])+','+e_getstr(3,atrb.par[2],atrb.par[6])+','+ e_getstr(4,atrb.par[2],atrb.par[7]) + ')';
              end;
            44:
              begin
                result := result + '播放效果 序号' + e_getstr(0,atrb.par[2],atrb.par[3]) + ' 动作类型' + e_getstr(1,atrb.par[2],atrb.par[4]) + ' 效果编号' +e_getstr(2,atrb.par[2],atrb.par[5]);
              end;
            45:
              begin
                result := result + '显示数字 颜色' + e_getstr(0,atrb.par[2],atrb.par[3]);
                if atrb.par[4]=0 then
                  result := result + ' 闪烁'
                else
                  result := result + ' 不闪烁';
                result := result + e_getstr(1,atrb.par[2],atrb.par[5]);
              end;
            46:
              begin
                result := result + '设定效果层 起始点(' + e_getstr(0,atrb.par[2],atrb.par[3]) + ',' + e_getstr(1,atrb.par[2],atrb.par[4]) + ') 长度(' + e_getstr(2,atrb.par[2],atrb.par[5]) + ',' + e_getstr(3,atrb.par[2],atrb.par[6]) + ')';
                if atrb.par[7] = 0 then
                  result := result + ' 无效果'
                else
                  result := result +  ' 有效果';
              end;
            47:
              begin
                result := result + '重置战场贴图 序号=' + e_getstr(0,atrb.par[2],atrb.par[3]);
              end;
            48:
              begin
                result := result + '调试指令 显示变量' + e_getstr(0,1,atrb.par[2]) +'--' + e_getstr(0,1,atrb.par[2] + atrb.par[3]-1);

              end;
            49:
              begin
                result := result + '调用任意子程(复刻版不可用)'
              end
            else
              begin
                if (atrb.par[1] >= 0) and (atrb.par[1] < Kdef50.num) and (Kdef50.sub[atrb.par[1]] <> '') then
                  result := result + displayname(Kdef50.sub[atrb.par[1]])
                else
                  result := result + '未知指令';
              end;
          end;
        end;
      55:
        begin
          result := result + '判断D*编号' + inttostr(atrb.par[1]) + '是否为' + inttostr(atrb.par[2]);
          if atrb.labelway > 0 then
            result := result + '是'
          else
            result := result + '否';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);
        end;
      56:
        begin
          result := result + '增加道德' + inttostr(atrb.par[1]);
        end;
      60:
        begin
          result := result + '判断场景' + inttostr(atrb.par[1]) + '事件位置' + inttostr(atrb.par[2]) + '是否有贴图' + inttostr(atrb.par[3]) + '?';
          if atrb.labelway > 0 then
            result := result + '是'
          else
            result := result + '否';
          result := result + '则跳转Label' + inttostr(atrb.labelstatus);
        end;
      63:
        begin
          result := result + '设置[' + CalRname(1, atrb.par[1]) + ']性别' + inttostr(atrb.par[2]);
        end;
      66:
        begin
          result := result + '播放音乐' + inttostr(atrb.par[1]);
        end;
      67:
        begin
          result := result + '播放声音' + inttostr(atrb.par[1]);
        end;
      68:
        begin
          //新对话
          if atrb.par[3] = -2 then
            result := result + '[' + calRname(1,atrb.par[1]) + ']'
          else if (atrb.par[3] >=0) and (atrb.par[3]< namestrnum) then
          begin
            result := result + '[' + cutstr(displaystr(readtalkstr(@namestr[atrb.par[3]]))) + ']'
          end
          else
            result := result + '[]';
          result := result + ':';
          try
            result := result + cutstr(displaystr(readtalkstr(@talkstr[word(atrb.par[2])])));
          except
            result := result + ' ';
          end;
          result := result + ' 背景(' + inttostr(atrb.par[7]) +')';
        end;
      69:
        begin
          result := result + '替换名称 ';
          case atrb.par[1] of
            0: result := result + '人物';
            1: result := result + '物品';
            2: result := result + '场景';
            3: result := result + '武功';
          end;
            result := result + '[' + calRname(atrb.par[1] + 1, atrb.par[2]) + inttostr(atrb.par[2]) +']';
          result := result + '=' + cutstr(displaystr(readtalkstr(@Namestr[atrb.par[3]])));
        end;
      70:
        begin
          result := result + '显示字幕，对话'+ inttostr(atrb.par[1]) +' 颜色'+inttostr(atrb.par[2]);
        end;
      71:
        begin
          result := result +'跳转场景'+ CalRname(3,atrb.par[1]) + ' 位置(' + inttostr(atrb.par[2]) + ',' + inttostr(atrb.par[3]) +')';
        end;
      72:
        begin
          result := result + '设置人物,指令不可用';
        end;
      73:
        begin
          result := result + '改变进门音乐'+inttostr(atrb.par[1]);
        end
      else
      begin
        if (atrb.attribnum >=0) and (atrb.attribnum < kdefini.KDEFnum) and (kdefini.KDEFitem[atrb.attribnum].note <> '') then
          result := result + displayname(kdefini.KDEFitem[atrb.attribnum].note)
        else
          result := result + '未知指令';
      end;
    end;
  end;
end;

function E_getstr(bit,t,x: smallint): widestring;
begin
  if (t and (1 shl bit)) = 0 then
    result := inttostr(x)
  else
    result := '[X' + inttostr(x) + ']';
end;

function cutstr(str:widestring): widestring;
var
  I : integer;
begin
  result := str;
  for I := 1 to length(result) - 1 do
    if result[I + 1] = '' then
    begin
      setlength(result, I);
      break;
    end;
end;

function calRname(datatype, index: integer): widestring;
var
  I: integer;
begin
  if (index >= 0) and (index < useR.Rtype[datatype].datanum) and (useR.Rtype[datatype].namepos >= 0) then
    result := inttostr(index) + displaystr(readRDatastr(@useR.Rtype[datatype].Rdata[index].Rdataline[useR.Rtype[datatype].namepos].Rarray[0].dataarray[0]))
  else
    result := inttostr(index);
  for I := 1 to length(result) - 1 do
    if result[I + 1] = '' then
    begin
      setlength(result, I);
      break;
    end;
end;

function calWname(index: integer): widestring;
var
  I: integer;
begin
  if (index >= 0) and (index < useW.Wtype.datanum) and (usew.Wtype.namepos >= 0) then
    result := inttostr(index) + displaystr(readRDatastr(@useW.Wtype.Rdata[index].Rdataline[useW.Wtype.namepos].Rarray[0].dataarray[0]))
  else
    result := '';
  for I := 1 to length(result) - 1 do
    if result[I + 1] = '' then
    begin
      setlength(result, I);
      break;
    end;
  if result = '' then
    result := inttostr(index);
end;

procedure Copyattrib(dest,source:Pattrib);
begin
  dest.attribnum := source.attribnum;
  dest.parcount := source.parcount;
  dest.labelstatus := source.labelstatus;
  dest.labelfrom := source.labelfrom;
  dest.labelto := source.labelto;
  dest.labelway := source.labelway;
  if source.parcount > 0 then
  begin
    setlength(dest.par, dest.parcount);
    copymemory(@dest.par[0], @source.par[0], dest.parcount * 2);
  end;
end;

procedure Copyevent(dest,source:Pevent);
var
  I:integer;
begin
  dest.attribamount := source.attribamount;
  if source.attribamount > 0 then
  begin
    setlength(dest.attrib, source.attribamount);
    for I := 0 to source.attribamount - 1 do
      copyattrib(@dest.attrib[I],@source.attrib[I]);
  end;
end;

procedure Addattrib(ent: Pevent; atrb: Pattrib; num: integer);
var
  I1, i2: integer;
  temp, tempbyte, tempatrbnum: integer;
  canchange: boolean;
  tempatrb:Tattrib;
begin
  inc(ent.attribamount);
  setlength(ent.attrib,ent.attribamount);
  for I1 := ent.attribamount - 1 downto num + 1 do
    copyattrib(@ent.attrib[I1],@ent.attrib[I1 - 1]);
  copyattrib(@ent.attrib[num],atrb);
  if (atrb.labelstatus = -1) then
    exit;
  if atrb.labelstatus <> -1 then
  begin
    for i1 := 0 to num - 1 do
    begin
      if ent.attrib[i1].labelstatus >= 0 then
      begin
        temp := ent.attrib[i1].labelstatus;
        canchange := false;
        for i2 := num + 1 to ent.attribamount - 1 do
          if (ent.attrib[i2].labelstatus = -1) and (ent.attrib[i2].labelfrom = temp) then
          begin
            canchange := true;
            break;
          end;
        if canchange then
        begin
          if ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump] <> 0 then
          begin
            ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump] := ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump] + atrb.parcount;
          end
          else if ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump] <> 0 then
          begin
            ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump] := ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump] + atrb.parcount;
          end
          else
          begin
            if ent.attrib[i1].labelway > 0 then
              ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump] := ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump] + atrb.parcount
            else if ent.attrib[i1].labelway < 0 then
              ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump] := ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump] + atrb.parcount;
          end;
        end;
      end;
    end;

    for I1 := num + 1 to ent.attribamount - 1 do
    begin
      if ent.attrib[i1].labelstatus >= 0 then
      begin
        temp := ent.attrib[i1].labelstatus;
        canchange := false;
        for i2 := num  downto 0 do
          if (ent.attrib[i2].labelstatus = -1) and (ent.attrib[i2].labelfrom = temp) then
          begin
            canchange := true;
            break;
          end;
        if canchange then
        begin
          if ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump] <> 0 then
          begin
            ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump] := ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump] - atrb.parcount;
          end
          else if ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump] <> 0 then
          begin
            ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump] := ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump] - atrb.parcount;
          end
          else
          begin
            if ent.attrib[i1].labelway > 0 then
              ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump] := ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump] - atrb.parcount
            else if ent.attrib[i1].labelway < 0 then
              ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump] := ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump] - atrb.parcount;
          end;
        end;
      end;
    end;
  end;
  if atrb.labelstatus >= 0 then
  begin
    tempatrb.attribnum := 0;
    tempatrb.parcount := 0;
    tempatrb.labelstatus := -1;
    tempatrb.labelfrom := atrb.labelstatus;
    if atrb.labelway > 0 then
      temp := atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump]
    else
      temp := atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
    tempbyte := 0;
    tempatrbnum := 0;
    if temp >= 0 then
    begin
      for i1 := num + 1 to ent.attribamount - 1 do
      begin
        if tempbyte >= temp then
          break;
        if ent.attrib[i1].labelstatus <> -1 then
        begin
          inc(tempbyte, ent.attrib[i1].parcount);
          inc(tempatrbnum);
        end;
      end;
      if atrb.labelway > 0 then
      begin
        atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] := tempbyte + atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump];
      end
      else
      begin
        atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := tempbyte + atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
      end;
      addattrib(ent,@tempatrb,num + 1 + tempatrbnum);
    end
    else
    begin
      for i1 := num downto 0 do
      begin
        if tempbyte >= abs(temp) then
          break;
        if ent.attrib[i1].labelstatus <> -1 then
        begin
          inc(tempbyte, ent.attrib[i1].parcount);
          inc(tempatrbnum);
        end;
      end;
      if atrb.labelway > 0 then
      begin
        atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] := atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] - tempbyte;
      end
      else
      begin
        atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] - tempbyte;
      end;
      addattrib(ent,@tempatrb, num  + 1 - tempatrbnum);
    end;
  end;
end;

procedure AddIct(ent: Pevent; atrb: Pattrib; num: integer);
var
  I1, i2: integer;
  temp, tempbyte, tempatrbnum: integer;
  canchange: boolean;
  tempatrb: Tattrib;
begin
  //
  if num < 0 then
    num := 0;
  if num > ent.attribamount then
    num := ent.attribamount;
  inc(ent.attribamount);
  setlength(ent.attrib,ent.attribamount);
  for I1 := ent.attribamount - 1 downto num + 1 do
    copyattrib(@ent.attrib[I1],@ent.attrib[I1 - 1]);

  copyattrib(@ent.attrib[num], atrb);

  if atrb.labelstatus = -1 then//如果添加的是标签，就不需要后续处理，直接返回
    exit;

  //对其它带标签指令的标签距离进行重新计算
  for I1 := 0 to num - 1 do
  begin
    if ent.attrib[I1].labelstatus >= 0 then
    begin
      temp := ent.attrib[I1].labelstatus;
      for I2 := num + 1 to ent.attribamount - 1 do
      begin
        if (ent.attrib[I2].labelstatus = -1) and (ent.attrib[I2].labelfrom = temp) then
        begin
          if ent.attrib[I1].labelway >= 0 then
          begin
            inc(ent.attrib[I1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump], atrb.parcount)
          end
          else
          begin
            inc(ent.attrib[I1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump], atrb.parcount)
          end;
        end;
      end;
    end
    else if ent.attrib[I1].labelstatus = -1 then
    begin
      temp := ent.attrib[I1].labelfrom;
      for I2 := num + 1 to ent.attribamount - 1 do
      begin
        if ent.attrib[I2].labelstatus = temp then
        begin
          if ent.attrib[I1].labelway >= 0 then
          begin
            dec(ent.attrib[I2].par[kdefini.KDEFitem[ent.attrib[i2].attribnum].yesjump], atrb.parcount)
          end
          else
          begin
            dec(ent.attrib[I2].par[kdefini.KDEFitem[ent.attrib[i2].attribnum].nojump], atrb.parcount)
          end;
        end;
      end;
    end;
  end;

  //如需添加标签，则进行添加（递归）
  if atrb.labelstatus >= 0 then
  begin
    if atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] <> 0 then
      temp := atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump]
    else if atrb.par[kdefini.KDEFitem[atrb.attribnum].nojump] <> 0 then
      temp := atrb.par[kdefini.KDEFitem[atrb.attribnum].nojump]
    else
    begin
      if atrb.labelway > 0 then
        temp := atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump]
      else
        temp := atrb.par[kdefini.KDEFitem[atrb.attribnum].nojump];
    end;
    if temp >= 0 then
    begin
      I1 := 0;
      I2 := num + 1;
      while (I1 < temp) do
      begin
        if I2 > ent.attribamount - 1 then
        begin
          break;
        end;
        if ent.attrib[I2].labelstatus <> -1 then
          inc(I1, ent.attrib[I2].parcount);
        inc(I2);
      end;
    end
    else
    begin
      I1 := 0;
      I2 := num + 1;
      while (I1 > temp) do
      begin
        dec(I2);
        if I2 < 0 then
        begin
          I2 := 0;
          break;
        end;
        if ent.attrib[I2].labelstatus <> -1 then
          dec(I1, ent.attrib[I2].parcount);
      end;

    end;

    if i1 <> temp then
    begin
      if atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] <> 0 then
      begin
        atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] := i1;
        atrb.par[kdefini.KDEFitem[atrb.attribnum].nojump] := 0;
      end
      else if atrb.par[kdefini.KDEFitem[atrb.attribnum].nojump] <> 0 then
        atrb.par[kdefini.KDEFitem[atrb.attribnum].nojump] := i1
      else
      begin
        if atrb.labelway >= 0 then
        begin
          atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] := i1;
          atrb.par[kdefini.KDEFitem[atrb.attribnum].nojump] := 0;
        end
        else
        begin
          atrb.par[kdefini.KDEFitem[atrb.attribnum].nojump] := i1;
          atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] := 0;
        end;
      end;
      copyattrib(@ent.attrib[num], atrb);
    end;
    tempatrb.attribnum := 0;
    tempatrb.parcount := 0;
    tempatrb.labelstatus := -1;
    tempatrb.labelfrom := atrb.labelstatus;
    if I1 >= 0 then
      tempatrb.labelway := 1
    else
      tempatrb.labelway := -1;
    AddIct(ent, @tempatrb, I2);
  end;
end;

procedure deleteatrb(ent: Pevent; num: integer);
var
  I1,I2, Nlabel, parcount, temp: integer;
  canchange: boolean;
begin
  //
  Nlabel := ent.attrib[num].labelstatus;
  parcount := ent.attrib[num].parcount;
  for i1 := num to ent.attribamount - 2 do
    copyattrib(@ent.attrib[I1],@ent.attrib[I1 + 1]);
  dec(ent.attribamount);
  setlength(ent.attrib, ent.attribamount);
  if Nlabel = -1 then
    exit;
  if Nlabel <> -1 then
  begin
    for i1 := 0 to num - 1 do
    begin
      if ent.attrib[i1].labelstatus >= 0 then
      begin
        temp := ent.attrib[i1].labelstatus;
        canchange := false;
        for i2 := num to ent.attribamount - 1 do
          if (ent.attrib[i2].labelstatus = -1) and (ent.attrib[i2].labelfrom = temp) then
          begin
            canchange := true;
            break;
          end;
        if canchange then
        begin
          if ent.attrib[i1].labelway >= 0 then
          begin
            ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump] := ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump] - parcount;
          end
          else
          begin
            ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump] := ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump] - parcount;
          end;
        end;
      end;
    end;

    for I1 := num to ent.attribamount - 1 do
    begin
      if ent.attrib[i1].labelstatus >= 0 then
      begin
        temp := ent.attrib[i1].labelstatus;
        canchange := false;
        for i2 := num  downto 0 do
          if (ent.attrib[i2].labelstatus = -1) and (ent.attrib[i2].labelfrom = temp) then
          begin
            canchange := true;
            break;
          end;
        if canchange then
        begin
          if ent.attrib[i1].labelway >= 0 then
          begin
            ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump] := ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].yesjump] + parcount;
          end
          else
          begin
            ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump] := ent.attrib[i1].par[kdefini.KDEFitem[ent.attrib[i1].attribnum].nojump] + parcount;
          end;
        end;
      end;
    end;
  end;
  if Nlabel >= 0 then
  begin
    for i1 := 0 to ent.attribamount - 1 do
      if (ent.attrib[i1].labelstatus = -1) and (ent.attrib[i1].labelfrom = Nlabel) then
      begin
        for i2 := i1 to ent.attribamount - 2 do
          copyattrib(@ent.attrib[I2],@ent.attrib[I2 + 1]);
        dec(ent.attribamount);
        setlength(ent.attrib, ent.attribamount);
        break;
      end;
    for i1 := 0 to ent.attribamount - 1 do
      if (ent.attrib[i1].labelstatus = -1) and (ent.attrib[i1].labelfrom > Nlabel) then
        dec(ent.attrib[i1].labelfrom)
      else if (ent.attrib[i1].labelstatus >= 0) and (ent.attrib[i1].labelstatus > Nlabel) then
      begin
        dec(ent.attrib[i1].labelstatus);
        dec(ent.attrib[i1].labelto);
      end;
    dec(labelnum);
  end;
end;

procedure saveevent(destent,sourceent:Pevent);
var
  tempevent: Tevent;
  i1,i2,temp: integer;
begin
  temp := 0;
  for i1 := 0 to sourceent.attribamount - 1 do
  begin
    if sourceent.attrib[i1].labelstatus <> -1 then
      inc(temp);
  end;
  tempevent.attribamount := temp;
  setlength(tempevent.attrib, tempevent.attribamount);
  i2 := 0;
  for i1 := 0 to tempevent.attribamount - 1 do
  begin
    while true do
    begin
      if sourceent.attrib[i2].labelstatus <> -1 then
        break
      else
        inc(i2);
    end;
    copyattrib(@tempevent.attrib[i1],@sourceent.attrib[i2]);
    inc(i2);
  end;
  copyevent(destent,@tempevent);
end;

procedure SaveEventtoData(destent: Peventdata; sourceent:Pevent);
var
  I1, I2, temp: integer;
begin
  //
  temp := 0;
  for i1 := 0 to sourceent.attribamount - 1 do
  begin
    {-1表示是标签，-2表示没有标签的指令，>=0表示有标签的指令}
    if sourceent.attrib[i1].labelstatus <> -1 then
      inc(temp, max(sourceent.attrib[i1].parcount, 0) * 2);
  end;
  destent.datalen := temp;
  setlength(destent.data, destent.datalen);
  I2 := 0;
  for I1 := 0 to sourceent.attribamount - 1 do
  begin
    if sourceent.attrib[i1].labelstatus = -1 then
      continue;
    if sourceent.attrib[i1].labelstatus >= 0 then
    begin
      if sourceent.attrib[i1].labelway >= 0 then
      begin
        sourceent.attrib[i1].par[kdefini.KDEFitem[sourceent.attrib[i1].attribnum].nojump] := 0;
      end
      else
        sourceent.attrib[i1].par[kdefini.KDEFitem[sourceent.attrib[i1].attribnum].yesjump] := 0;
    end;
    copymemory(@destent.data[I2], @sourceent.attrib[I1].par[0], sourceent.attrib[I1].parcount * 2);
    inc(I2, sourceent.attrib[I1].parcount * 2);
  end;
    
end;

procedure SaveDataToEvent(destent: Pevent; sourceent:Peventdata);
var
  temp, temp2, I1, I2: integer;
begin
  //
  I1 := 0;
  temp := 0;
  while (I1 < sourceent.datalen - 1) do
  begin
    temp2 := Psmallint(@sourceent.data[I1])^;
    if (temp2 >= 0) and (temp2 < Kdefini.KDEFnum) then
    begin
      inc(I1, Kdefini.KDEFitem[temp2].paramount * 2);
      inc(temp);
    end
    else
    begin
      inc(I1, 2);
      inc(temp);
    end;
  end;
  destent.attribamount := temp;
  setlength(destent.attrib, destent.attribamount);
  I1 := 0;
  I2 := 0;
  temp := 0;
  while (I1 < sourceent.datalen - 1) do
  begin
    temp2 := Psmallint(@sourceent.data[I1])^;
    if (temp2 >= 0) and (temp2 < Kdefini.KDEFnum) then
    begin

      destent.attrib[temp].attribnum := temp2;
      destent.attrib[temp].parcount := Kdefini.KDEFitem[temp2].paramount;
      setlength(destent.attrib[temp].par, destent.attrib[temp].parcount);

      if temp < destent.attribamount then
      begin
        copymemory(@(destent.attrib[temp].par[0]), @(sourceent.data[I1]), destent.attrib[temp].parcount * 2);
      end
      else
        copymemory(@(destent.attrib[temp].par[0]), @(sourceent.data[I1]), sourceent.datalen - I1);
      inc(temp);
      inc(I1, Kdefini.KDEFitem[temp2].paramount * 2);
    end
    else
    begin
      destent.attrib[temp].attribnum := temp2;
      destent.attrib[temp].parcount := 1;
      setlength(destent.attrib[temp].par, destent.attrib[temp].parcount);
      copymemory(@(destent.attrib[temp].par[0]), @(sourceent.data[I1]), 2);
      inc(I1, 2);
      inc(temp);
    end;
  end;

end;


function TForm7.EditIct(atrb: Pattrib): integer;
var
  I: integer;
  tempadr: cardinal;
begin
  //编辑事件
  //
  if GetInstructNeedGuide(atrb) then
  begin
    result := InstructGuide(atrb);
    exit;
  end;

  case atrb.attribnum of
    1:
      begin
        Form14.ComboBox1.Clear;
        Form14.ComboBox2.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
        begin
          Form14.ComboBox1.Items.Add(CalRname(1,I));
        end;
        for I := 0 to talkstrnum - 1 do
        begin
          Form14.ComboBox2.Items.Add(inttostr(I) + ':' + displaystr(readtalkstr(@talkstr[I])));
        end;
        Form14.ComboBox1.ItemIndex := atrb.par[2];
        Form14.ComboBox2.ItemIndex := atrb.par[1];
        Form14.Edit1.Text := displaystr(readtalkstr(@talkstr[Form14.ComboBox2.ItemIndex]));
        Form14.ComboBox3.ItemIndex := word(atrb.par[3]);
        if Form14.ShowModal = mrOK then
        begin
          atrb.par[2]:= Form14.ComboBox1.ItemIndex;
          atrb.par[1]:=Form14.ComboBox2.ItemIndex;
          atrb.par[3]:= Form14.ComboBox3.ItemIndex;
          arrangetalktocombobox;
        end;

      end;
    2:
      begin
        Form15.ComboBox1.Clear;
        for I := 0 to useR.Rtype[2].datanum - 1 do
        begin
          Form15.ComboBox1.Items.Add(CalRname(2,I));
        end;
        Form15.ComboBox1.ItemIndex := atrb.par[1];
        Form15.Edit1.Text := inttostr(atrb.par[2]);
        if Form15.ShowModal = mrOK then
        begin
          atrb.par[1]:= Form15.ComboBox1.ItemIndex;
          atrb.par[2]:= strtoint(Form15.edit1.Text);
        end;
      end;
    3:
      begin
        Form16.ComboBox1.Clear;
        Form16.ComboBox1.Items.Add('当前场景');
        for I := 0 to useR.Rtype[3].datanum - 1 do
        begin
          Form16.ComboBox1.Items.Add(CalRname(3,I));
        end;
        if atrb.par[1] < 0 then
          FOrm16.ComboBox1.ItemIndex := 0
        else
          FOrm16.ComboBox1.ItemIndex := atrb.par[1] + 1;
        Form16.edit11.text := inttostr(atrb.par[2]);
        if atrb.par[3] < 0 then
          Form16.ComboBox3.ItemIndex := 0
        else
          Form16.ComboBox3.ItemIndex := atrb.par[3] + 1;

        Form16.Edit1.Text := inttostr(atrb.par[4]);
        Form16.Edit2.Text := inttostr(atrb.par[5]);
        Form16.Edit3.Text := inttostr(atrb.par[6]);
        Form16.Edit4.Text := inttostr(atrb.par[7]);
        Form16.Edit5.Text := inttostr(atrb.par[8]);
        Form16.Edit6.Text := inttostr(atrb.par[9]);
        Form16.Edit7.Text := inttostr(atrb.par[10]);
        Form16.Edit8.Text := inttostr(atrb.par[11]);
        Form16.Edit9.Text := inttostr(atrb.par[12]);
        Form16.Edit10.Text := inttostr(atrb.par[13]);

        if Form16.ShowModal = mrOK then
        begin
          if Form16.combobox1.ItemIndex = 0 then
            atrb.par[1]:= -2
          else
            atrb.par[1] := Form16.combobox1.ItemIndex - 1;
          if Form16.combobox3.ItemIndex = 0 then
            atrb.par[3]:= -2
          else
            atrb.par[3] := Form16.combobox3.ItemIndex - 1;
          atrb.Par[4] := strtoint(Form16.Edit1.Text);
          atrb.Par[5] := strtoint(Form16.Edit2.Text);
          atrb.Par[6] := strtoint(Form16.Edit3.Text);
          atrb.Par[7] := strtoint(Form16.Edit4.Text);
          atrb.Par[8] := strtoint(Form16.Edit5.Text);
          atrb.Par[9] := strtoint(Form16.Edit6.Text);
          atrb.Par[10] := strtoint(Form16.Edit7.Text);
          atrb.Par[11] := strtoint(Form16.Edit8.Text);
          atrb.Par[12] := strtoint(Form16.Edit9.Text);
          atrb.Par[13] := strtoint(Form16.Edit10.Text);
          atrb.par[2] := strtoint(Form16.edit11.text);
        end;
      end;
    4:
      begin
        Form17.ComboBox1.Clear;
        for I := 0 to useR.Rtype[2].datanum - 1 do
          Form17.ComboBox1.Items.Add(CalRname(2,I));
        Form17.ComboBox1.itemindex := atrb.Par[1];
        if atrb.labelway = 1 then
          Form17.ComboBox2.ItemIndex := 0
        else
          Form17.ComboBox2.ItemIndex := 1;
        if Form17.ShowModal = mrOK then
        begin
          atrb.par[1] := Form17.ComboBox1.ItemIndex;
          if Form17.ComboBox2.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
        end;

      end;
    5:
      begin
        if atrb.labelway = 1 then
          Form18.ComboBox1.ItemIndex := 0
        else
          Form18.ComboBox1.ItemIndex := 1;
        if Form18.ShowModal=mrOK then
        begin
          if Form18.ComboBox1.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
        end;
      end;
    6:
      begin
        FOrm19.ComboBox1.Clear;
        for I := 0 to useW.Wtype.datanum - 1 do
          Form19.ComboBox1.Items.Add(CalWname(I));
        Form19.ComboBox1.ItemIndex := atrb.par[1];
        if atrb.labelway = 1 then
          Form19.ComboBox2.ItemIndex := 0
        else
          Form19.ComboBox2.ItemIndex := 1;
        Form19.ComboBox3.ItemIndex := atrb.par[4];
        if Form19.ShowModal = mrOK then
        begin
          atrb.par[1] := Form19.ComboBox1.ItemIndex;
          if Form19.ComboBox2.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
          atrb.par[4] := Form19.ComboBox3.ItemIndex;
        end;
      end;
    8:
      begin
        Form20.Edit1.Text :=  inttostr(atrb.par[1]);
        if Form20.ShowModal = mrOK then
        begin
          atrb.par[1] := strtoint(Form20.Edit1.Text);
        end;
      end;
    9:
      begin
        if atrb.labelway = 1 then
          Form18.ComboBox1.ItemIndex := 0
        else
          Form18.ComboBox1.ItemIndex := 1;
        if Form18.ShowModal=mrOK then
        begin
          if Form18.ComboBox1.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
        end;
      end;
    10:
      begin
        Form21.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          Form21.ComboBox1.Items.Add(CalRname(1,I));
        Form21.ComboBox1.ItemIndex := atrb.par[1];
        if Form21.ShowModal = mrOK then
        begin
          atrb.par[1]:= Form21.ComboBox1.ItemIndex;
        end;
      end;
    11:
      begin
        if atrb.labelway = 1 then
          Form18.ComboBox1.ItemIndex := 0
        else
          Form18.ComboBox1.ItemIndex := 1;
        if Form18.ShowModal=mrOK then
        begin
          if Form18.ComboBox1.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
        end;
      end;
    16:
      begin
        Form22.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          Form22.ComboBox1.Items.Add(CalRname(1,I));
        Form22.ComboBox1.ItemIndex := atrb.par[1];
        if atrb.labelway = 1 then
          Form22.ComboBox2.ItemIndex := 0
        else
          Form22.ComboBox2.ItemIndex := 1;
        if Form22.ShowModal = mrOK then
        begin
          atrb.par[1] := Form22.ComboBox1.ItemIndex;
          if Form22.ComboBox2.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
        end;
      end;
    17:
      begin
        Form23.ComboBox1.Clear;
        for I := 0 to useR.Rtype[3].datanum - 1 do
          Form23.ComboBox1.Items.Add(CalRname(3,I));
        Form23.ComboBox1.ItemIndex := atrb.par[1];
        Form23.ComboBox2.ItemIndex := atrb.par[2];
        Form23.Edit1.Text := inttostr(atrb.par[3]);
        Form23.Edit2.Text := inttostr(atrb.par[4]);
        Form23.Edit3.Text := inttostr(atrb.par[5]);
        if Form23.ShowModal = mrOK then
        begin
          atrb.par[1] := FOrm23.ComboBox1.ItemIndex;
          atrb.par[2] := Form23.ComboBox2.ItemIndex;
          atrb.par[3] := strtoint(Form23.Edit1.Text);
          atrb.par[4] := strtoint(Form23.Edit2.Text);
          atrb.par[5] := strtoint(Form23.Edit3.Text);
        end;
      end;
    18:
      begin
        Form22.ComboBox1.Clear;
        for I := 0 to useR.Rtype[2].datanum - 1 do
          Form22.ComboBox1.Items.Add(CalRname(2,I));
        Form22.ComboBox1.ItemIndex := atrb.par[1];
        if atrb.labelway = 1 then
          Form22.ComboBox2.ItemIndex := 0
        else
          Form22.ComboBox2.ItemIndex := 1;
        if Form22.ShowModal = mrOK then
        begin
          atrb.par[1] := Form22.ComboBox1.ItemIndex;
          if Form22.ComboBox2.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
        end;
      end;
    19:
      begin
        Form24.Edit1.Text := inttostr(atrb.par[1]);
        Form24.Edit2.Text := inttostr(atrb.par[2]);
        if FOrm24.ShowModal = mrOK then
        begin
          atrb.par[1] := strtoint(Form24.Edit1.Text);
          atrb.par[2] := strtoint(Form24.Edit2.Text);
        end;
      end;
    20:
      begin
        if atrb.labelway = 1 then
          Form18.ComboBox1.ItemIndex := 0
        else
          Form18.ComboBox1.ItemIndex := 1;
        if Form18.ShowModal=mrOK then
        begin
          if Form18.ComboBox1.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
        end;
      end;
    21:
      begin
        Form21.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          Form21.ComboBox1.Items.Add(CalRname(1,I));
        Form21.ComboBox1.ItemIndex := atrb.par[1];
        if Form21.ShowModal = mrOK then
        begin
          atrb.par[1]:= Form21.ComboBox1.ItemIndex;
        end;
      end;
    23:
      begin
        Form25.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          FOrm25.ComboBox1.Items.Add(CalRname(1,I));
        Form25.ComboBox1.ItemIndex := atrb.par[1];
        Form25.Edit1.Text := inttostr(atrb.par[2]);
        if Form25.ShowModal = mrOK then
        begin
          atrb.par[1] := Form25.ComboBox1.ItemIndex;
          atrb.par[2] := strtoint(Form25.Edit1.Text);
        end;
      end;
    25:
      begin
        FOrm26.Edit1.Text := inttostr(atrb.par[1]);
        FOrm26.Edit2.Text := inttostr(atrb.par[2]);
        FOrm26.Edit3.Text := inttostr(atrb.par[3]);
        FOrm26.Edit4.Text := inttostr(atrb.par[4]);
        if Form26.ShowModal = mrOK then
        begin
          atrb.par[1]:= strtoint(Form26.Edit1.Text);
          atrb.par[2]:= strtoint(Form26.Edit2.Text);
          atrb.par[3]:= strtoint(Form26.Edit3.Text);
          atrb.par[4]:= strtoint(Form26.Edit4.Text);
        end;
      end;
    26:
      begin
        Form27.ComboBox1.Clear;
        Form27.ComboBox1.Items.Add('-2当前场景');
        Form27.ComboBox1.Items.Add('-1无');
        for I := 0 to useR.Rtype[3].datanum - 1 do
          Form27.ComboBox1.Items.Add(CalRname(3,I));
        Form27.ComboBox1.ItemIndex := atrb.par[1] + 2;
        Form27.Edit1.Text := inttostr(atrb.par[2]);
        Form27.Edit2.Text := inttostr(atrb.par[3]);
        Form27.Edit3.Text := inttostr(atrb.par[4]);
        Form27.Edit4.Text := inttostr(atrb.par[5]);
        if Form27.ShowModal = mrOK then
        begin
          atrb.par[1] := max(Form27.ComboBox1.ItemIndex - 2, -2);
          atrb.par[2] := strtoint(Form27.Edit1.Text);
          atrb.par[3] := strtoint(Form27.Edit2.Text);
          atrb.par[4] := strtoint(Form27.Edit3.Text);
          atrb.par[5] := strtoint(Form27.Edit4.Text);
        end;
      end;
    27:
      begin
        Form28.Edit1.Text := inttostr(atrb.par[1]);
        Form28.Edit2.Text := inttostr(atrb.par[2]);
        Form28.Edit3.Text := inttostr(atrb.par[3]);
        if Form28.ShowModal = mrOK then
        begin
          atrb.par[1] := strtoint(Form28.Edit1.Text);
          atrb.par[2] := strtoint(Form28.Edit2.Text);
          atrb.par[3] := strtoint(Form28.Edit3.Text);
        end;
      end;
    28:
      begin
        if atrb.labelway = 1 then
          Form29.ComboBox2.ItemIndex := 0
        else
          Form29.ComboBox2.ItemIndex := 1;
        form29.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          form29.ComboBox1.Items.Add(calRname(1,I));
        Form29.ComboBox1.ItemIndex := atrb.par[1];
        form29.Edit1.Text := inttostr(atrb.par[2]);
        form29.Edit2.Text := inttostr(atrb.par[3]);
        if Form29.ShowModal = mrOK then
        begin
          if Form29.ComboBox2.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
          atrb.par[1] := form29.ComboBox1.ItemIndex;
          atrb.par[2]:= strtoint(Form29.Edit1.Text);
          atrb.par[3]:= strtoint(Form29.Edit2.Text);
        end;
      end;
    29:
      begin
        if atrb.labelway = 1 then
          Form29.ComboBox2.ItemIndex := 0
        else
          Form29.ComboBox2.ItemIndex := 1;
        form29.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          form29.ComboBox1.Items.Add(calRname(1,I));
        Form29.ComboBox1.ItemIndex := atrb.par[1];
        form29.Edit1.Text := inttostr(atrb.par[2]);
        form29.Edit2.Text := inttostr(atrb.par[3]);
        if Form29.ShowModal = mrOK then
        begin
          if Form29.ComboBox2.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
          atrb.par[1] := form29.ComboBox1.ItemIndex;
          atrb.par[2]:= strtoint(Form29.Edit1.Text);
          atrb.par[3]:= strtoint(Form29.Edit2.Text);
        end;
      end;
    30:
      begin
        FOrm26.Edit1.Text := inttostr(atrb.par[1]);
        FOrm26.Edit2.Text := inttostr(atrb.par[2]);
        FOrm26.Edit3.Text := inttostr(atrb.par[3]);
        FOrm26.Edit4.Text := inttostr(atrb.par[4]);
        if Form26.ShowModal = mrOK then
        begin
          atrb.par[1]:= strtoint(Form26.Edit1.Text);
          atrb.par[2]:= strtoint(Form26.Edit2.Text);
          atrb.par[3]:= strtoint(Form26.Edit3.Text);
          atrb.par[4]:= strtoint(Form26.Edit4.Text);
        end;
      end;
    31:
      begin
        Form30.Edit1.Text := inttostr(atrb.par[1]);
        if atrb.labelway = 1 then
          Form30.ComboBox1.ItemIndex := 0
        else
          Form30.ComboBox1.ItemIndex := 1;
        if FOrm30.ShowModal = mrOK then
        begin
          atrb.par[1] := strtoint(Form30.Edit1.Text);
          if Form30.ComboBox1.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
        end;
      end;
    32:
      begin
        Form15.ComboBox1.Clear;
        for I := 0 to useR.Rtype[2].datanum - 1 do
        begin
          Form15.ComboBox1.Items.Add(CalRname(2,I));
        end;
        Form15.ComboBox1.ItemIndex := atrb.par[1];
        Form15.Edit1.Text := inttostr(atrb.par[2]);
        if Form15.ShowModal = mrOK then
        begin
          atrb.par[1]:= Form15.ComboBox1.ItemIndex;
          atrb.par[2]:= strtoint(Form15.edit1.Text);
        end;
      end;
    33:
      begin
        Form31.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          FOrm31.ComboBox1.Items.Add(CalRname(1,I));
        Form31.ComboBox1.ItemIndex := atrb.par[1];
        Form31.ComboBox2.Clear;
        for I := 0 to useR.Rtype[4].datanum - 1 do
          FOrm31.ComboBox2.Items.Add(CalRname(4,I));
        Form31.ComboBox2.ItemIndex := atrb.par[4];
        if atrb.par[3] = 0 then
          Form31.CheckBox1.Checked := false
        else
          Form31.CheckBox1.Checked := true;
        if Form31.ShowModal = mrOK then
        begin
          atrb.par[1] := Form31.ComboBox1.ItemIndex;
          atrb.par[2] := Form31.ComboBox2.ItemIndex;
          if Form31.CheckBox1.Checked then
            atrb.par[3] := 1
          else
            atrb.par[3] := 0;
        end;
      end;
    34:
      begin
        Form25.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          FOrm25.ComboBox1.Items.Add(CalRname(1,I));
        Form25.ComboBox1.ItemIndex := atrb.par[1];
        Form25.Edit1.Text := inttostr(atrb.par[2]);
        if Form25.ShowModal = mrOK then
        begin
          atrb.par[1] := Form25.ComboBox1.ItemIndex;
          atrb.par[2] := strtoint(Form25.Edit1.Text);
        end;
      end;
    35:
      begin
        Form32.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          Form32.ComboBox1.Items.Add(CalRname(1,I));
        Form32.ComboBox1.ItemIndex := atrb.par[1];
        Form32.Edit1.Text := inttostr(atrb.par[2]);
        Form32.ComboBox2.Clear;
        for I := 0 to useR.Rtype[4].datanum - 1 do
          Form32.ComboBox2.Items.Add(CalRname(4,I));
        Form32.ComboBox2.ItemIndex := atrb.par[3];
        Form32.Edit2.Text := inttostr(atrb.par[4]);
        if Form32.ShowModal = mrOK then
        begin
          atrb.par[1]:= Form32.ComboBox1.ItemIndex;
          atrb.par[2] := strtoint(Form32.Edit1.Text);
          atrb.par[3] := Form32.ComboBox2.ItemIndex;
          atrb.par[4] := strtoint(Form32.Edit2.Text);
        end;
      end;
    36:
      begin
        if (atrb.par[1] < 3) and (atrb.par[1] >= 0) then
          Form33.ComboBox1.ItemIndex := atrb.par[1]
        else
          Form33.ComboBox1.ItemIndex := 3;
        if atrb.labelway = 1 then
          Form33.ComboBox2.ItemIndex := 0
        else
          Form33.ComboBox2.ItemIndex := 1;
        if Form33.ShowModal = mrOK then
        begin
          if (Form33.ComboBox1.ItemIndex >= 0) and (Form33.ComboBox1.ItemIndex < 3) then
            atrb.par[1] := Form33.ComboBox1.ItemIndex
          else
            atrb.par[1] := 256;
          if Form33.ComboBox2.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
        end;
      end;
    37:
      begin
        Form34.Edit1.Text := inttostr(atrb.par[1]);
        if Form34.ShowModal = mrOK then
        begin
          atrb.par[1] := strtoint(Form34.Edit1.Text);
        end;
      end;
    38:
      begin
        Form35.ComboBox1.Clear;
        for I := 0 to useR.Rtype[3].datanum - 1 do
          Form35.ComboBox1.Items.Add(CalRname(3,I));
        Form35.ComboBox1.ItemIndex := max(atrb.par[1], 0);
        Form35.Edit1.Text := inttostr(atrb.par[2]);
        Form35.Edit2.Text := inttostr(atrb.par[3]);
        Form35.Edit3.Text := inttostr(atrb.par[4]);
        if Form35.ShowModal = mrOK then
        begin
          atrb.par[1] := Form35.ComboBox1.ItemIndex;
          atrb.par[2] := strtoint(Form35.Edit1.Text);
          atrb.par[3] := strtoint(Form35.Edit2.Text);
          atrb.par[4] := strtoint(Form35.Edit3.Text);
        end;
      end;
    39:
      begin
        Form21.ComboBox1.Clear;
        for I := 0 to useR.Rtype[3].datanum - 1 do
          Form21.ComboBox1.Items.Add(CalRname(3,I));
        Form21.ComboBox1.ItemIndex := max(atrb.par[1],0);
        if Form21.ShowModal = mrOK then
        begin
          atrb.par[1]:= Form21.ComboBox1.ItemIndex;
        end;
      end;
    40:
      begin
        Form21.ComboBox1.Clear;
        Form21.ComboBox1.Items.Add(widestring('0-向上'));
        Form21.ComboBox1.Items.Add(widestring('1-向右'));
        Form21.ComboBox1.Items.Add(widestring('2-向左'));
        Form21.ComboBox1.Items.Add(widestring('3-向下'));
        Form21.ComboBox1.ItemIndex := max(atrb.par[1],0);
        if Form21.ShowModal = mrOK then
        begin
          atrb.par[1]:= Form21.ComboBox1.ItemIndex;
        end;
      end;
    41:
      begin
        Form36.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          Form36.ComboBox1.Items.Add(CalRname(1,I));
        Form36.ComboBox1.ItemIndex := max(atrb.par[1],0);
        Form36.ComboBox2.Clear;
        for I := 0 to useR.Rtype[2].datanum - 1 do
          Form36.ComboBox2.Items.Add(CalRname(2,I));
        Form36.ComboBox2.ItemIndex := max(atrb.par[2],0);
        Form36.Edit1.Text := inttostr(atrb.par[3]);
        if Form36.ShowModal = mrOK then
        begin
          atrb.par[1] := Form36.ComboBox1.ItemIndex;
          atrb.par[2] := Form36.ComboBox2.ItemIndex;
          atrb.par[3] := strtoint(Form36.edit1.Text);
        end;
      end;
    42:
      begin
        if atrb.labelway = 1 then
          Form18.ComboBox1.ItemIndex := 0
        else
          Form18.ComboBox1.ItemIndex := 1;
        if Form18.ShowModal=mrOK then
        begin
          if Form18.ComboBox1.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
        end;
      end;
    43:
      begin
        Form17.ComboBox1.Clear;
        for I := 0 to useR.Rtype[2].datanum - 1 do
          Form17.ComboBox1.Items.Add(CalRname(2,I));
        Form17.ComboBox1.itemindex := atrb.Par[1];
        if atrb.labelway = 1 then
          Form17.ComboBox2.ItemIndex := 0
        else
          Form17.ComboBox2.ItemIndex := 1;
        if Form17.ShowModal = mrOK then
        begin
          atrb.par[1] := Form17.ComboBox1.ItemIndex;
          if Form17.ComboBox2.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
        end;
      end;
    44:
      begin
        Form37.Edit1.Text := inttostr(atrb.par[1]);
        Form37.Edit2.Text := inttostr(atrb.par[2]);
        Form37.Edit3.Text := inttostr(atrb.par[3]);
        Form37.Edit4.Text := inttostr(atrb.par[4]);
        Form37.Edit5.Text := inttostr(atrb.par[5]);
        Form37.Edit6.Text := inttostr(atrb.par[6]);
        if FOrm37.ShowModal = mrOK then
        begin
          atrb.par[1] := strtoint(Form37.Edit1.Text);
          atrb.par[2] := strtoint(Form37.Edit2.Text);
          atrb.par[3] := strtoint(Form37.Edit3.Text);
          atrb.par[4] := strtoint(Form37.Edit4.Text);
          atrb.par[5] := strtoint(Form37.Edit5.Text);
          atrb.par[6] := strtoint(Form37.Edit6.Text);
        end;
      end;
    45:
      begin
        Form25.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          FOrm25.ComboBox1.Items.Add(CalRname(1,I));
        Form25.ComboBox1.ItemIndex := atrb.par[1];
        Form25.Edit1.Text := inttostr(atrb.par[2]);
        if Form25.ShowModal = mrOK then
        begin
          atrb.par[1] := Form25.ComboBox1.ItemIndex;
          atrb.par[2] := strtoint(Form25.Edit1.Text);
        end;
      end;
    46:
      begin
        Form25.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          FOrm25.ComboBox1.Items.Add(CalRname(1,I));
        Form25.ComboBox1.ItemIndex := atrb.par[1];
        Form25.Edit1.Text := inttostr(atrb.par[2]);
        if Form25.ShowModal = mrOK then
        begin
          atrb.par[1] := Form25.ComboBox1.ItemIndex;
          atrb.par[2] := strtoint(Form25.Edit1.Text);
        end;
      end;
    47:
      begin
        Form25.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          FOrm25.ComboBox1.Items.Add(CalRname(1,I));
        Form25.ComboBox1.ItemIndex := atrb.par[1];
        Form25.Edit1.Text := inttostr(atrb.par[2]);
        if Form25.ShowModal = mrOK then
        begin
          atrb.par[1] := Form25.ComboBox1.ItemIndex;
          atrb.par[2] := strtoint(Form25.Edit1.Text);
        end;
      end;
    48:
      begin
        Form25.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          FOrm25.ComboBox1.Items.Add(CalRname(1,I));
        Form25.ComboBox1.ItemIndex := atrb.par[1];
        Form25.Edit1.Text := inttostr(atrb.par[2]);
        if Form25.ShowModal = mrOK then
        begin
          atrb.par[1] := Form25.ComboBox1.ItemIndex;
          atrb.par[2] := strtoint(Form25.Edit1.Text);
        end;
      end;
    49:
      begin
        Form25.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          FOrm25.ComboBox1.Items.Add(CalRname(1,I));
        Form25.ComboBox1.ItemIndex := atrb.par[1];
        Form25.Edit1.Text := inttostr(atrb.par[2]);
        if Form25.ShowModal = mrOK then
        begin
          atrb.par[1] := Form25.ComboBox1.ItemIndex;
          atrb.par[2] := strtoint(Form25.Edit1.Text);
        end;
      end;
    50:
      begin
        FOrm44.ListBox1.Clear;
        for I := 0 to kdef50.num - 1 do
          Form44.listbox1.Items.Add(inttostr(I)+':'+displayname(kdef50.sub[I]));
        FOrm44.listbox1.ItemIndex := atrb.par[1];
        if Form44.ShowModal = mrOK then
        begin
          atrb.par[1] := max(Form44.ListBox1.ItemIndex,0);
          case atrb.par[1] of
            0:
              begin
                Form43.Edit1.Text := inttostr(atrb.par[2]);
                Form43.Edit2.Text := inttostr(atrb.par[3]);
                if FOrm43.ShowModal = mrOK then
                begin
                  atrb.par[2]:= strtoint(Form43.Edit1.Text);
                  atrb.par[3]:= strtoint(Form43.Edit2.Text);
                end;
              end;
            1:
              begin
                Form45.ComboBox1.ItemIndex := max(0, atrb.par[3]);
                Form45.Edit1.Text := inttostr(atrb.par[4]);
                Form45.Edit2.Text := inttostr(atrb.par[5]);
                Form45.Edit3.Text := inttostr(atrb.par[6]);
                if atrb.par[2] and 1 > 0 then
                  Form45.CheckBox1.Checked := true
                else
                  Form45.CheckBox1.Checked := false;
                if atrb.par[2] and 2 > 0 then
                  Form45.CheckBox2.Checked := true
                else
                  Form45.CheckBox2.Checked := false;
                if Form45.ShowModal = mrOK then
                begin
                  atrb.par[3]:=Form45.ComboBox1.ItemIndex;
                  atrb.par[4] := strtoint(Form45.Edit1.Text);
                  atrb.par[5] := strtoint(Form45.Edit2.Text);
                  atrb.par[6] := strtoint(Form45.Edit3.Text);
                  if Form45.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form45.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2]+ 2;

                end;
              end;
            2:
              begin
                Form46.ComboBox1.ItemIndex := max(0, atrb.par[3]);
                Form46.Edit1.Text := inttostr(atrb.par[4]);
                Form46.Edit2.Text := inttostr(atrb.par[5]);
                Form46.Edit3.Text := inttostr(atrb.par[6]);
                if atrb.par[2] and 1 > 0 then
                  Form46.CheckBox1.Checked := true
                else
                  Form46.CheckBox1.Checked := false;
                if Form46.ShowModal = mrOK then
                begin
                  atrb.par[3]:=Form46.ComboBox1.ItemIndex;
                  atrb.par[4] := strtoint(Form46.Edit1.Text);
                  atrb.par[5] := strtoint(Form46.Edit2.Text);
                  atrb.par[6] := strtoint(Form46.Edit3.Text);
                  if Form46.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                end;
              end;
            3:
              begin
                Form47.Edit1.Text := inttostr(atrb.par[4]);
                Form47.Edit2.Text := inttostr(atrb.par[5]);
                Form47.Edit3.Text := inttostr(atrb.par[6]);
                Form47.ComboBox1.ItemIndex := max(atrb.par[3], 0);
                if atrb.par[2]=0 then
                  Form47.CheckBox1.Checked := false
                else
                  Form47.CheckBox1.Checked := true;
                if FOrm47.ShowModal = mrOK then
                begin
                  atrb.par[4]:= strtoint(FOrm47.edit1.Text);
                  atrb.par[5]:= strtoint(FOrm47.edit2.Text);
                  atrb.par[6]:= strtoint(FOrm47.edit3.Text);
                  atrb.par[3] :=Form47.ComboBox1.ItemIndex;
                  if Form47.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                end;
              end;
            4:
              begin
                if atrb.par[2] = 0 then
                  Form48.CheckBox1.Checked := false
                else
                  Form48.CheckBox1.Checked := true;
                Form48.ComboBox1.ItemIndex:= max(0,atrb.par[3]);
                FOrm48.Edit1.Text := inttostr(atrb.par[4]);
                FOrm48.Edit2.Text := inttostr(atrb.par[5]);
                if Form48.ShowModal = mrOK then
                begin
                  if Form48.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  atrb.par[3] := Form48.ComboBox1.ItemIndex;
                  atrb.par[4] :=strtoint(Form48.Edit1.Text);
                  atrb.par[5] :=strtoint(Form48.Edit2.Text);
                end;
              end;
            8:
              begin
                Form49.ComboBox1.Clear;
                for I := 0 to talkstrnum - 1 do
                  Form49.ComboBox1.Items.Add(inttostr(I)+ ':' + displaystr(readtalkstr(@talkstr[I])));
                if atrb.par[2] = 0 then
                begin
                  FOrm49.CheckBox1.Checked := false;
                  Form49.ComboBox1.ItemIndex := max(atrb.par[3], 0);
                end
                else
                  Form49.CheckBox1.Checked := true;
                Form49.Edit2.Text := inttostr(atrb.par[3]);
                Form49.Edit1.Text := inttostr(atrb.par[4]);
                if Form49.ShowModal=mrOK then
                begin
                  atrb.par[3] := strtoint(Form49.Edit2.Text);
                  atrb.par[4] := strtoint(Form49.Edit1.Text);
                  if Form49.CheckBox1.Checked then
                    atrb.par[2]:= 1
                  else
                    atrb.par[2]:=0;
                end;
              end;
            9:
              begin
                if atrb.par[2]=0 then
                  Form50.CheckBox1.Checked := false
                else
                  Form50.CheckBox1.Checked := true;
                FOrm50.Edit1.Text := inttostr(atrb.par[3]);
                Form50.Edit2.Text := inttostr(atrb.par[4]);
                Form50.Edit3.Text := inttostr(atrb.par[5]);
                if FOrm50.ShowModal= mrOK then
                begin
                  atrb.par[3] := strtoint(Form50.Edit1.text);
                  atrb.par[4] := strtoint(Form50.Edit2.Text);
                  atrb.par[5] := strtoint(Form50.Edit3.Text);
                  if Form50.CheckBox1.Checked then
                    atrb.par[2]:=1
                  else
                    atrb.par[2]:= 0;
                end;
              end;
            10:
              begin
                Form51.Edit1.Text := inttostr(atrb.par[3]);
                Form51.Edit2.Text := inttostr(atrb.par[2]);
                if Form51.ShowModal=mrOK then
                begin
                  atrb.par[3] := strtoint(Form51.Edit1.Text);
                  atrb.par[2] := strtoint(Form51.Edit2.Text);
                end;
              end;
            11:
              begin
                Form52.Edit1.Text := inttostr(atrb.par[2]);
                Form52.Edit2.Text := inttostr(atrb.par[3]);
                Form52.Edit3.Text := inttostr(atrb.par[4]);
                if Form52.ShowModal=mrOK then
                begin
                  atrb.par[2]:= strtoint(Form52.Edit1.Text);
                  atrb.par[3]:= strtoint(Form52.Edit2.Text);
                  atrb.par[4]:= strtoint(Form52.Edit3.Text);
                end;
              end;
            12:
              begin
                Form53.Edit1.Text := inttostr(atrb.par[3]);
                Form53.Edit2.Text := inttostr(atrb.par[4]);
                if atrb.par[2]=0 then
                  Form53.CheckBox1.Checked := false
                else
                  FOrm53.CheckBox1.Checked := true;
                if Form53.ShowModal=mrOK then
                begin
                  atrb.par[3]:= strtoint(Form53.Edit1.Text);
                  atrb.par[4]:=strtoint(Form53.Edit2.Text);
                  if Form53.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2]:=0;
                end;
              end;
            16:
              begin
                Form54.initial(atrb);
                if Form54.ShowModal = mrOK then
                begin
                  atrb.par[3]:= Form54.combobox1.ItemIndex;
                  atrb.par[4] := strtoint(Form54.edit1.Text);
                  atrb.par[5] := strtoint(Form54.edit2.Text);
                  atrb.par[6] := strtoint(Form54.edit3.Text);
                  if FOrm54.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if FOrm54.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if FOrm54.CheckBox3.Checked then
                    atrb.par[2] := atrb.par[2] + 4;
                end;
              end;
            17:
              begin
                Form55.initial(atrb);
                if Form55.ShowModal=mrOK then
                begin
                  atrb.par[3]:= Form55.combobox1.ItemIndex;
                  atrb.par[4] := strtoint(Form55.edit1.Text);
                  atrb.par[5] := strtoint(Form55.edit2.Text);
                  atrb.par[6] := strtoint(Form55.edit3.Text);
                  if FOrm55.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if FOrm55.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                end;
              end;
            18:
              begin
                if (atrb.par[2] and 1 )> 0 then
                  Form56.CheckBox1.Checked := true
                else
                  Form56.CheckBox1.Checked := false;
                if (atrb.par[2] and 2) > 0 then
                  Form56.CheckBox2.Checked := true
                else
                  Form56.CheckBox2.Checked := false;
                Form56.Edit1.Text := inttostr(atrb.par[3]);
                Form56.Edit2.Text := inttostr(atrb.par[4]);
                if Form56.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form56.Edit1.Text);
                  atrb.par[4] := strtoint(Form56.Edit2.Text);
                  if Form56.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form56.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                end;
              end;
            19:
              begin
                if (atrb.par[2] and 1 )> 0 then
                  Form57.CheckBox1.Checked := true
                else
                  Form57.CheckBox1.Checked := false;
                Form57.Edit2.Text := inttostr(atrb.par[3]);
                Form57.Edit1.Text := inttostr(atrb.par[4]);
                if Form57.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form57.Edit2.Text);
                  atrb.par[4] := strtoint(Form57.Edit1.Text);
                  if Form57.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                end;
              end;
            20:
              begin
                Form58.ComboBox1.Clear;
                for I := 0 to useR.Rtype[2].datanum - 1 do
                  Form58.ComboBox1.Items.Add(CalRname(2,I));
                if atrb.par[2] = 0 then
                begin
                  Form58.ComboBox1.ItemIndex := atrb.par[3];
                  Form58.CheckBox1.Checked := false;
                end
                else
                  Form58.CheckBox1.Checked := true;
                Form58.edit2.Text := inttostr(atrb.par[3]);
                Form58.Edit1.Text := inttostr(atrb.par[4]);
                if Form58.ShowModal=mrOK then
                begin
                  atrb.par[4] :=  strtoint(Form58.Edit1.Text);
                  atrb.par[3] := strtoint(Form58.Edit2.Text);
                  if Form58.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                end;
              end;
            21:
              begin
                FOrm59.ComboBox1.Clear;
                for I := 0 to useR.Rtype[3].datanum - 1 do
                  Form59.ComboBox1.Items.Add(calRname(3,I));
                if atrb.par[2] and 1 > 0 then
                begin
                  Form59.CheckBox1.Checked := true;
                end
                else
                begin
                  Form59.CheckBox1.Checked := false;
                  Form59.ComboBox1.ItemIndex := atrb.par[3];
                end;
                if atrb.par[2] and 2> 0 then
                  Form59.CheckBox2.Checked := true
                else
                  Form59.CheckBox2.Checked := false;
                Form59.combobox2.clear;
                for I := 0 to Dini.num - 1 do
                  Form59.combobox2.items.add(inttostr(I)+':'+displayname(Dini.attrib[i]));
                if atrb.par[2] and 4 > 0 then
                  Form59.CheckBox3.Checked := true
                else
                begin
                  Form59.CheckBox3.Checked := false;
                  Form59.combobox2.itemindex := atrb.par[5];
                end;
                if atrb.par[2] and 8 > 0 then
                  Form59.CheckBox4.Checked := true
                else
                  Form59.CheckBox4.Checked := false;
                Form59.edit1.Text := inttostr(atrb.par[3]);
                Form59.edit2.Text := inttostr(atrb.par[4]);
                Form59.edit3.Text := inttostr(atrb.par[5]);
                Form59.edit4.Text := inttostr(atrb.par[6]);
                if FOrm59.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form59.Edit1.Text);
                  atrb.par[4] := strtoint(Form59.Edit2.Text);
                  atrb.par[5] := strtoint(Form59.Edit3.Text);
                  atrb.par[6] := strtoint(Form59.Edit4.Text);
                  if Form59.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if FOrm59.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if FOrm59.CheckBox3.Checked then
                    atrb.par[2] := atrb.par[2] + 4;
                  if FOrm59.CheckBox4.Checked then
                    atrb.par[2] := atrb.par[2] + 8;
                end;
              end;
            22:
              begin
                FOrm60.ComboBox1.Clear;
                for I := 0 to useR.Rtype[3].datanum - 1 do
                  Form60.ComboBox1.Items.Add(calRname(3,I));
                if atrb.par[2] and 1 > 0 then
                begin
                  Form60.CheckBox1.Checked := true;
                end
                else
                begin
                  Form60.CheckBox1.Checked := false;
                  Form60.ComboBox1.ItemIndex := atrb.par[3];
                end;
                if atrb.par[2] and 2> 0 then
                  Form60.CheckBox2.Checked := true
                else
                  Form60.CheckBox2.Checked := false;
                Form60.combobox2.clear;
                for I := 0 to Dini.num - 1 do
                  Form60.combobox2.items.add(inttostr(I)+':'+displayname(Dini.attrib[i]));
                if atrb.par[2] and 4 > 0 then
                  Form60.CheckBox3.Checked := true
                else
                begin
                  Form60.CheckBox3.Checked := false;
                  Form60.combobox2.itemindex := atrb.par[5];
                end;
                Form60.edit1.Text := inttostr(atrb.par[3]);
                Form60.edit2.Text := inttostr(atrb.par[4]);
                Form60.edit3.Text := inttostr(atrb.par[5]);
                Form60.edit4.Text := inttostr(atrb.par[6]);
                if FOrm60.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form60.Edit1.Text);
                  atrb.par[4] := strtoint(Form60.Edit2.Text);
                  atrb.par[5] := strtoint(Form60.Edit3.Text);
                  atrb.par[6] := strtoint(Form60.Edit4.Text);
                  if Form60.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if FOrm60.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if FOrm60.CheckBox3.Checked then
                    atrb.par[2] := atrb.par[2] + 4;
                end;
              end;
            23:
              begin
                FOrm61.ComboBox1.Clear;
                for I := 0 to useR.Rtype[3].datanum - 1 do
                  Form61.ComboBox1.Items.Add(CalRname(3,I));
                if atrb.par[2]and 1 > 0then
                  Form61.CheckBox1.Checked := true
                else
                begin
                  Form61.CheckBox1.Checked := false;
                  Form61.ComboBox1.ItemIndex := max(0,atrb.par[3]);
                end;
                Form61.Edit1.Text := inttostr(atrb.par[3]);
                Form61.Edit2.Text := inttostr(atrb.par[4]);
                Form61.Edit3.Text := inttostr(atrb.par[5]);
                Form61.Edit4.Text := inttostr(atrb.par[6]);
                Form61.Edit5.Text := inttostr(atrb.par[7]);
                if atrb.par[2] and 2 > 0 then
                  Form61.CheckBox2.Checked := true
                else
                  FOrm61.CheckBox2.Checked := false;
                if atrb.par[2] and 4 > 0 then
                  Form61.CheckBox3.Checked := true
                else
                  FOrm61.CheckBox3.Checked := false;
                if atrb.par[2] and 8 > 0 then
                  Form61.CheckBox4.Checked := true
                else
                  FOrm61.CheckBox4.Checked := false;
                if atrb.par[2] and 16 > 0 then
                  Form61.CheckBox5.Checked := true
                else
                  FOrm61.CheckBox5.Checked := false;
                if FOrm61.ShowModal = mrOK then
                begin
                  atrb.par[3]:=strtoint(Form61.Edit1.Text);
                  atrb.par[4]:=strtoint(Form61.Edit2.Text);
                  atrb.par[5]:=strtoint(Form61.Edit3.Text);
                  atrb.par[6]:=strtoint(Form61.Edit4.Text);
                  atrb.par[7]:=strtoint(Form61.Edit5.Text);
                  if Form61.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form61.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if Form61.CheckBox3.Checked then
                    atrb.par[2] := atrb.par[2] + 4;
                  if Form61.CheckBox4.Checked then
                    atrb.par[2] := atrb.par[2] + 8;
                  if Form61.CheckBox5.Checked then
                    atrb.par[2] := atrb.par[2] + 16;
                end;
              end;
            24:
              begin
                FOrm62.ComboBox1.Clear;
                for I := 0 to useR.Rtype[3].datanum - 1 do
                  Form62.ComboBox1.Items.Add(CalRname(3,I));
                if atrb.par[2]and 1 > 0then
                  Form62.CheckBox1.Checked := true
                else
                begin
                  Form62.CheckBox1.Checked := false;
                  Form62.ComboBox1.ItemIndex := max(0,atrb.par[3]);
                end;
                Form62.Edit1.Text := inttostr(atrb.par[3]);
                Form62.Edit2.Text := inttostr(atrb.par[4]);
                Form62.Edit3.Text := inttostr(atrb.par[5]);
                Form62.Edit4.Text := inttostr(atrb.par[6]);
                Form62.Edit5.Text := inttostr(atrb.par[7]);
                if atrb.par[2] and 2 > 0 then
                  Form62.CheckBox2.Checked := true
                else
                  FOrm62.CheckBox2.Checked := false;
                if atrb.par[2] and 4 > 0 then
                  Form62.CheckBox3.Checked := true
                else
                  FOrm62.CheckBox3.Checked := false;
                if atrb.par[2] and 8 > 0 then
                  Form62.CheckBox4.Checked := true
                else
                  FOrm62.CheckBox4.Checked := false;
                if FOrm62.ShowModal = mrOK then
                begin
                  atrb.par[3]:=strtoint(Form62.Edit1.Text);
                  atrb.par[4]:=strtoint(Form62.Edit2.Text);
                  atrb.par[5]:=strtoint(Form62.Edit3.Text);
                  atrb.par[6]:=strtoint(Form62.Edit4.Text);
                  atrb.par[7]:=strtoint(Form62.Edit5.Text);
                  if Form62.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form62.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if Form62.CheckBox3.Checked then
                    atrb.par[2] := atrb.par[2] + 4;
                  if Form62.CheckBox4.Checked then
                    atrb.par[2] := atrb.par[2] + 8;
                end;
              end;
            25:
              begin
                Form63.ComboBox1.ItemIndex := max(atrb.par[3],0);
                Form63.Edit1.Text := Format('%x', [(atrb.par[4] + atrb.par[5] shl 16)]);
                FOrm63.ComboBox2.Clear;
                for I := 0 to K50memorylist.num - 1 do
                  Form63.combobox2.Items.Add(Format('%x', [K50memorylist.addr[I]]) + displayname(K50memorylist.note[I]));
                Form63.Edit3.Text := inttostr(atrb.par[6]);
                Form63.Edit2.Text := inttostr(atrb.par[7]);
                if atrb.par[2]and 1 > 0 then
                  Form63.CheckBox2.Checked := true
                else
                  Form63.CheckBox2.Checked := false;
                if atrb.par[2] and 2 > 0 then
                  Form63.CheckBox1.Checked := true
                else
                  Form63.CheckBox1.Checked := false;
                if FOrm63.ShowModal=mrOK then
                begin
                  atrb.par[3] := max(Form63.ComboBox1.ItemIndex,0);
                  tempadr := strtoint('$' + Form63.edit1.Text);
                  atrb.par[4] := tempadr and $FFFF;
                  atrb.par[5] := (tempadr and $FFFF) shr 16;
                  atrb.par[6] := strtoint(Form63.Edit3.Text);
                  atrb.par[7] := strtoint(Form63.Edit2.Text);
                  if Form63.CheckBox2.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if FOrm63.CheckBox1.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                end;
              end;
            26:
              begin
                Form64.ComboBox1.ItemIndex := max(atrb.par[3],0);
                Form64.Edit1.Text := Format('%x', [(atrb.par[4] + atrb.par[5] shl 16)]);
                FOrm64.ComboBox2.Clear;
                for I := 0 to K50memorylist.num - 1 do
                  Form64.combobox2.Items.Add(Format('%x', [K50memorylist.addr[I]]) + displayname(K50memorylist.note[I]));
                Form64.Edit3.Text := inttostr(atrb.par[6]);
                Form64.Edit2.Text := inttostr(atrb.par[7]);
                if atrb.par[2] and 1 > 0 then
                  Form64.CheckBox1.Checked := true
                else
                  Form64.CheckBox1.Checked := false;
                if FOrm64.ShowModal=mrOK then
                begin
                  atrb.par[3] := max(Form64.ComboBox1.ItemIndex,0);
                  tempadr := strtoint('$' + Form64.edit1.Text);
                  atrb.par[4] := tempadr and $FFFF;
                  atrb.par[5] := (tempadr and $FFFF) shr 16;
                  atrb.par[6] := strtoint(Form64.Edit3.Text);
                  atrb.par[7] := strtoint(Form64.Edit2.Text);
                  if Form64.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                end;
              end;
            27:
              begin
                Form65.ComboBox1.Clear;
                for I := 1 to 4 do
                  Form65.ComboBox1.Items.Add(displayname(typename[I]));
                Form65.ComboBox1.ItemIndex := max(0, atrb.par[3]);
                Form65.ComboBox2.Clear;
                for I := 0 to useR.Rtype[FOrm65.ComboBox1.ItemIndex + 1].datanum - 1 do
                  Form65.ComboBox2.Items.Add(CalRname(Form65.ComboBox1.ItemIndex + 1, I));
                Form65.Edit1.Text := inttostr(atrb.par[5]);
                Form65.Edit2.Text := inttostr(atrb.par[4]);
                if atrb.par[2] and 1 > 0 then
                  Form65.CheckBox1.Checked := true
                else
                begin
                  Form65.CheckBox1.Checked := false;
                  Form65.ComboBox1.ItemIndex := max(0,atrb.par[4]);
                end;
                if Form65.ShowModal = mrOK then
                begin
                  atrb.par[3] := Form65.ComboBox1.ItemIndex;
                  atrb.par[4] := strtoint(Form65.Edit2.Text);
                  atrb.par[5] := strtoint(Form65.Edit1.Text);
                  if Form65.CheckBox1.Checked then
                  atrb.par[2] := 1
                  else atrb.par[2] := 0;
                end;
              end;
            28:
              begin
                Form66.Edit1.Text := inttostr(atrb.par[2]);
                if FOrm66.ShowModal = mrOK then
                begin
                  atrb.par[2] := strtoint(Form66.Edit1.Text);
                end;
              end;
            29:
              begin
                Form67.Edit1.Text := inttostr(atrb.par[3]);
                Form67.Edit2.Text := inttostr(atrb.par[4]);
                Form67.Edit3.Text := inttostr(atrb.par[5]);
                if atrb.par[6] = 0 then
                  Form67.RadioGroup1.ItemIndex := 1
                else
                  Form67.RadioGroup1.ItemIndex := 0;
                if atrb.par[2] and 1 > 0 then
                  Form67.CheckBox1.Checked := true
                else
                  Form67.CheckBox1.Checked := false;
                if atrb.par[2] and 2 > 0 then
                  Form67.CheckBox2.Checked := true
                else
                  Form67.CheckBox2.Checked := false;
                if Form67.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form67.Edit1.Text);
                  atrb.par[4] := strtoint(Form67.Edit2.Text);
                  atrb.par[5] := strtoint(Form67.Edit3.Text);
                  if Form67.CheckBox1.Checked then
                    atrb.par[2]:=1
                  else
                    atrb.par[2] := 0;
                  if Form67.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if Form67.radiogroup1.itemindex = 0 then
                    atrb.par[6] := 1
                  else
                    atrb.par[6] := 0;
                end;
              end;
            30:
              begin
                Form68.Edit1.Text := inttostr(atrb.par[3]);
                Form68.Edit2.Text := inttostr(atrb.par[4]);
                Form68.Edit3.Text := inttostr(atrb.par[5]);
                if atrb.par[2] and 1 > 0 then
                  Form68.CheckBox1.Checked := true
                else
                  Form68.CheckBox1.Checked := false;
                if atrb.par[2] and 2 > 0 then
                  Form68.CheckBox2.Checked := true
                else
                  Form68.CheckBox2.Checked := false;
                if FOrm68.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form68.Edit1.Text);
                  atrb.par[4] := strtoint(Form68.Edit2.Text);
                  atrb.par[5] := strtoint(Form68.Edit3.Text);
                  if Form68.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form68.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                end;
              end;
            31:
              begin
                Form69.Edit1.Text := inttostr(atrb.par[3]);
                Form69.Edit2.Text := inttostr(atrb.par[4]);
                Form69.Edit3.Text := inttostr(atrb.par[5]);
                if atrb.par[2] and 1 > 0 then
                  Form69.CheckBox1.Checked := true
                else
                  Form69.CheckBox1.Checked := false;
                if atrb.par[2] and 2 > 0 then
                  Form69.CheckBox2.Checked := true
                else
                  Form69.CheckBox2.Checked := false;
                if atrb.par[2] and 4 > 0 then
                  Form69.CheckBox3.Checked := true
                else
                  Form69.CheckBox3.Checked := false;
                if FOrm69.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form69.Edit1.Text);
                  atrb.par[4] := strtoint(Form69.Edit2.Text);
                  atrb.par[5] := strtoint(Form69.Edit3.Text);
                  if Form69.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form69.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if Form69.CheckBox3.Checked then
                    atrb.par[2] := atrb.par[2] + 4;
                end;
              end;
            32:
              begin
                Form70.Edit1.Text := inttostr(atrb.par[4]);
                Form70.Edit2.Text := inttostr(atrb.par[3]);
                if atrb.par[2] and 1 > 0 then
                  Form70.CheckBox1.Checked := true
                else
                  Form70.CheckBox1.Checked := false;
                if Form70.ShowModal = mrOK then
                begin
                  atrb.par[4] := strtoint(Form70.Edit1.Text);
                  atrb.par[3] := strtoint(FOrm70.Edit2.Text);
                  if Form70.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                end;
              end;
            33:
              begin
                FOrm71.initial(atrb);
                if Form71.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form71.Edit4.Text);
                  atrb.par[4] := strtoint(Form71.Edit5.Text);
                  atrb.par[5] := strtoint(Form71.Edit6.Text);
                  atrb.par[6] := strtoint(Form71.Edit3.Text);
                  if Form71.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form71.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if Form71.CheckBox3.Checked then
                    atrb.par[2] := atrb.par[2] + 4;
                end;
              end;
            34:
              begin
                Form72.Edit1.Text := inttostr(atrb.par[3]);
                Form72.Edit2.Text := inttostr(atrb.par[4]);
                Form72.Edit3.Text := inttostr(atrb.par[5]);
                Form72.Edit4.Text := inttostr(atrb.par[6]);
                Form72.Edit5.Text := inttostr(atrb.par[7]);
                if atrb.par[2] and 1 > 0 then
                  Form72.CheckBox1.Checked := true
                else
                  Form72.CheckBox1.Checked := false;
                if atrb.par[2] and 2 > 0 then
                  Form72.CheckBox2.Checked := true
                else
                  Form72.CheckBox2.Checked := false;
                if atrb.par[2] and 4 > 0 then
                  Form72.CheckBox3.Checked := true
                else
                  Form72.CheckBox3.Checked := false;
                if atrb.par[2] and 8 > 0 then
                  Form72.CheckBox4.Checked := true
                else
                  Form72.CheckBox4.Checked := false;
                if atrb.par[2] and 16 > 0 then
                  Form72.CheckBox5.Checked := true
                else
                  Form72.CheckBox5.Checked := false;
                if Form72.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(FOrm72.Edit1.Text);
                  atrb.par[4] := strtoint(FOrm72.Edit2.Text);
                  atrb.par[5] := strtoint(FOrm72.Edit3.Text);
                  atrb.par[6] := strtoint(FOrm72.Edit4.Text);
                  atrb.par[7] := strtoint(FOrm72.Edit5.Text);
                  if FOrm72.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if FOrm72.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if FOrm72.CheckBox3.Checked then
                    atrb.par[2] := atrb.par[2] + 4;
                  if FOrm72.CheckBox4.Checked then
                    atrb.par[2] := atrb.par[2] + 8;
                  if FOrm72.CheckBox5.Checked then
                    atrb.par[2] := atrb.par[2] + 16;
                end;
              end;
            35:
              begin
                Form73.Edit1.Text := inttostr(atrb.par[2]);
                Form73.Edit2.Text := inttostr(atrb.par[3]);
                Form73.Edit3.Text := inttostr(atrb.par[4]);
                if Form73.ShowModal = mrOK then
                begin
                  atrb.par[2] := strtoint(Form73.Edit1.Text);
                  atrb.par[3] := strtoint(Form73.Edit2.Text);
                  atrb.par[4] := strtoint(Form73.Edit3.Text);
                end;
              end;
            36:
              begin
                FOrm71.initial(atrb);
                if Form71.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form71.Edit4.Text);
                  atrb.par[4] := strtoint(Form71.Edit5.Text);
                  atrb.par[5] := strtoint(Form71.Edit6.Text);
                  atrb.par[6] := strtoint(Form71.Edit3.Text);
                  if Form71.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form71.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if Form71.CheckBox3.Checked then
                    atrb.par[2] := atrb.par[2] + 4;
                end;
              end;
            37:
              begin
                Form74.Edit1.Text := inttostr(atrb.par[3]);
                if atrb.par[2] and 1 >0 then
                  Form74.CheckBox1.Checked := true
                else
                  FOrm74.CheckBox1.Checked := false;
                if Form74.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form74.Edit1.Text);
                  if Form74.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                end;
              end;
            38:
              begin
                Form75.Edit1.Text := inttostr(atrb.par[4]);
                Form75.Edit2.Text := inttostr(atrb.par[3]);
                if atrb.par[2] and 1 > 0 then
                  Form75.CheckBox1.Checked := true
                else
                  Form75.CheckBox1.Checked := false;
                if Form75.ShowModal = mrOK then
                begin
                  atrb.par[4] := strtoint(Form75.Edit1.Text);
                  atrb.par[3] := strtoint(Form75.Edit2.Text);
                  if FOrm75.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                end;
              end;
            39:
              begin
                Form76.Edit1.Text := inttostr(atrb.par[3]);
                Form76.Edit2.Text := inttostr(atrb.par[4]);
                Form76.Edit3.Text := inttostr(atrb.par[5]);
                Form76.Edit4.Text := inttostr(atrb.par[6]);
                Form76.Edit5.Text := inttostr(atrb.par[7]);
                if atrb.par[2] and 1 > 0 then
                  Form76.CheckBox1.Checked := true
                else
                  Form76.CheckBox1.Checked := false;
                if atrb.par[2] and 2 > 0 then
                  Form76.CheckBox2.Checked := true
                else
                  Form76.CheckBox2.Checked := false;
                if atrb.par[2] and 4 > 0 then
                  Form76.CheckBox3.Checked := true
                else
                  Form76.CheckBox3.Checked := false;
                if FOrm76.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form76.Edit1.Text);
                  atrb.par[4] := strtoint(Form76.Edit2.Text);
                  atrb.par[5] := strtoint(Form76.Edit3.Text);
                  atrb.par[6] := strtoint(Form76.Edit4.Text);
                  atrb.par[7] := strtoint(Form76.Edit5.Text);
                  if Form76.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form76.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if Form76.CheckBox3.Checked then
                    atrb.par[2] := atrb.par[2] + 4;
                end;
              end;
            40:
              begin
                Form77.Edit1.Text := inttostr(atrb.par[3]);
                Form77.Edit2.Text := inttostr(atrb.par[4]);
                Form77.Edit3.Text := inttostr(atrb.par[5]);
                Form77.Edit4.Text := inttostr(atrb.par[6]);
                Form77.Edit5.Text := inttostr(atrb.par[7]);
                Form77.Edit6.Text := inttostr((atrb.par[2] shr 8 and $FF));
                if atrb.par[2] and 1 > 0 then
                  Form77.CheckBox1.Checked := true
                else
                  Form77.CheckBox1.Checked := false;
                if atrb.par[2] and 2 > 0 then
                  Form77.CheckBox2.Checked := true
                else
                  Form77.CheckBox2.Checked := false;
                if atrb.par[2] and 4 > 0 then
                  Form77.CheckBox3.Checked := true
                else
                  Form77.CheckBox3.Checked := false;
                if Form77.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form77.Edit1.Text);
                  atrb.par[4] := strtoint(Form77.Edit2.Text);
                  atrb.par[5] := strtoint(Form77.Edit3.Text);
                  atrb.par[6] := strtoint(Form77.Edit4.Text);
                  atrb.par[7] := strtoint(Form77.Edit5.Text);
                  if Form77.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form77.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if Form77.CheckBox3.Checked then
                    atrb.par[2] := atrb.par[2] + 4;
                  atrb.par[2] := atrb.par[2] + strtoint(Form77.Edit6.Text) shl 8;
                end;
              end;
            41:
              begin
                Form78.ComboBox1.ItemIndex := max(0,atrb.par[3]);
                Form78.Edit1.Text := inttostr(atrb.par[4]);
                Form78.Edit2.Text := inttostr(atrb.par[5]);
                Form78.Edit3.Text := inttostr(atrb.par[6]);
                if atrb.par[2] and 1 > 0 then
                  Form78.CheckBox1.Checked := true
                else
                  FOrm78.CheckBox1.Checked := false;
                if atrb.par[2] and 2 > 0 then
                  Form78.CheckBox2.Checked := true
                else
                  FOrm78.CheckBox2.Checked := false;
                if atrb.par[2] and 4 > 0 then
                  Form78.CheckBox3.Checked := true
                else
                  FOrm78.CheckBox3.Checked := false;
                if Form78.ShowModal = mrOK then
                begin
                  atrb.par[4] := strtoint(Form78.Edit1.Text);
                  atrb.par[5] := strtoint(Form78.Edit2.Text);
                  atrb.par[6] := strtoint(Form78.Edit3.Text);
                  atrb.par[3] := Form78.ComboBox1.ItemIndex;
                  if Form78.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form78.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if Form78.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 4;
                end;
              end;
            42:
              begin
                Form79.Edit1.Text := inttostr(atrb.par[3]);
                Form79.Edit2.Text := inttostr(atrb.par[4]);
                if atrb.par[2] and 1 > 0 then
                  Form79.CheckBox1.Checked := true
                else
                  Form79.CheckBox1.Checked := false;
                if atrb.par[2] and 2 > 0 then
                  Form79.CheckBox2.Checked := true
                else
                  Form79.CheckBox2.Checked := false;
                if Form79.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form79.Edit1.Text);
                  atrb.par[4] := strtoint(Form79.Edit2.Text);
                  if Form79.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form79.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                end;
              end;
            43:
              begin
                Form80.Edit1.Text := inttostr(atrb.par[3]);
                Form80.Edit2.Text := inttostr(atrb.par[4]);
                Form80.Edit3.Text := inttostr(atrb.par[5]);
                Form80.Edit4.Text := inttostr(atrb.par[6]);
                Form80.Edit5.Text := inttostr(atrb.par[7]);
                if atrb.par[2] and 1 > 0 then
                  Form80.CheckBox1.Checked := true
                else
                  Form80.CheckBox1.Checked := false;
                if atrb.par[2] and 2 > 0 then
                  Form80.CheckBox2.Checked := true
                else
                  Form80.CheckBox2.Checked := false;
                if atrb.par[2] and 4 > 0 then
                  Form80.CheckBox3.Checked := true
                else
                  Form80.CheckBox3.Checked := false;
                if atrb.par[2] and 8 > 0 then
                  Form80.CheckBox4.Checked := true
                else
                  Form80.CheckBox4.Checked := false;
                if atrb.par[2] and 16 > 0 then
                  Form80.CheckBox5.Checked := true
                else
                  Form80.CheckBox5.Checked := false;
                if Form80.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form80.Edit1.Text);
                  atrb.par[4] := strtoint(Form80.Edit2.Text);
                  atrb.par[5] := strtoint(Form80.Edit3.Text);
                  atrb.par[6] := strtoint(Form80.Edit4.Text);
                  atrb.par[7] := strtoint(Form80.Edit5.Text);
                  if Form80.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form80.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if Form80.CheckBox3.Checked then
                    atrb.par[2] := atrb.par[2] + 4;
                  if Form80.CheckBox4.Checked then
                    atrb.par[2] := atrb.par[2] + 8;
                  if Form80.CheckBox5.Checked then
                    atrb.par[2] := atrb.par[2] + 16;
                end;
              end;
            44:
              begin
                Form81.Edit1.Text := inttostr(atrb.par[3]);
                Form81.Edit2.Text := inttostr(atrb.par[4]);
                Form81.Edit3.Text := inttostr(atrb.par[5]);
                if atrb.par[2] and 1 > 0 then
                  Form81.CheckBox1.Checked := true
                else
                  Form81.CheckBox1.Checked := false;
                if atrb.par[2] and 2 > 0 then
                  Form81.CheckBox2.Checked := true
                else
                  Form81.CheckBox2.Checked := false;
                if atrb.par[2] and 4 > 0 then
                  Form81.CheckBox3.Checked := true
                else
                  Form81.CheckBox3.Checked := false;
                if Form81.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form81.Edit1.Text);
                  atrb.par[4] := strtoint(Form81.Edit2.Text);
                  atrb.par[5] := strtoint(Form81.Edit3.Text);

                  if Form81.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form81.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if Form81.CheckBox3.Checked then
                    atrb.par[2] := atrb.par[2] + 4;

                end;
              end;
            45:
              begin
                Form82.Edit1.Text := inttostr(atrb.par[3]);
                if atrb.par[2] and 1 > 0 then
                  Form82.CheckBox1.Checked := true
                else
                  Form82.CheckBox1.Checked := false;
                if FOrm82.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form82.Edit1.Text);
                   if Form82.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                end;
              end;
            46:
              begin
                Form83.Edit1.Text := inttostr(atrb.par[3]);
                Form83.Edit2.Text := inttostr(atrb.par[4]);
                Form83.Edit3.Text := inttostr(atrb.par[5]);
                Form83.Edit4.Text := inttostr(atrb.par[6]);
                Form83.Edit5.Text := inttostr(atrb.par[7]);
                if atrb.par[2] and 1 > 0 then
                  Form83.CheckBox1.Checked := true
                else
                  Form83.CheckBox1.Checked := false;
                if atrb.par[2] and 2 > 0 then
                  Form83.CheckBox2.Checked := true
                else
                  Form83.CheckBox2.Checked := false;
                if atrb.par[2] and 4 > 0 then
                  Form83.CheckBox3.Checked := true
                else
                  Form83.CheckBox3.Checked := false;
                if atrb.par[2] and 8 > 0 then
                  Form83.CheckBox4.Checked := true
                else
                  Form83.CheckBox4.Checked := false;
                if atrb.par[2] and 16 > 0 then
                  Form83.CheckBox5.Checked := true
                else
                  Form83.CheckBox5.Checked := false;
                if Form83.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form83.Edit1.Text);
                  atrb.par[4] := strtoint(Form83.Edit2.Text);
                  atrb.par[5] := strtoint(Form83.Edit3.Text);
                  atrb.par[6] := strtoint(Form83.Edit4.Text);
                  atrb.par[7] := strtoint(Form83.Edit5.Text);
                  if Form83.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                  if Form83.CheckBox2.Checked then
                    atrb.par[2] := atrb.par[2] + 2;
                  if Form83.CheckBox3.Checked then
                    atrb.par[2] := atrb.par[2] + 4;
                  if Form83.CheckBox4.Checked then
                    atrb.par[2] := atrb.par[2] + 8;
                  if Form83.CheckBox5.Checked then
                    atrb.par[2] := atrb.par[2] + 16;
                end;
              end;
            47:
              begin
                Form84.Edit1.Text := inttostr(atrb.par[3]);
                if atrb.par[2] and 1 > 0 then
                  Form84.CheckBox1.Checked := true
                else
                  Form84.CheckBox1.Checked := false;
                if FOrm84.ShowModal = mrOK then
                begin
                  atrb.par[3] := strtoint(Form84.Edit1.Text);
                   if Form84.CheckBox1.Checked then
                    atrb.par[2] := 1
                  else
                    atrb.par[2] := 0;
                end;
              end;
            48:
              begin
                Form85.Edit1.Text := inttostr(atrb.par[2]);
                Form85.Edit2.Text := inttostr(atrb.par[3]);
                if Form85.ShowModal = mrOK then
                begin
                  atrb.par[2] := strtoint(Form85.Edit1.Text);
                  atrb.par[3] := strtoint(Form85.Edit2.Text);
                end;
              end;
          end;
        end;
      end;
    56:
      begin
        Form34.Edit1.Text := inttostr(atrb.par[1]);
        if Form34.ShowModal = mrOK then
        begin
          atrb.par[1] := strtoint(Form34.Edit1.Text);
        end;
      end;
    60:
      begin
        Form39.ComboBox1.Clear;
        for I := 0 to useR.Rtype[3].datanum - 1 do
          Form39.ComboBox1.Items.Add(CalRname(3,I));
        Form39.ComboBox1.Itemindex := max(atrb.par[1], 0);
        FOrm39.Edit1.Text := inttostr(atrb.par[2]);
        FOrm39.Edit2.Text := inttostr(atrb.par[3]);
        if atrb.labelway = 1 then
          Form39.ComboBox2.ItemIndex := 0
        else
          Form39.ComboBox2.ItemIndex := 1;
        if Form39.ShowModal = mrOK then
        begin
          atrb.par[1] := Form39.ComboBox1.ItemIndex;
          atrb.par[2] := strtoint(Form39.Edit1.Text);
          atrb.par[3] := strtoint(Form39.Edit2.Text);
          if Form39.ComboBox2.ItemIndex = 0 then
          begin
            if atrb.labelway <> 1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].yesjump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] := 0;
              atrb.labelway := 1;
            end;
          end
          else
          begin
            if atrb.labelway <> -1 then
            begin
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Nojump] :=  atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump];
              atrb.par[kdefini.KDEFitem[atrb.attribnum].Yesjump] := 0;
              atrb.labelway := -1;
            end;
          end;
        end;
      end;
    63:
      begin
        Form25.ComboBox1.Clear;
        for I := 0 to useR.Rtype[1].datanum - 1 do
          FOrm25.ComboBox1.Items.Add(CalRname(1,I));
        Form25.ComboBox1.ItemIndex := atrb.par[1];
        Form25.Edit1.Text := inttostr(atrb.par[2]);
        if Form25.ShowModal = mrOK then
        begin
          atrb.par[1] := Form25.ComboBox1.ItemIndex;
          atrb.par[2] := strtoint(Form25.Edit1.Text);
        end;
      end;
    66:
      begin
        Form34.Edit1.Text := inttostr(atrb.par[1]);
        if Form34.ShowModal = mrOK then
        begin
          atrb.par[1] := strtoint(Form34.Edit1.Text);
        end;
      end;
    67:
      begin
        Form34.Edit1.Text := inttostr(atrb.par[1]);
        if Form34.ShowModal = mrOK then
        begin
          atrb.par[1] := strtoint(Form34.Edit1.Text);
        end;
      end;

    68:
      begin
        Form38.initial(atrb);
        if Form38.ShowModal = mrOK then
        begin
         atrb.par[1] := Form38.combobox1.ItemIndex;
         if Form38.combobox2.ItemIndex  > 0 then
           atrb.par[3]:= Form38.combobox2.ItemIndex - 1
         else
           atrb.par[3] := -2;
         atrb.par[2] :=  Form38.combobox5.ItemIndex;
         atrb.par[4]:=Form38.combobox3.ItemIndex ;
         atrb.par[5]:=Form38.combobox4.ItemIndex;
         atrb.par[6] := strtoint(Form38.Edit3.Text);
         atrb.par[7] := strtoint(Form38.Edit4.Text);
          arrangetalktocombobox;
        end;
      end;
    69:
      begin
        Form40.ComboBox1.ItemIndex := max(atrb.par[1],0);
        Form40.ComboBox2.Clear;
        for I := 0 to useR.Rtype[Form40.ComboBox1.ItemIndex + 1].datanum - 1 do
          Form40.ComboBox2.Items.Add(CalRname(Form40.ComboBox1.ItemIndex + 1,I));
        Form40.ComboBox2.ItemIndex := max(0,atrb.par[2]);
        Form40.ComboBox3.Clear;
        for I := 0 to namestrnum - 1 do
          Form40.ComboBox3.Items.Add(inttostr(I) +':'+ displaystr(readtalkstr(@namestr[I])));
        Form40.ComboBox3.ItemIndex := max(0,word(atrb.par[3]));
        if Form40.ShowModal = mrOK then
        begin
          atrb.par[1] := Form40.ComboBox1.ItemIndex;
          atrb.par[2] := Form40.ComboBox2.ItemIndex;
          atrb.par[3] := Form40.ComboBox3.ItemIndex;
        end;
      end;
    70:
      begin
        Form41.initial(atrb);
        if FOrm41.showmodal = mrOK then
        begin
          atrb.par[1] := Form41.combobox1.ItemIndex;
          atrb.par[2] := strtoint(Form41.edit3.text);
        end;
      end;
    71:
      begin
        Form42.ComboBox1.Clear;
        for I := 0 to useR.Rtype[3].datanum - 1 do
        begin
          Form42.ComboBox1.Items.Add(CalRname(3,I));
        end;
        FOrm42.ComboBox1.ItemIndex := max(0,atrb.par[1]);
        Form42.Edit1.Text := inttostr(atrb.par[2]);
        Form42.Edit2.Text := inttostr(atrb.par[3]);
        if FOrm42.ShowModal = mrOK then
        begin
          atrb.par[1] := Form42.ComboBox1.ItemIndex;
          atrb.par[2] := strtoint(Form42.Edit1.Text);
          atrb.par[3] := strtoint(Form42.Edit2.Text);
        end;
      end;
    73:
      begin
        Form34.Edit1.Text := inttostr(atrb.par[1]);
        if Form34.ShowModal = mrOK then
        begin
          atrb.par[1] := strtoint(Form34.Edit1.Text);
        end;
      end;
  end;
  result := 0;
end;



end.
