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

import Toybox.Application;
import Toybox.Lang;

/*
MessagePack is an efficient binary serialization format.
And now it's available for Monkey C.
*/
module MessagePack {

    (:MessagePackSerialize)
    module Serialize  {

        // Serialize (pack) a packable object, recursively as needed.
        //   @param  packableObj an object capable of being serialized, as per MessagePack spec
        //   @return byte array of the object, in MessagePack format
        function pack(packableObj as MsgPackObject?) as ByteArray {
            var byteArray = []b;
            if (packableObj == null) {
                byteArray.add(packNull());
            } else if (packableObj instanceof Array) {
                byteArray.addAll(packArray(packableObj as Array<MsgPackObject>));
            } else if (packableObj instanceof Boolean) {
                byteArray.add(packBoolean(packableObj));
            } else if (packableObj instanceof Dictionary) {
                byteArray.addAll(packDictionary(packableObj));
            } else if (packableObj instanceof Number or packableObj instanceof Long) {
                byteArray.addAll(packNumber(packableObj));
            } else if (packableObj instanceof Float or packableObj instanceof Double) {
                byteArray.addAll(packDecimal(packableObj));
            } else if (packableObj instanceof String) {
                byteArray.addAll(packString(packableObj));
            }
            return (byteArray);
        }

        // Serialize (pack) an array, including the elements contained within the array.
        //   @param  array an array of objects capable of being serialized, as per MessagePack spec
        //   @return byte array of the array, in MessagePack format
        function packArray(array as Array<MsgPackObject>) as ByteArray {
            var byteArray = new [1]b;   // there will be at least one element (representing the array length)

            if (array.size() < 16) {
                byteArray[0] = FORMAT_FIXARRAY + array.size();  // first element will be the array length
            } else if (array.size() < 65536) {
                byteArray.addAll([0,0]b);  // header is three bytes (0xDC + two bytes for array length)
                byteArray[0] = FORMAT_ARRAY16;
                byteArray[1] = (array.size() >> 8) & 0xFF;
                byteArray[2] = array.size() & 0xFF;
            } else {
                throw new MalformedFormatException(Application.loadResource(Rez.Strings.exceptionElementTooLarge) as String);
            }

            for (var i=0; i < array.size(); i++) {
                byteArray.addAll(pack(array[i]));
            }

            return (byteArray);
        }

        // Serialize (pack) binary data.
        //   @param  data a byte array of 'data'
        //   @return byte array of the data, in MessagePack format
        function packBinary(data as ByteArray) as ByteArray {
            // TODO: handle other types of input and transform them to byte array
            return (packByteArray(data));
        }

        // Serialize (pack) a byte array.
        //   @param  binData a byte array of 'data'
        //   @return byte array of the data, in MessagePack format
        function packByteArray(binData as ByteArray) as ByteArray {
            // FIXME - need to do this
            var headerSize = 2;     // header will be at least 2 bytes (0xC4 + one byte for data length)
            var byteArray = new [binData.size()+headerSize]b;
            if (binData.size() < 256) {
                byteArray[0] = FORMAT_BIN8;
                byteArray[1] = binData.size();
            } else if (binData.size() < 65536) {
                headerSize = 3;
                byteArray.add(0);   // header is five bytes (0xC6 + two bytes for data length)
                byteArray[0] = FORMAT_BIN16;
                byteArray[1] = (binData.size() >> 8) & 0xFF;
                byteArray[2] = binData.size() & 0xFF;
            } else {
                headerSize = 5;
                byteArray.addAll([0,0,0]b);   // header is five bytes (0xC6 + four bytes for data length)
                byteArray[0] = FORMAT_BIN32;
                byteArray[1] = (binData.size() >> 24) & 0xFF;
                byteArray[2] = (binData.size() >> 16) & 0xFF;
                byteArray[3] = (binData.size() >> 8) & 0xFF;
                byteArray[4] = binData.size() & 0xFF;
            }
            for (var i=0; i < binData.size(); i++) {
                byteArray[i+headerSize] = binData[i];
            }
            return (byteArray);
        }

        // Serialize (pack) a boolean.
        //   @param  bool a boolean
        //   @return an 8-bit value representing the boolean, as per MessagePack spec
        function packBoolean(bool as Boolean) as Number {
            if (bool) {
                return (FORMAT_TRUE);
            }
            return (FORMAT_FALSE);
        }

        //! TODO - describe function here
        function packDecimal(dec as Decimal) as ByteArray {
            var byteArray;
            if (dec instanceof Float) {
                byteArray = new [5]b;
                byteArray[0] = FORMAT_FLOAT32;
            } else {
                byteArray = new [9]b;
                byteArray[0] = FORMAT_FLOAT64;
            }
            // FIXME: need to implement decimal (float/double) packing
            return ([0]b);
        }

        // Serialize (pack) a Dictionary (map), including the elements contained within.
        //   @param  dict a dictionary of key/value pairs capable of being serialized, as per MessagePack spec
        //   @return byte array of the dictionary, in MessagePack format
        function packDictionary(dict as Dictionary) as ByteArray {
            var byteArray = new [1]b;
            var keys = dict.keys();
            if (keys.size() < 16) {
                byteArray[0] = FORMAT_FIXMAP + keys.size();
            } else if (keys.size() < 65536) {
                byteArray.addAll([0,0]b);  // header is three bytes (0xDA + two bytes for string length)
                byteArray[0] = FORMAT_MAP16;
                byteArray[1] = (keys.size() >> 8)  & 0xFF;
                byteArray[2] = keys.size() & 0xFF;
            } else {
                throw new MalformedFormatException(Application.loadResource(Rez.Strings.exceptionElementTooLarge) as String);
            }

            for (var i=0; i < keys.size(); i++) {
                var key = keys[i] as MsgPackObject;
                byteArray.addAll(pack(key));
                byteArray.addAll(pack(dict.get(key) as MsgPackObject?));
            }

            return (byteArray);
        }

