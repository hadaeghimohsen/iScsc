SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CALC_OPNT_P]	
AS
BEGIN
   DECLARE @AgopCode BIGINT, 
           @Rwno BIGINT;
	-- Calculate all open tables and show result
   DECLARE C$Aodt CURSOR FOR
      SELECT b.CODE, a.RWNO
        FROM dbo.Aggregation_Operation b, dbo.Aggregation_Operation_Detail a
       WHERE b.CODE = a.AGOP_CODE
         AND b.OPRT_TYPE = '005' -- بازی گیم کلاب و رزرواسیون باشد
         AND b.OPRT_STAT = '002' -- دفتر باز باشد
         AND a.REC_STAT = '002' -- رکورد فعال باشد
         AND a.STAT = '001'; -- میز باز باشد
   
   OPEN [C$Aodt];
   L$LoopCalcOpenTables:
   FETCH [C$Aodt] INTO @AgopCode, @Rwno;
   
   IF @@FETCH_STATUS <> 0 
      GOTO L$EndLoopCalcOpenTables;
   
   UPDATE dbo.Aggregation_Operation_Detail SET END_TIME = GETDATE() WHERE AGOP_CODE = @AgopCode AND RWNO = @Rwno;   
   EXEC dbo.CALC_APDT_P @Agop_Code = @AgopCode, @Rwno = @Rwno;      
   
   GOTO L$LoopCalcOpenTables;
   L$EndLoopCalcOpenTables:
   CLOSE [C$Aodt];
   DEALLOCATE [C$Aodt];
END
GO
