#!/usr/bin/env zsh
set -e

projectpath=$0:A:h:h

typeset -A only=()
for func; only[$func]=1;

integer failure=0 total=0
first_call_delay=.01 # preload function delay
other_call_delay=.001

zmodload zsh/zpty
zpty z 'zsh -f'

zpty -w z 'PROMPT="";d='${(q)projectpath}';fpath+=($d/widgets);funcs=($d/widgets/*);funcs=($funcs:t); autoload $funcs; for func in $funcs; zle -N $func; jtest() { local r; CURSOR=cursor; [[ -n $numeric ]] && NUMERIC=numeric; zle $jfunc && echo -E "<OUTPUT>$LBUFFER\${cursor}$RBUFFER</OUTPUT>" || echo -E "<OUTPUT>zle error</OUTPUT>";BUFFER=""; [[ -n $numeric ]] && unset numeric };zle -N jtest;bindkey @ jtest'

sleep .1
zpty -rt z result

test_function() {
  if [[ -n $only && -z $only[$1] ]]; then
    return 1
  fi

  test_function=$1
  test_delay=$first_call_delay
}

test() {
  local lbuf=${2/'${cursor}'*}
  zpty -w z "jfunc=$test_function;cursor=$#lbuf;$1"
  zpty -w -n z "$lbuf${2:$#lbuf+9}@"

  check_test "$@"
}

