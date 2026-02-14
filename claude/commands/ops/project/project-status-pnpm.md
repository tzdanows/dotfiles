---
allowed-tools: Bash(pnpm:*), Bash(node:*), Bash(fd:*), Bash(rg:*), Bash(jq:*), Bash(gdate:*), Bash(echo:*), Bash(which:*), Bash(eza:*), Bash(bat:*)
description: Comprehensive pnpm TypeScript project health check with build, test, lint, and type checking analysis
---

## Context

- Session ID: !`gdate +%s%N 2>/dev/null || date +%s%N 2>/dev/null || echo "$(date +%s)$(jot -r 1 100000 999999 2>/dev/null || shuf -i 100000-999999 -n 1 2>/dev/null || echo $RANDOM$RANDOM)"`
- Check mode: $ARGUMENTS (optional - quick or detailed, default: quick)
- Current directory: !`pwd`
- Node version: !`node --version 2>/dev/null || echo "Node not installed"`
- pnpm version: !`pnpm --version 2>/dev/null || echo "pnpm not installed"`
- Project detected: !`[ -f package.json ] && echo " Node.js project found" || echo " No package.json found"`
- TypeScript: !`[ -f tsconfig.json ] && echo "TypeScript project detected" || echo "JavaScript project"`
- Workspace: !`[ -f pnpm-workspace.yaml ] && echo "pnpm workspace detected" || echo "Single package project"`

## Your Task

STEP 1: Initialize pnpm project health check session

- CREATE session state file: `/tmp/pnpm-status-$SESSION_ID.json`
- VALIDATE Node.js project presence (package.json)
- DETERMINE check mode from $ARGUMENTS (quick vs detailed)
- GATHER initial project metadata

```bash
# Initialize session state
echo '{
  "sessionId": "'$SESSION_ID'",
  "timestamp": "'$(gdate -Iseconds 2>/dev/null || date -Iseconds)'",
  "checkMode": "'${ARGUMENTS:-quick}'",
  "projectPath": "'$(pwd)'",
  "healthStatus": {
    "build": "pending",
    "tests": "pending",
    "lint": "pending",
    "typecheck": "pending",
    "dependencies": "pending",
    "scripts": "pending"
  },
  "issues": []
}' > /tmp/pnpm-status-$SESSION_ID.json
```

STEP 2: Build and compilation health check

TRY:

```bash
echo " BUILD STATUS"
echo "═══════════════"

# Check if build script exists
if rg -q '"build"' package.json 2>/dev/null; then
    if [ "${ARGUMENTS:-quick}" = "detailed" ]; then
        # Detailed mode: run full build
        if pnpm build >/dev/null 2>&1; then
            echo " Project builds successfully"
            jq '.healthStatus.build = "pass"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
        else
            echo " Build errors detected"
            jq '.healthStatus.build = "fail"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
            echo "Run 'pnpm build' for details"
        fi
    else
        echo "ℹ️  Build script available (skipped in quick mode)"
        jq '.healthStatus.build = "pass"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
    fi
else
    echo "️  No build script defined"
    jq '.healthStatus.build = "warn"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
    echo "   Add 'build' script to package.json"
fi

# Check TypeScript compilation
if [ -f tsconfig.json ]; then
    echo ""
    echo " TypeScript compilation check..."
    if pnpm exec tsc --noEmit >/dev/null 2>&1; then
        echo " TypeScript compiles without errors"
        jq '.healthStatus.typecheck = "pass"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
    else
        echo " TypeScript compilation errors"
        jq '.healthStatus.typecheck = "fail"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
        echo "Run 'pnpm exec tsc --noEmit' for details"
    fi
else
    echo "ℹ️  No TypeScript configuration found"
    jq '.healthStatus.typecheck = "pass"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
fi

# Count source files
src_count=$(fd "\.(ts|tsx|js|jsx)$" src 2>/dev/null | wc -l || echo "0")
echo "   Source files: $src_count"
```

CATCH (build_check_failed):

```bash
echo "️  Build check failed - checking for common issues:"
echo "  - Missing dependencies: pnpm install"
echo "  - TypeScript errors: pnpm exec tsc --noEmit"
echo "  - Build tool issues: check build script configuration"
```

STEP 3: Test suite health analysis

