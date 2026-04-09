# RubberDuck Pilot Launch Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** QR 스캔으로 `https://duckpilot.vercel.app/launch` 링크를 열어 앱을 실행하고, 앱 미설치 시 설치 안내 웹페이지로 자연스럽게 유도하는 구조를 만든다.

**Architecture:** 모바일 앱은 딥링크/App Link/Universal Link를 받아 런타임 `pubSub_url`을 주입받아 부팅하는 구조로 바뀐다. `Vercel`의 `duckpilot.vercel.app`는 launch/install/invalid 라우트를 제공하고, 앱 설치 여부에 따라 앱 진입 또는 웹 fallback을 담당한다.

**Tech Stack:** Flutter, Android App Links, iOS Universal Links, Vercel, HTTPS on `*.vercel.app`

---

## Identity Set

- Product name: `RubberDuck Pilot`
- Android package / namespace: `com.rubberduck.pilot`
- iOS bundle identifier: `com.rubberduck.pilot`
- Vercel project: `duckpilot`
- Launch URL: `https://duckpilot.vercel.app/launch`
- Install URL: `https://duckpilot.vercel.app/install`
- Invalid URL: `https://duckpilot.vercel.app/invalid`
- Optional fallback scheme: `rubberduckpilot://launch`

## Launch URL Contract

권장 링크 형식:

```text
https://duckpilot.vercel.app/launch?v=1&pubsub_url=<urlencoded-wss-url>
```

필수 규칙:

- `pubsub_url`은 필수
- `pubsub_url`은 `wss://`만 허용
- 허용 호스트는 운영 환경에서 allowlist로 제한
- 앱은 링크를 영구 저장하지 않고 현재 세션에만 사용

## Runtime Flow

### Cold Start

1. 앱이 링크 없이 열리면 대기화면을 보여준다.
2. 앱이 `/launch` 링크와 함께 열리면 파라미터를 검증한다.
3. 검증이 끝나면 해당 `pubSub_url`로 컨트롤러 화면을 구동한다.

### Warm Start

1. 앱 실행 중 새 `/launch` 링크가 들어오면 확인 모달을 띄운다.
2. 승인 시 현재 연결을 끊고 새 URL로 세션을 갈아탄다.
3. 거부 시 현재 세션을 유지한다.

### Invalid Link

- 파라미터 누락, `wss` 아님, 허용되지 않은 호스트면 오류 안내 후 대기화면으로 복귀

## Vercel Project Scope

`duckpilot.vercel.app`는 별도 소형 프로젝트로 운영한다.

- `/launch`
  앱 설치 시 Universal/App Link로 앱 열기
  앱 미설치 시 `/install` 경험 제공
- `/install`
  Android APK 설치, iOS 사내 배포 안내
- `/invalid`
  잘못된 링크, 누락된 파라미터 안내

운영 원칙:

- `*.vercel.app` 기본 HTTPS 사용
- 별도 Let's Encrypt 운영 없음
- Android용 `assetlinks.json`, iOS용 `apple-app-site-association` 제공

## Distribution Plan

### Android

- 사내 웹페이지에서 서명된 APK 배포
- 설치 버튼, 버전, SHA-256, 변경 이력 표시
- 설치 후 다시 `launch` 링크를 여는 CTA 제공

### iOS

- 대상은 사내 직원
- 배포는 `Apple Developer Enterprise Program` 기준으로 설계
- 1순위는 MDM, 2순위는 사내 웹사이트 OTA 설치
- 설치 후 신뢰 설정 안내와 launch 재진입 버튼 제공

## Current Repo Update Scope

이번 변경에서 실제 반영할 항목:

- Android package / namespace를 `com.rubberduck.pilot`로 변경
- iOS bundle identifier를 `com.rubberduck.pilot`로 변경
- Android App Links 기본 intent filter 추가
- iOS Universal Links entitlements 기본값 추가
- README와 문서의 외부 launch 도메인 표기 정리

이번 변경에서 아직 반영하지 않을 항목:

- Flutter 런타임 딥링크 처리 로직
- 최초 대기화면
- 실행 중 링크 전환 확인 모달
- Vercel 프로젝트 실제 생성 및 배포 파일
- `assetlinks.json`, `apple-app-site-association` 실서명 값 채우기

## Task Breakdown

### Task 1: Identity And Platform Metadata

**Files:**
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `android/app/src/main/kotlin/com/rubberduck/pilot/MainActivity.kt`
- Delete: `android/app/src/main/kotlin/com/example/rubberduck_flutter/MainActivity.kt`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Modify: `ios/Runner/Info.plist`
- Create: `ios/Runner/Runner.entitlements`

- [x] Change Android namespace and applicationId to `com.rubberduck.pilot`
- [x] Rename the Kotlin package path and update `MainActivity` package declaration
- [x] Update Android app label to `RubberDuck Pilot`
- [x] Add Android `https://duckpilot.vercel.app/launch` App Link filter and fallback custom scheme
- [x] Update iOS bundle identifier and display name
- [x] Add iOS associated domains entitlement for `applinks:duckpilot.vercel.app`

### Task 2: Documentation Alignment

**Files:**
- Modify: `README.md`
- Modify: `plan.md`

- [x] Document `duckpilot.vercel.app` launch/install/invalid URLs
- [x] Document `com.rubberduck.pilot` identity set
- [x] Document that runtime deeplink handling is still pending implementation

### Task 3: Runtime Launch Bootstrap

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/app/runtime/runtime_controller_config.dart`
- Create: `lib/app/launch/launch_bootstrap_page.dart`
- Create: `lib/app/launch/launch_link_parser.dart`
- Create: `lib/app/launch/launch_state.dart`
- Test: `test/app/launch/launch_link_parser_test.dart`
- Test: `test/app/launch/launch_bootstrap_page_test.dart`

- [x] Write failing parser tests for valid and invalid launch URLs
- [x] Implement parser and runtime config injection
- [x] Add initial waiting screen and resolving state
- [x] Verify the app only auto-joins after a valid launch link is resolved

### Task 4: In-App Relaunch Handling

**Files:**
- Modify: `lib/features/controller/presentation/pilot_page.dart`
- Modify: `lib/features/controller/application/pilot_view_model.dart`
- Test: `test/app/launch/launch_bootstrap_page_test.dart` (warm-state confirmation coverage)

- [x] Write failing tests for warm-state relaunch confirmation
- [x] Implement confirmation dialog and reconnect flow
- [x] Verify decline keeps current session intact

### Task 5: Vercel Launcher Project

**Files:**
- Create: `launcher-web/...`

- [ ] Scaffold a minimal Vercel project for `/launch`, `/install`, `/invalid`
- [ ] Add platform-aware install content
- [ ] Add placeholders for `assetlinks.json` and `apple-app-site-association`
- [ ] Validate the generated URLs match the mobile app configuration
