# 청소난투(욕실의 난) 모바일 컨트롤러

`청소난투(욕실의 난)`은 욕실 테마의 4인 러버덕 난투 게임이다.  
이 저장소는 그중 `플레이어용 모바일 컨트롤러 앱`을 구현한다.

웹 캔버스는 게임 장면과 장애물을 렌더링하고, 이 앱은 한 손 세로형 UX로 이동 입력을 만들어 `Azure Web PubSub`로 전달한다.

## 현재 제품 식별자

- 앱 이름: `RubberDuck Pilot`
- Android package: `com.rubberduck.pilot`
- iOS bundle id: `com.rubberduck.pilot`
- launch 도메인: `https://duckpilot.vercel.app`
- launch URL: `https://duckpilot.vercel.app/launch`
- install URL: `https://duckpilot.vercel.app/install`
- invalid URL: `https://duckpilot.vercel.app/invalid`

## 현재 구현 목표

- 플레이어가 모바일 앱으로 러버덕을 조작
- 기기를 기울인 방향을 유지하면 이동이 이어지는 `tilt 기반 입력`
- `좌 / 정지 / 우` 보조 버튼 제공
- 세션 입장과 최소 상태 표시
- `Azure Web PubSub` 기반 실시간 송수신

## UX 방향

- 화면 방향: `세로모드`
- 사용 방식: `한 손`
- 메인 조작: `hold to steer`
- 자이로/센서 철학:
  - 화면 중앙 영역을 누르고 있을 때만 센서 입력 활성
  - 손을 떼면 즉시 정지
  - 앱이 백그라운드로 가도 정지

## 비주얼 방향

- 테마명: `Mini Control Room`
- 특징:
  - 다크 네이비 배경
  - 얇은 그리드 패턴
  - 둥근 패널
  - 블루 포인트
  - 발광 러버덕 포인트

## 현재 화면 구조

### 1. 입장 오버레이

- 플레이어 이름 입력
- 세션 코드 입력
- `입장하기` 버튼

### 2. 상단 상태 바

- 연결 상태
- 카운트다운
- 현재 깃발 보유자

### 3. 중앙 조작 영역

- `Hold to steer`
- tilt 벡터 상태 피드백
- 러버덕 포컬 오브젝트

### 4. 하단 보조 버튼

- `좌`
- `정지`
- `우`

## 입력 모델

앱 내부 이동은 `벡터 기반`이다.

필드:

- `x`
- `y`
- `magnitude`
- `active`

서버 또는 캔버스는 이를 바탕으로 `8방향`으로 해석할 수 있다.

지원 방향:

- `idle`
- `up`
- `down`
- `left`
- `right`
- `upLeft`
- `upRight`
- `downLeft`
- `downRight`

## 센서 해석

현재 구현은 `accelerometer 기반 tilt delta`를 사용한다.

즉:

- 단순 회전 속도가 아니라
- 기기를 기울인 방향 변화를 벡터로 정규화해서 사용한다.

기본 규칙:

- dead zone 존재
- 입력값 clamp
- hold 중에만 활성

실기기에서 감도와 축 방향은 추가 튜닝이 필요할 수 있다.

## 실시간 통신

### 사용 기술

- `Azure Web PubSub`

### 현재 연결 방식

앱은 `Client Access URL`을 런타임으로 주입받아 접속한다.

향후 기본 진입점은 아래 launch 링크다.

```text
https://duckpilot.vercel.app/launch?v=1&pubsub_url=<urlencoded-wss-url>
```

예:

```bash
flutter run --dart-define=RUBBERDUCK_PUBSUB_CLIENT_URL='wss://monolith.webpubsub.azure.com/client/hubs/rubberduck?access_token=...'
```

### 보안 원칙

- `AccessKey`와 연결 문자열은 앱 코드에 넣지 않는다
- 앱에는 `Client Access URL` 또는 negotiate 결과만 전달한다

## Web PubSub 메시지 흐름

### 송신

- `session.join`
- `controller.move`
- `controller.stop`

실제 Web PubSub 전송은 `sendToGroup` 프레임으로 감싼다.

### 수신

- `session.state`
- `flag.state`
- `player.assignment`

