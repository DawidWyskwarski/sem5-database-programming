-- Ex 1
DECLARE 
    lvl NUMBER := &input_lvl;
    max_lvl NUMBER := 0;

    select_bosses VARCHAR2(4000) := '';
    pivot_bosses VARCHAR2(4000) := '';

    sql_querry VARCHAR2(4000) := '';

    v_cursor INTEGER;
    v_status INTEGER;
    col_val VARCHAR2(100);
BEGIN
    SELECT MAX(level) - 1
    INTO max_lvl
    FROM KOCURY
    START WITH FUNKCJA IN ('MILUSIA', 'KOT')
    CONNECT BY PRIOR SZEF = PSEUDO;

    lvl := LEAST(max_lvl, lvl);

    FOR i IN 1..lvl LOOP
        IF i > 1 THEN
            select_bosses := select_bosses || ', ';
            pivot_bosses := pivot_bosses || ', ';
        END IF;
        select_bosses := select_bosses || 'NVL("Szef ' || i || '", '' '') AS "SZEF ' || i || '"';
        pivot_bosses := pivot_bosses || '''Szef ' || i || ''' AS "Szef ' || i || '"';
    END LOOP;

    sql_querry := 'SELECT Imie, ' || select_bosses || ' FROM ( ' ||
        'SELECT CONNECT_BY_ROOT IMIE AS Imie, IMIE AS S, ''Szef '' || (LEVEL-1) AS HIERARCHIA ' ||
        'FROM KOCURY ' ||
        'WHERE LEVEL BETWEEN 2 AND ' || (lvl+1) || ' ' ||
        'START WITH FUNKCJA IN (''KOT'', ''MILUSIA'') ' ||
        'CONNECT BY PRIOR SZEF = PSEUDO ' ||
        ') SRC ' ||
        'PIVOT (MAX(S) FOR HIERARCHIA IN (' || pivot_bosses || '))';

    DBMS_OUTPUT.PUT(RPAD('Imie', 15));
    FOR i IN 1..lvl LOOP
        DBMS_OUTPUT.PUT('| ' || RPAD('Szef ' || i, 13));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT(RPAD('--------------', 15));
    FOR i IN 1..lvl LOOP
        DBMS_OUTPUT.PUT('+' || RPAD('--------------', 14));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');

    v_cursor := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(v_cursor, sql_querry, DBMS_SQL.NATIVE);
    
    FOR i IN 1..(lvl + 1) LOOP
        DBMS_SQL.DEFINE_COLUMN(v_cursor, i, col_val, 100);
    END LOOP;

    v_status := DBMS_SQL.EXECUTE(v_cursor);

    WHILE DBMS_SQL.FETCH_ROWS(v_cursor) > 0 LOOP
        FOR i IN 1..(lvl + 1) LOOP
            DBMS_SQL.COLUMN_VALUE(v_cursor, i, col_val);
            IF i = 1 THEN
                DBMS_OUTPUT.PUT(RPAD(NVL(col_val, ' '), 15));
            ELSE
                DBMS_OUTPUT.PUT('| ' || RPAD(NVL(col_val, ' '), 13));
            END IF;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;

    DBMS_SQL.CLOSE_CURSOR(v_cursor);

EXCEPTION
    WHEN OTHERS THEN
        IF DBMS_SQL.IS_OPEN(v_cursor) THEN
            DBMS_SQL.CLOSE_CURSOR(v_cursor);
        END IF;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END;

-- Ex 3
DECLARE
    v_max NUMBER;
BEGIN
    SELECT NVL(MAX(NR_BANDY), 0) + 1 INTO v_max FROM BANDY;
    
    BEGIN
        EXECUTE IMMEDIATE 'DROP SEQUENCE bandy_seq';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    
    EXECUTE IMMEDIATE 'CREATE SEQUENCE bandy_seq START WITH ' || v_max;
END;


CREATE OR REPLACE TRIGGER track_id_seq
BEFORE INSERT ON BANDY
FOR EACH ROW
BEGIN
    :NEW.NR_BANDY := bandy_seq.NEXTVAL;
END;

DROP TRIGGER track_id_seq;

-- Ex 4
CREATE TABLE mouse_deviations (
    USERNAME VARCHAR2(15),
    ACTION_DATE DATE,
    CAT_PSEUDO VARCHAR2(15),
    OPERATION_TYPE VARCHAR2(10)
);

