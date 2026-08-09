# CKS — Commercial Kitchen Services

> *"We keep you cooking!"*

Website for **Commercial Kitchen Services, LLC** — a commercial kitchen equipment repair and maintenance company serving NE South Dakota, founded by Otis Bogue in 2022.

## About

CKS provides maintenance and repair services on cooking, prep, refrigeration, and HVAC equipment for commercial food service facilities across Northeast South Dakota.

- **Phone/Text:** (605) 880-2809
- **Email:** Otis.CKS@gmail.com
- **Service Area:** NE South Dakota (Watertown, SD)
- **Hours:** Mon–Fri, 8:00 AM – 5:00 PM

## Project Structure

```
CKS-Otis/
├── assets/
│   ├── logos/       # CKS logo files
│   ├── page-1/     # Hero / main page images
│   ├── page-2/     # Field work photos (set 1)
│   └── page-3/     # Field work photos (set 2)
├── .gitignore
└── README.md
```

## Development Workflow

This repo lives inside a Google Drive folder. Google Drive sync keeps it backed up automatically.

### Quick Commands

```bash
# Pull latest from GitHub
git pull origin main

# Stage, commit, and push changes
git add -A
git commit -m "your message"
git push origin main
```

### Auto-Sync

Run `sync-to-github.ps1` to automatically watch for file changes in the Google Drive folder and push them to GitHub.

```powershell
.\sync-to-github.ps1
```
