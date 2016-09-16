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

# SERVER SETTINGS CONFIGURATION
DT_SERVER=localhost
PORT=8021
ACCESS_TOKEN=YWRtaW46YWRtaW4= #YOUR_DT_CREDENTIALS_IN_BASE64 # Refer to explanation above

# PERFORMANCE WAREHOUSE CONFIGURATION
# Use these settings only to replace current database configuration using "sh dtrest.sh -p save" command
NEW_DB_USER=
NEW_DB_PASS=
NEW_DB_HOST=
NEW_DB_PORT=
NEW_DB_NAME=
NEW_DBMS= #embedded, sqlserver, oracle, postgresql

#DO NOT EDIT ANYTHING BEYOND THIS LINE

DTSERVER_URL="https://"$DT_SERVER":"$PORT
REQUEST_URL=/rest/management/
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
  echo "         config         Returns Performance Warehouse current configuration"
  echo "         save           Pushes new configuration for the Performance Warehouse and restarts it in the background (set global config. variables in script)"
  echo "         connect        Connects the Dynatrace Server to the Performance Warehouse"
  echo "         disconnect     Disconnects the Dynatrace Server from the Performance Warehouse"
  echo "         restart        Disconnects and then connects to the Performance Warehouse"
  echo ""
  echo "-s   Options for Dynatrace Server"
  echo "         version         Returns Dynatrace Server version"
  echo "         license         Retrieves license information"
  echo "         restart         Restarts Dynatrace Server"
  echo "         shutdown        Shutdown Dynatrace Server"
  # echo "         generateSupport Generate support archive on the server"
  echo ""

  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
}

performanceWarehouse () {
  REQUEST_URL=$REQUEST_URL"pwhconnection/"

  case $1 in
    status     ) pwhStatus;;
    config     ) pwhConfig;;
    save       ) pwhSave;;
    connect    ) pwhConnect;;
    disconnect ) pwhDisconnect;;
    restart    ) pwhRestart;;
    *          ) echo "Unknown command $1.";; # Default.
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

  xml=$(curl -s -k \
    -H "Authorization: Basic $ACCESS_TOKEN" \
    -H "Accept: text/xml" \
    -H "Content-Type: text/xml" \
    $DTSERVER_URL$1)

  re=".*<result value=\"(.*)\"/>"
  if [[ $xml =~ $re ]]; then
    echo ${BASH_REMATCH[1]}
  fi

}

serverLicense () {
  REQUEST_URL=$DTSERVER_URL$1"license/information"
  sendGETRequest $REQUEST_URL
}

serverRestart () {
  REQUEST_URL=$DTSERVER_URL$1"restart"
  sendSimplePOSTRequest $REQUEST_URL
}

serverShutdown () {
  REQUEST_URL=$DTSERVER_URL$1"shutdown"
  sendSimplePOSTRequest $REQUEST_URL
}

pwhStatus () {
  REQUEST_URL=$DTSERVER_URL$REQUEST_URL"status.json"
  sendGETRequest $REQUEST_URL
}

pwhConfig () {
  REQUEST_URL=$DTSERVER_URL$REQUEST_URL"config.json"
  sendGETRequest $REQUEST_URL
}

pwhSave () {

  if [ -z "$NEW_DB_NAME" ] || [ -z "$NEW_DBMS" ] || [ -z "$NEW_DB_HOST" ] || [ -z "$NEW_DB_PORT" ] || [ -z "$NEW_DB_USER" ] || [ -z "$NEW_DB_PASS" ];
    then
      echo "Not all variables in the Performance Warehouse configuration section have been assigned data!" 1>&2
      echo "Exiting..." 1>&2
	    exit 1
  fi
  REQUEST_URL=$DTSERVER_URL$REQUEST_URL"config.json?httpMethod=PUT"
  config="{\"dbname\":\""$NEW_DB_NAME"\",\"dbms\":\""$NEW_DBMS"\",\"host\":\""$NEW_DB_HOST"\",\"port\":\""$NEW_DB_PORT"\",\"user\":\""$NEW_DB_USER"\",\"password\":\""$NEW_DB_PASS"\"}\""
  sendPOSTRequest $REQUEST_URL $config
}

pwhDisconnect () {
  REQUEST_URL=$DTSERVER_URL$REQUEST_URL"status.json?httpMethod=PUT"
  ENDPOINT=$REQUEST_URL
  config="{\"isconnected\":false}"
  sendPOSTRequest $ENDPOINT $config
}

pwhConnect () {
  if [ -z "$ENDPOINT" ]; then ENDPOINT=$DTSERVER_URL$REQUEST_URL"status.json?httpMethod=PUT"; fi
  config="{\"isconnected\":true}"
  sendPOSTRequest $ENDPOINT $config
}

pwhRestart () {
  pwhDisconnect
  echo
  pwhConnect
}

sendGETRequest() {
  curl -s -k -H "Authorization: Basic $ACCESS_TOKEN" $1
}

sendPOSTRequest () {
  curl -s -k \
    -H "Authorization: Basic $ACCESS_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -X POST -d $2 \
    $1
}

sendSimplePOSTRequest () {
  curl -s -k \
    -H "Authorization: Basic $ACCESS_TOKEN" \
    -X POST \
    $1
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
