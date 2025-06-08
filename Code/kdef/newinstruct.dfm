object Form9: TForm9
  Left = 0
  Top = 0
  Margins.Left = 2
  Margins.Top = 2
  Margins.Right = 2
  Margins.Bottom = 2
  Caption = #28155#21152#25351#20196
  ClientHeight = 350
  ClientWidth = 654
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 13
  object RadioGroup1: TRadioGroup
    Left = 8
    Top = 230
    Width = 529
    Height = 52
    Caption = #36339#36716#26465#20214
    Columns = 2
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Tahoma'
    Font.Style = []
    ItemIndex = 0
    Items.Strings = (
      #26159#65288#28385#36275#26465#20214#65289#21017#36339#36716
      #21542#65288#19981#28385#36275#26465#20214#65289#21017#36339#36716)
    ParentFont = False
    TabOrder = 0
    Visible = False
  end
  object RadioGroup2: TRadioGroup
    Left = 8
    Top = 289
    Width = 529
    Height = 52
    Caption = #36339#36716#26041#21521
    Columns = 2
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Tahoma'
    Font.Style = []
    ItemIndex = 0
    Items.Strings = (
      #21521#19979#36339#36716
      #21521#19978#36339#36716)
    ParentFont = False
    TabOrder = 1
    Visible = False
  end
  object ListBox1: TListBox
    Left = 8
    Top = 8
    Width = 529
    Height = 216
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Tahoma'
    Font.Style = []
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ItemHeight = 14
    ParentFont = False
    TabOrder = 2
    OnClick = ListBox1Click
    OnDblClick = ListBox1DblClick
  end
  object Button1: TButton
    Left = 550
    Top = 42
    Width = 96
    Height = 33
    Caption = #30830#23450
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Tahoma'
    Font.Style = []
    ModalResult = 1
    ParentFont = False
    TabOrder = 3
  end
  object Button2: TButton
    Left = 550
    Top = 125
    Width = 96
    Height = 35
    Caption = #21462#28040
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Tahoma'
    Font.Style = []
    ModalResult = 2
    ParentFont = False
    TabOrder = 4
  end
end
