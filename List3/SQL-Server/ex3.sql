DECLARE @input_pseudo NVARCHAR(50) = 'TYGRYS';

IF NOT EXISTS (
    SELECT 1 
    FROM Kocury 
    WHERE pseudo = @input_pseudo
)
    BEGIN
        PRINT 'BŁĄD: Nie znaleziono kota o pseudonimie: ' + @input_pseudo;
    END
ELSE
BEGIN

    SELECT
        K.pseudo [Pseudonim],
        K.imie [Imie],
        b.nazwa [Nazwa bandy], 
        CASE WHEN EXISTS ( SELECT 1 FROM Wrogowie_kocurow WHERE pseudo = @input_pseudo ) 
            THEN 'TAK'
            ELSE 'NIE'
        END [Czy ma wrogow],
        CASE WHEN 
            12*(przydzial_myszy + ISNULL(myszy_extra,0)) > ( 
                SELECT AVG(12*(przydzial_myszy + ISNULL(myszy_extra,0))) 
                FROM KOCURY kin
                WHERE kin.nr_bandy = k.nr_bandy) THEN 'TAK'
            ELSE 'NIE'
        END [Czy roczny przydzial wiekszy niz srednia],
        DAY(w_stadku_od) [Dzien Wstapienia],
        DATENAME(month, w_stadku_od) [Miesac Wstapienia],
        YEAR(w_stadku_od) [Rok Wstapienia]
    FROM Kocury K
    INNER JOIN BANDY B ON K.nr_bandy = B.nr_bandy
    WHERE K.pseudo = @input_pseudo;
END;

-- DECLARE @input_pseudo NVARCHAR(50) = 'TYGRYS';

-- DECLARE @imie NVARCHAR(20),
--         @nazwaBandy NVARCHAR(50),
--         @czyMaWrogow NVARCHAR(3),
--         @czyWiecejNizSrednia NVARCHAR(3),
--         @dzien INT,
--         @miesiac NVARCHAR(15),
--         @rok INT

-- IF NOT EXISTS (
--     SELECT 1 
--     FROM Kocury 
--     WHERE pseudo = @input_pseudo
-- )
--     BEGIN
--         PRINT 'BŁĄD: Nie znaleziono kota o pseudonimie: ' + @input_pseudo;
--     END
-- ELSE
-- BEGIN

--     SELECT
--         @imie = K.imie,
--         @nazwaBandy = b.nazwa,
--         @czyMaWrogow = 
--             CASE WHEN EXISTS ( SELECT COUNT(*) FROM Wrogowie_kocurow WHERE pseudo = @input_pseudo ) 
--                 THEN 'TAK'
--                 ELSE 'NIE'
--             END,
--         @czyWiecejNizSrednia = 
--             CASE WHEN 
--                 12*(przydzial_myszy + ISNULL(myszy_extra,0)) > ( 
--                     SELECT AVG(12*(przydzial_myszy + ISNULL(myszy_extra,0))) 
--                     FROM KOCURY kin
-- 					WHERE kin.nr_bandy = k.nr_bandy) THEN 'TAK'
--                 ELSE 'NIE'
--             END,
--         @dzien = DAY(w_stadku_od),
--         @miesiac = DATENAME(month, w_stadku_od),
--         @rok = YEAR(w_stadku_od)
--     FROM Kocury K
--     INNER JOIN BANDY B ON K.nr_bandy = B.nr_bandy
--     WHERE K.pseudo = @input_pseudo;

--     PRINT 'INFORMACJE O KOCIE:';
--     PRINT '~~~~~~~~~~~~~~~~~~~';
--     PRINT 'Pseudonim:         ' + @input_pseudo;
--     PRINT 'Imie:              ' + @imie;
--     PRINT 'Nazwa bandy:       ' + @nazwaBandy;
--     PRINT 'Czy ma wrogow:     ' + @czyMaWrogow;
--     PRINT 'Czy roczny przydzial wiekszy niz srednia: ' + @czyWiecejNizSrednia
--     PRINT 'Dzien Wstapienia:  ' + CAST(@dzien as NVARCHAR)
--     PRINT 'Miesac Wstapienia: ' + @miesiac
--     PRINT 'Rok Wstapienia:    ' + CAST(@rok as NVARCHAR)
-- END;

