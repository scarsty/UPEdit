object Form40: TForm40
  Left = 0
  Top = 0
  Caption = #26367#25442#21517#31216
  ClientHeight = 233
  ClientWidth = 456
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
    Left = 32
    Top = 16
    Width = 24
    Height = 13
    Caption = #31867#21035
  end
  object Label2: TLabel
    Left = 224
    Top = 16
    Width = 24
    Height = 13
    Caption = #39033#30446
  end
  object Label3: TLabel
    Left = 32
    Top = 88
    Width = 24
    Height = 13
    Caption = #21517#23383
  end
  object ComboBox1: TComboBox
    Left = 32
    Top = 35
    Width = 121
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 0
    OnSelect = ComboBox1Select
    Items.Strings = (
      #20154#29289
      #29289#21697
      #22330#26223
      #27494#21151)
  end
  object ComboBox2: TComboBox
    Left = 224
    Top = 40
    Width = 185
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 1
  end
  object ComboBox3: TComboBox
    Left = 32
    Top = 112
    Width = 241
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 2
  end
  object Button1: TButton
    Left = 32
    Top = 168
    Width = 73
    Height = 33
    Caption = #30830#23450
    ModalResult = 1
    TabOrder = 3
  end
  object Button2: TButton
    Left = 336
    Top = 168
    Width = 73
    Height = 33
    Caption = #21462#28040
    ModalResult = 2
    TabOrder = 4
  end
end
