---
name: sync-lark-and-deploy
description: Sync documentation from Lark wiki and deploy to GitHub Pages
version: 1.0.0
allowed-tools:
  - bash
  - read
  - write
  - edit
  - glob
  - grep
  - task
---

# Sync Lark Documentation and Deploy

Automatically synchronize documentation from Lark wiki, update local files, and deploy to GitHub Pages.

## When to Use

**Trigger Keywords** (Claude Code should activate this skill when user mentions):
- **同步** Lark 文档并 **部署**
- **Sync** Lark documentation and **deploy**
- **更新**文档到远程 / **Update** docs to remote
- **发布**文档 / **Publish** documentation
- From Lark to GitHub Pages

This skill activates when the user:
- Wants to sync documentation from Lark wiki to local repository
- Needs to deploy updated documentation to GitHub Pages
- Requests automatic documentation update workflow
- Mentions both Lark URL and deployment in the same request

## Core Workflow

### Full Automated Flow (Recommended)

When user provides:
- Lark document URL (starting with `https://uponly.larksuite.com/wiki/`)
- Request to sync and deploy
- Optional: GitHub token for deployment

Execute the following steps:

#### Step 1: Fetch Lark Document
```bash
# Use lark-doc skill to fetch the document
node ~/.claude/plugins/cache/ai-coding-marketplace/lark-doc-skills/*/skills/lark-doc/scripts/fetch-lark-doc.mjs "<lark_url>"
```

Save the output to a temporary file for comparison.

#### Step 2: Deep Comparison
Use Task tool with `subagent_type=Explore` to compare:
- Lark document content vs local documentation
- Identify all differences (version history, API changes, field names, examples, etc.)
- Create a comprehensive list of changes needed

**Important**:
- Compare data models and examples for consistency
- Verify field naming conventions (camelCase vs snake_case)
- Check timestamp formats (number vs string)
- Note any contradictions in the source document

#### Step 3: Update Local Documentation
Create tasks for each identified difference:
```javascript
// Example tasks:
1. Update version history in introduction.mdx
2. Add missing API headers in guide.mdx
3. Update field names in API documentation
4. Add/update webhook parameters
5. Update flowcharts (ASCII to Mermaid)
6. Mark deprecated APIs
7. Verify data models
8. Update error codes
```

