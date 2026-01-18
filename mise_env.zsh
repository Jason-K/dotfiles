export PATH='/Users/jason/.local/bin:/Users/jason/.cache/lm-studio/bin:/Users/jason/.antigravity/antigravity/bin:/Users/jason/dotfiles/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/pmk/env/global/bin:/opt/X11/bin:/Library/Apple/usr/bin:/Applications/Privileges.app/Contents/MacOS:/Applications/Wireshark.app/Contents/MacOS:/Applications/Little Snitch.app/Contents/Components:/usr/local/share/dotnet:~/.dotnet/tools:/usr/local/go/bin:/opt/homebrew/bin:/Users/jason/.cargo/bin:/opt/homebrew/sbin'
precmd_functions=( ${precmd_functions:#_mise_hook_precmd} )
chpwd_functions=( ${chpwd_functions:#_mise_hook_chpwd} )
(( $+functions[_mise_hook_precmd] )) && unset -f _mise_hook_precmd
(( $+functions[_mise_hook_chpwd] )) && unset -f _mise_hook_chpwd
(( $+functions[_mise_hook] )) && unset -f _mise_hook
(( $+functions[mise] )) && unset -f mise
unset MISE_SHELL
unset __MISE_DIFF
unset __MISE_SESSION
unset __MISE_ZSH_PRECMD_RUN
export MISE_SHELL=zsh
if [ -z "${__MISE_ORIG_PATH:-}" ]; then
  export __MISE_ORIG_PATH="$PATH"
fi
export __MISE_ZSH_PRECMD_RUN=0

mise() {
  local command
  command="${1:-}"
  if [ "$#" = 0 ]; then
    command /Users/jason/.local/bin/mise
    return
  fi
  shift

  case "$command" in
  deactivate|shell|sh)
    # if argv doesn't contains -h,--help
    if [[ ! " $@ " =~ " --help " ]] && [[ ! " $@ " =~ " -h " ]]; then
      eval "$(command /Users/jason/.local/bin/mise "$command" "$@")"
      return $?
    fi
    ;;
  esac
  command /Users/jason/.local/bin/mise "$command" "$@"
}

_mise_hook() {
  eval "$(/Users/jason/.local/bin/mise hook-env -s zsh)";
}
_mise_hook_precmd() {
  eval "$(/Users/jason/.local/bin/mise hook-env -s zsh --reason precmd)";
}
_mise_hook_chpwd() {
  eval "$(/Users/jason/.local/bin/mise hook-env -s zsh --reason chpwd)";
}
typeset -ag precmd_functions;
if [[ -z "${precmd_functions[(r)_mise_hook_precmd]+1}" ]]; then
  precmd_functions=( _mise_hook_precmd ${precmd_functions[@]} )
fi
typeset -ag chpwd_functions;
if [[ -z "${chpwd_functions[(r)_mise_hook_chpwd]+1}" ]]; then
  chpwd_functions=( _mise_hook_chpwd ${chpwd_functions[@]} )
fi

_mise_hook
if [ -z "${_mise_cmd_not_found:-}" ]; then
    _mise_cmd_not_found=1
    [ -n "$(declare -f command_not_found_handler)" ] && eval "${$(declare -f command_not_found_handler)/command_not_found_handler/_command_not_found_handler}"

    function command_not_found_handler() {
        if [[ "$1" != "mise" && "$1" != "mise-"* ]] && /Users/jason/.local/bin/mise hook-not-found -s zsh -- "$1"; then
          _mise_hook
          "$@"
        elif [ -n "$(declare -f _command_not_found_handler)" ]; then
            _command_not_found_handler "$@"
        else
            echo "zsh: command not found: $1" >&2
            return 127
        fi
    }
fi
