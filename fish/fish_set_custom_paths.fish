#
# Add various folders to the PATH
#

function fish_set_custom_paths --description "Set my current PATH variables"

    # github/pages-engineering's dotfiles (if it exists locally only)
    set pages_engineering_dotfiles ~/work-repos/github@pages-engineering/dotfiles/bin/
    if test -d $pages_engineering_dotfiles
        set -U fish_user_paths $pages_engineering_dotfiles $fish_user_paths
    end

end