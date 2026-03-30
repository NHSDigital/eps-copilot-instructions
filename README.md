# EPS Copilot Instructions

This repository contains the shared GitHub Copilot instruction files used across EPS repositories, along with a composite GitHub Action that copies those files into a target repository and opens a pull request with the changes.

## What this repository contains

- Shared instruction files under `.github/instructions`
- A shared `.github/copilot-instructions.md`
- Shared prompts under `.github/prompts`
- A composite GitHub Action defined in `action.yml`

## Action overview

The action is intended to be called from another repository. It:

1. Checks out the calling repository at the requested base branch
2. Checks out copilot instruction files from copilot_instructions_ref repository at the requested ref
3. Replaces the target repository's Copilot instruction files with the shared versions
4. Creates a signed pull request containing the sync changes

The action currently syncs content from `NHSDigital/eps-common-workflows`.

## Files synced by the action

The action copies the following paths into the calling repository:

- `.github/instructions/general`
- `.github/instructions/languages`
- `.github/copilot-instructions.md`
- `.github/prompts`

Existing copies of those paths in the calling repository are removed before the new content is copied in.

## Inputs

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `copilot_instructions_ref` | No | `main` | Git ref to check out from the eps-copilot-instructions repository |
| `calling_repo_base_branch` | No | `main` | Base branch in the calling repository that the pull request should target |
| `CREATE_PULL_REQUEST_APP_ID` | Yes | None | GitHub App ID used to generate a token for pull request creation |
| `CREATE_PULL_REQUEST_PEM` | Yes | None | GitHub App private key in PEM format |

## Example usage

```yaml
name: Sync Copilot Instructions

on:
  workflow_dispatch:
  schedule:
    - cron: '0 6 * * 1'

jobs:
  sync-copilot-instructions:
    runs-on: ubuntu-latest
    environment: create_pull_request
    permissions:
      contents: read

    steps:
      - name: Sync shared instructions
        uses: NHSDigital/eps-copilot-instructions@95118f6746ca7081258cc7f651dca1c5bb7339f1
        with:
          copilot_instructions_ref: main
          calling_repo_base_branch: main
          CREATE_PULL_REQUEST_APP_ID: ${{ secrets.CREATE_PULL_REQUEST_APP_ID }}
          CREATE_PULL_REQUEST_PEM: ${{ secrets.CREATE_PULL_REQUEST_PEM }}
```

## Pull request behavior

When changes are detected, the action creates a pull request with:

- Branch prefix: `copilot-instructions-sync`
- Commit message: `Upgrade: [dependabot] - sync Copilot instructions`
- Pull request title: `Upgrade: [dependabot] - sync Copilot instructions`
- Signed commits enabled
- Automatic branch cleanup enabled

The pull request body includes the ref used for the sync.

## Prerequisites

Before using the action in a repository, ensure that https://github.com/NHSDigital/electronic-prescription-service-account-resources/blob/main/scripts/set_github_secrets.py has been run to create the environment and secrets

## Notes

- The action is implemented as a composite action in `action.yml`
- It uses pinned action SHAs for its external action dependencies
- The action opens a pull request instead of pushing directly to the base branch