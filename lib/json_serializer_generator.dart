import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

import 'src/map_reader.dart';
import 'src/type_info.dart';
import 'src/type_parser.dart';

class JsonSerializerGenerator {
  String format(String source) {
    try {
      final formatter = DartFormatter();
      source = formatter.format(source);
    } catch (e) {
      //
    }

    return source;
  }

  String generateClasses(
    Map classes, {
    void Function(ClassBuilder builder, Map classData)? build,
    Map serializers = const {},
  }) {
    final library = Library((b) {
      final classReader = MapReader(classes);
      final serializerReader = MapReader(serializers);
      for (final key in classes.keys) {
        final class_ = Class((b) {
          final className = '$key';
          b.name = className;
          final extend =
              classReader.tryRead<String>('$className.extends', false);
          if (extend != null) {
            b.extend = Reference(extend);
          }

          final typeInfo = _parseType(className);
          _checkTypeHasNoArguments(typeInfo, 'classes.$className');
          _checkTypeHasNoSuffix(typeInfo, 'classes.$className');
          final fieldsData = classReader.read<Map>('$className.fields');
          for (final key in fieldsData.keys) {
            final fieldName = '$key';
            b.fields.add(Field((b) {
              var type = classReader.tryRead<String>(
                  '$className.fields.$fieldName', false);
              if (type == null) {
                type = classReader
                    .read<String>('$className.fields.$fieldName.type');
                final metadata = classReader.tryRead<List>(
                    '$className.fields.$fieldName.metadata', false);
                if (metadata != null) {
                  for (final annotation in metadata) {
                    b.annotations.add(CodeExpression(Code('$annotation')));
                  }
                }
              }

              b.name = fieldName;
              b.type = Reference(type);
              b.modifier = FieldModifier.final$;
            }));
          }

          b.constructors.add(Constructor((b) {
            for (final key in fieldsData.keys) {
              final fieldName = '$key';
              b.optionalParameters.add(Parameter((b) {
                b.required = true;
                b.toThis = true;
                b.name = fieldName;
                b.named = true;
              }));
            }
          }));

          b.constructors.add(Constructor((b) {
            b.name = 'fromJson';
            b.factory = true;
            b.requiredParameters.add(Parameter((b) {
              b.name = 'json';
              b.type = Reference('Map');
            }));

            final code = <String>[];
            code.add('return $className(');
            for (final key in fieldsData.keys) {
              final fieldName = '$key';
              var alias = fieldName;
              String? serializer;
              var type = classReader.tryRead<String>(
                  '$className.fields.$fieldName', false);
              if (type == null) {
                type = classReader
                    .read<String>('$className.fields.$fieldName.type');
                alias = (classReader.tryRead<String>(
                            '$className.fields.$fieldName.alias', false) ??
                        fieldName)
                    .trim();
                serializer = classReader.tryRead(
                    '$className.fields.$fieldName.serializer', false);
              }

              final typeInfo = _parseType(type);
              var value = "json['$alias']";
              if (serializer != null) {
                value = '$serializer.serialize($value)';
              } else {
                value = _deserialize(typeInfo, value, serializerReader);
              }

              code.add("$fieldName: $value,");
            }

            code.add(');');
            b.body = Code(code.join('\n'));
          }));

          b.methods.add(Method((b) {
            b.static = true;
            b.returns = Reference('List<$className>');
            b.name = 'fromJsonList';
            b.requiredParameters.add(Parameter((b) {
              b.name = 'json';
              b.type = Reference('List');
            }));

            final code = <String>[];
            code.add(
                'return json.map((e) => $className.fromJson(e as Map)).toList();');
            b.body = Code(code.join('\n'));
          }));

          b.methods.add(Method((b) {
            b.name = 'toJson';
            b.returns = Reference('Map<String, dynamic>');
            final code = <String>[];
            code.add('return {');
            for (final key in fieldsData.keys) {
              final fieldName = '$key';
              var alias = fieldName;
              String? serializer;
              var type = classReader.tryRead<String>(
                  '$className.fields.$fieldName', false);
              if (type == null) {
                type = classReader
                    .read<String>('$className.fields.$fieldName.type');
                alias = (classReader.tryRead<String>(
                            '$className.fields.$fieldName.alias', false) ??
                        fieldName)
                    .trim();
                serializer = classReader.tryRead(
                    '$className.fields.$fieldName.serializer', false);
              }

              final typeInfo = _parseType(type);
              var value = fieldName;
              if (serializer != null) {
                value = '$serializer.serialize($value)';
              } else {
                value = _serialize(typeInfo, value, serializerReader);
              }

              code.add("'$alias': $value,");
            }

            code.add('};');
            b.body = Code(code.join('\n'));
          }));

          b.methods.add(Method((b) {
            b.static = true;
            b.returns = Reference('List<Map<String, dynamic>>');
            b.name = 'toJsonList';
            b.requiredParameters.add(Parameter((b) {
              b.name = 'list';
              b.type = Reference('List<$className>');
            }));

            final code = <String>[];
            code.add('return list.map((e) => e.toJson()).toList();');
            b.body = Code(code.join('\n'));
          }));
        });

        b.body.add(class_);
      }
    });

    final emitter = DartEmitter();
    final result = library.accept(emitter).toString();
    return result;
  }

