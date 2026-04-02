unit ImzObject;

interface

uses
  Sysutils, Windows, Head, inifiles, Graphics, PNGimage, Classes, dialogs, libzip;

Type
  TImzFile = Class
    imzFile: Timz;
    indexFile: String;
    function SaveImzToFile(Fname: string): Boolean; overload;
    function SaveImzToFile(tempimz: Pimz; Fname: string): Boolean; overload;
    function ReadImzFromFile(Fname: string): boolean;  overload;
    function ReadImzFromFolder(path: string): boolean; overload;
    function ReadImzFromFile(tempimz: pimz; Fname: string): boolean;  overload;
    function ReadImzFromFolder(tempimz: pimz; path: string): boolean; overload;
    procedure DrawImzPNGtoBitmap(Bmp: Pntbitmap; imzPNG: PimzPNG; count, x, y: integer);
    procedure DrawImzPNGtoCanvas(Acanvas: TCanvas; imzPNG: PimzPNG; count, x, y: integer);
    procedure DrawImztoBitmap(Bmp: Pntbitmap; imz: Pimz; PNGcount, count, x, y: integer);
    procedure DrawImztoCanvas(Acanvas: TCanvas; imz: Pimz; PNGcount, count, x, y: integer);
    //带ex的函数是有偏移的
    procedure DrawImzPNGtoBitmapEx(Bmp: Pntbitmap; imzPNG: PimzPNG; count, x, y: integer);
    procedure DrawImzPNGtoCanvasEx(Acanvas: TCanvas; imzPNG: PimzPNG; count, x, y: integer);
    procedure DrawImztoBitmapEx(Bmp: Pntbitmap; imz: Pimz; PNGcount, count, x, y: integer);
    procedure DrawImztoCanvasEx(Acanvas: TCanvas; imz: Pimz; PNGcount, count, x, y: integer);

    procedure SceneQuickDraw(Bmp: Pntbitmap; PNGcount, x, y: integer);
    procedure SceneQuickDrawCanvas(ACanvas: TCanvas; PNGcount, x, y: integer);
    procedure SceneQuickDrawBuf(Buf: PScenePNGBuf; PNGcount, x, y: integer);
    procedure ReadAllPNG;
    procedure ReleaseAllPNG;
  private
    PNGready: boolean;
  public
    property isPNGready: boolean read PNGready;
  private
    procedure CalImzLen(tempimz: Pimz);
  end;

  PImzFile = ^TImzFile;

const
  imzindexfilename = 'index.ka';

implementation

procedure TImzFile.ReadAllPNG;
var
  I, I2, I3, FH: integer;
  temprs: TmemoryStream;
  tempPNG: TPNGobject;
  tempBMP: Tbitmap;
begin
  for I := 0 to imzFile.PNGnum - 1 do
  begin
    if imzFile.imzPNG[I].frame > 0 then
    begin
      setlength(imzFile.imzPNG[I].PNG, imzFile.imzPNG[I].frame);
      for I2 := 0 to imzFile.imzPNG[I].frame - 1 do
      begin

        try
          try
            tempPNG := TPNGobject.Create;
            temprs := TmemoryStream.Create;
            tempBMP := Tbitmap.Create;
            temprs.SetSize(imzFile.imzPNG[I].framelen[I2]);
            temprs.Position := 0;
            temprs.Write(imzFile.imzPNG[I].framedata[I2].data[0], imzFile.imzPNG[I].framelen[I2]);
            temprs.Position := 0;
            tempPNG.LoadFromStream(temprs);
            if tempPNG.Width * tempPNG.Height > 0 then
            begin
              tempBMP.PixelFormat := pf32bit;
              tempbmp.Width := tempPNG.Width;
              tempbmp.Height := tempPNG.Height;
              imzFile.imzPNG[I].PNG[I2].width := tempPNG.Width;
              imzFile.imzPNG[I].PNG[I2].Height := tempPNG.Height;
              tempPNG.Draw(tempbmp.Canvas, tempbmp.Canvas.ClipRect);
              setlength(imzFile.imzPNG[I].PNG[I2].data, tempbmp.Height, tempbmp.Width * 4);
              setlength(imzFile.imzPNG[I].PNG[I2].alpha, tempbmp.Height, tempbmp.Width);

              for I3 := 0 to tempbmp.Height - 1 do
              begin
                copymemory(@imzFile.imzPNG[I].PNG[I2].data[I3][0], tempbmp.ScanLine[I3], tempbmp.Width * 4);
                copymemory(@imzFile.imzPNG[I].PNG[I2].alpha[I3][0], tempPNG.AlphaScanline[I3], tempbmp.Width);
              end;
            end
            else
            begin
              imzFile.imzPNG[I].PNG[I2].width := 0;
              imzFile.imzPNG[I].PNG[I2].Height := 0;
              setlength(imzFile.imzPNG[I].PNG[I2].data, 0, 0);
              setlength(imzFile.imzPNG[I].PNG[I2].alpha, 0, 0);

            end;
          except
            imzFile.imzPNG[I].PNG[I2].width := 0;
            imzFile.imzPNG[I].PNG[I2].Height := 0;
            setlength(imzFile.imzPNG[I].PNG[I2].data, 0, 0);
            setlength(imzFile.imzPNG[I].PNG[I2].alpha, 0, 0);
          end;
        finally
          Temprs.Free;
          tempPNG.Destroy;
          tempbMP.Free;
        end;
      end;
    end;
  end;
  PNGready := true;
