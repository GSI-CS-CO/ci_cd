export SWITCHES_DOT_JSON='../../switches.json'     # file with WR switch access info

# Function to evaluate command exit status
function exit_if_failed {
  # $1 - command return value
  # $2 - output text in case of command failure

  if [ $1 -ne 0 ]; then
    echo $2
    exit $1
  fi
}

