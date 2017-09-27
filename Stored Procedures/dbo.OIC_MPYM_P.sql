SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[OIC_MPYM_P]
   @X XML
AS 
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>164</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 164 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   BEGIN TRY
      BEGIN TRAN T1
         DECLARE @Rqid BIGINT
                ,@RegnCode VARCHAR(3)
                ,@PrvnCode VARCHAR(3);
         
         SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT');
         SELECT @RegnCode = REGN_CODE
               ,@PrvnCode = REGN_PRVN_CODE
           FROM Request
          WHERE RQID = @Rqid;
          
         SELECT @X = (
            SELECT @Rqid '@rqid'          
            ,'001' '@rqtpcode'
            ,'008' '@rqttcode'
            ,@RegnCode '@regncode'  
            ,@PrvnCode '@prvncode'
            FOR XML PATH('Request'), ROOT('Process')
         );
         EXEC INS_SEXP_P @X;             

         UPDATE Request
         SET SEND_EXPN = '002'
            ,SSTT_MSTT_CODE = 2
            ,SSTT_CODE = 2
         WHERE RQID = @Rqid;
         
         DECLARE @ExpnCode BIGINT
                ,@Qnty SMALLINT;
         SELECT @ExpnCode = s.EXPN_CODE
               ,@Qnty = s.TOTL_SESN 
           FROM Member_Ship m, [Session] s 
          WHERE m.RQRO_RQST_RQID = @Rqid 
            AND m.FIGH_FILE_NO = s.MBSP_FIGH_FILE_NO 
            AND m.RECT_CODE = s.MBSP_RECT_CODE 
            AND m.RWNO = s.MBSP_RWNO;
         
         DELETE Payment_Detail
          WHERE PYMT_RQST_RQID = @Rqid
            AND RQRO_RWNO = 1
            AND EXPN_CODE != @ExpnCode;          
         
         UPDATE Payment_Detail
            SET QNTY = @Qnty
          WHERE PYMT_RQST_RQID = @Rqid
            AND EXPN_CODE = @ExpnCode;
          
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
