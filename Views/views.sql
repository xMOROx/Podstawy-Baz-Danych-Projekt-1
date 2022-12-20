-- Current menu view --

CREATE VIEW dbo.CurrentMenu AS
    SELECT MenuID, Price, Name, Description FROM Menu INNER JOIN Products P ON P.ProductID = Menu.ProductID
    WHERE ((GETDATE() >= startDate) AND (GETDATE() <= endDate)) OR ((GETDATE() >= startDate) AND endDate IS NULL) ;
GO
-- Current menu view --


-- Current Reservation vars --

CREATE VIEW dbo.CurrentReservationVars AS
    SELECT WZ AS [Minimalna liczba zamowien], WK AS [Minimalna kwota dla zamowienia], startDate, ISNULL(CONVERT(VARCHAR(20), endDate, 120), 'Obowiązuje zawsze') AS 'Koniec menu'
    FROM ReservationVar
    WHERE ((GETDATE() >= startDate) AND (GETDATE() <= endDate)) OR ((GETDATE() >= startDate) AND endDate IS NULL);
GO
-- Current Reservation vars --

-- unpaid invoices  Individuals--

CREATE VIEW dbo.unPaidInvoicesIndividuals AS
    SELECT  InvoiceNumber AS [Numer faktury], InvoiceDate AS [Data wystawienia],
            DueDate AS [Data terminu zaplaty], CONCAT(LastName, ' ',FirstName) AS [Dane],
            Phone, Email, CONCAT(CityName, ' ',street,' ', LocalNr) AS [Adres], PostalCode
    FROM Invoice
        INNER JOIN Clients C ON C.ClientID = Invoice.ClientID
        INNER JOIN Address A ON C.AddressID = A.AddressID
        INNER JOIN IndividualClient IC ON C.ClientID = IC.ClientID
        INNER JOIN PersON P ON P.PersONID = IC.PersONID
        INNER JOIN Cities C2 ON C2.CityID = A.CityID
        INNER JOIN PaymentStatus PS ON Invoice.PaymentStatusID = PS.PaymentStatusID
    WHERE PaymentStatusName LIKE 'Unpaid'; -- system will change status
GO
-- unpaid invoices  Individuals--

-- unpaid invoices  Company--

CREATE VIEW dbo.unPaidInvoicesCompanies AS
    SELECT  InvoiceNumber AS [Numer faktury], InvoiceDate AS [Data wystawienia],
            DueDate AS [Data terminu zaplaty], CompanyName, NIP, ISNULL(KRS, 'Brak') AS [KRS], ISNULL(Regon, 'Brak') AS [Regon],
            Phone, Email, CONCAT(CityName, ' ',street,' ', LocalNr) AS [Adres], PostalCode
    FROM Invoice
        INNER JOIN Clients C ON C.ClientID = Invoice.ClientID
        INNER JOIN Companies CO ON CO.ClientID = C.ClientID
        INNER JOIN Address A ON C.AddressID = A.AddressID
        INNER JOIN Cities C2 ON C2.CityID = A.CityID
        INNER JOIN PaymentStatus PS ON Invoice.PaymentStatusID = PS.PaymentStatusID
    WHERE (PaymentStatusName LIKE 'Unpaid');
GO
-- unpaid invoices  Company--

-- withdrawn products --

CREATE VIEW dbo.withdrawnProducts AS
    SELECT Name, P.Description, C.CategoryName FROM Products P
        INNER JOIN Category C ON C.CategoryID = P.CategoryID WHERE P.IsAvailable = 0
GO
-- withdrawn products --

-- active products --

CREATE VIEW dbo.ActiveProducts AS
    SELECT Name, P.Description, C.CategoryName FROM Products P
        INNER JOIN Category C ON C.CategoryID = P.CategoryID WHERE P.IsAvailable = 1
GO
-- active products --

-- Active Tables --
-- dostępne dla klientów --

CREATE VIEW dbo.ActiveTables AS
    SELECT TableID, ChairAmount FROM Tables
        WHERE IsActive = 1
GO
-- Active Tables --

-- Not reserved Tables --

CREATE VIEW dbo.[Not reserved Tables] AS
    SELECT TableID, ChairAmount
    FROM Tables
        WHERE TableID NOT IN(SELECT ReservationDetails.TableID
            FROM ReservationDetails
                INNER JOIN ReservationCompany RC ON RC.ReservationID = ReservationDetails.ReservationID
                INNER JOIN Reservation R2 ON RC.ReservationID = R2.ReservationID
            WHERE (GETDATE() >= startDate) AND (GETDATE() <= endDate) AND (Status NOT LIKE 'cancelled' AND Status NOT LIKE 'denied') AND IsActive = 1)
UNION
    SELECT TableID, ChairAmount
    FROM Tables
        WHERE TableID NOT IN(SELECT ReservationDetails.TableID
            FROM ReservationDetails
                INNER JOIN ReservationIndividual RC ON RC.ReservationID = ReservationDetails.ReservationID
                INNER JOIN Reservation R2 ON RC.ReservationID = R2.ReservationID
            WHERE (GETDATE() >= startDate) AND (GETDATE() <= endDate) AND (Status NOT LIKE 'cancelled' AND Status NOT LIKE 'denied') AND IsActive = 1)
GO
-- Not reserved Tables --

-- weekly report about tables --