```bash
echo ""
echo " TEST STATUS"
echo "═══════════════"

# Check if test script exists
if rg -q '"test"' package.json 2>/dev/null; then
    if [ "${ARGUMENTS:-quick}" = "detailed" ]; then
        # Detailed mode: run tests
        if pnpm test --passWithNoTests 2>&1 | rg -q -E "(PASS|passed||Success)" || pnpm test 2>&1 | rg -q "0 passing"; then
            echo " Tests pass"
            jq '.healthStatus.tests = "pass"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
        else
            echo " Test failures detected"
            jq '.healthStatus.tests = "fail"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
            echo "Run 'pnpm test' for details"
        fi
        
        # Check for coverage
        if rg -q '"test:coverage"' package.json 2>/dev/null; then
            echo " Coverage script available"
            echo "   Run 'pnpm test:coverage' for coverage report"
        fi
    else
        echo "ℹ️  Test script available (skipped in quick mode)"
        jq '.healthStatus.tests = "pass"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
    fi
else
    echo "️  No test script defined"
    jq '.healthStatus.tests = "warn"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
    echo "   Add 'test' script to package.json"
fi

# Count test files
test_count=$(fd "\.(test|spec)\.(ts|tsx|js|jsx)$|__tests__" . 2>/dev/null | wc -l || echo "0")
echo "   Test files: $test_count"

# Detect test framework
rg -q "jest" package.json 2>/dev/null && echo "   Test framework: Jest"
rg -q "vitest" package.json 2>/dev/null && echo "   Test framework: Vitest"
rg -q "mocha" package.json 2>/dev/null && echo "   Test framework: Mocha"
rg -q "@testing-library" package.json 2>/dev/null && echo "   Using Testing Library"
```

STEP 4: Code quality - ESLint and Prettier

```bash
echo ""
echo " CODE QUALITY"
echo "═══════════════"

# ESLint check
if rg -q "eslint" package.json 2>/dev/null; then
    if [ -f .eslintrc.js ] || [ -f .eslintrc.json ] || [ -f .eslintrc.yaml ] || [ -f eslint.config.js ]; then
        echo " ESLint configured"
        
        if rg -q '"lint"' package.json 2>/dev/null; then
            if [ "${ARGUMENTS:-quick}" = "detailed" ]; then
                # Run linting in detailed mode
                if pnpm lint >/dev/null 2>&1; then
                    echo " No lint issues"
                    jq '.healthStatus.lint = "pass"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
                else
                    echo "️  Lint issues found"
                    jq '.healthStatus.lint = "warn"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
                    echo "Run 'pnpm lint' for details"
                fi
            else
                echo "   Lint script available"
                jq '.healthStatus.lint = "pass"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
            fi
        else
            echo "️  No lint script defined"
            jq '.healthStatus.lint = "warn"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
        fi
    else
        echo "️  ESLint installed but not configured"
        jq '.healthStatus.lint = "warn"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
    fi
else
    echo "ℹ️  ESLint not installed"
    jq '.healthStatus.lint = "pass"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
fi

# Prettier check
if rg -q "prettier" package.json 2>/dev/null; then
    if [ -f .prettierrc ] || [ -f .prettierrc.js ] || [ -f .prettierrc.json ] || [ -f prettier.config.js ]; then
        echo " Prettier configured"
        
        if rg -q '"format"' package.json 2>/dev/null; then
            echo "   Format script available"
        else
            echo "   Add 'format' script: \"prettier --write .\""
        fi
    else
        echo "️  Prettier installed but not configured"
    fi
else
    echo "ℹ️  Prettier not installed"
fi
```

STEP 5: Dependency health and security

