fix(server): retry migrations while the database starts

Note: this only changes startup. A server without a reachable database
now retries instead of exiting, and /ready reports the state.

Requests are refused until the migrations complete.
