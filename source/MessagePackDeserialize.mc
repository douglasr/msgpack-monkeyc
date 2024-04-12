/*
MIT License

Copyright (c) 2024 Douglas Robertson (douglas@edgeoftheearth.com)

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
import Toybox.StringUtil;
using Toybox.System;

/*
MessagePack is an efficient binary serialization format.
And now it's available for Monkey C.
*/
module MessagePack {

    (:MessagePackDeserialize)
    module Deserialize {

        // Deserialize (unpack) a packable object, recursively as needed.
        //   @param  byteArray byte array of the object, in MessagePack format
        //   @return an object compatible with MessagePack
        function unpack(byteArray as ByteArray) as MsgPackObject? {
            var parseResults = unpackRecursive(byteArray, 0);
            var index = parseResults[1] as Number;
            if (index < byteArray.size()) {
                throw new MalformedFormatException(Lang.format(Application.loadResource(Rez.Strings.exceptionExtraBytes) as String, [byteArray.size()-index]));
            }
            return parseResults[0] as MsgPackObject?;
        }

        // Deserialize (unpack) a packable object, recursively as needed, starting at a given index in the byte array.
        // Since array parameters (including ByteArray objects) are passed by by reference, it is more memory efficient
        // to pass the entire byte array and the index to start parsing at rather than slicing the array into pieces.
        //   @param  byteArray byte array of the object, in MessagePack format
        //   @param  index     the index within the byte array to start deserialization at
        //   @return an array/tuple of a MessagePack object and the end index (after parsing)
        function unpackRecursive(byteArray as ByteArray, index as Number) as [MsgPackObject, Number] {
            var parseResults;
            var formatByte;
            formatByte = byteArray[index];
            if (formatByte == FORMAT_UNUSED) {
                throw new MalformedFormatException(Application.loadResource(Rez.Strings.exceptionInvalidByte) as String);
            } else if (formatByte == FORMAT_NIL) {
                parseResults = unpackNull(byteArray, index);
            } else if ((formatByte >= FORMAT_FIXARRAY && formatByte < FORMAT_FIXARRAY+16) || formatByte == FORMAT_ARRAY16 || formatByte == FORMAT_ARRAY32) {
                parseResults = unpackArray(byteArray, index);
            } else if (formatByte == FORMAT_FALSE || formatByte == FORMAT_TRUE) {
                parseResults = unpackBoolean(byteArray, index);
            } else if ((formatByte >= FORMAT_FIXMAP && formatByte < FORMAT_FIXMAP+16) || formatByte == FORMAT_MAP16 || formatByte == FORMAT_MAP32) {
                parseResults = unpackDictionary(byteArray, index);
            } else if ((formatByte >= 0x00 && formatByte < 0x80) || (formatByte >= FORMAT_UINT8 && formatByte <= FORMAT_INT64) || formatByte == FORMAT_NEG_FIXINT) {
                parseResults = unpackNumber(byteArray, index);
            } else if ((formatByte >= FORMAT_FIXSTR && formatByte < FORMAT_FIXSTR+16) || formatByte == FORMAT_STR8 || formatByte == FORMAT_STR16) {
                parseResults = unpackString(byteArray, index);
            } else {
                throw new MalformedFormatException(Application.loadResource(Rez.Strings.exceptionInvalidByte) as String);
            }
            return parseResults as [MsgPackObject, Number];
        }

        // Deserialize (unpack) an array.
        //   @param  byteArray byte array of MessagePack object(s)
        //   @param  index     index within the byte array to start parsing
        //   @return an array/tuple of an array of MessagePack objects and the end index (after parsing)
        function unpackArray(byteArray as ByteArray, index as Number) as [Array, Number] {
            var arraySize;
            var headerSize;
            var unpackedArray = [];

            if (byteArray[index] >= FORMAT_FIXARRAY && byteArray[index] < FORMAT_FIXARRAY+16) {
                headerSize = 1;
                arraySize = byteArray[index] - FORMAT_FIXARRAY;
            } else if (byteArray[index] == FORMAT_ARRAY16) {
                headerSize = 3;
                arraySize = (byteArray[index+1] << 8) + byteArray[index+2];
            } else {
                throw new MalformedFormatException(Application.loadResource(Rez.Strings.exceptionUnsupportedFormatByte) as String);
            }

            index = index + headerSize;
            for (var i=0; i < arraySize; i++) {
                var parseResults = unpackRecursive(byteArray, index);
                unpackedArray.add(parseResults[0] as MsgPackObject?);
                index = parseResults[1];
            }

            return [unpackedArray, index];
        }