end;

procedure TImzFile.ReleaseAllPNG;
var
  I, I2: integer;
begin
  if not PNGready then
    exit;
  for I := 0 to imzFile.PNGnum - 1 do
  begin
    if imzFile.imzPNG[I].frame > 0 then
    begin
      for I2 := 0 to imzFile.imzPNG[I].frame - 1 do
      begin
          try
            imzFile.imzPNG[I].PNG[I2].width := 0;
            imzFile.imzPNG[I].PNG[I2].height := 0;
            setlength(imzFile.imzPNG[I].PNG[I2].data, 0, 0);
            setlength(imzFile.imzPNG[I].PNG[I2].alpha, 0, 0);
          except

          end;
      end;
    end;
  end;
  PNGready := false;;
end;

procedure TImzFile.SceneQuickDrawCanvas(ACanvas: TCanvas; PNGcount, x, y: integer);
begin
  DrawImztoCanvasEx(ACanvas, @imzFile, PNGcount, 0, x, y);
end;

procedure TImzFile.SceneQuickDraw(Bmp: Pntbitmap; PNGcount, x, y: integer);
begin
  DrawImztoBitmapEx(Bmp, @imzFile, PNGcount, 0, x, y);
end;

procedure TImzFile.DrawImztoBitmapEx(Bmp: Pntbitmap; imz: Pimz; PNGcount, count, x, y: integer);
begin
  //
  DrawImztoCanvasEx(Bmp.Canvas, imz, PNGcount, count, x, y);
end;

procedure TImzFile.DrawImztoCanvasEx(Acanvas: TCanvas; imz: Pimz; PNGcount, count, x, y: integer);
begin
  //
  if (imz.PNGnum <= 0) or (PNGcount < 0) or (PNGcount >= imz.PNGnum) then
    exit;
  DrawImzPNGtoCanvasEx(Acanvas, @imz.imzPNG[PNGcount], count, x, y);
end;

procedure TImzFile.DrawImzPNGtoBitmapEx(Bmp: Pntbitmap; imzPNG: PimzPNG; count, x, y: integer);
begin
  DrawImzPNGtoCanvasEx(Bmp.Canvas, imzPNG, count, x, y);
end;

procedure TImzFile.DrawImzPNGtoCanvasEx(Acanvas: TCanvas; imzPNG: PimzPNG; count, x, y: integer);
var
  temprs: Tmemorystream;
  PNG: TPNGObject;
begin
  //
  if (imzPNG.frame <= 0) or (count < 0) or (count >= imzPNG.frame) then
    exit;

  try
    //Acanvas.Lock;
    temprs := Tmemorystream.Create;
    PNG := TPNGobject.Create;
    temprs.SetSize(imzPNG.framelen[count]);
    temprs.Position := 0;
    temprs.Write(imzPNG.framedata[Count].data[0], imzPNG.framelen[count]);
    temprs.Position := 0;
    PNG.LoadFromStream(temprs);
    x := x - imzPNG.x;
    y := y - imzPNG.y;
    PNG.Draw(ACanvas, Rect(x, y, x + PNG.Width, y + PNG.Height));
  finally
    PNG.Destroy;
    temprs.Free;
    //Acanvas.UnLock;
  end;
