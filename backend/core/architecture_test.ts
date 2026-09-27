// The core must not depend on adapters, runtimes or Supabase: that is what keeps runtimes swappable.
import { assertEquals } from "jsr:@std/assert@1";

Deno.test("core imports only core modules and the protobuf bindings", () => {
  const bad: string[] = [];
  for (const f of Deno.readDirSync(new URL(".", import.meta.url))) {
    if (!f.name.endsWith(".ts") || f.name.endsWith("_test.ts")) continue;
    const src = Deno.readTextFileSync(new URL(f.name, import.meta.url));
    for (const [, spec] of src.matchAll(/from\s+"([^"]+)"/g)) {
      if (!spec.startsWith("./") && spec !== "npm:gtfs-realtime-bindings@1.1.1") bad.push(`${f.name}: ${spec}`);
      // Relative imports need the extension or the edge bundler silently drops them (measured 23/09).
      if (spec.startsWith("./") && !spec.endsWith(".ts")) bad.push(`${f.name}: ${spec} (no extension)`);
    }
  }
  assertEquals(bad, []);
});
