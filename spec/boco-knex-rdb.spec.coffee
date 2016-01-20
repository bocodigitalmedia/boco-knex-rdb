$files = {}

describe "boco-knex-rdb", ->

  describe "Usage", ->
    [BocoKnexRDB, knex] = []

    beforeEach ->
      BocoKnexRDB = require "boco-knex-rdb"
      knex = require("knex") client: "sqlite3", connection: "test.db"

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
      [TableGateway, gateway, record] = []

      beforeEach ->
        TableGateway = BocoKnexRDB.TableGateway
        gateway = new TableGateway knex: knex, table: "users"
        
        record =
          id: "aaeab0c8-201f-4a1b-85bd-f925a01d551c"
          username: "user@example.com"
          serialized_data: JSON.stringify(foo: "bar")

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
