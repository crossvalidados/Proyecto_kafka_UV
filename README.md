# Declaración de intenciones.

Este proyecto fue realizado como parte de la asignatura de Big Data del Máster de Ciencia de Datos en la Universitat de València.

El objetivo es la creación de un notificador de álbumes de música con valoración superior a 7.5 a partir de los registros presentes en la página https://pitchfork.com/. Lo haremos de forma que se pueda ejecutar repetidamente sin variar el resultado, y que se pueda seleccionar el rango de álbumes a valorar (variando la variable _paginas_). Además, implementaremos una forma de filtrar únicamente los registros no presentes en nuestros datos, para evitar la duplicidad.

Comenzaremos con una explicación de la estructura de kafka y nuestros ajustes.

# Configuración de Kafka.

Kafka es una aplicación de publicación y subscripción múltiple. Las dos principales ventajas de usar Kafka son su rendimiento (y escalabilidad) y su tolerancia a fallos. Sobre el primer punto no podemos trabajar mucho, dada la escala de nuestro trabajo, pero en el segundo, su característica principal (y la que usaremos) es la replicación, es decir, la posibilidad de usar múltiples brokers (servidores que almacenan los datos) de forma conjunta y coordinada.

Con esto, hemos decidido crear un clúster con 3 brokers escuchando en diferentes puertos, y coordinados por zookeeper. Además, se han agregado las opciones de configuración para poder eliminar topics y para poder realizar un apagado controlado de los brokers. También se han modificado las opciones de retención de logs para eliminarlos cada 24 horas y para verificar su posible eliminación cada 30 minutos (1800000 milisegundos). Por último, se ha modificado el directorio de logs tanto en los servidores como en zookeeper para unificarlos.

Así pues, las opciones modificadas son las siguientes:

```
controlled.shutdown.enable=true
delete.topic.enable=true
log.retention.hours=24
log.retention.check.interval.ms=1800000
```

Y las configuraciones que difieren en cada fichero de configuración de cada servidor (0, 1 y 2 para sus IDs):

Servidor 0:

```
broker.id=0
listeners=PLAINTEXT://:9092
log.dirs=/tmp/kafka/server-0
```

Servidor 1:

```
broker.id=1
listeners=PLAINTEXT://:9093
log.dirs=/tmp/kafka/server-1
```

Servidor 2:

```
broker.id=2
listeners=PLAINTEXT://:9094
log.dirs=/tmp/kafka/server-2
```

Zookeeper:

```
dataDir=/tmp/kafka/zookeeper
clientPort=2181
```

Los archivos de configuración generados están disponibles en el directorio `config/`. Cabe destacar que todo el proceso se lleva a cabo en distribuciones GNU-Linux.

Una vez configurados los brokers es hora de poner en marcha el zookeeper y el clúster. Hemos desarrollado un sencillo script de gestión de este proceso, seleccionando si se pretende iniciar o apagar los brokers o zookeeper individualmente o todo junto. La utilización es muy sencilla. Lo ejemplificamos a continuación (hay que situarse en el directorio en el cual se encuentra el script).

```
./kafka-start-stop-id.sh
0
5
```

Esto iniciará primero zookeeper y después los 3 servidores.

Una vez tenemos la estructura de Kafka ejecutándose, pasamos a hablar de los topics necesarios para el trabajo. Hemos decidido utilizar dos, que llamaremos *raw_albums* y *review_links*. El primero es para almacenar la información de los ábumes sin formato alguno, y el segundo es para almacenar los links de los álbumes ya descargados y usarlo como filtro ante nuevos álbumes.

La creación de los topics la haremos con un script, en el cual seleccionamos si queremos la creación o eliminación de los mismos (internamente se llama a kafka-topics.sh). Cabe notar que utilizaremos replicación 3 para aprovechar los 3 brokers de los que disponemos, y 1 única partición en cada uno. Los asociaremos al puerto de zookeeper también.
Internamente este script llama a la función kafka-topics.sh --create o --delete.

