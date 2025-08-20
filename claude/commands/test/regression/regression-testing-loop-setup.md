---
allowed-tools: Read, Write, MultiEdit, Bash(npm test:*), Bash(deno test:*), Bash(cargo test:*), Bash(go test:*), Bash(pytest:*), Bash(jest:*), Bash(vitest:*), Bash(mocha:*), Task
description: Set up regression testing loop with automated hooks for continuous test validation
arguments: "[--auto-fix] [--strict] [--framework <name>] [--test-command <cmd>]"
---

## Command Arguments

- `--auto-fix`: Automatically attempt to fix failing tests (default: interactive)
- `--strict`: Fail immediately on any test failure, no recovery attempts
- `--framework <name>`: Specify test framework (jest, vitest, mocha, deno, pytest, etc.)
- `--test-command <cmd>`: Override auto-detected test command

Examples:
- `/regression-testing-loop-setup` - Interactive setup with prompts
- `/regression-testing-loop-setup --auto-fix` - Auto-fix mode for CI/CD
- `/regression-testing-loop-setup --framework vitest --test-command "npm run test:unit"`
- `/regression-testing-loop-setup --strict` - No tolerance for failures

## Context

- Current directory: !`pwd`
- Project type detection: !`ls -la | head -20`
- Existing test files: !`find . -type f \( -name "*test*" -o -name "*spec*" \) -not -path "*/node_modules/*" -not -path "*/.git/*" | head -20`
- Package manager: !`if [ -f "package.json" ]; then echo "npm/yarn"; elif [ -f "deno.json" ]; then echo "deno"; elif [ -f "Cargo.toml" ]; then echo "cargo"; elif [ -f "go.mod" ]; then echo "go"; elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then echo "python"; else echo "unknown"; fi`
- Git hooks directory: !`if [ -d ".git/hooks" ]; then echo "Git hooks available"; else echo "Not a git repository"; fi`
- Command arguments: $ARGUMENTS

## Your Task

Set up a comprehensive regression testing loop for this project that enforces test-driven quality assurance throughout development cycles.

### Phase 1: Analysis and Setup

1. **Parse Command Arguments**
   - Check if $ARGUMENTS contains configuration flags
   - Extract --framework, --test-command, --auto-fix, --strict options
   - Use provided values to override auto-detection where specified

2. **Detect Testing Framework**
   - If --framework provided, use that framework
   - Otherwise auto-detect: Jest, Vitest, Mocha, Deno test, pytest, cargo test, go test, etc.
   - If --test-command provided, use that command
   - Otherwise determine the test command from package.json or project config

3. **Create Regression Testing Configuration**
   - Create `.claude/regression-testing.json` with:
     ```json
     {
       "testCommand": "<detected or provided test command>",
       "testPattern": "<glob pattern for test files>",
       "mode": "<auto-fix|strict|interactive>",
       "framework": "<detected or provided framework>",
       "hooks": {
         "postImplementation": true,
         "preCommit": false
       },
       "baselineTests": [],
       "regressionHistory": []
     }
     ```

4. **Establish Baseline**
   - Run the existing test suite to capture the current passing state
   - Document all passing tests as the regression baseline
   - Store results in `.claude/regression-baseline.json`
   - If no tests exist, prompt user to:
     a) Create comprehensive test suite based on implementation
     b) Create minimal smoke tests
     c) Skip and handle manually later

### Phase 2: Hook Configuration

5. **Create Claude Code Hook**
   - Create or update `.claude/settings.local.json` to add a post-implementation hook:
     ```json
     {
       "hooks": {
         "post-edit": {
           "command": "bash -c 'echo \"🧪 Running regression tests...\" && <test_command> 2>&1 | tee .claude/last-test-run.log'",
           "description": "Run regression tests after code modifications"
         }
       }
     }
     ```

