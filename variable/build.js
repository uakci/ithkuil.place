const  fs = require('fs'),
  process = require('process');
process.chdir(__dirname);

// Nothing happens here. As of yet.
// This is where we’re gonna invoke a static page builder or the like.
// The output should go in a separate directory –
// let’s say it’s `/variable/output/`.

fs.mkdirSync("output");
