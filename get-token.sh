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

export BEARER_TOKEN=$(curl \
  --disable \
  --silent \
  --insecure \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data "grant_type=password&client_id=orbis-u-webclient&orbis_facility_id=1&username=${USERNAME}&password=${PASSWORD}&=" \
  "https://${TOKEN_SERVER}/auth/realms/orbis/protocol/openid-connect/token" | \
    sed \
      --regexp-extended \
      --expression 's/\{"access_token":"([^"]*).*/\1/')