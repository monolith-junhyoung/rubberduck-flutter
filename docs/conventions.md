---

## Overview

This guide presents a Flutter Clean Architecture implementation using Riverpod's AsyncNotifier pattern with event-driven state management. It follows a feature-based folder structure with State-Entity-DTO data flow.

### Key Characteristics

- Strict dependency inversion: dependencies flow inward (presentation → domain ← data)
- Feature-based modular structure under `lib/src/features/<feature>/`
- Riverpod 3.x with code generation (`@riverpod`)
- Freezed for immutable entities and state models (where it improves ergonomics)
- Use case pattern to encapsulate business logic
- Repository pattern to abstract data sources

### Core Principles

- **Separation of Concerns**: Each layer has a clear, distinct responsibility
- **Dependency Inversion**: Higher layers don't depend on lower layers
- **Testability**: Each layer can be tested independently
- **Scalability**: New features can be added with minimal impact on existing code
- **Event-Driven State**: Explicit, traceable state changes through events
- **Type Safety**: Dart sealed events + Riverpod; Freezed where it improves state/DTO ergonomics

---

## Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│   (UI, State, Events, AsyncNotifier)    │
│   - Widget                              │
│   - Event (User Actions)                │
│   - AsyncNotifier (Event Controller)    │
│   - AsyncValue<State>                   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          Domain Layer                   │
│      (Business Logic, Entities)         │
│   - Entity (Domain Model)               │
│   - Repository Interface                │
│   - UseCase                             │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           Data Layer                    │
│    (Data Sources, DTOs, Repository)     │
│   - DTO (Data Transfer Object)          │
│   - DataSource (Remote/Local)           │
│   - Repository Implementation           │
└─────────────────────────────────────────┘
```

---

## Layer Responsibilities & Constraints

### Presentation

- Location: `lib/src/features/<feature>/presentation/`
- Controllers extend `EventControllerNotifier` and implement `onEvent` with a `switch`.
- Events are `sealed` and follow `{Feature}{Action}Event` naming.
- UI dispatches events via `RefEventDispatcherX` (`ref.dispatch(...)`).
- Core definitions live in `lib/src/core/arch/event_controller.dart`.
- State lives with the controller unless it exceeds 100 lines.
- Do not import Data layer types in Presentation.
- Do not create nested `<feature>` folders under `presentation/`.

### Domain

- Location: `lib/src/features/<feature>/domain/`
- Entities: immutable models (Freezed is allowed and common).
- Repositories: interfaces only.
- Use Cases: one action per file, `call(params)` only.
- Do not import Presentation or Data.

### Data

- Location: `lib/src/features/<feature>/data/`
- Data Sources: remote/local interfaces + implementations.
- DTOs: conversion to/from Entities.
- Repository implementations: orchestrate data sources and map DTO ↔ Entity.
- Do not import Presentation.

### Cross-Cutting (Core)

- Location: `lib/src/core/`
- Shared utilities, base abstractions, and infrastructure that are reused across features.

---

## Folder Structure

### Feature Based

```
lib/
├── main.dart
└── src/
    ├── core/
    │   ├── arch/
    │   │   └── event_controller.dart
    │   ├── errors/
    │   │   ├── exceptions.dart
    │   │   └── failures.dart
    │   ├── network/
    │   │   └── dio_client.dart
    │   ├── providers/
    │   │   └── dio_provider.dart
    │   └── domain/
    │       └── use_case.dart
    │
    ├── features/
    │   ├── auth/
    │   │   ├── data/
    │   │   │   ├── models/                    # DTO models only
    │   │   │   │   ├── login_request_dto.dart
    │   │   │   │   ├── login_response_dto.dart
    │   │   │   │   └── user_dto.dart
    │   │   │   ├── auth_local_data_source.dart
    │   │   │   ├── auth_remote_data_source.dart
    │   │   │   └── auth_repository_impl.dart
    │   │   │
    │   │   ├── domain/
    │   │   │   ├── entities/                  # Domain entities only
    │   │   │   │   └── user_entity.dart
    │   │   │   ├── auth_repository.dart
    │   │   │   ├── login_use_case.dart
    │   │   │   ├── logout_use_case.dart
    │   │   │   └── get_current_user_use_case.dart
    │   │   │
    │   │   └── presentation/
    │   │       ├── widgets/                   # Reusable widgets only
    │   │       │   ├── login_form.dart
    │   │       │   └── password_field.dart
    │   │       ├── auth_controller.dart
    │   │       ├── auth_event.dart
    │   │       ├── auth_providers.dart
    │   │       ├── auth_state.dart
    │   │       ├── login_page.dart
    │   │       └── register_page.dart
    │   │
    │   └── todo/
    │       ├── data/
    │       │   └── models/
    │       ├── domain/
    │       │   └── entities/
    │       └── presentation/
    │           └── widgets/
