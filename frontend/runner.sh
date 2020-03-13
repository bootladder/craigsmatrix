set -e

printf "$(cat tests-templates/JsonDecodeTest.tmpl.elm)" "$(cat ../example.json)" > tests/JsonDecodeTest.elm
printf "$(cat src-templates/Main.tmpl.elm)" "$(cat ../example.json)" > src/Main.elm
elm-test

elm make src/Main.elm --output main.js
