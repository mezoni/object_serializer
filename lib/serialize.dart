import 'object_serializer.dart';

T deserialize<T>(List stream, ObjectSerializerCollection collection) {
  final deserializer = Deserializer(collection: collection);
  return deserializer.deserialize(stream);
}

List<T> deserializeList<T>(List stream, ObjectSerializerCollection collection) {
  final deserializer = Deserializer(collection: collection);
  return deserializer.deserializeList(stream);
}

Map<K, V> deserializeMap<K, V>(
    List stream, ObjectSerializerCollection collection) {
  final deserializer = Deserializer(collection: collection);
  return deserializer.deserializeMap(stream);
}

Set<T> deserializeSet<T>(List stream, ObjectSerializerCollection collection) {
  final deserializer = Deserializer(collection: collection);
  return deserializer.deserializeSet(stream);
}

List serialize<T>(T object, ObjectSerializerCollection collection) {
  final serializer = Serializer(collection: collection);
  return serializer.serialize(object);
}

List serializeList<T>(List<T> object, ObjectSerializerCollection collection) {
  final serializer = Serializer(collection: collection);
  return serializer.serializeList(object);
}

List serializeMap<K, V>(
    Map<K, V> object, ObjectSerializerCollection collection) {
  final serializer = Serializer(collection: collection);
  return serializer.serializeMap(object);
}

List serializeSet<T>(Set<T> object, ObjectSerializerCollection collection) {
  final serializer = Serializer(collection: collection);
  return serializer.serializeSet(object);
}
