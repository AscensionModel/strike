#!/usr/bin/env node

import WebSocket from "ws";

const SUPABASE_URL = "https://enmympaziigrdaogmdbf.supabase.co";
const SUPABASE_KEY = "sb_publishable_XOblrggMAmE_LDt9la4ing_9XusUKQa";

const [mode, teamCodeArg, senderNameArg] = process.argv.slice(2);

if (!["listen", "send"].includes(mode) || !teamCodeArg) {
  console.log("Usage:");
  console.log("  node scripts/realtime-debug.mjs listen TEAM-CODE");
  console.log("  node scripts/realtime-debug.mjs send TEAM-CODE [NAME]");
  process.exit(2);
}

const teamCode = teamCodeArg.toLowerCase();
const senderName = senderNameArg || process.env.USER || "Debug Sender";
const clientId = `debug-${crypto.randomUUID()}`;
const topic = `realtime:team:${teamCode}`;
const url = new URL(SUPABASE_URL);
url.protocol = url.protocol === "http:" ? "ws:" : "wss:";
url.pathname = "/realtime/v1/websocket";
url.search = new URLSearchParams({
  apikey: SUPABASE_KEY,
  vsn: "1.0.0"
}).toString();

let joined = false;
const joinRef = "1";
let ref = Number(joinRef);
const ws = new WebSocket(url);

function nextRef() {
  ref += 1;
  return `${ref}`;
}

function sendMessage({ topic, event, payload, ref = nextRef(), join_ref }) {
  const message = { topic, event, payload, ref };
  if (join_ref) {
    message.join_ref = join_ref;
  }
  ws.send(JSON.stringify(message));
}

function sendStrike() {
  const strike = {
    id: crypto.randomUUID(),
    senderID: clientId,
    senderName,
    scheduledAt: Date.now() / 1000 + 0.75
  };

  sendMessage({
    topic,
    event: "broadcast",
    join_ref: joinRef,
    payload: {
      type: "broadcast",
      event: "strike",
      payload: strike
    }
  });

  console.log(`sent strike to ${topic}`);
}

ws.on("open", () => {
  console.log(`opened websocket for ${topic}`);
  sendMessage({
    topic,
    event: "phx_join",
    ref: joinRef,
    join_ref: joinRef,
    payload: {
      config: {
        broadcast: { ack: false, self: true },
        presence: { enabled: true, key: clientId },
        postgres_changes: [],
        private: false
      }
    }
  });

  setInterval(() => {
    sendMessage({ topic: "phoenix", event: "heartbeat", payload: {} });
  }, 25_000);
});

ws.on("message", (data) => {
  const text = data.toString();
  console.log(`received: ${text}`);

  let message;
  try {
    message = JSON.parse(text);
  } catch {
    return;
  }

  if (message.event === "phx_reply" && message.ref === joinRef) {
    joined = message.payload?.status === "ok";
    console.log(joined ? `joined ${topic}` : `join failed for ${topic}`);

    if (joined && mode === "send") {
      setTimeout(sendStrike, 250);
    }
  }
});

ws.on("error", (error) => {
  console.error(`websocket error: ${error.message}`);
  process.exitCode = 1;
});

ws.on("close", (code, reason) => {
  console.log(`closed: ${code} ${reason}`);
});
