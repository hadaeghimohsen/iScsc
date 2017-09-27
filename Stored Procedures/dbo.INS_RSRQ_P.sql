SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_RSRQ_P]   
   @X XML
AS 
BEGIN
   BEGIN TRY
   BEGIN TRAN INS_RSRQ_P_T      
      DECLARE @RqroRqstRqid BIGINT
             ,@RqroRwno SMALLINT
             ,@ResnRqtpCode VARCHAR(3)
             ,@ResnRwno SMALLINT
             ,@Rwno SMALLINT
             ,@OthrDesc NVARCHAR(250);
             
      SELECT @RqroRqstRqid = @X.query('Request').value('(Request/@rqid)[1]', 'BIGINT')
            ,@RqroRwno = @X.query('Request/Request_Row').value('(Request_Row/@rwno)[1]', 'SMALLINT')
            ,@ResnRqtpCode = @X.query('Request/Request_Row/Reason_Request').value('(Reason_Request/@resnrqtpcode)[1]', 'VARCHAR(3)')
            ,@ResnRwno = @X.query('Request/Request_Row/Reason_Request').value('(Reason_Request/@resnrwno)[1]', 'SMALLINT')
            ,@OthrDesc = @X.query('Request/Request_Row/Reason_Request').value('(Reason_Request/@othrdesc)[1]', 'NVARCHAR(250)');
            
      IF @ResnRwno = 0 RAISERROR(N'نوع دلیل خود را وارد کنید', 16, 1)
      
      INSERT INTO Reason_Request (RESN_RQTP_CODE, RESN_RWNO, RQRO_RQST_RQID, RQRO_RWNO, RWNO, OTHR_DESC)
      VALUES (@ResnRqtpCode, @ResnRwno, @RqroRqstRqid, @RqroRwno, 0, @OthrDesc); 
         
      COMMIT TRAN INS_RSRQ_P_T;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN INS_RSRQ_P_T;
   END CATCH
END
GO
