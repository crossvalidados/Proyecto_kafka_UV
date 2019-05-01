#!/bin/sh

kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 3 --partitions 1 --topic parsed_reviews
kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 3 --partitions 1 --topic raw_albums
kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 3 --partitions 1 --topic review_links