  String generateEnums(Map enums) {
    final library = Library((lib) {
      final enumReader = MapReader(enums);
      for (final key in enums.keys) {
        final enum_ = Enum((b) {
          final enumName = '$key';
          b.name = enumName;
          final valuesData = enumReader.read<Map>('$enumName.values');
          for (final key in valuesData.keys) {
            final valueName = '$key';
            b.values.add(EnumValue((b) {
              b.name = valueName;
            }));
          }
        });

        lib.body.add(enum_);
      }
    });

    final emitter = DartEmitter();
    final result = library.accept(emitter).toString();
    return result;
  }

  String generateSerializers(Map serializers) {
    final library = Library((b) {
      final serializerReader = MapReader(serializers);
      for (final key in serializers.keys) {
        final class_ = Class((b) {
          final className = '$key';
          final classType = _parseType(className);
          _checkTypeHasNoSuffix(classType, className);
          _checkTypeHasNoArguments(classType, className);
          final typeName = serializerReader.read<String>('$className.type');
          final type = _parseType(typeName);
          _checkTypeHasNoSuffix(type, '$className.type');
          _checkTypeHasOnlySimpleArguments(type, '$className.type');
          final typeArguments = type.arguments;
          b.name = className;
          b.constructors.add(Constructor((b) {
            b.constant = true;
          }));

          b.methods.add(Method((b) {
            b.returns = Reference(typeName);
            b.name = 'deserialize';
            if (typeArguments.isNotEmpty) {
              b.types.addAll(typeArguments.map((e) => Reference(e.name)));
            }

            b.requiredParameters.add(Parameter((b) {
              b.name = 'value';
              b.type = Reference('Object');
            }));
            final body =
                serializerReader.read<String>('$className.deserialize');
            b.body = Code(body);
          }));

          b.methods.add(Method((b) {
            b.returns = Reference('Object');
            b.name = 'serialize';
            if (typeArguments.isNotEmpty) {
              b.types.addAll(typeArguments.map((e) => Reference(e.name)));
            }

            b.requiredParameters.add(Parameter((b) {
              b.name = 'value';
              b.type = Reference(typeName);
            }));
            final body = serializerReader.read<String>('$className.serialize');
            b.body = Code(body);
          }));
        });

        b.body.add(class_);
      }
    });

    final emitter = DartEmitter();
    final result = library.accept(emitter).toString();
    return result;
  }

  String render(String template, Map<String, String> values) {
    for (final key in values.keys) {
      final value = values[key]!;
      template = template.replaceAll('{{$key}}', value);
    }

    return template;
  }

  void _checkTypeHasNoArguments(TypeInfo type, String path) {
    final arguments = type.arguments;
    if (arguments.isNotEmpty) {
      throw StateError(
          "Type '$type' must be specified without arguments: $path");
    }
  }

