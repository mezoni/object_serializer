class Deserializer {
  Map<int, Object?> _cache = {};

  final ObjectSerializerCollection _collection;

  int _offset = 0;

  List _stream = [];

  Deserializer({
    required ObjectSerializerCollection collection,
  }) : _collection = collection;

  T deserialize<T>(List stream) {
    _reset(stream);
    final result = readObject<T>();
    _cleanup();
    return result;
  }

  List<T> deserializeList<T>(List stream) {
    _reset(stream);
    final result = readList<T>();
    _cleanup();
    return result;
  }

  Map<K, V> deserializeMap<K, V>(List stream) {
    _reset(stream);
    final result = readMap<K, V>();
    _cleanup();
    return result;
  }

  MapEntry<K, V> deserializeMapEntry<K, V>(List stream) {
    _reset(stream);
    final result = readMapEntry<K, V>();
    _cleanup();
    return result;
  }

  Set<T> deserializeSet<T>(List stream) {
    _reset(stream);
    final result = readSet<T>();
    _cleanup();
    return result;
  }

  List<T> readList<T>() {
    final offset = readRaw<int>();
    if (_isInCache(offset)) {
      final object = _readFromCache(offset);
      return _check(object);
    }

    _expectedTag(_getKnownTypeTag(KnownType.listType));
    final result = _readList<T>();
    _cache[offset] = result;
    return result;
  }

  Map<K, V> readMap<K, V>() {
    final offset = readRaw<int>();
    if (_isInCache(offset)) {
      final object = _readFromCache(offset);
      return _check(object);
    }

    _expectedTag(_getKnownTypeTag(KnownType.mapType));
    final result = _readMap<K, V>();
    _cache[offset] = result;
    return result;
  }

  MapEntry<K, V> readMapEntry<K, V>() {
    final offset = readRaw<int>();
    if (_isInCache(offset)) {
      final object = _readFromCache(offset);
      return _check(object);
    }

    _expectedTag(_getKnownTypeTag(KnownType.mapEntryType));
    final result = _readMapEntry<K, V>();
    _cache[offset] = result;
    return result;
  }

  T readObject<T>() {
    final offset = readRaw<int>();
    if (_isInCache(offset)) {
      final object = _readFromCache(offset);
      return _check(object);
    }

    final tag = _readTag();
    Object? object;
    final knownTypeTag = _collection.tryGetKnownType(tag);
    if (knownTypeTag != null) {
      switch (knownTypeTag) {
        case KnownType.nullType:
          break;
        case KnownType.boolType:
        case KnownType.doubleType:
        case KnownType.intType:
        case KnownType.stringType:
          object = readRaw();
          break;
        case KnownType.listType:
          object = _readList();
          break;
        case KnownType.mapType:
          object = _readMap();
          break;
        case KnownType.mapEntryType:
          object = _readMapEntry();
          break;
        case KnownType.setType:
          object = _readSet();
          break;
      }
    } else {
      final serializer = _collection.getSerializer<T>(tag);
      object = serializer.deserialize(this);
    }

    _cache[offset] = object;
    return _check(object);
  }

  T readRaw<T>() {
    final value = _getNext();
    if (value is T) {
      return value;
    }

    throw StateError(
        'Unable to deserialize. Expected raw value of type $T, but got ${value.runtimeType}');
  }

  Set<T> readSet<T>() {
    final offset = readRaw<int>();
    if (_isInCache(offset)) {
      final object = _readFromCache(offset);
      return _check(object);
    }

    _expectedTag(_getKnownTypeTag(KnownType.setType));
    final result = _readSet<T>();
    _cache[offset] = result;
    return result;
  }

  T _check<T>(Object? object) {
    if (object is T) {
      return object;
    }

    throw StateError(
        'Unable to deserialize. Expected raw value of type $T, but got ${object.runtimeType}');
  }

  void _checkEos() {
    if (_offset != _stream.length) {
      throw StateError(
          'Unable to deserialize. Expected end of stream (${_stream.length}) but got $_offset');
    }
  }

  void _cleanup() {
    _checkEos();
    _cache = {};
    _stream = [];
  }

  void _expectedTag(int tag) {
    final result = _readTag();
    if (tag != result) {
      throw StateError(
          'Unable to deserialize. Expected tag: $tag but got $result');
    }
  }

  int _getKnownTypeTag(KnownType type) {
    final result = _collection.getKnownTypeTag(type);
    return result;
  }

  Object? _getNext() {
    if (_offset > _stream.length) {
      throw StateError('Unable to deserialize. The data stream has ended');
    }

    return _stream[_offset++];
  }

  bool _isInCache(int offset) {
    final result = _cache.containsKey(offset);
    return result;
  }

  Object? _readFromCache(int offset) {
    final result = _cache[offset];
    return result;
  }

  List<T> _readList<T>() {
    final length = readRaw<int>();
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      final value = readObject<T>();
      result.add(value);
    }

    return result;
  }

  Map<K, V> _readMap<K, V>() {
    final length = readRaw<int>();
    final result = <K, V>{};
    for (var i = 0; i < length; i++) {
      final key = readObject<K>();
      final value = readObject<V>();
      result[key] = value;
    }

    return result;
  }

  MapEntry<K, V> _readMapEntry<K, V>() {
    final key = readObject<K>();
    final value = readObject<V>();
    final result = MapEntry(key, value);
    return result;
  }

  Set<T> _readSet<T>() {
    final length = readRaw<int>();
    final result = <T>{};
    for (var i = 0; i < length; i++) {
      final value = readObject<T>();
      result.add(value);
    }

    return result;
  }

  int _readTag() {
    final result = readRaw<int>();
    return result;
  }

  void _reset(List stream) {
    _cache = {};
    _offset = 0;
    _stream = stream;
  }
}

