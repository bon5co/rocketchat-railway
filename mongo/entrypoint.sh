#!/bin/bash
# Rocket.Chat-ready MongoDB: single-node replica set with keyfile internal auth.
# Railway mounts volumes as uid 0; mongod runs as mongodb, so fix ownership first.
set -euo pipefail

DATA_DIR=${MONGO_DATA_DIR:-/data/db}
KEYFILE=/tmp/mongo-keyfile
RS_NAME=${MONGO_REPLICA_SET:-rs0}
RS_HOST=${MONGO_RS_HOST:-127.0.0.1}
USER=${MONGO_INITDB_ROOT_USERNAME:?MONGO_INITDB_ROOT_USERNAME is required}
PASS=${MONGO_INITDB_ROOT_PASSWORD:?MONGO_INITDB_ROOT_PASSWORD is required}

mkdir -p "$DATA_DIR"
chown -R mongodb:mongodb "$DATA_DIR"

printf '%s' "${MONGO_KEYFILE:?MONGO_KEYFILE is required}" > "$KEYFILE"
chmod 400 "$KEYFILE"
chown mongodb:mongodb "$KEYFILE"

msh() { mongosh --quiet --host 127.0.0.1 --port 27017 "$@"; }

# Phase 1 - first boot only: create the root user on a standalone instance.
# A not-yet-initiated replica set refuses writes, so the user cannot be created
# after --replSet is on; this is why the stock entrypoint cannot do both.
if [ ! -f "$DATA_DIR/.rc-initialized" ]; then
  echo "[init] first boot: creating root user"
  gosu mongodb mongod --dbpath "$DATA_DIR" --bind_ip 127.0.0.1 --port 27017 --fork \
    --logpath /tmp/mongod-init.log
  until msh --eval 'db.adminCommand({ping:1})' >/dev/null 2>&1; do sleep 1; done
  msh admin --eval "db.createUser({user:'$USER',pwd:'$PASS',roles:[{role:'root',db:'admin'}]})" >/dev/null
  gosu mongodb mongod --dbpath "$DATA_DIR" --shutdown
  touch "$DATA_DIR/.rc-initialized"
  echo "[init] root user created"
fi

# Phase 2: initiate / repair the replica set once the real server is up.
(
  until msh -u "$USER" -p "$PASS" --authenticationDatabase admin \
      --eval 'db.adminCommand({ping:1})' >/dev/null 2>&1; do sleep 2; done
  if msh -u "$USER" -p "$PASS" --authenticationDatabase admin \
      --eval 'rs.status().ok' >/dev/null 2>&1; then
    echo "[init] replica set already live; reconfiguring host to $RS_HOST"
    msh -u "$USER" -p "$PASS" --authenticationDatabase admin --eval \
      "var c=rs.conf(); if(c.members[0].host!=='$RS_HOST:27017'){c.members[0].host='$RS_HOST:27017';c.version++;rs.reconfig(c,{force:true});}" >/dev/null || true
  else
    echo "[init] initiating replica set $RS_NAME on $RS_HOST:27017"
    msh -u "$USER" -p "$PASS" --authenticationDatabase admin --eval \
      "rs.initiate({_id:'$RS_NAME',members:[{_id:0,host:'$RS_HOST:27017'}]})" >/dev/null
  fi
  echo "[init] replica set ready"
) &

exec gosu mongodb mongod --dbpath "$DATA_DIR" --replSet "$RS_NAME" \
  --keyFile "$KEYFILE" --ipv6 --bind_ip ::,0.0.0.0 --port 27017 \
  --setParameter diagnosticDataCollectionEnabled=false
