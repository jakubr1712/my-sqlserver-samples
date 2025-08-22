CREATE DATABASE WypozyczalniaSamochodow;
USE WypozyczalniaSamochodow;


CREATE TABLE Klienci (
    ID_Klienta INT PRIMARY KEY IDENTITY(1,1),
    Imie NVARCHAR(50) NOT NULL,
    Nazwisko NVARCHAR(50) NOT NULL,
    Pesel NVARCHAR(11) UNIQUE NOT NULL,
    Telefon NVARCHAR(15),
    Email NVARCHAR(100),
    Adres NVARCHAR(200),
    Miasto NVARCHAR(50),
    Data_Rejestracji DATE DEFAULT GETDATE(),
    Aktywny BIT DEFAULT 1
);

CREATE TABLE Kategorie (
    ID_Kategorii INT PRIMARY KEY IDENTITY(1,1),
    Nazwa_Kategorii NVARCHAR(50) NOT NULL,
    Cena_Za_Dzien DECIMAL(10,2) NOT NULL,
    Opis NVARCHAR(200)
);

CREATE TABLE Samochody (
    ID_Samochodu INT PRIMARY KEY IDENTITY(1,1),
    Marka NVARCHAR(50) NOT NULL,
    Model NVARCHAR(50) NOT NULL,
    Rok_Produkcji INT,
    Nr_Rejestracyjny NVARCHAR(10) UNIQUE NOT NULL,
    Kolor NVARCHAR(30),
    Przebieg INT DEFAULT 0,
    ID_Kategorii INT,
    Dostepny BIT DEFAULT 1,
    Data_Dodania DATE DEFAULT GETDATE(),
    FOREIGN KEY (ID_Kategorii) REFERENCES Kategorie(ID_Kategorii)
);

CREATE TABLE Wypozyczenia (
    ID_Wypozyczenia INT PRIMARY KEY IDENTITY(1,1),
    ID_Klienta INT NOT NULL,
    ID_Samochodu INT NOT NULL,
    Data_Wypozyczenia DATE NOT NULL,
    Data_Zwrotu_Planowana DATE NOT NULL,
    Data_Zwrotu_Rzeczywista DATE NULL,
    Koszt_Calkowity DECIMAL(10,2),
    Status NVARCHAR(20) DEFAULT 'Aktywne',
    Uwagi NVARCHAR(500),
    Miasto_Wypozyczenia NVARCHAR(50),
    FOREIGN KEY (ID_Klienta) REFERENCES Klienci(ID_Klienta),
    FOREIGN KEY (ID_Samochodu) REFERENCES Samochody(ID_Samochodu),
    CHECK (Data_Zwrotu_Planowana > Data_Wypozyczenia),
    CHECK (Status IN ('Aktywne', 'Zakonczone', 'Anulowane'))
);

CREATE TABLE Logi_Operacji (
    ID_Logu INT PRIMARY KEY IDENTITY(1,1),
    Tabela NVARCHAR(50),
    Operacja NVARCHAR(20),
    ID_Rekordu INT,
    Uzytkownik NVARCHAR(100),
    Data_Operacji DATETIME DEFAULT GETDATE(),
    Szczegoly NVARCHAR(500)
);

CREATE TABLE WypozyczeniaJson (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Json NVARCHAR(MAX)
);


INSERT INTO Kategorie (Nazwa_Kategorii, Cena_Za_Dzien, Opis) VALUES
('Ekonomiczna', 80.00, 'Ma�e, oszcz�dne samochody idealne na miasto'),
('Kompaktowa', 120.00, '�rednie samochody z dobrym komfortem'),
('Premium', 250.00, 'Luksusowe samochody z pe�nym wyposa�eniem'),
('SUV', 180.00, 'Przestronne samochody terenowe');

