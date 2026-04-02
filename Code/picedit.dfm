object Form4: TForm4
  Left = 0
  Top = 0
  Caption = 'pic'#22270#29255#32534#36753
  ClientHeight = 676
  ClientWidth = 840
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
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object panel4: TPanel
    Left = 0
    Top = 0
    Width = 840
    Height = 193
    Align = alTop
    BevelOuter = bvNone
    Caption = 'panel4'
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 56
      Width = 24
      Height = 13
      Caption = #32534#21495
    end
    object Label4: TLabel
      Left = 9
      Top = 144
      Width = 24
      Height = 13
      Caption = 'From'
    end
    object Label5: TLabel
      Left = 75
      Top = 144
      Width = 12
      Height = 13
      Caption = 'To'
    end
    object BitBtn1: TBitBtn
      Left = 132
      Top = 49
      Width = 32
      Height = 41
      Caption = '<<'
      TabOrder = 0
      OnClick = BitBtn1Click
    end
    object BitBtn2: TBitBtn
      Left = 794
      Top = 49
      Width = 30
      Height = 41
      Caption = '>>'
      TabOrder = 1
      OnClick = BitBtn2Click
    end
    object Panel3: TPanel
      Left = 178
      Top = 17
      Width = 604
      Height = 104
      BevelInner = bvLowered
      BevelOuter = bvLowered
      Color = clWhite
      ParentBackground = False
      TabOrder = 2
      object Image1: TImage
        Left = 2
        Top = 2
        Width = 600
        Height = 100
        Align = alClient
        OnClick = Image1Click
        OnMouseLeave = Image1MouseLeave
        OnMouseMove = Image1MouseMove
        ExplicitLeft = 10
        ExplicitTop = 0
      end
    end
    object Button1: TButton
      Left = 17
      Top = 17
      Width = 89
      Height = 33
      Caption = #25171#24320#25991#20214
      TabOrder = 3
      OnClick = Button1Click
    end
    object SpinEdit1: TSpinEdit
      Left = 17
      Top = 75
      Width = 89
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 4
      Value = 0
      OnChange = SpinEdit1Change
    end
    object Edit1: TEdit
      Left = 39
      Top = 141
      Width = 30
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 5
      Text = '0'
    end
    object Edit2: TEdit
      Left = 93
      Top = 141
      Width = 33
      Height = 21
      ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
      TabOrder = 6
      Text = '0'
    end
    object Button10: TButton
      Left = 17
      Top = 168
      Width = 88
      Height = 25
      Caption = #25209#37327#35774#32622#20559#31227
      TabOrder = 7
      OnClick = Button10Click
    end
    object Button11: TButton
      Left = 17
      Top = 110
      Width = 88
      Height = 25
      Caption = #36873#25321#20840#37096
      TabOrder = 8
      OnClick = Button11Click
    end
    object Panel5: TPanel
      Left = 180
      Top = 134
      Width = 600
      Height = 34
      BevelOuter = bvLowered
      Color = clWhite
      ParentBackground = False
      TabOrder = 9
      object ProgressBar1: TProgressBar
        Left = 1
        Top = 1
        Width = 598
        Height = 32
        Align = alClient
        TabOrder = 0
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 193
    Width = 121
    Height = 483
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    object Label2: TLabel
      Left = 16
      Top = 6
      Width = 30
      Height = 13
      Caption = 'x'#20559#31227
    end
    object Label3: TLabel
      Left = 16
      Top = 53
      Width = 30
      Height = 13
      Caption = 'y'#20559#31227
    end
    object SpeedButton1: TSpeedButton
      Left = 16
      Top = 377
      Width = 65
      Height = 25
      AllowAllUp = True
      GroupIndex = 1
      Caption = #36873#25321#20559#31227#28857
    end
    object SpeedButton2: TSpeedButton
      Left = 17
      Top = 408
      Width = 65
      Height = 25
      AllowAllUp = True
      GroupIndex = 1
      Caption = #36873#25321#36879#26126#33394
    end
    object Image4: TImage
      Left = 93
      Top = 408
      Width = 25
      Height = 25
    end
    object SpinEdit2: TSpinEdit
      Left = 16
      Top = 25
      Width = 89
      Height = 22
      MaxValue = 10000
      MinValue = -10000
      TabOrder = 0
      Value = 0
      OnChange = SpinEdit2Change
    end
    object SpinEdit3: TSpinEdit
      Left = 16
      Top = 72
      Width = 89
      Height = 22
      MaxValue = 10000
      MinValue = -10000
      TabOrder = 1
      Value = 0
      OnChange = SpinEdit3Change
    end
    object CheckBox1: TCheckBox
      Left = 26
      Top = 100
      Width = 89
      Height = 17
      Caption = #40657#33394#32972#26223
      TabOrder = 2
      OnClick = CheckBox1Click
    end
    object Button2: TButton
      Left = 16
      Top = 123
      Width = 89
      Height = 25
      Caption = #22797#21046#21040#21098#20999#26495
      TabOrder = 3
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 16
      Top = 154
      Width = 89
      Height = 25
      Caption = #20174#21098#20999#26495#22797#21046
      TabOrder = 4
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 16
      Top = 185
      Width = 89
      Height = 24
      Caption = #25554#20837#22270#29255
      TabOrder = 5
      OnClick = Button4Click
    end
    object Button5: TButton
      Left = 16
      Top = 216
      Width = 89
      Height = 25
      Caption = #28155#21152#22270#29255#21040#26368#21518
      TabOrder = 6
      OnClick = Button5Click
    end
    object Button6: TButton
      Left = 16
      Top = 248
      Width = 89
      Height = 25
      Caption = #21024#38500#24403#21069
      TabOrder = 7
      OnClick = Button6Click
    end
    object Button7: TButton
      Left = 16
      Top = 280
      Width = 89
      Height = 25
      Caption = #24403#21069#22270#21478#23384#20026
      TabOrder = 8
      OnClick = Button7Click
    end
    object Button8: TButton
      Left = 16
      Top = 312
      Width = 89
      Height = 25
      Caption = #20840#37096#23548#20986
      TabOrder = 9
      OnClick = Button8Click
    end
    object Button9: TButton
      Left = 16
      Top = 346
      Width = 89
      Height = 25
      Caption = #20445#23384#25991#20214
      TabOrder = 10
      OnClick = Button9Click
    end
  end
  object Panel2: TPanel
    Left = 121
    Top = 193
    Width = 719
    Height = 483
    Align = alClient
    BevelOuter = bvLowered
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object ScrollBox1: TScrollBox
      Left = 1
      Top = 1
      Width = 717
      Height = 481
      Align = alClient
      TabOrder = 0
      object Image2: TImage
        Left = 0
        Top = 0
        Width = 713
        Height = 477
        Align = alClient
        OnMouseDown = Image2MouseDown
        OnMouseMove = Image2MouseMove
        ExplicitTop = -3
      end
    end
  end
  object OpenDialog1: TOpenDialog
    FilterIndex = 0
    Left = 128
  end
  object SaveDialog1: TSaveDialog
    Left = 72
  end
end
