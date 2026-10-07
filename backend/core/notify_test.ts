import { assertEquals } from "jsr:@std/assert@1";
import {
  type Claim,
  type Notice,
  type NotifyStore,
  type PushSender,
  render,
  runNotifier,
  type SendResult,
} from "./notify.ts";

// 17:10 in Rome (UTC+2 in October).
const scheduled = Date.UTC(2026, 9, 6, 15, 10) / 1000;
const claim = (over: Partial<Claim> = {}): Claim => ({
  followId: "f1",
  serviceDate: "2026-10-06",
  event: "lead",
  kinds: ["lead:10"],
  minutes: 10,
  eta: scheduled + 120,
  scheduled,
  realtime: true,
  route: "64",
  stop: "Venezia",
  headsign: "Termini",
  devices: [{ token: "tok", locale: "it" }],
  ...over,
});

Deno.test("a lead notice says the line, the minutes and the stop, in the device's language", () => {
  const it = render(claim(), "it-IT");
  assertEquals([it.title, it.body], ["Linea 64: tra 10 min", "Venezia verso Termini"]);
  const en = render(claim(), "en");
  assertEquals([en.title, en.body], ["Line 64: in 10 min", "Venezia to Termini"]);
  assertEquals(render(claim(), "fr").title, "Line 64: in 10 min"); // anything else gets English
});

Deno.test("a lead notice from the schedule says so; at zero minutes the bus is arriving", () => {
  assertEquals(render(claim({ realtime: false }), "it").body, "Venezia verso Termini · orario programmato");
  assertEquals(render(claim({ realtime: false }), "en").body, "Venezia to Termini · scheduled time");
  assertEquals(render(claim({ minutes: 0 }), "it").title, "Linea 64: sta arrivando");
  assertEquals(render(claim({ minutes: 0 }), "en").title, "Line 64: is arriving");
});

Deno.test("status notices name the trip by its scheduled time in Rome", () => {
  const canceled = render(claim({ event: "canceled", minutes: null }), "it");
  assertEquals(canceled.title, "Linea 64: corsa cancellata");
  assertEquals(canceled.body, "La corsa delle 17:10 a Venezia verso Termini è stata cancellata");
  const still = render(claim({ event: "still", minutes: 7 }), "en");
  assertEquals(still.title, "Line 64: bus standing still for 7 min");
  assertEquals(still.body, "The 17:10 at Venezia to Termini");
  assertEquals(render(claim({ event: "lost", minutes: null }), "en").title, "Line 64: signal lost");
});

Deno.test("the notice carries a tag per trip and a link to the followed trips", () => {
  const n = render(claim(), "en");
  assertEquals(n.tag, "f1");
  assertEquals(n.data, { type: "trip", event: "lead", follow_id: "f1", link: "/trips" });
});

function fakes(results: Record<string, SendResult>) {
  const log = { sent: [] as [string, Notice][], released: [] as Claim[], dropped: [] as string[] };
  let due: Claim[] = [];
  const store: NotifyStore = {
    claim: () => Promise.resolve(due),
    release: (c) => Promise.resolve(void log.released.push(...c)),
    dropTokens: (t) => Promise.resolve(void log.dropped.push(...t)),
  };
  const push: PushSender = {
    send: (token, notice) => {
      log.sent.push([token, notice]);
      return Promise.resolve(results[token] ?? "ok");
    },
  };
  return { log, ports: { store, push }, due: (c: Claim[]) => (due = c) };
}

Deno.test("each device gets the notice in its own language", async () => {
  const f = fakes({});
  f.due([claim({ devices: [{ token: "a", locale: "it" }, { token: "b", locale: "en" }] })]);
  const s = await runNotifier(f.ports);
  assertEquals(s, { claimed: 1, sent: 2, retried: 0, dropped: 0, failed: 0 });
  assertEquals(f.log.sent.map(([t, n]) => [t, n.title]), [["a", "Linea 64: tra 10 min"], ["b", "Line 64: in 10 min"]]);
});

Deno.test("a dead token is forgotten, the other device still gets the notice", async () => {
  const f = fakes({ dead: "invalid" });
  f.due([claim({ devices: [{ token: "dead", locale: "it" }, { token: "ok", locale: "it" }] })]);
  const s = await runNotifier(f.ports);
  assertEquals([s.sent, s.dropped, s.retried], [1, 1, 0]);
  assertEquals(f.log.dropped, ["dead"]);
  assertEquals(f.log.released, []);
});

Deno.test("a notice nobody received because FCM was down is released for the next cycle", async () => {
  const f = fakes({ a: "retry", b: "retry" });
  const c = claim({ devices: [{ token: "a", locale: "it" }, { token: "b", locale: "it" }] });
  f.due([c, claim({ followId: "f2", devices: [{ token: "c", locale: "it" }] })]);
  const s = await runNotifier(f.ports);
  assertEquals([s.sent, s.retried], [1, 1]);
  assertEquals(f.log.released, [c]);
});

Deno.test("a refused notice is not retried, one half-delivered is not repeated", async () => {
  const f = fakes({ bad: "failed", flaky: "retry" });
  f.due([
    claim({ followId: "f1", devices: [{ token: "bad", locale: "it" }] }),
    claim({ followId: "f2", devices: [{ token: "flaky", locale: "it" }, { token: "ok", locale: "it" }] }),
  ]);
  const s = await runNotifier(f.ports);
  assertEquals([s.sent, s.failed, s.retried], [1, 1, 0]);
  assertEquals(f.log.released, []);
});

Deno.test("nothing due, nothing done", async () => {
  const f = fakes({});
  assertEquals(await runNotifier(f.ports), { claimed: 0, sent: 0, retried: 0, dropped: 0, failed: 0 });
  assertEquals(f.log.sent, []);
});
