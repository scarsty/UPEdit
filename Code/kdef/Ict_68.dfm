object Form38: TForm38
  Left = 0
  Top = 0
  Caption = #26032#23545#35805
  ClientHeight = 507
  ClientWidth = 745
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 48
    Top = 16
    Width = 60
    Height = 13
    Caption = #35828#35805#20154#22836#20687
  end
  object Image1: TImage
    Left = 48
    Top = 72
    Width = 105
    Height = 97
  end
  object Image2: TImage
    Left = 192
    Top = 216
    Width = 192
    Height = 192
    OnMouseDown = Image2MouseDown
  end
  object Image3: TImage
    Left = 114
    Top = 291
    Width = 57
    Height = 17
  end
  object Image4: TImage
    Left = 114
    Top = 341
    Width = 57
    Height = 17
  end
  object Label2: TLabel
    Left = 48
    Top = 200
    Width = 24
    Height = 13
    Caption = #39068#33394
  end
  object Label3: TLabel
    Left = 176
    Top = 16
    Width = 98
    Height = 13
    Caption = #26174#31034#21517#23383'(0'#19981#26174#31034')'
  end
  object Label4: TLabel
    Left = 176
    Top = 44
    Width = 48
    Height = 13
    Caption = #26174#31034#20301#32622
  end
  object Label5: TLabel
    Left = 176
    Top = 74
    Width = 72
    Height = 13
    Caption = #26159#21542#26174#31034#22836#20687
  end
  object Label6: TLabel
    Left = 176
    Top = 99
    Width = 60
    Height = 13
    Caption = #23545#35805#26694#39068#33394
  end
  object Label7: TLabel
    Left = 456
    Top = 16
    Width = 24
    Height = 13
    Caption = #23545#35805
  end
  object ComboBox1: TComboBox
    Left = 48
    Top = 40
    Width = 105
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 0
    OnChange = ComboBox1Change
  end
  object Button1: TButton
    Left = 80
    Top = 440
    Width = 105
    Height = 33
    Caption = #30830#23450
    ModalResult = 1
    TabOrder = 1
  end
  object Button2: TButton
    Left = 448
    Top = 440
    Width = 105
    Height = 33
    Caption = #21462#28040
    ModalResult = 2
    TabOrder = 2
  end
  object RadioGroup1: TRadioGroup
    Left = 32
    Top = 264
    Width = 76
    Height = 97
    Caption = #39068#33394
    ItemIndex = 0
    Items.Strings = (
      #21069#26223#33394
      #32972#26223#33394)
    TabOrder = 3
  end
  object Edit1: TEdit
    Left = 114
    Top = 264
    Width = 57
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ReadOnly = True
    TabOrder = 4
  end
  object Edit2: TEdit
    Left = 114
    Top = 314
    Width = 57
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ReadOnly = True
    TabOrder = 5
  end
  object Edit3: TEdit
    Left = 48
    Top = 224
    Width = 121
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 6
  end
  object ComboBox2: TComboBox
    Left = 280
    Top = 13
    Width = 121
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 7
  end
  object ComboBox3: TComboBox
    Left = 280
    Top = 40
    Width = 121
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 8
    Items.Strings = (
      #24038
      #21491)
  end
  object ComboBox4: TComboBox
    Left = 280
    Top = 67
    Width = 121
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 9
    Items.Strings = (
      #26159
      #21542)
  end
  object Edit4: TEdit
    Left = 280
    Top = 96
    Width = 121
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 10
  end
  object ComboBox5: TComboBox
    Left = 456
    Top = 40
    Width = 265
    Height = 21
    Style = csDropDownList
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 11
    OnSelect = ComboBox5Select
  end
  object Button3: TButton
    Left = 456
    Top = 104
    Width = 73
    Height = 30
    Caption = #22686#21152#23545#35805
    TabOrder = 12
    OnClick = Button3Click
  end
  object Edit5: TEdit
    Left = 456
    Top = 72
    Width = 265
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 13
  end
  object Button4: TButton
    Left = 552
    Top = 104
    Width = 73
    Height = 30
    Caption = #20462#25913#23545#35805
    TabOrder = 14
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 648
    Top = 104
    Width = 73
    Height = 30
    Caption = #21024#38500#23545#35805
    TabOrder = 15
    OnClick = Button5Click
  end
  object ListBox1: TListBox
    Left = 456
    Top = 192
    Width = 265
    Height = 108
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ItemHeight = 13
    TabOrder = 16
    OnClick = ListBox1Click
  end
  object Edit6: TEdit
    Left = 456
    Top = 312
    Width = 265
    Height = 21
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 17
  end
  object Button6: TButton
    Left = 456
    Top = 341
    Width = 73
    Height = 33
    Caption = #26032#22686#21517#23383
    TabOrder = 18
    OnClick = Button6Click
  end
  object Button7: TButton
    Left = 552
    Top = 341
    Width = 73
    Height = 33
    Caption = #20462#25913#21517#23383
    TabOrder = 19
    OnClick = Button7Click
  end
  object Button8: TButton
    Left = 648
    Top = 341
    Width = 73
    Height = 33
    Caption = #20445#23384#20462#25913
    TabOrder = 20
    OnClick = Button8Click
  end
end
