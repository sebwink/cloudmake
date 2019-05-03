#!/bin/sh

cat pom.xml \
		| tail -n +2 \
		| sed -e 's/ xmlns.*=".*"//g' \
		| sed -e 's/ xsi.*=".*"//g' \
		| xmlstarlet sel  -t -m "/project/version" -v .
