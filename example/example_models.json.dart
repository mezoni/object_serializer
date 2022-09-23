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
  Baz({required this.date1, required this.date2, required this.list});

  factory Baz.fromJson(Map json) {
    return Baz(
      date1: _DateTimeSerializer().deserialize(json['date1'] as Object),
      date2: json['date2'] == null
          ? null
          : _DateTimeSerializer().deserialize(json['date2'] as Object),
      list: json['list'] == null
          ? <List<List<BigInt>>>[]
          : (json['list'] as List)
              .map((e) => e == null
                  ? <List<BigInt>>[]
                  : (e as List)
                      .map((e) => e == null
                          ? <BigInt>[]
                          : (e as List)
                              .map((e) =>
                                  _BigIntSerializer().deserialize(e as Object))
                              .toList())
                      .toList())
              .toList(),
    );
  }

  final DateTime date1;

  final DateTime? date2;

  final List<List<List<BigInt>>> list;

  static List<Baz> fromJsonList(List json) {
    return json.map((e) => Baz.fromJson(e as Map)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'date1': _DateTimeSerializer().serialize(date1),
      'date2': date2 == null
          ? null
          : _DateTimeSerializer().serialize(date2 as DateTime),
      'list': list
          .map((e) => e
              .map((e) =>
                  e.map((e) => _BigIntSerializer().serialize(e)).toList())
              .toList())
          .toList(),
    };
  }

  static List<Map<String, dynamic>> toJsonList(List<Baz> list) {
    return list.map((e) => e.toJson()).toList();
  }
}

class _BigIntSerializer {
  const _BigIntSerializer();

  BigInt deserialize(Object value) {
    return BigInt.parse(value as String);
  }

  Object serialize(BigInt value) {
    return value.toString();
  }
}

class _DateTimeSerializer {
  const _DateTimeSerializer();

  DateTime deserialize(Object value) {
    return DateTime.fromMicrosecondsSinceEpoch(int.parse(value as String));
  }

  Object serialize(DateTime value) {
    return value.microsecondsSinceEpoch.toString();
  }
}
