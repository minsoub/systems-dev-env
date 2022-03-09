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
  db:
     image: mariadb:10
     container_name: mysqldb
     ports:
        - 3306:3306
     volumes:
        - ./mysql/conf.d:/etc/mysql/conf.d
        - ./mysql/data:/var/lib/mysql
        - ./mysql/initdb.d:/docker-entrypoint-initdb.d
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