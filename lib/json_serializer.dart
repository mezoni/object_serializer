final _primitiveTypes = () {
  final result = {bool, double, int, num, String};
  void f1<R>(R o) {
    result.add(R);
  }

  void f2<R>([R? object]) {
    f1(object);
  }

  f2<bool>();
  f2<double>();
  f2<int>();
  f2<num>();
  f2<String>();
  return result;
}();

T deserialize<T>(
  Object? value,
  JsonSerializerCollection collection, {
  bool isNullable = true,
}) {
  final deserializer = Deserializer(
    collection: collection,
    isNullable: isNullable,
  );
  final result = deserializer.deserialize<T>(value);
  return result;
}

List<T> deserializeList<T>(
  Object? value,
  JsonSerializerCollection collection, {
  bool isNullable = true,
}) {
  final deserializer = Deserializer(
    collection: collection,
    isNullable: isNullable,
  );
  final result = deserializer.deserializeList<T>(value);
  return result;
}

Map<String, T> deserializeMap<T>(
  Object? value,
  JsonSerializerCollection collection, {
  bool isNullable = true,
}) {
  final deserializer = Deserializer(
    collection: collection,
    isNullable: isNullable,
  );
  final result = deserializer.deserializeMap<T>(value);
  return result;
}

Object? serialize<T>(T value, JsonSerializerCollection collection) {
  final serializer = Serializer(collection: collection);
  final result = serializer.serialize<T>(value);
  return result;
}

List serializeList<T>(List<T> value, JsonSerializerCollection collection) {
  final serializer = Serializer(collection: collection);
  final result = serializer.serializeList(value);
  return result;
}

Map serializeMap<T>(Map<String, T> value, JsonSerializerCollection collection) {
  final serializer = Serializer(collection: collection);
  final result = serializer.serializeMap(value);
  return result;
}

class Deserializer {
  final JsonSerializerCollection _collection;

  final bool _isNullable;

  Deserializer({
    required JsonSerializerCollection collection,
    bool isNullable = true,
  })  : _collection = collection,
        _isNullable = isNullable;

  T deserialize<T>(Object? value) {
    if (_primitiveTypes.contains(T)) {
      return _cast(value);
    } else {
      {
        final serializer1 = _collection.tryGetSerializer<T>();
        if (serializer1 != null) {
          final result = serializer1.deserialize(this, value);
          return result;
        }

        final serializer2 = _collection.tryGetNullableSerializer<T>();
        if (serializer2 == null) {
          throw StateError(
              'Unable to deserialize value ${value.runtimeType} to type $T');
        }

        if (value == null) {
          return _cast(null);
        }

        final result = serializer2.deserialize(this, value);
        return result;
      }
    }
  }

  List<T> deserializeList<T>(Object? value) {
    JsonSerializer<T>? serializer;
    if (!_primitiveTypes.contains(T)) {
      serializer = _collection.getSerializer<T>();
    }

    if (value == null && !_isNullable) {
      return [];
    }

    final list = _cast<List>(value);
    final result = <T>[];
    for (var i = 0; i < list.length; i++) {
      final element = list[i];
      if (serializer != null) {
        final val = serializer.deserialize(this, element);
        result.add(val);
      } else {
        result.add(_cast(element));
      }
    }

    return result;
  }

  Map<String, T> deserializeMap<T>(Object? value) {
    JsonSerializer<T>? serializer;
    if (!_primitiveTypes.contains(T)) {
      serializer = _collection.getSerializer<T>();
    }

    if (value == null && !_isNullable) {
      return <String, T>{};
    }

    final map = _cast<Map>(value);
    final result = <String, T>{};
    final entries = <MapEntry<String, T>>[];
    for (final entry in map.entries) {
      final key = _cast<String>(entry.key);
      final val = entry.value;
      if (serializer != null) {
        final v = serializer.deserialize(this, val);
        entries.add(MapEntry(key, v));
      } else {
        entries.add(MapEntry(key, _cast(val)));
      }
    }

    result.addEntries(entries);
    return result;
  }

  T _cast<T>(Object? value) {
    if (value is T) {
      return value;
    }

    if (value == null && !_isNullable) {
      const defaultValues = {
        bool: false,
        double: 0.0,
        int: 0,
        num: 0,
        String: '',
      };

      final defaultValue = defaultValues[T];
      if (defaultValue is T) {
        return defaultValue;
      }
    }

    throw StateError('Unable to cast value ${value.runtimeType} to type $T');
  }
}