INSERT INTO Klienci (Imie, Nazwisko, Pesel, Telefon, Email, Adres, Miasto) VALUES
('Jan', 'Kowalski', '85010112345', '123456789', 'jan.kowalski@email.com', 'ul. S�oneczna 15', 'Warszawa'),
('Anna', 'Nowak', '90020223456', '987654321', 'anna.nowak@email.com', 'ul. Kwiatowa 8', 'Krak�w'),
('Piotr', 'Wi�niewski', '88030334567', '555666777', 'piotr.wisniewski@email.com', 'ul. Le�na 22', 'Gda�sk'),
('Maria', 'Kowalczyk', '92040445678', '444333222', 'maria.kowalczyk@email.com', 'ul. Morska 5', 'Warszawa'),
('Tomasz', 'Zieli�ski', '87050556789', '111222333', 'tomasz.zielinski@email.com', 'ul. G�rska 12', 'Krak�w');

INSERT INTO Samochody (Marka, Model, Rok_Produkcji, Nr_Rejestracyjny, Kolor, Przebieg, ID_Kategorii) VALUES
('Toyota', 'Yaris', 2020, 'WA12345', 'Czerwony', 45000, 1),
('Volkswagen', 'Golf', 2019, 'KR67890', 'Niebieski', 38000, 2),
('BMW', 'X5', 2021, 'GD11111', 'Czarny', 25000, 4),
('Mercedes', 'C-Class', 2022, 'WA22222', 'Srebrny', 15000, 3),
('Skoda', 'Octavia', 2020, 'KR33333', 'Bia�y', 42000, 2),
('Audi', 'A4', 2021, 'GD44444', 'Szary', 28000, 3);

INSERT INTO Wypozyczenia (ID_Klienta, ID_Samochodu, Data_Wypozyczenia, Data_Zwrotu_Planowana, Data_Zwrotu_Rzeczywista, Koszt_Calkowity, Status, Miasto_Wypozyczenia) VALUES
(1, 1, '2024-01-15', '2024-01-20', '2024-01-20', 400.00, 'Zakonczone', 'Warszawa'),
(2, 2, '2024-02-10', '2024-02-17', '2024-02-17', 840.00, 'Zakonczone', 'Krak�w'),
(3, 3, '2024-03-05', '2024-03-12', NULL, 1260.00, 'Aktywne', 'Gda�sk'),
(4, 4, '2024-03-20', '2024-03-25', '2024-03-25', 1250.00, 'Zakonczone', 'Warszawa'),
(5, 5, '2024-04-01', '2024-04-08', NULL, 840.00, 'Aktywne', 'Krak�w'),
(1, 6, '2024-04-15', '2024-04-20', NULL, 1250.00, 'Aktywne', 'Warszawa');


CREATE PROCEDURE sp_WypozyczSamochod
    @ID_Klienta INT,
    @ID_Samochodu INT,
    @Data_Wypozyczenia DATE,
    @Liczba_Dni INT,
    @Miasto_Wypozyczenia NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF NOT EXISTS (SELECT 1 FROM Samochody WHERE ID_Samochodu = @ID_Samochodu AND Dostepny = 1)
        BEGIN
            RAISERROR('Samoch�d nie jest dost�pny', 16, 1);
            RETURN;
        END
        
        IF NOT EXISTS (SELECT 1 FROM Klienci WHERE ID_Klienta = @ID_Klienta AND Aktywny = 1)
        BEGIN
            RAISERROR('Klient nie istnieje lub nie jest aktywny', 16, 1);
            RETURN;
        END
        
        DECLARE @Cena_Za_Dzien DECIMAL(10,2);
        DECLARE @Koszt_Calkowity DECIMAL(10,2);
        DECLARE @Data_Zwrotu DATE = DATEADD(day, @Liczba_Dni, @Data_Wypozyczenia);
        
        SELECT @Cena_Za_Dzien = k.Cena_Za_Dzien
        FROM Samochody s
        JOIN Kategorie k ON s.ID_Kategorii = k.ID_Kategorii
        WHERE s.ID_Samochodu = @ID_Samochodu;
        
        SET @Koszt_Calkowity = @Cena_Za_Dzien * @Liczba_Dni;
        
        INSERT INTO Wypozyczenia (ID_Klienta, ID_Samochodu, Data_Wypozyczenia, Data_Zwrotu_Planowana, Koszt_Calkowity, Miasto_Wypozyczenia)
        VALUES (@ID_Klienta, @ID_Samochodu, @Data_Wypozyczenia, @Data_Zwrotu, @Koszt_Calkowity, @Miasto_Wypozyczenia);
        
        UPDATE Samochody SET Dostepny = 0 WHERE ID_Samochodu = @ID_Samochodu;
        
        COMMIT TRANSACTION;
        PRINT 'Wypo�yczenie zosta�o pomy�lnie dodane';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;

