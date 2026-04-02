object Form89: TForm89
  Left = 0
  Top = 0
  Caption = #33485#28814#22836#20687#32534#36753
  ClientHeight = 432
  ClientWidth = 642
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsMDIChild
  OldCreateOrder = False
  Visible = True
  OnClose = FormClose
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 642
    Height = 129
    Align = alTop
    TabOrder = 0
    object Label1: TLabel
      Left = 40
      Top = 8
      Width = 94
      Height = 13
      Caption = #36873#25321'hdgrp.idx'#25991#20214
    end
    object Label2: TLabel
      Left = 40
      Top = 56
      Width = 96
      Height = 13
      Caption = #36873#25321'hdgrp.grp'#25991#20214
    end
    object Edit1: TEdit
      Left = 40
      Top = 24
      Width = 297
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 0
    end
    object Edit2: TEdit
      Left = 40
      Top = 72
      Width = 297
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 1
    end
    object Button1: TButton
      Left = 360
      Top = 15
      Width = 73
      Height = 39
      Caption = #36873#25321'idx'
      TabOrder = 2
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 360
      Top = 63
      Width = 73
      Height = 39
      Caption = #36873#25321'grp'
      TabOrder = 3
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 464
      Top = 15
      Width = 73
      Height = 39
      Caption = #25171#24320#25991#20214
      TabOrder = 4
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 464
      Top = 63
      Width = 73
      Height = 39
      Caption = #20445#23384#25991#20214
      TabOrder = 5
      OnClick = Button4Click
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 129
    Width = 121
    Height = 303
    Align = alLeft
    TabOrder = 1
    object Label3: TLabel
      Left = 16
      Top = 16
      Width = 60
      Height = 13
      Caption = #24403#21069#32534#21495#65306
    end
    object Button5: TButton
      Left = 16
      Top = 48
      Width = 33
      Height = 33
      Caption = '<<'
      TabOrder = 0
      OnClick = Button5Click
    end
    object Button6: TButton
      Left = 66
      Top = 48
      Width = 33
      Height = 33
      Caption = '>>'
      TabOrder = 1
      OnClick = Button6Click
    end
    object Button7: TButton
      Left = 16
      Top = 128
      Width = 83
      Height = 33
      Caption = #26367#25442#24403#21069#22270#29255
      TabOrder = 2
      OnClick = Button7Click
    end
    object Button8: TButton
      Left = 66
      Top = 89
      Width = 33
      Height = 33
      Caption = '+10'
      TabOrder = 3
      OnClick = Button8Click
    end
    object Button9: TButton
      Left = 16
      Top = 89
      Width = 33
      Height = 33
      Caption = '-10'
      TabOrder = 4
      OnClick = Button9Click
    end
    object Button10: TButton
      Left = 16
      Top = 167
      Width = 83
      Height = 33
      Caption = #23548#20986#22836#20687#21040'PNG'
      TabOrder = 5
      OnClick = Button10Click
    end
  end
  object Panel3: TPanel
    Left = 121
    Top = 129
    Width = 521
    Height = 303
    Align = alClient
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object Image1: TImage
      Left = 1
      Top = 1
      Width = 519
      Height = 301
      Align = alClient
      ExplicitLeft = 32
      ExplicitTop = 8
      ExplicitWidth = 465
      ExplicitHeight = 209
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 8
    Top = 8
  end
end
