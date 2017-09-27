SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[UPD_RSRQ_P]   
   @X XML
AS 
BEGIN
   BEGIN TRY
   BEGIN TRAN UPD_RSRQ_P_T      
      DECLARE @RqroRqstRqid BIGINT
             ,@RqroRwno SMALLINT
             ,@ResnRqtpCode VARCHAR(3)
             ,@ResnRwno SMALLINT
             ,@Rwno SMALLINT
             ,@OthrDesc NVARCHAR(250);
             
      SELECT @RqroRqstRqid = @X.query('Request').value('(Request/@rqid)[1]', 'BIGINT')
            ,@RqroRwno = @X.query('Request/Request_Row').value('(Request_Row/@rwno)[1]', 'SMALLINT')
            ,@ResnRwno = @X.query('Request/Request_Row/Reason_Request').value('(Reason_Request/@resnrwno)[1]', 'SMALLINT')
            ,@Rwno = @X.query('Request/Request_Row/Reason_Request').value('(Reason_Request/@rwno)[1]', 'SMALLINT')
            ,@OthrDesc = @X.query('Request/Request_Row/Reason_Request').value('(Reason_Request/@othrdesc)[1]', 'NVARCHAR(250)');
            
      
      UPDATE Reason_Request
         SET OTHR_DESC = @OthrDesc
       WHERE RQRO_RQST_RQID = @RqroRqstRqid
         AND RQRO_RWNO = @RqroRwno
         AND RWNO = @Rwno;
         
      COMMIT TRAN UPD_RSRQ_P_T;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN UPD_RSRQ_P_T;
   END CATCH
END
GO
