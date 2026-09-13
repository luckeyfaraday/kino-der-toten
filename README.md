Kino der Toten — browser Zombies
================================

**Play online:** [Kino der Toten](https://kino-der-toten.pages.dev/). This Pages site hosts Kino only, with desktop and touch controls. Wait for the map to load, then press **Enter the Theater**. The site works independently of this PC's local launcher.

**Fresh checkout:** install Git LFS and Node.js 24, then run the following commands. The browser assets are included; large binary assets use Git LFS. Python 3.11 with Pillow is also needed to stage or deploy to Cloudflare Pages.

```powershell
git lfs install
git clone https://github.com/luckeyfaraday/kino-der-toten.git
cd kino-der-toten
git lfs pull
npm ci
npm start
```

Open the local address printed by the server. The repository includes the other local map work, while the Pages deployment script packages Kino only. Original game archives, extraction dumps, third-party extraction executables, local caches, and Cloudflare credentials are excluded. Rebuilding assets from the original installation requires the separate inputs and tools described below.

**The Kino gameplay completion pass is ready:** 32 weapons, native upgrades and dual guns, timed Pack-a-Punch retrieval, projectiles, Claymores, Monkey Bombs, turrets, hidden return rooms and film reels. See [KINO_COMPLETION.md](KINO_COMPLETION.md) for controls, source references and fidelity limits.

Double-click **Play Kino.cmd**, then click **Enter the Theater**. The launcher starts a local server and opens its local address (normally **http://127.0.0.1:5173/**; ports 5174–5183 are available if needed). Use desktop Chrome or Edge with hardware acceleration enabled. The first load includes the full map and can take several seconds.

The exported assets and browser dependencies are already included in this workspace. Playing requires Node.js, which is installed here. Python and FFmpeg are needed only for rebuilding. The browser loads its assets locally; it does not need a CDN or an account. Opening `index.html` directly with `file://` will not work.

**Mobile controls are available on Kino and Moon**, using the same touch system as the Black Ops 2 browser game. Tap the start button, move with the left stick (push forward to sprint), and swipe the right side to look. Hold FIRE and drag it to aim while shooting; tap AIM and CROUCH to toggle. USE, KNIFE, JUMP, RELOAD, weapon switching, grenades, and each map's equipment have on-screen buttons. Hold USE to rebuild barricades; Moon also has P.E.S., HACK, Wave Gun mode, and OBJECTIVE buttons. Pause in the upper-right corner to adjust look sensitivity. Landscape gives the controls more room, and portrait is supported.

Kino automatically uses smaller textures and a 30 FPS limit on phones. Its renderer and sound pause when Safari is backgrounded, and a restored graphics context resumes the existing run from the pause menu. This reduces memory pressure; iOS can still discard a background tab, and a fully discarded tab does not currently restore its run. `npm run build:mobile` regenerates phone textures. The memory/rotation checks are `npm run test:mobile:memory` and `npm run test:mobile:webkit`; the latter uses Playwright's Windows WebKit port, not a physical iPhone.

To play from a phone on the same Wi-Fi, double-click **Play Mobile.cmd** (or run `npm run start:mobile`) on this PC and open one of the printed phone addresses. Kino is at `/`, and Moon is at `/moon.html`, on port 5184. Keep the terminal running while playing; Ctrl+C stops the server. The maps still load their full local assets, so the first load can take time on a phone. Mobile touch and layout checks use Chromium device emulation; physical Android and iPhone performance has not been measured.

This is a playable solo reconstruction built from this installation's geometry, textures, models, animations, scripts, and weapon definitions. It implements rounds, barricades, pursuit and melee, hellhounds, Nova crawlers, points, weapons, perks, power, traps, the Mystery Box, teleporting, Pack-a-Punch, and the 115 music Easter egg. It is not yet a complete reproduction of the T5 engine. See **RECONSTRUCTION.md** for the remaining differences and source references.

The theater's Nazi flag emblems are censored in the game and map viewer: banners render as plain red cloth with their original cutout edges. This renderer override survives asset rebuilds; source archives and extracted textures remain unchanged.

| Control | Action |
| --- | --- |
| WASD / mouse | Move / look |
| Left / right mouse | Fire / aim down sights |
| Shift + W | Sprint |
| Space | Jump |
| Ctrl or C | Crouch |
| F or E | Use / purchase; hold to repair a barricade |
| R | Reload |
| V | Knife; upgraded after buying the Bowie Knife |
| G | Throw grenade |
| 1 / 2, Q, or mouse wheel | Switch weapon |
| 4 / X | Place Claymore / throw Monkey Bomb |
| 5 | Switch upgraded M16/AUG attachment |
| Esc | Pause and release the mouse |
| M | Toggle sound |
| F3 | Show frame rate and diagnostics |

Start in the lobby with 500 points and the M1911. Survive rounds and buy doors to reach the stage power switch. Link the stage teleporter, activate its partner pad in the lobby, then return to the stage to teleport. The projection room gives you 30 seconds to use Pack-a-Punch. Retrieve the weapon with F after processing. The return trip may briefly visit a hidden room with a film reel. Quick Revive works in solo before power and can be used three times.

**Development and rebuilding**

For Cloudflare Pages, run `npm run cloudflare:stage`, then `npm run test:pages` to check the packaged game locally. `npm run cloudflare:deploy` rebuilds and publishes it to the existing `kino-der-toten` Pages project (Cloudflare login required). The build in `.work/cloudflare-pages` includes only Kino and splits map geometry and collision data into files below Pages' 25 MiB limit. Staging verifies every glTF buffer view, deduplicates identical collision positions, and verifies every triangle corner and the unchanged BVH. Python 3.11 with Pillow builds the mobile texture variants. Reports and browser screenshots are in `artifacts/cloudflare` and `artifacts/mobile-memory`. To check production, run `$env:KINO_URL='https://kino-der-toten.pages.dev/'; npm run test:pages` in PowerShell.

Run commands from this folder:

```powershell
npm start                         # foreground server; Ctrl+C stops it
npm test                          # game rule checks
npm run test:mobile                # both maps: real browser touch contacts, rotation, menus; starts its own server
npm run test:routes                # physically walk four routes using map collision
npm run test:gameplay              # browser gameplay checks; server must be running
npm run test:extras                # melee, collision, repair, round, grenade, Bowie checks
npm run test:weapons               # load, fire, and reload all 32 weapons
node .tools/test-weapons.mjs --upgraded # upgrade, fire and reload all 32
npm run test:completion            # equipment, projectiles, upgrades, reels, turrets
npm run test:presentation          # native weapon poses, actions, knives and audio
npm run test:melee                 # in-game knife timing, recovery and interruption
npm run test:zombies               # native drops, perk drinks and Mystery Box sequences
```

The launcher verifies the workspace when reusing its running server and finds another port when needed. Double-click **Stop Kino.cmd** to stop that background server. If you use `npm start`, stop the launcher server first or use `node .tools/serve.mjs 5174` and visit that port. The launcher's process ID and logs are in `artifacts/server.pid`, `artifacts/server.log`, and `artifacts/server-error.log`.

To regenerate the browser assets from the existing local dumps:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .tools/rebuild-kino.ps1
```

This requires Python 3.11 with Pillow, Node.js, and FFmpeg/FFprobe with the Black Ops Audio decoder. Those tools are installed on this machine. Add `-SkipAudio` to reuse the existing converted audio. Add `-Extract` to refresh the supported game asset dumps from the local fastfiles first. The initial world dump and static OBJ export are retained from the earlier reconstruction; regenerating that world dump needs the patched OpenAssetTools exporter described in **RECONSTRUCTION.md**.

The weapon fidelity pass restores per-weapon hip/ADS positions, native sprint and reload actions, per-shell shotgun reloads, and standard/Bowie knife models, animations and sounds. See **ANIMATION_NOTES.md** for the reverse-engineering findings and remaining differences.

The six Kino drops now have their original models, announcements and timed HUD icons. Perk purchases play the bottle-drinking sequence. The Mystery Box opens, cycles visible weapons and closes, with independent 10-point boxes during Fire Sale and teddy-bear relocation. See **ZOMBIES_INTERACTIONS.md** for source rules, timings and remaining presentation differences.

**Verification and continuation**

`artifacts/qa/report.json` records 25 browser checks, with screenshots and a WebM recording in the same folder. `artifacts/qa/extras-report.json` records six further gameplay checks. `artifacts/physical-routes.json` records the four physical traversal checks. These use real rendering and input plus controlled debug setups; they are not an uninterrupted human survival playthrough.

The browser exposes `kino.debug` for inspecting entities, navigation, collision, weapon shots, audio, and test state. The old free-fly viewer is retained at `/viewer.html`. Runtime code is in `export/web`; build and diagnostic tools are in `.tools`. Original game archives remain in `main` and `zone`.

**Call of the Dead map:** double-click **Play Call of the Dead.cmd** to open the original map directly in the browser, with walking and free flight, no landing page. See [CALL_OF_THE_DEAD_PORT.md](CALL_OF_THE_DEAD_PORT.md) for controls, source coverage and rebuild instructions.

**Moon now includes the solo quest and ending:** double-click **Play Moon.cmd**. Perks, Mystery Box, Pack-a-Punch, Wave/Zap Guns, Gersh/QED equipment, Hacker, excavators, special enemies and the Big Bang Theory sequence are connected. The launcher finds an available local port. See [MOON_PORT.md](MOON_PORT.md) for controls, the quest guide, build instructions, test evidence and differences from the original T5 game.
