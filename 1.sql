-- 1
select * from authors where au_fname like 'M%R'
-- 2
select * from titles where title like '%?'
-- 3
select * from Sales  where ord_date between '1993-06-01' and '1994-10-31'
-- 4
select * from stores where zip between 80000 and 95000
-- 5
select left(au_fname,1) + '. ' + left(au_lname,1) as FullName from authors
--6
SELECT 
    au_id,
    au_lname,
    au_fname,
    CAST(
        REPLACE(
            REPLACE(phone, ' ', ''),  
            '-', ''                  
        ) AS BIGINT
    ) AS phone_numeric
FROM authors;

-- 7
select au_fname + ' ' + au_lname as fullname from authors union select fname + ' ' + lname as fullname from employee

-- 8
SELECT 
    DATEPART(YEAR, pubdate) AS publication_year,
    COUNT(*) AS number_of_publications
FROM titles
GROUP BY DATEPART(YEAR, pubdate)
ORDER BY publication_year;

--9
SELECT
    [type],
    AVG(price) AS avg_price
FROM titles
GROUP BY [type]
HAVING AVG(price) > 15;


--10
SELECT 
    e.fname AS first_name,
    e.lname AS last_name,
    j.job_desc AS job_title,
    COALESCE(p.[state], 'NA') AS [state]
FROM employee e
JOIN publishers p ON e.pub_id = p.pub_id
JOIN jobs j      ON e.job_id = j.job_id
WHERE e.hire_date < '1994-01-01'
ORDER BY p.pub_name, j.job_desc;

--11
USE pubs;
GO

CREATE TABLE title_reviews
(
    review_id        INT IDENTITY(1,1) PRIMARY KEY,
    title_id         tid NOT NULL
        REFERENCES titles(title_id),     
    review_text      VARCHAR(2000) NULL,   
    review_date      DATETIME NOT NULL
        CONSTRAINT DF_title_reviews_date DEFAULT GETDATE(),  
      

    reviewer_fname   VARCHAR(50) NULL,     
    reviewer_lname   VARCHAR(50) NULL,     

    rating           TINYINT NOT NULL
        CHECK (rating >= 1 AND rating <= 5)
);
GO


INSERT INTO title_reviews 
    (title_id, review_text, reviewer_fname, reviewer_lname, rating)
VALUES
    ('BU1032', 
     'Œwietna lektura.', 
     'Jan', 'Kowalski', 5),

    ('MC2222', 
     'Ksi¹¿ka o gotowaniu.', 
     'Anna', 'Nowak', 3),

    ('PS7777', 
     'Ciekawe ujêcie.', 
     NULL, NULL, 4),  

    ('TC7777', 
     'Zbyt skomplikowane ', 
     'Marek', 'Wiœniewski', 2),

    ('PC9999', 
     'Œwietne wskazówki.', 
     'Ewa', 'B¹k', 5);
GO

--12
USE pubs;
GO

CREATE VIEW v_author_revenue
AS
SELECT 
    a.au_id,
    a.au_lname,
    a.au_fname,
    SUM(s.qty * t.price * (ta.royaltyper / 100.0)) AS author_revenue
FROM authors AS a
    JOIN titleauthor AS ta ON a.au_id = ta.au_id
    JOIN titles      AS t  ON ta.title_id = t.title_id
    JOIN sales       AS s  ON t.title_id = s.title_id
GROUP BY 
    a.au_id, 
    a.au_lname, 
    a.au_fname;
GO

SELECT * FROM v_author_revenue;


--13
USE pubs;
GO

CREATE VIEW v_publisher_monthly_revenue
AS
SELECT
    p.pub_id,
    p.pub_name,
    DATEPART(YEAR,  s.ord_date) AS sale_year,
    DATEPART(MONTH, s.ord_date) AS sale_month,
    SUM(s.qty * t.price)        AS monthly_revenue
FROM publishers p
    JOIN titles t ON p.pub_id = t.pub_id
    JOIN sales  s ON t.title_id = s.title_id