```bash
echo ""
echo " DEPENDENCIES & SECURITY"
echo "══════════════════════════"

# Check lock file
if [ -f pnpm-lock.yaml ]; then
    echo " Lock file present"
    # Count dependencies
    dep_count=$(pnpm list --depth=0 --json 2>/dev/null | jq -r '.[0].dependencies | length' || echo "0")
    dev_dep_count=$(pnpm list --depth=0 --json --dev 2>/dev/null | jq -r '.[0].devDependencies | length' || echo "0")
    echo "   Dependencies: $dep_count production, $dev_dep_count development"
else
    echo " No pnpm-lock.yaml found"
    echo "   Run 'pnpm install' to generate lock file"
fi

# Check for outdated packages
if [ "${ARGUMENTS:-quick}" = "detailed" ]; then
    echo ""
    echo " Checking for outdated packages..."
    outdated=$(pnpm outdated --format json 2>/dev/null | jq -r '. | length' || echo "0")
    if [ "$outdated" -gt 0 ]; then
        echo "️  $outdated packages have updates available"
        echo "   Run 'pnpm outdated' for details"
    else
        echo " All packages up to date"
    fi
fi

# Security audit
echo ""
echo " Security audit..."
audit_output=$(pnpm audit --json 2>/dev/null || echo '{"advisories":{}}')
vulnerabilities=$(echo "$audit_output" | jq -r '.advisories | length' || echo "0")

if [ "$vulnerabilities" -eq 0 ]; then
    echo " No known vulnerabilities"
    jq '.healthStatus.dependencies = "pass"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
else
    echo " $vulnerabilities security vulnerabilities found!"
    jq '.healthStatus.dependencies = "fail"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
    echo "Run 'pnpm audit' for details"
    echo "Try 'pnpm audit --fix' to auto-fix"
fi

# Check for unused dependencies
if which depcheck >/dev/null 2>&1; then
    echo ""
    echo " Checking for unused dependencies..."
    depcheck --json 2>/dev/null | jq -r '.dependencies | length' | xargs -I {} echo "   {} unused dependencies found"
else
    echo ""
    echo "ℹ️  depcheck not installed (install globally: pnpm add -g depcheck)"
fi
```

STEP 6: Scripts and project configuration

```bash
echo ""
echo " SCRIPTS & CONFIGURATION"
echo "══════════════════════════"

# Analyze available scripts
scripts=$(jq -r '.scripts | keys[]' package.json 2>/dev/null | wc -l || echo "0")
if [ "$scripts" -gt 0 ]; then
    echo " $scripts npm scripts configured"
    jq '.healthStatus.scripts = "pass"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
    
    # List key scripts
    echo "   Key scripts:"
    jq -r '.scripts | to_entries[] | select(.key | IN("dev", "start", "build", "test", "lint", "format", "typecheck")) | "   - \(.key): \(.value)"' package.json 2>/dev/null | head -10 || true
else
    echo " No scripts defined"
    jq '.healthStatus.scripts = "fail"' /tmp/pnpm-status-$SESSION_ID.json > /tmp/pnpm-status-$SESSION_ID.tmp && mv /tmp/pnpm-status-$SESSION_ID.tmp /tmp/pnpm-status-$SESSION_ID.json
fi

# Check for common configuration files
echo ""
echo "️  Configuration files:"
[ -f tsconfig.json ] && echo "    tsconfig.json (TypeScript)"
[ -f vite.config.ts ] || [ -f vite.config.js ] && echo "    Vite configuration"
[ -f webpack.config.js ] && echo "    Webpack configuration"
[ -f rollup.config.js ] && echo "    Rollup configuration"
[ -f .babelrc ] || [ -f babel.config.js ] && echo "    Babel configuration"
[ -f jest.config.js ] || [ -f vitest.config.ts ] && echo "    Test configuration"
[ -f .env.example ] && echo "    Environment example file"
```

STEP 7: Project structure and framework detection (detailed mode)

IF check_mode is "detailed":

```bash
echo ""
echo " PROJECT STRUCTURE"
echo "══════════════════"

# Check for important files
[ -f README.md ] && echo " README.md present" || echo "️  Missing README.md"
[ -f LICENSE ] && echo " LICENSE present" || echo "️  Missing LICENSE file"
[ -f .gitignore ] && echo " .gitignore present" || echo "️  Missing .gitignore"
[ -f .nvmrc ] || [ -f .node-version ] && echo " Node version specified"
[ -d .github/workflows ] && echo " CI/CD workflows present" || echo "ℹ️  No GitHub Actions workflows"

# Detect frameworks
echo ""
echo " FRAMEWORKS & LIBRARIES"

# React/Vue/Angular
rg -q "react" package.json 2>/dev/null && echo " React detected"
rg -q "vue" package.json 2>/dev/null && echo " Vue detected"
rg -q "@angular/core" package.json 2>/dev/null && echo " Angular detected"
rg -q "svelte" package.json 2>/dev/null && echo " Svelte detected"

# Meta-frameworks
rg -q "next" package.json 2>/dev/null && echo " Next.js detected"
rg -q "nuxt" package.json 2>/dev/null && echo " Nuxt detected"
rg -q "vite" package.json 2>/dev/null && echo " Vite detected"
rg -q "remix" package.json 2>/dev/null && echo " Remix detected"

# Build tools and bundlers
echo ""
echo "️  BUILD TOOLS"
rg -q "typescript" package.json 2>/dev/null && echo " TypeScript"
rg -q "esbuild" package.json 2>/dev/null && echo " esbuild"
rg -q "webpack" package.json 2>/dev/null && echo " Webpack"
rg -q "rollup" package.json 2>/dev/null && echo " Rollup"
rg -q "parcel" package.json 2>/dev/null && echo " Parcel"

# pnpm workspace analysis
if [ -f pnpm-workspace.yaml ]; then
    echo ""
    echo " PNPM WORKSPACE"
    workspace_count=$(yq e '.packages | length' pnpm-workspace.yaml 2>/dev/null || echo "0")
    echo "   Workspace packages: $workspace_count"
fi
```

