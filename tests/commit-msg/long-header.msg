fix(server): retry the migrations while the database container is still starting up

A server without a reachable database now retries instead of exiting.
