

1. Go binary compiled for ARM, not x86_64. Confirmation command: `docker run --rm --entrypoint sh ttl.sh/<your-name>:2h -c 'file /app/main'`. It will mention ARM instead of x86-64. Fixable by rebuilding. 

2. Image base layer is the wrong archiutecture. Image layers can have their own architecture, and the manifest alone does not guarantee the executable inside matches the runtime host.

