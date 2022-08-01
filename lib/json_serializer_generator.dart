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
    final classReader = MapReader(classes);
    final serializerReader = MapReader(serializers);
    final library = Library((b) {
      for (final key in classes.keys) {
        final class_ = Class((b) {
          final className = '$key';
          b.name = className;
          final extend =
              classReader.tryRead<String>('$className.extends', false);
          if (extend != null) {
            b.extend = Reference(extend);
          }

          final typeParameters =
              classReader.tryRead<String>('$className.typeParameters', false);
          if (typeParameters != null) {
            final type = _parseType('$className$typeParameters');
            b.types.addAll(type.arguments.map((e) => Reference('$e')));
          }

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
              String? deserialize;
              var type = classReader.tryRead<String>(
                  '$className.fields.$fieldName', false);
              if (type == null) {
                type = classReader
                    .read<String>('$className.fields.$fieldName.type');
                alias = (classReader.tryRead<String>(
                            '$className.fields.$fieldName.alias', false) ??
                        fieldName)
                    .trim();
                deserialize = classReader.tryRead(
                    '$className.fields.$fieldName.deserialize', false);
              }

              final typeInfo = _parseType(type);
              var value = "json['$alias']";
              if (deserialize != null) {
                value = '$deserialize($value)';
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
              String? serialize;
              var type = classReader.tryRead<String>(
                  '$className.fields.$fieldName', false);
              if (type == null) {
                type = classReader
                    .read<String>('$className.fields.$fieldName.type');
                alias = (classReader.tryRead<String>(
                            '$className.fields.$fieldName.alias', false) ??
                        fieldName)
                    .trim();
                serialize = classReader.tryRead(
                    '$className.fields.$fieldName.serialize', false);
              }

              final typeInfo = _parseType(type);
              var value = fieldName;
              if (serialize != null) {
                value = '$serialize($value)';
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

  String generateGenericSerializer(Map serializer) {
    final library = Library((lib) {
      final serializerReader = MapReader(serializer);
      final class_ = Class((b) {
        final name = serializerReader.read<String>('name');
        b.name = name;
        final types = serializerReader.read<List>('types');
        final typeNames = <String>{};
        for (final element in types) {
          final typeName = '$element';
          final type = _parseType(typeName);
          if (type.hasSuffix) {
            throw StateError(
                'Generic serializer does not support nullable types: $type');
          }

          if (type.arguments.isNotEmpty) {
            throw StateError(
                'Generic serializer does not support parametrized types: $type');
          }

          typeNames.add(type.name);
        }

        b.methods.add(Method((b) {
          b.static = true;
          b.returns = Reference('T');
          b.name = 'deserialize';
          b.types.add(Reference('T'));
          b.requiredParameters.add(Parameter((b) {
            b.name = 'json';
            b.type = Reference('Map');
          }));
          const template = r'''
const types = {{{types}}};
final fromJson = types[T];
if (fromJson != null) {
  return fromJson(json) as T;
}

throw StateError('Unable to deserialize type $T');''';
          final values = {
            'types': typeNames.map((e) => '$e: $e.fromJson').join(',\n'),
          };
          b.body = Code(render(template, values));
        }));
      });

      lib.body.add(class_);
    });

    final emitter = DartEmitter();
    final result = library.accept(emitter).toString();
    return result;
  }

  String generateSerializers(Map serializers) {
    final library = Library((b) {
      for (final key in serializers.keys) {
        final class_ = Class((b) {
          final typeName = '$key';
          final reader = MapReader(serializers);
          final className = reader.read<String>('$typeName.type');
          b.name = className;
          b.methods.add(Method((b) {
            b.static = true;
            b.name = 'deserialize';
            b.returns = Reference('$key');
            b.requiredParameters.add(Parameter((b) {
              b.name = 'value';
              b.type = Reference('Object?');
            }));
            final body = reader.read<String>('$typeName.deserialize');
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
            final body = reader.read<String>('$typeName.serialize');
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
          final name = typeInfo.name;
          final serializer = serializers.tryRead(name, false);
          if (serializer != null) {
            return _deserializeWith(typeInfo, value, serializers);
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
    final defaultValue = _isNullableType(typeInfo) ? 'null' : '[]';
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
      TypeInfo typeInfo, String value, MapReader serializers) {
    final name = typeInfo.name;
    final serializerTypeName = serializers.read<String>('$name.type');
    final code = <String>[];
    if (_isNullableType(typeInfo)) {
      code.add(
          '$value == null ? null: $serializerTypeName.deserialize($value)');
    } else {
      code.add('$serializerTypeName.deserialize($value)');
    }

    return code.join('\n');
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
          final name = typeInfo.name;
          final serializer = serializers.tryRead(name, false);
          if (serializer != null) {
            return _serializeWith(typeInfo, value, serializers);
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
      TypeInfo typeInfo, String value, MapReader serializers) {
    final name = typeInfo.name;
    final serializerTypeName = serializers.read<String>('$name.type');
    final code = <String>[];
    if (_isNullableType(typeInfo)) {
      code.add(
          '$value == null ? null : $serializerTypeName.serialize($value as $name)');
    } else {
      code.add('$serializerTypeName.serialize($value)');
    }

    return code.join('\n');
  }
}
