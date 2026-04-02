object ImzPNGeditForm: TImzPNGeditForm
  Left = 0
  Top = 0
  Margins.Left = 2
  Margins.Top = 2
  Margins.Right = 2
  Margins.Bottom = 2
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #22270#29255#32534#36753
  ClientHeight = 424
  ClientWidth = 644
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 644
    Height = 118
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 636
    object Label1: TLabel
      Left = 17
      Top = 17
      Width = 30
      Height = 13
      Caption = 'x'#20559#31227
    end
    object Label2: TLabel
      Left = 17
      Top = 70
      Width = 30
      Height = 13
      Caption = 'y'#20559#31227
    end
    object Panel4: TPanel
      Left = 171
      Top = 13
      Width = 423
      Height = 76
      BevelInner = bvLowered
      BevelOuter = bvLowered
      Color = clWhite
      ParentBackground = False
      TabOrder = 2
      object Image1: TImage
        Left = 2
        Top = 2
        Width = 419
        Height = 72
        Align = alClient
        OnMouseUp = Image1MouseUp
        ExplicitWidth = 420
      end
    end
    object Edit1: TEdit
      Left = 17
      Top = 41
      Width = 85
      Height = 21
      ImeName = #20013#25991' - QQ'#25340#38899#36755#20837#27861
      TabOrder = 0
      OnKeyPress = Edit1KeyPress
    end
    object Edit2: TEdit
      Left = 17
      Top = 90
      Width = 85
      Height = 21
      ImeName = #20013#25991' - QQ'#25340#38899#36755#20837#27861
      TabOrder = 1
      OnKeyPress = Edit2KeyPress
    end
    object Button3: TButton
      Left = 130
      Top = 38
      Width = 31
      Height = 27
      Caption = '<<'
      TabOrder = 3
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 602
      Top = 38
      Width = 31
      Height = 27
      Caption = '>>'
      TabOrder = 4
      OnClick = Button4Click
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 118
    Width = 126
    Height = 306
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitHeight = 281
    object Label3: TLabel
      Left = 17
      Top = 47
      Width = 36
      Height = 13
      Caption = #24403#21069#24103
    end
    object Button2: TButton
      Left = 17
      Top = 6
      Width = 85
      Height = 27
      Caption = #30830#35748#20559#31227
      TabOrder = 0
      OnClick = Button2Click
    end
    object SpinEdit1: TSpinEdit
      Left = 17
      Top = 71
      Width = 85
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 1
      Value = 0
      OnChange = SpinEdit1Change
    end
    object Button1: TButton
      Left = 17
      Top = 109
      Width = 85
      Height = 26
      Caption = #20445#23384
      TabOrder = 2
      OnClick = Button1Click
    end
    object Button5: TButton
      Left = 17
      Top = 174
      Width = 85
      Height = 26
      Caption = #25554#20837#24103
      TabOrder = 4
      OnClick = Button5Click
    end
    object Button6: TButton
      Left = 17
      Top = 206
      Width = 85
      Height = 26
      Caption = #28155#21152#24103#21040#26368#21518
      TabOrder = 5
      OnClick = Button6Click
    end
    object Button7: TButton
      Left = 17
      Top = 238
      Width = 85
      Height = 27
      Caption = #21024#38500#24403#21069#24103
      TabOrder = 6
      OnClick = Button7Click
    end
    object Button8: TButton
      Left = 17
      Top = 142
      Width = 85
      Height = 25
      Caption = #26367#25442#24403#21069#24103
      TabOrder = 3
      OnClick = Button8Click
    end
  end
  object Panel3: TPanel
    Left = 126
    Top = 118
    Width = 518
    Height = 306
    Align = alClient
    BevelOuter = bvLowered
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    ExplicitWidth = 510
    ExplicitHeight = 281
    object ScrollBox1: TScrollBox
      Left = 1
      Top = 1
      Width = 516
      Height = 304
      Align = alClient
      TabOrder = 0
      ExplicitWidth = 508
      ExplicitHeight = 279
      object Image2: TImage
        Left = 0
        Top = 0
        Width = 52
        Height = 52
        OnMouseDown = Image2MouseDown
      end
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 80
    Top = 8
  end
end
