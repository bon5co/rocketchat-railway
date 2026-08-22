# MongoDB configured the way Rocket.Chat actually needs it: a single-node replica
# set with keyfile internal auth. A standalone mongod lets Rocket.Chat boot and
# answer /api/info, but every change stream fails with
# "The $changeStream stage is only supported on replica sets", so real-time
# delivery never works.
FROM mongo@sha256:95a98776f273721a295b03098578b06bc10281bb56aa828c77e9f60ecc70b150
COPY entrypoint.sh /usr/local/bin/rc-mongo-entrypoint.sh
RUN chmod +x /usr/local/bin/rc-mongo-entrypoint.sh
ENV MONGO_REPLICA_SET=rs0
EXPOSE 27017
ENTRYPOINT ["/usr/local/bin/rc-mongo-entrypoint.sh"]
ENV MONGO_INITDB_ROOT_USERNAME=mongo
