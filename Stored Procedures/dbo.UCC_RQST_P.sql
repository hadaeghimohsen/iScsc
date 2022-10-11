SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UCC_RQST_P]
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
      
      DECLARE @StrtDate DATETIME
             ,@EndDate  DATETIME             
             ,@PrntCont SMALLINT
             ,@NumbMontOfer INT
             ,@NumbOfAttnMont INT
             ,@NumbOfAttnWeek INT
             ,@AttnDayType VARCHAR(3);
      SET @StrtDate = NULL;
      SET @EndDate = NULL;
      SET @PrntCont = 0;
      SET @NumbMontOfer = 0;
      SET @NumbOfAttnMont = 0;
      SET @NumbOfAttnWeek = 0;
      SET @AttnDayType = '001';
      
      SELECT @StrtDate = r.query('Member_Ship').value('(Member_Ship/@strtdate)[1]', 'DATETIME')
            ,@EndDate  = r.query('Member_Ship').value('(Member_Ship/@enddate)[1]',  'DATETIME')
            ,@PrntCont = r.query('Member_Ship').value('(Member_Ship/@prntcont)[1]', 'SMALLINT')
            ,@NumbMontOfer = r.query('Member_Ship').value('(Member_Ship/@numbmontofer)[1]', 'INT')            
            ,@NumbOfAttnMont = r.query('Member_Ship').value('(Member_Ship/@numbofattnmont)[1]', 'INT')
            ,@NumbOfAttnWeek = r.query('Member_Ship').value('(Member_Ship/@numbofattnweek)[1]', 'INT')
            ,@AttnDayTYpe = r.query('Member_Ship').value('(Member_Ship/@attndaytype)[1]', 'VARCHAR(3)')
        FROM @X.nodes('//Request_Row') Rqrv(r)
       WHERE r.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT') = @fileno;
      
      IF CAST(@StrtDate AS DATE) IN ('1900-01-01', '0001-01-01') OR CAST(@EndDate AS DATE) IN ('1900-01-01', '0001-01-01')
      BEGIN
         DECLARE @FgpbType VARCHAR(3);
         SELECT @FgpbType = FGPB_TYPE_DNRM
           FROM Fighter
          WHERE FILE_NO = @FileNo;
      
         IF @FgpbType = '005' --هنرجوی مهمان 
         BEGIN
            SET @StrtDate = GETDATE();
            SET @EndDate  = @StrtDate;
            SET @NumbMontOfer = 0;
            SET @NumbOfAttnMont = 1;
            SET @NumbOfAttnWeek = 1;
            SET @AttnDayType = CASE WHEN DATEPART(dw,GETDATE()) IN (1,3,5) THEN '001' ELSE '002' END
         END
         ELSE
         BEGIN
            SET @StrtDate = GETDATE();
            --SET @EndDate  = NULL;
            --SELECT @StrtDate = COALESCE (DATEADD(DAY, 1, END_DATE), GETDATE()) FROM Member_Ship m, Fighter F WHERE m.FIGH_FILE_NO = @FileNo AND m.RECT_CODE = '004' AND F.FILE_NO = m.FIGH_FILE_NO AND F.MBSP_RWNO_DNRM = M.RWNO;
            SET @EndDate = DATEADD(day, 30, @StrtDate);
         END
      END
      
      IF NOT EXISTS(SELECT * FROM Member_Ship WHERE RQRO_RQST_RQID = @Rqid AND RQRO_RWNO = @RqroRwno AND FIGH_FILE_NO = @FileNo AND RECT_CODE = '001')
         EXEC INS_MBSP_P @Rqid, @RqroRwno, @FileNo, '001', '001', @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, @NumbOfAttnWeek, @AttnDayType;
      ELSE
         EXEC UPD_MBSP_P @Rqid, @RqroRwno, @FileNo, '001', '001', @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, @NumbOfAttnWeek, @AttnDayType;
      
      GOTO NextFromRqrv;
      EndFetchRqrv:
      CLOSE C$RQRVUCC_RQST_P;
      DEALLOCATE C$RQRVUCC_RQST_P;          
	   -- اگر در ثبت موقت باشیم و برای نوع درخواست و متقاضی آیین نامه هزینه داری داشته باشیم درخواست را به فرم اعلام هزینه ارسال میکنیم            
      IF EXISTS(
         SELECT *
           FROM Request_Row Rr, Fighter F
          WHERE Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND Rr.RECD_STAT = '002'
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(@PrvnCode, @RegnCode, NULL, @RqtpCode, @RqttCode, NULL, NULL, F.Mtod_Code_Dnrm , F.Ctgy_Code_Dnrm)
            )
      )
         UPDATE Request
         SET SEND_EXPN = '002'
         WHERE RQID = @Rqid;
      ELSE
         UPDATE Request
         SET SEND_EXPN = '001'
         WHERE RQID = @Rqid;   

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