end;

procedure TImzFile.SceneQuickDrawBuf(Buf: PScenePNGBuf; PNGcount, x, y: integer);
var
  I, I2: integer;
begin

  if (imzFile.PNGnum <= 0) or (PNGcount < 0) or (PNGcount >= imzFile.PNGnum) then
    exit;
  if imzFile.imzPNG[PNGcount].frame <= 0 then
    exit;
  x := x - imzFile.imzPNG[PNGcount].x;
  y := y - imzFile.imzPNG[PNGcount].y;
  if imzFile.imzPNG[PNGcount].PNG[0].width * imzFile.imzPNG[PNGcount].PNG[0].height > 0 then
  begin
    for I := 0 to imzFile.imzPNG[PNGcount].PNG[0].height - 1 do
    begin
      for I2 := 0 to imzFile.imzPNG[PNGcount].PNG[0].width - 1 do
      begin
        if (I + y >= 0) and (I + y < buf.height) and (I2 + x >= 0) and (I2 + x < buf.width) then
        begin
          if imzFile.imzPNG[PNGcount].PNG[0].alpha[I][I2] = 255 then
          begin
            Pcardinal(@buf.data[I + y][4 * (I2 + x)])^ := Pcardinal(@imzFile.imzPNG[PNGcount].PNG[0].data[I][I2 * 4])^;
          end
          else //if imzFile.imzPNG[PNGcount].PNG[0].alpha[I][I2] <> 0 then
          begin
            //buf.data[I + y][I2 + x] := (imzFile.imzPNG[PNGcount].PNG[0].data[I][I2 * 4] * imzFile.imzPNG[PNGcount].PNG[0].alpha[I][I2] + buf.data[I + y][I2 + x] * (255 - imzFile.imzPNG[PNGcount].PNG[0].alpha[I][I2])) div 255;
            //buf.data[I + y][4 *(I2 + x)] := $FF;
            buf.data[I + y][4 *(I2 + x) + 1] := (imzFile.imzPNG[PNGcount].PNG[0].data[I][I2 * 4 + 1] * imzFile.imzPNG[PNGcount].PNG[0].alpha[I][I2] + buf.data[I + y][4 * (I2 + x) + 1] * (255 - imzFile.imzPNG[PNGcount].PNG[0].alpha[I][I2])) div 255;
            buf.data[I + y][4 *(I2 + x) + 2] := (imzFile.imzPNG[PNGcount].PNG[0].data[I][I2 * 4 + 2] * imzFile.imzPNG[PNGcount].PNG[0].alpha[I][I2] + buf.data[I + y][4 * (I2 + x) + 2] * (255 - imzFile.imzPNG[PNGcount].PNG[0].alpha[I][I2])) div 255;
            buf.data[I + y][4 *(I2 + x)] := (imzFile.imzPNG[PNGcount].PNG[0].data[I][I2 * 4] * imzFile.imzPNG[PNGcount].PNG[0].alpha[I][I2] + buf.data[I + y][4 * (I2 + x)] * (255 - imzFile.imzPNG[PNGcount].PNG[0].alpha[I][I2])) div 255;
          end;
        end;
      end;
    end;
  end;
end;

procedure TImzFile.DrawImztoBitmap(Bmp: Pntbitmap; imz: Pimz; PNGcount, count, x, y: integer);
begin
  //
  DrawImztoCanvas(Bmp.Canvas, imz, PNGcount, count, x, y);
end;

procedure TImzFile.DrawImztoCanvas(Acanvas: TCanvas; imz: Pimz; PNGcount, count, x, y: integer);
begin
  //
  if (imz.PNGnum <= 0) or (PNGcount < 0) or (PNGcount >= imz.PNGnum) then
    exit;
  DrawImzPNGtoCanvas(Acanvas, @imz.imzPNG[PNGcount], count, x, y);
end;

procedure TImzFile.DrawImzPNGtoBitmap(Bmp: Pntbitmap; imzPNG: PimzPNG; count, x, y: integer);
begin
  DrawImzPNGtoCanvas(Bmp.Canvas, imzPNG, count, x, y);
end;

