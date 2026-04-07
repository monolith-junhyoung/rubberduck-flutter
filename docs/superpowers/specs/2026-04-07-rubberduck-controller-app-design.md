# RubberDuck Controller App Design

## Goal

`청소난투(욕실의 난)`의 플레이어용 모바일 컨트롤러 앱을 설계한다.  
이 앱은 게임 화면을 직접 렌더링하지 않고, 한 손 세로형 조작 UX를 중심으로 이동 입력을 생성해 `Azure Web PubSub` 기반 실시간 시스템으로 전달하는 역할을 가진다.

## Product Summary

- 앱 유형: 플레이어용 모바일 리모컨
- 핵심 역할: 자이로 기반 이동 입력 생성 및 전송
- 보조 역할: 최소 상태 확인
- 메인 타겟 UX: 한 손 세로 조작
- 비주얼 방향: 다크 네이비 기반 `Mini Control Room`

## Core Decisions

### 1. App Role

- 앱은 `조작 + 최소 상태 확인` 앱이다.
- 게임의 메인 시각화와 장애물 연출은 웹 캔버스가 담당한다.
- 앱은 입력 생성과 상태 확인에 집중한다.

### 2. Screen Model

- 단일 메인 화면 구조를 사용한다.
- 별도 페이지 전환 없이, 실행 직후 같은 화면 위에 입장 오버레이를 띄운다.
- 오버레이 입력값:
  - 플레이어 이름
  - 세션 코드

### 3. Orientation and Grip

- 기본 방향은 `세로모드`
- 사용 방식은 `한 손으로 가볍게`
- 가로모드는 MVP 우선순위에서 제외한다.

### 4. Input Model

- 메인 입력은 `자이로 기반`
- 자이로는 `사용자가 화면 중앙 영역을 누르고 있을 때만 활성`
- 하단 보조 버튼은 `좌 / 정지 / 우`
- 버튼은 대체 입력이 아니라 `비상 방향 보정용`

### 5. Movement Representation

- 앱 내부 입력 표현은 `벡터 기반`
- 최소 필드:
  - `x`
  - `y`
  - `magnitude`
  - `active`
- 서버는 이 벡터를 받아 `8방향`으로 해석 가능해야 한다.
- 지원 방향:
  - `idle`
  - `up`
  - `down`
  - `left`
  - `right`
  - `upLeft`
  - `upRight`
  - `downLeft`
  - `downRight`

### 6. Transmission Policy

- 전송 정책은 `혼합형`
- 기본적으로 고정 주기로 현재 벡터를 전송한다.
- 벡터 크기 또는 방향 변화가 큰 경우 즉시 추가 전송한다.

### 7. Sensitivity Policy

- 기본 감도는 `중간`
- 중앙 데드존을 둔다.
- 폰을 약간 흔드는 정도로는 입력이 발생하지 않게 한다.

## UX Structure

### Join Overlay

역할:

- 플레이어 이름 입력
- 세션 코드 입력
- 세션 입장 요청
- 실패 시 재시도 안내

원칙:

- 메인 화면 위 오버레이로 표시
- 성공 시 닫힘
- 별도 라우팅 없이 동일 화면에서 플레이 시작

### Top Status Bar

표시 항목:

- 연결 상태
- 카운트다운
- 현재 깃발 보유자

원칙:

- 항상 보이되 화면 점유는 작게
- 읽기 쉬운 칩 또는 소형 카드 형태

### Central Gyro Hold Area

역할:

- 터치 홀드 상태 감지
- 홀드 중에만 자이로 입력 활성화
- 현재 입력 방향의 약한 시각 피드백 제공

원칙:

- 화면에서 가장 큰 영역
- 실수 입력을 막기 위해 홀드 해제 시 즉시 정지

### Bottom Correction Controls

구성:

- `좌`
- `정지`
- `우`

원칙:

- 한 손 엄지로 빠르게 누를 수 있어야 함
- `정지`는 항상 가장 신뢰할 수 있는 정지 수단이어야 함

## Visual Direction

캔버스 레퍼런스의 테마를 모바일에 맞게 재해석한다.

핵심 요소:

- 다크 네이비 기반 배경
- 얇은 그리드 패턴
- 둥근 카드/패널
- 밝은 블루 포인트 컬러
- 발광하는 러버덕 포인트

비주얼 콘셉트:

- 귀엽지만 장치적인 콘솔
- 화면이 화려하기보다 정돈되어 있어야 함
- 입력 집중을 방해하지 않도록 정보 밀도를 제한

선택된 비주얼 방향:

- `Mini Control Room`

## State Model

### Join State

- `playerName`
- `sessionCode`
- `isSubmitting`
- `errorMessage`

