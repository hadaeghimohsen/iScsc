SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[TST_RQST_F]
	@X XML
AS
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>74</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 74 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>75</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 75 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>76</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 76 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid BIGINT
	          ,@RqtpCode VARCHAR(3)
	          ,@RqttCode VARCHAR(3)
	          ,@RegnCode VARCHAR(3)
	          ,@PrvnCode VARCHAR(3);
      DECLARE @FileNo BIGINT;
      
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
	         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
	         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)')
	         ,@FileNo   = @X.query('//Request_Row').value('(Request_Row/@fileno)[1]', 'BIGINT');

      IF @FileNo = 0 OR @FileNo IS NULL BEGIN RAISERROR(N'شماره پرونده برای هنرجو وارد نشده', 16, 1); RETURN; END
      IF LEN(@RqttCode) <> 3 BEGIN RAISERROR(N'نوع متقاضی برای درخواست وارد نشده', 16, 1); RETURN; END
      
      SELECT @RegnCode = Regn_Code, @PrvnCode = Regn_Prvn_Code 
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
      END
/*      ELSE
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
*/
      DECLARE @XHandle INT;
      EXEC SP_XML_PREPAREDOCUMENT @XHandle OUTPUT, @X;
      
      DECLARE C$Fighter CURSOR FOR
         SELECT *
         FROM OPENXML(@XHandle, '//Request_Row')
         WITH (
            File_No      BIGINT      '@fileno'
           ,Crtf_Date    DATE        'Test/@crtfdate'
           ,Crtf_Numb    NVARCHAR(20)'Test/@crtfnumb'
           ,Mtod_Code    BIGINT      'Test/@mtodcode'
           ,Ctgy_Code    BIGINT      'Test/@ctgycode'
           ,Test_Date    DATE        'Test/@testdate'
           ,Glob_Code    VARCHAR(20) 'Test/@globcode'
           ,Rslt         VARCHAR(3)  'Test/@rslt'
         );
      
      DECLARE @CrtfDate DATE
             ,@CrtfNumb NVARCHAR(20)
             ,@MtodCode BIGINT
             ,@CtgyCode BIGINT
             ,@TestDate DATE
             ,@GlobCode VARCHAR(20)
             ,@Rslt     VARCHAR(3);
      
      OPEN C$Fighter;
      NextFetchFighter:
      FETCH NEXT FROM C$Fighter INTO @FileNo, @CrtfDate, @CrtfNumb, @MtodCode, @CtgyCode, @TestDate, @GlobCode, @Rslt;
      
      IF @@FETCH_STATUS <> 0
         GOTO EndFetchFighter;
      
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
      
      IF @MtodCode IS NULL OR @CtgyCode IS NULL
         GOTO NextFetchFighter;

      -- کاربر نمی تواند سبک هنرجو را عوض کند
      IF EXISTS(SELECT * FROM Fighter WHERE FILE_NO = @FileNo AND MTOD_CODE_DNRM <> @MtodCode)
      BEGIN
         IF @MtodCode <> 0 
            RAISERROR ( N'نمی توانید سبک دیگری را وارد کنید', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         ELSE 
            SELECT @MtodCode = MTOD_CODE_DNRM
                  ,@CtgyCode = (SELECT CODE FROM Category_Belt WHERE MTOD_CODE = F.MTOD_CODE_DNRM AND ORDR = (SELECT ORDR + 1 FROM Category_Belt WHERE MTOD_CODE = F.MTOD_CODE_DNRM AND CODE = F.CTGY_CODE_DNRM))
              FROM Fighter F
             WHERE FILE_NO = @FileNo;
      END
      
      -- چک کردن ترتیب رده کمربندی
      DECLARE @OldOrdr SMALLINT
             ,@NewOrdr SMALLINT;
      
      SELECT @NewOrdr = ORDR
        FROM Category_Belt c
       WHERE c.CODE = @CtgyCode
         AND c.MTOD_CODE = @MtodCode;
      
      SELECT @OldOrdr = ORDR
        FROM Category_Belt c, Fighter F
       WHERE c.CODE = f.CTGY_CODE_DNRM
         AND c.MTOD_CODE = F.MTOD_CODE_DNRM
         AND f.FILE_NO = @FileNo;
      
      IF @NewOrdr - 1 <> @OldOrdr
      BEGIN
         SET @ErrorMessage = N'رده کمربندی برای مشترک ' + CAST(@fileno AS VARCHAR(20)) + N' اشتباه وارد شده. ترتیب رده ها درست انتخاب نشده';
         RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      END
      
      -- چک کردن فاصله زمانی رده های کمربندی
      DECLARE @ActnDate DATETIME
             ,@CyclDate DATETIME
             ,@Cycl     INT;
      
      SELECT @ActnDate = TEST_DATE 
        FROM Test 
       WHERE FIGH_FILE_NO = @FileNo 
         AND RECT_CODE = '004' 
         AND RWNO = (SELECT MAX(RWNO)
                       FROM Test
                      WHERE FIGH_FILE_NO = @FileNo
                        AND RECT_CODE = '004');

      IF @ActnDate IS NULL
      BEGIN
         SELECT @ActnDate = MIN(P.CRET_DATE)
           FROM Fighter F, Fighter_Public P
          WHERE F.FILE_NO = P.FIGH_FILE_NO
            AND F.MTOD_CODE_DNRM = P.MTOD_CODE
            AND F.CTGY_CODE_DNRM = P.CTGY_CODE
            AND P.RECT_CODE      = '004';
      END      
      
      SELECT @Cycl = dc.CYCL
        FROM Method m, Category_Belt c1, Category_Belt c2, Distance_Category dc, Fighter F
       WHERE m.CODE = c1.MTOD_CODE
         AND m.CODE = c2.MTOD_CODE
         AND m.CODE = f.MTOD_CODE_DNRM         
         AND c1.CODE = dc.FRST_CTGY_CODE
         AND c2.CODE = dc.SCND_CTGY_CODE         
         AND c1.CODE = f.CTGY_CODE_DNRM
         AND c2.CODE = @CtgyCode;
      
      IF @Cycl IS NULL
         RAISERROR(N'بازه زمانی برای رده های کمربند درست تعریف نشده یا بعد از کمربند فعلی کمربندی دیگر وجود ندارد', 16, 1);
      
      SET @CyclDate = DATEADD(MONTH, @Cycl * -1, GETDATE());
      SET @Cycl     = DATEDIFF(DAY, @ActnDate, @CyclDate);
      IF @Cycl < 0 
      BEGIN
         SET @ErrorMessage = N'زمان باقیمانده برای رده کمربندی جدید ' + CAST(@Cycl * -1 AS VARCHAR(10)) + N' روز می باشد' ;
         RAISERROR(@ErrorMessage, 16, 1);
      END
      
      IF NOT EXISTS(
         SELECT *
           FROM Test
          WHERE FIGH_FILE_NO = @FileNo
            AND RQRO_RQST_RQID = @Rqid
            AND RECT_CODE = '001'
      )
      BEGIN
         EXEC INS_TEST_P 
            @Rqid
           ,@RqroRwno
           ,@FileNo
           ,'001'
           ,@CrtfDate
           ,@CrtfNumb
           ,@TestDate
           ,@Rslt
           ,@MtodCode
           ,@CtgyCode
           ,@GlobCode; 
      END
      ELSE
      BEGIN
         EXEC UPD_TEST_P 
            @Rqid
           ,@RqroRwno
           ,@FileNo
           ,'001'
           ,@CrtfDate
           ,@CrtfNumb
           ,@TestDate
           ,@Rslt
           ,@MtodCode
           ,@CtgyCode
           ,@GlobCode; 
      END     
      
      GOTO NextFetchFighter;
         
      EndFetchFighter:
      CLOSE C$Fighter;
      DEALLOCATE C$Fighter;
         
	   EXEC SP_XML_REMOVEDOCUMENT @XHandle;
	   
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
 	   IF (SELECT CURSOR_STATUS('local','C$Fighter')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Fighter')) > -1
         BEGIN
          CLOSE C$Fighter
         END
       DEALLOCATE C$Fighter
      END

      /*
      SELECT
          ERROR_NUMBER() AS ErrorNumber
         ,ERROR_SEVERITY() AS ErrorSeverity
         ,ERROR_STATE() AS ErrorState
         ,ERROR_PROCEDURE() AS ErrorProcedure
         ,ERROR_LINE() AS ErrorLine
         ,ERROR_MESSAGE() AS ErrorMessage;
*/
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN;
	END CATCH;
END
GO
