instructions:

- name: "Flutter Analysis"
  fileFilters:
    - "**/*.dart"
    - "!**/*.g.dart"
    - "!**/*.r.g.dart"
    - "!**/*.freezed.dart"
    - "!**/*.mocks.dart"
      instructions: |
      You are an expert mobile developer(flutter and native) reviewing code for flutter, android,
      and iOS. Including Dart, Java, Kotlin and Swift languages.

    1. **Memory & Resource Management**
        - Check for unremoved listeners (ValueNotifier, ChangeNotifier, Streams)
        - Verify dispose() methods clean up controllers, listeners, and subscriptions
        - Look for potential memory leaks

    2. **Null Safety & Error Handling**
        - Verify null-aware operators (?., ??) are used correctly
        - Verify there is no usage of force unwrapping (!) or as it is called in dart the bang
          operator
        - Check for proper null checks before accessing nullable properties
        - Ensure async operations have try-catch blocks with appropriate error handling
        - Validate BuildContext usage doesn't cross async gaps

    3. **Performance Optimization**
        - Use `const` constructors where possible to reduce rebuilds
        - Check for unnecessary widget rebuilds (use const, keys, or memoization)
        - Verify hooks and child widgets are used instead of builders
        - Look for expensive operations in build() methods
        - Ensure proper use of RepaintBoundary for complex widgets
        - Make sure there are no hooks inside conditions or loops
        - Avoid large widget trees in single build methods
        - Prefer stateless and hook widgets instead of stateful widgets
        - Provide suggestions for separating pure business logic from UI code specially from inside
          the hooks

    4. **Code Style & Best Practices**
        - Follow Dart naming: lowerCamelCase for variables/methods, UpperCamelCase for classes
        - Avoid magic numbers—use named constants
        - Prefer named parameters for functions with multiple arguments
        - Use widget subclasses instead of methods that return widgets

    5. **Testing & Maintainability**
        - Identify integration test scenarios for critical flows
        - Check for testability: avoid static dependencies, use dependency injection

    6. **Common Flutter Pitfalls**
        - Keys are used correctly in ListView/GridView
        - Infinite loops in widget rebuilds are avoided
        - MediaQuery/Theme are not accessed unnecessarily
        - GlobalKey usage is justified and not overused

- name: "General Code Quality"
  fileFilters:
    - "**/*"
    - "!**/*.md"
    - "!**/*.yaml"
    - "!**/*.g.dart"
    - "!**/*.r.g.dart"
    - "!**/*.freezed.dart"
      instructions: |

    1. Add meaningful comments for complex logic.
    2. Ensure no secrets or environment values are hardcoded.
    3. Verify proper use of linters (flutter analyze).
    4. Maintain architectural consistency (e.g., separation of concerns).