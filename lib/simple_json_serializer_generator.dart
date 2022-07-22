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
            final fieldType = _getValue<String>(classData, fieldName);
            b.fields.add(Field((b) {
              b.name = fieldName;
              b.type = Reference(fieldType);
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
          final enumData = _getValue<List>(enums, enumName);
          for (final value in enumData) {
            final valueName = '$value';
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
      String name, Iterable<String> named, Iterable<String> other) {
    final buffer = StringBuffer();
    buffer.writeln('final $name = JsonSerializerCollection()');
    final list = <String>[];
    for (final name in named) {
      list.add('..addSerializer(${name}Serializer())');
    }

    for (final name in other) {
      list.add('..addSerializer($name())');
    }

    list.sort();
    buffer.write(list.join('\n'));
    buffer.writeln(';');
    final result = buffer.toString();
    return result;
  }

  String generateSerializersForClasses(Map classes) {
    final library = Library((lib) {
      for (final key in classes.keys) {
        final class_ = Class((b) {
          final className = '$key';
          b.name = '${className}Serializer';
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
              final fieldType = _getValue<String>(classData, fieldName).trim();
              var collection = '';
              if (fieldType.startsWith('List<')) {
                collection = 'List';
              } else if (fieldType.startsWith('Map<')) {
                collection = 'Map';
              }

              code.add(
                  "$fieldName: deserializer.deserialize$collection(json['$fieldName']),");
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
              final fieldType = _getValue<String>(classData, fieldName).trim();
              var collection = '';
              if (fieldType.startsWith('List<')) {
                collection = 'List';
              } else if (fieldType.startsWith('Map<')) {
                collection = 'Map';
              }

              code.add(
                  "'$fieldName': serializer.serialize$collection(value.$fieldName),");
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

  String generateSerializersForEnums(Map enums) {
    final library = Library((lib) {
      for (final key in enums.keys) {
        final class_ = Class((b) {
          final enumName = '$key';
          b.name = '${enumName}Serializer';
          b.extend = Reference('JsonSerializer<$enumName>');
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
            code.add('final json = cast<int>(value);');
            code.add('return $enumName.values[json];');
            b.body = Code(code.join('\n'));
          }));

          b.methods.add(Method((b) {
            b.annotations.add(CodeExpression(Code('override')));
            b.name = 'serialize';
            b.returns = Reference('int');
            b.requiredParameters.add(Parameter((b) {
              b.name = 'serializer';
              b.type = Reference('Serializer');
            }));
            b.requiredParameters.add(Parameter((b) {
              b.name = 'value';
              b.type = Reference(enumName);
            }));

            final code = <String>[];
            code.add('return value.index;');
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

  T _getValue<T>(Map map, Object? key) {
    final result = map[key];
    if (result is T) {
      return result;
    }

    throw StateError(
        "Unable to cast field ${result.runtimeType} '$key' to type $T");
  }
}
