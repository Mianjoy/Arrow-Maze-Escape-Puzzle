# Architecture diagrams

Editable sources for the README Architecture section.

| File | Purpose |
|------|---------|
| [`clean-architecture.mmd`](clean-architecture.mmd) | Clean Architecture **concentric onion** (L4⊃L3⊃L2⊃L1), English labels, DIP dashed arrows, external `arrowmaze-backend` box |
| [`class-diagram.mmd`](class-diagram.mmd) | Main classes, UML relationships, layer colors, GoF patterns |

## Regenerate README embeds

```bash
python scripts/sync-readme-diagrams.py
```

## Export PNG

```bash
npx --yes @mermaid-js/mermaid-cli@11.4.0 -i docs/architecture/clean-architecture.mmd -o docs/architecture/clean-architecture.png -b white -w 6400 -H 5400
npx @mermaid-js/mermaid-cli -i docs/architecture/class-diagram.mmd -o docs/architecture/class-diagram.png -b white -w 2800
```

## Clean Architecture checklist (rubric)

- [x] Four concentric layers (domain at the center)
- [x] Dependency rule: outer → inner only
- [x] Legend with layer names and source folders
- [x] Ports and adapters labeled and linked
- [x] Component → component arrows with English labels
- [x] DIP shown with dashed `implements` arrows
- [x] External backend REST API box
- [x] Domain isolation callout (zero external imports)
- [x] PNG + `.mmd` source in `/docs`
