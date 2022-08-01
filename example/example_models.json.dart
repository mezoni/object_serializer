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
  Baz({required this.date});

  factory Baz.fromJson(Map json) {
    return Baz(
      date: _DateTimeSerializer.deserialize(json['date']),
    );
  }

  final DateTime date;

  static List<Baz> fromJsonList(List json) {
    return json.map((e) => Baz.fromJson(e as Map)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'date': _DateTimeSerializer.serialize(date),
    };
  }

  static List<Map<String, dynamic>> toJsonList(List<Baz> list) {
    return list.map((e) => e.toJson()).toList();
  }
}

class Response<T> {
  Response({required this.data});

  factory Response.fromJson(Map json) {
    return Response(
      data: (x) {
        return _Generic.deserialize<T>(x as Map);
      }(json['data']),
    );
  }

  final T data;

  static List<Response> fromJsonList(List json) {
    return json.map((e) => Response.fromJson(e as Map)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'data': (x) {
        return (data as dynamic).toJson;
      }(data),
    };
  }

  static List<Map<String, dynamic>> toJsonList(List<Response> list) {
    return list.map((e) => e.toJson()).toList();
  }
}

class _DateTimeSerializer {
  static DateTime deserialize(Object? value) {
    final json = value as String;
    return DateTime.fromMicrosecondsSinceEpoch(int.parse(json));
  }

  static Object? serialize(DateTime value) {
    return value.microsecondsSinceEpoch.toString();
  }
}

class _Generic {
  static T deserialize<T>(Map json) {
    const types = {Bar: Bar.fromJson, Baz: Baz.fromJson, Foo: Foo.fromJson};
    final fromJson = types[T];
    if (fromJson != null) {
      return fromJson(json) as T;
    }

    throw StateError('Unable to deserialize type $T');
  }
}