6. **Create Test Runner Script**
   - Create `.claude/scripts/regression-test-runner.sh`:
     ```bash
     #!/bin/bash
     # Regression Testing Loop Runner
     
     # Parse command line arguments
     AUTO_FIX=false
     STRICT_MODE=false
     while [[ $# -gt 0 ]]; do
         case $1 in
             --auto-fix) AUTO_FIX=true; shift ;;
             --strict) STRICT_MODE=true; shift ;;
             *) shift ;;
         esac
     done
     
     echo "🔄 Starting Regression Testing Loop"
     echo "=================================="
     
     # Run existing tests first
     echo "📋 Phase 1: Running existing test suite..."
     <test_command>
     EXISTING_RESULT=$?
     
     if [ $EXISTING_RESULT -ne 0 ]; then
         echo ""
         echo "❌ Regression detected! Existing tests are failing after your changes."
         echo ""
         # Parse and display failed tests
         echo "Failed tests:"
         <test_command> --verbose 2>&1 | grep -E "(FAIL|✗|ERROR)" | head -20
         echo ""
         
         if [ "$STRICT_MODE" = true ]; then
             echo "⚠️  STRICT MODE: Failing immediately"
             exit 1
         fi
         
         if [ "$AUTO_FIX" = true ]; then
             echo "🔧 AUTO-FIX MODE: Attempting to fix implementation..."
             # Auto-fix logic would go here
             echo "Please review the changes and re-run tests"
         else
             # Interactive mode - ask user what to do
             echo "What would you like to do?"
             echo ""
             echo "  [1] 🔧 Attempt to fix the implementation to pass existing tests"
             echo "  [2] 🔍 Analyze why tests are failing (show detailed diff)"
             echo "  [3] ✏️  Update the tests to match new behavior (if intentional)"
             echo "  [4] 🔙 Revert recent changes and start over"
             echo "  [5] 📋 Save failure report and continue manually"
             echo "  [6] ❌ Exit and handle manually"
             echo ""
             read -p "Select an option (1-6): " choice
             
             case $choice in
                 1)
                     echo "🔧 Let me analyze and suggest fixes..."
                     # Trigger fix analysis
                     ;;
                 2)
                     echo "🔍 Analyzing test failures..."
                     <test_command> --verbose 2>&1 | tee .claude/test-failure-analysis.log
                     echo "Full analysis saved to .claude/test-failure-analysis.log"
                     ;;
                 3)
                     echo "✏️  Updating tests to match new behavior..."
                     echo "⚠️  WARNING: Only do this if the behavior change is intentional!"
                     read -p "Are you sure the new behavior is correct? (y/n): " confirm
                     if [ "$confirm" = "y" ]; then
                         echo "Updating baseline tests..."
                     else
                         echo "Cancelled. Please fix the implementation instead."
                     fi
                     ;;
                 4)
                     echo "🔙 Reverting recent changes..."
                     git diff > .claude/changes-backup.patch
                     echo "Changes backed up to .claude/changes-backup.patch"
                     read -p "Revert all changes since last commit? (y/n): " revert
                     if [ "$revert" = "y" ]; then
                         git checkout -- .
                         echo "Changes reverted"
                     fi
                     ;;
                 5)
                     echo "📋 Saving failure report..."
                     <test_command> --verbose 2>&1 > .claude/regression-report-$(date +%s).log
                     echo "Report saved. You can continue manually."
                     ;;
                 6)
                     echo "Exiting. Please fix the tests manually."
                     exit 1
                     ;;
                 *)
                     echo "Invalid option. Exiting."
                     exit 1
                     ;;
             esac
         fi
         
         # After handling, check if we should retry
         if [ "$choice" != "6" ] && [ "$choice" != "5" ]; then
             echo ""
             read -p "Retry tests? (y/n): " retry
             if [ "$retry" = "y" ]; then
                 exec $0 $@  # Re-run script with same arguments
             fi
         fi
         
         exit 1
     fi
     
     echo "✅ All existing tests passing!"
     echo ""
     echo "📝 Phase 2: You may now add tests for new features"
     echo "After adding new tests, run this script again for final verification"
     ```

7. **Create Regression Report Generator**
   - Create `.claude/scripts/regression-report.sh`:
     ```bash
     #!/bin/bash
     # Generate regression testing report
     
     echo "📊 Regression Testing Report"
     echo "============================"
     echo ""
     
     # Compare current results with baseline
     <test_command> --json > .claude/current-test-results.json 2>/dev/null || \
     <test_command> > .claude/current-test-results.txt 2>&1
     
     echo "🔍 Test Suite Status:"
     echo "-------------------"
     
     # Display test counts and any regressions
     if [ -f ".claude/regression-baseline.json" ]; then
         echo "Baseline comparison available"
         # Add comparison logic based on test framework
     else
         echo "No baseline established yet"
     fi
     
     # Show recent test history
     if [ -f ".claude/last-test-run.log" ]; then
         echo ""
         echo "📝 Last Test Run Summary:"
         tail -20 .claude/last-test-run.log | grep -E "(pass|fail|error|✓|✗)"
     fi
     ```

### Phase 3: Workflow Documentation

