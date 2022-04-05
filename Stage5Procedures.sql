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

DELIMITER //
CREATE PROCEDURE SetPopularity ()
BEGIN
    DECLARE AuthName VARCHAR(255) DEFAULT "";
    DECLARE AuthUserRating INT DEFAULT 0;

    DECLARE Done INT DEFAULT 0;

    DECLARE cs CURSOR FOR (SELECT Name FROM Authors);
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET Done=1;

    OPEN cs;
    REPEAT
        FETCH cs INTO AuthName;

        SET AuthUserRating = (
            SELECT SUM(Rating)
            FROM Books b NATURAL JOIN Ratings r
            WHERE b.Author = AuthName
            GROUP BY b.Author
        );

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

    UPDATE Authors SET UserRatings = (@curr_pop + NEW.Rating) WHERE Name=@curr_author;

END //

DELIMITER ;

DELIMITER //
CREATE PROCEDURE UpdatePopularity ()
BEGIN
    DECLARE AuthName VARCHAR(255) DEFAULT "";
    DECLARE AuthUserRating INT DEFAULT 0;
    DECLARE AuthBaseRating INT DEFAULT 0;

    DECLARE Done INT DEFAULT 0;

    DECLARE cs CURSOR FOR (SELECT Name, UserRatings, BaseRatings FROM Authors);
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET Done=1;

    OPEN cs;
    REPEAT
        FETCH cs INTO AuthName, AuthUserRating, AuthBaseRating;
        UPDATE Authors SET Popularity = AuthBaseRating + AuthUserRating WHERE Name = AuthName;

        UNTIL Done
    END REPEAT;
    CLOSE cs;
END //
DELIMITER ;
