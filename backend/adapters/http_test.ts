import { assertEquals, assertStringIncludes } from "jsr:@std/assert@1";
import { r2Archive } from "./http.ts";

Deno.test("R2 archive: signed S3 PUT under {feed}/YYYY/MM/DD/hhmmss.pb.gz", async () => {
  const real = globalThis.fetch;
  let seen: Request | undefined;
  globalThis.fetch = (input: RequestInfo | URL, init?: RequestInit) => {
    seen = new Request(input, init);
    return Promise.resolve(new Response(null, { status: 200 }));
  };
  try {
    const archive = r2Archive({ accountId: "acc", accessKeyId: "key", secretAccessKey: "secret", bucket: "archive" });
    const path = await archive.put("vp", 1790419130, new Uint8Array([1, 2, 3]));
    assertEquals(path, "vp/2026/09/26/103850.pb.gz");
    assertEquals(seen?.method, "PUT");
    assertEquals(seen?.url, "https://acc.r2.cloudflarestorage.com/archive/vp/2026/09/26/103850.pb.gz");
    assertStringIncludes(seen?.headers.get("authorization") ?? "", "AWS4-HMAC-SHA256 Credential=key/");
  } finally {
    globalThis.fetch = real;
  }
});
