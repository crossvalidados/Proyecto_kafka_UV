#!/bin/sh

sudo zkServer.sh start config/zookeeper.properties &
sudo kafka-server-start.sh config/server.properties &
sudo kafka-server-start.sh config/server-1.properties &
sudo kafka-server-start.sh config/server-2.properties 


# To stop
# sudo kafka-server-stop.sh
# sudo zkServer.sh stop config/zookeeper.properties


# To test
# kafka-console-consumer.sh --topic parsed_reviews --bootstrap-server localhost:9092 --from-beginning
# kafka-topics.sh --zookeeper localhost:2181 --topic parsed_reviews -describe
# kafka-topics.sh --zookeeper localhost:2181 --list
