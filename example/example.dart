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

class Company {
  Company({required this.name, required this.website});

  factory Company.fromJson(Map json) {
    return Company(
      name: json['name'] as String,
      website: _UriSerializer.deserialize(json['website']),
    );
  }

  final String name;

  final Uri website;

  static List<Company> fromJsonList(List json) {
    return json.map((e) => Company.fromJson(e as Map)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'website': _UriSerializer.serialize(website),
    };
  }

  static List<Map<String, dynamic>> toJsonList(List<Company> list) {
    return list.map((e) => e.toJson()).toList();
  }
}

class Customer {
  Customer(
      {required this.age,
      required this.birthday,
      required this.frequency,
      required this.level,
      required this.name});

  factory Customer.fromJson(Map json) {
    return Customer(
      age: json['age'] == null ? null : 0,
      birthday: json['birthday'] == null
          ? null
          : _DateTimeSerializer.deserialize(json['birthday']),
      frequency: _DurationSerializer.deserialize(json['frequency']),
      level: _CustomerLevelSerializer.deserialize(json['customer_level']),
      name: json['name'] as String,
    );
  }

  final int? age;

  final DateTime? birthday;

  final Duration frequency;

  final CustomerLevel level;

  final String name;

  static List<Customer> fromJsonList(List json) {
    return json.map((e) => Customer.fromJson(e as Map)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'birthday': birthday == null
          ? null
          : _DateTimeSerializer.serialize(birthday as DateTime),
      'frequency': _DurationSerializer.serialize(frequency),
      'customer_level': _CustomerLevelSerializer.serialize(level),
      'name': name,
    };
  }

  static List<Map<String, dynamic>> toJsonList(List<Customer> list) {
    return list.map((e) => e.toJson()).toList();
  }
}

class Order {
  Order(
      {required this.amount,
      required this.company,
      required this.customer,
      required this.date,
      required this.lines});

  factory Order.fromJson(Map json) {
    return Order(
      amount: _BigIntSerializer.deserialize(json['amount']),
      company: Company.fromJson(json['company'] as Map),
      customer: Customer.fromJson(json['customer'] as Map),
      date: _DateTimeSerializer.deserialize(json['date']),
      lines: json['lines'] == null
          ? []
          : (json['lines'] as List)
              .map((e) => OrderLine.fromJson(e as Map))
              .toList(),
    );
  }

  final BigInt amount;

  final Company company;

  final Customer customer;

  final DateTime date;

  final List<OrderLine> lines;

  static List<Order> fromJsonList(List json) {
    return json.map((e) => Order.fromJson(e as Map)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': _BigIntSerializer.serialize(amount),
      'company': company.toJson(),
      'customer': customer.toJson(),
      'date': _DateTimeSerializer.serialize(date),
      'lines': lines.map((e) => e.toJson()).toList(),
    };
  }

  static List<Map<String, dynamic>> toJsonList(List<Order> list) {
    return list.map((e) => e.toJson()).toList();
  }
}

class OrderLine {
  OrderLine(
      {required this.product,
      required this.price,
      required this.quantity,
      required this.total});

  factory OrderLine.fromJson(Map json) {
    return OrderLine(
      product: Product.fromJson(json['product'] as Map),
      price: _BigIntSerializer.deserialize(json['price']),
      quantity: json['quantity'] as int,
      total: _BigIntSerializer.deserialize(json['total']),
    );
  }

  final Product product;

  final BigInt price;

  final int quantity;

  final BigInt total;

  static List<OrderLine> fromJsonList(List json) {
    return json.map((e) => OrderLine.fromJson(e as Map)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'price': _BigIntSerializer.serialize(price),
      'quantity': quantity,
      'total': _BigIntSerializer.serialize(total),
    };
  }

  static List<Map<String, dynamic>> toJsonList(List<OrderLine> list) {
    return list.map((e) => e.toJson()).toList();
  }
}

class Product {
  Product({required this.name, required this.price, required this.priceRange});

  factory Product.fromJson(Map json) {
    return Product(
      name: json['name'] as String,
      price: _BigIntSerializer.deserialize(json['price']),
      priceRange: json['priceRange'] == null
          ? {}
          : (json['priceRange'] as Map)
              .map((k, v) => MapEntry(k as String, v as double)),
    );
  }

  final String name;

  final BigInt price;

  final Map<String, double> priceRange;

  static List<Product> fromJsonList(List json) {
    return json.map((e) => Product.fromJson(e as Map)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': _BigIntSerializer.serialize(price),
      'priceRange': priceRange.map(MapEntry.new),
    };
  }

  static List<Map<String, dynamic>> toJsonList(List<Product> list) {
    return list.map((e) => e.toJson()).toList();
  }
}

enum CustomerLevel { retail, wholesale }

class _BigIntSerializer {
  static BigInt deserialize(Object? value) {
    final json = value as String;
    return BigInt.parse(json);
  }

  static Object? serialize(BigInt value) {
    return value.toString();
  }
}

class _DateTimeSerializer {
  static DateTime deserialize(Object? value) {
    final json = value as String;
    return DateTime.fromMicrosecondsSinceEpoch(int.parse(json));
  }

  static Object? serialize(DateTime value) {
    return value.microsecondsSinceEpoch.toString();
  }
}

class _CustomerLevelSerializer {
  static CustomerLevel deserialize(Object? value) {
    final json = value as int;
    return CustomerLevel.values[json];
  }

  static Object? serialize(CustomerLevel value) {
    return value.index;
  }
}

class _DurationSerializer {
  static Duration deserialize(Object? value) {
    final json = value as String;
    return Duration(microseconds: int.parse(json));
  }

  static Object? serialize(Duration value) {
    return value.inMicroseconds.toString();
  }
}

class _UriSerializer {
  static Uri deserialize(Object? value) {
    final json = value as String;
    return Uri.parse(json);
  }

  static Object? serialize(Uri value) {
    return value.toString();
  }
}
