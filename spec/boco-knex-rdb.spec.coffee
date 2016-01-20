$files = {}

describe "boco-knex-rdb", ->

  describe "Usage", ->
    [BocoKnexRDB, knex, record] = []

    beforeEach ->
      BocoKnexRDB = require "boco-knex-rdb"
      knex = require("knex") client: "sqlite3", connection: "test.db"
      record =
        id: "aaeab0c8-201f-4a1b-85bd-f925a01d551c"
        username: "user@example.com"
        full_name: null
        serialized_data: JSON.stringify(foo: "bar")

    it "Let's create a \"users\" table to use for our examples:", (ok) ->
      defineUsersTable = (table) ->
        table.uuid("id").primary()
        table.string("username")
        table.string("full_name")
        table.json("serialized_data")
      
      createUsersTable = ->
        knex.schema.createTableIfNotExists("users", defineUsersTable)
      
      createUsersTable().asCallback (error) ->
        expect(error?).toBe false
        ok()

    describe "Table Gateway", ->
      [gateway] = []

      beforeEach ->
        gateway = new BocoKnexRDB.TableGateway knex: knex, table: "users"

      describe "Inserting a record", ->

        it "Insert a new record by passing in the record data.", (ok) ->
          gateway.insert record, (error, insertedId) ->
            expect(error?).toBe false
            ok()

      describe "Updating a record", ->

        it "Update a record by passing in the identifier, followed by a set of update parameters.", (ok) ->
          parameters =
            username: "john.doe@example.com"
            full_name: "John Doe"
          
          gateway.update record.id, parameters, (error, updateCount) ->
            expect(error?).toBe false
            expect(updateCount).toEqual 1
            ok()

      describe "Reading a record", ->

        it "Read a record by passing in the identifier.", (ok) ->
          gateway.read record.id, (error, result) ->
            expect(error?).toBe false
            expect(result.id).toEqual(record.id)
            expect(result.username).toEqual("john.doe@example.com")
            expect(result.full_name).toEqual("John Doe")
            expect(result.serialized_data).toEqual('{"foo":"bar"}')
            ok()

      describe "Reading all records", ->

        it "Just call `all` to get a `Cursor` for all records", (ok) ->
          cursor = gateway.all()
          cursor.toArray (error, records) ->
            expect(error?).toBe false
            expect(records.length).toEqual(1)
            expect(records[0].id).toEqual record.id
            ok()

    describe "DataMapper", ->
      [usersGateway, mapper, user] = []

      beforeEach ->
        usersGateway = new BocoKnexRDB.TableGateway knex: knex, table: "users"
        mapper = new BocoKnexRDB.DataMapper tableGateway: usersGateway
        mapper.defineObjectSourceMap
          id: null
          username: null
          firstName: (record) -> record.full_name.split(" ")[0]
          lastName: (record) -> record.full_name.split(" ")[1]
          data: ["serialized_data", JSON.parse]
        
        mapper.defineRecordSourceMap
          id: null
          username: null
          full_name: (user) -> [user.firstName, user.lastName].join(" ")
          serialized_data: ["data", JSON.stringify]

      describe "Using the DataMapper", ->

        it "The methods of the DataMapper mimic the underlying TableGateway interface.\nThe only difference being that your model objects are converted to and from records.", (ok) ->
          userId = record.id
          
          mapper.read userId, (error, user) ->
            expect(error?).toBe false
            expect(user.id).toEqual record.id
            expect(user.username).toEqual "john.doe@example.com"
            expect(user.firstName).toEqual "John"
            expect(user.lastName).toEqual "Doe"
            expect(user.data.foo).toEqual "bar"
            ok()
