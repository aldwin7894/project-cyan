FROM redis:alpine

COPY ./redis.conf /usr/local/etc/redis/redis.conf

HEALTHCHECK --interval=10s --timeout=5s --retries=5  \
  CMD ["redis-cli", "ping", "||", "exit", "1"]

CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]
