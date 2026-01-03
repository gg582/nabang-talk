<template>
  <div class="page">
    <header class="hero">
      <div>
        <p class="eyebrow">NabangTalk · 나방톡</p>
        <h1>Chatter BBS JSON API Web Client</h1>
        <p class="subtitle">
          Connect through the TCP-to-WebSocket bridge and chat in a cute, cozy room.
        </p>
      </div>
      <div class="hero-card">
        <h2>Connection</h2>
        <label class="field">
          <span>WebSocket URL</span>
          <input
            v-model="wsUrl"
            type="text"
            placeholder="ws://localhost:5174"
          />
        </label>
        <div class="row">
          <button class="primary" :disabled="isConnected" @click="connect">
            Connect
          </button>
          <button class="ghost" :disabled="!isConnected" @click="disconnect">
            Disconnect
          </button>
        </div>
        <p class="hint">
          Use <code>npm run proxy</code> to bridge TCP → WebSocket for the
          JSON line API.
        </p>
        <p class="status" :class="{ live: isConnected }">
          {{ isConnected ? 'Connected' : 'Disconnected' }}
        </p>
      </div>
    </header>

    <main class="main">
      <section class="panel">
        <div class="panel-header">
          <h2>Compose</h2>
          <p>Send chat, media, poll, vote, or ASCII art payloads.</p>
        </div>
        <div class="panel-body">
          <label class="field">
            <span>Username</span>
            <input v-model="username" type="text" placeholder="moe-user" />
          </label>

          <label class="field">
            <span>Message type</span>
            <select v-model="messageType">
              <option value="chat">Chat</option>
              <option value="image">Image</option>
              <option value="video">Video</option>
              <option value="audio">Audio</option>
              <option value="files">Files</option>
              <option value="asciiart">ASCII Art</option>
              <option value="poll">Poll (create)</option>
              <option value="poll-vote">Poll (vote)</option>
              <option value="vote">Vote (create)</option>
              <option value="vote-vote">Vote (vote)</option>
            </select>
          </label>

          <template v-if="messageType === 'chat'">
            <label class="field">
              <span>Message</span>
              <textarea v-model="message" rows="3" placeholder="Say hello ✨" />
            </label>
          </template>

          <template v-if="['image', 'video', 'audio', 'files'].includes(messageType)">
            <label class="field">
              <span>URL</span>
              <input v-model="mediaUrl" type="text" placeholder="https://..." />
            </label>
            <label class="field">
              <span>Caption</span>
              <input v-model="caption" type="text" placeholder="Optional caption" />
            </label>
          </template>

          <template v-if="messageType === 'asciiart'">
            <label class="field">
              <span>ASCII Art</span>
              <textarea
                v-model="asciiArt"
                rows="5"
                placeholder=" /\_/\\\n( o.o )\n > ^ <"
              />
            </label>
          </template>

          <template v-if="messageType === 'poll'">
            <label class="field">
              <span>Question</span>
              <input v-model="pollQuestion" type="text" placeholder="Favorite snack?" />
            </label>
            <label class="field">
              <span>Options (comma-separated)</span>
              <input v-model="pollOptions" type="text" placeholder="cake, cookie, tea" />
            </label>
            <label class="checkbox">
              <input type="checkbox" v-model="pollOperator" />
              <span>Send as operator</span>
            </label>
          </template>

          <template v-if="messageType === 'poll-vote'">
            <label class="field">
              <span>Choice index</span>
              <input v-model.number="pollChoice" type="number" min="1" />
            </label>
          </template>

          <template v-if="messageType === 'vote'">
            <label class="field">
              <span>Label</span>
              <input v-model="voteLabel" type="text" placeholder="weekend" />
            </label>
            <label class="field">
              <span>Question</span>
              <input v-model="voteQuestion" type="text" placeholder="Plan?" />
            </label>
            <label class="field">
              <span>Options (comma-separated)</span>
              <input v-model="voteOptions" type="text" placeholder="hike, rest" />
            </label>
            <label class="checkbox">
              <input type="checkbox" v-model="voteAllowMultiple" />
              <span>Allow multiple choice</span>
            </label>
          </template>

          <template v-if="messageType === 'vote-vote'">
            <label class="field">
              <span>Label</span>
              <input v-model="voteLabel" type="text" placeholder="weekend" />
            </label>
            <label class="field">
              <span>Choice index</span>
              <input v-model.number="voteChoice" type="number" min="1" />
            </label>
          </template>

          <button class="primary" :disabled="!isConnected" @click="sendMessage">
            Send
          </button>
        </div>
      </section>

      <section class="panel">
        <div class="panel-header">
          <h2>Room Feed</h2>
          <p>Incoming events and responses from the server.</p>
        </div>
        <div class="panel-body">
          <div v-if="messages.length === 0" class="empty">
            No messages yet. Connect and send your first payload!
          </div>
          <ul class="feed">
            <li v-for="entry in messages" :key="entry.localId" class="feed-item">
              <div class="feed-meta">
                <span class="badge" :class="entry.direction">{{ entry.direction }}</span>
                <span class="timestamp">{{ entry.time }}</span>
              </div>
              <div class="feed-title">{{ entry.title }}</div>
              <pre class="feed-body">{{ entry.body }}</pre>
            </li>
          </ul>
        </div>
      </section>
    </main>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue';

