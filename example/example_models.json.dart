class Foo {
  Foo({required this.bar});

  factory Foo.fromJson(Map json) {
    return Foo(
      bar: Bar.fromJson(json['bar'] as Map),
    );
  }

  final Bar bar;

  static List<Foo> fromJsonList(List json) {
    return json.map((e) => Foo.fromJson(e as Map)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'bar': bar.toJson(),
    };
  }

  static List<Map<String, dynamic>> toJsonList(List<Foo> list) {
    return list.map((e) => e.toJson()).toList();
  }
}

class Bar {
  Bar({required this.baz});

  factory Bar.fromJson(Map json) {
    return Bar(
      baz: Baz.fromJson(json['baz'] as Map),
    );
  }

  final Baz baz;

  static List<Bar> fromJsonList(List json) {
    return json.map((e) => Bar.fromJson(e as Map)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'baz': baz.toJson(),
    };
  }

  static List<Map<String, dynamic>> toJsonList(List<Bar> list) {
    return list.map((e) => e.toJson()).toList();
  }
}

class Baz {
  Baz({required this.date1, required this.date2});

  factory Baz.fromJson(Map json) {
    return Baz(
      date1: _Serializer.deserialize<DateTime>(json['date1']),
      date2: _Serializer.deserialize<DateTime?>(json['date2']),
    );
  }

  final DateTime date1;

  final DateTime? date2;

  static List<Baz> fromJsonList(List json) {
    return json.map((e) => Baz.fromJson(e as Map)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'date1': _Serializer.serialize<DateTime>(date1),
      'date2': _Serializer.serialize<DateTime?>(date2),
    };
  }

  static List<Map<String, dynamic>> toJsonList(List<Baz> list) {
    return list.map((e) => e.toJson()).toList();
  }
}

class Response<T1> {
  Response({required this.data1});

  factory Response.fromJson(Map json) {
    return Response(
      data1: _Serializer.deserialize<T1>(json['data1']),
    );
  }

  final T1 data1;

  static List<Response> fromJsonList(List json) {
    return json.map((e) => Response.fromJson(e as Map)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'data1': _Serializer.serialize<T1>(data1),
    };
  }

  static List<Map<String, dynamic>> toJsonList(List<Response> list) {
    return list.map((e) => e.toJson()).toList();
  }
}

class _Serializer {
  static final Map<Type, int> _types = _generateTypes();

  static T deserialize<T>(Object? value) {
    final id = _types[T];
    dynamic result;
    switch (id) {
      case 0:
        result = value == null ? null : Bar.fromJson(value as Map);
        break;
      case 1:
        result = value == null ? null : Baz.fromJson(value as Map);
        break;
      case 2:
        result = value == null ? null : Foo.fromJson(value as Map);
        break;
      case 3:
        result = value == null
            ? null
            : DateTime.fromMicrosecondsSinceEpoch(int.parse(value as String));
        break;
      default:
        throw StateError('Unable to deserialize type $T');
    }

    if (result is T) {
      return result;
    }

    throw StateError("Unable to cast '${result.runtimeType}' value to type $T");
  }

  static Object? serialize<T>(T value) {
    final id = _types[T];
    Object? result;
    switch (id) {
      case 0:
        result = value == null ? null : (value as Bar).toJson();
        break;
      case 1:
        result = value == null ? null : (value as Baz).toJson();
        break;
      case 2:
        result = value == null ? null : (value as Foo).toJson();
        break;
      case 3:
        result = value == null
            ? null
            : (value as DateTime).microsecondsSinceEpoch.toString();
        break;
      default:
        throw StateError('Unable to serialize type $T');
    }

    return result;
  }

  static Map<Type, int> _generateTypes() {
    final result = <Type, int>{};
    void addType<T>(int id) {
      result[T] = id;
    }

    addType<Bar>(0);
    addType<Bar?>(0);
    addType<Baz>(1);
    addType<Baz?>(1);
    addType<Foo>(2);
    addType<Foo?>(2);
    addType<DateTime>(3);
    addType<DateTime?>(3);
    return result;
  }
}
