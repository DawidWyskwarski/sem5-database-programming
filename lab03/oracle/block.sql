-- Zad 1
DECLARE
    fun Kocury.FUNKCJA%TYPE;
BEGIN
    SELECT DISTINCT funkcja
    INTO fun 
    FROM Kocury 
    WHERE funkcja = UPPER('&input_fun');

    DBMS_OUTPUT.PUT_LINE('cat who has ' || fun || ' function found!');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('no cat with a given function found!');
END;

UNDEFINE input_fun;

-- Zad 3
DECLARE
    cat KOCURY%ROWTYPE;
BEGIN 
    SELECT * 
    INTO cat
    FROM KOCURY
    WHERE PSEUDO = UPPER('&input_pseudo');

    IF 12*(cat.przydzial_myszy + NVL(cat.myszy_extra, 0)) > 700 THEN
        DBMS_OUTPUT.PUT_LINE('calkowity roczny przydzial myszy > 700');
    ELSIF cat.imie LIKE '%A%' THEN
        DBMS_OUTPUT.PUT_LINE('imie zawiera litere A');
    ELSIF EXTRACT (MONTH FROM cat.w_stadku_od) = 5 THEN
        DBMS_OUTPUT.PUT_LINE('maj jest miesiacem przystapienia do stada');
    ELSE
        DBMS_OUTPUT.PUT_LINE('nie odpowieada kryteriom');
    END IF;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('no cat with a given pseudo found!');
END;

UNDEFINE input_pseudo;

-- Zad 4 -- czy mogę wypisać od razu czy tak jak jest zrobione, czy wszystkie bandy czy tylko te w których jest co najmniej jeden kot
DECLARE
    TYPE cat_tab IS TABLE OF KOCURY%ROWTYPE
        INDEX BY BINARY_INTEGER;
    lowest_time_in_band cat_tab;
    CURSOR bands IS 
        SELECT DISTINCT nr_bandy FROM kocury ORDER BY nr_bandy;
    i BANDY.nr_bandy%TYPE;
BEGIN

    FOR b IN bands LOOP
        SELECT * INTO lowest_time_in_band(b.nr_bandy)
        FROM KOCURY
        WHERE NR_BANDY = b.nr_bandy
        ORDER BY w_stadku_od DESC
        FETCH FIRST 1 ROW ONLY;
    END LOOP;

    FOR b IN bands LOOP
        i:= b.nr_bandy;

        DBMS_OUTPUT.PUT_LINE(
            'BANDA: ' || lowest_time_in_band(i).nr_bandy);
        DBMS_OUTPUT.PUT_LINE(
            'IMIE: ' || lowest_time_in_band(i).imie);
        DBMS_OUTPUT.PUT_LINE(
            'PLEC: ' || lowest_time_in_band(i).plec);
        DBMS_OUTPUT.PUT_LINE(
            'FUNKCJA: ' || lowest_time_in_band(i).funkcja);
        DBMS_OUTPUT.PUT_LINE(
            'SZEF: ' || lowest_time_in_band(i).szef);
        DBMS_OUTPUT.PUT_LINE(
            'W STADKU OD: ' || TO_CHAR(lowest_time_in_band(i).w_stadku_od,'YYYY-MM-DD'));
        DBMS_OUTPUT.PUT_LINE(
            'PRZYDZIAL MYSZY: ' || lowest_time_in_band(i).przydzial_myszy);
        DBMS_OUTPUT.PUT_LINE(
            'MYSZY EXTRA: ' || NVL(lowest_time_in_band(i).myszy_extra,0));

        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('no cats found');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM); 
END;

-- Zad 5
DECLARE
    CURSOR catsOrdered IS
        SELECT k.pseudo, k.PRZYDZIAL_MYSZY, f.MAX_MYSZY
        FROM KOCURY k 
        INNER JOIN FUNKCJE f
            ON k.FUNKCJA = f.FUNKCJA
        ORDER BY PRZYDZIAL_MYSZY;
    
    cat catsOrdered%ROWTYPE;
    new_allocation INTEGER;
    s INTEGER;
    changes INTEGER := 0;
    threshold INTEGER := 1050;
