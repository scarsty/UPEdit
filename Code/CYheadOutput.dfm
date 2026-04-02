object Form90: TForm90
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = #33485#28814#22836#20687#23548#20986
  ClientHeight = 183
  ClientWidth = 496
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
    Left = 24
    Top = 61
    Width = 24
    Height = 13
    Caption = #36827#24230
  end
  object Label2: TLabel
    Left = 24
    Top = 9
    Width = 60
    Height = 13
    Caption = #23548#20986#22320#22336#65306
  end
  object Edit1: TEdit
    Left = 24
    Top = 28
    Width = 281
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 0
  end
  object Button1: TButton
    Left = 345
    Top = 21
    Width = 112
    Height = 35
    Caption = #36873#25321#23548#20986#22320#22336
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 376
    Top = 119
    Width = 81
    Height = 33
    Caption = #20851#38381
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 24
    Top = 119
    Width = 81
    Height = 33
    Caption = #24320#22987
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 200
    Top = 119
    Width = 81
    Height = 33
    Caption = #20572#27490
    TabOrder = 4
    OnClick = Button4Click
  end
  object ProgressBar1: TProgressBar
    Left = 24
    Top = 80
    Width = 433
    Height = 26
    TabOrder = 5
  end
end
