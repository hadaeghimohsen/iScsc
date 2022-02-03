SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[REMV_STIS_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION [T$REMV_STIS_P]
	
	-- Check Validation Access Permission
	DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>253</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 253 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
	-- Params Var
	DECLARE @FromDate DATE = @X.query('.').value('(Statistic/@fromdate)[1]', 'DATE'),
	        @ToDate DATE = @X.query('.').value('(Statistic/@todate)[1]', 'DATE');
	        
	DELETE dbo.Statistic
	 WHERE CAST(STIS_DATE AS DATE) BETWEEN @FromDate AND @ToDate;
	 
	COMMIT TRANSACTION [T$REMV_STIS_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(max) = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);
	   ROLLBACK
	END CATCH
END
GO
