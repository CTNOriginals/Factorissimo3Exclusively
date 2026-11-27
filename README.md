# Factorissimo 3 Exclusively

A scenario where the whole game is played inside a single
[Factorissimo 3](https://mods.factorio.com/mod/factorissimo-2-notnotmelon) factory building.

<!-- TODO: screenshot of the factory floor with the input combinators -->

## Features

- Start inside the biggest factory building, with nothing else in the world
- Resources come in through constant combinators in the void behind the gaps in the factory walls
- Items are fed onto belts, fluids into pipes
- A picker that only offers the basic resources, anything else is cleared from the combinators

## Usage

1. Start a new game from the **Factorissimo 3 Exclusively** scenario
2. Place a belt or pipe on a gap in the factory wall
3. Open the combinator in the void behind it and pick an ore or fluid

Switch the combinator off or clear it to stop the input.

## Configuration

The allowed resources, feed rates and spawn point are in
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

Inside the editor, `/setup-inputs` places an input combinator behind every
wall gap of the factory you are standing in.

## License

BSD 3-Clause, see [LICENSE.md](LICENSE.md)
