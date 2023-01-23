Using Go contexts as "magical value vaults" can be hard to understand. This article is written to quickly introduce a way to easily grasp it.

(This blog article was rewritten from a previous chat message.)

Given this piece of Go code that uses the [chi](https://github.com/go-chi/chi) router library:

```go
r.Group(func(r *chi.Router) {
    r.Use(auth.Middleware(database))
    r.Route("/super-secret-thing", func(r *chi.Router) {
        r.Get("/", secretthing.Server(database))
    })
})
```

It might be more helpful to imagine this as making a value available to a scope containing all routes inside it:

```
middleware -----------------\
| + /super-secret-thing     |
|   + /super-secret-thing/  |
\---------------------------/
```

We can implement our `auth` package like so:

```go
package auth

// Imports omitted for brevity.

// Middleware constructs an authentication middleware. All routes beneath it must have 
// the right authentication cookie to continue; otherwise, the user is redirected to
// /login.
func Middleware(database *sqlx.DB) func(http.Request) http.Request {
    return func(next http.Request) http.Request {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            account := doAuth(r)
            if account == nil {
                http.Redirect(w, r, "/login", http.StatusSeeOther)
                return
            }

            // Inject the user account information.
            ctx := context.WithValue(r.Context(), accountKey, account)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}

// Account returns the account information from the given context. The context must be
// obtained from a route within the middleware scope.
func Account(ctx context.Context) *Account {
    return context.Value(accountKey).(*Account)
}
```

Notice that the `auth.Middleware` middleware injects a context value into the request that it passes down to the handler beneath it. This is what creates the virtual scope.

All handlers beneath that scope can simply pull out the account information seemingly out of nowhere:

```go
package secretthing

import "github.com/diamondburned/secretproject/internal/http/auth"

// Server creates a new secret thing server using the given database instance.
func Server(database *sqlx.DB) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        account := auth.Account(r.Context())
        io.WriteString(w, "Hello, " + account.Username)
    })
}
```

While this may seem very convenient, always keep in mind that having too many context scopes will eventually be very confusing: the scope is only declared in the route declaration, but the handler, which sits elsewhere, is the one consuming the context. If the user forgets to inject the middleware into the scope, the handler will explode.

Because of this, use of context for this purpose should be kept to a minimum.
