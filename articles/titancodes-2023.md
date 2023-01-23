# TitanCodes 2023 Walkthrough (spoilers!)

**Note**: this article contains **spoilers!**.

I'll be using this article to brain-dump my thought process while doing
TitanCodes 2023. A lot of the solutions here assume you already know some Linux
and will heavily utilize Linux tools.

## Validation/Even more secure!

I don't recommend using `pwgen`, but...

```sh
pwgen -c -n -y 14 100 -r "{}[];,.=-\"'\\/\`()<>:|~*-_=+?" | wl-copy
```

## Automation/Bang!

This one is easy if you're on Linux and are using PulseAudio/Pipewire:

```sh
paplay audiofile.wav
```

## Stegonography/order

Steg**a**nography, by the way.

Super easy Bash one-liner:

```sh
cat $(ls | sort -n)
```

`ls` lists all files. `sort -n` sorts all those files, with the `-n` flag
indicating natural number ordering (i.e. 1, 2, 3, 10, 20, 30, ...) as opposed to
lexicographic sorting (i.e. 1, 10, 2, 20, 3, 30, ...).

## Networked/say hi

Basic netcatting works here:

```sh
nc 137.151.29.179 3000
```

## Linux Scavenger Hunt/the transmission

Hint: `man ip`

## Drawing/The illuminati is real

There's a trick to easily do this one:

1. Install Inkscape or use any vector-drawing program and draw a triangle.
2. Save above triangle as an SVG file.
3. With Imagemagick, do `convert -density 1200 -resize 256x256 triangle.svg triangle.png`.

## Validation/dmv.ca.gov

This is easily doable in Bash:

```sh
while read -r plate; do
    [[ "$plate" =~ ^[0-9][A-Z]{3}[0-9]{3}$ ]] && printf T || printf F
done < plates.txt
```

`read -r plate` reads one line into `$plate` and returns. This is done as a
condition for our `while` loop, and we feed `plates.txt` into the whole loop as
stdin.

We use Bash's `=~` operator which does regex matching. `^...$` means we want the
regex to cover the whole line (important because some plates are longer than 7
characters). The rest is fairly self-explanatory: 1 1 0-9, 3 A-Z, then 3 0-9.

## Parsing/czeched in

This one can also be trivially done in Bash.

First, we filter out the file for entries belonging to employee 9 and 4. Just
use `grep` for that. We only care about their check-in and check-out times, so
we use `cut` to extract those columns.

```sh
cat checkincheckout.csv | grep '^\(9,\|4,\)' | cut -d, -f3-4 > checkincheckout-4-9-times.csv
```

With our new results, we can then calculate the duration with `date`:

```sh
while IFS=, read -r enter leave; do
    echo $[ $(date -d "$leave" +%s) - $(date -d "$enter" +%s) ]
done \
    < checkincheckout-4-9-times.csv \
    > checkincheckout-4-9-times-sum.csv
```

Here, we use `read -r` to parse each line into `$enter` and `$leave` delimited
by `$IFS`. This is done in a `while` loop like earlier. Then, we use `date -d
"..." +%s` to parse the timestamp into a Unix epoch timestamp, which is just
seconds. Use Bash's `$[ ]` or `$(( ))` syntax to subtract the two epoch
timestamps and get the duration in seconds.