```

The structure above reflects the rules below (no nested feature folders under `data/`, `domain/`, or `presentation/`).

### Key Structure Decisions

**Folders are minimal and specific:**

- `data/` - Data layer handling API calls, local storage, and data source management
- `domain/` - Business logic layer containing use cases and domain entities (framework-independent)
- `presentation/` - UI layer with pages, screens, and reusable widgets
- `data/models/` - DTOs only (create only if DTOs exist)
- `domain/entities/` - Domain entities only (create only if entities exist)
- `presentation/widgets/` - Reusable UI components only (create only if widgets exist)
- **No nested feature folders** inside `data/`, `domain/`, or `presentation/`.
- Only the allowed subfolders may exist (e.g., `data/models`, `domain/entities`, `presentation/widgets`).

### Code Organization (Feature-First Structure)

This section is the architecture implementation of `.specify/memory/constitution.md` **3. Code Organization (Feature-First Structure)**.

- Follow feature-based folder structure: `lib/src/features/<feature>/{data,domain,presentation}/`
- No nested feature folders under `data/`, `domain/`, or `presentation/`
- Only allowed subfolders: `data/models/`, `domain/entities/`, `presentation/widgets/`
- Never create empty directories; only create folders when files will occupy them
- Maximum file length: 500 lines (split if exceeded; State exceeds 100 lines → separate file)
- File naming: `snake_case.dart`; class naming: `PascalCase`

⚠️ Rule: Never create empty directories. Only create folders when you have files to place in them.

**Files are organized by type within a feature:**

- Repository implementations: `{feature}_repository_impl.dart`
- Data Sources: `{feature}_{type}_data_source.dart`
- Use Cases: `{action}_use_case.dart`
- Pages: `{name}_page.dart` (inside `presentation/`)
- Controllers: `{feature}_controller.dart` (inside `presentation/`)
- Providers: `{feature}_providers.dart` (inside `presentation/`)

### Configuration and Constants

Avoid single, global constants files. Use one of these patterns instead:

- Feature-scoped config: `lib/src/features/<feature>/data/<feature>_config.dart`
- Core config for shared settings: `lib/src/core/config/app_config.dart`
- Environment values via `--dart-define` + a small `AppEnv` wrapper
- Remote config or backend-driven flags for runtime tuning

Each constant should live near the code it affects, with clear naming and ownership.

---

## Data Flow

### Complete Data Flow Diagram

```
User Interaction
      ↓
┌─────────────────────────────────────────┐
│  Presentation Layer                     │
│  Widget → dispatches Event              │
│           ↓                             │
│  AsyncNotifier controller handles Event │
│           ↓                             │
│  calls UseCase                          │
│           ↓                             │
│  updates AsyncValue<State>              │
│  - AsyncLoading                         │
│  - AsyncData<State>                     │
│  - AsyncError                           │
│           ↓                             │
│  Widget rebuilds via ref.watch()        │
└─────────────┬───────────────────────────┘
              ↓ calls
