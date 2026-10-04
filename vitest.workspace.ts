// Vitest workspace — aggregates unit test configs from all packages and services.
// Run with: pnpm test
import { defineWorkspace } from "vitest/config";
export default defineWorkspace(["packages/*/vitest.config.ts", "services/*/vitest.config.ts"]);
