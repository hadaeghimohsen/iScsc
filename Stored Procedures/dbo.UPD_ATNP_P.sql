SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[UPD_ATNP_P] 
   @X XML
AS
BEGIN
   DECLARE @AttnCode BIGINT;
   
   SELECT @AttnCode = @X.query('Attendance').value('(Attendance/@code)[1]', 'BIGINT');
   UPDATE dbo.Attendance
      SET PRNT_STAT = '002'
         ,PRNT_CONT += 1
    WHERE CODE = @AttnCode;
END;
GO
