# Factorissimo 3 Exclusively

A scenario where the whole game is played inside a single
[Factorissimo 3](https://mods.factorio.com/mod/factorissimo-2-notnotmelon) factory building.

Inspired by [this video](https://www.youtube.com/watch?v=maxsZF-rsb4).

<!-- TODO: screenshot of the factory floor with the input combinators -->

## Features

- Start inside the biggest factory building, with nothing else in the world
- Resources come in through constant combinators in the void behind the gaps in the factory walls
- Items are fed onto belts, fluids into pipes
- A picker that only offers the basic resources, anything else is cleared from the combinators
- Uranium ore needs sulfuric acid, like mining it does: picking it builds pipes around the combinator to deliver it to
- Oil processing and uranium processing, which normally need the resource mined, are researched by storing it instead
- Crude oil and uranium ore become available once those technologies can be researched

## Usage

1. Start a new game from the **Factorissimo 3 Exclusively** scenario
2. Place a belt or pipe on a gap in the factory wall
3. Open the combinator in the void behind it and pick an ore or fluid

Switch the combinator off or clear it to stop the input.

For uranium ore, also deliver sulfuric acid: pipes are built around the combinator, with a pipe to ground on each side
facing the factory. Connect to either one with a pipe to ground inside the wall. Every ore that comes in uses 1 acid.

### Research

Mining crude oil and uranium ore is impossible in here, so the technologies that need it ask for the resource to be
stored instead. The goal and its progress are shown in the top left while the technology is available:

| Technology         | Goal                                    |
| ------------------ | --------------------------------------- |
| Oil processing     | Store 50,000 crude oil in storage tanks |
| Uranium processing | Store 500 uranium ore in chests         |

The research screen still shows the vanilla requirement, since that text can only be changed for every game.

## Configuration

The allowed resources, feed rates, fluid costs, research goals and spawn point are in
[`shared/config.lua`](src/shared/config.lua).
A game keeps the scripts it was started with, so changes only apply to new games.

## Development

```bash
git clone --recursive https://github.com/CTNOriginals/factorissimo3-exclusively.git
```

- Copy `.env.example` to `.env` and fill in the paths
- Run `make help` to see the available commands

Requires `make`, `git`, `awk`, and `zip` for `make package`.

### Editing the map

The map editor only opens scenarios from the user scenarios folder, and saving
writes its loaded copy of the scripts back there. So the map is edited in a
copy, and only the map files are brought back into `src`:

1. `make edit` copies the scenario to the user scenarios folder
2. Open and save it in the map editor
3. `make pull` copies the saved map back into `src`

Inside the editor, these commands set up the factory you are standing in:

- `/setup-inputs` places an input combinator behind every wall gap
- `/center-power-pole` moves the factory power pole to the middle of the entrance

## AI disclosure

This project was built together with an AI assistant, as one long, continuous back and forth rather than a
single generated result. The idea, the design of each feature and the project structure are my own: I decided
what to build and how it should play, and the AI wrote most of the code to those directions. Every change was
reviewed and tested in game by me, and many were sent back with fixes or a different approach. The map itself,
the balancing and the decisions on what to keep were done by hand.

The AI also did not work from scratch. The project structure, the make tooling (including the log filter) and
the code style all come from my own [Color Coded Combinators](https://github.com/CTNOriginals/ColorCodedCombinators)
mod, and the code here was written to follow it. That way this project builds on my own earlier work rather than
on code taken from others.

## License

BSD 3-Clause, see [LICENSE.md](LICENSE.md)
