# Loaner Website - GitHub Pages Setup

This folder contains the public-facing website for Loaner, designed to be hosted on **GitHub Pages** for free.

## Files

- `index.html` - Landing page with app overview
- `privacy.html` - Privacy policy (required for App Store)
- `support.html` - Support documentation and FAQ
- `README.md` - This file

## Setup Instructions

### Option 1: Host Under Your Main GitHub Account (Recommended)

1. Create a new repository named `brownsterbits.github.io` (if you don't have it already)
2. Create a folder named `loaner` in the repo
3. Copy all files from this `docs/` folder into `loaner/`
4. Commit and push to GitHub
5. Your site will be available at: `https://brownsterbits.github.io/loaner/`

**Directory structure:**
```
brownsterbits.github.io/
├── index.html (optional - your main page)
├── loaner/
│   ├── index.html
│   ├── privacy.html
│   └── support.html
├── otherapp/
│   ├── index.html
│   ├── privacy.html
│   └── support.html
└── ...
```

### Option 2: Separate Repository per App

1. Create a new repository named `loaner` in your GitHub account
2. Copy all files from this `docs/` folder to the repo root
3. Enable GitHub Pages:
   - Go to Settings → Pages
   - Source: Deploy from a branch
   - Branch: main (or master)
   - Folder: / (root)
4. Your site will be available at: `https://brownsterbits.github.io/loaner/`

### Option 3: Custom Domain (Optional)

If you want `loaner.brownster.com` instead:

1. Follow Option 1 or 2 above
2. Add a CNAME file with content: `loaner.brownster.com`
3. Configure DNS at your domain registrar:
   - Type: CNAME
   - Name: loaner
   - Value: brownsterbits.github.io
4. Enable custom domain in GitHub Pages settings

**Cost:** Custom domains require purchasing brownster.com (~$12/year)

## App Store Connect Configuration

When setting up your app in App Store Connect, use these URLs:

| Field | URL |
|-------|-----|
| Privacy Policy URL | `https://brownsterbits.github.io/loaner/privacy.html` |
| Support URL | `https://brownsterbits.github.io/loaner/support.html` |
| Marketing URL (optional) | `https://brownsterbits.github.io/loaner/` |

## Email Configuration

Set up `bits@brownster.com` as your support contact email. This goes in:

1. App Store Connect → App Information → Support Email
2. The support and privacy pages (already configured)

## Multiple Apps Strategy

**Recommended approach:** Use Option 1 (single brownsterbits.github.io repo) with folders per app:

```
https://brownsterbits.github.io/loaner/
https://brownsterbits.github.io/otherapp/
https://brownsterbits.github.io/yetanotherapp/
```

**Benefits:**
- Single repo to manage
- Free hosting forever
- No per-app domains needed
- Simple URL structure
- One support email for all apps

**Total cost:** $99/year for Apple Developer account (required)

## Updating Content

To update any page:

1. Edit the HTML file
2. Commit and push to GitHub
3. Changes appear within 1-2 minutes

No build step required - these are static HTML files.

## Testing Locally

Open any HTML file directly in your browser to test:

```bash
cd docs
open index.html
```

Or use Python's built-in server:

```bash
cd docs
python3 -m http.server 8000
# Visit http://localhost:8000
```

## Next Steps

1. ✅ Files created
2. ✅ GitHub account configured (brownsterbits)
3. ⏳ Create `brownsterbits.github.io` repository
4. ⏳ Push these files to GitHub
5. ⏳ Verify pages load at your GitHub Pages URL
6. ⏳ Configure App Store Connect with URLs
7. ⏳ Submit app for review

## Notes

- All pages use responsive design (mobile-friendly)
- Simple, clean styling matches iOS design language
- No JavaScript or tracking - pure static HTML/CSS
- Pages load instantly (no external dependencies)
- Works on all modern browsers
- Accessibility-friendly markup

## Customization

To customize for your other apps:

1. Copy the `loaner/` folder
2. Rename it (e.g., `myotherapp/`)
3. Search and replace "Loaner" with your app name
4. Update feature descriptions
5. Push to GitHub

The HTML is self-contained and easy to modify without any build tools.