const wsUrl = ref('ws://localhost:5174');
const username = ref('api-demo');
const messageType = ref('chat');
const message = ref('hello');
const mediaUrl = ref('');
const caption = ref('');
const asciiArt = ref(' /\\_/\\\n( o.o )\n > ^ <');
const pollQuestion = ref('Favorite color?');
const pollOptions = ref('red, blue, green');
const pollOperator = ref(false);
const pollChoice = ref(1);
const voteLabel = ref('weekend');
const voteQuestion = ref('Plan?');
const voteOptions = ref('hike, rest');
const voteAllowMultiple = ref(true);
const voteChoice = ref(1);

const socket = ref(null);
const messages = ref([]);
const nextId = ref(1);
const localId = ref(1);

const isConnected = computed(() => socket.value?.readyState === WebSocket.OPEN);

const connect = () => {
  if (socket.value) {
    socket.value.close();
  }

  const ws = new WebSocket(wsUrl.value);
  ws.addEventListener('open', () => {
    socket.value = ws;
    pushMessage('system', 'Connected', 'WebSocket connection is live.');
  });
  ws.addEventListener('close', () => {
    pushMessage('system', 'Disconnected', 'WebSocket connection closed.');
  });
  ws.addEventListener('error', () => {
    pushMessage('system', 'Error', 'Failed to connect. Check the bridge URL.');
  });
  ws.addEventListener('message', (event) => {
    const text = String(event.data || '');
    const lines = text.split('\n').filter(Boolean);
    lines.forEach((line) => handleIncoming(line));
  });

  socket.value = ws;
};

const disconnect = () => {
  if (socket.value) {
    socket.value.close();
    socket.value = null;
  }
};

const handleIncoming = (line) => {
  try {
    const payload = JSON.parse(line);
    const title = `${payload.type ?? 'event'}: ${payload.event ?? payload.status ?? 'update'}`;
    pushMessage('incoming', title, JSON.stringify(payload, null, 2));
  } catch (error) {
    pushMessage('incoming', 'raw', line);
  }
};

const sendMessage = () => {
  if (!socket.value || socket.value.readyState !== WebSocket.OPEN) {
    pushMessage('system', 'Not connected', 'Connect before sending.');
    return;
  }

  const payload = buildPayload();
  socket.value.send(JSON.stringify(payload));
  pushMessage('outgoing', `sent: ${payload.type}`, JSON.stringify(payload, null, 2));
};

const buildPayload = () => {
  const id = nextId.value++;
  const base = {
    id,
    username: username.value
  };

  if (messageType.value === 'chat') {
    return { ...base, type: 'chat', message: message.value };
  }

  if (messageType.value === 'asciiart') {
    return { ...base, type: 'asciiart', message: asciiArt.value };
  }

  if (['image', 'video', 'audio', 'files'].includes(messageType.value)) {
    return {
      ...base,
      type: messageType.value,
      url: mediaUrl.value,
      caption: caption.value
    };
  }

  if (messageType.value === 'poll') {
    return {
      ...base,
      type: 'poll',
      is_operator: pollOperator.value,
      question: pollQuestion.value,
      options: splitOptions(pollOptions.value)
    };
  }

  if (messageType.value === 'poll-vote') {
    return {
      ...base,
      type: 'poll',
      action: 'vote',
      choice: pollChoice.value
    };
  }

  if (messageType.value === 'vote') {
    return {
      ...base,
      type: 'vote',
      label: voteLabel.value,
      question: voteQuestion.value,
      options: splitOptions(voteOptions.value),
      allow_multiple: voteAllowMultiple.value
    };
  }

  return {
    ...base,
    type: 'vote',
    label: voteLabel.value,
    action: 'vote',
    choice: voteChoice.value
  };
};