enum KnownType {
  boolType,
  doubleType,
  intType,
  listType,
  mapType,
  mapEntryType,
  nullType,
  setType,
  stringType,
}

class ListSerializer<E> extends ObjectSerializer<List<E>> {
  @override
  List<E> deserialize(Deserializer deserializer) {
    final result = <E>[];
    final int length = deserializer.readRaw();
    for (var i = 0; i < length; i++) {
      result.add(deserializer.readObject());
    }

    return result;
  }

  @override
  void serialize(Serializer serializer, List<E> object) {
    serializer.writeRaw(object.length);
    for (final element in object) {
      serializer.writeObject(element);
    }
  }
}

class MapEntrySerializer<K, V> extends ObjectSerializer<MapEntry<K, V>> {
  @override
  MapEntry<K, V> deserialize(Deserializer deserializer) {
    final K key = deserializer.readObject();
    final V value = deserializer.readObject();
    final result = MapEntry(key, value);
    return result;
  }

  @override
  void serialize(Serializer serializer, MapEntry<K, V> object) {
    serializer.writeObject(object.key);
    serializer.writeObject(object.value);
  }
}

class MapSerializer<K, V> extends ObjectSerializer<Map<K, V>> {
  @override
  Map<K, V> deserialize(Deserializer deserializer) {
    final result = <K, V>{};
    final int length = deserializer.readRaw();
    for (var i = 0; i < length; i++) {
      final K key = deserializer.readObject();
      result[key] = deserializer.readObject();
    }

    return result;
  }

  @override
  void serialize(Serializer serializer, Map<K, V> object) {
    serializer.writeRaw(object.length);
    for (final entry in object.entries) {
      serializer.writeObject(entry.key);
      serializer.writeObject(entry.value);
    }
  }
}

abstract class ObjectSerializer<T> {
  bool canSerialize(Object? object) => object is T;

  T deserialize(Deserializer deserializer);

  void serialize(Serializer serializer, T object);
}

class ObjectSerializerCollection {
  final List<ObjectSerializer> _serializerList = [];

  final Map<Type, int> _types = {};

  void addSerializer<T>(ObjectSerializer<T> serializer) {
    if (_types.containsKey(T)) {
      throw ArgumentError('Serializer for type $T already exists');
    }

    final tag = _serializerList.length + _getStartTag();
    _serializerList.add(serializer);
    _types[T] = tag;
  }

  int getKnownTypeTag(KnownType knownType) {
    return knownType.index;
  }

  ObjectSerializer<T> getSerializer<T>(int tag) {
    final index = tag - _getStartTag();
    if (index < 0 || index >= _serializerList.length) {
      throw StateError('Object serializer not found: $tag');
    }

    final result = _serializerList[index];
    return _cast(result);
  }

  int? getTag<T>() {
    final result = tryGetTag<T>();
    if (result != null) {
      return result;
    }

    throw StateError('Object serializer for $T type not found');
  }

  int getTagFor(Object? object) {
    final result = tryGetTagFor(object);
    if (result != null) {
      return result;
    }

    throw StateError('Object serializer tag not found: ${object.runtimeType}');
  }

  KnownType? tryGetKnownType(int tag) {
    const values = KnownType.values;
    if (tag < 0 || tag >= values.length) {
      return null;
    }

    final result = values[tag];
    return result;
  }

  int? tryGetTag<T>() {
    final result = _types[T];
    return result;
  }

  int? tryGetTagFor(Object? object) {
    for (var i = 0; i < _serializerList.length; i++) {
      final serializer = _serializerList[i];
      if (serializer.canSerialize(object)) {
        final result = KnownType.values.length + i;
        return result;
      }
    }

    return null;
  }

  ObjectSerializer<T> _cast<T>(ObjectSerializer serializer) {
    if (serializer is ObjectSerializer<T>) {
      return serializer;
    }

    throw StateError(
        'Unable to cast ${serializer.runtimeType} to ObjectSerializer<$T>');
  }

  int _getStartTag() {
    return KnownType.values.length;
  }
}

class Serializer {
  final ObjectSerializerCollection _collection;

  Map<Object?, int> _objects = {};

  List _stream = [];

  Serializer({
    required ObjectSerializerCollection collection,
  }) : _collection = collection;

