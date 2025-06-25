object Form12: TForm12
  Left = 0
  Top = 0
  Caption = #22330#26223#22320#22270#32534#36753
  ClientHeight = 470
  ClientWidth = 792
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsMDIChild
  KeyPreview = True
  Position = poDesigned
  Visible = True
  WindowState = wsMaximized
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 198
    Height = 445
    Align = alLeft
    DoubleBuffered = False
    ParentDoubleBuffered = False
    TabOrder = 0
    ExplicitHeight = 670
    object Label1: TLabel
      Left = 10
      Top = -1
      Width = 24
      Height = 13
      Caption = #36827#24230
    end
    object Label2: TLabel
      Left = 10
      Top = 47
      Width = 36
      Height = 13
      Caption = #22330#26223#21495
    end
    object Label14: TLabel
      Left = 10
      Top = 98
      Width = 36
      Height = 13
      Caption = #25805#20316#23618
    end
    object Button1: TButton
      Left = 10
      Top = 180
      Width = 79
      Height = 27
      Caption = #36873#25321#36148#22270
      TabOrder = 0
      OnClick = Button1Click
    end
    object ComboBox1: TComboBox
      Left = 10
      Top = 18
      Width = 103
      Height = 21
      Style = csDropDownList
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 1
      OnSelect = ComboBox1Select
    end
    object ComboBox2: TComboBox
      Left = 10
      Top = 66
      Width = 103
      Height = 21
      Style = csDropDownList
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 2
      OnSelect = ComboBox2Select
    end
    object ComboBox3: TComboBox
      Left = 10
      Top = 114
      Width = 103
      Height = 21
      Style = csDropDownList
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ItemIndex = 0
      TabOrder = 3
      Text = #26410#36873#25321
      OnSelect = ComboBox3Select
      Items.Strings = (
        #26410#36873#25321
        #22320#38754#23618
        #24314#31569#23618
        #31354#20013#23618
        #20107#20214#23618
        #24314#31569#28023#25300
        #31354#20013#28023#25300
        #20840#37096)
    end
    object GroupBox1: TGroupBox
      Left = 9
      Top = 246
      Width = 176
      Height = 427
      Caption = #24403#21069#36148#22270
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 4
      object Label15: TLabel
        Left = 16
        Top = 21
        Width = 48
        Height = 13
        Caption = #24403#21069#22320#38754
      end
      object Label16: TLabel
        Left = 16
        Top = 104
        Width = 48
        Height = 13
        Caption = #24403#21069#24314#31569
      end
      object 当前空中: TLabel
        Left = 16
        Top = 240
        Width = 48
        Height = 13
        Caption = #24403#21069#31354#20013
      end
      object Label17: TLabel
        Left = 16
        Top = 303
        Width = 48
        Height = 13
        Caption = #24403#21069#20107#20214
      end
      object Label18: TLabel
        Left = 80
        Top = 21
        Width = 3
        Height = 13
      end
      object Label19: TLabel
        Left = 80
        Top = 103
        Width = 3
        Height = 13
      end
      object Label20: TLabel
        Left = 80
        Top = 240
        Width = 3
        Height = 13
      end
      object Label21: TLabel
        Left = 80
        Top = 303
        Width = 3
        Height = 13
      end
      object Panel4: TPanel
        Left = 14
        Top = 43
        Width = 133
        Height = 53
        BevelKind = bkSoft
        BevelWidth = 2
        TabOrder = 0
        object Image2: TImage
          Left = 0
          Top = 0
          Width = 129
          Height = 49
        end
      end
      object Panel5: TPanel
        Left = 14
        Top = 123
        Width = 133
        Height = 109
        BevelKind = bkSoft
        BevelWidth = 2
        TabOrder = 1
        object Image3: TImage
          Left = 0
          Top = 0
          Width = 129
          Height = 105
        end
      end
      object Panel6: TPanel
        Left = 14
        Top = 260
        Width = 133
        Height = 42
        BevelKind = bkSoft
        BevelWidth = 2
        TabOrder = 2
        object Image4: TImage
          Left = 0
          Top = 0
          Width = 129
          Height = 38
        end
      end
      object Panel7: TPanel
        Left = 14
        Top = 320
        Width = 133
        Height = 99
        BevelKind = bkSoft
        BevelWidth = 2
        TabOrder = 3
        object Image5: TImage
          Left = 0
          Top = 0
          Width = 129
          Height = 95
        end
      end
    end
    object Button3: TButton
      Left = 104
      Top = 180
      Width = 81
      Height = 27
      Caption = #20445#23384
      TabOrder = 5
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 10
      Top = 144
      Width = 79
      Height = 30
      Caption = #28155#21152#22330#26223#22320#22270
      TabOrder = 6
      OnClick = Button4Click
    end
    object Button5: TButton
      Left = 104
      Top = 144
      Width = 81
      Height = 30
      Caption = #21024#38500#26368#21518#22320#22270
      TabOrder = 7
      OnClick = Button5Click
    end
    object CheckBox1: TCheckBox
      Left = 121
      Top = 58
      Width = 73
      Height = 17
      Caption = #21024#38500#27169#24335
      TabOrder = 8
    end
    object Button7: TButton
      Left = 119
      Top = 80
      Width = 66
      Height = 25
      Caption = #23548#20837#22330#26223
      TabOrder = 9
      OnClick = Button7Click
    end
    object Button8: TButton
      Left = 119
      Top = 110
      Width = 66
      Height = 25
      Caption = #23548#20986#22330#26223
      TabOrder = 10
      OnClick = Button8Click
    end
    object Button9: TButton
      Left = 9
      Top = 215
      Width = 79
      Height = 25
      Caption = #23548#20986#24403#21069#22270#22359
      TabOrder = 11
      OnClick = Button9Click
    end
    object Button10: TButton
      Left = 104
      Top = 215
      Width = 81
      Height = 25
      Caption = #23548#20837#22270#22359
      TabOrder = 12
      OnClick = Button10Click
    end
    object CheckBox2: TCheckBox
      Left = 121
      Top = 40
      Width = 73
      Height = 17
      Caption = #26356#22810#35774#32622
      TabOrder = 13
      OnClick = CheckBox2Click
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 445
    Width = 792
    Height = 25
    Panels = <>
    ExplicitTop = 670
    ExplicitWidth = 790
  end
  object Panel8: TPanel
    Left = 198
    Top = 0
    Width = 594
    Height = 445
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitWidth = 592
    ExplicitHeight = 670
    object Panel9: TPanel
      Left = 0
      Top = 0
      Width = 594
      Height = 69
      Align = alTop
      TabOrder = 0
      Visible = False
      ExplicitWidth = 592
      object Label23: TLabel
        Left = 136
        Top = 8
        Width = 96
        Height = 13
        Caption = #25764#38144#27425#25968#19978#38480#35843#25972
      end
      object CheckBox3: TCheckBox
        Left = 26
        Top = 12
        Width = 73
        Height = 17
        Caption = #26174#31034#32593#26684
        TabOrder = 0
        OnClick = CheckBox3Click
      end
      object CheckBox4: TCheckBox
        Left = 26
        Top = 35
        Width = 105
        Height = 17
        Caption = #21482#26174#31034#25805#20316#23618
        TabOrder = 1
        OnClick = CheckBox4Click
      end
      object CheckBox5: TCheckBox
        Left = 481
        Top = 7
        Width = 80
        Height = 17
        Hint = #36873#20013#27492#39033#65292#21487#20197#22312#22320#22270#20013
        Caption = #36873#21462#27169#24335
        TabOrder = 2
        Visible = False
      end
      object SpinEdit1: TSpinEdit
        Left = 137
        Top = 27
        Width = 112
        Height = 22
        MaxValue = 100
        MinValue = 10
        TabOrder = 3
        Value = 10
        OnChange = SpinEdit1Change
      end
      object Button11: TButton
        Left = 255
        Top = 8
        Width = 98
        Height = 21
        Caption = 'undo(ctrl+z)'
        TabOrder = 4
        OnClick = Button11Click
      end
      object Button12: TButton
        Left = 255
        Top = 35
        Width = 98
        Height = 21
        Caption = 'redo(ctrl+shift+z)'
        TabOrder = 5
        OnClick = Button12Click
      end
      object RadioGroup1: TRadioGroup
        Left = 368
        Top = 1
        Width = 97
        Height = 65
        Caption = #36148#22270#27169#24335#36873#25321
        ItemIndex = 0
        Items.Strings = (
          #21407#22987'rle'#36148#22270
          'PNG'#25171#21253
          'PNG'#25991#20214#22841)
        TabOrder = 6
        OnClick = RadioGroup1Click
      end
    end
    object Panel10: TPanel
      Left = 0
      Top = 69
      Width = 594
      Height = 376
      Align = alClient
      BevelOuter = bvLowered
      TabOrder = 1
      ExplicitWidth = 592
      ExplicitHeight = 601
      object ScrollBox1: TScrollBox
        Left = 1
        Top = 1
        Width = 592
        Height = 374
        Align = alClient
        TabOrder = 0
        object Image1: TImage
          Left = 0
          Top = 0
          Width = 2500
          Height = 1400
          OnDragDrop = Image1DragDrop
          OnDragOver = Image1DragOver
          OnMouseDown = Image1MouseDown
          OnMouseMove = Image1MouseMove
          OnMouseUp = Image1MouseUp
        end
      end
      object Panel2: TPanel
        Left = 2
        Top = 2
        Width = 153
        Height = 361
        TabOrder = 1
        Visible = False
        object Label3: TLabel
          Left = 11
          Top = 19
          Width = 48
          Height = 13
          Caption = #33021#21542#36890#36807
        end
        object Label4: TLabel
          Left = 11
          Top = 46
          Width = 24
          Height = 13
          Caption = #32534#21495
        end
        object Label5: TLabel
          Left = 11
          Top = 73
          Width = 30
          Height = 13
          Caption = #20107#20214'1'
        end
        object Label6: TLabel
          Left = 11
          Top = 100
          Width = 30
          Height = 13
          Caption = #20107#20214'2'
        end
        object Label7: TLabel
          Left = 11
          Top = 127
          Width = 30
          Height = 13
          Caption = #20107#20214'3'
        end
        object Label8: TLabel
          Left = 11
          Top = 154
          Width = 48
          Height = 13
          Caption = #24320#22987#36148#22270
        end
        object Label9: TLabel
          Left = 11
          Top = 181
          Width = 48
          Height = 13
          Caption = #32467#26463#36148#22270
        end
        object Label10: TLabel
          Left = 11
          Top = 208
          Width = 48
          Height = 13
          Caption = #24320#22987#36148#22270
        end
        object Label11: TLabel
          Left = 11
          Top = 235
          Width = 48
          Height = 13
          Caption = #21160#30011#24310#36831
        end
        object Label12: TLabel
          Left = 11
          Top = 262
          Width = 30
          Height = 13
          Caption = 'X'#22352#26631
        end
        object Label13: TLabel
          Left = 11
          Top = 289
          Width = 30
          Height = 13
          Caption = 'Y'#22352#26631
        end
        object Edit1: TEdit
          Left = 65
          Top = 16
          Width = 73
          Height = 21
          ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          TabOrder = 0
        end
        object Edit2: TEdit
          Left = 65
          Top = 43
          Width = 73
          Height = 21
          ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          TabOrder = 1
        end
        object Edit3: TEdit
          Left = 65
          Top = 70
          Width = 73
          Height = 21
          ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          TabOrder = 2
        end
        object Edit4: TEdit
          Left = 65
          Top = 97
          Width = 73
          Height = 21
          ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          TabOrder = 3
        end
        object Edit5: TEdit
          Left = 65
          Top = 124
          Width = 73
          Height = 21
          ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          TabOrder = 4
        end
        object Edit6: TEdit
          Left = 65
          Top = 151
          Width = 73
          Height = 21
          ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          TabOrder = 5
        end
        object Edit7: TEdit
          Left = 65
          Top = 178
          Width = 73
          Height = 21
          ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          TabOrder = 6
        end
        object Edit8: TEdit
          Left = 65
          Top = 205
          Width = 73
          Height = 21
          ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          TabOrder = 7
        end
        object Edit9: TEdit
          Left = 65
          Top = 232
          Width = 73
          Height = 21
          ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          TabOrder = 8
        end
        object Edit10: TEdit
          Left = 65
          Top = 259
          Width = 73
          Height = 21
          ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          TabOrder = 9
        end
        object Edit11: TEdit
          Left = 65
          Top = 286
          Width = 73
          Height = 21
          ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          TabOrder = 10
        end
        object Button2: TButton
          Left = 24
          Top = 328
          Width = 105
          Height = 25
          Caption = #30830#35748#20462#25913
          TabOrder = 11
          OnClick = Button2Click
        end
      end
      object Panel3: TPanel
        Left = 2
        Top = 2
        Width = 152
        Height = 115
        TabOrder = 2
        Visible = False
        object Label22: TLabel
          Left = 32
          Top = 18
          Width = 24
          Height = 13
          Caption = #28023#25300
        end
        object Edit12: TEdit
          Left = 24
          Top = 37
          Width = 105
          Height = 21
          ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          TabOrder = 0
          OnKeyPress = Edit12KeyPress
        end
        object Button6: TButton
          Left = 40
          Top = 70
          Width = 73
          Height = 25
          Caption = #36171#20540
          TabOrder = 1
          OnClick = Button6Click
        end
      end
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 25
    OnTimer = Timer1Timer
    Left = 160
    Top = 8
  end
  object OpenDialog1: TOpenDialog
    Left = 40
    Top = 8
  end
  object SaveDialog1: TSaveDialog
    Left = 80
    Top = 8
  end
  object Timer2: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Timer2Timer
    Left = 128
  end
end
