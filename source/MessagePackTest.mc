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
import Toybox.Test;

module MessagePack {

    module Serialize {

        // Wrapping all test cases within a module will allow the compiler
        // to eliminate the entire module when not building unit tests.
        (:test)
        module Test {

            (:test)
            function testNull(logger as Logger) as Boolean {
                return (packNull() == MessagePack.FORMAT_NIL);
            }

            (:test)
            function testFixArray(logger as Logger) as Boolean {
                Test.assertEqual(packArray([] as Array<Number>), [0x90]b);
                Test.assertEqual(packArray([1] as Array<Number>), [0x91, 0x01]b);
                Test.assertEqual(packArray([0,1,2,3,4,5] as Array<Number>), [0x96, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05]b);
                Test.assertEqual(
                    packArray([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14] as Array<Number>),
                    [0x9F, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E]b
                );
                Test.assertNotEqual(
                    packArray([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15] as Array<Number>),
                    [0xA0, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F]b
                );
                return true;
            }

            (:test)
            function testArray16(logger as Logger) as Boolean {
                Test.assertEqual(
                    packArray([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15] as Array<Number>),
                    [0xDC, 0x00, 0x10, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F]b
                );
                Test.assertEqual(
                    packArray([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20] as Array<Number>),
                    [0xDC, 0x00, 0x15, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12, 0x13, 0x14]b
                );
                return true;
            }

            (:test)
            function testBin8(logger as Logger) as Boolean {
                Test.assertEqual(packBinary([0x00, 0x01, 0x02]b), [0xC4, 0x03, 0x00, 0x01, 0x02]b);
                Test.assertEqual(
                    packBinary([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06]b),
                    [0xC4, 0x07, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06]b
                );

                var maxBin8Array = new [255]b;
                for (var i=0; i < 255; i++) {
                    maxBin8Array[i] = i;
                }
                Test.assertEqual(
                    packBinary(maxBin8Array),
                    ([0xC4, 0xFF]b).addAll(maxBin8Array)
                );
                maxBin8Array.add(0xFF);
                Test.assertNotEqual(packBinary(maxBin8Array)[0], 0xC4);
                return true;
            }

            (:test)
            function testBin16(logger as Logger) as Boolean {
                var minBin16Array = new [256]b;
                for (var i=0; i < 256; i++) {
                    minBin16Array[i] = i;
                }
                Test.assertEqual(
                    packBinary(minBin16Array),
                    ([0xC5, 0x01, 0x00]b).addAll(minBin16Array)
                );

                var maxBin16Array = new [65535]b;
                for (var i=0; i < 65535; i++) {
                    maxBin16Array[i] = i % 256;
                }
                Test.assertEqual(
                    packBinary(maxBin16Array),
                    ([0xC5, 0xFF, 0xFF]b).addAll(maxBin16Array)
                );
                return true;
            }

            (:test)
            function testBin32(logger as Logger) as Boolean {
                var minBin32Array = new [65536]b;
                for (var i=0; i < 65536; i++) {
                    minBin32Array[i] = i % 256;
                }
                Test.assertEqual(
                    packBinary(minBin32Array),
                    ([0xC6, 0x00, 0x01, 0x00, 0x00]b).addAll(minBin32Array)
                );
                return true;
            }

            (:test)
            function testBoolean(logger as Logger) as Boolean {
                Test.assertEqual(packBoolean(false), MessagePack.FORMAT_FALSE);
                Test.assertEqual(packBoolean(true), MessagePack.FORMAT_TRUE);
                return true;
            }