        // Deserialize (unpack) a boolean.
        //   @param  byteArray byte array of MessagePack object(s)
        //   @param  index     index within the byte array to start parsing
        //   @return an array/tuple of a boolean object and the end index (after parsing)
        function unpackBoolean(byteArray as ByteArray, index as Number) as [Boolean, Number] {
            if (byteArray[index] == FORMAT_TRUE) {
                return [true, index+1];
            } else if (byteArray[index] == FORMAT_FALSE) {
                return [false, index+1];
            }
            throw new MalformedFormatException(Application.loadResource(Rez.Strings.exceptionInvalidByte) as String);
        }

        // Deserialize (unpack) a dictionary (map).
        //   @param  byteArray byte array of MessagePack object(s)
        //   @param  index     index within the byte array to start parsing
        //   @return an array/tuple of an dictionary of MessagePack object key/pairs and the end index (after parsing)
        function unpackDictionary(byteArray as ByteArray, index as Number) as [Dictionary, Number] {
            var mapSize;
            var headerSize;
            var unpackedMap = {};
            var parseResults;

            if (byteArray[index] >= FORMAT_FIXMAP && byteArray[index] < FORMAT_FIXMAP+16) {
                headerSize = 1;
                mapSize = byteArray[index] - FORMAT_FIXMAP;
            } else if (byteArray[index] == FORMAT_MAP16) {
                headerSize = 3;
                mapSize = (byteArray[index+1] << 8) + byteArray[index+2];
            } else {
                throw new MalformedFormatException(Application.loadResource(Rez.Strings.exceptionUnsupportedFormatByte) as String);
            }

            index += headerSize;
            for (var i=0; i < mapSize; i++) {
                // parse the key
                parseResults = unpackRecursive(byteArray, index);
                var key = parseResults[0];
                index = parseResults[1] as Number;

                // parse the value
                parseResults = unpackRecursive(byteArray, index);
                var value = parseResults[0];
                index = parseResults[1] as Number;

                unpackedMap[key] = value;
            }

            return [unpackedMap, index];
        }

        // Deserialize (unpack) a null.
        //   @param  byteArray byte array of MessagePack object(s)
        //   @param  index     index within the byte array to start parsing
        //   @return an array/tuple of a null object and the end index (after parsing)
        function unpackNull(byteArray as ByteArray, index as Number) as [Null, Number] {
            if (byteArray[index] == FORMAT_NIL) {
                return [null, index+1];
            }
            throw new MalformedFormatException(Application.loadResource(Rez.Strings.exceptionInvalidByte) as String);
        }