┌─────────────────────────────────────────┐
│  Domain Layer                           │
│  UseCase (Business Logic)               │
│           ↓                             │
│  processes Entity                       │
│  - Pure Dart objects                    │
│  - Business rules                       │
│           ↓ through                     │
│  Repository Interface                   │
└─────────────┬───────────────────────────┘
              ↓ implements
┌─────────────────────────────────────────┐
│  Data Layer                             │
│  Repository Implementation              │
│           ↓                             │
│  DataSource (Remote/Local)              │
│           ↓                             │
│  DTO (Data Transfer Object)             │
│  - JSON serialization                   │
│  - API response mapping                 │
│           ↓ converts to                 │
│  Entity                                 │
└─────────────────────────────────────────┘
```

### Event-Driven Flow with AsyncNotifier

```
1. User Action (Button Click)
      ↓
2. Widget dispatches Event
   ref.dispatch(authControllerProvider, const AuthSignInEvent())
      ↓
3. Controller routes events via `onEvent` (switch) to private handlers
      ↓
4. AsyncValue automatically handles states
   - AsyncLoading (during execution)
   - AsyncData<State> (on success)
   - AsyncError (on failure)
      ↓
5. Widget listens to state changes
   ref.watch(authControllerProvider).when(
     loading: () => CircularProgressIndicator(),
     data: (state) => /* render state */,
     error: (error, stack) => /* show error */,
   )
```

### Event Dispatch Pattern

- UI dispatches events through `RefEventDispatcherX` (`ref.dispatch(...)`).
- Controllers extend `EventControllerNotifier` and implement `onEvent` with a `switch` over sealed events.
- Event routing lives in `onEvent`; no handler registration or init hooks.
- Optional: override `log` to plug in event observability.
- Reference implementation: `lib/src/core/arch/event_controller.dart`.

### State, Entity, DTO Conversion Flow

```
API Response (JSON)
      ↓
Dto.fromJson()
      ↓
DTO (Data Layer)
      ↓
dto.toEntity()
      ↓
Entity (Domain Layer)
      ↓
UseCase processes Entity
      ↓
AsyncNotifier wraps in State
      ↓
AsyncValue<State> (Presentation Layer)
      ↓
Widget watches AsyncValue
      ↓
Widget displays UI
```

---

## Key Rules

### Critical Architecture Rules

#### 1. Freezed Usage Rules

```dart
// ✅ CORRECT: All freezed models are abstract classes
@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({...}) = _UserEntity;
}

// ✅ CORRECT: Always generate both files
// user_entity.freezed.dart
// user_dto.g.dart (if using json_serializable)

