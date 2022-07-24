import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

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
      for (final key in classes.keys) {
        final class_ = Class((b) {
          final className = '$key';
          final classData = _getValue<Map>(classes, className);
          final fieldsData = _getValue<Map>(classData, 'fields');
          b.name = className;
          final extend = _tryGetValue<String>(classData, 'extends');
          if (extend != null) {
            b.extend = Reference(extend);
          }

          for (final key in fieldsData.keys) {
            final fieldName = '$key';
            final fieldData = _getFieldData(fieldsData, fieldName);
            final type = _getValue<String>(fieldData, 'type');
            final metadata = _tryGetValue<List>(fieldData, 'metadata');
            if (metadata != null) {
              for (final annotation in metadata) {
                b.annotations.add(CodeExpression(Code('$annotation')));
              }
            }

            b.fields.add(Field((b) {
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
              final fieldData = _getFieldData(fieldsData, fieldName);
              final type = _getValue<String>(fieldData, 'type').trim();
              final typeInfo = _parseType(type);
              final alias =
                  (_tryGetValue<String>(fieldData, 'alias') ?? fieldName)
                      .trim();
              final deserialize = _tryGetValue(fieldData, 'deserialize');
              var value = "json['$alias']";
              if (deserialize != null) {
                value = '$deserialize($value)';
              } else {
                value = _deserialize(typeInfo, value, serializers);
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
              final fieldData = _getFieldData(fieldsData, fieldName);
              final type = _getValue<String>(fieldData, 'type').trim();
              final typeInfo = _parseType(type);
              final alias =
                  (_tryGetValue<String>(fieldData, 'alias') ?? fieldName)
                      .trim();
              final serialize = _tryGetValue(fieldData, 'serialize');
              var value = fieldName;
              if (serialize != null) {
                value = '$serialize($value)';
              } else {
                value = _serialize(typeInfo, value, serializers);
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
      for (final key in enums.keys) {
        final enum_ = Enum((b) {
          final enumName = '$key';
          b.name = enumName;
          final enumData = _getValue<Map>(enums, enumName);
          final valuesData = _getValue<Map>(enumData, 'values');
          for (final key in valuesData.keys) {
            final valueName = '$key';
            _getEnumValueData(valuesData, key);
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
      for (final key in serializers.keys) {
        final class_ = Class((b) {
          final classData = _getValue<Map>(serializers, key);
          final type = _getValue<String>(classData, 'type');
          b.name = type;
          b.methods.add(Method((b) {
            b.static = true;
            b.name = 'deserialize';
            b.returns = Reference('$key');
            b.requiredParameters.add(Parameter((b) {
              b.name = 'value';
              b.type = Reference('Object?');
            }));
            final body = _getValue<String>(classData, 'deserialize');
            b.body = Code(body);
          }));

          b.methods.add(Method((b) {
            b.static = true;
            b.name = 'serialize';
            b.returns = Reference('Object?');
            b.requiredParameters.add(Parameter((b) {
              b.name = 'value';
              b.type = Reference('$key');
            }));
            final body = _getValue<String>(classData, 'serialize');
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

  String _deserialize(TypeInfo typeInfo, String value, Map serializers) {
    final name = typeInfo.nameWithSuffix;
    final typeArguments = typeInfo.arguments;
    if (typeArguments.isEmpty) {
      const types = {
        'bool',
        'double',
        'int',
        'num',
        'String',
        'dynamic',
        'dynamic?',
        'Null',
        'Null?',
        'Object',
        'Object?',
      };
      if (types.contains(name)) {
        return '$value as $name';
      }

      final defaultValues = {
        'bool?': 'false',
        'double?': ' 0.0',
        'int?': '0',
        'num?': '0',
        'String?': "''",
      };

      final defaultValue = defaultValues[name];
      if (defaultValue != null) {
        return '$value == null ? null : $defaultValue';
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
          final name = typeInfo.name;
          final serializer = _tryGetValue(serializers, name);
          if (serializer != null) {
            return _deserializeWith(typeInfo, value, serializers);
          }

          return _deserializeObject(typeInfo, value);
        }
    }

    throw StateError('Unable to generate deserializer for type $typeInfo');
  }

  String _deserializeList(TypeInfo typeInfo, String value, Map serializers) {
    final typeArguments = typeInfo.arguments;
    final elementType = typeArguments[0];
    final serializeElement = _deserialize(elementType, 'e', serializers);
    final code = <String>[];
    final defaultValue = _isNullableType(typeInfo) ? 'null' : '[]';
    code.add(
        '$value == null ? $defaultValue : ($value as List).map((e) => $serializeElement).toList()');
    return code.join('\n');
  }

  String _deserializeMap(TypeInfo typeInfo, String value, Map serializers) {
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

  String _deserializeWith(TypeInfo typeInfo, String value, Map serializers) {
    final name = typeInfo.name;
    final serializerData = _getValue<Map>(serializers, name);
    final serializerTypeName = _getValue<String>(serializerData, 'type');
    final code = <String>[];
    if (_isNullableType(typeInfo)) {
      code.add(
          '$value == null ? null: $serializerTypeName.deserialize($value)');
    } else {
      code.add('$serializerTypeName.deserialize($value)');
    }

    return code.join('\n');
  }

  Map _getEnumValueData(Map map, key) {
    final result = _tryGetValue<Map>(map, key);
    if (result != null) {
      return result;
    }

    return {};
  }

  Map _getFieldData(Map map, key) {
    final type = _tryGetValue<String>(map, key);
    if (type != null) {
      return {'type': type};
    }

    final result = _getValue<Map>(map, key);
    return result;
  }

  T _getValue<T>(Map map, Object? key) {
    final result = map[key];
    if (result is T) {
      return result;
    }

    throw StateError(
        "Unable to cast field ${result.runtimeType} '$key' to type $T");
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

  String _serialize(TypeInfo typeInfo, String value, Map serializers) {
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
          final name = typeInfo.name;
          final serializer = _tryGetValue(serializers, name);
          if (serializer != null) {
            return _serializeWith(typeInfo, value, serializers);
          }

          return _serializeObject(typeInfo, value);
        }
    }

    throw StateError('Unable to generate serializer for type $typeInfo');
  }

  String _serializeList(TypeInfo typeInfo, String value, Map serializers) {
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

  String _serializeMap(TypeInfo typeInfo, String value, Map serializers) {
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

  String _serializeWith(TypeInfo typeInfo, String value, Map serializers) {
    final name = typeInfo.name;
    final serializerData = _getValue<Map>(serializers, name);
    final serializerTypeName = _getValue<String>(serializerData, 'type');
    final code = <String>[];
    if (_isNullableType(typeInfo)) {
      code.add(
          '$value == null ? null : $serializerTypeName.serialize($value as $name)');
    } else {
      code.add('$serializerTypeName.serialize($value)');
    }

    return code.join('\n');
  }

  T? _tryGetValue<T>(Map map, Object? key) {
    final result = map[key];
    if (result is T) {
      return result;
    }

    return null;
  }
}