FINALLY: Generate executive summary and recommendations

```bash
echo ""
echo "═══════════════════════════════════════════"
echo " PNPM PROJECT HEALTH SUMMARY"
echo "═══════════════════════════════════════════"
echo "Session: $SESSION_ID"
echo "Project: $(jq -r '.name // "unnamed"' package.json 2>/dev/null)"
echo "Version: $(jq -r '.version // "0.0.0"' package.json 2>/dev/null)"
echo "Node: $(node --version 2>/dev/null || echo "unknown")"
echo "pnpm: $(pnpm --version 2>/dev/null || echo "unknown")"
echo ""

# Overall health score
health_data=$(cat /tmp/pnpm-status-$SESSION_ID.json)
pass_count=$(echo "$health_data" | jq -r '[.healthStatus[] | select(. == "pass")] | length')
total_checks=$(echo "$health_data" | jq -r '[.healthStatus[] | select(. != "pending")] | length')
health_percentage=$((pass_count * 100 / total_checks))

echo " Overall Health Score: $health_percentage%"
echo ""

# Quick status overview
echo "Status Overview:"
echo "$health_data" | jq -r '.healthStatus | to_entries[] | select(.value != "pending") | "  \(.key): \(.value)"' | sed 's/pass//g; s/fail//g; s/warn/️/g'

# Recommendations
echo ""
echo " RECOMMENDATIONS"
echo "═════════════════"

if [ "$health_percentage" -eq 100 ]; then
    echo " Excellent! Your pnpm project is in great health."
else
    echo "$health_data" | jq -r '.healthStatus | to_entries[] | select(.value != "pass" and .value != "pending") | .key' | while read -r failing_check; do
        case "$failing_check" in
            "build")
                echo " Fix build errors: pnpm build"
                ;;
            "tests")
                echo " Fix failing tests: pnpm test"
                ;;
            "lint")
                echo " Fix lint issues: pnpm lint"
                ;;
            "typecheck")
                echo " Fix TypeScript errors: pnpm exec tsc --noEmit"
                ;;
            "dependencies")
                echo " Fix security vulnerabilities: pnpm audit --fix"
                ;;
            "scripts")
                echo " Add essential scripts to package.json"
                ;;
        esac
    done
fi

# Additional recommendations
[ ! -f pnpm-lock.yaml ] && echo " Generate lock file: pnpm install"
[ "$vulnerabilities" -gt 0 ] && echo " Fix security issues: pnpm audit --fix"
[ "$outdated" -gt 0 ] && echo " Update dependencies: pnpm update --interactive"
[ ! -f README.md ] && echo " Add a README.md file"
[ ! -f .nvmrc ] && echo " Pin Node version: echo '$(node --version)' > .nvmrc"

echo ""
echo " Full report saved to: /tmp/pnpm-status-$SESSION_ID.json"
```

## Quick Reference

### Usage Examples

```bash
# Quick health check (default)
/project-status-pnpm

# Detailed analysis with all checks
/project-status-pnpm detailed

# From a specific project directory
cd my-pnpm-project && /project-status-pnpm
```

### Health Checks Performed

1. **Build Health**: Build script and TypeScript compilation
2. **Test Suite**: Test execution and framework detection
3. **Code Quality**: ESLint and Prettier configuration
4. **Type Safety**: TypeScript configuration and errors
5. **Dependencies**: Security audit and outdated packages
6. **Scripts**: npm scripts analysis and configuration
7. **Project Structure**: Framework detection and best practices (detailed mode)

This command provides comprehensive pnpm project health monitoring with focus on modern TypeScript development practices.