// ❌ WRONG: Don't make freezed class non-abstract
@freezed
class UserEntity with _$UserEntity { // Missing 'abstract'
```

#### 2. File and Class Naming Rules

```dart
// ❌ WRONG: Don't use generic names
// Bad file names:
- utils.dart
- helpers.dart
- common.dart
- base.dart

// ✅ CORRECT: Use specific, declarative names
// Good file names:
- email_validator.dart
- date_formatter.dart
- network_error_handler.dart
- auth_token_registry.dart

> Forbidden ambiguity (explicit): avoid `utils.dart`, `helpers.dart`, `Util`, `Helper`, `Manager`.

// ✅ CORRECT: Class names should be explicit
class EmailValidator { }           // Good: Specific purpose
class DateFormatter { }            // Good: Clear responsibility
class NetworkErrorHandler { }      // Good: Descriptive

// ❌ WRONG: Generic class names
class Util { }                     // Wrong: Too generic
class Helper { }                   // Wrong: Unclear purpose
class Manager { }                  // Wrong: Too vague
```

#### 3. Meaningful Naming Rules

**Variables and parameters should be:**

- **Specific**: Describe exactly what they contain
- **Predictable**: Follow consistent patterns
- **Explicit**: No abbreviations unless universally known

```dart
// ✅ CORRECT: Meaningful variable names
final authenticatedUser = await _loginUseCase(...);
final activeTodoList = todos.where((t) => !t.isCompleted).toList();
final emailValidationError = _validateEmail(email);

// ❌ WRONG: Unclear variable names
final data = await _loginUseCase(...);     // What data?
final list = todos.where(...);             // What list?
final err = _validateEmail(email);         // Abbreviation

// ✅ CORRECT: Descriptive event field names
// todoTitle, todoDescription

// ❌ WRONG: Generic event field names
// title, desc
```

#### 4. State Management with AsyncValue

```dart
state = const AsyncLoading();
state = await AsyncValue.guard(() async => /* use case */);
```

Do not add loading variants to State; AsyncValue already covers loading.

#### 5. State File Placement Rule

- If the State model is **under 100 lines**, keep it in the same file as its Controller.
- If the State model is **100 lines or more**, move it to its own file in the same folder.

#### 6. Layer Dependency Rules

```dart
// ✅ CORRECT: Dependencies flow inward
// Presentation → Domain ← Data

// Presentation can import:
import 'package:app/features/auth/domain/entities/user_entity.dart';  // ✅
import 'package:app/features/auth/domain/login_use_case.dart';         // ✅

// ❌ WRONG: Presentation importing Data
import 'package:app/features/auth/data/models/user_dto.dart';         // ❌

// ❌ WRONG: Domain importing Presentation or Data
import 'package:app/features/auth/presentation/auth_controller.dart';   // ❌
import 'package:app/features/auth/data/auth_repository_impl.dart';    // ❌
```

#### 7. DTO to Entity Conversion Rules

```dart
// ✅ CORRECT: Conversion methods in DTO
class UserDto {
  // toEntity in DTO (Data → Domain)
  UserEntity toEntity() {
    return UserEntity(...);
  }

  // fromEntity in DTO (Domain → Data)
  factory UserDto.fromEntity(UserEntity entity) {
    return UserDto(...);
  }
}

// ❌ WRONG: Conversion in Entity
class UserEntity {
  UserDto toDto() { }  // ❌ Entity shouldn't know about DTO
}
```

#### 8. Provider Organization Rules

```dart
// ✅ CORRECT: One provider file per feature
// auth_providers.dart contains ALL auth-related providers
@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) => ...;

@riverpod
AuthRepository authRepository(Ref ref) => ...;

@riverpod
LoginUseCase loginUseCase(Ref ref) => ...;

@riverpod
class AuthController extends _$AuthController { ... }

// ❌ WRONG: Explicit Provider declarations
final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(...);

// ❌ WRONG: Scattered providers across multiple files
// Don't split providers into separate files per type
```

#### 9. Error Handling Rules

```dart
// ✅ CORRECT: Let AsyncValue.guard handle errors
state = await AsyncValue.guard(() async {
  final result = await _useCase(...);
  return switch (result) {
    Result.ok(:final value) => SuccessState(value),
    Result.error(:final error) => throw error, // Throw to be caught by guard
  };
});

// ❌ WRONG: Manual error catching loses stack trace
try {
  final result = await _useCase(...);
  state = AsyncData(result);
} catch (e) {
  state = AsyncError(e, StackTrace.current);  // Wrong stack trace
}
```

#### 10. Use Case Parameter Rules

```dart
// ✅ CORRECT: Use Freezed for parameters
@freezed
abstract class LoginParams with _$LoginParams {
  const factory LoginParams({
    required String email,
    required String password,
  }) = _LoginParams;
}

// ✅ CORRECT: Use NoParams when no parameters needed
class GetCurrentUserUseCase implements UseCase<UserEntity, NoParams> {
  Future<Result<UserEntity>> call(NoParams params) async { }
}