CREATE VIEW dbo.TablesWeekly AS
    SELECT YEAR(R2.StartDate) AS year,
        DATEPART(ISo_week, R2.StartDate) AS week,
        T.TableID AS table_id,
        T.ChairAmount AS table_size,
        COUNT(RD.TableID) AS how_many_times_reserved
    FROM Tables T
        INNER JOIN ReservationDetails RD ON T.TableID = RD.TableID
        INNER JOIN ReservationIndividual RI ON RI.ReservationID = RD.ReservationID
        INNER JOIN Reservation R2 ON RD.ReservationID = R2.ReservationID
    WHERE (Status NOT LIKE 'cancelled' AND Status NOT LIKE 'denied')
    GROUP BY YEAR(R2.StartDate), DATEPART(ISo_week, R2.StartDate), T.TableID, T.ChairAmount
UNION
    SELECT YEAR(R2.StartDate) AS year,
        DATEPART(ISo_week , R2.StartDate) AS week,
        T.TableID AS table_id,
        T.ChairAmount AS table_size,
        COUNT(RD.TableID) AS how_many_times_reserved
    FROM Tables T
        INNER JOIN ReservationDetails RD ON T.TableID = RD.TableID
        INNER JOIN ReservationCompany RI ON RI.ReservationID = RD.ReservationID
        INNER JOIN Reservation R2 ON RD.ReservationID = R2.ReservationID
    WHERE (Status NOT LIKE 'cancelled' AND Status NOT LIKE 'denied')
    GROUP BY YEAR(R2.StartDate), DATEPART(ISo_week, R2.StartDate), T.TableID, T.ChairAmount
GO
-- weekly report about tables --

-- Monthly report about tables --

CREATE VIEW dbo.TablesMonthly AS
    SELECT YEAR(R2.StartDate) AS year,
        DATEPART(mONth , R2.StartDate) AS mONth,
        T.TableID AS table_id,
        T.ChairAmount AS table_size,
        COUNT(RD.TableID) AS how_many_times_reserved
    FROM Tables T
        INNER JOIN ReservationDetails RD ON T.TableID = RD.TableID
        INNER JOIN ReservationIndividual RI ON RI.ReservationID = RD.ReservationID
        INNER JOIN Reservation R2 ON RD.ReservationID = R2.ReservationID
    WHERE (Status NOT LIKE 'cancelled' AND Status NOT LIKE 'denied')
    GROUP BY YEAR(R2.StartDate), DATEPART(mONth, R2.StartDate), T.TableID, T.ChairAmount
UNION
    SELECT YEAR(R2.StartDate) AS year,
        DATEPART(mONth, R2.StartDate) AS mONth,
        T.TableID AS table_id,
        T.ChairAmount AS table_size,
        COUNT(RD.TableID) AS how_many_times_reserved
    FROM Tables T
        INNER JOIN ReservationDetails RD ON T.TableID = RD.TableID
        INNER JOIN ReservationCompany RI ON RI.ReservationID = RD.ReservationID
        INNER JOIN Reservation R2 ON RD.ReservationID = R2.ReservationID
    WHERE (Status NOT LIKE 'cancelled' AND Status NOT LIKE 'denied')
    GROUP BY YEAR(R2.StartDate), DATEPART(mONth, R2.StartDate), T.TableID, T.ChairAmount
GO

-- Monthly report about tables --

-- takeaway Orders not picked Individuals--

CREATE VIEW dbo.[takeaways Orders not picked Individuals] AS
    SELECT PrefDate AS [Data odbioru], CONCAT(LastName, ' ',FirstName) AS [Dane],
           Phone, Email, CONCAT(CityName, ' ',street,' ', LocalNr) AS [Adres], PostalCode,
            OrderID, OrderDate, OrderCompletionDate, OrderSum
        FROM OrdersTakeaways OT
            INNER JOIN Orders O ON OT.TakeawaysID = O.TakeawayID
            INNER JOIN Clients C ON O.ClientID = C.ClientID
            INNER JOIN IndividualClient IC ON C.ClientID = IC.ClientID
            INNER JOIN PersON P ON IC.PersONID = P.PersONID
            INNER JOIN Address A ON C.AddressID = A.AddressID
            INNER JOIN Cities C2 ON A.CityID = C2.CityID
        WHERE OrderStatus LIKE 'Completed' 
GO
-- takeaways Orders not picked Individuals--

-- takeaways Orders not picked Companies--

CREATE VIEW dbo.[takeaways Orders not picked Companies] AS
    SELECT PrefDate AS [Data odbioru], CompanyName, NIP, ISNULL(KRS, 'Brak') AS [KRS], ISNULL(ReonN, 'Brak') AS [ReonN],
           Phone, Email, CONCAT(CityName, ' ',street,' ', LocalNr) AS [Adres], PostalCode,
            OrderID, OrderDate, OrderCompletionDate, OrderSum
    FROM OrdersTakeaways OT
        INNER JOIN Orders O ON OT.TakeawaysID = O.TakeawayID
        INNER JOIN Clients C ON O.ClientID = C.ClientID
        INNER JOIN Companies CO ON C.ClientID = CO.ClientID
        INNER JOIN Address A ON C.AddressID = A.AddressID
        INNER JOIN Cities C2 ON A.CityID = C2.CityID
    WHERE OrderStatus LIKE 'Completed' 
GO
-- takeaways Orders not picked Companies--


-- takeaway Orders  Individuals--