check_test() {
  ((++total))
  echo -nE $'l.\033[35m'"${functrace/*:} "$'\033[36m'"$test_function "${1:+$'\033[37m'$1 }$'\033[0m'"$2 "

  sleep $test_delay
  test_delay=$other_call_delay
  local result
  result=$(zpty -rt z)
  result=${result:${#result/'<OUTPUT>'*}+8}
  result=${result:0:${#result/'<\/OUTPUT>'*}}
  #result=${result//$'\r'}

  if [[ $result != $3 ]]; then
    local -i istart iend n=$#3 nres=$#result min

    ((n < nres)) && min=n || min=nres

    for ((istart=1; istart <= min; ++istart)); do
      [[ $result[istart] = ${3[istart]} ]] || break
    done

    for ((iend=0; iend < min; ++iend)); do
      [[ $result[nres-iend] = ${3[n-iend]} ]] || break
    done

    istart+=-1
    n+=-iend
    nres+=-iend

    echo -E $'\033[31mERROR\033[0m'
    echo -E "input   : $2|"
    #echo -E "expected: $2"
    #echo -E "output  : $result"
    echo -E "expected: ${3:0:$istart}"$'\033[4;33m'"${3:$istart:$n-$istart}"$'\033[0m'"${3:$n}|"
    echo -E "output  : ${result:0:$istart}"$'\033[4;33m'"${result:$istart:$nres-$istart}"$'\033[0m'"${result:$nres}|"
    echo
    ((++failure))
  else
    echo -E $'\033[32mOK\033[0m'
  fi
}

if test_function jln-forward-arg ; then
  test '' 'echo abc${cursor} cde fgh'   'echo abc ${cursor}cde fgh'
  test '' 'echo a${cursor}bc cde fgh'   'echo abc ${cursor}cde fgh'
  test '' 'echo ${cursor}abc cde fgh'   'echo abc ${cursor}cde fgh'
  test '' 'echo ${cursor}  abc cde'     'echo   ${cursor}abc cde'
  test '' 'echo "a${cursor} b"   cde'   'echo "a b"   ${cursor}cde'
  test '' 'echo abc${cursor}'           'echo abc${cursor}'
  test '' 'echo abc${cursor} '          'echo abc ${cursor}'
  test '' 'echo abc ${cursor}'          'echo abc ${cursor}'

  test 'numeric=2' 'echo abc${cursor} cd fgh'    'echo abc cd ${cursor}fgh'
  test 'numeric=2' 'echo a${cursor}bc cd fgh'    'echo abc cd ${cursor}fgh'
  test 'numeric=2' 'echo ${cursor}abc cd fgh'    'echo abc cd ${cursor}fgh'
  test 'numeric=2' 'echo ${cursor}  abc cde'     'echo   abc ${cursor}cde'
  test 'numeric=2' 'echo "a${cursor} b"   cde'   'echo "a b"   cde${cursor}'
  test 'numeric=2' 'echo abc${cursor}'           'echo abc${cursor}'
  test 'numeric=2' 'echo abc${cursor} '          'echo abc ${cursor}'
  test 'numeric=2' 'echo abc ${cursor}'          'echo abc ${cursor}'
fi

if test_function jln-backward-arg; then
  test '' 'echo abc${cursor} cde fgh'   'echo ${cursor}abc cde fgh'
  test '' 'echo a${cursor}bc cde fgh'   'echo ${cursor}abc cde fgh'
  test '' 'echo ${cursor}abc cde fgh'   '${cursor}echo abc cde fgh'
  test '' 'echo ${cursor}  abc cde'     '${cursor}echo   abc cde'
  test '' 'echo  "a ${cursor}b"  cde'   'echo  ${cursor}"a b"  cde'
  test '' '${cursor}echo abc'           '${cursor}echo abc'
  test '' ' ${cursor}echo abc'          '${cursor} echo abc'
  test '' '${cursor} echo abc'          '${cursor} echo abc'

  test 'numeric=2' 'echo abc cd${cursor} fgh'    'echo ${cursor}abc cd fgh'
  test 'numeric=2' 'echo abc c${cursor}de fgh'   'echo ${cursor}abc cde fgh'
  test 'numeric=2' 'echo abc cd ${cursor}fgh'    'echo ${cursor}abc cd fgh'
  test 'numeric=2' 'echo ${cursor}abc cde fgh'   '${cursor}echo abc cde fgh'
  test 'numeric=2' 'echo abc cde  ${cursor}fg'   'echo ${cursor}abc cde  fg'
  test 'numeric=2' 'echo ${cursor}  abc cde'     '${cursor}echo   abc cde'
  test 'numeric=2' 'echo  x "a ${cursor}b"'      'echo  ${cursor}x "a b"'
  test 'numeric=2' 'echo  "a ${cursor}b"  cde'   '${cursor}echo  "a b"  cde'
  test 'numeric=2' '${cursor}echo abc'           '${cursor}echo abc'
  test 'numeric=2' ' ${cursor}echo abc'          '${cursor} echo abc'
  test 'numeric=2' '${cursor} echo abc'          '${cursor} echo abc'
fi

if test_function jln-forward-arg-end; then
  test '' 'echo abc${cursor} cde fgh'   'echo abc cde${cursor} fgh'
  test '' 'echo a${cursor}bc cde fgh'   'echo abc${cursor} cde fgh'
  test '' 'echo ${cursor}abc cde fgh'   'echo abc${cursor} cde fgh'
  test '' 'echo ${cursor}  abc cde'     'echo   abc${cursor} cde'
  test '' 'echo "a${cursor} b"   cde'   'echo "a b"${cursor}   cde'
  test '' 'echo abc${cursor}'           'echo abc${cursor}'
  test '' 'echo abc${cursor} '          'echo abc ${cursor}'
  test '' 'echo abc ${cursor}'          'echo abc ${cursor}'

  test 'numeric=2' 'echo abc${cursor} cde f'     'echo abc cde f${cursor}'
  test 'numeric=2' 'echo abc${cursor} cd f g'    'echo abc cd f${cursor} g'
  test 'numeric=2' 'echo a${cursor}bc cde fgh'   'echo abc cde${cursor} fgh'
  test 'numeric=2' 'echo ${cursor}abc cde fgh'   'echo abc cde${cursor} fgh'
  test 'numeric=2' 'echo ${cursor}  abc cd f'    'echo   abc cd${cursor} f'
  test 'numeric=2' 'echo "a${cursor} b"   c e'   'echo "a b"   c${cursor} e'
  test 'numeric=2' 'echo abc${cursor}'           'echo abc${cursor}'
  test 'numeric=2' 'echo abc${cursor} '          'echo abc ${cursor}'
  test 'numeric=2' 'echo abc ${cursor}'          'echo abc ${cursor}'
fi

if test_function jln-backward-arg-end; then
  test '' 'echo abc${cursor} cde fgh'   'echo${cursor} abc cde fgh'
  test '' 'echo a${cursor}bc cde fgh'   'echo${cursor} abc cde fgh'
  test '' 'echo ${cursor}abc cde fgh'   'echo${cursor} abc cde fgh'
  test '' 'echo ${cursor}  abc cde'     'echo${cursor}   abc cde'
  test '' 'echo  "a ${cursor}b"  cde'   'echo${cursor}  "a b"  cde'
  test '' '${cursor}echo abc'           '${cursor}echo abc'
  test '' ' ${cursor}echo abc'          '${cursor} echo abc'
  test '' '${cursor} echo abc'          '${cursor} echo abc'

  test 'numeric=2' 'echo abc cd${cursor} fgh'    'echo${cursor} abc cd fgh'
  test 'numeric=2' 'echo abc c${cursor}de fgh'   'echo${cursor} abc cde fgh'
  test 'numeric=2' 'echo abc cde ${cursor}fgh'   'echo abc${cursor} cde fgh'
  test 'numeric=2' 'echo ${cursor}abc cde fgh'   '${cursor}echo abc cde fgh'
  test 'numeric=2' 'echo abc cde  ${cursor}fg'   'echo abc${cursor} cde  fg'
  test 'numeric=2' 'echo ${cursor}  abc cde'     '${cursor}echo   abc cde'
  test 'numeric=2' 'echo  x "a ${cursor}b"'      'echo${cursor}  x "a b"'
  test 'numeric=2' 'echo  "a ${cursor}b"  cde'   '${cursor}echo  "a b"  cde'
  test 'numeric=2' '${cursor}echo abc'           '${cursor}echo abc'
  test 'numeric=2' ' ${cursor}echo abc'          '${cursor} echo abc'
  test 'numeric=2' '${cursor} echo abc'          '${cursor} echo abc'
fi

if test_function jln-kill-arg; then
  test '' 'echo abc${cursor} cd fgh'   'echo abc${cursor} fgh'
  test '' 'echo a${cursor}bc cd fgh'   'echo a${cursor} cd fgh'
  test '' 'echo ${cursor}abc cd fgh'   'echo ${cursor} cd fgh'
  test '' 'echo ${cursor}  abc cd'     'echo ${cursor} cd'
  test '' 'echo "a${cursor} b"   cd'   'echo "a${cursor}   cd'
  test '' 'echo abc${cursor}'          'echo abc${cursor}'
  test '' 'echo abc${cursor} '         'echo abc${cursor}'
  test '' 'echo abc ${cursor}'         'echo abc ${cursor}'

  test 'numeric=2' 'echo abc${cursor} cd fgh'    'echo abc${cursor}'
  test 'numeric=2' 'echo a${cursor}bc cd fgh'    'echo a${cursor} fgh'
  test 'numeric=2' 'echo ${cursor}abc cd fgh'    'echo ${cursor} fgh'
  test 'numeric=2' 'echo ${cursor}  abc cd'      'echo ${cursor}'
  test 'numeric=2' 'echo ${cursor}  abc cd f'    'echo ${cursor} f'
  test 'numeric=2' 'echo "a${cursor} b"   cd'    'echo "a${cursor}'
  test 'numeric=2' 'echo "a${cursor} b"   c e'   'echo "a${cursor} e'
  test 'numeric=2' 'echo abc${cursor}'           'echo abc${cursor}'
  test 'numeric=2' 'echo abc${cursor} '          'echo abc${cursor}'
  test 'numeric=2' 'echo abc ${cursor}'          'echo abc ${cursor}'
fi

if test_function jln-kill-arg-and-space; then
  test '' 'echo abc${cursor} cd fgh'   'echo abc${cursor}fgh'
  test '' 'echo a${cursor}bc cd fgh'   'echo a${cursor}cd fgh'
  test '' 'echo ${cursor}abc cd fgh'   'echo ${cursor}cd fgh'
  test '' 'echo ${cursor}  abc cd'     'echo ${cursor}cd'
  test '' 'echo "a${cursor} b"   cd'   'echo "a${cursor}cd'
  test '' 'echo abc${cursor}'          'echo abc${cursor}'
  test '' 'echo abc${cursor} '         'echo abc${cursor}'
  test '' 'echo abc ${cursor}'         'echo abc ${cursor}'

  test 'numeric=2' 'echo abc${cursor} cd fgh'    'echo abc${cursor}'
  test 'numeric=2' 'echo a${cursor}bc cd fgh'    'echo a${cursor}fgh'
  test 'numeric=2' 'echo ${cursor}abc cd fgh'    'echo ${cursor}fgh'
  test 'numeric=2' 'echo ${cursor}  abc cd'      'echo ${cursor}'
  test 'numeric=2' 'echo ${cursor}  abc cd f'    'echo ${cursor}f'
  test 'numeric=2' 'echo "a${cursor} b"   cd'    'echo "a${cursor}'
  test 'numeric=2' 'echo "a${cursor} b"   c e'   'echo "a${cursor}e'
  test 'numeric=2' 'echo abc${cursor}'           'echo abc${cursor}'
  test 'numeric=2' 'echo abc${cursor} '          'echo abc${cursor}'
  test 'numeric=2' 'echo abc ${cursor}'          'echo abc ${cursor}'
fi

if test_function jln-transpose-arg; then
  test '' 'echo abc${cursor} cd fgh'   'echo cd abc ${cursor}fgh'
  test '' 'echo a${cursor}bc cd fgh'   'echo cd abc ${cursor}fgh'
  test '' 'echo ${cursor}abc cd fgh'   'abc echo ${cursor}cd fgh'
  test '' 'echo ${cursor}  abc cd'     'abc   echo ${cursor}cd'
  test '' 'echo "a${cursor} b"   cd'   'echo cd   "a b"${cursor}'
  test '' 'echo abc${cursor}'          'abc echo${cursor}'
  test '' 'echo abc${cursor} '         'abc echo ${cursor}'
  test '' 'echo abc ${cursor}'         'abc echo ${cursor}'

  test 'numeric=2' 'echo abc${cursor} cd fgh'    'echo cd fgh abc${cursor}'
  test 'numeric=2' 'echo a${cursor}bc cd fgh'    'echo cd fgh abc${cursor}'
  test 'numeric=2' 'echo ${cursor}abc cd fgh'    'abc cd echo ${cursor}fgh'
  test 'numeric=2' 'echo ${cursor}  abc cd'      'abc cd   echo${cursor}'
  test 'numeric=2' 'echo ${cursor}  abc cd f'    'abc cd   echo ${cursor}f'
  test 'numeric=2' 'echo "a${cursor} b"   cd '   'echo cd   "a b" ${cursor}'
  test 'numeric=2' 'echo "a${cursor} b"   c e'   'echo c e   "a b"${cursor}'
  test 'numeric=2' 'echo abc${cursor}'           'abc echo${cursor}'
  test 'numeric=2' 'echo abc${cursor} '          'abc echo ${cursor}'
  test 'numeric=2' 'echo abc ${cursor}'          'abc echo ${cursor}'
fi

if test_function jln-save-command-line; then
# set -xe
  test '' 'echo abc${cursor} cd fgh'   'echo abc${cursor} cd fgh'
  zpty -w z 'echo xyz;jfunc=redisplay;'
  zpty -wn z '@'
  check_test '' 'restore line' 'echo abc${cursor} cd fgh'
  zpty -w z 'echo xyz;jfunc=jln-save-command-line;'
  zpty -wn z '@' # disable
  zpty -w z 'echo'
  check_test '' 'new line' 'echo abc${cursor} cd fgh'
  zpty -w z 'echo'
  check_test '' 'new line' ''
fi

if test_function jln-insert-sudo; then
  test '' 'echo abc${cursor}'         'sudo echo abc${cursor}'
  test '' ' echo ab${cursor}c'        ' sudo echo ab${cursor}c'
  test '' 'sudo echo a${cursor}bc'    'echo a${cursor}bc'
  test '' ' sudo echo ${cursor}abc'   ' echo ${cursor}abc'
  test '' ''                          'sudo jfunc=jln-insert-sudo;cursor=0;${cursor}'
  test '' '  '                        '  sudo jfunc=jln-insert-sudo;cursor=2;${cursor}'
fi


zpty -d z

if (( failure )); then
  echo "failure: $failure on $total" >&2
  exit 1
else
  echo "$total tests ok"
fi
