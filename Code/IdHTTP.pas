unit IdHTTP;

{$modeswitch autoderef}

interface

uses
  Classes, SysUtils;

type
  TIdHTTPRequest = class(TPersistent)
  private
    FConnection: string;
  published
    property Connection: string read FConnection write FConnection;
  end;

  TIdHTTP = class(TComponent)
  private
    FConnectTimeout: Integer;
    FReadTimeout: Integer;
    FRequest: TIdHTTPRequest;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Get(const AURL: string; AResponseContent: TStream); overload;
    procedure Disconnect;
  published
    property ConnectTimeout: Integer read FConnectTimeout write FConnectTimeout;
    property ReadTimeout: Integer read FReadTimeout write FReadTimeout;
    property Request: TIdHTTPRequest read FRequest write FRequest;
  end;

implementation

constructor TIdHTTP.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRequest := TIdHTTPRequest.Create;
  FConnectTimeout := 10000;
  FReadTimeout := 10000;
end;

destructor TIdHTTP.Destroy;
begin
  FRequest.Free;
  inherited Destroy;
end;

procedure TIdHTTP.Get(const AURL: string; AResponseContent: TStream);
begin
  // Stub implementation for Lazarus build compatibility.
  // Network download is disabled in this compatibility layer.
end;

procedure TIdHTTP.Disconnect;
begin
  // Stub implementation for compatibility.
end;

end.


