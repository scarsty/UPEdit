object Form93: TForm93
  Left = 0
  Top = 0
  Margins.Left = 2
  Margins.Top = 2
  Margins.Right = 2
  Margins.Bottom = 2
  Caption = #23548#20986#22823#22320#22270
  ClientHeight = 271
  ClientWidth = 454
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 13
  object Label1: TLabel
    Left = 136
    Top = 17
    Width = 48
    Height = 13
    Caption = #32553#25918#27604#20363
  end
  object Label2: TLabel
    Left = 241
    Top = 17
    Width = 65
    Height = 13
    Caption = '% (1~100)%'
  end
  object Button1: TButton
    Left = 18
    Top = 206
    Width = 135
    Height = 43
    Caption = #23548#20986
    TabOrder = 0
    OnClick = Button1Click
  end
  object GroupBox1: TGroupBox
    Left = 18
    Top = 8
    Width = 100
    Height = 192
    Caption = #25991#23383#35774#32622
    TabOrder = 1
    object Button3: TButton
      Left = 10
      Top = 101
      Width = 74
      Height = 34
      Caption = #26356#25913#23383#20307#33394
      TabOrder = 0
      OnClick = Button3Click
    end
    object Panel3: TPanel
      Left = 16
      Top = 142
      Width = 59
      Height = 32
      BevelInner = bvLowered
      BevelOuter = bvLowered
      Color = clYellow
      ParentBackground = False
      TabOrder = 1
      object Image1: TImage
        Left = 2
        Top = 2
        Width = 56
        Height = 28
        Align = alClient
        OnClick = Image1Click
      end
    end
    object Button2: TButton
      Left = 10
      Top = 60
      Width = 74
      Height = 34
      Caption = #20462#25913#23383#20307
      TabOrder = 2
      OnClick = Button2Click
    end
    object CheckBox1: TCheckBox
      Left = 6
      Top = 28
      Width = 102
      Height = 18
      Caption = #32472#21046#22330#26223#21517#31216
      Checked = True
      State = cbChecked
      TabOrder = 3
    end
  end
  object Edit1: TEdit
    Left = 134
    Top = 74
    Width = 302
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ReadOnly = True
    TabOrder = 2
    Text = 'map.bmp'
  end
  object Button4: TButton
    Left = 136
    Top = 42
    Width = 102
    Height = 26
    Caption = #20462#25913#20445#23384#25991#20214#21517
    TabOrder = 3
    OnClick = Button4Click
  end
  object Edit2: TEdit
    Left = 193
    Top = 14
    Width = 39
    Height = 21
    Alignment = taRightJustify
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 4
    Text = '25'
  end
  object Button5: TButton
    Left = 302
    Top = 206
    Width = 134
    Height = 43
    Caption = #20851#38381
    TabOrder = 5
    OnClick = Button5Click
  end
  object Memo1: TMemo
    Left = 134
    Top = 102
    Width = 302
    Height = 92
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 6
  end
  object CheckBox2: TCheckBox
    Left = 339
    Top = 17
    Width = 91
    Height = 13
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = #32472#21046#22320#38754#23618
    Checked = True
    State = cbChecked
    TabOrder = 7
  end
  object CheckBox3: TCheckBox
    Left = 339
    Top = 35
    Width = 97
    Height = 14
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = #32472#21046#34920#38754#23618
    Checked = True
    State = cbChecked
    TabOrder = 8
  end
  object CheckBox4: TCheckBox
    Left = 339
    Top = 54
    Width = 97
    Height = 13
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = #32472#21046#24314#31569#23618
    Checked = True
    State = cbChecked
    TabOrder = 9
  end
  object FontDialog1: TFontDialog
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Left = 216
    Top = 272
  end
  object ColorDialog1: TColorDialog
    Left = 264
    Top = 272
  end
  object SaveDialog1: TSaveDialog
    Filter = 'BMP'#22270#29255'|*.bmp|PNG'#22270#29255'|*.png'
    OnTypeChange = SaveDialog1TypeChange
    Left = 312
    Top = 272
  end
end
