FROM node:22

WORKDIR /app

RUN apt-get update \
    && apt-get install -y git \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./

RUN npm install

COPY . .

RUN npm install -g serve

RUN rm -rf caches/pokemon-showdown \
    && node build full

RUN rm -f play.pokemonshowdown.com/config/config.js \
    && cp config/config.js play.pokemonshowdown.com/config/config.js

RUN printf '%s\n' \
    '<!doctype html>' \
    '<html>' \
    '<head>' \
    '<meta http-equiv="refresh" content="0; url=/testclient-new.html">' \
    '</head>' \
    '<body></body>' \
    '</html>' \
    > play.pokemonshowdown.com/index.html

CMD ["sh", "-c", "serve play.pokemonshowdown.com -l $PORT"]