BEGIN
    SELECT SUM(PRZYDZIAL_MYSZY) 
    INTO s
    FROM KOCURY;

    WHILE (s <= threshold) LOOP
        OPEN catsOrdered;
        LOOP
            FETCH catsOrdered INTO cat;
            EXIT WHEN catsOrdered%NOTFOUND OR s >= threshold;

            new_allocation := LEAST(FLOOR(cat.PRZYDZIAL_MYSZY*1.1), cat.MAX_MYSZY);
            s := s - cat.przydzial_myszy + new_allocation; 

            IF cat.przydzial_myszy <> new_allocation THEN
                UPDATE KOCURY SET 
                    PRZYDZIAL_MYSZY = new_allocation
                WHERE 
                    PSEUDO = cat.pseudo;

                changes := changes + 1;
            END IF;
            
        END LOOP;
        CLOSE catsOrdered;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Calk. przydzial w stadku: ' || s);
    DBMS_OUTPUT.PUT_LINE('Zmian: ' || changes);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;

SELECT IMIE, PRZYDZIAL_MYSZY
FROM KOCURY
ORDER BY PRZYDZIAL_MYSZY DESC;

ROLLBACK;

-- Zad 6
DECLARE
    nr INTEGER := 1;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Nr  Pseudonim   Zjada');
    DBMS_OUTPUT.PUT_LINE('--------------------');

    FOR cat IN ( SELECT PSEUDO, PRZYDZIAL_MYSZY + NVL(MYSZY_EXTRA, 0) as EATS FROM KOCURY ORDER BY EATS DESC ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(nr, 4) || RPAD(cat.PSEUDO, 11) || LPAD(cat.EATS, 5));
        nr := nr + 1;
        EXIT WHEN nr > 5;
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;

--Zad 7
DECLARE 
    lvl NUMBER := &input_lvl;
    max_lvl NUMBER := 0;

    curr_lvl NUMBER := 0;
    cat KOCURY%ROWTYPE;
BEGIN
    SELECT MAX(level) - 1
    INTO max_lvl
    FROM KOCURY
    START WITH FUNKCJA IN ('MILUSIA', 'KOT')
    CONNECT BY PRIOR SZEF = PSEUDO;

    lvl := LEAST(max_lvl, lvl);
    DBMS_OUTPUT.PUT(RPAD('Imie', 15));
    
    FOR i IN 1..lvl LOOP
        DBMS_OUTPUT.PUT(RPAD('|  Szef ' || i, 18));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT('------------- ');

    FOR i IN 1..lvl LOOP
        DBMS_OUTPUT.PUT('--- ------------- ');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');

    FOR cat_row IN (
        SELECT * 
        FROM KOCURY
        WHERE FUNKCJA IN ('MILUSIA', 'KOT')
    ) LOOP
        DBMS_OUTPUT.PUT(RPAD(cat_row.IMIE, 15));
        curr_lvl := 1;
        cat :=cat_row;

        WHILE curr_lvl <= lvl LOOP
            IF cat.SZEF IS NULL THEN
                DBMS_OUTPUT.PUT(RPAD('|', 18));
            ELSE
                SELECT * 
                INTO cat 
                FROM KOCURY
                WHERE PSEUDO = cat.SZEF;

                DBMS_OUTPUT.PUT(RPAD('|  ' || cat.IMIE, 18));
            END IF;
            curr_lvl := curr_lvl + 1;
        END LOOP;
    DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
END;

UNDEFINE input_lvl;

-- Zad 8

DECLARE
    bandNr NUMBER := &bNr;
    bandName VARCHAR2(20) := UPPER('&bName');
    bandArea VARCHAR2(15) := UPPER('&bArea');

    existCount INTEGER := 0;

    existingThings VARCHAR2(255);
    exist EXCEPTION;
    negative EXCEPTION;
