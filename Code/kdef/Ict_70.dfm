object Form41: TForm41
  Left = 0
  Top = 0
  Caption = #26174#31034#23383#24149
  ClientHeight = 408
  ClientWidth = 515
  Color = clBtnFace
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
  object Image1: TImage
    Left = 256
    Top = 120
    Width = 192
    Height = 192
    OnMouseDown = Image1MouseDown
  end
  object Image2: TImage
    Left = 152
    Top = 176
    Width = 81
    Height = 25
  end
  object Image3: TImage
    Left = 152
    Top = 256
    Width = 81
    Height = 25
  end
  object Label1: TLabel
    Left = 72
    Top = 91
    Width = 24
    Height = 13
    Caption = #39068#33394
  end
  object Label2: TLabel
    Left = 72
    Top = 24
    Width = 24
    Height = 13
    Caption = #23545#35805
  end
  object Edit1: TEdit
    Left = 152
    Top = 144
    Width = 81
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ReadOnly = True
    TabOrder = 0
    Text = 'Edit1'
  end
  object Edit2: TEdit
    Left = 152
    Top = 224
    Width = 81
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ReadOnly = True
    TabOrder = 1
    Text = 'Edit1'
  end
  object RadioGroup1: TRadioGroup
    Left = 72
    Top = 132
    Width = 74
    Height = 157
    Caption = #39068#33394
    ItemIndex = 0
    Items.Strings = (
      #21069#26223#33394
      #32972#26223#33394)
    TabOrder = 2
  end
  object Edit3: TEdit
    Left = 112
    Top = 88
    Width = 81
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ReadOnly = True
    TabOrder = 3
    Text = 'Edit3'
  end
  object Button1: TButton
    Left = 88
    Top = 334
    Width = 105
    Height = 41
    Caption = #30830#23450
    ModalResult = 1
    TabOrder = 4
  end
  object Button2: TButton
    Left = 304
    Top = 334
    Width = 113
    Height = 41
    Caption = #21462#28040
    ModalResult = 2
    TabOrder = 5
  end
  object ComboBox1: TComboBox
    Left = 72
    Top = 48
    Width = 401
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 6
  end
end
