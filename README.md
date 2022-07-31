# object_serializer

A collection of serializers for serializing data in a variety of ways (JSON, Generic Objects).

Version: 0.3.6

Two kinds of data serializers are currently available:  
- JSON serializer
- Object serializer

`JSON serializer` is a serializer to standard JSON format. Serialization is supported for types that can be converted to simpler data types (eg. `BigInt`, `DateTime`, `Duration`, `Uri` etc). The working principle is simple. You yourself choose the method of serialization and deserialization of data, that is, you completely control this process.

`Object serializer` is a serializer (with caching support) of any static (generic) complex data that can be represented as simpler data.

Allows you to implement a serializer for any data that can be transferred between isolates or even over the Internet.  
The principle of operation is very simple, for each data type you need to implement your own object serializer.  

Implementing an object serializer is also very simple. To do this, you need to write the data in a `strict order` and then read this data in `the same order`.

## JSON serializer

`JSON serializer` is a serializer to standard JSON format.  
Let's say that we need to use this data objects to exchange data in JSON format.

```yaml
classes:
  Foo:
    fields:
      bar: Bar
  Bar:
    fields:
      baz: Baz
  Baz:
    fields:
      date:
        type: DateTime

serializers:
  DateTime:
    type: _DateTimeSerializer
    deserialize: |-
      final json = value as String;
      return DateTime.fromMicrosecondsSinceEpoch(int.parse(json));

    serialize: |-
      return value.microsecondsSinceEpoch.toString();

```

Now let's try to generate the code.  
Let's do this through the project build process.  

Let's call this file `example\example_models.json.yaml`.

You need to add dependencies to the `pubspec.yaml` file.

```yaml
dev_dependencies:
  build_runner: any
  object_serializer: ^0.3.6
```

And start the build process:

`dart run build_runner build`

As a result of the `build_runner` operation, the `example\example_models.json.dart` file will be generated.

```dart
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

class _DateTimeSerializer {
  static DateTime deserialize(Object? value) {
    final json = value as String;
    return DateTime.fromMicrosecondsSinceEpoch(int.parse(json));
  }

  static Object? serialize(DateTime value) {
    return value.microsecondsSinceEpoch.toString();
  }
}

```

Second way. Using a generator for this.  
Example of generator script can be found here:  
https://github.com/mezoni/object_serializer/blob/master/example/example_generate_small_example.dart

Example of generated script can be found here:  
https://github.com/mezoni/object_serializer/blob/master/example/small_example.dart

## Object serializer

`Object serializer` is a serializer (with caching support) of any static (generic) complex data that can be represented as simpler data.  
Example of simple object serializer:

```dart
class _UriSerializer extends ObjectSerializer<Uri> {
  @override
  Uri deserialize(Deserializer deserializer) {
    return Uri.parse(deserializer.readObject());
  }

  @override
  void serialize(Serializer serializer, Uri object) {
    serializer.writeObject(object.toString());
  }
}
```

This is not an analogue or replacement for the JSON serializer.  
In this case, the data is serialized into a so-called stream and, if necessary, cached.  

For example, you can serialize such data.  

```dart
typedef _ComplexType = Map<Uri, List<Tuple2<BigInt, Tuple2<int, Base?>>>>;

class A extends Base {
  A(super.base);

  @override
  bool operator ==(other) => other is A && other.base == base;
}

class B extends Base {
  final int x;

  B(super.base, this.x);

  @override
  bool operator ==(other) => other is B && other.base == base && other.x == x;
}

class Base {
  final String base;

  Base(this.base);
}
```

For example, such data can be serialized.

```dart
final _ComplexType map = {
  Uri.parse('package:animals'): [
    Tuple2(BigInt.parse('1'), Tuple2(1, A('Hello'))),
    Tuple2(BigInt.parse('2'), Tuple2(1, A('Hello'))),
  ],
  Uri.parse('package:zoo'): [
    Tuple2(BigInt.parse('1'), Tuple2(1, B('Goodbye', 41))),
    Tuple2(BigInt.parse('2'), Tuple2(2, null)),
    Tuple2(BigInt.parse('1'), Tuple2(1, A('Hello'))),
  ],
};
```

Output data stream:

```dart
[1, 4, 2, 4, 16, 6, 8, package:animals, 9, 9, 2, 12, 11, 14, 15, 16, 8, 1, 19, 12, 21, 2, 1, 24, 13, 26, 8, Hello, 29, 11, 31, 15, 33, 8, 2, 36, 12, 21, 39, 13, 26, 42, 16, 44, 8, package:zoo, 47, 9, 3, 50, 11, 14, 53, 12, 21, 56, 14, 58, 8, Goodbye, 61, 2, 41, 64, 11, 31, 67, 12, 69, 2, 2, 72, 6, 74, 11, 14, 77, 12, 21, 80, 13, 26]
```