```
./create-delete-topics.sh
0
```

Una vez finalizado el proceso tenemos nuestros 3 brokers con una partición de cada topic en ellos. Pasamos ahora a describir el código y su funcionamiento.

# Código y puesta en marcha.

Como hemos contado antes, el propósito del código es crear un aviso de recomendación de álbumes de música a partir de la web https://pitchfork.com/. Para ello hemos creado 2 scripts en python, que han de ejecutarse por separado esperando a la ejecución completa del primero para poder accionar el segundo.

El primer script es el llamado *producer_raw_reviews.py*, y se encarga de acceder a la página web y almacenar los datos de los álbumes (por páginas de 12 álbumes por página, según el número de páginas que designemos) en el topic *raw_albums* de nuestro clúster Kafka. Por otra parte, también almacena los links de los álbumes (en el tópic *review_links*) ya almacenados para filtrar por ellos,
y evitar que se envíen mensajes duplicados al topic.

El segundo script se llama *producer_consumer_parse_notify_reviews.py* y se encarga de gestionar los mensajes del topic *raw_albums* y obtener los campos de _título, puntaje, artistas, género, imagen, año y etiqueta_, para posteriormente filtrar los de puntaje superior a 7.5 y devolverlos como recomendados.

## Funciones del código.

En el primer script, *producer_raw_reviews.py*, encontramos diversas funciones:

- *publish_message()*: Publicar Mensajes en el topic *raw_albums*.
- _connect_kafka_producer()_: Conectar con Kafka Creando un Productor, lo hacemos indicando alguno de los brokers en activo (localhost:9092, por ejemplo), la versión de la API, y definiendo acks a "all", para asegurar que lleguen los mensajes a todos los brokers sincronizados antes de continuar.
- *fetch_raw()*: Obtener los datos del álbum en crudo (sin procesar).
- *get_albums()*: Almacenar los datos anteriores por página de álbumes (recordamos que hay 12 álbumes por página), filtrando por los ya presentes en el topic *review_links*. Este último punto se hace leyendo los links presentes en el topic *review_links*  con un Consumer (indicando el topic, el offset = "earliest" para que lea los mensajes desde el primero, el servidor, la API y el tiempo de desconexión de 15 segundos para asegurarnos de que no se desconecta antes de recibir los mensajes) y comprobando que el nuevo link no esté en esa lista.

En el segundo script, *producer_consumer_parse_notify_reviews.py* , encontramos las siguientes:

- *parse()*: Se encarga de extraer los datos buscados (artista, puntaje...) de los datos en bruto obtenidos a partir del *fetch_raw()* del script anterior.

# Funcionamiento.

A continuación, vamos a ejemplificar el funcionamiento del código ejecutándolo en local y mostrando parte de los outputs para verificar el correcto funcionamiento.

Comenzamos ejecutando el script *producer_raw_reviews.py*, en el que hemos definido la variable **paginas = 1**. Esto limita a 12 el número de álbumes a obtener de la página web. Obtenemos el siguiente output:

```
Accessing list
Processing..https://pitchfork.com/reviews/albums/aphex-twin-selected-ambient-works-volume-ii/
Processing..https://pitchfork.com/reviews/albums/rico-nasty-kenny-beats-anger-management/
Processing..https://pitchfork.com/reviews/albums/pure-bathing-culture-night-pass/
Processing..https://pitchfork.com/reviews/albums/shy-glizzy-covered-n-blood/
Processing..https://pitchfork.com/reviews/albums/joel-ross-kingmaker/
Processing..https://pitchfork.com/reviews/albums/vampire-weekend-father-of-the-bride/
Processing..https://pitchfork.com/reviews/albums/l7-scatter-the-rats/
Processing..https://pitchfork.com/reviews/albums/local-natives-violet-street/
Processing..https://pitchfork.com/reviews/albums/pile-green-and-gray/
Processing..https://pitchfork.com/reviews/albums/omb-peezy-preacher-to-the-streets/
Processing..https://pitchfork.com/reviews/albums/kevin-abstract-arizona-baby/
Processing..https://pitchfork.com/reviews/albums/nick-murphy-run-fast-sleep-naked/
Añadidos  12  álbums
Enviando albums.
Enviados  12  albums.
Enviando links.
Enviados 12  links.
```

