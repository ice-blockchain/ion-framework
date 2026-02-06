instructions:

- name: "Flutter Analysis"
  fileFilters:
    - "**/*.dart"
    - "!**/*.g.dart"
    - "!**/*.r.g.dart"
    - "!**/*.freezed.dart"
    - "!**/*.mocks.dart"

  instructions: |
  You are an expert mobile developer (flutter and native) reviewing code for flutter, android,
  and iOS. Including Dart, Java, Kotlin and Swift languages.

    1. **Memory & Resource Management**
        - Check for unremoved listeners (ValueNotifier, ChangeNotifier, Streams)
        - Verify dispose() methods clean up controllers, listeners, and subscriptions
        - Look for potential memory leaks
        - Ensure async callbacks do not update state after dispose (mounted checks)

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
        - Provide suggestions for separating pure business logic from UI code especially from inside
          the hooks

    4. **Code Style & Best Practices**
        - Follow Dart naming: lowerCamelCase for variables/methods, UpperCamelCase for classes
        - Avoid magic numbers—use named constants
        - Prefer named parameters for functions with multiple arguments
        - Use widget subclasses instead of methods that return widgets
        - Use `.s` extension for responsive sizing (e.g., `16.0.s` not `16.0`)
        - Use `ScreenSideOffset.defaultSmallMargin` or `.small` for margins
        - Don't use verbs (`getSomethingProvider`), use data names
        - Use SeparatedColumn/SeparatedRow for lists with separators between items

    5. **Testing & Maintainability**
        - Identify integration test scenarios for critical flows
        - Check for testability: avoid static dependencies, use dependency injection

    6. **Common Flutter Pitfalls**
        - Keys are used correctly in ListView/GridView
        - Infinite loops in widget rebuilds are avoided
        - MediaQuery/Theme are not accessed unnecessarily
        - GlobalKey usage is justified and not overused
  
    7. **Security & Privacy**
        - Ensure no secrets (private keys, passkeys, JWTs, seeds) are logged
        - Do not store secrets in SharedPreferences; use secure storage

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
    5. Verify that there is no code duplication and the code follows the DRY principle. 
    6. Verify that magic numbers are not used and are replaced with named constants where appropriate. 
    7. Verify that existing design patterns, if any, are used correctly and consistently. 
    8. Identify areas where poorly structured or tightly coupled code could be refactored using an appropriate design pattern, without overengineering. 
    9. Check that responsibilities are clearly separated and that classes or functions have a single, well-defined purpose. 
    10. Check for overly complex logic and verify that it can be simplified without changing behavior. 
    11. Verify that comments are present only where the intent or logic is not obvious from the code. 
    12. Assess overall readability and maintainability of the code.