# Build strategy

Track: Build. Workspace: originally greenfield, now Godot first playable.
Output strategy: full. Mode: guided-build. Exploration: high for the character rebuild; standard for narrow gameplay fixes.
Current gameplay target: first-playable local single-player. Character0.9 target: polished-prototype foundation with native review, model export, rig tests and a studio; authored final art remains a separate gate.
Team: 4 people, proposed20h/person/week and75% productive focus; no cash budget.
Platform: Godot4.7.2 stable, GDScript, Compatibility, Windows native first; Web spike next.

Thin loop: navigate → fight → capture → feed → progression → death/respawn → local save.
Simulation is independent of rendering/input/audio. Original code-drawn forest/jade/stone and original skinned3D character geometry avoid paid assets. No broad ECS/service rewrite in this slice.

The online FSD and72-package WBS remain the alpha specification. Local tests do not complete server/security/transaction gates. Forecast199PD +20%reserve and36weeks needs re-estimation after the Godot online/DB spike and actual team availability.

Next: two-client headless authority and PostgreSQL feed transaction; then refine/equip/rank and content. Defer social until durable economy/recovery works. See ../implementation/GODOT_IMPLEMENTATION_PLAN.md for role budgets, dependencies and evidence.

Character pass uses builder/reviewer/verifier as required by the high-exploration skill: animation, studio/core, weapon motion, Blender authoring, independent model/material review and root model/render integration. Durable character plan/FSD/WBS record the review gates and remaining production art work.

0.14 continuation: Polish / prelaunch / guided-build / polished-prototype visual target / high exploration. Root builds presentation/gait/camera; independent verifier reviews geometry, hand origins, F6 controls and native frames. Runtime verification and visual review precede the source handoff. Gameplay/online scope stays as specified above.
