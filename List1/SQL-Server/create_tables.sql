CREATE TABLE Funkcje (
    funkcja NVARCHAR(10) PRIMARY KEY,
    min_myszy TINYINT,
    max_myszy TINYINT,

    CONSTRAINT chk_min_myszy
        CHECK(min_myszy > 5),
    CONSTRAINT chk_max_myszy
        CHECK(min_myszy <= max_myszy AND max_myszy < 200)
);

CREATE TABLE Wrogowie (
    imie_wroga NVARCHAR(15) PRIMARY KEY,
    stopien_wrogosci TINYINT,
    gatunek NVARCHAR(15),
    lapowa NVARCHAR(20),

    CONSTRAINT chk_stopien_wrogosci
        CHECK(stopien_wrogosci<=10 AND 1<=stopien_wrogosci)
);

CREATE TABLE Kocury (
    imie NVARCHAR(15) NOT NULL,
    plec NVARCHAR(1),
    pseudo NVARCHAR(15) PRIMARY KEY,
    funkcja NVARCHAR(10),
    szef NVARCHAR(15),
    w_stadku_od DATE DEFAULT (GETDATE()),
    przydzial_myszy TINYINT,
    myszy_extra TINYINT,
    nr_bandy TINYINT,
  
    CONSTRAINT chk_plec
        CHECK(plec IN ('M', 'D')),
    CONSTRAINT fk_funkcja
        FOREIGN KEY (funkcja)
        REFERENCES Funkcje(funkcja),
    CONSTRAINT fk_szef
        FOREIGN KEY (szef)
        REFERENCES Kocury(pseudo)
);

CREATE TABLE Bandy (
    nr_bandy TINYINT PRIMARY KEY,
    nazwa NVARCHAR(20) NOT NULL,
    teren NVARCHAR(15) UNIQUE,
    szef_bandy NVARCHAR(15) UNIQUE,

    CONSTRAINT fk_szef_bandy
        FOREIGN KEY (szef_bandy)
        REFERENCES Kocury(pseudo)
);

ALTER TABLE Kocury
    ADD CONSTRAINT fk_nr_bandy
    FOREIGN KEY (nr_bandy)
    REFERENCES Bandy(nr_bandy);

CREATE TABLE Wrogowie_kocurow (
    pseudo NVARCHAR(15),
    imie_wroga NVARCHAR(15),
    data_incydentu DATE NOT NULL,
    opis_incydentu NVARCHAR(50),

    CONSTRAINT fk_pseudo
        FOREIGN KEY (pseudo)
        REFERENCES Kocury(pseudo),
    CONSTRAINT fk_imie_wroga
        FOREIGN KEY (imie_wroga)
        REFERENCES Wrogowie(imie_wroga),
    CONSTRAINT pk_pseudo_imie_wroga
        PRIMARY KEY (pseudo, imie_wroga)
);