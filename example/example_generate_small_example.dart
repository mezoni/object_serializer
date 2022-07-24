import 'dart:io';

import 'package:object_serializer/json_serializer_generator.dart';
import 'package:yaml/yaml.dart';

void main() {
  final classes = loadYaml(_classes) as Map;
  final serializers = loadYaml(_serializers) as Map;
  final g = JsonSerializerGenerator();
  final classesCode = g.generateClasses(
    classes,
    serializers: serializers,
  );
  final serializersCode = g.generateSerializers(
    serializers,
  );
  final enums = loadYaml(_enums) as Map;
  final enumCode = g.generateEnums(enums);
  final values = {
    'classes': classesCode,
    'enums': enumCode,
    'serializers': serializersCode,
  };

  var source = g.render(_template, values);
  source = g.format(source);
  File('example/small_example.dart').writeAsStringSync(source);
}

const _classes = '''
Post:
  fields:
    id: int
    user: User
    text: String
    comments: List<int>?

User:
  fields:
    id: int
    name: String
    age: int?
''';

const _enums = '''
{}
''';

const _serializers = '''
{}
''';

const _template = r'''
import 'dart:convert';

void main(List<String> args) {
  final user = User(
    id: 1,
    name: "Jack",
    age: null,
  );

  final post1 = Post(
    id: 1,
    user: user,
    text: 'Hello!',
    comments: [123, 456],
  );

  final post2 = Post(
    id: 2,
    user: user,
    text: 'Goodbye!',
    comments: null,
  );

  final input = Post.toJsonList([post1, post2]);
  final json = jsonEncode(input);
  final output = jsonDecode(json);
  final posts = Post.fromJsonList(output as List);
  print(json);
  print('Posts: ${posts.length}');
  print('Users: ${posts.map((e) => e.user.name)}');
}

{{classes}}

{{enums}}

{{serializers}}
''';
