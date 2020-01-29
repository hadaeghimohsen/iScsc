SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GRN_TRQT_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN

	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T_GRN_TRQT_P;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @RqtpCode VARCHAR(3) = '031',
	           @RqttCode VARCHAR(3) = '004',
	           @RegnCode VARCHAR(3),
	           @PrvnCode VARCHAR(3);
   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT');
	         --,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	         --,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
	         --,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
	         --,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)');
      
      --IF @RegnCode IS NULL OR @PrvnCode IS NULL 
      SELECT TOP 1 @RegnCode = CODE
                  ,@PrvnCode = PRVN_CODE
        FROM Region;
        
      --IF @RqttCode IS NULL OR LEN(@RqttCode) < 3
      --   SET @RqttCode = '003';
         
      -- ثبت شماره درخواست 
      IF @Rqid IS NULL OR @Rqid = 0
      BEGIN
         EXEC dbo.INS_RQST_P
            @PrvnCode,
            @RegnCode,
            NULL,
            @RqtpCode,
            @RqttCode,
            NULL,
            NULL,
            NULL,
            @Rqid OUT;      
      END
      ELSE
      BEGIN
         EXEC UPD_RQST_P
            @Rqid,
            @PrvnCode,
            @RegnCode,
            @RqtpCode,
            @RqttCode,
            NULL,
            NULL,
            NULL;            
      END
      DECLARE @FileNo BIGINT;
      SELECT @FileNo = @X.query('//Fighter').value('(Fighter/@fileno)[1]', 'BIGINT');
      
      -- ثبت شماره پرونده 
      IF @FileNo IS NULL OR @FileNo = 0
      BEGIN
         EXEC dbo.INS_FIGH_P @Rqid, @PrvnCode, @RegnCode, @FileNo OUT;
      END
      
      -- ثبت ردیف درخواست 
      DECLARE @RqroRwno SMALLINT;
      SELECT @RqroRwno = Rwno
         FROM Request_Row
         WHERE RQST_RQID = @Rqid
           AND FIGH_FILE_NO = @FileNo;
           
      IF @RqroRwno IS NULL
      BEGIN
         EXEC INS_RQRO_P
            @Rqid
           ,@FileNo
           ,@RqroRwno OUT;
      END
                
      COMMIT TRAN T_GRN_TRQT_P;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T_GRN_TRQT_P;
   END CATCH;  
END
GO
