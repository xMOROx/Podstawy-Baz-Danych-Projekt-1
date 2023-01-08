-- Sea food trigger 
-- Trigger ten blokuje zamówienia, które ze względu na znajdujące się w nim owoce
-- morza, winno być złożone maksymalnie do poniedziałku poprzedzającego
-- zamówienie.
CREATE FUNCTION SeaFoodInTime (@PrefDate datetime, @TakeawayTime datetime,@ReservationTime datetime,@DayName nvarchar,@Days int ) RETURNS bit AS
BEGIN
    DECLARE @Y datetime = @TakeawayTime
    if @TakeawayTime is null
        BEGIN;
           SET @Y = @ReservationTime
        END
    RETURN IIF(DATENAME(WEEKDAY, @PrefDate) LIKE @DayName AND DATEDIFF(DAY, @PrefDate, @Y) <= @Days, 1, 0)
END

CREATE TRIGGER SeaFoodCheckMonday
    ON OrderDetails
AFTER INSERT
AS BEGIN
   SET NOCOUNT ON
    DECLARE @CategoryID int
    SELECT @CategoryID = CategoryID from Category where CategoryName like 'sea food'
    IF EXISTS(

        SELECT * FROM inserted AS I
        INNER JOIN Orders AS O ON O.OrderID = I.OrderID
        INNER JOIN dbo.OrderDetails OD on O.OrderID = OD.OrderID
        INNER JOIN Products P on OD.ProductID = P.ProductID
        INNER JOIN OrdersTakeaways OT on O.TakeawayID = OT.TakeawaysID
        INNER JOIN Reservation R2 on O.ReservationID = R2.ReservationID

        WHERE CategoryID = @CategoryID AND
              dbo.SeaFoodInTime(O.OrderDate,OT.PrefDate,  R2.startDate, 2, 'Thursday') = 1
           OR dbo.SeaFoodInTime(O.OrderDate,OT.PrefDate,  R2.startDate, 3, 'Friday') = 1
           OR dbo.SeaFoodInTime(O.OrderDate,OT.PrefDate,  R2.startDate, 4, 'Saturday') = 1
        )

        BEGIN;
            THROW 50001, N'Takie zamówienie winno być złożone maksylamnie do poniedziałku poprzedzającego zamówienie.', 1
        END
    END
GO

-- Trigger usuwa szczegóły zamówienia z tabeli OrderDetails, jeżeli powiązana z nim
-- rezerwacja została anulowana przez klienta

CREATE TRIGGER DeleteOrderDetails
ON OrderDetails
FOR DELETE
AS
BEGIN
   SET NOCOUNT ON
    DELETE FROM OrderDetails WHERE OrderID in (
        SELECT O.OrderID from Orders O
        INNER JOIN Reservation R2 on R2.ReservationID = O.ReservationID
        WHERE R2.Status = 'cancelled'
    )
END
-- Trigger sprawdza czy danie które probujemy dodac do menu jest w bazie w czasie odbioru zamowienia zaznaczone jako dostepne i jest w menu wtedy
CREATE TRIGGER orderDetailsInsert
ON OrderDetails
FOR INSERT
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @ProductID int
    DECLARE @OrderID int
    DECLARE @MenuID int
    SELECT @MenuID = MAX(MenuID) from Menu

    SELECT @ProductID = ProductID from inserted
    SELECT @OrderID = OrderID from inserted
    IF EXISTS(SELECT * FROM Products P WHERE P.ProductID = @ProductID AND P.IsAvailable = 0)
        BEGIN;
            THROW 50001, 'Niepoprawne ProductID, Jego IsAvailable to 0 w tabeli Products. ', 1
            ROLLBACK TRANSACTION
        END
    IF NOT EXISTS(SELECT * FROM Menu M WHERE M.MenuID = @MenuID AND M.ProductID = @ProductID)
        BEGIN
            THROW 50001, 'Ten produkt nieznajduje się aktualnie w menu.', 1
            ROLLBACK TRANSACTION
        END
END
GO

-- Sprawdzanie czy pracodawca dodanego pracownika jest firmą

