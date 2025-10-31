---
description: 'Brief description of the instruction purpose and scope'
applyTo: 'terraform/**'
---

# Copilot Authoring Guide for Terraform in this Repository

This guide tunes AI code completions for our Terraform code under `terraform/`. It encodes patterns and constraints we want Copilot to follow. Completions that violate these rules should be discarded or re-asked.

## Core Principles
- Deterministic, explicit infrastructure: prefer explicit resource blocks over opaque modules unless a shared module already exists in `terraform/modules/`.
- Consistent tagging & naming: all AWS resources must include `default_tags` or explicit `tags` matching our local tags set (see below).
- Environment isolation via Terraform workspaces: never hardcode environment names; derive with `terraform.workspace` in locals.
- Minimise blast radius: use variables for mutable capacity / feature toggles; avoid inline wildcards except where already accepted (some IAM policies intentionally use `*`).
- Security first: prefer least privilege in new policies. Do NOT introduce new broad `"*"` actions unless strongly justified.
- Idempotent & import-friendly: avoid interpolations that create random strings; no `random_*` resources unless approved.

## Standard Locals Pattern
Every stack defines:
```hcl
locals {
  environment         = terraform.workspace
  production          = startswith(local.environment, "live")
  data_classification = local.production ? "5" : "1"
  aws_account_id      = data.aws_caller_identity.current.account_id
  tags = {
    TagVersion         = "1"
    Programme          = "Clinicals"
    Project            = "EPS"
    DataClassification = local.data_classification
    Environment        = local.environment
    ServiceCategory    = local.production ? "Platinum" : "N/A"
    Tool               = "terraform"
    Domain             = "clinicals"
    map-migrated       = "mig45780"
  }
}

data "aws_caller_identity" "current" {}
```
Copilot should replicate this exact structure when creating a new stack folder.

## Provider & Backend Block
Use the pattern:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">=1.9.4"
}

provider "aws" {
  region              = "eu-west-2"
  allowed_account_ids = var.allowed_account_ids
  default_tags { tags = local.tags }
}

terraform { backend "s3" {} }
```
Never add backend bucket/key details here; they are injected externally via init.

## Variables Conventions
- Always define variables with `description` unless trivial and already established (e.g. repeated `allowed_account_ids`).
- Use concrete types (`list(string)`, `map(object({...}))`, `object({...})`); avoid `any`.
- Feature toggles use `bool` with default `false` unless enabling is safer (explicit exceptions: see existing patterns like `deploy_insights = true`).
- Capacity objects: follow `provisioned_capacity` shape from `storage/variables.tf` if adding similar scaling constructs.

## Resource Naming
- Prefix environment only when conditional: use a `prepend_env` variable or local logic (see `iam.tf`).
- KMS alias pattern: `alias/${local.environment}-<purpose>`.
- S3 bucket pattern: `${local.environment}-spine-eps-datastore-archive` etc. Always avoid uppercase and underscores.
- IAM roles/policies: include environment, service, purpose; keep consistent with existing examples (`eps-storage-${local.environment}-terraform-plan`).

## Tagging
- Use provider `default_tags` except where AWS requires inline tags (e.g., DynamoDB `tags` or KMS policy-derived resources). Inline tags MUST include a `Name` following existing naming conventions.
- Do not add ad-hoc tag keys. Changes to tagging require team approval.

## IAM Policies
- Prefer `data "aws_iam_policy_document"` to build JSON, then `aws_iam_policy`.
- Allowed wildcard: inside `Resource` when resource ARNs vary or for already broadly permitted deployment role (`codebuild_apply`). Don't extend wildcard scope in new policies.
- When referencing DynamoDB stream or table ARNs lists: use for-expressions as in `iam.tf`.

## KMS Policies
- Keep the minimal root policy block pattern used in `kms.tf`; don't invent complex grants unless required.
- Reuse `aws_account_id` from locals; never hardcode account IDs.

## DynamoDB Tables
- Table names come from `var.ddb_table_names`; don't hardcode names.
- Support both PAY_PER_REQUEST and PROVISIONED with the existing capacity structure.
- Enable encryption: always specify `server_side_encryption { enabled = true kms_key_arn = <key>.arn }`.
- Conditional features (TTL, PITR, streams) are controlled by variables; replicate this approach for new features.

## Autoscaling
- Use `for_each` with `toset(var.ddb_table_names)` or derived maps; replicate naming pattern for policies.
- Target tracking metric type should match read/write capacity utilization; keep target at `70` unless data-driven change requested.

## Event Source Mappings
- Derive lambda ARN via locals; avoid duplicating account ID retrieval.
- Set batching window conditional by environment (`dev` = 0 else 60).
- Use filter criteria with jsonencode pattern like existing `event_source.tf`.

## S3 Buckets
- Must set: versioning, encryption (KMS), public access block, lifecycle only for non-production (count trick `local.production ? 0 : 1`).
- Enforce SSL with a bucket policy using the `AllowSSLRequestsOnly` statement pattern.

## CodeBuild / CodePipeline
- Environment variable injection should use interpolation of pipeline variables like shown (`#{variables.TerraformStack}`).
- Buildspec paths live under `terraform/deployment/scripts/`.
- Log groups names follow `/eps-storage-${local.environment}-codebuild/<purpose>`.
- Use `execution_mode = "PARALLEL"` and include dynamic Approval stage only for non-dev envs.

