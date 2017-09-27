SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MBS_RQST_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	/*
	   شرایط ارسال داده ها مربوط به جدول درخواست
	   1 - درخواست جدید می باشد و ستون شماره درخواست خالی می باشد
	   2 - درخواست قبلا ثبت شده و ستون شماره درخواست خالی نمی باشد
	*/
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @RqstRqid BIGINT,
	           @RqtpCode VARCHAR(3),
	           @RqttCode VARCHAR(3),
	           @RegnCode VARCHAR(3),
	           @PrvnCode VARCHAR(3);
   	DECLARE @FileNo BIGINT;
   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqstRqid = @X.query('//Request').value('(Request/@rqstrqid)[1]', 'BIGINT')
	         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
	         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
	         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)')
	         ,@FileNo   = @X.query('//Request_Row').value('(Request_Row/@fileno)[1]', 'BIGINT');
	   
	   SELECT @RegnCode = REGN_CODE
	         ,@PrvnCode = REGN_PRVN_CODE
	     FROM Fighter WHERE FILE_NO = @FileNo;      
               
      /* ثبت شماره درخواست */
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
         UPDATE Request
            SET RQST_RQID = @RqstRqid
          WHERE RQID =  @Rqid;
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

      DECLARE C$RQRVUCC_RQST_P CURSOR FOR
         SELECT r.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT')
           FROM @X.nodes('//Request_Row')Rr(r);
      
      OPEN C$RQRVUCC_RQST_P;
      NextFromRqrv:
      FETCH NEXT FROM C$RQRVUCC_RQST_P INTO @FileNo;
      
      IF @@FETCH_STATUS <> 0
         GOTO EndFetchRqrv;
      
            /* ثبت ردیف درخواست */
      DECLARE @RqroRwno SMALLINT;
      SET @RqroRwno = NULL;
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
      
      DECLARE @SesnMeetDate DATETIME
             ,@StrtDate DATE
             ,@EndDate DATE
             ,@TotlSesn INT
             ,@RemindSesn INT
             ,@SmsSend VARCHAR(3);
      SET @SesnMeetDate = NULL;
      
      SELECT @StrtDate = MBSP_STRT_DATE
            ,@EndDate = MBSP_END_DATE
            ,@TotlSesn = m.NUMB_OF_ATTN_MONT
        FROM dbo.Fighter F, dbo.Member_Ship m
       WHERE F.FILE_NO = m.FIGH_FILE_NO
         AND F.MBSP_RWNO_DNRM = m.RWNO
         AND m.RECT_CODE = '004'
         AND F.FILE_NO = @FileNo;
      
      SELECT @RemindSesn = @TotlSesn - (SELECT COUNT(*) FROM dbo.Member_Ship WHERE FIGH_FILE_NO = @FileNo AND RECT_CODE = '004' AND TYPE = '006' AND SESN_MEET_TYPE IN ('001', '003'));
     
      SELECT @SesnMeetDate = r.query('Member_Ship').value('(Member_Ship/@sesnmeetdate)[1]', 'DATETIME')
            ,@SmsSend = r.query('Member_Ship').value('(Member_Ship/@smssend)[1]', 'VARCHAR(3)')
        FROM @X.nodes('//Request_Row') Rqrv(r)
       WHERE r.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT') = @fileno;
      
      IF NOT EXISTS(SELECT * FROM Member_Ship WHERE RQRO_RQST_RQID = @Rqid AND RQRO_RWNO = @RqroRwno AND FIGH_FILE_NO = @FileNo AND RECT_CODE = '001')
         EXEC INS_MBSP_P @Rqid, @RqroRwno, @FileNo, '001', '006', @StrtDate, @EndDate, 1, 0, @TotlSesn, @RemindSesn, NULL;
      ELSE
         EXEC UPD_MBSP_P @Rqid, @RqroRwno, @FileNo, '001', '006', @StrtDate, @EndDate, 1, 0, @TotlSesn, @RemindSesn, NULL;
      
      UPDATE dbo.Member_Ship
         SET SESN_MEET_DATE = @SesnMeetDate
            ,SESN_MEET_TYPE = '000'
            ,SMS_SEND = @SmsSend
       WHERE RQRO_RQST_RQID = @Rqid
         AND FIGH_FILE_NO = @FileNo
         AND RECT_CODE = '001'
         AND TYPE = '006';
      
      GOTO NextFromRqrv;
      EndFetchRqrv:
      CLOSE C$RQRVUCC_RQST_P;
      DEALLOCATE C$RQRVUCC_RQST_P;          

      COMMIT TRAN T1;
      RETURN 0;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
      RETURN -1;
   END CATCH; 
END
GO
