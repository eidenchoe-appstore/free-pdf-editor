<p align="center">
  <img src="assets/icon.png" width="112" alt="Free PDF Editor app icon">
</p>

<h1 align="center">Free PDF Editor</h1>

<p align="center">
  A native macOS PDF editor for visual text replacement, annotations, and signatures.
</p>

<p align="center">
  <a href="https://github.com/eidenchoe-appstore/free-pdf-editor/raw/main/dist/FreePDFEditor-v0.0.1.dmg"><strong>Download DMG</strong></a>
  ·
  <a href="documents/README.ko.md">한국어 README</a>
  ·
  <a href="https://github.com/eidenchoe-appstore/free-pdf-editor/releases">Releases</a>
</p>

<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/version-0.0.1-black?style=flat-square">
  <a href="LICENSE">
    <img alt="License" src="https://img.shields.io/badge/license-Apache--2.0-blue?style=flat-square">
  </a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey?style=flat-square">
</p>

## Overview

Free PDF Editor is built for the everyday PDF editing workflow: open a PDF, click detected text, visually replace it with a Mac font, highlight passages, add notes or shapes, place reusable signatures, and export a clean final copy. It uses Apple's PDFKit for native PDF rendering and annotation storage instead of shipping a custom PDF engine.

## Features

| Tool | What it does | Behavior |
| --- | --- | --- |
| PDF viewer | Opens and renders local PDF files | Native PDFKit scrolling, thumbnails, page navigation, zoom, and reading modes |
| Text replacement | Edits detected text lines visually | Covers the original area and places replacement text with selected font, size, and color |
| Markup | Adds highlight, underline, and strikeout | Uses PDF annotations that can be saved or flattened |
| Text and comments | Adds free text boxes and note comments | Supports font, color, and size controls from the inspector |
| Shapes and stamps | Adds rectangle, ellipse, line, and text stamp annotations | Supports stroke, fill, and line width settings |
| Signatures | Draws a reusable signature or imports PNG/JPEG/TIFF images | Places signatures on the PDF as movable, resizable image annotations |
| Save and export | Saves editable PDFs or flattened final copies | Normal save preserves annotations; flattened export burns them into the visual PDF |

## Download

Download the current v0.0.1 DMG:

[FreePDFEditor-v0.0.1.dmg](https://github.com/eidenchoe-appstore/free-pdf-editor/raw/main/dist/FreePDFEditor-v0.0.1.dmg)

After opening the DMG, drag **Free PDF Editor** into **Applications**.

> The current build is ad-hoc signed for local distribution. For public distribution, sign with an Apple Developer ID certificate and notarize the DMG.

## Usage

1. Open **Free PDF Editor**.
2. Drag a `.pdf` file into the drop area, or click **Open PDF** to choose a file manually.
3. Select an editing tool from the toolbar:
   - **Replace Text** to click an existing text line and place replacement text.
   - **Highlight**, **Underline**, or **Strikeout** to mark selected text.
   - **Text Box** or **Comment** to add editable notes.
   - **Rectangle**, **Ellipse**, **Line**, or **Stamp** to add simple visual marks.
   - **Signature** to place a saved signature on the PDF.
4. Use the right inspector to change fonts, colors, cover color, line width, stamp text, and signatures.
5. Save with **Command + S**, or use **Export Flattened PDF** when you need a final sharing copy.

## Keyboard Shortcuts

| Shortcut | Action |
| --- | --- |
| `Command + O` | Open PDF |
| `Command + S` | Save |
| `Command + Shift + S` | Save As |
| `Command + Left Arrow` | Previous page |
| `Command + Right Arrow` | Next page |
| `Command + =` | Zoom in |
| `Command + -` | Zoom out |
| `Command + 0` | Actual size |
| `Command + Option + S` | Toggle page thumbnails |
| `Command + Option + I` | Toggle inspector |
| `Command + 1` ... `Command + 9` | Switch between core editing tools |
| `Delete` | Delete selected annotation |

## Editing Behavior

PDF files are final-layout documents, not Word-style editable files. Free PDF Editor uses a practical PDFKit editing layer:

```text
detected text bounds
cover annotation
replacement text annotation
save or flattened export
```

This works well for forms, certificates, invoices, simple contracts, and white-background PDFs. It is not a secure redaction engine. If you need legal or forensic redaction, use a dedicated redaction workflow that removes underlying PDF content.

## Requirements

- macOS 14 or later
- No external PDF engine or command-line converter required

## Development

```bash
swift build
./script/build_and_run.sh --verify
./script/package_dmg.sh
```

The packaged DMG is written to:

```text
dist/FreePDFEditor-v0.0.1.dmg
```

## Release

Current version: `0.0.1`

The app bundle is generated from SwiftPM, includes the app icon from `assets/icon.png`, and is packaged into a verified DMG.

## License

Apache License 2.0. See [LICENSE](LICENSE).
