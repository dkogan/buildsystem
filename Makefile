DOC = docs/build_documentation.html

all: $(DOC)

%.html: %.org
	emacs --batch $^ --eval "(org-export-as-html nil)"

clean:
	rm -rf $(DOC)
