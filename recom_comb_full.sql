DELIMITER //
CREATE PROCEDURE RecommendFromAll(IN usr VARCHAR(255), IN minRating INT, IN minSimilar INT)
BEGIN
    DROP TABLE IF EXISTS MergedRatings;
    DROP TABLE IF EXISTS CombinedRatings;

    CALL RecommendFromSimilar(usr, minRating, minSimilar);
    CALL RecommendFromAuthor(usr, minRating);
    CALL RecommendFromFriends(usr, minRating);
    CALL RecommendFromPublisher(usr, minRating);

    CREATE TABLE MergedRatings (
        ISBN CHAR(10) PRIMARY KEY,
        Title VARCHAR(4096),
        Author VARCHAR(255),
        PublisherName VARCHAR(8192),
        Score INT
    );

    INSERT INTO MergedRatings (
        SELECT *
        FROM SimilarRatings
        LIMIT 50
    );

    INSERT INTO MergedRatings (
        SELECT *
        FROM FriendRatings
        LIMIT 50
    );

    INSERT INTO MergedRatings (
        SELECT *
        FROM AuthorRatings
        LIMIT 50
    );

    INSERT INTO MergedRatings (
        SELECT *
        FROM PublisherRatings
        LIMIT 50
    );

    CREATE TABLE CombinedRatings (
        ISBN CHAR(10) PRIMARY KEY,
        Title VARCHAR(4096),
        Author VARCHAR(255),
        PublisherName VARCHAR(8192),
        Score INT       
    );

    INSERT INTO CombinedRatings (
        SELECT r.ISBN AS ISBN, r.Title AS Title, r.Author AS Author, r.PublisherName AS PublisherName,
        a.Score AS Score
        FROM MergedRatings r LEFT OUTER JOIN Authors a ON (r.Author = a.Name)
        ORDER BY Score
    );

    SELECT * FROM CombinedRatings LIMIT 50;

END //
DELIMTER ;