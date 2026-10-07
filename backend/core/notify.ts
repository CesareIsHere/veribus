// Notices for the trips users follow (supabase/migrations/*_trip_follow.sql). The database decides what is due and
// records it as sent (`notify.claim`); this module writes the notice in the user's language, hands it to a push sender
// and gives back what failed. It knows nothing of FCM or Postgres: the runtimes plug the ports in.

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

  for (const claim of claims) {
    let delivered = false;
    let transient = false;
    for (const device of claim.devices) {
      const result = await ports.push.send(device.token, render(claim, device.locale));
      if (result === "ok") {
        delivered = true;
        summary.sent++;
      } else if (result === "invalid") dead.add(device.token);
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

/** The notice in the device's language (Italian or English). */
export function render(c: Claim, locale: string): Notice {
  const it = locale.toLowerCase().startsWith("it");
  const lang = it ? "it-IT" : "en-GB";
  const trip = hhmm(c.scheduled, lang);
  const to = c.headsign ? (it ? ` verso ${c.headsign}` : ` to ${c.headsign}`) : "";
  const min = c.minutes ?? 0;
  const base = { tag: c.followId, data: { type: "trip", event: c.event, follow_id: c.followId, link: "/trips" } };

  switch (c.event) {
    case "lead": {
      const when = min <= 0 ? (it ? "sta arrivando" : "is arriving") : it ? `tra ${min} min` : `in ${min} min`;
      const approx = c.realtime ? "" : it ? " · orario programmato" : " · scheduled time";
      return {
        ...base,
        title: it ? `Linea ${c.route}: ${when}` : `Line ${c.route}: ${when}`,
        body: `${c.stop}${to}${approx}`,
      };
    }
    case "canceled":
      return {
        ...base,
        title: it ? `Linea ${c.route}: corsa cancellata` : `Line ${c.route}: trip canceled`,
        body: it
          ? `La corsa delle ${trip} a ${c.stop}${to} è stata cancellata`
          : `The ${trip} at ${c.stop}${to} was canceled`,
      };
    case "still":
      return {
        ...base,
        title: it ? `Linea ${c.route}: bus fermo da ${min} min` : `Line ${c.route}: bus standing still for ${min} min`,
        body: it ? `Corsa delle ${trip} a ${c.stop}${to}` : `The ${trip} at ${c.stop}${to}`,
      };
    case "lost":
      return {
        ...base,
        title: it ? `Linea ${c.route}: segnale perso` : `Line ${c.route}: signal lost`,
        body: it
          ? `Il mezzo della corsa delle ${trip} a ${c.stop} ha smesso di trasmettere: potrebbe non arrivare`
          : `The vehicle of the ${trip} at ${c.stop} stopped transmitting: it may not arrive`,
      };
  }
}
