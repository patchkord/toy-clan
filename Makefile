deps:
	mix geps.get

run: deps
	mix run -e Demo.run --no-halt
