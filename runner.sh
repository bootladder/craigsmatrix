set -e

printf "$(cat tests/JsonDecodeTest.elm.tmpl)" "$(cat example.json)" > tests/JsonDecodeTest.elm
elm-test

elm make src/Main.elm --output main.js
