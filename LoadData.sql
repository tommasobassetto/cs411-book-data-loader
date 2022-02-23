/*
CREATE PROCEDURE LoadFullData ()
BEGIN
    DROP DATABASE IF EXISTS(cs_411_test);
    CREATE DATABASE(cs_411_test);
    USE cs_411_test;

    CALL LoadData1();
END;
*/
DROP TABLE IF EXISTS Data1_RAW;
DROP TABLE IF EXISTS Data1_Cleaned;

CREATE TABLE Data1_RAW (
    BookId          INT,
    Title           VARCHAR(255),
    Authors         VARCHAR(1023),
    AvgRating       VARCHAR(255),
    ISBN            VARCHAR(255),
    ISBN13          VARCHAR(255),
    Lang            VARCHAR(255),
    PageCt          VARCHAR(255),
    RateCt          VARCHAR(255),
    TextReviewCt    VARCHAR(255),
    Publication     VARCHAR(255),
    Publisher       VARCHAR(255),
    Unused          VARCHAR(255),

    PRIMARY KEY (BookId)
);

-- The data must be in this location
LOAD DATA INFILE '/var/lib/mysql-files/data1/books.csv'
INTO TABLE Data1_RAW
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Check that data was inserted succesfully
SELECT * FROM Data1_RAW LIMIT 10;

-- Create cleaned table, and use stored procedure to convert to this format
CREATE TABLE Data1_Cleaned (
    BookId          INT,
    Title           VARCHAR(255),
    Authors         VARCHAR(1023),
    AvgRating       REAL,
    ISBN            BIGINT,
    ISBN13          BIGINT,
    Lang            VARCHAR(255),
    PageCt          INT,
    RateCt          INT,
    TextReviewCt    INT,
    Publication     DATE,
    Publisher       VARCHAR(255),

    PRIMARY KEY (BookId)
);
-- FIXME: Use a subquery instead of a stored procedure to clean the data
INSERT INTO Data1_Cleaned
VALUES (
    ()
)

CREATE PROCEDURE CleanDataOne ()
BEGIN
SELECT * FROM Data1_RAW LIMIT 10;
    /*DECLARE cur_id          INT;
    DECLARE cur_title       VARCHAR(255);
    DECLARE cur_authors     VARCHAR(1023);

    DECLARE cur_rating      VARCHAR(255);
    DECLARE cur_rating_i    REAL;

    DECLARE cur_isbn        VARCHAR(255);

    DECLARE cur_isbn13      VARCHAR(255);
    DECLARE cur_isbn13_i    BIGINT;

    DECLARE cur_lang        VARCHAR(255);

    DECLARE cur_rct         VARCHAR(255);
    DECLARE cur_rct_i       INT;

    DECLARE cur_tct         VARCHAR(255);
    DECLARE cur_tct_i       INT;

    DECLARE cur_pub_d       VARCHAR(255);
    DECLARE cur_pub_d_i     DATE;

    DECLARE cur_pub_ed      VARCHAR(255);
    DECLARE cur_unused      VARCHAR(255);

    DECLARE finished BOOL DEFAULT FALSE;

    DECLARE cur CURSOR FOR SELECT * FROM Data1_RAW;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = TRUE;

    OPEN cur;
    REPEAT
        FETCH cur INTO cur_id, cur_title, cur_authors, cur_rating, cur_isbn, cur_isbn13, cur_lang, cur_rct, cur_tct, cur_pub_d, cur_pub_ed, cur_unused;

        -- Use try_cast to check for data validity and convert to correct format
        SET cur_rating_i = TRY_CAST(cur_rating AS REAL);
        SET cur_isbn13_i = TRY_CAST(cur_isbn13 AS BIGINT);
        SET cur_rct_i    = TRY_CAST(cur_rct AS INT);
        SET cur_tct_i    = TRY_CAST(cur_tct AS INT);
        SET cur_pub_d_i  = TRY_CAST(cur_pub_d AS DATE);

        IF cur_rating_i     IS NOT NULL
        AND cur_isbn13_i    IS NOT NULL
        AND cur_rct_i       IS NOT NULL
        AND cur_tct_i       IS NOT NULL
        AND cur_pub_d_i     IS NOT NULL
        AND cur_unused      IS NULL THEN

            -- If data is valid, insert it into the cleaned table
            INSERT INTO Data1_Cleaned
            VALUES (
                cur_id, cur_title, cur_authors, cur_rating_i, cur_isbn, cur_isbn13_i, cur_lang, cur_rct_i, cur_tct_i, cur_pub_d_i, cur_pub_ed
            );
        END IF;

    UNTIL finished;
    END REPEAT;

    CLOSE cur;

    SELECT * FROM Data1_Cleaned LIMIT 10;*/

END

CALL CleanDataOne();
