# The Mystical Magic Terrence 2 Editor
This is a Godot 4.7 plugin that transforms the Godot editor into a fully featured editor for The Mystical Magic Terrence 2 and the accompanying Terrence Engine for Nintendo Wii.

### The engine is currently in a heavy WIP state and not ready for public use. I've simply open sourced it... because I just felt like it lmao

## Setup
This section assumes you are on Windows. I don't exactly know how to use Linux, so you're on your own there, pal.
1. Download or clone this repository.
2. Install [Godot 4.7](https://godotengine.org/download/archive/4.7-stable/).
3. Install [devkitpro](https://github.com/devkitPro/installer/releases) for Wii, and build and install [GRRLIB](https://github.com/GRRLIB/GRRLIB).
4. Download [Dolphin Emulator](https://dolphin-emu.org). To run it directly from the editor, you will need to add it to your PATH encironment variable.
5. Download and install [Haxe](https://haxe.org).
6. Run the following Haxe command in the command prompt to install reflaxe/cpp:
```
haxelib git reflaxe.cpp https://github.com/SomeRanDev/reflaxe.CPP
```
7. Copy the [template project](https://github.com/theresaway/terrence-template?tab=readme-ov-file).
8. Clone it into ``game``:
```
git clone (your repo) game
```
9. Open the project in the Godot editor.

And you should be all good to go!

## Building
Building is relatively straightforward. See the Terrence menu in the top right for options.

<img width="296" height="51" alt="image" src="https://github.com/user-attachments/assets/cda52c9f-0bfc-4abc-8874-09940a4dbe00" />

## Credits
[The GRRLib team](https://github.com/GRRLIB/GRRLIB) - Made the GRRLib library (what did you think they made?)

[Godot Developers](https://github.com/godotengine/godot.git) - Also self-explanatory.

[SomeRanDev](https://github.com/SomeRanDev) - For Reflaxe.CPP.

Bob - yeah

## License
Terrence Editor and Terrence Engine are licensed under the MIT license, meaning you can do whatever. Credit would be much appreciated, however.
