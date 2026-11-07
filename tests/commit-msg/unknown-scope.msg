fix(cli): print the usage when no arguments are given

Running the tool without arguments printed nothing and exited 0, so
scripts could not tell it apart from success.
