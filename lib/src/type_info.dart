class TypeInfo {
  List<TypeInfo> arguments = [];

  final String name;

  final String suffix;

  TypeInfo({
    required this.name,
    this.suffix = '',
  });

  bool get hasSuffix {
    return suffix.isNotEmpty;
  }

  String get nameWithSuffix {
    return '$name$suffix';
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write(name);
    if (arguments.isNotEmpty) {
      sb.write('<');
      final args = <String>[];
      for (var argument in arguments) {
        args.add(argument.toString());
      }

      sb.write(args.join(', '));
      sb.write('>');
    }

    return sb.toString();
  }
}
