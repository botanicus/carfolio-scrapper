#!/bin/bash

for char in {A..Z}; do
  result=$(ps aux | grep "ruby ./scrapper.rb $char" | grep -v "grep ruby")
  status=$(test -n "$result" && echo 'Running' || echo 'Finished')
  echo "$char: $status"
done
