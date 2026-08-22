# rocketchat-railway

Wrapper images behind the Railway Rocket.Chat template.

- `rocketchat/` — Rocket.Chat 7.10.0 pinned by digest, literal settings baked in
  (no blank required variables on the deploy form), open registration closed to
  Secret URL.
- `mongo/` — MongoDB 8.0.12 as a **single-node replica set with keyfile auth**.
  Rocket.Chat needs change streams; on a standalone mongod the server still boots
  and passes a healthcheck while `$changeStream` fails on a loop forever.

The replica set cannot be initiated by the stock mongo entrypoint: a member that
has not been initiated refuses writes, so the root user has to be created on a
standalone instance first. `mongo/entrypoint.sh` does that once, then starts the
real server with `--replSet` and initiates it against `MONGO_RS_HOST`.
