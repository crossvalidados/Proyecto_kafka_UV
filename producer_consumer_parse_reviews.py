import json
from bs4 import BeautifulSoup
from kafka import KafkaConsumer, KafkaProducer
import re


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


def parse(markup):
    artist = '-'
    title = '-'
    score = 0
    genre = []
    year = 0
    cover = "-"
    label = "-"
    rec = {'title': title, 'artist': artist, 'score': score, 
           'year': year, 'cover': cover, 'genre': genre, 'label': label}


    try:

        soup = BeautifulSoup(markup, 'lxml')
        # title
        title_section = soup.select('.single-album-tombstone__review-title')
        # score
        score_section = soup.select('.score')
        # artist
        artist_section = soup.select('.artist-links a')
        # genre
        genre_section = soup.select('.genre-list__link')
        # cover
        cover_section = soup.select('.single-album-tombstone__art img')
        # year
        year_section = soup.select('.single-album-tombstone__meta-year')
        # label
        label_section = soup.select('.labels-list__item')
        

        if artist_section:
            title = title_section[0].text
        if score_section:
            score = float(score_section[0].text)
        if artist_section:
            artist = artist_section[0].text
        if genre_section:
            genre = genre_section[0].text.split("/")
        if cover_section:
            cover = cover_section[0]['src']
        if year_section:
            year = year_section[0].text
            year = re.findall("[0-9]+", year)[0]
            year = int(year)
        if label_section:
            label = label_section[0].text

        rec = {'title': title, 'artist': artist, 'score': score, 
               'year': year, 'cover': cover, 'genre': genre, 'label': label}

    except Exception as ex:
        print('Exception while parsing')
        print(str(ex))
    finally:
        return json.dumps(rec)


if __name__ == '__main__':
    print('Running Consumer..')
    parsed_records = []
    topic_name = 'raw_albums'
    parsed_topic_name = 'parsed_reviews'

    consumer = KafkaConsumer(topic_name, auto_offset_reset='earliest',
                             bootstrap_servers=['localhost:9092'], api_version=(0, 10), consumer_timeout_ms=1000)
    for msg in consumer:
        html = msg.value
        result = parse(html)
        parsed_records.append(result)

    consumer.close()
    #sleep(5)

    if len(parsed_records) > 0:
        print('Publishing records..')
        producer = connect_kafka_producer()
        for rec in parsed_records:
            publish_message(producer, parsed_topic_name, 'parsed', rec)