  void _checkTypeHasNoSuffix(TypeInfo type, String path) {
    if (type.hasSuffix) {
      throw StateError("Type '$type' must be specified without suffix: $path");
    }
  }

  void _checkTypeHasOnlySimpleArguments(TypeInfo type, String path) {
    final typeArguments = type.arguments;
    if (typeArguments.isEmpty) {
      return;
    }

    if (typeArguments.any((e) => e.arguments.isNotEmpty)) {
      throw StateError("Type '$type' not have complex arguments: $path");
    }
  }

  String _deserialize(TypeInfo typeInfo, String value, MapReader serializers) {
    final name = typeInfo.nameWithSuffix;
    final typeArguments = typeInfo.arguments;
    if (typeArguments.isEmpty) {
      const primitiveTypes = {
        'bool?',
        'double?',
        'int?',
        'num?',
        'String?',
      };
      if (primitiveTypes.contains(name)) {
        return '$value as $name';
      }

      final defaultValues = {
        'bool': 'false',
        'double': ' 0.0',
        'int': '0',
        'num': '0',
        'String': "''",
      };

      final defaultValue = defaultValues[name];
      if (defaultValue != null) {
        return '$value == null ? $defaultValue : $value as $name';
      }

      const bottomTypes = {
        'dynamic',
        'dynamic?',
        'Null',
        'Null?',
        'Object',
        'Object?',
      };
      if (bottomTypes.contains(name)) {
        return value;
      }
    }

    switch (name) {
      case 'List':
      case 'List?':
        if (typeArguments.length == 1) {
          return _deserializeList(typeInfo, value, serializers);
        }

        break;
      case 'Map':
      case 'Map?':
        if (typeArguments.length == 2) {
          final keyType = typeArguments[0];
          if (keyType.nameWithSuffix == 'String') {
            return _deserializeMap(typeInfo, value, serializers);
          }
        }

        break;
      default:
        if (typeArguments.isEmpty) {
          final serializer =
              _findSerializer(typeInfo, serializers: serializers);
          if (serializer != null) {
            return _deserializeWith(typeInfo, value, serializer);
          }

          return _deserializeObject(typeInfo, value);
        }
    }

    throw StateError('Unable to generate deserializer for type $typeInfo');
  }

  String _deserializeList(
      TypeInfo typeInfo, String value, MapReader serializers) {
    final typeArguments = typeInfo.arguments;
    final elementType = typeArguments[0];
    final serializeElement = _deserialize(elementType, 'e', serializers);
    final code = <String>[];
    final defaultValue =
        _isNullableType(typeInfo) ? 'null' : '<$elementType>[]';
    code.add(
        '$value == null ? $defaultValue : ($value as List).map((e) => $serializeElement).toList()');
    return code.join('\n');
  }

  String _deserializeMap(
      TypeInfo typeInfo, String value, MapReader serializers) {
    final typeArguments = typeInfo.arguments;
    final valueType = typeArguments[1];
    final serializeValue = _deserialize(valueType, 'v', serializers);
    final defaultValue = _isNullableType(typeInfo) ? 'null' : '{}';
    final code = <String>[];
    code.add(
        '$value == null ? $defaultValue : ($value as Map).map((k, v) => MapEntry(k as String, $serializeValue))');
    return code.join('\n');
  }

  String _deserializeObject(TypeInfo typeInfo, String value) {
    final name = typeInfo.name;
    final code = <String>[];
    if (_isNullableType(typeInfo)) {
      code.add('$value == null ? null : $name.fromJson($value as Map)');
    } else {
      code.add('$name.fromJson($value as Map)');
    }

    return code.join('\n');
  }

  String _deserializeWith(
      TypeInfo typeInfo, String value, String serializerName) {
    final code = <String>[];
    if (_isNullableType(typeInfo)) {
      code.add(
          '$value == null ? null: $serializerName().deserialize($value as Object)');
    } else {
      code.add('$serializerName().deserialize($value as Object)');
    }

    return code.join('\n');
  }

