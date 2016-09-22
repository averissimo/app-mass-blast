#!/bin/bash
set -e

# Figure out where this script is located.
SELFDIR="`dirname \"$0\"`"
SELFDIR="`cd \"$SELFDIR\" && pwd`"

# Tell Bundler where the Gemfile and gems are.
export BUNDLE_GEMFILE="$SELFDIR/lib/vendor/Gemfile"
unset BUNDLE_IGNORE_CONFIG

cd "$SELFDIR/lib/app"
# Run the actual app using the bundled Ruby interpreter, with Bundler activated.
exec "$SELFDIR/lib/ruby/bin/ruby" -rbundler/setup "$SELFDIR/lib/ruby/bin.real/bundle" exec rake spec
cd "$SELFDIR"
# cp results of tblastn, db and queries
cp -r $SELFDIR/lib/app/output/test_tblastn $SELFDIR/output
mkdir -p $SELFDIR/db_and_queries/test-tblastn-db
mkdir -p $SELFDIR/db_and_queries/test-tblastn-query
cp -r $SELFDIR/lib/app/test/db $SELFDIR/db_and_queries/test-tblastn-db
cp -r $SELFDIR/lib/app/test/tblastn/query/* $SELFDIR/db_and_queries/test-tblastn-query/
