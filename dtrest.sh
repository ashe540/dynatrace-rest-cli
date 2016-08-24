#!/bin/bash

# Try invoking this script with:
#   'scriptname -mn'
#   'scriptname -oq qOption' (qOption can be some arbitrary string.)
#   'scriptname -qXXX -r'
#
#   'scriptname -qr'
#+      - Unexpected result, takes "r" as the argument to option "q"
#   'scriptname -q -r' 
#+      - Unexpected result, same as above
#   'scriptname -mnop -mnop'  - Unexpected result
#   (OPTIND is unreliable at stating where an option came from.)
#
#  If an option expects an argument ("flag:"), then it will grab
#+ whatever is next on the command-line.

NO_ARGS=0 
E_OPTERROR=85

if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
  echo "Usage: `basename $0` options (-mnopqrs)"
  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi  

help () {
  echo ""
  echo "Usage: `basename $0` options"
  echo "-h      Prints help for different options"
  echo ""
  echo "-p      Options for Performance Warehouse"
  echo "    connect         Connects Performance Warehouse"
  echo "    disconnect      Disconnects Performance Warehouse"
  echo ""
  echo "-s      Options for Dynatrace Server"

  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
  
}


while getopts ":hp:s:" Option
do
  case $Option in
    h     ) help $OPTARG;;
    p     ) echo "option -m- \"$OPTARG\"";;
    s     ) echo "Scenario #5: option -$Option";;
    *     ) echo "Missing argument or unimplemented option chosen."; help;;   # Default.
  esac
done

shift $(($OPTIND - 1))
#  Decrements the argument pointer so it points to next argument.
#  $1 now references the first non-option item supplied on the command-line
#+ if one exists.

exit $?
