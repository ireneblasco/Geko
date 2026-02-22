# User Interview Guidelines

Simple, actionable guidelines for conducting user interviews to uncover gaps and bugs in Geko.

## What We're Looking For (The 3 Pillars)

| Pillar | Question to Answer | What to Watch |
|--------|--------------------|---------------|
| **Confusion** | Where do they hesitate, ask "what does this do?", or guess wrong? | Pauses, wrong taps, re-reading labels |
| **Friction** | Where does the flow feel slow, repetitive, or annoying? | Sighs, extra taps, workarounds |
| **Delight gaps** | What did they expect that wasn't there? | "I wish it could…", "I thought it would…" |

**Steve Jobs principle:** *"It's not the customer's job to know what they want."* — Don't ask "what do you want?" Ask them to *do* things and watch what happens.

**Derek Sivers principle:** *"If it's not a hell yeah, it's a no."* — If they're lukewarm about a core flow, that's a signal.

## Simple Interview Structure (15–20 min)

### 1. Setup (2 min)

- Give them the app on a device (their own or a test device).
- Say: *"Use it like you would a habit tracker. I'll watch and take notes. There are no wrong answers."*
- **Don't** explain features. Let them discover.

### 2. Core Tasks (10–12 min)

Ask them to do these, one at a time. Observe; don't help unless they're truly stuck:

1. **Add a habit** — e.g. "Add a habit called 'Morning run'."
2. **Complete it today** — "Mark it as done for today."
3. **Check progress** — "See how you did this week."
4. **Change view** — "Switch to month or year view if you can."
5. **Edit or delete** — "Change the habit name or remove it."

*(Adjust if Geko has Watch/widget flows you care about.)*

### 3. Wrap-up (3–5 min)

- *"What was the most confusing part?"*
- *"What would make you use this every day?"*
- *"Anything that felt broken or wrong?"*

## What to Capture (Minimal Notes)

| Signal | Example Note |
|--------|--------------|
| Wrong tap | "Tapped week dot expecting detail, got nothing" |
| Hesitation | "Stared at Add button for 5 seconds" |
| Workaround | "Used search to find habit instead of scrolling" |
| Bug | "App crashed when completing 4th habit" |
| Missing expectation | "Expected to see streak count" |

**One rule:** If you can't act on it, don't write it. Notes should lead to a concrete fix or decision.

## After the Interview

1. **Prioritize** — Confusion and bugs first; friction second; delight gaps when you have bandwidth.
2. **One change per finding** — Each note maps to one fix or one "won't fix" decision.
3. **Re-test** — After fixing, run the same tasks with someone new to validate.

## Summary: The 5 Rules

1. **Watch, don't lead** — Let them use the app; don't explain.
2. **Tasks over opinions** — "Do X" beats "What do you think of X?"
3. **Confusion, friction, delight gaps** — These are the three things we're hunting.
4. **Notes = actions** — Every note should lead to a fix or a conscious "won't fix."
5. **Keep it short** — 15–20 min per session; 5 core tasks max.
