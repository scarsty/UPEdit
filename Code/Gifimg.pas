unit Gifimg;

{$modeswitch autoderef}

interface

uses
  Classes, Graphics, Types;

type
  TGifSubImage = class
  public
    procedure Draw(ACanvas: TCanvas; const ARect: TRect; Transparent, UsePalette: Boolean);
  end;

  TGifSubImages = class
  private
    FItem: TGifSubImage;
    function GetCount: Integer;
    function GetItem(Index: Integer): TGifSubImage;
  public
    constructor Create;
    destructor Destroy; override;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TGifSubImage read GetItem; default;
  end;

  TGifImage = class(TPersistent)
  private
    FWidth: Integer;
    FHeight: Integer;
    FDrawBackgroundColor: Cardinal;
    FBackgroundColor: TColor;
    FImages: TGifSubImages;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile(const FileName: string);
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property DrawBackgroundColor: Cardinal read FDrawBackgroundColor write FDrawBackgroundColor;
    property BackgroundColor: TColor read FBackgroundColor write FBackgroundColor;
    property Images: TGifSubImages read FImages;
  end;

implementation

procedure TGifSubImage.Draw(ACanvas: TCanvas; const ARect: TRect; Transparent, UsePalette: Boolean);
begin
  // Compatibility stub: no-op draw.
end;

constructor TGifSubImages.Create;
begin
  inherited Create;
  FItem := TGifSubImage.Create;
end;

destructor TGifSubImages.Destroy;
begin
  FItem.Free;
  inherited Destroy;
end;

function TGifSubImages.GetCount: Integer;
begin
  Result := 1;
end;

function TGifSubImages.GetItem(Index: Integer): TGifSubImage;
begin
  Result := FItem;
end;

constructor TGifImage.Create;
begin
  inherited Create;
  FImages := TGifSubImages.Create;
  FWidth := 0;
  FHeight := 0;
  FDrawBackgroundColor := clBlack;
  FBackgroundColor := clBlack;
end;

destructor TGifImage.Destroy;
begin
  FImages.Free;
  inherited Destroy;
end;

procedure TGifImage.LoadFromFile(const FileName: string);
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    try
      Bmp.LoadFromFile(FileName);
      FWidth := Bmp.Width;
      FHeight := Bmp.Height;
    except
      FWidth := 0;
      FHeight := 0;
    end;
  finally
    Bmp.Free;
  end;
end;

end.