GROUP BY
    p.pub_id,
    p.pub_name,
    DATEPART(YEAR,  s.ord_date),
    DATEPART(MONTH, s.ord_date);
GO

SELECT * FROM v_publisher_monthly_revenue;
SELECT * FROM v_publisher_monthly_revenue
WHERE pub_name = 'New Moon Books';

--14
USE pubs;
GO

CREATE FUNCTION fn_total_book_sale
(
    @title_id tid
)
RETURNS INT
AS
BEGIN
    DECLARE @total INT;

    SELECT @total = SUM(s.qty)
    FROM sales s
    WHERE s.title_id = @title_id;

    
    RETURN COALESCE(@total, 0);
END;
GO

SELECT dbo.fn_total_book_sale('BU1032') AS total_sold;


--15
USE pubs;
GO

CREATE FUNCTION fn_avg_price_by_pub
(
    @pub_id CHAR(4)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @avg_price DECIMAL(10,2);

    SELECT @avg_price = AVG(t.price)
    FROM titles t
    WHERE t.pub_id = @pub_id;

    RETURN @avg_price;
END;
GO

SELECT dbo.fn_avg_price_by_pub('1389') AS total_sold;



--16
USE pubs;
GO

CREATE PROCEDURE sp_add_new_author
(
    @fname  VARCHAR(20),
    @lname  VARCHAR(40),
    @phone  CHAR(12)       = 'UNKNOWN', 
    @addr   VARCHAR(40)    = NULL,
    @city   VARCHAR(20)    = NULL,
    @state  CHAR(2)        = NULL,
    @zip    CHAR(5)        = NULL,
    @contract BIT          = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS
    (
        SELECT 1
        FROM authors
        WHERE au_lname = @lname
          AND au_fname = @fname
    )
    BEGIN
        RAISERROR('Author with the given first and last name already exists.', 16, 1);
        RETURN;
    END;


    DECLARE @new_id VARCHAR(11);

    SET @new_id = 'AUT' 
                  + REPLACE(
                       SUBSTRING(
                           CONVERT(VARCHAR(23), GETDATE(), 121), 1, 8
                       ), 
                       '-', ''
                    ); 

 
    INSERT INTO authors
    (
        au_id, au_lname, au_fname, phone, address, city, state, zip, contract
    )
    VALUES
    (
        @new_id, @lname, @fname, @phone, @addr, @city, @state, @zip, @contract
    );

 
    SELECT 'New author inserted with ID: ' + @new_id AS InfoMessage;
END;
GO

--17
USE pubs;
GO

CREATE PROCEDURE sp_delete_book
(
    @title_id tid
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRAN;   

   
    IF NOT EXISTS(SELECT 1 FROM titles WHERE title_id = @title_id)
    BEGIN
        RAISERROR('No book found with the given title_id: %s',16,1,@title_id);
        ROLLBACK TRAN;
        RETURN;
    END;

    DELETE FROM sales       WHERE title_id = @title_id;
    DELETE FROM titleauthor WHERE title_id = @title_id;
    DELETE FROM roysched    WHERE title_id = @title_id;

    DELETE FROM titles      WHERE title_id = @title_id;

    COMMIT TRAN; 

    SELECT 'Book with ID ' + @title_id + ' was successfully removed.' AS InfoMessage;
END;
GO

--18

USE pubs;
GO

CREATE PROCEDURE sp_author_sales_summary
(
    @au_id id
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS(SELECT 1 FROM authors WHERE au_id = @au_id)
    BEGIN
        RAISERROR('Author with given au_id does not exist: %s', 16, 1, @au_id);
        RETURN;
    END;

    DECLARE @total INT;

    SELECT @total = SUM(s.qty)
    FROM titleauthor ta
         JOIN sales s ON ta.title_id = s.title_id
    WHERE ta.au_id = @au_id;

    IF @total IS NULL
    BEGIN
        RAISERROR('No books or no sales found for author with au_id = %s', 16, 1, @au_id);
        RETURN;
    END;

    SELECT @au_id AS au_id, @total AS total_sold;
END;
GO
