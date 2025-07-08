object FightFrameForm: TFightFrameForm
  Left = 0
  Top = 0
  Caption = 'FightFrame'
  ClientHeight = 286
  ClientWidth = 288
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnShow = FormShow
  TextHeight = 15
  object Label1: TLabel
    Left = 32
    Top = 27
    Width = 13
    Height = 15
    Caption = #21307
  end
  object Label2: TLabel
    Left = 32
    Top = 67
    Width = 13
    Height = 15
    Caption = #25331
  end
  object Label3: TLabel
    Left = 32
    Top = 107
    Width = 13
    Height = 15
    Caption = #21073
  end
  object Label4: TLabel
    Left = 32
    Top = 147
    Width = 13
    Height = 15
    Caption = #20992
  end
  object Label5: TLabel
    Left = 32
    Top = 187
    Width = 13
    Height = 15
    Caption = #29305
  end
  object Edit1: TEdit
    Left = 120
    Top = 24
    Width = 121
    Height = 23
    TabOrder = 0
    Text = '0'
  end
  object Edit2: TEdit
    Left = 120
    Top = 64
    Width = 121
    Height = 23
    TabOrder = 1
    Text = '0'
  end
  object Edit3: TEdit
    Left = 120
    Top = 104
    Width = 121
    Height = 23
    TabOrder = 2
    Text = '0'
  end
  object Edit4: TEdit
    Left = 120
    Top = 144
    Width = 121
    Height = 23
    TabOrder = 3
    Text = '0'
  end
  object Edit5: TEdit
    Left = 120
    Top = 184
    Width = 121
    Height = 23
    TabOrder = 4
    Text = '0'
  end
  object Button1: TButton
    Left = 32
    Top = 232
    Width = 75
    Height = 25
    Caption = #30830#23450
    TabOrder = 5
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 166
    Top = 232
    Width = 75
    Height = 25
    Caption = #21462#28040
    TabOrder = 6
    OnClick = Button2Click
  end
end
