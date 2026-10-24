# Flutter Unit Testing & Mocking Reference

Reference: [An Introduction to Unit Testing](https://docs.flutter.dev/cookbook/testing/unit/introduction) & [Mocking](https://docs.flutter.dev/cookbook/testing/unit/mocking)

## 1. Test Standards
- Every unit test file must reside under `test/` and end with `_test.dart`.
- Group related tests logically using `group('Component/Feature', () { ... })`.
- Separate Arrange, Act, and Assert steps clearly.

## 2. Templates
- Reference unit test template: [unit_test.dart.template](../resources/templates/unit_test.dart.template)
- Reference BLoC test template: [bloc_test.dart.template](../resources/templates/bloc_test.dart.template)
