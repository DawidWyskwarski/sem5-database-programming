-- Zad 1
SELECT K.imie
FROM KOCURY K
INNER JOIN KOCURY K2 
    ON K.szef = K2.pseudo 
LEFT JOIN Wrogowie_kocurow WK 
    ON K.pseudo = WK.pseudo
WHERE K.w_stadku_od < K2.w_stadku_od OR WK.imie_wroga IS NULL;

-- Zad 2
SELECT
    K.pseudo,
    WK.imie_wroga,
    WK.opis_incydentu
FROM KOCURY K
INNER JOIN Wrogowie_kocurow WK 
    ON K.pseudo = WK.pseudo
WHERE K.plec = 'D';

-- Zad 3
SELECT 
    K.pseudo,
    K.nr_bandy
FROM KOCURY K
INNER JOIN Bandy B
    ON K.nr_bandy = B.nr_bandy
WHERE 
    B.szef_bandy <> 'TYGRYS' AND
    K.szef = 'TYGRYS';

-- Zad 4
SELECT 
    ISNULL(K1.pseudo, 'Brak przelozonego') AS "Przelozony",
    ISNULL(K2.pseudo, 'Brak podwladnego') AS "Podwladny"
FROM KOCURY K1
FULL JOIN KOCURY K2
    ON K1.pseudo = K2.szef
WHERE
    (K1.plec = 'M' OR K1.szef IS NULL) AND
    (K2.plec = 'M' OR K2.szef IS NULL);

-- Zad 5
SELECT DISTINCT
    K.pseudo,
    K.przydzial_myszy,
    S.SUM_W_BANDZIE,
    CAST(ROUND(K.PRZYDZIAL_MYSZY * 100.0 / S.SUM_W_BANDZIE, 0) AS INT) AS "PROC_W_BANDZIE"
FROM KOCURY K
INNER JOIN BANDY B
    ON K.nr_bandy = B.nr_bandy
INNER JOIN Wrogowie_kocurow WK
    ON K.pseudo = WK.pseudo
INNER JOIN WROGOWIE W
    ON Wk.imie_wroga = W.imie_wroga
CROSS APPLY (
    SELECT SUM(PRZYDZIAL_MYSZY) AS "SUM_W_BANDZIE"
    FROM KOCURY
    WHERE NR_BANDY = K.NR_BANDY 
) S
WHERE 
    B.teren IN ('POLE', 'CALOSC') AND 
    W.stopien_wrogosci > 5;

-- Zad 6
SELECT 
    K.pseudo,
    K.przydzial_myszy,
    K.nr_bandy,
    CASE
        WHEN K.przydzial_myszy > (SELECT AVG(KI.przydzial_myszy) FROM KOCURY KI ) THEN 'Prominent'
        WHEN K.przydzial_myszy = (SELECT MIN(KI.przydzial_myszy) FROM KOCURY KI WHERE KI.nr_bandy = K.nr_bandy) THEN 'Szarak'
    END AS TYP
FROM KOCURY K
WHERE
    ( K.przydzial_myszy > (SELECT AVG(KI.przydzial_myszy) FROM KOCURY KI) ) OR
    ( K.przydzial_myszy = (SELECT MIN(KI.przydzial_myszy) FROM KOCURY KI WHERE KI.nr_bandy = K.nr_bandy) )
ORDER BY TYP;

-- Zad 7
SELECT 
    K.pseudo,
    (
        SELECT AVG(CAST(KIN.przydzial_myszy AS FLOAT))
        FROM Kocury KIN
        WHERE KIN.nr_bandy = K.nr_bandy
    ) as "Srednio w bandzie"
FROM KOCURY K
WHERE K.plec = 'M';

-- Zad 8a
SELECT 
    K.nr_bandy,
    AVG(CAST(K.przydzial_myszy AS FLOAT)) as "Sredni przydzial w bandzie"
FROM KOCURY K
GROUP BY K.nr_bandy
HAVING AVG(CAST(K.przydzial_myszy AS FLOAT)) > (
    SELECT AVG(CAST(KIN.przydzial_myszy AS FLOAT))
    FROM KOCURY KIN
);

-- Zad 8b
SELECT 
    K.nr_bandy,
    AVG(CAST(K.przydzial_myszy AS FLOAT)) as "Sredni przydzial w bandzie",
    (
        SELECT AVG(CAST(KIN.przydzial_myszy AS FLOAT))
        FROM KOCURY KIN
    ) AS "Sredni przydzial"
FROM KOCURY K
GROUP BY K.nr_bandy
HAVING AVG(CAST(K.przydzial_myszy AS FLOAT)) > (
    SELECT AVG(KIN.przydzial_myszy)
    FROM KOCURY KIN
);

-- Zad 9
SELECT 
    DATENAME(month, K.w_stadku_od) AS Miesiac,
    COUNT(*) AS "Liczba rekrutow"
FROM KOCURY K
GROUP BY DATENAME(month, K.w_stadku_od), MONTH(K.w_stadku_od)
ORDER BY MONTH(K.w_stadku_od);

-- Zad 10
SELECT
    K.funkcja,
    ISNULL(SUM(
        CASE WHEN B.nazwa = 'CZARNI RYCERZE' THEN
            K.przydzial_myszy + ISNULL(K.myszy_extra,0) end
    ),0) as "Banda CZARNI RYCERZE",
    ISNULL(SUM(
        CASE WHEN B.nazwa = 'BIALI LOWCY' THEN
            K.przydzial_myszy + ISNULL(K.myszy_extra,0) end
    ),0) as "Banda BIALI LOWCY"
FROM KOCURY K 
INNER JOIN BANDY B
    ON K.nr_bandy = B.nr_bandy
WHERE K.FUNKCJA <> 'SZEFUNIO'
GROUP BY K.funkcja;

-- Zad 11
SELECT
    K.funkcja,
    K.plec,
    ISNULL(SUM(
        CASE WHEN B.nazwa = 'CZARNI RYCERZE' THEN
            K.przydzial_myszy + ISNULL(K.myszy_extra,0) end
    ),0) as "Banda CZARNI RYCERZE",
    ISNULL(SUM(
        CASE WHEN B.nazwa = 'BIALI LOWCY' THEN
            K.przydzial_myszy + ISNULL(K.myszy_extra,0) end
    ),0) as "Banda BIALI LOWCY"
FROM KOCURY K 
INNER JOIN BANDY B
    ON K.nr_bandy = B.nr_bandy
WHERE K.FUNKCJA <> 'SZEFUNIO'
GROUP BY K.funkcja, K.plec;