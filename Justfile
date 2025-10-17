[private]
@all:
	just -l

# generate the article date of the given article file
@article-date path:
	./tools/article-date "{{path}}"

# build the blog to public/
@build *args:
	./tools/build {{args}}

# paste the image from clipboard to the static directory and print the HTML/Markdown code to embed the image
@paste-image:
	./tools/paste-image

# generate a synopsis for the given article file
@synopsis path:
	./tools/synopsis "{{path}}"

# generate the title for the given article file
@title path:
	./tools/title "{{path}}"

# start a simple static file server to serve the built blog
@serve: build
	python3 -m http.server -d public
