object Form93: TForm93
  Left = 0
  Top = 0
  Caption = #23548#20986#22823#22320#22270
  ClientHeight = 339
  ClientWidth = 570
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 120
  TextHeight = 17
  object Label1: TLabel
    Left = 170
    Top = 21
    Width = 56
    Height = 17
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = #32553#25918#27604#20363
  end
  object Label2: TLabel
    Left = 301
    Top = 21
    Width = 84
    Height = 17
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = '% (1~100)%'
  end
  object Button1: TButton
    Left = 22
    Top = 258
    Width = 169
    Height = 53
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = #23548#20986
    TabOrder = 0
    OnClick = Button1Click
  end
  object GroupBox1: TGroupBox
    Left = 22
    Top = 10
    Width = 126
    Height = 240
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = #25991#23383#35774#32622
    TabOrder = 1
    object Button3: TButton
      Left = 13
      Top = 126
      Width = 92
      Height = 43
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #26356#25913#23383#20307#33394
      TabOrder = 0
      OnClick = Button3Click
    end
    object Panel3: TPanel
      Left = 20
      Top = 177
      Width = 74
      Height = 40
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      BevelInner = bvLowered
      BevelOuter = bvLowered
      Color = clYellow
      ParentBackground = False
      TabOrder = 1
      object Image1: TImage
        Left = 2
        Top = 2
        Width = 70
        Height = 36
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Align = alClient
        OnClick = Image1Click
        ExplicitLeft = 3
        ExplicitTop = 3
        ExplicitWidth = 69
        ExplicitHeight = 35
      end
    end
    object Button2: TButton
      Left = 13
      Top = 75
      Width = 92
      Height = 43
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #20462#25913#23383#20307
      TabOrder = 2
      OnClick = Button2Click
    end
    object CheckBox1: TCheckBox
      Left = 8
      Top = 35
      Width = 127
      Height = 23
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #32472#21046#22330#26223#21517#31216
      Checked = True
      State = cbChecked
      TabOrder = 3
    end
  end
  object Edit1: TEdit
    Left = 167
    Top = 93
    Width = 378
    Height = 25
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ReadOnly = True
    TabOrder = 2
    Text = 'map.bmp'
  end
  object Button4: TButton
    Left = 170
    Top = 52
    Width = 127
    Height = 33
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = #20462#25913#20445#23384#25991#20214#21517
    TabOrder = 3
    OnClick = Button4Click
  end
  object Edit2: TEdit
    Left = 241
    Top = 17
    Width = 49
    Height = 25
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Alignment = taRightJustify
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 4
    Text = '25'
  end
  object Button5: TButton
    Left = 377
    Top = 258
    Width = 168
    Height = 53
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = #20851#38381
    TabOrder = 5
    OnClick = Button5Click
  end
  object Memo1: TMemo
    Left = 167
    Top = 128
    Width = 378
    Height = 114
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 6
  end
  object CheckBox2: TCheckBox
    Left = 424
    Top = 21
    Width = 113
    Height = 17
    Caption = #32472#21046#22320#38754#23618
    Checked = True
    State = cbChecked
    TabOrder = 7
  end
  object CheckBox3: TCheckBox
    Left = 424
    Top = 44
    Width = 121
    Height = 17
    Caption = #32472#21046#34920#38754#23618
    Checked = True
    State = cbChecked
    TabOrder = 8
  end
  object CheckBox4: TCheckBox
    Left = 424
    Top = 67
    Width = 121
    Height = 17
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
    Left = 312
    OnTypeChange = SaveDialog1TypeChange
    Top = 272
  end
end