const splitOptions = (value) =>
  value
    .split(',')
    .map((option) => option.trim())
    .filter(Boolean);

const pushMessage = (direction, title, body) => {
  messages.value.unshift({
    localId: localId.value++,
    direction,
    title,
    body,
    time: new Date().toLocaleTimeString()
  });
};
</script>

<style>
:root {
  color-scheme: light;
  font-family: 'Nunito', 'Pretendard', 'Noto Sans KR', system-ui, sans-serif;
  line-height: 1.5;
  font-weight: 400;
  background-color: #fff7f7;
  color: #3c2f34;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  background: #fff7f7;
}

.page {
  min-height: 100vh;
  padding: 32px;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.hero {
  display: grid;
  grid-template-columns: minmax(0, 2fr) minmax(0, 1fr);
  gap: 24px;
  align-items: start;
}

.eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.12em;
  font-size: 0.75rem;
  color: #c06a7a;
  margin-bottom: 8px;
}

h1 {
  font-size: 2.3rem;
  margin: 0 0 12px 0;
}

.subtitle {
  margin: 0;
  color: #69525a;
}

.hero-card {
  background: #ffffff;
  border: 1px solid #f1c5cd;
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 8px 20px rgba(240, 188, 198, 0.25);
}

.row {
  display: flex;
  gap: 12px;
  margin-top: 12px;
}

.hint {
  font-size: 0.85rem;
  color: #8b6b73;
  margin-top: 12px;
}

.status {
  margin-top: 12px;
  font-weight: 600;
  color: #a07a83;
}

.status.live {
  color: #c05a6a;
}

.main {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 24px;
}

.panel {
  background: #ffffff;
  border-radius: 20px;
  border: 1px solid #f4cdd3;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.panel-header {
  padding: 20px;
  border-bottom: 1px solid #f6d7dc;
  background: #fff0f2;
}

.panel-header h2 {
  margin: 0 0 6px 0;
}

.panel-header p {
  margin: 0;
  color: #7b5f66;
}

.panel-body {
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 8px;
  font-size: 0.9rem;
  color: #6c4e57;
}

input,
select,
textarea {
  border: 1px solid #f0c7cf;
  border-radius: 14px;
  padding: 10px 12px;
  font-size: 0.95rem;
  background: #fffaf9;
  color: #3b2a30;
}

textarea {
  resize: vertical;
}

.checkbox {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 0.9rem;
  color: #6c4e57;
}

button {
  border: none;
  border-radius: 14px;
  padding: 12px 16px;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

button:disabled {
  cursor: not-allowed;
  opacity: 0.6;
  box-shadow: none;
  transform: none;
}

button.primary {
  background: #f2a5b3;
  color: #ffffff;
  box-shadow: 0 6px 12px rgba(242, 165, 179, 0.3);
}

button.ghost {
  background: #ffe9ed;
  color: #c36b7b;
}

button:not(:disabled):hover {
  transform: translateY(-1px);
}

.feed {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 16px;
  max-height: 520px;
  overflow: auto;
}

.feed-item {
  background: #fff6f7;
  border-radius: 16px;
  padding: 12px;
  border: 1px solid #f7d9de;
}

.feed-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
  font-size: 0.8rem;
  color: #7c5e66;
}

.badge {
  padding: 4px 10px;
  border-radius: 999px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  font-size: 0.7rem;
}

.badge.incoming {
  background: #ffe0e6;
  color: #b65a6c;
}

.badge.outgoing {
  background: #f9c1cc;
  color: #ffffff;
}

.badge.system {
  background: #f3e4e8;
  color: #8a6a73;
}

.feed-title {
  font-weight: 600;
  margin-bottom: 8px;
}

.feed-body {
  margin: 0;
  white-space: pre-wrap;
  font-size: 0.85rem;
  color: #4a3640;
}

.empty {
  padding: 24px;
  text-align: center;
  color: #8c6b73;
  background: #fff6f8;
  border-radius: 16px;
}

@media (max-width: 900px) {
  .hero {
    grid-template-columns: 1fr;
  }
}
</style>
