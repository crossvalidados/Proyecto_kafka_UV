#!/bin/sh

zookeeper-server-start.sh config/zookeeper.properties &
kafka-server-start.sh config/server.properties &
kafka-server-start.sh config/server-1.properties &
kafka-server-start.sh config/server-2.properties 

# To test
# kafka-console-consumer.sh --topic parsed_reviews --bootstrap-server localhost:9092 --from-beginning
# kafka-topics.sh --zookeeper localhost:2181 --topic parsed_reviews -describe
# kafka-topics.sh --zookeeper localhost:2181 --list
