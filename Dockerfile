
FROM node:22

WORKDIR /app

RUN apt-get update \
    && apt-get install -y git \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./

RUN npm install

COPY . .

RUN npm install -g serve

# Pull your custom server repository.
RUN rm -rf caches/pokemon-showdown \
    && git clone --depth 1 \
        https://github.com/Cade-Spaulding/pokemon-showdown-SlotShowdown.git \
        caches/pokemon-showdown \
    && node build full --no-update

# Verify Struggly and Shirkuroo in generated client data.
# Also print Chromon and Shirkuroo's Champions tier for debugging.
RUN node -e '\
const assert = require("node:assert/strict"); \
const path = "./play.pokemonshowdown.com/data/"; \
const dex = require(path + "pokedex.js").BattlePokedex; \
const index = require(path + "search-index.js").BattleSearchIndex; \
const tables = require(path + "teambuilder-tables.js").BattleTeambuilderTable; \
console.log("Shirkuroo:", dex.shirkuroo); \
console.log("Chromon:", dex.chromon); \
console.log("Champions tier:", tables.champions?.overrideTier?.shirkuroo); \
assert.equal(dex.struggly?.name, "Struggly"); \
assert.equal(dex.shirkuroo?.name, "Shirkuroo"); \
assert.ok(index.some(e => e[0] === "shirkuroo" && e[1] === "pokemon")); \
'

# Restore client index page.
RUN cp play.pokemonshowdown.com/caches/index-old.html \
    play.pokemonshowdown.com/index.html

# Install custom client configuration.
RUN rm -f play.pokemonshowdown.com/config/config.js \
    && cp config/config.js play.pokemonshowdown.com/config/config.js

CMD ["sh", "-c", "serve -s play.pokemonshowdown.com -l $PORT"]
