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
  table.boolean("active").defaultTo(true)

createUsersTable = ->
  knex.schema.createTableIfNotExists("users", defineUsersTable)

createUsersPromise = createUsersTable()
```

We'll also hold on to a "user" record for later use.

```coffee
record =
  id: "aaeab0c8-201f-4a1b-85bd-f925a01d551c"
  username: "user@example.com"
  full_name: null
  serialized_data: JSON.stringify(foo: "bar")
  active: false
```

Make sure the table was created before continuing...

```coffee
createUsersPromise.asCallback (error, result) ->
  expect(error?).toBe false
  ok()
```


### Table Gateway

```coffee
gateway = new BocoKnexRDB.TableGateway knex: knex, table: "users"
```

#### Modifying record construction

Since knex returns `1` or `0` for booleans, let's override the `constructRecord` method
to return `true` and `false` on our `active` property:

```coffee
gateway.constructRecord = (record) ->
  record.active = Boolean(record.active)
  record
```

#### Inserting a record

Insert a new record by passing in the record data.

```coffee
gateway.insert record, (error, incrementId) ->
  throw error if error?
  expect(incrementId).toBe 1
  ok()
```

#### Updating a record

Update a record by passing in the identifier, followed by a set of update parameters.

```coffee
parameters =
  username: "john.doe@example.com"
  full_name: "John Doe"
  active: true

gateway.update record.id, parameters, (error, updateCount) ->
  throw error if error?
  expect(updateCount).toEqual 1
  ok()
```

#### Reading a record

Read a record by passing in the identifier.

```coffee
gateway.read record.id, (error, result) ->
  throw error if error?
  expect(result.id).toEqual record.id
  expect(result.username).toEqual "john.doe@example.com"
  expect(result.full_name).toEqual "John Doe"
  expect(result.serialized_data).toEqual '{"foo":"bar"}'
  expect(result.active).toEqual 1
  ok()
```

#### Reading all records

Just call `all` to get a `Cursor` for all records

```coffee
cursor = gateway.all()
cursor.toArray (error, records) ->
  throw error if error?
  expect(records.length).toEqual(1)
  expect(records[0].id).toEqual record.id
  ok()
```

#### Finding records with scopes

Define named scopes for your gateway, with each scope
receiving a query pre-bound to select full records from the
table.

The second argument of your scope method will be the value passed
to the scope via the `find` method.

```coffee
gateway.defineScope "isActive", (query, activeState) ->
  query.where active: activeState

gateway.defineScope "withLastName", (query, last) ->
  query.where "full_name", "like", "% #{last}"
```

Call `find` with scopes and their parameters to get a cursor.

```coffee
cursor = gateway.find isActive: true, withLastName: "Doe"

cursor.toArray (error, results) ->
  throw error if error?
  expect(results.length).toBe 1
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
  active: null

mapper.defineRecordSourceMap
  id: null
  username: null
  full_name: (user) -> [user.firstName, user.lastName].join(" ")
  serialized_data: ["data", JSON.stringify]
  active: null
```

#### Using the DataMapper

The methods of the DataMapper mimic the underlying TableGateway interface.
The only difference being that your model objects are converted to and from records.

```coffee
userId = record.id

mapper.read userId, (error, user) ->
  throw error if error?
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

---

The MIT License (MIT)

Copyright (c) 2016 Christian Bradley + Boco Digital Media

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