procedure TImzFile.DrawImzPNGtoCanvas(Acanvas: TCanvas; imzPNG: PimzPNG; count, x, y: integer);
var
  temprs: Tmemorystream;
  PNG: TPNGObject;
begin
  //
  if (imzPNG.frame <= 0) or (count < 0) or (count >= imzPNG.frame) then
    exit;

  try
    //Acanvas.Lock;
    temprs := Tmemorystream.Create;
    PNG := TPNGobject.Create;
    temprs.SetSize(imzPNG.framelen[count]);
    temprs.Position := 0;
    temprs.Write(imzPNG.framedata[Count].data[0], imzPNG.framelen[count]);
    temprs.Position := 0;
    PNG.LoadFromStream(temprs);
    PNG.Draw(ACanvas, Rect(x, y, x + PNG.Width, y + PNG.Height));
  finally
    PNG.Destroy;
    temprs.Free;
    //Acanvas.UnLock;
  end;
end;

procedure TImzFile.CalImzLen(tempimz: Pimz);
var
  I, I2, tempint: integer;
begin
  //
  for I := 0 to tempimz.PNGnum - 1 do
  begin
    tempimz.imzPNG[I].len := 2 * 2 + 4 + tempimz.imzPNG[I].frame * 2 * 4;
    for I2 := 0 to tempimz.imzPNG[I].frame - 1 do
    begin
      tempimz.imzPNG[I].len := tempimz.imzPNG[I].len + tempimz.imzPNG[I].framelen[I2];
    end;
  end;
end;

function TImzFile.SaveImzToFile(Fname: string): Boolean;
begin
  result := SaveImzToFile(@(Self.imzFile), Fname);
end;

function TImzFile.SaveImzToFile(tempimz: Pimz; Fname: string): Boolean;
var
  FH, I, I2, pos: integer;
  offset: array of integer;
  frameoffset: array of integer;
begin
  //
  try
    CalImzLen(tempimz);
    FH := Filecreate(Fname, fmopenreadwrite);
    filewrite(FH, tempimz.PNGnum, 4);
    setlength(offset, tempimz.PNGnum);
    if tempimz.PNGnum > 0 then
    begin
      offset[0] := 4 + tempimz.PNGnum * 4;
      for I := 1 to tempimz.PNGnum - 1 do
      begin
        offset[I] := Offset[I - 1] + tempimz.imzPNG[I - 1].len;
      end;
      filewrite(FH, offset[0], tempimz.PNGnum * 4);
      pos := 4 + tempimz.PNGnum * 4;
      for I := 0 to tempimz.PNGnum - 1 do
      begin
        filewrite(FH, tempimz.imzPNG[I].x, 2);
        filewrite(FH, tempimz.imzPNG[I].y, 2);
        filewrite(FH, tempimz.imzPNG[I].frame, 4);
        inc(pos, 8);
        setlength(frameoffset, tempimz.imzPNG[I].frame);
        if tempimz.imzPNG[I].frame > 0 then
        begin
          pos := pos + tempimz.imzPNG[I].frame * 2 * 4;
          frameoffset[0] := pos;
          for I2 := 1 to tempimz.imzPNG[I].frame - 1 do
          begin
            frameoffset[I2] := frameoffset[I2 - 1] + tempimz.imzPNG[I].framelen[I2 - 1];
          end;
          for I2 := 0 to tempimz.imzPNG[I].frame - 1 do
          begin
            filewrite(FH, frameoffset[I2], 4);
            filewrite(FH, tempimz.imzPNG[I].framelen[I2], 4);
          end;
          for I2 := 0 to tempimz.imzPNG[I].frame - 1 do
          begin
            filewrite(FH, tempimz.imzPNG[I].framedata[I2].data[0], tempimz.imzPNG[I].framelen[I2]);
            inc(pos, tempimz.imzPNG[I].framelen[I2]);
          end;
        end;
      end;
      fileclose(FH);
    end
    else
      fileclose(FH);
    result := true;
  except
    result := false;
 end;
end;

function TImzFile.ReadImzFromFile(Fname: string): boolean;
begin
  Result := ReadImzFromFile(@(self.imzFile), Fname);
end;

function TImzFile.ReadImzFromFolder(path: string): boolean;
begin
  Result := ReadImzFromFolder(@(Self.imzFile), path);
end;

