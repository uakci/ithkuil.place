#!/usr/bin/env bash
shopt -s nullglob globstar

capitalize() {
  sed -E 's/-/ /g;s/(^| )./\U&/g' <<< "$1"
}

cat "$1"

already_processed_latest=''
for prefix in latest/ **/; do
  if [[ "$prefix" = latest/ ]]; then
    if [[ -z "$already_processed_latest" ]]
    then already_processed_latest=1
    else continue; fi
  fi

  slashes=$(tr -cd / <<< "/$prefix")
  hashes="${slashes//\//\#}"
  secname="$(basename "${prefix%/}")"

  echo $'\n'"$hashes $(capitalize "$secname") {#$secname}"
  [[ -n "$(echo "$prefix"*?.?*)" ]] || continue
  echo

  for f in "$prefix"*?.?*; do
    if link_target="$(readlink "$f")"; then
      core="$(basename "$link_target")"
    else
      core="${f##"$prefix"}"
    fi

    extension="${core##*.}"
    core="${core%%."$extension"}"

    date="${core: -10}"
    core="${core%%-"$date"}"

    versionless="${core%%-v[0-9]*}"
    version=
    if [[ ! "$versionless" = "$core" ]]; then
      version="${core##"$versionless"}"
      core="${core%%"$version"}"
      version="${version:1}"
    fi

    pre="$(capitalize "$core") "
    link="$version"
    if [[ "$core" = "$(basename "$prefix")" ]]; then pre=''; fi
    if [[ -z "$version" ]]; then pre='' link="$(capitalize "$core")"; fi

    echo "* ${pre}[$link]($f) (.$extension, $date)"
  done
done