CREATE VIEW dbo.[takeaways Orders Individuals] AS
    SELECT PrefDate AS [Data odbiORu], CONCAT(LastName, ' ',FirstName) AS [Dane],
           Phone, Email, CONCAT(CityName, ' ',street,' ', LocalNr) AS [Adres], PostalCode,
           OrderID, OrderDate, OrderCompletionDate, OrderStatus, OrderSum
    FROM OrdersTakeaways OT
        INNER JOIN Orders O ON OT.TakeawaysID = O.TakeawayID
        INNER JOIN Clients C ON O.ClientID = C.ClientID
        INNER JOIN IndividualClient IC ON C.ClientID = IC.ClientID
        INNER JOIN PersON P ON IC.PersONID = P.PersONID
        INNER JOIN Address A ON C.AddressID = A.AddressID
        INNER JOIN Cities C2 ON A.CityID = C2.CityID
    WHERE (((GETDATE() >= OrderDate) AND (GETDATE() <= OrderCompletionDate)) OR (OrderCompletionDate IS NULL AND (GETDATE() >= OrderDate)))
GO
-- takeaways Orders  Individuals--


-- takeaways Orders companies --

CREATE VIEW dbo.[takeaways Orders companies] AS
    SELECT PrefDate AS [Data odbiORu], CompanyName, NIP, ISNULL(KRS, 'Brak') AS [KRS], ISNULL(ReGON, 'Brak') AS [ReGON],
           Phone, Email, CONCAT(CityName, ' ',street,' ', LocalNr) AS [Adres], PostalCode,
            OrderID, OrderDate, OrderCompletionDate, OrderStatus, OrderSum
    FROM OrdersTakeaways OT
        INNER JOIN Orders O ON OT.TakeawaysID = O.TakeawayID
        INNER JOIN Clients C ON O.ClientID = C.ClientID
        INNER JOIN Companies CO ON C.ClientID = CO.ClientID
        INNER JOIN Address A ON C.AddressID = A.AddressID
        INNER JOIN Cities C2 ON A.CityID = C2.CityID
    WHERE (((GETDATE() >= OrderDate) AND (GETDATE() <= OrderCompletionDate)) OR (OrderCompletionDate IS NULL AND (GETDATE() >= OrderDate)))
GO

-- takeaways Orders companies --

-- ReservationInfo --

CREATE VIEW ReservationInfo AS
    SELECT R.ReservationID, TableID, StartDate, EndDate
    FROM Reservation R
        LEFT OUTER JOIN ReservationDetails RD ON RD.ReservationID = R.ReservationID
    WHERE Status NOT LIKE 'Cancelled'
GO

-- ReservationInfo --
-- ReservationDenied --

CREATE VIEW ReservationDenied AS
    SELECT R.ReservationID, TableID, ClientID, StartDate, EndDate
    FROM Reservation R
        LEFT OUTER JOIN ReservationDetails RD ON RD.ReservationID = R.ReservationID
        INNER JOIN Orders O ON O.ReservationID = R.ReservationID
    WHERE Status LIKE 'denied'
GO

-- ReservationDenied --

-- PendingReservation --

CREATE VIEW dbo.PendingReservations AS
    SELECT R.ReservationID, startDate, endDate,
           OrderID, OrderSum
    FROM Reservation R
        INNER JOIN Orders O ON R.ReservationID = O.ReservationID
    WHERE Status LIKE 'Pending'
GO
-- PendingReservation --

--Orders repORt (wyświetlanie ilości zamówień ORaz ich wartości w okresach czASowych)
CREATE VIEW dbo.OrdersRepORt AS
    SELECT
        ISNULL(CONVERT(VARCHAR(50), YEAR(O.OrderDate), 120), 'Podsumowanie po latach') AS [Year],
        ISNULL(CONVERT(VARCHAR(50),  MONTH(O.OrderDate), 120), 'Podsumowanie miesiaca') AS [MONth],
        ISNULL(CONVERT(VARCHAR(50),  DATEPART(ISo_week , O.OrderDate), 120), 'Podsumowanie tyGOdnia') AS [WEEK],
        COUNT(O.OrderID) AS [ilość zamówień],
        SUM(O.OrderSum) AS [Suma przychodów]
    FROM Orders AS O
    GROUP BY ROLLUP (YEAR(O.OrderDate), MONTH(O.OrderDate), DATEPART(ISo_week, O.OrderDate))
GO
--Orders repORt

--individual clients expenses repORt (wyświetlanie wydanych kwot przez klientów indywidualnych w okresach czasowych)
CREATE VIEW dbo.individualClientExpensesRepORt AS
    SELECT
         YEAR(O.OrderDate) AS [Year],
        ISNULL(CONVERT(VARCHAR(50),  MONTH(O.OrderDate), 120), 'Podsumowanie miesiaca') AS [MONth],
        ISNULL(CONVERT(VARCHAR(50),  DATEPART(ISo_week , O.OrderDate), 120), 'Podsumowanie tyGOdnia') AS [WEEK],
        C.ClientID,
        CONCAT(P2.LastName, ' ',P2.FirstName) AS [Dane],
        C.Phone,
        C.Email,
        CONCAT(A.CityName, ' ',A.street,' ', A.LocalNr) AS [Adres],
        A.PostalCode
        SUM(O.OrderSum) AS [wydane środki]
    FROM Orders AS O
        INNER JOIN Clients C ON C.ClientID = O.ClientID
        INNER JOIN IndividualClient IC ON IC.ClientID = C.ClientID
        INNER JOIN PersON P2 ON P2.PersONID = IC.PersONID
        INNER JOIN Adress A ON A.AdressID = C.AdressID
    GROUP BY GROUPING SETS (
            (C.ClientID, YEAR(O.OrderDate), MONTH(O.OrderDate), DATEPART(week, O.OrderDate)),
            (C.ClientID, YEAR(O.OrderDate), MONTH(O.OrderDate)),
            (C.ClientID, YEAR(O.OrderDate))
        )
