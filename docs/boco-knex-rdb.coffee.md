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

### Table Gateway

```coffee
TableGateway = BocoKnexRDB.TableGateway
gateway = new TableGateway knex: knex, table: "users"

record =
  id: "aaeab0c8-201f-4a1b-85bd-f925a01d551c"
  username: "user@example.com"
  serialized_data: JSON.stringify(foo: "bar")
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


[npm]: http://npmjs.org
[github]: http://www.github.com