Donde se indican los links de los álbumes a procesar (que no a enviar a algún topic) y el número de álbumes y de links enviados a sus respectivos topics.

Podemos comprobar que existen 12 álbumes y 12 links en el cluster si ejecutamos:

```
kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic raw_albums --from-beginning
```

Se obtiene una larga cadena en formato lxml y una sentencia final *Processed a total of 12 messages*, que indica que contiene 12 mensajes.
Esto se realiza de igual forma con el topic *review_links* y se obtiene un output equivalente.

A continuación ejecutamos el segundo script (*producer_consumer_parse_notify_reviews.py*), que únicamente crea un Consumidor y lee los mensajes del topic *raw_albums*, para procesarlos y mostrar los de puntaje superior a 7.5. Obtenemos el siguiente output.

```
Running Consumer..
========================================
Good album alert!
Title: Selected Ambient Works Volume II
Artist: Aphex Twin
Genres: Electronic
Score: 10.0
========================================
Good album alert!
Title: Anger Management
Artist: Rico Nasty
Genres: Rap
Score: 7.6
========================================
Good album alert!
Title: KingMaker
Artist: Joel Ross
Genres: Jazz
Score: 7.8
========================================
Good album alert!
Title: Father of the Bride
Artist: Vampire Weekend
Genres: Rock
Score: 8.0
========================================
Good album alert!
Title: Green and Gray
Artist: Pile
Genres: Rock
Score: 7.9
========================================

```

Donde se muestran 5 álbumes con puntaje superior a 7.5 de entre los 12 procesados. Para comprobar el funcionamiento del filtro, vamos a ejecutar los dos scripts de nuevo en el mismo orden, pero cambiando la variable **paginas = 3** para procesar un total de 36 albums y links. El output del primer script es el siguiente:

```
Accessing list
Añadidos  0  álbums
Accessing list
Processing..https://pitchfork.com/reviews/albums/judy-and-the-jerks-music-for-donuts-ep/
Processing..https://pitchfork.com/reviews/albums/various-artists-mettavolution/
Processing..https://pitchfork.com/reviews/albums/kevin-morby-oh-my-god/
Processing..https://pitchfork.com/reviews/albums/dj-nate-take-off-mode/
Processing..https://pitchfork.com/reviews/albums/club-night-what-life/
Processing..https://pitchfork.com/reviews/albums/jackie-mendoza-luvhz-ep/
Processing..https://pitchfork.com/reviews/albums/schoolboy-q-crash-talk/
Processing..https://pitchfork.com/reviews/albums/the-mountain-goats-in-league-with-dragons/
Processing..https://pitchfork.com/reviews/albums/pivot-gang-you-cant-sit-with-us/
Processing..https://pitchfork.com/reviews/albums/ariel-zetina-organism-ep/
Processing..https://pitchfork.com/reviews/albums/various-artists-for-the-throne-music-inspired-by-the-hbo-series-game-of-thrones/
Processing..https://pitchfork.com/reviews/albums/craig-finn-i-need-a-new-war/
Añadidos  12  álbums
Accessing list
Processing..https://pitchfork.com/reviews/albums/marina-love-fear/
Processing..https://pitchfork.com/reviews/albums/otoboke-beaver-itekoma-hits/
Processing..https://pitchfork.com/reviews/albums/bennie-maupin-the-jewel-in-the-lotus/
Processing..https://pitchfork.com/reviews/albums/foxygen-seeing-other-people/
Processing..https://pitchfork.com/reviews/albums/wiz-khalifa-fly-times-vol-1-the-good-fly-young/
Processing..https://pitchfork.com/reviews/albums/lamb-the-secret-of-letting-go/
Processing..https://pitchfork.com/reviews/albums/picastro-exit/
Processing..https://pitchfork.com/reviews/albums/aldous-harding-designer/
Processing..https://pitchfork.com/reviews/albums/king-gizzard-and-the-lizard-wizard-fishing-for-fishies/
Processing..https://pitchfork.com/reviews/albums/kelsey-lu-blood/
Processing..https://pitchfork.com/reviews/albums/body-meat-truck-music/
Processing..https://pitchfork.com/reviews/albums/sunn-o-life-metal/
Añadidos  12  álbums
Enviando albums.
Enviados  24  albums.
Enviando links.
Enviados 24  links.
```

