if status --is-interactive

  # Setup brew (bin and co)
  set brew_location /opt/homebrew/bin/brew
  if not test -e "$brew_location"
    set brew_location /usr/local/bin/brew
  end
  eval $($brew_location shellenv)

  # Start SSH-AGENT (if not done already)
  fish_ssh_agent

end
