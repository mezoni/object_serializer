import 'dart:async';

import 'package:build/build.dart';
import 'package:yaml/yaml.dart' as y;

import 'json_serializer_generator.dart';

Builder jsonSerializer(BuilderOptions options) {
  return JsonSerializerLibraryGenerator();
}

class JsonSerializerLibraryGenerator extends Builder {
  static const _template = '''
{{directives}}

{{classes}}

{{serializers}}
''';

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.json.yaml': ['.json.dart'],
      };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final source = await buildStep.readAsString(inputId);
    final yaml = y.loadYaml(source);
    if (yaml is! Map) {
      throw StateError('Expected YAML map but got ${yaml.runtimeType}');
    }

    var classes = {};
    if (yaml.containsKey('classes')) {
      classes = _getValue<Map>(yaml, 'classes');
    }

    var directives = [];
    if (yaml.containsKey('directives')) {
      directives = _getValue<List>(yaml, 'directives');
    }

    var serializers = {};
    if (yaml.containsKey('serializers')) {
      serializers = _getValue<Map>(yaml, 'serializers');
    }

    final g = JsonSerializerGenerator();
    var classesCode = '';
    if (classes.isNotEmpty) {
      classesCode = g.generateClasses(
        classes,
        serializers: serializers,
      );
    }

    var serializersCode = '';
    if (serializers.isNotEmpty) {
      serializersCode = g.generateSerializers(
        serializers,
      );
    }

    var directivesCode = '';
    if (directives.isNotEmpty) {
      directivesCode = directives.join('\n');
    }

    final values = {
      'classes': classesCode,
      'directives': directivesCode,
      'serializers': serializersCode,
    };
    var result = g.render(_template, values);
    result = g.format(result);
    final outputId = inputId.changeExtension('.dart');
    await buildStep.writeAsString(outputId, result);
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
