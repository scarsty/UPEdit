object Form8: TForm8
  Left = 0
  Top = 0
  Caption = #35774#32622#32534#36753#22120#37197#32622
  ClientHeight = 396
  ClientWidth = 380
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 13
  object Label1: TLabel
    Left = 32
    Top = 8
    Width = 4
    Height = 16
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Button1: TButton
    Left = 42
    Top = 344
    Width = 97
    Height = 33
    Caption = #30830#23450
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 242
    Top = 344
    Width = 97
    Height = 33
    Caption = #21462#28040
    TabOrder = 1
    OnClick = Button2Click
  end
  object RadioGroup1: TRadioGroup
    Left = 42
    Top = 89
    Width = 297
    Height = 57
    Caption = #23545#35805#25968#25454#32534#30721
    Columns = 4
    Items.Strings = (
      'GBK'
      'BIG5'
      'UNICODE'
      'UTF-8')
    TabOrder = 2
  end
  object RadioGroup2: TRadioGroup
    Left = 42
    Top = 8
    Width = 297
    Height = 57
    Caption = #28216#25103#25968#25454#32534#30721
    Columns = 4
    Items.Strings = (
      'GBK('#21069#20256')'
      'BIG5('#21407#29256#31561')'
      'UNICODE'
      'UTF-8')
    TabOrder = 3
  end
  object RadioGroup3: TRadioGroup
    Left = 42
    Top = 247
    Width = 297
    Height = 75
    Caption = #26159#21542#33258#21160#26816#26597#26356#26032'('#31243#24207#27599#27425#21551#21160#26102#26816#26597')'
    Items.Strings = (
      #26816#27979
      #26816#27979#65292#20294#26816#27979#22833#36133#26102#19981#25552#31034
      #19981#26816#27979)
    TabOrder = 4
  end
  object RadioGroup4: TRadioGroup
    Left = 42
    Top = 168
    Width = 297
    Height = 57
    Caption = #23545#35805#25968#25454#26159#21542#21462#21453
    Columns = 2
    Items.Strings = (
      #26159
      #21542)
    TabOrder = 5
  end
end
