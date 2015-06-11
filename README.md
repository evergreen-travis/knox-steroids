# knox-steroids

![Last version](https://img.shields.io/github/tag/Kikobeats/knox-steroids.svg?style=flat-square)
[![Build Status](http://img.shields.io/travis/Kikobeats/knox-steroids/master.svg?style=flat-square)](https://travis-ci.org/Kikobeats/knox-steroids)
[![Dependency status](http://img.shields.io/david/Kikobeats/knox-steroids.svg?style=flat-square)](https://david-dm.org/Kikobeats/knox-steroids)
[![Dev Dependencies Status](http://img.shields.io/david/dev/Kikobeats/knox-steroids.svg?style=flat-square)](https://david-dm.org/Kikobeats/knox-steroids#info=devDependencies)
[![NPM Status](http://img.shields.io/npm/dm/knox-steroids.svg?style=flat-square)](https://www.npmjs.org/package/knox-steroids)
[![Gittip](http://img.shields.io/gittip/Kikobeats.svg?style=flat-square)](https://www.gittip.com/Kikobeats/)

> A S3 knox library with steroids.

## Install

```bash
npm install knox-steroids --save
```

## Usage

```js
var knoxSteroids = require('knox-steroids');
var S3Client = new knoxSteroids({
  key: 'yourkey',
  secret: 'yoursecretkey',
  bucket: 'yourbucket'
});
```

## API

The same knox methods and:

* .listFiles
* .deleteFolders
* .deleteFolder
* .isEmpty
* .putGzipFile
* .putJSON
* .putGzip
* .getGzip
* .getJSONGzipped
* .getJSON

## License

MIT © [Kiko Beats](http://www.kikobeats.com)
