import { assertEquals } from "jsr:@std/assert@1";
import { numberArray } from "./postgres.ts";

// The connection does not fetch the array types, so the integer arrays of live.trip_state come as text.
Deno.test("numberArray reads Postgres integer arrays in text format", () => {
  assertEquals(numberArray("{}"), []);
  assertEquals(numberArray(null), []);
  assertEquals(numberArray("{7}"), [7]);
  assertEquals(numberArray("{1,22,333}"), [1, 22, 333]);
  assertEquals(numberArray("{1790000100,1790000200}"), [1790000100, 1790000200]); // bigint, beyond 32 bits
});
