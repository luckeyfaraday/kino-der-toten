# Kino browser game

Double-click **Play Kino.cmd**, then **Enter the Theater**. The launcher reuses this workspace's server or selects an available port from 5173–5183. The chosen address is written to `artifacts/kino-url.txt`.

Kino is endless solo survival. There is no final boss or victory screen; the film reels and 115 music are optional discoveries during a run.

## Added gameplay

- **32 primary weapons** with exported models, native animations, ammunition and upgraded definitions. The Mystery Box uses the map script's 23 eligible entries, including Monkey Bombs; wall-only weapons no longer enter its pool.
- **Pack-a-Punch** takes the selected weapon for 4.35 seconds, then offers it for 15 seconds. Press F again to retrieve it. It costs 5,000 points once. Missing the offer loses that weapon; another wall or box purchase restores an empty slot. A second weapon remains usable during processing.
- **Native upgrade names and dual models**, including Mustang & Sally, Tokyo & Rose, Calamity & Jane, and Typhoid & Mary. Dual guns alternate their firing animations and use one combined magazine counter. Upgraded M16 and AUG attachments switch with **5** and retain separate ammunition.
- **Projectile flight** for Ray Gun, launchers, crossbow bolts, and the Ballistic Knife. Bolts stick and explode after their fuse; Awful Lawton bolts attract nearby zombies. Spent ballistic blades can be recovered. Walls block projectile hits and blast damage.
- **Claymores:** buy once for 1,000 points at the stage wall, then press **4** to place. They arm, detect enemies in their forward cone, and detonate after a 0.4-second warning. Two replenish each round or with Max Ammo.
- **Monkey Bombs:** obtain from the box and press **X** to throw. They attract zombies, animate their cymbals after landing, and explode. They have their own three-bomb supply, replenished by Max Ammo.
- **Two automatic turrets:** restore power, then pay 1,500 points at a turret switch. Each targets visible enemies for 30 seconds. Repeated use while active cannot charge again.
- **Hidden return rooms and film reels:** after 30 seconds in the projection room, the teleporter has a 75% chance of visiting one of four rooms before returning to the lobby. Three reels are randomized across three different rooms. Carry one reel at a time and use F at the projector on a later visit. The projector displays frames from the original recovered film atlas. The screen lowers over six seconds when power comes on.
- **HUD guidance** for power, linking and carried reels; equipment counts; safe pause on focus loss; restart cleanup for all added entities. Collision now includes the four hidden rooms, with correct floor contact and a fall-reset limit below the basement.

## Controls

| Key | Action |
| --- | --- |
| WASD / mouse | Move / look |
| Left / right mouse | Fire / aim |
| Shift + W / Space / C or Ctrl | Sprint / jump / crouch |
| F or E | Use; hold to repair |
| R / V / G | Reload / knife / grenade |
| 1, 2, Q or mouse wheel | Switch primary weapon |
| 4 / X | Place Claymore / throw Monkey Bomb |
| 5 | Switch upgraded M16/AUG attachment |
| Esc / M / F3 | Pause / mute / diagnostics |

## Sources and rebuilding

The original archives remain unchanged. `npm run build:assets` reproduces the expanded data, models, film atlas and 676 clips from the retained local dumps. Unchanged animation exports are reused. `.tools/rebuild-kino.ps1` remains the full geometry, navigation and audio rebuild command.

Gameplay references are `zombie_theater.gsc`, `zombie_theater_teleporter.gsc`, `zombie_theater_movie_screen.gsc`, `_zombiemode_perks.gsc`, `_zombiemode_claymore.gsc`, `_zombiemode_auto_turret.gsc`, `_zombiemode_weap_cymbal_monkey.gsc`, and the original `weapons/*` definitions in `export_game`.

`kino-session.js` owns the new inventory rules, `kino-events.js` owns reel selection, and `kino-features.js` connects projectiles, equipment, turrets and projection to the scene. Moon retains its separate progression module.

## Verification

Run `npm test` for rules and local asset coverage. With the server running:

```powershell
npm run test:completion
npm run test:weapons
node .tools/test-weapons.mjs --upgraded
npm run test:gameplay
npm run test:zombies
npm run test:extras
npm run test:melee
npm run test:presentation
npm run test:routes
node .tools/test-kino-rooms.mjs
```

Reports and screenshots are under `artifacts/kino-completion`, `artifacts/weapons`, `artifacts/qa`, `artifacts/zombies`, and `artifacts/presentation`. These combine real browser controls with controlled setups and accelerated simulation; they are not an uninterrupted survival playthrough.

The physical room check walks from each native return destination to all twelve possible reel placements, within the visit timer. It also verifies floor contact. The four original main-map routes remain covered separately.

## Remaining fidelity differences

This is a browser reconstruction, not the original engine. Native lightmaps, full material layering, exact collision/AI, recoil and penetration, weapon camo, native FX/ragdolls, camera feeds and every ambient scripted event remain approximate or absent. Turrets use simplified aiming and damage. Dual guns share one ammo counter. Equipment placement/throwing does not reproduce every native first-person gesture, and film playback uses the recovered atlas rather than the complete FX interpreter. Some sounds use procedural fallbacks. Rare random powerups in the return rooms are not implemented. Networking, saved runs and controller/mobile input remain outside this solo desktop build.

See `RECONSTRUCTION.md` for the retained engine reconstruction notes. Pre-change core files are in `artifacts/completion-originals`.