Full example:

```dart
import 'dart:isolate';

import 'package:object_serializer/object_serializer.dart';
import 'package:object_serializer/serialize.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

Future<void> main() async {
  test(
    'Example',
    () async {
      final _ComplexType map = {
        Uri.parse('package:animals'): [
          Tuple2(BigInt.parse('1'), Tuple2(1, A('Hello'))),
          Tuple2(BigInt.parse('2'), Tuple2(1, A('Hello'))),
        ],
        Uri.parse('package:zoo'): [
          Tuple2(BigInt.parse('1'), Tuple2(1, B('Goodbye', 41))),
          Tuple2(BigInt.parse('2'), Tuple2(2, null)),
          Tuple2(BigInt.parse('1'), Tuple2(1, A('Hello'))),
        ],
      };

      final stream = serializeMap(map, _collection);

      //
      final port = ReceivePort();
      final isolate =
          await Isolate.spawn<List>(compute, [port.sendPort, stream]);
      final stream2 = await port.first as List;
      isolate.kill(priority: Isolate.immediate);

      //
      final _ComplexType result = deserializeMap(stream2, _collection);
      expect(result, map);
    },
  );
}

final _collection = ObjectSerializerCollection()
  ..addSerializer(ListSerializer<Tuple2<BigInt, Tuple2<int, Base?>>>())
  ..addSerializer(_ASerializer())
  ..addSerializer(_BSerializer())
  ..addSerializer(_BigIntSerializer())
  ..addSerializer(_Tuple2Serializer<BigInt, Tuple2<int, Base?>>())
  ..addSerializer(_Tuple2Serializer<int, Base?>())
  ..addSerializer(_UriSerializer());

void compute(List args) {
  final sendPort = args[0] as SendPort;
  final input = args[1] as List;
  final _ComplexType map = deserializeMap(input, _collection);
  final output = serializeMap(map, _collection);
  sendPort.send(output);
}

typedef _ComplexType = Map<Uri, List<Tuple2<BigInt, Tuple2<int, Base?>>>>;

class A extends Base {
  A(super.base);

  @override
  bool operator ==(other) => other is A && other.base == base;
}

class B extends Base {
  final int x;

  B(super.base, this.x);

  @override
  bool operator ==(other) => other is B && other.base == base && other.x == x;
}

class Base {
  final String base;

  Base(this.base);
}

class _ASerializer extends ObjectSerializer<A> {
  @override
  A deserialize(Deserializer deserializer) {
    return A(
      deserializer.readObject(),
    );
  }

  @override
  void serialize(Serializer serializer, A object) {
    serializer.writeObject(object.base);
  }
}

class _BigIntSerializer extends ObjectSerializer<BigInt> {
  @override
  BigInt deserialize(Deserializer deserializer) {
    return BigInt.parse(deserializer.readObject());
  }

  @override
  void serialize(Serializer serializer, BigInt object) {
    serializer.writeObject('$object');
  }
}

class _BSerializer extends ObjectSerializer<B> {
  @override
  B deserialize(Deserializer deserializer) {
    return B(
      deserializer.readObject(),
      deserializer.readObject(),
    );
  }

  @override
  void serialize(Serializer serializer, B object) {
    serializer.writeObject(object.base);
    serializer.writeObject(object.x);
  }
}

class _Tuple2Serializer<T1, T2> extends ObjectSerializer<Tuple2<T1, T2>> {
  @override
  Tuple2<T1, T2> deserialize(Deserializer deserializer) {
    return Tuple2(
      deserializer.readObject(),
      deserializer.readObject(),
    );
  }

  @override
  void serialize(Serializer serializer, Tuple2<T1, T2> object) {
    serializer.writeObject(object.item1);
    serializer.writeObject(object.item2);
  }
}

class _UriSerializer extends ObjectSerializer<Uri> {
  @override
  Uri deserialize(Deserializer deserializer) {
    return Uri.parse(deserializer.readObject());
  }

  @override
  void serialize(Serializer serializer, Uri object) {
    serializer.writeObject(object.toString());
  }
}

```

For simpler or non-generic data, fewer serializers are required. But, in any case, each data requires its own serializer.

This allows any type of data to be serialized. For example, you can serialize a parsed AST.  
The main goal is to make it easier to write serializers to pass data between isolates.  
