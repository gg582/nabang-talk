import net from 'node:net';
import { WebSocketServer } from 'ws';

const args = process.argv.slice(2);
const config = {
  tcp: '127.0.0.1:34567',
  ws: '0.0.0.0:5174'
};

for (let index = 0; index < args.length; index += 1) {
  const arg = args[index];
  const next = args[index + 1];
  if (arg === '--tcp' && next) {
    config.tcp = next;
    index += 1;
  } else if (arg === '--ws' && next) {
    config.ws = next;
    index += 1;
  } else if (arg === '--help') {
    console.log('Usage: node scripts/ws-proxy.js --tcp host:port --ws host:port');
    process.exit(0);
  }
}

const [tcpHost, tcpPortRaw] = config.tcp.split(':');
const [wsHost, wsPortRaw] = config.ws.split(':');
const tcpPort = Number(tcpPortRaw || 34567);
const wsPort = Number(wsPortRaw || 5174);

const server = new WebSocketServer({ host: wsHost, port: wsPort });

server.on('connection', (socket) => {
  const tcp = net.createConnection({ host: tcpHost, port: tcpPort });
  let buffer = '';

  tcp.on('data', (chunk) => {
    buffer += chunk.toString('utf-8');
    const parts = buffer.split('\n');
    buffer = parts.pop() ?? '';
    parts.filter(Boolean).forEach((line) => socket.send(line));
  });

  tcp.on('close', () => {
    if (socket.readyState === socket.OPEN) {
      socket.close();
    }
  });

  socket.on('message', (data) => {
    const text = String(data);
    tcp.write(`${text}\n`);
  });

  socket.on('close', () => {
    tcp.end();
  });
});

console.log(`WebSocket bridge ready at ws://${wsHost}:${wsPort}`);
console.log(`Forwarding to tcp://${tcpHost}:${tcpPort}`);
