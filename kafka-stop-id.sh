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

read -p "Enter que server id you want to shutdown, or the number 3 to close zookeeper: " id

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


SIGNAL=${SIGNAL:-TERM}
PIDS=$(ps ax | grep -i $serv | grep java | grep -v grep | awk '{print $1}')

if [ -z "$PIDS" ]; then
  echo "No kafka server or zookeeper to stop"
  exit 1
else
  sudo kill -s $SIGNAL $PIDS
fi
