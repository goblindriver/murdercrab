# MurderCrab Balance Brief for Code

## Objective
Tune **Loop 2** so the early and middle game normalize upward to the current late-loop difficulty band, while preserving the fact that:
- **Loop 1 already feels right**
- **Stage 5 Loop 2 is already close**
- **both TLBs are already hard, but can take a modest density increase**

This is not a global “make everything harder” pass.

## Player test read
A test run started with **100 lives** for safety and finished Loop 2 with **99 lives and 0 bombs** before/through the TLB path.
Interpreted against the normal **3-life start**, that suggests the run would likely end with roughly:
- **2 lives left**
- **0 bombs left**

That means the top end is not fundamentally broken. The issue is the **resource drain curve**:
- attrition starts too late
- early/mid Loop 2 is too soft
- late Loop 2 and the TLB zone are closer to target

## Desired difficulty shape
### Keep:
- Loop 1 baseline
- current Stage 5 Loop 2 identity
- current TLB identity, with only modest escalation

### Raise:
- Loop 2 Stage 1
- Loop 2 Stage 2
- Loop 2 Stage 3
- Loop 2 Stage 4

### Slightly raise:
- TLB 1 bullet density
- Final TLB bullet density

## Design target
Loop 2 should feel immediately distinct from Loop 1 and should settle into a stable pressure band that sits:
- above Loop 1’s finale/TLB-adjacent tension
- below or near current Loop 2 Stage 5
- then naturally climb into Stage 5 and the final TLB

## Practical tuning notes

### Loop 2 Stage 1–2
Increase enough that the second loop is obvious from the opening.
Recommended levers:
- bullet density +10% to +20%
- bullet speed +4% to +7%
- slightly shorter downtime between waves
- slightly more aimed pressure where readable
- modest HP increase only for space-holding threats

Do **not** just make popcorn tankier.

### Loop 2 Stage 3–4
These should become the loop’s “true operating pressure.”
Recommended levers:
- bullet density +15% to +20%
- bullet speed +6% to +10%
- less dead air between patterns
- add one extra burst or one extra support threat where the route still reads clearly
- modest mini-boss / boss HP increase only if needed for pattern persistence

### Loop 2 Stage 5
Touch lightly.
Only fix obviously soft stretches.
Recommended levers:
- density +0% to +5% max in any over-safe moments
- trim dead time before raising raw speed

### TLB 1
Increase bullet density modestly.
Recommended levers:
- density +10% to +15%
- speed +3% to +5% max
- tighten existing lanes before inventing entirely new chaos

### Final TLB
Also raise density modestly, but preserve dignity and readability.
Recommended levers:
- density +8% to +12%
- speed +2% to +4% max
- pressure the resets and obviously safe recovery beats
- preserve pattern identity

## Success criteria
A successful pass should produce this feel:
- Loop 2 is unmistakably Loop 2 from the start
- resource drain begins earlier
- Stage 1–4 no longer feel like a fallback to first-loop comfort
- Stage 5 still feels like the climax
- both TLBs feel denser and more authoritative, not mushier
- a good player still survives with discipline, but can no longer coast the first half

## What not to do
Do not solve this by:
- inflating HP across the board
- adding bullets uniformly to every pattern
- making Stage 4 harder than current Stage 5
- replacing authored pressure with sludge
- turning TLBs into unreadable soup

## Implementation order
1. raise Loop 2 Stage 1–2
2. raise Loop 2 Stage 3–4
3. retest Stage 5 unchanged
4. then increase both TLBs’ density
5. only after that, fine-tune speed again

## Short version for ticketing
“Normalize Loop 2 upward from Stage 1 onward so its early and midgame live in the same neighborhood as the current late-loop standard. Keep Loop 1 intact. Touch Stage 5 lightly. Increase both TLBs’ bullet density modestly without sacrificing readability.”