현재 구현은 위 세 이벤트를 수신해서 상태 바와 플레이어 식별값에 반영한다.

## 현재 코드 구조

### 앱 / 테마

- [lib/app/app.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/app/app.dart)
- [lib/app/theme/app_colors.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/app/theme/app_colors.dart)
- [lib/app/theme/app_theme.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/app/theme/app_theme.dart)

### 도메인 모델

- [lib/core/models/control_vector.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/core/models/control_vector.dart)
- [lib/core/models/movement_command.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/core/models/movement_command.dart)
- [lib/core/models/session_join_request.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/core/models/session_join_request.dart)
- [lib/core/models/flag_state.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/core/models/flag_state.dart)

### 컨트롤러 로직

- [lib/features/controller/application/controller_view_state.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/features/controller/application/controller_view_state.dart)
- [lib/features/controller/application/controller_view_model.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/features/controller/application/controller_view_model.dart)
- [lib/features/controller/application/gyro_input_service.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/features/controller/application/gyro_input_service.dart)
- [lib/features/controller/application/move_transmission_policy.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/features/controller/application/move_transmission_policy.dart)
- [lib/features/controller/domain/direction_resolver.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/features/controller/domain/direction_resolver.dart)

### UI

- [lib/features/controller/presentation/controller_home_page.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/features/controller/presentation/controller_home_page.dart)
- [lib/features/controller/presentation/widgets/join_overlay.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/features/controller/presentation/widgets/join_overlay.dart)
- [lib/features/controller/presentation/widgets/status_bar.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/features/controller/presentation/widgets/status_bar.dart)
- [lib/features/controller/presentation/widgets/gyro_hold_pad.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/features/controller/presentation/widgets/gyro_hold_pad.dart)
- [lib/features/controller/presentation/widgets/correction_controls.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/features/controller/presentation/widgets/correction_controls.dart)
- [lib/features/controller/presentation/widgets/vector_feedback.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/features/controller/presentation/widgets/vector_feedback.dart)

### PubSub 인프라

- [lib/infrastructure/pubsub/pubsub_config.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/infrastructure/pubsub/pubsub_config.dart)
- [lib/infrastructure/pubsub/session_bootstrap_api.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/infrastructure/pubsub/session_bootstrap_api.dart)
- [lib/infrastructure/pubsub/pubsub_client.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/infrastructure/pubsub/pubsub_client.dart)
- [lib/infrastructure/pubsub/pubsub_message_codec.dart](/Users/junhyounglee/workspace/rubberduck-flutter/lib/infrastructure/pubsub/pubsub_message_codec.dart)

## 현재 구현 상태

완료:

- Mini Control Room 테마
- 세로형 단일 화면
- 입장 오버레이
- hold 기반 센서 활성
- `좌 / 정지 / 우` 버튼
- 벡터 기반 이동 모델
- 8방향 해석기
- mixed send policy
- direct client access URL bootstrap
- Web PubSub `join / move / stop` 송신
- `session.state / flag.state / player.assignment` 수신 반영
- lifecycle stop 안전장치

아직 남은 핵심:

- 실제 서버 포맷과 payload 필드 완전 일치 확인
- 실기기 감도/축 튜닝
- 연결 실패/재연결 UI 고도화
- launch 대기화면 및 딥링크 런타임 처리
- 전체 테스트 스위트 최종 점검

## 테스트

현재 주요 테스트:

- widget layout test
- direction resolver test
- controller view model test
- move transmission policy test
- gyro input mapping test
- realtime join flow test
- pubsub codec test

실행:

```bash
flutter test
```

## 참고

현재 앱은 `로컬 모드`와 `실시간 모드`를 모두 지원한다.

- `RUBBERDUCK_PUBSUB_CLIENT_URL` 미주입: 로컬 모드
- `RUBBERDUCK_PUBSUB_CLIENT_URL` 주입: 실시간 접속 시도

## 한 줄 요약

이 저장소는 `청소난투`의 플레이어용 세로형 모바일 컨트롤러 앱이며, tilt 기반 입력과 Azure Web PubSub 실시간 통신을 중심으로 MVP를 구현 중이다.
