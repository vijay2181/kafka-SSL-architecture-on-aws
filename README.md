# kafka-architecture-with-ssl
This repo has all the code related to kafka cluster setup using docker and compose with SSL/TLS/HTTPS

![image](https://github.com/vijay2181/kafka-architecture/assets/66196388/bf2591d2-7dfc-4d3a-9f6b-3d9d3360cd1a)



take one kafka server and do the below steps


CA(CERTIFICATE AUTHORITY)
-------------------------
- create ca files
- ca.key(private key)
- ca.crt(public key)
- private key has to be within this boundary so cannot be shared to anyone else, rather like a certificate file. it's okay to distribute public key.

Keystore and Truststore:
------------------------
Next thing we need to create a keystore and a truststore.
now once you have certificate Authority, kafka, keystore, truststore, the very first step is to import the ca.crt into your truststore

1. import ca.crt into truststore,

2. once that is done, using the keystore as an input you need to create a file called Kafka unsigned.crt certificate because this is just
created using keystore. it is not yet signed by the cerificate Authority.

3. so now to sign this from a certificate authority, you need to send this file(Kafka unsigned.crt) to CA, CA in turn will use its (ca.key)private key and (ca.crt)public key along with file(Kafka unsigned.crt) and produce a signed certificate file. Now you have a signed certificate(kafka signed.crt) which is ready to be imported into your Keystore.

4. But before importing into keystore, all you need to do is to import ca.crt into keystore.

5. you can import signed certificate(kafka signed.crt) which you have got from CA into your keystore.

so now by this time you have a keystore and Truststore ready, all you need to do is to bootstrap your Kafka and provide the location for Keystore and truststore.
this defines the whole setup.

All the above steps should be done inside kafka broker server only


Automated Process:
------------------
Run below scripts to bring up 3 kafka and zookeeper cluster on docker-compose

```
./create-ssl-certs.sh
```

- The above command will create ca folder, which will contain public key and private key
- truststore,keystore,password files will be created in secrets folder


```
./start_kafka_cluster_with_ssl.sh
```

- The above command will build required images for kafka and zookeeper with configs and with those images pointed in docker-compose file will start 3 node kafka and 3 node zookeeper containers

```
docker ps
```

to create a topic from a docker client:
---------------------------------------

If Kafka is not available in local machine, below commands can be used to run kafka as client in docker container

```
./create_kafka_topic.sh vijay-test-topic
```

ubuntu@ip-172-31-86-198:~/kafka-ssl-architecture-on-docker$ ./create_kafka_topic.sh vijay-test-topic
Created topic vijay-test-topic.

```
./list_all_topics.sh
```

ubuntu@ip-172-31-86-198:~/kafka-ssl-architecture-on-docker$ ./list_all_topics.sh
Following are the list of topics in kafka cluster.. OK!
vijay-test-topic
