object Form11: TForm11
  Left = 0
  Top = 0
  Margins.Left = 2
  Margins.Top = 2
  Margins.Right = 2
  Margins.Bottom = 2
  Caption = #25112#26007#22320#22270#32534#36753
  ClientHeight = 607
  ClientWidth = 931
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsMDIChild
  Visible = True
  WindowState = wsMaximized
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 169
    Height = 581
    Align = alLeft
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 0
    ExplicitTop = -6
    object Label1: TLabel
      Left = 34
      Top = 72
      Width = 36
      Height = 13
      Caption = #25805#20316#23618
    end
    object Label2: TLabel
      Left = 34
      Top = 22
      Width = 48
      Height = 13
      Caption = #22320#22270#32534#21495
    end
    object Label3: TLabel
      Left = 29
      Top = 365
      Width = 72
      Height = 13
      Caption = #24403#21069#22320#38754#36148#22270
    end
    object Label4: TLabel
      Left = 31
      Top = 436
      Width = 48
      Height = 13
      Caption = #24403#21069#24314#31569
    end
    object Label5: TLabel
      Left = 42
      Top = 326
      Width = 12
      Height = 13
      Caption = '    '
    end
    object Label6: TLabel
      Left = 42
      Top = 434
      Width = 9
      Height = 13
      Caption = '   '
    end
    object ComboBox1: TComboBox
      Left = 34
      Top = 42
      Width = 101
      Height = 21
      Style = csDropDownList
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 0
      OnSelect = ComboBox1Select
    end
    object ComboBox2: TComboBox
      Left = 34
      Top = 92
      Width = 101
      Height = 21
      Style = csDropDownList
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ItemIndex = 0
      TabOrder = 1
      Text = #26410#36873#25321
      OnSelect = ComboBox2Select
      Items.Strings = (
        #26410#36873#25321
        #22320#38754
        #24314#31569
        #20840#37096)
    end
    object Button1: TButton
      Left = 27
      Top = 144
      Width = 119
      Height = 29
      Caption = #36873#25321#36148#22270
      TabOrder = 2
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 27
      Top = 177
      Width = 119
      Height = 28
      Caption = #28155#21152#22320#22270#21040#26368#21518
      TabOrder = 3
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 27
      Top = 210
      Width = 119
      Height = 27
      Caption = #21024#38500#26368#21518#19968#20010#22320#22270
      TabOrder = 4
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 27
      Top = 272
      Width = 119
      Height = 28
      Caption = #20445#23384#25991#20214
      TabOrder = 10
      OnClick = Button4Click
    end
    object ExportImageButton: TButton
      Left = 29
      Top = 306
      Width = 119
      Height = 25
      Caption = #23548#20986#24403#21069#22270#29255
      TabOrder = 5
      OnClick = ExportImageButtonClick
    end
    object ExportGroundCheckBox: TCheckBox
      Left = 24
      Top = 337
      Width = 59
      Height = 22
      Caption = #22320#38754#23618
      Checked = True
      State = cbChecked
      TabOrder = 11
    end
    object ExportBuildingCheckBox: TCheckBox
      Left = 89
      Top = 337
      Width = 59
      Height = 22
      Caption = #24314#31569#23618
      Checked = True
      State = cbChecked
      TabOrder = 9
    end
    object Panel2: TPanel
      Left = 26
      Top = 384
      Width = 126
      Height = 65
      BevelKind = bkSoft
      BevelWidth = 2
      TabOrder = 12
      object Image2: TImage
        Left = -1
        Top = -1
        Width = 118
        Height = 57
        Align = alCustom
      end
    end
    object Panel3: TPanel
      Left = 27
      Top = 455
      Width = 125
      Height = 175
      BevelKind = bkSoft
      BevelWidth = 2
      TabOrder = 7
      object Image3: TImage
        Left = 2
        Top = 2
        Width = 117
        Height = 167
        Align = alClient
        ExplicitTop = 24
        ExplicitHeight = 145
      end
    end
    object Button5: TButton
      Left = 29
      Top = 240
      Width = 50
      Height = 26
      Caption = #23548#20837#22270#22359
      TabOrder = 8
      OnClick = Button5Click
    end
    object Button6: TButton
      Left = 95
      Top = 239
      Width = 51
      Height = 29
      Caption = #23548#20986#22270#22359
      TabOrder = 6
      OnClick = Button6Click
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 581
    Width = 931
    Height = 26
    Panels = <>
  end
  object Panel4: TPanel
    Left = 169
    Top = 0
    Width = 762
    Height = 581
    Align = alClient
    TabOrder = 2
    object ScrollBox1: TScrollBox
      Left = 1
      Top = 86
      Width = 760
      Height = 494
      Align = alClient
      TabOrder = 0
      object Image1: TImage
        Left = 3
        Top = -3
        Width = 2615
        Height = 1465
        ParentCustomHint = False
        OnDragDrop = Image1DragDrop
        OnDragOver = Image1DragOver
        OnMouseDown = Image1MouseDown
        OnMouseMove = Image1MouseMove
        OnMouseUp = Image1MouseUp
      end
    end
    object Panel5: TPanel
      Left = 1
      Top = 1
      Width = 760
      Height = 85
      Align = alTop
      TabOrder = 1
      Visible = False
      object RadioGroup1: TRadioGroup
        Left = 17
        Top = 10
        Width = 101
        Height = 68
        Caption = #36148#22270#27169#24335#36873#25321
        ItemIndex = 0
        Items.Strings = (
          #21407#22987'rle'#36148#22270
          'PNG'#25171#21253
          'PNG'#25991#20214#22841)
        TabOrder = 0
        OnClick = RadioGroup1Click
      end
    end
  end
  object CheckBox1: TCheckBox
    Left = 41
    Top = 120
    Width = 76
    Height = 18
    Caption = #26356#22810#35774#32622
    TabOrder = 3
    OnClick = CheckBox1Click
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 25
    OnTimer = Timer1Timer
    Left = 128
    Top = 8
  end
  object OpenDialog1: TOpenDialog
    Top = 48
  end
  object SaveDialog1: TSaveDialog
    Left = 8
  end
end
