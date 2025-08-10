--1
SELECT title
FROM titles
WHERE pub_id IN (
    SELECT pub_id
    FROM publishers
    WHERE state = 'CA'
);


--2
SELECT 
    title,
    price,
    (SELECT AVG(price) FROM titles) AS avg_price
FROM titles;

--3
SELECT
	au_lname,
	au_fname
from authors
where au_id in(
SELECT au_id
FROM titleauthor
WHERE title_id IN (
    SELECT title_id
    FROM titles
    WHERE price > (
        SELECT AVG(price) FROM titles
    )
));
--4
SELECT p.pub_name, t.avg_price
FROM publishers p
JOIN (
    SELECT pub_id, AVG(price) AS avg_price
    FROM titles
    GROUP BY pub_id
) t
ON p.pub_id = t.pub_id;


--5
SELECT pub_name
FROM publishers
WHERE pub_id IN (
    SELECT pub_id
    FROM titles
    GROUP BY pub_id
    HAVING COUNT(*) > 5
);

--6
UPDATE titles
SET price = price * 1.10
WHERE price < (
    SELECT AVG(price) FROM titles
);

--7
SELECT
    au_lname,
    au_fname,
    (SELECT COUNT(*) FROM titleauthor ta WHERE ta.au_id = a.au_id) AS book_count
FROM authors a;

--8
INSERT INTO stores (stor_id, stor_name)
VALUES (0, 'withdrawn');


INSERT INTO sales (stor_id, ord_num, ord_date, qty, payterms, title_id)
SELECT 
    0,                            
    -1,                           
    GETDATE(),                     
    0,                            
    'n/a',                         
    t.title_id                    
FROM titles t
LEFT JOIN sales s ON t.title_id = s.title_id
WHERE s.title_id IS NULL;         
