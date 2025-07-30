CREATE TABLE authors_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    au_id VARCHAR(11),
    action VARCHAR(255),
    event_time DATETIME DEFAULT GETDATE()
);

--1
CREATE TRIGGER trg_Author_Insert
ON authors
AFTER INSERT
AS
BEGIN
    INSERT INTO authors_log (au_id, action, event_time)
    SELECT au_id, 'Dodano nowego autora', GETDATE()
    FROM inserted;
END;

INSERT INTO authors (au_id, au_lname, au_fname, phone, address, city, state, zip, contract)
VALUES ('567-56-0008', 'Konrad', 'Wanat', '415 658-9932', '6223 Bateman St.', 'Berkeley', 'CA', '94705', 1);

--2
CREATE TRIGGER trg_Author_Delete
ON authors
AFTER DELETE
AS
BEGIN
    INSERT INTO authors_log (au_id, action, event_time)
    SELECT au_id, 'Author Deleted', GETDATE()
    FROM deleted;
END;

DELETE FROM authors
WHERE au_id = '567-56-0008';

SELECT * FROM authors_log;

--3
DROP TABLE authors_log

CREATE TABLE authors_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    au_id VARCHAR(12),
    action VARCHAR(255),
    old_au_lname VARCHAR(40),
    new_au_lname VARCHAR(40),
    event_time DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_Author_Update
ON authors
AFTER UPDATE
AS
BEGIN
    IF UPDATE(au_lname)
    BEGIN
        INSERT INTO authors_log (au_id, action, old_au_lname, new_au_lname, event_time)
        SELECT 
            i.au_id, 
            'Author Updated', 
            d.au_lname,   
            i.au_lname,   
            GETDATE()      
        FROM inserted i
        JOIN deleted d ON i.au_id = d.au_id
        WHERE i.au_id = d.au_id;
    END
END;

UPDATE authors
SET au_lname = 'Kowalski'
WHERE au_id = '409-56-7008';

SELECT * FROM authors_log;

--4
CREATE TRIGGER trg_Author_Before_Insert
ON authors
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE LEN(phone) != 12
    )
    BEGIN
        RAISERROR('Numer telefonu musi zawieraæ dok³adnie 12 znaków.', 16, 1);
        RETURN;
    END
    
    INSERT INTO authors (au_id, au_lname, au_fname, phone, address, city, state, zip, contract)
    SELECT au_id, au_lname, au_fname, phone, address, city, state, zip, contract
    FROM inserted;
END;

INSERT INTO authors (au_id, au_lname, au_fname, phone, address, city, state, zip, contract)
VALUES ('123-45-6789', 'Nowak', 'Jan', '415 658 9932', '123 Main St.', 'Warsaw', 'WA', '00001', 1);

SELECT * FROM authors_log;

--5
CREATE TRIGGER trg_Author_Delete2
ON authors
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM titleauthor ta
        INNER JOIN deleted d ON ta.au_id = d.au_id
    )
    BEGIN
        RAISERROR('Nie mo¿na usun¹æ autora, poniewa¿ posiada przypisane ksi¹¿ki.', 16, 1);
        RETURN;
    END
    
    DELETE FROM authors
    WHERE au_id IN (SELECT au_id FROM deleted);
END;

DELETE FROM authors
WHERE au_id = '409-56-7008';

--6
CREATE TRIGGER trg_Author_Phone_Update
ON authors
AFTER UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE LEN(phone) != 12 OR phone = ''
    )
    BEGIN
        RAISERROR('Numer telefonu musi mieæ dok³adnie 12 znaków.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;

UPDATE authors
SET phone = '415 658 9032'
WHERE au_id = '123-45-6789';

SELECT * FROM authors;
