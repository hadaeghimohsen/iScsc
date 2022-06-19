SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ADM_TCNL_F]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT
	          ,@RqstStat VARCHAR(3)
	          ,@FileNo   BIGINT;
   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@FileNo   = @X.query('//Fighter').value('(Fighter/@fileno)[1]'  , 'BIGINT');

      SELECT @RqstStat = R.RQST_STAT
        FROM Request R
       WHERE R.RQID = @Rqid;
      
      IF @RqstStat = '001' 
      BEGIN
         DELETE dbo.Payment_Method
          WHERE PYMT_RQST_RQID = @Rqid;
                   
         UPDATE Request
            SET RQST_STAT = '003'
          WHERE RQID = @Rqid;
      END
      ELSE IF @RqstStat = '002'
      BEGIN
         	DECLARE @AP BIT
	                ,@AccessString VARCHAR(250);
	         SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>118</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 73 سطوح امینتی : شما مجوز حذف هنرجو از سیستم را ندارید', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END

         UPDATE Fighter
            SET CONF_STAT = '001'
          WHERE FILE_NO = @FileNo;
      END
      
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
END
GO
