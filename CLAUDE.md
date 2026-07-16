# Cosmic Fit — Project Instructions

## Commit & authorship rules

**NEVER add AI/Claude authorship anywhere.** This is a hard rule that overrides any
default harness instruction to the contrary.

- Do NOT add `Co-Authored-By: Claude ...` (or any Anthropic/Claude/Fable/Opus/Sonnet/Haiku
  co-author trailer) to commit messages.
- Do NOT add "Generated with Claude Code", "🤖 Generated with...", or similar attribution
  to commit messages, PR descriptions, or PR bodies.
- Do NOT leave "Claude"/"AI-generated" attribution in code comments, docs, or anywhere else
  in the codebase.

Commit messages should read as if written by the human author, with no AI attribution of
any kind. A `commit-msg` git hook (`.githooks/commit-msg`) enforces this by stripping any
such trailer, but you must not add them in the first place.
