# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"


# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(zsh-autosuggestions gitfast)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


# Setup Configs .sh files
for fname in $(find ~/mydotfiles/configs -name "*.sh*"); do
    source $fname
done

# Link zsh aliases
for fname in $(find ~/mydotfiles/zsh/aliases  -name "*.sh*"); do
    source $fname
done

# Link zsh functions
for fname in $(find ~/mydotfiles/zsh/functions -name "*.sh*"); do
    source $fname
done

# Link zsh envs
for fname in $(find ~/mydotfiles/zsh/envs -name "*.sh*"); do
    source $fname
done

# Link zsh secrets
for fname in $(find ~/mydotfiles/zsh/secrets -name "*.sh*"); do
    source $fname
done

# Misc Shell settings
set -o vi

# Prompt
_fishy_collapsed_wd() {
  echo $(pwd | perl -pe "
   BEGIN {
      binmode STDIN,  ':encoding(UTF-8)';
      binmode STDOUT, ':encoding(UTF-8)';
   }; s|^$HOME|~|g; s|/([^/])[^/]*(?=/)|/\$1|g
")
}

_get_aws_account(){
  aws_account_name=${AWS_PROFILE:u}
  if [[ "$aws_account_name" =~ "TEST" ]]; then
    echo "%{$fg_bold[green]%} $aws_account_name"
  elif [[ "$aws_account_name" =~ "QA" ]]; then
    echo "%{$fg_bold[yellow]%} $aws_account_name"
  elif [[ "$aws_account_name" =~ "PROD" ]]; then
    echo "%{$fg_bold[red]%} $aws_account_name"
  else
    echo "%{$fg_bold[blue]%} $aws_account_name"
  fi
}

_get_pulumi_backend_account(){
  PULUMI_CREDS_FILE=~/.pulumi/credentials.json
  if test -f "$PULUMI_CREDS_FILE"; then
    PULUMI_ACCOUNT_NUMBER=$(jq -r .current $PULUMI_CREDS_FILE | cut -d '-' -f4)
    echo $(jq -r ".accountList[] | select( .accountId == \"$PULUMI_ACCOUNT_NUMBER\" ) | .accountName" ~/.aws/sso_accounts.json | tr a-z A-Z)
  fi
}

_compare_aws_pulumi_account(){
  PULUMI=$( _get_pulumi_backend_account)
  AWS_ACCOUNT_NAME=${AWS_PROFILE:u}
  if [ ! -z ${AWS_PROFILE+x} ] && [ -n "$PULUMI" ]; then
    if [[ "$AWS_ACCOUNT_NAME" =~ "$PULUMI" ]]; then
      echo '🏆'
    else
      echo '❌'
    fi
  fi
}

exit_code='%(?.👌.👎)'
local user_color='cyan'; [ $UID -eq 0 ] && user_color='red'
# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
PROMPT='%{$fg_bold[$user_color]%}$(_fishy_collapsed_wd)$(_get_aws_account)$(_compare_aws_pulumi_account)$exit_code%{$fg[green]%}%(!.#. $)%{$reset_color%} '

# z Jump Around - https://github.com/rupa/z - installed via git clone and sourced below
source ~/z/z.sh

# zsh syntax highlighting - installed via homebrew (see Brewfile)
source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/ethan.rogers/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
