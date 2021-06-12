#!/usr/bin/env zsh
set -e

projectpath=$0:A:h:h
cd $projectpath

typeset -A only=()
for func; only[$func]=1;

integer failure=0 total=0 haserror=0

test_function() {
  if [[ -n $only && -z $only[$1] ]]; then
    return 1
  fi

  test_function=$1
  eval "xxx() { $(<$projectpath/functions/$1) }"
}

keep() {
  echo -E ${(qqq)@}
}

test() {
  ((++total))
  echo -nE $'l.\033[35m'"${functrace/*:} "$'\033[36m'"$test_function "$'\033[0m'"$@ "
  haserror=0

  output=$(xxx $@ 2>&1) || haserror=1
}

check() {
  local expected=${(j: :)${(qqq)@}}

  if (( haserror )) || [[ $expected != $output ]]; then
    echo -E $'\033[31mERROR\033[0m'
    local -i min=$#output i
    if (( $#expected < min )); then
      min=$#expected
    fi

    for ((i=1; i <= min; ++i)); do
      [[ $output[i] = $expected[i] ]] || break
    done
    i+=-1

    echo -E "expected: ${expected:0:$i}"$'\033[4;33m'"${expected:$i}"$'\033[0m'
    echo -E "output  : ${output:0:$i}"$'\033[4;33m'"${output:$i}"$'\033[0m'
    if (( haserror )); then
      echo -E "error   : $haserror"
    fi
    echo

    ((++failure))
  else
    echo -E $'\033[32mOK\033[0m'
  fi
}


if test_function jln-glob ; then
  test nocase,numeric keep 'F*'; check functions
  test numeric,nocase keep 'F*'; check functions
  test nocase keep 'F*'; check functions
  test null keep 'F*'; check
fi

if test_function jln-unalias-exec ; then
  alias a0='print -E';
  alias a1='a0 plop'
  alias a2='noglob a1 xy'

  test 0 1 keep a1 abc; check print -E plop abc
  test 0 0 keep ls 'fun*'; check ls functions
  test 0 1 keep ls 'fun*'; check ls 'fun*'
  test 0 0 keep a2 'fun*'; check print -E plop xy functions

  alias ls='ls -l'
  test 0 1 keep ls 'fun*'; check ls -l 'fun*'
  test 0 0 keep ls 'fun*'; check ls -l functions

  alias g='a0 func*'

  test 0 0 keep g 'fun*'; check print -E functions functions
  test 1 0 keep g 'fun*'; check print -E 'func*' functions
  test 0 1 keep g 'fun*'; check print -E functions 'fun*'
  test 1 1 keep g 'fun*'; check print -E 'func*' 'fun*'

  alias ng='noglob a0 func*'

  test 0 0 keep ng 'fun*'; check print -E 'func*' functions
  test 1 0 keep ng 'fun*'; check print -E 'func*' functions
  test 0 1 keep ng 'fun*'; check print -E 'func*' 'fun*'
  test 1 1 keep ng 'fun*'; check print -E 'func*' 'fun*'

  # recursive alias
  alias r0='r1 abc'
  alias r1='r0 xyz'

  test 0 0 keep r0 n; check r0 xyz abc n
  test 0 0 keep r1 n; check r1 abc xyz n
fi


if (( failure )); then
  echo "failure: $failure on $total" >&2
  exit 1
else
  echo "$total tests ok"
fi
