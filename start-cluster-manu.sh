#!/bin/sh

zookeeper-server-start.sh config/zookeeper.properties &
kafka-server-start.sh config/server.properties &
kafka-server-start.sh config/server-1.properties &
kafka-server-start.sh config/server-2.properties 
#kafka-topics.sh –create –zookeeper localhost:2181 –replication-factor 3 –partitions 1 –topic Topic

