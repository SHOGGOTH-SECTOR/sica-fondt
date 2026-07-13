# devCorrectionLog

⊳ User gives **additive** clarifications. Only an explicit "no" is a replacement.
⊳ Don't rewrite — append. Don't guess — ask or research first.
⊳ Don't idle while subagents run.

```yml
corrections:
  - epoch: 1783985662
    failcase: "rewrote L3 seven times"
    identifyBy: "treating every clarification as a full replacement"
    instead: "append the new detail to existing text, preserve prior content"

  - epoch: 1783985662
    failcase: "idle during foreground subagent"
    identifyBy: "ran research agent synchronously, did nothing while waiting"
    instead: "run agents in background, continue editing other files"

  - epoch: 1783985662
    failcase: "guessed sim speed without research"
    identifyBy: "accepted 360:1 then 3600:1 then 86400:1 without pushback"
    instead: "research comparable systems before committing a number"

  - epoch: 1783985662
    failcase: "5 commits on one parameter"
    identifyBy: "each clarification triggered a commit-push cycle"
    instead: "accumulate related changes, commit once when stable"

  - epoch: 1783985662
    failcase: "never asked what economy organ was"
    identifyBy: "wrote 8 wrong specs (text digestion) without asking"
    instead: "ask what the thing is before designing it"
```