GO
--individualClients expenses repORt

--company expenses repORt (wyświetlanie wydanych kwot przez firmy w okresach czASowych)
CREATE VIEW dbo.companyExpensesRepORt AS
    SELECT
        YEAR(O.OrderDate) AS [Rok],
        MONTH(O.OrderDate) AS [Miesiąc],
        DATEPART(week, O.OrderDate) AS [Tydzień],
        C.ClientID,
        C2.CompanyName,
        C2.NIP,
        ISNULL(cASt(C2.KRS AS VARCHAR), 'Brak') AS [KRS],
        ISNULL(cASt(C2.ReGON AS VARCHAR), 'Brak') AS [ReGON],
        C.Phone,
        C.Email,
        CONCAT(A.CityName, ' ',A.street,' ', A.LocalNr) AS [Adres],
        A.PostalCode,
        SUM(O.OrderSum) AS [wydane środki]
    FROM Orders AS O
    INNER JOIN Clients C ON C.ClientID = O.ClientID
    INNER JOIN Companies C2 ON C2.ClientID = C.ClientID
    INNER JOIN Adress A ON A.AdressID = C.AdressID
    GROUP BY GROUPING SETS (
            (C.ClientID, YEAR(O.OrderDate), MONTH(O.OrderDate), DATEPART(week, O.OrderDate)),
            (C.ClientID, YEAR(O.OrderDate), MONTH(O.OrderDate)),
            (C.ClientID, YEAR(O.OrderDate))
        )
GO
--company expenses repORt

--Number of individual clients (ilość klientów indywidualnych w okresach czASu)
CREATE VIEW dbo.numberOfIndividualClients AS
    SELECT
        YEAR(O.OrderDate) AS [Rok],
        MONTH(O.OrderDate) AS [Miesiąc],
        DATEPART(week, O.OrderDate) AS [Tydzień],
        COUNT(DISTINCT C.CustomerID) AS [Ilość klientów indywidualnych]
    FROM Orders AS O
        INNER JOIN Client C ON C.OrderID = O.OrderID
        INNER JOIN IndividualClient IC ON IC.ClientID = C.ClientID
    GROUP BY GROUPING SETS (
            (YEAR(O.OrderDate), MONTH(O.OrderDate), DATEPART(week, O.OrderDate)),
            (YEAR(O.OrderDate), MONTH(O.OrderDate)),
            (YEAR(O.OrderDate))
        )
GO
--Number of clients

--Number of companies (ilość firm w okresach czASu)
CREATE VIEW dbo.numberOfCompanies AS
    SELECT
        YEAR(O.OrderDate) AS [Rok],
        MONTH(O.OrderDate) AS [Miesiąc],
        DATEPART(week, O.OrderDate) AS [Tydzień],
        COUNT(DISTINCT C.CustomerID) AS [Ilość zamawiających firm]
    FROM Orders AS O
        INNER JOIN Client C ON C.OrderID = O.OrderID
        INNER JOIN Companies C2 ON C2.ClientID = C.ClientID
    GROUP BY GROUPING SETS (
            (YEAR(O.OrderDate), MONTH(O.OrderDate), DATEPART(week, O.OrderDate)),
            (YEAR(O.OrderDate), MONTH(O.OrderDate)),
            (YEAR(O.OrderDate))
        )
GO
--Number of companies

--Number of Orders individual client       (ilość zamówień złożONych przez klientów indywidualnych w okresach czASu)
CREATE VIEW dbo.individualClientNumberOfOrders AS
    SELECT
        YEAR(O.OrderDate) AS [Rok],
        MONTH(O.OrderDate) AS [Miesiąc],
        DATEPART(week, O.OrderDate) AS [Tydzień],
        C.ClientID,
        CONCAT(P2.LastName, ' ',P2.FirstName) AS [Dane],
        C.Phone,
        C.Email,
        CONCAT(A.CityName, ' ', A.street, ' ', A.LocalNr) AS [Adres],
        A.PostalCode
        COUNT(DISTINCT O.OrderID) AS [Ilość złożONych zamówień]
    FROM Orders AS O
        INNER JOIN Client C ON C.OrderID = O.OrderID
        INNER JOIN IndividualClient IC ON IC.ClientID = C.ClientID
        INNER JOIN PersON P2 ON P2.PersONID = IC.PersONID
        INNER JOIN Adress A ON A.AdressID = C.AdressID
    GROUP BY GROUPING SETS 
        (
            (C.ClientID, YEAR(O.OrderDate), MONTH(O.OrderDate), DATEPART(week, O.OrderDate)),
            (C.ClientID, YEAR(O.OrderDate), MONTH(O.OrderDate)),
            (C.ClientID, YEAR(O.OrderDate))
        )
GO
--Number of Orders individual client

