// netlify/functions/ai_chat.js
// Node18+ 想定

const fs = require("fs");
const path = require("path");

function parseCsv(text) {
  const lines = text.split(/\r?\n/).filter(Boolean);
  const header = lines.shift().split(",").map(s => s.trim());
  return lines.map(line => {
    // 超簡易CSV（ダブルクォート内カンマに弱い）。本番はCSVパーサ導入推奨。
    const cols = line.split(",").map(s => s.trim());
    const obj = {};
    header.forEach((h, i) => obj[h] = cols[i] ?? "");
    return obj;
  });
}

function scoreRow(row, q) {
  const hay = `${row.name ?? ""} ${row.title ?? ""} ${row.description ?? ""} ${row.tags ?? ""}`.toLowerCase();
  const tokens = q.toLowerCase().split(/\s+/).filter(Boolean);
  let s = 0;
  for (const t of tokens) {
    if (hay.includes(t)) s += 2;
  }
  return s;
}

function topK(rows, q, k = 6) {
  return rows
    .map(r => ({ r, s: scoreRow(r, q) }))
    .filter(x => x.s > 0)
    .sort((a, b) => b.s - a.s)
    .slice(0, k)
    .map(x => x.r);
}

function loadData() {
  const dataDir = path.join(__dirname, "data");


  const spotsCsv = fs.readFileSync(path.join(dataDir, "island_spots.csv"), "utf8");
  const eventsCsv = fs.readFileSync(path.join(dataDir, "events.csv"), "utf8");
  const quizCsv = fs.readFileSync(path.join(dataDir, "kids_quiz.csv"), "utf8");
  const transportJson = fs.readFileSync(path.join(dataDir, "transport_status.json"), "utf8");

  return {
    spots: parseCsv(spotsCsv),
    events: parseCsv(eventsCsv),
    quiz: parseCsv(quizCsv),
    transport: JSON.parse(transportJson),
  };
}

async function callOpenAI({ messages }) {
  // ★キー名はOPENAI_API_KEYに統一（Netlify側もこれに合わせる）
  const apiKey = process.env.OPENAI_API_KEY;

  if (!apiKey) {
    console.error("❌ OPENAI_API_KEY is missing");
    throw new Error("OPENAI_API_KEY is not set in environment variables");
  }

  console.log("✅ OPENAI_API_KEY exists (length):", apiKey.length);

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages,
      temperature: 0.6,
    }),
  });

  console.log("📡 OpenAI status:", res.status);

  const text = await res.text();
  console.log("📡 OpenAI raw response:", text);

  if (!res.ok) {
    throw new Error(`OpenAI error ${res.status}: ${text}`);
  }

  const json = JSON.parse(text);
  return json.choices?.[0]?.message?.content ?? "";
}



function buildSystemPromptIsland(uiState) {
  const policy = uiState?.policy ?? {};
  return [
    "あなたは『島ナビAI』。観光客に、今日役立つ情報を短くわかりやすく提案する。",
    "次を必ず守る：",
    "1) 店は『よく開いている店』を優先して提案（確実性を上げる）。",
    "2) イベントは見落としなく紹介する（期間/場所/ポイント）。",
    "3) 交通は、バス運行・自転車レンタル在庫など『具体データ』に触れて提案する。データがなければ『未取得』と明言し、代替案を出す。",
    "4) 断定しすぎない。営業時間や運行は変動する前提で注意書きを1行添える。",
    policy.preferReliableOpenShops ? "（設定）よく開いている店中心：ON" : "",
  ].filter(Boolean).join("\n");
}

function buildSystemPromptKids(uiState) {
  const mode = uiState?.mode ?? "going";
  const isGoing = mode === "going";
  return [
    "あなたは『子ども向けクイズAI』。小学生でも楽しい言葉で出題・解説する。",
    "ルール：",
    "1) 行きモード：クイズの合間に“島の豆知識”を多めに入れる（学び重視）。",
    "2) 帰りモード：テンポよくクイズ。正解したら必ず褒める。誤答ならヒント。",
    "3) 1回の返答は短め。選択肢は A/B/C で出す。",
    "4) ユーザーが答えたら、正解時は文末に [CORRECT] を付ける（アプリが加点するため）。",
    isGoing ? "（現在）行きモード" : "（現在）帰りモード",
  ].join("\n");
}

exports.handler = async (event) => {
  try {

    const body = JSON.parse(event.body || "{}");
    const bot = body.bot; // island / kids
    const message = (body.message || "").toString();
    const uiState = body.uiState || {};

    const data = loadData();

    // CSVから関連候補抽出（軽量RAG）
    const relatedSpots = topK(data.spots, message, 6);
    const relatedEvents = topK(data.events, message, 6);

    // kids：modeに応じてクイズ問題候補を抽出
    const mode = uiState?.mode ?? "going";
    const quizPool = data.quiz.filter(q => (q.mode || "").toLowerCase() === mode);
    const relatedQuiz = topK(quizPool, message, 6);

    const context = {
      spots: relatedSpots,
      events: relatedEvents,
      transport: data.transport,
      quiz: relatedQuiz,
    };

    const sys = bot === "kids" ? buildSystemPromptKids(uiState) : buildSystemPromptIsland(uiState);

    const messages = [
      { role: "system", content: sys },
      {
        role: "system",
        content:
          "参考データ（必要なものだけ使って回答してOK）:\n" +
          JSON.stringify(context, null, 2),
      },
      { role: "user", content: message },
    ];

    const reply = await callOpenAI({ messages });

    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ reply }),
    };
  } catch (e) {
    return { statusCode: 500, body: JSON.stringify({ reply: `サーバエラー: ${e.message}` }) };
  }
};
