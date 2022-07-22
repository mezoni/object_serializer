# object_serializer

A collection of serializers for serializing data in a variety of ways (JSON, Generic Objects).

Version: 0.1.3

Two kinds of data serializers are currently available:  
- JSON serializer
- Object serializer

`JSON serializer` is a serializer to standard JSON format. Serialization is supported for types that can be converted to simpler data types (eg. `BigInt`, `DateTime`, `Duration`, `Uri` etc). The working principle is simple. You yourself choose the method of serialization and deserialization of data, that is, you completely control this process.

`Object serializer` is a serializer (with caching support) of any static (generic) complex data that can be represented as simpler data.

Allows you to implement a serializer for any data that can be transferred between isolates or even over the Internet.  
The principle of operation is very simple, for each data type you need to implement your own object serializer.  

Implementing an object serializer is also very simple. To do this, you need to write the data in a `strict order` and then read this data in `the same order`.

## JSON

Let's say that we need to use this data objects.

```dart
class Company {
  final String name;

  final Uri website;

  Company({
    required this.name,
    required this.website,
  });
}

class Customer {
  final int? age;

  final DateTime? birthday;

  final Duration frequency;

  final CustomerLevel level;

  final String name;

  Customer({
    required this.age,
    required this.birthday,
    required this.frequency,
    required this.level,
    required this.name,
  });
}

enum CustomerLevel { retail, wholesale }

class Order {
  final BigInt amount;

  final Company company;

  final Customer customer;

  final DateTime date;

  final List<OrderLine> lines;

  Order({
    required this.amount,
    required this.company,
    required this.customer,
    required this.date,
    required this.lines,
  });
}

class OrderLine {
  final Product product;

  final BigInt price;

  final int quantity;

  final BigInt total;

  OrderLine({
    required this.product,
    required this.price,
    required this.quantity,
    required this.total,
  });
}

class Product {
  final String name;

  final BigInt price;

  final Map<String, double> priceRange;

  Product({
    required this.name,
    required this.price,
    required this.priceRange,
  });
}
```

How to implement serializers for these data types in less than 30 minutes?  
Let's try to do this.

