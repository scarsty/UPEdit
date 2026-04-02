object Form86: TForm86
  Left = 0
  Top = 0
  Caption = #22797#21051#29256#21015#34920#25991#20214#32534#36753
  ClientHeight = 346
  ClientWidth = 631
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
  object Label1: TLabel
    Left = 32
    Top = 8
    Width = 48
    Height = 13
    Caption = #31163#38431#21015#34920
  end
  object Label2: TLabel
    Left = 216
    Top = 32
    Width = 6
    Height = 13
    Caption = '0'
  end
  object Label3: TLabel
    Left = 32
    Top = 64
    Width = 48
    Height = 13
    Caption = #25928#26524#21015#34920
  end
  object Label4: TLabel
    Left = 216
    Top = 88
    Width = 6
    Height = 13
    Caption = '0'
  end
  object Label5: TLabel
    Left = 32
    Top = 128
    Width = 96
    Height = 13
    Caption = #27494#22120#27494#21151#37197#21512#21015#34920
  end
  object Label6: TLabel
    Left = 216
    Top = 152
    Width = 6
    Height = 13
    Caption = '0'
  end
  object Label7: TLabel
    Left = 32
    Top = 192
    Width = 72
    Height = 13
    Caption = #21319#32423#32463#39564#21015#34920
  end
  object Label8: TLabel
    Left = 216
    Top = 216
    Width = 6
    Height = 13
    Caption = '0'
  end
  object Label9: TLabel
    Left = 280
    Top = 8
    Width = 24
    Height = 13
    Caption = #38431#21592
  end
  object Label10: TLabel
    Left = 280
    Top = 69
    Width = 24
    Height = 13
    Caption = #24103#25968
  end
  object Label11: TLabel
    Left = 280
    Top = 128
    Width = 24
    Height = 13
    Caption = #27494#22120
  end
  object Label12: TLabel
    Left = 400
    Top = 128
    Width = 24
    Height = 13
    Caption = #27494#21151
  end
  object Label13: TLabel
    Left = 520
    Top = 128
    Width = 24
    Height = 13
    Caption = #21152#25104
  end
  object Label14: TLabel
    Left = 280
    Top = 192
    Width = 24
    Height = 13
    Caption = #32463#39564
  end
  object ScrollBar1: TScrollBar
    Left = 32
    Top = 32
    Width = 177
    Height = 17
    Max = 99
    PageSize = 0
    TabOrder = 0
    OnChange = ScrollBar1Change
  end
  object ComboBox1: TComboBox
    Left = 280
    Top = 32
    Width = 97
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 1
    OnChange = ComboBox1Change
  end
  object ScrollBar2: TScrollBar
    Left = 32
    Top = 88
    Width = 177
    Height = 17
    Max = 199
    PageSize = 0
    TabOrder = 2
    OnChange = ScrollBar2Change
  end
  object ScrollBar3: TScrollBar
    Left = 32
    Top = 152
    Width = 177
    Height = 17
    Max = 99
    PageSize = 0
    TabOrder = 3
    OnChange = ScrollBar3Change
  end
  object ScrollBar4: TScrollBar
    Left = 32
    Top = 216
    Width = 177
    Height = 17
    Max = 99
    PageSize = 0
    TabOrder = 4
    OnChange = ScrollBar4Change
  end
  object Edit1: TEdit
    Left = 280
    Top = 88
    Width = 97
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 5
    Text = 'Edit1'
    OnChange = Edit1Change
  end
  object ComboBox2: TComboBox
    Left = 280
    Top = 152
    Width = 97
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 6
    OnChange = ComboBox2Change
  end
  object ComboBox3: TComboBox
    Left = 400
    Top = 152
    Width = 97
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 7
    OnChange = ComboBox3Change
  end
  object Edit2: TEdit
    Left = 520
    Top = 152
    Width = 81
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 8
    Text = 'Edit2'
    OnChange = Edit2Change
  end
  object Edit3: TEdit
    Left = 280
    Top = 213
    Width = 97
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 9
    Text = 'Edit2'
    OnChange = Edit3Change
  end
  object Button1: TButton
    Left = 64
    Top = 280
    Width = 81
    Height = 33
    Caption = #20445#23384
    TabOrder = 10
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 280
    Top = 280
    Width = 81
    Height = 33
    Caption = #20851#38381
    TabOrder = 11
    OnClick = Button2Click
  end
end
