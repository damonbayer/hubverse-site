#!/bin/bash
# Test that markdown links in hub card descriptions render as HTML <a> tags
# This test runs AFTER quarto render and checks the output HTML

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_DIR="${SCRIPT_DIR}/../_site"
HUBS_HTML="${SITE_DIR}/community/hubs.html"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}PASS${NC}: $1"
}

fail() {
    echo -e "${RED}FAIL${NC}: $1"
    exit 1
}

# Check if site has been built
if [ ! -f "$HUBS_HTML" ]; then
    echo "ERROR: $HUBS_HTML not found. Run 'quarto render' first."
    exit 1
fi

echo "Testing hub card link rendering in ${HUBS_HTML}"
echo "=============================================="

# Test 1: Check that the hubverse archival hub description contains a working link
# The description should have: [FluSight](https://github.com/cdcepi/FluSight-forecasts)
# which should render as: <a href="https://github.com/cdcepi/FluSight-forecasts">FluSight</a>
if grep -q 'href="https://github.com/cdcepi/FluSight-forecasts"' "$HUBS_HTML"; then
    pass "FluSight link renders as HTML anchor tag"
else
    # Check if the raw markdown is present (which would indicate the bug)
    if grep -q '\[FluSight\](https://github.com/cdcepi/FluSight-forecasts)' "$HUBS_HTML"; then
        fail "FluSight link appears as raw markdown instead of HTML"
    else
        echo "SKIP: FluSight link test - link not found in current data"
    fi
fi

# Test 2: Verify no raw markdown link syntax appears in card descriptions
# Look for patterns like [text](http that would indicate unrendered markdown
RAW_MARKDOWN_LINKS=$(grep -oP '\[[^\]]+\]\(https?://[^)]+\)' "$HUBS_HTML" 2>/dev/null || true)
if [ -n "$RAW_MARKDOWN_LINKS" ]; then
    echo "Found raw markdown links that should have been converted to HTML:"
    echo "$RAW_MARKDOWN_LINKS"
    fail "Raw markdown links found in rendered HTML"
else
    pass "No raw markdown link syntax found in rendered HTML"
fi

# Test 3: Check that legitimate HTML anchor tags exist in hub descriptions
# (This confirms the page rendered at all)
ANCHOR_COUNT=$(grep -c '<a[^>]*href=' "$HUBS_HTML" || echo "0")
if [ "$ANCHOR_COUNT" -gt 10 ]; then
    pass "Found $ANCHOR_COUNT anchor tags in rendered HTML"
else
    fail "Expected more than 10 anchor tags, found $ANCHOR_COUNT"
fi

# Test 4: If the test fixture was rendered, check it specifically
TEST_FIXTURE_HTML="${SITE_DIR}/tests/fixtures/test-hub-links.html"
if [ -f "$TEST_FIXTURE_HTML" ]; then
    echo ""
    echo "Testing isolated test fixture..."

    # Check for the test link
    if grep -q 'href="https://example.com"' "$TEST_FIXTURE_HTML"; then
        pass "Test fixture: Example Site link renders correctly"
    else
        if grep -q '\[Example Site\](https://example.com)' "$TEST_FIXTURE_HTML"; then
            fail "Test fixture: Example Site link appears as raw markdown"
        else
            fail "Test fixture: Example Site link not found at all"
        fi
    fi

    if grep -q 'href="https://test.example.com/path"' "$TEST_FIXTURE_HTML"; then
        pass "Test fixture: Hub description link renders correctly"
    else
        if grep -q '\[markdown link\](https://test.example.com/path)' "$TEST_FIXTURE_HTML"; then
            fail "Test fixture: Hub description link appears as raw markdown"
        else
            fail "Test fixture: Hub description link not found at all"
        fi
    fi
fi

echo ""
echo "All hub card link tests passed!"
