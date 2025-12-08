-- Zad 26
WITH KOTKI AS (
    SELECT pseudo
    FROM Kocury
    WHERE plec = 'D'
),
POWYZEJ5 AS (
    SELECT k.pseudo
    FROM Kocury k
    INNER JOIN Wrogowie_kocurow wk
        ON k.pseudo = wk.pseudo
    INNER JOIN Wrogowie w
        ON wk.imie_wroga = w.imie_wroga
    WHERE w.stopien_wrogosci > 5
)
SELECT pseudo as "Zadziorne kotki" FROM KOTKI
INTERSECT
SELECT pseudo FROM POWYZEJ5;

-- Zad 27
WITH Hierarchia AS (
    SELECT 
        k.pseudo,
        k.funkcja,
        k.nr_bandy,
        k.plec,
        k.szef,
        1 AS poziom,
        CAST('/' + k.pseudo AS varchar(max)) AS sciezka
    FROM Kocury k
    WHERE k.plec = 'M' AND k.funkcja = 'BANDZIOR'

    UNION ALL

    SELECT 
        c.pseudo,
        c.funkcja,
        c.nr_bandy,
        c.plec,
        c.szef,
        h.poziom + 1,
        h.sciezka + CAST('/' + c.pseudo AS varchar(max))
    FROM Kocury c
    INNER JOIN Hierarchia h ON c.szef = h.pseudo
)
SELECT 
    poziom AS "Poziom",
    pseudo AS "Pseudonim",
    funkcja AS "Funkcja",
    nr_bandy AS "Nr bandy"
FROM Hierarchia
WHERE plec = 'M'
ORDER BY sciezka, poziom, pseudo;

-- Zad 28
WITH Hierarchia AS (
    SELECT 
        0 AS Poziom,
        pseudo,
        imie,
        szef AS [Pseudo szefa],
        funkcja AS [Funkcja],
        myszy_extra,
        pseudo AS root_szef
    FROM Kocury
    WHERE szef IS NULL

    UNION ALL

    SELECT 
        h.Poziom + 1,
        k.pseudo,
        k.imie,
        k.szef AS [Pseudo szefa],
        k.funkcja AS [Funkcja],
        k.myszy_extra,
        h.root_szef
    FROM Kocury k
    JOIN Hierarchia h
        ON k.szef = h.pseudo
)
SELECT 
    CONCAT(REPLICATE('===>', Poziom),Poziom) + '    ' + imie AS Hierarchia,
    ISNULL("Pseudo szefa", 'Sam sobie panem') AS "Pseudo szefa",
    "Funkcja"
FROM Hierarchia h
WHERE h.myszy_extra IS NOT NULL
ORDER BY h.root_szef, Poziom;

-- Zad 29
WITH Hierarchia as (
    SELECT
        k.pseudo,
        cast('/' + k.pseudo as varchar(max)) as sciezka,
        0 as poziom
    FROM Kocury k
    WHERE k.szef IS NULL

    UNION ALL 

    SELECT 
        k.pseudo,
        h.sciezka + cast('/' + k.pseudo as varchar(max)) as sciezka,
        poziom + 1 as poziom
    FROM KOCURY k
    JOIN Hierarchia h
        ON k.szef = h.pseudo
), Liscie as (
    SELECT 
        h.pseudo,
        case when h.poziom < LEAD(h.poziom) OVER (ORDER BY h.sciezka) THEN 0 ELSE 1 END as lisc
    FROM Hierarchia h
)
SELECT DISTINCT
    k.pseudo,
    b.nazwa
FROM Liscie l 
INNER JOIN Kocury k
    on l.pseudo = k.pseudo
INNER JOIN Bandy b
    ON k.nr_bandy = b.nr_bandy
INNER JOIN Funkcje f
    ON k.funkcja = f.funkcja
INNER JOIN Wrogowie_kocurow wk
    ON k.pseudo = wk.pseudo
WHERE 
    l.lisc = 1 AND 
    k.przydzial_myszy >= (f.min_myszy + (f.max_myszy - f.min_myszy)/3);