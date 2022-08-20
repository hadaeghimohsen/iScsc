SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CALC_EXCO_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   -- Parameter Variables
	DECLARE @ExpnCode BIGINT = @X.query('//Expense').value('(Expense/@code)[1]', 'BIGINT'),
	        @ExpnPric BIGINT = @X.query('//Expense').value('(Expense/@pric)[1]', 'BIGINT');
	
	-- Local Column Storage Variables
	DECLARE @Rwno SMALLINT,
	        @InitAmntDnrm BIGINT,
	        @ExcoType VARCHAR(3),
	        @ExcoAmnt BIGINT,
	        @ExcoCalcAmnt BIGINT;
   
   -- Local Processing Variables
   DECLARE @i INT = 1;
   
   DECLARE C$Exco CURSOR FOR
      SELECT RWNO, EXCO_TYPE, EXCO_AMNT
       FROM dbo.Expense_Cost
      WHERE EXPN_CODE = @ExpnCode
        AND EXCO_STAT = '002'
      ORDER BY RWNO;
   
   OPEN [C$Exco];
   L$Loop:
   FETCH [C$Exco] INTO @Rwno, @ExcoType, @ExcoAmnt;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndLoop;
   
   IF @i = 1
   BEGIN
      SET @InitAmntDnrm = @ExpnPric;
      SET @i += 1;
   END;
   
   SET @ExcoCalcAmnt = CASE @ExcoType WHEN '001' THEN (@InitAmntDnrm * @ExcoAmnt) / 100 WHEN '002' THEN @ExcoAmnt END;
   UPDATE dbo.Expense_Cost
      SET INIT_AMNT_DNRM = @InitAmntDnrm
         ,EXCO_CALC_AMNT = @ExcoCalcAmnt
    WHERE EXPN_CODE = @ExpnCode
      AND RWNO = @Rwno;
     
   SET @InitAmntDnrm -= @ExcoCalcAmnt;
   
   GOTO L$Loop;
   L$EndLoop:
   CLOSE [C$Exco];
   DEALLOCATE [C$Exco];
   
   -- Update Expense By Last Cost Operation
   UPDATE dbo.Expense
      SET PROF_AMNT_DNRM = @InitAmntDnrm,
          DEDU_AMNT_DNRM = PRIC - @InitAmntDnrm
    WHERE CODE = @ExpnCode;
END;
GO
