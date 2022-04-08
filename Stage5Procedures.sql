USE cs_411_test;

ALTER TABLE Authors
ADD COLUMN UserRatings INT DEFAULT 0,
ADD COLUMN BaseRatings INT DEFAULT 0;

-- Set the author base ratings correctly
-- FIXME: Check that the user has at least MIN_RATINGS ratings to allow their ratings to be counted
-- (This will count as another advanced query and satisfy the requirements to use IF)
UPDATE `Authors` SET `BaseRatings` = `Popularity`;

DROP PROCEDURE IF EXISTS SetPopularity;
DROP PROCEDURE IF EXISTS UpdatePopularity;
DROP TRIGGER   IF EXISTS UpdateUserReviews;

-- This index was actually slower than no index (by almost 0.5 seconds in a 2s query, quite significant)
-- CREATE INDEX BookAuthorIndex ON Books (Author);

DELIMITER //
CREATE PROCEDURE SetPopularity ()
BEGIN
    DECLARE AuthName VARCHAR(255) DEFAULT "";
    DECLARE AuthUserRating INT DEFAULT 0;

    DECLARE Done INT DEFAULT 0;

    DECLARE cs CURSOR FOR (SELECT Name FROM Authors);
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET Done=1;

    DROP TABLE IF EXISTS AuthUserRatings;

    CREATE TABLE AuthUserRatings (
        UserScores INT,
        Author VARCHAR(255) PRIMARY KEY
    );

    INSERT INTO AuthUserRatings (
        SELECT SUM(r.Rating) AS UserScores, b.Author
        FROM Books b NATURAL JOIN Ratings r
        GROUP BY b.Author
    );

    OPEN cs;
    REPEAT
        FETCH cs INTO AuthName;

        SET AuthUserRating = (SELECT UserScores FROM AuthUserRatings WHERE Author=AuthName);

        UPDATE `Authors` SET `UserRatings` = AuthUserRating WHERE `Name` = AuthName;

        UNTIL Done
    END REPEAT;
    CLOSE cs;
END //
DELIMITER ;


-- End of one-time database updates, start of running procedures
DELIMITER //

CREATE TRIGGER UpdateUserReviews 
BEFORE INSERT ON Ratings
FOR EACH ROW
BEGIN
    SET @curr_author = (SELECT Author FROM Books WHERE ISBN = NEW.ISBN);
    SET @curr_pop = (SELECT UserRatings FROM Authors WHERE Name = @curr_author);

    SET @curr_ratings = (SELECT COUNT(*) FROM Ratings WHERE Username = NEW.Username);

    -- Check that a user has at least 10 reviews before updating the database
    IF (@curr_ratings >= 10) THEN
        UPDATE Authors SET UserRatings = (@curr_pop + NEW.Rating) WHERE Name=@curr_author;
    END IF;

END //

DELIMITER ;

DELIMITER //
CREATE PROCEDURE UpdatePopularity ()
BEGIN
    DECLARE AuthName VARCHAR(255) DEFAULT "";
    DECLARE AuthPop INT DEFAULT 0;
    DECLARE AuthUserRating INT DEFAULT 0;
    DECLARE AuthBaseRating INT DEFAULT 0;

    DECLARE Done INT DEFAULT 0;

    DECLARE cs CURSOR FOR (SELECT Name, Popularity, UserRatings, BaseRatings FROM Authors);
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET Done=1;

    OPEN cs;
    REPEAT
        FETCH cs INTO AuthName, AuthPop, AuthUserRating, AuthBaseRating;

        -- check that an author's rating doesn't go up too much
        -- (from bot reviews)
        IF (AuthUserRating + AuthBaseRating < 1.1 * AuthPop) THEN
            UPDATE `Authors` SET `UserRatings` = AuthUserRating + AuthBaseRating 
            WHERE `Name` = AuthName;
        END IF;

        UNTIL Done
    END REPEAT;
    CLOSE cs;
END //
DELIMITER ;
