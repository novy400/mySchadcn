# Domain Docs

This repository uses a single domain context.

## Before exploring, read these

- `CONTEXT.md` at the repository root
- Relevant architectural decisions under `docs/adr/`

If these files do not exist, proceed silently. The domain-modeling workflows create them lazily when terminology or architectural decisions are resolved.

## File structure

```text
/
├── CONTEXT.md
├── docs/adr/
└── src/
```

## Use the glossary's vocabulary

When naming a domain concept in an issue, proposal, hypothesis or test, use the term defined in `CONTEXT.md`. Avoid synonyms that the glossary explicitly rejects.

If a needed concept is absent, reconsider whether it belongs to the project or record the gap for domain modeling.

## Flag ADR conflicts

If proposed work contradicts an existing ADR, identify that conflict explicitly instead of silently overriding the decision.
