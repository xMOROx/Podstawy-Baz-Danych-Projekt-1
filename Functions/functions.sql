CREATE FUNCTION GetAvgPriceOfMenu(@MenuID int) RETURNS money AS BEGIN RETURN (
    SELECT
        AVG(Price)
    FROM
        Menu
    WHERE
        MenuID = @MenuID
)
END
GO
    CREATE FUNCTION MenuIsCorrect(@MenuID int) RETURNS bit AS BEGIN DECLARE @SameItems int
SET
    @SameItems = (
        SELECT
            COUNT(*)
        FROM
            (
                SELECT
                    ProductID
                FROM
                    Menu
                WHERE
                    MenuID = (@MenuID - 1)
                INTERSECT
                SELECT
                    ProductID
                FROM
                    Menu
                WHERE
                    MenuID = @MenuID
            ) OUT
    ) DECLARE @minAmountToChange int
SET
    @minAmountToChange = (
        SELECT
            COUNT(*)
        FROM
            Menu
        WHERE
            MenuID = (@MenuID - 1)
    ) / 2 IF @SameItems <= @minAmountToChange BEGIN RETURN 1
END RETURN 0
END
GO
    CREATE FUNCTION GetMinimumPriceOfMenu(@MenuID int) RETURNS money AS BEGIN RETURN (
        SELECT
            TOP 1 MIN(Price)
        FROM
            Menu
        WHERE
            MenuID = @MenuID
    )
END
GO
    CREATE FUNCTION GetMaximumPriceOfMenu(@MenuID int) RETURNS money AS BEGIN RETURN (
        SELECT
            TOP 1 MAX(Price)
        FROM
            Menu
        WHERE
            MenuID = @MenuID
    )
END
GO
    CREATE FUNCTION show_taken_tables_from_x_to_y_with_z_chairs(
        @StartDate datetime,
        @EndDate datetime,
        @Chairs int
    ) RETURNS TABLE AS RETURN
SELECT
    T.TableID,
    T.ChairAmount,
    O.ClientID,
    O.OrderID,
    R2.startDate,
    R2.endDate
FROM
    TABLES T
    INNER JOIN ReservationDetails RD ON T.TableID = RD.TableID
    INNER JOIN ReservationCompany RC ON RC.ReservationID = RD.ReservationID
    INNER JOIN Reservation R2 ON RC.ReservationID = R2.ReservationID
    INNER JOIN Orders O ON R2.ReservationID = O.ReservationID
WHERE
    R2.startDate >= @StartDate
    AND R2.endDate <= @EndDate
    AND T.ChairAmount = @Chairs
UNION
SELECT
    T.TableID,
    T.ChairAmount,
    O.ClientID,
    O.OrderID,
    R2.startDate,
    R2.endDate
FROM
    TABLES T
    INNER JOIN ReservationDetails RD ON T.TableID = RD.TableID
    INNER JOIN ReservationIndividual RC ON RC.ReservationID = RD.ReservationID
    INNER JOIN Reservation R2 ON RC.ReservationID = R2.ReservationID
    INNER JOIN Orders O ON R2.ReservationID = O.ReservationID
WHERE
    R2.startDate >= @StartDate
    AND R2.endDate <= @EndDate
    AND T.ChairAmount = @Chairs
GO
    CREATE FUNCTION show_free_tables_from_x_to_y_with_z_chairs(
        @StartDate datetime,
        @EndDate datetime,
        @Chairs int
    ) RETURNS TABLE AS RETURN
SELECT
    T.TableID,
    T.ChairAmount
FROM
    TABLES T
WHERE
    T.TableID NOT IN (
        SELECT
            Q.TableID
        FROM
            show_taken_tables_from_x_to_y_with_z_chairs(@StartDate, @EndDate, @Chairs) Q
    )
    AND T.isActive = 1
    AND ChairAmount = @Chairs
GO
    CREATE FUNCTION GetBestMeal(@input int) RETURNS TABLE AS RETURN
SELECT
    DISTINCT TOP (@input) P.Name,
    MMI.times_sold
FROM
    Products P
    INNER JOIN mealMenuInfo MMI ON P.ProductID = MMI.ProductID
ORDER BY
    MMI.times_sold
GO
    CREATE FUNCTION GetClientsOrderedMoreThanXTimes(@amount int) RETURNS TABLE AS RETURN
SELECT
    *
FROM
    ClientStatistics
WHERE
    [times ordered] > @amount
GO
    CREATE FUNCTION GetClientsOrderedMoreThanXValue(@value float) RETURNS TABLE AS RETURN
SELECT
    *
FROM
    ClientStatistics
WHERE
    [value ordered] > @value
GO
    CREATE FUNCTION GetClientsWhoOweMoreThanX(@value int) RETURNS TABLE AS RETURN
SELECT
    ClientID,
    [money to pay]
FROM
    individualClientsWhoNotPayForOrders
WHERE
    [money to pay] > @value
UNION
SELECT
    ClientID,
    [money to pay]
FROM
    companiesWhoNotPayForOrders
WHERE
    [money to pay] > @value
GO