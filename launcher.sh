#!/bin/bash

rm scrapper.log
rm -rf specs

for char in {A..Z}; do
  echo "~ Launching worker for $char."
  nohup bundle exec ./scrapper.rb $char &>> scrapper.log &
done