8. **Create Workflow Guide**
   - Create `REGRESSION_TESTING.md` in project root:
     ```markdown
     # Regression Testing Loop Workflow
     
     This project follows a strict regression testing loop to ensure code quality.
     
     ## The Development Cycle
     
     ### Phase 1: Initial Implementation
     1. Implement core functionality
     2. Create comprehensive test suite (this becomes the regression baseline)
     
     ### Subsequent Phases: Feature Development
     
     For EVERY new feature:
     
     1. **Implement New Feature**
        - Modify code as needed
        - This may temporarily break existing tests
     
     2. **Run & Fix Existing Tests** ⚠️ CRITICAL
        - Run: `.claude/scripts/regression-test-runner.sh`
        - If ANY existing tests fail:
          - DO NOT add new tests yet
          - Fix the implementation until ALL existing tests pass
          - The script will block progression until fixed
     
     3. **Add New Tests**
        - Only after existing tests pass
        - Create tests for the new feature
        - Add them to the test suite
     
     4. **Final Verification**
        - Run the complete test suite
        - Ensure both old and new tests pass
     
     ## Automated Hooks
     
     Tests run automatically after code modifications via Claude Code hooks.
     
     Failed tests will display:
     - Which tests broke
     - Error messages
     - Suggestions for fixes
     
     ## Commands
     
     - Run regression loop: `.claude/scripts/regression-test-runner.sh`
     - Generate report: `.claude/scripts/regression-report.sh`
     - View last run: `cat .claude/last-test-run.log`
     ```

### Phase 4: Implementation

9. **Execute Setup**
   - Create all configuration files and scripts
   - Make scripts executable
   - Run initial test suite to establish baseline
   - Configure hooks for automatic testing

10. **Provide User Feedback**
   - Display setup summary
   - Show detected test framework and command
   - List number of baseline tests
   - Explain the workflow and how to use it
   - Highlight failed tests if any broke during setup

### Output Format

After setup, provide:

```
✅ Regression Testing Loop Configured
=====================================

Project: <project_name>
Test Framework: <detected_framework>
Test Command: <test_command>
Baseline Tests: <count> tests passing
Mode: <interactive|auto-fix|strict>

Hooks Configured:
- Post-implementation: Enabled ✓
- Tests will run automatically after code changes

Workflow:
1. Modify code for new features
2. Existing tests run automatically
3. If tests fail, choose action:
   - Fix implementation (recommended)
   - Analyze failures
   - Update tests (if change intentional)
   - Revert changes
4. Add new tests for new features
5. Run final verification

Commands:
- Run tests: .claude/scripts/regression-test-runner.sh [--auto-fix] [--strict]
- View report: .claude/scripts/regression-report.sh
- Check status: cat .claude/last-test-run.log

Interactive Options:
When tests fail, you'll be prompted to:
  [1] Fix implementation
  [2] Analyze failures
  [3] Update tests (if intentional)
  [4] Revert changes
  [5] Save report and continue
  [6] Exit

⚠️ Remember: ALWAYS fix existing tests before adding new ones!
```

### Error Handling

IF no tests are found:
- Prompt user to create initial tests first
- Provide template test file based on detected framework
- Explain importance of baseline tests

IF multiple test frameworks detected:
- Ask user to specify primary framework
- Configure for selected framework
- Note other frameworks in documentation

IF hooks cannot be configured:
- Provide manual workflow instructions
- Create git pre-commit hook as alternative
- Document manual testing requirements

### Interactive Decision Flow Example

When implementing a new feature that breaks existing tests:

```
❌ Regression detected! Existing tests are failing after your changes.

Failed tests:
✗ CartItem > displays product information correctly
✗ CartItem > removes item when quantity is 0

What would you like to do?

  [1] 🔧 Attempt to fix the implementation to pass existing tests
  [2] 🔍 Analyze why tests are failing (show detailed diff)
  [3] ✏️  Update the tests to match new behavior (if intentional)
  [4] 🔙 Revert recent changes and start over
  [5] 📋 Save failure report and continue manually
  [6] ❌ Exit and handle manually

Select an option (1-6): 1

🔧 Let me analyze and suggest fixes...
The tests are failing because:
- The DOM structure changed when adding the wishlist button
- The remove behavior now calls moveToWishlist instead of removeFromCart

Suggested fixes:
1. Keep original removeFromCart for quantity=0
2. Add separate wishlist button with new handler
3. Maintain backward compatibility

Applying fixes...
✅ Tests now passing! You may proceed with adding new feature tests.
```

### Usage Examples

```bash
# Interactive setup (default)
/regression-testing-loop-setup

# Auto-fix mode for CI/CD pipelines
/regression-testing-loop-setup --auto-fix

# Strict mode for production branches
/regression-testing-loop-setup --strict

# Override framework detection
/regression-testing-loop-setup --framework vitest --test-command "npm run test:unit"

# Combine options
/regression-testing-loop-setup --framework jest --auto-fix
```