function TImzFile.ReadImzFromFile(tempimz: pimz; Fname: string): boolean;
var
  FH, I, I2: integer;
  offset, frameoffset: array of integer;
  zip: pzip_t;
  INI: Tinifile;
  str: ansistring;
  fnameu8:utf8string;
begin
  //
  if PNGready then
    ReleaseAllPNG;
  PNGready := false;

  if fname.EndsWith('.zip') then
  begin
  try
      ini := Tinifile.Create(StartPath + iniFileName);
      indexfile := imzindexfilename;
      indexfile := ini.ReadString('File', 'ImzIndexFileName', indexFile);
    finally
      ini.Free;
    end;
    fnameu8:=fname;
    zip:= zip_open(@fnameu8[1]);

    str:=zip_express(zip, indexfile);
    tempimz.PNGnum := length(str) shr 2;
      setlength(tempimz.imzPNG, tempimz.PNGnum);
      for I := 0 to tempimz.PNGnum - 1 do
      begin
        tempimz.imzPNG[I].x := psmallint(@str[1+i*4])^;
        tempimz.imzPNG[I].y := psmallint(@str[3+i*4])^;
      end;

      for I := 0 to tempimz.PNGnum - 1 do
    begin
      tempimz.imzPNG[I].frame := 0;
      if zip_has_file(zip, inttostr(I) + '.png') then
      begin
        tempimz.imzPNG[I].frame := 1;
        setlength(tempImz.imzPNG[I].framelen, tempimz.imzPNG[I].frame);
        setlength(tempImz.imzPNG[I].framedata, tempimz.imzPNG[I].frame);
        try
          str := zip_express(zip, inttostr(I) + '.png');
          tempImz.imzPNG[I].framelen[0] := length(str);
          setlength(tempImz.imzPNG[I].framedata[0].data, tempImz.imzPNG[I].framelen[0]);
          move(str[1], tempImz.imzPNG[I].framedata[0].data[0], tempImz.imzPNG[I].framelen[0]);
        finally

        end;
      end
      else
      begin
        i2 := 0;
        while (zip_has_file(zip, inttostr(I) + '_' + inttostr(i2) + '.png')) do
          inc(i2);
        tempimz.imzPNG[I].frame := i2;
        setlength(tempImz.imzPNG[I].framelen, tempimz.imzPNG[I].frame);
        setlength(tempImz.imzPNG[I].framedata, tempimz.imzPNG[I].frame);
        for I2 := 0 to tempimz.imzPNG[I].frame - 1 do
        begin
          try
            str := zip_express(zip,  inttostr(I) + '_' + inttostr(i2) + '.png');
            tempImz.imzPNG[I].framelen[I2] := length(str);
            setlength(tempImz.imzPNG[I].framedata[I2].data, tempImz.imzPNG[I].framelen[I2]);
            move(str[1], tempImz.imzPNG[I].framedata[I2].data[0], tempImz.imzPNG[I].framelen[I2]);
          finally

          end;
        end;
      end;
    end;

    CalImzLen(tempimz);
    result := true;

    zip_close(zip);
    exit;
  end;


  try
    FH := Fileopen(Fname, fmopenread);
    fileread(FH, tempimz.PNGnum, 4);
    if tempimz.PNGnum < 0 then
      tempimz.PNGnum := 0;
    if tempimz.PNGnum > 0 then
    begin
      setlength(Offset, tempimz.PNGnum);
      fileread(FH, offset[0], tempimz.PNGnum * 4);
      setlength(tempimz.imzPNG, tempimz.PNGnum);
      for I := 0 to tempimz.PNGnum - 1 do
      begin
        fileseek(FH, offset[I], 0);
        fileread(FH, tempimz.imzPNG[I].x, 2);
        fileread(FH, tempimz.imzPNG[I].y, 2);
        fileread(FH, tempimz.imzPNG[I].frame, 4);
        if tempimz.imzPNG[I].frame > 0 then
        begin
          setlength(tempimz.imzPNG[I].framedata, tempimz.imzPNG[I].frame);
          setlength(tempimz.imzPNG[I].framelen, tempimz.imzPNG[I].frame);
          setlength(frameoffset, tempimz.imzPNG[I].frame);
        end;
        for I2 := 0 to tempimz.imzPNG[I].frame - 1 do
        begin
          fileread(FH, frameoffset[I2], 4);
          fileread(FH, tempimz.imzPNG[I].framelen[I2], 4);
        end;
        for I2 := 0 to tempimz.imzPNG[I].frame - 1 do
        begin
          setlength(tempimz.imzPNG[I].framedata[I2].data, tempimz.imzPNG[I].framelen[I2]);
          fileseek(FH, frameoffset[I2], 0);
          fileread(FH, tempimz.imzPNG[I].framedata[I2].data[0], tempimz.imzPNG[I].framelen[I2]);
        end;
      end;
    end;
    fileclose(FH);
    CalImzLen(tempimz);
    result := true;
  except
    fileclose(FH);
    tempimz.PNGnum := 0;
    setlength(tempimz.imzPNG, tempimz.PNGnum);
    result := false;
  end;

