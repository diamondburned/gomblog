Go doesn't have unions, but there's a hack to do it.

Assume we want to create a union type of a node that may be a text node or a
container node that holds text nodes. The following code ([playground](https://play.golang.org/p/isMeZfGvVAN)) demonstrates this:

```go
package main

type node interface {
	node()
}

type textNode struct {
	text string
}

func (textNode) node() {}

type containerNode []node

func (containerNode) node() {}

func main() {
	nodes := []node{
		textNode{"hello"},
		textNode{" "},
		containerNode{
			textNode{"world"},
			textNode{"!"},
		},
	}

	printNodes(nodes)
}

func printNodes(nodes []node) {
	for _, n := range nodes {
		switch n := n.(type) {
		case textNode:
			fmt.Print(n.text)
		case containerNode:
			printNodes([]node(n))
		}
	}
}
```

This trick does in fact give us some type checking during compile time: the
following code

```go
switch node := node.(type) {
case string:
}
```

will error out when built:

```
impossible type switch case: n (type node) cannot have dynamic type string (missing node method)
```
