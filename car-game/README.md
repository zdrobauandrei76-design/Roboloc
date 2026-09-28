# Mega Ramp Launch

A Roblox car game built on Frazer's game boilerplate. Players drive off a giant mega ramp, tap at the right moment for a perfect launch, hold nitro to fly further, and earn cash for every meter they fly through eight themed zones. Cash buys upgrades and cars; rebirths reset upgrades for a permanent cash bonus and higher level caps.

<details>
<summary>For AI agents:</summary>

If you're an agent, please refer to [AGENTS.md](AGENTS.md) before making any code changes or install scripts.

</details>

## The game

- **Core loop (about 10 to 40 seconds):** press LAUNCH, tap when the needle is green (up to 1.25x launch speed), hold NITRO in the air, land, collect cash, repeat.
- **Eight zones along one 56,000 m runway:** Meadow, Desert (x1.5), Frost Peaks (x2), Lava Land (x3), Candy Kingdom (x4), Moon Base (x6), Deep Space (x8) and Galaxy's Edge (x12). Every meter pays that zone's multiplier. The lighting changes as you fly through each zone.
- **Progression:** Engine, Nitro and Wings upgrades, 13 cars (9 bought with cash, plus a group car, a daily-streak car, a VIP car and a starter-pack car), and rebirths (+0.5x cash each, plus more upgrade levels).
- **Retention:** 7-day daily streak (day 7 unlocks the Neon Hover), 8 playtime gifts per session, codes, global top-50 leaderboard, in-server leaderstats, server-wide announcements when someone reaches a new zone, and a first-time tutorial.
- **Social and CCU:** up to 12 players launch side by side in their own lanes and see each other fly. Every friend in the server adds +10% cash (up to +40%), Premium adds +10% and group members get +10%. An invite button sits on the HUD. The Auto Launch pass keeps AFK players launching.
- **Monetization:** 4 game passes and 6 developer products (see below). Cash packs scale with the player's best run, so they stay worth buying at every stage.
- **Anti-cheat:** the server re-simulates every flight from the player's inputs, with the same physics code the client uses. It caps rewards by a minimum flight time and validates every request, so exploiters can't fake distances or cash.

Progression pace, from a simulation of an efficient player: Desert at about 1 minute, Frost Peaks about 4 minutes, first rebirth about 12 minutes, Lava Land about 30 minutes, Candy Kingdom about 1 hour, Moon Base about 2 hours, Deep Space about 4 hours, Galaxy's Edge about 7 hours and the finish line about 13 hours. Real players take longer. The 2x Cash pass roughly halves every milestone.

## Setup

