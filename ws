#!/usr/bin/env bash

# TODO:
# - test yaml parser on more use cases
# - add obvious docker fail checks
# - wrap docker ps command
# - on workspace init source commands(cmd entries names), so no scripts in .local/bin will be necessary
# - make shell option default if no action is specified
# - handle containers that already exists
# - add case for enclosed array in extract

log() {
  echo "Error: $1" >&2
}

# This is a simple yaml element extractor, $2 is the Mapping
extract() {
  # Checks arguments
  if ! [ -n "$1" ] || ! [ -n "$2" ]; then
    echo ""
    return
  fi

  # Removes comments
  local file=$(echo "$1" | sed 's/ #.*//' | sed '/^$/d')

  # Extracts the mapping to be processed
  local node=$(echo "$file" | sed -n "/^$2:/,/^[A-Za-z].*:/{/^\s/{s/\s\s//;p;}}")
  if [ "$node" == "" ]; then
    node=$(echo "$file" | sed -n "/^$2:/,/^[A-Za-z].*:/{/\s/{s/\s\s//;p;}}")
  fi

  local num=$(echo "$node" | grep -o '^[A-Za-z].*:' | wc -l)

  # Tries to extract single element
  if [ "$num" -eq "1" ]; then
    if [[ "${node}" == $2:* ]]; then
      echo "$node" | cut -d : -f 2 | tr -d "'\"" # this might break the code
      return
    fi
    echo "$node"
    return
  fi

  # Tries to extract array
  if [ "$num" -eq "0" ]; then
    echo "$node" | sed "s/\-//" | tr -d '"'
    return
  fi

  local frag=$(echo "$node" | sed -n "/^$2/p" | cut -d : -f 2 | tr -d "'\"")
  if ! [ "$frag" == "" ]; then
    echo $frag
    return
  fi
  echo "$node"
}

# Get ws configuration file
check_config() {
  if ! [ -n "$HOME/.config/workspace/config.yml" ]; then
    log "no configuration file found"
    exit 1
  else
    echo "$(cat $HOME/.config/workspace/config.yml)"
  fi
}

show_help () {
  cat <<EOF
  Usage: ws [opt] [workspace] [cmd]

    Commands:
      help                        : Show this message.
      build   <workspace>         : Build the workspace image.
      run     <workspace>         : Start workspace.
      exec    <workspace> <cmd>   : Execute a command in the workspace.
      stop    <workspace>         : Stop the workspace.

EOF
  exit 0
}

ws() {
  if ! [ -n "$1" ] || ! [ -n "$2" ]; then
    log "No option was provided."
    show_help
  fi

  local action="$1"
  local workspace="$2"

  local file=$(check_config)
  file=$(extract "$file" "$workspace")
  if ! [ -n "$file" ]; then
    log "$workspace workspace does not exist in configuration file"
    exit 1
  fi
  if [ "$action" != "stop" ]; then
    file=$(extract "$file" "$action")
    if ! [ -n "$file" ]; then
      log "No valid workspace action provided"
      exit 1
    fi
  fi

  case "$action" in
  "build")
    local path=$(extract "$file" path)
    local args=$(extract "$file" args | sed 's/ /\-\-build-arg /')
    local build="docker build $args -t $workspace $path"
    echo $build
    exit 0
    ;;
  "run")
    local env=$(extract "$file" env | sed 's/ /\-e /' | sed "s/'/\"/g")
    local args=$(extract "$file" args | tr -d "'\"")
    local volumes=$(extract "$file" volumes | sed 's/ /\-v /' | sed "s/'/\"/g")
    local run="docker run -d --name $workspace -it $args $volumes $env $workspace"
    echo $run
    exit 0
    ;;
  "exec")
    if docker ps -q --filter "name=$workspace" | grep -q .; then
      local args=$(extract "$file" args | tr -d "'\"")
      local cmd=$(extract "$file" cmd)
      local run=''
      local t=''
      if [ "$3" == "tty" ]; then
        run=$(extract "$cmd" "$4")
        t=t
      else
        run=$(extract "$cmd" "$3")
      fi
      if ! [ -n "$run" ]; then
        log "No command provided or missing"
        exit 1
      fi
      if ! [ -n "$t" ]; then
        local exec="docker exec -${t}i $args $workspace bash -c "
        shift 3
        for a in "$@"; do
          run="${run} ${a}"
        done
        exec="${exec}'${run}'"
        echo $exec
        exit 0
      fi
        local exec="docker exec -${t}i $args $workspace bash -c '$run'"
        echo $exec
    else
      log "$workspace doesn't seem to be running"
      exit 1
    fi
    ;;
  "stop")
    echo "Info: stopping $workspace workspace!"
    if ! docker ps -q --filter "name=$workspace" | grep -q .; then
      log "$workspace doesn't seem to be running"
      exit 1
    else
      docker stop $workspace >/dev/null
      local output="$(docker rm $workspace)"
      if [ $? -eq 0 ]; then
        echo "Info: $workspace workspace finished successfully."
        exit 0
      else
        log "$workspace workspace output:\n $output"
        exit 1
      fi
    fi
    ;;
  "help")
    show_help
    ;;
  *)
    if ! [ -n "$action" ]; then
      log "No workspace action provided"
      exit 1
    fi
    log "$action action not found in configuration file"
    exit 1
    ;;
  esac
  exit 0
}

ws "$@"