At this point, you'll end up with a list of numbers that you can just add up.
Use your favorite calculator program to calculate it. I chose to convert it to
an equation that I can just paste into [Qalculate](http://qalculate.github.io/):

```sh
cat checkincheckout-4-9-times-sum.csv | dos2unix | tr $'\n' +; echo -n 0
```

## Linux Scavenger Hunt/the alternator

Simply use `ps aux` to list all processes on the system:

```sh
ps aux | grep cb1442
```

## Automation/Big Ben

I decided to do this one lazily, which is to check the time every second (or
minute, whatever):

```sh
while sleep 1; do
	if (( ($(date +%M) % 15) == 0 )); then
		echo "Chime!"
		paplay ./rickroll.wav
	fi
done
```

I decided to play [Rick Astley's Never Gonna Give You
Up](https://www.youtube.com/watch?v=dQw4w9WgXcQ), since it's long enough that
it's very hard to miss. This way, I can just run the script in the background
and move on. To get a `rickroll.wav` file, use `youtube-dl`/`yt-dlp`:

```sh
yt-dlp -x -o rickroll.wav --audio-format wav -f wa https://www.youtube.com/watch?v=E4WlUXrJgy4
```

## Web/Rigging the vote

For this one, simply go to the Network tab, right click the `/vote` request,
choose Copy, Copy as cURL, then stick that into a Bash for loop:

```sh
for i in {1..500}; do
    # insert curl ...
done
```

## Misc/Crafting a Calculator

![clipboard.png](https://diamondburned.mataroa.blog/images/dd18450d.png)

I decided to use GTK and Go for this one. The full code (excluding `style.css`)
is available at [go.dev/play/p/Jd8mFbOcVzE](https://go.dev/play/p/Jd8mFbOcVzE).

This one is quite painful, mostly because of the way I wrote `Eval()`.

Here's the function to create the button grid:

```go
func newButtonGrid(onPress func(r rune)) *gtk.Grid {
	grid := gtk.NewGrid()
	grid.SetColumnHomogeneous(true)
	grid.SetRowHomogeneous(true)

	place := func(x, y, w, h int, r rune) {
		button := gtk.NewButtonWithLabel(string(r))
		button.ConnectClicked(func() { onPress(r) })
		button.SetHasFrame(false)
		grid.Attach(button, x, y, w, h)
	}

	for i, r := range "123456789" {
		place(i%3, i/3, 1, 1, r)
	}

	place(0, 3, 2, 1, '0')
	place(2, 3, 1, 1, '.')

	for i, r := range "+-*/" {
		place(3, i, 1, 1, r)
	}

	place(4, 0, 1, 4, '=')

	return grid
}
```

For the digits excluding 0, we can use `x=i%3` which gives us `0, 1, 2, 0, 1, 2,
...` and `y=i/3` which gives us `0, 0, 0, 1, 1, 1, ...`. This maps the numbers
so that:

- `1` goes to `x = 0%3 = 0`, `y = 0/3 = 0`
- `2` goes to `x = 1%3 = 1`, `y = 1/3 = 0`
- `3` goes to `x = 2%3 = 2`, `y = 2/3 = 0`
- `4` goes to `x = 3%3 = 0`, `y = 3/3 = 1`
- `5` goes to `x = 4%3 = 1`, `y = 4/3 = 1`
- ...

Here's how `onPress` is implemented:

```go
var state State
var prevState State
var floatBuf strings.Builder

onPress := func(r rune) {
	switch r {
	case '+', '-', '*', '/':
		state.op.Set(r)

		if floatBuf.Len() == 0 {
			state.lh.Set(prevState.eq.Value)
		} else {
			lh, err := strconv.ParseFloat(floatBuf.String(), 64)
			must(err)
			state.lh.Set(lh)
			floatBuf.Reset()
		}
	case '=':
		rh, err := strconv.ParseFloat(floatBuf.String(), 64)
		must(err)
		state.rh.Set(rh)
		floatBuf.Reset()

		state.Eval()

		defer func() {
			prevState = state
			state = State{}
		}()
	default:
		_, err := strconv.ParseFloat(floatBuf.String()+string(r), 64)
		if err == nil {
			floatBuf.WriteRune(r)
		}
	}

	resultLabel.SetText(state.Display() + floatBuf.String())
}
```

For handling the runes, we have 3 basic cases to handle:

- If the user pressed a digit or a period (`default`), we can add that character
  into our `floatBuf` and validate it.
  - Validation is done before concatenation to ensure that the buffer is always
    valid.
- If the user has pressed any of the math operators (`case '+', '-', '*', '/'`):
  - If `floatBuf` is empty, then the user hasn't inputted anything before they
    pressed this button. Simply use the result from the previous calculation as
    the left-hand side.
  - Otherwise, we parse `floatBuf` and fill in the left-hand side.
- If the user has pressed equal (`case '='`), then parse `floatBuf` and fill in
  the right-hand side. We can then evaluate our state to form the result. 

For displaying the result, we render the current calculator state with
`state.Display()` which shows everything that we have finalized, then
concatenate that with the current digit's buffer (`floatBuf`). This gives us the
`10+3` UI. `Display` was implemented like so:

```go
func (s *State) Display() string {
	if s.eq.Valid {
		if math.IsInf(s.eq.Value, 0) {
			return "Error"
		}
		return ftoa(s.eq.Value)
	}

	var display strings.Builder
	if s.lh.Valid {
		display.WriteString(ftoa(s.lh.Value))
	}
	if s.op.Valid {
		display.WriteRune(s.op.Value)
	}
	if s.rh.Valid {
		display.WriteString(ftoa(s.rh.Value))
	}

	return display.String()
}
```

The function has two simple cases:

- If we already have a result, display only that.
- Otherwise, display `lh op rh` (skipping undefined fields), e.g. `12+` or
  `12+24`.

Note that we made all values optional just to be extra careful in how we're
rendering the state. Also, `x/0` returns `+Inf`, so we consider that `Error`.

## Drawing/What time is it?

![clipboard.png](https://diamondburned.mataroa.blog/images/fb1e4e1f.png)

I was lazy. Here's my (stolen) font:

```
 _     _  _     _  _  _  _  _    
| |  | _| _||_||_ |_   ||_||_| o 
|_|  ||_  _|  | _||_|  ||_| _| o 
```

Our font is laid out like so:

```
111222333...
111222333...
111222333...
```

So we can parse it like so:

```go
font := make(map[rune]string, 10)
for i, r := range "0123456789:" {
	for y := 0; y < len(lines); y++ {
		font[r] += lines[y][(i*3)+0:(i*3)+3] + "\n"
	}
}
```

To break down what's happening:

- For each digit from 0 to 9:
    - For line `111222333...`:
        - We slice using `[(i*3) : (i*3)+3]`.
            - Notice how `111` belongs to 0, `222` belongs to 1, etc.
            - `111` is `[0:3]`, `222` is from `[3:6]`, ...
            - Our pattern gives us the above equation.
        - Append the concatenated string into our character map `font`.
            - The font is appended per line, e.g. 1 would be `111`, `111`, `111`.

The simplest way to redraw our clock is to move the cursor up 3 lines (because
our font is always 3 lines high). We do this in the terminal by printing
`\033[3A`. The terminal emulator reads this and understands it as a command to
move the cursor up 3 lines, which allows us to override our old lines.

## Stegonography/unordered

This one can trivially be done in Bash:

```sh
f=0.txt
while :; do
	read -r char next < "$f"
	echo -n "$char"
	f="${next}.txt"
	[[ "$f" == "0.txt" ]] && break
done
```

We basically start at `0.txt` then read the two words in it into `$char` and
`$next`. We'll print `$char` then move on to `$next`. Repeat until we're back to
`0.txt`.

## Web/Rigging the vote (Round 2!)

Our round 1 solution also works for round 2.

## Web/Larry's Loggin' Logs Login

Not much code was required (unless you count CSS). Here's a screenshot of my design:

![](https://cdn.discordapp.com/attachments/1060736006309019700/1066542448119136386/clipboard.png)

## Networked/Hangman

This one was interesting. I decided to break the code for this problem down into
3 components:

- The hangman parser, which parses the hangman ASCII to see how many wrong
  answers it is indicating,
- The prompt parser, which parses the output into a structure of word, letters
  and "hangmen" (a list of hangman ASCIIs), and
- The main program logic.

Writing the parser was interesting. I used a template that marks `x` where the
body parts would be:

```
 +--+
 |  |
 x  |
xxx |
x x |
    |
=====
```

Then I simply searched for the positions of those `x`s. This allowed me to
simplify parsing the hangman ASCII to a simple loop:

```go
var wrongs int
for _, ix := range hangmanIxs {
	if hangman[ix] != ' ' {
		wrongs++
	}
}
```

The loop assumes that the ASCII character for each body part is either a space
`(' ')` which indicates no body part (not wrong) or anything else (not empty,
therefore wrong).

Parsing the prompt was fairly simple given the fact that each prompt is
"delimited" by the closing parenthesis (`)`) character. Ideally, we would read
until the string `(Enter the number)`, but I couldn't find an easy way to do
that in Go. Thankfully, we're not aiming for good code :)

The simplest way to parse the `Letters guessed` value is just to trim the prefix
and filter out all characters outside the set `a-z`. There's no need to parse
the array syntax.

```go
lettersLine := strings.TrimPrefix(lines[1], "Letters guessed:  ")
letters := []rune(strings.Map(mapRune(unicode.IsLetter), lettersLine))

// mapRune is a helper function.
func mapRune(isRune func(rune) bool) func(rune) rune {
	return func(r rune) rune {
		if isRune(r) {
			return r
		}
		return -1 // omit
	}
}
```

## Automation/As per my last email

Just use `msmtp`:

```sh
#!/usr/bin/env nix-shell
#! nix-shell -i bash -p msmtp
cat<<EOF | msmtp \
	--auth \
	--host smtp.gmail.com \
	--port 587 \
	--tls \
	--tls-starttls \
	--read-envelope-from \
	--read-recipients \
	--user "${GMAIL_USERNAME}" \
	--passwordeval 'printenv GMAIL_PASSWORD'
From: ${GMAIL_USERNAME}@gmail.com
To: acmcsufullerton@gmail.com
Subject: Default Email

Hi!!! Thanks for organizing TitanCodes!
EOF
```

## Web/Larry's Loggin' Logs Login [Part 2!]

Implement the backend however you want. Just make it handle a simple POST
request.

You don't need to write any JS for the webpage though. Just use `<form>`:

```html
<main>
	<form class="page" method="post" action="login">
		<h1>Login</h1>
		<formset>
			<label for="username">Username</label>
			<input type="text" id="username" name="username">
			<label for="password">Password</label>
			<input type="password" id="password" name="password">
		</formset>
		<input type="submit" value="Log in">
	</form>
</main>
```
