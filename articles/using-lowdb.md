# Using lowdb

This article is written for [Fullyhacks 2024](https://fullyhacks.acmcsuf.com).
It is a guide to using [lowdb](https://github.com/typicode/lowdb), a simple
JSON database for small projects.

## What is a database?

A database is a collection of data stored persistently. It allows for storage
and later retrieval of data. Almost all applications require some form of
database to store data.

For example:

  - If you're building Facebook, you would need a database to store
    user profiles and posts.
  - If you're building Discord, you would need a database to store
    user messages and channels.

## What is [lowdb](https://github.com/typicode/lowdb)?

[lowdb](https://github.com/typicode/lowdb) is a very simple JSON-backed
database. This means that the entire database is stored in a single JSON file.
It is very easy to use and is perfect for small projects.

In reality, no one would ever use lowdb for real-world applications. It is
not performant, it is not scalable, and it is not efficient. However, it is
perfect for small projects such as Hackathons.

## How to use [lowdb](https://github.com/typicode/lowdb)

To use lowdb, you need to install it first. You can install it using npm:

``` bash
npm i lowdb
```

Once you have installed lowdb, you can use it in your project. Here is an
example of how to use lowdb in JavaScript:

``` js
const db = await JSONFilePreset("database.json", {
  // Populate our database with a default value:
  users: [],
  posts: [],
});

db.data.users.push({ name: "Alice" });
db.data.posts.push({ body: "Hello, world!", author: "Alice" });
await db.write();

// Find Alice's profile:
console.log(db.data.users.find(u => u.name == "Alice"))

// Find Alice's posts:
console.log(db.data.posts.filter(p => p.author == "Alice"))
```

If you're a fan of TypeScript, you can give your database a schema:

``` ts
export type User = {
  name: string;
}

export type Post = {
  body: string;
  author: string;
}

type Schema = {
  users: User[];
  posts: Post[];
}

const db = await JSONFilePreset<Schema>("database.json", {
  // Populate our database with a default value:
  users: [],
  posts: [],
});
```

That's it\! Go give [lowdb](https://github.com/typicode/lowdb) a try and a
star\!
