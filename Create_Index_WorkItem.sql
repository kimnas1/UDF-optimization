/* =============================================================
   Create_Index_WorkItem.sql
   -------------------------------------------------------------
   Covers (Id_Work, Is_Complit) and includes Price so later
   SUM/AVG extensions will be seek-only.
   ============================================================= */
USE UDFLab;
GO

IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE  name = 'IX_WorkItem_IdWork_IsComplit'
          AND  object_id = OBJECT_ID('dbo.WorkItem')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_WorkItem_IdWork_IsComplit
        ON dbo.WorkItem (Id_Work, Is_Complit)
        INCLUDE (Price);
END
GO

