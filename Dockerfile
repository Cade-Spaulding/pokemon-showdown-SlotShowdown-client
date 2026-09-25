FROM node:22

WORKDIR /app

RUN apt-get update \
	&& apt-get install -y git \
	&& rm -rf /var/lib/apt/lists/*

COPY package*.json ./

RUN npm install

COPY . .

RUN npm install -g serve

RUN rm -rf caches/pokemon-showdown && node build full

RUN cp play.pokemonshowdown.com/caches/index-old.html \
	play.pokemonshowdown.com/index.html

RUN rm -f play.pokemonshowdown.com/config/config.js \
	&& cp config/config.js play.pokemonshowdown.com/config/config.js

CMD ["sh", "-c", "serve -s play.pokemonshowdown.com -l $PORT"]
