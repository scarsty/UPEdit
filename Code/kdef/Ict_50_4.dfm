object Form48: TForm48
  Left = 0
  Top = 0
  Caption = #21464#37327#21028#26029
  ClientHeight = 254
  ClientWidth = 480
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 56
    Top = 72
    Width = 31
    Height = 13
    Caption = #21464#37327'A'
  end
  object Label2: TLabel
    Left = 256
    Top = 72
    Width = 30
    Height = 13
    Caption = #21464#37327'B'
  end
  object Edit1: TEdit
    Left = 56
    Top = 96
    Width = 145
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 0
    Text = 'Edit1'
  end
  object ComboBox1: TComboBox
    Left = 88
    Top = 16
    Width = 281
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 1
    Items.Strings = (
      '0:A<B '#36339#36716#21464#37327'JMP'#20026'0'#65292#21542#21017#20026'1'
      '1:A<=B '#36339#36716#21464#37327'JMP'#20026'0'#65292#21542#21017#20026'1'
      '2:A=B '#36339#36716#21464#37327'JMP'#20026'0'#65292#21542#21017#20026'1'
      '3:A<>B '#36339#36716#21464#37327'JMP'#20026'0'#65292#21542#21017#20026'1'
      '4:A>=B '#36339#36716#21464#37327'JMP'#20026'0'#65292#21542#21017#20026'1'
      '5:A>B '#36339#36716#21464#37327'JMP'#20026'0'#65292#21542#21017#20026'1'
      '6:'#19981#31649'A'#12289'B'#30340#20540#65292'JMP'#35774#20026'0'
      '7:'#19981#31649'A'#12289'B'#30340#20540#65292'JMP'#35774#20026'1'
      '')
  end
  object Edit2: TEdit
    Left = 256
    Top = 96
    Width = 153
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 2
    Text = 'Edit2'
  end
  object CheckBox1: TCheckBox
    Left = 256
    Top = 136
    Width = 113
    Height = 25
    Caption = #21464#37327
    TabOrder = 3
  end
  object Button1: TButton
    Left = 56
    Top = 184
    Width = 113
    Height = 33
    Caption = #30830#23450
    ModalResult = 1
    TabOrder = 4
  end
  object Button2: TButton
    Left = 272
    Top = 184
    Width = 113
    Height = 33
    Caption = #21462#28040
    ModalResult = 2
    TabOrder = 5
  end
end
