# CopyURL - YouTube Thumbnail URL Copier

A lightweight Chrome/Brave extension that lets you copy a YouTube video's URL by hovering over its thumbnail and pressing **Alt+C** — no need to open the video.

## Why I Made This

I frequently paste YouTube URLs into Gemini to get video summaries. Opening every video just to grab the URL was tedious and slow. With this extension, I hover over a thumbnail, press a shortcut, and paste the URL straight into Gemini — skipping the video entirely.

## How to Use

1. Browse YouTube as usual (home feed, search results, channel pages, etc.)
2. **Hover** your mouse over any video thumbnail
3. Press **Alt+C**
4. A small "Copied!" toast confirms the URL is in your clipboard
5. Paste the clean URL wherever you need it (e.g., Gemini for a summary)

The copied URL is always in clean format: `https://www.youtube.com/watch?v=VIDEO_ID` — no tracking parameters, no extra clutter.

YouTube Shorts thumbnails are also supported and normalized to the standard `/watch?v=` format.

## Installation

1. Download or clone this repository
2. Open **Brave** (or Chrome): go to `brave://extensions` (or `chrome://extensions`)
3. Enable **Developer mode** (toggle in the top-right corner)
4. Click **Load unpacked** and select the `CopyURL` folder
5. Done — the extension is now active on YouTube

## Files

| File | Description |
|------|-------------|
| `manifest.json` | Extension configuration (Manifest V3) |
| `content.js` | Core logic: hover detection, keyboard shortcut, clipboard copy, toast UI |
| `icon*.png` | Extension icons |
