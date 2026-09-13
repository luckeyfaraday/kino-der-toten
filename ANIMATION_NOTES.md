# Weapon animation and sound reconstruction

This pass uses the original local T5 weapon definitions, compiled XAnims and
skeletal models. It does not claim a pixel-perfect comparison with a running
native executable. Before-change runtime files are retained in
`artifacts/animation-originals`.

## Position and animation findings

The weapon's `adsUpAnim` is an absolute animation of `tag_torso`. Its first
frame defines the hip pose, and its final frame defines ADS. For example, the
M1911 hip torso is `(-4.6318, 0, -1.377)`, while the MP40 is
`(3.9063, -1.6042, -3.6421)` in the source coordinates. Applying the M1911 arms'
bind torso to every weapon moved the MP40 toward the camera and made it huge.
The renderer now samples each weapon's own torso track, holds its ADS endpoint,
and restores its hip pose for actions that do not animate that bone.

Attachments are assembled outside the scene, with the exported root transform
removed before attaching `j_gun` to `tag_weapon`. Previously, deriving those
matrices beneath a moving viewmodel pivot included the previous weapon's ADS
or recoil in the new attachment. The regression check compares an MP40 equipped
from an aimed, firing weapon with a clean MP40 equip.

The runtime now plays native raise, idle/empty idle, fire/last shot/ADS fire,
reload, sprint entry/loop/exit, and knife animations. Single-pose clips have a
one-frame duration; firing can restart its action immediately. Animation
notifies drive reload foley. Reload and sprint playback speeds use the original
weapon timers, including Speed Cola. The Ray Gun has no sprint XAnims: its
definition instead specifies sprint translation `(3, -4, -5)` in forward,
right, up axes and pitch/roll offsets of five degrees.

Stakeout and SPAS-12 use the recovered segmented reload settings and
start/insert/end clips. Shells are added individually. A firing input finishes
the current insertion, closes the reload, and fires; switching or melee cancels
the reload without later transferring ammunition. Ammo transfers currently
occur at the end of each stage, rather than at the separate native add-time
within that stage.

## Knife reconstruction

| Action | Original asset |
| --- | --- |
| Standard blade | `viewmodel_knife` |
| Standard swipe/stab | `viewmodel_M4m203_knife_melee_1` / `_2` |
| Bowie blade | `viewmodel_knife_bowie` |
| Bowie swipe/stab | `viewmodel_bowie_slash` / `viewmodel_bowie_stick` |
| Blade attachment | Dempsey arms' `tag_knife_attach` |

V plays a swipe when no enemy is in reach and the stab clip when one is in
reach. The same action lowers the gun, animates the hand and attached knife,
then restores the weapon. Damage is evaluated once after the definition's
0.05-second swipe delay or 0.15-second stab delay, with a fresh range and
line-of-sight check. Recovery lasts long enough to complete the source clip.
The swing blocks shooting, reload, grenades and switching. Standard damage is
150; Bowie damage is 1,000, correcting the previous 1,150 approximation.
Native auto-lunge movement is not implemented.

## Resident audio recovery

`.tools/extract_resident_audio.py` reads `common_zombie.ff` and
`zombie_theater.ff`, inflates their `IWffu100` streams, and validates inline
60-byte `LoadedSound` records against the local T5 layout. Inline names are
followed by a seek table and audio payload; virtual block alignment must not
be mistaken for file padding.

For WMA records, the extractor reconstructs an xWMA `RIFF` container using
`fmt `, `dpds`, and `data` chunks. Packet size is payload length divided by seek
entry count. Decoding trims by sample count and resets timestamps, preserving
the tails that time-based trimming discarded. Every selected record must
decode without FFmpeg errors, and FFprobe checks the output.

There are 401 recovered resident weapon cues in addition to the 19 existing
streamed cues. The manifest and `artifacts/resident-audio/report.json` retain
the fastfile name, source path, decompressed offset, payload SHA-256, native
duration, decoded duration, rate, channels and decoder version. Native whoosh,
body impact and hard-surface knife sounds, Bowie sounds, magazine/bolt foley,
and player shots for 16 of the 18 weapons are connected. Commando and SPAS-12
shots still use the existing fallback; their original alias-to-shared-sample
mapping has not been recovered. Complete native sound-alias mixing, pitch
variation, spatial filtering and every secondary layer remain outside this
pass.

The existing `build:audio` and rebuild command now include resident extraction.
The asset builder exports 301 clips, both knives, and the recovered action
settings. No original fastfile or IWD is modified.

External format references: [OpenAssetTools T5 structures](https://github.com/Laupetin/OpenAssetTools/blob/main/src/Common/Game/T5/T5_Assets.h),
[compiled XAnim reader](https://github.com/Laupetin/OpenAssetTools/blob/main/src/ObjLoading/XAnim/CompiledXAnimLoader.cpp),
and [FFmpeg's xWMA demuxer](https://github.com/FFmpeg/FFmpeg/blob/master/libavformat/xwma.c).

## Verification

- `npm test`: 11 rule checks, including melee exclusion, shell insertion,
  interruption, ammo conservation and Speed Cola.
- `npm run test:presentation`: 122 browser checks with hip, ADS, reload,
  sprint and knife screenshots in `artifacts/presentation`, plus decoded audio
  waveform checks and actual native-cue playback.
- `npm run test:melee`: 14 in-game checks covering input, delayed damage,
  recovery, missed swings, reload cancellation, Bowie damage and playback.
- `npm run test:weapons`: all 18 weapons load, fire and reload in the map.
- Existing gameplay and extras checks exercise the surrounding game loop.

The screenshots and controlled tests validate this implementation; they are
not an uninterrupted human survival playthrough or a frame-by-frame native
engine comparison.
