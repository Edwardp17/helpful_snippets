## For pipenv auto-maintenance
function set_curr_dir {
    touch "$HOME/.tmp/CURR_DIR"
    echo "$(pwd)" > $HOME/.tmp/CURR_DIR
}

function cd_curr_dir {
    PIPENV_DIR=$(<$HOME/.tmp/CURR_DIR)
    builtin cd "$PIPENV_DIR"
}

function set_active_pipenv_dir {
    echo "$(pwd)" > $HOME/.tmp/ACTIVE_PIPENV
}

function auto_pipenv_shell {
    # Set the current directory, we need to keep track of this 
    set_curr_dir
    if [ ! -n "${PIPENV_ACTIVE+1}" ]; then
        # If pipenv is not active, loop recursively through directories
        #  to see if we can find a Pipfile. If a Pipfile is found in any
        #  parent directories, copy the Pipfile path to ACTIVE_PIPENV to
        #  keep track of the current Pipfile location. Also activate a new
        #  pipenv shell and break the while loop. If no Pipfile is found
        #  don't do anything. Cd into the original directory we wanted to be in
        #  after all of that.
        while [ $PWD != "/" ]; do
            if [ -f "Pipfile" ]; then
                touch "$HOME/.tmp/ACTIVE_PIPENV"
                set_active_pipenv_dir
                echo "PIPENV FOUND: ACTIVATING NEW PIPENV SHELL"
                pipenv shell
                break
            else
                builtin cd ..
            fi
        done
    elif [ -n "${PIPENV_ACTIVE+1}" ]; then
        # This part of the if/elif is for 1) switching pipenvs if we cd into a different
        #  pipenv shell-directory or exiting a pipenv if we cd out of the pipenv shell-directory.
        # If an active pipenv is found, recursively loop through parent directories
        #  until we find a Pipfile. If the found Pipfile is equal to our currently active
        #  shell-directory then do nothing. Otherwise active a new pipenv shell.
        SECONDARY_PIPENV='none'
        while [ $PWD != "/" ]; do
            if [ -f "Pipfile" ]; then
                SECONDARY_PIPENV="$(pwd)"
                if [ $SECONDARY_PIPENV = $(<$HOME/.tmp/ACTIVE_PIPENV) ]; then 
                    break
                else
                    echo $SECONDARY_PIPENV > $HOME/.tmp/ACTIVE_PIPENV
                    "DIFFERENT PIPENV FOUND: ACTIVATING NEW PIPENV SHELL"
                    pipenv shell
                    break
                fi
            else
                builtin cd ..
            fi 
        done
        if [ $SECONDARY_PIPENV = 'none' ]; then
            # If no Pipfile is found then we are likely out of a pipenv shell-directory.
            #  Therefore exit pipenv. Has a weird bug where if you init a pipenv shell yourself,
            #  then try to cd out of that shell-directory, it will exit the pipenv but not cd you
            #  into the CURR_DIR - not urgrent so won't spend time on it yet.
            echo "NO PIPENV FOUND: EXITING PIPENV SHELL"
            exit
        fi
    fi
    cd_curr_dir
}

function make_tmp_dir {
    mkdir -p "$HOME/.tmp"
}

function cd {
    builtin cd "$@"
    auto_pipenv_shell
    
}

function start_at_home {
# Without this, if you close terminal while in a pipenv shell-directory
#  then open terminal again, the above tries to run pipenv and gets a weird error
#  so this will always start your terminal at $HOME to avoid the error, but should not
#  impact pipenv shells.
    if [ ! -n "${PIPENV_ACTIVE+1}" ]; then
        echo "hi"
        builtin cd $HOME
    fi
}

start_at_home
make_tmp_dir
