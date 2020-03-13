set -e

printf "$(cat tests-templates/JsonDecodeTest.tmpl.elm)" "$(cat ../data/example.json)" > tests/JsonDecodeTest.elm
elm-test

elm make src/Main.elm --output main.js
