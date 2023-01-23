`fmt.Scan`, `fmt.Scanf` and `fmt.Scanln` are harmful.

Every time I want to use those APIs, I always find myself having to look up the documentation for their exact behaviors.

The only times I've wanted to use those functions were when my inputs were verified and constant. For example, this was extremely useful for parsing files during Advent of Code.

Most people should use something else. Something like `bufio.Scanner` would be a much better choice *most* of the time. If you want to make a prompt, maybe even check out [readline in Go](https://pkg.go.dev/github.com/chzyer/readline).
