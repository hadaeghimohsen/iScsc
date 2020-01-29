SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GRN_TSAV_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN

	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T_GRN_TSAV_P;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT;   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT');     
      
      UPDATE dbo.Request
         SET RQST_STAT = '002'
       WHERE RQID = @Rqid;
                
      COMMIT TRAN T_GRN_TSAV_P;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T_GRN_TSAV_P;
   END CATCH;  
END
GO