            (:test)
            function testFixMap(logger as Logger) as Boolean {
                Test.assertEqual(packDictionary({}), [0x80]b);
                Test.assertEqual(
                    packDictionary({ "x" => 13 }),
                    [0x81, 0xA1, 0x78, 0x0D]b
                );
                Test.assertEqual(
                    packDictionary({ "a" => 0, "b" => 1, "c" => 2, "d" => 3, "e" => 4 }),
                    [0x85, 0xA1, 0x61, 0x00, 0xA1, 0x62, 0x01, 0xA1, 0x63, 0x02, 0xA1, 0x64, 0x03, 0xA1, 0x65, 0x04]b
                );
                Test.assertNotEqual(
                    packDictionary({
                        "a" => 0, "b" => 1, "c" => 2, "d" => 3,
                        "e" => 4, "f" => 5, "g" => 6, "h" => 7,
                        "i" => 8, "j" => 9, "k" => 10, "l" => 11,
                        "m" => 12, "n" => 13, "o" => 14,"p" => 15
                    }),
                    [
                        0x90,
                        0xA1, 0x61, 0x00, 0xA1, 0x62, 0x01, 0xA1, 0x63, 0x02, 0xA1, 0x64, 0x03, 0xA1,
                        0x65, 0x04, 0xA1, 0x66, 0x05, 0xA1, 0x67, 0x06, 0xA1, 0x68, 0x07, 0xA1, 0x69,
                        0x08, 0xA1, 0x6A, 0x09, 0xA1, 0x6B, 0x0A, 0xA1, 0x6C, 0x0B, 0xA1, 0x6D, 0x0C,
                        0xA1, 0x6E, 0x0D, 0xA1, 0x6F, 0x0E, 0xA1, 0x70, 0x0F
                    ]b
                );
                return true;
            }

            (:test)
            function testMap16(logger as Logger) as Boolean {
                Test.assertEqual(
                    packDictionary({
                        "a" => 0, "b" => 1, "c" => 2, "d" => 3,
                        "e" => 4, "f" => 5, "g" => 6, "h" => 7,
                        "i" => 8, "j" => 9, "k" => 10, "l" => 11,
                        "m" => 12, "n" => 13, "o" => 14, "p" => 15
                    }),
                    [
                        0xDE, 0x00, 0x10,
                        0xA1, 0x61, 0x00, 0xA1, 0x62, 0x01, 0xA1, 0x63, 0x02, 0xA1, 0x64, 0x03,
                        0xA1, 0x65, 0x04, 0xA1, 0x66, 0x05, 0xA1, 0x67, 0x06, 0xA1, 0x68, 0x07,
                        0xA1, 0x69, 0x08, 0xA1, 0x6A, 0x09, 0xA1, 0x6B, 0x0A, 0xA1, 0x6C, 0x0B,
                        0xA1, 0x6D, 0x0C, 0xA1, 0x6E, 0x0D, 0xA1, 0x6F, 0x0E, 0xA1, 0x70, 0x0F
                    ]b
                );
                return true;
            }

            (:test)
            function testPosFixInt(logger as Logger) as Boolean {
                Test.assertEqual(packNumber(0), [0x00]b);
                Test.assertEqual(packNumber(56), [0x38]b);
                Test.assertEqual(packNumber(127), [0x7F]b);
                Test.assertNotEqual(packNumber(128), [0x80]b);
                return true;
            }

            (:test)
            function testNegFixInt(logger as Logger) as Boolean {
                Test.assertEqual(packNumber(-1), [0xFF]b);
                Test.assertEqual(packNumber(-13), [0xF3]b);
                Test.assertEqual(packNumber(-31), [0xE1]b);
                Test.assertEqual(packNumber(-32), [0xE0]b);
                Test.assertNotEqual(packNumber(-33), [0xDF]b);
                return true;
            }

            (:test)
            function testUInt8(logger as Logger) as Boolean {
                Test.assertEqual(packNumber(128), [0xCC, 0x80]b);
                Test.assertEqual(packNumber(201), [0xCC, 0xC9]b);
                Test.assertEqual(packNumber(255), [0xCC, 0xFF]b);
                Test.assertNotEqual(packNumber(256), [0xCC, 0x01, 0x00]b);
                return true;
            }

            (:test)
            function testUInt16(logger as Logger) as Boolean {
                Test.assertEqual(packNumber(256), [0xCD, 0x01, 0x00]b);
                Test.assertEqual(packNumber(65535), [0xCD, 0xFF, 0xFF]b);
                Test.assertNotEqual(packNumber(65536), [0xCD, 0x01, 0xFF, 0xFF]b);
                Test.assertNotEqual(packNumber(65536), [0xCD, 0x00, 0x00]b);
                return true;
            }