CREATE TRIGGER EmployeeInsert
ON Employees
FOR INSERT
AS
    BEGIN
        DECLARE @ClientID int
        SELECT @ClientID = CompanyID from inserted
        IF NOT EXISTS(SELECT * FROM Companies C where C.ClientID = @ClientID)
            BEGIN;
                THROW 50001, N'Klient o podanym ID nie jest firmą. Nie można dodać pracownika!', 1
                ROLLBACK TRANSACTION
            END
    END
GO

-- Trigger sprawdza czy stolik można dodać do rezerwacji (czy jest wtedy wolny i aktywny)

CREATE TRIGGER addTableToReservationInsertCheck
ON ReservationDetails
FOR INSERT
AS
    BEGIN
        DECLARE @ReservationID int = (SELECT ReservationID FROM inserted)
        DECLARE @TableID int = (SELECT TableID FROM inserted)

        DECLARE @StartReservationDate datetime
        DECLARE @EndReservationDate datetime

        SELECT @StartReservationDate = StartDate, @EndReservationDate = EndDate FROM Reservation R WHERE R.ReservationID = @ReservationID

        DECLARE @TableInUseCountCompany int
        DECLARE @TableInUseCountIndividuals int

        SELECT @TableInUseCountCompany = COUNT(TableID) from Reservation R
            INNER JOIN ReservationCompany RC on R.ReservationID = RC.ReservationID
            INNER JOIN ReservationDetails RD on RC.ReservationID = RD.ReservationID
        WHERE (R.startDate >= @StartReservationDate AND R.endDate <= @EndReservationDate)

        SELECT @TableInUseCountIndividuals = COUNT(TableID) from Reservation R
            INNER JOIN ReservationIndividual RI on R.ReservationID = RI.ReservationID
            INNER JOIN ReservationDetails RD on RI.ReservationID = RD.ReservationID
        WHERE (R.startDate >= @StartReservationDate AND R.endDate <= @EndReservationDate)

        IF @TableInUseCountIndividuals > 0 OR @TableInUseCountCompany > 0
        BEGIN;
            THROW 50200, N'Dany stolik jest używany przez inną rezerwację! ', 1
            ROLLBACK TRANSACTION;
        END

        IF EXISTS(SELECT * FROM Tables T WHERE T.TableID = @TableID AND T.isActive = 0)
            BEGIN;
                THROW 50200, N'Stolik nie jest w użyciu (isActive jest 0)', 1
                ROLLBACK TRANSACTION;
            END
    END
GO

CREATE TRIGGER TablesOnDelete
ON ReservationDetails
FOR DELETE, UPDATE
AS
    BEGIN
        SET NOCOUNT ON
        DECLARE @TableInUseCountCompany int
        DECLARE @TableInUseCountIndividuals int

        SELECT @TableInUseCountCompany = COUNT(*) FROM deleted D
            INNER JOIN ReservationCompany RC ON RC.ReservationID = D.ReservationID
            INNER JOIN Reservation R2 on RC.ReservationID = R2.ReservationID
        WHERE R2.startDate >= GETDATE()

        SELECT @TableInUseCountIndividuals = COUNT(*) FROM deleted D
            INNER JOIN ReservationIndividual RC ON RC.ReservationID = D.ReservationID
            INNER JOIN Reservation R2 on RC.ReservationID = R2.ReservationID
        WHERE R2.startDate >= GETDATE()

        IF @TableInUseCountCompany > 0 OR @TableInUseCountIndividuals > 0
        BEGIN;
            THROW 52000, N'Stolik nie może zostać usunięty lub zmieniony jego status aktywności jeśli jest zarezerwowany', 1
            ROLLBACK;
        END
    END
GO

-- Trigger sprawdza czy dodana nowa zmienna zniżki Z1 (ilość minimalna zamówień by
-- otrzymać zniżkę) jest prawidłowa (większa od 0)
CREATE TRIGGER Z1TestForNewDiscountVariable
    ON DiscountsVar
    FOR INSERT ,UPDATE
    AS
    BEGIN
        SET NOCOUNT ON
        IF EXISTS(
            SELECT * FROM inserted AS I
            WHERE I.MinimalOrders<=0
            )
        BEGIN
            THROW 52000, N'Nowa zniżka powinna miec dodatni parametr MinimalOrders', 1
        END
    END
GO