#!/bin/sh

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "This Script creates certificates and private keys"
   echo
   echo "Syntax: $0 [-n|-i|-k]"
   echo ""
   echo "options:"
   echo "k     Keep old CAcert (it does not create a new one)."
   echo "n     Server domain name (required)."
   echo "i     Server IP address (required)."
   echo
   echo "Example: $0 -n myserver.domain.com -i 66.66.66.66"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################
SERVER_NAME=""
SERVER_IP=""
REMOVE_CA=true





############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":n:i:k:" option; do
   case $option in
      k)
         REMOVE_CA=false;;
      n)
         SERVER_NAME=$OPTARG;;
      i)
         SERVER_IP=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         echo ""
         Help
         exit;;
   esac
done

echo "$SERVER_NAME -  $SERVER_IP"

if [[ "$SERVER_NAME" == "" || "$SERVER_IP" == "" ]]; then
  echo ""
  echo "Error: You need to include the server name and the server IP with the options -s and -i"
  echo ""
  echo "Example: $0 -n myserver.domain.com -i 66.66.66.66"
  echo ""
  exit
fi




SUBJ_CACERT="/C=ES/ST=Madrid/L=Madrid/O=None/CN=$(hostname)"
SUBJ_SERVER="/C=ES/ST=Madrid/L=Madrid/O=None/CN=${SERVER_NAME}"
SUBJ_CLIENT="/C=ES/ST=Madrid/L=Madrid/O=None/CN=$(hostname)"




touch index.txt

echo 01 > serial


cat <<EOF > client_ext.cnf
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection
EOF



cat <<EOF > server_ext.cnf
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
IP.1 = ${SERVER_IP}
DNS.1 = ${SERVER_NAME}
EOF





if [[ $REMOVE_CA ]];then
  rm -rf OUTPUT/cacert.pem
  rm -rf OUTPUT/cakey.pem

  echo ""
  echo "**********************************************"
  echo "Creating CA cert"
  echo "**********************************************"
  echo ""

  openssl genrsa -out OUTPUT/cakey.pem 4096
  openssl req -new -subj ${SUBJ_CACERT} -x509 -days 3650 -config openssl.cnf -key OUTPUT/cakey.pem -out OUTPUT/cacert.pem
  openssl x509 -in OUTPUT/cacert.pem -out OUTPUT/cacert.pem -outform PEM


fi



echo ""
echo ""
echo "**********************************************"
echo "Creating client certificate and private key"
echo "**********************************************"
echo ""

rm -f OUTPUT/client.cert.pem
rm -f OUTPUT/client.key.pem

openssl genrsa -out OUTPUT/client.key.pem 4096
openssl req -new -subj ${SUBJ_CLIENT} -key OUTPUT/client.key.pem -out OUTPUT/client.csr
openssl ca -config openssl.cnf -extfile client_ext.cnf -days 3650 -notext -batch -in OUTPUT/client.csr -out OUTPUT/client.cert.pem

chmod 400 OUTPUT/client.cert.pem

rm -f OUTPUT/client.csr



echo ""
echo ""
echo "**********************************************"
echo "Creating server certificate and private key"
echo "**********************************************"
echo ""

rm -f OUTPUT/server.cert.pem
rm -f OUTPUT/server.key.pem

openssl genrsa -out OUTPUT/server.key.pem 4096
openssl req -new -subj ${SUBJ_SERVER} -key OUTPUT/server.key.pem -out OUTPUT/server.csr
openssl ca -config openssl.cnf -extfile server_ext.cnf -days 3650 -notext -batch -in OUTPUT/server.csr -out OUTPUT/server.cert.pem

chmod 400 OUTPUT/server.cert.pem

rm -f OUTPUT/server.csr



### CLEANING
rm -f serial*
rm -f index.*

rm -f client_ext.cnf
rm -f server_ext.cnf
