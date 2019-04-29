#!/bin/sh

sudo zkServer.sh start config/zookeeper.properties &
sudo kafka-server-start.sh config/server.properties &
sudo kafka-server-start.sh config/server-1.properties &
sudo kafka-server-start.sh config/server-2.properties 
