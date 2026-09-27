// Entry point only: the logic lives in backend/ so the container runtime can reuse it unchanged.
import { handler } from "../../../backend/runtimes/edge/handler.ts";

Deno.serve(handler);
