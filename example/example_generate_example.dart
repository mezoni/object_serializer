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
  File('example/example.dart').writeAsStringSync(source);
}

const _classes = '''
Company:
  fields:
    name: String
    website: Uri

Customer:
  fields:
    age: int?
    birthday: DateTime?
    frequency: Duration
    level: {type: CustomerLevel, alias: customer_level}
    name: String

Order:
  fields:
    amount: BigInt
    company: Company
    customer: Customer
    date: DateTime
    lines: List<OrderLine>

OrderLine:
  fields:
    product: Product
    price: BigInt
    quantity: int
    total: BigInt

Product:
  fields:
    name: String
    price: BigInt
    priceRange: Map<String, double>
''';

const _enums = '''
CustomerLevel:
  values:
    retail:
    wholesale:
''';

const _serializers = '''
BigInt:
  type: _BigIntSerializer
  deserialize: |-
    final json = value as String;
    return BigInt.parse(json);
  serialize: |-
     return value.toString();



DateTime:
  type: _DateTimeSerializer
  deserialize: |-
   final json = value as String;
   return DateTime.fromMicrosecondsSinceEpoch(int.parse(json));

  serialize: |-
    return value.microsecondsSinceEpoch.toString();

CustomerLevel:
  type: _CustomerLevelSerializer
  deserialize: |-
    final json = value as int;
    return CustomerLevel.values[json];
  serialize: |-
    return value.index;

Duration:
  type: _DurationSerializer
  deserialize: |-
    final json = value as String;
    return Duration(microseconds: int.parse(json));
  serialize: |-
    return value.inMicroseconds.toString();

Uri:
  type: _UriSerializer
  deserialize: |-
    final json = value as String;
    return Uri.parse(json);
  serialize: |-
    return value.toString();
''';

const _template = r'''
import 'dart:convert';

void main(List<String> args) {
  final price = BigInt.from(29.99);
  final order = Order(
    amount: price,
    company: _company,
    customer: _customer,
    date: DateTime.now(),
    lines: [
      OrderLine(
          product: _product,
          price: price,
          quantity: 25,
          total: price * BigInt.from(25))
    ],
  );

  final jsonObject = Order.toJsonList([order, order]);
  final jsonString = jsonEncode(jsonObject);
  final jsonObject2 = jsonDecode(jsonString);
  final orders = Order.fromJsonList(jsonObject2 as List);
  final jsonObject3 = Order.toJsonList(orders);
  final jsonString2 = jsonEncode(jsonObject3);
  final result = jsonString == jsonString2;
  print(jsonString2);
  print('Test passed: $result');
}

final _company = Company(
  name: 'ACME Inc.',
  website: Uri.parse('https://acme.com'),
);

final _customer = Customer(
  age: null,
  birthday: null,
  frequency: Duration(days: 10),
  level: CustomerLevel.wholesale,
  name: 'Peter Pan',
);

final _product = Product(
  name: 'The Little White Bird',
  price: BigInt.from(49.99),
  priceRange: {
    '3': 49.99,
    '10': 39.99,
    '25': 29.99,
  },
);

{{classes}}

{{enums}}

{{serializers}}
''';
