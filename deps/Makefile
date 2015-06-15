libbitvector.dylib: bitvector.c
	$(CC) -std=c99 -dynamiclib -msse4 -O3 -o $@ $<

.PHONY: clean
clean:
	rm -rf libbitvector.dylib
