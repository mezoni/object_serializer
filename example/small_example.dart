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

class Post {
  Post(
      {required this.id,
      required this.user,
      required this.text,
      required this.comments});

  factory Post.fromJson(Map json) {
    return Post(
      id: json['id'] as int,
      user: User.fromJson(json['user'] as Map),
      text: json['text'] as String,
      comments: json['comments'] == null
          ? null
          : (json['comments'] as List).map((e) => e as int).toList(),
    );
  }

  final int id;

  final User user;

  final String text;

  final List<int>? comments;

  static List<Post> fromJsonList(List json) {
    return json.map((e) => Post.fromJson(e as Map)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'text': text,
      'comments': comments,
    };
  }

  static List<Map<String, dynamic>> toJsonList(List<Post> list) {
    return list.map((e) => e.toJson()).toList();
  }
}

class User {
  User({required this.id, required this.name, required this.age});

  factory User.fromJson(Map json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      age: json['age'] == null ? null : 0,
    );
  }

  final int id;

  final String name;

  final int? age;

  static List<User> fromJsonList(List json) {
    return json.map((e) => User.fromJson(e as Map)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  static List<Map<String, dynamic>> toJsonList(List<User> list) {
    return list.map((e) => e.toJson()).toList();
  }
}