--Number of Orders companies       (ilość zamówień złożONych przez firmy w okresach czASu)
CREATE VIEW dbo.companiesNumberOfOrders AS
    SELECT
        YEAR(O.OrderDate) AS [Rok],
        MONTH(O.OrderDate) AS [Miesiąc],
        DATEPART(week, O.OrderDate) AS [Tydzień],
        C.ClientID,
        C2.CompanyName,
        C2.NIP,
        ISNULL(cASt(C2.KRS AS VARCHAR), 'Brak') AS [KRS],
        ISNULL(cASt(C2.ReGON AS VARCHAR), 'Brak') AS [ReGON],
        C.Phone,
        C.Email,
        CONCAT(A.CityName, ' ', A.street, ' ', A.LocalNr) AS [Adres],
        A.PostalCode,
        COUNT(DISTINCT O.OrderID) AS [Ilość złożONych zamówień]
    FROM Orders AS O
        INNER JOIN Client C ON C.OrderID = O.OrderID
        INNER JOIN Companies C2 ON C2.ClientID = C.ClientID
        INNER JOIN Adress A ON A.AdressID = C.AdressID
    GROUP BY GROUPING SETS (
            (C.ClientID, YEAR(O.OrderDate), MONTH(O.OrderDate), DATEPART(week, O.OrderDate)),
            (C.ClientID, YEAR(O.OrderDate), MONTH(O.OrderDate)),
            (C.ClientID, YEAR(O.OrderDate))
        )
GO
--Number of Orders companies

--individual clients who have not paid fOR their Orders (klienci indywidualni, którzy mają nieopłacONe zamówienia ORaz jaka jest ich należność)
CREATE VIEW dbo.individualClientsWhONotPayFOROrders AS
    SELECT
        C.ClientID,
        CONCAT(P.LastName, ' ', P.FirstName) AS [Dane],
        C.Phone,
        C.Email,
        CONCAT(A.CityName, ' ',A.street,' ', A.LocalNr) AS [Adres],
        A.PostalCode,
        C.OrderDate,
        SUM(O.OrderSum) AS [Zaległa należność]
    FROM Clients AS C
    WHERE (PS.PaymentStatusName LIKE 'Unpaid')
        INNER JOIN IndividualClient IC ON IC.ClientID = C.ClientID
        INNER JOIN PersON P ON P.PersONID = IndividualClient.PersONID
        INNER JOIN Orders O ON O.ClientID = C.ClientID
        INNER JOIN PaymentStatus PS ON PS.PaymentStatusID = O.PaymentStatusID
        INNER JOIN Adress A ON A.AdressID = C.AdressID
    GROUP BY C.ClientID
GO
--individual clients who have not paid fOR their Orders



--companies who have not paid fOR their Orders  (firmy, które mają nieopłacONe zamówienia ORaz jaka jest ich wartość)
CREATE VIEW dbo.companiesWhONotPayFOROrders AS
    SELECT
        C.ClientID,
        C2.CompanyName,
        C2.NIP,
        ISNULL(C2.KRS, 'Brak') AS [KRS],
        ISNULL(C2.ReGON, 'Brak') AS [ReGON],
        C.Phone,
        C.Email,
        CONCAT(A.CityName, ' ',A.street,' ', A.LocalNr) AS [Adres],
        A.PostalCode,
        SUM(O.OrderSum) AS [Zaległa należność]
    FROM Clients AS C
    WHERE (PS.PaymentStatusName LIKE 'Unpaid')
        INNER JOIN Orders O ON O.ClientID = C.ClientID
        INNER JOIN Companies C2 ON C2.ClientID = C.ClientID
        INNER JOIN PaymentStatus PS ON PS.PaymentStatusID = O.PaymentStatusID
    GROUP BY C.ClientID
GO
--companies who have not paid fOR their Orders

--Orders ON-site             (zamówienia na miejscu, które są przyGOtowywane)
CREATE VIEW dbo.OrdersONSite AS
    SELECT
        O.OrderID,
        O.ClientID,
        C.Phone,
        C.Email,
        OD.Quantity,
        P.Name
    FROM Orders
        INNER JOIN Clients C ON C.OrderID = O.OrderID
        INNER JOIN OrderDetails OD ON OD.OrderID = O.OrderID
        INNER JOIN Products P ON P.ProductID = OD.ProductID
    WHERE (O.TakeawayID IS NULL) AND (O.OrderStatus LIKE 'accepted')
GO
--Orders in progress

--takeaway Orders in progress      (zamówienia na wynos, które są przyGOtowywane dla klientów indywidualnych)

CREATE VIEW dbo.takeawayOrdersInProgressIndividual AS
    SELECT
        O.OrderID,
        O.ClientID,
        C.Phone,
        C.Email,
        CONCAT(P.LastName, ' ', P.FirstName) AS [Dane],
        OD.Quantity,
        P.Name,
        OT.PrefDate
    FROM Orders
        INNER JOIN Clients C ON C.OrderID = O.OrderID
        INNER JOIN IndividualClient IC ON IC.ClientID = C.ClientID
        INNER JOIN PersON P ON P.PersONID = IC.PersONID
        INNER JOIN OrderDetails OD ON OD.OrderID = O.OrderID
        INNER JOIN Products P ON P.ProductID = OD.ProductID
        INNER JOIN OrdersTakeaway OT ON OT.TakeawayID = O.TakeawayID
    WHERE  (O.OrderStatus LIKE 'accepted')
GO

--takeaway Orders in progress

--takeaway Orders in progress      (zamówienia na wynos, które są przyGOtowywane dla klientów indywidualnych)

