/* =============================================================
   Create_Index_Works.sql
   -------------------------------------------------------------
   Compound key ordered by newest CREATE_Date so ‘TOP (3000)
   ORDER BY Id_Work DESC’ becomes a backward scan instead of
   an explicit sort.
   ============================================================= */
USE UDFLab;
GO

IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE  name = 'IX_Works_CreateDate_Employee'
          AND  object_id = OBJECT_ID('dbo.Works')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_Works_CreateDate_Employee
        ON dbo.Works (CREATE_Date DESC, Id_Employee);
END
GO

