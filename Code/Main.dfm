object UPeditMainForm: TUPeditMainForm
  Left = 194
  Top = 111
  Margins.Left = 2
  Margins.Top = 2
  Margins.Right = 2
  Margins.Bottom = 2
  AlphaBlendValue = 1
  Caption = 'UPedit'
  ClientHeight = 667
  ClientWidth = 778
  Color = clBtnFace
  Constraints.MinHeight = 347
  Constraints.MinWidth = 496
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -19
  Font.Name = #24494#36719#38597#40657
  Font.Style = []
  FormStyle = fsMDIForm
  Menu = MainMenu1
  Position = poDefault
  WindowState = wsMaximized
  WindowMenu = Window1
  OnClose = FormClose
  OnCreate = FormCreate
  OnResize = FormResize
  TextHeight = 25
  object Panel1: TPanel
    Left = 0
    Top = 33
    Width = 778
    Height = 65
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alTop
    BevelEdges = []
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 0
    Visible = False
    ExplicitWidth = 776
    object Label2: TLabel
      Left = 111
      Top = 2
      Width = 485
      Height = 53
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
    end
    object Label1: TLabel
      Left = 40
      Top = 2
      Width = 43
      Height = 25
      Caption = #28040#24687':'
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 98
    Width = 248
    Height = 569
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alLeft
    BevelEdges = []
    BevelOuter = bvNone
    TabOrder = 1
    Visible = False
    ExplicitHeight = 561
    object WebBrowser1: TWebBrowser
      Left = 0
      Top = 23
      Width = 248
      Height = 546
      Align = alClient
      TabOrder = 0
      OnNewWindow2 = WebBrowser1NewWindow2
      ExplicitHeight = 538
      ControlData = {
        4C00000081140000252D00000000000000000000000000000000000000000000
        000000004C000000000000000000000001000000E0D057007335CF11AE690800
        2B2E12620A000000000000004C0000000114020000000000C000000000000046
        8000000000000000000000000000000000000000000000000000000000000000
        00000000000000000100000000000000000000000000000000000000}
    end
    object Button1: TButton
      Left = 0
      Top = 0
      Width = 248
      Height = 23
      Align = alTop
      Caption = #21047#26032
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -14
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = Button1Click
    end
  end
  object Panel3: TPanel
    Left = 251
    Top = 246
    Width = 266
    Height = 72
    Caption = #38544#34255#30340'webbrowser'
    TabOrder = 2
    Visible = False
    object WebBrowser2: TWebBrowser
      Left = 3
      Top = 2
      Width = 60
      Height = 75
      TabOrder = 0
      OnBeforeNavigate2 = WebBrowser2BeforeNavigate2
      ControlData = {
        4C000000F6040000340600000000000000000000000000000000000000000000
        000000004C000000000000000000000001000000E0D057007335CF11AE690800
        2B2E12620A000000000000004C0000000114020000000000C000000000000046
        8000000000000000000000000000000000000000000000000000000000000000
        00000000000000000100000000000000000000000000000000000000}
    end
  end
  object Panel4: TPanel
    Left = 0
    Top = 0
    Width = 778
    Height = 33
    Align = alTop
    TabOrder = 3
    ExplicitWidth = 776
    object Label3: TLabel
      Left = 25
      Top = 3
      Width = 80
      Height = 21
      Caption = #24555#25463#21151#33021#65306
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
    end
    object Label4: TLabel
      Left = 117
      Top = 3
      Width = 80
      Height = 21
      Cursor = crHandPoint
      Caption = #25105#35201#25913#23384#26723
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
      OnClick = Label4Click
      OnMouseEnter = Label4MouseEnter
      OnMouseLeave = Label4MouseLeave
    end
    object Label5: TLabel
      Left = 228
      Top = 3
      Width = 80
      Height = 21
      Cursor = crHandPoint
      Caption = #25105#35201#25913#22270#29255
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
      OnClick = Label5Click
      OnMouseEnter = Label5MouseEnter
      OnMouseLeave = Label5MouseLeave
    end
    object Label6: TLabel
      Left = 339
      Top = 3
      Width = 80
      Height = 21
      Cursor = crHandPoint
      Caption = #25105#35201#25913#22330#26223
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
      OnClick = Label6Click
      OnMouseEnter = Label6MouseEnter
      OnMouseLeave = Label6MouseLeave
    end
    object Label7: TLabel
      Left = 455
      Top = 3
      Width = 80
      Height = 21
      Cursor = crHandPoint
      Caption = #25105#35201#25913#20107#20214
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      ParentFont = False
      OnClick = Label7Click
      OnMouseEnter = Label7MouseEnter
      OnMouseLeave = Label7MouseLeave
    end
  end
  object MainMenu1: TMainMenu
    Left = 128
    Top = 104
    object File1: TMenuItem
      Caption = #31243#24207
      Hint = 'File related commands'
      object N2: TMenuItem
        Caption = #35774#32622#28216#25103#36335#24452
        OnClick = N2Click
      end
      object N5: TMenuItem
        Caption = #35774#32622#32534#36753#22120#37197#32622
        OnClick = N5Click
      end
      object N33: TMenuItem
        Caption = #35774#32622#25991#20214#20851#32852
        OnClick = N33Click
      end
      object N20: TMenuItem
        Caption = #26174#31034#20844#21578#26639
        Checked = True
        OnClick = N20Click
      end
      object N21: TMenuItem
        Caption = #26174#31034#20391#36793#26639
        Checked = True
        OnClick = N21Click
      end
      object FileExitItem: TMenuItem
        Caption = #36864#20986
        Hint = 'Exit|Exit application'
        OnClick = FileExit1Execute
      end
    end
    object N3: TMenuItem
      Caption = #25968#25454#32534#36753
      object R1: TMenuItem
        Caption = 'R'#25991#20214#32534#36753
        OnClick = R1Click
      end
      object N4: TMenuItem
        Caption = #20107#20214#32534#36753
        OnClick = N4Click
      end
      object N9: TMenuItem
        Caption = #25112#26007#25968#25454#32534#36753
        OnClick = N9Click
      end
      object N17: TMenuItem
        Caption = #22797#21051#21015#34920#25991#20214#32534#36753
        OnClick = N17Click
      end
      object N31: TMenuItem
        Caption = #21095#26412#23548#20837
        OnClick = N31Click
      end
    end
    object form1: TMenuItem
      Caption = #36148#22270#22788#29702
      object N1: TMenuItem
        Caption = #22270#29255#23548#20837'GRP'
        OnClick = N1Click
      end
      object grp1: TMenuItem
        Caption = 'Grp'#36148#22270#26597#30475
        OnClick = grp1Click
      end
      object PNG1: TMenuItem
        Caption = 'PNG'#25209#37327#23548#20837
        OnClick = PNG1Click
      end
      object IMZ1: TMenuItem
        Caption = 'IMZ'#32534#36753
        OnClick = IMZ1Click
      end
    end
    object N7: TMenuItem
      Caption = #22320#22270#32534#36753
      object N11: TMenuItem
        Caption = #25112#26007#22320#22270#32534#36753
        OnClick = N11Click
      end
      object N13: TMenuItem
        Caption = #22330#26223#22320#22270#32534#36753
        OnClick = N13Click
      end
      object N15: TMenuItem
        Caption = #20027#22320#22270#32534#36753
        OnClick = N15Click
      end
    end
    object MOD1: TMenuItem
      Caption = #20854#20182'MOD'#19987#29992#21151#33021
      object N22: TMenuItem
        Caption = #33485#28814#22836#20687#32534#36753
        OnClick = N22Click
      end
      object pic1: TMenuItem
        Caption = #21069#20256'Pic'#22270#29255#32534#36753
        OnClick = pic1Click
      end
    end
    object Window1: TMenuItem
      Caption = #31383#21475
      Hint = 'Window related commands'
      object N6: TMenuItem
        Caption = '-'
        Enabled = False
      end
    end
    object Help1: TMenuItem
      Caption = #24110#21161
      Hint = 'Help topics'
      object bug2: TMenuItem
        Caption = #24847#35265#24314#35758#21450'bug'#25552#20132
        OnClick = bug2Click
      end
      object N19: TMenuItem
        Caption = #33258#21160#26356#26032
        OnClick = N19Click
      end
      object HelpAboutItem: TMenuItem
        Caption = #20851#20110'...'
        Hint = 
          'About|Displays program information, version number, and copyrigh' +
          't'
        OnClick = HelpAbout1Execute
      end
    end
  end
  object IdHTTP1: TIdHTTP
    RedirectMaximum = 30
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = -1
    Request.ContentRangeStart = -1
    Request.ContentRangeInstanceLength = -1
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    Request.Ranges.Units = 'bytes'
    Request.Ranges = <>
    HTTPOptions = [hoForceEncodeParams]
    Left = 32
    Top = 96
  end
  object TrayIcon1: TTrayIcon
    Animate = True
    PopupMenu = PopupMenu1
    Visible = True
    OnClick = TrayIcon1Click
    OnDblClick = TrayIcon1DblClick
    Left = 32
    Top = 160
  end
  object PopupMenu1: TPopupMenu
    Left = 24
    Top = 232
    object N25: TMenuItem
      Caption = #21319#32423#26356#26032
      OnClick = N25Click
    end
    object bug1: TMenuItem
      Caption = #24847#35265#24314#35758#21450'bug'#25552#20132
      OnClick = bug1Click
    end
    object N26: TMenuItem
      Caption = '-'
      Enabled = False
    end
    object N28: TMenuItem
      Caption = #35774#32622#28216#25103#36335#24452
      OnClick = N28Click
    end
    object N29: TMenuItem
      Caption = #35774#32622#32534#36753#22120#23646#24615
      OnClick = N29Click
    end
    object N34: TMenuItem
      Caption = #35774#32622#25991#20214#20851#32852
      OnClick = N34Click
    end
    object N27: TMenuItem
      Caption = '-'
      Enabled = False
    end
    object N30: TMenuItem
      Caption = #20851#20110'...'
      OnClick = N30Click
    end
    object N24: TMenuItem
      Caption = #36864#20986
      OnClick = N24Click
    end
  end
  object IdAntiFreeze1: TIdAntiFreeze
    IdleTimeOut = 50
    Left = 120
    Top = 176
  end
end
