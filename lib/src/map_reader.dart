class MapReader {
  final Map map;

  MapReader(this.map);

  T read<T>(String path) {
    final keys = path.split('.');
    if (keys.isEmpty) {
      throw StateError('Keys must not be empty');
    }

    var map = this.map;
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      if (map.containsKey(key)) {
        final value = map[key];
        if (i == keys.length - 1) {
          if (value is T) {
            return value;
          }

          throw StateError(
              "Expected '$T' value but got ${value.runtimeType}: $path");
        }

        if (value is Map) {
          map = value;
        } else {
          break;
        }
      }
    }

    _errorPathNotExists(path);
  }

  T? tryRead<T>(String path, bool checkPath) {
    final keys = path.split('.');
    if (keys.isEmpty) {
      throw StateError('Keys must not be empty');
    }

    var map = this.map;
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      if (map.containsKey(key)) {
        final value = map[key];
        if (i == keys.length - 1) {
          if (value is T) {
            return value;
          }

          return null;
        }

        if (value is Map) {
          map = value;
        } else {
          break;
        }
      }
    }

    if (checkPath) {
      _errorPathNotExists(path);
    }

    return null;
  }

  Never _errorPathNotExists(String path) {
    throw StateError('Unable to read value: $path');
  }
}
