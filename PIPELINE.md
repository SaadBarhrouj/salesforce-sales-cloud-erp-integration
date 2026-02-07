# 🔄 CI/CD Pipeline Documentation

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [CI Pipeline — Pull Request Validation](#ci-pipeline--pull-request-validation)
  - [Job 1: Static Code Analysis (PMD)](#job-1-static-code-analysis-pmd)
  - [Job 2: Build & Test (Scratch Org)](#job-2-build--test-scratch-org)
  - [Job 3: PR Results Comment](#job-3-pr-results-comment)
- [CD Pipeline — Deploy to Integration](#cd-pipeline--deploy-to-integration)
- [PMD Ruleset Configuration](#pmd-ruleset-configuration)
- [CLI Caching Strategy](#cli-caching-strategy)
- [Scenarios & Workflow Examples](#scenarios--workflow-examples)
- [Secrets Configuration](#secrets-configuration)
- [Troubleshooting](#troubleshooting)

---

## Overview

This project uses **GitHub Actions** for continuous integration and continuous deployment of Salesforce metadata. The pipeline is designed around two core principles:

1. **Fail Fast** — Catch code quality issues before expensive scratch org operations
2. **Developer Feedback** — Provide clear, actionable results directly on Pull Requests

### What Changed (vs. Previous Pipeline)

| Feature | Before | After |
|---------|--------|-------|
| Static Analysis | ❌ None | ✅ PMD with custom Apex ruleset |
| PR Feedback | ❌ Must check Actions tab | ✅ Auto-comment on PR with results |
| CLI Installation | 🐌 Fresh install every run (~2 min) | ⚡ Cached (~5 sec on cache hit) |
| Auth file cleanup | ❌ Left on disk | ✅ Removed after use (`rm -f`) |
| Job dependencies | Single monolithic job | 3 jobs with fail-fast dependency chain |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    CI Pipeline (Pull Request)                    │
│                                                                  │
│  ┌──────────────────┐    ┌──────────────────┐    ┌────────────┐ │
│  │  Job 1: PMD      │───▶│  Job 2: Build &  │───▶│  Job 3: PR │ │
│  │  Static Analysis │    │  Test (Scratch)   │    │  Comment   │ │
│  │  (~30 sec)       │    │  (~5-8 min)       │    │  (~10 sec) │ │
│  └──────────────────┘    └──────────────────┘    └────────────┘ │
│         │ fail                  │ fail                           │
│         ▼                      ▼                                │
│    🚫 Block PR           🚫 Block PR                            │
│    (skip Job 2)          (Job 3 still runs)                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    CD Pipeline (Push to main)                    │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Job: Deploy to Integration Org                          │   │
│  │  Checkout → Cache CLI → Auth → Deploy (RunLocalTests)    │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## CI Pipeline — Pull Request Validation

**File:** `.github/workflows/ci.yml`  
**Trigger:** Pull Request targeting `main` branch (only when `force-app/**` files change)

### Job 1: Static Code Analysis (PMD)

**Purpose:** Verify code quality BEFORE creating a scratch org. This saves ~5 minutes of pipeline time when code has quality issues.

**How it works:**

1. Checks out the repository
2. Runs [PMD](https://pmd.github.io/) static analysis using the custom `ruleset.xml`
3. Only analyzes **modified files** (not the entire codebase) for faster execution
4. Creates GitHub annotations (inline warnings/errors on the PR diff)
5. Uploads a SARIF report for GitHub's Security tab
6. **Fails the job** if any violations are found

**What PMD detects:**

| Category | Rules | Priority |
|----------|-------|----------|
| 🔴 **Performance** | SOQL in loops, DML in loops, SOSL in loops | Critical (P1) |
| 🔴 **Error Prone** | Hardcoded IDs, Empty catch blocks | Critical (P1) |
| 🔴 **Security** | SOQL Injection, XSS, Insecure endpoints | Critical (P1) |
| 🟠 **Design** | Cyclomatic complexity > 25, Cognitive complexity > 15 | High (P2) |
| 🟠 **Best Practices** | Unused variables, Logic in triggers, Missing asserts | High (P2) |
| 🟡 **Design** | Class too long (> 500 lines), Too many parameters (> 5) | Medium (P3) |

---

### Job 2: Build & Test (Scratch Org)

**Purpose:** Validate that the code compiles and all Apex tests pass in an isolated scratch org.

**Dependency:** Only runs if **Job 1 (PMD) passes** ✅

**How it works:**

1. Checks out the repository
2. **Restores Salesforce CLI from cache** (or installs fresh if cache miss)
3. Authenticates to the Dev Hub using `SFDX_AUTH_URL` secret
4. Creates a temporary scratch org (1-day duration)
5. Pushes all source to the scratch org
6. Runs all Apex tests with code coverage
7. **Always** deletes the scratch org (even if tests fail)

---

### Job 3: PR Results Comment

**Purpose:** Post a summary comment on the Pull Request so reviewers can see CI results without opening the Actions tab.

**Dependency:** Runs **always** after Jobs 1 and 2 (even if they fail)

**How it works:**

1. Evaluates the result of each previous job (success/failure/skipped)
2. Posts a **sticky comment** on the PR (updates the same comment on re-runs)
3. Includes a link to the full Actions run

---

## CD Pipeline — Deploy to Integration

**File:** `.github/workflows/cd.yml`  
**Trigger:** Push to `main` branch (only when `force-app/**` files change)

**How it works:**

1. Checks out the repository
2. **Restores Salesforce CLI from cache** (or installs fresh if cache miss)
3. Authenticates to the Integration Org using `INTEGRATION_AUTH_URL` secret
4. Deploys all source from `force-app/` with `RunLocalTests` test level

---

## PMD Ruleset Configuration

**File:** `ruleset.xml`

The PMD ruleset is organized into 5 categories with 30+ rules. See the file for full details.

### Customizing the Ruleset

To **disable** a rule, remove or comment out its `<rule>` element.

To **adjust thresholds**, modify the `<property>` values:

```xml
<rule ref="category/apex/design.xml/CyclomaticComplexity">
    <properties>
        <property name="methodReportLevel" value="30" />
    </properties>
</rule>
```

---

## CLI Caching Strategy

Both CI and CD pipelines use **GitHub Actions Cache** to avoid re-installing Salesforce CLI on every run.

| Scenario | What happens | Time saved |
|----------|-------------|------------|
| **Cache hit** | CLI restored from cache, skip install | ~1-2 min |
| **Cache miss** | CLI installed fresh, cached for next run | 0 (first run) |

Cache expires after **7 days** of no access. To force refresh, bump the cache key version.

---

## Scenarios & Workflow Examples

### Scenario 1: Clean PR ✅
PMD passes → Tests pass → PR Comment shows all green → Merge

### Scenario 2: SOQL in a loop ❌
PMD fails → Tests SKIPPED (saved ~5 min) → PR Comment shows failure → Fix and re-push

### Scenario 3: Tests fail ❌
PMD passes → Tests fail → Scratch org deleted → PR Comment shows failure

### Scenario 4: Non-Apex changes
Pipeline does NOT trigger (paths filter: `force-app/**`)

---

## Secrets Configuration

| Secret | Used by | Description |
|--------|---------|-------------|
| `SFDX_AUTH_URL` | CI Pipeline | SFDX auth URL for the Dev Hub org |
| `INTEGRATION_AUTH_URL` | CD Pipeline | SFDX auth URL for the Integration org |

---

## Troubleshooting

### PMD false positives
Add `// NOPMD` comment on the line, or exclude the file in `ruleset.xml`.

### Cache not working
GitHub Actions cache has a 10 GB limit and expires after 7 days of no access.

### PR comment not appearing
Ensure the workflow has `pull-requests: write` permission.
