import 'package:object_serializer/object_serializer.dart';
import 'package:object_serializer/serialize.dart';
import 'package:test/test.dart';

void main() {
  _testCustom();
  _testList();
  _testMap();
  _testObject();
  _testSet();
}

final _collection = _createCollection();

ObjectSerializerCollection _createCollection() {
  final result = ObjectSerializerCollection();
  result.addSerializer(_BigIntSerializer());
  result.addSerializer(_FooIntSerializer());
  result.addSerializer(MapSerializer<BigInt, Uri?>());
  result.addSerializer(_UriSerializer());
  return result;
}

void _testCustom() {
  test('Custom', () {
    {
      final object = BigInt.parse('1234567890');
      final stream = serialize(object, _collection);
      final result = deserialize(stream, _collection);
      expect(result, object);
    }

    {
      final map1 = {
        BigInt.parse('123'): Uri.parse('foo'),
        BigInt.parse('456'): Uri.parse('baz'),
      };
      final map2 = {
        BigInt.parse('-123'): Uri.parse('foo!'),
        BigInt.parse('456'): null,
        BigInt.parse('123'): Uri.parse('foo'),
      };

      final object = Foo(bigIntUriMap: [
        map1,
        map2,
        map1,
      ]);
      final stream = serialize(object, _collection);
      final result = deserialize(stream, _collection);
      expect(result, isA<Foo>());
      final result1 = result as Foo;
      expect(result1.bigIntUriMap, object.bigIntUriMap);
    }
  });
}

void _testList() {
  test(
    'List',
    () {
      {
        final object = [
          Uri.parse('package:path/path.dart'),
          Uri.parse('package:test/test.dart'),
        ];
        final stream = serializeList(object, _collection);
        final List<Uri> result = deserializeList(stream, _collection);
        expect(result, isA<List<Uri>>());
        expect(result, object);
      }
    },
  );
}

void _testMap() {
  test(
    'Map',
    () {
      {
        final object = {
          BigInt.parse('123'): Uri.parse('package:path/path.dart'),
          BigInt.parse('345'): Uri.parse('package:test/test.dart'),
        };
        final stream = serializeMap(object, _collection);
        final Map<BigInt, Uri> result = deserializeMap(stream, _collection);
        expect(result, isA<Map<BigInt, Uri>>());
        expect(result, object);
      }
    },
  );
}

void _testObject() {
  test('Object', () {
    {
      final object = [
        1,
        2,
        1,
        [
          2,
          [1]
        ]
      ];
      final stream = serialize(object, _collection);
      final result = deserialize(stream, _collection);
      expect(result, object);
    }

    {
      final object = [
        Uri.parse('package:test/test.dart'),
        2,
        1,
        [
          2,
          [Uri.parse('package:test/test.dart')]
        ]
      ];
      final stream = serialize(object, _collection);
      final result = deserialize(stream, _collection);
      expect(result, object);
    }
  });
}

void _testSet() {
  test(
    'Set',
    () {
      {
        final object = {
          Uri.parse('package:path/path.dart'),
          Uri.parse('package:test/test.dart'),
        };
        final stream = serializeSet(object, _collection);
        final Set<Uri> result = deserializeSet(stream, _collection);
        expect(result, isA<Set<Uri>>());
        expect(result, object);
      }
    },
  );
}

class Foo {
  List<Map<BigInt, Uri?>> bigIntUriMap;

  Foo({
    required this.bigIntUriMap,
  });
}

class _BigIntSerializer extends ObjectSerializer<BigInt> {
  @override
  BigInt deserialize(Deserializer deserializer) {
    return BigInt.parse(deserializer.readObject());
  }

  @override
  void serialize(Serializer serializer, BigInt object) {
    serializer.writeObject(object.toString());
  }
}

class _FooIntSerializer extends ObjectSerializer<Foo> {
  @override
  Foo deserialize(Deserializer deserializer) {
    return Foo(
      bigIntUriMap: deserializer.readList(),
    );
  }

  @override
  void serialize(Serializer serializer, Foo object) {
    serializer.writeList(object.bigIntUriMap);
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