            (:test)
            function testUInt32(logger as Logger) as Boolean {
                Test.assertEqual(packNumber(65536), [0xCE, 0x00, 0x01, 0x00, 0x00]b);
                Test.assertEqual(packNumber(10001030), [0xCE, 0x00, 0x98, 0x9A, 0x86]b);
                Test.assertEqual(packNumber(2147483647), [0xCE, 0x7F, 0xFF, 0xFF, 0xFF]b);
                Test.assertEqual(packNumber(2147483648l), [0xCE, 0x80, 0x00, 0x00, 0x00]b);
                Test.assertEqual(packNumber(4294967295l), [0xCE, 0xFF, 0xFF, 0xFF, 0xFF]b);
                Test.assertNotEqual(packNumber(4294967296l), [0xCE, 0x01, 0x00, 0x00, 0x00, 0x00]b);
                return true;
            }

            (:test)
            function testUInt64(logger as Logger) as Boolean {
                Test.assertEqual(packNumber(4294967296l), [0xCF, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00]b);
                Test.assertEqual(packNumber(9223372036854775807l), [0xCF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]b);
                return true;
            }

            (:test)
            function testInt8(logger as Logger) as Boolean {
                Test.assertEqual(packNumber(-128), [0xD0, 0x80]b);
                Test.assertEqual(packNumber(-127), [0xD0, 0x81]b);
                Test.assertEqual(packNumber(-100), [0xD0, 0x9C]b);
                Test.assertEqual(packNumber(-33), [0xD0, 0xDF]b);
                Test.assertNotEqual(packNumber(-129), [0xD0, 0x7F]b);
                Test.assertNotEqual(packNumber(-32), [0xD0, 0xE0]b);
                return true;
            }

            (:test)
            function testInt16(logger as Logger) as Boolean {
                Test.assertEqual(packNumber(-129), [0xD1, 0xFF, 0x7F]b);
                Test.assertEqual(packNumber(-16384), [0xD1, 0xC0, 0x00]b);
                Test.assertEqual(packNumber(-32768), [0xD1, 0x80, 0x00]b);
                Test.assertNotEqual(packNumber(-32769), [0xD1, 0x7F, 0xFF]b);
                return true;
            }

            (:test)
            function testInt32(logger as Logger) as Boolean {
                Test.assertEqual(packNumber(-32769), [0xD2, 0xFF, 0xFF, 0x7F, 0xFF]b);
                Test.assertEqual(packNumber(-101916021), [0xD2, 0xF9, 0xEC, 0xE2, 0x8B]b);
                Test.assertEqual(packNumber(-2147483648l), [0xD2, 0x80, 0x00, 0x00, 0x00]b);
                Test.assertNotEqual(packNumber(-2147483649l), [0xD2, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF]b);
                return true;
            }

            (:test)
            function testInt64(logger as Logger) as Boolean {
                Test.assertEqual(packNumber(-2147483649l), [0xD3, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF]b);
                Test.assertEqual(packNumber(-9223372036854775807l), [0xD3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]b);
                Test.assertEqual(packNumber(-9223372036854775808l), [0xD3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]b);
                return true;
            }

            (:test)
            function testFixStr(logger as Logger) as Boolean {
                Test.assertEqual(packString(""), [0xA0]b);
                Test.assertEqual(packString(" "), [0xA1, 0x20]b);
                Test.assertEqual(packString("0"), [0xA1, 0x30]b);
                Test.assertEqual(
                    packString("012345678"),
                    [0xA9, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38]b
                );
                Test.assertEqual(
                    packString("01234567890123456789"),
                    [
                        0xB4,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39
                    ]b
                );
                Test.assertEqual(
                    packString("0123456789012345678901234567890"),
                    [
                        0xBF,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30
                    ]b
                );
                Test.assertNotEqual(
                    packString("01234567890123456789012345678901"),
                    [
                        0xC0,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31
                    ]b
                );
                return true;
            }

            (:test)
            function testStr8(logger as Logger) as Boolean {
                Test.assertEqual(
                    packString("01234567890123456789012345678901"),
                    [
                        0xD9, 0x20,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31
                    ]b
                );
                return true;
            }

