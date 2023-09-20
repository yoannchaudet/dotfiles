if status --is-interactive

  # Setup brew (bin and co)
  eval $(/opt/homebrew/bin/brew shellenv)

  # Start SSH-AGENT (if not done already)
  fish_ssh_agent

end
