# Architecture diagrams

Editable Mermaid sources for the README:

| File | Purpose |
|------|---------|
| [`clean-architecture.mmd`](clean-architecture.mmd) | Four-layer Clean Architecture (dependency rule) |
| [`class-diagram.mmd`](class-diagram.mmd) | Main classes, UML relations, layer colors, GoF patterns |

## Regenerate README embeds

From the repository root:

```bash
python scripts/sync-readme-diagrams.py
```

## Optional static PNG export (for deliverables)

```bash
npx @mermaid-js/mermaid-cli -i docs/architecture/clean-architecture.mmd -o docs/architecture/clean-architecture.png -b transparent
npx @mermaid-js/mermaid-cli -i docs/architecture/class-diagram.mmd -o docs/architecture/class-diagram.png -b transparent
```
