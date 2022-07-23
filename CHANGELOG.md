# 0.2.0

- Breaking change in `SimpleJsonSerializerGenerator`. To enhance the generation of classes and enumerations, fields and values should now be located under attributes `fields` and `values`, respectively.
- Added the ability to specify a superclass (`extends`) for the class
- Added the ability to specify custom serialization functions for class fields (`deserialize`, `serialize`)

# 0.1.8

- Added code generation example to `README.md` file

# 0.1.7

- Fixed bug in helper function `serialize`
- Added the ability to specify default values for fields

# 0.1.6

- Added small code fix

# 0.1.5

- Improved simple code generator `SimpleJsonSerializerGenerator`
- Improved  an example of using the code generator `SimpleJsonSerializerGenerator`

# 0.1.4

- Added simple code generator `SimpleJsonSerializerGenerator`
- Added an example of using the code generator `SimpleJsonSerializerGenerator`

# 0.1.3

- Added `JsonSerializer` serializer.

# 0.1.2

- Improved serialization performance by 30%. It's about the algorithm for finding a serializer for an object. In the case where the type of the object (by type argument) was known at the time serialization was started, finding a serializer for the this type (using a lookup table) would be faster than searching through all serializers, testing the object in each serializer (`canSerialize(Object? object) => object is T`). The more types are used for serialization, the more noticeable will be the difference in serialization speed with the previous version.

# 0.1.1

- Simplified example code.

## 0.1.0

- Initial release