  String? _findSerializer(
    TypeInfo typeInfo, {
    required MapReader serializers,
  }) {
    final map = serializers.map;
    final typeName = '$typeInfo';
    for (final key in map.keys) {
      final serializerName = '$key';
      final typeName2 =
          serializers.tryRead<String>('$serializerName.type', false);
      if (typeName2 != null) {
        final typeInfo2 = _parseType(typeName2);
        if (typeName == '$typeInfo2') {
          return serializerName;
        }
      }
    }

    return null;
  }

  bool _isNullableType(TypeInfo typeInfo) {
    final name = typeInfo.name;
    if (typeInfo.hasSuffix || name == 'dynamic' || name == 'Null') {
      return true;
    }

    return false;
  }

  TypeInfo _parseType(String source) {
    final parser = TypeParser();
    final result = parser.parse(source);
    return result;
  }

  String _serialize(TypeInfo typeInfo, String value, MapReader serializers) {
    const types = {
      'bool',
      'bool?',
      'double',
      'double?',
      'int',
      'int?',
      'num',
      'num?',
      'String',
      'String?',
      'dynamic',
      'dynamic?',
      'Null',
      'Null,',
      'Object',
      'Object?',
    };
    final nameWithSuffix = typeInfo.nameWithSuffix;
    final typeArguments = typeInfo.arguments;
    if (types.contains(nameWithSuffix) && typeArguments.isEmpty) {
      return value;
    }

    switch (nameWithSuffix) {
      case 'List':
      case 'List?':
        if (typeArguments.length == 1) {
          return _serializeList(typeInfo, value, serializers);
        }

        break;
      case 'Map':
      case 'Map?':
        if (typeArguments.length == 2) {
          final keyType = typeArguments[0];
          if (keyType.nameWithSuffix == 'String') {
            return _serializeMap(typeInfo, value, serializers);
          }
        }

        break;
      default:
        if (typeArguments.isEmpty) {
          final serializer =
              _findSerializer(typeInfo, serializers: serializers);
          if (serializer != null) {
            return _serializeWith(typeInfo, value, serializer);
          }

          return _serializeObject(typeInfo, value);
        }
    }

    throw StateError('Unable to generate serializer for type $typeInfo');
  }

  String _serializeList(
      TypeInfo typeInfo, String value, MapReader serializers) {
    final typeArguments = typeInfo.arguments;
    final code = <String>[];
    final elementType = typeArguments[0];
    final serializeElement = _serialize(elementType, 'e', serializers);
    final test = _isNullableType(typeInfo) ? '?' : '';
    if (serializeElement == 'e') {
      code.add(value);
    } else {
      code.add('$value$test.map((e) => $serializeElement).toList()');
    }

    return code.join('\n');
  }

  String _serializeMap(TypeInfo typeInfo, String value, MapReader serializers) {
    final typeArguments = typeInfo.arguments;
    final code = <String>[];
    final valueType = typeArguments[0];
    final serializeValue = _serialize(valueType, 'v', serializers);
    final test = _isNullableType(typeInfo) ? '?' : '';
    if (serializeValue == 'v') {
      code.add('$value$test.map(MapEntry.new)');
    } else {
      code.add('$value$test.map((k, v) => MapEntry(k, $serializeValue))');
    }

    return code.join('\n');
  }

  String _serializeObject(TypeInfo typeInfo, String value) {
    final code = <String>[];
    final test = _isNullableType(typeInfo) ? '?' : '';
    code.add('$value$test.toJson()');
    return code.join('\n');
  }

  String _serializeWith(
      TypeInfo typeInfo, String value, String serializerName) {
    final name = typeInfo.name;
    final code = <String>[];
    if (_isNullableType(typeInfo)) {
      code.add(
          '$value == null ? null : $serializerName().serialize($value as $name)');
    } else {
      code.add('$serializerName().serialize($value)');
    }

    return code.join('\n');
  }
}
