DROP PROCEDURE IF EXISTS RecommendFromSimilar;
DROP PROCEDURE IF EXISTS RecommendFromFriends;
DROP PROCEDURE IF EXISTS RecommendFromAuthor;
DROP PROCEDURE IF EXISTS RecommendFromPublisher;

-- Recommend books based on similar users.
DELIMITER //
CREATE PROCEDURE RecommendFromSimilar (IN usr VARCHAR(30), IN minRating INT, IN minSimilar INT) BEGIN
    DROP TABLE IF EXISTS RateList;
    DROP TABLE IF EXISTS GoodRated;
    DROP TABLE IF EXISTS SimilarUsers;
    DROP TABLE IF EXISTS RateListUnsorted;

    -- List of all books the user liked
    CREATE TABLE GoodRated (
        ISBN CHAR(10) PRIMARY KEY
    );

    INSERT INTO GoodRated (
        SELECT ISBN
        FROM Ratings
        WHERE Username = usr AND Rating > minRating
    );

    -- Get all users with similar reading lists that liked similar books
    CREATE TABLE SimilarUsers (
        Username VARCHAR(32) PRIMARY KEY,
        NumCommonBooks INT
    );

    INSERT INTO SimilarUsers (
        SELECT Username, COUNT(Rating) AS NumCommonBooks
        FROM Ratings r
        WHERE EXISTS (SELECT * FROM GoodRated g WHERE g.ISBN = r.ISBN) AND Rating > minRating
        GROUP BY Username 
        HAVING NumCommonBooks > minSimilar 
        ORDER BY NumCommonBooks DESC LIMIT 10
    );

    -- Find the similar users' reading lists and keep the ones with the most ratings
    CREATE TABLE RateListUnsorted (
        ISBN CHAR(10) PRIMARY KEY,
        Title VARCHAR(4096),
        Author VARCHAR(255),
        PublisherName VARCHAR(8192)
    );
    INSERT INTO RateListUnsorted (
        SELECT ISBN, MIN(b.Title) AS Title, MIN(b.Author) AS Author, MIN(PublisherName) AS PublisherName
        FROM (Books b NATURAL JOIN Ratings r NATURAL JOIN Publishers p)
        WHERE EXISTS(SELECT * FROM SimilarUsers s WHERE s.Username = r.Username)
        GROUP BY ISBN
    );

    -- Next, we need to add a similarity score to determine what books to recommend (sort)
    -- use sum(num common books) for every similar user that read that book
    CREATE TABLE RateList (
        ISBN CHAR(10) PRIMARY KEY,
        Title VARCHAR(4096),
        Author VARCHAR(255),
        PublisherName VARCHAR(8192),
        Score INT
    );
    INSERT INTO RateList (
        SELECT ISBN, MIN(b.Title) AS Title, MIN(b.Author) AS Author, MIN(PublisherName) AS PublisherName, SUM(NumCommonBooks) AS Score
        FROM RateListUnsorted b NATURAL JOIN Ratings r NATURAL JOIN SimilarUsers u
        GROUP BY ISBN
        ORDER BY Score DESC
        LIMIT 50
    );

    SELECT * FROM RateList LIMIT 30;

END //
DELIMITER ;

-- Recommend books from friends.
DELIMITER //
CREATE PROCEDURE RecommendFromFriends (IN usr VARCHAR(30), IN minRating INT) 
BEGIN
    DROP TABLE IF EXISTS UserBooksRead;
    DROP TABLE IF EXISTS UserFriends;
    DROP TABLE IF EXISTS FriendRatings;

    -- List of all books the user read
    CREATE TABLE UserBooksRead (
        ISBN CHAR(10) PRIMARY KEY
    );

    INSERT INTO UserBooksRead (
        SELECT ISBN
        FROM Ratings
        WHERE Username = usr
    );

    -- Get all of the user's friends
    CREATE TABLE UserFriends (
        WantsRecs VARCHAR(32),
        GivesRecs VARCHAR(32),
        PRIMARY KEY (WantsRecs, GivesRecs)
    );

    INSERT INTO UserFriends (
        SELECT WantsRecs, GivesRecs
        FROM Friends f
        WHERE WantsRecs = usr -- this is important because we want to filter the friends table to only include the friends of the user we are interested in
    );

    -- Find the friend's reading lists and their ratings
    CREATE TABLE FriendRatings (
        ISBN CHAR(10) PRIMARY KEY,
        Title VARCHAR(4096),
        Author VARCHAR(255),
        PublisherName VARCHAR(8192),
        Score INT
    );
    
    INSERT INTO FriendRatings ( -- ask about the min thing
        SELECT ISBN, MIN(b.Title) AS Title, MIN(b.Author) AS Author, MIN(PublisherName) AS PublisherName, SUM(Rating) as Score
        FROM (Books b NATURAL JOIN Ratings r NATURAL JOIN Publishers p)
        WHERE (r.Rating >= minRating) AND EXISTS(
            SELECT GivesRecs 
            FROM UserFriends uf
            WHERE uf.GivesRecs = r.Username
        ) AND NOT EXISTS(
            SELECT ISBN
            FROM UserBooksRead br
            WHERE br.ISBN = b.ISBN
        )
        GROUP BY ISBN
        ORDER BY Score DESC
    );

    SELECT * FROM FriendRatings LIMIT 30;

