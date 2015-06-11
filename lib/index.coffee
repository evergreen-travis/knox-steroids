'use strict'

zlib  = require 'zlib'
async = require 'async'
knox  = require 'knox'

module.exports = class knoxSteroids extends knox

  constructor: (options) ->
    super options
    this

  listFiles: (filename, mapFn, sortFn, cb) ->

    defaultMapFn = (file) -> file.Key

    if arguments.length == 2
      cb = mapFn
      mapFn = defaultMapFn
      sortFn = null

    mapFn = defaultMapFn if mapFn == null

    filename = filename.toString()
    filename += '/' if filename.charAt(filename.length - 1) != '/'

    @list prefix: filename, (err, data) ->
      return cb err if err
      fileNames = data.Contents.map mapFn
      cb null, fileNames.sort sortFn

  deleteFolders: (filenames, cb) ->
    async.forEach filenames, @deleteFolder, cb

  deleteFolder: (filename, cb) =>
    filename = filename.toString()
    @listFiles filename, (err, filenames) =>
      return cb err if err
      @deleteMultiple filenames, cb

  isEmpty: (filename, cb) ->
    filename = filename.toString()
    @listFiles filename, (err, files) ->
      return cb err if err
      cb null, files.length == 0, files

  putGzipFile: (src, filename, headers, cb) ->
    if arguments.length == 3
      cb = headers
      headers = {}

    src = src.toString()
    filename = filename.toString()

    headers['Content-Type'] = 'application/x-gzip'
    headers['Content-Encoding'] = 'gzip'

    @putFile src, filename, headers, (err, res) ->
      return cb err if err
      cb res.statusCode == 200, res

  putJSON: (data, filename, headers, cb) ->
    if arguments.length == 3
      cb = headers
      headers = {}

    data = JSON.stringify data if typeof data == 'object'
    filename = filename.toString()

    headers['Content-Length'] = Buffer.byteLength(data)
    headers['Content-Type'] = 'application/json'

    req = @put filename, headers
    req.on 'response', (res) -> cb res.statusCode != 200, res
    req.end data

  putGzip: (data, filename, headers, cb) ->
    if arguments.length == 3
      cb = headers
      headers = {}

    filename = filename.toString()

    headers['Content-Type'] = 'application/x-gzip'
    headers['Content-Encoding'] = 'gzip'

    buffer = new Buffer(JSON.stringify(data))

    zlib.gzip buffer, (err, data) =>
      return cb err if err

      headers['Content-Length'] = data.length

      req = @put filename, headers
      req.end data
      req.on 'response', (res) -> cb res.statusCode != 200, res

  getGzip: (opts, filename, headers, cb) ->
    if arguments.length == 2
      cb = headers
      headers = {}
      opts = parseJSON: false

    if arguments.length == 3
      cb = opts
      opts = parseJSON: false

    filename = filename.toString()

    headers['Accept-Encoding:'] = 'gzip'

    @getFile filename, headers, (err, res) ->
      return cb err if err
      buffer = ''
      gunzip = zlib.createGunzip()
      res.pipe gunzip

      gunzip.on 'data', (data) -> buffer += data.toString 'utf8'

      gunzip.on 'end', ->
        result = if opts.parseJSON then JSON.parse buffer else buffer.toString()
        cb null, result

      gunzip.on 'error', (err) -> cb err

  getJSONGzipped: (filename, headers, cb) ->
    if arguments.length == 2
      cb = headers
      headers = {}

    @getGzip parseJSON: true, filename, headers, cb

  getJSON: (filename, headers, cb) ->
    if arguments.length == 2
      cb = headers
      headers = {}

    @getFile filename, headers, (err, res) ->
      buffer = ''
      res.setEncoding 'utf8'

      res.on 'data', (chunk) -> buffer += chunk

      res.on 'end', ->
        buffer = JSON.parse(buffer)
        cb null, buffer

      res.on 'error', (err) -> cb err