Vemos los que en la primera página (el script procesa los álbumes página por página) no se añaden nuevos álbumes, ya que ya se encuentran presentes. En las dos siguientes páginas se añaden 12 álbumes nuevos en cada una, para acabar enviando 24 nuevos álbumes y links a sus respectivos topics. Si ahora ejecutamos el segundo script obtenemos:

```
Running Consumer..
========================================
Good album alert!
Title: Selected Ambient Works Volume II
Artist: Aphex Twin
Genres: Electronic
Score: 10.0
========================================
Good album alert!
Title: Anger Management
Artist: Rico Nasty
Genres: Rap
Score: 7.6
========================================
Good album alert!
Title: KingMaker
Artist: Joel Ross
Genres: Jazz
Score: 7.8
========================================
Good album alert!
Title: Father of the Bride
Artist: Vampire Weekend
Genres: Rock
Score: 8.0
========================================
Good album alert!
Title: Green and Gray
Artist: Pile
Genres: Rock
Score: 7.9
========================================
Good album alert!
Title: Music for Donuts EP
Artist: Judy and the Jerks
Genres: Rock
Score: 7.7
========================================
Good album alert!
Title: Take Off Mode
Artist: DJ Nate
Genres: Electronic
Score: 7.6
========================================
Good album alert!
Title: What Life
Artist: Club Night
Genres: Rock
Score: 7.7
========================================
Good album alert!
Title: You Can't Sit With Us
Artist: Pivot Gang
Genres: Rap
Score: 7.5
========================================
Good album alert!
Title: Organism EP
Artist: Ariel Zetina
Genres: Electronic
Score: 7.6
========================================
Good album alert!
Title: I Need a New War
Artist: Craig Finn
Genres: Rock
Score: 8.0
========================================
Good album alert!
Title: Itekoma Hits
Artist: Otoboke Beaver
Genres: Rock
Score: 7.7
========================================
Good album alert!
Title: The Jewel in the Lotus
Artist: Bennie Maupin
Genres: Jazz
Score: 9.1
========================================
Good album alert!
Title: Exit
Artist: Picastro
Genres: Folk, Country
Score: 7.8
========================================
Good album alert!
Title: Designer
Artist: Aldous Harding
Genres: Folk, Country
Score: 8.0
========================================
Good album alert!
Title: Blood
Artist: Kelsey Lu
Genres: Experimental
Score: 7.5
========================================
Good album alert!
Title: Truck Music
Artist: Body Meat
Genres: Experimental
Score: 7.5
========================================
Good album alert!
Title: Life Metal
Artist: Sunn O)))
Genres: Experimental
Score: 8.4
========================================
```

Vemos que los primeros 5 álbumes no aparecen duplicados, ya que solo tenemos un registro de cada uno presente en el topic *raw_albums*. Además, se han añadido 13 nuevos álbumes con puntaje superior a 7.5 provenientes de las páginas 2 y 3.

# Prueba de funcionamiento de brokers.

Ahora vamos a interrumpir el trabajo de un broker apagándolo, para ello, mostramos la estructura del topic *raw_albums* antes del apagado del broker 0 (con *kafka-topics.sh --describe --zookeeper localhost:2181 --topic raw_albums*).