1. Install [Aftman](https://github.com/LPGhatguy/aftman), then from this folder run `./scripts/install.ps1`.
2. Run `rojo serve default.project.json --address 127.0.0.1` and connect the Rojo plugin in Studio (`localhost:34873`).
3. **Build the UI, map and cars.** In Studio open **View > Command Bar** and run:

   ```lua
   require(game.ServerStorage.StudioBuild:Clone()).Build()
   ```

   This creates the ScreenGuis in StarterGui, `Workspace.Map`, the car models in `ReplicatedStorage.Assets.Cars` and the lighting. They are ordinary Studio instances saved in your place, so you can restyle them by hand. Running the command again rebuilds and overwrites them. To rebuild one part only, use `.BuildUI()`, `.BuildMap()` or `.BuildCars()`. After Rojo syncs new code, rerun the command; if a change doesn't show up, reopen the place first, because Studio can cache required modules.
4. **Add the sounds (one upload, see [Sounds](#sounds)).**
5. Save the place (**File > Save to Roblox**), then turn on **Game Settings > Security > Enable Studio Access to API Services** so saving works in Studio.
6. Press **Play**.

If the builder warns about StreamingEnabled, turn off **Workspace > StreamingEnabled** in the Properties window. Far zones must stay loaded while cars fly past them at high speed.

## Before publishing

### 1. Create the game passes and developer products

On the Creator Dashboard, create them and paste each ID into `src/shared/Config/Monetization.luau`. Any item left at `Id = 0` is hidden in game automatically.

| Key | Type | What it does | Suggested price |
| --- | --- | --- | --- |
| `DoubleCash` | Game pass | 2x cash forever | 299 R$ |
| `VIP` | Game pass | 1.5x cash, Golden Supercar, [VIP] chat tag | 249 R$ |
| `AutoLaunch` | Game pass | Auto launch, timing and nitro (AFK farming) | 149 R$ |
| `MegaNitro` | Game pass | +50% nitro fuel | 99 R$ |
| `StarterPack` | Product | Rocket Racer, 30 min of 2x cash and a cash bundle. The shop and popup offer it once. | 49 R$ |
| `CashBoost` | Product | 30 min of 2x cash (stacks) | 39 R$ |
| `CashSmall` / `CashMedium` / `CashLarge` / `CashHuge` | Product | Cash worth 10 / 35 / 120 / 400 of the player's best launches | 25 / 79 / 199 / 499 R$ |

The starter pack popup appears once per session after the player's third launch.

### 2. Everything else

- **Group:** create a Roblox group, then set `GroupId` and `GroupName` in `src/shared/Config/GameConfig.luau`. Members get +10% cash and the Police Cruiser from the Codes screen.
- **Codes:** edit `src/server/Services/RewardService/Codes.luau`. The current codes are `LAUNCH`, `NITRO` and `RELEASE`. Set `ExpiresAt` (Unix time) to end one. Put codes in your game description and socials.
- **Max players:** set **Game Settings > Places > Max Players** to 12, matching the 12 launch lanes. More players still work; they share lanes.
- **Music:** pick a free looping track in the Creator Store (Toolbox > Audio > Music), copy its ID and set `MusicId = "rbxassetid://<ID>"` in `src/shared/Config/Sounds.luau`.
- **Store page:** add an icon, thumbnails and a description that lists the codes.

## Sounds

The game has 13 original sound effects made for it: button clicks, panel open, launch engine rev, perfect-launch chime, looping nitro roar, looping wind, landing thump, cash ka-ching, new-zone fanfare, purchase bling, a soft error, the rebirth power-up and a return swoosh. They are packed into one audio file, `assets/sounds/SoundSprite.ogg`, so you only upload once:

1. Upload `car-game/assets/sounds/SoundSprite.ogg` to Roblox: on [create.roblox.com](https://create.roblox.com/dashboard/creations) go to **Creations > Development Items > Audio > Upload Asset**, or in Studio use **View > Asset Manager > Bulk Import**. Upload it under the same owner as the game (your account, or the group if a group owns the game).
2. Copy the new asset's ID.
3. In `src/shared/Config/Sounds.luau`, set `SpriteId = "rbxassetid://<ID>"`. Rojo syncs it; press Play.

Until `SpriteId` is set, the game falls back to a few basic built-in Roblox sounds. Each sound's volume lives in `Config/Sounds.luau`. The same effects are also in `assets/sounds` as separate files; to use one of them instead, upload it and put its ID in that sound's `Id` field.

To change the sounds, edit `tools/sounds.py` and run `python tools/sounds.py` (needs `numpy`, `scipy` and `soundfile`). It rewrites the files in `assets/sounds` and the timings in `src/shared/Config/SoundSprite.luau`. Then upload the new sprite and update `SpriteId`.

## Tuning

Everything lives in frozen tables in `src/shared/Config`:

| File | Controls |
| --- | --- |
| `Flight.luau` | Gravity, launch speed curve, nitro, glide, bounces, ramp time, timing window |
| `Upgrades.luau` | Upgrade costs, cost growth, base level caps and extra levels per rebirth |
| `Cars.luau` | Car prices, speed and cash multipliers, colors and styles |
| `Zones.luau` | Zone start distances, multipliers, ground and lighting |
| `Rewards.luau` | Daily streak, playtime gifts, friend, Premium and group bonuses |
| `GameConfig.luau` | Name, group, rebirth cap, starter offer timing, auto-launch delays |
| `Theme.luau` | UI colors and font (re-run `.BuildUI()` after changing) |
| `Sounds.luau` | Sound sprite ID, music ID, per-sound volumes and overrides |

Car shapes live in `studio/CarModels` (`Kit` has the building blocks, `Bodies` the roadster and closed-cabin bodies, `Specials` the one-off designs). Car colors and stats are in `Cars.luau`; re-run `.BuildCars()` after changing either.

The world is 56,000 m long. A fully upgraded top car with a perfect launch reaches the end. If you raise speeds, extend `WorldLength` in `Track.luau` and rebuild the map.
