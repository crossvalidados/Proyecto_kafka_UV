#!/bin/sh
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

read -p "Type 0 if you want to start or 1 if you want to shutdown any server or zookeeper: " choice

if [ $choice -eq 0 ]
then
    read -p "Enter que server id you want to start (0, 1 or 2), or the number 3 to start zookeeper, or 4 to start everything: " id
    
    if [ $id -eq 0 ]
    then
        echo "Starting server $id"
        kafka-server-start.sh config/server.properties
    fi

    if [ $id -eq 1 ]
    then
        echo "Starting server $id"
        kafka-server-start.sh config/server-1.properties
    fi

    if [ $id -eq 2 ]
    then
        echo "Starting server $id"
        kafka-server-start.sh config/server-2.properties
    fi

    if [ $id -eq 3 ]
    then
        echo "Starting zookeeper"
        zookeeper-server-start.sh config/zookeeper.properties
    fi

    if [ $id -eq 4 ]
    then
        echo "Starting everything"
        zookeeper-server-start.sh config/zookeeper.properties &
        kafka-server-start.sh config/server.properties &
        kafka-server-start.sh config/server-1.properties &
        kafka-server-start.sh config/server-2.properties 
    fi
        
elif [ $choice -eq 1 ]
then
    read -p "Enter que server id you want to shutdown (0, 1 or 2), or the number 3 to close zookeeper, or 4 to close everything: " id
    
    if [ $id -eq 0 ]
    then
        serv="server.properties"
        echo "Closing server $id"
    fi

    if [ $id -eq 1 ]
    then
        serv="server-1.properties"
        echo "Closing server $id"
    fi

    if [ $id -eq 2 ]
    then
        serv="server-2.properties"
        echo "Closing server $id"
    fi

    if [ $id -eq 3 ]
    then
        serv="zookeeper.properties"
        echo "Closing zookeeper"
    fi

    if [ $id -eq 4 ]
    then
        kafka-server-stop.sh
        sleep 30
        serv="zookeeper.properties"
    fi
    
    SIGNAL=${SIGNAL:-TERM}
    PIDS=$(ps ax | grep -i $serv | grep java | grep -v grep | awk '{print $1}')

    if [ -z "$PIDS" ]
    then
    echo "No kafka server or zookeeper to stop"
    exit 1
    else
    kill -s $SIGNAL $PIDS
    fi

else
    echo "Not a valid answer"
fi


 