            (:test)
            function testStr16(logger as Logger) as Boolean {
                Test.assertEqual(
                    packString("0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345"),
                    [
                        0xDA, 0x01, 0x00,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
                        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35
                    ]b
                );
                return true;
            }

            (:test)
            function testPack(logger as Logger) as Boolean {
                Test.assertEqual(
                    pack( { "a" => 0, "b" => [1,2,3], "c" => true, "d" => null, "e" => "Blarg", "foxtrot" => { "x" => 4, "y" => 5 } } ),
                    [
                        0x86, 0xA1, 0x61, 0x00, 0xA1, 0x62, 0x93, 0x01, 0x02, 0x03, 0xA1, 0x63, 0xC3, 0xA1, 0x64,
                        0xC0, 0xA1, 0x65, 0xA5, 0x42, 0x6c, 0x61, 0x72, 0x67, 0xA7, 0x66, 0x6f, 0x78, 0x74, 0x72,
                        0x6f, 0x74, 0x82, 0xA1, 0x78, 0x04, 0xA1, 0x79, 0x05
                    ]b
                );
                return true;
            }

        }
    }

    module Deserialize {

        // Wrapping all test cases within a module will allow the compiler
        // to eliminate the entire module when not building unit tests.
        (:test)
        module Test {

            // Check if two given single dimension arrays are "equal"; that is, they have the same number of elements
            //   in the same order/index. This function is needed for this test suite as the Array object does not
            //   implement Object.equals() as one would expect.
            // @param  arrayA an array of MessagePack objects
            // @param  arrayB an array of MessagePack objects
            // @return boolean, true if they are "equal" or false otherwise
            function equalArrays(arrayA as Array?, arrayB as Array?) as Boolean {
                if (arrayA == null || arrayB == null) {
                    return false;
                }
                if (arrayA.size() != arrayB.size()) {
                    return false;
                }
                for (var i=0; i < arrayA.size(); i++) {
                    if (arrayA[i] != arrayB[i] && !(arrayA[i] as MsgPackObject).equals(arrayB[i] as MsgPackObject)) {
                        // check if the objects are arrays or dictionaries
                        if (arrayA[i] instanceof Array) {
                            if (!equalArrays(arrayA[i] as Array, arrayB[i] as Array)) {
                                return false;
                            }
                        } else if (arrayA[i] instanceof Dictionary) {
                            if (!equalDictionaries(arrayA[i] as Dictionary, arrayB[i] as Dictionary)) {
                                return false;
                            }
                        } else {
                            return false;
                        }
                    }
                }
                return true;
            }

            // Check if two given dictionaries (maps) are "equal"; that is, they have the same number of key/value
            //   pairs. This function is needed for this test suite as the Dictionary object does not implement
            //   Object.equals() as one would expect.
            // @param  arrayA an array of MessagePack objects
            // @param  arrayB an array of MessagePack objects
            // @return boolean, true if they are "equal" or false otherwise
            function equalDictionaries(dictA as Dictionary?, dictB as Dictionary?) as Boolean {
                if (dictA == null || dictB == null) {
                    return false;
                }
                if (dictA.keys().size() != dictB.keys().size()) {
                    return false;
                }
                for (var i=0; i < dictA.keys().size(); i++) {
                    var key = dictA.keys()[i];
                    if (!dictB.hasKey(key)) {
                        return false;
                    }

                    if (dictA[key] == null && dictB[key] != null) {
                        return false;
                    }
                    if (dictA[key] != dictB[key] && !(dictA[key] as Object).equals(dictB[key])) {
                        // check if the objects are arrays or dictionaries
                        if (dictA[key] instanceof Array) {
                            if (!equalArrays(dictA[key] as Array, dictB[key] as Array)) {
                                return false;
                            }
                        } else if (dictA[key] instanceof Dictionary) {
                            if (!equalDictionaries(dictA[key] as Dictionary, dictB[key] as Dictionary)) {
                                return false;
                            }
                        } else {
                            return false;
                        }
                    }
                }
                return true;
            }

