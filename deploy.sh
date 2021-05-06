#!/bin/bash

set -xe

cd assets
npx tailwindcss-cli@latest build -o css/tailwind.css

cd ..
git push gigalixir main