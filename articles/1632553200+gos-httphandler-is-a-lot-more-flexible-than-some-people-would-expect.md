Go's `http.Handler` is a lot more flexible than some people would expect. Here are
some of my preferred ways of using them.

The article will assume that the router library is [chi][go-chi], because it's a
great library to use. It will also assume that the application being made is
named `bookstore`.

## Handler structs

This is almost always my go-to way for making a subroute, because it groups
routes into its own structure neatly.

```go
package post // import "bookstore.com/http/post"

// Handler is a HTTP handler that serves posts. It implements the http.Handler
// interface.
type Handler struct {
	http.Handler
	provider bookstore.PostProvider
}

func NewHandler(prov bookstore.Provider) *Handler {
	r := chi.NewRouter()
	h := &Handler{
		Handler:  r,
		provider: prov.PostProvider,
	}

	r.Use(middleware.ContentType("application/json"))
	r.Get("/", h.listPost)
	r.Post("/", h.makePost)
	r.Route("/{id}", func(r chi.Router) {
		r.Get("/", h.getPost)

		// comments.NewHandler has to know the post's parameter name.
		r.Mount("/comments", comments.NewHandler(prov.CommentProvider, "id"))
	})

	return h
}

func (h *Handler) listPost(w http.ResponseWriter, r *http.Request) {
	posts := h.provider.AllPosts()
	json.NewEncoder(w).Encode(posts)
}
```

```go
package main

func main() {
	db := initDB()
	prov := sqlprovider.New(db)

	r := chi.NewRouter()
	r.Mount("/post", post.NewHandler(prov))

	log.Fatal("cannot serve:", http.ListenAndServe(":8080", r))
}
```

## Closures

This is probably the least surprising way to write a handler, since it's quite
small and intuitive, but it only really works well for small handlers. Since I
never really have small handlers like these, I never really do this.

```go
package main

func main() {
	db := initDB()
	prov := sqlprovider.New(db)

	jsonMiddleware := middleware.ContentType("application/json")

	r := chi.NewRouter()
	r.With(jsonMiddleware).Get("/help", http.HandleFunc(
		func(w http.ResponseWriter, r *http.Request) {
			help := prov.HelpProvider.Help()
			io.WriteString(w, help)
		},
	))

	log.Fatal("cannot serve:", http.ListenAndServe(":8080", r))
}
```

## Nested Routes

This method is fairly common among [chi][go-chi] users, but it's a method that I
typically try to avoid, because it can become *very* nested and complex. Most
people who use this method usually pass in methods as handlers (like below) or
use it with closures (like above), but both ways can become very cluttered.

```go
package main

func main() {
	db := initDB()
	prov := sqlprovider.New(db)

	jsonMiddleware := middleware.ContentType("application/json")

	r := chi.NewRouter()
	r.Route("/book", func(r chi.Router) {
		bookHandler := bookhandler.New(prov)

		r.Use(jsonMiddleware)
		r.Get("/", bookHandler.ListBooks)
		r.Post("/", bookHandler.MakeBook)

		r.Route("/{id}", func(r chi.Router) {
			r.Get("/", bookHandler.GetBook("id"))

			// We still have to give commentHandler the parameter name used for
			// the book ID.
			commentHandler := commenthandler.New(prov, "id")

			r.Route("/comments", func(r chi.Router) {
				r.Get("/", commentHandler.ListComments)
				r.Post("/reply/{commentID}", commentHandler.Reply("commentID"))
			})
		})
	})

	log.Fatal("cannot serve:", http.ListenAndServe(":8080", r))
}
```

[go-chi]: https://github.com/go-chi/chi
