SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MCC_RQST_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	/*
	   شرایط ارسال داده ها مربوط به جدول درخواست
	   1 - درخواست جدید می باشد و ستون شماره درخواست خالی می باشد
	   2 - درخواست قبلا ثبت شده و ستون شماره درخواست خالی نمی باشد
	*/
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>110</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 110 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>111</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 111 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>112</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 112 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

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
	   
	   IF @FileNo IS NULL OR @FileNo = 0 BEGIN RAISERROR(N'شماره پرونده هنرجو وارد نشده',16 ,1); RETURN;  END
	   IF @RqttCode IS NULL OR LEN(@RqttCode) <> 3 BEGIN RAISERROR(N'نوع متقاضی رو مشخص نکرده اید', 16, 1); RETURN; END
      
      SELECT @PrvnCode = REGN_PRVN_CODE, @RegnCode = REGN_CODE
        FROM Fighter  
       WHERE FILE_NO = @FileNo;
       
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



      DECLARE C$RQRV CURSOR FOR
         SELECT r.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT')
           FROM @X.nodes('//Request_Row')Rr(r);
      
      OPEN C$RQRV;
      NextFromRqrv:
      FETCH NEXT FROM C$RQRV INTO @FileNo;
      
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
      
      DECLARE @StrtDate DATE
             ,@EndDate  DATE;
      
      SELECT @StrtDate = r.query('Member_Ship').value('(Member_Ship/@strtdate)[1]', 'DATE')
            ,@EndDate  = r.query('Member_Ship').value('(Member_Ship/@enddate)[1]', 'DATE')
        FROM @X.nodes('//Request_Row') Rqrv(r)
       WHERE r.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT') = @fileno;
      
      IF @StrtDate = '1900-01-01' OR @EndDate = '1900-01-01'
      BEGIN
         DECLARE @FgpbType VARCHAR(3);
         SELECT @FgpbType = FGPB_TYPE_DNRM
           FROM Fighter
          WHERE FILE_NO = @FileNo;
      
         IF @FgpbType = '004' --هنرجوی مهمان 
         BEGIN
            RAISERROR(N'هنرجویان مهمان نمی توانند از خدمات کارت عضویت سبک در این باشگاه استفاده نمایند.', 16, 1);
         END
         ELSE
         BEGIN
            SET @StrtDate = GETDATE();
            SET @EndDate = DATEADD(DAY, 364, @StrtDate);
         END
      END
      
      IF NOT EXISTS(SELECT * FROM Member_Ship WHERE RQRO_RQST_RQID = @Rqid AND RQRO_RWNO = @RqroRwno AND FIGH_FILE_NO = @FileNo AND RECT_CODE = '001')
         EXEC INS_MBSP_P @Rqid, @RqroRwno, @FileNo, '001', '002', @StrtDate, @EndDate, 0, 0, 0, 0, NULL;
      ELSE
         EXEC UPD_MBSP_P @Rqid, @RqroRwno, @FileNo, '001', '002', @StrtDate, @EndDate, 0, 0, 0, 0, NULL;
      
      GOTO NextFromRqrv;
      EndFetchRqrv:
      CLOSE C$RQRV;
      DEALLOCATE C$RQRV;   
             
	   -- اگر در ثبت موقت باشیم و برای نوع درخواست و متقاضی آیین نامه هزینه داری داشته باشیم درخواست را به فرم اعلام هزینه ارسال میکنیم            
            IF EXISTS(
         SELECT *
           FROM Request_Row Rr, Fighter F
          WHERE Rr.FIGH_FILE_NO = F.FILE_NO
            AND Rr.RQST_RQID = @Rqid
            AND EXISTS(
               SELECT *
                 FROM dbo.VF$All_Expense_Detail(
                  @PrvnCode, 
                  @RegnCode, 
                  NULL, 
                  @RqtpCode, 
                  @RqttCode, 
                  NULL, 
                  NULL, 
                  F.Mtod_Code_Dnrm , 
                  F.Ctgy_Code_Dnrm)
            )
      )
      BEGIN
         IF NOT EXISTS(SELECT * FROM Request WHERE RQID = @Rqid AND SSTT_MSTT_CODE = 2 AND SSTT_CODE = 2)
         BEGIN
            SELECT @X = (
               SELECT @Rqid '@rqid'          
                     ,@RqtpCode '@rqtpcode'
                     ,@RqttCode '@rqttcode'
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
        END
      END
      ELSE
      BEGIN
         UPDATE Request
            SET SEND_EXPN = '001'
               ,SSTT_MSTT_CODE = 1
               ,SSTT_CODE = 1
          WHERE RQID = @Rqid;                
         
         DELETE Payment_Detail 
          WHERE PYMT_RQST_RQID = @Rqid;          
         DELETE Payment
          WHERE RQST_RQID = @Rqid;            
      END  


      COMMIT TRAN T1;
   END TRY
   BEGIN CATCH
      IF (SELECT CURSOR_STATUS('local','C$RQRV')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$RQRV')) > -1
         BEGIN
          CLOSE C$RQRV
         END
       DEALLOCATE C$RQRV
      END
      
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH; 
END
GO
