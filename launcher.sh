#!/bin/sh

rm scrapper.log

for char in {A..Z}; do
  echo "~ Launching worker for $char."
  bundle exec ./scrapper.rb $char &>> scrapper.log
done
