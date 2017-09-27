SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MBC_TRQT_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT,
	           @RqstRqid BIGINT,
	           @RqstDesc NVARCHAR(1000),
	           @RqtpCode VARCHAR(3),
	           @RqttCode VARCHAR(3),
	           @RegnCode VARCHAR(3),
	           @PrvnCode VARCHAR(3);
      
      DECLARE @FileNo BIGINT
             ,@MtodCode BIGINT
             ,@CtgyCode BIGINT
             ,@CbmtCode BIGINT;
   	
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqstRqid = @X.query('//Request').value('(Request/@rqstrqid)[1]', 'BIGINT')
	         ,@RqstDesc = @X.query('//Request').value('(Request/@rqstdesc)[1]', 'NVARCHAR(1000)')
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
         UPDATE Request
            SET RQST_RQID = @RqstRqid
               ,RQST_DESC = @RqstDesc
          WHERE RQID =  @Rqid;
      END
      ELSE
      BEGIN
         UPDATE dbo.Request
            SET SSTT_MSTT_CODE = 1
               ,SSTT_CODE = 1
          WHERE RQID = @Rqid;

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
      
      DECLARE @StrtDate DATE
             ,@EndDate  DATE
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
      
      SELECT @StrtDate = r.query('Member_Ship').value('(Member_Ship/@strtdate)[1]', 'DATE')
            ,@EndDate  = r.query('Member_Ship').value('(Member_Ship/@enddate)[1]',  'DATE')
            ,@PrntCont = r.query('Member_Ship').value('(Member_Ship/@prntcont)[1]', 'SMALLINT')
            ,@NumbMontOfer = r.query('Member_Ship').value('(Member_Ship/@numbmontofer)[1]', 'INT')            
            ,@NumbOfAttnMont = r.query('Member_Ship').value('(Member_Ship/@numbofattnmont)[1]', 'INT')
            ,@NumbOfAttnWeek = r.query('Member_Ship').value('(Member_Ship/@numbofattnweek)[1]', 'INT')
            ,@AttnDayType = r.query('Member_Ship').value('(Member_Ship/@attndaytype)[1]', 'VARCHAR(3)')
            ,@MtodCode = r.query('Fighter').value('(Fighter/@mtodcodednrm)[1]', 'BIGINT')
            ,@CtgyCode = r.query('Fighter').value('(Fighter/@ctgycodednrm)[1]', 'BIGINT')
            ,@CbmtCode = r.query('Fighter').value('(Fighter/@cbmtcodednrm)[1]', 'BIGINT')
        FROM @X.nodes('//Request_Row') Rqrv(r)
       WHERE r.query('.').value('(Request_Row/@fileno)[1]', 'BIGINT') = @fileno;
      
      -- 1395/06/17 * برای ثبت ابتدایی درخواست تمدید
      IF ISNULL(@MtodCode, 0) = 0 OR ISNULL(@CtgyCode, 0) = 0
      BEGIN
         SELECT @MtodCode = MTOD_CODE_DNRM
               ,@CtgyCode = CTGY_CODE_DNRM
           FROM Fighter
          WHERE FILE_NO = @FileNo;
      END
      -- 1395/06/17 * برای مشخص کردن نرخ هزینه و ساعت کلاسی مربی
      ELSE
      BEGIN
         UPDATE dbo.Fighter
            SET MTOD_CODE_DNRM = @MtodCode
               ,CTGY_CODE_DNRM = @CtgyCode
               ,CBMT_CODE_DNRM = @CbmtCode
          WHERE FILE_NO = @FileNo;
         
         DELETE dbo.Payment_Discount
          WHERE PYMT_RQST_RQID = @Rqid
            AND EXPN_CODE IS NOT NULL;
      END;
      
      IF @StrtDate IN ('1900-01-01', '0001-01-01') OR @EndDate IN ('1900-01-01', '0001-01-01')
      BEGIN
         /*DECLARE @FgpbType VARCHAR(3);
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
         ELSE*/
         BEGIN
            SET @StrtDate = GETDATE();
            -- 1395/07/23 * تاریخ آخرین جلسه با مربی باید با تاریخ آخرین جلسه باشگاه هماهنگی داشته باشد
            /*SELECT @EndDate = Mbsp_End_Date
              FROM Fighter
             WHERE FILE_No = @FileNo;*/
            SET @EndDate = DATEADD(DAY, 29, @StrtDate);
         END
      END
      /*ELSE
      BEGIN
         IF EXISTS (
            SELECT * 
              FROM Fighter 
             WHERE File_No = @FileNo
               AND ( 
                     CAST(@StrtDate AS DATE) < MBSP_STRT_DATE OR
                     CAST(@EndDate AS DATE) > MBSP_END_DATE
                   )               
         )
         BEGIN
            RAISERROR (N'تاریخ جلسه خصوصی با مربی برای هنرجو درست وارد نشده. یا تاریخ شروع از تاریخ شروع تمدید باشگاه کوچکتر می باشد یا تاریخ پایان از تاریخ پایان تمدید باشگاه بزرگتر می باشد', 16, 1);
            RETURN;
         END         
      END*/
      
      IF NOT EXISTS(SELECT * FROM Member_Ship WHERE RQRO_RQST_RQID = @Rqid AND RQRO_RWNO = @RqroRwno AND FIGH_FILE_NO = @FileNo AND RECT_CODE = '001')
      BEGIN
         -- 1395/07/13 * بارگذاری آخرین اطلاعات
         SELECT @NumbOfAttnMont = M.NUMB_OF_ATTN_MONT
               ,@NumbOfAttnWeek = M.NUMB_OF_ATTN_WEEK
               ,@NumbMontOfer = ISNULL(@NumbMontOfer, NUMB_MONT_OFER)
               --,@EndDate = DATEADD(DAY, NUMB_OF_DAYS_DNRM, @StrtDate)
           FROM dbo.Fighter F, dbo.Member_Ship M
          WHERE F.FILE_NO = M.FIGH_FILE_NO
            AND F.MBCO_RWNO_DNRM = M.RWNO
            AND M.RECT_CODE = '004'
            AND F.FILE_NO = @FileNo;
            
         EXEC INS_MBSP_P @Rqid, @RqroRwno, @FileNo, '001', '003', @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, @NumbOfAttnWeek, @AttnDayType;
      END
      ELSE
         EXEC UPD_MBSP_P @Rqid, @RqroRwno, @FileNo, '001', '003', @StrtDate, @EndDate, @PrntCont, @NumbMontOfer, @NumbOfAttnMont, @NumbOfAttnWeek, @AttnDayType;
      
      GOTO NextFromRqrv;
      EndFetchRqrv:
      CLOSE C$RQRVUCC_RQST_P;
      DEALLOCATE C$RQRVUCC_RQST_P;          
	   BEGIN                
          -- اگر در ثبت موقت باشیم و برای نوع درخواست و متقاضی آیین نامه هزینه داری داشته باشیم درخواست را به فرم اعلام هزینه ارسال میکنیم            
          IF EXISTS(
            SELECT *
              FROM dbo.VF$All_Expense_Detail(@PrvnCode, @RegnCode, NULL, @RqtpCode, @RqttCode, NULL, NULL, @MtodCode, @CtgyCode)
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
            ELSE
            BEGIN
                 -- 1395/06/17 * اضافه شدن بابت محاسبه نرخ جدید
                 UPDATE Request
                    SET SEND_EXPN = '001'
                       ,SSTT_MSTT_CODE = 1
                       ,SSTT_CODE = 1
                  WHERE RQID = @Rqid;                

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
                --          
                
                DECLARE @Qnty SMALLINT;
             
                SELECT @Qnty = NUMB_OF_MONT_DNRM - ISNULL(NUMB_MONT_OFER, 0)
                  FROM dbo.Member_Ship
                 WHERE RQRO_RQST_RQID = @Rqid
                   AND RQRO_RWNO = @RqroRwno;
                
                IF @Qnty <= 0
                BEGIN
                   RAISERROR(N'تعداد ماه های تخفیف بیشتر از حد مجاز می باشد، لطفا اصلاح و دوباره امتحان کنید.', 16, 1);
                END
                
                UPDATE dbo.Payment_Detail
                   SET QNTY = @Qnty
                 WHERE PYMT_RQST_RQID = @Rqid
                   AND RQRO_RWNO = @RqroRwno
                   AND ISNULL(ADD_QUTS, '001') = '001';  
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
      END
      
      -- 1395/07/25 * اضافه شدن گزینه ای برای بررسی آیین نامه درآمد که باید تمامی فرآیند ها از آن استفاده کنند
      IF @RqttCode = '001' AND 
         NOT EXISTS(
            SELECT *
            FROM dbo.Payment
            WHERE RQST_RQID = @Rqid
         )
      BEGIN
         RAISERROR(N'برای درخواستهایی که متقاضی آن هنرجو می باشد بایستی هزینه محاسبه گردد که اینجا برای هنرجو سیستم نتواسته محاسبه رو به درستی انجام دهد. لطفا آیین نامه درآمد خود را چک کنید.', 16, 1);
         RETURN;
      END;

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
