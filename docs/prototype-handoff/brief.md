# Product Brief — FishSignal (selected working name)

> Prototype state. Inspired by market signal `Fishing Calendar & Tide Times` (App Store ID 414676749, GB / Weather). This is a differentiated build, not a clone. Source market data lives in `prototype.yaml`.

## Product Thesis

A fishing **bite-window forecast** that tells an angler the single best time to fish a specific spot today and this week — by fusing solunar major/minor periods with **barometric pressure trend, wind, and tide state** into one honest go / wait / skip call.

## Target User

UK shore, coarse, and small-boat anglers who fish in *limited* free windows (a morning before work, a Saturday tide). They are not meteorologists; they have strong folk-knowledge that **falling pressure and the right tide matter more than the moon alone**. Secondary: outdoor/local creators in angling communities.

## Emotional Job

> "Don't waste my one free morning on a dead tide."

The feeling we sell is **confidence about *when* to go** — and permission to *not* go when the window is bad, without guilt. It removes the gnawing "should I have gone earlier?" second-guessing.

## One-Line Promise

"Know your best two hours on the water before you load the car."

## One Core Loop

1. **Pick / confirm a spot** (home mark or a saved spot).
2. **See today's Bite Window** — a single score + the best time block, on a timeline that overlays solunar peaks, tide state, pressure trend, and wind.
3. **Open the window → session plan** — what is driving the score in plain angler language, a shareable card, and a one-tap "alert me 1 hour before."

The loop is *real* in the prototype: the Bite Score is computed live in JS from honest mocked fixture data (solunar + pressure + tide + wind), not a static picture.

## What Makes It Singular

The source app's top non-payment complaint is "it's basically just a solunar calendar — ignores weather and air pressure, which every angler knows matters." Our first-run mechanic **leads with pressure-aware, tide-aware bite windows**, the exact gap users named. The home screen is a fishing instrument, not a generic weather card.

## What NOT To Claim

- **No guarantee of catching fish.** Language is "best window / higher activity," never "you will catch."
- **Not live weather in prototype** — all forecast numbers are mocked fixtures, labelled in-app and in the report.
- **No catch-photo AI / species recognition.** The source app's catch-upload feature crashes; we deliberately scope it out of MVP rather than ship it broken.
- **No community, leaderboards, or social feed.** No fake social proof, no invented "X anglers fishing near you."
- **Not a marine safety or navigation tool.** Tide data is for planning, not for safety-of-life-at-sea decisions — stated in-app.
- **No medical/diagnostic-style certainty framing.** It is a *preparation* aid.

## Why This Is Worth A Prototype

Narrow job, defensible folk-knowledge wedge, a category with proven small-MVP revenue, and a clean annual-subscription story *if* the score proves trustworthy. The risk is entirely **forecast credibility**, which is exactly what prototype + first proof test should probe.
