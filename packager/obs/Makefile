all:
	cd ../debian/ && make
	osc rm home\:tange/parallel/parallel_*.dsc || true
	cp ../debian/parallel_*.dsc ../debian/parallel_*.tar.gz home\:tange/parallel/
	cp `ls ../../parallel-2*.tar.bz2|tail -n1` home\:tange/parallel/
	cd home\:tange/parallel/ && osc up 
	cd home\:tange/parallel/ && parallel osc add ::: *.spec *.dsc *.tar.gz *.tar.bz2 && echo Src added OK || true
	cd home\:tange/parallel/ && osc ci -m "New release"