```dart
class _BigIntSerializer extends JsonSerializer<BigInt> {
  @override
  BigInt deserialize(Deserializer deserializer, Object? value) {
    final json = cast<String>(value);
    return BigInt.parse(json);
  }

  @override
  String serialize(Serializer serializer, BigInt value) {
    return value.toString();
  }
}

class _CompanySerializer extends JsonSerializer<Company> {
  @override
  Company deserialize(Deserializer deserializer, Object? value) {
    final json = cast<Map>(value);
    return Company(
      name: deserializer.deserialize(json['name']),
      website: deserializer.deserialize(json['website']),
    );
  }

  @override
  Map<String, dynamic> serialize(Serializer serializer, Company value) {
    return {
      'name': serializer.serialize(value.name),
      'website': serializer.serialize(value.website),
    };
  }
}

class _CustomerLevelSerializer extends JsonSerializer<CustomerLevel> {
  @override
  CustomerLevel deserialize(Deserializer deserializer, Object? value) {
    final json = cast<int>(value);
    return CustomerLevel.values[json];
  }

  @override
  int serialize(Serializer serializer, CustomerLevel value) {
    return value.index;
  }
}

class _CustomerSerializer extends JsonSerializer<Customer> {
  @override
  Customer deserialize(Deserializer deserializer, Object? value) {
    final json = cast<Map>(value);
    return Customer(
      birthday: deserializer.deserialize(json['birthday']),
      age: deserializer.deserialize(json['age']),
      frequency: deserializer.deserialize(json['frequency']),
      level: deserializer.deserialize(json['level']),
      name: deserializer.deserialize(json['name']),
    );
  }

  @override
  Map<String, dynamic> serialize(Serializer serializer, Customer value) {
    return {
      'age': serializer.serialize(value.age),
      'birthday': serializer.serialize(value.birthday),
      'frequency': serializer.serialize(value.frequency),
      'level': serializer.serialize(value.level),
      'name': serializer.serialize(value.name),
    };
  }
}

class _DateTimeSerializer extends JsonSerializer<DateTime> {
  @override
  DateTime deserialize(Deserializer deserializer, Object? value) {
    final json = cast<String>(value);
    return DateTime.fromMicrosecondsSinceEpoch(int.parse(json));
  }

  @override
  String serialize(Serializer serializer, DateTime value) {
    return value.microsecondsSinceEpoch.toString();
  }
}

class _DurationSerializer extends JsonSerializer<Duration> {
  @override
  Duration deserialize(Deserializer deserializer, Object? value) {
    final json = cast<String>(value);
    return Duration(microseconds: int.parse(json));
  }

  @override
  String serialize(Serializer serializer, Duration value) {
    return value.inMicroseconds.toString();
  }
}

class _OrderLineSerializer extends JsonSerializer<OrderLine> {
  @override
  OrderLine deserialize(Deserializer deserializer, Object? value) {
    final json = cast<Map>(value);
    return OrderLine(
      price: deserializer.deserialize(json['price']),
      product: deserializer.deserialize(json['product']),
      quantity: deserializer.deserialize(json['quantity']),
      total: deserializer.deserialize(json['total']),
    );
  }

  @override
  Map<String, dynamic> serialize(Serializer serializer, OrderLine value) {
    return {
      'price': serializer.serialize(value.price),
      'product': serializer.serialize(value.product),
      'quantity': serializer.serialize(value.quantity),
      'total': serializer.serialize(value.total),
    };
  }
}

class _OrderSerializer extends JsonSerializer<Order> {
  @override
  Order deserialize(Deserializer deserializer, Object? value) {
    final json = cast<Map>(value);
    return Order(
      amount: deserializer.deserialize(json['amount']),
      company: deserializer.deserialize(json['company']),
      customer: deserializer.deserialize(json['customer']),
      date: deserializer.deserialize(json['date']),
      lines: deserializer.deserializeList(json['lines']),
    );
  }

  @override
  Map<String, dynamic> serialize(Serializer serializer, Order value) {
    return {
      'amount': serializer.serialize(value.amount),
      'company': serializer.serialize(value.company),
      'customer': serializer.serialize(value.customer),
      'date': serializer.serialize(value.date),
      'lines': serializer.serializeList(value.lines),
    };
  }
}

class _ProductSerializer extends JsonSerializer<Product> {
  @override
  Product deserialize(Deserializer deserializer, Object? value) {
    final json = cast<Map>(value);
    return Product(
      name: deserializer.deserialize(json['name']),
      price: deserializer.deserialize(json['price']),
      priceRange: deserializer.deserializeMap(json['priceRange']),
    );
  }

  @override
  Map<String, dynamic> serialize(Serializer serializer, Product value) {
    return {
      'name': serializer.serialize(value.name),
      'price': serializer.serialize(value.price),
      'priceRange': serializer.serializeMap(value.priceRange),
    };
  }
}

class _UriSerializer extends JsonSerializer<Uri> {
  @override
  Uri deserialize(Deserializer deserializer, Object? value) {
    final json = cast<String>(value);
    return Uri.parse(json);
  }

  @override
  String serialize(Serializer serializer, Uri value) {
    return value.toString();
  }
}
```

About 180 lines of code.   
Not much, given that you have complete control over what and how to serialize.

Let's see the result of this work in action.  
The simplest test:

