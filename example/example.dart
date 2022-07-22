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
