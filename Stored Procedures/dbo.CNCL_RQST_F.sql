SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CNCL_RQST_F]
	-- Add the parameters for the stored procedure here
    @X XML
AS
BEGIN
    DECLARE @ErrorMessage NVARCHAR(MAX);
    BEGIN TRAN T1;
    BEGIN TRY
        DECLARE @Rqid BIGINT;
        SELECT  @Rqid = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT');
	     
	     -- 1401/02/04 * حذف رکورد های پرداختی درخواست
	     DELETE dbo.Payment_Method 
	      WHERE PYMT_RQST_RQID = @Rqid;
	     
        UPDATE  Request
        SET     RQST_STAT = '003'
        WHERE   RQID = @Rqid;
	 
        COMMIT TRAN T1;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
        ROLLBACK TRAN T1;
    END CATCH;	 
END;
GO
