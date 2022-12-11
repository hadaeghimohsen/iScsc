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
	     
	     -- Loval Var 
	     DECLARE @RqtpCode VARCHAR(3);
	     SELECT @RqtpCode = RQTP_CODE FROM dbo.Request WHERE RQID = @Rqid;	     
	     
	     -- Local Var 
	     DECLARE @AP BIT
               ,@AccessString VARCHAR(250);
        
        -- 1401/09/12 * درخواست های مورد نظر که اگر چاپ هزینه یا پرداختی داشته باشند نباید بتوانیم انصراف بدهیم
	     IF @RqtpCode IN ('001', '009', '016') AND 
	        EXISTS (SELECT * FROM dbo.Step_History_Detail shd WHERE shd.SHIS_RQST_RQID = @Rqid AND shd.SSTT_MSTT_CODE = 2 AND shd.SSTT_CODE = 3)
	     BEGIN 
	        -- 1401/09/12 * اگر درخواستی داریم که چاپ فاکتور زده شده باشیم و بخواهیم آن را انصراف بزنیم باید چک کنیم که دسترسی آن را داریم یا خیر
	        -- بررسی دسترسی 263 که ایا درخواست مجوز انصراف را دارد یا خیر	        
           SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>263</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
           EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
           IF @AP = 0 
           BEGIN
              RAISERROR ( N'خطا - عدم دسترسی به ردیف 263 سطوح امینتی', -- Message text.
                          16, -- Severity.
                          1 -- State.
                        );
              RETURN;
           END;
           
           -- اگر درخواست ردیف پرداخت داشته باشد
           IF EXISTS(SELECT * FROM dbo.Payment_Method pm WHERE pm.RQRO_RQST_RQID = @Rqid)
           BEGIN
              -- 1401/09/12 * اگر درخواستی داریم که چاپ فاکتور زده شده باشیم و بخواهیم آن را انصراف بزنیم باید چک کنیم که ایا درخواست ردیف پرداخت دارد یا خیر دسترسی آن را داریم یا خیر
	           -- بررسی دسترسی 264 که ایا درخواست مجوز انصراف را دارد یا خیر	        
              SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>264</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
              EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
              IF @AP = 0 
              BEGIN
                 RAISERROR ( N'خطا - عدم دسترسی به ردیف 264 سطوح امینتی', -- Message text.
                             16, -- Severity.
                             1 -- State.
                           );
                 RETURN;
              END;
           END
        END;
	     
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