CREATE OR REPLACE TRIGGER check_mouse_limits
BEFORE INSERT OR UPDATE ON KOCURY
FOR EACH ROW
DECLARE
    fun_min FUNKCJE.MIN_MYSZY%TYPE;
    fun_max FUNKCJE.MAX_MYSZY%TYPE;

    usr mouse_deviations.USERNAME%TYPE;

    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    SELECT MIN_MYSZY, MAX_MYSZY
    INTO fun_min, fun_max
    FROM FUNKCJE
    WHERE FUNKCJA = :NEW.FUNKCJA;

    IF :NEW.PRZYDZIAL_MYSZY NOT BETWEEN fun_min AND fun_max THEN
        usr := LOGIN_USER;
        
        IF INSERTING THEN
            INSERT INTO mouse_deviations 
                VALUES(usr, SYSDATE, :NEW.PSEUDO, 'INSERT');
            COMMIT;
        ELSIF UPDATING THEN
            INSERT INTO mouse_deviations 
                VALUES(usr, SYSDATE, :OLD.PSEUDO, 'UPDATE');
            COMMIT;
        END IF;

        RAISE_APPLICATION_ERROR(
            -20001,
            'NEW RATION FOR THIS FUNCTION IS OUTSIDE THE RANGE MIN: ' || fun_min ||
            ' MAX: ' || fun_max
        );
    END IF;    
END;  

DROP TRIGGER check_mouse_limits;

-- Ex 5 a
CREATE OR REPLACE PACKAGE milusie_package AS
    tygrys_ration KOCURY.PRZYDZIAL_MYSZY%TYPE;
    tygrys_extra KOCURY.MYSZY_EXTRA%TYPE;
    is_updating BOOLEAN := FALSE;
END milusie_package; 

CREATE OR REPLACE TRIGGER fetch_trygrys_ration
BEFORE UPDATE OF PRZYDZIAL_MYSZY ON KOCURY
BEGIN
    IF milusie_package.is_updating THEN RETURN; END IF;
    
    SELECT PRZYDZIAL_MYSZY, MYSZY_EXTRA
    INTO milusie_package.tygrys_ration, milusie_package.tygrys_extra
    FROM KOCURY
    WHERE PSEUDO = 'TYGRYS';

    DBMS_OUTPUT.PUT_LINE('INITIAL TYGRYS RATIONS: ' || MILUSIE_PACKAGE.tygrys_ration);
    DBMS_OUTPUT.PUT_LINE('INITIAL TYGRYS EXTRA: ' || MILUSIE_PACKAGE.tygrys_extra);
END;

CREATE OR REPLACE TRIGGER check_for_bad_decisions
BEFORE UPDATE OF PRZYDZIAL_MYSZY ON KOCURY
FOR EACH ROW
WHEN (NEW.FUNKCJA = 'MILUSIA')
DECLARE
    deci_tygrys_ration KOCURY.PRZYDZIAL_MYSZY%TYPE := milusie_package.tygrys_ration * 0.1;
BEGIN
    IF milusie_package.is_updating THEN RETURN; END IF;
    
    IF :OLD.PRZYDZIAL_MYSZY > :NEW.PRZYDZIAL_MYSZY THEN
        RAISE_APPLICATION_ERROR(-20002, 'Ration cannot be decreased for MILUSIA');
    END IF;

    IF :NEW.PRZYDZIAL_MYSZY - :OLD.PRZYDZIAL_MYSZY < deci_tygrys_ration THEN

        DBMS_OUTPUT.PUT_LINE('MILUSIE DOES NOT LIKE THAT');
        DBMS_OUTPUT.PUT_LINE('CHANGED RATION: ' || :NEW.PRZYDZIAL_MYSZY);
        DBMS_OUTPUT.PUT_LINE('DECI TYGRYS RATION: ' || deci_tygrys_ration);
        
        :NEW.PRZYDZIAL_MYSZY := :NEW.PRZYDZIAL_MYSZY + deci_tygrys_ration;
        :NEW.MYSZY_EXTRA := :NEW.MYSZY_EXTRA + 5;

        MILUSIE_PACKAGE.tygrys_ration := MILUSIE_PACKAGE.tygrys_ration - deci_tygrys_ration;
    ELSE
        DBMS_OUTPUT.PUT_LINE('PRIZE AWAITS');
        MILUSIE_PACKAGE.tygrys_extra := MILUSIE_PACKAGE.tygrys_extra + 5;
    END IF;

    DBMS_OUTPUT.PUT_LINE('NEW TYGRYS RATION: ' || MILUSIE_PACKAGE.tygrys_ration);
    DBMS_OUTPUT.PUT_LINE('NEW TYGRYS EXTRA: ' || MILUSIE_PACKAGE.tygrys_extra);
    DBMS_OUTPUT.PUT_LINE('');
END;


