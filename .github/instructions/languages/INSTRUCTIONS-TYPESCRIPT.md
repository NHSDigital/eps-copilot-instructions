## Language: TypeScript
---
description: 'Brief description of the instruction purpose and scope'
applyTo: '*.ts'
---
### Project Style (clinicalView)
- Use named exports (no default)
- Prefer small pure functions; pass `logger: Logger` explicitly rather than using globals.

### JSON Schema Pattern
- Define schemas with `as const satisfies JSONSchema`
- Export corresponding types using `FromSchema<typeof schema>` right after the schema object.
- Reuse existing element schemas instead of inlining duplicates.

### Coding / Mapping Conventions
- Reuse mapping constants for code/display pairs (e.g. prescription type, performer site, status maps); do not hardcode strings already present.
- For UUIDs use `randomUUID()` from `crypto`
- When adding new status or code systems, centralize enums in a schema file under `src/schema/` and update maps in `fhirMaps.ts`.

### Error Handling
- Represent conditional outcomes using discriminated unions similar to `ParsedSpineResponse` in [`parseSpineResponse`](packages/clinicalView/src/parseSpineResponse.ts).
- Return `[result, errors]` tuples for validators (pattern in `validateRequest` declaration).

### Logging & Middleware
- Instantiate `Logger` from `@aws-lambda-powertools/logger`; pass through layers/functions (see [`handler`](packages/clinicalView/src/handler.ts)).
- For new handlers wrap with `middy` and apply existing middlewares: `injectLambdaContext`, `httpHeaderNormalizer`, `inputOutputLogger`, shared error handler.

### FHIR Resource Construction
- Use existing helper logic patterns in [`generateFhirResponse`](packages/clinicalView/src/generateFhirResponse.ts): derive `intent` from `INTENT_MAP`, map therapy/course codes from constants, conditionally include optional fields with object spread (`...(condition ? {field} : {})`).
- Maintain consistent array wrapping for singular FHIR arrays (e.g. `coding: [{ ... }]`, `identifier: [{ ... }]`, `dosageInstruction: [{ text }]`).

### Extensions
- Follow existing structure: `{ url, valueCoding }` or `{ url, extension: [...] }` (see [`extensions`](packages/clinicalView/src/schema/extensions.ts)).
- Do not invent new URL namespaces; reuse `https://fhir.nhs.uk/...` patterns.

### Testing
- Snapshot-like expectations in tests should mirror object shape used in generation; keep field order stable to reduce churn (see tests in `tests/testGenerateFhirResponse.test.ts`).

### General TS Practices
- Use `as const` for literal enums & maps to preserve string literal types.
- Avoid `any`; prefer explicit interfaces or inferred types from schemas.
- Prefer `Record<Key, Value>` for code/display maps (see `PRESCRIPTION_TYPE_MAP` etc.).
- Use union narrowing via presence checks instead of optional chaining inside tight loops for performance-critical parsing.

### When Adding Code
1. Add schema first (if new structure).
2. Export type via `FromSchema`.
3. Extend maps in `fhirMaps.ts` if introducing coded values.
4. Update generator logic keeping ordering conventions.
5. Add/adjust tests in `packages/clinicalView/tests/`.
6. Ensure new exports are re-exported in index only if needed by other packages.

### Avoid
- Duplicating code system enums already defined.
- Introducing default exports.
- Hardcoding display text strings when a map exists.
- Using mutable push patterns where direct literal construction is clearer.

### Example Pattern (New Simple Schema)
```ts
import {FromSchema, JSONSchema} from "json-schema-to-ts"

export const exampleResource = {
  type: "object",
  properties: {
    resourceType: {type: "string", enum: ["Example"]},
    id: {type: "string"},
    status: {type: "string", enum: ["active", "inactive"]}
  },
  required: ["resourceType", "id", "status"]
} as const satisfies JSONSchema

export type ExampleResourceType = FromSchema<typeof exampleResource>
```

Keep additions consistent with existing clinicalView module structure.