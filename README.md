## Docs

Each file is self-documented. Some widgets support `zstyle` option and `NUMERIC` variable.

## Config

```zsh
# in ~/.zshrc
ZSH_SCRIPT=the-project-path
fpath+=(${ZSH_SCRIPT}/widgets ${ZSH_SCRIPT}/functions)
autoload list-of-function-and-widget-used
zle -N a-widget
zle -N an-another-widget
# ...

bindkey bindkey '^[^K' jln-kill-arg # bind a widget on ctrl+alt+k
```

## Some examples

## jln-glob

```zsh
alias ng='noglob jln-glob numeric' # sort numerically

# 3 files listed in lexicographic order
echo *
# file-1 file-11 file-2

# 3 files listed in natural order
ng echo *
# file-1 file-2 file-11
```

## smart-sudo

```zsh
alias l='ls -CF'
smart-sudo l # run sudo ls -CF
```

## jln-transpose-arg

```zsh
$ cp a-file 'another file'
                          ^ cursor
# jln-transpose-arg
$ cp 'another file' a-file
                          ^ cursor
```

```zsh
$ cp a-file 'another file' one-more-file
        ^ cursor
# jln-transpose-arg
$ cp 'another file' a-file one-more-file
                           ^ cursor
```

## Tests

    ./test/all.zsh [function|widget...]
