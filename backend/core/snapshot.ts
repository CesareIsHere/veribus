// The poller's state as a compressed document, for the runtimes that keep it outside the database (the edge function
// writes it to R2: its outbound traffic is not Supabase egress, reading the same rows back from Postgres is).
import type { CycleState, Feed, FeedMarker, TripInfo, TripState, Vehicle } from "./types.ts";

const FORMAT = 1;

interface StateDocument {
  format: number;
  markers: Record<Feed, FeedMarker>;
  vehicles: Vehicle[];
  trips: TripState[];
}

export interface TripInfoDocument {
  format: number;
  /** The network version (md5 of the import) the entries belong to. */
  version: string;
  entries: Record<string, TripInfo>;
}

async function gzip(text: string): Promise<Uint8Array> {
  const stream = new Blob([text]).stream().pipeThrough(new CompressionStream("gzip"));
  return new Uint8Array(await new Response(stream).arrayBuffer());
}

async function gunzip(bytes: Uint8Array): Promise<string> {
  const stream = new Blob([bytes as BlobPart]).stream().pipeThrough(new DecompressionStream("gzip"));
  return await new Response(stream).text();
}

export function encodeState(state: CycleState): Promise<Uint8Array> {
  const doc: StateDocument = {
    format: FORMAT,
    markers: state.markers,
    vehicles: [...state.vehicles.values()],
    trips: [...state.trips.values()],
  };
  return gzip(JSON.stringify(doc));
}

/** Throws on a document of another format: the caller then reads the database instead. */
export async function decodeState(bytes: Uint8Array): Promise<CycleState> {
  const doc = JSON.parse(await gunzip(bytes)) as StateDocument;
  if (doc.format !== FORMAT) throw new Error(`state document format ${doc.format}, expected ${FORMAT}`);
  return {
    markers: doc.markers,
    vehicles: new Map(doc.vehicles.map((v) => [v.vehicleId, v])),
    trips: new Map(doc.trips.map((t) => [t.tripId, t])),
  };
}

export function encodeTripInfo(version: string, entries: Record<string, TripInfo>): Promise<Uint8Array> {
  return gzip(JSON.stringify({ format: FORMAT, version, entries } satisfies TripInfoDocument));
}

/** The entries for `version`, or null when the document is of another version or format. */
export async function decodeTripInfo(bytes: Uint8Array, version: string): Promise<Record<string, TripInfo> | null> {
  const doc = JSON.parse(await gunzip(bytes)) as TripInfoDocument;
  return doc.format === FORMAT && doc.version === version ? doc.entries : null;
}
