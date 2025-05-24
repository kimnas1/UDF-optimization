/* =============================================================
   Rewrite_F_WORKS_LIST.sql
   -------------------------------------------------------------
   Drops the original multi-statement TVF and creates an inline
   version that SQL Server can fully inline and parallelise.
   ============================================================= */
USE UDFLab;
GO

DROP FUNCTION IF EXISTS dbo.F_WORKS_LIST;
GO

CREATE FUNCTION dbo.F_WORKS_LIST ()
RETURNS TABLE WITH SCHEMABINDING
AS
RETURN
SELECT
        w.Id_Work,
        w.CREATE_Date,
        w.MaterialNumber,
        w.IS_Complit,
        w.FIO,
        CONVERT(varchar(10), w.CREATE_Date, 104)           AS D_DATE,

        -- count items by completion status
        ws_not.cnt                                         AS WorkItemsNotComplit,
        ws_done.cnt                                        AS WorkItemsComplit,

        -- build employee initials
        e.SURNAME + ' ' +
        UPPER(LEFT(e.Name,1)) + '. ' +
        UPPER(LEFT(e.Patronymic,1)) + '.'                  AS FULL_NAME,

        w.StatusId,
        s.StatusName,

        -- flag: any print / send dates set?
        CASE WHEN w.Print_Date       IS NOT NULL
           OR  w.SendToClientDate    IS NOT NULL
           OR  w.SendToDoctorDate    IS NOT NULL
           OR  w.SendToOrgDate       IS NOT NULL
           OR  w.SendToFax           IS NOT NULL
             THEN 1 ELSE 0 END                             AS Is_Print
FROM    dbo.Works        AS w
LEFT    JOIN dbo.WorkStatus AS s  ON s.StatusID   = w.StatusId
JOIN    dbo.Employee     AS e  ON e.Id_Employee = w.Id_Employee

-- inline counts (no scalar UDFs)
OUTER APPLY (
    SELECT COUNT(*) AS cnt
    FROM   dbo.WorkItem wi
    WHERE  wi.Id_Work    = w.Id_Work
      AND  wi.Is_Complit = 0
) AS ws_not
OUTER APPLY (
    SELECT COUNT(*) AS cnt
    FROM   dbo.WorkItem wi
    WHERE  wi.Id_Work    = w.Id_Work
      AND  wi.Is_Complit = 1
) AS ws_done;
GO

