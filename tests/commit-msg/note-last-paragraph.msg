fix(server): retry migrations while the database starts

A server without a reachable database now retries instead of exiting.

Note: run the migration first.
