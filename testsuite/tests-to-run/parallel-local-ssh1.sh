#!/bin/bash

rm -rf tmp
mkdir tmp
cd tmp

cat <<'EOF' | sed -e s/\$SERVER1/$SERVER1/\;s/\$SERVER2/$SERVER2/ | stdout parallel -vj5 -k -L1
echo '### bug #41964: --controlmaster not seems to reuse OpenSSH connections to the same host'
  (parallel -S redhat9.tange.dk true ::: {1..20}; echo No --controlmaster - finish last) & 
  (parallel -M -S redhat9.tange.dk true ::: {1..20}; echo With --controlmaster - finish first) & 
  wait

echo '### Stop if all hosts are filtered and there are no hosts left to run on'
  stdout parallel --filter-hosts -S no-such.host echo ::: 1

echo '### bug #41805: Idea: propagate --env for parallel --number-of-cores'
  echo '** test_zsh'
  FOO=test_zsh parallel --env FOO,PATH -S zsh@lo env ::: "" |sort|egrep 'FOO|PATH'
  echo '** test_zsh_filter'
  FOO=test_zsh_filter parallel --filter-hosts --env FOO,PATH -S zsh@lo env ::: "" |sort|egrep 'FOO|PATH'
  echo '** test_csh'
  FOO=test_csh parallel --env FOO,PATH -S csh@lo env ::: "" |sort|egrep 'FOO|PATH'
  echo '** test_csh_filter'
  FOO=test_csh_filter parallel --filter-hosts --env FOO,PATH -S csh@lo env ::: "" |sort|egrep 'FOO|PATH'
  echo '** bug #41805 done'

echo '### Deal with long command lines on remote servers'
  perl -e 'print((("\""x10000)."\n")x10)' | parallel -j1 -S lo -N 10000 echo {} |wc

echo '### Test bug #34241: --pipe should not spawn unneeded processes'
  seq 5 | ssh csh@lo parallel -k --block 5 --pipe -j10 cat\\\;echo Block_end

echo '### --env _'
  fUbAr="OK FUBAR" parallel -S parallel@lo --env _ echo '$fUbAr $DEBEMAIL' ::: test
  fUbAr="OK FUBAR" parallel -S csh@lo --env _ echo '$fUbAr $DEBEMAIL' ::: test
echo '### --env _ with explicit mentioning of normally ignored var $DEBEMAIL'
  fUbAr="OK FUBAR" parallel -S parallel@lo --env DEBEMAIL,_ echo '$fUbAr $DEBEMAIL' ::: test
  fUbAr="OK FUBAR" parallel -S csh@lo --env DEBEMAIL,_ echo '$fUbAr $DEBEMAIL' ::: test

echo 'bug #40137: SHELL not bash: Warning when exporting funcs'
  . <(printf 'myfunc() {\necho $1\n}'); export -f myfunc; parallel --env myfunc -S lo myfunc ::: no_warning
  . <(printf 'myfunc() {\necho $1\n}'); export -f myfunc; SHELL=/bin/sh parallel --env myfunc -S lo myfunc ::: warning

echo '### bug #40002: --files and --nonall seem not to work together:'
  parallel --files --nonall -S localhost true | tee >(parallel rm) | wc -l

echo '### bug #40001: --joblog and --nonall seem not to work together:'
  parallel --joblog - --nonall -S lo,localhost true | wc -l

echo '### bug #40132: FreeBSD: --workdir . gives warning if . == $HOME'
  cd && parallel --workdir . -S lo pwd ::: ""

echo '### test filename :'
  echo content-of-: > :; 
  echo : | parallel -j1 --trc {}.{.} -S parallel@lo '(echo remote-{}.{.};cat {}) > {}.{.}'; 
  cat :.:; rm : :.:

echo '### Test --wd ... --cleanup which should remove the filled tmp dir'
  find ~/.parallel/tmp |grep uNiQuE_sTrInG.6 | parallel rm; 
  stdout parallel -j9 -k --retries 3 --wd ... --cleanup -S lo -v echo ">"{}.6 :::  uNiQuE_sTrInG; 
  find ~/.parallel/tmp |grep uNiQuE_sTrInG.6

echo '### Test --wd --'
  stdout parallel --wd -- -S lo echo OK ">"{}.7 ::: uNiQuE_sTrInG; 
  cat ~/--/uNiQuE_sTrInG.7; 
  stdout rm ~/--/uNiQuE_sTrInG.7

echo '### Test --wd " "'
  stdout parallel --wd " " -S lo echo OK ">"{}.8 ::: uNiQuE_sTrInG; 
  cat ~/" "/uNiQuE_sTrInG.8; 
  stdout rm ~/" "/uNiQuE_sTrInG.8

echo "### Test --wd \"'\""
  stdout parallel --wd "'" -S lo echo OK ">"{}.9 ::: uNiQuE_sTrInG; 
  cat ~/"'"/uNiQuE_sTrInG.9; 
  stdout rm ~/"'"/uNiQuE_sTrInG.9

echo '### Test --trc ./--/--foo1'
  mkdir -p ./--; echo 'Content --/--foo1' > ./--/--foo1; 
  stdout parallel --trc {}.1 -S lo '(cat {}; echo remote1) > {}.1' ::: ./--/--foo1; cat ./--/--foo1.1; 
  stdout parallel --trc {}.2 -S lo '(cat ./{}; echo remote2) > {}.2' ::: --/--foo1; cat ./--/--foo1.2

echo '### Test --trc ./:dir/:foo2'
  mkdir -p ./:dir; echo 'Content :dir/:foo2' > ./:dir/:foo2; 
  stdout parallel --trc {}.1 -S lo '(cat {}; echo remote1) > {}.1' ::: ./:dir/:foo2; cat ./:dir/:foo2.1; 
  stdout parallel --trc {}.2 -S lo '(cat ./{}; echo remote2) > {}.2' ::: :dir/:foo2; cat ./:dir/:foo2.2

echo '### Test --trc ./" "/" "foo3'
  mkdir -p ./" "; echo 'Content _/_foo3' > ./" "/" "foo3; 
  stdout parallel --trc {}.1 -S lo '(cat {}; echo remote1) > {}.1' ::: ./" "/" "foo3; cat ./" "/" "foo3.1; 
  stdout parallel --trc {}.2 -S lo '(cat ./{}; echo remote2) > {}.2' ::: " "/" "foo3; cat ./" "/" "foo3.2

echo '### Test --trc ./--/./--foo4'
  mkdir -p ./--; echo 'Content --/./--foo4' > ./--/./--foo4; 
  stdout parallel --trc {}.1 -S lo '(cat ./--foo4; echo remote{}) > --foo4.1' ::: --/./--foo4; cat ./--/./--foo4.1

echo '### Test --trc ./:/./:foo5'
  mkdir -p ./:; echo 'Content :/./:foo5' > ./:/./:foo5; 
  stdout parallel --trc {}.1 -S lo '(cat ./:foo5; echo remote{}) > ./:foo5.1' ::: ./:/./:foo5; cat ./:/./:foo5.1

echo '### Test --trc ./" "/./" "foo6'
  mkdir -p ./" "; echo 'Content _/./_foo6' > ./" "/./" "foo6; 
  stdout parallel --trc {}.1 -S lo '(cat ./" "foo6; echo remote{}) > ./" "foo6.1' ::: ./" "/./" "foo6; cat ./" "/./" "foo6.1

echo TODO

## echo '### Test --trc --basefile --/./--foo7 :/./:foo8 " "/./" "foo9 ./foo11/./foo11'
## echo missing
## echo '### Test --trc "-- "'
## echo missing
## echo '### Test --trc " --"'
## echo missing
## 
EOF

rm -rf tmp
mkdir tmp
cd tmp
