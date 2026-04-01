object Form55: TForm55
  Left = 0
  Top = 0
  Caption = #35835#21462#23646#24615
  ClientHeight = 277
  ClientWidth = 588
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 40
    Top = 16
    Width = 48
    Height = 13
    Caption = #31867#21035#21517#31216
  end
  object Label2: TLabel
    Left = 24
    Top = 69
    Width = 36
    Height = 13
    Caption = #23646#24615#20540
  end
  object Label3: TLabel
    Left = 371
    Top = 69
    Width = 24
    Height = 13
    Caption = #20559#31227
  end
  object Label4: TLabel
    Left = 195
    Top = 69
    Width = 24
    Height = 13
    Caption = #32534#21495
  end
  object ComboBox1: TComboBox
    Left = 120
    Top = 13
    Width = 137
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 0
    OnSelect = ComboBox1Select
    Items.Strings = (
      #20154#29289
      #29289#21697
      #22330#26223
      #27494#21151
      #23567#23453#21830#24215)
  end
  object Edit1: TEdit
    Left = 195
    Top = 125
    Width = 153
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 1
    Text = 'Edit1'
  end
  object ComboBox2: TComboBox
    Left = 195
    Top = 88
    Width = 153
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 2
    OnSelect = ComboBox2Select
  end
  object CheckBox1: TCheckBox
    Left = 200
    Top = 152
    Width = 121
    Height = 25
    Caption = #21464#37327
    TabOrder = 3
  end
  object CheckBox2: TCheckBox
    Left = 371
    Top = 147
    Width = 121
    Height = 25
    Caption = #21464#37327
    TabOrder = 4
  end
  object Edit2: TEdit
    Left = 371
    Top = 120
    Width = 209
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 5
    Text = 'Edit1'
  end
  object ComboBox3: TComboBox
    Left = 371
    Top = 88
    Width = 209
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 6
    OnSelect = ComboBox3Select
  end
  object Edit3: TEdit
    Left = 24
    Top = 88
    Width = 121
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 7
    Text = 'Edit1'
  end
  object Button1: TButton
    Left = 96
    Top = 208
    Width = 97
    Height = 33
    Caption = #27491#30830
    ModalResult = 1
    TabOrder = 8
  end
  object Button2: TButton
    Left = 320
    Top = 208
    Width = 97
    Height = 33
    Caption = #21462#28040
    ModalResult = 2
    TabOrder = 9
  end
end