            (:test)
            function testUnusedFormat(logger as Logger) as Boolean {
                try {
                    unpack([0xC1]b);
                    return false;       // should never reach this as an exception should be thrown (see below)
                }
                catch (ex instanceof MalformedFormatException) {
                    // all good, an exception should be thrown as this format byte (0xC1) is unused
                }
                return true;
            }

            (:test)
            function testFixArray(logger as Logger) as Boolean {
                Test.assert(equalArrays(unpackArray([0x90]b, 0)[0] as Array<MsgPackObject>, []));
                Test.assert(equalArrays(unpackArray([0x91, 0x01]b, 0)[0] as Array<MsgPackObject>, [1]));
                Test.assert(equalArrays(unpackArray([0x96, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05]b, 0)[0] as Array<MsgPackObject>, [0,1,2,3,4,5]));

                // check an array within an array (need to do this manually because .equals() doesn't work on arrays)
                // value == [0,1,[10,11,12],3];
                var arrayWithinArray = unpackArray([0x94,0x00,0x01,0x93,0x0A,0x0B,0x0C,0x03]b, 0)[0] as Array<MsgPackObject>;
                Test.assertEqual(arrayWithinArray.size(), 4);
                Test.assert((arrayWithinArray[2] as Array).size() == 3);

                Test.assert(equalArrays(
                    unpackArray([0x9F, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E]b, 0)[0] as Array<MsgPackObject>,
                    [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14]
                ));
                return true;
            }

            (:test)
            function testArray16(logger as Logger) as Boolean {
                Test.assert(equalArrays(
                    unpackArray([0xDC, 0x00, 0x11, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10]b, 0)[0] as Array<MsgPackObject>,
                    [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]
                ));
                return true;
            }

            (:test)
            function testBin8(logger as Logger) as Boolean {
                // TODO: need to implement these tests
                return false;
            }

            (:test)
            function testBin16(logger as Logger) as Boolean {
                // TODO: need to implement these tests
                return false;
            }

            (:test)
            function testBin32(logger as Logger) as Boolean {
                // TODO: need to implement these tests
                return false;
            }

            (:test)
            function testBoolean(logger as Logger) as Boolean {
                Test.assert((unpackBoolean([0xC2]b, 0)[0] as Boolean) == false);
                Test.assert((unpackBoolean([0xC3]b, 0)[0] as Boolean) == true);
                try {
                    unpackNull([0xC2, 0x00]b, 0);
                    return false;
                }
                catch (ex instanceof MalformedFormatException) {
                    // all good; an exception should be thrown as there are extra bytes
                }
                try {
                    unpackNull([0x00]b, 0);
                    return false;
                }
                catch (ex instanceof MalformedFormatException) {
                    // all good; an exception should be thrown as 0x00 is not a valid boolean value
                }
                return true;
            }

            (:test)
            function testNull(logger as Logger) as Boolean {
                var parseResults;

                parseResults = unpackNull([0xC0]b, 0);
                Test.assert(parseResults[0] == null && parseResults[1] == 1);

                try {
                    unpack([0xC0, 0x00]b);
                    return false;
                }
                catch (ex instanceof MalformedFormatException) {
                    // all good, an exception should be thrown as there are extra bytes
                }
                return true;
            }


            (:test)
            function testFixMap(logger as Logger) as Boolean {
                Test.assert(equalDictionaries(unpackDictionary([0x80]b, 0)[0] as Dictionary, {}));
                Test.assert(equalDictionaries(unpackDictionary([0x81, 0xA1, 0x78, 0x0D]b, 0)[0] as Dictionary, {"x" => 13}));
                Test.assert(equalDictionaries(
                    unpackDictionary([0x85, 0xA1, 0x61, 0x00, 0xA1, 0x62, 0x01, 0xA1, 0x63, 0xA1, 0x61, 0xA1, 0x64, 0x03, 0xA1, 0x65, 0x04]b, 0)[0] as Dictionary,
                    { "a" => 0, "b" => 1, "c" => "a", "d" => 3, "e" => 4 }
                ));
                return true;
            }

