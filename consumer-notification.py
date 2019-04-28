import json
from kafka import KafkaConsumer

if __name__ == '__main__':
    parsed_topic_name = 'parsed_reviews'
    # Notify if a recipe has more than 200 calories
    score_threshold = 8

    consumer = KafkaConsumer(parsed_topic_name, auto_offset_reset='earliest',
                             bootstrap_servers=['localhost:9092'], api_version=(0, 10), consumer_timeout_ms=1000)
    
    print('========================================')
    
    for msg in consumer:
        review = json.loads(msg.value)
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
        #sleep(3)

    if consumer is not None:
        consumer.close()
