FROM node:22

WORKDIR /app

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm install

COPY . .

RUN npm install -g serve

RUN node build full

RUN cp play.pokemonshowdown.com/index-new.html play.pokemonshowdown.com/index.html

CMD ["sh", "-c", "serve -s play.pokemonshowdown.com -l $PORT"]
