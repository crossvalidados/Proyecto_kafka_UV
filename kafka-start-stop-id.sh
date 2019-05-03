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
clear
read -p "Type 0 if you want to start or 1 if you want to shutdown any server or zookeeper:
" choice

if [ $choice -eq 0 ]
then
    #read -p "Enter que server id you want to start (0, 1 or 2), or the number 3 to start zookeeper, or 4 to start everything: " id
    options=("Iniciar servidor 0 Kafka" "Iniciar servidor 1 Kafka"\
	   "Iniciar servidor 2 Kafka" "Iniciar Zookeeper" "Iniciar todo" "Salir")
    clear
    echo "Selecciona una opción:"
    select opt in "${options[@]}"
    do

	    case $opt in
		    "${options[0]}")
				echo "Starting server 0"
				kafka-server-start.sh config/server.properties;;
		    "${options[1]}")
				echo "Starting server 1"
				kafka-server-start.sh config/server-1.properties;;
		    "${options[2]}")
				echo "Starting server 2"
				kafka-server-start.sh config/server-2.properties;;
		    "${options[3]}")
				echo "Starting zookeeper"
				zookeeper-server-start.sh  config/zookeeper.properties;;
		    "${options[4]}")
				echo "Starting everything"
				zookeeper-server-start.sh  config/zookeeper.properties &
				kafka-server-start.sh config/server.properties &
				kafka-server-start.sh config/server-1.properties &
				kafka-server-start.sh config/server-2.properties ;;
		    *)
				exit;;
		esac

	done

elif [ $choice -eq 1 ]
then
    #read -p "Enter que server id you want to shutdown (0, 1 or 2), or the number 3 to close zookeeper, or 4 to close everything: " id
    options=("Cerrar servidor 0 Kafka" "Cerrar servidor 1 Kafka"\
	   "Cerrar servidor 2 Kafka" "Cerrar Zookeeper" "Cerrar todo" "Salir")
    clear
    echo "Selecciona una opción:"
    select opt in "${options[@]}"
    do

	    case $opt in
		    "${options[0]}")
                    SIGNAL=${SIGNAL:-TERM}
                    serv="server.properties"
                    PIDS=$(ps ax | grep -i $serv | grep java | grep -v grep | awk '{print $1}')
        			echo "Closing server 0"
        			kill -s $SIGNAL $PIDS;;
		    "${options[1]}")
        			SIGNAL=${SIGNAL:-TERM}
                    serv="server-1.properties"
                    PIDS=$(ps ax | grep -i $serv | grep java | grep -v grep | awk '{print $1}')
        			echo "Closing server 1"
        			kill -s $SIGNAL $PIDS;;
		    "${options[2]}")
        			SIGNAL=${SIGNAL:-TERM}
                    serv="server-2.properties"
                    PIDS=$(ps ax | grep -i $serv | grep java | grep -v grep | awk '{print $1}')
        			echo "Closing server 2"
        			kill -s $SIGNAL $PIDS;;
		    "${options[3]}")
        			SIGNAL=${SIGNAL:-TERM}
                    serv="zookeeper.properties"
                    PIDS=$(ps ax | grep -i $serv | grep java | grep -v grep | awk '{print $1}')
        			echo "Closing zookeeper"
        			kill -s $SIGNAL $PIDS;;
		    "${options[4]}")
        			kafka-server-stop.sh
        			sleep 30
        			SIGNAL=${SIGNAL:-TERM}
                    serv="zookeeper.properties"
                    PIDS=$(ps ax | grep -i $serv | grep java | grep -v grep | awk '{print $1}')
        			echo "Closing zookeeper"
        			kill -s $SIGNAL $PIDS;;
		    *)
			        exit;;
		esac

	done

else
    echo "Not a valid answer"
fi