CREATE PROCEDURE sp_ZwrotSamochodu
    @ID_Wypozyczenia INT,
    @Data_Zwrotu DATE,
    @Dodatkowe_Koszty DECIMAL(10,2) = 0
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @ID_Samochodu INT;
        DECLARE @Data_Planowana DATE;
        DECLARE @Koszt_Podstawowy DECIMAL(10,2);
        DECLARE @Kara DECIMAL(10,2) = 0;
        
        SELECT @ID_Samochodu = ID_Samochodu, @Data_Planowana = Data_Zwrotu_Planowana, @Koszt_Podstawowy = Koszt_Calkowity
        FROM Wypozyczenia
        WHERE ID_Wypozyczenia = @ID_Wypozyczenia AND Status = 'Aktywne';
        
        IF @ID_Samochodu IS NULL
        BEGIN
            RAISERROR('Nie znaleziono aktywnego wypo�yczenia', 16, 1);
            RETURN;
        END
        
        IF @Data_Zwrotu > @Data_Planowana
        BEGIN
            SET @Kara = DATEDIFF(day, @Data_Planowana, @Data_Zwrotu) * 50;
        END
        
        UPDATE Wypozyczenia 
        SET Data_Zwrotu_Rzeczywista = @Data_Zwrotu,
            Status = 'Zakonczone',
            Koszt_Calkowity = @Koszt_Podstawowy + @Kara + @Dodatkowe_Koszty
        WHERE ID_Wypozyczenia = @ID_Wypozyczenia;
        
        UPDATE Samochody SET Dostepny = 1 WHERE ID_Samochodu = @ID_Samochodu;
        
        COMMIT TRANSACTION;
        PRINT CONCAT('Zwrot zako�czony. Kara: ', @Kara, ' z�, Dodatkowe koszty: ', @Dodatkowe_Koszty, ' z�');
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;

CREATE PROCEDURE sp_RaportMiesieczny
    @Rok INT,
    @Miesiac INT
AS
BEGIN
    DECLARE @Data_Od DATE = DATEFROMPARTS(@Rok, @Miesiac, 1);
    DECLARE @Data_Do DATE = EOMONTH(@Data_Od);
    
    SELECT 
        'STATYSTYKI OG�LNE' AS Kategoria,
        COUNT(*) AS Liczba_Wypozyczen,
        SUM(Koszt_Calkowity) AS Przychod_Calkowity,
        AVG(Koszt_Calkowity) AS Sredni_Koszt,
        COUNT(DISTINCT ID_Klienta) AS Liczba_Klientow
    FROM Wypozyczenia
    WHERE Data_Wypozyczenia BETWEEN @Data_Od AND @Data_Do;
    
    SELECT TOP 3
        s.Marka + ' ' + s.Model AS Samochod,
        COUNT(*) AS Liczba_Wypozyczen,
        SUM(w.Koszt_Calkowity) AS Przychod
    FROM Wypozyczenia w
    JOIN Samochody s ON w.ID_Samochodu = s.ID_Samochodu
    WHERE w.Data_Wypozyczenia BETWEEN @Data_Od AND @Data_Do
    GROUP BY s.Marka, s.Model, s.ID_Samochodu
    ORDER BY COUNT(*) DESC;
    
    SELECT 
        Miasto_Wypozyczenia,
        COUNT(*) AS Liczba_Wypozyczen,
        SUM(Koszt_Calkowity) AS Przychod
    FROM Wypozyczenia
    WHERE Data_Wypozyczenia BETWEEN @Data_Od AND @Data_Do
    GROUP BY Miasto_Wypozyczenia
    ORDER BY Przychod DESC;
