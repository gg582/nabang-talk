<template>
  <div class="app">
    <header class="top-bar">
      <div class="brand">
        <span class="dot" aria-hidden="true"></span>
        <div>
          <p class="eyebrow">NabangTalk · 나방톡</p>
          <h1>Chatter BBS Chat Room</h1>
        </div>
      </div>
      <div class="status-chip" :class="{ live: isConnected }">
        <span class="status-dot"></span>
        {{ isConnected ? 'Connected' : 'Disconnected' }}
      </div>
    </header>

    <main class="layout">
      <section class="chat-panel">
        <div class="chat-header">
          <div>
            <h2>Room Feed</h2>
            <p>Incoming and outgoing chats, styled like a real messenger.</p>
          </div>
          <div class="header-actions">
            <button class="ghost" :disabled="isConnected" @click="connect">Connect</button>
            <button class="primary" v-if="isConnected && !isAuthenticated" @click="performLogin">Login</button>
            <button class="ghost" :disabled="!isConnected" @click="disconnect">Disconnect</button>
          </div>
        </div>

        <div class="chat-body">
          <div v-if="chatMessages.length === 0" class="empty">
            아직 아무 말도 없어요. Connect 후 첫 메시지를 보내보세요!
          </div>
          <ol class="chat-list">
            <li
              v-for="entry in chatMessages"
              :key="entry.localId"
              class="chat-item"
              :class="entry.direction"
            >
              <div class="avatar" aria-hidden="true">
                {{ entry.initials }}
              </div>
              <div class="bubble-wrap">
                <div class="bubble-meta">
                  <span class="name">{{ entry.username }}</span>
                  <span class="time">{{ entry.time }}</span>
                </div>
                <div class="bubble" :class="entry.kind">
                  <p v-if="entry.kind === 'text'">{{ entry.content }}</p>
                  <pre v-else-if="entry.kind === 'asciiart'">{{ entry.content }}</pre>
                  <div v-else-if="entry.kind === 'media'" class="media">
                    <p class="media-label">{{ entry.mediaType }}</p>
                    <a :href="entry.url" target="_blank" rel="noreferrer">{{ entry.url }}</a>
                    <p v-if="entry.caption" class="caption">{{ entry.caption }}</p>
                  </div>
                  <div v-else-if="entry.kind === 'poll'" class="poll">
                    <p class="poll-title">{{ entry.content }}</p>
                    <ol>
                      <li v-for="(option, index) in entry.options" :key="index">
                        {{ option }}
                      </li>
                    </ol>
                  </div>
                  <div v-else-if="entry.kind === 'vote'" class="poll">
                    <p class="poll-title">{{ entry.content }}</p>
                    <p class="vote-meta">{{ entry.meta }}</p>
                  </div>
                  <p v-else class="system">{{ entry.content }}</p>
                </div>
                <details class="payload" v-if="entry.raw">
                  <summary>JSON</summary>
                  <pre>{{ entry.raw }}</pre>
                </details>
              </div>
            </li>
          </ol>
        </div>

        <div v-if="isConnected && !isAuthenticated" class="login-prompt">
           <p>Please login to chat (click Login in header).</p>
        </div>
        <form v-else class="composer" @submit.prevent="sendMessage">
          <div class="composer-row">
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
          </div>

          <div class="composer-grid">
            <label v-if="messageType === 'chat'" class="field full">
              <span>Message</span>
              <textarea v-model="message" rows="2" placeholder="카톡 느낌으로 톡 ✨" />
            </label>

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

            <label v-if="messageType === 'asciiart'" class="field full">
              <span>ASCII Art</span>
              <textarea
                v-model="asciiArt"
                rows="4"
                placeholder=" /\_/\\\n( o.o )\n > ^ <"
              />
            </label>

            <template v-if="messageType === 'poll'">
              <label class="field">
                <span>Question</span>
                <input v-model="pollQuestion" type="text" placeholder="Favorite snack?" />
              </label>
              <label class="field">
                <span>Options (comma-separated)</span>
                <input v-model="pollOptions" type="text" placeholder="cake, cookie, tea" />
              </label>
              <label class="checkbox full">
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
              <label class="checkbox full">
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
          </div>

          <div class="composer-actions">
            <button class="primary" :disabled="!isConnected" type="submit">Send</button>
          </div>
        </form>
      </section>

      <aside class="side-panel">
        <div class="panel-card">
          <h3>Connection</h3>
          <label class="field">
            <span>WebSocket URL</span>
            <input v-model="wsUrl" type="text" placeholder="ws://localhost:5174" />
          </label>
          <p class="hint">
            Run <code>npm run proxy</code> to bridge TCP → WebSocket for the JSON line API.
          </p>
        </div>
        <div class="panel-card">
          <h3>Activity</h3>
          <ul class="activity">
            <li v-for="entry in activity" :key="entry.localId">
              <span class="time">{{ entry.time }}</span>
              <span class="label">{{ entry.title }}</span>
              <p>{{ entry.body }}</p>
            </li>
          </ul>
          <p v-if="activity.length === 0" class="hint">No events yet.</p>
        </div>
      </aside>
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
const chatMessages = ref([]);
const activity = ref([]);
const nextId = ref(1);
const localId = ref(1);
const token = ref('');
const isAuthenticated = ref(false);

