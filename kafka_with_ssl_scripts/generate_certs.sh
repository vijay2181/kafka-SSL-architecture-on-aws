#!/bin/bash

# Generate SSL Certificates
# Usage: ./generate_certs.sh <DOMAIN_NAME> <SRVPASS>

if [ $# -ne 2 ]; then
    echo "Usage: ./generate_certs.sh <DOMAIN_NAME> <SRVPASS>"
    exit 1
fi

DOMAIN_NAME=$1
SRVPASS=$2

# Install required packages
sudo apt-get update
sudo apt-get install -y wget net-tools netcat tar openjdk-8-jdk

mkdir ssl
cd ssl 

# Setup CA
openssl req -new -newkey rsa:4096 -days 365 -x509 -subj "/CN=Kafka-Security-CA" -keyout ca-key -out ca-cert -nodes

## create a server (kafka broker) certificate
keytool -genkey -keystore kafka.server.keystore.jks -validity 365 -storepass $SRVPASS -keypass $SRVPASS -dname "CN=$DOMAIN_NAME" -storetype pkcs12

# create a certification request file, to be signed by the CA
keytool -keystore kafka.server.keystore.jks -certreq -file cert-file -storepass $SRVPASS -keypass $SRVPASS

# sign the server certificate
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 365 -CAcreateserial -passin pass:$SRVPASS

# Trust the CA by creating a truststore for our Kafka broker and importing the ca-cert
keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert -storepass $SRVPASS -keypass $SRVPASS -noprompt

# Import CA and the signed server certificate into the keystore
keytool -keystore kafka.server.keystore.jks -alias CARoot -import -file ca-cert -storepass $SRVPASS -keypass $SRVPASS -noprompt
keytool -keystore kafka.server.keystore.jks -import -file cert-signed -storepass $SRVPASS -keypass $SRVPASS -noprompt

echo "SSL certificates generated successfully."
