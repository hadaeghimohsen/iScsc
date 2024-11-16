SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_FGPR_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   BEGIN TRAN [T$UPD_FGPR_P]
	BEGIN TRY
	
	-- Param Var
	DECLARE @Code BIGINT;
	SELECT @Code = @X.query('//Fighter_Grouping_Permission').value('(Fighter_Grouping_Permission/@code)[1]', 'BIGINT');
	
	DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
          
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>279</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 279 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END;  
	
	UPDATE dbo.Fighter_Grouping_Permission SET PERM_STAT = CASE PERM_STAT WHEN '002' THEN '001' ELSE '002' END WHERE CODE = @Code;
	
	COMMIT TRAN [T$UPD_FGPR_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);
	   ROLLBACK TRAN [T$UPD_FGPR_P];
	END CATCH
END
GO