CREATE OR REPLACE TRIGGER take_care_of_tygrys
AFTER UPDATE OF PRZYDZIAL_MYSZY ON KOCURY
DECLARE
    tmp_ration MILUSIE_PACKAGE.tygrys_ration%TYPE := MILUSIE_PACKAGE.tygrys_ration;
    tmp_extra MILUSIE_PACKAGE.tygrys_extra%TYPE := MILUSIE_PACKAGE.tygrys_extra;
BEGIN

    IF milusie_package.is_updating THEN RETURN; END IF;

    IF tmp_ration <> 0 OR tmp_extra <> 0 THEN
        milusie_package.is_updating := TRUE;

        UPDATE KOCURY SET 
            PRZYDZIAL_MYSZY = tmp_ration,
            MYSZY_EXTRA = tmp_extra
        WHERE PSEUDO = 'TYGRYS';  

        milusie_package.is_updating := FALSE;
    END IF;

    MILUSIE_PACKAGE.tygrys_ration := 0;
    MILUSIE_PACKAGE.tygrys_extra := 0;
END;

DROP TRIGGER fetch_trygrys_ration;
DROP TRIGGER check_for_bad_decisions;
DROP TRIGGER take_care_of_tygrys;

-- Ex 5 b
CREATE OR REPLACE TRIGGER mischievous_plan
FOR UPDATE OF PRZYDZIAL_MYSZY ON KOCURY
COMPOUND TRIGGER
    tygrys_ration      KOCURY.PRZYDZIAL_MYSZY%TYPE;
    tygrys_extra       KOCURY.MYSZY_EXTRA%TYPE;
    deci_tygrys_ration KOCURY.PRZYDZIAL_MYSZY%TYPE;
    is_updating BOOLEAN := FALSE;

    BEFORE STATEMENT IS
    BEGIN
        BEGIN
            SELECT PRZYDZIAL_MYSZY, MYSZY_EXTRA
            INTO tygrys_ration, tygrys_extra
            FROM KOCURY
            WHERE PSEUDO = 'TYGRYS';
        END;
    END BEFORE STATEMENT;

    BEFORE EACH ROW IS
    BEGIN
        IF :NEW.FUNKCJA = 'MILUSIA' THEN
            is_updating := TRUE;
            deci_tygrys_ration := tygrys_ration * 0.1;

            IF :OLD.PRZYDZIAL_MYSZY > :NEW.PRZYDZIAL_MYSZY THEN
                RAISE_APPLICATION_ERROR(-20002, 'Ration cannot be decreased for MILUSIA');
            END IF;

            IF :NEW.PRZYDZIAL_MYSZY - :OLD.PRZYDZIAL_MYSZY < deci_tygrys_ration THEN
                :NEW.PRZYDZIAL_MYSZY := :NEW.PRZYDZIAL_MYSZY + deci_tygrys_ration;
                :NEW.MYSZY_EXTRA := NVL(:NEW.MYSZY_EXTRA, 0) + 5;
                tygrys_ration := tygrys_ration - deci_tygrys_ration;
            ELSE    
                tygrys_extra := tygrys_extra + 5;
            END IF;
        END IF;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        IF is_updating THEN
            UPDATE KOCURY SET
                PRZYDZIAL_MYSZY = tygrys_ration,
                MYSZY_EXTRA = tygrys_extra
            WHERE PSEUDO = 'TYGRYS';
        END IF;
    END AFTER STATEMENT;        
END;

DROP TRIGGER mischievous_plan;

-- Ex 6
CREATE TABLE Dodatki_extra (
    pseudo VARCHAR2(15),
    dodatek_extra NUMBER(3)
);

CREATE OR REPLACE TRIGGER punishment
BEFORE UPDATE OF PRZYDZIAL_MYSZY ON KOCURY
FOR EACH ROW
WHEN (NEW.FUNKCJA = 'MILUSIA')
DECLARE
    USR VARCHAR2(15) := LOGIN_USER;
BEGIN
    IF (:NEW.PRZYDZIAL_MYSZY - :OLD.PRZYDZIAL_MYSZY > 0) AND USR <> 'TYGRYS' THEN
        :NEW.PRZYDZIAL_MYSZY := :OLD.PRZYDZIAL_MYSZY;
        EXECUTE IMMEDIATE 'INSERT INTO DODATKI_EXTRA VALUES(''' || :NEW.PSEUDO || ''', ' || -10 || ')';
    END IF;
END;

SELECT * FROM KOCURY;

UPDATE KOCURY 
SET PRZYDZIAL_MYSZY = 23
WHERE PSEUDO = 'MALA';

SELECT * FROM DODATKI_EXTRA;

ROLLBACK;