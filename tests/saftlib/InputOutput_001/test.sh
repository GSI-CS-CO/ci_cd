#! /bin/sh
set -e

case "$1" in
 start)
  echo "Starting Test..."
  make clean
  make
  ./main baseboard IO1 IO3
  sleep 1
  ./main baseboard IO3 IO1
  ;;

 end)
  echo "Ending Test..."
  ;;

 *)
  echo "Usage: ./test {start|end}"
  exit 1
  ;;
esac

exit 0


