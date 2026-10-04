// Root ESLint flat config — extends shared config from tooling/eslint.
// Each package may add overrides in its own eslint.config.mjs.
import base from "./tooling/eslint/index.mjs";
export default [...base];
