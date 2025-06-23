object Form10: TForm10
  Left = 0
  Top = 0
  Width = 721
  Height = 577
  Margins.Left = 2
  Margins.Top = 2
  Margins.Right = 2
  Margins.Bottom = 2
  AutoScroll = True
  Caption = #25112#26007#25968#25454#32534#36753
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
  OnResize = FormResize
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 697
    Height = 102
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 25
      Top = 25
      Width = 48
      Height = 13
      Caption = #36873#25321#25112#26007
    end
    object Button1: TButton
      Left = 217
      Top = 14
      Width = 101
      Height = 34
      Caption = #35835#21462#25112#26007#25991#20214
      TabOrder = 0
      OnClick = Button1Click
    end
    object ComboBox1: TComboBox
      Left = 25
      Top = 45
      Width = 169
      Height = 21
      Style = csDropDownList
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 1
      OnSelect = ComboBox1Select
    end
    object Button2: TButton
      Left = 217
      Top = 54
      Width = 101
      Height = 35
      Caption = #20445#23384#25112#26007#25991#20214
      TabOrder = 2
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 337
      Top = 14
      Width = 109
      Height = 34
      Caption = #26032#22686#25112#26007#21040#26368#21518
      TabOrder = 3
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 337
      Top = 54
      Width = 109
      Height = 35
      Caption = #21024#38500#26368#21518#19968#20010#25112#26007
      TabOrder = 4
      OnClick = Button4Click
    end
    object Button5: TButton
      Left = 466
      Top = 14
      Width = 104
      Height = 34
      Caption = #23548#20986'Excel'
      TabOrder = 5
      Visible = False
      OnClick = Button5Click
    end
    object Button6: TButton
      Left = 588
      Top = 14
      Width = 104
      Height = 34
      Caption = #23548#20837'Excel'
      TabOrder = 6
      Visible = False
      OnClick = Button6Click
    end
    object Button11: TButton
      Left = 466
      Top = 54
      Width = 104
      Height = 35
      Caption = #23548#20986'Excel('#24555#36895')'
      TabOrder = 7
      OnClick = Button11Click
    end
    object Button12: TButton
      Left = 588
      Top = 54
      Width = 104
      Height = 35
      Caption = #23548#20837'Excel('#24555#36895')'
      TabOrder = 8
      OnClick = Button12Click
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 102
    Width = 173
    Height = 391
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 1
    object ListBox1: TListBox
      Left = 1
      Top = 1
      Width = 179
      Height = 414
      Align = alClient
      Columns = 3
      DoubleBuffered = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = []
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ItemHeight = 14
      ParentDoubleBuffered = False
      ParentFont = False
      TabOrder = 0
      OnClick = ListBox1Click
      OnDblClick = ListBox1DblClick
    end
  end
  object Panel3: TPanel
    Left = 173
    Top = 102
    Width = 524
    Height = 391
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 2
    object StatusBar1: TStatusBar
      Left = 0
      Top = 397
      Width = 524
      Height = 19
      Panels = <>
      ExplicitTop = 372
    end
    object ScrollBox1: TScrollBox
      Left = 0
      Top = 69
      Width = 524
      Height = 328
      Align = alClient
      TabOrder = 1
      ExplicitHeight = 303
      object Image1: TImage
        Left = 0
        Top = 0
        Width = 462
        Height = 302
        OnMouseDown = Image1MouseDown
        OnMouseMove = Image1MouseMove
      end
    end
    object Panel4: TPanel
      Left = 0
      Top = 0
      Width = 524
      Height = 69
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 2
      object Label2: TLabel
        Left = 17
        Top = 38
        Width = 36
        Height = 13
        Caption = #27604#20363#65306
      end
      object SpinEdit1: TSpinEdit
        Left = 61
        Top = 30
        Width = 99
        Height = 22
        MaxValue = 20
        MinValue = 1
        TabOrder = 0
        Value = 3
        OnChange = SpinEdit1Change
      end
      object CheckBox1: TCheckBox
        Left = 6
        Top = 6
        Width = 88
        Height = 18
        Caption = #26174#31034#32553#30053#22270
        Checked = True
        State = cbChecked
        TabOrder = 1
        OnClick = CheckBox1Click
      end
      object CheckBox2: TCheckBox
        Left = 115
        Top = 0
        Width = 227
        Height = 26
        Caption = #20351#29992#40736#26631#35774#23450#20301#32622#21518#19981#21462#28040#36873#25321
        TabOrder = 2
        OnClick = CheckBox2Click
      end
    end
  end
  object StatusBar2: TStatusBar
    Left = 0
    Top = 493
    Width = 697
    Height = 20
    Panels = <>
  end
  object OpenDialog1: TOpenDialog
    Left = 16
    Top = 104
  end
  object SaveDialog1: TSaveDialog
    Left = 80
    Top = 104
  end
end
