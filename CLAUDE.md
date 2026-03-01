# CLAUDE.md

## Communication Style
- Be **brief and laconic**. No walls of text.
- State the next action item or problem concisely.
- Prefer bullet points over paragraphs.

## TDD Workflow (Red-Green)
Iterate in small steps — never write a full test suite then full implementation:
1. Write **one** failing test (red)
2. Implement **just enough** to pass it (green)
3. Repeat

## Project
Rails 8.1.1 / Ruby 4.0.0 / SQLite3 property management app.
See [README.md](README.md) and [REQUIREMENTS.md](REQUIREMENTS.md) for specs.

## Commands
```bash
bundle exec rspec                          # all tests
bundle exec rspec spec/path/to_spec.rb     # single file
bundle exec standardrb                     # lint
bundle exec standardrb --fix               # auto-fix
bin/rails db:migrate                       # migrations
```

## Conventions
- Tests: RSpec (`spec/`)
- Linter: StandardRB (no RuboCop config)
- Currency/labels configurable via env vars (see README)
- SQLite for all environments
