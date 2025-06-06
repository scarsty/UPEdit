object Form5: TForm5
  Left = 0
  Top = 0
  Margins.Left = 2
  Margins.Top = 2
  Margins.Right = 2
  Margins.Bottom = 2
  Caption = 'R'#25991#20214#32534#36753
  ClientHeight = 673
  ClientWidth = 860
  Color = clBtnFace
  DoubleBuffered = True
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
    Width = 860
    Height = 169
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 858
    object Label1: TLabel
      Left = 25
      Top = 25
      Width = 56
      Height = 17
      Caption = #25968#25454#21517#31216
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -14
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object Label2: TLabel
      Left = 201
      Top = 25
      Width = 28
      Height = 17
      Caption = #24207#21495
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -14
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object Label5: TLabel
      Left = 703
      Top = 25
      Width = 56
      Height = 17
      Caption = #28216#25103#36827#24230
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -14
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object ComboBox1: TComboBox
      Left = 25
      Top = 50
      Width = 152
      Height = 21
      Style = csDropDownList
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 0
      OnChange = ComboBox1Change
    end
    object ComboBox2: TComboBox
      Left = 201
      Top = 50
      Width = 160
      Height = 21
      Style = csDropDownList
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 1
      OnSelect = ComboBox2Select
    end
    object Button1: TButton
      Left = 402
      Top = 6
      Width = 126
      Height = 35
      Caption = #35835#21462#36827#24230
      TabOrder = 2
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 552
      Top = 7
      Width = 127
      Height = 36
      Caption = #20445#23384#36827#24230
      TabOrder = 3
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 402
      Top = 47
      Width = 126
      Height = 35
      Caption = #28155#21152#39033#30446
      TabOrder = 4
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 552
      Top = 47
      Width = 127
      Height = 35
      Caption = #21024#38500#39033#30446
      TabOrder = 5
      OnClick = Button4Click
    end
    object ComboBox3: TComboBox
      Left = 703
      Top = 50
      Width = 119
      Height = 21
      Style = csDropDownList
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 6
    end
    object Button5: TButton
      Left = 402
      Top = 89
      Width = 126
      Height = 36
      Caption = #23548#20986'Excel'
      TabOrder = 7
      Visible = False
      OnClick = Button5Click
    end
    object Button6: TButton
      Left = 552
      Top = 89
      Width = 127
      Height = 36
      Caption = #23548#20837'Excel'
      TabOrder = 8
      Visible = False
      OnClick = Button6Click
    end
    object Button11: TButton
      Left = 402
      Top = 130
      Width = 126
      Height = 36
      Caption = #23548#20986'Excel('#24555#36895')'
      TabOrder = 9
      OnClick = Button11Click
    end
    object Button12: TButton
      Left = 552
      Top = 128
      Width = 127
      Height = 36
      Caption = #23548#20837'Excel('#24555#36895')'
      TabOrder = 10
      OnClick = Button12Click
    end
  end
  object Panel2: TPanel
    Left = 110
    Top = 169
    Width = 750
    Height = 504
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 1
    ExplicitWidth = 748
    ExplicitHeight = 496
    object StatusBar1: TStatusBar
      Left = 1
      Top = 483
      Width = 748
      Height = 20
      Panels = <>
      ExplicitTop = 475
      ExplicitWidth = 746
    end
    object CheckListBox1: TCheckListBox
      Left = 1
      Top = 1
      Width = 748
      Height = 482
      Align = alClient
      BevelInner = bvLowered
      BevelOuter = bvRaised
      Ctl3D = True
      Flat = False
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ItemHeight = 17
      ParentCtl3D = False
      TabOrder = 1
      OnClick = CheckListBox1Click
      OnDblClick = CheckListBox1DblClick
      ExplicitWidth = 746
      ExplicitHeight = 474
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 169
    Width = 110
    Height = 504
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitHeight = 496
    object Label3: TLabel
      Left = 11
      Top = 265
      Width = 16
      Height = 13
      Caption = 'To:'
    end
    object Label4: TLabel
      Left = 11
      Top = 214
      Width = 28
      Height = 13
      Caption = 'From:'
    end
    object Button7: TButton
      Left = 11
      Top = 6
      Width = 82
      Height = 35
      Caption = #20840#36873
      TabOrder = 0
      OnClick = Button7Click
    end
    object Button8: TButton
      Left = 11
      Top = 50
      Width = 82
      Height = 35
      Caption = #20840#19981#36873
      TabOrder = 1
      OnClick = Button8Click
    end
    object Button9: TButton
      Left = 11
      Top = 91
      Width = 82
      Height = 35
      Caption = #21453#36873
      TabOrder = 2
      OnClick = Button9Click
    end
    object RadioButton1: TRadioButton
      Left = 11
      Top = 159
      Width = 77
      Height = 26
      Caption = #36873#20013#39033#30446
      Checked = True
      TabOrder = 3
      TabStop = True
      OnClick = RadioButton1Click
    end
    object RadioButton2: TRadioButton
      Left = 11
      Top = 183
      Width = 77
      Height = 27
      Caption = #25351#23450#33539#22260
      TabOrder = 4
    end
    object Edit1: TEdit
      Left = 11
      Top = 234
      Width = 82
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 5
      Text = '0'
      OnKeyPress = Edit1KeyPress
    end
    object Edit2: TEdit
      Left = 11
      Top = 285
      Width = 82
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 6
      Text = '0'
      OnKeyPress = Edit2KeyPress
    end
    object ComboBox4: TComboBox
      Left = 11
      Top = 343
      Width = 85
      Height = 21
      Style = csDropDownList
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ItemIndex = 0
      TabOrder = 7
      Text = '='
      Items.Strings = (
        '='
        '+'
        '-'
        '*'
        '/')
    end
    object Edit3: TEdit
      Left = 11
      Top = 377
      Width = 82
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 8
      Text = '0'
    end
    object Button10: TButton
      Left = 11
      Top = 405
      Width = 82
      Height = 34
      Caption = #36171#20540#36873#20013
      TabOrder = 9
      OnClick = Button10Click
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 680
    Top = 72
  end
  object SaveDialog1: TSaveDialog
    Left = 752
    Top = 16
  end
end
