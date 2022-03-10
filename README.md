## docker-compose
```yaml
version: '3.7'
services:
  redis:
     image: redis:alpine
     command: redis-server --port 6379
     container_name: redisdb
     hostname: redisdb
     labels:
       - "name=redis"
       - "mode=standalone"
     ports:
       - 6379:6379
  mysql:
     image: mariadb:10
     container_name: mysqldb
     ports:
        - 3306:3306
     volumes:
        - ./mysql/conf.d:/etc/mysql/conf.d
        - ./mysql/data:/var/lib/mysql
        - ./mysql/initdb.d/create_table.sql:/docker-entrypoint-initdb.d/setup.sql
     env_file: ./mysql/.env
     environment:
        TZ: Asia/Seoul
     restart: always
  zookeeper:
     image: wurstmeister/zookeeper:3.4.6
     container_name: zookeeper
     ports:
        - 2181:2181
  kafka:
     image: wurstmeister/kafka:2.12-2.3.0
     container_name: kafka
     depends_on:
        - zookeeper
     ports:
        - 9092:9092
     environment:
        KAFKA_ADVERTISED_HOST_NAME: 127.0.0.1
        KAFKA_ADVERTISED_PORT: 9092
        KAFKA_CREATE_TOPICS: "systems_topic:2:2"
        KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
     volumes:
        - ./kafka/docker.sock:/var/run/docker.sock
  elasticsearch:
     image: docker.elastic.co/elasticsearch/elasticsearch:7.10.0
     container_name: elasticsearch
     ports:
        - 9200:9200
        - 9300:9300
     configs:
        - source: elastic_config
          target: /usr/share/elasticsearch/config/elasticsearch.yml
     environment:
        ES_JAVA_OPTS: "-Xmx256m -Xms256m"
        ELASTIC_PASSWORD: password
        discovery.type: single-node
     networks:
        - elk
     deploy:
        mode: replicated
        replicas: 1
  logstash:
     image: docker.elastic.co/logstash/logstash:7.10.0
     container_name: logstash
     ports:
        - 5044:5044
        - 5000:5000
        - 9600:9600
     configs:
        - source: logstash_config
          target: /usr/share/logstash/config/logstash.yml
        - source: logstash_pipeline
          target: /usr/share/logstash/pipeline/logstash.conf
     environment:
        LS_JAVA_OPTS: "-Xms256m -Xms256m"
     networks:
        - elk
     deploy:
        mode: replicated
        replicas: 1
  kibana:
     image: docker.elastic.co/kibana/kibana:7.10.0
     container_name: kibana
     ports:
        - 5601:5601
     configs:
        - source: kibana_config
          target: /usr/share/kibana/config/kiban.yml
     networks:
        - elk
     deploy:
        mode: replicated
        replicas: 1
configs:
  elastic_config:
     file: ./elk/elasticsearch/config/elasticsearch.yml
  logstash_config:
     file: ./elk/logstash/config/logstash.yml
  logstash_pipeline:
     file: ./elk/logstash/pipeline/logstash.conf
  kibana_config:
     file: ./elk/kibana/config/kibana.yml
networks:
  elk:
     name: elk-network
     driver: bridge
```
- 실행
```shell
$ docker-compose -f ./dev-server.yml up -d
$ docker ps
```
- redis 접속
```shell
minsoub@minsoubui-MacBookPro src % docker exec -it redisdb redis-cli
127.0.0.1:6379> keys *
(empty array)
127.0.0.1:6379> 
```
- mysql 접속
```shell
minsoub@minsoubui-MacBookPro src % docker exec -it mysqldb bash
root@31fa25ffed45:/# mysql -u root -psystemsroot!
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 3
Server version: 10.7.3-MariaDB-1:10.7.3+maria~focal mariadb.org binary distribution
```
- zookeeper log 보기
```shell
minsoub@minsoubui-MacBookPro src % docker container logs zookeeper
JMX enabled by default
Using config: /opt/zookeeper-3.4.6/bin/../conf/zoo.cfg
```
- kafka log 보기
```shell
minsoub@minsoubui-MacBookPro src % docker container logs kafka           
waiting for kafka to be ready
[Configuring] 'advertised.port' in '/opt/kafka/config/server.properties'
```
- stop/down
```shell
$ docker-compose -f ./dev-server.yml stop
$ docker-compose -f ./dev-server.yml down
```
- delete
```shell
$ docker-compose -f ./dev-server.yml rm -vf
```
- Kafka Test
테스트 프로그램 설치 - https://kafka.apache.org/downloads   
Topic 생성   
  - options   
    --zookeeper : Zookeeper 가 실행 중인 Host   
    --list : LIST
    --create : Topic create   
    --topic : Topic name   
    --partitions: topic partition count   
    --replication-factor: topic replica count
```
minsoub@minsoubui-MacBookPro bin % ./kafka-topics.sh --create --topic test-topic --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1
Created topic test-topic.
minsoub@minsoubui-MacBookPro bin % 
```
Consumer and Producer Test
```shell
kafka-console-consumer.sh –bootstrap-server localhost:9092 –topic test-topic –from-beginning
```
```shell
kafka-console-producer.sh –broker-list localhost:9092 –topic test-topic
```
producer에서 데이터를 입력하게 되면 consumer에서 나오게 된다.   

### ELK stack
#### logstash check
- Helath Check
```shell
minsoub@192 ~ % curl -XGET 'localhost:9600/?pretty'
{
  "host" : "0ab1ac305776",
  "version" : "7.10.0",
  "http_address" : "0.0.0.0:9600",
  "id" : "8003e074-fed5-4eb1-86bc-c44fa4bf3f96",
  "name" : "0ab1ac305776",
  "ephemeral_id" : "3d5dca13-a7f5-481a-b699-25329d5e4f2b",
  "status" : "green",
  "snapshot" : false,
  "pipeline" : {
    "workers" : 4,
    "batch_size" : 125,
    "batch_delay" : 50
  },
  "build_date" : "2020-11-09T23:35:06Z",
  "build_sha" : "d7808a0a3727cc53abb7d7cbe4df8df928dc557f",
  "build_snapshot" : false
}%   
```
- External connection setup
  config/logstash.yml   
```yml
http.host: "0.0.0.0"
```
#### elasticsearch check
```shell
minsoub@192 src % curl -XGET http://localhost:9200
{
  "name" : "2af08525dc3b",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "UQaBLl5cRdOa6yp9zgi6Lw",
  "version" : {
    "number" : "7.10.0",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "51e9d6f22758d0374a0f3f5c6e8f3a7997850f96",
    "build_date" : "2020-11-09T21:30:33.964949Z",
    "build_snapshot" : false,
    "lucene_version" : "8.7.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
minsoub@192 src % 
```
#### Kiban check
웹브라우저를 통해서 아래와 같이 접속한다.   
http://localhost:5601/    