CREATE VIEW dbo.takeawayOrdersInProgressCompanies AS
    SELECT
        O.OrderID,
        O.ClientID,
        C.Phone,
        C.Email,
        C2.CompanyName,
        C2.NIP,
        ISNULL(cASt(C2.KRS AS VARCHAR), 'Brak') AS [KRS],
        ISNULL(cASt(C2.ReGON AS VARCHAR), 'Brak') AS [ReGON],
        OD.Quantity,
        P.Name,
        OT.PrefDate
    FROM Orders
        INNER JOIN Clients C ON C.OrderID = O.OrderID
        INNER JOIN Companies C2 ON C2.ClientID = C.ClientID
        INNER JOIN OrderDetails OD ON OD.OrderID = O.OrderID
        INNER JOIN Products P ON P.ProductID = OD.ProductID
        INNER JOIN OrdersTakeaway OT ON OT.TakeawayID = O.TakeawayID
    WHERE  (O.OrderStatus LIKE 'accepted')
GO

--takeaway Orders in progress

--Orders fOR individual clients infORmatiON - (inFROMacje o zamówieniach dla klientów indywidualnych)
CREATE VIEW dbo.OrdersInfORmatiONIndividualClient AS
    SELECT
        O.OrderID,
        O.OrderStatus,
        PS.PaymentStatus,
        SUM(O.OrderSum) AS [Wartość zamówienia],
        C.Phone,
        C.Email,
        CONCAT(P.LastName, ' ',P.FirstName) AS [Dane],
        CONCAT(A.CityName, ' ',A.street,' ', A.LocalNr) AS [Adres],
        A.PostalCode,
    FROM Orders AS O
        INNER JOIN PaymentStatus PS ON PS.PaymentStatusID = O.PaymentStatusID
        INNER JOIN Clients C ON C.ClientID = O.ClientID
        INNER JOIN IndividualClient IC ON IC.ClientID = C.ClientID
        INNER JOIN PersON P ON P.PersONID = P.IndividualClient
        INNER JOIN Adress A ON A.AdressID = C.AdressID
        INNER JOIN
    GROUP BY O.OrderID
GO
--Orders fOR individual clients infORmatiON

--Orders fOR company infORmatiON - (infORmacje o zamówieniach dla firm)
CREATE VIEW dbo.OrdersInfORmatiONCompany AS
    SELECT
        O.OrderID,
        O.OrderStatus,
        PS.PaymentStatus,
        SUM(O.OrderSum) AS [Wartość zamówienia],
        C.Phone,
        C.Email,
        C2.CompanyName,
        C2.NIP,
        ISNULL(cASt(C2.KRS AS VARCHAR), 'Brak') AS [KRS],
        ISNULL(cASt(C2.ReGON AS VARCHAR), 'Brak') AS [ReGON],
        CONCAT(A.CityName, ' ',A.street,' ', A.LocalNr) AS [Adres],
        A.PostalCode,
    FROM Orders AS O
        INNER JOIN PaymentStatus PS ON PS.PaymentStatusID = O.PaymentStatusID
        INNER JOIN Clients C ON C.ClientID = O.ClientID
        INNER JOIN Companies C2 ON C2.ClientID = C.ClientID
        INNER JOIN Adress A ON A.AdressID = C.AdressID
        INNER JOIN
    GROUP BY O.OrderID
GO
--Orders fOR company infORmatiON

-- PendingReservation Companies--

CREATE VIEW dbo.PendingReservationsCompanies AS
    SELECT R.ReservationID, startDate, endDate,
           OrderID, OrderSum
    FROM Reservation R
        INNER JOIN ReservationCompany RC ON RC.ReservationID = R.ReservationID
        INNER JOIN Orders O ON R.ReservationID = O.ReservationID
    WHERE Status LIKE 'Pending'
GO

-- PendingReservation Companies--

-- PendingReservation Individual--

CREATE VIEW dbo.PendingReservationsIndividual AS
    SELECT R.ReservationID, startDate, endDate,
           OrderID, OrderSum
    FROM Reservation R
        INNER JOIN ReservationIndividual RC ON RC.ReservationID = R.ReservationID
        INNER JOIN Orders O ON R.ReservationID = O.ReservationID
    WHERE Status LIKE 'Pending'
GO

-- Reservation accepted BY --
CREATE VIEW dbo.ReservationAcceptedBY AS
    SELECT CONCAT(LastName, ' ',FirstName) AS Dane, PositiON, Email, Phone
    FROM Staff
        INNER JOIN Reservation R2 ON Staff.StaffID = R2.StaffID
    WHERE Status LIKE 'accepted'
GO
-- Reservation accepted BY --

-- Reservation summary --

CREATE VIEW dbo.ReservationSummary AS
    SELECT
        O.ClientID AS 'Numer clienta',
        startDate,
        endDate,
        CONVERT(TIME,endDate - startDate , 108) AS 'CzAS trwania',
        O.OrderSum,
        O.OrderDate,
        O.OrderCompletionDate,
        OD.Quantity,
        RD.TableID
    FROM Reservation
        INNER JOIN Orders O ON Reservation.ReservationID = O.ReservationID
        INNER JOIN OrderDetails OD ON O.OrderID = OD.OrderID
        INNER JOIN ReservationCompany RC ON Reservation.ReservationID = RC.ReservationID
        INNER JOIN ReservationDetails RD ON RC.ReservationID = RD.ReservationID
    WHERE Status NOT LIKE 'denied'
