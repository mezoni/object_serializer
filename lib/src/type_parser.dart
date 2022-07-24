import 'token.dart';
import 'type_info.dart';
import 'type_tokenizer.dart';

class TypeParser {
  String? _source;

  late Token _token;

  late List<Token> _tokens;

  int _pos = 0;

  TypeInfo parse(String source) {
    _source = source;
    final tokenizer = TypeTokenizer();
    _tokens = tokenizer.tokenize(source);
    _reset();

    return _parseType();
  }

  void _match(TokenKind kind) {
    if (_token.kind == kind) {
      _nextToken();
      return;
    }

    throw FormatException(
        'Expected $kind but got $_token.kind}', _source, _token.start);
  }

  Token _nextToken() {
    if (_pos + 1 < _tokens.length) {
      _token = _tokens[++_pos];
    }

    return _token;
  }

  List<TypeInfo> _parseArgs() {
    final result = <TypeInfo>[];
    final type = _parseType();
    result.add(type);
    while (true) {
      if (_token.kind != TokenKind.comma) {
        break;
      }

      _nextToken();
      final type = _parseType();
      result.add(type);
    }

    return result;
  }

  TypeInfo _parseType() {
    final name = _token.text;
    _match(TokenKind.ident);
    var arguments = <TypeInfo>[];
    if (_token.kind == TokenKind.open) {
      _nextToken();
      arguments = _parseArgs();
      _match(TokenKind.close);
    }

    var suffix = '';
    if (_token.kind == TokenKind.question) {
      suffix = _token.toString();
      _nextToken();
    }

    final result = TypeInfo(name: name, suffix: suffix);
    result.arguments.addAll(arguments);
    return result;
  }

  void _reset() {
    _pos = 0;
    _token = _tokens[0];
  }
}