        // Deserialize (unpack) a whole number (integer).
        //   @param  byteArray byte array of MessagePack object(s)
        //   @param  index     index within the byte array to start parsing
        //   @return an array/tuple of a number/long and the end index (after parsing)
        function unpackNumber(byteArray as ByteArray, index as Number) as [Number or Long, Number] {
            if (byteArray[index] >= 0x00 && byteArray[index] < 0x80) {
                // value is the actual byte
                return [byteArray[index], index+1];
            } else if (byteArray[index] >= 0xE0 && byteArray[index] <= 0xFF) {
                // value is 0x1FF-byte-1
                return [(byteArray[index]-FORMAT_NEG_FIXINT-1), index+1];
            } else if (byteArray[index] == FORMAT_UINT8) {
                // value is the byte after the format
                return [byteArray[index+1], index+2];
            } else if (byteArray[index] == FORMAT_UINT16) {
                // value is the two bytes after the format
                var uint16 = (byteArray[index+1] << 8) + byteArray[index+2];
                return [uint16, index+4];
            } else if (byteArray[index] == FORMAT_UINT32) {
                // value is the four bytes after the format
                var uint32 = 0;
                // if the resulting number will be >= 2,147,483,648 then we need to treat the first byte as a Long
                if (byteArray[index+1] >= 0x80) {
                    uint32 = (byteArray[index+1].toLong() << 24);
                } else {
                    uint32 = (byteArray[index+1] << 24);
                }
                uint32 = uint32 + (byteArray[index+2] << 16) + (byteArray[index+3] << 8) + byteArray[index+4];
                return [uint32, index+6];
            } else if (byteArray[index] == FORMAT_UINT64) {
                var uint64 = (byteArray[index+1].toLong() << 56) + (byteArray[index+2].toLong() << 48);
                uint64 = uint64 + (byteArray[index+3].toLong() << 40) + (byteArray[index+4].toLong() << 32);
                uint64 = uint64 + (byteArray[index+5].toLong() << 24) + (byteArray[index+6] << 16);
                uint64 = uint64 + (byteArray[index+7] << 8) + byteArray[index+8];
                return [uint64, index+10];
            } else if (byteArray[index] == FORMAT_INT8) {
                // value is byte - 256
                return [(byteArray[index+1]-256), index+2];
            } else if (byteArray[index] == FORMAT_INT16) {
                // value is byte - 65536
                var int16 = (byteArray[index+1] << 8) + byteArray[index+2] - 65536;
                return [int16, index+3];
            } else if (byteArray[index] == FORMAT_INT32) {
                // value is byte - 4294967296
                var int32 = (byteArray[index+1].toLong() << 24);
                int32 = int32 + (byteArray[index+2] << 16) + (byteArray[index+3] << 8) + byteArray[index+4];
                int32 = (int32 - 4294967296l).toNumber();
                return [int32, index+6];
            } else {
                // value is byte - 9223372036854775807 - 9223372036854775807 - 2
                var int64 = (byteArray[index+1].toLong() << 56) + (byteArray[index+2].toLong() << 48);
                int64 = int64 + (byteArray[index+3].toLong() << 40) + (byteArray[index+4].toLong() << 32);
                int64 = int64 + (byteArray[index+5].toLong() << 24) + (byteArray[index+6] << 16);
                int64 = int64 + (byteArray[index+7] << 8) + byteArray[index+8];
                int64 = int64 - 9223372036854775807l;
                int64 = int64 - 9223372036854775807l;
                int64 = int64 - 2;
                return [int64, index+10];
            }
        }

        // Deserialize (unpack) a string.
        //   @param  byteArray byte array of MessagePack object(s)
        //   @param  index     index within the byte array to start parsing
        //   @return an array/tuple of a string object and the end index (after parsing)
        function unpackString(byteArray as ByteArray, index as Number) as [String, Number] {
            var strLength;
            var headerSize;
            var unpackedStr = "";
            if (byteArray[index] >= FORMAT_FIXSTR && byteArray[index] < FORMAT_FIXSTR+16) {
                strLength = byteArray[index] - FORMAT_FIXSTR;
                headerSize = 1;
            } else if (byteArray[index] == FORMAT_STR8) {
                strLength = byteArray[index+1];
                headerSize = 2;
            } else if (byteArray[index] == FORMAT_STR16) {
                strLength = (byteArray[index+1] << 8) + byteArray[index+2];
                headerSize = 3;
            } else {
                throw new MalformedFormatException(Application.loadResource(Rez.Strings.exceptionInvalidByte) as String);
            }

            var convertOptions = {
                :fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
                :toRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT
            };
            try {
                unpackedStr = StringUtil.convertEncodedString(byteArray.slice(index+headerSize,index+headerSize+strLength), convertOptions) as String;
            }
            catch (ex) {
            }

            return [unpackedStr, index+headerSize+strLength];
        }
    }
}