            (:test)
            function testMap16(logger as Logger) as Boolean {
                Test.assert(equalDictionaries(
                    unpackDictionary([
                        0xDE, 0x00, 0x10,
                        0xA1, 0x61, 0x00, 0xA1, 0x62, 0x01, 0xA1, 0x63, 0x02, 0xA1, 0x64, 0x03,
                        0xA1, 0x65, 0x04, 0xA1, 0x66, 0x05, 0xA1, 0x67, 0x06, 0xA1, 0x68, 0x07,
                        0xA1, 0x69, 0x08, 0xA1, 0x6A, 0x09, 0xA1, 0x6B, 0x0A, 0xA1, 0x6C, 0x0B,
                        0xA1, 0x6D, 0x0C, 0xA1, 0x6E, 0x0D, 0xA1, 0x6F, 0x0E, 0xA1, 0x70, 0x0F
                    ]b, 0)[0] as Dictionary,
                    {
                        "a" => 0, "b" => 1, "c" => 2, "d" => 3,
                        "e" => 4, "f" => 5, "g" => 6, "h" => 7,
                        "i" => 8, "j" => 9, "k" => 10, "l" => 11,
                        "m" => 12, "n" => 13, "o" => 14, "p" => 15
                    }
                ));
                return true;
            }

            (:test)
            function testPosFixInt(logger as Logger) as Boolean {
                Test.assertEqual(unpackNumber([0x00]b, 0)[0], 0);
                Test.assertEqual(unpackNumber([0x38]b, 0)[0], 56);
                Test.assertEqual(unpackNumber([0x7F]b, 0)[0], 127);
                //Test.assertNotEqual(unpackNumber([0x80]b, 0)[0], 128);
                return true;
            }

            (:test)
            function testNegFixInt(logger as Logger) as Boolean {
                Test.assertEqual(unpackNumber([0xFF]b, 0)[0], -1);
                Test.assertEqual(unpackNumber([0xF3]b, 0)[0], -13);
                Test.assertEqual(unpackNumber([0xE1]b, 0)[0], -31);
                Test.assertEqual(unpackNumber([0xE0]b, 0)[0], -32);
                //Test.assertNotEqual(unpackNumber([0xDF]b, 0)[0], -33);
                return true;
            }

            (:test)
            function testUInt8(logger as Logger) as Boolean {
                Test.assertEqual(unpackNumber([0xCC, 0x80]b, 0)[0], 128);
                Test.assertEqual(unpackNumber([0xCC, 0xC9]b, 0)[0], 201);
                Test.assertEqual(unpackNumber([0xCC, 0xFF]b, 0)[0], 255);
                Test.assertNotEqual(unpackNumber([0xCC, 0x01, 0x00]b, 0)[0], 256);
                return true;
            }

            (:test)
            function testUInt16(logger as Logger) as Boolean {
                Test.assertEqual(unpackNumber([0xCD, 0x01, 0x00]b, 0)[0], 256);
                Test.assertEqual(unpackNumber([0xCD, 0xFF, 0xFF]b, 0)[0], 65535);
                Test.assertNotEqual(unpackNumber([0xCD, 0x01, 0xFF, 0xFF]b, 0)[0], 65536);
                Test.assertNotEqual(unpackNumber([0xCD, 0x00, 0x00]b, 0)[0], 65536);
                return true;
            }

            (:test)
            function testUInt32(logger as Logger) as Boolean {
                Test.assertEqual(unpackNumber([0xCE, 0x00, 0x01, 0x00, 0x00]b, 0)[0], 65536);
                Test.assertEqual(unpackNumber([0xCE, 0x00, 0x98, 0x9A, 0x86]b, 0)[0], 10001030);
                Test.assertEqual(unpackNumber([0xCE, 0x7F, 0xFF, 0xFF, 0xFF]b, 0)[0], 2147483647);
                Test.assertEqual(unpackNumber([0xCE, 0x80, 0x00, 0x00, 0x00]b, 0)[0], 2147483648l);
                Test.assertEqual(unpackNumber([0xCE, 0xFF, 0xFF, 0xFF, 0xFF]b, 0)[0], 4294967295l);
                Test.assertNotEqual(unpackNumber([0xCE, 0x01, 0x00, 0x00, 0x00, 0x00]b, 0)[0], 4294967296l);
                return true;
            }

