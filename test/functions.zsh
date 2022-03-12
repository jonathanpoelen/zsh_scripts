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
  output=

  output=$(xxx $@ 2>&1) || haserror=1
}

check() {
  local expected=${(j: :)${(qqq)@}}
  check_impl
}

check_s() {
  local expected=${(j: :)${@}}
  check_impl
}

check_impl() {
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

check_error()
{
  if (( haserror )) && [[ $1 = $output ]] ; then
    echo -E $'\033[32mOK\033[0m'
  else
    haserror=1
    check_s $1
  fi
}

check_cmd()
{
  if (( haserror )); then
    echo -E $'\033[31mERROR\033[0m'
    echo error code $'\033[4;33m'$haserror$'\033[0m'
    echo output: $'\033[4;33m'$output$'\033[0m'
    return
  fi

  local msg=''
  integer i=1
  for cmd; do
    haserror=0
    eval $cmd || msg+=$'\nwith $'$i$': \033[4;33m'$cmd$'\033[0m'
    ((++i))
  done
  if [[ -n $msg ]] ; then
    echo -E $'\033[31mERROR\033[0m'$msg
    ((++failure))
  else
    echo -E $'\033[32mOK\033[0m'
  fi
}


if test_function each ; then
  test echo a b; check_s $'a\nb'
  test echo a -- b c; check_s $'a b\na c'
  test echo -- a -- b; check_s $'a\n--\nb'
fi

if test_function jln-glob ; then
  eval "pre_$(functions xxx)"
  xxx() { pre_xxx $=1 ; shift ; jln-glob-pop $~@ }
  test 'nocase numeric' keep 'F*'; check functions
  test 'numeric nocase' keep 'F*'; check functions
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

if test_function swap ; then
  d=${TMPDIR:-/tmp}/jln_zsh_script
  dq=${(q)d}

  [[ -d $d ]] && rm -r $d
  mkdir -p $d/a
  :>$d/b

  test $d/a $d/c; check_error "xxx: '$d/c': No such file or directory"
  test $d/b $d/a/; check_cmd "[[ -f $dq/a ]]" "[[ -d $dq/b ]]"
  test $d/b/ $d/a; check_cmd "[[ -d $dq/a ]]" "[[ -f $dq/b ]]"
fi

s='Lorem Ipsum is
simply dummy text
of the printing and
typesetting industry'

if test_function zhead ; then
  test 0 <<<$s; check_s
  test 1 <<<$s; check_s 'Lorem Ipsum is'
  test 2 <<<$s; check_s $'Lorem Ipsum is\nsimply dummy text'
  test 5 <<<$s; check_s $s
  test -1 <<<$s; check_s 'typesetting industry'
  test -2 <<<$s; check_s $'of the printing and\ntypesetting industry'
  test -5 <<<$s; check_s $s
fi

if test_function zg ; then
  GREP_COLOR='1;31'
  color=$'\x1b[1;31m'
  reset=$'\x1b[0m'
  test in <<<$s; check_s $'of the printing and\ntypesetting industry'
  test -v in <<<$s; check_s $'Lorem Ipsum is\nsimply dummy text'
  test -a in <<<$s; check_s "of the pr${color}in${reset}t${color}in${reset}g and"$'\n'"typesett${color}in${reset}g ${color}in${reset}dustry"
  test -av in <<<$s; check_s $'Lorem Ipsum is\nsimply dummy text'

  test -C in <<<$s; check_s "Lorem Ipsum is
simply dummy text
of the pr${color}in${reset}t${color}in${reset}g and
typesett${color}in${reset}g ${color}in${reset}dustry"

  test -VC in <<<$s; check_s "${color}Lorem Ipsum is${reset}
${color}simply dummy text${reset}
${color}of the pr${reset}in${color}t${reset}in${color}g and${reset}
${color}typesett${reset}in${color}g ${reset}in${color}dustry${reset}"
fi

if test_function zs ; then
  test r 2,3 <<<$s; check_s $'simply dummy text\nof the printing and'
  test r 2,-2 <<<$s; check_s $'simply dummy text\nof the printing and'
  test r 3, <<<$s; check_s $'of the printing and\ntypesetting industry'
  test r ,2 <<<$s; check_s $'Lorem Ipsum is\nsimply dummy text'
  test r ,2 s m X <<<$s; check_s $'LoreX Ipsum is\nsiXply dummy text'
  test r ,2 gs m X <<<$s; check_s $'LoreX IpsuX is\nsiXply duXXy text'
fi


if (( failure )); then
  echo "failure: $failure on $total" >&2
  exit 1
else
  echo "$total tests ok"
fi
