/* =======================================================================
   GenerateTestData.sql  —  UDF-optimisation lab
   -----------------------------------------------------------------------
   - Builds a 100 000-row Numbers helper table
   - Seeds all lookup tables exactly once
   - Inserts 50 000 Works (orders)
   - Inserts 150 000 WorkItem lines (3 per order)
   ======================================================================= */
SET NOCOUNT ON;

/*----------------------------------------------------------
  0.  Wipe demo data if you’re re-running the script
----------------------------------------------------------*/
DELETE FROM dbo.WorkItem;     -- child first
DELETE FROM dbo.Works;
DELETE FROM dbo.Employee;
DELETE FROM dbo.Organization;
DELETE FROM dbo.Analiz;
DELETE FROM dbo.SelectType;
DELETE FROM dbo.WorkStatus;
DELETE FROM dbo.PrintTemplate;
DELETE FROM dbo.TemplateType;
-- keep PrintTemplate foreign-key safe
/*----------------------------------------------------------
  1.  Numbers helper (1…100 000)
----------------------------------------------------------*/
IF OBJECT_ID('dbo.Numbers') IS NOT NULL
    DROP TABLE dbo.Numbers;
SELECT TOP (100000)
       ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
INTO   dbo.Numbers
FROM   sys.all_objects a
CROSS  JOIN sys.all_objects b;   -- plenty of rows
CREATE UNIQUE CLUSTERED INDEX IX_Numbers ON dbo.Numbers(n);
/*----------------------------------------------------------
  2.  Lookup tables
----------------------------------------------------------*/
-- 2-a  TemplateType & PrintTemplate  (3 / 6 rows)
INSERT INTO dbo.TemplateType (TemlateVal, Comment)
SELECT CONCAT('TT-', n), CONCAT('Template-type #', n)
FROM dbo.Numbers WHERE n <= 3;

INSERT INTO dbo.PrintTemplate (TemplateName, CreateDate, Ext, Comment, Id_TemplateType)
SELECT CONCAT('PT-', n),
       DATEADD(DAY, -n, SYSUTCDATETIME()),
       '.docx',
       CONCAT('Print template #', n),
       1 + (n-1) % 3
FROM dbo.Numbers WHERE n <= 6;

-- 2-b  Organization  (10 rows, FK → PrintTemplate)
INSERT INTO dbo.Organization (ORG_NAME, Template_FN, Id_PrintTemplate, Email)
SELECT CONCAT('Org-', n),
       CONCAT('tmpl_', n, '.docx'),
       1 + (n-1) % 6,
       CONCAT('org', n, '@example.com')
FROM dbo.Numbers WHERE n <= 10;

-- 2-c  WorkStatus  (5 rows)
INSERT INTO dbo.WorkStatus (StatusName)
VALUES ('Новый'), ('В работе'), ('Пауза'), ('Завершён'), ('Отправлен');

-- 2-d  SelectType  (5 rows)
INSERT INTO dbo.SelectType (SelectType)
SELECT CONCAT('SEL-', n)
FROM dbo.Numbers WHERE n <= 5;

-- 2-e  Employee  (200 rows, unique Login_Name)
INSERT INTO dbo.Employee (Login_Name, Name, Patronymic, Surname,
                          Email, Post, Archived, IS_Role, Role)
SELECT CONCAT('emp', n),
       CONCAT('Имя', n),
       CONCAT('Отч', n),
       CONCAT('Фам', n),
       CONCAT('emp', n, '@demo.local'),
       'Lab-Tech',
       0, 0, NULL
FROM dbo.Numbers WHERE n <= 200;

-- 2-f  Analiz  (300 rows: 60 groups, 240 leaves)
INSERT INTO dbo.Analiz (IS_GROUP, FULL_NAME, Price)
SELECT CASE WHEN n <= 60 THEN 1 ELSE 0 END,
       CONCAT('Анализ-', n),
       50 + (n % 150)        -- 50–199
FROM dbo.Numbers WHERE n <= 300;

/*----------------------------------------------------------
  3.  Works   (50 000 rows, FK → Employee, Organization, WorkStatus)
----------------------------------------------------------*/
INSERT INTO dbo.Works
        (IS_Complit, CREATE_Date, Id_Employee, ID_ORGANIZATION,
         FIO, Is_Del, StatusId, MaterialNumber)
SELECT 0,
       DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, SYSUTCDATETIME()),
       1 + ABS(CHECKSUM(NEWID())) % 200,      -- Employee 1-200
       1 + ABS(CHECKSUM(NEWID())) % 10,       -- Org 1-10
       CONCAT(N'Пациент ', n),
       0,
       1 + ABS(CHECKSUM(NEWID())) % 5,        -- Status 1-5
       n                                      -- MaterialNumber = n
FROM dbo.Numbers
WHERE n <= 50000;

/*----------------------------------------------------------
  4.  WorkItem  (150 000 rows = 3 per Work)
----------------------------------------------------------*/
;WITH Three AS (
    SELECT Id_Work,
           ROW_NUMBER() OVER (PARTITION BY Id_Work ORDER BY (SELECT NULL)) AS rn
    FROM dbo.Works
    CROSS APPLY (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3) t(x)   -- 3 per work
)
INSERT INTO dbo.WorkItem
        (CREATE_DATE, Is_Complit, Id_Employee, ID_ANALIZ, Id_Work,
         Is_Print, Is_Select, Is_NormTextPrint, Price, Id_SelectType)
SELECT  DATEADD(SECOND, rn, SYSUTCDATETIME()),
        CAST(ABS(CHECKSUM(NEWID())) % 2 AS BIT),     -- random complete flag
        1 + ABS(CHECKSUM(NEWID())) % 200,            -- random Employee
        61 + ABS(CHECKSUM(NEWID())) % 240,           -- non-group Analiz IDs 61-300
        th.Id_Work,
        1, 0, 1,
        (SELECT Price FROM dbo.Analiz WHERE ID_ANALIZ = 61 + ABS(CHECKSUM(NEWID())) % 240),
        1 + ABS(CHECKSUM(NEWID())) % 5               -- SelectType 1-5
FROM    Three AS th;

/*----------------------------------------------------------
  5.  Report counts
----------------------------------------------------------*/
PRINT '--- Row counts ---';
SELECT 'TemplateType' AS [Table], COUNT(*) FROM dbo.TemplateType UNION ALL
SELECT 'PrintTemplate', COUNT(*) FROM dbo.PrintTemplate UNION ALL
SELECT 'Organization', COUNT(*) FROM dbo.Organization UNION ALL
SELECT 'WorkStatus', COUNT(*) FROM dbo.WorkStatus UNION ALL
SELECT 'SelectType', COUNT(*) FROM dbo.SelectType UNION ALL
SELECT 'Employee', COUNT(*) FROM dbo.Employee UNION ALL
SELECT 'Analiz', COUNT(*) FROM dbo.Analiz UNION ALL
SELECT 'Works', COUNT(*) FROM dbo.Works UNION ALL
SELECT 'WorkItem', COUNT(*) FROM dbo.WorkItem;

PRINT '✅  Test-data generation finished.';

