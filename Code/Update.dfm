object Form87: TForm87
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #19979#36733#26356#26032
  ClientHeight = 220
  ClientWidth = 528
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 13
  object Label1: TLabel
    Left = 24
    Top = 21
    Width = 288
    Height = 13
    Caption = #19979#36733#23436#25972#21387#32553#21253#30340#20445#23384#36335#24452#65292#21482#26377#19979#36733#21387#32553#21253#38656#35201#35774#32622
  end
  object Label2: TLabel
    Left = 32
    Top = 85
    Width = 48
    Height = 13
    Caption = #19979#36733#36827#24230
    Visible = False
  end
  object ProgressBar1: TProgressBar
    Left = 24
    Top = 104
    Width = 471
    Height = 26
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 0
  end
  object Edit1: TEdit
    Left = 24
    Top = 44
    Width = 372
    Height = 21
    TabStop = False
    ImeName = #20013#25991' ('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ReadOnly = True
    TabOrder = 2
  end
  object Button1: TButton
    Left = 318
    Top = 13
    Width = 80
    Height = 25
    Caption = #20445#23384#36335#24452
    TabOrder = 3
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 277
    Top = 153
    Width = 92
    Height = 32
    Caption = #19979#36733#23436#25972#21387#32553#21253
    TabOrder = 6
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 403
    Top = 153
    Width = 92
    Height = 32
    Caption = #20851#38381
    TabOrder = 7
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 24
    Top = 153
    Width = 92
    Height = 32
    Caption = #26356#26032#20027#31243#24207
    TabOrder = 4
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 414
    Top = 13
    Width = 81
    Height = 49
    Caption = #26816#26597#26356#26032
    TabOrder = 1
    OnClick = Button5Click
  end
  object Button6: TButton
    Left = 152
    Top = 153
    Width = 92
    Height = 32
    Caption = #26356#26032#20840#37096#25991#20214
    TabOrder = 5
    OnClick = Button6Click
  end
  object IdHTTP1: TIdHTTP
    OnWork = IdHTTP1Work
    OnWorkBegin = IdHTTP1WorkBegin
    OnWorkEnd = IdHTTP1WorkEnd
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
    Left = 488
    Top = 69
  end
end
