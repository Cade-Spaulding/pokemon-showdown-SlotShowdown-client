FROM node:22

WORKDIR /app

RUN apt-get update \
	&& apt-get install -y git \
	&& rm -rf /var/lib/apt/lists/*

COPY package*.json ./

RUN npm install

COPY . .

RUN npm install -g serve

# Pull YOUR custom server repo so the client build sees Struggly,
# Hyperdrive, your custom formats, Champions data, etc.
RUN rm -rf caches/pokemon-showdown \
	&& git clone --depth 1 \
		https://github.com/Cade-Spaulding/pokemon-showdown-SlotShowdown.git \
		caches/pokemon-showdown \
	&& node build full --no-update

# Make the build fail loudly if Struggly did not enter the generated client data.
RUN grep -qi "struggly" play.pokemonshowdown.com/data/search-index.js \
	|| (echo "ERROR: Struggly is missing from generated search-index.js" && exit 1)

RUN cp play.pokemonshowdown.com/caches/index-old.html \
	play.pokemonshowdown.com/index.html

RUN rm -f play.pokemonshowdown.com/config/config.js \
	&& cp config/config.js play.pokemonshowdown.com/config/config.js

CMD ["sh", "-c", "serve -s play.pokemonshowdown.com -l $PORT"]
