object Form94: TForm94
  Left = 0
  Top = 0
  Caption = 'PNG'#25209#37327#23548#20837
  ClientHeight = 474
  ClientWidth = 587
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsMDIChild
  OldCreateOrder = False
  Visible = True
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label8: TLabel
    Left = 416
    Top = 47
    Width = 88
    Height = 13
    Caption = #36873#25321#24120#29992'grp'#25991#20214
  end
  object Label9: TLabel
    Left = 416
    Top = 1
    Width = 36
    Height = 13
    Caption = #36827#24230#26465
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 587
    Height = 105
    Align = alTop
    TabOrder = 0
    object Edit1: TEdit
      Left = 8
      Top = 10
      Width = 306
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ReadOnly = True
      TabOrder = 0
    end
    object Button1: TButton
      Left = 320
      Top = 8
      Width = 73
      Height = 25
      Caption = #35835#21462'col'#25991#20214
      TabOrder = 1
      OnClick = Button1Click
    end
    object Edit2: TEdit
      Left = 8
      Top = 39
      Width = 306
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ReadOnly = True
      TabOrder = 2
    end
    object Button2: TButton
      Left = 320
      Top = 39
      Width = 73
      Height = 25
      Caption = #35835#21462'idx'#25991#20214
      TabOrder = 3
      OnClick = Button2Click
    end
    object Edit3: TEdit
      Left = 8
      Top = 70
      Width = 306
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ReadOnly = True
      TabOrder = 4
    end
    object Button3: TButton
      Left = 320
      Top = 70
      Width = 73
      Height = 25
      Caption = #35835#21462'grp'#25991#20214
      TabOrder = 5
      OnClick = Button3Click
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 105
    Width = 153
    Height = 369
    Align = alLeft
    TabOrder = 1
    object Button4: TButton
      Left = 16
      Top = 17
      Width = 113
      Height = 33
      Caption = #28155#21152#26032#25991#20214
      TabOrder = 0
      OnClick = Button4Click
    end
    object Button5: TButton
      Left = 16
      Top = 64
      Width = 113
      Height = 33
      Caption = #20462#25913#24403#21069#36873#25321
      TabOrder = 1
      OnClick = Button5Click
    end
    object Button6: TButton
      Left = 16
      Top = 112
      Width = 113
      Height = 33
      Caption = #21024#38500#24403#21069#36873#25321
      TabOrder = 2
      OnClick = Button6Click
    end
    object Button7: TButton
      Left = 16
      Top = 208
      Width = 113
      Height = 33
      Caption = #20851#38381#31383#21475
      TabOrder = 3
      OnClick = Button7Click
    end
    object Button8: TButton
      Left = 16
      Top = 160
      Width = 113
      Height = 33
      Caption = #24320#22987#23548#20837
      TabOrder = 4
      OnClick = Button8Click
    end
  end
  object Panel3: TPanel
    Left = 153
    Top = 105
    Width = 434
    Height = 369
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 2
    object ListBox1: TListBox
      Left = 1
      Top = 1
      Width = 432
      Height = 367
      Align = alClient
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ItemHeight = 13
      MultiSelect = True
      TabOrder = 0
      OnDblClick = ListBox1DblClick
      OnMouseUp = ListBox1MouseUp
    end
  end
  object ComboBox1: TComboBox
    Left = 416
    Top = 66
    Width = 137
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 3
    OnChange = ComboBox1Change
  end
  object Panel4: TPanel
    Left = 416
    Top = 18
    Width = 139
    Height = 25
    BevelOuter = bvLowered
    BevelWidth = 2
    Color = clWhite
    ParentBackground = False
    TabOrder = 4
    object ProgressBar1: TProgressBar
      Left = 2
      Top = 2
      Width = 135
      Height = 21
      Align = alClient
      TabOrder = 0
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 160
    Top = 136
  end
  object OpenDialog2: TOpenDialog
    Filter = 'PNG'#22270#29255'|*.png|'#25152#26377#25991#20214'|*.*'
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofFileMustExist, ofEnableSizing]
    Left = 160
    Top = 192
  end
  object PopupMenu1: TPopupMenu
    Left = 8
    Top = 152
    object N3: TMenuItem
      Caption = #28155#21152#25991#20214
      OnClick = N3Click
    end
    object N1: TMenuItem
      Caption = #20462#25913#20559#31227
      OnClick = N1Click
    end
    object N2: TMenuItem
      Caption = #21024#38500#25152#36873
      OnClick = N2Click
    end
  end
end
