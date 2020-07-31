# `/admin/`

This directory is mostly for <abbr title="uakci’s">my</abbr> personal use.
The files here contained are just in case I need to revive the setup somewhere
else. Those are:

* a bootstrap script that’s run on every push (`pull.sh`);
  + *requires git, docker, realpath to run*
* a [webhook](https://github.com/adnanh/webhook) config file (`webhook.json`);
  + *needs supplying a shared secret*
* a systemd unit for running the webhook daemon (`webhook.service`).
