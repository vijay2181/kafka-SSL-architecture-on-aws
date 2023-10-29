#!/bin/bash

# Kafka Installation and Configuration
# Usage: ./install_kafka.sh <KAFKA_VERSION> <DOMAIN_NAME> <SRVPASS>

if [ $# -ne 3 ]; then
    echo "Usage: ./install_kafka.sh <KAFKA_VERSION> <DOMAIN_NAME> <SRVPASS>"
    exit 1
fi

KAFKA_VERSION=$1
DOMAIN_NAME=$2
SRVPASS=$3

cd /home/ubuntu

# Download and extract Kafka
wget https://downloads.apache.org/kafka/$KAFKA_VERSION/kafka_2.12-$KAFKA_VERSION.tgz
tar -xzf kafka_2.12-$KAFKA_VERSION.tgz
ln -s kafka_2.12-$KAFKA_VERSION kafka

########################################################
# Add service scripts for managing Kafka/Zookeeper
cat > /etc/systemd/system/zookeeper.service << EOF
[Unit]
Description=Apache Zookeeper server
Documentation=http://zookeeper.apache.org
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
ExecStart=/home/ubuntu/kafka/bin/zookeeper-server-start.sh /home/ubuntu/kafka/config/zookeeper.properties
ExecStop=/home/ubuntu/kafka/bin/zookeeper-server-stop.sh

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/kafka.service << EOF
[Unit]
Description=Apache Kafka server (broker)
Documentation=http://kafka.apache.org/documentation.html
Requires=zookeeper.service

[Service]
Type=simple
ExecStart=/home/ubuntu/kafka/bin/kafka-server-start.sh /home/ubuntu/kafka/config/server.properties
ExecStop=/home/ubuntu/kafka/bin/kafka-server-stop.sh

[Install]
WantedBy=multi-user.target
EOF
##########################################################

# Copy the properties files here
mkdir /home/ubuntu/zookeeper
mkdir /home/ubuntu/kafka-logs

#ZOOKEPER
mv /home/ubuntu/kafka/config/zookeeper.properties /home/ubuntu/kafka/config/zookeeper.properties-backup
cat > /home/ubuntu/kafka/config/zookeeper.properties << EOF
dataDir=/home/ubuntu/zookeeper
clientPort=2181
maxClientCnxns=0
EOF


#KAFKA
mv /home/ubuntu/kafka/config/server.properties /home/ubuntu/kafka/config/server.properties-backup
cat > /home/ubuntu/kafka/config/server.properties << EOF
broker.id=0
listeners=PLAINTEXT://0.0.0.0:9092,SSL://0.0.0.0:9093
advertised.listeners=PLAINTEXT://$DOMAIN_NAME:9092,SSL://$DOMAIN_NAME:9093
zookeeper.connect=$DOMAIN_NAME:2181
ssl.keystore.location=/home/ubuntu/ssl/kafka.server.keystore.jks
ssl.keystore.password=serverpassword
ssl.key.password=serverpassword
ssl.truststore.location=/home/ubuntu/ssl/kafka.server.truststore.jks
ssl.truststore.password=serverpassword
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
auto.create.topics.enable=false
log.dirs=/home/ubuntu/kafka-logs
num.partitions=1
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
zookeeper.connection.timeout.ms=6000
EOF
##############################################################
# Activate the systemd scripts
systemctl daemon-reload
sudo systemctl enable zookeeper
sudo systemctl enable kafka

sudo systemctl start zookeeper
sleep 10
sudo systemctl start kafka

echo "Kafka installed and configured successfully."

##############################################################



