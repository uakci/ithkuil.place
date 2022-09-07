#!/usr/bin/env bash

if values="$(yq eval --front-matter=extract '.pagename,.description,.heading' "$1" 2>/dev/null)"
  then { read -r PAGENAME; read -r DESCRIPTION; read -r HEADING; } <<< "$values"
  else standalone=1; grep '^---$' "$1" && echo >&2 "file $1 seems to contain invalid front matter"
fi

tee <<TEMPLATE
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="$DESCRIPTION">
    <title>$PAGENAME</title>
    <link rel="stylesheet" type="text/css" href="/common.css">
  </head>
  <body>
    <header>
      <h1>$HEADING</h1>
    </header>
    <main>

$(if test "$standalone"
  then tee
  else sed '0,/^---$/d'
fi < "$1" | pandoc --fail-if-warnings)

    </main>
    <footer>
      This website is not associated with the sole creator of Ithkuil, John
      Quijada. For licensing and contact information and how you can contribute
      to this site, please take a look at the <a href="about">about page</a>.
    </footer>
  </body>
</html>
TEMPLATE
