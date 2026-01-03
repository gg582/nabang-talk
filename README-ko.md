# 나방톡 (NabangTalk)

SSH-Chatter JSON 라인 API를 위한 **귀엽고 가벼운** 웹 클라이언트입니다.

## 기능
- Vue 3 싱글 페이지 채팅 클라이언트.
- 채팅, 미디어, ASCII 아트, 투표/설문을 지원.
- TCP JSON API를 WebSocket으로 연결하는 브리지 제공.
- 연한 코랄 핑크 포인트의 라이트 테마, 플랫 UI.

## 요구 사항
- Node.js 18+

## 빠른 시작
1. 의존성 설치:
   ```bash
   npm install
   ```
2. TCP → WebSocket 브리지 실행:
   ```bash
   npm run proxy -- --tcp 127.0.0.1:34567 --ws 0.0.0.0:5174
   ```
3. 웹 앱 실행:
   ```bash
   npm run dev -- --host 0.0.0.0 --port 5173
   ```
4. 브라우저에서 `http://localhost:5173` 접속 후 `ws://localhost:5174`로 연결하세요.

## 공개 테스트 방 사용 시
공개 방 주소는 `chat.korokorok.com:34567` 입니다.
**운영 중인 방이므로 대량 스팸 전송은 절대 금지**입니다. 몇 개만 보내고 읽기 위주로 테스트해주세요.

브리지 연결 예시:
```bash
npm run proxy -- --tcp chat.korokorok.com:34567 --ws 0.0.0.0:5174
```

## 빌드
```bash
npm run build
```

## 참고
- 브라우저는 TCP JSON API에 직접 연결할 수 없으므로 WebSocket 브리지가 필요합니다.
- 메시지 ID는 세션 내에서 자동 증가합니다.
