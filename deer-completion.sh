#/usr/bin/env bash
_ls()
{
  local cur
  COMPREPLY=()
  cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=($( compgen -W '$(deer ls)' -- $cur ) )
}

complete -F _ls deer
complete -F _ls deer pull
complete -F _ls deer start
complete -F _ls deer stop
complete -F _ls deer restart