            (:test)
            function testUInt64(logger as Logger) as Boolean {
                Test.assertEqual(unpackNumber([0xCF, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00]b, 0)[0], 4294967296l);
                Test.assertEqual(unpackNumber([0xCF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]b, 0)[0], 9223372036854775807l);
                return true;
            }

            (:test)
            function testInt8(logger as Logger) as Boolean {
                Test.assertEqual(unpackNumber([0xD0, 0x80]b, 0)[0], -128);
                Test.assertEqual(unpackNumber([0xD0, 0x81]b, 0)[0], -127);
                Test.assertEqual(unpackNumber([0xD0, 0x9C]b, 0)[0], -100);
                Test.assertEqual(unpackNumber([0xD0, 0xDF]b, 0)[0], -33);
                Test.assertEqual(unpackNumber([0xD0, 0xE0]b, 0)[0], -32);   // not the best way to do -32 but is allowed (I think)
                // FIXME: this test should be 127
                //Test.assertNotEqual(unpackNumber([0xD0, 0x7F]b, 0)[0], -129);
                return true;
            }

            (:test)
            function testInt16(logger as Logger) as Boolean {
                Test.assertEqual(unpackNumber([0xD1, 0xFF, 0x7F]b, 0)[0], -129);
                Test.assertEqual(unpackNumber([0xD1, 0xC0, 0x00]b, 0)[0], -16384);
                Test.assertEqual(unpackNumber([0xD1, 0x80, 0x00]b, 0)[0], -32768);
                // FIXME: this test should be 32767
                //Test.assertNotEqual(unpackNumber([0xD1, 0x7F, 0xFF]b, 0)[0], -32769);
                return true;
            }

            (:test)
            function testInt32(logger as Logger) as Boolean {
                Test.assertEqual(unpackNumber([0xD2, 0xFF, 0xFF, 0x7F, 0xFF]b, 0)[0], -32769);
                Test.assertEqual(unpackNumber([0xD2, 0xF9, 0xEC, 0xE2, 0x8B]b, 0)[0], -101916021);
                Test.assertEqual(unpackNumber([0xD2, 0x80, 0x00, 0x00, 0x00]b, 0)[0], -2147483648);

                //Test.assertNotEqual(packNumber(-2147483649l), [0xD2, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF]b);
                return true;
            }

            (:test)
            function testInt64(logger as Logger) as Boolean {
                Test.assertEqual(unpackNumber([0xD3, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF]b, 0)[0], -2147483649l);
                Test.assertEqual(unpackNumber([0xD3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]b, 0)[0], -9223372036854775807l);
                Test.assertEqual(unpackNumber([0xD3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]b, 0)[0], -9223372036854775808l);
                return true;
            }

            (:test)
            function testFixStr(logger as Logger) as Boolean {
                var parseResults;
                parseResults = unpackString([0xA0]b, 0);
                Test.assertEqual(parseResults[0], "");

                parseResults = unpackString([0xA6,0x47,0x61,0x72,0x6D,0x69,0x6E]b, 0);
                Test.assertEqual(parseResults[0], "Garmin");

                parseResults = unpackString([0xAF,0x47,0x61,0x72,0x6D,0x69,0x6E,0x20,0x77,0x65,0x61,0x72,0x61,0x62,0x6C,0x65]b, 0);
                Test.assertEqual(parseResults[0], "Garmin wearable");

                return true;
            }

            (:test)
            function testStr8(logger as Logger) as Boolean {
                var parseResults;
                parseResults = unpackString([0xD9,0x10,0x47,0x61,0x72,0x6D,0x69,0x6E,0x20,0x77,0x65,0x61,0x72,0x61,0x62,0x6C,0x65,0x73]b, 0);
                Test.assertEqual(parseResults[0], "Garmin wearables");

                return true;
            }

