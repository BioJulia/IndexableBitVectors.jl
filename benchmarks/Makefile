JULIA=julia

all: CompactBitVector.tsv SucVector.tsv RRR.tsv LargeRRR.tsv

%.tsv:
	$(JULIA) bench.jl $(basename $@) > $@

clean:
	rm -f *.tsv