### Session State

- `playerId`
- `connectionState`
- `countdown`
- `flagHolder`
- `sessionCode`

### Control State

- `gyroHoldActive`
- `currentVectorX`
- `currentVectorY`
- `currentMagnitude`
- `resolvedDirection`
- `lastSentAt`

## Event Model

### Outgoing Events

#### `session.join`

Fields:

- `playerName`
- `sessionCode`
- `deviceId`
- `sentAt`

#### `controller.move`

Fields:

- `playerId`
- `sessionCode`
- `x`
- `y`
- `magnitude`
- `active`
- `source`
- `sentAt`

Notes:

- `source`는 `gyro` 또는 `button`
- 서버는 이 값을 받아 연속 벡터 또는 8방향으로 해석 가능해야 함

#### `controller.stop`

Fields:

- `playerId`
- `sessionCode`
- `reason`
- `sentAt`

`reason` 예시:

- `touch_release`
- `stop_button`
- `backgrounded`
- `disconnect`

### Incoming Events

#### `player.assignment`

- 서버가 플레이어 식별자를 할당

#### `session.state`

- 연결 상태
- 카운트다운
- 활성 플레이어 수

#### `flag.state`

- 현재 깃발 보유자
- 필요 시 보유 시간 요약

## Realtime Architecture

### Communication Standard

- MQTT는 사용하지 않는다.
- 실시간 통신 기준은 `Azure Web PubSub`

### Connection Flow

1. 앱이 백엔드에 접속 토큰 또는 접속 URL 요청
2. 백엔드가 Azure Web PubSub 접속 정보 발급
3. 앱이 PubSub에 연결
4. 세션 코드 기준 그룹에 입장
5. 앱은 컨트롤 이벤트 발행
6. 서버/캔버스는 동일 세션 그룹을 통해 상태를 수신

### Responsibility Split

앱:

- 입력 생성
- 세션 입장
- 최소 상태 표시

백엔드 / 서버:

- 접속 정보 발급
- 플레이어 식별
- 이벤트 중계
- 벡터 -> 8방향 해석
- 게임 상태 집계

캔버스:

- 맵 렌더링
- 장애물 트리거 처리
- 플레이어 표현
- 순위 및 시간 시각화

## Error Handling and Safety

### Connection States

- `idle`
- `connecting`
- `connected`
- `reconnecting`
- `disconnected`

### Reconnect Policy

- 연결이 끊기면 자동 재시도
- 실패가 누적되면 재접속 UI 노출
- 재연결 후 자동 이동 재개 금지
- 복구 직후는 항상 정지 상태에서 다시 시작

### Stop Rules

- 터치 홀드 해제 시 즉시 정지
- 앱이 백그라운드로 가면 정지
- 연결이 끊기면 정지
- 정지 버튼은 항상 높은 우선순위

### Join Failure Cases

- 세션 코드 없음
- 세션 종료
- 정원 초과
- 중복 이름 또는 중복 식별값
- 토큰 발급 실패
- Web PubSub 연결 실패

## Architecture Recommendation

### UI

- `JoinOverlay`
- `StatusBar`
- `GyroPad`
- `CorrectionButtons`
- `ControllerScreen`

### Application Layer

- 세션 입장 흐름 제어
- 자이로 활성/비활성 제어
- 이동 벡터 계산 결과를 전송 정책에 맞게 발행

### Domain Layer

- 이동 벡터 모델
- 세션 상태 모델
- 연결 상태 모델
- 이벤트 모델

### Infrastructure Layer

- Azure Web PubSub 연결
- 토큰 요청 클라이언트
- 메시지 직렬화/역직렬화

## Implementation Priority

1. 단일 화면 UI와 오버레이 구조 확정
2. 다크 네이비 `Mini Control Room` 테마 반영
3. 홀드 기반 자이로 입력 모델 구현
4. 로컬 벡터 시뮬레이션 구현
5. Azure Web PubSub 연결 계층 추가
6. `join / move / stop` 이벤트 송신 구현
7. `session.state / flag.state / player.assignment` 수신 구현
8. 디버그 정보 노출 방식 추가

## Out of Scope for MVP

- 복잡한 회전 조작
- 전체 플레이어 상태판
- 관리자용 운영 화면
- 앱 안의 상세 로그 UI
- 화려한 애니메이션 중심 UI

## Summary

이 앱은 `청소난투`의 플레이어용 세로형 모바일 컨트롤러이며, `Mini Control Room` 비주얼 아래에서 `홀드 중 자이로 입력 + 최소 상태 확인 + Azure Web PubSub 연동`을 중심으로 구성한다.
