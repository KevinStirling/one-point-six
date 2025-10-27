FROM debian:bullseye-slim

# Install required 32-bit dependencies for HLDS
RUN dpkg --add-architecture i386 && \
    apt update && \
    apt install -y --no-install-recommends \
    lib32gcc-s1 \
    lib32stdc++6 \
    curl unzip bash ca-certificates && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Working directory
WORKDIR /cs16

ENV GAME_PORT=27017
ENV CLIENT_PORT=27007
ENV TV_PORT=27022
ENV MAX_PLAYERS=16

# Start the server
CMD ["bash", "-c", "./hlds_run -game cstrike -port $GAME_PORT -clientport $CLIENT_PORT -sourcetvport $TV_PORT +map de_dust2 +maxplayers $MAX_PLAYERS"]