## Module Usage
- If adding a reusable construct, place it under `terraform/modules/<module-name>/` and accept inputs rather than hardcoding environment. Provide example usage in a stack.
- Keep modules small, single responsibility (e.g., backup-destination vs backup-source separation).

## Workspaces & Environments
- Never assume workspace names beyond matching `live*` for production detection.
- Place per-env config in `env/*.tfvars.json` files; do not create new env-specific `.tf` logic.

## Formatting & Style
- Indent with two spaces.
- Keep attribute ordering: identifiers (name/bucket/etc) first, then settings, then nested blocks, then `tags` last.
- Use snake_case for variable names; hyphen-separated for resource names.
- Use `jsonencode({...})` for inline JSON to prevent quoting mistakes.

## tfsec & Security Exceptions
- Annotate intentional rule suppressions with inline comments directly above the resource (`# tfsec:ignore:<rule-id>`).
- Don't add new ignores without reason; if required, add short justification after the rule id.

## Avoid
- Randomness (`random_id`, etc.) unless collision avoidance is critical and approved.
- Hardcoding account IDs, environment names, or ARNs (derive via data sources / locals).
- Unbounded resource growth (autoscaling caps required via variables).

## When Copilot Generates Code
1. Include the standard locals and provider blocks for new stack folders.
2. Reuse existing variable patterns; if unsure, look at the closest analogous file.
3. Prefer `for_each` over `count` when keys are meaningful (use `count` only for conditional single resources).
4. Suggest feature toggles (bool vars) for optional capabilities.
5. Ensure encryption and logging defaults are present.

## Review Checklist (Copilot Internal)
Before finalizing a completion:
- Are all new resources tagged? (Either via default_tags or inline Name)
- Are environment/account references dynamic?
- Are optional features behind variables?
- Are IAM/KMS policies least-privilege following patterns?
- Is formatting consistent (2 spaces, block ordering)?

## Example Minimal New Stack Skeleton
```hcl
# terraform/newstack/locals.tf
locals { /* standard locals as above */ }

data "aws_caller_identity" "current" {}

# terraform/newstack/provider.tf
terraform { /* standard required_providers and required_version */ }
provider "aws" { /* region + allowed_account_ids + default_tags */ }
terraform { backend "s3" {} }

# terraform/newstack/variables.tf
variable "allowed_account_ids" { type = list(string) }
```

## Extending This Guide
Raise a PR to modify this file for any new patterns. Don't drift without updating instructions. Keep the frontmatter `languages` array if adding multi-language guidance.

---
