
FROM node:22

WORKDIR /app

RUN apt-get update \
    && apt-get install -y git \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./

RUN npm install

COPY . .

RUN npm install -g serve

# Pull the custom server and build client data from that exact checkout.
RUN rm -rf caches/pokemon-showdown \
    && git clone --depth 1 \
        https://github.com/Cade-Spaulding/pokemon-showdown-SlotShowdown.git \
        caches/pokemon-showdown \
    && node build full --no-update

# TEST THE ACTUAL SERVER VALIDATOR (not just the existence of entries).
# Fail the Docker build if Shirkuroo has an invalid ability or Tail Glow.
RUN node -e '\
const assert = require("node:assert/strict"); \
const {Dex} = require("./caches/pokemon-showdown/dist/sim/dex"); \
const {TeamValidator} = require("./caches/pokemon-showdown/dist/sim/team-validator"); \
const format = Dex.formats.get("gen9championsvgc2026regmcfakemons"); \
assert.ok(format.exists, "Missing Fakemons format"); \
assert.equal(format.mod, "championsfakemons", "Fakemons format uses the wrong mod"); \
const dex = Dex.forFormat(format); \
const species = dex.species.get("shirkuroo"); \
assert.equal(species.name, "Shirkuroo"); \
assert.equal(species.isNonstandard, null, "Shirkuroo is nonstandard in the Fakemons mod"); \
assert.ok(Object.values(species.abilities).includes("Light And Dark")); \
assert.equal(dex.abilities.get("lightanddark").isNonstandard, null); \
assert.equal(dex.moves.get("tailglow").isNonstandard, null); \
assert.ok(dex.species.getLearnsetData("shirkuroo").learnset?.tailglow?.some(s => s.startsWith("9"))); \
const validator = TeamValidator.get(format.id); \
for (const ability of ["Light And Dark", "Triage"]) { \
  const set = {name: "Shirkuroo", species: "Shirkuroo", ability, moves: ["Tail Glow"], level: 50, nature: "Modest", teraType: species.types[0]}; \
  const problems = validator.validateSet(set, {}) || []; \
  assert.deepEqual(problems, [], ability + ": " + problems.join("; ")); \
} \
console.log("PASS: Shirkuroo ability and Tail Glow legality"); \
'

# The client generates its Champions teambuilder tier list from the ordinary
# Champions mod, NOT championsfakemons. Give Shirkuroo a client-side tier so
# that the generic Champions teambuilder does not show it as Illegal.
# The real server legality check above must pass BEFORE this adjustment.
RUN node -e '\
const fs = require("node:fs"); \
const file = "./play.pokemonshowdown.com/data/teambuilder-tables.js"; \
const tables = require(file).BattleTeambuilderTable; \
if (!tables.champions?.overrideTier || !Array.isArray(tables.champions.tiers)) { \
  throw new Error("Generated Champions teambuilder table is missing"); \
} \
fs.appendFileSync(file, "\nexports.BattleTeambuilderTable.champions.overrideTier.shirkuroo = \"OU\";\n" + \
  "if (!exports.BattleTeambuilderTable.champions.tiers.includes(\"shirkuroo\")) " + \
  "exports.BattleTeambuilderTable.champions.tiers.push(\"shirkuroo\");\n"); \
'

# TEST THE GENERATED CLIENT DATA, including its teambuilder tier.
RUN node -e '\
const assert = require("node:assert/strict"); \
const path = "./play.pokemonshowdown.com/data/"; \
const dex = require(path + "pokedex.js").BattlePokedex; \
const index = require(path + "search-index.js").BattleSearchIndex; \
const tables = require(path + "teambuilder-tables.js").BattleTeambuilderTable; \
const abilities = require(path + "abilities.js").BattleAbilities; \
const moves = require(path + "moves.js").BattleMovedex; \
console.log("Shirkuroo:", dex.shirkuroo); \
console.log("Chromon:", dex.chromon); \
console.log("Champions tier:", tables.champions?.overrideTier?.shirkuroo); \
assert.equal(dex.struggly?.name, "Struggly"); \
assert.equal(dex.shirkuroo?.name, "Shirkuroo"); \
assert.ok(index.some(e => e[0] === "shirkuroo" && e[1] === "pokemon")); \
assert.equal(abilities.lightanddark?.name, "Light And Dark"); \
assert.equal(moves.tailglow?.name, "Tail Glow"); \
assert.ok(tables.learnsets?.shirkuroo?.tailglow?.includes("9")); \
assert.equal(tables.champions?.overrideTier?.shirkuroo, "OU"); \
assert.ok(tables.champions.tiers.includes("shirkuroo")); \
console.log("PASS: Generated Fakemon client data and Shirkuroo tier"); \
'

# Restore client index page.
RUN cp play.pokemonshowdown.com/caches/index-old.html \
    play.pokemonshowdown.com/index.html

# Install custom client configuration.
RUN rm -f play.pokemonshowdown.com/config/config.js \
    && cp config/config.js play.pokemonshowdown.com/config/config.js

CMD ["sh", "-c", "serve -s play.pokemonshowdown.com -l $PORT"]
