SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CALC_EXPN_P]
	@X XML
AS
BEGIN
   BEGIN TRY
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>128</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 128 سطوح امینتی : شما مجوز محاسبه هزینه مربیان را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END


   BEGIN TRAN T1
	DECLARE @FromPymtDate DATE
	       ,@ToPymtDate   DATE
	       ,@PrctValu     SMALLINT
	       ,@CochFileNo   BIGINT
	       ,@EpitCode     BIGINT
	       ,@RqttCode     VARCHAR(3)
	       ,@PydtCode     BIGINT
	       ,@ExpnPric     INT
	       ,@DecrPrct     FLOAT
	       ,@RqtpCode     VARCHAR(3)
	       ,@MtodCode     BIGINT
	       ,@CtgyCode     BIGINT
	       ,@CalcType     VARCHAR(3)
	       ,@PymtStat     VARCHAR(3);
	
	SELECT @FromPymtDate = @X.query('//Payment').value('(Payment/@fromdate)[1]', 'DATE')
	      ,@ToPymtDate   = @X.query('//Payment').value('(Payment/@todate)[1]',   'DATE')
	      ,@CochFileNo   = @X.query('//Payment').value('(Payment/@cochfileno)[1]','BIGINT')
	      ,@DecrPrct     = @X.query('//Payment').value('(Payment/@decrprct)[1]',   'FLOAT');
   
   IF @FromPymtDate IN ('1900-01-01', '0001-01-01' ) BEGIN RAISERROR (N'برای فیلد "از تاریخ" اطلاعات وارد نشده' , 16, 1); END
   IF @ToPymtDate IN ('1900-01-01', '0001-01-01' ) BEGIN RAISERROR (N'برای فیلد "تا تاریخ" اطلاعات وارد نشده' , 16, 1); END
   IF @CochFileNo = 0 SET @CochFileNo = NULL;
   IF @DecrPrct IS NULL SET @DecrPrct = 0;
   
   -- برای محاسبه درصدی آیتم هایی که برای مربی مشخص کرده ایم که باید بر اساس مبلغ دوره محسابه شود
   DECLARE C$CochFileNo$CalcExpnP CURSOR FOR
      SELECT C.Coch_File_No, C.Epit_Code, C.Rqtt_Code, C.Prct_Valu,
             c.RQTP_CODE, c.MTOD_CODE, c.CTGY_CODE, C.CALC_TYPE, C.PYMT_STAT
        FROM Fighter F, Fighter_Public P, Calculate_Expense_Coach C
       WHERE F.File_No = C.Coch_File_No
         AND F.File_No = P.Figh_File_No 
         AND F.Fgpb_Rwno_Dnrm = P.Rwno
         AND P.Rect_Code = '004'
         AND P.Coch_Deg = C.Coch_Deg
         AND C.Stat = '002'
         AND (@CochFileNo IS NULL OR F.File_No = @CochFileNo)
         AND C.CALC_TYPE = '001' /* محاسبه توسط درصدی */
         AND c.CALC_EXPN_TYPE = '001' /* مبلغ دوره */;
   
   -- DELETE FOR Paymemt_Expense FOR Coach With Vald_Type = '001'
   DELETE Misc_Expense
    WHERE CALC_EXPN_TYPE = '001'
      AND VALD_TYPE = '001';
      
   DELETE Payment_Expense
    WHERE VALD_TYPE = '001';
    
   OPEN C$CochFileNo$CalcExpnP;
   NextC$CochFileNo$CalcExpnP:
   FETCH NEXT FROM C$CochFileNo$CalcExpnP INTO 
   @CochFileNo, @EpitCode, @RqttCode, @PrctValu, @RqtpCode, @MtodCode, @CtgyCode, @CalcType, @PymtStat;
   
   IF @@FETCH_STATUS <> 0
      GOTO EndC$CochFileNo$CalcExpnP;
      
      -- در دستور پایین باید سطوح دسترسی به رکورد را اعمال کنیم. مثلا ناحیه، باشگاه، خود هنرجو      
      INSERT INTO Payment_Expense (Code, PYDT_CODE, COCH_FILE_NO, VALD_TYPE, EXPN_AMNT, EXPN_PRIC, RCPT_PRIC, DSCN_PRIC, PRCT_VALU, DECR_PRCT_VALU, RQTP_CODE, MTOD_CODE, CTGY_CODE, CLUB_CODE, DECR_AMNT_DNRM, RQRO_RQST_RQID, RQRO_RWNO, CALC_EXPN_TYPE, CALC_TYPE, PYMT_STAT, MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO)
      SELECT dbo.GNRT_NVID_U(),
             PYDT.CODE, 
             @CochFileNo,
             '001',
             --(PYDT.EXPN_PRIC * @PrctValu / 100) - ((PYDT.EXPN_PRIC * @PrctValu / 100) * @DecrPrct / 100),
             (PYMT.SUM_RCPT_EXPN_PRIC * @PrctValu / 100) - ((PYMT.SUM_RCPT_EXPN_PRIC * @PrctValu / 100) * @DecrPrct / 100),
             PYMT.SUM_EXPN_PRIC,
             PYMT.SUM_RCPT_EXPN_PRIC,
             PYMT.SUM_PYMT_DSCN_DNRM,
             @PrctValu,
             @DecrPrct,
             RQRO.RQTP_CODE,
             PYDT.MTOD_CODE_DNRM,
             PYDT.CTGY_CODE_DNRM,
             PYMT.CLUB_CODE_DNRM,
             ((PYMT.SUM_RCPT_EXPN_PRIC * @PrctValu / 100) * @DecrPrct / 100),
             RQRO.RQST_RQID,
             RQRO.RWNO,
             '001', -- مبلغ دوره
             '001', -- درصدی
             @PymtStat,
             RQRO.FIGH_FILE_NO,
             '004',
             CASE WHEN RQRO.RQTP_CODE = '001' THEN 1 ELSE (SELECT ms.RWNO FROM dbo.Member_Ship ms WHERE ms.RQRO_RQST_RQID = RQRO.RQST_RQID AND ms.RQRO_RWNO = RQRO.RWNO AND ms.RECT_CODE = '004') END
        FROM Payment_Detail AS PYDT INNER JOIN
             dbo.Payment AS PYMT ON PYMT.CASH_CODE = PYDT.PYMT_CASH_CODE AND PYMT.RQST_RQID = PYDT.PYMT_RQST_RQID INNER JOIN
             Request_Row AS RQRO ON PYDT.PYMT_RQST_RQID = RQRO.RQST_RQID AND PYDT.RQRO_RWNO = RQRO.RWNO INNER JOIN
             Fighter AS FIGH ON RQRO.FIGH_FILE_NO = FIGH.FILE_NO INNER JOIN
             Expense AS EXPN ON PYDT.EXPN_CODE = EXPN.CODE INNER JOIN
             Expense_Type EXTP ON EXPN.EXTP_CODE = EXTP.CODE INNER JOIN
             Expense_Item EPIT ON EXTP.EPIT_CODE = EPIT.CODE INNER JOIN
             Request_Requester RQRQ ON EXTP.RQRQ_CODE = RQRQ.CODE 
       WHERE (PYDT.PAY_STAT = @PymtStat) 
         AND (RQRO.RECD_STAT = '002') 
         AND (FIGH.FGPB_TYPE_DNRM NOT IN ('003','002', '004'))
         AND (CAST(PYDT.CRET_DATE AS DATE) >= @FromPymtDate)
         AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(PYDT.CRET_DATE AS DATE) <= @ToPymtDate)
         AND (FIGH.COCH_FILE_NO_DNRM = @CochFileNo)
         AND (EPIT.CODE = @EpitCode)
         AND (RQRQ.RQTT_CODE = @RqttCode)
         AND (pydt.MTOD_CODE_DNRM = @MtodCode)
         AND (PYDT.CTGY_CODE_DNRM = @CtgyCode)
         AND (RQRO.RQTP_CODE = @RqtpCode)
         AND dbo.PLC_FIGH_U('<Fighter fileno="' + CAST(Figh.FILE_NO AS VARCHAR(30)) + '"/>') = '002';
  
   GOTO NextC$CochFileNo$CalcExpnP;
   EndC$CochFileNo$CalcExpnP:
   CLOSE C$CochFileNo$CalcExpnP;
   DEALLOCATE C$CochFileNo$CalcExpnP;   
   
   -- برای محاسبه درصدی آیتم هایی که برای مربی مشخص کرده ایم که باید بر اساس تعداد جلسات محسابه شود
   DECLARE C$CochFileNo$CalcExpnPT CURSOR FOR
      SELECT C.Coch_File_No, C.Epit_Code, C.Rqtt_Code, C.Prct_Valu,
             c.RQTP_CODE, c.MTOD_CODE, c.CTGY_CODE, C.CALC_TYPE, C.PYMT_STAT
        FROM Fighter F, Fighter_Public P, Calculate_Expense_Coach C
       WHERE F.File_No = C.Coch_File_No
         AND F.File_No = P.Figh_File_No 
         AND F.Fgpb_Rwno_Dnrm = P.Rwno
         AND P.Rect_Code = '004'
         AND P.Coch_Deg = C.Coch_Deg
         AND C.Stat = '002'
         AND (@CochFileNo IS NULL OR F.File_No = @CochFileNo)
         AND C.CALC_TYPE = '001' /* محاسبه توسط درصدی */
         AND c.CALC_EXPN_TYPE = '002' /* تعداد جلسات */;
   
   OPEN C$CochFileNo$CalcExpnPT;
   NextC$CochFileNo$CalcExpnPT:
   FETCH NEXT FROM C$CochFileNo$CalcExpnPT INTO 
   @CochFileNo, @EpitCode, @RqttCode, @PrctValu, @RqtpCode, @MtodCode, @CtgyCode, @CalcType, @PymtStat;
   
   IF @@FETCH_STATUS <> 0
      GOTO EndC$CochFileNo$CalcExpnPT;

   -- در دستور پایین باید سطوح دسترسی به رکورد را اعمال کنیم. مثلا ناحیه، باشگاه، خود هنرجو      
      INSERT INTO Payment_Expense (Code, PYDT_CODE, COCH_FILE_NO, VALD_TYPE, EXPN_AMNT, EXPN_PRIC, RCPT_PRIC, DSCN_PRIC, PRCT_VALU, DECR_PRCT_VALU, RQTP_CODE, MTOD_CODE, CTGY_CODE, CLUB_CODE, DECR_AMNT_DNRM, RQRO_RQST_RQID, RQRO_RWNO, CALC_EXPN_TYPE, CALC_TYPE, PYMT_STAT, MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO)
      SELECT dbo.GNRT_NVID_U(),
             PYDT.CODE, 
             @CochFileNo,
             '001',
             (PYMT.SUM_RCPT_EXPN_PRIC * @PrctValu / 100) - ((PYMT.SUM_RCPT_EXPN_PRIC * @PrctValu / 100) * @DecrPrct / 100),
             PYMT.SUM_EXPN_PRIC,
             PYMT.SUM_RCPT_EXPN_PRIC,
             PYMT.SUM_PYMT_DSCN_DNRM,
             @PrctValu,
             @DecrPrct,
             RQRO.RQTP_CODE,
             PYDT.MTOD_CODE_DNRM,
             PYDT.CTGY_CODE_DNRM,
             PYMT.CLUB_CODE_DNRM,
             ((PYMT.SUM_RCPT_EXPN_PRIC * @PrctValu / 100) * @DecrPrct / 100),
             RQRO.RQST_RQID,
             RQRO.RWNO,
             '002', -- تعداد جلسات
             '001', -- درصدی
             @PymtStat,
             RQRO.FIGH_FILE_NO,
             '004',
             CASE WHEN RQRO.RQTP_CODE = '001' THEN 1 ELSE (SELECT ms.RWNO FROM dbo.Member_Ship ms WHERE ms.RQRO_RQST_RQID = RQRO.RQST_RQID AND ms.RQRO_RWNO = RQRO.RWNO AND ms.RECT_CODE = '004') END
        FROM Payment_Detail AS PYDT INNER JOIN
             dbo.Payment AS PYMT ON PYMT.CASH_CODE = PYDT.PYMT_CASH_CODE AND PYMT.RQST_RQID = PYDT.PYMT_RQST_RQID INNER JOIN
             Request_Row AS RQRO ON PYDT.PYMT_RQST_RQID = RQRO.RQST_RQID AND PYDT.RQRO_RWNO = RQRO.RWNO INNER JOIN
             Fighter AS FIGH ON RQRO.FIGH_FILE_NO = FIGH.FILE_NO INNER JOIN
             Expense AS EXPN ON PYDT.EXPN_CODE = EXPN.CODE INNER JOIN
             Expense_Type EXTP ON EXPN.EXTP_CODE = EXTP.CODE INNER JOIN
             Expense_Item EPIT ON EXTP.EPIT_CODE = EPIT.CODE INNER JOIN
             Request_Requester RQRQ ON EXTP.RQRQ_CODE = RQRQ.CODE 
       WHERE (PYDT.PAY_STAT = @PymtStat) 
         AND (RQRO.RECD_STAT = '002') 
         AND (FIGH.FGPB_TYPE_DNRM NOT IN ('003','002', '004'))
         AND (CAST(PYDT.CRET_DATE AS DATE) >= @FromPymtDate)
         AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(PYDT.CRET_DATE AS DATE) <= @ToPymtDate)
         AND (FIGH.COCH_FILE_NO_DNRM = @CochFileNo)
         AND (EPIT.CODE = @EpitCode)
         AND (RQRQ.RQTT_CODE = @RqttCode)
         AND (pydt.MTOD_CODE_DNRM = @MtodCode)
         AND (PYDT.CTGY_CODE_DNRM = @CtgyCode)
         AND (RQRO.RQTP_CODE = @RqtpCode)
         AND dbo.PLC_FIGH_U('<Fighter fileno="' + CAST(Figh.FILE_NO AS VARCHAR(30)) + '"/>') = '002';
   
   UPDATE pe
      SET pe.EXPN_AMNT = 
          (
            (EXPN_PRIC / ms.NUMB_OF_ATTN_MONT) * @PrctValu / 100  - 
            ((pe.EXPN_PRIC * @PrctValu / 100) * @DecrPrct / 100)
          ) * ms.SUM_ATTN_MONT_DNRM
     FROM dbo.Payment_Expense pe, dbo.Member_Ship ms
    WHERE pe.MBSP_FIGH_FILE_NO = ms.FIGH_FILE_NO
      AND pe.MBSP_RWNO = ms.RWNO
      AND pe.MBSP_RECT_CODE = ms.RECT_CODE
      AND pe.MTOD_CODE = @MtodCode
      AND pe.CTGY_CODE = @CtgyCode
      AND pe.RQTP_CODE = @RqtpCode
      AND pe.CRET_BY = UPPER(SUSER_NAME())
      AND CAST(pe.CRET_DATE AS DATE) = CAST(GETDATE() AS DATE)
      AND pe.CALC_EXPN_TYPE = '002' -- تعداد جلسات
      AND pe.CALC_TYPE = '001'; -- درصدی            
   
   GOTO NextC$CochFileNo$CalcExpnPT;
   EndC$CochFileNo$CalcExpnPT:
   CLOSE C$CochFileNo$CalcExpnPT;
   DEALLOCATE C$CochFileNo$CalcExpnPT;   
      
   DELETE Payment_Expense 
    WHERE EXISTS(SELECT * FROM Payment_Expense Pe WHERE Pe.CODE <> Payment_Expense.CODE AND Pe.PYDT_CODE = Payment_Expense.PYDT_CODE AND Pe.VALD_TYPE = '002' AND Payment_Expense.VALD_TYPE = '001')   
   
   -- درج سرجمع هزینه های مربی   
   INSERT INTO Misc_Expense (REGN_PRVN_CNTY_CODE, REGN_PRVN_CODE, REGN_CODE, CLUB_CODE, CODE, COCH_FILE_NO, VALD_TYPE, EXPN_AMNT, CALC_EXPN_TYPE, DECR_PRCT) 
   SELECT REGN_PRVN_CNTY_CODE, REGN_PRVN_CODE, REGN_CODE, CLUB_CODE_DNRM, dbo.GNRT_NVID_U(), COCH_FILE_NO, '001', Expn_Amnt, '001', @DecrPrct
     FROM (
      SELECT r.REGN_PRVN_CNTY_CODE, r.REGN_PRVN_CODE, r.REGN_CODE, p.CLUB_CODE_DNRM, COCH_FILE_NO, SUM(EXPN_AMNT) AS Expn_Amnt
        FROM Payment_Expense pe, Payment_Detail pd, Payment p, Request R
       WHERE pe.VALD_TYPE = '001'
         AND pe.PYDT_CODE = pd.CODE
         AND pd.PYMT_CASH_CODE = p.CASH_CODE
         AND pd.PYMT_RQST_RQID = p.RQST_RQID
         AND p.RQST_RQID = R.RQID
    GROUP BY r.REGN_PRVN_CNTY_CODE, r.REGN_PRVN_CODE, 
             r.REGN_CODE, p.CLUB_CODE_DNRM, 
             pe.COCH_FILE_NO ) T	  
   
   UPDATE pe
      SET pe.MSEX_CODE = me.CODE
     FROM dbo.Payment_Expense pe, dbo.Misc_Expense me
    WHERE pe.COCH_FILE_NO = me.COCH_FILE_NO
      AND pe.CLUB_CODE = me.CLUB_CODE
      AND pe.MSEX_CODE IS NULL
      AND me.CALC_EXPN_TYPE = '001'
      AND me.DELV_STAT IS NULL;
   
   /*MERGE dbo.Payment_Expense T
   USING (SELECT DISTINCT COCH_FILE_NO, CODE 
            FROM dbo.Misc_Expense 
           WHERE CALC_EXPN_TYPE = '001' 
             AND DELV_STAT IS NULL) S
   ON (T.COCH_FILE_NO = S.COCH_FILE_NO AND T.MSEX_CODE IS NULL)
   WHEN MATCHED THEN
      UPDATE SET t.MSEX_CODE = S.CODE;*/
         
   COMMIT TRAN T1;  
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH   
END
GO