END;

CREATE PROCEDURE sp_AktualizujPrzeterminowane
AS
BEGIN
    
    DECLARE @Liczba_Zaktualizowanych INT;
    
    UPDATE Wypozyczenia 
    SET Status = 'Przeterminowane',
        Uwagi = CONCAT(ISNULL(Uwagi, ''), ' [Przeterminowane od: ', GETDATE(), ']')
    WHERE Status = 'Aktywne' 
    AND Data_Zwrotu_Planowana < GETDATE()
    AND Data_Zwrotu_Rzeczywista IS NULL;
    
    SET @Liczba_Zaktualizowanych = @@ROWCOUNT;
    
    PRINT CONCAT('Zaktualizowano ', @Liczba_Zaktualizowanych, ' przeterminowanych wypo�ycze�');
END;


CREATE VIEW v_DostepneSamochody AS
SELECT 
    s.ID_Samochodu,
    s.Marka,
    s.Model,
    s.Rok_Produkcji,
    s.Nr_Rejestracyjny,
    s.Kolor,
    s.Przebieg,
    k.Nazwa_Kategorii,
    k.Cena_Za_Dzien,
    s.Data_Dodania
FROM Samochody s
JOIN Kategorie k ON s.ID_Kategorii = k.ID_Kategorii
WHERE s.Dostepny = 1;

CREATE VIEW v_AktywneWypozyczenia AS
SELECT 
    w.ID_Wypozyczenia,
    k.Imie + ' ' + k.Nazwisko AS Klient,
    k.Telefon,
    s.Marka + ' ' + s.Model AS Samochod,
    s.Nr_Rejestracyjny,
    w.Data_Wypozyczenia,
    w.Data_Zwrotu_Planowana,
    w.Koszt_Calkowity,
    w.Miasto_Wypozyczenia,
    DATEDIFF(day, GETDATE(), w.Data_Zwrotu_Planowana) AS Dni_Do_Zwrotu
FROM Wypozyczenia w
JOIN Klienci k ON w.ID_Klienta = k.ID_Klienta
JOIN Samochody s ON w.ID_Samochodu = s.ID_Samochodu
WHERE w.Status IN ('Aktywne', 'Przeterminowane');

CREATE VIEW v_StatystykiKlientow AS
SELECT 
    k.ID_Klienta,
    k.Imie + ' ' + k.Nazwisko AS Klient,
    k.Email,
    k.Miasto,
    COUNT(w.ID_Wypozyczenia) AS Liczba_Wypozyczen,
    SUM(w.Koszt_Calkowity) AS Laczne_Wydatki,
    AVG(w.Koszt_Calkowity) AS Srednie_Wydatki,
    MAX(w.Data_Wypozyczenia) AS Ostatnie_Wypozyczenie
FROM Klienci k
LEFT JOIN Wypozyczenia w ON k.ID_Klienta = w.ID_Klienta
WHERE k.Aktywny = 1
GROUP BY k.ID_Klienta, k.Imie, k.Nazwisko, k.Email, k.Miasto;


