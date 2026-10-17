<h1 align="center">
  <br>
  <img src="/assets/shared/images/Sollaxx Engine Logo.png" height=350></a>
  <br>
  <b>Sollaxx Engine Classic</b>
  <br>
</h1>
<h3 align="center">
  <b>Sollaxx Engine Classic was made to bring back the old FNF 2021 to make it have modern features.</b>
</h3>

Work in Progress

If you wish to port your Psych Engine mod to Sollaxx Engine it's very easy to do that.

Sollaxx Engine Classic & original are compatible with mods from Psych Engine. Tho some stuff like scripts/events may break. as this is still in experimental. We don't know if Psych 0.5.2h mods and older are compatible but you can try. Psych 0.6.3 mods work the best.


## Gameplay look (We're aiming for the looks of FNF 0.2.5 to 0.2.7 / Week 4 to Week 6 update)
- The gameplay HUD now matches the old looks
  - Score text reads `Score: 150` in plain white, right-aligned under the health bar.
  - The health bar uses the vanilla red/green colors.
  - Rating and combo popups now appear near GF instead of on the HUD. (can be customized)
  - Combo numbers only show at 10 combo or more.
- The time bar has been removed, along with its option.
- Note splashes have been removed completely, including in the chart editor playtest.
- The icon bop is rebuilt to match the old FNF.

## Characters
- **Classic Opponent Idle** (Gameplay Settings, default ON)
  - The opponent only bops while the camera isn't on them.
  - Dad, Pico and Monster loop their idle animation at all times.
  - The opponent goes back to idle the moment the camera moves to a must-hit section.

## Notes
- **CPU Strum Glow** (Gameplay Settings, default OFF)
  - Turn it off and the opponent strums stay still when the CPU hits notes.
- **Broken Hold Notes** (Visuals, default ON)
  - Hold notes before 0.2.7.1 were broken. 
  - That means that the Hold notes weren't clipped at the middle of the strum but above :sob:

## HUD options (Visuals)
- **Old Sollaxx Engine Status Bar** (default OFF)
  - Shows Score | Misses | Accuracy | Rank under the health bar. fun fact this is how Sollaxx Engine 0.1.5 Alpha looked like back in 2022! ;)
  **Sarv Engine HUD** (default OFF)
  - Experience Sarv Engine again came from the Mid-fight Masses mod! (made by Kuroao_Anomal, Mike geno & Dokki.Doodlez) (MID-FIGHT MASSES MOD WILL NEVER BE INCLUDED DO IT YOURSELF.)
- **Sollaxx Engine Watermark** (default ON)
  - Shows a short `SEC <version>` watermark when the status bar is off.
  - With the status bar on, it shows the full `Song Difficulty - Sollaxx Engine Classic <version>`.

## Freeplay
- Freeplay now plays the instrumental of the song you're on, fading in as you scroll, like the old game.
- SPACE-to-listen has been removed.
- The menu music comes back when you leave Freeplay. (It wasn't like that but I kind of prefer it that way.)
- Freeplay's BG will beat if you turn on Sarv Engine HUD and the menu transition will be 4:3

## Technical
- Lua scripts that call `setTimeBarColors` keep working (it now does nothing).
- `timeBarType` always reads as `'Disabled'` in Lua.

## Customization:

if you wish to disable things like *Lua Scripts* or *Video Cutscenes*, you can read over to `Project.xml`

inside `Project.xml`, you will find several variables to customize Sollaxx Engine to your liking

to start you off, disabling Videos should be simple, simply Delete the line `"VIDEOS_ALLOWED"` or comment it out by wrapping the line in XML-like comments, like this `<!-- YOUR_LINE_HERE -->`

same goes for *Lua Scripts*, comment out or delete the line with `LUA_ALLOWED`, this and other customization options are all available within the `Project.xml` file


## Discord:

Join the discord server for the updates/announcements and support
<a href=https://discord.gg/CN7WTE5Mbt>Discord Server Link</a>

# Credits
* SollaxxScape - Main Developer/Programmer
* SollaxxScape - the funni old art style of every 2021 engines
* Kuroao_Anomal - the original creator of Sarv Engine
_____________________________________
