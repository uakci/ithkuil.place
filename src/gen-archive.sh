shopt -s nullglob globstar

capitalize() {
  sed -E 's/-/ /g;s/(^| )./\U&/g' <<< "$1"
}

cat "$1"

for prefix in **/; do
  slashes=$(tr -cd / <<< "/$prefix")
  hashes="${slashes//\//\#}"
  secname="$(basename "${prefix%/}")"

  echo $'\n'"$hashes $(capitalize "$secname") {#$secname}"
  [[ -n "$(echo "$prefix"*?.?*)" ]] || continue
  echo

  # shellcheck disable=sc2012
  for f in "$prefix"*?.?*; do
    core="${f##"$prefix"}"

    extension="${core##*.}"
    core="${core%%.$extension}"

    date="${core: -10}"
    core="${core%%-$date}"

    versionless="${core%%-v[0-9]*}"
    version=
    if [[ ! "$versionless" = "$core" ]]; then
      version="${core##$versionless}"
      core="${core%%$version}"
      version="${version:1}"
    fi

    pre="$(capitalize "$core") "
    link="$version"
    if [[ "$core" = "$(basename "$prefix")" ]]; then pre=; fi
    if [[ -z "$version" ]]; then pre= link="$(capitalize "$core")"; fi

    echo "* $pre[$link]($f) (.$extension, $date)"
  done
done
