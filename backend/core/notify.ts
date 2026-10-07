// Notices for the trips users follow (supabase/migrations/*_trip_follow.sql). The database decides what is due and
// records it as sent (`notify.claim`); this module writes the notice in the user's language, hands it to a push sender
// and gives back what failed. It knows nothing of FCM or Postgres: the runtimes plug the ports in.

import { noticeStrings } from "./notice_strings.ts";

export type NoticeEvent = "lead" | "canceled" | "still" | "lost";

export interface Device {
  token: string;
  /** Language of the app on that device ("it", "en"); anything else gets English. */
  locale: string;
}

/** One notice due for one followed trip, as `notify.claim` returns it. */
export interface Claim {
  followId: string;
  /** Service day the trip belongs to (YYYY-MM-DD). */
  serviceDate: string;
  event: NoticeEvent;
  /** Everything the database recorded as sent with this notice (the lead times skipped by a catch-up too). */
  kinds: string[];
  /** lead: minutes to the stop; still: minutes standing still. */
  minutes: number | null;
  /** Epoch seconds: when the bus is expected at the stop (prediction, or the schedule without realtime). */
  eta: number;
  /** Epoch seconds: the scheduled time at the stop, which names the trip ("the 17:10"). */
  scheduled: number;
  /** False when `eta` is only the schedule. */
  realtime: boolean;
  route: string;
  stop: string;
  headsign: string;
  devices: Device[];
}

export interface Notice {
  title: string;
  body: string;
  /** Replaces the previous notice with the same tag: "in 10 min" takes the place of "in 15 min". */
  tag: string;
  data: Record<string, string>;
}

export type SendResult =
  /** Delivered to FCM. */
  | "ok"
  /** The token is dead (app uninstalled, token rotated): forget it. */
  | "invalid"
  /** FCM or the network failed for now: try again at the next cycle. */
  | "retry"
  /** Refused for a reason retrying does not fix (credentials, malformed message): logged, not retried. */
  | "failed";

export interface PushSender {
  send(token: string, notice: Notice): Promise<SendResult>;
}

export interface NotifyStore {
  /** The notices due now, already recorded as sent. */
  claim(): Promise<Claim[]>;
  /** Takes the record back: the next cycle will claim them again. */
  release(claims: Claim[]): Promise<void>;
  dropTokens(tokens: string[]): Promise<void>;
}

export interface NotifySummary {
  claimed: number;
  sent: number;
  retried: number;
  dropped: number;
  failed: number;
}

export async function runNotifier(ports: { store: NotifyStore; push: PushSender }): Promise<NotifySummary> {
  const claims = await ports.store.claim();
  const summary: NotifySummary = { claimed: claims.length, sent: 0, retried: 0, dropped: 0, failed: 0 };
  const retry: Claim[] = [];
  const dead = new Set<string>();

  // Every send at once: a few notices a cycle, and a slow FCM must not stretch the cycle by its timeout per device.
  const outcomes = await Promise.all(claims.map(async (claim) => ({
    claim,
    results: await Promise.all(claim.devices.map(async (d) => ({
      token: d.token,
      result: await ports.push.send(d.token, render(claim, d.locale)),
    }))),
  })));

  for (const { claim, results } of outcomes) {
    let delivered = false;
    let transient = false;
    for (const { token, result } of results) {
      if (result === "ok") {
        delivered = true;
        summary.sent++;
      } else if (result === "invalid") dead.add(token);
      else if (result === "retry") transient = true;
      else summary.failed++;
    }
    // A user with one good device and one that failed is notified: only a notice nobody got is tried again.
    if (!delivered && transient) retry.push(claim);
  }

  if (retry.length > 0) await ports.store.release(retry);
  if (dead.size > 0) await ports.store.dropTokens([...dead]);
  summary.retried = retry.length;
  summary.dropped = dead.size;
  return summary;
}

const clock = new Map<string, Intl.DateTimeFormat>();

/** "17:10" in Rome, whatever the server's time zone. */
function hhmm(epoch: number, locale: string): string {
  let f = clock.get(locale);
  if (!f) {
    f = new Intl.DateTimeFormat(locale, {
      timeZone: "Europe/Rome",
      hour: "2-digit",
      minute: "2-digit",
      hourCycle: "h23",
    });
    clock.set(locale, f);
  }
  return f.format(new Date(epoch * 1000));
}

/** `{name}` placeholders of a template. */
function fill(template: string, values: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (_, name) => String(values[name] ?? ""));
}

/** The notice in the device's language (the texts come from the ARB files: notice_strings.ts), English by default. */
export function render(c: Claim, locale: string): Notice {
  const lang = locale.slice(0, 2).toLowerCase();
  const t = noticeStrings[lang] ?? noticeStrings.en;
  const tpl = (key: string, values: Record<string, string | number> = {}) => fill(t[key], values);
  const route = c.route;
  const time = hhmm(c.scheduled, noticeStrings[lang] ? lang : "en-GB");
  const place = c.headsign ? tpl("pushStopTo", { stop: c.stop, headsign: c.headsign }) : c.stop;
  const min = c.minutes ?? 0;
  const base = { tag: c.followId, data: { type: "trip", event: c.event, follow_id: c.followId, link: "/trips" } };

  switch (c.event) {
    case "lead":
      return {
        ...base,
        title: min <= 0 ? tpl("pushArriving", { route }) : tpl("pushLead", { route, minutes: min }),
        // Without realtime the time is only the schedule, and the notice says so.
        body: c.realtime ? place : `${place} · ${tpl("pushScheduled")}`,
      };
    case "canceled":
      return { ...base, title: tpl("pushCanceledTitle", { route }), body: tpl("pushCanceledBody", { time, place }) };
    case "still":
      return {
        ...base,
        title: tpl("pushStillTitle", { route, minutes: min }),
        body: tpl("pushStillBody", { time, place }),
      };
    case "lost":
      return { ...base, title: tpl("pushLostTitle", { route }), body: tpl("pushLostBody", { time, place: c.stop }) };
  }
}