UNION
    SELECT
        O.ClientID AS 'Numer clienta',
        startDate,
        endDate,
        CONVERT(TIME,endDate - startDate , 108) AS 'CzAS trwania',
        O.OrderSum,
        O.OrderDate,
        O.OrderCompletionDate,
        OD.Quantity,
        RD.TableID
    FROM Reservation
        INNER JOIN Orders O ON Reservation.ReservationID = O.ReservationID
        INNER JOIN OrderDetails OD ON O.OrderID = OD.OrderID
        INNER JOIN ReservationIndividual RC ON Reservation.ReservationID = RC.ReservationID
        INNER JOIN ReservationDetails RD ON RC.ReservationID = RD.ReservationID
    WHERE Status NOT LIKE 'denied'

GO

-- Reservation summary --

-- Products summary Daily --

CREATE VIEW dbo.ProductsSummaryDaily AS
    SELECT P.Name, P.Description, cASt(O.OrderDate AS DATE) AS 'Dzien', COUNT(OD.ProductID) AS 'Liczba zamowiONych produktow'
    FROM Products P
        INNER JOIN OrderDetails OD ON P.ProductID = OD.ProductID
        INNER JOIN Orders O ON OD.OrderID = O.OrderID
    WHERE O.OrderStatus NOT LIKE 'denied'
        GROUP BY P.Name, P.Description, cASt(O.OrderDate AS DATE)
GO

-- Products summary Daily --

-- Products summary  weekly --

CREATE VIEW dbo.ProductsSummaryWeekly AS
    SELECT P.Name, P.Description, DATEPART(ISo_week ,cASt(O.OrderDate AS DATE)) AS 'Tydzien', DATEPART(YEAR, cASt(O.OrderDate AS DATE)) AS 'Rok', COUNT(OD.ProductID) AS 'Liczba produktow'
    FROM Products P
        INNER JOIN OrderDetails OD ON P.ProductID = OD.ProductID
        INNER JOIN Orders O ON OD.OrderID = O.OrderID
    WHERE O.OrderStatus NOT LIKE 'denied'
        GROUP BY P.Name, P.Description, DATEPART(ISo_week  ,cASt(O.OrderDate AS DATE)), DATEPART(YEAR, cASt(O.OrderDate AS DATE))
GO

-- Products summary  weekly --

-- Products summary Monthly --

CREATE VIEW dbo.ProductsSummaryMonthly AS
    SELECT P.Name, P.Description, DATEPART(MONTH ,cASt(O.OrderDate AS DATE)) AS 'Miesiac', DATEPART(YEAR, cASt(O.OrderDate AS DATE)) AS 'Rok', COUNT(OD.ProductID) AS  'Liczba zamowiONych produktow'
    FROM Products P
        INNER JOIN OrderDetails OD ON P.ProductID = OD.ProductID
        INNER JOIN Orders O ON OD.OrderID = O.OrderID
    WHERE O.OrderStatus NOT LIKE 'denied'
        GROUP BY P.Name, P.Description, DATEPART(MONTH ,cASt(O.OrderDate AS DATE)), DATEPART(YEAR, cASt(O.OrderDate AS DATE))
GO

-- Products summary Monthly --



-- Not reserved Tables --

-- Kto wydał dane zamówienie
CREATE OR alter VIEW dbo.Waiters AS
    SELECT FirstName + ' ' + LastName AS Name, OrderID AS id
    FROM Staff
             JOIN Orders O ON Staff.StaffID = O.staffID
    WHERE PositiON = 'waiter'
       OR PositiON = 'waitress';
GO

-- Jakie zamówienia są na wynos
CREATE OR alter VIEW dbo.AllTakeaways AS
    SELECT TakeawayID,
           PrefDate,
           OrderID,
           ClientID,
           PaymentStatusID,
           CONCAT(S.LastName, ' ',S.FirstName) AS 'Dane kelnera',
           PositiON,
           OrderSum,
           OrderDate,
           OrderCompletionDate,
           OrderStatus
    FROM OrdersTakeaways
            JOIN Orders O ON OrdersTakeaways.TakeawaysID = O.TakeawayID
            JOIN Staff S ON O.staffID = S.StaffID
GO

-- Jakie zamówienia są w trakcie przyGOtowywania
CREATE OR alter VIEW dbo.OrdersToPrepare AS
    SELECT OrderID, ClientID, TakeawayID, PaymentStatusName, PM.PaymentName,
           CONCAT(S.LastName, ' ',S.FirstName) AS 'Dane kelnera',
            OrderSum, OrderDate, PrefDate
    FROM Orders JOIN OrdersTakeaways OT ON Orders.TakeawayID = OT.TakeawaysID
        INNER JOIN PaymentStatus PS ON PS.PaymentStatusID = Orders.PaymentStatusID
        INNER JOIN PaymentMethods PM ON PS.PaymentMethodID = PM.PaymentMethodID
        INNER JOIN Staff S ON Orders.staffID = S.StaffID
    WHERE ((OrderCompletionDate IS NULL AND (GETDATE() >= OrderDate)) AND OrderStatus = 'pending')
GO

