# Systems design

Current verbs: click move/select; Q moon, W shield, E dash, R frost; C capture, Tab feed, Esc pause, M mute. Safe camp radius2 blocks offensive casts and incoming damage. Navigation and sweep share blocked cells; diagonal corner cutting is disallowed.

Moon power35+0.8attack, mana8%, cooldown2s, range6. Shield70+0.5attack, cap40%maxHP, duration5s, mana12%, cooldown12s. Dash range3 with sweep, mana10%, cooldown8s. Frost20+0.8attack, slow30%/3s, mana10%, cooldown8s, range5. Mob defense4; player base attack10/HP200/mana100. Costs apply after validation; accepted cast cancels movement/capture.

Wolf: idle → chase → windup0.65s → strike12/cooldown1.3s → leash/dead. Strike checks reach1.45 andLOS on resolution; moving out dodges. Safe/dead/far player triggers return/reset. Kill/capture respawn20s. First valid hit sets local encounter ownership.

Capture: owned targetHP≤30%, range≤3, LOS, seal and bag space. Consume seal on start, channel2s,70%roll. Damage/move/cast/invalid target or range cancels without refund. Success removes target and adds1Gu. Captured Gu cannot yet be swapped into fixed hotbar.

Inventory30slots; material stack99; Gu unique including equipped. Hunger100start, equipped online decay1/300s; <20output×0.8,0cannot cast; correct food+40cap100. Starter moon82 is a teaching fixture. Feed replay sameID/payload returns same receipt; payload change conflicts; last128receipts persist. Pending material rewards auto-recover when space opens, separate from the future alpha inbox/ledger.

Kill12currency/35XP/meat/seal once. Next level cumulative threshold50L(L+1), max20; HP+20/level. Teaching quest3kill/1capture/1feed awards200once. Death5s, penalty5%currency cap50, noGu loss; respawn full resources. No offline hunger. Local restart resets transient combat.

Refine/equip/rank/passive, full quests and online recovery remain future FSD work. See system-architecture.md and ../implementation/GODOT_IMPLEMENTATION_PLAN.md.
