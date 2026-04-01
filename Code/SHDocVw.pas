unit SHDocVw;

{$modeswitch autoderef}

interface

uses
  Classes, Controls, OleCtrls, ActiveX, Variants;

type
  TWebBrowser = class(TOleControl)
  private
    function GetDefaultInterface: IDispatch;
  public
    procedure Refresh;
    procedure Navigate(const URL: WideString);
    property DefaultInterface: IDispatch read GetDefaultInterface;
  end;

implementation

function TWebBrowser.GetDefaultInterface: IDispatch;
begin
  Result := nil;
end;

procedure TWebBrowser.Refresh;
begin
end;

procedure TWebBrowser.Navigate(const URL: WideString);
begin
end;

end.


