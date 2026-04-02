object Form2: TForm2
  Left = 0
  Top = 0
  Caption = #36148#22270#32534#36753
  ClientHeight = 557
  ClientWidth = 757
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnMouseWheelDown = FormMouseWheelDown
  OnMouseWheelUp = FormMouseWheelUp
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 757
    Height = 89
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 372
      Top = 18
      Width = 78
      Height = 19
      Caption = #36148#22270#25918#22823#20493#25968
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
    end
    object Button1: TButton
      Left = 24
      Top = 31
      Width = 145
      Height = 33
      Caption = #22797#21046#21040#21098#20999#26495
      TabOrder = 1
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 193
      Top = 31
      Width = 145
      Height = 33
      Caption = #20174#21098#20999#26495#22797#21046
      TabOrder = 2
      OnClick = Button2Click
    end
    object ComboBox1: TComboBox
      Left = 372
      Top = 43
      Width = 177
      Height = 21
      Style = csDropDownList
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ItemIndex = 0
      TabOrder = 0
      Text = '1'
      OnChange = ComboBox1Change
      Items.Strings = (
        '1'
        '2'
        '4'
        '8'
        '16')
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 89
    Width = 129
    Height = 468
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    Visible = False
    object Label3: TLabel
      Left = 24
      Top = 16
      Width = 12
      Height = 13
      Caption = #23485
    end
    object Label4: TLabel
      Left = 24
      Top = 58
      Width = 12
      Height = 13
      Caption = #39640
    end
    object Label5: TLabel
      Left = 24
      Top = 97
      Width = 30
      Height = 13
      Caption = 'x'#20559#31227
    end
    object Label6: TLabel
      Left = 24
      Top = 144
      Width = 30
      Height = 13
      Caption = 'y'#20559#31227
    end
    object Button5: TButton
      Left = 16
      Top = 200
      Width = 89
      Height = 41
      Caption = #30830#35748#23485#39640
      TabOrder = 0
      OnClick = Button5Click
    end
    object Edit1: TEdit
      Left = 24
      Top = 34
      Width = 81
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 1
    end
    object Edit2: TEdit
      Left = 24
      Top = 72
      Width = 81
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 2
    end
    object Edit3: TEdit
      Left = 24
      Top = 112
      Width = 81
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 3
    end
    object Edit4: TEdit
      Left = 24
      Top = 160
      Width = 81
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 4
    end
    object CheckBox1: TCheckBox
      Left = 24
      Top = 256
      Width = 81
      Height = 25
      Caption = #26174#31034#20559#31227
      TabOrder = 5
      OnClick = CheckBox1Click
    end
    object Button9: TButton
      Left = 24
      Top = 325
      Width = 67
      Height = 32
      Caption = #39034#26102#38024#36716'90'
      TabOrder = 6
      OnClick = Button9Click
    end
    object Button8: TButton
      Left = 24
      Top = 287
      Width = 67
      Height = 32
      Caption = #36870#26102#38024#36716'90'
      TabOrder = 7
      OnClick = Button8Click
    end
  end
  object Panel3: TPanel
    Left = 129
    Top = 89
    Width = 224
    Height = 468
    Align = alLeft
    BevelOuter = bvLowered
    TabOrder = 2
    object Image2: TImage
      Left = 18
      Top = 268
      Width = 192
      Height = 192
      OnMouseDown = Image2MouseDown
    end
    object SpeedButton1: TSpeedButton
      Left = 98
      Top = 181
      Width = 106
      Height = 25
      AllowAllUp = True
      GroupIndex = 1
      Caption = #20197#24403#21069#39068#33394#32472#22270
    end
    object SpeedButton2: TSpeedButton
      Left = 98
      Top = 209
      Width = 106
      Height = 25
      AllowAllUp = True
      GroupIndex = 1
      Caption = #20174#22270#20013#36873#21462#39068#33394
    end
    object Label2: TLabel
      Left = 26
      Top = 201
      Width = 48
      Height = 13
      Caption = #24403#21069#39068#33394
    end
    object SpeedButton3: TSpeedButton
      Left = 98
      Top = 153
      Width = 106
      Height = 25
      AllowAllUp = True
      GroupIndex = 1
      Caption = #24038#38190#25342#21462#21491#38190#32472#22270
      OnClick = SpeedButton3Click
    end
    object Label7: TLabel
      Left = 6
      Top = 83
      Width = 203
      Height = 30
      AutoSize = False
      Caption = 'label'
      WordWrap = True
    end
    object Label8: TLabel
      Left = 6
      Top = 119
      Width = 203
      Height = 31
      AutoSize = False
      Caption = #33258#23450#20041#39068#33394#20250#33258#21160#21305#37197#21040#26368#25509#36817#30340#35843#33394#26495#20013#30340#39068#33394#65292#25152#20197#21487#33021#25481#33394#12290
      WordWrap = True
    end
    object SpeedButton4: TSpeedButton
      Left = 98
      Top = 237
      Width = 106
      Height = 25
      AllowAllUp = True
      GroupIndex = 1
      Caption = #25226#39068#33394#25913#20026#36879#26126#33394
      OnClick = SpeedButton3Click
    end
    object Button3: TButton
      Left = 41
      Top = 6
      Width = 144
      Height = 36
      Caption = #20445#23384#24403#21069#36148#22270
      TabOrder = 0
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 23
      Top = 167
      Width = 65
      Height = 28
      Caption = #33258#23450#20041#39068#33394
      TabOrder = 1
      OnClick = Button4Click
    end
    object Button6: TButton
      Left = 41
      Top = 48
      Width = 67
      Height = 30
      Caption = #27700#24179#32763#36716
      TabOrder = 2
      OnClick = Button6Click
    end
    object Button7: TButton
      Left = 117
      Top = 48
      Width = 67
      Height = 30
      Caption = #19978#19979#32763#36716
      TabOrder = 3
      OnClick = Button7Click
    end
    object Panel5: TPanel
      Left = 24
      Top = 220
      Width = 69
      Height = 37
      BevelKind = bkSoft
      BevelWidth = 2
      TabOrder = 4
      object Image3: TImage
        Left = 0
        Top = 0
        Width = 65
        Height = 33
      end
    end
  end
  object Panel4: TPanel
    Left = 353
    Top = 89
    Width = 404
    Height = 468
    Align = alClient
    TabOrder = 3
    object ScrollBox1: TScrollBox
      Left = 1
      Top = 1
      Width = 402
      Height = 466
      Align = alClient
      Color = clWhite
      ParentColor = False
      TabOrder = 0
      TabStop = True
      object Image1: TImage
        Left = 0
        Top = 0
        Width = 0
        Height = 0
        Hint = #40736#26631#24038#38190#25342#21462#65292#21491#38190#32472#22270
        OnMouseDown = Image1MouseDown
      end
    end
  end
end