BEGIN
    IF bandNr <= 0 THEN
        raise negative;
    END IF;

    SELECT COUNT(*) 
    INTO existCount
    FROM BANDY
    WHERE NR_BANDY = bandNr;

    IF existCount > 0 THEN
        existingThings := TO_CHAR(bandNr);
    END IF;

    SELECT COUNT(*) 
    INTO existCount
    FROM BANDY
    WHERE NAZWA = bandName;

    IF existCount > 0 THEN
        IF existingThings IS NOT NULL THEN
            existingThings := existingThings || ', '; 
        END IF; 

        existingThings := existingThings || bandName;
    END IF;

    SELECT COUNT(*) 
    INTO existCount
    FROM BANDY
    WHERE TEREN = bandArea;

    IF existCount > 0 THEN
        IF existingThings IS NOT NULL THEN
            existingThings := existingThings || ', '; 
        END IF;
        
        existingThings := existingThings || bandArea;
    END IF;

    IF LENGTH(existingThings) > 0 THEN 
        raise exist;
    END IF;

    INSERT INTO BANDY (NR_BANDY, NAZWA, TEREN) VALUES (bandNr, bandName, bandArea);
EXCEPTION
    WHEN negative THEN
        DBMS_OUTPUT.PUT_LINE('Liczba musi byc dodatnia!');
    WHEN exist THEN
        DBMS_OUTPUT.PUT_LINE(existingThings || ': już istnieje');
    WHEN OTHERS THEN 
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;

UNDEFINE bNr;
UNDEFINE bName;
UNDEFINE bArea;

SELECT * FROM BANDY;

rollback;

-- Zad 9
CREATE OR REPLACE PROCEDURE changeMouseRation(func FUNKCJE.FUNKCJA%TYPE, newRation KOCURY.PRZYDZIAL_MYSZY%TYPE) IS
    tooLittle EXCEPTION;
    tooMuch EXCEPTION;
    noRowsUpdated EXCEPTION;
    funcIsNull EXCEPTION;
    newRationIsNull EXCEPTION;

    minFun FUNKCJE.MIN_MYSZY%TYPE;
    maxFun FUNKCJE.MAX_MYSZY%TYPE;
    rowsUpdated INTEGER;
BEGIN
    IF func IS NULL THEN
        RAISE funcIsNull;
    END IF;

    IF newRation IS NULL THEN
        RAISE newRationIsNull;
    END IF;
    
    SELECT MIN_MYSZY, MAX_MYSZY
    INTO minFun, maxFun
    FROM FUNKCJE
    WHERE FUNKCJA = UPPER(func);

    IF newRation < minFun THEN
        RAISE tooLittle;
    END IF;

    IF newRation > maxFun THEN
        RAISE tooMuch;
    END IF;

    UPDATE KOCURY 
    SET PRZYDZIAL_MYSZY = newRation
    WHERE FUNKCJA = UPPER(func);

    rowsUpdated := SQL%ROWCOUNT;

    IF rowsUpdated = 0 THEN
        RAISE noRowsUpdated;
    END IF;

EXCEPTION 
    WHEN funcIsNull THEN
        DBMS_OUTPUT.PUT_LINE('function parameter can not be null');
    WHEN newRationIsNull THEN
        DBMS_OUTPUT.PUT_LINE('newRation parameter can not be null');
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('function ' || UPPER(func) || ' does not exist'); 
    WHEN tooLittle THEN
        DBMS_OUTPUT.PUT_LINE('new ration ' || newRation || ' is too small. min: ' || minFun);
    WHEN tooMuch THEN
        DBMS_OUTPUT.PUT_LINE('new ration ' || newRation || ' is too big. max: ' || maxFun);
    WHEN noRowsUpdated THEN
        DBMS_OUTPUT.PUT_LINE('no cats with a function ' || UPPER(func) || ' found');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;

-- Zad 10
CREATE OR REPLACE FUNCTION calculateTax(catPseudo KOCURY.PSEUDO%TYPE) RETURN NUMBER IS
    tax NUMBER;
    countBoss NUMBER := 0;
    countEnemies NUMBER := 0;
    isKot NUMBER;
