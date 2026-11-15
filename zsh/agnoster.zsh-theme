# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segments of the prompt, default order declaration

typeset -aHg AGNOSTER_PROMPT_SEGMENTS=(
    prompt_status
    prompt_context
    prompt_virtualenv
    prompt_dir
    prompt_git
    prompt_conflicts
    prompt_end
)

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
if [[ -z "$PRIMARY_FG" ]]; then
	PRIMARY_FG=black
fi

# Characters
LEFT_SEPARATOR=""
RIGHT_SEPARATOR=""
PLUSMINUS=""
PLUS=""
BRANCH=""
DETACHED=""
CROSS=""
LIGHTNING=""
GEAR=""

typeset -gi AGNOSTER_GIT_STAGED=0 AGNOSTER_GIT_UNSTAGED=0 AGNOSTER_GIT_CONFLICTS=0
typeset -gF AGNOSTER_COMMAND_STARTED_AT=0
typeset -g AGNOSTER_COMMAND_DURATION=''

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n "%{$bg%F{$CURRENT_BG}%}$RIGHT_SEPARATOR%{$fg%}"
  else
    print -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n "%{%k%F{$CURRENT_BG}%}$RIGHT_SEPARATOR"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CONNECTION" ]]; then
    prompt_segment $PRIMARY_FG default " %(!.%{%F{yellow}%}.)$user@%m "
  fi
}

# Collect Git counts once for both sides of the prompt.
prompt_agnoster_git_status() {
  local entry xy
  AGNOSTER_GIT_STAGED=0
  AGNOSTER_GIT_UNSTAGED=0
  AGNOSTER_GIT_CONFLICTS=0
  [[ -n "$vcs_info_msg_0_" ]] || return 0

  while IFS= read -r -d '' entry; do
    xy=${entry[1,2]}
    case "$xy" in
      DD|AU|UD|UA|DU|AA|UU)
        (( AGNOSTER_GIT_CONFLICTS += 1 )) ;;
      '??')
        (( AGNOSTER_GIT_UNSTAGED += 1 )) ;;
      *)
        [[ ${xy[1]} != ' ' ]] && (( AGNOSTER_GIT_STAGED += 1 ))
        [[ ${xy[2]} != ' ' ]] && (( AGNOSTER_GIT_UNSTAGED += 1 )) ;;
    esac
    # Renames/copies have a second NUL-delimited path, not a status entry.
    if [[ ${xy[1]} == [RC] || ${xy[2]} == [RC] ]]; then
      IFS= read -r -d '' entry
    fi
  done < <(git status --porcelain=v1 -z --untracked-files=all --ignore-submodules)
}

# Git: branch/detached head and staged/unstaged file counts.
prompt_git() {
  local color ref marker=''
  ref="$vcs_info_msg_0_"
  if [[ -n "$ref" ]]; then
    (( AGNOSTER_GIT_STAGED )) && marker+=" $PLUS$AGNOSTER_GIT_STAGED"
    (( AGNOSTER_GIT_UNSTAGED )) && marker+=" $PLUSMINUS$AGNOSTER_GIT_UNSTAGED"
    if (( AGNOSTER_GIT_STAGED || AGNOSTER_GIT_UNSTAGED || AGNOSTER_GIT_CONFLICTS )); then
      color=yellow
      ref+="$marker"
    else
      color=green
      ref="${ref} "
    fi
    if [[ "${ref/.../}" == "$ref" ]]; then
      ref="$BRANCH $ref"
    else
      ref="$DETACHED ${ref/.../}"
    fi
    prompt_segment $color $PRIMARY_FG
    print -n " $ref"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue $PRIMARY_FG ' %~ '
}

# Conflicts: the last segment of the left prompt, after the Git segment.
prompt_conflicts() {
  if (( AGNOSTER_GIT_CONFLICTS )); then
    prompt_segment red white " !$AGNOSTER_GIT_CONFLICTS "
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}$CROSS"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}$LIGHTNING"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}$GEAR"

  [[ -n "$symbols" ]] && prompt_segment $PRIMARY_FG default " $symbols "
}

# Display current virtual environment
prompt_virtualenv() {
  if [[ -n $VIRTUAL_ENV ]]; then
    color=cyan
    prompt_segment $color $PRIMARY_FG
    print -Pn " $(basename $VIRTUAL_ENV) "
  fi
}

## Main prompt
prompt_agnoster_main() {
  CURRENT_BG='NONE'
  for prompt_segment in "${AGNOSTER_PROMPT_SEGMENTS[@]}"; do
    [[ -n $prompt_segment ]] && $prompt_segment
  done
}

prompt_agnoster_right_segment() {
  local bg=$1 fg=$2 text=$3
  print -nr -- "%{%k%F{$bg}%}$LEFT_SEPARATOR%{%K{$bg}%F{$fg}%} $text %{%k%F{$bg}%}$RIGHT_SEPARATOR%{%f%}"
}

prompt_agnoster_right() {
  if [[ -n "$AGNOSTER_COMMAND_DURATION" ]]; then
    prompt_agnoster_right_segment 8 default "$AGNOSTER_COMMAND_DURATION"
  fi
}

prompt_agnoster_preexec() {
  AGNOSTER_COMMAND_STARTED_AT=$EPOCHREALTIME
}

prompt_agnoster_precmd() {
  local last_status=$?
  local -F elapsed
  local -i duration_seconds
  RETVAL=$last_status
  AGNOSTER_COMMAND_DURATION=''
  if (( AGNOSTER_COMMAND_STARTED_AT > 0 )); then
    elapsed=$(( EPOCHREALTIME - AGNOSTER_COMMAND_STARTED_AT ))
    if (( elapsed > 5 )); then
      printf -v duration_seconds '%.0f' "$elapsed"
      if (( duration_seconds >= 3600 )); then
        printf -v AGNOSTER_COMMAND_DURATION '%dh %dm %ds' \
          $(( duration_seconds / 3600 )) $(( duration_seconds / 60 % 60 )) $(( duration_seconds % 60 ))
      elif (( duration_seconds >= 60 )); then
        printf -v AGNOSTER_COMMAND_DURATION '%dm %ds' \
          $(( duration_seconds / 60 )) $(( duration_seconds % 60 ))
      else
        AGNOSTER_COMMAND_DURATION="${duration_seconds}s"
      fi
    fi
    AGNOSTER_COMMAND_STARTED_AT=0
  fi
  vcs_info
  prompt_agnoster_git_status
  PROMPT='%{%f%b%k%}$(prompt_agnoster_main) '
  RPROMPT='$(prompt_agnoster_right)'
}

prompt_agnoster_setup() {
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info
  zmodload zsh/datetime

  prompt_opts=(cr subst percent)

  add-zsh-hook precmd prompt_agnoster_precmd
  add-zsh-hook preexec prompt_agnoster_preexec

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' check-for-changes false
  zstyle ':vcs_info:git*' formats '%b'
  zstyle ':vcs_info:git*' actionformats '%b (%a)'
}

prompt_agnoster_setup "$@"
