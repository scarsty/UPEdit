object Form13: TForm13
  Left = 0
  Top = 0
  Margins.Left = 2
  Margins.Top = 2
  Margins.Right = 2
  Margins.Bottom = 2
  Caption = #20027#22320#22270#32534#36753
  ClientHeight = 764
  ClientWidth = 900
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
    Width = 194
    Height = 764
    Align = alLeft
    TabOrder = 0
    ExplicitHeight = 756
    object Label1: TLabel
      Left = 25
      Top = 8
      Width = 36
      Height = 13
      Caption = #25805#20316#23618
    end
    object Button1: TButton
      Left = 25
      Top = 68
      Width = 77
      Height = 34
      Caption = #36873#25321#36148#22270
      TabOrder = 0
      OnClick = Button1Click
    end
    object ComboBox1: TComboBox
      Left = 25
      Top = 25
      Width = 127
      Height = 21
      Style = csDropDownList
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      ItemIndex = 0
      TabOrder = 1
      Text = #26410#36873#25321
      OnSelect = ComboBox1Select
      Items.Strings = (
        #26410#36873#25321
        #22320#38754
        #34920#38754
        #24314#31569
        #24341#29992#24314#31569
        #20840#37096)
    end
    object GroupBox1: TGroupBox
      Left = 8
      Top = 188
      Width = 179
      Height = 499
      Caption = #24403#21069#36148#22270
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 2
      object Label2: TLabel
        Left = 17
        Top = 34
        Width = 48
        Height = 13
        Caption = #24403#21069#22320#38754
      end
      object Label3: TLabel
        Left = 17
        Top = 93
        Width = 48
        Height = 13
        Caption = #24403#21069#34920#38754
      end
      object Label4: TLabel
        Left = 17
        Top = 150
        Width = 48
        Height = 13
        Caption = #24403#21069#24314#31569
      end
      object Label5: TLabel
        Left = 17
        Top = 326
        Width = 48
        Height = 13
        Caption = #24341#29992#24314#31569
      end
      object Label6: TLabel
        Left = 17
        Top = 54
        Width = 3
        Height = 13
      end
      object Label7: TLabel
        Left = 17
        Top = 113
        Width = 3
        Height = 13
      end
      object Label8: TLabel
        Left = 84
        Top = 150
        Width = 3
        Height = 13
      end
      object Label9: TLabel
        Left = 84
        Top = 326
        Width = 3
        Height = 13
      end
      object Panel3: TPanel
        Left = 82
        Top = 18
        Width = 88
        Height = 49
        BevelKind = bkSoft
        BevelWidth = 2
        TabOrder = 0
        object Image2: TImage
          Left = 0
          Top = 0
          Width = 85
          Height = 43
        end
      end
      object Panel4: TPanel
        Left = 82
        Top = 78
        Width = 88
        Height = 50
        BevelKind = bkSoft
        BevelWidth = 2
        TabOrder = 1
        object Image3: TImage
          Left = 0
          Top = 0
          Width = 85
          Height = 43
        end
      end
      object Panel5: TPanel
        Left = 14
        Top = 170
        Width = 157
        Height = 150
        BevelKind = bkSoft
        BevelWidth = 2
        TabOrder = 2
        object Image4: TImage
          Left = 0
          Top = 0
          Width = 152
          Height = 143
        end
      end
      object Panel6: TPanel
        Left = 14
        Top = 346
        Width = 157
        Height = 150
        BevelKind = bkSoft
        BevelWidth = 2
        TabOrder = 3
        object Image5: TImage
          Left = 0
          Top = 0
          Width = 152
          Height = 143
        end
      end
    end
    object Button2: TButton
      Left = 25
      Top = 109
      Width = 77
      Height = 34
      Caption = #20445#23384#25991#20214
      TabOrder = 3
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 25
      Top = 150
      Width = 77
      Height = 34
      Caption = #23548#20986#22320#22270
      TabOrder = 4
      OnClick = Button3Click
    end
    object CheckBox1: TCheckBox
      Left = 112
      Top = 76
      Width = 76
      Height = 18
      Caption = #26356#22810#35774#32622
      TabOrder = 5
      OnClick = CheckBox1Click
    end
  end
  object Panel2: TPanel
    Left = 194
    Top = 0
    Width = 706
    Height = 764
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 704
    ExplicitHeight = 756
    object Panel7: TPanel
      Left = 1
      Top = 1
      Width = 704
      Height = 84
      Align = alTop
      TabOrder = 0
      Visible = False
      ExplicitWidth = 702
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
    object Panel9: TPanel
      Left = 1
      Top = 85
      Width = 704
      Height = 678
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      OnResize = Panel9Resize
      ExplicitWidth = 702
      ExplicitHeight = 670
      object Image1: TImage
        Left = 0
        Top = 0
        Width = 683
        Height = 637
        Align = alClient
        OnDragDrop = Image1DragDrop
        OnDragOver = Image1DragOver
        OnMouseDown = Image1MouseDown
        OnMouseMove = Image1MouseMove
        OnMouseUp = Image1MouseUp
        ExplicitWidth = 684
        ExplicitHeight = 682
      end
      object ScrollBar2: TScrollBar
        Left = 683
        Top = 0
        Width = 21
        Height = 637
        Align = alRight
        Kind = sbVertical
        LargeChange = 10
        PageSize = 0
        TabOrder = 0
        OnChange = ScrollBar2Change
        ExplicitLeft = 681
        ExplicitHeight = 629
      end
      object StatusBar1: TStatusBar
        Left = 0
        Top = 654
        Width = 704
        Height = 24
        Panels = <>
        ExplicitTop = 646
        ExplicitWidth = 702
      end
      object ScrollBar1: TScrollBar
        Left = 0
        Top = 637
        Width = 704
        Height = 17
        Align = alBottom
        LargeChange = 10
        PageSize = 0
        TabOrder = 2
        OnChange = ScrollBar1Change
        ExplicitTop = 629
        ExplicitWidth = 702
      end
    end
  end
  object Button5: TButton
    Left = 119
    Top = 109
    Width = 60
    Height = 34
    Caption = #23548#20837#22270#22359
    TabOrder = 2
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 119
    Top = 150
    Width = 59
    Height = 34
    Caption = #23548#20986#22270#22359
    TabOrder = 3
    OnClick = Button6Click
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 25
    OnTimer = Timer1Timer
    Left = 200
    Top = 16
  end
  object OpenDialog1: TOpenDialog
    Left = 144
    Top = 8
  end
  object SaveDialog1: TSaveDialog
    Left = 144
    Top = 56
  end
end
