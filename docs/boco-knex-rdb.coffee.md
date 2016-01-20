# boco-knex-rdb

![npm version](https://img.shields.io/npm/v/boco-knex-rdb.svg)
![npm license](https://img.shields.io/npm/l/boco-knex-rdb.svg)
![dependencies](https://david-dm.org/bocodigitalmedia/boco-knex-rdb.png)

## Installation

Installation is available via [npm] or [github].

```bash
$ npm install boco-knex-rdb
$ git clone https://github.com/bocodigitalmedia/boco-knex-rdb
```

## Usage

```coffee
BocoKnexRDB = require "boco-knex-rdb"
knex = require("knex") client: "sqlite3", connection: "test.db"
```

Let's create a "users" table to use for our examples:

```coffee
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
```

Let's hold on to a "user" record for use in these examples:

```coffee
record =
  id: "aaeab0c8-201f-4a1b-85bd-f925a01d551c"
  username: "user@example.com"
  full_name: null
  serialized_data: JSON.stringify(foo: "bar")
```

### Table Gateway

```coffee
gateway = new BocoKnexRDB.TableGateway knex: knex, table: "users"
```

#### Inserting a record

Insert a new record by passing in the record data.

```coffee
gateway.insert record, (error, insertedId) ->
  expect(error?).toBe false
  ok()
```

#### Updating a record

Update a record by passing in the identifier, followed by a set of update parameters.

```coffee
parameters =
  username: "john.doe@example.com"
  full_name: "John Doe"

gateway.update record.id, parameters, (error, updateCount) ->
  expect(error?).toBe false
  expect(updateCount).toEqual 1
  ok()
```

#### Reading a record

Read a record by passing in the identifier.

```coffee
gateway.read record.id, (error, result) ->
  expect(error?).toBe false
  expect(result.id).toEqual(record.id)
  expect(result.username).toEqual("john.doe@example.com")
  expect(result.full_name).toEqual("John Doe")
  expect(result.serialized_data).toEqual('{"foo":"bar"}')
  ok()
```

#### Reading all records

Just call `all` to get a `Cursor` for all records

```coffee
cursor = gateway.all()
cursor.toArray (error, records) ->
  expect(error?).toBe false
  expect(records.length).toEqual(1)
  expect(records[0].id).toEqual record.id
  ok()
```

#### Transactions

Pass a `knex` transaction as an option into any method as the last parameter
before the callback to run that method within the transaction:

* `gateway.insert record, {transaction}, done`
* `gateway.update id, parameters, {transaction}, done`
* `gateway.read id, transaction: {transaction}, done`
* `gateway.remove id, {transaction}, done`
* `gateway.all {transaction}`

### DataMapper

The DataMapper acts as a layer over a TableGateway.

```coffee
usersGateway = new BocoKnexRDB.TableGateway knex: knex, table: "users"
mapper = new BocoKnexRDB.DataMapper tableGateway: usersGateway
```

Define the object source map for your records and the objects they represent.
See [boco-object-source-map] for more information on object source maps.

Note that there are default resolvers on both the `recordSourceMap` and `objectSourceMap`
for translating `snakeCase` record keys to `camelCase` object keys, and vice-versa.

```coffee
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
```

#### Using the DataMapper

The methods of the DataMapper mimic the underlying TableGateway interface.
The only difference being that your model objects are converted to and from records.

```coffee
userId = record.id

mapper.read userId, (error, user) ->
  expect(error?).toBe false
  expect(user.id).toEqual record.id
  expect(user.username).toEqual "john.doe@example.com"
  expect(user.firstName).toEqual "John"
  expect(user.lastName).toEqual "Doe"
  expect(user.data.foo).toEqual "bar"
  ok()
```


[npm]: http://npmjs.org
[github]: http://www.github.com
[boco-object-source-map]: http://github.com/bocodigitalmedia/boco-object-source-map