end;

function TImzFile.ReadImzFromFolder(tempimz: pimz; path: string): boolean;
var
  FH, I, I2: integer;
  INI: Tinifile;
begin
  //
  if PNGready then
    ReleaseAllPNG;
  PNGready := false;
  try
    try
      ini := Tinifile.Create(StartPath + iniFileName);
      indexfile := imzindexfilename;
      indexfile := ini.ReadString('File', 'ImzIndexFileName', indexFile);
    finally
      ini.Free;
    end;

    if path[length(path)] <> '\' then
      path := path + '\';

    try
      if not fileexists(path + indexfile) then
      begin
        tempimz.PNGnum := 0;
        setlength(tempimz.imzPNG, tempimz.PNGnum);
        result := false;
        exit;
      end;
      FH := Fileopen(path + indexfile, fmopenread);
      tempimz.PNGnum := Fileseek(FH, 0, 2) shr 2;
      Fileseek(FH, 0, 0);
      setlength(tempimz.imzPNG, tempimz.PNGnum);
      for I := 0 to tempimz.PNGnum - 1 do
      begin
        fileread(FH, tempimz.imzPNG[I].x, 2);
        fileread(FH, tempimz.imzPNG[I].y, 2);
      end;
    finally
      Fileclose(FH);
    end;

    for I := 0 to tempimz.PNGnum - 1 do
    begin
      tempimz.imzPNG[I].frame := 0;
      if Fileexists(path + inttostr(I) + '.png') then
      begin
        tempimz.imzPNG[I].frame := 1;
        setlength(tempImz.imzPNG[I].framelen, tempimz.imzPNG[I].frame);
        setlength(tempImz.imzPNG[I].framedata, tempimz.imzPNG[I].frame);
        try
          FH := Fileopen(path + inttostr(I) + '.png', fmopenread);
          tempImz.imzPNG[I].framelen[0] := fileseek(FH, 0, 2);
          fileseek(FH, 0, 0);
          setlength(tempImz.imzPNG[I].framedata[0].data, tempImz.imzPNG[I].framelen[0]);
          fileread(FH, tempImz.imzPNG[I].framedata[0].data[0], tempImz.imzPNG[I].framelen[0]);
        finally
          Fileclose(FH);
        end;
      end
      else
      begin
        i2 := 0;
        while (Fileexists(path + inttostr(I) + '_' + inttostr(i2) + '.png')) do
          inc(i2);
        tempimz.imzPNG[I].frame := i2;
        setlength(tempImz.imzPNG[I].framelen, tempimz.imzPNG[I].frame);
        setlength(tempImz.imzPNG[I].framedata, tempimz.imzPNG[I].frame);
        for I2 := 0 to tempimz.imzPNG[I].frame - 1 do
        begin
          try
            FH := Fileopen(path + inttostr(I) + '_' + inttostr(i2) + '.png', fmopenread);
            tempImz.imzPNG[I].framelen[I2] := fileseek(FH, 0, 2);
            fileseek(FH, 0, 0);
            setlength(tempImz.imzPNG[I].framedata[I2].data, tempImz.imzPNG[I].framelen[I2]);
            fileread(FH, tempImz.imzPNG[I].framedata[I2].data[0], tempImz.imzPNG[I].framelen[I2]);
          finally
            Fileclose(FH);
          end;
        end;
      end;
    end;

    CalImzLen(tempimz);
    result := true;
  except
    fileclose(FH);
    tempimz.PNGnum := 0;
    setlength(tempimz.imzPNG, tempimz.PNGnum);
    result := false;
  end;


end;

end.
