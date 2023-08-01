#!/bin/bash

SERVER1=ec2-35-90-113-2543.us-west-2.compute.amazonaws.com
SERVER2=ec2-52-43-209-2403.us-west-2.compute.amazonaws.com
SERVER3=ec2-54-187-78-1003.us-west-2.compute.amazonaws.com


function log() {
    echo "$1" >&2
}

function die() {
    log "$1"
    exit 1
}

function check_exist() {
    [ ! -z "$(command -v java)" ] || die "The 'java' command is missing - Please install"
    [ ! -z "$(command -v openssl)" ] || die "The the 'openssl' command is missing - Please install"
    [ ! -z "$(command -v keytool)" ] || die "The the 'keytool' command is missing - Please install"
}

check_exist

set -o nounset \
    -o errexit
PASS="password"
printf "Deleting previous (if any)..."
mkdir -p secrets
mkdir -p tmp
mkdir -p ca
echo " OK!"

CA_CERT=ca/kafka-ca.crt
CA_KEY=ca/kafka-ca.key

# Generate CA key
printf "Creating CA..."
if [[ ! -f $CA_CERT ]] && [[ ! -f $CA_KEY ]];then
openssl req -new -x509 -keyout $CA_KEY -out $CA_CERT -days 3650 -subj '/CN=Kafka CA/OU=Devops/O=DevopsLtd/L=Hyderabad/C=IN' -passin pass:$PASS -passout pass:$PASS >/dev/null 2>&1
echo " OK"
else
printf "CA certs already exists - Skip creating it.."
echo " OK!"
fi

for i in $SERVER1 $SERVER2 $SERVER3 'client'
do
        if [[ ! -f secrets/$i.keystore.jks ]] && [[ ! -f secrets/$i.truststore.jks ]];then
        printf "Creating cert and keystore of $i..."
        # Create keystores
        keytool -genkey -noprompt \
                                 -alias $i \
                                 -dname "CN=$i, OU=Devops, O=DevopsLtd, L=Hyderabad, C=IN" \
                                 -keystore secrets/$i.keystore.jks \
                                 -keyalg RSA \
                                 -storepass $PASS \
                                 -keypass $PASS  >/dev/null 2>&1

        # Create CSR, sign the key and import back into keystore
        keytool -keystore secrets/$i.keystore.jks -alias $i -certreq -file tmp/$i.csr -storepass $PASS -keypass $PASS >/dev/null 2>&1

        openssl x509 -req -CA $CA_CERT -CAkey $CA_KEY -in tmp/$i.csr -out tmp/$i-ca-signed.crt -days 1825 -CAcreateserial -passin pass:$PASS  >/dev/null 2>&1

        keytool -keystore secrets/$i.keystore.jks -alias CARoot -import -noprompt -file $CA_CERT -storepass $PASS -keypass $PASS >/dev/null 2>&1

        keytool -keystore secrets/$i.keystore.jks -alias $i -import -file tmp/$i-ca-signed.crt -storepass $PASS -keypass $PASS >/dev/null 2>&1

        # Create truststore and import the CA cert.
        keytool -keystore secrets/$i.truststore.jks -alias CARoot -import -noprompt -file $CA_CERT -storepass $PASS -keypass $PASS >/dev/null 2>&1
  echo " OK!"
     else
        printf "Keystore: $i.keystore.jks and truststore: $i.truststore.jks already exist..skip creating it.."
        echo " OK!"
  fi
done

echo "$PASS" > secrets/cert_creds
rm -rf tmp
echo "SUCCEEDED"
