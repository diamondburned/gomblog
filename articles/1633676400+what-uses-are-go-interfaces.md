**What uses are Go interfaces, and why should I care?**

Let's go down a shallow rabbit hole and talk about the importance of interfaces
and how it impacts your code not just for unit testing but also to neatly
separate and organize your services.

**Note** that this article is an introduction to another article that I will be
writing shortly after. It is meant to explain why interfaces are important when
structuring packages.

For a tl;dr, scroll to the bottom.

---

It can be hard to grasp a concept without having a realistic and fun example, so
let's make one up.

Let's pretend we know Bob. Bob wants to test his backend application, because
he's so tired of having to run it in an environment and manually firing up his
websites to test it.

Bob's backend uses SQLite and `net/http`. In order to test his backend
application, Bob thought that he has to simultaneously test SQLite and
`net/http` at the same time, because that's what his application was wired up to
do. This makes sense.

However, often times, you don't need to test SQLite and `net/http`, since both of them are battle-tested libraries. You might need to test *your* SQL, though,
but more often than not, you're looking to test your application logic, and the
logic parts don't particularly have to do with the SQL part.

Here, we see a problem: our SQL logic and application logic should be separate
parts of the application, yet our code grouped them together. In other words,
we're tightly coupling them together. Let's fix that.

Let's introduce a concept in object-oriented programming.

> *I know, OOP? I thought that was POOP! Why should I bring POOP into my
> application? I want to write code, not boilerplate!*
> 
> Object-oriented programming often gets a lot of bad rap, but just stick with
> me for a moment.

I want to introduce the concept of *polymorphism*. In a very simple (and almost
incorrect) explanation, polymorphism is describing what we expect a thing to do.
For example, if I have a car, I would expect it to start up its engine and move.
If I have a washing machine, I would expect it to, you know, wash.

Let's translate those two examples to code. Let's say I have a car and a washing
machine. How would it look like in Go?

```go
type Car interface {
	StartEngine() error
	Drive(where string)
}

type WashingMachine interface {
	Wash(clothes []Clothing) error
}
```

**Sidenote** that I'm ignoring the Go interface naming convention in an attempt
to simplify the explanation of this concept. Forget about the names.

Let's say I have a Chevrolet Bolt. That's a car, and we all know that it is one.
Here's how that would look like in Go.

```go
type ChevroletBolt struct {
	motor     MagneticMotor
	batteries []Battery
}

func (b *ChevroletBolt) StartEngine() error {
	return b.motor.start()
}

func (b *ChevroletBolt) Drive(where string) {
	panic("FIXME: missing a driving wheel!")
}
```

Notice that `ChevroletBolt` has 2 methods: `StartEngine` and `Drive`, both of
which look very similar to what we saw in the `Car` interface. In Go, this means
that we can now use a `ChevroletBolt` as a `Car`, like so:

```go
// DriveHome drives the car home.
func DriveHome(car Car) error {
	if err := car.StartEngine(); err != nil {
		return errors.Wrap(err, "engine failure")
	}

	car.Drive(homeAddress)
	return nil
}

chevyBolt := new(ChevroletBolt)
DriveHome(chevyBolt)
```

Simple! The highlight here is that `DriveHome` doesn't need to know what the car
is exactly. It only needs to know that a car can start its engine and drive. In
other words, `DriveHome` requires something that can `StartEngine` and `Drive`,
and that's it.

What does this mean in our backend, then? How is this relevant at all? Well,
remember that the problem with testing our backend was that the logic was too
coupled to the SQL database code. Does it have to? The logic only needs the SQL
database code to store and retrieve data, after all.

If we only need to store and retrieve data, then surely we don't need all of the
SQL code. In fact, we could do that with a JSON flat file. The fact that we know
we can swap out the SQL for something else and it would still make sense tells
us that we can decouple those two things out the same way we did with our
`DriveHome` method. So let's do that.

To give a more concrete example, pretend that Bob's backend serves a bookstore.
No, it's Bob, not Bezos. Bob wants to implement the database that holds his
books in SQLite, so Bob writes his HTTP handlers to call on SQL functions. This
makes sense, but it's not ideal. Why?

