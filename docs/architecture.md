# Architecture

**Analysis Date:** 2026-04-09

## Purpose

This document explains how the RubberDuck Pilot project should apply the target architecture defined in [conventions.md](/Users/junhyounglee/workspace/rubberduck-flutter/docs/conventions.md).

`docs/conventions.md` is the source of truth for structure and implementation rules. This document stays aligned with that baseline and maps the target architecture onto this project's actual feature set and migration work.

## Architectural Baseline

The project target is:

- Flutter Clean Architecture
- feature-based structure under `lib/src/features/<feature>/`
- Presentation, Domain, and Data layers inside each feature
- Riverpod AsyncNotifier pattern with event-driven state management
- Freezed-backed immutable state and entities where useful
- shared cross-feature utilities under `lib/src/core/`

The current codebase does not fully follow this structure yet. The target architecture is the destination, not a description of the current layout.

## Target Project Structure

```text
lib/
├── main.dart
└── src/
    ├── core/
    │   ├── arch/
    │   ├── config/
    │   ├── domain/
    │   ├── errors/
    │   ├── network/
    │   └── providers/
    └── features/
        ├── launch/
        │   ├── data/
        │   │   └── models/
        │   ├── domain/
        │   │   └── entities/
        │   └── presentation/
        │       └── widgets/
        └── duck_pilot/
            ├── data/
            │   └── models/
            ├── domain/
            │   │   └── entities/
            └── presentation/
                └── widgets/
```

## Feature Mapping

### Launch Feature

The `launch` feature should own all app-entry and deep-link behavior.

Responsibilities:

- parse incoming app links
- validate launch URLs and required parameters
- represent launch success and failure states
- show waiting UI when no valid launch data exists
- handle in-app relaunch confirmation flow
- hand off resolved runtime information to downstream features

Target location:

- `lib/src/features/launch/presentation/`
- `lib/src/features/launch/domain/`
- `lib/src/features/launch/data/`

### Duck Pilot Feature

The gameplay controller feature should be named `duck_pilot`.

Responsibilities:

- duck pilot gameplay page and widgets
- player/session interaction state
- event-driven controller logic
- gyro-based input behavior
- movement direction and transmission rules
- realtime join flow
- PubSub transport, bootstrap, and message protocol integration owned by this feature

Target location:

- `lib/src/features/duck_pilot/presentation/`
- `lib/src/features/duck_pilot/domain/`
- `lib/src/features/duck_pilot/data/`

The previous `controller` feature name should be treated as transitional only.

## Layer Application In This Project

### Presentation

In this project, Presentation should contain:

- pages
- widgets
- event types
- AsyncNotifier controllers
- `AsyncValue<State>` driven state
- provider files for feature wiring

This follows the baseline in [conventions.md](/Users/junhyounglee/workspace/rubberduck-flutter/docs/conventions.md):

- controllers belong in `presentation/`
- events are sealed
- UI dispatches events through `ref.dispatch(...)`
- state lives with the controller unless it grows large enough to extract

### Domain

In this project, Domain should contain:

- entities
- repository interfaces
- use cases
- pure business rules such as direction resolution or launch validation rules

Domain must not depend on Presentation or Data implementations.

### Data

In this project, Data should contain:

- DTOs
- repository implementations
- local or remote data sources
- feature-owned bootstrap clients
- PubSub clients and codecs when they are only used by `duck_pilot`
- app-link sources when they are only used by `launch`

Data must not depend on Presentation.

## Current Gap From Target

The current codebase is still in a transitional structure.

- `lib/app/launch/` should move into `lib/src/features/launch/`
- `lib/features/controller/` should be renamed and moved to `lib/src/features/duck_pilot/`
- `lib/features/controller/application/` should be removed because controller logic belongs in `presentation/`
- `lib/infrastructure/pubsub/` should move under `lib/src/features/duck_pilot/data/`
- `lib/core/` should be reviewed and split into `lib/src/core/` according to actual cross-feature ownership

These are migration targets, not structures to preserve.

## Migration Plan

### Launch Migration

1. Create `lib/src/features/launch/presentation/`, `domain/`, and `data/`.
2. Move the launch entry page and waiting UI into `presentation/`.
3. Move launch parser and related launch result or entity types into `domain/`.
4. Move app-link source integration into `data/`.
5. Keep only minimal app composition logic outside the feature.

Expected mapping:

- `lib/app/launch/app_link_page.dart` -> `lib/src/features/launch/presentation/app_link_page.dart`
- `lib/app/launch/launch_state.dart` -> `lib/src/features/launch/presentation/launch_state.dart`
- `lib/app/launch/launch_link_parser.dart` -> `lib/src/features/launch/domain/launch_link_parser.dart`

### Controller To Pilot Migration

1. Rename the feature from `controller` to `duck_pilot`.
2. Create `lib/src/features/duck_pilot/presentation/`, `domain/`, and `data/`.
3. Fold `application/` contents into `presentation/`.
4. Move pure rules into `domain/`.
5. Move PubSub integration into `data/`.
6. Update imports, providers, tests, and feature names to `duck_pilot`.

Expected mapping:

- `lib/features/controller/presentation/pilot_page.dart` -> `lib/src/features/duck_pilot/presentation/duck_pilot_page.dart`
- `lib/features/controller/application/pilot_view_model.dart` -> `lib/src/features/duck_pilot/presentation/duck_pilot_view_model.dart`
- `lib/features/controller/application/pilot_view_state.dart` -> `lib/src/features/duck_pilot/presentation/duck_pilot_view_state.dart`
- `lib/features/controller/application/gyro_input_service.dart` -> `lib/src/features/duck_pilot/data/gyro_input_service.dart`
- `lib/features/controller/application/move_transmission_policy.dart` -> `lib/src/features/duck_pilot/domain/move_transmission_policy.dart`
- `lib/features/controller/domain/direction_resolver.dart` -> `lib/src/features/duck_pilot/domain/direction_resolver.dart`
- `lib/infrastructure/pubsub/pubsub_client.dart` -> `lib/src/features/duck_pilot/data/pubsub_client.dart`
- `lib/infrastructure/pubsub/pubsub_config.dart` -> `lib/src/features/duck_pilot/data/pubsub_config.dart`
- `lib/infrastructure/pubsub/pubsub_message_codec.dart` -> `lib/src/features/duck_pilot/data/pubsub_message_codec.dart`
- `lib/infrastructure/pubsub/session_bootstrap_api.dart` -> `lib/src/features/duck_pilot/data/session_bootstrap_api.dart`

## Architectural Decisions For This Project

- `conventions.md` remains the primary standard.
- The target structure uses `lib/src/features/<feature>/`.
- `lib/src/core/` remains valid for shared abstractions reused across features.
- Event-driven AsyncNotifier state management is part of the target architecture.
- `duck_pilot` is the correct feature name for the gameplay controller feature.
- `launch` is a dedicated feature, not just an app-level utility folder.

## Refactoring Principle

When refactoring toward this architecture:

- move code into the owning feature first,
- preserve the Presentation, Domain, and Data boundaries defined in [conventions.md](/Users/junhyounglee/workspace/rubberduck-flutter/docs/conventions.md),
- keep shared code in `lib/src/core/` only when it is genuinely cross-feature,
- and treat the current `app`, `core`, `features/controller`, and `infrastructure` layout as a migration source rather than the final shape.