            (:test)
            function testStr16(logger as Logger) as Boolean {
                var longStrPacked = new [259]b;  // 256 byte string + format byte + 2 byte length
                var longStrUnpacked = "";

                longStrPacked[0] = 0xDA;
                longStrPacked[1] = 0x01;
                longStrPacked[2] = 0x00;

                for (var i=0; i < 256; i++) {
                    longStrPacked[i+3] = 0x61;
                    longStrUnpacked = longStrUnpacked + "a";    // string length of 256 characters, all letter 'a'
                }
                var parseResults = unpackString(longStrPacked, 0);
                Test.assertEqual(parseResults[0], longStrUnpacked);
                return true;
            }

            (:test)
            function testUnpack(logger as Logger) as Boolean {
                Test.assert(unpack([0xC0]b) == null);                   // value: null
                Test.assert((unpack([0xC2]b) as Boolean) == false);     // value: false
                Test.assert((unpack([0xC3]b) as Boolean) == true);      // value: true

                // value: string == "Garmin"
                Test.assertEqual((unpack([0xA6,0x47,0x61,0x72,0x6D,0x69,0x6E]b) as String), "Garmin");

                // value: array == [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]
                Test.assert(equalArrays(
                    unpack([0xDC, 0x00, 0x11, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10]b) as Array<MsgPackObject>,
                    [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16] as Array<MsgPackObject>
                ));

                // test array with map embedded
                Test.assert(equalArrays(
                    unpack([0x95, 0x00, 0x01, 0x82, 0xA1, 0x61, 0x00, 0xA1, 0x62, 0x01, 0x03, 0x04]b) as Array<MsgPackObject>,
                    [0, 1, {"a" => 0, "b" => 1}, 3, 4] as Array<MsgPackObject>
                ));

                // TODO: test array within an array
                Test.assert(equalArrays(
                    unpack([0x95, 0x00, 0x01, 0x93, 0x0A, 0x0B, 0x0C, 0x03, 0x04]b) as Array<MsgPackObject>,
                    [0, 1, [10,11,12], 3, 4] as Array<MsgPackObject>
                ));

                // test map with array embedded
                Test.assert(equalDictionaries(
                    unpack([0x83, 0xA1, 0x61, 0x00, 0xA1, 0x62, 0x93, 0x00, 0x01, 0x02, 0xA1, 0x63, 0x02]b) as Dictionary,
                    { "a" => 0, "b" => [0, 1, 2], "c" => 2 }
                ));

                // test map within a map
                Test.assert(equalDictionaries(
                    unpack([0x82, 0xA1, 0x61, 0x00, 0xA1, 0x62, 0x81, 0xA1, 0x64, 0xA1, 0x65]b) as Dictionary,
                    { "a" => 0, "b" => { "d" => "e"} }
                ));

                // test map with array AND map embedded
                Test.assert(equalDictionaries(
                    unpack([0x83, 0xA1, 0x61, 0x00, 0xA1, 0x62, 0x93, 0x00, 0x01, 0x02, 0xA1, 0x63, 0x81, 0xA1, 0x64, 0xA1, 0x65]b) as Dictionary,
                    { "a" => 0, "b" => [0, 1, 2], "c" => { "d" => "e"} }
                ));

                // FIXME: this fails for some reason...
                // unpack([0x81, 0xA1, 0xC1, 0x0D]b);

                // test that the extra bytes exception is thrown
                try {
                    unpack([0x96, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x11]b);
                    return false;
                }
                catch (ex instanceof MalformedFormatException) {
                    // catching this exception is good; it should throw an extra bytes exception
                    var errorMsg = Lang.format(Application.loadResource(Rez.Strings.exceptionExtraBytes) as String, [1]);
                    Test.assertEqual(ex.getErrorMessage() as String, errorMsg);
                }

                // test that the invalid byte exception is thrown
                try {
                    unpack([0x81, 0xC1, 0x78, 0x0D]b);
                    return false;
                }
                catch (ex instanceof MalformedFormatException) {
                    // catching this exception is good; it should throw an extra bytes exception
                    var errorMsg = Application.loadResource(Rez.Strings.exceptionInvalidByte) as String;
                    Test.assertEqual(ex.getErrorMessage() as String, errorMsg);
                }

                // TODO: test that the unexpected end of buffer (not enough bytes) exception is thrown

                return true;
            }

        }

    }

}
