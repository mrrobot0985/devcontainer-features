# Pandoc Document Converter

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Pandoc universal document converter with optional LaTeX support for PDF generation.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Pandoc version to install (e.g., 3.1.11, latest) |
| `installLatex` | boolean | `false` | Install TeX Live for PDF generation support |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/pandoc-convert:1": {
        "version": "latest",
        "installLatex": true
    }
}
```

## CLI

```bash
# Convert markdown to PDF
pandoc input.md -o output.pdf

# Convert with custom template
pandoc input.md -o output.pdf --template=eisvogel

# Check feature status
devcontainer-pandoc status

# Markdown to PDF shortcut
devcontainer-pandoc md2pdf input.md output.pdf
```

## Requirements

- curl for downloading releases
- Optional: TeX Live for PDF output

## Notes

- Pandoc supports Markdown, HTML, LaTeX, DOCX, EPUB, and many other formats
- TeX Live is large; enable `installLatex` only when PDF output is needed
