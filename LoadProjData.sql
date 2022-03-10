-- Change this to the database name!
USE cs_411_test;

-- Create tables for data usage

DROP TABLE IF EXISTS Friends;
DROP TABLE IF EXISTS Ratings;
DROP TABLE IF EXISTS Books;
DROP TABLE IF EXISTS Publishers;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Authors;

DROP TABLE IF EXISTS Books_RAW;

-- Load Books table
CREATE TABLE Books_RAW (
    -- ISBN10 is always 10 characters long and it's unique
    ISBN            CHAR(10)        PRIMARY KEY, 
    Title           VARCHAR(4096),
    Author          VARCHAR(255),
    YearPublished   INT,
    PublisherName   VARCHAR(8192),
    UNUSED1         VARCHAR(255),
    UNUSED2         VARCHAR(255),
    UNUSED3         VARCHAR(255)
);

LOAD DATA INFILE '/var/lib/mysql-files/books/Books.csv' IGNORE
INTO TABLE Books_RAW
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

ALTER TABLE Books_RAW
DROP COLUMN UNUSED1,
DROP COLUMN UNUSED2,
DROP COLUMN UNUSED3;

-- Load Publishers by creating unique IDs for each publisher
SET @pub_id=1;
CREATE TABLE Publishers (
  SELECT @pub_id:=@pub_id+1 AS PublisherId, PublisherName
  FROM Books_RAW
  GROUP BY PublisherName
);

ALTER TABLE Publishers
ADD PRIMARY KEY(PublisherId);

-- Convert the Books dataset to use Publisher IDs
CREATE TABLE Books (
    SELECT * FROM Books_RAW NATURAL JOIN Publishers
);

DROP TABLE Books_RAW;

ALTER TABLE Books
DROP COLUMN PublisherName,
ADD PRIMARY KEY (ISBN),
ADD FOREIGN KEY (PublisherId) REFERENCES Publishers (PublisherId);

-- Load the Users dataset
CREATE TABLE Users (
    Username VARCHAR(32) PRIMARY KEY,
    UNUSED1  VARCHAR(255),
    UNUSED2  VARCHAR(255)
);

LOAD DATA INFILE '/var/lib/mysql-files/books/Users.csv' IGNORE
INTO TABLE Users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

ALTER TABLE Users
DROP COLUMN UNUSED1,
DROP COLUMN UNUSED2,
ADD COLUMN DisplayName VARCHAR(32) DEFAULT NULL,
ADD COLUMN PasswordHash CHAR(64) DEFAULT NULL; -- We use SHA512 so hashes are 512 bits = 64 B

-- Load the Ratings dataset
CREATE TABLE Ratings (
    Username    VARCHAR(32) ,
    ISBN        CHAR(10),
    Rating      INT,

    FOREIGN KEY (Username)  REFERENCES Users (Username),
    FOREIGN KEY (ISBN)      REFERENCES Books (ISBN),
    PRIMARY KEY (Username, ISBN),

    -- The rating must be valid
    CHECK(Rating >= 0 AND Rating <= 10)
);

LOAD DATA INFILE '/var/lib/mysql-files/books/Ratings.csv' IGNORE
INTO TABLE Ratings
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

ALTER TABLE Ratings
ADD COLUMN Description VARCHAR(255) DEFAULT ""; 

CREATE TABLE Authors (
    UNUSED1 VARCHAR(255),
    Name VARCHAR(255) PRIMARY KEY,
    UNUSED2 VARCHAR(255),
    Popularity INT
);

LOAD DATA INFILE '/var/lib/mysql-files/books/authors.csv' IGNORE
INTO TABLE Authors
FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

ALTER TABLE Authors
DROP COLUMN UNUSED1,
DROP COLUMN UNUSED2;

CREATE TABLE Friends (
    WantsRecs VARCHAR(32),
    GivesRecs VARCHAR(32),

    FOREIGN KEY (WantsRecs) REFERENCES Users (Username),
    FOREIGN KEY (GivesRecs) REFERENCES Users (Username)
);