BEGIN
    SELECT CEIL((PRZYDZIAL_MYSZY+NVL(MYSZY_EXTRA,0))*0.05)
    INTO tax
    FROM KOCURY
    WHERE PSEUDO = catPseudo;

    SELECT COUNT(*)
    INTO countBoss
    FROM KOCURY
    WHERE SZEF = catPseudo;

    IF countBoss = 0 THEN
        tax := tax + 2;
    END IF;

    SELECT COUNT(*)
    INTO countEnemies
    FROM WROGOWIE_KOCUROW
    WHERE pseudo = catPseudo; 

    IF countEnemies = 0 THEN
        tax := tax + 1;
    END IF;
    
    -- Jeśli kocur pwłni funkcję KOT płaci dodatek do podatku
    SELECT COUNT(*)
    INTO isKot
    FROM KOCURY
    WHERE PSEUDO = catPseudo AND FUNKCJA = 'KOT';
    
    IF isKot = 1 THEN
        tax := tax + 1;
    END IF;

    RETURN tax;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('no cat with given pseudo found');
        RETURN NULL;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
        RETURN NULL; 
END;

-- Zad 11
DECLARE
    CURSOR functions IS ( 
        SELECT DISTINCT FUNKCJA
        FROM KOCURY
    );
    tmp NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT(RPAD('NAZWA BANDY', 18) || RPAD('PLEC', 7) || LPAD('ILE', 5));
    
    FOR fun IN functions LOOP
        DBMS_OUTPUT.PUT(LPAD(fun.funkcja,10));    
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(LPAD('SUMA', 7));

    DBMS_OUTPUT.PUT('----------------- ------- ----');
    
    FOR fun IN functions LOOP
        DBMS_OUTPUT.PUT(' ---------');    
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(' ------');

    FOR band IN (
        SELECT DISTINCT
            k.NR_BANDY as bandNr, 
            b.NAZWA as bandName
        FROM KOCURY k
        INNER JOIN BANDY b ON k.nr_bandy = b.nr_bandy
        ORDER BY bandName ASC 
    ) LOOP
        FOR gender IN (
            SELECT DISTINCT PLEC
            FROM KOCURY
            ORDER BY PLEC ASC
        ) LOOP
            IF gender.plec = 'D' THEN
                DBMS_OUTPUT.put(RPAD(band.bandName, 18));
                DBMS_OUTPUT.put(RPAD('Kotka', 7));    
            ELSE
                DBMS_OUTPUT.put(RPAD(' ', 18));
                DBMS_OUTPUT.put(RPAD('Kocor', 7));
            END IF;

            SELECT COUNT(*) 
            INTO tmp
            FROM KOCURY
            WHERE NR_BANDY = band.bandNr AND PLEC = gender.PLEC;

            DBMS_OUTPUT.put(LPAD(tmp, 5));

            FOR fun IN functions LOOP
                
                SELECT SUM(PRZYDZIAL_MYSZY + NVL(MYSZY_EXTRA, 0)) 
                INTO tmp
                FROM KOCURY
                WHERE 
                    NR_BANDY = band.bandNr AND 
                    PLEC = gender.PLEC AND
                    FUNKCJA = fun.funkcja;
                
                DBMS_OUTPUT.put(LPAD( NVL(tmp,0), 10));
            END LOOP;

            SELECT SUM(PRZYDZIAL_MYSZY + NVL(MYSZY_EXTRA, 0)) 
            INTO tmp
            FROM KOCURY
            WHERE 
                NR_BANDY = band.bandNr AND 
                PLEC = gender.PLEC;

            DBMS_OUTPUT.PUT_LINE(LPAD(NVL(tmp,0), 7));

        END LOOP;
    END LOOP;

    DBMS_OUTPUT.PUT('Z---------------- ------- ----');
    
    FOR fun IN functions LOOP
        DBMS_OUTPUT.PUT(' ---------');    
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(' ------');

    DBMS_OUTPUT.PUT(RPAD('ZJADA RAZEM', 18) || RPAD(' ', 12));

    FOR fun IN functions LOOP
        SELECT SUM(PRZYDZIAL_MYSZY + NVL(MYSZY_EXTRA, 0))
        INTO tmp
        FROM KOCURY
        WHERE FUNKCJA = fun.funkcja;

        DBMS_OUTPUT.put(LPAD( NVL(tmp,0), 10));
    END LOOP;

    SELECT SUM(PRZYDZIAL_MYSZY + NVL(MYSZY_EXTRA, 0)) 
    INTO tmp
    FROM KOCURY;

    DBMS_OUTPUT.PUT_LINE(LPAD(NVL(tmp,0), 7));

END;

     