  T deserialize<T>() {
    throw UnimplementedError();
  }

  List serialize<T>(T object) {
    _reset();
    writeObject(object);
    final result = _stream;
    _reset();
    return result;
  }

  List serializeList<T>(List<T> object) {
    _reset();
    writeList(object);
    final result = _stream;
    _reset();
    return result;
  }

  List serializeMap<K, V>(Map<K, V> object) {
    _reset();
    writeMap(object);
    final result = _stream;
    _reset();
    return result;
  }

  List serializeMapEntry<K, V>(MapEntry<K, V> object) {
    _reset();
    writeMapEntry(object);
    final result = _stream;
    _reset();
    return result;
  }

  List serializeSet<T>(Set<T> object) {
    _reset();
    writeSet(object);
    final result = _stream;
    _reset();
    return result;
  }

  void writeList<T>(List<T?> object) {
    if (_writeReference(object)) {
      return;
    }

    _writeList<T>(object);
  }

  void writeMap<K, V>(Map<K?, V?> object) {
    if (_writeReference(object)) {
      return;
    }

    _writeMap<K, V>(object);
  }

  void writeMapEntry<K, V>(MapEntry<K?, V?> object) {
    if (_writeReference(object)) {
      return;
    }

    _writeMapEntry<K, V>(object);
  }

  void writeObject<T>(T? object) {
    if (_writeReference(object)) {
      return;
    }

    if (object == null) {
      _writeKnownTypeTag(KnownType.nullType);
      return;
    } else if (object is bool) {
      _writeKnownTypeTag(KnownType.boolType);
      writeRaw(object);
      return;
    } else if (object is double) {
      _writeKnownTypeTag(KnownType.doubleType);
      writeRaw(object);
      return;
    } else if (object is int) {
      _writeKnownTypeTag(KnownType.intType);
      writeRaw(object);
      return;
    } else if (object is String) {
      _writeKnownTypeTag(KnownType.stringType);
      writeRaw(object);
      return;
    }

    var tag = _collection.tryGetTag<T>();
    tag ??= _collection.tryGetTagFor(object);
    if (tag != null) {
      _writeTag(tag);
      final serializer = _collection.getSerializer<T>(tag);
      serializer.serialize(this, object);
      return;
    }

    if (object is List) {
      _writeList(object);
      return;
    } else if (object is Map) {
      _writeMap(object);
      return;
    } else if (object is MapEntry) {
      _writeMapEntry(object);
      return;
    } else if (object is Set) {
      _writeSet(object);
      return;
    }

    throw StateError('Object serializer not found: ${object.runtimeType}');
  }

  void writeRaw<T>(T? value) {
    _stream.add(value);
  }

  void writeSet<T>(Set<T?> object) {
    if (_writeReference(object)) {
      return;
    }

    _writeSet<T>(object);
  }

  void _reset() {
    _objects = {};
    _stream = [];
  }

  void _writeKnownTypeTag(KnownType knownType) {
    final tag = _collection.getKnownTypeTag(knownType);
    _writeTag(tag);
  }

  void _writeList<T>(List<T?> object) {
    final tag = _collection.getKnownTypeTag(KnownType.listType);
    _writeTag(tag);
    writeRaw(object.length);
    for (var i = 0; i < object.length; i++) {
      final element = object[i];
      writeObject(element);
    }
  }

  void _writeMap<K, V>(Map<K?, V?> object) {
    final tag = _collection.getKnownTypeTag(KnownType.mapType);
    _writeTag(tag);
    writeRaw(object.length);
    final keys = object.keys.toList();
    final values = object.values.toList();
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final value = values[i];
      writeObject(key);
      writeObject(value);
    }
  }

  void _writeMapEntry<K, V>(MapEntry<K?, V?> object) {
    final tag = _collection.getKnownTypeTag(KnownType.mapEntryType);
    _writeTag(tag);
    writeObject(object.key);
    writeObject(object.value);
  }

  bool _writeReference(Object? object) {
    var offset = _objects[object];
    if (offset != null) {
      writeRaw(offset);
      return true;
    }

    offset = _stream.length + 1;
    _objects[object] = offset;
    writeRaw(offset);
    return false;
  }

  void _writeSet<T>(Set<T?> object) {
    final tag = _collection.getKnownTypeTag(KnownType.setType);
    _writeTag(tag);
    writeRaw(object.length);
    for (final element in object) {
      writeObject(element);
    }
  }

  void _writeTag(int tag) {
    writeRaw(tag);
  }
}

class SetSerializer<E> extends ObjectSerializer<Set<E>> {
  @override
  Set<E> deserialize(Deserializer deserializer) {
    final result = <E>{};
    final int length = deserializer.readRaw();
    for (var i = 0; i < length; i++) {
      result.add(deserializer.readObject());
    }

    return result;
  }

  @override
  void serialize(Serializer serializer, Set<E> object) {
    serializer.writeRaw(object.length);
    for (final element in object) {
      serializer.writeObject(element);
    }
  }
}
