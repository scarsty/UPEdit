# WebP Runtime

`libwebp.dll` and `libsharpyuv.dll` are x64 runtime dependencies copied from
the existing local promise build (`bin-c/build/x64/Release`). MSBuild copies
both files to the selected output directory. The application uses
`WebPGetInfo` and `WebPDecodeRGBAInto` when Qt has no WebP image plugin.

Upstream: https://github.com/webmproject/libwebp

Redistribution terms are in `COPYING.libwebp`. Retain this notice and the
license when distributing these binaries. Replace both DLLs together when
upgrading the decoder.