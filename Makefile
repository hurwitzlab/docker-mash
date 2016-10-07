image:
	docker build -t mash .

run:
	docker run --rm -v $(shell pwd):/work -w /work mash

it:
	docker run --rm -it -v $(shell pwd):/work -w /work --entrypoint bash mash 

pov:
	docker run --rm -v $(shell pwd):/work -v /usr/local/imicrobe/data/pov:/data -w /work mash -i /data/fasta -o /data/mash-out -a /data/aliases.txt
