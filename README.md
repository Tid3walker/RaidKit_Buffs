# RaidKit - Buffs & Consumables

**See which consumables and buffs are missing, and how close you are to the 32-buff limit.**

A World of Warcraft **Classic Era** addon. It puts your raid consumables and buffs on one configurable bar: missing
buffs are gray, active ones are in color with their remaining time, and a Ctrl+click uses the item.

**Try it in your browser:** [interactive preview](https://tid3walker.github.io/RaidKit_Buffs/) (bar and options
window, no game needed).

## Download and install

**Download the zip from [Releases](https://github.com/Tid3walker/RaidKit_Buffs/releases/latest)** (the file
`RaidKit_Buffs-<version>.zip` under "Assets").

1. Unzip it into `World of Warcraft\_classic_era_\Interface\AddOns\`.
2. You should now have the folder `Interface\AddOns\RaidKit_Buffs\` with `RaidKit_Buffs.toc` directly inside.
3. Restart the game (a `/reload` is not enough for a new addon).

> Do **not** use the green "Code > Download ZIP" button. That zip contains a folder named `RaidKit_Buffs-main`,
> and the game does not load an addon whose folder name does not match its `.toc` file.

**With git:** run this inside `Interface\AddOns\`, later update with `git pull`:

```
git clone https://github.com/Tid3walker/RaidKit_Buffs.git
```

## Highlights
- **Remove unwanted buffs with one click** - even in combat. Intellect on a warrior, costumes, transformations: they
  are collected in their own row, and one click clears them all to free up buff slots.
- **The bar changes color as the 32-buff limit fills up** (4 slots free = yellow ... full = red), so you can make
  room before an expensive elixir gets pushed off. A loss alarm tells you when a consumable vanished early.
- **Cheaper alternatives already set up:** many consumables come with a fallback (Elixir of the Mongoose -> Greater
  Agility, Juju Power -> Elixir of Giants ...). Whatever you have in your bags is used.
- Weapon enchants, world buffs, raid buffs, your own class buffs and an optional mount icon.
- Can replace the default buff frame (never, always, in a party, in a raid).
- Options window with drag & drop, a catalog of 200+ Classic Era consumables and templates for every class.
- Profiles with export and import, e.g. to share a setup with your guild.

## Commands
| Command | Effect |
|---------|--------|
| `/rkb` or `/rkbc` | Open or close the options |
| `/rkb show` / `hide` / `toggle` | Show, hide or toggle the bar (works in macros) |
| `/rkb profile <name>` | Load a saved profile |
| `/rkb reset` | Move the bar back to its default position |

**Moving the bar:** Shift+drag. **Options:** Shift+right-click on the bar.

## Languages
English, German, French and Spanish. The addon follows your game client's language; you can change it in the options.

## Bug reports
Open the options (`/rkb`), go to the **Info** tab and click **Bug report...**. Copy the text (Ctrl+C) and open an
[issue](https://github.com/Tid3walker/RaidKit_Buffs/issues) with it and a short description of what happened. The
report contains no character or realm names.

## License and credits
All rights reserved. You may download and use the addon; please do not redistribute modified copies.

- Sound "Noooh!" by jorickhoofd, [freesound.org/s/180350](https://freesound.org/s/180350/), licensed under
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Used unchanged.
- Sound "Retro video game sfx - Fail" by OwlStorm, [freesound.org/s/404743](https://freesound.org/s/404743/) (CC0).
- Icons and game sounds by Blizzard Entertainment. World of Warcraft is a trademark of Blizzard Entertainment. This
  addon is not affiliated with Blizzard.
