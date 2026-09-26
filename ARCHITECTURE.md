# Architecture (v0.2)

This pack installs machines. It does not install one model's personality.

## Harness, then mind

The harness is the part that stays: cards, tools, a power list, and files the next session can read. The model is a seat. You can swap the mind and run the same jobs. Proof is the tool it called and whether the box did the thing, not whether the sentence sounded right.

That is architecting by conversation. The talk decides. The file keeps the decision. A chat that forgets itself when it closes is a different method.

## Seats

| Seat | Job |
|------|-----|
| Desk | Where you sit and build |
| Fast GPU | Short talk, voice, tools that must answer now |
| Capacity | One big model and its context. 128 GB class. Does not replace the fast seat |

Do not split one model's weights and context across a 1 GbE house LAN. If you add a faster private link (fiber, RDMA), measure it before you treat it as a fabric. A second capacity box is how the pool grows. The fast GPU does not become a peer of that box just because a cable exists.

## What this repository installs

Three profiles only. Placeholders only.

- `minimal-web` — one web box
- `ai-desk` — one GPU or desk box (Ollama, Open WebUI, HouseCap)
- `homelab-core` — those two plus a small always-on monitor and fleet update scripts

Your real addresses, passwords, and family data stay in `nodes.yaml` and `secrets.env`, which are not part of the git tree.

## Inner seats

A CLI or a phone agent can sit in front of the harness and ask it to do a job. It should not hold the power password or the node list. One outer harness. A few inner seats. Not a second copy of the house.
