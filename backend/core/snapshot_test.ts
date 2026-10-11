import { assert, assertEquals, assertRejects } from "jsr:@std/assert@1";
import { decodeState, decodeTripInfo, encodeState, encodeTripInfo } from "./snapshot.ts";
import type { CycleState } from "./types.ts";

const state: CycleState = {
  markers: {
    vp: { lastModified: "Sun, 11 Oct 2026 13:38:24 GMT", hash: "abc", feedTs: 1790000000 },
    tu: { lastModified: null, hash: "def", feedTs: 1790000001 },
    sa: { lastModified: null, hash: null, feedTs: null },
  },
  vehicles: new Map([["V1", {
    vehicleId: "V1",
    label: "3081",
    tripId: "T1",
    routeId: "64",
    lat: 41.9,
    lon: 12.5,
    gpsAt: 1790000000,
    seq: 3,
    stopId: "S1",
    stillLat: 41.9,
    stillLon: 12.5,
    stillSince: 1789999000,
  }]]),
  trips: new Map([["T1", {
    tripId: "T1",
    routeId: "64",
    vehicleId: "V1",
    status: "uncertain" as const,
    signal: { code: "S3" as const, min: 5 },
    predSeq: [3, 4, 5],
    predTs: [1790000100, 1790000200, 1790000300],
    lastSeq: 3,
    seenAt: 1790000000,
    suppressedAt: null,
  }]]),
};

Deno.test("a state survives the round trip, Maps included", async () => {
  const bytes = await encodeState(state);
  const back = await decodeState(bytes);
  assertEquals(back.markers, state.markers);
  assertEquals([...back.vehicles.entries()], [...state.vehicles.entries()]);
  assertEquals([...back.trips.entries()], [...state.trips.entries()]);
  assert(back.vehicles instanceof Map && back.trips instanceof Map);
});

Deno.test("the document is compressed, and a document of another format is refused", async () => {
  const many: CycleState = { ...state, vehicles: new Map(), trips: new Map() };
  for (let i = 0; i < 1000; i++) {
    many.vehicles.set(`V${i}`, { ...state.vehicles.get("V1")!, vehicleId: `V${i}`, tripId: `T${i}` });
    many.trips.set(`T${i}`, { ...state.trips.get("T1")!, tripId: `T${i}`, vehicleId: `V${i}` });
  }
  const bytes = await encodeState(many);
  assert(bytes.length < JSON.stringify([...many.trips.values()]).length / 3, `${bytes.length} bytes`);

  const other = new Blob([JSON.stringify({ format: 99 })]).stream().pipeThrough(new CompressionStream("gzip"));
  await assertRejects(
    async () => await decodeState(new Uint8Array(await new Response(other).arrayBuffer())),
    Error,
    "format",
  );
  await assertRejects(() => decodeState(new Uint8Array([1, 2, 3])));
});

Deno.test("trip info: the entries of the version asked, nothing for another version", async () => {
  const entries = { T1: { routeId: "64", firstSeq: 1, lastSeq: 40 }, T2: { routeId: "40", firstSeq: 1, lastSeq: 30 } };
  const bytes = await encodeTripInfo("v-md5-1", entries);
  assertEquals(await decodeTripInfo(bytes, "v-md5-1"), entries);
  assertEquals(await decodeTripInfo(bytes, "v-md5-2"), null);
});
