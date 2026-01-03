# NabangTalk (나방톡)

A cute, light, pale-coral-pink web client for the **SSH-Chatter** JSON line API.

[Korean README → README-ko.md](./README-ko.md)

## Features
- Vue 3 single-page chat client.
- Supports chat, media, ASCII art, polls, and votes.
- WebSocket bridge to the TCP JSON API.
- Light theme with a flat, moe aesthetic.

## Requirements
- Node.js 18+

## Quick start
1. Install dependencies:
   ```bash
   npm install
   ```
2. Start the TCP → WebSocket bridge:
   ```bash
   npm run proxy -- --tcp 127.0.0.1:34567 --ws 0.0.0.0:5174
   ```
3. Start the web app:
   ```bash
   npm run dev -- --host 0.0.0.0 --port 5173
   ```
4. Open `http://localhost:5173` and connect to `ws://localhost:5174`.

## Using the public test room
The public room lives at `chat.korokorok.com:34567`.
Please **do not spam** it with large bursts of messages—send a few test messages and read replies instead.

To connect through the proxy:
```bash
npm run proxy -- --tcp chat.korokorok.com:34567 --ws 0.0.0.0:5174
```

## Build
```bash
npm run build
```

## Notes
- The browser cannot connect directly to the TCP JSON line API, so the WebSocket bridge is required.
- Message IDs auto-increment per session; you can change the username in the compose panel.
