'use strict'

os           = require 'os'
knox         = require 'knox'
zlib         = require 'zlib'
async        = require 'async'
Args         = require 'args-js'
concatStream = require 'concat-stream'

DEFAULT =
  headers: {}
  sort: null
  map: (file) -> file.Key

prefixPath = (filePath) ->
  filePath = '/' + filePath if filePath.charAt(0) isnt '/'
  filePath

postfixPath = (filePath) ->
  filePath += '/' if filePath.charAt(filePath.length - 1) isnt '/'
  filePath

stringify = (something) ->
  return something if typeof something is 'string'
  return something.toString() if typeof something is 'number'
  JSON.stringify(something, null, 2) + os.EOL

module.exports = class knoxSteroids extends knox

  constructor: (options) ->
    super options
    this

  listFiles: ->
    args = Args([
      [
        { filename : Args.STRING | Args.Required }
        { filename : Args.INT    | Args.Required }
      ]
      { mapFn    : Args.FUNCTION | Args.Optional, _default : DEFAULT.map  }
      { sortFn   : Args.FUNCTION | Args.Optional, _default : DEFAULT.sort }
      { cb       : Args.FUNCTION | Args.Required                          }
      ], arguments)

    args.filename = stringify args.filename
    @list prefix: args.filename, (err, data) ->
      return args.cb err if err
      fileNames = data.Contents.map args.mapFn
      args.cb null, fileNames.sort args.sortFn

  deleteFolder: =>
    args = Args([
      [
        { filename : Args.STRING | Args.Required }
        { filename : Args.INT    | Args.Required }
      ]
      { cb       : Args.FUNCTION | Args.Required }
      ], arguments)

    args.filename = stringify args.filename
    @listFiles args.filename, (err, filenames) =>
      return args.cb err if err
      @deleteMultiple filenames, args.cb

  deleteFolders: ->
    args = Args([
      { filenames : Args.ARRAY    | Args.Required }
      { cb       : Args.FUNCTION | Args.Required }
      ], arguments)

    async.each args.filenames, @deleteFolder, args.cb

  isEmpty: ->
    args = Args([
      [
        { filename : Args.STRING | Args.Required }
        { filename : Args.INT    | Args.Required }
      ]
      { mapFn    : Args.FUNCTION | Args.Optional }
      { sortFn   : Args.FUNCTION | Args.Optional }
      { cb       : Args.FUNCTION | Args.Required }
      ], arguments)

    args.filename = stringify args.filename
    @listFiles args.filename, args.mapFn, args.sortFn, (err, files) ->
      return args.cb err if err
      args.cb null, files.length == 0, files

  putGzip: ->
    args = Args([
      [
        { data : Args.STRING | Args.Required }
        { data : Args.OBJECT | Args.Required }
      ]
      [
        { filename : Args.STRING | Args.Required }
        { filename : Args.INT    | Args.Required }
      ]
      { headers  : Args.OBJECT   | Args.Optional, _default : DEFAULT.headers }
      { cb       : Args.FUNCTION | Args.Required                             }
      ], arguments)

    args.data = stringify args.data
    args.filename = prefixPath stringify(args.filename)
    args.headers['Content-Encoding'] = 'gzip'

    buffer = new Buffer args.data
    zlib.gzip buffer, (err, encoded) =>
      @putBuffer encoded, args.filename, args.headers, (err, res) ->
        return args.cb err if err
        args.cb res.statusCode != 200, res

  putGzipFile: ->
    args = Args([
      [
        { src : Args.STRING | Args.Required }
        { src : Args.INT    | Args.Required }
      ]
      [
        { filename : Args.STRING | Args.Required }
        { filename : Args.INT    | Args.Required }
      ]
      { headers  : Args.OBJECT   | Args.Optional, _default : DEFAULT.headers   }
      { cb       : Args.FUNCTION | Args.Required                               }
      ], arguments)

    args.src = prefixPath(stringify args.src)
    args.filename = prefixPath stringify(args.filename)
    @putFile args.src, args.filename, args.headers, (err, res) ->
      return args.cb err if err
      args.cb res.statusCode != 200, res

  putJSON: ->
    args = Args([
      [
        { data : Args.STRING | Args.Required }
        { data : Args.OBJECT | Args.Required }
      ],
      [
        { filename : Args.STRING | Args.Required }
        { filename : Args.INT    | Args.Required }
      ]
      { headers  : Args.OBJECT   | Args.Optional, _default : DEFAULT.headers }
      { cb       : Args.FUNCTION | Args.Required                             }
      ], arguments)

    args.data = stringify args.data
    args.filename = prefixPath stringify(args.filename)
    buffer = new Buffer args.data
    @putBuffer buffer, filename, headers (err, rest) ->
      return args.cb err if err
      args.cb res.statusCode != 200, res

  getJSON:  ->
    args = Args([
      [
        { filename : Args.STRING | Args.Required }
        { filename : Args.INT    | Args.Required }
      ]
      { headers  : Args.OBJECT   | Args.Optional, _default : DEFAULT.headers }
      { cb       : Args.FUNCTION | Args.Required                             }
      ], arguments)

    args.filename = prefixPath stringify(args.filename)

    @getFile args.filename, args.headers, (err, res) ->
      return args.cb err if err
      res.pipe concatStream (buffer) -> args.cb null, JSON.parse buffer

  getGzip: =>
    args = Args([
      [
        { filename : Args.STRING | Args.Required }
        { filename : Args.INT    | Args.Required }
      ]
      { headers  : Args.OBJECT   | Args.Optional, _default : DEFAULT.headers }
      { cb       : Args.FUNCTION | Args.Required                             }
      ], arguments)

    args.filename = prefixPath stringify(args.filename)

    @getFile args.filename, args.headers, (err, res) ->
      return args.cb err if err
      res.pipe concatStream (buffer) -> zlib.gunzip buffer, args.cb

  getJSONGzipped: (filename, headers, cb) ->
    args = Args([
      [
        { filename : Args.STRING | Args.Required }
        { filename : Args.INT    | Args.Required }
      ]
      { headers  : Args.OBJECT   | Args.Optional, _default : DEFAULT.headers }
      { cb       : Args.FUNCTION | Args.Required                             }
      ], arguments)

    args.filename = prefixPath stringify(args.filename)
    @getGzip args.filename, args.headers, (err, decoded) ->
      args.cb err, JSON.parse decoded