Let's step back to the `DriveHome` example for a moment. Pretend that I'm
writing this code for myself, and I own a Chevrolet Bolt. When I think of
driving home, I think of driving home my Chevrolet Bolt, because that's what I
have. This makes sense, so let's rewrite our function.

```go
// DriveHome drives a Chevrolet Bolt home.
func DriveHome(car *ChevroletBolt) error {
	if err := car.StartEngine(); err != nil {
		return errors.Wrap(err, "engine failure")
	}

	car.Drive(homeAddress)
	return nil
}
```

To me, this function is still perfectly usable. I can use it on my Chevrolet
Bolt, and it would just work. But what happens if I want to test it? What if I
have a model car, and I want to try and drive it home? What if I buy a new car?
That's fine, I'll just copy-paste...

Except we don't want to copy-paste this. What if the process of driving home is
full of turns? What if our function is too complicated to copy-paste? What if we
simply don't want to maintain two versions of the same functionality? This is
where you'd think of using an interface.

> Did you know that patterns like these are very common in Go? You probably
> don't even need to understand Go interfaces to spot them! In fact, if you're
> writing a HTTP application, chances are you're already using one.

Let's use another short example here, just to prove my point. Say I have a
function that copies a file into another file. Let's write a function prototype
for that:

```go
func copyFile(dst *os.File, src string) error
```

This is a pretty straightforward function. It expects the destination file to be
copied onto, and it expects the path to the source file. But this is useless to
my HTTP application, because then I would want it to copy the file into my HTTP
response, not another file. I'm working with the web, not with my disk. So what
now?

The answer is simple: you just change it so it works. Really. Notice how both
`*os.File` and `http.ResponseWriter` have a `Write` method. Since `copyFile`
only needs to write, just like how our `DriveHome` function only needs to start
an engine and drive, we can change it as such:

```go
type Writer interface {
	Write(b []byte) (int, error)
}

func copyFile(w Writer, src string) error
```

In fact, this is so common that Go defines a `Writer` interface for us! It's in
package `io`, so let's use that.

```go
func copyFile(w io.Writer, src string) error
```

Now, our `copyFile` can write to anything that can write, and all is well.

Let's go back to Bob's example. Bob's application actually only needs to store
and retrieve data, or in this case, books, so let's change it as such. But
before we do that, let's all agree that each book is identified by its
[ISBN][isbn]. We'll define a type for that in Go. I won't be explaining why we
should, but let's just do it:

```go
// ISBN is the International Standard Book Number.
type ISBN string
```

Let's also agree that a book, being identified by its ISBN, will also have a
title, author, and pages. Here's that in Go:

```go
type Book struct {
	ISBN   ISBN
	Title  string
	Author string
	Pages  []Page
}
```

[isbn]: https://en.wikipedia.org/wiki/International_Standard_Book_Number

Anyway, let's call the thing that stores and retrieves books a *provider*. We
will define methods to store and retrieve them. Here's how it would look like in
Go:

```go
type BookProvider interface {
	Store(Book) error
	Book(isbn ISBN) (*Book, error)
}
```

**Note** that the retrieval method is named `Book`. This is [Go's convention for
a "getter"][getter], or effectively the retrieval method in this case.

[getter]: https://golang.org/doc/effective_go#Getters

Let's say that we had a SQL function that retrieves a book by its ISBN before.
The function takes in the SQL database instance and the ISBN, then returns the
book:

```go
func FindBookByISBN(db *sqlx.DB, isbn ISBN) (*bookstore.Book, error)
```

The HTTP handler directly calls this function, like so:

```go
type bookHandler struct {
	db *sqlx.DB
}

func (h *bookHandler) findBook(w http.ResponseWriter, r *http.Request) {
	isbn := bookstore.ISBN(r.Query().Get("isbn"))

	b, err := FindBookByISBN(h.db, isbn)
	// err check
	// use b
}
```

Since the original problem was that the code was too coupled together, forcing
Bob to include SQL in his test, and that we've agreed on the solution of
decoupling the code, let's see how that looks like.

**Note** that I will be writing seemingly very different HTTP handler code from
what I have before. If you want to know why, see [the earlier article on writing
good HTTP handlers][handlers].

[handlers]: https://blog.arikawa-hi.me/gos-http-handler-is-a-lot-more-flexible-than-some-people-expect

