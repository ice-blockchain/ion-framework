#!/bin/bash

printf "\e[33;1m%s\e[0m\n" 'Pre-Push'

# Format Code
printf "\e[33;1m%s\e[0m\n" '=== Format Code ==='
melos run 4mat
if [ $? -ne 0 ]; then
  printf "\e[31;1m%s\e[0m\n" '=== Format Code changes ==='
  exit 1
fi
printf "\e[33;1m%s\e[0m\n" 'Finished running Format Code'
printf '%s\n' "${avar}"

# Generate Code
printf "\e[33;1m%s\e[0m\n" '=== Generate Code ==='
scripts/generate_code.sh
if [ $? -ne 0 ]; then
  printf "\e[31;1m%s\e[0m\n" '=== Generate Code error ==='
  exit 1
fi
printf "\e[33;1m%s\e[0m\n" 'Finished running Generate Code'
printf '%s\n' "${avar}"

# Generate Locales
printf "\e[33;1m%s\e[0m\n" '=== Generate Locales ==='
scripts/generate_locales.sh
if [ $? -ne 0 ]; then
  printf "\e[31;1m%s\e[0m\n" '=== Generate locales error ==='
  exit 1
fi
printf "\e[33;1m%s\e[0m\n" 'Finished running Generate Locales'
printf '%s\n' "${avar}"

# Check License
printf "\e[33;1m%s\e[0m\n" '=== Check License ==='
scripts/license_check.sh
if [ $? -ne 0 ]; then
  printf "\e[31;1m%s\e[0m\n" '=== Check License error ==='
  exit 1
fi
printf "\e[33;1m%s\e[0m\n" 'Finished running Check License'
printf '%s\n' "${avar}"

# Flutter Analyzer
printf "\e[33;1m%s\e[0m\n" '=== Running Flutter analyzer ==='
melos run analyze
if [ $? -ne 0 ]; then
  printf "\e[31;1m%s\e[0m\n" '=== Flutter analyzer error ==='
  exit 1
fi
printf "\e[33;1m%s\e[0m\n" 'Finished running Flutter analyzer'
printf '%s\n' "${avar}"

# Run Tests
printf "\e[33;1m%s\e[0m\n" '=== Run Tests ==='
melos run test
if [ $? -ne 0 ]; then
  printf "\e[31;1m%s\e[0m\n" '=== Run Tests error ==='
  exit 1
fi
printf "\e[33;1m%s\e[0m\n" 'Finished running Run Tests'
printf '%s\n' "${avar}"

# If we made it this far, the commit is pushed
exit 0
