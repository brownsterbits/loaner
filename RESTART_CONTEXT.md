# Restart Context - GitHub Pages Deployment

**Date:** November 14, 2025
**Status:** Awaiting Claude Code restart to load new MCP configuration

## Current State

### ✅ Completed
- GitHub Pages website files created in `/docs` folder
- All files updated with `bits@brownster.com` email
- Dual GitHub MCP configuration added to `.mcp.json`
- GitHub token for brownsterbits added (line 35 of .mcp.json)

### ⏳ Next Steps (After Restart)
1. User will say "ready"
2. Create `brownsterbits.github.io` repository using `mcp__github-personal__create_repository`
3. Push files from `/docs` to `brownsterbits.github.io/loaner/` using GitHub MCP
4. Verify site is live at `https://brownsterbits.github.io/loaner/`

## Key Information

### GitHub Setup
- **Account:** brownsterbits (https://github.com/brownsterbits)
- **Email:** bits@brownster.com
- **Token:** Configured in `.mcp.json` line 35
- **Scopes:** `repo` + `workflow`

### Files Ready to Deploy
```
/Users/chadbrown/projects/loaner/docs/
├── index.html       # Landing page
├── privacy.html     # Privacy policy (App Store required)
├── support.html     # Support & FAQ
└── README.md        # Deployment instructions
```

### Target URLs
- **Privacy:** https://brownsterbits.github.io/loaner/privacy.html
- **Support:** https://brownsterbits.github.io/loaner/support.html
- **Landing:** https://brownsterbits.github.io/loaner/

## MCP Configuration

### Two GitHub Servers Configured

**1. github** (XOGOio organization - company work)
- For: /github-pulse, /customer-insights, agent system
- Token: company token

**2. github-personal** (brownsterbits - personal projects)
- For: Loaner, other personal apps
- Token: [REDACTED - stored in .mcp.json]

Tools will be prefixed: `mcp__github-personal__*`

## Action Required

**User must:**
1. Close Claude Code completely
2. Reopen Claude Code (loads new MCP config)
3. Say "ready" to trigger repository creation

**I will then:**
1. Use `mcp__github-personal__create_repository` to create brownsterbits.github.io
2. Use `mcp__github-personal__push_files` to upload all docs files to loaner/ folder
3. Verify deployment and provide URLs

## Resume Command

When user says "ready", I should:
```
1. Create repo: brownsterbits.github.io (public, with README)
2. Push files to loaner/ subdirectory
3. Wait 1-2 minutes for GitHub Pages to deploy
4. Provide final URLs for App Store Connect
```

## Context Files Updated
- ✅ SESSION_SUMMARY.md - Added GitHub Pages section
- ✅ MVP_SHIPPING_PLAN.md - Marked Step 11 complete
- ✅ docs/README.md - Updated with brownsterbits URLs
- ✅ docs/*.html - All use bits@brownster.com
- ✅ .mcp.json - Dual GitHub configuration
- ✅ RESTART_CONTEXT.md - This file

## Notes
- All website files use responsive design
- Privacy policy is ~1,800 words (comprehensive)
- Support page has ~2,000 words (detailed FAQ)
- No JavaScript or tracking - pure HTML/CSS
- Pages optimized for App Store compliance
