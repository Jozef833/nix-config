# agent-policy

A bash policy engine for coding agents. It evaluates every Bash command an
agent is about to run against `policy.json` and either allows it or denies
it with a message that teaches the better approach. The denial reason is
fed back to the model, so the correction happens in-session at the moment
it is relevant.

Each supported harness gets a thin adapter — a hook subcommand or native
plugin that translates that harness's own tool-call schema into a call to
the shared engine below — wired up in `modules/agent-policy.nix`, running
under `bypassPermissions` and applying to subagents.

## Design philosophy

Two decisions shape everything here.

**Knowledge lives in rules, not in the engine.** There is no universal
grammar of command-line flags — argv conventions are private to each binary —
so an engine that tries to *understand* commands (search roots, transparent
launchers like `sudo`, per-tool depth flags) accretes unbounded per-binary
tables. This engine instead models exactly one binary: bash itself. It
parses the script (via `mvdan.cc/sh`), enumerates every simple command —
including inside `$(...)` and `<(...)` — and tags loop membership. Those are
facts about bash structure, which is finite and portable. Everything else
(which paths are slow, which tools traverse, what counts as bounded) is
expressed in `policy.json`, which is deliberately personal and curated.

**Intervene before execution, never during.** Verdicts are allow or deny,
decided pre-flight. A false deny costs a rephrase; a runtime interruption can
destroy legitimate long-running work and fights the lifecycle machinery the
host tools already have (Claude Code backgrounds long commands, OpenCode has
its own timeouts). Slow-but-legal commands simply run. Unparsable input is
allowed (fail open): a policy engine that wedges the agent is worse than a
missed match.

Tolerated imprecision is what keeps this small: because the failure mode of
an over-broad rule is a readable denial the agent can adjust to — never lost
work — textual matching is good enough, and a thousand lines of semantic
modeling stay deleted.

## Rule schema

```json
{
  "match":   [{ "command": ["find", "fd"], "args": "(^| )/mnt/" }],
  "unless":  [{ "args": "-maxdepth [1-3]( |$)" }],
  "scope":   "command",
  "message": "why this is denied and what to do instead"
}
```

- `command`: exact match on argv[0] (string or list = any-of). Requires a
  literal argv[0], so `echo "find /"` can never false-positive.
- `args`: RE2 regex (string or list = all-must-match) over the remaining
  argv joined with spaces. Literal words are unquoted/unescaped; expansions
  keep their source text (`$VAR`, `$(cmd)`).
- `scope`: how close together multiple matchers must co-occur — `command`
  (same simple command; default for one matcher), `loop` (same loop body),
  `script` (anywhere; default for several matchers).
- `unless`: suppresses the rule when satisfied within the same scope.
- Rules are an unordered set: every rule is always evaluated, so order never
  changes the outcome, and a command that violates several rules is denied
  with all of their messages. A rule has no name; its message is its
  documentation.

Workflow for a new rule: add it to `policy.json`, add a fixture to
`testdata/fixtures.json` proving it fires (plus one proving a legitimate
variant stays allowed), and run `agent-policy test` from this directory.
Changes deploy at the next rebuild; the git diff is the review gate.

## Conscious tradeoffs

- Anchoring on argv[0] means `sudo find /` or `xargs find /` does not trip a
  `command: "find"` rule. Add a targeted rule if it starts happening.
- The same anchoring makes `timeout` the *sanctioned* escape hatch:
  `timeout 5 find ...` deliberately bypasses traversal rules, because a
  search bounded to a few seconds is exactly what the policy wants — a depth
  cap limits pathological routes, but the tight timeout is what actually
  caps the cost. Deny messages teach that form.
- The noise-filter rule (`grep -v` over `.git/`, `node_modules`, `.venv`,
  `site-packages`, `__pycache__`, `.direnv`) deliberately matches on the
  *filter alone*, with no list of producing commands. Writing that filter is
  itself an admission that something already walked those trees, so the
  producer clause only re-verified — through an incomplete enumeration — what
  the filter already proves, and enumerating every tool that can walk a
  directory (`find`, `fd`, `grep -r`, `rg`, `ls -R`, `diff -r`, a `**` glob)
  is unwinnable. A producer list fails *open*, which is the expensive
  direction; matching the filter alone fails closed. The accepted cost is
  false positives on streams that are not traversals at all — `npm run build
  2>&1 | grep -v node_modules` is denied, and `testdata/fixtures.json` pins
  that case by name so the tradeoff stays visible under review.
- The sibling rule for *exclusion flags* (`find -not -path '*/.git/*'`,
  `grep -r --exclude-dir=.git`) does keep a command list, because there the
  producer is the only thing to match — no separate filter incriminates it.
  It stays scoped to `.git` alone: `.git` is special in having tooling that
  skips it by construction (`git ls-files`, `rg`, `fd`), whereas `-not -path
  '*/node_modules/*'` is the bound the unpruned-`find` rule actively
  recommends, and widening this rule would deny its own remedy.
- Inline scripts (`bash -c '...'`) are not analyzed — argv contents are plain
  text to the engine. Deliberately deferred as too hard to do well this
  early; args regexes can still match the quoted text if a rule wants to.
- No path resolution: `cd` targets are matched textually (see the
  script-scoped `cd /mnt/*` rule), so a traversal after a *dynamic* cd
  (`cd "$DIR" && find .`) is invisible.
- No metering: a wasteful-but-rule-free command runs to completion under the
  host tool's own timeout. If a pattern recurs, it becomes a rule.
- Learning is manual: prompt the agent to propose a rule + fixture, review
  the diff, rebuild. There is no automated self-modification.

## TODO

- Inline shell script analysis (`bash -c '...'`, including behind wrappers
  like `sudo` or `devenv shell --`) is deferred; compendium item 5 (a
  `find /` inside `devenv shell -- bash -c '...'`) is currently uncaught.
- Fixtures encode this machine's layout (`/mnt/*` mounts, the repositories
  path); portable they are not. Fine for now — the policy itself is personal
  — but worth revisiting if this is ever extracted for reuse.
- `grep` after `cd` onto a mount is not covered by the script-scoped
  `cd /mnt/*` rule (only recursive-by-default tools are listed) to avoid
  denying single-file greps; add a flag-gated variant if it bites.
- A generous wrapper (`timeout 300 find /mnt/...`) escapes the same way a
  tight one does — nothing checks the duration. If agents start reaching for
  large values, add a rule matching `command: "timeout"` with a duration
  pattern.
- Deferred from v1 by design review: argv-level PATH shims (exec-time
  enforcement), automated in-session self-healing, and any filesystem
  classification in the engine.