Execute each task systematically:
- Read existing files
- Make precise edits using Edit tool
- Preserve correct content (don't blindly copy errors from source)
- Verify consistency across related files

#### Step 4: Git Commit
```bash
git add docs/
git commit -m "$(cat <<'EOF'
Sync documentation from Lark

Source: <lark_url>
Changes:
- [List major changes]
- [List major changes]

Co-Authored-By: Claude (global.anthropic.claude-sonnet-4-5-20250929-v1:0) <noreply@anthropic.com>
EOF
)"
```

#### Step 5: Push to Remote
```bash
git push origin master
```

#### Step 6: Deploy to GitHub Pages (if token provided)
```bash
# Temporarily update remote URL with token
ORIGINAL_REMOTE=$(git remote get-url origin)
git remote set-url origin "https://${GITHUB_TOKEN}@github.com/<org>/<repo>.git"

# Build and deploy
npm run build
npm run deploy

# Restore original remote
git remote set-url origin "$ORIGINAL_REMOTE"
```

### Quality Assurance

**Before finalizing updates:**
1. **Cross-reference**: Compare API documentation with data models
2. **Consistency check**: Verify naming conventions across all files
3. **Format validation**: Ensure timestamp types, currency formats are consistent
4. **Source validation**: If source document contains contradictions, prefer local correctness
5. **User confirmation**: Report any ambiguities to user before proceeding

### Script Usage (Alternative)

For manual or semi-automated workflow:

```bash
# Basic usage (no auto-deploy)
./scripts/sync-lark-and-deploy.sh --url "<lark_url>"

# With auto-deploy
./scripts/sync-lark-and-deploy.sh --url "<lark_url>" --token "<github_token>"

# Custom documentation path
./scripts/sync-lark-and-deploy.sh --url "<lark_url>" --path "./docs/custom-path"

# Skip git commit
./scripts/sync-lark-and-deploy.sh --url "<lark_url>" --no-commit
```

## Configuration

### Prerequisites
- Node.js installed
- lark-doc-skills plugin installed
- Git repository with proper remote setup
- npm packages installed (`npm ci`)
- GitHub Pages configured (for deployment)

### Environment
- **Repository**: Should be a Docusaurus project
- **Build command**: `npm run build`
- **Deploy command**: `npm run deploy` (configured for GitHub Pages)
- **Main branch**: `master` or `main`

## Examples

### Example 1: Quick Sync and Deploy
**User**: "同步 https://uponly.larksuite.com/wiki/StZZwcTsniQD2OkIZ0vu59dHsxd 并部署到远程"

**Claude Code Actions**:
1. Fetch Lark document using lark-doc skill
2. Compare with local docs at `./docs/scan-payment`
3. Update all identified differences
4. Commit with message: "Sync documentation from Lark"
5. Push to GitHub
6. Ask for GitHub token if deployment needed
7. Build and deploy to GitHub Pages

### Example 2: Sync Without Deploy
**User**: "更新文档从 Lark: https://uponly.larksuite.com/wiki/xxx"

**Claude Code Actions**:
1. Fetch Lark document
2. Compare and update local files
3. Commit changes
4. Push to remote
5. Skip deployment (no token provided)

### Example 3: Deploy After Manual Changes
**User**: "直接帮我 deploy"

**Claude Code Actions**:
1. Ask for GitHub token
2. Build project: `npm run build`
3. Deploy to GitHub Pages: `npm run deploy`
4. Restore git remote URL
5. Confirm deployment URL

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| Lark auth failed | Token expired | Re-authenticate using lark-doc skill |
| Build failed | npm dependencies | Run `npm ci` to reinstall |
| Deploy failed | Invalid token | Check GitHub token permissions (repo, pages) |
| Git push failed | No remote access | Verify git remote URL and credentials |
| Merge conflict | Concurrent changes | Resolve conflicts manually |

## Best Practices

1. **Always compare before updating**: Don't blindly copy content
2. **Preserve local corrections**: If local docs are more accurate, keep them
3. **Verify data consistency**: Check that examples match data model definitions
4. **Test build locally**: Run `npm run build` before deploying
5. **Review git diff**: Check changes before committing
6. **Secure tokens**: Never commit tokens, remove from git remote after use

## Related Skills

- `lark-doc`: Fetch Lark documents with authentication
- Task tool with `Explore` agent: Deep codebase comparison
- Git commit workflow: Proper commit message formatting

## References

### Files Modified in Typical Sync
```
docs/scan-payment/
├── introduction.mdx        # Version history, overview
├── guide.mdx              # Authentication, API basics
├── flow.mdx               # Flowcharts, state machines
├── payment-notify.mdx     # Webhook documentation
├── create-payment.mdx     # Payment creation API
├── payment-result.mdx     # Query payment API
├── refund.mdx             # Refund API
├── payout.mdx             # Payout API
└── settlement.mdx         # Settlement API
```

### GitHub Pages Deployment
- **Branch**: `gh-pages`
- **Directory**: `/` (root)
- **Build output**: `./build`
- **Typical URL**: `https://<org>.github.io/<repo>/`

### Workflow Files
- `.github/workflows/deploy.yml`: GitHub Actions auto-deployment
- `scripts/sync-lark-and-deploy.sh`: Manual sync script
- `package.json`: Build and deploy scripts
- `docusaurus.config.js`: Site configuration

## Troubleshooting

### Issue: Local docs are more accurate than Lark
**Solution**: Prefer local correctness. Inform user about discrepancies.

Example from previous sync:
- Lark had `refund_amount` (snake_case) in examples
- Data model showed `refundAmount` (camelCase)
- Local docs correctly used `refundAmount` throughout
- Decision: Keep local docs, report issue to user

### Issue: Large documentation set
**Solution**: Use Task tool to parallelize updates
- Create separate tasks for each file
- Update tasks as you progress
- Mark completed when done

### Issue: Deployment fails with 403
**Solution**: Check GitHub token permissions
- Required scopes: `repo`, `workflow`, `pages`
- Generate new token from GitHub settings if needed

## Version History

| Version | Date | Changes |
|:--------|:-----|:--------|
| 1.0.0 | 2026-01-28 | Initial release with full automation support |

---

## Quick Reference Card

**User says**: "同步 Lark 并部署"

**You should**:
1. ✅ Fetch Lark document (lark-doc skill)
2. ✅ Deep compare with local (Task/Explore agent)
3. ✅ Update all differences systematically
4. ✅ Commit with descriptive message
5. ✅ Push to remote
6. ✅ Deploy to GitHub Pages (if token provided)
7. ✅ Confirm deployment URL

**Key principle**: Compare carefully, preserve correctness, automate fearlessly.
