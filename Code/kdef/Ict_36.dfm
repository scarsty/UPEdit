object Form33: TForm33
  Left = 0
  Top = 0
  Caption = #21028#26029#20027#35282#24615#21035' or JMP'#21464#37327#26159#21542#20026#38646
  ClientHeight = 191
  ClientWidth = 483
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 56
    Top = 40
    Width = 163
    Height = 13
    Caption = #20027#35282#24615#21035#20540#20026#26576#20540' '#25110#32773' JMP'#20026'0'
  end
  object Label2: TLabel
    Left = 256
    Top = 40
    Width = 48
    Height = 13
    Caption = #36339#36716#26465#20214
  end
  object ComboBox1: TComboBox
    Left = 56
    Top = 64
    Width = 163
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 0
    Items.Strings = (
      #24615#21035#20026'0'
      #24615#21035#20026'1'
      #24615#21035#20026'2'
      'JMP'#21464#37327#20026'0')
  end
  object ComboBox2: TComboBox
    Left = 256
    Top = 64
    Width = 153
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 1
    Items.Strings = (
      #28385#36275#26465#20214#36339#36716
      #19981#28385#36275#36339#36716)
  end
  object Button1: TButton
    Left = 64
    Top = 112
    Width = 89
    Height = 25
    Caption = #30830#23450
    ModalResult = 1
    TabOrder = 2
  end
  object Button2: TButton
    Left = 312
    Top = 112
    Width = 89
    Height = 25
    Caption = #21462#28040
    ModalResult = 2
    TabOrder = 3
  end
end
