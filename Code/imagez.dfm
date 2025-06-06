object ImzForm: TImzForm
  Left = 0
  Top = 0
  Margins.Left = 2
  Margins.Top = 2
  Margins.Right = 2
  Margins.Bottom = 2
  Caption = 'Imz'#25991#20214#32534#36753
  ClientHeight = 561
  ClientWidth = 829
  Color = clBtnFace
  Constraints.MinHeight = 596
  Constraints.MinWidth = 837
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsMDIChild
  Position = poDefault
  Visible = True
  WindowState = wsMaximized
  OnClose = FormClose
  OnCreate = FormCreate
  OnMouseWheelDown = FormMouseWheelDown
  OnMouseWheelUp = FormMouseWheelUp
  OnResize = FormResize
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 829
    Height = 146
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 821
    object GroupBox1: TGroupBox
      Left = 346
      Top = 1
      Width = 237
      Height = 139
      Caption = #25171#21253#19982#35299#21253
      TabOrder = 1
      object Label1: TLabel
        Left = 10
        Top = 22
        Width = 112
        Height = 13
        Caption = #25171#21253'/'#35299#21253#25991#20214#22841#30446#24405
      end
      object Edit1: TEdit
        Left = 10
        Top = 49
        Width = 215
        Height = 21
        ImeName = #20013#25991' - QQ'#25340#38899#36755#20837#27861
        TabOrder = 0
      end
      object Button1: TButton
        Left = 10
        Top = 88
        Width = 68
        Height = 28
        Caption = #36873#25321#25991#20214#22841
        TabOrder = 1
        OnClick = Button1Click
      end
      object Button2: TButton
        Left = 97
        Top = 88
        Width = 51
        Height = 28
        Caption = #25171#21253
        TabOrder = 2
        OnClick = Button2Click
      end
      object Button7: TButton
        Left = 174
        Top = 88
        Width = 51
        Height = 28
        Caption = #35299#21253
        TabOrder = 3
        OnClick = Button7Click
      end
    end
    object GroupBox2: TGroupBox
      Left = 10
      Top = 1
      Width = 330
      Height = 139
      Caption = 'imz'#25991#20214
      TabOrder = 0
      object Label2: TLabel
        Left = 11
        Top = 24
        Width = 91
        Height = 13
        Caption = 'imz'#25991#20214#21517'/'#30446#24405#21517
      end
      object Edit2: TEdit
        Left = 17
        Top = 48
        Width = 291
        Height = 21
        ImeName = #20013#25991' - QQ'#25340#38899#36755#20837#27861
        TabOrder = 0
      end
      object Button3: TButton
        Left = 11
        Top = 74
        Width = 56
        Height = 26
        Caption = #35835#21462#25991#20214
        TabOrder = 1
        OnClick = Button3Click
      end
      object Button4: TButton
        Left = 85
        Top = 110
        Width = 56
        Height = 26
        Caption = #20445#23384
        TabOrder = 4
        OnClick = Button4Click
      end
      object Button5: TButton
        Left = 85
        Top = 74
        Width = 56
        Height = 26
        Caption = #26174#31034
        TabOrder = 3
        OnClick = Button5Click
      end
      object CheckBox1: TCheckBox
        Left = 154
        Top = 93
        Width = 73
        Height = 17
        Caption = #21160#30011#25928#26524
        Checked = True
        State = cbChecked
        TabOrder = 5
        OnClick = CheckBox1Click
      end
      object Button6: TButton
        Left = 11
        Top = 110
        Width = 56
        Height = 26
        Caption = #35835#21462#30446#24405
        TabOrder = 2
        OnClick = Button6Click
      end
      object RadioGroup1: TRadioGroup
        Left = 234
        Top = 79
        Width = 76
        Height = 57
        Caption = #24403#21069#27169#24335
        ItemIndex = 0
        Items.Strings = (
          'imz'#27169#24335
          'PNG'#25991#20214#22841
          'PNG'#21387#32553#21253)
        TabOrder = 6
        OnClick = RadioGroup1Click
      end
    end
    object GroupBox3: TGroupBox
      Left = 590
      Top = 0
      Width = 219
      Height = 135
      Caption = #25209#37327#35774#32622#20559#31227
      TabOrder = 2
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
    Top = 146
    Width = 829
    Height = 415
    Align = alClient
    BevelOuter = bvLowered
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    ExplicitWidth = 821
    ExplicitHeight = 390
    object Image1: TImage
      Left = 1
      Top = 1
      Width = 806
      Height = 413
      Align = alClient
      OnEndDrag = Image1EndDrag
      OnMouseDown = Image1MouseDown
      OnMouseLeave = Image1MouseLeave
      OnMouseMove = Image1MouseMove
      OnMouseUp = Image1MouseUp
      OnStartDrag = Image1StartDrag
    end
    object ScrollBar1: TScrollBar
      Left = 807
      Top = 1
      Width = 21
      Height = 413
      Align = alRight
      DoubleBuffered = True
      Kind = sbVertical
      Max = 0
      PageSize = 0
      ParentDoubleBuffered = False
      TabOrder = 0
      OnChange = ScrollBar1Change
      ExplicitLeft = 799
      ExplicitHeight = 388
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 128
    Top = 8
  end
  object SaveDialog1: TSaveDialog
    Left = 184
    Top = 8
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Timer1Timer
    Left = 224
    Top = 8
  end
  object PopupMenu1: TPopupMenu
    Left = 88
    Top = 8
    object N1: TMenuItem
      Caption = #32534#36753#36148#22270
      OnClick = N1Click
    end
    object N2: TMenuItem
      Caption = #25554#20837#36148#22270
      OnClick = N2Click
    end
    object N3: TMenuItem
      Caption = #21024#38500#36148#22270
      OnClick = N3Click
    end
    object N6: TMenuItem
      Caption = #22797#21046#36148#22270
      OnClick = N6Click
    end
    object N7: TMenuItem
      Caption = #31896#36148#36148#22270
      OnClick = N7Click
    end
    object N4: TMenuItem
      Caption = #28155#21152#36148#22270#21040#26368#21518
      OnClick = N4Click
    end
    object N5: TMenuItem
      Caption = #21024#38500#26368#21518#36148#22270
      OnClick = N5Click
    end
    object N8: TMenuItem
      Caption = #35774#32622#24635#36148#22270#25968
      OnClick = N8Click
    end
  end
end
