-- ZAD 11
SELECT 
    PSEUDO,
    TO_CHAR(W_STADKU_OD, 'YYYY-MM-DD') AS W_STADKU_OD,
    CASE 
        WHEN EXTRACT(DAY FROM W_STADKU_OD) <= 15 THEN 
            CASE 
                WHEN TO_DATE('2024-10-31', 'YYYY-MM-DD') 
                     <= NEXT_DAY(LAST_DAY(TO_DATE('2024-10-31', 'YYYY-MM-DD')) - 7, 'WED') 
                THEN TO_CHAR(NEXT_DAY(LAST_DAY(TO_DATE('2024-10-31', 'YYYY-MM-DD')) - 7, 'WED'), 'YYYY-MM-DD')
                ELSE TO_CHAR(NEXT_DAY(LAST_DAY(ADD_MONTHS(TO_DATE('2024-10-31', 'YYYY-MM-DD'), 1)) - 7, 'WED'), 'YYYY-MM-DD')
            END
        ELSE 
            TO_CHAR(NEXT_DAY(LAST_DAY(ADD_MONTHS(TO_DATE('2024-10-31', 'YYYY-MM-DD'), 1)) - 7, 'WED'), 'YYYY-MM-DD')
    END AS WYPLATA
FROM 
    KOCURY;

-- ZAD 12
SELECT 'Liczba kotow= ' || COUNT(*) || ' lowi jako ' || FUNKCJA || ' i zjada max. ' || MAX(PRZYDZIAL_MYSZY+ NVL(MYSZY_EXTRA, 0)) || ' myszy miesiecznie' AS "Informacje o kotkach"
FROM KOCURY
WHERE 
    FUNKCJA != 'SZEFUNIO' AND 
    PLEC = 'D'
GROUP BY 
    FUNKCJA
HAVING 
    AVG(PRZYDZIAL_MYSZY + NVL(MYSZY_EXTRA, 0)) > 50
ORDER BY 
    COUNT(*);

-- ZAD 13
SELECT 
    NR_BANDY, 
    PLEC, 
    MIN(PRZYDZIAL_MYSZY) AS "Minimalny przydzial"
FROM 
    KOCURY
GROUP BY 
    NR_BANDY, 
    PLEC;