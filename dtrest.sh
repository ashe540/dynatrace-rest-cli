#!/bin/bash

# User Authentication:
#   Provide user name and password to authenticate against the Dynatrace Server
#     The authentication technique follows the RFC 2617 standard. 
#     The BASE 64 hash key must be calculated based on the concatenated 
#     string consisting of the user name, a colon ( : ),  and the password. 
#
#     The string Basic plus the hash key must be set as the Authorization 
#     header to the HTTP request.
#
#     To generate the credentials use the following command in your terminal
#       echo -n "Aladdin:OpenSesame" | base64

#     (The -n makes sure there's not an extra newline being encoded)
#
#     This will return a string 'QWxhZGRpbjpPcGVuU2VzYW1l' that is used like so:
#     Authorization: Basic QWxhZGRpbjpPcGVuU2VzYW1l


# Example request:
#
# curl -H "Authorization: Basic <ACCESS_TOKEN>" http://DT_SERVER:8021
#
#  If an option expects an argument ("flag:"), then it will grab
#+ whatever is next on the command-line.

DT_SERVER=localhost
PORT=8021
REQUEST_URL=/rest/management/
ACCESS_TOKEN=YWRtaW46YWRtaW4=

DBNAME=dynaTrace63
DBMS=embedded

SERVER_URL="https://"$DT_SERVER":"$PORT

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
  echo "-h   Prints help for different options"
  echo ""
  echo "-p   Options for Performance Warehouse"
  echo "         status         Returns Performance Warehouse status"
  echo "         restart        Pushes new configuration to PWH and restarts it in the background"
  echo ""
  echo "-s   Options for Dynatrace Server"
  echo "         version         Returns Dynatrace Server version"
  echo "         license         Retrieves license information"
  echo "         restart         Restarts Dynatrace Server"
  echo "         shutdown        Shutdown Dynatrace Server"
  echo "         generateSupport Generate support archive on the server"
  echo ""

  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
}

performanceWarehouse () {
  REQUEST_URL=$REQUEST_URL"pwhconnection/"
  
  case $1 in
    status    ) pwhStatus;;
    restart   ) pwhRestart;;
    *         ) echo "Unknown command $1.";; # Default.
  esac
}

server () {
  SERVER_URL=$REQUEST_URL"server/"
  VERSION_URL=$REQUEST_URL"version"
  
  case $1 in
    version         ) version $VERSION_URL;;
    license         ) serverLicense $SERVER_URL;;
    restart         ) serverRestart $SERVER_URL;;
    shutdown        ) serverShutdown $SERVER_URL;;
    *               ) echo "Unknown command $1.";; # Default.
  esac
}

version () {
  curl -s -k -H "Authorization: Basic $ACCESS_TOKEN" $1
}

serverLicense () {
  REQUEST_URL=$1"license/information"
  curl -s -k -H "Authorization: Basic $ACCESS_TOKEN" $REQUEST_URL
}

serverRestart () {
  REQUEST_URL=$1"restart"
  curl -s -k -H "Authorization: Basic $ACCESS_TOKEN" $REQUEST_URL
}

serverShutdown () {
  REQUEST_URL=$1"shutdown"
  curl -s -k -H "Authorization: Basic $ACCESS_TOKEN" $REQUEST_URL
}

pwhStatus () {
  REQUEST_URL=$REQUEST_URL"status.json"
  ENDPOINT=$SERVER_URL$REQUEST_URL
  curl -s -k -H "Authorization: Basic $ACCESS_TOKEN" $ENDPOINT
}

pwhRestart () {
  REQUEST_URL=$REQUEST_URL"config.json?httpMethod=PUT"
  ENDPOINT=$SERVER_URL$REQUEST_URL
  curl -s -k \
    -H "Authorization: Basic $ACCESS_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -X POST -d "{\"dbname\":\""$DBNAME"\",\"dbms\":\""$DBMS"\"}" \
    $ENDPOINT

}

while getopts ":hp:s:" Option
do
  case $Option in
    h     ) help;;
    p     ) performanceWarehouse $OPTARG;;
    s     ) server $OPTARG;;
    *     ) echo "Missing argument or unimplemented option chosen."; help;;   # Default.
  esac
done

shift $(($OPTIND - 1))
#  Decrements the argument pointer so it points to next argument.
#  $1 now references the first non-option item supplied on the command-line
#+ if one exists.

exit $?
