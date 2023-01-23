Profiling in Go is dead easy. You should do it.

It is always better to have actual empirical evidence showing that your code is slow rather than blindly taking a guess at where it might be slow, or even worse, rewriting a chunk of code to use the fast\* libraries without understanding how it works (I'm looking at you, `fiber`, `fasthttp` and `fastjson`).

There are 2 primary ways to profile a Go application: using a `net/http/pprof` server for long-running applications, or using `runtime/pprof` for short-running applications. This article will provide example copy-paste-friendly snippets of code for both.

## `net/http/pprof`

Insert the following snippet, but **replace `package main` with your package name**.

```go
package main

import (
	"net/http"
	_ "net/http/pprof"
)

func init() {
	go func() {
		println("Serving HTTP at 127.0.0.1:48574 for profiler at /debug/pprof")
		panic(http.ListenAndServe("127.0.0.1:48574", nil))
	}()
}
```

Run the application, then use the following command to profile for 10 seconds:

```sh
go tool pprof http://127.0.0.1:48574/debug/pprof/profile?seconds=10
```

## `runtime/pprof`

Insert the following piece of code into the `main()` function:

```go
{
	f, err := os.Create("/tmp/cpuprofile.pprof")
	if err != nil {
	    log.Fatal("could not create CPU profile: ", err)
	}
	defer f.Close()

	if err := pprof.StartCPUProfile(f); err != nil {
	    log.Fatal("could not start CPU profile: ", err)
	}
	defer pprof.StopCPUProfile()
}
```

Run the application, then use the following command to read the profile:


```sh
go tool pprof /tmp/cpuprofile.pprof
```

---

Interpreting the profiles isn't within the scope of this article; consult the [Profiling Go Programs](https://go.dev/blog/pprof) blog post written by Russ Cox for more information.