Anyway, let's make our handler use the provider interface instead of directly
using SQL. Here's how that'll look like in Go:

```go
type bookHandler struct {
	books bookstore.BookProvider
}

func (h *bookHandler) findBook(w http.ResponseWriter, r *http.Request) {
	isbn := bookstore.ISBN(r.Query().Get("isbn"))

	b, err := h.books.Book(isbn)
	// err check
	// use b
}
```

Since our handler no longer directly requires a `*sqlx.DB` instance, this means
that we no longer need anything SQL to use the handler. So let's not do that,
but instead, let's write a book provider that can only provide a single book.
Here's how that'll look like:

```go
type singleBookProvider struct {
	book bookstore.Book
}

func (p *singleBookProvider) Book(isbn ISBN) (*bookstore.Book, error) {
	if isbn == p.book.ISBN {
		return &p.book, nil
	}
	return nil, bookstore.ErrBookNotFound
}

func (p *singleBookProvider) Store(bookstore.Book) error {
	return errors.New("cannot store book: singleBookProvider is read only.")
}
```

Notice how we've stubbed our `Store` method. It does nothing. This is fine,
because we don't need it to do anything. Our `findBook` handler only needs to
retrieve a book, so why should we care?

**Note** that idiomatically, you would normally have this handler only require
the `Book` method. As we've subtly seen above, types can implement interfaces
without ever needing to say that it does, so anyone can define interfaces
similar to it. If you don't understand what this means, that's fine; carry on.

Now, with our `singleBookProvider`, we can plug it directly into `bookHandler`
and run it without needing any SQL. Any HTTP request performed will not use any
SQL, and will instead only hit our `singleBookProvider`. But what does this mean
for Bob?

We've shown that the handler is now decoupled from the SQL code so that it no
longer needs a SQL instance in order to work. This means that the logic of the
handler is now decoupled from the SQL's. This means that for Bob, he can now
write HTTP handler tests without needing a working SQL database. Instead, he
could just write stub types for each handler and test that the handlers are
responding with what is expected.

Testing is easy again, and life is good again.

So how exactly should we write the old SQL code? Let's separate that code into
an entirely different package. I won't be going into the reasons why, but keep
in mind that well-decoupled code are easy to separate because they're
well-decoupled.

Here's roughly how that would look like if we spare it a package `sql` inside
`./internal/providers/sql/sql.go`:

```go
package sql

type bookProvider struct {
	*sqlx.DB
}

func NewBookProvider(db *sqlx.DB) bookstore.BookProvider {
	return bookProvider{db}
}

func (p bookProvider) Book(isbn bookstore.ISBN) (*bookstore.Book, error) {
	var book bookstore.Book

	row := p.DB.QueryRow("SELECT FROM books WHERE isbn = ?", string(isbn))
	if err := row.StructScan(&book); err != nil {
		return nil, err
	}

	return &book, nil
}

func (p bookProvider) Store(book bookstore.Book) error {
	_, err := p.DB.Exec(
		"INSERT INTO books (isbn, title, author) VALUES (?, ?, ?)",
		string(book.ISBN), book.Title, book.Author,
	)
	return err
}
```

This has the nice side effect of having our SQL code separated from the HTTP
handler and into neatly organized structures that separate the parts of the SQL
database. How you might choose to split the providers is up to you, but the
concept is the same.

---

Alright, that was long. So what? Bob gets his tests done, but what have we
learned?

Well, we've learned that interfaces just describe the things that we want
something to do. When we have code that needs a certain thing to do something
else, **instead of requiring that exact thing, we can instead write a
description of what we want it to do**. That is basically what interfaces
are for.

So the next time you find yourself needing to mock a SQL database to test, think
twice: do you *really* need to do that? What are you actually testing? Can you
decouple it further?

And knowing when and how to decouple is also very important for organizing
packages. I really cannot stretch this enough. Once you know how to decouple
your code properly so that each component won't hard-depend on each other,
organizing packages suddenly becomes so intuitive. Because your code would've
been separated already, it would be almost effortless.

If you want to know how to structure your packages properly, keep an eye on this
blog. I will be writing one about it very soon. I will post a link on top of
this article, but I won't remove this paragraph. If you're reading this
paragraph and the link is already there, then now you know to scroll up.
