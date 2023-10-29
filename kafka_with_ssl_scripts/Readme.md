# Installing Single Node kafka Cluster with SSL using SHELL script

- Take t2.medium ubuntu 22.04 server
- open 22,2181,9092-9093,2888-3888 ports in SG

```
chmod +x generate_certs.sh
cd /home/ubuntu
```
```
# Usage: ./generate_certs.sh <PUBLIC_DOMAIN_NAME> <SRVPASS
bash -x generate_certs.sh ec2-52-3-192-172.compute-1.amazonaws.com serverpassword
```
- This will create ca certs and server keystore, trustore in /home/ubuntu/ssl folder

```
chmod +x install_kafka.sh
# Usage: ./install_kafka.sh <KAFKA_VERSION> <PUBLIC_DOMAIN_NAME> <SRVPASS>
sudo bash -x install_kafka.sh 3.6.0 ec2-52-3-192-172.compute-1.amazonaws.com serverpassword
```
- The above command has to be executed with sudo previlages because we are configuring zookeeper and kafka as systemd services
- This will install kafka, start zookeeper kafka will all configs and ssl as service
- zookeeper and kafka will be STARTED and you can test with below commands

```
#VERFICATION OF ZOOKEEPER AND KAFKA:
tail -n 5 ~/kafka/logs/zookeeper.out
echo "ruok" | nc localhost 2181 ; echo
tail -f /home/ubuntu/kafka/logs/server.log
netstat -pant | grep ":9092"
ps -ef | grep kafka
ps -ef | grep zookeeper
openssl s_client -connect $DOMAIN_NAME:9093

sudo systemctl status zookeeper
sudo systemctl status kafka
sudo systemctl stop zookeeper
sudo systemctl stop kafka
```

## PRODUCER TESTING
```
#TESTING
#MAIN SERVER AS PRODUCER:

## grab CA certificate from server and add it to CLIENT truststore
- go to kafka main server where you installed kafka with ssl
cd ~
mkdir /home/ubuntu/client
export CLIPASS=clientpassword
cd ~
cd ssl

keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file ca-cert  -storepass $CLIPASS -keypass $CLIPASS -noprompt
mv kafka.client.truststore.jks /home/ubuntu/client/

cd /home/ubuntu/client

So next we are going to create our properties file as which we have to provide as additional parameter to our clients.
So the console consumer and the console producer at the end

## create client.properties and configure SSL parameters

cat > /home/ubuntu/client/client.properties << EOF
security.protocol=SSL
ssl.truststore.location=/home/ubuntu/client/kafka.client.truststore.jks
ssl.truststore.password=clientpassword
EOF

- paste the above content in /home/ubuntu/client/client.properties file
- now we can start our consumer client on same main server

CREATE A SAMPLE TOPIC:
======================
/home/ubuntu/kafka/bin/kafka-topics.sh --create --if-not-exists --bootstrap-server ec2-52-3-192-172.compute-1.amazonaws.com:9093 --command-config /home/ubuntu/client/client.properties --replication-factor 1 --partitions 3 --topic vijay-test-topic

/home/ubuntu/kafka/bin/kafka-topics.sh --describe --topic vijay-test-topic --bootstrap-server ec2-52-3-192-172.compute-1.amazonaws.com:9093 --command-config /home/ubuntu/client/client.properties

ubuntu@ip-172-31-49-206:~/client$ /home/ubuntu/kafka/bin/kafka-topics.sh --describe --topic vijay-test-topic --bootstrap-server ec2-52-3-192-172.compute-1.amazonaws.com:9093 --command-config /home/ubuntu/client/client.properties
Topic: vijay-test-topic TopicId: wCqJuC3MRQKhGmX2q9lwIQ PartitionCount: 3       ReplicationFactor: 1    Configs: segment.bytes=1073741824
        Topic: vijay-test-topic Partition: 0    Leader: 0       Replicas: 0     Isr: 0
        Topic: vijay-test-topic Partition: 1    Leader: 0       Replicas: 0     Isr: 0
        Topic: vijay-test-topic Partition: 2    Leader: 0       Replicas: 0     Isr: 0


/home/ubuntu/kafka/bin/kafka-console-producer.sh --broker-list <MAIN KAFKA SERVER PUBLIC DNS>:9093 --topic kafka-security-topic --producer.config /home/ubuntu/client/client.properties

/home/ubuntu/kafka/bin/kafka-console-producer.sh --broker-list ec2-52-3-192-172.compute-1.amazonaws.com:9093 --topic vijay-test-topic --producer.config /home/ubuntu/client/client.properties


root@ip-172-31-91-214:~/client# /home/ubuntu/kafka/bin/kafka-console-producer.sh --broker-list ec2-52-3-192-172.compute-1.amazonaws.com:9093 --topic vijay-test-topic --producer.config /home/ubuntu/client/client.properties
>Hi Iam Vijay
>This is producer producing 1234 Message
>

```

