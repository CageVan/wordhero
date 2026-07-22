// WordHero · 有道例句代理（Supabase Edge Function / 也可作 Cloudflare Worker）
//
// 作用：在服务端代抓有道词典的「英英 + 中文」双语例句（blng_sents_part），
//       返回轻量 JSON 给手机端 PWA。浏览器直连有道会被 CORS 拦截，故需此代理。
//
// ⚠️ 部署关键：Supabase Edge Function 默认要求 JWT 校验，浏览器用 anon key
//    直连会吃 401。必须带 --no-verify-jwt 部署，让函数对匿名公开调用放行。
//
// 部署（需本地装好 Supabase CLI 并登录一次）：
//   1) supabase login
//   2) supabase functions deploy youdao-examples --no-verify-jwt --project-ref <你的PROJECT_REF>
//      （<PROJECT_REF> = 你 Supabase 项目 URL https://xxxx.supabase.co 里的 xxxx）
//   3) 完事。PWA 会自动用云端配置里的 SB.url 拼出端点，无需改代码。
//
// 想用 Cloudflare 更省事？把下面 Deno.serve(...) 整段换成：
//   export default { async fetch(req){ return handle(req); } };
// 然后粘贴到 Workers 控制台即可（此时需把 PWA 里 youdaoEp() 改成你的 CF 域名）。
//
// 调用：GET <端点>?q=apple
// 返回：{ "examples": [ { "en": "...", "zh": "..." }, ... ] }

const YOUDAO = "https://dict.youdao.com/jsonapi?q=";

// 轻量内存缓存：同一词 6 小时内不重复打有道（Deno 实例常驻即生效）
const CACHE_TTL = 6 * 60 * 60 * 1000;
const cache = new Map<string, { t: number; v: any }>();

function htmlDecode(s: string): string {
  return (s || "")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, " ");
}

// 去掉有道返回里夹带的 <b>/<font> 等标签并解码实体
function strip(s: string): string {
  return htmlDecode((s || "").replace(/<[^>]+>/g, "").replace(/\s+/g, " ")).trim();
}

async function handle(req: Request): Promise<Response> {
  const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  };
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const url = new URL(req.url);
  const q = (url.searchParams.get("q") || url.searchParams.get("word") || "").trim();
  if (!q) {
    return new Response(JSON.stringify({ examples: [] }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }

  const hit = cache.get(q);
  if (hit && Date.now() - hit.t < CACHE_TTL) {
    return new Response(JSON.stringify({ examples: hit.v, cached: true }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }

  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 6000);
  try {
    const r = await fetch(YOUDAO + encodeURIComponent(q), {
      headers: { "User-Agent": "Mozilla/5.0", "Accept": "application/json" },
      signal: ctrl.signal,
    });
    const j = await r.json();
    const pairs =
      (j && j.blng_sents_part && j.blng_sents_part["sentence-pair"]) || [];
    const examples = pairs
      .slice(0, 3)
      .map((p: any) => ({ en: strip(p.sentence), zh: strip(p["sentence-translation"]) }))
      .filter((e: any) => e.en && e.zh);
    cache.set(q, { t: Date.now(), v: examples });
    return new Response(JSON.stringify({ examples }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ examples: [], err: String(e) }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } finally {
    clearTimeout(timer);
  }
}

Deno.serve(handle);