```dart
import 'dart:convert';

import 'package:object_serializer/json_serializer.dart';

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

  final orders = [order, order];
  final jsonObject = serializeList(orders, _collection);
  final jsonString = jsonEncode(jsonObject);
  final jsonObject2 = jsonDecode(jsonString);
  final orders2 = deserializeList<Order>(jsonObject2, _collection);
  final jsonObject3 = serializeList(orders2, _collection);
  final jsonString2 = jsonEncode(jsonObject3);
  final result = jsonString == jsonString2;
  print(jsonString2);
  print('Test passed: $result');
}

final _collection = JsonSerializerCollection()
  ..addSerializer(_BigIntSerializer())
  ..addSerializer(_CompanySerializer())
  ..addSerializer(_CustomerLevelSerializer())
  ..addSerializer(_CustomerSerializer())
  ..addSerializer(_DateTimeSerializer())
  ..addSerializer(_DurationSerializer())
  ..addSerializer(_OrderLineSerializer())
  ..addSerializer(_OrderSerializer())
  ..addSerializer(_ProductSerializer())
  ..addSerializer(_UriSerializer());

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
```

Result pf work:

[{"amount":"29","company":{"name":"ACME Inc.","website":"https://acme.com"},"customer":{"age":null,"birthday":null,"frequency":"864000000000","level":1,"name":"Peter Pan"},"date":"1658504965053872","lines":[{"price":"29","product":{"name":"The Little White Bird","price":"49","priceRange":{"3":49.99,"10":39.99,"25":29.99}},"quantity":25,"total":"725"}]},{"amount":"29","company":{"name":"ACME Inc.","website":"https://acme.com"},"customer":{"age":null,"birthday":null,"frequency":"864000000000","level":1,"name":"Peter Pan"},"date":"1658504965053872","lines":[{"price":"29","product":{"name":"The Little White Bird","price":"49","priceRange":{"3":49.99,"10":39.99,"25":29.99}},"quantity":25,"total":"725"}]}]
Test passed: true

## Object serializer

Example of simple object serializer:

```dart
class _UriSerializer extends ObjectSerializer<Uri> {
  @override
  Uri deserialize(Deserializer deserializer) {
    return Uri.parse(deserializer.readObject());
  }

  @override
  void serialize(Serializer serializer, Uri object) {
    serializer.writeObject(object.toString());
  }
}
```

This is not an analogue or replacement for the JSON serializer.  
In this case, the data is serialized into a so-called stream and, if necessary, cached.  

For example, you can serialize such data.  

```dart
typedef _ComplexType = Map<Uri, List<Tuple2<BigInt, Tuple2<int, Base?>>>>;

class A extends Base {
  A(super.base);

  @override
  bool operator ==(other) => other is A && other.base == base;
}

class B extends Base {
  final int x;

  B(super.base, this.x);

  @override
  bool operator ==(other) => other is B && other.base == base && other.x == x;
}

class Base {
  final String base;

  Base(this.base);
}
```

For example, such data can be serialized.

```dart
final _ComplexType map = {
  Uri.parse('package:animals'): [
    Tuple2(BigInt.parse('1'), Tuple2(1, A('Hello'))),
    Tuple2(BigInt.parse('2'), Tuple2(1, A('Hello'))),
  ],
  Uri.parse('package:zoo'): [
    Tuple2(BigInt.parse('1'), Tuple2(1, B('Goodbye', 41))),
    Tuple2(BigInt.parse('2'), Tuple2(2, null)),
    Tuple2(BigInt.parse('1'), Tuple2(1, A('Hello'))),
  ],
};
```

Output data stream:

```dart
[1, 4, 2, 4, 16, 6, 8, package:animals, 9, 9, 2, 12, 11, 14, 15, 16, 8, 1, 19, 12, 21, 2, 1, 24, 13, 26, 8, Hello, 29, 11, 31, 15, 33, 8, 2, 36, 12, 21, 39, 13, 26, 42, 16, 44, 8, package:zoo, 47, 9, 3, 50, 11, 14, 53, 12, 21, 56, 14, 58, 8, Goodbye, 61, 2, 41, 64, 11, 31, 67, 12, 69, 2, 2, 72, 6, 74, 11, 14, 77, 12, 21, 80, 13, 26]
```

Full example:

```dart
import 'dart:isolate';

import 'package:object_serializer/object_serializer.dart';
import 'package:object_serializer/serialize.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

Future<void> main() async {
  test(
    'Example',
    () async {
      final _ComplexType map = {
        Uri.parse('package:animals'): [
          Tuple2(BigInt.parse('1'), Tuple2(1, A('Hello'))),
          Tuple2(BigInt.parse('2'), Tuple2(1, A('Hello'))),
        ],
        Uri.parse('package:zoo'): [
          Tuple2(BigInt.parse('1'), Tuple2(1, B('Goodbye', 41))),
          Tuple2(BigInt.parse('2'), Tuple2(2, null)),
          Tuple2(BigInt.parse('1'), Tuple2(1, A('Hello'))),
        ],
      };

      final stream = serializeMap(map, _collection);

      //
      final port = ReceivePort();
      final isolate =
          await Isolate.spawn<List>(compute, [port.sendPort, stream]);
      final stream2 = await port.first as List;
      isolate.kill(priority: Isolate.immediate);

      //
      final _ComplexType result = deserializeMap(stream2, _collection);
      expect(result, map);
    },
  );
}

final _collection = ObjectSerializerCollection()
  ..addSerializer(ListSerializer<Tuple2<BigInt, Tuple2<int, Base?>>>())
  ..addSerializer(_ASerializer())
  ..addSerializer(_BSerializer())
  ..addSerializer(_BigIntSerializer())
  ..addSerializer(_Tuple2Serializer<BigInt, Tuple2<int, Base?>>())
  ..addSerializer(_Tuple2Serializer<int, Base?>())
  ..addSerializer(_UriSerializer());

void compute(List args) {
  final sendPort = args[0] as SendPort;
  final input = args[1] as List;
  final _ComplexType map = deserializeMap(input, _collection);
  final output = serializeMap(map, _collection);
  sendPort.send(output);
}

typedef _ComplexType = Map<Uri, List<Tuple2<BigInt, Tuple2<int, Base?>>>>;

class A extends Base {
  A(super.base);

  @override
  bool operator ==(other) => other is A && other.base == base;
}

class B extends Base {
  final int x;

  B(super.base, this.x);

  @override
  bool operator ==(other) => other is B && other.base == base && other.x == x;
}

class Base {
  final String base;

  Base(this.base);
}

class _ASerializer extends ObjectSerializer<A> {
  @override
  A deserialize(Deserializer deserializer) {
    return A(
      deserializer.readObject(),
    );
  }

  @override
  void serialize(Serializer serializer, A object) {
    serializer.writeObject(object.base);
  }
}

class _BigIntSerializer extends ObjectSerializer<BigInt> {
  @override
  BigInt deserialize(Deserializer deserializer) {
    return BigInt.parse(deserializer.readObject());
  }

  @override
  void serialize(Serializer serializer, BigInt object) {
    serializer.writeObject('$object');
  }
}

class _BSerializer extends ObjectSerializer<B> {
  @override
  B deserialize(Deserializer deserializer) {
    return B(
      deserializer.readObject(),
      deserializer.readObject(),
    );
  }

  @override
  void serialize(Serializer serializer, B object) {
    serializer.writeObject(object.base);
    serializer.writeObject(object.x);
  }
}

class _Tuple2Serializer<T1, T2> extends ObjectSerializer<Tuple2<T1, T2>> {
  @override
  Tuple2<T1, T2> deserialize(Deserializer deserializer) {
    return Tuple2(
      deserializer.readObject(),
      deserializer.readObject(),
    );
  }

  @override
  void serialize(Serializer serializer, Tuple2<T1, T2> object) {
    serializer.writeObject(object.item1);
    serializer.writeObject(object.item2);
  }
}

class _UriSerializer extends ObjectSerializer<Uri> {
  @override
  Uri deserialize(Deserializer deserializer) {
    return Uri.parse(deserializer.readObject());
  }

  @override
  void serialize(Serializer serializer, Uri object) {
    serializer.writeObject(object.toString());
  }
}

```

For simpler or non-generic data, fewer serializers are required. But, in any case, each data requires its own serializer.

This allows any type of data to be serialized. For example, you can serialize a parsed AST.  
The main goal is to make it easier to write serializers to pass data between isolates.  