abstract class JsonSerializer<T> {
  R cast<R>(Object? value) {
    if (value is R) {
      return value;
    }

    throw StateError('Unable to cast value ${value.runtimeType} to type $R');
  }

  T deserialize(Deserializer deserializer, Object? value);

  Object? serialize(Serializer serializer, T value);
}

class JsonSerializerCollection {
  final Map<Type, JsonSerializer> _serializers = {};

  final Map<Type, Type> _nullableTypes = {};

  void addSerializer<T>(JsonSerializer<T> serializer) {
    if (_serializers.containsKey(T)) {
      throw ArgumentError('Serializer for type $T already exists');
    }

    _serializers[T] = serializer;
    void f1<R>(R o) {
      _nullableTypes[R] = T;
    }

    void f2<R>(R? object) {
      f1(object);
    }

    f2<T>(null);
  }

  JsonSerializer<T> getSerializer<T>() {
    final serializer = _serializers[T];
    if (serializer != null) {
      return _cast(serializer);
    }

    throw StateError('JSON serializer for type $T not found');
  }

  JsonSerializer<T>? tryGetNullableSerializer<T>() {
    final type = _nullableTypes[T];
    if (type != null) {
      final serializer = _serializers[type];
      if (serializer != null) {
        return _cast(serializer);
      }
    }

    return null;
  }

  JsonSerializer<T>? tryGetSerializer<T>() {
    final serializer = _serializers[T];
    if (serializer != null) {
      return _cast(serializer);
    }

    return null;
  }

  JsonSerializer<T> _cast<T>(JsonSerializer serializer) {
    if (serializer is JsonSerializer<T>) {
      return serializer;
    }

    throw StateError(
        'Unable to cast ${serializer.runtimeType} to JsonSerializer<$T>');
  }
}

class ListSerializer<T> extends JsonSerializer<List<T>> {
  @override
  List<T> deserialize(Deserializer deserializer, Object? value) {
    final list = cast<List>(value);
    final result = <T>[];
    for (var i = 0; i < list.length; i++) {
      final element = list[i];
      final T val = deserializer.deserialize(element);
      result.add(val);
    }

    return result;
  }

  @override
  Object? serialize(Serializer serializer, List<T> value) {
    final result = [];
    for (var i = 0; i < value.length; i++) {
      final element = value[i];
      final val = serializer.serialize(element);
      result.add(val);
    }

    return result;
  }
}

class MapSerializer<T> extends JsonSerializer<Map<String, T>> {
  @override
  Map<String, T> deserialize(Deserializer deserializer, Object? value) {
    final map = cast<Map>(value);
    final entries = <MapEntry<String, T>>[];
    final result = <String, T>{};
    for (final entry in map.entries) {
      final String key = cast(entry.key);
      final T val = deserializer.deserialize(entry.value);
      entries.add(MapEntry(key, val));
    }

    result.addEntries(entries);
    return result;
  }

  @override
  Object? serialize(Serializer serializer, Map<String, T> value) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final val = serializer.serialize(entry.value);
      result[key] = val;
    }

    return result;
  }
}

class Serializer {
  final JsonSerializerCollection _collection;

  Serializer({
    required JsonSerializerCollection collection,
  }) : _collection = collection;

  Object? serialize<T>(T value) {
    if (value is num || value is String || value is bool || value == null) {
      return value;
    } else {
      final serializer1 = _collection.tryGetSerializer<T>();
      if (serializer1 != null) {
        final result = serializer1.serialize(this, value);
        return result;
      }

      final serializer2 = _collection.tryGetNullableSerializer<T>();
      if (serializer2 == null) {
        throw StateError('Unable to serialize value $T');
      }

      final result = serializer2.serialize(this, value);
      return result;
    }
  }

  List serializeList<T>(List<T> value) {
    JsonSerializer<T>? serializer;
    if (!_primitiveTypes.contains(T)) {
      serializer = _collection.getSerializer<T>();
    }

    final result = [];
    for (var i = 0; i < value.length; i++) {
      final element = value[i];
      if (serializer != null) {
        final val = serializer.serialize(this, element);
        result.add(val);
      } else {
        result.add(element);
      }
    }

    return result;
  }

  Map<String, dynamic> serializeMap<T>(Map<String, T> value) {
    JsonSerializer<T>? serializer;
    if (!_primitiveTypes.contains(T)) {
      serializer = _collection.getSerializer<T>();
    }

    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final val = entry.value;
      if (serializer != null) {
        final v = serializer.serialize(this, val);
        result[key] = v;
      } else {
        result[key] = val;
      }
    }

    return result;
  }
}