// ❌ WRONG: Don't use Map for parameters
class LoginUseCase {
  Future<Result<UserEntity>> call(Map<String, dynamic> params) { }
}
```

#### 11. Dispatch-Only State Changes

- UI must call controller `dispatch` only (via `RefEventDispatcherX`).
- Forbidden: calling controller methods directly or mutating state outside `dispatch`.
- Controller public API = `dispatch`; handler methods are private and start with `_on`.
- Route events in `onEvent` using a `switch` over sealed events.
- Inside handlers, update state via `AsyncValue.guard` or explicit `AsyncLoading`.

```dart
// ✅ Allowed
ref.dispatch(authControllerProvider, const AuthSignInEvent());

// ❌ Forbidden (outside dispatch)
ref.read(authControllerProvider.notifier)._onSignIn(AuthSignInEvent());
state = state.copyWith(...);
```

#### 12. Events Must Be Sealed

```dart
sealed class AuthEvent {
  const AuthEvent();
}

final class AuthSignInEvent extends AuthEvent {
  const AuthSignInEvent();
}

final class AuthSignOutEvent extends AuthEvent {
  const AuthSignOutEvent();
}
```

#### 13. Event Observability (Logging)

- Log every `dispatch` with event name, timestamp, and state before/after.
- Implement via a core `EventLogger` provider or app-level observer.
- Keep logs behind environment flags.

```dart
void _log(AuthEvent event, AsyncValue<AuthState> before, AsyncValue<AuthState> after) =>
    ref.read(eventLoggerProvider).log(event: event, before: before, after: after);
```

---

## Naming Conventions

### File Naming Rules

#### Domain Layer

```
{name}_entity.dart              Example: user_entity.dart
{feature}_repository.dart       Example: auth_repository.dart
{action}_use_case.dart          Example: login_use_case.dart
```

#### Data Layer

```
{name}_dto.dart                Example: user_dto.dart
{action}_request_dto.dart      Example: login_request_dto.dart
{action}_response_dto.dart     Example: login_response_dto.dart
{feature}_repository_impl.dart Example: auth_repository_impl.dart
{feature}_{type}_data_source.dart Example: auth_remote_data_source.dart
```

#### Presentation Layer

```
{feature}_state.dart           Example: auth_state.dart
{feature}_event.dart           Example: auth_event.dart
{feature}_controller.dart      Example: auth_controller.dart
{feature}_providers.dart       Example: auth_providers.dart
{name}_page.dart              Example: login_page.dart
{descriptive}_widget.dart     Example: password_input_field.dart
```

### Class Naming Rules

#### Domain Layer

```dart
{Name}Entity                   Example: UserEntity, TodoEntity
{Feature}Repository            Example: AuthRepository
{Action}UseCase               Example: LoginUseCase, GetTodosUseCase
{Action}Params                Example: LoginParams, CreateTodoParams
```

#### Data Layer

```dart
{Name}Dto                     Example: UserDto, TodoDto
{Action}RequestDto            Example: LoginRequestDto
{Action}ResponseDto           Example: LoginResponseDto
{Feature}RepositoryImpl       Example: AuthRepositoryImpl
{Feature}{Type}DataSource     Example: AuthRemoteDataSource
{Feature}{Type}DataSourceImpl Example: AuthRemoteDataSourceImpl
```

#### Presentation Layer

```dart
{Feature}State                Example: AuthState, TodoState
{Feature}Controller           Example: AuthController, TodoController
{Feature}{Action}Event        Example: AuthSignInEvent, TodoCreateEvent
{Name}Page                    Example: LoginPage, TodoListPage
{Descriptive}Widget           Example: PasswordInputField, TodoListItem
```

### Event & Handler Naming Rules

- Events are `sealed` and end with `Event`.
- Use `{Feature}{Action}Event` (AuthSignInEvent, AuthSignOutEvent, TodoCreateEvent).
- `Feature` refers to the top-level folder under `lib/src/features/<feature>/`.
- For snake_case feature folders (e.g., `plan_pal`), use UpperCamelCase in class names (PlanPalLoadEvent).
- Avoid request-style suffixes like `Requested`/`Started` unless the domain requires it.
- Handler methods are private and must start with `_on`.
- Do not use `handle` / `_handle` prefixes.

```dart
// ✅ CORRECT
Future<void> _onSignIn(AuthSignInEvent event) async { }

