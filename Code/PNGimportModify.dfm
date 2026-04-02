object Form95: TForm95
  Left = 0
  Top = 0
  Caption = #20462#25913#20559#31227
  ClientHeight = 372
  ClientWidth = 289
  Color = clBtnFace
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
    Left = 8
    Top = 8
    Width = 30
    Height = 13
    Caption = 'X'#20559#31227
  end
  object Label2: TLabel
    Left = 82
    Top = 8
    Width = 30
    Height = 13
    Caption = 'y'#20559#31227
  end
  object Edit1: TEdit
    Left = 8
    Top = 24
    Width = 49
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 0
    OnChange = Edit1Change
  end
  object Edit2: TEdit
    Left = 79
    Top = 24
    Width = 50
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 1
    OnChange = Edit2Change
  end
  object Button1: TButton
    Left = 31
    Top = 318
    Width = 81
    Height = 33
    Caption = #30830#23450
    ModalResult = 1
    TabOrder = 2
  end
  object Button2: TButton
    Left = 176
    Top = 318
    Width = 81
    Height = 33
    Caption = #21462#28040
    ModalResult = 2
    TabOrder = 3
  end
  object ScrollBox1: TScrollBox
    Left = 7
    Top = 57
    Width = 275
    Height = 201
    Color = clWhite
    ParentColor = False
    TabOrder = 4
    OnMouseDown = ScrollBox1MouseDown
    object Image1: TImage
      Left = 0
      Top = 0
      Width = 177
      Height = 129
      OnMouseDown = Image1MouseDown
    end
  end
  object CheckBox1: TCheckBox
    Left = 8
    Top = 295
    Width = 274
    Height = 17
    Caption = #21518#38754#30340#36873#39033#20840#37096#24212#29992#27492#20559#31227#35774#32622#19982#22270#20687#26684#24335#35774#32622
    TabOrder = 5
  end
  object CheckBox2: TCheckBox
    Left = 144
    Top = 8
    Width = 113
    Height = 17
    Caption = #26159#21542#35774#32622#36879#26126#33394
    TabOrder = 6
  end
  object Button3: TButton
    Left = 144
    Top = 28
    Width = 73
    Height = 25
    Caption = #36873#25321#36879#26126#33394
    TabOrder = 7
    OnClick = Button3Click
  end
  object CheckBox3: TCheckBox
    Left = 8
    Top = 264
    Width = 273
    Height = 25
    Caption = #26159#21542#20445#30041#21407'PNG'#26684#24335'('#33509#20445#30041#21017#20559#31227#20449#24687#26080#25928')'
    TabOrder = 8
  end
  object ColorDialog1: TColorDialog
    Left = 240
    Top = 24
  end
end
