#!/bin/sh

read -p "Type 0 if you want to create the topics or 1 if you want to delete them all: " choice

if [ $choice -eq 0 ]
then
    kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 3 --partitions 1 --topic raw_albums
    kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 3 --partitions 1 --topic review_links
elif [ $choice -eq 1 ]
then
    kafka-topics.sh --delete --zookeeper localhost:2181 --topic raw_albums
    kafka-topics.sh --delete --zookeeper localhost:2181 --topic review_links
else
    echo "Not a valid option"
fi