const isConnected = computed(() => socket.value?.readyState === WebSocket.OPEN);

const connect = () => {
  if (socket.value) {
    socket.value.close();
  }

  const ws = new WebSocket(wsUrl.value);
  ws.addEventListener('open', () => {
    socket.value = ws;
    logActivity('Connected', 'WebSocket connection is live.');
    addSystemMessage('Connected. Please log in.');
  });
  ws.addEventListener('close', () => {
    socket.value = null;
    isAuthenticated.value = false;
    token.value = '';
    logActivity('Disconnected', 'WebSocket connection closed.');
    addSystemMessage('Connection closed.');
  });
  ws.addEventListener('error', () => {
    socket.value = null;
    isAuthenticated.value = false;
    logActivity('Error', 'Failed to connect. Check the bridge URL.');
    addSystemMessage('Failed to connect.');
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
    isAuthenticated.value = false;
    token.value = '';
  }
};

const performLogin = () => {
  if (!socket.value) return;
  const id = nextId.value++;
  const payload = {
    id,
    type: 'login',
    username: username.value
  };
  socket.value.send(JSON.stringify(payload));
  logActivity('Login', `Requesting token for ${username.value}...`);
};

const handleIncoming = (line) => {
  try {
    const payload = JSON.parse(line);
    
    // Intercept login/auth responses
    if (payload.type === 'response') {
      if (payload.result && payload.result.token) {
        token.value = payload.result.token;
        logActivity('Token Received', 'Authenticating...');
        // Auto-auth
        const authPayload = {
          type: 'auth',
          token: token.value
        };
        socket.value.send(JSON.stringify(authPayload));
        return;
      }
      if (payload.message === 'Authenticated') {
        isAuthenticated.value = true;
        addSystemMessage(`Logged in as ${username.value}`);
        logActivity('Authenticated', 'Session is valid.');
        return;
      }
    }

    addIncomingMessage(payload);
  } catch (error) {
    addSystemMessage(line);
  }
};

const sendMessage = () => {
  if (!socket.value || socket.value.readyState !== WebSocket.OPEN) {
    logActivity('Not connected', 'Connect before sending.');
    addSystemMessage('Connect before sending.');
    return;
  }

  const payload = buildPayload();
  socket.value.send(JSON.stringify(payload));
  addOutgoingMessage(payload);
};

const buildPayload = () => {
  const id = nextId.value++;
  const base = {
    id,
    username: username.value
  };

  if (messageType.value === 'chat') {
    return {
      ...base,
      type: 'message',
      message: message.value,
      preserve_whitespace: false,
      attachment: {
        type: 'none',
        target: '',
        caption: ''
      }
    };
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

const addIncomingMessage = (payload) => {
  const { data, eventType } = unwrapIncoming(payload);
  const normalized = normalizePayload(data, false, {
    eventType,
    rawPayload: payload
  });
  chatMessages.value.push({
    localId: localId.value++,
    direction: 'incoming',
    ...normalized
  });
  logActivity(`Incoming ${normalized.kind}`, normalized.summary || 'New message');
};

const addOutgoingMessage = (payload) => {
  const normalized = normalizePayload(payload, true, {
    rawPayload: payload
  });
  chatMessages.value.push({
    localId: localId.value++,
    direction: 'outgoing',
    ...normalized
  });
  logActivity(`Sent ${normalized.kind}`, normalized.summary || 'Message sent');
};

const addSystemMessage = (messageText) => {
  chatMessages.value.push({
    localId: localId.value++,
    direction: 'system',
    username: 'System',
    initials: '⚙️',
    time: new Date().toLocaleTimeString(),
    kind: 'system',
    content: messageText
  });
};

const unwrapIncoming = (payload) => {
  if (payload?.type === 'event' && payload.payload) {
    return {
      data: payload.payload,
      eventType: payload.event || payload.payload.type || 'event'
    };
  }

  return { data: payload, eventType: payload?.type };
};

const normalizePayload = (payload, isOutgoing = false, meta = {}) => {
  const kind = payload.type || meta.eventType || payload.event || 'system';
  const usernameValue = payload.username || payload.user || (isOutgoing ? username.value : 'Anonymous');
  const createdAt = payload.created_at ? new Date(payload.created_at * 1000) : new Date();
  const time = createdAt.toLocaleTimeString();
  const initials = String(usernameValue).slice(0, 2).toUpperCase();
  const raw = JSON.stringify(meta.rawPayload ?? payload, null, 2);

  if (kind === 'message' && payload.attachment?.type && payload.attachment.type !== 'none') {
    return {
      kind: 'media',
      username: usernameValue,
      initials,
      time,
      mediaType: payload.attachment.type,
      url: payload.attachment.target || '',
      caption: payload.attachment.caption || '',
      raw
    };
  }

  if (kind === 'chat' || kind === 'message') {
    return {
      kind: 'text',
      username: usernameValue,
      initials,
      time,
      content: payload.message || payload.text || '',
      raw
    };
  }

  if (kind === 'asciiart') {
    return {
      kind: 'asciiart',
      username: usernameValue,
      initials,
      time,
      content: payload.message || '',
      raw
    };
  }

  if (['image', 'video', 'audio', 'files'].includes(kind)) {
    return {
      kind: 'media',
      username: usernameValue,
      initials,
      time,
      mediaType: kind,
      url: payload.url || '',
      caption: payload.caption || '',
      raw
    };
  }

  if (kind === 'poll') {
    return {
      kind: 'poll',
      username: usernameValue,
      initials,
      time,
      content: payload.question || payload.title || 'Poll',
      options: payload.options || [],
      raw
    };
  }

  if (kind === 'vote') {
    return {
      kind: 'vote',
      username: usernameValue,
      initials,
      time,
      content: payload.question || payload.label || 'Vote',
      meta: payload.action ? `Action: ${payload.action}` : 'Vote update',
      raw
    };
  }

  return {
    kind: 'system',
    username: usernameValue,
    initials,
    time,
    content: payload.message || payload.status || payload.event || 'Update',
    raw
  };
};

const logActivity = (title, body) => {
  activity.value.unshift({
    localId: localId.value++,
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
  background-color: #fff5f6;
  color: #3c2f34;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  background: #fff5f6;
}

.app {
  min-height: 100vh;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.top-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  background: #ffffff;
  border: 1px solid #f3c8d1;
  border-radius: 20px;
  padding: 16px 20px;
}

.brand {
  display: flex;
  align-items: center;
  gap: 16px;
}

.dot {
  width: 44px;
  height: 44px;
  border-radius: 14px;
  background: #f6a9b7;
  display: inline-block;
}

.eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.12em;
  font-size: 0.75rem;
  color: #c06a7a;
  margin: 0 0 4px 0;
}

h1 {
  font-size: 1.6rem;
  margin: 0;
}

.layout {
  display: grid;
  grid-template-columns: minmax(0, 2fr) minmax(280px, 1fr);
  gap: 20px;
}

.chat-panel {
  background: #ffffff;
  border-radius: 24px;
  border: 1px solid #f3c8d1;
  display: flex;
  flex-direction: column;
  min-height: 70vh;
}

.chat-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  padding: 20px;
  border-bottom: 1px solid #f6d7dc;
  background: #fff0f2;
}

.chat-header h2 {
  margin: 0 0 6px 0;
}

.chat-header p {
  margin: 0;
  color: #7b5f66;
}

.header-actions {
  display: flex;
  gap: 10px;
  align-items: center;
}

.status-chip {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  border-radius: 999px;
  background: #fff0f2;
  color: #c06a7a;
  font-weight: 600;
  border: 1px solid #f3c8d1;
}

.status-chip.live {
  background: #f8d0d8;
  color: #b05566;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: currentColor;
}

.chat-body {
  padding: 20px;
  flex: 1;
  overflow-y: auto;
  background: #fff7f8;
}

.chat-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.chat-item {
  display: grid;
  grid-template-columns: 40px 1fr;
  gap: 12px;
  align-items: flex-start;
}

.chat-item.outgoing {
  grid-template-columns: 1fr 40px;
}

.chat-item.outgoing .avatar {
  order: 2;
}

.chat-item.outgoing .bubble-wrap {
  order: 1;
  align-items: flex-end;
}

.chat-item.system {
  grid-template-columns: 1fr;
}

.chat-item.system .avatar {
  display: none;
}

.avatar {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  background: #f7c2cd;
  display: grid;
  place-items: center;
  font-weight: 700;
  color: #ffffff;
  font-size: 0.85rem;
}

.bubble-wrap {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.bubble-meta {
  display: flex;
  gap: 10px;
  font-size: 0.75rem;
  color: #7b5f66;
}

.bubble {
  background: #ffffff;
  border: 1px solid #f3c8d1;
  border-radius: 16px;
  padding: 12px 14px;
  color: #3c2f34;
}

.chat-item.outgoing .bubble {
  background: #f8d0d8;
  border-color: #f3a9b8;
}

.chat-item.system .bubble {
  background: #fff0f3;
  text-align: center;
}

.bubble p {
  margin: 0;
}

.bubble pre {
  margin: 0;
  white-space: pre-wrap;
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
  font-size: 0.85rem;
}

.media a {
  color: #b05566;
  text-decoration: none;
}

.caption {
  margin-top: 6px;
  color: #7b5f66;
  font-size: 0.85rem;
}

.poll {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.poll-title {
  margin: 0;
  font-weight: 600;
}

.poll ol {
  margin: 0;
  padding-left: 18px;
}

.vote-meta {
  margin: 0;
  font-size: 0.85rem;
  color: #7b5f66;
}

.payload {
  font-size: 0.75rem;
  color: #7b5f66;
}

.payload pre {
  white-space: pre-wrap;
  margin: 6px 0 0 0;
  background: #fff7f8;
  border-radius: 10px;
  padding: 8px;
}

.composer {
  border-top: 1px solid #f6d7dc;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  background: #ffffff;
}

.composer-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 12px;
}

.composer-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 12px;
}

.composer-actions {
  display: flex;
  justify-content: flex-end;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 0.85rem;
  color: #6c4e57;
}

.field.full {
  grid-column: 1 / -1;
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
  font-size: 0.85rem;
  color: #6c4e57;
}

button {
  border: none;
  border-radius: 14px;
  padding: 10px 16px;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s ease;
}

button.primary {
  background: #f2a5b3;
  color: #ffffff;
}

button.ghost {
  background: #ffe9ed;
  color: #c36b7b;
}

button:disabled {
  cursor: not-allowed;
  opacity: 0.6;
  transform: none;
}

button:not(:disabled):hover {
  transform: translateY(-1px);
}

.side-panel {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.panel-card {
  background: #ffffff;
  border-radius: 20px;
  border: 1px solid #f3c8d1;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.panel-card h3 {
  margin: 0;
}

.hint {
  font-size: 0.8rem;
  color: #8b6b73;
  margin: 0;
}

.activity {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.activity li {
  background: #fff6f7;
  border-radius: 14px;
  padding: 10px;
  border: 1px solid #f7d9de;
}

.activity .time {
  font-size: 0.7rem;
  color: #9a717b;
}

.activity .label {
  font-weight: 600;
  font-size: 0.85rem;
  color: #4a3640;
}

.activity p {
  margin: 4px 0 0 0;
  font-size: 0.8rem;
  color: #6c4e57;
}

.empty {
  padding: 24px;
  text-align: center;
  color: #8c6b73;
  background: #fff6f8;
  border-radius: 16px;
}

.login-prompt {
  padding: 20px;
  text-align: center;
  color: #8c6b73;
  background: #fff;
  border-top: 1px solid #f6d7dc;
}

@media (max-width: 980px) {
  .layout {
    grid-template-columns: 1fr;
  }

  .chat-panel {
    min-height: auto;
  }
}
</style>
