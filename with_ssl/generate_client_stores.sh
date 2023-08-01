#!/bin/bash

#This script will create client truststore and keystores from CA 

# Change these variables as needed
CLIENT_NAME="kafka-client"
PASSWORD="clientpass"
CA_CERT="kafka-ca.crt"
CA_KEY="kafka-ca.key"
CA_KEY_PASSWORD="password"  # Provide the password for the CA key here
CA_ALIAS="kafka-ca-alias"

# Step 1: Import CA certificate into truststore
keytool -import -alias $CA_ALIAS -file $CA_CERT -keystore kafka.client.truststore.jks -storepass $PASSWORD -noprompt

# Step 2: Generate client key and certificate
keytool -genkey -alias $CLIENT_NAME -keyalg RSA -keystore kafka.client.keystore.jks -storepass $PASSWORD -keypass $PASSWORD -dname "CN=$CLIENT_NAME,OU=Unknown,O=Unknown,L=Unknown,ST=Unknown,C=Unknown"

# Step 3: Generate a Certificate Signing Request (CSR)
keytool -certreq -alias $CLIENT_NAME -keystore kafka.client.keystore.jks -storepass $PASSWORD -file $CLIENT_NAME.csr

# Step 4: Sign the CSR with the CA private key to get the client certificate
openssl x509 -req -CA $CA_CERT -CAkey $CA_KEY -in $CLIENT_NAME.csr -out $CLIENT_NAME.crt -days 365 -CAcreateserial -passin pass:$CA_KEY_PASSWORD

# Step 5: Import the CA certificate and the client certificate into the keystore
keytool -import -alias $CA_ALIAS -file $CA_CERT -keystore kafka.client.keystore.jks -storepass $PASSWORD -noprompt
keytool -import -alias $CLIENT_NAME -file $CLIENT_NAME.crt -keystore kafka.client.keystore.jks -storepass $PASSWORD -noprompt

# Step 6: Clean up temporary files
rm $CLIENT_NAME.csr $CLIENT_NAME.crt

echo "Kafka client keystore and truststore have been generated."