CREATE TRIGGER tr_KlienciLogger
ON Klienci
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO Logi_Operacji (Tabela, Operacja, ID_Rekordu, Uzytkownik, Szczegoly)
        SELECT 'Klienci', 'INSERT', ID_Klienta, SUSER_NAME(), 
               CONCAT('Dodano klienta: ', Imie, ' ', Nazwisko)
        FROM inserted;
    END
    
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO Logi_Operacji (Tabela, Operacja, ID_Rekordu, Uzytkownik, Szczegoly)
        SELECT 'Klienci', 'UPDATE', i.ID_Klienta, SUSER_NAME(),
               CONCAT('Zaktualizowano klienta: ', i.Imie, ' ', i.Nazwisko)
        FROM inserted i;
    END
    
    IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO Logi_Operacji (Tabela, Operacja, ID_Rekordu, Uzytkownik, Szczegoly)
        SELECT 'Klienci', 'DELETE', ID_Klienta, SUSER_NAME(),
               CONCAT('Usuni�to klienta: ', Imie, ' ', Nazwisko)
        FROM deleted;
    END
END;

CREATE TRIGGER tr_ObliczKosztWypozyczenia
ON Wypozyczenia
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE w
    SET Koszt_Calkowity = k.Cena_Za_Dzien * DATEDIFF(day, i.Data_Wypozyczenia, i.Data_Zwrotu_Planowana)
    FROM Wypozyczenia w
    JOIN inserted i ON w.ID_Wypozyczenia = i.ID_Wypozyczenia
    JOIN Samochody s ON i.ID_Samochodu = s.ID_Samochodu
    JOIN Kategorie k ON s.ID_Kategorii = k.ID_Kategorii
    WHERE (i.Koszt_Calkowity IS NULL OR i.Koszt_Calkowity = 0)
    AND DATEDIFF(day, i.Data_Wypozyczenia, i.Data_Zwrotu_Planowana) > 0;
END;


CREATE TRIGGER tr_WalidacjaDatWypozyczenia
ON Wypozyczenia
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    
    IF EXISTS (SELECT 1 FROM inserted WHERE Data_Wypozyczenia >= Data_Zwrotu_Planowana)
    BEGIN
        RAISERROR('Data zwrotu musi by� p�niejsza ni� data wypo�yczenia', 16, 1);
        RETURN;
    END
    
    IF EXISTS (SELECT 1 FROM inserted WHERE Data_Wypozyczenia < CAST(GETDATE() AS DATE))
    BEGIN
        RAISERROR('Data wypo�yczenia nie mo�e by� w przesz�o�ci', 16, 1);
        RETURN;
    END
    
    IF NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO Wypozyczenia (ID_Klienta, ID_Samochodu, Data_Wypozyczenia, Data_Zwrotu_Planowana, 
                                 Data_Zwrotu_Rzeczywista, Koszt_Calkowity, Status, Uwagi, Miasto_Wypozyczenia)
        SELECT ID_Klienta, ID_Samochodu, Data_Wypozyczenia, Data_Zwrotu_Planowana,
               Data_Zwrotu_Rzeczywista, Koszt_Calkowity, Status, Uwagi, Miasto_Wypozyczenia
        FROM inserted;
    END
    ELSE
    BEGIN
        UPDATE w
        SET ID_Klienta = i.ID_Klienta,
            ID_Samochodu = i.ID_Samochodu,
            Data_Wypozyczenia = i.Data_Wypozyczenia,
            Data_Zwrotu_Planowana = i.Data_Zwrotu_Planowana,
            Data_Zwrotu_Rzeczywista = i.Data_Zwrotu_Rzeczywista,
            Koszt_Calkowity = i.Koszt_Calkowity,
            Status = i.Status,
            Uwagi = i.Uwagi,
            Miasto_Wypozyczenia = i.Miasto_Wypozyczenia
        FROM Wypozyczenia w
        JOIN inserted i ON w.ID_Wypozyczenia = i.ID_Wypozyczenia;
    END
END;


