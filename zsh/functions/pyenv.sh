#Run the virtual environments functions for the prompt on each cd <<2
# -------------------------------------------------------------------
cd() {
 builtin cd "$@"
 unset NODE_NAME
 deactivate > /dev/null 2>&1
 workon_virtualenv
}
#===============================================================================
# Workon virtualenv <<2
#--------------------------------------------------------------------
# If we cd into a directory that is named the same as a virtualenv
# auto activate that virtualenv
# -------------------------------------------------------------------
workon_virtualenv() {
 if [[ -d .git ]]; then
 VENV_CUR_DIR="${PWD##*/}"
 if [[ -a ~/.pyenv/versions/$VENV_CUR_DIR ]]; then
 deactivate > /dev/null 2>&1
 source ~/.pyenv/versions/$VENV_CUR_DIR/bin/activate
 fi
 fi
}

# Make virtualenv <<2
#--------------------------------------------------------------------
# If we create a virtualenv, put it in ~/.pyenv/versions to allow for
# auto activation of that virtualenv
#mkvirtualenv() {
# deactivate > /dev/null 2>&1
# VENV_CUR_DIR="${PWD##*/}"
# pushd ~/.pyenv/versions
# pyenv virtualenv $VENV_CUR_DIR -p /usr/local/bin/python
# popd
# source ~/.pyenv/versions/$VENV_CUR_DIR/bin/activate
#}