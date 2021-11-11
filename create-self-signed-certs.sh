#!/bin/sh

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "This Script creates certificates and private keys"
   echo
   echo "Syntax: $0 [-n|-i|-r|-p]"
   echo ""
   echo "options:"
   echo "r     Remove CAcert and create a new one (default=true)."
   echo "n     Server domain name (required)."
   echo "i     Server IP address (required)."
   echo "p     Password for importing/exporting the client PKCS#12 certificate (default=root)."
   echo
   echo "Example: $0 -n myserver.domain.com -i 66.66.66.66 -r false -p pass"
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################
SERVER_NAME=""
SERVER_IP=""
CLIENTPASS=""
REMOVE_CA="true"



############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":n:i:r:p:" option; do
   case $option in
      r)
         REMOVE_CA=$OPTARG;;
      n)
         SERVER_NAME=$OPTARG;;
      i)
         SERVER_IP=$OPTARG;;
      p)
         CLIENTPASS=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         echo ""
         Help
         exit;;
   esac
done


if [[ "$SERVER_NAME" == "" || "$SERVER_IP" == "" ]]; then
  echo ""
  echo "Error: You need to include the server name and the server IP with the options -s and -i"
  echo ""
  echo ""
  Help
  exit
fi


if [[ "$CLIENTPASS" == ""  ]]; then
  CLIENTPASS="root"
fi


SUBJ_CACERT="/CN=$(hostname)/ST=Madrid/C=ES/O=None/OU=None"
SUBJ_SERVER="/CN=${SERVER_NAME}/ST=Madrid/C=ES/O=None/OU=None"
SUBJ_CLIENT="/CN=$(hostname)/ST=Madrid/C=ES/O=None/OU=None"



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





if [[ $REMOVE_CA == "true" ]];then
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

openssl pkcs12 -export -out OUTPUT/client.cert.p12 -in OUTPUT/client.cert.pem -inkey OUTPUT/client.key.pem -passin pass:${CLIENTPASS} -passout pass:${CLIENTPASS}

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




 # Display Info
   echo ""
   echo ""
   echo "The certificates have been created in the OUPUT directory"
   echo ""
   echo ""

