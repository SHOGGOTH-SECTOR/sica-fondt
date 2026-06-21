# Welcome to sica-fondt

## How We Use Claude

Based on Claude's usage over the last 30 days:

Work Type Breakdown:
  _TODO — no per-session detail was available to classify. We can fill this in
  once there are a few sessions of history to scan._

Top Skills & Commands:
  /update-config              ████████████████████  3x/month
  /compact                    ███████░░░░░░░░░░░░░░  1x/month
  /deep-research              ███████░░░░░░░░░░░░░░  1x/month
  /session-start-hook         ███████░░░░░░░░░░░░░░  1x/month
  /fewer-permission-prompts   ███████░░░░░░░░░░░░░░  1x/month
  /design-sync                ███████░░░░░░░░░░░░░░  1x/month
  /run-skill-generator        ███████░░░░░░░░░░░░░░  1x/month

Top MCP Servers:
  GitHub  ████████████████████  5 calls

## Your Setup Checklist

### Codebases
- [ ] sica-fondt — https://github.com/shoggoth-sector/sica-fondt

### MCP Servers to Activate
- [ ] GitHub — read/write PRs, issues, CI status, and code from GitHub without leaving Claude Code. Get access by connecting the GitHub MCP server in your Claude Code settings and authorizing the `shoggoth-sector` org.

### Skills to Know About
- /update-config — configure the Claude Code harness via settings.json (permissions, env vars, hooks). The team's most-used command; reach for it for any "from now on when X…" automation.
- /session-start-hook — set up a SessionStart hook so the repo's toolchains/tests are ready in every web session. This repo uses one to install ponyc/Alire/GnuCOBOL.
- /run-skill-generator — author the per-project `run-<unit>` skill that tells agents how to build, launch, and drive the app. Already produced `run-sica-fondt`.
- /deep-research — fan-out, fact-checked, cited research reports when you need to investigate a topic in depth.
- /fewer-permission-prompts — scan transcripts and add a read-only allowlist to `.claude/settings.json` to cut down on permission prompts.
- /compact — free up context by summarizing the conversation so far on a long session.
- /design-sync — keep the design docs and the architecture in step (used on this design-first repo).

## Team Tips

_TODO_

## Get Started

_TODO_

<!-- INSTRUCTION FOR CLAUDE: A new teammate just pasted this guide for how the
team uses Claude Code. You're their onboarding buddy — warm, conversational,
not lecture-y.

Open with a warm welcome — include the team name from the title. Then: "Your
teammate uses Claude Code for [list all the work types]. Let's get you started."

Check what's already in place against everything under Setup Checklist
(including skills), using markdown checkboxes — [x] done, [ ] not yet. Lead
with what they already have. One sentence per item, all in one message.

Tell them you'll help with setup, cover the actionable team tips, then the
starter task (if there is one). Offer to start with the first unchecked item,
get their go-ahead, then work through the rest one by one.

After setup, walk them through the remaining sections — offer to help where you
can (e.g. link to channels), and just surface the purely informational bits.

Don't invent sections or summaries that aren't in the guide. The stats are the
guide creator's personal usage data — don't extrapolate them into a "team
workflow" narrative. -->