// ❌ WRONG
Future<void> handleLogin(...) async { }
```

### Provider Naming Rules

```dart
// Provider naming pattern: {feature}{Type}Provider

// Data Source providers
@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) => ...;

@riverpod
TodoLocalDataSource todoLocalDataSource(Ref ref) => ...;

// Repository providers
@riverpod
AuthRepository authRepository(Ref ref) => ...;

@riverpod
TodoRepository todoRepository(Ref ref) => ...;

// Use Case providers
@riverpod
LoginUseCase loginUseCase(Ref ref) => ...;

@riverpod
GetTodosUseCase getTodosUseCase(Ref ref) => ...;

// Controller providers
// Generated by @riverpod on controller classes.
// Example: authControllerProvider, todoControllerProvider
```

### Method Naming Rules

#### Event Controllers in AsyncNotifier

```dart
// Route events in onEvent
Future<void> onEvent(AuthEvent event) => switch (event) {
      AuthSignInEvent e => _onSignIn(e),
      AuthSignOutEvent e => _onSignOut(e),
    };

// Handler methods: _on{Action} (private)
Future<void> _onSignIn(AuthSignInEvent event) async { }
Future<void> _onCreateTodo(TodoCreateEvent event) async { }

// Other private controller methods
Future<void> _onTokenRefreshed() async { }
Future<void> _onDataSynced() async { }
```

#### UseCase Methods

```dart
// Always use 'call' method
class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  @override
  Future<Result<UserEntity>> call(LoginParams params) async { }
}
```

#### Helper Methods (Private)

```dart
// Action-oriented names
List<TodoEntity> _filterCompletedTodos(List<TodoEntity> todos) { }
bool _isEmailValid(String email) { }
String _formatDate(DateTime date) { }

// NOT generic names
void _process() { }        // ❌ Too generic
void _handle() { }         // ❌ Unclear
void _doSomething() { }    // ❌ Meaningless
```

### Freezed Union Variant Naming

#### State Variants

```dart
@freezed
abstract class AuthState with _$AuthState {
  // Initial state
  const factory AuthState.initial() = AuthInitial;

  // Success states (past participle or descriptive)
  const factory AuthState.authenticated({
    required UserEntity user,
  }) = AuthAuthenticated;

  const factory AuthState.unauthenticated() = AuthUnauthenticated;
}

@freezed
abstract class TodoState with _$TodoState {
  const factory TodoState.initial() = TodoInitial;

  const factory TodoState.loaded({
    required List<TodoEntity> todos,
  }) = TodoLoaded;

  const factory TodoState.empty() = TodoEmpty;
}
```

### Variable Naming Best Practices

```dart
// ✅ CORRECT: Descriptive and specific
final authenticatedUser = result.user;
final completedTodoList = todos.where((t) => t.isCompleted).toList();
final emailValidationErrorMessage = validator.validate(email);
final isUserAuthenticated = authState is AuthAuthenticated;

// ❌ WRONG: Generic or abbreviated
final user = result.user;              // Which user? Current? New?
final list = todos.where(...);         // What list?
final msg = validator.validate(email); // Abbreviation
final isAuth = authState is AuthAuthenticated; // Unclear
```

---

## Dispatch Helper (Recommended)

Use the shared helper defined in `lib/src/core/arch/event_controller.dart`:

```dart
extension RefEventDispatcherX on Ref {
  Future<void> dispatch<E, S, N extends EventControllerNotifier<S, E>>(
    AsyncNotifierProvider<N, S> provider,
    E event,
  ) => read(provider.notifier).dispatch(event);
}
```

## Build & Test (Short)

- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter test`
