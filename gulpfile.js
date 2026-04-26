'use strict';

const build = require('@microsoft/sp-build-web');

// Extend supported Node version range to include Node 20
build.rig.nodeSupportedVersionRange =
  '>=12.13.0 <13.0.0 || >=14.15.0 <15.0.0 || >=16.13.0 <17.0.0 || >=18.17.1 <19.0.0 || >=20.0.0 <21.0.0';

build.addSuppression(/Warning - \[sass\]/gi);

const getTasks = build.initialize(require('gulp'));

if (process.argv.indexOf('--ship') !== -1) {
  build.configureWebpack.setConfig({ bundleAnalyzerPlugin: { openAnalyzer: false } });
}

module.exports = getTasks;
