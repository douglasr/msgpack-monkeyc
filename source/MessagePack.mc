/*
MIT License

Copyright (c) 2024-2025 Douglas Robertson (douglas@edgeoftheearth.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Author: Douglas Robertson (GitHub: douglasr; Garmin Connect: dbrobert)
*/

import Toybox.Lang;

/*
MessagePack is an efficient binary serialization format.
And now it's available for Monkey C.
*/
module MessagePack {

    const FORMAT_FIXMAP     = 0x80;
    const FORMAT_FIXARRAY   = 0x90;
    const FORMAT_FIXSTR     = 0xA0;
    const FORMAT_NIL        = 0xC0;
    const FORMAT_UNUSED     = 0xC1;
    const FORMAT_FALSE      = 0xC2;
    const FORMAT_TRUE       = 0xC3;
    const FORMAT_BIN8       = 0xC4;
    const FORMAT_BIN16      = 0xC5;
    const FORMAT_BIN32      = 0xC6;
    const FORMAT_EXT8       = 0xC7;     // TODO: not yet implemented
    const FORMAT_EXT16      = 0xC8;     // TODO: not yet implemented
    const FORMAT_EXT32      = 0xC9;     // TODO: not yet implemented
    const FORMAT_FLOAT32    = 0xCA;     // TODO: not yet implemented
    const FORMAT_FLOAT64    = 0xCB;     // TODO: not yet implemented
    const FORMAT_UINT8      = 0xCC;
    const FORMAT_UINT16     = 0xCD;
    const FORMAT_UINT32     = 0xCE;
    const FORMAT_UINT64     = 0xCF;
    const FORMAT_INT8       = 0xD0;
    const FORMAT_INT16      = 0xD1;
    const FORMAT_INT32      = 0xD2;
    const FORMAT_INT64      = 0xD3;
    const FORMAT_FIXEXT1    = 0xD4;     // TODO: not yet implemented
    const FORMAT_FIXEXT2    = 0xD5;     // TODO: not yet implemented
    const FORMAT_FIXEXT4    = 0xD6;     // TODO: not yet implemented
    const FORMAT_FIXEXT8    = 0xD7;     // TODO: not yet implemented
    const FORMAT_FIXEXT16   = 0xD8;     // TODO: not yet implemented
    const FORMAT_STR8       = 0xD9;
    const FORMAT_STR16      = 0xDA;
    const FORMAT_STR32      = 0xDB;     // TODO: not yet implemented
    const FORMAT_ARRAY16    = 0xDC;
    const FORMAT_ARRAY32    = 0xDD;     // TODO: not yet implemented
    const FORMAT_MAP16      = 0xDE;
    const FORMAT_MAP32      = 0xDE;     // TODO: not yet implemented
    const FORMAT_NEG_FIXINT = 0xFF;

    typedef MsgPackObject as Array or Boolean or ByteArray or Decimal or Dictionary or Number or Long or String;

    class MalformedFormatException extends Lang.Exception {
        var _message as String?;

        function initialize(message as String?) {
            Exception.initialize();
            _message = message;
        }

        function getErrorMessage() as Lang.String? {
            return (_message);
        }
    }

    // Generate a printable string (in a pretty manner) from a byte array.
    //   @param  byteArray byte array of unspecified size
    //   @return a string representation of the byte array
    (:debug)
    function prettyPrint(byteArray as ByteArray) as String {
        var printableStr = "";
        for (var i=0; i < byteArray.size(); i++) {
            printableStr = printableStr + "\\x" + byteArray[i].toNumber().format("%02X");
        }
        return (printableStr);
    }

}
