SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CNCL_PYMT_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION [T$CNCL_PYMT_P]
	DECLARE @Rqid BIGINT
          ,@RqstRqid BIGINT
          ,@OrginRqid BIGINT
          ,@PrvnCode VARCHAR(3)
          ,@RegnCode VARCHAR(3)
          ,@CnclType VARCHAR(3);
          
	SELECT @RqstRqid = @x.query('Payment').value('(Payment/@rqid)[1]', 'BIGINT'),
	       @CnclType = @x.query('Payment').value('(Payment/@cncltype)[1]', 'VARCHAR(3)');		       
	
	-- ابطال عادی
	IF @CnclType = '001'
	BEGIN
	   DECLARE @AP BIT
             ,@AccessString VARCHAR(250);
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>243</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 243 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END
   END
   -- صورتحساب اصلاحی
   ELSE IF @CnclType = '002'   
   BEGIN
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>244</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 244 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END
   END
   -- ابطال بدون بازگشت
   ELSE IF @CnclType = '003'
   BEGIN
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>246</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 246 سطوح امینتی', -- Message text.
                     16, -- Severity.
                     1 -- State.
                    );
         RETURN;
      END
   END
   
   -- ابطال دوره های بایگانی شده
   ELSE IF EXISTS(
      SELECT *
        FROM dbo.Request r, dbo.Member_Ship m
       WHERE r.RQID = m.RQRO_RQST_RQID
         AND m.RECT_CODE = '004'
         AND r.RQID = @RqstRqid
         AND NOT (
             CAST(GETDATE() AS DATE) BETWEEN m.STRT_DATE AND m.END_DATE AND 
             (m.NUMB_OF_ATTN_MONT = 0 OR m.NUMB_OF_ATTN_MONT > m.SUM_ATTN_MONT_DNRM)
         )
   )
   BEGIN
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>247</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 247 سطوح امینتی', -- Message text.
                     16, -- Severity.
                     1 -- State.
                    );
         RETURN;
      END
   END
	
	SET @OrginRqid = @RqstRqid;
	
	-- بدست آوردن اطلاعات درخواست مربوط به پرداختی
	-- این گزینه برای درخواست تمدید دوره اولیه بابت ثبت نام نوشته شده است
	IF EXISTS(
	   SELECT * 
	     FROM dbo.Request r1, dbo.Request r2
	    WHERE r1.RQID = @RqstRqid 
	      AND r1.RQTP_CODE = '009'
	      AND r1.RQTT_CODE = '004'
	      AND r1.RQST_RQID = r2.RQID
	      AND r2.RQTT_CODE = '001' 
	      AND r2.RQTP_CODE = '001'
	)
	BEGIN
	   SELECT @RqstRqid = RQST_RQID
	     FROM dbo.Request
	    WHERE RQID = @RqstRqid;
	END;
	
	-- بررسی اینکه صورتحساب قبلا ابطال نشده باشد
	IF EXISTS (SELECT * FROM dbo.Payment WHERE RQST_RQID = @RqstRqid AND PYMT_STAT = '002')
	BEGIN
	   RAISERROR ( N'صورتحساب قبلا ابطال شده است', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
	END;
	
	-- بدست اوردن اطلاعات ناحیه
	SELECT @PrvnCode = REGN_PRVN_CODE
	      ,@RegnCode = REGN_CODE
	  FROM dbo.Request
	 WHERE RQID = @RqstRqid;
	
	DECLARE @RqtpCode VARCHAR(3) = CASE @CnclType WHEN '001' THEN '029' WHEN '002' THEN '030' WHEN '003' THEN '032' END;
	
	-- ثبت شماره درخواست 
   IF @Rqid IS NULL OR @Rqid = 0
   BEGIN
      EXEC dbo.INS_RQST_P
         @PrvnCode,
         @RegnCode,
         NULL,
         @RqtpCode,
         '004',
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
         '004',
         NULL,
         NULL,
         NULL;            
   END
	
	-- بدست آوردن شماره پرونده مشتری
   DECLARE @FileNo BIGINT;
   SELECT @FileNo = FIGH_FILE_NO
     FROM dbo.Request_Row
    WHERE RQST_RQID = @RqstRqid;
    
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
	
	-- ایا درخواست ثبت نام یا تمدید میباشد
	IF EXISTS(SELECT * FROM dbo.Request WHERE RQID = @RqstRqid AND RQTP_CODE IN ('001', '009'))
	BEGIN 
	   -- پیدا کردن درخواست مربوط به جدول دوره متصل 	   
	   /*IF EXISTS(SELECT * FROM dbo.Request WHERE RQID = @RqstRqid AND RQTT_CODE = '001' AND RQTP_CODE = '001')
	      SELECT @RqstRqid = RQID
	        FROM dbo.Request
	       WHERE RQST_RQID = @RqstRqid
	         AND RQTP_CODE = '009';*/
      
      IF EXISTS(SELECT * FROM dbo.Request WHERE RQID = @RqstRqid AND RQTP_CODE = '001' AND RQTT_CODE = '001')
      BEGIN
         -- در این قسمت هم میتوانیم شماره ردیف شماره "یک" مورد خطاب قرار بدهیم این گزینه برای سرعت عمل بیشتر می باشد
         -- غیرفعال کردن دوره 
         /*UPDATE dbo.Member_Ship
            SET VALD_TYPE = '001'
          WHERE RQRO_RQST_RQID = (SELECT RQID FROM dbo.Request WHERE RQST_RQID = @RqstRqid AND RQST_STAT = '002' AND RQTT_CODE = '004')
            AND RECT_CODE = '004';*/
         UPDATE dbo.Member_Ship
            SET VALD_TYPE = '001'
          WHERE FIGH_FILE_NO = @FileNo
            AND RECT_CODE = '004'
            AND RWNO = 1;
      END;
      ELSE
      BEGIN      
         -- غیرفعال کردن دوره 
         UPDATE dbo.Member_Ship
            SET VALD_TYPE = '001'
          WHERE RQRO_RQST_RQID = @RqstRqid
            AND RECT_CODE = '004';
      END;
      
      -- 1398/12/12 * امروز شورا برای علی کیانی جلسه داشتیم که بنده خدا نیومد
      -- این گزینه برای ثبت درخواست تک جلسه ای استفاده شده توسط مشتریان می باشد
      -- اگر مشتری قبلا از جلسات دوره استفاده کرده باشد
      DECLARE @SumAttnMontDnrm INT
             ,@MbspRwno INT
             ,@SumExstAttn INT
             ,@PymtAmnt BIGINT
             ,@CashCode BIGINT
             ,@ExpnCode BIGINT
             ,@ExpnPric INT
             ,@ExtrPrct INT
             ,@RcptMtod VARCHAR(3)
             ,@MtodCode BIGINT;
             
      SELECT @SumAttnMontDnrm = m.SUM_ATTN_MONT_DNRM
            ,@MbspRwno = m.RWNO
        FROM dbo.Member_Ship m
       WHERE m.RQRO_RQST_RQID = @OrginRqid
         AND m.RECT_CODE = '004';         
      
      IF @SumAttnMontDnrm > 0
      BEGIN
         SELECT @SumExstAttn = COUNT(a.CODE)
               ,@MtodCode = a.MTOD_CODE_DNRM
           FROM dbo.Attendance a
          WHERE a.FIGH_FILE_NO = @FileNo
            AND a.MBSP_RWNO_DNRM = @MbspRwno
            AND a.ATTN_TYPE NOT IN ('002', '006', '008') -- d$attp
            AND a.ATTN_STAT = '002'
          GROUP BY a.MTOD_CODE_DNRM;
         
         SELECT @PymtAmnt = SUM(Amnt)
           FROM dbo.Payment_Method
          WHERE RQRO_RQST_RQID = @RqstRqid;
         
         IF @SumAttnMontDnrm >= @SumExstAttn 
         BEGIN
            DECLARE C$Attn1 CURSOR FOR
               SELECT CAST(a.ATTN_DATE AS DATE) AS Attn_Date, a.COCH_FILE_NO, a.CBMT_CODE_DNRM, COUNT(a.CODE) AS Attn_Cont
                 FROM dbo.Attendance a
                WHERE a.FIGH_FILE_NO = @FileNo
                  AND a.MBSP_RWNO_DNRM = @MbspRwno
                  AND a.MBSP_RECT_CODE_DNRM = '004'
                GROUP BY CAST(a.ATTN_DATE AS DATE), a.COCH_FILE_NO, a.CBMT_CODE_DNRM;
            
            DECLARE @AttnDate DATE 
                   ,@AttnCont INT
                   ,@CochFileNo BIGINT
                   ,@CbmtCode BIGINT;
            
            OPEN [C$Attn1]
            L$Loop$Attn1:
            FETCH [C$Attn1] INTO @AttnDate, @CochFileNo, @CbmtCode, @AttnCont;
            
            IF @@FETCH_STATUS <> 0
               GOTO L$EndLoop$Attn1;
            
            DECLARE @xTemp XML;
            SELECT @xTemp = (
                  SELECT 0 AS '@rqid'
                        ,'016' AS '@rqtpcode'
                        ,'001' AS '@rqttcode'
                        ,'ALL_FLDF_F' AS '@mdulname'
                        ,'ALL_001_F' AS '@sctnname'
                        ,@Rqid AS '@rqstrqid' 
                        ,(
                           SELECT @FileNo AS '@fileno'
                              FOR XML PATH('Request_Row'), TYPE                           
                        )
                     FOR XML PATH('Request'), ROOT('Process')
               );
            EXEC dbo.OIC_ERQT_F @X = @xTemp -- xml
            
            DECLARE @TempRqid BIGINT;
            
            -- بدست آوردن شماره درخواست درآمد متفرقه
            SELECT @TempRqid = RQID, @CashCode = p.CASH_CODE
              FROM dbo.Request r, dbo.Payment p
             WHERE r.RQID = p.RQST_RQID
               AND r.RQTP_CODE = '016'
               AND r.RQST_STAT = '001'
               AND r.CRET_BY = UPPER(SUSER_NAME());
            
            -- ابتدا باید متوجه شویم که کد تعرفه متعلق به چه هزینه ای متصل می باشد
            SELECT @ExpnCode = e.CODE, @ExpnPric = e.PRIC, @ExtrPrct = e.EXTR_PRCT
              FROM dbo.Expense e, dbo.Expense_Type et, dbo.Request_Requester rr, dbo.Expense_Item ei
             WHERE e.EXTP_CODE = et.CODE
               AND et.RQRQ_CODE = rr.CODE            
               AND rr.RQTP_CODE = '016'
               AND e.MTOD_CODE = @MtodCode
               AND e.NUMB_OF_ATTN_MONT = 1
               AND e.EXPN_STAT = '002'
               AND et.EPIT_CODE = (
                   SELECT et1.EPIT_CODE
                     FROM dbo.Payment_Detail pd, dbo.Expense e1, dbo.Expense_Type et1
                    WHERE pd.PYMT_RQST_RQID = @RqstRqid
                      AND pd.EXPN_CODE = e1.CODE
                      AND e1.EXTP_CODE = et1.CODE
               );
               
            -- درج ردیف هزینه در جدول هزینه
            EXEC dbo.INS_PYDT_P @PYMT_CASH_CODE = @CashCode, -- bigint
                @PYMT_RQST_RQID = @TempRqid, -- bigint
                @RQRO_RWNO = 1, -- smallint
                @EXPN_CODE = @ExpnCode, -- bigint
                @PAY_STAT = '001', -- varchar(3)
                @EXPN_PRIC = @ExpnPric, -- int
                @EXPN_EXTR_PRCT = @ExtrPrct, -- int
                @REMN_PRIC = 0, -- int
                @QNTY = @AttnCont, -- smallint
                @DOCM_NUMB = 0, -- bigint
                @ISSU_DATE = @AttnDate, -- datetime
                @RCPT_MTOD = '012', -- varchar(3)
                @RECV_LETT_NO = NULL, -- varchar(15)
                @RECV_LETT_DATE = NULL, -- datetime
                @PYDT_DESC = N'ثبت تک جلسه ای بابت ابطال دوره براساس جدول حضور و غیاب', -- nvarchar(250)
                @ADD_QUTS = '', -- varchar(3)
                @Figh_File_No = @CochFileNo, -- bigint
                @PRE_EXPN_STAT = NULL, -- varchar(3)
                @CBMT_CODE_DNRM = @CbmtCode, -- bigint
                @EXPR_DATE = NULL, -- date
                @CODE = 0; -- bigint
            
            IF @PymtAmnt >= CAST((@ExpnPric + ISNULL(@ExtrPrct, 0)) * @AttnCont AS BIGINT)
            BEGIN
               -- مبلغ پرداختی مشتری بیش از مبلغ تک جلسه ای باشد
               -- ثبت وصولی درخواست
               SELECT @xTemp = (
                  SELECT 'InsertUpdate' AS '@actntype',
                         (
                           SELECT @CashCode AS '@cashcode',
                                  @TempRqid AS '@rqstrqid',
                                  CAST((@ExpnPric + ISNULL(@ExtrPrct, 0)) * @AttnCont AS BIGINT) AS '@amnt',
                                  '012' AS '@rcptmtod',
                                  @RqstRqid AS '@refno',
                                  @AttnDate AS '@actndate'
                              FOR XML PATH('Payment_Method'), ROOT('Insert'), TYPE                           
                         )                      
                    FOR XML PATH('Payment')                 
               );            
               EXEC dbo.PAY_MSAV_P @X = @xTemp -- xml
               
               SET @PymtAmnt -= CAST((@ExpnPric + ISNULL(@ExtrPrct, 0)) * @AttnCont AS BIGINT)
               
               -- ذخیره نهایی درخواست با حالت پرداخت کامل
               SELECT @xTemp = (
                  SELECT @TempRqid AS '@rqid',
                         1 AS 'Request_Row/@rwno',
                         @FileNo AS 'Request_Row/@fileno',
                         0 AS 'Payment/@setondebt'
                     FOR XML PATH('Request'), ROOT('Process')
               );
            END 
            ELSE
            BEGIN
               IF @PymtAmnt > 0
               BEGIN
                  -- ثبت وصولی درخواست
                  SELECT @xTemp = (
                     SELECT 'InsertUpdate' AS '@actntype',
                            (
                              SELECT @CashCode AS '@cashcode',
                                     @TempRqid AS '@rqstrqid',
                                     @PymtAmnt AS '@amnt',
                                     '012' AS '@rcptmtod',
                                     @RqstRqid AS '@refno',
                                     @AttnDate AS '@actndate'
                                 FOR XML PATH('Payment_Method'), ROOT('Insert'), TYPE                           
                            )                      
                       FOR XML PATH('Payment')                 
                  );            
                  EXEC dbo.PAY_MSAV_P @X = @xTemp -- xml
                  
                  SET @PymtAmnt -= @PymtAmnt;
               END 
               -- ذخیره نهایی درخواست با حابت ثبت بدهی
               SELECT @xTemp = (
                  SELECT @TempRqid AS '@rqid',
                         1 AS 'Request_Row/@rwno',
                         @FileNo AS 'Request_Row/@fileno',
                         1 AS 'Payment/@setondebt'
                     FOR XML PATH('Request'), ROOT('Process')
               );
            END 
            
            EXEC dbo.OIC_ESAV_F @X = @xTemp -- xml
            
            GOTO L$Loop$Attn1;
            L$EndLoop$Attn1:
            CLOSE [C$Attn1];
            DEALLOCATE [C$Attn1];
         END
         
         -- اگر ستون جدول دوره تعداد حضوری های بیشتری نسبت به تعداد رکورد حضوری در جدول حضور و غیاب داشته باشد
         -- که به احتمال زیاد به صورت اصلاح دوره ویرایش شده است
         IF @SumAttnMontDnrm - @SumExstAttn > 0
         BEGIN
            SELECT @xTemp = (
                  SELECT 0 AS '@rqid'
                        ,'016' AS '@rqtpcode'
                        ,'001' AS '@rqttcode'
                        ,'ALL_FLDF_F' AS '@mdulname'
                        ,'ALL_001_F' AS '@sctnname'                     
                        ,@Rqid AS '@rqstrqid' 
                        ,(
                           SELECT @FileNo AS '@fileno'
                              FOR XML PATH('Request_Row'), TYPE                           
                        )
                     FOR XML PATH('Request'), ROOT('Process')
               );
            EXEC dbo.OIC_ERQT_F @X = @xTemp -- xml
            
            -- بدست آوردن شماره درخواست درآمد متفرقه
            SELECT @TempRqid = RQID, @CashCode = p.CASH_CODE
              FROM dbo.Request r, dbo.Payment p
             WHERE r.RQID = p.RQST_RQID
               AND r.RQTP_CODE = '016'
               AND r.RQST_STAT = '001'
               AND r.CRET_BY = UPPER(SUSER_NAME());
            
            -- ابتدا باید متوجه شویم که کد تعرفه متعلق به چه هزینه ای متصل می باشد
            SELECT @ExpnCode = e.CODE, @ExpnPric = e.PRIC, @ExtrPrct = e.EXTR_PRCT
              FROM dbo.Expense e, dbo.Expense_Type et, dbo.Request_Requester rr, dbo.Expense_Item ei
             WHERE e.EXTP_CODE = et.CODE
               AND et.RQRQ_CODE = rr.CODE            
               AND rr.RQTP_CODE = '016'
               AND e.MTOD_CODE = @MtodCode
               AND e.NUMB_OF_ATTN_MONT = 1
               AND e.EXPN_STAT = '002'
               AND et.EPIT_CODE = (
                   SELECT et1.EPIT_CODE
                     FROM dbo.Payment_Detail pd, dbo.Expense e1, dbo.Expense_Type et1
                    WHERE pd.PYMT_RQST_RQID = @RqstRqid
                      AND pd.EXPN_CODE = e1.CODE
                      AND e1.EXTP_CODE = et1.CODE
               );
            
            SET @SumAttnMontDnrm -= @SumExstAttn;
            SET @AttnDate = GETDATE();
               
            -- درج ردیف هزینه در جدول هزینه
            EXEC dbo.INS_PYDT_P @PYMT_CASH_CODE = @CashCode, -- bigint
                @PYMT_RQST_RQID = @TempRqid, -- bigint
                @RQRO_RWNO = 1, -- smallint
                @EXPN_CODE = @ExpnCode, -- bigint
                @PAY_STAT = '001', -- varchar(3)
                @EXPN_PRIC = @ExpnPric, -- int
                @EXPN_EXTR_PRCT = @ExtrPrct, -- int
                @REMN_PRIC = 0, -- int
                @QNTY = @SumAttnMontDnrm, -- smallint
                @DOCM_NUMB = 0, -- bigint
                @ISSU_DATE = @AttnDate, -- datetime
                @RCPT_MTOD = '012', -- varchar(3)
                @RECV_LETT_NO = NULL, -- varchar(15)
                @RECV_LETT_DATE = NULL, -- datetime
                @PYDT_DESC = N'ثبت تک جلسه ای بابت ابطال دوره', -- nvarchar(250)
                @ADD_QUTS = '', -- varchar(3)
                @Figh_File_No = @CochFileNo, -- bigint
                @PRE_EXPN_STAT = NULL, -- varchar(3)
                @CBMT_CODE_DNRM = @CbmtCode, -- bigint
                @EXPR_DATE = NULL, -- date
                @CODE = 0; -- bigint
            
            IF @PymtAmnt >= CAST((@ExpnPric + ISNULL(@ExtrPrct, 0)) * @SumAttnMontDnrm AS BIGINT)
            BEGIN
               -- مبلغ پرداختی مشتری بیش از مبلغ تک جلسه ای باشد
               -- ثبت وصولی درخواست
               SELECT @xTemp = (
                  SELECT 'InsertUpdate' AS '@actntype',
                         (
                           SELECT @CashCode AS '@cashcode',
                                  @TempRqid AS '@rqstrqid',
                                  CAST((@ExpnPric + ISNULL(@ExtrPrct, 0)) * @SumAttnMontDnrm AS BIGINT) AS '@amnt',
                                  '012' AS '@rcptmtod',
                                  @RqstRqid AS '@refno',
                                  @AttnDate AS '@actndate'
                              FOR XML PATH('Payment_Method'), ROOT('Insert'), TYPE                           
                         )                      
                    FOR XML PATH('Payment')                 
               );            
               EXEC dbo.PAY_MSAV_P @X = @xTemp -- xml
               SET @PymtAmnt -= CAST((@ExpnPric + ISNULL(@ExtrPrct, 0)) * @SumAttnMontDnrm AS BIGINT);
               
               -- ذخیره نهایی درخواست با حالت پرداخت کامل
               SELECT @xTemp = (
                  SELECT @TempRqid AS '@rqid',
                         1 AS 'Request_Row/@rwno',
                         @FileNo AS 'Request_Row/@fileno',
                         0 AS 'Payment/@setondebt'
                     FOR XML PATH('Request'), ROOT('Process')
               );
            END 
            ELSE
            BEGIN
               IF @PymtAmnt > 0
               BEGIN
                  -- ثبت وصولی درخواست
                  SELECT @xTemp = (
                     SELECT 'InsertUpdate' AS '@actntype',
                            (
                              SELECT @CashCode AS '@cashcode',
                                     @TempRqid AS '@rqstrqid',
                                     @PymtAmnt AS '@amnt',
                                     '012' AS '@rcptmtod',
                                     @RqstRqid AS '@refno',
                                     @AttnDate AS '@actndate'
                                 FOR XML PATH('Payment_Method'), ROOT('Insert'), TYPE                           
                            )                      
                       FOR XML PATH('Payment')                 
                  );            
                  EXEC dbo.PAY_MSAV_P @X = @xTemp -- xml
                  
                  SET @PymtAmnt -= @PymtAmnt;
               END 
               -- ذخیره نهایی درخواست با حابت ثبت بدهی
               SELECT @xTemp = (
                  SELECT @TempRqid AS '@rqid',
                         1 AS 'Request_Row/@rwno',
                         @FileNo AS 'Request_Row/@fileno',
                         1 AS 'Payment/@setondebt'
                     FOR XML PATH('Request'), ROOT('Process')
               );
            END 
            
            EXEC dbo.OIC_ESAV_F @X = @xTemp -- xml
         END
      END 
   END;
   
   -- اگر فرآیند ابطال بدون بازگشت صادر شود مبلغ پرداختی دیگر به عنوان مبلغ سپرده لحاظ نمیشود
   IF @CnclType IN ('001', '002')
   BEGIN
      -- اگر صورتحساب مشتری دارای پرداختی میباشد مبلغ پرداختی را به صورت سپرده قرار میدهیم
      IF EXISTS(SELECT * FROM dbo.Payment_Method WHERE PYMT_RQST_RQID = @RqstRqid)
      BEGIN
         DECLARE @Amnt BIGINT;
         SELECT @Amnt = SUM(AMNT)
           FROM dbo.Payment_Method
          WHERE RQRO_RQST_RQID = @OrginRqid;
         
         SELECT @PymtAmnt = ISNULL(SUM(AMNT), 0)
           FROM dbo.Payment_Method
          WHERE RQRO_RQST_RQID IN (
                SELECT r.RQID
                  FROM dbo.Request r
                 WHERE r.RQST_RQID = @Rqid
                   AND r.RQTP_CODE = '016'
                   AND r.RQST_STAT = '002'
          );
         
         SET @Amnt -= @PymtAmnt;         
         
         SET @AttnDate = GETDATE();
         -- تسویه حساب کردن درخواست های بدهکار
         DECLARE C$DebtPymt1 CURSOR FOR 
            SELECT RQID, CASH_CODE, (SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT) - (SUM_RCPT_EXPN_PRIC + SUM_PYMT_DSCN_DNRM) AS DEBT_AMNT
              from dbo.[VF$Save_Payments](NULL, @FileNo)
             WHERE (SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT) - (SUM_RCPT_EXPN_PRIC + SUM_PYMT_DSCN_DNRM) > 0
             ORDER BY DEBT_AMNT DESC;
         
         DECLARE @DebtAmnt BIGINT;
         
         OPEN [C$DebtPymt1];
         L$Loop$DebtPymt1:
         FETCH [C$DebtPymt1] INTO @TempRqid, @CashCode, @DebtAmnt;
         
         IF @@FETCH_STATUS <> 0
            GOTO L$EndLoop$DebtPymt1;
         
         IF @Amnt > @DebtAmnt
         BEGIN
            SET @PymtAmnt = @DebtAmnt;
            SET @Amnt -= @DebtAmnt;
         END
         ELSE IF @Amnt > 0
         BEGIN
            SET @PymtAmnt = @Amnt;
            SET @Amnt -= @Amnt;
         END
         ELSE IF @Amnt = 0
            GOTO L$EndLoop$DebtPymt1;
         
         IF @PymtAmnt > 0
         BEGIN
            -- ثبت وصولی درخواست
            SELECT @xTemp = (
               SELECT 'InsertUpdate' AS '@actntype',
                      (
                        SELECT @CashCode AS '@cashcode',
                               @TempRqid AS '@rqstrqid',
                               @PymtAmnt AS '@amnt',
                               '012' AS '@rcptmtod',
                               @RqstRqid AS '@refno',
                               @AttnDate AS '@actndate'
                           FOR XML PATH('Payment_Method'), ROOT('Insert'), TYPE                           
                      )                      
                 FOR XML PATH('Payment')                 
            );            
            EXEC dbo.PAY_MSAV_P @X = @xTemp -- xml
         END
         
         GOTO L$Loop$DebtPymt1;
         L$EndLoop$DebtPymt1:
         CLOSE [C$DebtPymt1];
         DEALLOCATE [C$DebtPymt1];
         
         -- اگر مبلغ سپرده بیشتر از صفر باشد
         IF @Amnt > 0
         BEGIN          
            SELECT @x = (
               SELECT 
                  0 AS '@rqid',
                  @Rqid AS '@rqstrqid',
                  @FileNo AS 'Request_Row/@fighfileno',
                  0 AS 'Gain_Loss_Rials/@glid',
                  '002' AS 'Gain_Loss_Rials/@type',
                  @Amnt AS 'Gain_Loss_Rials/@amnt',
                  GETDATE() AS 'Gain_Loss_Rials/@paiddate',
                  '002' AS 'Gain_Loss_Rials/@dpststat',
                  N'افزایش سپرده بابت ابطال صورتحساب',
                  (
                     SELECT 1 AS '@rwno',
                            @Amnt AS '@amnt',
                            '012' AS '@rcptmtod'
                        FOR XML PATH('Gain_Loss_Rial_Detial'), ROOT('Gain_Loss_Rial_Detials'), TYPE
                  )
                  FOR XML PATH('Request'), ROOT('Process')
            );            
            EXEC dbo.GLR_TRQT_P @X = @X -- xml            
            SELECT @RqstRqid = RQID
              FROM dbo.Request
             WHERE RQTP_CODE = '020'
               AND RQST_STAT = '001'
               AND RQTT_CODE = '004'
               AND CRET_BY = UPPER(SUSER_NAME())
               AND SUB_SYS = 1;            
            SELECT @X = (
               SELECT @RqstRqid AS '@rqid'
                  FOR XML PATH('Request'), ROOT('Process')
            );            
            EXEC dbo.GLR_TSAV_P @X = @X -- xml
         END;         
      END; 
   END;
   -- 
   ELSE IF @CnclType IN ('003') 
   BEGIN
      -- حال باید در صورتحساب های صادره در گزارشات این مورد را لحاظ کنیم که صورتحساب معتبر باشد
      PRINT 'Nothing'
   END;  
   
   SET @RqstRqid = NULL;
   
   -- تغییر وضعیت صورتحساب به حالت ابطال
   UPDATE dbo.Payment 
      SET PYMT_STAT = '002' -- وضعیت صورتحساب به صورت ابطال در اورده میشود
    WHERE RQST_RQID = @OrginRqid;
   
   -- پایان درخواست
   UPDATE Request
      SET RQST_STAT = '002'
         ,RQST_RQID = @OrginRqid
    WHERE RQID = @Rqid;
   
   -- 001 درخواست ابطال عادی
   -- 002 درخواست صدور صورتحساب اصلاحی
   IF @CnclType = '002' 
   BEGIN
      -- اگر درخواست اصلاح صورتحساب متعلق به ثبت نام و تمدید باشد
      IF EXISTS(SELECT * FROM dbo.Request WHERE RQID = @OrginRqid AND RQTP_CODE IN ('001', '009'))
      BEGIN
         SET @RqstRqid = @OrginRqid;
         -- پیدا کردن درخواست مربوط به جدول دوره متصل 	   
	      IF EXISTS(SELECT * FROM dbo.Request WHERE RQID = @OrginRqid AND RQTP_CODE = '001' AND RQTP_CODE = '001')
	         SELECT @RqstRqid = RQID
	           FROM dbo.Request
	          WHERE RQST_RQID = @OrginRqid
	            AND RQTP_CODE = '009';
	       
         SELECT @X = (
            SELECT 0 AS '@rqid'
                  ,@Rqid AS '@rqstrqid'
                  ,'009' AS '@rqtpcode'
                  ,'001' AS '@rqttcode'                  
                  ,(
                     SELECT @FileNo AS '@fileno'
                           ,STRT_DATE AS 'Member_Ship/@strtdate'
                           ,END_DATE AS 'Member_Ship/@enddate'
                           ,PRNT_CONT AS 'Member_Ship/@prntcont'
                           ,NUMB_MONT_OFER AS 'Member_Ship/@numbmontofer'
                           ,NUMB_OF_ATTN_MONT AS 'Member_Ship/@numbofattnmont'
                           ,NUMB_OF_ATTN_WEEK AS 'Member_Ship/@numbofattnweek'
                           ,'' AS 'Member_Ship/@newfngrprnt'
                       FROM dbo.Member_Ship
                      WHERE RQRO_RQST_RQID = @RqstRqid
                        AND RECT_CODE = '004'
                        FOR XML PATH('Request_Row'), TYPE
                  )
              FOR XML PATH('Request'), ROOT('Process')
         );
         
         EXEC dbo.UCC_TRQT_P @X = @X -- xml         
         
         SELECT @RqstRqid = RQID
           FROM dbo.Request
          WHERE RQTP_CODE = '009'
            AND RQST_STAT = '001'
            AND RQTT_CODE = '004'
            AND CRET_BY = UPPER(SUSER_NAME())
            AND SUB_SYS = 1;
      END
      /*ELSE IF EXISTS(SELECT * FROM dbo.Request WHERE RQID = @OrginRqid AND RQTP_CODE = '016')
      BEGIN
         SELECT 'Fuck :|';
      END */
   END 
	
	COMMIT TRANSACTION [T$CNCL_PYMT_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErrorMessage NVARCHAR(MAX);
	   SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN [T$CNCL_PYMT_P]
	END CATCH
END
GO
