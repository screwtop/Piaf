#!/bin/sh

# Create the Piaf user database (if necessary).
# What about schema upgrades?  Could/should they ultimately be handled here?  (That's getting pretty comancy for an editor that will probably only ever be used by me!)
SETTINGS_DIR=~/.piaf
mkdir -p $SETTINGS_DIR
DBFILE=$SETTINGS_DIR/data.db
if ! [ -f $DBFILE ]
then
	echo -n "Database file $DBFILE does not exist; creating..."
	echo .exit | sqlite3 $DBFILE
	echo -n "initialising..."
	echo .exit | sqlite3 -batch -bail -init schema.sql $DBFILE
	echo "Done."
fi

