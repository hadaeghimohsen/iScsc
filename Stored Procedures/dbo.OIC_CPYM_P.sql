SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[OIC_CPYM_P]
   @X XML
AS 
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>187</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 187 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   BEGIN TRY
      BEGIN TRAN T1
         DECLARE @Rqid BIGINT
                ,@RegnCode VARCHAR(3)
                ,@PrvnCode VARCHAR(3)
                ,@RqtpCode VARCHAR(3)
                ,@RqttCode VARCHAR(3)
                ,@PymtType VARCHAR(3);
         
         SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT')
               ,@PymtType = @X.query('//Request').value('(Request/@pymttype)[1]', 'VARCHAR(3)');
         SELECT @RegnCode = REGN_CODE
               ,@PrvnCode = REGN_PRVN_CODE
               ,@RqtpCode = RQTP_CODE
               ,@RqttCode = RQTT_CODE
           FROM Request
          WHERE RQID = @Rqid;
          
         IF ISNULL(@PymtType , '001') = '001'
         BEGIN
            SELECT @X = (
               SELECT @Rqid '@rqid'          
               ,@RqtpCode/*'001'*/ '@rqtpcode'
               ,'008' '@rqttcode'
               ,@RegnCode '@regncode'  
               ,@PrvnCode '@prvncode'
               FOR XML PATH('Request'), ROOT('Process')
            );
            EXEC INS_SEXP_P @X;             

            UPDATE Request
            SET /*SEND_EXPN = '002'
               ,*/SSTT_MSTT_CODE = 2
               ,SSTT_CODE = 2
            WHERE RQID = @Rqid;
         END
         ELSE
         BEGIN
            DELETE dbo.Payment_Detail
             WHERE PYMT_RQST_RQID = @Rqid;
            
            DELETE dbo.Payment_Check
             WHERE PYMT_RQST_RQID = @Rqid;
            
            DELETE dbo.Payment_Discount
             WHERE PYMT_RQST_RQID = @Rqid;
            
            DELETE dbo.Payment_Method
             WHERE PYMT_RQST_RQID = @Rqid;
            
            DELETE dbo.Payment
             WHERE RQST_RQID = @Rqid;
            
            UPDATE Request
            SET /*SEND_EXPN = '002'
               ,*/SSTT_MSTT_CODE = 1
               ,SSTT_CODE = 1
            WHERE RQID = @Rqid; 
         END
      COMMIT TRAN T1;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH
END;
GO
