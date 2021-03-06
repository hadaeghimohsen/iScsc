SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[SCV_MBSP_P] -- Speed Change Value
	-- Add the parameters for the stored procedure here
	@X XML	
AS
BEGIN
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @RegnCode VARCHAR(3),
	           @PrvnCode VARCHAR(3);
      DECLARE @FileNo BIGINT
             ,@ColumnName VARCHAR(100);   	
      
	   SELECT @FileNo     = @X.query('//Fighter').value('(Fighter/@fileno)[1]', 'BIGINT')
	         ,@ColumnName = @X.query('//Fighter').value('(Fighter/@columnname)[1]', 'VARCHAR(100)');
      
      IF @FileNo = 0 OR @FileNo IS NULL BEGIN RAISERROR(N'شماره پرونده برای هنرجو وارد نشده', 16, 1); RETURN; END
      SELECT @RegnCode = Regn_Code, @PrvnCode = Regn_Prvn_Code 
        FROM Fighter
       WHERE FILE_NO = @FileNo;
      
      DECLARE @Xt XML;
      SELECT @Xt = (
         SELECT 0 AS '@rqid'
               ,'027' AS '@rqtpcode'
               ,'004' AS '@rqttcode'
               ,(
                  SELECT @FileNo AS '@fileno'
                     FOR XML PATH('Request_Row'), TYPE
               )
             FOR XML PATH('Request'), ROOT('Process')
      );
      EXECUTE dbo.MBZ_NRQT_P @X = @Xt -- xml
      
      SELECT @Rqid = R.RQID
        FROM dbo.Request r, dbo.Request_Row Rr, dbo.Fighter f
       WHERE r.RQID = rr.RQST_RQID
         AND rr.FIGH_FILE_NO = f.FILE_NO
         AND r.RQID = f.RQST_RQID
         AND r.RQST_STAT = '001'
         AND r.RQTP_CODE = '027'
         AND r.RQTT_CODE = '004';

      SELECT @Xt = (
         SELECT @Rqid AS '@rqid'
               ,@PrvnCode AS '@prvncode'
               ,@RegnCode AS '@regncode'
               ,(
                  SELECT @FileNo AS '@fileno'
                     FOR XML PATH('Request_Row'), TYPE                     
               )
             FOR XML PATH('Request'), ROOT('Process')
      );
      EXECUTE dbo.MBZ_NSAV_P @X = @Xt -- xml
      COMMIT TRAN T1;
      RETURN 0;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      --PRINT @ErrorMessage;
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
      RETURN -1;
   END CATCH;   
END
GO