## CONSUMER TESTING

```
CLIENT :
========
- TAKE ONE UBUNTU SERVER ON AWS AND INSTALL KAFKA IN IT 

cd /home/ubuntu
KAFKA_VERSION=3.6.0

# Install required packages
sudo apt-get update
sudo apt-get install -y openjdk-11-jre-headless


# Download and extract Kafka
wget https://downloads.apache.org/kafka/$KAFKA_VERSION/kafka_2.13-$KAFKA_VERSION.tgz
tar -xzf kafka_2.13-$KAFKA_VERSION.tgz
#mv kafka_2.13-$KAFKA_VERSION kafka_dir
ln -s kafka_2.13-$KAFKA_VERSION kafka


## grab CA certificate ca-cert from Remote MAIN server and add it to LOCAL CLIENT truststore
we can copy the ca-cert from main server and create client.trustore for client
#scp -i ~/kafka-security.pem ubuntu@<<your-public-DNS>>:/home/ubuntu/ssl/ca-cert .
#scp -i ~/kafka-security.pem ubuntu@ec2-52-3-192-172.compute-1.amazonaws.com:/home/ubuntu/ssl/ca-cert .
#or directly paste content of ca-cert from MAIN server


mkdir /home/ubuntu/client
export CLIPASS=clientpassword

cd /home/ubuntu/client
ls
ca-cert



keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file ca-cert  -storepass $CLIPASS -keypass $CLIPASS -noprompt

So next we are going to create our properties file as which we have to provide as additional parameter to our clients.
So the console producer at the end

## create client.properties and configure SSL parameters

cat > /home/ubuntu/client/client.properties << EOF
security.protocol=SSL
ssl.truststore.location=/home/ubuntu/client/kafka.client.truststore.jks
ssl.truststore.password=clientpassword
EOF

- paste the above content in /home/ubuntu/client/client.properties file
- now we can start our producer client


## TEST
test using console-consumer

### CONSUMER

openssl s_client -connect <MAIN KAFKA SERVER PUBLIC DNS>:9093
#openssl s_client -connect ec2-52-3-192-172.compute-1.amazonaws.com:9093


/home/ubuntu/kafka/bin/kafka-console-consumer.sh --bootstrap-server ec2-52-3-192-172.compute-1.amazonaws.com:9093 --topic vijay-test-topic --consumer.config /home/ubuntu/client/client.properties


root@ip-172-31-26-33:~/client# /home/ubuntu/kafka/bin/kafka-console-consumer.sh --bootstrap-server ec2-52-3-192-172.compute-1.amazonaws.com:9093 --topic vijay-test-topic --consumer.config /home/ubuntu/client/client.properties
Hi Iam Vijay
This is producer producing 1234 Message

And you can see that we were able to successfully produce a message to our SSL enabled endpoint. on port 9093

- HERE MAIN SERVER(KAFKA) IS PRODUCER AND OTHER SERVER(CLIENT) IS CONSUMER
```



![image](https://github.com/vijay2181/kafka-SSL-architecture-on-aws/assets/66196388/1a82bdcd-87e7-43e9-a0d2-fa9ac16fde9e)


![image](https://github.com/vijay2181/kafka-SSL-architecture-on-aws/assets/66196388/342d73b8-b017-4c81-907f-24f2dbd54ccd)

