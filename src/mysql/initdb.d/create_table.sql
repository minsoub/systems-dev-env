CREATE DATABASE systems;
GRANT ALL PRIVILEGES ON systems.* TO 'systems'@'%';
USE systems;
CREATE TABLE `sample` (
  `idx` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` varchar(30) NOT NULL,
  `user_name` varchar(30) NOT NULL,
  `password` varchar(128) NOT NULL,
  `email` varchar(50) NOT NULL,
  `create_date` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`idx`),
  UNIQUE KEY `UK_sample` (`user_id`)
);