-- Ile jest zamówień które będą realizowane jako owoce mORza i które to są grupowane po klientach
CREATE OR alter VIEW dbo.SeeFoodOrdersBYClient AS
    SELECT COUNT(OD.OrderID) AS 'Liczba zamowien z owocami mORza', Orders.OrderID
    FROM Orders
        JOIN OrderDetails OD ON Orders.OrderID = OD.OrderID
        JOIN Products P ON P.ProductID = OD.ProductID JOIN Category C ON C.CategoryID = P.CategoryID
    WHERE CategoryName='sea food' AND (OrderStatus NOT LIKE 'denied') AND ( (OrderCompletionDate IS NULL AND (GETDATE() >= OrderDate)))
    GROUP BY CategoryName, Orders.OrderID
GO

-- Ile jest zamówień które będą realizowane jako owoce mORza i które to są 
CREATE OR alter VIEW dbo.SeeFoodOrders AS
    SELECT COUNT(OD.OrderID) AS 'Liczba zamowien z owocami mORza'
    FROM Orders
        JOIN OrderDetails OD ON Orders.OrderID = OD.OrderID
        JOIN Products P ON P.ProductID = OD.ProductID JOIN Category C ON C.CategoryID = P.CategoryID
    WHERE CategoryName='sea food' AND (OrderStatus NOT LIKE 'denied') AND ( (OrderCompletionDate IS NULL AND (GETDATE() >= OrderDate)))
    GROUP BY CategoryName
GO


-- Aktualnie nałożONe zniżki na klientów
CREATE OR alter VIEW CurrentDISCOUNTs AS
    SELECT FirstName,LastName, IC.ClientID, DISCOUNTID, AppliedDate, startDate, endDate, DISCOUNTType,
           DISCOUNTValue, MinimalOrders, MinimalAggregateValue, ValidityPeriod
    FROM DISCOUNTsVar JOIN DISCOUNTs ON DISCOUNTsVar.VarID = DISCOUNTs.VarID
        JOIN IndividualClient IC ON DISCOUNTs.ClientID = IC.ClientID
        JOIN PersON P ON P.PersONID = IC.PersONID
    WHERE (((GETDATE() >= startDate) AND (GETDATE() <= endDate)) OR ((GETDATE() >= startDate) AND (endDate IS NULL)))
GO

-- infORmacje na temat wszystkich przyznanych zniżek
CREATE OR alter VIEW AllDISCOUNTs AS
    SELECT IC.PersONID, LastName, FirstName,IC.ClientID, DISCOUNTsVar.VarID, DISCOUNTType, MinimalOrders, MinimalAggregateValue, ValidityPeriod, DISCOUNTValue, startDate, endDate, DISCOUNTID, AppliedDate
    FROM DISCOUNTsVar 
        JOIN DISCOUNTs ON DISCOUNTsVar.VarID = DISCOUNTs.VarID 
        JOIN IndividualClient IC ON DISCOUNTs.ClientID = IC.ClientID 
        JOIN PersON P ON P.PersONID = IC.PersONID
GO
-- Dania wymagane na dzISiaj na wynos

CREATE OR alter VIEW DIShesInProgressTakeaways AS
    SELECT  Name, COUNT(Products.ProductID) AS 'Liczba zamowien', sum(Quantity) AS 'Liczba sztuk'
    FROM Products JOIN OrderDetails OD ON Products.ProductID = OD.ProductID
        JOIN Orders ON OD.OrderID = Orders.OrderID
        JOIN OrdersTakeaways OT ON Orders.TakeawayID = OT.TakeawaysID
    WHERE (((GETDATE() >= OrderDate) AND (GETDATE() <= OrderCompletionDate)))
      AND (Orders.OrderStatus NOT LIKE 'denied' OR Orders.OrderStatus NOT LIKE 'cancelled')
    GROUP BY Name
GO

-- Dania wymagane na dzISiaj w rezerwacji
CREATE OR alter VIEW DIShesInProgressReservation AS
    SELECT Name, COUNT(Products.ProductID) AS 'Liczba zamowien', sum(Quantity) AS 'Liczba sztuk'
    FROM Products
        JOIN OrderDetails OD ON Products.ProductID = OD.ProductID
        JOIN Orders ON OD.OrderID = Orders.OrderID
        JOIN Reservation R2 ON Orders.ReservationID = R2.ReservationID
    WHERE (((GETDATE() >= OrderDate) AND (GETDATE() <= OrderCmpletiONDate)))
      AND Orders.OrderStatus NOT LIKE 'denied' AND (R2.Status NOT LIKE 'denied' OR R2.Status NOT LIKE 'cancelled')
    GROUP BY Name
GO

-- Products informations --

CREATE VIEW dbo.dbo.ProductsInformations AS
    SELECT Name, P.Description, CategoryName, IIF(IsAvailable = 1, 'Aktywne', 'Nieaktywne') AS 'Czy produkt aktywny',
           IIF(P.ProductID in (SELECT ProductID
                            FROM Menu
                            WHERE ((startDate >= GETDATE()) AND (endDate >= GETDATE()))
                                OR ((startDate >= GETDATE()) AND endDate IS NULL) AND P.ProductID = Menu.ProductID),
               'Aktualnie w menu', 'Nie jest w menu') AS 'Czy jest aktualnie w menu', COUNT(OD.ProductID) AS 'Ilosc zamowien daneGO produktu'
   FROM Products P
        INNER JOIN Category C ON C.CategoryID = P.CategoryID
        INNER JOIN OrderDetails OD ON P.ProductID = OD.ProductID
    GROUP BY Name, P.Description, CategoryName, P.ProductID, IsAvailable
GO

-- Products informations --
