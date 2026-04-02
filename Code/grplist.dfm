object Form3: TForm3
  Left = 0
  Top = 0
  Width = 1126
  Height = 509
  Margins.Left = 2
  Margins.Top = 2
  Margins.Right = 2
  Margins.Bottom = 2
  AutoScroll = True
  Caption = 'grp'#26597#30475
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsMDIChild
  Visible = True
  OnClose = FormClose
  OnCreate = FormCreate
  OnResize = FormResize
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1110
    Height = 152
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 1108
    object Label1: TLabel
      Left = 310
      Top = 60
      Width = 88
      Height = 13
      Caption = #36873#25321#24120#29992'grp'#25991#20214
    end
    object Label2: TLabel
      Left = 310
      Top = 108
      Width = 72
      Height = 13
      Caption = #36873#25321#36148#22270#37096#20998
    end
    object Button1: TButton
      Left = 252
      Top = 62
      Width = 50
      Height = 36
      Caption = #25171#24320'idx'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Edit1: TEdit
      Left = 10
      Top = 66
      Width = 236
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ReadOnly = True
      TabOrder = 1
    end
    object Edit3: TEdit
      Left = 10
      Top = 21
      Width = 236
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ReadOnly = True
      TabOrder = 2
    end
    object Button3: TButton
      Left = 252
      Top = 14
      Width = 50
      Height = 35
      Caption = #25171#24320'col'
      TabOrder = 3
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 308
      Top = 10
      Width = 56
      Height = 44
      Caption = #26174#31034#36148#22270
      TabOrder = 4
      OnClick = Button4Click
    end
    object ComboBox1: TComboBox
      Left = 310
      Top = 79
      Width = 114
      Height = 21
      Style = csDropDownList
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 5
      OnChange = ComboBox1Change
    end
    object ComboBox2: TComboBox
      Left = 310
      Top = 126
      Width = 114
      Height = 21
      Style = csDropDownList
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 6
      OnChange = ComboBox2Change
    end
    object Edit2: TEdit
      Left = 10
      Top = 109
      Width = 236
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ReadOnly = True
      TabOrder = 7
    end
    object Button2: TButton
      Left = 252
      Top = 111
      Width = 50
      Height = 35
      Caption = #25171#24320'grp'
      TabOrder = 8
      OnClick = Button2Click
    end
    object RadioGroup1: TRadioGroup
      Left = 655
      Top = 10
      Width = 115
      Height = 132
      Caption = 'PNG'#22270#29255#32534#36753#26041#24335
      ItemIndex = 0
      Items.Strings = (
        #24635#26159#35810#38382
        #24635#26159#26367#25442'PNG'
        #24635#26159#23384#20026'RLE8')
      TabOrder = 9
      OnClick = RadioGroup1Click
    end
    object Button5: TButton
      Left = 367
      Top = 10
      Width = 56
      Height = 44
      Caption = #20445#23384#25991#20214
      TabOrder = 10
      OnClick = Button5Click
    end
    object GroupBox1: TGroupBox
      Left = 776
      Top = 10
      Width = 92
      Height = 136
      Caption = #32972#26223#21644#23383#20307#39068#33394
      TabOrder = 11
      object Button6: TButton
        Left = 10
        Top = 18
        Width = 72
        Height = 25
        Caption = #26356#25913#32972#26223#33394
        TabOrder = 0
        OnClick = Button6Click
      end
      object Panel3: TPanel
        Left = 10
        Top = 46
        Width = 71
        Height = 22
        BevelInner = bvLowered
        BevelOuter = bvLowered
        TabOrder = 1
        object Image2: TImage
          Left = 2
          Top = 2
          Width = 67
          Height = 18
          Align = alClient
          OnClick = Image2Click
          ExplicitWidth = 68
        end
      end
      object Button7: TButton
        Left = 10
        Top = 72
        Width = 72
        Height = 26
        Caption = #26356#25913#23383#20307#33394
        TabOrder = 2
        OnClick = Button7Click
      end
      object Panel4: TPanel
        Left = 10
        Top = 103
        Width = 71
        Height = 22
        BevelInner = bvLowered
        BevelOuter = bvLowered
        TabOrder = 3
        object Image3: TImage
          Left = 2
          Top = 2
          Width = 67
          Height = 18
          Align = alClient
          OnClick = Image3Click
          ExplicitWidth = 68
        end
      end
    end
    object GroupBox2: TGroupBox
      Left = 430
      Top = 10
      Width = 219
      Height = 136
      Caption = #25209#37327#35774#32622#20559#31227
      TabOrder = 12
      object Label3: TLabel
        Left = 14
        Top = 27
        Width = 36
        Height = 13
        Caption = 'From'#65306
      end
      object Label4: TLabel
        Left = 117
        Top = 27
        Width = 24
        Height = 13
        Caption = 'To'#65306
      end
      object Label5: TLabel
        Left = 17
        Top = 84
        Width = 30
        Height = 13
        Caption = 'X'#20559#31227
      end
      object Label6: TLabel
        Left = 111
        Top = 84
        Width = 30
        Height = 13
        Caption = 'Y'#20559#31227
      end
      object Button9: TButton
        Left = 3
        Top = 106
        Width = 65
        Height = 26
        Caption = #35774#32622#20559#31227
        TabOrder = 0
        OnClick = Button9Click
      end
      object Button8: TButton
        Left = 74
        Top = 106
        Width = 66
        Height = 26
        Caption = #35774#32622'x'#20559#31227
        TabOrder = 1
        OnClick = Button8Click
      end
      object Button10: TButton
        Left = 146
        Top = 105
        Width = 66
        Height = 27
        Caption = #35774#32622'y'#20559#31227
        TabOrder = 2
        OnClick = Button10Click
      end
      object Edit4: TEdit
        Left = 57
        Top = 21
        Width = 54
        Height = 21
        ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
        TabOrder = 3
        Text = '0'
      end
      object Edit5: TEdit
        Left = 147
        Top = 21
        Width = 55
        Height = 21
        ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
        TabOrder = 4
        Text = '0'
      end
      object Edit6: TEdit
        Left = 52
        Top = 79
        Width = 54
        Height = 21
        ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
        TabOrder = 5
        Text = '0'
      end
      object Edit7: TEdit
        Left = 146
        Top = 79
        Width = 55
        Height = 21
        ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
        TabOrder = 6
        Text = '0'
      end
      object ComboBox3: TComboBox
        Left = 49
        Top = 47
        Width = 125
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
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 152
    Width = 1110
    Height = 318
    Align = alClient
    BevelOuter = bvLowered
    Color = clWhite
    DoubleBuffered = True
    ParentBackground = False
    ParentDoubleBuffered = False
    TabOrder = 1
    ExplicitWidth = 1108
    ExplicitHeight = 310
    object Image1: TImage
      Left = 1
      Top = 1
      Width = 1087
      Height = 316
      Align = alClient
      OnMouseDown = Image1MouseDown
      OnMouseMove = Image1MouseMove
      OnMouseUp = Image1MouseUp
      OnStartDrag = Image1StartDrag
      ExplicitWidth = 864
      ExplicitHeight = 217
    end
    object ScrollBar2: TScrollBar
      Left = 1088
      Top = 1
      Width = 21
      Height = 316
      Align = alRight
      Kind = sbVertical
      LargeChange = 5
      Max = 0
      PageSize = 0
      TabOrder = 0
      OnChange = ScrollBar2Change
      ExplicitLeft = 1086
      ExplicitHeight = 308
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 16
    Top = 160
    object N1: TMenuItem
      Caption = #32534#36753#36148#22270
      OnClick = N1Click
    end
    object PNG2: TMenuItem
      Caption = #29992'PNG'#22270#29255#26367#25442#24403#21069'('#20445#25345'PNG'#26684#24335')'
      OnClick = PNG2Click
    end
    object PNGRLE81: TMenuItem
      Caption = #29992'PNG'#26367#25442','#24182#19988#30452#25509#23384#20026'RLE8'#26684#24335
      OnClick = PNGRLE81Click
    end
    object N3: TMenuItem
      Caption = #22797#21046#24403#21069#36148#22270
      OnClick = N3Click
    end
    object N4: TMenuItem
      Caption = #31896#36148#36148#22270
      OnClick = N4Click
    end
    object N5: TMenuItem
      Caption = #20445#23384#25991#20214
      OnClick = N5Click
    end
    object N7: TMenuItem
      Caption = #25554#20837#36148#22270
      OnClick = N7Click
    end
    object N2: TMenuItem
      Caption = #21024#38500#36148#22270
      OnClick = N2Click
    end
    object N6: TMenuItem
      Caption = #28155#21152#36148#22270#21040#26368#21518
      OnClick = N6Click
    end
    object PNG1: TMenuItem
      Caption = #20840#37096#23548#20986#21040'PNG'
      OnClick = PNG1Click
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 72
    Top = 160
  end
  object ColorDialog1: TColorDialog
    Left = 128
    Top = 160
  end
end