```
Topic:raw_albums        PartitionCount:1        ReplicationFactor:3     Configs:
        Topic: raw_albums       Partition: 0    Leader: 0       Replicas: 0,1,2 Isr: 0,1,2
```

Que indica que tenemos los 3 brokers activos y en sincronización. Si ahora apagamos uno utilizando el script *./kafka-start-stop-id.sh* y seleccionando el broker 0, y volvemos a inspeccionar el topic *raw_albums*:

```
Topic:raw_albums        PartitionCount:1        ReplicationFactor:3     Configs:
        Topic: raw_albums       Partition: 0    Leader: 1       Replicas: 0,1,2 Isr: 1,2

```

Vemos que tenemos 2 replicas en sincronización. Si ahora ejecutamos nuestros primer script (producer_raw_reviews.py),

```
Accessing list
Processing..https://pitchfork.com/reviews/albums/aphex-twin-selected-ambient-works-volume-ii/
Processing..https://pitchfork.com/reviews/albums/rico-nasty-kenny-beats-anger-management/
Processing..https://pitchfork.com/reviews/albums/pure-bathing-culture-night-pass/
Processing..https://pitchfork.com/reviews/albums/shy-glizzy-covered-n-blood/
Processing..https://pitchfork.com/reviews/albums/joel-ross-kingmaker/
Processing..https://pitchfork.com/reviews/albums/vampire-weekend-father-of-the-bride/
Processing..https://pitchfork.com/reviews/albums/l7-scatter-the-rats/
Processing..https://pitchfork.com/reviews/albums/local-natives-violet-street/
Processing..https://pitchfork.com/reviews/albums/pile-green-and-gray/
Processing..https://pitchfork.com/reviews/albums/omb-peezy-preacher-to-the-streets/
Processing..https://pitchfork.com/reviews/albums/kevin-abstract-arizona-baby/
Processing..https://pitchfork.com/reviews/albums/nick-murphy-run-fast-sleep-naked/
Añadidos  12  álbums
Enviando albums.
Enviados  12  albums.
Enviando links.
Enviados 12  links.
```

Observamos que los mensajes se han enviado igualmente, ya que zookeeper ha adaptado el clúster ante la caida del servidor 0 (el líder antes era el 0 y ahora es el 1, por ejemplo).
Esto se consigue gracias a la utilización del parámetro *metadata_max_age_ms = 1000* en la definición del productor, ya que hace que se actualice la información de los brokers y líderes cada segundo.

Ahora vamos a probar reactivando el broker 0, viendo cual es el nuevo líder, y apagándolo en mitad de la transmisión, cuando el Productor ya está definido. Veamos si obtenemos mensajes en el topic (previamente vaciamos el topic con *./create-delete-topics.sh*).
Observemos la nueva descripción de *raw_albums*.

```
Topic:raw_albums        PartitionCount:1        ReplicationFactor:3     Configs:
        Topic: raw_albums       Partition: 0    Leader: 1       Replicas: 1,2,0 Isr: 1,2,0
```

Ahora el líder es el broker 1, por lo que apagaremos ese una vez se estén enviando los mensajes (lo haremos con la función *./kafka-start-stop-id-kevin.sh* pulsando 1 y 2 en el momento en el que aparezca *Enviando albums* en el output). Veamos si al terminar el proceso hay algún mensaje en ese topic:
Tanto en *raw_albums* como en *review_links* obtenemos:

```
Processed a total of 12 messages
```

Y sus estructuras luego de todo el proceso:

```
Topic:raw_albums        PartitionCount:1        ReplicationFactor:3     Configs:
        Topic: raw_albums       Partition: 0    Leader: 2       Replicas: 1,2,0 Isr: 2,0

Topic:review_links      PartitionCount:1        ReplicationFactor:3     Configs:
        Topic: review_links     Partition: 0    Leader: 2       Replicas: 2,0,1 Isr: 2,0
```

Por lo que concluímos la estructura y funcionamiento del clúster y proceso son satisfactorios.
