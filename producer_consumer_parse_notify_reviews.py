import json
from bs4 import BeautifulSoup
from kafka import KafkaConsumer
import re

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
            try:
                year = year_section[0].text
                year = re.findall("[0-9]+", year)[0]
                year = int(year)
            except:
                year = 'Not available'
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

    consumer = KafkaConsumer(topic_name, auto_offset_reset='earliest', bootstrap_servers=['localhost:9092', 'localhost:9093', 'localhost:9094'], api_version=(0, 10), consumer_timeout_ms=15000)

    for msg in consumer:
        html = msg.value
        result = parse(html)
        parsed_records.append(result)
        
    print('========================================')
    score_threshold = 7.5
    for msg in parsed_records:
        review = json.loads(msg)
        score = review['score']
        title = review['title']
        artist = review['artist']
        genre = review['genre']

        if score >= score_threshold:
            print('Good album alert!')
            print('Title: ' + title)
            print('Artist: ' + artist)
            print('Genres: ' + ', '.join(genre))
            print('Score: {}'.format(score))

            print('========================================')

    consumer.close()