CREATE PROCEDURE sp_KopiujWypozyczeniaDoJSON
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ID_Wypozyczenia INT;
    DECLARE @Miasto NVARCHAR(50);
    DECLARE @JsonData NVARCHAR(MAX);
    DECLARE @ErrorMessage NVARCHAR(500);
    
    DECLARE miasto_cursor CURSOR FOR
    SELECT DISTINCT Miasto_Wypozyczenia
    FROM Wypozyczenia
    WHERE Miasto_Wypozyczenia IS NOT NULL;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DELETE FROM WypozyczeniaJson;
        
        OPEN miasto_cursor;
        FETCH NEXT FROM miasto_cursor INTO @Miasto;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @JsonData = (
                SELECT 
                    @Miasto AS miasto,
                    COUNT(*) AS liczba_wypozyczen,
                    SUM(Koszt_Calkowity) AS laczny_koszt,
                    AVG(Koszt_Calkowity) AS sredni_koszt,
                    (
                        SELECT 
                            w.ID_Wypozyczenia,
                            k.Imie + ' ' + k.Nazwisko AS klient,
                            s.Marka + ' ' + s.Model AS samochod,
                            w.Data_Wypozyczenia,
                            w.Data_Zwrotu_Planowana,
                            w.Koszt_Calkowity,
                            w.Status
                        FROM Wypozyczenia w
                        JOIN Klienci k ON w.ID_Klienta = k.ID_Klienta
                        JOIN Samochody s ON w.ID_Samochodu = s.ID_Samochodu
                        WHERE w.Miasto_Wypozyczenia = @Miasto
                        FOR JSON PATH
                    ) AS wypozyczenia
                FROM Wypozyczenia
                WHERE Miasto_Wypozyczenia = @Miasto
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            );
            
            INSERT INTO WypozyczeniaJson (Json) VALUES (@JsonData);
            
            FETCH NEXT FROM miasto_cursor INTO @Miasto;
        END
        
        CLOSE miasto_cursor;
        DEALLOCATE miasto_cursor;
        
        COMMIT TRANSACTION;
        PRINT 'Dane zosta�y pomy�lnie skopiowane do formatu JSON';
        
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('global', 'miasto_cursor') >= -1
        BEGIN
            CLOSE miasto_cursor;
            DEALLOCATE miasto_cursor;
        END
        
        ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = CONCAT('B��d podczas kopiowania danych: ', ERROR_MESSAGE());
        RAISERROR(@ErrorMessage, 16, 1);
        
    END CATCH
END;


--testy

SELECT * FROM v_DostepneSamochody;

--
DECLARE @dzis DATE = CAST(GETDATE() AS DATE);

EXEC sp_WypozyczSamochod 
    @ID_Klienta = 1, 
    @ID_Samochodu = 1, 
    @Data_Wypozyczenia = @dzis, 
    @Liczba_Dni = 3, 
    @Miasto_Wypozyczenia = 'Warszawa';



--
EXEC sp_WypozyczSamochod 
    @ID_Klienta = 2, 
    @ID_Samochodu = 1, 
    @Data_Wypozyczenia = '2025-06-12', 
    @Liczba_Dni = 5,
    @Miasto_Wypozyczenia = 'Krak�w';

EXEC sp_RaportMiesieczny @Rok = 2024, @Miesiac = 3;


EXEC sp_KopiujWypozyczeniaDoJSON;


SELECT * FROM v_DostepneSamochody;
SELECT * FROM v_AktywneWypozyczenia;
SELECT * FROM v_StatystykiKlientow;


SELECT * FROM Logi_Operacji ORDER BY Data_Operacji DESC;


SELECT * FROM WypozyczeniaJson;


EXEC sp_WypozyczSamochod 
    @ID_Klienta = 2, 
    @ID_Samochodu = 1, 
    @Data_Wypozyczenia = '2024-06-12', 
    @Liczba_Dni = 5,
    @Miasto_Wypozyczenia = 'Krak�w';


