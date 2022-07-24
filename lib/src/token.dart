class Token {
  final TokenKind kind;

  final int start;

  final String text;

  Token({required this.kind, required this.start, required this.text});

  @override
  String toString() => text;
}

enum TokenKind { close, comma, eof, ident, open, question }
