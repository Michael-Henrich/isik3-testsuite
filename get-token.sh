if [ -z ${3+x} ]; then
  echo "+--------------------------------------------------------------------------+"
  echo "| Usage: ./get-token.sh <host> <username> <password>                       |"
  echo "| Usage: ./get-token.sh vmnae-proxy.orbis.dedalus.com doctor safePassword  |"
  echo "+--------------------------------------------------------------------------+"
  exit 1
fi

TOKEN_SERVER=$1
USERNAME=$2
PASSWORD=$3

if RESPONSE=$(curl \
  --disable \
  --insecure \
  --silent \
  --fail \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data "grant_type=password&client_id=orbis-u-webclient&orbis_facility_id=1&username=${USERNAME}&password=${PASSWORD}&=" \
  "https://${TOKEN_SERVER}/auth/realms/orbis/protocol/openid-connect/token"); then

  BEARER_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')

  if [ -z "$BEARER_TOKEN" ] || [ "$BEARER_TOKEN" == "null" ]; then
    echo "Token is missing or malformed in the JSON response"
    exit 1
  fi

  export BEARER_TOKEN
  echo "Valid token retrieved. Starting tests..."
else
  echo "Failed to retrieve token. Please check the host address, your username and password"
  exit 1
fi
