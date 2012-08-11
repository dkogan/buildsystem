DOC = docs/build_documentation.html

all: $(DOC)

%.html: %.org
	emacs --batch $^ --eval "(org-export-as-html nil)"

test:
	cd tests && ./test.pl

clean:
	rm -rf $(DOC)
	make -C tests clean
