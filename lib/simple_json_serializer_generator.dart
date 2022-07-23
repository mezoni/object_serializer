import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

class SimpleJsonSerializerGenerator {
  String format(String source) {
    final formatter = DartFormatter();
    final result = formatter.format(source);
    return result;
  }

  String generateClasses(Map classes) {
    final library = Library((lib) {
      for (final key in classes.keys) {
        final class_ = Class((b) {
          final className = '$key';
          b.name = className;
          final classData = _getValue<Map>(classes, className);
          for (final key in classData.keys) {
            final fieldName = '$key';
            final filedData = _getFieldData(classData, fieldName);
            final type = _getValue<String>(filedData, 'type');
            b.fields.add(Field((b) {
              b.name = fieldName;
              b.type = Reference(type);
              b.modifier = FieldModifier.final$;
            }));
          }

          b.constructors.add(Constructor((b) {
            for (final key in classData.keys) {
              final fieldName = '$key';
              b.optionalParameters.add(Parameter((b) {
                b.required = true;
                b.toThis = true;
                b.name = fieldName;
                b.named = true;
              }));
            }
          }));
        });

        lib.body.add(class_);
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
          for (final key in enumData.keys) {
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

  String generateSerializerCollection(
      String name, Iterable<String> serializers) {
    final buffer = StringBuffer();
    buffer.writeln('final $name = JsonSerializerCollection()');
    final list = <String>[];
    for (final serializer in serializers) {
      list.add('..addSerializer($serializer())');
    }

    list.sort();
    buffer.write(list.join('\n'));
    buffer.writeln(';');
    final result = buffer.toString();
    return result;
  }

  String generateSerializers(Map serializers) {
    final library = Library((lib) {
      for (final key in serializers.keys) {
        final class_ = Class((b) {
          final serializerName = '$key';
          final serializerData = _getValue<Map>(serializers, key);
          b.name = serializerName;
          final type = _getValue<String>(serializerData, 'type');
          b.extend = Reference('JsonSerializer<$type>');
          b.methods.add(Method((b) {
            b.annotations.add(CodeExpression(Code('override')));
            b.name = 'deserialize';
            b.returns = Reference(type);
            b.requiredParameters.add(Parameter((b) {
              b.name = 'deserializer';
              b.type = Reference('Deserializer');
            }));
            b.requiredParameters.add(Parameter((b) {
              b.name = 'value';
              b.type = Reference('Object?');
            }));

            final deserialize =
                _getValue<String>(serializerData, 'deserialize');
            b.body = Code(deserialize);
          }));

          b.methods.add(Method((b) {
            b.annotations.add(CodeExpression(Code('override')));
            b.name = 'serialize';
            final returns =
                _getValue<String>(serializerData, 'serializeReturns');
            b.returns = Reference(returns);
            b.requiredParameters.add(Parameter((b) {
              b.name = 'serializer';
              b.type = Reference('Serializer');
            }));
            b.requiredParameters.add(Parameter((b) {
              b.name = 'value';
              b.type = Reference(type);
            }));

            final serialize = _getValue<String>(serializerData, 'serialize');
            b.body = Code(serialize);
          }));
        });

        lib.body.add(class_);
      }
    });

    final emitter = DartEmitter();
    final result = library.accept(emitter).toString();
    return result;
  }

  String generateSerializersForClasses(
      Map classes, String Function(String name) generateName) {
    final library = Library((lib) {
      for (final key in classes.keys) {
        final class_ = Class((b) {
          final className = '$key';
          b.name = generateName(className);
          b.extend = Reference('JsonSerializer<$className>');
          final classData = _getValue<Map>(classes, className);
          b.methods.add(Method((b) {
            b.annotations.add(CodeExpression(Code('override')));
            b.name = 'deserialize';
            b.returns = Reference(className);
            b.requiredParameters.add(Parameter((b) {
              b.name = 'deserializer';
              b.type = Reference('Deserializer');
            }));
            b.requiredParameters.add(Parameter((b) {
              b.name = 'value';
              b.type = Reference('Object?');
            }));

            final code = <String>[];
            code.add('final json = cast<Map>(value);');
            code.add('return $className(');
            for (final key in classData.keys) {
              final fieldName = '$key';
              final fieldData = _getFieldData(classData, fieldName);
              final type = _getValue<String>(fieldData, 'type').trim();
              final alias =
                  (_tryGetValue<String>(fieldData, 'alias') ?? fieldName)
                      .trim();
              var collection = '';
              if (type.startsWith('List<')) {
                collection = 'List';
              } else if (type.startsWith('Map<')) {
                collection = 'Map';
              }

              code.add(
                  "$fieldName: deserializer.deserialize$collection(json['$alias']),");
            }

            code.add(');');
            b.body = Code(code.join('\n'));
          }));

          b.methods.add(Method((b) {
            b.annotations.add(CodeExpression(Code('override')));
            b.name = 'serialize';
            b.returns = Reference('Map<String, dynamic>');
            b.requiredParameters.add(Parameter((b) {
              b.name = 'serializer';
              b.type = Reference('Serializer');
            }));
            b.requiredParameters.add(Parameter((b) {
              b.name = 'value';
              b.type = Reference(className);
            }));

            final code = <String>[];
            code.add('return {');
            for (final key in classData.keys) {
              final fieldName = '$key';
              final fieldData = _getFieldData(classData, fieldName);
              final type = _getValue<String>(fieldData, 'type').trim();
              final alias =
                  (_tryGetValue<String>(fieldData, 'alias') ?? fieldName)
                      .trim();
              var collection = '';
              if (type.startsWith('List<')) {
                collection = 'List';
              } else if (type.startsWith('Map<')) {
                collection = 'Map';
              }

              code.add(
                  "'$alias': serializer.serialize$collection(value.$fieldName),");
            }

            code.add('};');
            b.body = Code(code.join('\n'));
          }));
        });

        lib.body.add(class_);
      }
    });

    final emitter = DartEmitter();
    final result = library.accept(emitter).toString();
    return result;
  }

  String generateSerializersForEnums(
      Map enums, String Function(String name) generateName) {
    final library = Library((lib) {
      for (final key in enums.keys) {
        final class_ = Class((b) {
          final enumName = '$key';
          b.name = generateName(enumName);
          b.extend = Reference('JsonSerializer<$enumName>');
          final enumData = _getValue<Map>(enums, enumName);
          final values = <String, dynamic>{};
          for (final key in enumData.keys) {
            final valueName = '$key'.trim();
            final value = _tryGetValue(enumData, valueName);
            values[valueName] = value;
          }

          final isMapped = values.values.any((e) => e != null);
          b.methods.add(Method((b) {
            b.annotations.add(CodeExpression(Code('override')));
            b.name = 'deserialize';
            b.returns = Reference(enumName);
            b.requiredParameters.add(Parameter((b) {
              b.name = 'deserializer';
              b.type = Reference('Deserializer');
            }));
            b.requiredParameters.add(Parameter((b) {
              b.name = 'value';
              b.type = Reference('Object?');
            }));

            final code = <String>[];
            if (!isMapped) {
              code.add('final json = cast<int>(value);');
              code.add('return $enumName.values[json];');
            } else {
              final entries = <String>[];
              var index = 0;
              for (final key in values.keys) {
                final value = values[key];
                final val = value ?? index;
                final entry = '$val: $index';
                entries.add(entry);
                index++;
              }

              code.add('const map = {');
              code.add(entries.join(',\n'));
              code.add('};');
              code.add('final index = map[value] as int;');
              code.add('return $enumName.values[index];');
            }

            b.body = Code(code.join('\n'));
          }));

          b.methods.add(Method((b) {
            b.annotations.add(CodeExpression(Code('override')));
            b.name = 'serialize';
            b.returns = isMapped ? Reference('Object?') : Reference('int');
            b.requiredParameters.add(Parameter((b) {
              b.name = 'serializer';
              b.type = Reference('Serializer');
            }));
            b.requiredParameters.add(Parameter((b) {
              b.name = 'value';
              b.type = Reference(enumName);
            }));

            final code = <String>[];
            if (!isMapped) {
              code.add('return value.index;');
            } else {
              final entries = <String>[];
              var index = 0;
              for (final key in values.keys) {
                final value = values[key];
                final val = value ?? index;
                final entry = '$index: $val';
                entries.add(entry);
                index++;
              }

              code.add('const map = {');
              code.add(entries.join(',\n'));
              code.add('};');
              code.add('return map[value.index];');
            }

            b.body = Code(code.join('\n'));
          }));
        });

        lib.body.add(class_);
      }
    });

    final emitter = DartEmitter();
    final result = library.accept(emitter).toString();
    return result;
  }

  Map _getFieldData(Map map, String key) {
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

  T? _tryGetValue<T>(Map map, Object? key) {
    final result = map[key];
    if (result is T) {
      return result;
    }

    return null;
  }
}