END //
DELIMITER ;

-- Recommend books from same author
DELIMITER //
CREATE PROCEDURE RecommendFromAuthor (IN usr VARCHAR(30), IN minRating INT) 
BEGIN
    DROP TABLE IF EXISTS UserBooksRead;
    DROP TABLE IF EXISTS Authors;
    DROP TABLE IF EXISTS AuthorRatings;

    -- List of all books the user read
    CREATE TABLE UserBooksRead (
        ISBN CHAR(10) PRIMARY KEY
    );

    INSERT INTO UserBooksRead (
        SELECT ISBN
        FROM Ratings
        WHERE Username = usr
    );

    -- Get all of the user's friends
    CREATE TABLE Authors (
        Author VARCHAR(255)
    );

    INSERT INTO Authors (
        SELECT DISTINCT Author
        FROM Books b
        WHERE EXISTS (
            SELECT *
            FROM UserBooksRead ub
            WHERE ub.ISBN = b.ISBN
        )
    );

    CREATE TABLE AuthorRatings (
        ISBN CHAR(10) PRIMARY KEY,
        Title VARCHAR(4096),
        Author VARCHAR(255),
        PublisherName VARCHAR(8192),
        Score INT
    );
 
    INSERT INTO AuthorRatings (
        SELECT ISBN, MIN(b.Title) AS Title, MIN(b.Author) AS Author, MIN(PublisherName) AS PublisherName, 1 as Score
        FROM (Books b NATURAL JOIN Ratings r NATURAL JOIN Publishers p)
        WHERE (r.Rating >= minRating) AND EXISTS(
            SELECT * 
            FROM Authors a
            WHERE a.Author = b.Author
        ) AND NOT EXISTS(
            SELECT ISBN
            FROM UserBooksRead br
            WHERE br.ISBN = b.ISBN
        )
        GROUP BY ISBN
        ORDER BY Score DESC
    );

    SELECT * FROM AuthorRatings LIMIT 30;

END //
DELIMITER ;

-- Recommend from same publisher
DELIMITER //
CREATE PROCEDURE RecommendFromPublisher (IN usr VARCHAR(30), IN minRating INT) 
BEGIN
    DROP TABLE IF EXISTS UserBooksRead;
    DROP TABLE IF EXISTS Publishers_Proc;
    DROP TABLE IF EXISTS PublisherRatings;

    -- List of all books the user read
    CREATE TABLE UserBooksRead (
        ISBN CHAR(10) PRIMARY KEY
    );

    INSERT INTO UserBooksRead (
        SELECT ISBN
        FROM Ratings
        WHERE Username = usr
    );

    -- Get all of the user's friends
    CREATE TABLE Publishers_Proc (
        PublisherId INT
    );

    INSERT INTO Publishers_Proc (
        SELECT DISTINCT PublisherId
        FROM Books b
        WHERE EXISTS (
            SELECT *
            FROM UserBooksRead ub
            WHERE ub.ISBN = b.ISBN
        )
    );

    CREATE TABLE PublisherRatings (
        ISBN CHAR(10) PRIMARY KEY,
        Title VARCHAR(4096),
        Author VARCHAR(255),
        PublisherName VARCHAR(8192),
        TotalRating INT -- check if int or real
    );
 
    INSERT INTO PublisherRatings (
        SELECT ISBN, MIN(b.Title) AS Title, MIN(b.Author) AS Author, MIN(PublisherName) AS PublisherName, 1 as Score
        FROM (Books b NATURAL JOIN Ratings r NATURAL JOIN Publishers p)
        WHERE (r.Rating >= minRating) AND EXISTS(
            SELECT * 
            FROM Publishers_Proc pp
            WHERE p.PublisherId = pp.PublisherId
        ) AND NOT EXISTS(
            SELECT ISBN
            FROM UserBooksRead br
            WHERE br.ISBN = b.ISBN
        )
        GROUP BY ISBN
        ORDER BY Score DESC
    );

    SELECT * FROM PublisherRatings LIMIT 30;

END //
DELIMITER ;