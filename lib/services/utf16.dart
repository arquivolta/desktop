// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

class Utf16 extends Encoding {
  final _decoder = const _Utf16Decoder();
  final _encoder = const _Utf16Encoder();

  @override
  Converter<List<int>, String> get decoder => _decoder;

  @override
  Converter<String, List<int>> get encoder => _encoder;

  @override
  String get name => 'utf16';
}

class _Utf16Encoder extends Converter<String, List<int>> {
  const _Utf16Encoder();

  @override
  List<int> convert(String input) => encodeUtf16le(input);
}

class _Utf16Decoder extends Converter<List<int>, String> {
  const _Utf16Decoder();

  @override
  String convert(List<int> input) {
    final bd = ByteData(input.length);
    bd.buffer.asUint8List().setAll(0, input);

    final ret = String.fromCharCodes(bd.buffer.asUint16List());
    return ret;
  }
}

/// Invalid codepoints or encodings may be substituted with the value U+fffd.
const int _UNICODE_REPLACEMENT_CHARACTER_CODEPOINT = 0xfffd;

const int _UNICODE_BYTE_ZERO_MASK = 0xff;
const int _UNICODE_BYTE_ONE_MASK = 0xff00;

const int _UNICODE_VALID_RANGE_MAX = 0x10ffff;
const int _UNICODE_PLANE_ONE_MAX = 0xffff;

const int _UNICODE_UTF16_RESERVED_LO = 0xd800;
const int _UNICODE_UTF16_RESERVED_HI = 0xdfff;
const int _UNICODE_UTF16_OFFSET = 0x10000;
const int _UNICODE_UTF16_SURROGATE_UNIT_0_BASE = 0xd800;
const int _UNICODE_UTF16_SURROGATE_UNIT_1_BASE = 0xdc00;
const int _UNICODE_UTF16_HI_MASK = 0xffc00;
const int _UNICODE_UTF16_LO_MASK = 0x3ff;

/// Produce a list of UTF-16LE encoded bytes. This method produces UTF-16LE
/// bytes with no BOM.
List<int> encodeUtf16le(String str) {
  final utf16CodeUnits = _stringToUtf16CodeUnits(str);
  final encoding = List<int>.filled(2 * utf16CodeUnits.length, -1);
  var i = 0;
  for (final unit in utf16CodeUnits) {
    encoding[i++] = unit & _UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = (unit & _UNICODE_BYTE_ONE_MASK) >> 8;
  }
  return encoding;
}

List<int> _stringToUtf16CodeUnits(String str) {
  return codepointsToUtf16CodeUnits(str.codeUnits);
}

/// Encode code points as UTF16 code units.
List<int> codepointsToUtf16CodeUnits(
  List<int> codepoints, {
  int offset = 0,
  int? length,
  int replacementCodepoint = _UNICODE_REPLACEMENT_CHARACTER_CODEPOINT,
}) {
  final listRange = codepoints;
  var encodedLength = 0;
  for (final value in listRange) {
    if ((value >= 0 && value < _UNICODE_UTF16_RESERVED_LO) ||
        (value > _UNICODE_UTF16_RESERVED_HI &&
            value <= _UNICODE_PLANE_ONE_MAX)) {
      encodedLength++;
    } else if (value > _UNICODE_PLANE_ONE_MAX &&
        value <= _UNICODE_VALID_RANGE_MAX) {
      encodedLength += 2;
    } else {
      encodedLength++;
    }
  }

  final codeUnitsBuffer = List<int>.filled(encodedLength, -1);
  var j = 0;
  for (final value in listRange) {
    if ((value >= 0 && value < _UNICODE_UTF16_RESERVED_LO) ||
        (value > _UNICODE_UTF16_RESERVED_HI &&
            value <= _UNICODE_PLANE_ONE_MAX)) {
      codeUnitsBuffer[j++] = value;
    } else if (value > _UNICODE_PLANE_ONE_MAX &&
        value <= _UNICODE_VALID_RANGE_MAX) {
      final base = value - _UNICODE_UTF16_OFFSET;
      codeUnitsBuffer[j++] = _UNICODE_UTF16_SURROGATE_UNIT_0_BASE +
          ((base & _UNICODE_UTF16_HI_MASK) >> 10);
      codeUnitsBuffer[j++] = _UNICODE_UTF16_SURROGATE_UNIT_1_BASE +
          (base & _UNICODE_UTF16_LO_MASK);
    } else {
      codeUnitsBuffer[j++] = replacementCodepoint;
    }
  }
  return codeUnitsBuffer;
}
