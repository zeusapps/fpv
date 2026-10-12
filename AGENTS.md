# AGENTS.md

Repository instructions for Codex.

## Shared project instructions

Read and follow [CLAUDE.md](CLAUDE.md) before you work in this repository.
It contains the shared hardware constraints, evidence requirements, configuration rules, OpenSpec workflow, and documentation style.
Keep those rules in `CLAUDE.md` so Claude Code and Codex use the same instructions.

Read [HANDOFF.md](HANDOFF.md) before work on the Pavo20 Pro II.
Read [docs/betaflight-reference.md](docs/betaflight-reference.md) before answers about Betaflight CLI formats and encoded values.

## Codex workflow

- Use the repository skills in `.agents/skills/` for OpenSpec tasks.
- Use `$openspec-propose` to prepare a change and `$openspec-apply-change` to implement it.
- Use `$openspec-update-change` to revise a plan.
- Treat `opsx ff` and `$openspec-ff-change` as aliases for `$openspec-propose`, as the shared instructions require.
- Use the command table in [README.md](README.md) to translate Claude commands into Codex skills.
- Run CLI commands with the available shell. The generated skills use Bash labels, but this repository does not require Bash.
- Keep repository skills under version control. Do not depend on prompts in a user's `~/.codex/prompts/` directory.

There is no software build or test suite for the aircraft configurations.
Keep source review, syntax validation, bench verification, and flight verification distinct in reports.
