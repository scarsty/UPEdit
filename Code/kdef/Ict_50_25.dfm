object Form63: TForm63
  Left = 0
  Top = 0
  Caption = #20445#23384#32473#23450#22320#22336#25968#25454
  ClientHeight = 381
  ClientWidth = 585
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
    Left = 32
    Top = 96
    Width = 48
    Height = 13
    Caption = #20869#23384#22320#22336
  end
  object Label2: TLabel
    Left = 256
    Top = 96
    Width = 24
    Height = 13
    Caption = #20559#31227
  end
  object Label3: TLabel
    Left = 424
    Top = 88
    Width = 12
    Height = 13
    Caption = #20540
  end
  object Label4: TLabel
    Left = 32
    Top = 216
    Width = 60
    Height = 13
    Caption = #24120#29992#20869#23384#34920
  end
  object ComboBox1: TComboBox
    Left = 32
    Top = 24
    Width = 129
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 0
    Items.Strings = (
      '16'#20301#25968
      '8'#20301#23383#33410)
  end
  object Edit1: TEdit
    Left = 32
    Top = 120
    Width = 193
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 1
    Text = 'Edit1'
  end
  object Edit2: TEdit
    Left = 256
    Top = 120
    Width = 129
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 2
    Text = 'Edit2'
  end
  object Edit3: TEdit
    Left = 424
    Top = 120
    Width = 137
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 3
    Text = 'Edit3'
  end
  object CheckBox1: TCheckBox
    Left = 256
    Top = 139
    Width = 129
    Height = 33
    Caption = #21464#37327
    TabOrder = 4
  end
  object CheckBox2: TCheckBox
    Left = 424
    Top = 139
    Width = 129
    Height = 33
    Caption = #21464#37327
    TabOrder = 5
  end
  object Button1: TButton
    Left = 104
    Top = 296
    Width = 89
    Height = 41
    Caption = #30830#23450
    ModalResult = 1
    TabOrder = 6
  end
  object Button2: TButton
    Left = 347
    Top = 296
    Width = 89
    Height = 41
    Caption = #21462#28040
    ModalResult = 2
    TabOrder = 7
  end
  object ComboBox2: TComboBox
    Left = 32
    Top = 240
    Width = 201
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 8
    OnSelect = ComboBox2Select
  end
end
