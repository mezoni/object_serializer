import 'token.dart';

class TypeTokenizer {
  static const _eof = 0;

  late int _ch;

  late int _pos;

  late String _source;

  List<Token> tokenize(String source) {
    _source = source;
    final tokens = <Token>[];
    _reset();
    while (true) {
      _white();
      String text;
      TokenKind kind;
      if (_ch == _eof) {
        kind = TokenKind.eof;
        text = '';
        break;
      }

      final start = _pos;
      switch (_ch) {
        case 44:
          text = ',';
          kind = TokenKind.comma;
          _nextCh();
          break;
        case 60:
          text = '<';
          kind = TokenKind.open;
          _nextCh();
          break;
        case 62:
          text = '>';
          kind = TokenKind.close;
          _nextCh();
          break;
        case 63:
          text = '?';
          kind = TokenKind.question;
          _nextCh();
          break;
        default:
          if (_alpha(_ch) || _ch == 36 || _ch == 95) {
            var length = 1;
            _nextCh();
            while (_alphanum(_ch) || _ch == 36 || _ch == 95) {
              length++;
              _nextCh();
            }

            text = source.substring(start, start + length);
            kind = TokenKind.ident;
          } else {
            throw FormatException('Invalid type', source, start);
          }
      }

      final token = Token(kind: kind, start: start, text: text);
      tokens.add(token);
    }

    return tokens;
  }

  bool _alpha(int c) {
    if (c >= 65 && c <= 90 || c >= 97 && c <= 122) {
      return true;
    }

    return false;
  }

  bool _alphanum(int c) {
    if (_alpha(c) || _digit(c)) {
      return true;
    }

    return false;
  }

  bool _digit(int c) {
    if (c >= 48 && c <= 57) {
      return true;
    }

    return false;
  }

  int _nextCh() {
    if (_pos + 1 < _source.length) {
      _ch = _source.codeUnitAt(++_pos);
    } else {
      _ch = _eof;
    }

    return _ch;
  }

  void _reset() {
    _pos = 0;
    _ch = _eof;
    if (_source.isNotEmpty) {
      _ch = _source.codeUnitAt(0);
    }
  }

  void _white() {
    while (true) {
      if (_ch == 32) {
        _nextCh();
      } else {
        break;
      }
    }
  }
}
