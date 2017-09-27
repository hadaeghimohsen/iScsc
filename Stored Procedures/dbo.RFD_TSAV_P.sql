SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[RFD_TSAV_P]
	@X XML
AS
BEGIN
	DECLARE @AP BIT
       ,@AccessString VARCHAR(250);

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>183</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 183 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
	DECLARE @ErrorMessage NVARCHAR(MAX);

   BEGIN TRY
      BEGIN TRAN T1;
      
      DECLARE @Rqid BIGINT;
	          
	   SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT');      
      
      UPDATE Request
         SET RQST_STAT = '002'
       WHERE RQID = @Rqid;

      /* ثبت هزینه های استرداد شده درون جدول */
      UPDATE Request_Letter
         SET REC_STAT = '002'
       WHERE RQST_RQID = @Rqid;
       
      UPDATE Finance_Document
         SET REC_STAT = '002'
       WHERE RQRO_RQST_RQID = @Rqid;       
       
      COMMIT TRAN T1;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH
END
GO
