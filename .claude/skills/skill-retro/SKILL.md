---
name: skill-retro
description: Mini retrospective on the current session — what skills were used, what friction showed up, and what edits to the skill files would prevent that friction next time. Use when the user says "skill-retro", "retro on this session", "what should we change about the skills", or invokes /skill-retro. No arguments — scopes to the current conversation.
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
---

# /skill-retro

Lightweight feedback loop on custom skills. Each session is real usage data — friction worth fixing usually only surfaces in retrospect, after the work is done. This skill is the moment to capture it.

No arguments. Scopes to the conversation you're already in.

---

## Process

### 1. Inventory what happened

Look back over the conversation:
- Which skills were invoked? (Including built-in ones like `/review` if they came up.)
- What was the user trying to do at each step?
- Where did the user have to redirect, correct, or work around the skill?
- Where did *you* hesitate, ask the user something the skill should have answered, or pick the wrong tool?

Don't list every step — list the friction points. A smooth skill run with no surprises produces zero items here, and that's fine.

### 2. Categorize each friction point

For each one, decide if it's:

- **Skill bug** — the skill said to do X, X didn't work or pointed somewhere wrong.
- **Skill gap** — the skill didn't cover a case that came up. (e.g. "user reported a bug mid-implementation; nothing in the skill said to ask diagnostic questions first.")
- **Skill scope mismatch** — wrong skill was invoked because descriptions overlapped or the right one's trigger phrases didn't match user phrasing.
- **Not a skill problem** — operator error, unrelated repo issue, environmental flake. Note it but don't propose a skill edit.

### 3. Propose edits

For each Skill bug / gap / scope finding, write a concrete edit:
- Which file (`.claude/skills/<name>/SKILL.md`)
- Which section (step number, anti-patterns block, frontmatter description)
- Old text → new text, or "add this bullet"

Keep edits *small and specific*. The trap here is rewriting whole sections; the win is precise sentences that close the gap that actually showed up. If the skill is fundamentally well-shaped, one-line tweaks beat a rewrite.

### 4. Confirm with the user before editing

Show the proposed edits as a list. Ask which to apply. The user is the source of truth on whether something was actually friction or just a one-off.

### 5. Apply approved edits

- Edit each `.claude/skills/<name>/SKILL.md` in place.
- Trigger-phrase changes go in the frontmatter `description:` field (that's what the harness uses to match user phrases to skills).
- Process changes go in numbered steps.
- Lessons that are easy to forget go in the `## Anti-patterns` block.

If a finding is broad enough to warrant a *new* skill (rare — usually it's an edit to an existing one), confirm scope with the user before creating files. New skills add cognitive load on every future session, so the bar is high.

### 6. Commit (when the user asks)

Skill edits are repo files like any other. If the user wants them committed, follow commit conventions the user prefers. Subject line should reference what changed, e.g. `Tighten /implement hand-off + add diagnostic-first anti-pattern`. No issue number unless one applies.

---

## Anti-patterns

- **Don't generate findings to look thorough.** A clean session has nothing to fix. Saying "no friction worth changing" is a valid output.
- **Don't rewrite skills when a sentence will do.** Small targeted edits compound; sweeping rewrites just churn the files.
- **Don't add anti-patterns the user never hit.** Speculative warnings bloat the skill and dilute the real ones.
- **Don't propose new skills lightly.** A new skill needs to justify the cognitive load of *every* future session having it on the list. Edit an existing one first if at all possible.
- **Don't apply edits without confirming.** The user knows their own friction tolerance — what felt rough to them might be fine, and vice versa.
