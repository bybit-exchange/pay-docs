#!/bin/bash

# Sync Lark Documentation and Deploy to GitHub Pages
# Usage: ./scripts/sync-lark-and-deploy.sh <lark_url> [local_docs_path] [github_token]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
LARK_URL=""
LOCAL_DOCS_PATH="./docs/scan-payment"
GITHUB_TOKEN=""
AUTO_COMMIT=true
AUTO_DEPLOY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --url)
      LARK_URL="$2"
      shift 2
      ;;
    --path)
      LOCAL_DOCS_PATH="$2"
      shift 2
      ;;
    --token)
      GITHUB_TOKEN="$2"
      AUTO_DEPLOY=true
      shift 2
      ;;
    --no-commit)
      AUTO_COMMIT=false
      shift
      ;;
    --help)
      echo "Usage: $0 --url <lark_url> [options]"
      echo ""
      echo "Options:"
      echo "  --url <url>        Lark document URL (required)"
      echo "  --path <path>      Local documentation path (default: ./docs/scan-payment)"
      echo "  --token <token>    GitHub token for deployment (enables auto-deploy)"
      echo "  --no-commit        Skip git commit"
      echo "  --help             Show this help message"
      exit 0
      ;;
    *)
      if [ -z "$LARK_URL" ]; then
        LARK_URL="$1"
      fi
      shift
      ;;
  esac
done

# Validate required parameters
if [ -z "$LARK_URL" ]; then
  echo -e "${RED}Error: Lark URL is required${NC}"
  echo "Usage: $0 --url <lark_url> [options]"
  exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${RED}Error: Not in a git repository${NC}"
  exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Sync Lark Documentation and Deploy${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Lark URL: $LARK_URL"
echo "  Local Docs: $LOCAL_DOCS_PATH"
echo "  Auto Commit: $AUTO_COMMIT"
echo "  Auto Deploy: $AUTO_DEPLOY"
echo ""

# Step 1: Save Lark document to temp file
TEMP_FILE=$(mktemp)
echo -e "${YELLOW}[1/6] Fetching Lark document...${NC}"

# Try to use lark-doc-skills if available
if command -v node >/dev/null 2>&1; then
  # Check if lark-doc-skills is installed
  LARK_SCRIPT="$HOME/.claude/plugins/cache/ai-coding-marketplace/lark-doc-skills/*/skills/lark-doc/scripts/fetch-lark-doc.mjs"
  LARK_SCRIPT_PATH=$(ls $LARK_SCRIPT 2>/dev/null | head -1)

  if [ -n "$LARK_SCRIPT_PATH" ]; then
    node "$LARK_SCRIPT_PATH" "$LARK_URL" > "$TEMP_FILE" 2>&1
    if [ $? -ne 0 ]; then
      echo -e "${RED}Failed to fetch Lark document${NC}"
      cat "$TEMP_FILE"
      rm "$TEMP_FILE"
      exit 1
    fi
    echo -e "${GREEN}✓ Lark document fetched successfully${NC}"
  else
    echo -e "${YELLOW}Warning: lark-doc-skills not found, please fetch manually${NC}"
    echo "Please run: claude skill lark-doc $LARK_URL > $TEMP_FILE"
    exit 1
  fi
else
  echo -e "${RED}Error: Node.js not found${NC}"
  exit 1
fi

# Step 2: Compare and show differences
echo ""
echo -e "${YELLOW}[2/6] Comparing with local documentation...${NC}"
echo -e "${BLUE}This step requires manual review. Please review the Lark document at:${NC}"
echo -e "${BLUE}  $TEMP_FILE${NC}"
echo ""
read -p "Press Enter to continue with synchronization..."

# Step 3: Update documentation (this would need to be done by Claude or manually)
echo ""
echo -e "${YELLOW}[3/6] Updating local documentation...${NC}"
echo -e "${YELLOW}Note: This step requires Claude Code or manual update${NC}"
echo -e "${BLUE}Lark document content is available at: $TEMP_FILE${NC}"
echo ""
read -p "Have you updated the documentation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Aborted by user${NC}"
  rm "$TEMP_FILE"
  exit 0
fi

# Step 4: Git commit
if [ "$AUTO_COMMIT" = true ]; then
  echo ""
  echo -e "${YELLOW}[4/6] Committing changes...${NC}"

  # Check if there are changes
  if git diff --quiet && git diff --cached --quiet; then
    echo -e "${YELLOW}No changes to commit${NC}"
  else
    git add "$LOCAL_DOCS_PATH"

    # Generate commit message
    COMMIT_MSG="Sync documentation from Lark

Source: $LARK_URL
Updated: $(date '+%Y-%m-%d %H:%M:%S')

Co-Authored-By: Claude (global.anthropic.claude-sonnet-4-5-20250929-v1:0) <noreply@anthropic.com>"

    git commit -m "$COMMIT_MSG"
    echo -e "${GREEN}✓ Changes committed${NC}"
  fi
else
  echo -e "${YELLOW}[4/6] Skipping commit (--no-commit flag)${NC}"
fi

# Step 5: Push to remote
echo ""
echo -e "${YELLOW}[5/6] Pushing to remote...${NC}"
git push origin master
echo -e "${GREEN}✓ Pushed to remote${NC}"

# Step 6: Deploy to GitHub Pages
if [ "$AUTO_DEPLOY" = true ] && [ -n "$GITHUB_TOKEN" ]; then
  echo ""
  echo -e "${YELLOW}[6/6] Deploying to GitHub Pages...${NC}"

  # Save current remote URL
  ORIGINAL_REMOTE=$(git remote get-url origin)

  # Set remote with token temporarily
  REPO_URL=$(echo "$ORIGINAL_REMOTE" | sed 's|https://github.com/|https://'"$GITHUB_TOKEN"'@github.com/|')
  git remote set-url origin "$REPO_URL"

  # Build and deploy
  npm run build
  npm run deploy

  # Restore original remote
  git remote set-url origin "$ORIGINAL_REMOTE"

  echo -e "${GREEN}✓ Deployed to GitHub Pages${NC}"
else
  echo ""
  echo -e "${YELLOW}[6/6] Skipping deployment (no token provided)${NC}"
  echo -e "${BLUE}To deploy manually, run:${NC}"
  echo "  npm run build"
  echo "  npm run deploy"
fi

# Cleanup
rm "$TEMP_FILE"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Synchronization Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
