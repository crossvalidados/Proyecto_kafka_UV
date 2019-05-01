import requests
from bs4 import BeautifulSoup
from kafka import KafkaProducer

def publish_message(producer_instance, topic_name, key, value):
    try:
        key_bytes = bytes(key, encoding='utf-8')
        value_bytes = bytes(value, encoding='utf-8')
        producer_instance.send(topic_name, key=key_bytes, value=value_bytes)
        producer_instance.flush()
        print('Message published successfully.')
    except Exception as ex:
        print('Exception in publishing message')
        print(str(ex))


def connect_kafka_producer():
    _producer = None
    try:
        _producer = KafkaProducer(bootstrap_servers=['localhost:9092'], api_version=(0, 10))
    except Exception as ex:
        print('Exception while connecting Kafka')
        print(str(ex))
    finally:
        return _producer


def fetch_raw(review_url):
    html = None
    print('Processing..{}'.format(review_url))
    try:
        r = requests.get(review_url, headers=headers)
        if r.status_code == 200:
            html = r.text
    except Exception as ex:
        print('Exception while accessing raw html')
        print(str(ex))
    finally:
        return html


def get_albums(pag):
  
    albums = []
    url = 'https://pitchfork.com/reviews/albums/' + pag
    print('Accessing list')

    try:
        r = requests.get(url, headers=headers)
        if r.status_code == 200:
            html = r.text
            soup = BeautifulSoup(html, 'lxml')
            links = soup.select('.review__link')
            idx = 0
            for link in links:

                #sleep(2)
                album = fetch_raw(url_albums.strip('/') + link['href'])
                albums.append(album)
                idx += 1
    except Exception as ex:
        print('Exception in get_albums')
        print(str(ex))
       
    return albums


if __name__ == '__main__':
    headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36',
        'Pragma': 'no-cache'
    }

    # Definimos la página a la que queremos llegar para calcular los albums con mejor rating.
    pagina = 2
    all_albums = []

    for i in range(pagina):
        
        pag = '?page=' + str(i + 1)
        albums_iterator = get_albums(pag)

        for a in albums_iterator:

            all_albums.append(a)

    if len(all_albums) > 0:
        kafka_producer = connect_kafka_producer()
        for album in all_albums:
            publish_message(kafka_producer, 'raw_albums', 'raw', album)
        if kafka_producer is not None:
            kafka_producer.close()
