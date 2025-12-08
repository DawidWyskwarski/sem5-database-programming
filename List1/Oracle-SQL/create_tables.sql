CREATE TABLE Funkcje (
    funkcja VARCHAR2(10) PRIMARY KEY,
    min_myszy NUMBER(3),
    max_myszy NUMBER(3),

    CONSTRAINT chk_min_myszy 
        CHECK(min_myszy > 5), 
    CONSTRAINT chk_max_myszy 
        CHECK(min_myszy <= max_myszy AND max_myszy < 200)
);

CREATE TABLE Wrogowie (
    imie_wroga VARCHAR2(15) PRIMARY KEY,
    stopien_wrogosci NUMBER(2),
    gatunek VARCHAR2(15),
    lapowa VARCHAR2(20),
    
    CONSTRAINT chk_stopien_wrogosci 
        CHECK(stopien_wrogosci<=10 AND 1<=stopien_wrogosci)
);

CREATE TABLE Kocury (
    imie VARCHAR2(15) NOT NULL,
    plec VARCHAR2(1),
    pseudo VARCHAR2(15) PRIMARY KEY,
    funkcja VARCHAR2(10),
    szef VARCHAR2(15),
    w_stadku_od DATE DEFAULT SYSDATE,
    przydzial_myszy NUMBER(3),
    myszy_extra NUMBER(3),
    nr_bandy NUMBER(2),

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
    nr_bandy NUMBER(2) PRIMARY KEY,
    nazwa VARCHAR2(20) NOT NULL,
    teren VARCHAR2(15) UNIQUE,
    szef_bandy VARCHAR2(15) UNIQUE,

    CONSTRAINT fk_szef_bandy 
        FOREIGN KEY (szef_bandy) 
        REFERENCES Kocury(pseudo)
);

ALTER TABLE Kocury
    ADD CONSTRAINT fk_nr_bandy 
    FOREIGN KEY (nr_bandy)
    REFERENCES Bandy(nr_bandy);

CREATE TABLE Wrogowie_kocurow (
    pseudo VARCHAR2(15),
    imie_wroga VARCHAR2(15),
    data_incydentu DATE NOT NULL,
    opis_incydentu VARCHAR2(50),

    CONSTRAINT fk_pseudo 
        FOREIGN KEY (pseudo) 
        REFERENCES Kocury(pseudo),
    CONSTRAINT fk_imie_wroga 
        FOREIGN KEY (imie_wroga) 
        REFERENCES Wrogowie(imie_wroga),
    CONSTRAINT pk_pseudo_imie_wroga 
        PRIMARY KEY (pseudo, imie_wroga)
);