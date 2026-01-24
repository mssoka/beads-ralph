#!/bin/bash
# Quick verification script for enhanced merge conflict resolution

set -e

echo "Testing enhanced merge conflict resolution..."
echo ""

# 1. Check that new functions exist
echo "✓ Checking function definitions..."
grep -q "^gather_merge_context()" br || { echo "✗ gather_merge_context() not found"; exit 1; }
grep -q "^build_comprehensive_merge_prompt()" br || { echo "✗ build_comprehensive_merge_prompt() not found"; exit 1; }
grep -q "^format_merge_diagnostics()" br || { echo "✗ format_merge_diagnostics() not found"; exit 1; }
grep -q "^resolve_merge_conflict()" br || { echo "✗ resolve_merge_conflict() not found"; exit 1; }
echo "  ✓ All functions defined"
echo ""

# 2. Check that functions are called
echo "✓ Checking function usage..."
grep -q "resolve_merge_conflict.*integration" br || { echo "✗ Integration merge not using new resolution"; exit 1; }
grep -q "resolve_merge_conflict.*final" br || { echo "✗ Final merge not using new resolution"; exit 1; }
echo "  ✓ Functions properly integrated"
echo ""

# 3. Check CLI flags
echo "✓ Checking CLI flags..."
grep -q "\-\-no-merge-ai" br || { echo "✗ --no-merge-ai flag not found"; exit 1; }
grep -q "\-\-merge-timeout" br || { echo "✗ --merge-timeout flag not found"; exit 1; }
echo "  ✓ CLI flags added"
echo ""

# 4. Check default variables
echo "✓ Checking default variables..."
grep -q "^NO_MERGE_AI=false" br || { echo "✗ NO_MERGE_AI default not set"; exit 1; }
grep -q "^MERGE_TIMEOUT=900" br || { echo "✗ MERGE_TIMEOUT default not set"; exit 1; }
echo "  ✓ Defaults configured"
echo ""

# 5. Check help text
echo "✓ Checking help text..."
grep -q "MERGE CONFLICT RESOLUTION" br || { echo "✗ Help section not added"; exit 1; }
echo "  ✓ Help text updated"
echo ""

# 6. Check config file example
echo "✓ Checking config example..."
[[ -f .ralphy/config.yaml.example ]] || { echo "✗ Config example not found"; exit 1; }
grep -q "merge_resolution:" .ralphy/config.yaml.example || { echo "✗ merge_resolution not in example"; exit 1; }
echo "  ✓ Config example created"
echo ""

# 7. Check documentation
echo "✓ Checking documentation..."
grep -q "Merge Conflict Resolution" README.md || { echo "✗ Documentation not added to README"; exit 1; }
echo "  ✓ Documentation updated"
echo ""

# 8. Check bash syntax
echo "✓ Checking bash syntax..."
bash -n br || { echo "✗ Syntax error in br script"; exit 1; }
echo "  ✓ No syntax errors"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ All checks passed!"
echo ""
echo "Implementation complete:"
echo "  • gather_merge_context() - Collects comprehensive context"
echo "  • build_comprehensive_merge_prompt() - Builds AI prompt"
echo "  • format_merge_diagnostics() - Pretty-prints failure info"
echo "  • resolve_merge_conflict() - Main resolution function"
echo ""
echo "Integration points:"
echo "  • Integration merge (line ~2810)"
echo "  • Final merge (line ~3403)"
echo ""
echo "CLI flags:"
echo "  • --no-merge-ai - Disable AI resolution"
echo "  • --merge-timeout N - Set timeout in seconds"
echo ""
echo "Configuration:"
echo "  • See .ralphy/config.yaml.example"
echo "  • See README.md section 'Merge Conflict Resolution'"
echo ""
echo "To test with real conflicts:"
echo "  1. Create parallel tasks that modify same files"
echo "  2. Run: ./br --parallel"
echo "  3. Check logs in: .ralphy/logs/merge-resolution/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
