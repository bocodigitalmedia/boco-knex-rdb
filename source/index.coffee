configure = (dependencies = {}) ->
  {snakeCase, camelCase, ObjectSourceMap, Bluebird, WritableStream, TransformStream} = dependencies

  if typeof require is 'function'
    snakeCase ?= require('lodash').snakeCase
    camelCase ?= require('lodash').camelCase
    ObjectSourceMap ?= require('boco-object-source-map').ObjectSourceMap
    Bluebird ?= require "bluebird"
    TransformStream ?= require("stream").Transform
    WritableStream ?= require("stream").Writable

  class DataMapperObjectSourceMap extends ObjectSourceMap
    defaultResolver: (source, key) -> source[snakeCase(key)]

  class DataMapperRecordSourceMap extends ObjectSourceMap
    defaultResolver: (source, key) -> source[camelCase(key)]

  class TableGateway
    table: null
    knex: null

    constructor: (props) ->
      @[key] = val for own key, val of props

    createIdentityParameters: (identifier) ->
      return id: identifier unless typeof identifier is 'object'
      return id: identifier.id

    executeQuery: (query, args..., done) ->
      Bluebird.try ->
        [{transaction} = {}] = args[0] if args.length
        query = query.transacting(transaction) if transaction?
        return query
      .done done.bind(null, null), done

    createCursor: (query, args..., done) ->
      [{transaction} = {}] = args[0] if args.length
      query = query.transacting(transaction) if transaction?
      new Cursor stream: query.stream()

    insert: (record, args..., done) ->
      query = @knex(@table).insert(record)
      @executeQuery query, args..., (error, insertedIds) ->
        return done error if error?
        return done null, insertedIds[0]

    update: (identifier, parameters, args..., done) ->
      identityParameters = @createIdentityParameters identifier
      query = @knex(@table).where(identityParameters).update(parameters)
      @executeQuery query, args..., (error, updatedRecordsCount) ->
        # TODO: RecordNotUpdated
        return done error if error?
        return done "no rows updated" if updatedRecordsCount is 0
        return done null, updatedRecordsCount

    remove: (identifier, args..., done) ->
      identityParameters = @createIdentityParameters identifier
      query = @knex(@table).where(identityParameters).del()
      @executeQuery query, args..., (error, removedRecordsCount) ->
        # TODO: RecordNotRemoved error
        return done error if error?
        return done "record not removed" if removedRecordsCount is 0
        return done null, removedRecordsCount

    read: (identifier, args..., done) ->
      identityParameters = @createIdentityParameters identifier
      query = @knex(@table).where(identityParameters).first()
      @executeQuery query, args..., done

    all: (args...) ->
      query = @knex(@table).select('*')
      @createCursor query, args...

  class DataMapper
    objectSourceMap: null
    recordSourceMap: null
    tableGateway: null

    constructor: (props) ->
      @[key] = val for own key, val of props
      @objectSourceMap ?= new DataMapperObjectSourceMap()
      @recordSourceMap ?= new DataMapperRecordSourceMap()

    defineObjectSourceMap: (definition) ->
      @objectSourceMap.define definition

    defineRecordSourceMap: (definition) ->
      @recordSourceMap.define definition

    constructObject: (properties) ->
      properties

    constructRecord: (properties) ->
      properties

    convertRecord: (record) ->
      properties = @objectSourceMap.resolve record
      @constructObject properties

    convertObject: (object) ->
      properties = @recordSourceMap.resolve object
      @constructRecord properties

    convertObjectParameters: (parameters) ->
      parameters = @recordSourceMap.resolve parameters
      delete parameters[key] for own key, val of parameters when val is undefined
      parameters

    convertObjectIdentifier: (identifier) ->
      return identifier unless typeof identifier is 'object'
      @convertObjectParameters identifier

    createTransformStream: ->
      convertRecord = @convertRecord.bind(@)
      transform = (record, _, done) -> done null, convertRecord(record)
      new TransformStream objectMode: true, transform: transform

    insert: (object, args..., done) ->
      record = @convertObject object
      @tableGateway.insert record, args..., done

    update: (identifier, parameters, args..., done) ->
      identifier = @convertObjectIdentifier(identifier)
      parameters = @convertObjectParameters(parameters)
      @tableGateway.update identifier, parameters, args..., done

    remove: (identifier, args..., done) ->
      identifier = @convertObjectIdentifier(identifier)
      @tableGateway.remove identifier, args..., done

    read: (identifier, args..., done) ->
      identifier = @convertObjectIdentifier(identifier)
      @tableGateway.read identifier, args..., (error, record) =>
        return done error if error?
        return done null, @convertRecord(record)

    all: (args...) ->
      cursor = @tableGateway.all args...
      cursor.stream = cursor.stream.pipe @createTransformStream()
      cursor

  class Cursor
    stream: null

    constructor: (props) ->
      @[key] = val for own key, val of props

    forEach: (callback, done) ->
      write = (record, _, done) -> callback record, done
      writable = new WritableStream objectMode: true, write: write
      writable.on "error", (error) -> done error
      writable.on "finish", -> done()
      @stream.pipe(writable)

    toArray: (done) ->
      records = []
      pushRecord = (record, done) -> done null, records.push(record)
      @forEach pushRecord, (error) ->
        return done error if error
        return done null, records

  BocoKnexRDB =
    configure: configure
    TableGateway: TableGateway
    DataMapper: DataMapper
    Cursor: Cursor
    DataMapperObjectSourceMap: DataMapperObjectSourceMap
    DataMapperRecordSourceMap: DataMapperRecordSourceMap

module.exports = configure()
