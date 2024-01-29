#
# Add various folders to the PATH or export various variables
#

function fish_set_custom_paths --description "Set my current PATH variables"

    # github/pages-engineering's dotfiles (if it exists locally only)
    set pages_engineering_dotfiles ~/work-repos/github@pages-engineering/dotfiles/bin/
    if test -d $pages_engineering_dotfiles
        set -U fish_user_paths $pages_engineering_dotfiles $fish_user_paths
    end

    # goproxy
    # see https://github.com/github/goproxy/blob/main/doc/user.md#authentication-token
    # also need a PAT in ~/.netrc
    set -Ux GOPROXY https://goproxy.githubapp.com/mod,https://proxy.golang.org/,direct
    set -Ux GOPRIVATE ""
    set -Ux GONOPROXY ""
    set -Ux GONOSUMDB 'github.com/github/*'

    # Brew: Unversioned symlinks for python, python-config, pip etc.
    set -U fish_user_paths (brew --prefix python)/libexec/bin

end