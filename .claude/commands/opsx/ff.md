---
name: "OPSX: FF"
description: "Alias for /opsx:propose - create a change and generate all its artifacts in one step"
allowed-tools: Bash(openspec:*), Bash(npm view:*)
category: "Workflow"
tags: ["workflow", "artifacts", "alias"]
---

**Hand-maintained alias. `openspec update` overwrites this file - see `CLAUDE.md`.**

`ff` (fast-forward) is still a real OpenSpec workflow, kept in this project's profile only so that
`/opsx:ff` keeps resolving. This repo prefers `propose`, which does the same job but adds a
planning boundary: it stops after the artifacts and will not start implementation in the same
response.

**Do this**: run the `openspec-propose` skill, passing whatever followed `/opsx:ff` as the change
name or description. Follow that skill's instructions exactly, including its step 0 CLI version
check. Do not re-implement the workflow here.

If `openspec-propose` is unavailable, the profile is out of sync. Run `openspec update`, then
retry. Falling back to the `openspec-ff-change` skill is acceptable, but it has no planning
boundary, so stop after the artifacts and do not begin implementation.

**Tell the user once, at the start of the run**: `/opsx:ff` is an alias for `/opsx:propose`, which
will not start implementation in the same response.