        // Serialize (pack) a null
        //   @return an 8-bit value representing null, as per MessagePack spec
        function packNull() as Number {
            return (FORMAT_NIL);
        }

        // Serialize (pack) a positive/negative whole number.
        //   @param  num a number or long
        //   @return byte array of the number, in MessagePack format
        function packNumber(num as Number or Long) as ByteArray {
            var long = num.toLong();
            num = num.toNumber();
            if (long >= 0) {
                // positive numbers
                if (long < 128) {
                    return ([num]b);
                } else if (long < 256) {
                    return ([FORMAT_UINT8, num]b);
                } else if (long < 65536) {
                    var baUINT16 = new [3]b;
                    baUINT16[0] = FORMAT_UINT16;
                    baUINT16[1] = (num >> 8) & 0xFF;
                    baUINT16[2] = num & 0xFF;
                    return (baUINT16);
                } else if (long < 4294967296l) {
                    var baUINT32 = new [5]b;
                    baUINT32[0] = FORMAT_UINT32;
                    baUINT32[1] = ((long >> 24) & 0xFF).toNumber();
                    baUINT32[2] = ((long >> 16) & 0xFF).toNumber();
                    baUINT32[3] = ((long >> 8) & 0xFF).toNumber();
                    baUINT32[4] = (long & 0xFF).toNumber();
                    return (baUINT32);
                } else {
                    var baUINT64 = new [9]b;
                    baUINT64[0] = FORMAT_UINT64;
                    baUINT64[1] = ((long >> 56) & 0xFF).toNumber();
                    baUINT64[2] = ((long >> 48) & 0xFF).toNumber();
                    baUINT64[3] = ((long >> 40) & 0xFF).toNumber();
                    baUINT64[4] = ((long >> 32) & 0xFF).toNumber();
                    baUINT64[5] = ((long >> 24) & 0xFF).toNumber();
                    baUINT64[6] = ((long >> 16) & 0xFF).toNumber();
                    baUINT64[7] = ((long >> 8) & 0xFF).toNumber();
                    baUINT64[8] = (long & 0xFF).toNumber();
                    return (baUINT64);
                }
            } else {
                // negative numbers
                if (long >= -32) {
                    return ([((FORMAT_NEG_FIXINT+1)+num)]b);
                } else if (long >= -128) {
                    var baINT8 = new [2]b;
                    baINT8[0] = FORMAT_INT8;
                    baINT8[1] = num+256;
                    return (baINT8);
                } else if (long >= -32768) {
                    var numToPack = num+65536;
                    var baINT16 = new [3]b;
                    baINT16[0] = FORMAT_INT16;
                    baINT16[1] = (numToPack >> 8) & 0xFF;
                    baINT16[2] = numToPack & 0xFF;
                    return (baINT16);
                } else if (long >= -2147483648l) {
                    var numToPack = long+4294967296l;
                    var baINT32 = new [5]b;
                    baINT32[0] = FORMAT_INT32;
                    baINT32[1] = ((numToPack >> 24) & 0xFF).toNumber();
                    baINT32[2] = ((numToPack >> 16) & 0xFF).toNumber();
                    baINT32[3] = ((numToPack >> 8) & 0xFF).toNumber();
                    baINT32[4] = (numToPack & 0xFF).toNumber();
                    return (baINT32);
                } else {
                    var numToPack = long+9223372036854775807l+9223372036854775807l+1+1;
                    var baINT64 = new [9]b;
                    baINT64[0] = FORMAT_INT64;
                    baINT64[1] = ((numToPack >> 56) & 0xFF).toNumber();
                    baINT64[2] = ((numToPack >> 48) & 0xFF).toNumber();
                    baINT64[3] = ((numToPack >> 40) & 0xFF).toNumber();
                    baINT64[4] = ((numToPack >> 32) & 0xFF).toNumber();
                    baINT64[5] = ((numToPack >> 24) & 0xFF).toNumber();
                    baINT64[6] = ((numToPack >> 16) & 0xFF).toNumber();
                    baINT64[7] = ((numToPack >> 8) & 0xFF).toNumber();
                    baINT64[8] = (numToPack & 0xFF).toNumber();
                    return (baINT64);
                }
            }
        }

        // Serialize (pack) a string.
        //   @param  str the string to be serialized
        //   @return byte array of the string, in MessagePack format
        function packString(str as String) as ByteArray {
            var chars = str.toCharArray();
            var headerSize = 1;
            var byteArray = new [chars.size()+1]b;

            if (chars.size() < 32) {
                byteArray[0] = FORMAT_FIXSTR + chars.size();
            } else if (chars.size() < 256) {
                headerSize = 2;
                byteArray.add(0);   // header is two bytes (0xD9 + one byte for string length)
                byteArray[0] = FORMAT_STR8;
                byteArray[1] = chars.size();
            } else if (chars.size() < 65536) {
                headerSize = 3;
                byteArray.addAll([0,0]b);  // header is three bytes (0xDA + two bytes for string length)
                byteArray[0] = FORMAT_STR16;
                byteArray[1] = chars.size() >> 8;
                byteArray[2] = chars.size() & 0xFF;
            } else {
                // TODO -- should this even be supported, since most Garmin devices have limited memory
            }

            for (var i=0; i < chars.size(); i++) {
                byteArray[i+headerSize] = chars[i].toNumber();
            }

            return (byteArray);
        }
    }
}
