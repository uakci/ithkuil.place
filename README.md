# [ithkuil.place](https://ithkuil.place/)

…is a website whose ultimate goal is to become the one and only place
for all things Ithkuil (or at least links to them) to be hosted at:
resources, tools, weblets, and maybe even computer-friendly APIs and
[databases](https://github.com/Philosophical-Language-Group/NILDB). 

## Technical overview

`./build.sh` converts and copies files to `/target/` as needed, then
creates a Docker image (quite aptly tagged `ithkuil.place`). It
requires `docker`, `git`, `pandoc`, and `tree` to run. At the moment,
the Docker container just serves static files with `nginx`; however,
more sophisticated setups are possible and should be easy to
implement.
