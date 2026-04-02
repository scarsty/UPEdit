unit Ict_50_16;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, head, math;

type
  TForm54 = class(TForm)
    Label1: TLabel;
    ComboBox1: TComboBox;
    Edit1: TEdit;
    ComboBox2: TComboBox;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Edit2: TEdit;
    ComboBox3: TComboBox;
    CheckBox3: TCheckBox;
    Edit3: TEdit;
    Button1: TButton;
    Button2: TButton;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Select(Sender: TObject);
    procedure initial(atrb:Pattrib);
    procedure ComboBox2Select(Sender: TObject);
    procedure ComboBox3Select(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form54: TForm54;

implementation

uses
  Redit, kdefedit;

{$R *.dfm}

procedure TForm54.ComboBox1Select(Sender: TObject);
var
  I,I2,I3: integer;
  offset: integer;
begin
  if combobox1.ItemIndex >=0 then
  begin
    combobox2.Clear;
    for I := 0 to useR.Rtype[combobox1.ItemIndex + 1].datanum - 1 do
      combobox2.Items.Add(CalRname(combobox1.ItemIndex + 1, I));
    combobox2.ItemIndex := 0;
    edit1.Text := '0';
    combobox3.Clear;
    offset := 0;
    for I := 0 to typedataitem[combobox1.ItemIndex + 1] - 1 do
      for i2 := 0 to Rini[combobox1.ItemIndex + 1].Rterm[I].datanum - 1 do
        for i3 := 0 to Rini[combobox1.ItemIndex + 1].Rterm[I].incnum - 1 do
        begin
          if Rini[combobox1.ItemIndex + 1].Rterm[I].datanum > 1 then
            combobox3.Items.Add('Æ«ÒÆ:'+inttostr(offset)+ ' '+displayname(Rini[1 +combobox1.ItemIndex].Rterm[i + i3].name) + inttostr(i2 + 1))
          else
            combobox3.Items.Add('Æ«ÒÆ:'+inttostr(offset)+ ' '+displayname(Rini[1 +combobox1.ItemIndex].Rterm[i + i3].name));
          inc(offset, Rini[1+combobox1.ItemIndex].Rterm[i+i3].datalen);
        end;
    combobox3.ItemIndex := 0;
    edit2.Text := '0';
  end;
end;

procedure TForm54.ComboBox2Select(Sender: TObject);
begin
  if not(checkbox1.Checked) then
    edit1.Text := inttostr(combobox2.ItemIndex);
end;

procedure TForm54.ComboBox3Select(Sender: TObject);
var
  I,I2,I3,offset,index:integer;
  canbreak: boolean;
begin
  if not(checkbox2.Checked) then
  begin
    canbreak := false;
    index := 0;
    offset := 0;
    for I := 0 to typedataitem[combobox1.ItemIndex + 1] - 1 do
    begin
      for i2 := 0 to Rini[combobox1.ItemIndex + 1].Rterm[I].datanum - 1 do
      begin
        for i3 := 0 to Rini[combobox1.ItemIndex + 1].Rterm[I].incnum - 1 do
        begin
          if index = combobox3.ItemIndex then
          begin
            canbreak := true;
            break;
          end;
          inc(index);
          inc(offset, Rini[1+combobox1.ItemIndex].Rterm[i+i3].datalen);
        end;
        if canbreak then
          break;
      end;
      if canbreak then
        break;
    end;
    edit2.Text := inttostr(offset);
  end;
end;

procedure TForm54.FormCreate(Sender: TObject);
var
  I: integer;
begin
  combobox1.Clear;
  for I := 1 to useR.typenumber - 1 do
    combobox1.Items.Add(displayname(typename[I]));
end;

procedure TForm54.initial(atrb:Pattrib);
var
  I,I3,I2,offset,index: integer;
  canbreak: boolean;
begin
  combobox1.ItemIndex := max(atrb.par[3],0);
  if combobox1.ItemIndex >=0 then
  begin
    combobox2.Clear;
    for I := 0 to useR.Rtype[combobox1.ItemIndex + 1].datanum - 1 do
      combobox2.Items.Add(CalRname(combobox1.ItemIndex + 1, I));
    combobox3.Clear;
    offset := 0;
    for I := 0 to typedataitem[combobox1.ItemIndex + 1] - 1 do
      for i2 := 0 to Rini[combobox1.ItemIndex + 1].Rterm[I].datanum - 1 do
        for i3 := 0 to Rini[combobox1.ItemIndex + 1].Rterm[I].incnum - 1 do
        begin
          if Rini[combobox1.ItemIndex + 1].Rterm[I].datanum > 1 then
            combobox3.Items.Add('Æ«ÒÆ:'+inttostr(offset)+ displayname(Rini[1 +combobox1.ItemIndex].Rterm[i + i3].name) + inttostr(i2 + 1))
          else
            combobox3.Items.Add('Æ«ÒÆ:'+inttostr(offset)+ displayname(Rini[1 + combobox1.ItemIndex].Rterm[i + i3].name));
          inc(offset, Rini[1+combobox1.ItemIndex].Rterm[i+i3].datalen);
        end;
  end;
  edit1.Text := inttostr(atrb.par[4]);
  edit2.Text := inttostr(atrb.par[5]);
  edit3.Text := inttostr(atrb.par[6]);
  if atrb.par[2] and 1 > 0 then
    checkbox1.Checked := true
  else
  begin
    checkbox1.Checked :=false;
    combobox2.ItemIndex := atrb.par[4];
  end;
  if atrb.par[2] and 2 > 0 then
    checkbox2.Checked := true
  else
  begin
    checkbox2.Checked :=false;
    canbreak := false;
    index := 0;
    offset := 0;
    for I := 0 to typedataitem[combobox1.ItemIndex + 1] - 1 do
    begin
      for i2 := 0 to Rini[combobox1.ItemIndex + 1].Rterm[I].datanum - 1 do
      begin
        for i3 := 0 to Rini[combobox1.ItemIndex + 1].Rterm[I].incnum - 1 do
        begin
          if offset >= atrb.par[5] then
          begin
            canbreak:= true;
            break;
          end;
          inc(offset, Rini[1+combobox1.ItemIndex].Rterm[i+i3].datalen);
          inc(index);
        end;
        if canbreak then
          break;
      end;
      if canbreak then
        break;
    end;
    combobox3.ItemIndex := index;
    edit2.Text := inttostr(offset);
  end;
  if atrb.par[2] and 4 > 0 then
    checkbox3.Checked := true
  else
  begin
    checkbox3.Checked :=false;
  end;
end;

end.
