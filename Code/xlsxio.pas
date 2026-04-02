unit xlsxio;

interface

// the writer of this library only supports single sheet in a file
const
  xlsxio_read_dll = 'libxlsxio_read.dll';

  XLSXIOREAD_SKIP_NONE = 0;
  XLSXIOREAD_SKIP_EMPTY_ROWS = 1;
  XLSXIOREAD_SKIP_EMPTY_CELLS = 2;
  XLSXIOREAD_SKIP_ALL_EMPTY = (XLSXIOREAD_SKIP_EMPTY_ROWS or
    XLSXIOREAD_SKIP_EMPTY_CELLS);
  XLSXIOREAD_SKIP_EXTRA_CELLS = 4;

type
  xlsxioreader = pointer;
  xlsxioreadersheet = pointer;

procedure xlsxioread_get_version(var pmajor: integer; var pminor: integer;
  var pmicro: integer); stdcall; external xlsxio_read_dll;
function xlsxioread_open(filename: pansichar): xlsxioreader; stdcall;
  external xlsxio_read_dll;
procedure xlsxioread_close(handle: xlsxioreader); stdcall;
  external xlsxio_read_dll;
function xlsxioread_sheet_open(handle: xlsxioreader; sheetname: pansichar;
  flags: integer): xlsxioreadersheet; stdcall; external xlsxio_read_dll;
procedure xlsxioread_sheet_close(sheethandle: xlsxioreadersheet); stdcall;
  external xlsxio_read_dll;
function xlsxioread_sheet_next_row(sheethandle: xlsxioreadersheet): integer;
  stdcall; external xlsxio_read_dll;
function xlsxioread_sheet_next_cell(sheethandle: xlsxioreadersheet): pansichar;
  stdcall; external xlsxio_read_dll;

const
  xlsxwriter_dll = 'xlsxwriter.dll';

type
  plxw_workbook = pointer;
  plxw_worksheet = pointer;

function workbook_new(filename: pansichar): plxw_workbook; stdcall;
  external xlsxwriter_dll;
function workbook_add_worksheet(workbook: plxw_workbook; sheetname: pansichar)
  : plxw_worksheet; stdcall; external xlsxwriter_dll;
function workbook_get_worksheet_by_name(workbook: plxw_workbook;
  sheetname: pansichar): plxw_worksheet; stdcall; external xlsxwriter_dll;
function workbook_close(workbook: plxw_workbook): integer; stdcall;
  external xlsxwriter_dll;
function worksheet_write_string(worksheet: plxw_worksheet; row: longword;
  col: longword; value: pansichar; format: pointer): integer; stdcall;
  external xlsxwriter_dll;
function worksheet_write_number(worksheet: plxw_worksheet; row: longword;
  col: longword; value: real; format: pointer): integer; stdcall;
  external xlsxwriter_dll;

implementation


end.
