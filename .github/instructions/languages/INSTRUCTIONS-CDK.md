# Copilot Instructions (TypeScript AWS CDK for this repo)
---
description: 'Brief description of the instruction purpose and scope'
applyTo: 'packages/cdk/**'
---
## Purpose
Guide generation of AWS CDK TypeScript code consistent with existing constructs, patterns, naming conventions, and compliance expectations in this repository.

## Core Constructs (reuse over raw CDK)
- Prefer custom constructs:
  - LambdaFunction -> wraps NodejsFunction with logging, layers, policies ([constructs/LambdaFunction.ts](packages/cdk/constructs/LambdaFunction.ts)).
  - RestApiGateway + LambdaEndpoint / StateMachineEndpoint for API resources ([constructs/RestApiGateway.ts](packages/cdk/constructs/RestApiGateway.ts), [constructs/RestApiGateway/LambdaEndpoint.ts](packages/cdk/constructs/RestApiGateway/LambdaEndpoint.ts)).
  - ExpressStateMachine for Step Functions ([constructs/StateMachine.ts](packages/cdk/constructs/StateMachine.ts)).
  - State machine definition ([resources/StateMachineDefinitions/ClinicalView.ts](packages/cdk/resources/StateMachineDefinitions/ClinicalView.ts)).
- When adding a Lambda, use LambdaFunction; do NOT instantiate NodejsFunction directly unless enhancing the construct itself.

## Naming & Environment
- Lambda function names: `${stackName}-<ComponentName>` (see Functions.ts).
- Expose new functions via Functions construct; add environment variables into `lambdaDefaultEnvironmentVariables` ([resources/Functions.ts](packages/cdk/resources/Functions.ts)).
- Required env keys pattern: `LOG_LEVEL`, `NODE_OPTIONS="--enable-source-maps"`, `TargetSpineServer`, versioning (`VERSION_NUMBER`, `COMMIT_ID`), secrets layer (`AWS_LAMBDA_EXEC_WRAPPER="/opt/get-secrets-layer"`).
- Use `Fn.importValue` for cross-stack references (KMS keys, policies, secrets).
- Context keys consumed externally: `accountId`, `stackName`, `versionNumber`, `commitId`, `logRetentionInDays` (set via deployment script).

## Lambda Defaults
Replicate defaults from getDefaultLambdaOptions:
- runtime: `Runtime.NODEJS_22_X`
- memorySize: 256
- timeout: 50s
- architecture: `X86_64`
- handler: "handler"
- bundling: `target: es2022`, `minify: true`, `sourceMap: true`, `tsconfig` points to package's tsconfig

## Logging & Retention
- Pass `logRetentionInDays` into constructs; never hard-code retention.
- Log groups encrypted via imported KMS key; maintain existing pattern.
- When adding subscription filters or streams, follow pattern used in LambdaFunction (Kinesis Stream, subscription roles).

## Policies & Security
- Attach least-privilege managed policies; reuse imported managed policies.
- Suppress cdk-nag rules only via helper in nagSuppressions.ts; do not inline suppressions.
- Avoid wildcard resource ARNs unless justified; document justification consistent with existing reasoning style.

## API Resources
- For new API route:
  1. Create LambdaFunction in Functions.ts.
  2. Use LambdaEndpoint under RestApiGateway with `resourceName` matching path segment.
  3. Attach execution policy via `restApiGatewayRole.addManagedPolicy(lambda.executionPolicy)` (see LambdaEndpoint construct).

## Step Functions
- Compose definitions using existing patterns: Pass, Choice, TaskInput, Function.fromFunctionArn for imported lambdas.
- Return a chainable definition assigned to `this.definition`.

## Layers & Secrets
- Always include secrets layer and Insights layer (see LambdaFunction: insightsLayerArn + getSecretLayer).
- Do not create additional layers unless absolutely needed; if needed, follow same RemovalPolicy and packaging style.

## Removal Policies
- Log groups: `RemovalPolicy.RETAIN`.
- Layers: `RemovalPolicy.RETAIN`.
- Keep consistent to avoid accidental data loss.

## Code Style
- Two-space indentation.
- Interfaces named `<Name>Props`.
- Public construct properties explicitly declared (`public readonly`).
- Avoid default exports.
- Use trailing commas only where existing codebase does (mostly arrays/objects in multiline).
- Enforce explicit access modifiers.

## Import Ordering
1. aws-cdk-lib modules (grouped).
2. Third-party constructs.
3. Local relative imports.
4. Then interfaces & exports.

## Error Handling
- Do not add try/catch in constructs unless wrapping unsafe dynamic operations; rely on CDK synthesis errors.

## Adding New Functionality Example (Lambda + Endpoint)
Generate code that:
- Adds a new LambdaFunction in Functions.ts with proper env reuse.
- Adds endpoint in Apis.ts using LambdaEndpoint.

## What to Avoid
- Direct instantiation of CloudWatch LogGroups outside constructs unless extending logging pattern.
- Hard-coded ARNs instead of `Fn.importValue`.
- Inconsistent environment variable casing.
- Adding inline IAM policies directly to Roles when a ManagedPolicy pattern exists.

## Testing Expectations
- Any new construct should be testable via snapshot or fine-grained assertions (not provided here—keep design modular).

## Performance & Bundling
- Keep bundle size small: rely on minification and es2022 target.
- Do not disable source maps (used for debugging with NODE_OPTIONS).

## cdk-nag
- If new resources trigger nag findings needing suppression, add them to existing grouped calls in nagSuppressions.ts using helper functions; supply reason matching style.

## Deployment Flow
- Remember deployment scripts set context keys: do not rely on undefined fallbacks; ensure constructs read from props rather than process.env (process.env used only inside Lambda runtime code).

## Style Snippet Template (for new construct)
```ts
export interface MyFeatureProps {
  readonly stackName: string
  readonly logRetentionInDays: number
  // additional props...
}

export class MyFeature extends Construct {
  public readonly lambda: LambdaFunction
  public constructor(scope: Construct, id: string, props: MyFeatureProps) {
    super(scope, id)
    this.lambda = new LambdaFunction(this, "MyFeatureLambda", {
      stackName: props.stackName,
      functionName: `${props.stackName}-MyFeature`,
      packageBasePath: "packages/myFeature",
      entryPoint: "src/handler.ts",
      environmentVariables: {/* extend from shared defaults */},
      logRetentionInDays: props.logRetentionInDays,
      logLevel: "INFO"
    })
  }
}
```

## Consistency
Generate code that composes existing constructs, avoids duplication, and maintains naming / environment conventions.

## If Unsure
Prefer referencing or extending an existing construct rather than creating raw CDK resources.
