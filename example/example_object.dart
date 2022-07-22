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
