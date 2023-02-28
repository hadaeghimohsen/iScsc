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
	       ,@PrctValu     FLOAT
	       ,@CochFileNoP  BIGINT
	       ,@CochDegrP    VARCHAR(3)
	       ,@MtodCodeP    BIGINT
	       ,@CtgyCodeP    BIGINT
	       ,@EpitCodeP    BIGINT
	       ,@CetpCodeP    VARCHAR(3)
	       ,@CxtpCodeP    VARCHAR(3)
	       ,@RqtpCodeP    VARCHAR(3)
	       ,@CochFileNo   BIGINT
	       ,@EpitCode     BIGINT
	       ,@RqttCode     VARCHAR(3)
	       ,@PydtCode     BIGINT
	       ,@ExpnPric     INT
	       ,@DecrPrct     FLOAT
	       ,@RqtpCode     VARCHAR(3)
	       ,@MtodCode     BIGINT
	       ,@CtgyCode     BIGINT
	       ,@CbmtCode     BIGINT
	       ,@CalcType     VARCHAR(3)
	       ,@PymtStat     VARCHAR(3)
	       ,@RducAmnt     BIGINT
	       ,@EfctDateType VARCHAR(3)
	       ,@MinAttnStat  VARCHAR(3)
	       ,@ExprPayDay   INT;
	
	SELECT @FromPymtDate = @X.query('//Payment').value('(Payment/@fromdate)[1]', 'DATE')
	      ,@ToPymtDate   = @X.query('//Payment').value('(Payment/@todate)[1]',   'DATE')
	      ,@CochFileNoP   = @X.query('//Payment').value('(Payment/@cochfileno)[1]','BIGINT')
	      ,@DecrPrct     = @X.query('//Payment').value('(Payment/@decrprct)[1]',   'FLOAT')
	      ,@CochDegrP     = @X.query('//Payment').value('(Payment/@cochdegr)[1]',   'VARCHAR(3)')
	      ,@MtodCodeP    = @X.query('//Payment').value('(Payment/@mtodcode)[1]',   'BIGINT')
	      ,@CtgyCodeP    = @X.query('//Payment').value('(Payment/@ctgycode)[1]',   'BIGINT')
	      ,@EpitCodeP    = @X.query('//Payment').value('(Payment/@epitcode)[1]',   'BIGINT')
	      ,@CetpCodeP    = @X.query('//Payment').value('(Payment/@cetpcode)[1]',   'VARCHAR(3)')
	      ,@CxtpCodeP     = @X.query('//Payment').value('(Payment/@cxtpcode)[1]',   'VARCHAR(3)')
	      ,@RqtpCodeP     = @X.query('//Payment').value('(Payment/@rqtpcode)[1]',   'VARCHAR(3)');
	      
   
   IF @FromPymtDate IN ('1900-01-01', '0001-01-01' ) BEGIN RAISERROR (N'برای فیلد "از تاریخ" اطلاعات وارد نشده' , 16, 1); END
   IF @ToPymtDate IN ('1900-01-01', '0001-01-01' ) BEGIN RAISERROR (N'برای فیلد "تا تاریخ" اطلاعات وارد نشده' , 16, 1); END
   IF @CochFileNoP = 0 SET @CochFileNoP = NULL;
   IF @DecrPrct IS NULL SET @DecrPrct = 0;
   IF @MtodCodeP = 0 SET @MtodCodeP = NULL;
   IF @CtgyCodeP = 0 SET @CtgyCodeP = NULL;
   IF @EpitCodeP = 0 SET @EpitCodeP = NULL;
   IF @CochDegrP = '' SET @CochDegrP = NULL;
   IF @CetpCodeP = '' SET @CetpCodeP = NULL;
   IF @CxtpCodeP = '' SET @CxtpCodeP = NULL;
   IF @RqtpCodeP = '' SET @RqtpCodeP = NULL;

   DECLARE @PmexCode BIGINT;

   -- DELETE FOR Paymemt_Expense FOR Coach With Vald_Type = '001'
   ALTER TABLE dbo.Attendance DISABLE TRIGGER [CG$AUPD_ATTN];
   UPDATE dbo.Attendance
      SET RCPT_STAT = NULL
    WHERE RCPT_STAT != '003'
      AND EXISTS(
          SELECT * 
            FROM dbo.Calculate_Expense_Coach cec
           WHERE cec.CALC_EXPN_TYPE = '005'
             AND cec.STAT = '002'
             AND dbo.Attendance.MTOD_CODE_DNRM = cec.MTOD_CODE
             AND dbo.Attendance.CTGY_CODE_DNRM = cec.CTGY_CODE
             AND dbo.Attendance.COCH_FILE_NO = cec.COCH_FILE_NO
      )
      AND EXISTS(
          SELECT *
            FROM dbo.Payment_Expense
           WHERE VALD_TYPE = '001'
             AND CALC_EXPN_TYPE = '005'
             AND CODE = PMEX_CODE
    ) OR NOT EXISTS (
          SELECT *
            FROM dbo.Payment_Expense
           WHERE CODE = PMEX_CODE
    );
   ALTER TABLE dbo.Attendance ENABLE TRIGGER [CG$AUPD_ATTN];
   
   DELETE Misc_Expense
    WHERE CALC_EXPN_TYPE = '001'
      AND VALD_TYPE = '001';   
      
   DELETE Payment_Expense
    WHERE VALD_TYPE = '001';
   
   -- پارت اول
   -- محاسبه به صورت درصدی %
   -- برای محاسبه درصدی آیتم هایی که برای مربی مشخص کرده ایم که باید بر اساس مبلغ دوره محسابه شود
   DECLARE C$CochFileNo$CalcExpnP CURSOR FOR
      SELECT C.Coch_File_No, C.Epit_Code, C.Rqtt_Code, C.Prct_Valu,
             c.RQTP_CODE, c.MTOD_CODE, c.CTGY_CODE, C.CALC_TYPE, 
             C.PYMT_STAT, ISNULL(c.RDUC_AMNT, 0), c.EFCT_DATE_TYPE
        FROM Fighter F, Fighter_Public P, Calculate_Expense_Coach C
       WHERE F.File_No = C.Coch_File_No
         AND F.File_No = P.Figh_File_No 
         AND F.Fgpb_Rwno_Dnrm = P.Rwno
         AND P.Rect_Code = '004'
         /*AND ISNULL(P.Coch_Deg, '000') = ISNULL(C.Coch_Deg, '000')*/
         AND C.Stat = '002'
         AND F.ACTV_TAG_DNRM >= '101'
         AND C.CALC_TYPE = '001' /* درصدی */
         AND C.CALC_EXPN_TYPE = '001' /* مبلغ دوره */
         AND (@CochFileNoP IS NULL OR F.File_No = @CochFileNoP)
         AND (@MtodCodeP IS NULL OR c.MTOD_CODE = @MtodCodeP)
         AND (@CtgyCodeP IS NULL OR c.CTGY_CODE = @CtgyCodeP)
         AND (@EpitCodeP IS NULL OR c.EPIT_CODE = @EpitCodeP)
         AND (@CochDegrP IS NULL OR c.COCH_DEG = @CochDegrP)
         AND (@CetpCodeP IS NULL OR c.CALC_TYPE = @CetpCodeP)
         AND (@CxtpCodeP IS NULL OR c.CALC_EXPN_TYPE = @CxtpCodeP)
         AND (@RqtpCodeP IS NULL OR c.RQTP_CODE = @RqtpCodeP);         
    
   OPEN C$CochFileNo$CalcExpnP;
   NextC$CochFileNo$CalcExpnP:
   FETCH NEXT FROM C$CochFileNo$CalcExpnP INTO 
   @CochFileNo, @EpitCode, @RqttCode, @PrctValu, @RqtpCode, 
   @MtodCode, @CtgyCode, @CalcType, @PymtStat, @RducAmnt, @EfctDateType;
   
   IF @@FETCH_STATUS <> 0
      GOTO EndC$CochFileNo$CalcExpnP;
      
   -- در دستور پایین باید سطوح دسترسی به رکورد را اعمال کنیم. مثلا ناحیه، باشگاه، خود هنرجو      
   INSERT INTO Payment_Expense (
      Code, PYDT_CODE, COCH_FILE_NO, VALD_TYPE, EXPN_AMNT, EXPN_PRIC, RCPT_PRIC, 
      DSCN_PRIC, SELF_DSCN_PRIC, CALC_EXPN_PRIC, PRCT_VALU, DECR_PRCT_VALU, RQTP_CODE, MTOD_CODE, CTGY_CODE, CLUB_CODE, 
      DECR_AMNT_DNRM, RQRO_RQST_RQID, RQRO_RWNO, CALC_EXPN_TYPE, CALC_TYPE, PYMT_STAT, 
      MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, FROM_DATE, TO_DATE, RDUC_AMNT, EFCT_DATE_TYPE,
      RECT_CODE, RECT_DATE, PROF_AMNT, DEDU_AMNT)
   SELECT dbo.GNRT_NVID_U(),
          PYDT.CODE, 
          @CochFileNo,
          '001',
          (
             (
                 CASE WHEN ISNULL(pydt.PROF_AMNT_DNRM, 0) > 0 THEN pydt.PROF_AMNT_DNRM else (PYDT.EXPN_PRIC * PYDT.QNTY) END * @PrctValu / 100 
             ) - (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = RQST.RQID AND pd.PYDT_CODE_DNRM = PYDT.CODE AND pd.AMNT_TYPE = '005' AND pd.STAT = '002') -- تخفیف خود مربی
             /*- 
             (
                (
                  (
                      (PYDT.EXPN_PRIC * PYDT.QNTY) * @PrctValu / 100 
                  ) - (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = RQST.RQID AND pd.PYDT_CODE_DNRM = PYDT.CODE AND pd.AMNT_TYPE = '005' AND pd.STAT = '002') -- تخفیف خود مربی
                ) * @DecrPrct / 100
             )*/
          ),
          (PYDT.EXPN_PRIC * PYDT.QNTY),
          (PYDT.EXPN_PRIC * PYDT.QNTY) - (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = RQST.RQID AND pd.PYDT_CODE_DNRM = PYDT.CODE AND pd.STAT = '002'),
          (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = RQST.RQID AND pd.PYDT_CODE_DNRM = PYDT.CODE AND pd.STAT = '002'),          
          (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = RQST.RQID AND pd.PYDT_CODE_DNRM = PYDT.CODE AND pd.AMNT_TYPE = '005' AND pd.STAT = '002'), -- تخفیف خود مربی
          CASE WHEN ISNULL(pydt.PROF_AMNT_DNRM, 0) > 0 THEN pydt.PROF_AMNT_DNRM else (PYDT.EXPN_PRIC * PYDT.QNTY) END * @PrctValu / 100,
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
          CASE WHEN RQRO.RQTP_CODE = '001' THEN 1 WHEN RQRO.RQTP_CODE = '016' THEN (SELECT MBSP_RWNO_DNRM FROM dbo.Fighter WHERE FILE_NO = RQRO.FIGH_FILE_NO) ELSE (SELECT ms.RWNO FROM dbo.Member_Ship ms WHERE ms.RQRO_RQST_RQID = RQRO.RQST_RQID AND ms.RQRO_RWNO = RQRO.RWNO AND ms.RECT_CODE = '004') END,
          /*@FromPymtDate,
          @ToPymtDate,*/
          CASE RQST.RQTP_CODE
            WHEN '001' THEN (SELECT ms.STRT_DATE
                               FROM dbo.Member_Ship ms
                              WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                AND ms.RECT_CODE = '004'
                                AND ms.RWNO = 1)
            WHEN '009' THEN (SELECT ms.STRT_DATE
                               FROM dbo.Member_Ship ms
                              WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                AND ms.RECT_CODE = '004'
                                AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                                AND ms.RQRO_RWNO = RQRO.RWNO)
            WHEN '016' THEN rqst.SAVE_DATE
          END ,
          CASE RQST.RQTP_CODE
            WHEN '001' THEN (SELECT ms.END_DATE
                               FROM dbo.Member_Ship ms
                              WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                AND ms.RECT_CODE = '004'
                                AND ms.RWNO = 1)
            WHEN '009' THEN (SELECT ms.END_DATE
                               FROM dbo.Member_Ship ms
                              WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                AND ms.RECT_CODE = '004'
                                AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                                AND ms.RQRO_RWNO = RQRO.RWNO)
            WHEN '016' THEN rqst.SAVE_DATE
          END ,
          @RducAmnt,
          @EfctDateType,
          '004',
          NULL,
          CASE WHEN ISNULL(PYDT.PROF_AMNT_DNRM, 0) > 0 THEN PYDT.PROF_AMNT_DNRM ELSE (PYDT.EXPN_PRIC * PYDT.QNTY) END,
          PYDT.DEDU_AMNT_DNRM
     FROM Payment_Detail AS PYDT INNER JOIN
          dbo.Payment AS PYMT ON PYMT.CASH_CODE = PYDT.PYMT_CASH_CODE AND PYMT.RQST_RQID = PYDT.PYMT_RQST_RQID INNER JOIN
          Request_Row AS RQRO ON PYDT.PYMT_RQST_RQID = RQRO.RQST_RQID AND PYDT.RQRO_RWNO = RQRO.RWNO INNER JOIN
          Request AS RQST ON RQST.RQID = RQRO.RQST_RQID INNER JOIN 
          Fighter AS FIGH ON RQRO.FIGH_FILE_NO = FIGH.FILE_NO INNER JOIN
          Expense AS EXPN ON PYDT.EXPN_CODE = EXPN.CODE INNER JOIN
          Expense_Type EXTP ON EXPN.EXTP_CODE = EXTP.CODE INNER JOIN
          Expense_Item EPIT ON EXTP.EPIT_CODE = EPIT.CODE INNER JOIN
          Request_Requester RQRQ ON EXTP.RQRQ_CODE = RQRQ.CODE 
    WHERE (PYDT.PAY_STAT = @PymtStat) 
      AND (RQRO.RECD_STAT = '002') 
      AND (FIGH.FGPB_TYPE_DNRM NOT IN (/*'003',*/'002', '004'))
      AND (
             ( @EfctDateType = '007' -- تاریخ تاییدیه تسویه حساب
               AND (CAST(PYDT.ISSU_DATE AS DATE) >= @FromPymtDate)
               AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(PYDT.ISSU_DATE AS DATE) <= @ToPymtDate)
             ) OR 
             ( @EfctDateType = '006' -- تاریخ ویرایش رکورد
               AND (CAST(PYDT.MDFY_DATE AS DATE) >= @FromPymtDate)
               AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(PYDT.MDFY_DATE AS DATE) <= @ToPymtDate)
             ) OR 
             ( @EfctDateType = '005' -- تاریخ ایجاد رکورد
               AND (CAST(PYDT.CRET_DATE AS DATE) >= @FromPymtDate)
               AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(PYDT.CRET_DATE AS DATE) <= @ToPymtDate)
             ) OR 
             ( @EfctDateType = '004' -- تاریخ تایید درخواست
               AND (CAST(RQST.SAVE_DATE AS DATE) >= @FromPymtDate)
               AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.SAVE_DATE AS DATE) <= @ToPymtDate)
             ) OR 
             ( @EfctDateType = '003' -- تاریخ ثبت درخواست
               AND (CAST(RQST.RQST_DATE AS DATE) >= @FromPymtDate)
               AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.RQST_DATE AS DATE) <= @ToPymtDate)
             ) OR 
             ( @EfctDateType = '002' -- تاریخ پایان دوره
               AND (
                      (
                         RQST.RQTP_CODE = '001' AND 
                         EXISTS(
                           SELECT *
                             FROM dbo.Member_Ship ms
                            WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                              AND ms.RECT_CODE = '004'
                              AND ms.RWNO = 1
                              AND (CAST(ms.END_DATE AS DATE) >= @FromPymtDate)
                              AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.END_DATE AS DATE) <= @ToPymtDate)
                         )
                      ) OR
                      (
                         RQST.RQTP_CODE = '009' AND 
                         EXISTS(
                           SELECT *
                             FROM dbo.Member_Ship ms
                            WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                              AND ms.RECT_CODE = '004'
                              AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                              AND ms.RQRO_RWNO = RQRO.RWNO
                              AND (CAST(ms.END_DATE AS DATE) >= @FromPymtDate)
                              AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.END_DATE AS DATE) <= @ToPymtDate)
                         )
                      ) OR 
                      (
                         RQST.RQTP_CODE = '016' AND
                         (CAST(RQST.SAVE_DATE AS DATE) >= @FromPymtDate) AND 
                         (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.SAVE_DATE AS DATE) <= @ToPymtDate)
                      )
                   )                      
             ) OR 
             ( @EfctDateType = '001' -- تاریخ شروع دوره
               AND (
                      (
                         RQST.RQTP_CODE = '001' AND 
                         EXISTS(
                           SELECT *
                             FROM dbo.Member_Ship ms
                            WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                              AND ms.RECT_CODE = '004'
                              AND ms.RWNO = 1
                              AND (CAST(ms.STRT_DATE AS DATE) >= @FromPymtDate)
                              AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.STRT_DATE AS DATE) <= @ToPymtDate)
                         )
                      ) OR
                      (
                         RQST.RQTP_CODE = '009' AND 
                         EXISTS(
                           SELECT *
                             FROM dbo.Member_Ship ms
                            WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                              AND ms.RECT_CODE = '004'
                              AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                              AND ms.RQRO_RWNO = RQRO.RWNO
                              AND (CAST(ms.STRT_DATE AS DATE) >= @FromPymtDate)
                              AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.STRT_DATE AS DATE) <= @ToPymtDate)
                         )
                      ) OR 
                      (
                         RQST.RQTP_CODE = '016' AND
                         (CAST(RQST.SAVE_DATE AS DATE) >= @FromPymtDate) AND 
                         (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.SAVE_DATE AS DATE) <= @ToPymtDate)
                      )
                   )                      
             )
      )
      AND (PYDT.FIGH_FILE_NO = @CochFileNo)
      AND (EPIT.CODE = @EpitCode)
      AND (RQRQ.RQTT_CODE = @RqttCode)
      AND (pydt.MTOD_CODE_DNRM = @MtodCode)
      AND (PYDT.CTGY_CODE_DNRM = ISNULL(@CtgyCode, PYDT.CTGY_CODE_DNRM))
      AND (RQRO.RQTP_CODE = @RqtpCode)
      AND dbo.PLC_FIGH_U('<Fighter fileno="' + CAST(Figh.FILE_NO AS VARCHAR(30)) + '"/>') = '002';
   
   -- بروز کردن رکورد هایی که مبلغ کاهش در ردیف آنها لحاظ شده است
   UPDATE pe
      SET pe.EXPN_AMNT = (
             (
                (
                     CASE WHEN ISNULL(pe.PROF_AMNT, 0) > 0 THEN pe.PROF_AMNT ELSE pe.EXPN_PRIC END 
                  -  (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = pe.RQRO_RQST_RQID AND pd.PYDT_CODE_DNRM = pe.PYDT_CODE AND pd.AMNT_TYPE = '005' AND pd.STAT = '002') -- تخفیف خود مربی
                  -  (
                          pe.RDUC_AMNT -- سهم باشگاه
                       -  (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = pe.RQRO_RQST_RQID AND pd.PYDT_CODE_DNRM = pe.PYDT_CODE AND pd.AMNT_TYPE != '005' AND pd.STAT = '002') -- تخفیف باشگاه
                     )
                  
                ) * @PrctValu / 100 
             ) - 
             (
                (
                  (
                        CASE WHEN ISNULL(pe.PROF_AMNT, 0) > 0 THEN pe.PROF_AMNT ELSE pe.EXPN_PRIC END 
                     -  (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = pe.RQRO_RQST_RQID AND pd.PYDT_CODE_DNRM = pe.PYDT_CODE AND pd.AMNT_TYPE = '005' AND pd.STAT = '002') -- تخفیف خود مربی
                     -  (
                             pe.RDUC_AMNT -- سهم باشگاه
                          -  (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = pe.RQRO_RQST_RQID AND pd.PYDT_CODE_DNRM = pe.PYDT_CODE AND pd.AMNT_TYPE != '005' AND pd.STAT = '002') -- تخفیف باشگاه
                        )
                  ) * @PrctValu / 100 
                ) * @DecrPrct / 100
             )                
          )
     FROM dbo.Payment_Expense pe
    WHERE COCH_FILE_NO = @CochFileNo
      AND CALC_EXPN_TYPE = '001' -- مبلع دوره * Cycl Amnt
      and CALC_TYPE = '001' -- درصدی
      AND VALD_TYPE = '001'
      AND RDUC_AMNT > 0;
         
   GOTO NextC$CochFileNo$CalcExpnP;
   EndC$CochFileNo$CalcExpnP:
   CLOSE C$CochFileNo$CalcExpnP;
   DEALLOCATE C$CochFileNo$CalcExpnP;   
   
   -- پارت دوم
   -- محاسبه بر اساس مبلغی
   -- برای محاسبه درصدی آیتم هایی که برای مربی مشخص کرده ایم که باید بر اساس مبلغ دوره محسابه شود
   DECLARE C$CochFileNo$CalcExpnPA CURSOR FOR
      SELECT C.Coch_File_No, C.Epit_Code, C.Rqtt_Code, C.Prct_Valu,
             c.RQTP_CODE, c.MTOD_CODE, c.CTGY_CODE, C.CALC_TYPE, C.PYMT_STAT,
             C.EFCT_DATE_TYPE
        FROM Fighter F, Fighter_Public P, Calculate_Expense_Coach C
       WHERE F.File_No = C.Coch_File_No
         AND F.File_No = P.Figh_File_No 
         AND F.Fgpb_Rwno_Dnrm = P.Rwno
         AND P.Rect_Code = '004'
         /*AND ISNULL(P.Coch_Deg, '000') = ISNULL(C.Coch_Deg, '000')*/
         AND C.Stat = '002'
         AND F.ACTV_TAG_DNRM >= '101'
         AND (@CochFileNoP IS NULL OR F.File_No = @CochFileNoP)
         AND (@MtodCodeP IS NULL OR c.MTOD_CODE = @MtodCodeP)
         AND (@CtgyCodeP IS NULL OR c.CTGY_CODE = @CtgyCodeP)
         AND (@EpitCodeP IS NULL OR c.EPIT_CODE = @EpitCodeP)
         AND (@CochDegrP IS NULL OR c.COCH_DEG = @CochDegrP)
         AND (@CetpCodeP IS NULL OR c.CALC_TYPE = @CetpCodeP)
         AND (@CxtpCodeP IS NULL OR c.CALC_EXPN_TYPE = @CxtpCodeP)         
         AND (@RqtpCodeP IS NULL OR c.RQTP_CODE = @RqtpCodeP)
         AND C.CALC_TYPE = '002' /* مبلغی */
         AND c.CALC_EXPN_TYPE = '001' /* مبلغ دوره */;
    
   OPEN C$CochFileNo$CalcExpnPA;
   NextC$CochFileNo$CalcExpnPA:
   FETCH NEXT FROM C$CochFileNo$CalcExpnPA INTO 
   @CochFileNo, @EpitCode, @RqttCode, @PrctValu, @RqtpCode, @MtodCode, @CtgyCode, @CalcType, @PymtStat, @EfctDateType;
   
   IF @@FETCH_STATUS <> 0
      GOTO EndC$CochFileNo$CalcExpnPA;
      
      -- در دستور پایین باید سطوح دسترسی به رکورد را اعمال کنیم. مثلا ناحیه، باشگاه، خود هنرجو      
      INSERT INTO Payment_Expense (
         Code, PYDT_CODE, COCH_FILE_NO, VALD_TYPE, EXPN_AMNT, EXPN_PRIC, RCPT_PRIC,
         DSCN_PRIC, PRCT_VALU, DECR_PRCT_VALU, RQTP_CODE, MTOD_CODE, CTGY_CODE, 
         CLUB_CODE, DECR_AMNT_DNRM, RQRO_RQST_RQID, RQRO_RWNO, CALC_EXPN_TYPE, 
         CALC_TYPE, PYMT_STAT, MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO,
         FROM_DATE, TO_DATE, EFCT_DATE_TYPE, RECT_CODE, RECT_DATE)
      SELECT dbo.GNRT_NVID_U(),
             PYDT.CODE, 
             @CochFileNo,
             '001',
             --(PYDT.EXPN_PRIC * @PrctValu / 100) - ((PYDT.EXPN_PRIC * @PrctValu / 100) * @DecrPrct / 100),
             (@PrctValu) - (@PrctValu * @DecrPrct / 100),
             PYMT.SUM_EXPN_PRIC,
             PYMT.SUM_RCPT_EXPN_PRIC,
             PYMT.SUM_PYMT_DSCN_DNRM,
             @PrctValu,
             @DecrPrct,
             RQRO.RQTP_CODE,
             PYDT.MTOD_CODE_DNRM,
             PYDT.CTGY_CODE_DNRM,
             PYMT.CLUB_CODE_DNRM,
             (@PrctValu * @DecrPrct / 100),
             RQRO.RQST_RQID,
             RQRO.RWNO,
             '001', -- مبلغ دوره
             '002', -- مبلغی
             @PymtStat,
             RQRO.FIGH_FILE_NO,
             '004',
             CASE WHEN RQRO.RQTP_CODE = '001' THEN 1 WHEN RQRO.RQTP_CODE = '016' THEN (SELECT MBSP_RWNO_DNRM FROM dbo.Fighter WHERE FILE_NO = RQRO.FIGH_FILE_NO) ELSE (SELECT ms.RWNO FROM dbo.Member_Ship ms WHERE ms.RQRO_RQST_RQID = RQRO.RQST_RQID AND ms.RQRO_RWNO = RQRO.RWNO AND ms.RECT_CODE = '004') END,
             /*@FromPymtDate,
             @ToPymtDate,*/
             CASE RQST.RQTP_CODE
               WHEN '001' THEN (SELECT ms.STRT_DATE
                                  FROM dbo.Member_Ship ms
                                 WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                   AND ms.RECT_CODE = '004'
                                   AND ms.RWNO = 1)
               WHEN '009' THEN (SELECT ms.STRT_DATE
                                  FROM dbo.Member_Ship ms
                                 WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                   AND ms.RECT_CODE = '004'
                                   AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                                   AND ms.RQRO_RWNO = RQRO.RWNO)
               WHEN '016' THEN rqst.SAVE_DATE
             END ,
             CASE RQST.RQTP_CODE
               WHEN '001' THEN (SELECT ms.END_DATE
                                  FROM dbo.Member_Ship ms
                                 WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                   AND ms.RECT_CODE = '004'
                                   AND ms.RWNO = 1)
               WHEN '009' THEN (SELECT ms.END_DATE
                                  FROM dbo.Member_Ship ms
                                 WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                   AND ms.RECT_CODE = '004'
                                   AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                                   AND ms.RQRO_RWNO = RQRO.RWNO)
               WHEN '016' THEN rqst.SAVE_DATE
             END ,
             @EfctDateType,
             '004',
             NULL
        FROM Payment_Detail AS PYDT INNER JOIN
             dbo.Payment AS PYMT ON PYMT.CASH_CODE = PYDT.PYMT_CASH_CODE AND PYMT.RQST_RQID = PYDT.PYMT_RQST_RQID INNER JOIN
             Request_Row AS RQRO ON PYDT.PYMT_RQST_RQID = RQRO.RQST_RQID AND PYDT.RQRO_RWNO = RQRO.RWNO INNER JOIN
             Request AS RQST ON RQST.RQID = RQRO.RQST_RQID INNER JOIN             
             Fighter AS FIGH ON RQRO.FIGH_FILE_NO = FIGH.FILE_NO INNER JOIN
             Expense AS EXPN ON PYDT.EXPN_CODE = EXPN.CODE INNER JOIN
             Expense_Type EXTP ON EXPN.EXTP_CODE = EXTP.CODE INNER JOIN
             Expense_Item EPIT ON EXTP.EPIT_CODE = EPIT.CODE INNER JOIN
             Request_Requester RQRQ ON EXTP.RQRQ_CODE = RQRQ.CODE 
       WHERE (PYDT.PAY_STAT = @PymtStat) 
         AND (RQRO.RECD_STAT = '002') 
         AND (FIGH.FGPB_TYPE_DNRM NOT IN ('003','002', '004'))
         AND (
                ( @EfctDateType = '007' -- تاریخ تاییدیه تسویه حساب
                  AND (CAST(PYDT.ISSU_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(PYDT.ISSU_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '006' -- تاریخ ویرایش رکورد
                  AND (CAST(PYDT.MDFY_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(PYDT.MDFY_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '005' -- تاریخ ایجاد رکورد
                  AND (CAST(PYDT.CRET_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(PYDT.CRET_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '004' -- تاریخ تایید درخواست
                  AND (CAST(RQST.SAVE_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.SAVE_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '003' -- تاریخ ثبت درخواست
                  AND (CAST(RQST.RQST_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.RQST_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '002' -- تاریخ پایان دوره
                  AND (
                         (
                            RQST.RQTP_CODE = '001' AND 
                            EXISTS(
                              SELECT *
                                FROM dbo.Member_Ship ms
                               WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                 AND ms.RECT_CODE = '004'
                                 AND ms.RWNO = 1
                                 AND (CAST(ms.END_DATE AS DATE) >= @FromPymtDate)
                                 AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.END_DATE AS DATE) <= @ToPymtDate)
                            )
                         ) OR
                         (
                            RQST.RQTP_CODE = '009' AND 
                            EXISTS(
                              SELECT *
                                FROM dbo.Member_Ship ms
                               WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                 AND ms.RECT_CODE = '004'
                                 AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                                 AND ms.RQRO_RWNO = RQRO.RWNO
                                 AND (CAST(ms.END_DATE AS DATE) >= @FromPymtDate)
                                 AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.END_DATE AS DATE) <= @ToPymtDate)
                            )
                         ) OR 
                         (
                            RQST.RQTP_CODE = '016' AND
                            (CAST(RQST.SAVE_DATE AS DATE) >= @FromPymtDate) AND 
                            (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.SAVE_DATE AS DATE) <= @ToPymtDate)
                         )
                      )                      
                ) OR 
                ( @EfctDateType = '001' -- تاریخ شروع دوره
                  AND (
                         (
                            RQST.RQTP_CODE = '001' AND 
                            EXISTS(
                              SELECT *
                                FROM dbo.Member_Ship ms
                               WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                 AND ms.RECT_CODE = '004'
                                 AND ms.RWNO = 1
                                 AND (CAST(ms.STRT_DATE AS DATE) >= @FromPymtDate)
                                 AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.STRT_DATE AS DATE) <= @ToPymtDate)
                            )
                         ) OR
                         (
                            RQST.RQTP_CODE = '009' AND 
                            EXISTS(
                              SELECT *
                                FROM dbo.Member_Ship ms
                               WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                 AND ms.RECT_CODE = '004'
                                 AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                                 AND ms.RQRO_RWNO = RQRO.RWNO
                                 AND (CAST(ms.STRT_DATE AS DATE) >= @FromPymtDate)
                                 AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.STRT_DATE AS DATE) <= @ToPymtDate)
                            )
                         ) OR 
                         (
                            RQST.RQTP_CODE = '016' AND
                            (CAST(RQST.SAVE_DATE AS DATE) >= @FromPymtDate) AND 
                            (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.SAVE_DATE AS DATE) <= @ToPymtDate)
                         )
                      )                      
                )
         )
         AND (PYDT.FIGH_FILE_NO = @CochFileNo)
         AND (EPIT.CODE = @EpitCode)
         AND (RQRQ.RQTT_CODE = @RqttCode)
         AND (pydt.MTOD_CODE_DNRM = @MtodCode)
         AND (PYDT.CTGY_CODE_DNRM = ISNULL(@CtgyCode, PYDT.CTGY_CODE_DNRM))
         AND (RQRO.RQTP_CODE = @RqtpCode)
         AND dbo.PLC_FIGH_U('<Fighter fileno="' + CAST(Figh.FILE_NO AS VARCHAR(30)) + '"/>') = '002';
  
      -- بروز کردن رکورد هایی که مبلغ کاهش در ردیف آنها لحاظ شده است
      UPDATE pe
         SET pe.EXPN_AMNT = (
                (                   
                     pe.EXPN_AMNT
                  -  (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = pe.RQRO_RQST_RQID AND pd.AMNT_TYPE = '005' AND pd.STAT = '002') -- تخفیف خود مربی                    
                ) - 
                (
                   (
                        pe.EXPN_AMNT
                     -  (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = pe.RQRO_RQST_RQID AND pd.AMNT_TYPE = '005' AND pd.STAT = '002') -- تخفیف خود مربی                        
                   ) * @DecrPrct / 100
                )                
             )
        FROM dbo.Payment_Expense pe
       WHERE COCH_FILE_NO = @CochFileNo
         AND CALC_EXPN_TYPE = '001' -- مبلع دوره * Cycl Amnt
         and CALC_TYPE = '002' -- درصدی
         AND VALD_TYPE = '001'
         AND RDUC_AMNT > 0;
         
   GOTO NextC$CochFileNo$CalcExpnPA;
   EndC$CochFileNo$CalcExpnPA:
   CLOSE C$CochFileNo$CalcExpnPA;
   DEALLOCATE C$CochFileNo$CalcExpnPA;
   
   -- پارت سوم
   --**********************************************************************
   --************************ محاسبه تعداد جلسات ****************************
   --**********************************************************************
   
   -- برای محاسبه درصدی آیتم هایی که برای مربی مشخص کرده ایم که باید بر اساس تعداد جلسات محسابه شود
   DECLARE C$CochFileNo$CalcExpnPT CURSOR FOR
      SELECT C.Coch_File_No, C.Epit_Code, C.Rqtt_Code, C.Prct_Valu,
             c.RQTP_CODE, c.MTOD_CODE, c.CTGY_CODE, C.CALC_TYPE, C.PYMT_STAT,
             c.EFCT_DATE_TYPE, c.MIN_ATTN_STAT, c.EXPR_PAY_DAY
        FROM Fighter F, Fighter_Public P, Calculate_Expense_Coach C
       WHERE F.File_No = C.Coch_File_No
         AND F.File_No = P.Figh_File_No 
         AND F.Fgpb_Rwno_Dnrm = P.Rwno
         AND P.Rect_Code = '004'
         /*AND ISNULL(P.Coch_Deg, '000') = ISNULL(C.Coch_Deg, '000')*/
         AND C.Stat = '002'
         AND F.ACTV_TAG_DNRM >= '101'
         AND (@CochFileNoP IS NULL OR F.File_No = @CochFileNoP)
         AND (@MtodCodeP IS NULL OR c.MTOD_CODE = @MtodCodeP)
         AND (@CtgyCodeP IS NULL OR c.CTGY_CODE = @CtgyCodeP)
         AND (@EpitCodeP IS NULL OR c.EPIT_CODE = @EpitCodeP)
         AND (@CochDegrP IS NULL OR c.COCH_DEG = @CochDegrP)
         AND (@CetpCodeP IS NULL OR c.CALC_TYPE = @CetpCodeP)
         AND (@CxtpCodeP IS NULL OR c.CALC_EXPN_TYPE = @CxtpCodeP)         
         AND (@RqtpCodeP IS NULL OR c.RQTP_CODE = @RqtpCodeP)
         AND C.CALC_TYPE = '001' /* درصدی */
         AND c.CALC_EXPN_TYPE = '002' /* تعداد جلسات */;
   
   OPEN C$CochFileNo$CalcExpnPT;
   NextC$CochFileNo$CalcExpnPT:
   FETCH NEXT FROM C$CochFileNo$CalcExpnPT INTO 
   @CochFileNo, @EpitCode, @RqttCode, @PrctValu, @RqtpCode, @MtodCode, 
   @CtgyCode, @CalcType, @PymtStat, @EfctDateType, @MinAttnStat, @ExprPayDay;
   
   IF @@FETCH_STATUS <> 0
      GOTO EndC$CochFileNo$CalcExpnPT;

      -- در دستور پایین باید سطوح دسترسی به رکورد را اعمال کنیم. مثلا ناحیه، باشگاه، خود هنرجو      
      INSERT INTO Payment_Expense (
         Code, PYDT_CODE, COCH_FILE_NO, VALD_TYPE, EXPN_AMNT, EXPN_PRIC, RCPT_PRIC, 
         DSCN_PRIC, PRCT_VALU, DECR_PRCT_VALU, RQTP_CODE, MTOD_CODE, CTGY_CODE, CLUB_CODE, 
         DECR_AMNT_DNRM, RQRO_RQST_RQID, RQRO_RWNO, CALC_EXPN_TYPE, CALC_TYPE, PYMT_STAT, 
         MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO,
         FROM_DATE, TO_DATE,EFCT_DATE_TYPE, RECT_CODE, RECT_DATE)
      SELECT dbo.GNRT_NVID_U(),
             PYDT.CODE, 
             @CochFileNo,
             '001',
             (PYMT.SUM_RCPT_EXPN_PRIC /** @PrctValu / 100*/) - ((PYMT.SUM_RCPT_EXPN_PRIC /** @PrctValu / 100*/) * @DecrPrct / 100),
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
             FIGH.FILE_NO,
             '004',
             (CASE WHEN RQRO.Rqtp_Code = '001' THEN 1 ELSE (SELECT Rwno FROM dbo.Member_Ship WHERE RQRO_RQST_RQID = RQRO.RQST_RQID AND RECT_CODE = '004') END),
             /*@FromPymtDate,
             @ToPymtDate,*/
             CASE RQST.RQTP_CODE
               WHEN '001' THEN (SELECT ms.STRT_DATE
                                  FROM dbo.Member_Ship ms
                                 WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                   AND ms.RECT_CODE = '004'
                                   AND ms.RWNO = 1)
               WHEN '009' THEN (SELECT ms.STRT_DATE
                                  FROM dbo.Member_Ship ms
                                 WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                   AND ms.RECT_CODE = '004'
                                   AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                                   AND ms.RQRO_RWNO = RQRO.RWNO)
               WHEN '016' THEN rqst.SAVE_DATE
             END ,
             CASE RQST.RQTP_CODE
               WHEN '001' THEN (SELECT ms.END_DATE
                                  FROM dbo.Member_Ship ms
                                 WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                   AND ms.RECT_CODE = '004'
                                   AND ms.RWNO = 1)
               WHEN '009' THEN (SELECT ms.END_DATE
                                  FROM dbo.Member_Ship ms
                                 WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                   AND ms.RECT_CODE = '004'
                                   AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                                   AND ms.RQRO_RWNO = RQRO.RWNO)
               WHEN '016' THEN rqst.SAVE_DATE
             END ,
             @EfctDateType,
             CASE 
               WHEN @MinAttnStat = '002' AND RQST.RQTP_CODE = '001' AND 
                    EXISTS (
                       SELECT *
                         FROM dbo.Member_Ship ms
                        WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                          AND ms.RECT_CODE = '004'
                          AND ms.RWNO = 1
                          AND ms.NUMB_OF_ATTN_MONT > 0
                          AND ms.NUMB_OF_ATTN_MONT > ms.SUM_ATTN_MONT_DNRM
                    )
               THEN '005'
               WHEN @MinAttnStat = '002' AND RQST.RQTP_CODE = '009' AND 
                    EXISTS (
                       SELECT *
                         FROM dbo.Member_Ship ms
                        WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                          AND ms.RECT_CODE = '004'
                          AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                          AND ms.RQRO_RWNO = RQRO.RWNO
                          AND ms.NUMB_OF_ATTN_MONT > 0
                          AND ms.NUMB_OF_ATTN_MONT > ms.SUM_ATTN_MONT_DNRM
                    )
               THEN '005'
               ELSE '004'
             END,
             CASE 
               WHEN @MinAttnStat = '002' AND RQST.RQTP_CODE = '001' AND 
                    EXISTS (
                       SELECT *
                         FROM dbo.Member_Ship ms
                        WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                          AND ms.RECT_CODE = '004'
                          AND ms.RWNO = 1
                          AND ms.NUMB_OF_ATTN_MONT > 0
                          AND ms.NUMB_OF_ATTN_MONT > ms.SUM_ATTN_MONT_DNRM
                    )
               THEN (
                       SELECT DATEADD(DAY, @ExprPayDay, ms.END_DATE)
                         FROM dbo.Member_Ship ms
                        WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                          AND ms.RECT_CODE = '004'
                          AND ms.RWNO = 1                          
                    )
               WHEN @MinAttnStat = '002' AND RQST.RQTP_CODE = '009' AND 
                    EXISTS (
                       SELECT *
                         FROM dbo.Member_Ship ms
                        WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                          AND ms.RECT_CODE = '004'
                          AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                          AND ms.RQRO_RWNO = RQRO.RWNO
                          AND ms.NUMB_OF_ATTN_MONT > 0
                          AND ms.NUMB_OF_ATTN_MONT > ms.SUM_ATTN_MONT_DNRM
                    )
               THEN (
                       SELECT DATEADD(DAY, @ExprPayDay, ms.END_DATE)
                         FROM dbo.Member_Ship ms
                        WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                          AND ms.RECT_CODE = '004'
                          AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                          AND ms.RQRO_RWNO = RQRO.RWNO
                    )
               ELSE NULL
             END 
        FROM Payment_Detail AS PYDT INNER JOIN
             dbo.Payment AS PYMT ON PYMT.CASH_CODE = PYDT.PYMT_CASH_CODE AND PYMT.RQST_RQID = PYDT.PYMT_RQST_RQID INNER JOIN
             Request_Row AS RQRO ON PYDT.PYMT_RQST_RQID = RQRO.RQST_RQID AND PYDT.RQRO_RWNO = RQRO.RWNO INNER JOIN
             Request AS RQST ON RQST.RQID = RQRO.RQST_RQID INNER JOIN
             Fighter AS FIGH ON RQRO.FIGH_FILE_NO = FIGH.FILE_NO INNER JOIN
             Expense AS EXPN ON PYDT.EXPN_CODE = EXPN.CODE INNER JOIN
             Expense_Type EXTP ON EXPN.EXTP_CODE = EXTP.CODE INNER JOIN
             Expense_Item EPIT ON EXTP.EPIT_CODE = EPIT.CODE INNER JOIN
             Request_Requester RQRQ ON EXTP.RQRQ_CODE = RQRQ.CODE 
       WHERE (PYDT.PAY_STAT = @PymtStat) 
         AND (RQRO.RECD_STAT = '002') 
         AND (FIGH.FGPB_TYPE_DNRM NOT IN ('003','002', '004'))
         AND (
                ( @EfctDateType = '007' -- تاریخ تاییدیه تسویه حساب
                  AND (CAST(PYDT.ISSU_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(PYDT.ISSU_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '006' -- تاریخ ویرایش رکورد
                  AND (CAST(PYDT.MDFY_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(PYDT.MDFY_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '005' -- تاریخ ایجاد رکورد
                  AND (CAST(PYDT.CRET_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(PYDT.CRET_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '004' -- تاریخ تایید درخواست
                  AND (CAST(RQST.SAVE_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.SAVE_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '003' -- تاریخ ثبت درخواست
                  AND (CAST(RQST.RQST_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.RQST_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '002' -- تاریخ پایان دوره
                  AND (
                         (
                            RQST.RQTP_CODE = '001' AND 
                            EXISTS(
                              SELECT *
                                FROM dbo.Member_Ship ms
                               WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                 AND ms.RECT_CODE = '004'
                                 AND ms.RWNO = 1
                                 AND (CAST(ms.END_DATE AS DATE) >= @FromPymtDate)
                                 AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.END_DATE AS DATE) <= @ToPymtDate)
                            )
                         ) OR
                         (
                            RQST.RQTP_CODE = '009' AND 
                            EXISTS(
                              SELECT *
                                FROM dbo.Member_Ship ms
                               WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                 AND ms.RECT_CODE = '004'
                                 AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                                 AND ms.RQRO_RWNO = RQRO.RWNO
                                 AND (CAST(ms.END_DATE AS DATE) >= @FromPymtDate)
                                 AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.END_DATE AS DATE) <= @ToPymtDate)
                            )
                         ) OR 
                         (
                            RQST.RQTP_CODE = '016' AND
                            (CAST(RQST.SAVE_DATE AS DATE) >= @FromPymtDate) AND 
                            (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.SAVE_DATE AS DATE) <= @ToPymtDate)
                         )
                      )                      
                ) OR 
                ( @EfctDateType = '001' -- تاریخ شروع دوره
                  AND (
                         (
                            RQST.RQTP_CODE = '001' AND 
                            EXISTS(
                              SELECT *
                                FROM dbo.Member_Ship ms
                               WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                 AND ms.RECT_CODE = '004'
                                 AND ms.RWNO = 1
                                 AND (CAST(ms.STRT_DATE AS DATE) >= @FromPymtDate)
                                 AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.STRT_DATE AS DATE) <= @ToPymtDate)
                            )
                         ) OR
                         (
                            RQST.RQTP_CODE = '009' AND 
                            EXISTS(
                              SELECT *
                                FROM dbo.Member_Ship ms
                               WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                 AND ms.RECT_CODE = '004'
                                 AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                                 AND ms.RQRO_RWNO = RQRO.RWNO
                                 AND (CAST(ms.STRT_DATE AS DATE) >= @FromPymtDate)
                                 AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.STRT_DATE AS DATE) <= @ToPymtDate)
                            )
                         ) OR 
                         (
                            RQST.RQTP_CODE = '016' AND
                            (CAST(RQST.SAVE_DATE AS DATE) >= @FromPymtDate) AND 
                            (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.SAVE_DATE AS DATE) <= @ToPymtDate)
                         )
                      )                      
                )
         )
         AND (PYDT.FIGH_FILE_NO = @CochFileNo)
         AND (EPIT.CODE = @EpitCode)
         AND (RQRQ.RQTT_CODE = @RqttCode)
         AND (pydt.MTOD_CODE_DNRM = @MtodCode)
         AND (PYDT.CTGY_CODE_DNRM = ISNULL(@CtgyCode, PYDT.CTGY_CODE_DNRM))
         AND (RQRO.RQTP_CODE = @RqtpCode)
         AND dbo.PLC_FIGH_U('<Fighter fileno="' + CAST(Figh.FILE_NO AS VARCHAR(30)) + '"/>') = '002';
   
   UPDATE pe
      SET pe.EXPN_AMNT = 
          (
            (pe.EXPN_PRIC / ms.NUMB_OF_ATTN_MONT) * @PrctValu / 100  - 
            (((pe.EXPN_PRIC / ms.NUMB_OF_ATTN_MONT) * @PrctValu / 100) * @DecrPrct / 100)
          ) * ms.SUM_ATTN_MONT_DNRM
          -  (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = pe.RQRO_RQST_RQID AND pd.AMNT_TYPE = '005' AND pd.STAT = '002'), -- تخفیف خود مربی
          pe.TOTL_NUMB_ATTN = ms.NUMB_OF_ATTN_MONT,
          pe.RCPT_NUMB_ATTN = ms.SUM_ATTN_MONT_DNRM
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

   -- پارت چهارم
   --**********************************************************************
   --************************ محاسبه تعداد جلسات ****************************
   --**********************************************************************
   
   -- برای محاسبه درصدی آیتم هایی که برای مربی مشخص کرده ایم که باید بر اساس تعداد جلسات محسابه شود
   DECLARE C$CochFileNo$CalcExpnPO CURSOR FOR
      SELECT C.Coch_File_No, C.Epit_Code, C.Rqtt_Code, C.Prct_Valu,
             c.RQTP_CODE, c.MTOD_CODE, c.CTGY_CODE, C.CALC_TYPE, C.PYMT_STAT,
             C.EFCT_DATE_TYPE, c.MIN_ATTN_STAT, c.EXPR_PAY_DAY
        FROM Fighter F, Fighter_Public P, Calculate_Expense_Coach C
       WHERE F.File_No = C.Coch_File_No
         AND F.File_No = P.Figh_File_No 
         AND F.Fgpb_Rwno_Dnrm = P.Rwno
         AND P.Rect_Code = '004'
         /*AND ISNULL(P.Coch_Deg, '000') = ISNULL(C.Coch_Deg, '000')*/
         AND C.Stat = '002'
         AND F.ACTV_TAG_DNRM >= '101'
         AND (@CochFileNoP IS NULL OR F.File_No = @CochFileNoP)
         AND (@MtodCodeP IS NULL OR c.MTOD_CODE = @MtodCodeP)
         AND (@CtgyCodeP IS NULL OR c.CTGY_CODE = @CtgyCodeP)
         AND (@EpitCodeP IS NULL OR c.EPIT_CODE = @EpitCodeP)
         AND (@CochDegrP IS NULL OR c.COCH_DEG = @CochDegrP)
         AND (@CetpCodeP IS NULL OR c.CALC_TYPE = @CetpCodeP)
         AND (@CxtpCodeP IS NULL OR c.CALC_EXPN_TYPE = @CxtpCodeP)         
         AND (@RqtpCodeP IS NULL OR c.RQTP_CODE = @RqtpCodeP)
         AND C.CALC_TYPE = '002' /* مبلغی */
         AND c.CALC_EXPN_TYPE = '002' /* تعداد جلسات */;
   
   OPEN C$CochFileNo$CalcExpnPO;
   NextC$CochFileNo$CalcExpnPO:
   FETCH NEXT FROM C$CochFileNo$CalcExpnPO INTO 
      @CochFileNo, @EpitCode, @RqttCode, @PrctValu, @RqtpCode, 
      @MtodCode, @CtgyCode, @CalcType, @PymtStat,@EfctDateType,
      @MinAttnStat, @ExprPayDay;
   
   IF @@FETCH_STATUS <> 0
      GOTO EndC$CochFileNo$CalcExpnPO;

      -- در دستور پایین باید سطوح دسترسی به رکورد را اعمال کنیم. مثلا ناحیه، باشگاه، خود هنرجو      
      INSERT INTO Payment_Expense (
         Code, PYDT_CODE, COCH_FILE_NO, VALD_TYPE, EXPN_AMNT, EXPN_PRIC, RCPT_PRIC, 
         DSCN_PRIC, PRCT_VALU, DECR_PRCT_VALU, RQTP_CODE, MTOD_CODE, CTGY_CODE, CLUB_CODE, 
         DECR_AMNT_DNRM, RQRO_RQST_RQID, RQRO_RWNO, CALC_EXPN_TYPE, CALC_TYPE, PYMT_STAT, 
         MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO,
         FROM_DATE, TO_DATE,EFCT_DATE_TYPE, RECT_CODE, RECT_DATE)
      SELECT dbo.GNRT_NVID_U(),
             PYDT.CODE, 
             @CochFileNo,
             '001',
             (PYMT.SUM_RCPT_EXPN_PRIC /** @PrctValu / 100*/) - ((PYMT.SUM_RCPT_EXPN_PRIC /** @PrctValu / 100*/) * @DecrPrct / 100),
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
             '002', -- مبلغی
             @PymtStat,
             FIGH.FILE_NO,
             '004',
             (CASE WHEN RQRO.Rqtp_Code = '001' THEN 1 ELSE (SELECT Rwno FROM dbo.Member_Ship WHERE RQRO_RQST_RQID = RQRO.RQST_RQID AND RECT_CODE = '004') END),
             /*@FromPymtDate,
             @ToPymtDate,*/
             CASE RQST.RQTP_CODE
               WHEN '001' THEN (SELECT ms.STRT_DATE
                                  FROM dbo.Member_Ship ms
                                 WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                   AND ms.RECT_CODE = '004'
                                   AND ms.RWNO = 1)
               WHEN '009' THEN (SELECT ms.STRT_DATE
                                  FROM dbo.Member_Ship ms
                                 WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                   AND ms.RECT_CODE = '004'
                                   AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                                   AND ms.RQRO_RWNO = RQRO.RWNO)
               WHEN '016' THEN rqst.SAVE_DATE
             END ,
             CASE RQST.RQTP_CODE
               WHEN '001' THEN (SELECT ms.END_DATE
                                  FROM dbo.Member_Ship ms
                                 WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                   AND ms.RECT_CODE = '004'
                                   AND ms.RWNO = 1)
               WHEN '009' THEN (SELECT ms.END_DATE
                                  FROM dbo.Member_Ship ms
                                 WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                   AND ms.RECT_CODE = '004'
                                   AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                                   AND ms.RQRO_RWNO = RQRO.RWNO)
               WHEN '016' THEN rqst.SAVE_DATE
             END ,
             @EfctDateType,
             CASE 
               WHEN @MinAttnStat = '002' AND RQST.RQTP_CODE = '001' AND 
                    EXISTS (
                       SELECT *
                         FROM dbo.Member_Ship ms
                        WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                          AND ms.RECT_CODE = '004'
                          AND ms.RWNO = 1
                          AND ms.NUMB_OF_ATTN_MONT > 0
                          AND ms.NUMB_OF_ATTN_MONT > ms.SUM_ATTN_MONT_DNRM
                    )
               THEN '005'
               WHEN @MinAttnStat = '002' AND RQST.RQTP_CODE = '009' AND 
                    EXISTS (
                       SELECT *
                         FROM dbo.Member_Ship ms
                        WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                          AND ms.RECT_CODE = '004'
                          AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                          AND ms.RQRO_RWNO = RQRO.RWNO
                          AND ms.NUMB_OF_ATTN_MONT > 0
                          AND ms.NUMB_OF_ATTN_MONT > ms.SUM_ATTN_MONT_DNRM
                    )
               THEN '005'
               ELSE '004'
             END,
             CASE 
               WHEN @MinAttnStat = '002' AND RQST.RQTP_CODE = '001' AND 
                    EXISTS (
                       SELECT *
                         FROM dbo.Member_Ship ms
                        WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                          AND ms.RECT_CODE = '004'
                          AND ms.RWNO = 1
                          AND ms.NUMB_OF_ATTN_MONT > 0
                          AND ms.NUMB_OF_ATTN_MONT > ms.SUM_ATTN_MONT_DNRM
                    )
               THEN (
                       SELECT DATEADD(DAY, @ExprPayDay, ms.END_DATE)
                         FROM dbo.Member_Ship ms
                        WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                          AND ms.RECT_CODE = '004'
                          AND ms.RWNO = 1                          
                    )
               WHEN @MinAttnStat = '002' AND RQST.RQTP_CODE = '009' AND 
                    EXISTS (
                       SELECT *
                         FROM dbo.Member_Ship ms
                        WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                          AND ms.RECT_CODE = '004'
                          AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                          AND ms.RQRO_RWNO = RQRO.RWNO
                          AND ms.NUMB_OF_ATTN_MONT > 0
                          AND ms.NUMB_OF_ATTN_MONT > ms.SUM_ATTN_MONT_DNRM
                    )
               THEN (
                       SELECT DATEADD(DAY, @ExprPayDay, ms.END_DATE)
                         FROM dbo.Member_Ship ms
                        WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                          AND ms.RECT_CODE = '004'
                          AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                          AND ms.RQRO_RWNO = RQRO.RWNO
                    )
               ELSE NULL
             END
        FROM Payment_Detail AS PYDT INNER JOIN
             dbo.Payment AS PYMT ON PYMT.CASH_CODE = PYDT.PYMT_CASH_CODE AND PYMT.RQST_RQID = PYDT.PYMT_RQST_RQID INNER JOIN
             Request_Row AS RQRO ON PYDT.PYMT_RQST_RQID = RQRO.RQST_RQID AND PYDT.RQRO_RWNO = RQRO.RWNO INNER JOIN
             Request AS RQST ON RQST.RQID = RQRO.RQST_RQID INNER JOIN
             Fighter AS FIGH ON RQRO.FIGH_FILE_NO = FIGH.FILE_NO INNER JOIN
             Expense AS EXPN ON PYDT.EXPN_CODE = EXPN.CODE INNER JOIN
             Expense_Type EXTP ON EXPN.EXTP_CODE = EXTP.CODE INNER JOIN
             Expense_Item EPIT ON EXTP.EPIT_CODE = EPIT.CODE INNER JOIN
             Request_Requester RQRQ ON EXTP.RQRQ_CODE = RQRQ.CODE 
       WHERE (PYDT.PAY_STAT = @PymtStat) 
         AND (RQRO.RECD_STAT = '002') 
         AND (FIGH.FGPB_TYPE_DNRM NOT IN ('003','002', '004'))
         AND (
                ( @EfctDateType = '007' -- تاریخ ویرایش رکورد
                  AND (CAST(PYDT.ISSU_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(PYDT.ISSU_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '006' -- تاریخ ویرایش رکورد
                  AND (CAST(PYDT.MDFY_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(PYDT.MDFY_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '005' -- تاریخ ایجاد رکورد
                  AND (CAST(PYDT.CRET_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(PYDT.CRET_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '004' -- تاریخ تایید درخواست
                  AND (CAST(RQST.SAVE_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.SAVE_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '003' -- تاریخ ثبت درخواست
                  AND (CAST(RQST.RQST_DATE AS DATE) >= @FromPymtDate)
                  AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.RQST_DATE AS DATE) <= @ToPymtDate)
                ) OR 
                ( @EfctDateType = '002' -- تاریخ پایان دوره
                  AND (
                         (
                            RQST.RQTP_CODE = '001' AND 
                            EXISTS(
                              SELECT *
                                FROM dbo.Member_Ship ms
                               WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                 AND ms.RECT_CODE = '004'
                                 AND ms.RWNO = 1
                                 AND (CAST(ms.END_DATE AS DATE) >= @FromPymtDate)
                                 AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.END_DATE AS DATE) <= @ToPymtDate)
                            )
                         ) OR
                         (
                            RQST.RQTP_CODE = '009' AND 
                            EXISTS(
                              SELECT *
                                FROM dbo.Member_Ship ms
                               WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                 AND ms.RECT_CODE = '004'
                                 AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                                 AND ms.RQRO_RWNO = RQRO.RWNO
                                 AND (CAST(ms.END_DATE AS DATE) >= @FromPymtDate)
                                 AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.END_DATE AS DATE) <= @ToPymtDate)
                            )
                         ) OR 
                         (
                            RQST.RQTP_CODE = '016' AND
                            (CAST(RQST.SAVE_DATE AS DATE) >= @FromPymtDate) AND 
                            (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.SAVE_DATE AS DATE) <= @ToPymtDate)
                         )
                      )                      
                ) OR 
                ( @EfctDateType = '001' -- تاریخ شروع دوره
                  AND (
                         (
                            RQST.RQTP_CODE = '001' AND 
                            EXISTS(
                              SELECT *
                                FROM dbo.Member_Ship ms
                               WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                 AND ms.RECT_CODE = '004'
                                 AND ms.RWNO = 1
                                 AND (CAST(ms.STRT_DATE AS DATE) >= @FromPymtDate)
                                 AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.STRT_DATE AS DATE) <= @ToPymtDate)
                            )
                         ) OR
                         (
                            RQST.RQTP_CODE = '009' AND 
                            EXISTS(
                              SELECT *
                                FROM dbo.Member_Ship ms
                               WHERE ms.FIGH_FILE_NO = FIGH.FILE_NO
                                 AND ms.RECT_CODE = '004'
                                 AND ms.RQRO_RQST_RQID = RQRO.RQST_RQID
                                 AND ms.RQRO_RWNO = RQRO.RWNO
                                 AND (CAST(ms.STRT_DATE AS DATE) >= @FromPymtDate)
                                 AND (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(ms.STRT_DATE AS DATE) <= @ToPymtDate)
                            )
                         ) OR 
                         (
                            RQST.RQTP_CODE = '016' AND
                            (CAST(RQST.SAVE_DATE AS DATE) >= @FromPymtDate) AND 
                            (@ToPymtDate IN ('1900-01-01', '0001-01-01') OR CAST(RQST.SAVE_DATE AS DATE) <= @ToPymtDate)
                         )
                      )                      
                )
         )
         AND (PYDT.FIGH_FILE_NO = @CochFileNo)
         AND (EPIT.CODE = @EpitCode)
         AND (RQRQ.RQTT_CODE = @RqttCode)
         AND (pydt.MTOD_CODE_DNRM = @MtodCode)
         AND (PYDT.CTGY_CODE_DNRM = ISNULL(@CtgyCode, PYDT.CTGY_CODE_DNRM))
         AND (RQRO.RQTP_CODE = @RqtpCode)
         AND dbo.PLC_FIGH_U('<Fighter fileno="' + CAST(Figh.FILE_NO AS VARCHAR(30)) + '"/>') = '002';
   
   UPDATE pe
      SET pe.EXPN_AMNT = 
          (
            @PrctValu - 
            (@PrctValu * @DecrPrct / 100)
          ) * ms.SUM_ATTN_MONT_DNRM
          -  (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = pe.RQRO_RQST_RQID AND pd.AMNT_TYPE = '005' AND pd.STAT = '002'), -- تخفیف خود مربی
          pe.TOTL_NUMB_ATTN = ms.NUMB_OF_ATTN_MONT,
          pe.RCPT_NUMB_ATTN = ms.SUM_ATTN_MONT_DNRM
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
      AND pe.CALC_TYPE = '002'; -- مبلغی            

   GOTO NextC$CochFileNo$CalcExpnPO;
   EndC$CochFileNo$CalcExpnPO:
   CLOSE C$CochFileNo$CalcExpnPO;
   DEALLOCATE C$CochFileNo$CalcExpnPO;
   
   -- پارت پنجم
   --**********************************************************************
   --************************ محاسبه مربیان ساعتی ***************************
   --**********************************************************************
   DECLARE C$CochFileNo$CalcExpnPH CURSOR FOR
      SELECT C.Coch_File_No, C.Epit_Code, C.Rqtt_Code, C.Prct_Valu,
             c.RQTP_CODE, c.MTOD_CODE, c.CTGY_CODE, C.CALC_TYPE, C.PYMT_STAT,C.EFCT_DATE_TYPE
        FROM Fighter F, Fighter_Public P, Calculate_Expense_Coach C
       WHERE F.File_No = C.Coch_File_No
         AND F.File_No = P.Figh_File_No 
         AND F.Fgpb_Rwno_Dnrm = P.Rwno
         AND P.Rect_Code = '004'
         --AND P.Coch_Deg = C.Coch_Deg
         AND C.Stat = '002'
         AND F.ACTV_TAG_DNRM >= '101'
         AND (@CochFileNoP IS NULL OR F.File_No = @CochFileNoP)
         AND (@MtodCodeP IS NULL OR c.MTOD_CODE = @MtodCodeP)
         --AND (@CtgyCodeP IS NULL OR c.CTGY_CODE = @CtgyCodeP)
         --AND (@EpitCodeP IS NULL OR c.EPIT_CODE = @EpitCodeP)
         --AND (@CochDegrP IS NULL OR c.COCH_DEG = @CochDegrP)
         --AND (@CetpCodeP IS NULL OR c.CALC_TYPE = @CetpCodeP)
         AND (@CxtpCodeP IS NULL OR c.CALC_EXPN_TYPE = @CxtpCodeP)
         --AND (@RqtpCodeP IS NULL OR c.RQTP_CODE = @RqtpCodeP)
         AND c.CALC_EXPN_TYPE = '003' /* محاسبه ساعتی */;
   
   OPEN C$CochFileNo$CalcExpnPH;
   NextC$CochFileNo$CalcExpnPH:
   FETCH NEXT FROM C$CochFileNo$CalcExpnPH INTO 
   @CochFileNo, @EpitCode, @RqttCode, @PrctValu, @RqtpCode, @MtodCode, @CtgyCode, @CalcType, @PymtStat, @EfctDateType;
   
   IF @@FETCH_STATUS <> 0
      GOTO EndC$CochFileNo$CalcExpnPH;
   
   DECLARE @Hors INT,
           @Mint INT,
           @NumbAttnDay INT,
           @ClubCode BIGINT,
           @MbspRwno SMALLINT;
   
   SELECT @MbspRwno = f.MBSP_RWNO_DNRM
     FROM dbo.Fighter f
    WHERE f.FILE_NO = @CochFileNo;    
   
   JUMPS$CbmtPH:
   SELECT TOP 1 @ClubCode = cm.CLUB_CODE
     FROM dbo.Club_Method cm
    WHERE cm.COCH_FILE_NO = @CochFileNo
      AND MTOD_CODE = @MtodCode
      AND MTOD_STAT = '002'
      AND NOT EXISTS(
          SELECT *
            FROM dbo.Payment_Expense pe
           WHERE pe.CLUB_CODE = cm.CLUB_CODE
             AND pe.COCH_FILE_NO = cm.COCH_FILE_NO
             AND pe.MTOD_CODE = cm.MTOD_CODE
             AND pe.CALC_EXPN_TYPE = '003' /* محاسبه ساعتی */
      );
   
   IF @ClubCode IS NULL
      GOTO ENDJUMPS$CmbtPH;
   
   SELECT @Mint = SUM(DATEDIFF(MINUTE, STRT_TIME, END_TIME))
     FROM dbo.Club_Method
    WHERE COCH_FILE_NO = @CochFileNo
      AND MTOD_CODE = @MtodCode
      AND CLUB_CODE = @ClubCode
      AND MTOD_STAT = '002';
   
   SELECT @Hors = @Mint / 60
         ,@Mint = @Mint % 60;
   
   SELECT @NumbAttnDay = COUNT(DISTINCT CAST(a.ATTN_DATE AS DATE))
     FROM dbo.Attendance a
    WHERE a.FIGH_FILE_NO = @CochFileNo
      --AND a.MTOD_CODE_DNRM = @MtodCode
      AND CAST(a.ATTN_DATE AS DATE) BETWEEN CAST(@FromPymtDate AS DATE) AND CAST(@ToPymtDate AS DATE)      
      AND a.ATTN_STAT = '002'
      AND EXISTS(
          SELECT *
            FROM dbo.Club_Method cm , dbo.Club_Method_Weekday cmw
           WHERE cm.CODE = cmw.CBMT_CODE
             AND cmw.STAT = '002'
             AND cm.COCH_FILE_NO = @CochFileNo
             AND cm.MTOD_CODE = @MtodCode
             AND cm.CLUB_CODE = @ClubCode
             AND cm.MTOD_STAT = '002'
             AND dbo.GET_PSTR_U(DATEPART(WEEKDAY, a.ATTN_DATE), 3) = cmw.WEEK_DAY
      );
      
   DECLARE @TotlHors INT = @NumbAttnDay * @Hors
          ,@TotlMint INT = @NumbAttnDay * @Mint;
   
   IF @TotlMint > 0 AND @TotlMint > 60
   BEGIN
      SELECT @TotlHors = @TotlHors + @TotlMint / 60
            ,@TotlMint = @TotlMint % 60;
   END
   
   INSERT INTO Payment_Expense (
      Code, PYDT_CODE, COCH_FILE_NO, VALD_TYPE, EXPN_AMNT, EXPN_PRIC, RCPT_PRIC, 
      DSCN_PRIC, PRCT_VALU, DECR_PRCT_VALU, RQTP_CODE, MTOD_CODE, CTGY_CODE, 
      CLUB_CODE, DECR_AMNT_DNRM, RQRO_RQST_RQID, RQRO_RWNO, CALC_EXPN_TYPE, 
      CALC_TYPE, PYMT_STAT, MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO,
      FROM_DATE, TO_DATE, NUMB_HORS, NUMB_MINT, NUMB_DAYS, EFCT_DATE_TYPE, RECT_CODE, RECT_DATE
   )
   SELECT dbo.GNRT_NVID_U(), NULL, @CochFileNo,'001',
          (@TotlHors * @PrctValu + (@PrctValu / 60) * @TotlMint) - ((@TotlHors * @PrctValu + (@PrctValu / 60) * @TotlMint) * @DecrPrct / 100),
          (@TotlHors * @PrctValu + (@PrctValu / 60) * @TotlMint),0,0,@PrctValu,@DecrPrct,NULL,@MtodCode,
          NULL,@ClubCode,
          ((@TotlHors * @PrctValu + (@PrctValu / 60) * @TotlMint) * @DecrPrct / 100),
          NULL,NULL,
          '003', -- محاسبه ساعتی
          '002', -- مبلغی
          NULL,@CochFileNo,'004',@MbspRwno,
          @FromPymtDate, @ToPymtDate, @TotlHors, @TotlMint, @NumbAttnDay, @EfctDateType,
          '004', NULL;
   
   SET @ClubCode = NULL;             
   GOTO JUMPS$CbmtPH;   
   ENDJUMPS$CmbtPH:
   
   GOTO NextC$CochFileNo$CalcExpnPH;
   EndC$CochFileNo$CalcExpnPH:
   CLOSE C$CochFileNo$CalcExpnPH;
   DEALLOCATE C$CochFileNo$CalcExpnPH;
   
   -- پارت ششم
   --**********************************************************************
   --************************ محاسبه مربیان روزکاری ***************************
   --**********************************************************************
   DECLARE C$CochFileNo$CalcExpnPD CURSOR FOR
      SELECT C.Coch_File_No, C.Epit_Code, C.Rqtt_Code, C.Prct_Valu,
             c.RQTP_CODE, c.MTOD_CODE, c.CTGY_CODE, C.CALC_TYPE, C.PYMT_STAT, c.EFCT_DATE_TYPE
        FROM Fighter F, Fighter_Public P, Calculate_Expense_Coach C
       WHERE F.File_No = C.Coch_File_No
         AND F.File_No = P.Figh_File_No 
         AND F.Fgpb_Rwno_Dnrm = P.Rwno
         AND P.Rect_Code = '004'
         --AND P.Coch_Deg = C.Coch_Deg
         AND C.Stat = '002'
         AND F.ACTV_TAG_DNRM >= '101'
         AND (@CochFileNoP IS NULL OR F.File_No = @CochFileNoP)
         AND (@MtodCodeP IS NULL OR c.MTOD_CODE = @MtodCodeP)
         --AND (@CtgyCodeP IS NULL OR c.CTGY_CODE = @CtgyCodeP)
         --AND (@EpitCodeP IS NULL OR c.EPIT_CODE = @EpitCodeP)
         --AND (@CochDegrP IS NULL OR c.COCH_DEG = @CochDegrP)
         --AND (@CetpCodeP IS NULL OR c.CALC_TYPE = @CetpCodeP)
         AND (@CxtpCodeP IS NULL OR c.CALC_EXPN_TYPE = @CxtpCodeP)
         --AND (@RqtpCodeP IS NULL OR c.RQTP_CODE = @RqtpCodeP)
         AND c.CALC_EXPN_TYPE = '004' /* محاسبه روزکاری */;
   
   OPEN C$CochFileNo$CalcExpnPD;
   NextC$CochFileNo$CalcExpnPD:
   FETCH NEXT FROM C$CochFileNo$CalcExpnPD INTO 
   @CochFileNo, @EpitCode, @RqttCode, @PrctValu, @RqtpCode, @MtodCode, @CtgyCode, @CalcType, @PymtStat, @EfctDateType;
   
   IF @@FETCH_STATUS <> 0
      GOTO EndC$CochFileNo$CalcExpnPD;
   
   SELECT @MbspRwno = MBSP_RWNO_DNRM
     FROM dbo.Fighter
    WHERE FILE_NO = @CochFileNo;
   
   JUMPS$CbmtPD:
   SELECT @ClubCode = a.CLUB_CODE
         ,@NumbAttnDay = COUNT(DISTINCT CAST(a.ATTN_DATE AS DATE))
     FROM dbo.Attendance a
    WHERE a.FIGH_FILE_NO = @CochFileNo
      AND CAST(a.ATTN_DATE AS DATE) BETWEEN CAST(@FromPymtDate AS DATE) AND CAST(@ToPymtDate AS DATE)
      AND a.ATTN_STAT = '002'
      AND EXISTS(
          SELECT *
            FROM dbo.Club_Method cm , dbo.Club_Method_Weekday cmw
           WHERE cm.CODE = cmw.CBMT_CODE
             AND cmw.STAT = '002'
             AND cm.COCH_FILE_NO = @CochFileNo
             AND cm.MTOD_CODE = @MtodCode
             --AND cm.CLUB_CODE = a.CLUB_CODE
             AND cm.MTOD_STAT = '002'
             AND dbo.GET_PSTR_U(DATEPART(WEEKDAY, a.ATTN_DATE), 3) = cmw.WEEK_DAY
      )
      AND NOT EXISTS(
          SELECT *
            FROM dbo.Payment_Expense pe
           WHERE pe.CLUB_CODE = a.CLUB_CODE
             AND pe.COCH_FILE_NO = a.FIGH_FILE_NO
             AND pe.MTOD_CODE = @MtodCode
             AND pe.CALC_EXPN_TYPE = '004'
      )
 GROUP BY a.CLUB_CODE;
   
   IF @ClubCode IS NULL
      GOTO ENDJUMPS$CmbtPD;
      
   INSERT INTO Payment_Expense (
      Code, PYDT_CODE, COCH_FILE_NO, VALD_TYPE, EXPN_AMNT, EXPN_PRIC, RCPT_PRIC, 
      DSCN_PRIC, PRCT_VALU, DECR_PRCT_VALU, RQTP_CODE, MTOD_CODE, CTGY_CODE, 
      CLUB_CODE, DECR_AMNT_DNRM, RQRO_RQST_RQID, RQRO_RWNO, CALC_EXPN_TYPE, 
      CALC_TYPE, PYMT_STAT, MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO,
      FROM_DATE, TO_DATE, NUMB_DAYS, EFCT_DATE_TYPE, RECT_CODE, RECT_DATE)
      SELECT dbo.GNRT_NVID_U(), NULL, @CochFileNo,'001',
             (@NumbAttnDay * @PrctValu) - ((@NumbAttnDay * @PrctValu) * @DecrPrct / 100),
             (@NumbAttnDay * @PrctValu),0,0,@PrctValu,@DecrPrct,NULL,@MtodCode,
             NULL,@ClubCode,
             ((@NumbAttnDay * @PrctValu) * @DecrPrct / 100),
             NULL,NULL,
             '004', -- محاسبه روزکاری
             '002', -- مبلغی
             NULL,@CochFileNo,'004',@MbspRwno,
             @FromPymtDate, @ToPymtDate, @NumbAttnDay, @EfctDateType, '004', NULL;

   SET @ClubCode = NULL;             
   GOTO JUMPS$CbmtPD;   
   ENDJUMPS$CmbtPD:
      
   GOTO NextC$CochFileNo$CalcExpnPD;
   EndC$CochFileNo$CalcExpnPD:
   CLOSE C$CochFileNo$CalcExpnPD;
   DEALLOCATE C$CochFileNo$CalcExpnPD;

   -- پارت هفتم
   --**********************************************************************
   --************* محاسبه مربیان برای تعداد جلسات گروهی اعضا **************
   --**********************************************************************
   DECLARE C$CochFileNo$CalcExpnPAG CURSOR FOR
      SELECT C.Coch_File_No, C.Epit_Code, C.Rqtt_Code, C.Prct_Valu,
             c.RQTP_CODE, c.MTOD_CODE, c.CTGY_CODE, C.CALC_TYPE, C.PYMT_STAT, 
             c.MIN_NUMB_ATTN, C.EFCT_DATE_TYPE
        FROM Fighter F, Fighter_Public P, Calculate_Expense_Coach C
       WHERE F.File_No = C.Coch_File_No
         AND F.File_No = P.Figh_File_No 
         AND F.Fgpb_Rwno_Dnrm = P.Rwno
         AND P.Rect_Code = '004'
         --AND P.Coch_Deg = C.Coch_Deg
         AND C.Stat = '002'
         AND F.ACTV_TAG_DNRM >= '101'
         AND (@CochFileNoP IS NULL OR F.File_No = @CochFileNoP)
         AND (@MtodCodeP IS NULL OR c.MTOD_CODE = @MtodCodeP)
         AND (@CtgyCodeP IS NULL OR c.CTGY_CODE = @CtgyCodeP)
         --AND (@EpitCodeP IS NULL OR c.EPIT_CODE = @EpitCodeP)
         --AND (@CochDegrP IS NULL OR c.COCH_DEG = @CochDegrP)
         --AND (@CetpCodeP IS NULL OR c.CALC_TYPE = @CetpCodeP)
         AND (@CxtpCodeP IS NULL OR c.CALC_EXPN_TYPE = @CxtpCodeP)
         --AND (@RqtpCodeP IS NULL OR c.RQTP_CODE = @RqtpCodeP)
         AND c.CALC_EXPN_TYPE = '005' /* محاسبه تعداد جلسات گروهی */;
   
   DECLARE @MinNumbAttn SMALLINT;          
   
   OPEN C$CochFileNo$CalcExpnPAG;
   NextC$CochFileNo$CalcExpnPAG:
   FETCH NEXT FROM C$CochFileNo$CalcExpnPAG INTO 
   @CochFileNo, @EpitCode, @RqttCode, @PrctValu, @RqtpCode, @MtodCode, @CtgyCode, @CalcType, @PymtStat, @MinNumbAttn, @EfctDateType;
   
   IF @@FETCH_STATUS <> 0
      GOTO EndC$CochFileNo$CalcExpnPAG;
   
   SELECT @MbspRwno = MBSP_RWNO_DNRM
     FROM dbo.Fighter
    WHERE FILE_NO = @CochFileNo;
   
   DECLARE @TotlAttnNumb INT;
      
   SELECT @ClubCode = a.CLUB_CODE
         ,@TotlAttnNumb = COUNT(a.CODE)
     FROM dbo.Attendance a
    WHERE a.COCH_FILE_NO = @CochFileNo
      AND a.ATTN_DATE <= @ToPymtDate
      AND ( a.RCPT_STAT IS NULL OR a.RCPT_STAT = '001' )
      AND a.MTOD_CODE_DNRM = @MtodCode
      AND a.CTGY_CODE_DNRM = @CtgyCode
      AND a.ATTN_STAT = '002'
      AND a.ATTN_TYPE NOT IN ('002')
    GROUP BY a.CLUB_CODE;

   IF ( @TotlAttnNumb / @MinNumbAttn ) >= 1
   BEGIN
      SET @PmexCode = dbo.GNRT_NVID_U();
      INSERT INTO Payment_Expense (
         Code, PYDT_CODE, COCH_FILE_NO, VALD_TYPE, EXPN_AMNT, EXPN_PRIC, RCPT_PRIC, 
         DSCN_PRIC, PRCT_VALU, DECR_PRCT_VALU, RQTP_CODE, MTOD_CODE, CTGY_CODE, 
         CLUB_CODE, DECR_AMNT_DNRM, RQRO_RQST_RQID, RQRO_RWNO, CALC_EXPN_TYPE, 
         CALC_TYPE, PYMT_STAT, MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO,
         FROM_DATE, TO_DATE, TOTL_NUMB_ATTN, RCPT_NUMB_ATTN, MIN_NUMB_ATTN, NUMB_PKET_ATTN ,
         EFCT_DATE_TYPE, RECT_CODE, RECT_DATE)
         SELECT @PmexCode, NULL, @CochFileNo,'001',
                ((@TotlAttnNumb / @MinNumbAttn) * @PrctValu) - (((@TotlAttnNumb / @MinNumbAttn) * @PrctValu) * @DecrPrct / 100),
                ((@TotlAttnNumb / @MinNumbAttn) * @PrctValu),0,0,@PrctValu,@DecrPrct,NULL,@MtodCode,
                @CtgyCode,@ClubCode,
                (((@TotlAttnNumb / @MinNumbAttn) * @PrctValu) * @DecrPrct / 100),
                NULL,NULL,
                '005', -- محاسبه جلسات گروهی
                '002', -- مبلغی
                NULL,@CochFileNo,'004',@MbspRwno,
                @FromPymtDate, @ToPymtDate, @TotlAttnNumb, (@TotlAttnNumb) - (@TotlAttnNumb % @MinNumbAttn),
                @MinNumbAttn, (@TotlAttnNumb / @MinNumbAttn), @EfctDateType,
                '004', NULL;
      
      -- تنظیم کردن ستون جدول حضور و غیاب برای اعضا که با مربی حساب شده است
      UPDATE dbo.Attendance
         SET RCPT_STAT = '002'
            ,PMEX_CODE = @PmexCode
       WHERE CODE IN (
             SELECT TOP ((@TotlAttnNumb) - (@TotlAttnNumb % @MinNumbAttn)) 
                    CODE
               FROM dbo.Attendance
              WHERE COCH_FILE_NO = @CochFileNo
                AND MTOD_CODE_DNRM = @MtodCode
                AND CTGY_CODE_DNRM = @CtgyCode
                AND (RCPT_STAT IS NULL OR RCPT_STAT = '001')
                AND ATTN_STAT = '002'
                AND ATTN_TYPE NOT IN ('002')
                AND ATTN_DATE <= @ToPymtDate
       );
   END;
   
   GOTO NextC$CochFileNo$CalcExpnPAG;
   EndC$CochFileNo$CalcExpnPAG:
   CLOSE C$CochFileNo$CalcExpnPAG;
   DEALLOCATE C$CochFileNo$CalcExpnPAG;

   -- پارت هشتم
   -- محاسبه بر اساس مبلغی برای هر سانس عمومی
   -- برای محاسبه مشخص میکنیم که در این سانس آیا مربی ثبت نامی عمومی داشته یا نه اگر داشته باشد مبلغی به آن اضافه میکنیم
   DECLARE C$CochFileNo$CalcExpnPI CURSOR FOR
      SELECT C.Coch_File_No, C.CBMT_CODE, C.Rqtt_Code, C.Prct_Valu,
             c.RQTP_CODE, c.MTOD_CODE, c.CTGY_CODE, C.CALC_TYPE, C.PYMT_STAT, C.EFCT_DATE_TYPE
        FROM Fighter F, Fighter_Public P, Calculate_Expense_Coach C
       WHERE F.File_No = C.Coch_File_No
         AND F.File_No = P.Figh_File_No 
         AND F.Fgpb_Rwno_Dnrm = P.Rwno
         AND P.Rect_Code = '004'
         /*AND ISNULL(P.Coch_Deg, '000') = ISNULL(C.Coch_Deg, '000')*/
         AND C.Stat = '002'
         AND F.ACTV_TAG_DNRM >= '101'
         AND (@CochFileNoP IS NULL OR F.File_No = @CochFileNoP)
         AND (@MtodCodeP IS NULL OR c.MTOD_CODE = @MtodCodeP)
         AND (@CtgyCodeP IS NULL OR c.CTGY_CODE = @CtgyCodeP)
         AND (@EpitCodeP IS NULL OR c.EPIT_CODE = @EpitCodeP)
         AND (@CochDegrP IS NULL OR c.COCH_DEG = @CochDegrP)
         AND (@CetpCodeP IS NULL OR c.CALC_TYPE = @CetpCodeP)
         AND (@CxtpCodeP IS NULL OR c.CALC_EXPN_TYPE = @CxtpCodeP)         
         AND (@RqtpCodeP IS NULL OR c.RQTP_CODE = @RqtpCodeP)
         AND C.CALC_TYPE = '002' /* مبلغی */
         AND c.CALC_EXPN_TYPE = '006' /* مبلغ برای هر سانس */;
    
   OPEN C$CochFileNo$CalcExpnPI;
   NextC$CochFileNo$CalcExpnPI:
   FETCH NEXT FROM C$CochFileNo$CalcExpnPI INTO 
   @CochFileNo, @CbmtCode, @RqttCode, @PrctValu, @RqtpCode, @MtodCode, @CtgyCode, @CalcType, @PymtStat, @EfctDateType;
   
   SELECT @MbspRwno = f.MBSP_RWNO_DNRM
     FROM dbo.Fighter f
    WHERE f.FILE_NO = @CochFileNo;
   
   SELECT @ClubCode = CLUB_CODE
     FROM dbo.Club_Method
    WHERE CODE = @CbmtCode;    
   
   IF @@FETCH_STATUS <> 0
      GOTO EndC$CochFileNo$CalcExpnPI;
      
      IF EXISTS(
         SELECT *
           FROM dbo.[VF$Coach_MemberShip](REPLACE('<Club_Method code="{0}"/>', '{0}', @CbmtCode))
          WHERE CTGY_CODE = ISNULL(@CtgyCode, CTGY_CODE)
            AND STRT_DATE BETWEEN @FromPymtDate AND @ToPymtDate
      )
      AND NOT EXISTS(
         SELECT *
           FROM dbo.Payment_Expense
          WHERE CALC_EXPN_TYPE = '006'
            AND CALC_TYPE = '002'
            AND COCH_FILE_NO = @CochFileNo
            AND FROM_DATE = @FromPymtDate
            AND TO_DATE = @ToPymtDate
            AND CLUB_CODE = @ClubCode
            AND MTOD_CODE = @MtodCode
            AND CTGY_CODE = ISNULL(@CtgyCode, CTGY_CODE)
            AND CBMT_CODE = @CbmtCode
      )
      BEGIN
         INSERT INTO Payment_Expense (
            Code, PYDT_CODE, COCH_FILE_NO, VALD_TYPE, EXPN_AMNT, EXPN_PRIC, RCPT_PRIC, 
            DSCN_PRIC, PRCT_VALU, DECR_PRCT_VALU, RQTP_CODE, MTOD_CODE, CTGY_CODE, 
            CLUB_CODE, DECR_AMNT_DNRM, RQRO_RQST_RQID, RQRO_RWNO, CALC_EXPN_TYPE, 
            CALC_TYPE, PYMT_STAT, MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO,
            FROM_DATE, TO_DATE, CBMT_CODE, EFCT_DATE_TYPE, RECT_CODE, RECT_DATE
         )
         SELECT dbo.GNRT_NVID_U(), NULL, @CochFileNo,'001',
                (@PrctValu) - (@PrctValu * @DecrPrct / 100),NULL,NULL,
                NULL,@PrctValu,@DecrPrct,NULL,@MtodCode,@CtgyCode,
                @ClubCode,
                (@PrctValu * @DecrPrct / 100),
                NULL,NULL,
                '006', -- مبلغ سانس کلاسی
                '002', -- مبلغی
                NULL,@CochFileNo,'004',@MbspRwno,
                @FromPymtDate, @ToPymtDate, @CbmtCode, @EfctDateType,
                '004', NULL;
      END;
  
   GOTO NextC$CochFileNo$CalcExpnPI;
   EndC$CochFileNo$CalcExpnPI:
   CLOSE C$CochFileNo$CalcExpnPI;
   DEALLOCATE C$CochFileNo$CalcExpnPI;

   -- پارت نهم
   -- محاسبه بر اساس مبلغی ثابت برای هر ماه
   -- برای محاسبه مشخص میکنیم که در این سانس آیا مربی ثبت نامی عمومی داشته یا نه اگر داشته باشد مبلغی به آن اضافه میکنیم
   DECLARE C$CochFileNo$CalcExpnPK CURSOR FOR
      SELECT C.Coch_File_No, C.CBMT_CODE, C.Rqtt_Code, C.Prct_Valu,
             c.RQTP_CODE, c.MTOD_CODE, c.CTGY_CODE, C.CALC_TYPE, C.PYMT_STAT, C.EFCT_DATE_TYPE
        FROM Fighter F, Fighter_Public P, Calculate_Expense_Coach C
       WHERE F.File_No = C.Coch_File_No
         AND F.File_No = P.Figh_File_No 
         AND F.Fgpb_Rwno_Dnrm = P.Rwno
         AND P.Rect_Code = '004'
         /*AND ISNULL(P.Coch_Deg, '000') = ISNULL(C.Coch_Deg, '000')*/
         AND C.Stat = '002'
         AND F.ACTV_TAG_DNRM >= '101'
         AND (@CochFileNoP IS NULL OR F.File_No = @CochFileNoP)
         AND (@MtodCodeP IS NULL OR c.MTOD_CODE = @MtodCodeP)
         AND (@CtgyCodeP IS NULL OR c.CTGY_CODE = @CtgyCodeP)
         AND (@EpitCodeP IS NULL OR c.EPIT_CODE = @EpitCodeP)
         AND (@CochDegrP IS NULL OR c.COCH_DEG = @CochDegrP)
         AND (@CetpCodeP IS NULL OR c.CALC_TYPE = @CetpCodeP)
         AND (@CxtpCodeP IS NULL OR c.CALC_EXPN_TYPE = @CxtpCodeP)         
         AND (@RqtpCodeP IS NULL OR c.RQTP_CODE = @RqtpCodeP)
         AND C.CALC_TYPE = '002' /* مبلغی */
         AND c.CALC_EXPN_TYPE = '007' /* مبلغ ثابت */;
    
   OPEN C$CochFileNo$CalcExpnPK;
   NextC$CochFileNo$CalcExpnPK:
   FETCH NEXT FROM C$CochFileNo$CalcExpnPK INTO 
   @CochFileNo, @CbmtCode, @RqttCode, @PrctValu, @RqtpCode, @MtodCode, @CtgyCode, @CalcType, @PymtStat, @EfctDateType;
   
   SELECT @MbspRwno = f.MBSP_RWNO_DNRM
     FROM dbo.Fighter f
    WHERE f.FILE_NO = @CochFileNo;
   
   SELECT @ClubCode = CLUB_CODE
     FROM dbo.Club_Method
    WHERE CODE = @CbmtCode;    
   
   IF @@FETCH_STATUS <> 0
      GOTO EndC$CochFileNo$CalcExpnPK;
      
      IF NOT EXISTS(
         SELECT *
           FROM dbo.Payment_Expense
          WHERE CALC_EXPN_TYPE = '007'
            AND CALC_TYPE = '002'
            AND COCH_FILE_NO = @CochFileNo
            AND FROM_DATE = @FromPymtDate
            AND TO_DATE = @ToPymtDate
            AND CLUB_CODE = @ClubCode
      )
      BEGIN
         INSERT INTO Payment_Expense (
            Code, PYDT_CODE, COCH_FILE_NO, VALD_TYPE, EXPN_AMNT, EXPN_PRIC, RCPT_PRIC, 
            DSCN_PRIC, PRCT_VALU, DECR_PRCT_VALU, RQTP_CODE, MTOD_CODE, CTGY_CODE, 
            CLUB_CODE, DECR_AMNT_DNRM, RQRO_RQST_RQID, RQRO_RWNO, CALC_EXPN_TYPE, 
            CALC_TYPE, PYMT_STAT, MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO,
            FROM_DATE, TO_DATE, CBMT_CODE, EFCT_DATE_TYPE, RECT_CODE, RECT_DATE
         )
         SELECT dbo.GNRT_NVID_U(), NULL, @CochFileNo,'001',
                (@PrctValu) - (@PrctValu * @DecrPrct / 100),NULL,NULL,
                NULL,@PrctValu,@DecrPrct,NULL,@MtodCode,@CtgyCode,
                @ClubCode,
                (@PrctValu * @DecrPrct / 100),
                NULL,NULL,
                '006', -- مبلغ ثابت ماهیانه
                '002', -- مبلغی
                NULL,@CochFileNo,'004',@MbspRwno,
                @FromPymtDate, @ToPymtDate, @CbmtCode, @EfctDateType, '004', NULL;
      END;
  
   GOTO NextC$CochFileNo$CalcExpnPK;
   EndC$CochFileNo$CalcExpnPK:
   CLOSE C$CochFileNo$CalcExpnPK;
   DEALLOCATE C$CochFileNo$CalcExpnPK;
   
   --***********************************
   --******** محاسبه درآمد متفرقه *********
   --***********************************
   
   DELETE Payment_Expense 
    WHERE EXISTS (
          SELECT * 
            FROM Payment_Expense Pe 
           WHERE Pe.CODE <> Payment_Expense.CODE 
             AND Pe.PYDT_CODE = Payment_Expense.PYDT_CODE 
             AND Pe.VALD_TYPE = '002' 
             AND Payment_Expense.VALD_TYPE = '001'
          );
   
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
             pe.COCH_FILE_NO ) T;
   
   INSERT INTO Misc_Expense (REGN_PRVN_CNTY_CODE, REGN_PRVN_CODE, REGN_CODE, CLUB_CODE, CODE, COCH_FILE_NO, VALD_TYPE, EXPN_AMNT, CALC_EXPN_TYPE, DECR_PRCT) 
   SELECT REGN_PRVN_CNTY_CODE, REGN_PRVN_CODE, REGN_CODE, CLUB_CODE, dbo.GNRT_NVID_U(), COCH_FILE_NO, '001', Expn_Amnt, '001', @DecrPrct
     FROM (
      SELECT c.REGN_PRVN_CNTY_CODE, c.REGN_PRVN_CODE, c.REGN_CODE, c.CODE AS CLUB_CODE, COCH_FILE_NO, SUM(EXPN_AMNT) AS Expn_Amnt
        FROM Payment_Expense pe, dbo.Club c
       WHERE pe.VALD_TYPE = '001'
         AND pe.PYDT_CODE IS NULL
         AND pe.CLUB_CODE = c.CODE
         AND NOT EXISTS(
             SELECT *
               FROM dbo.Misc_Expense ME
              WHERE me.CALC_EXPN_TYPE = '001'
                AND me.VALD_TYPE = '001'
                AND me.CLUB_CODE = c.CODE
                AND me.COCH_FILE_NO = pe.COCH_FILE_NO
         )
    GROUP BY c.REGN_PRVN_CNTY_CODE, c.REGN_PRVN_CODE, 
             c.REGN_CODE, c.CODE, 
             pe.COCH_FILE_NO ) T	  	  
   
   UPDATE pe
      SET pe.MSEX_CODE = me.CODE
     FROM dbo.Payment_Expense pe, dbo.Misc_Expense me
    WHERE pe.COCH_FILE_NO = me.COCH_FILE_NO
      AND pe.CLUB_CODE = me.CLUB_CODE
      AND pe.MSEX_CODE IS NULL
      AND me.CALC_EXPN_TYPE = '001'
      AND me.DELV_STAT IS NULL;  
   
   -- 1401/09/18 * #MahsaAmini
   -- محاسبه کسورات حقوق های محاسبه شده و نهایی کردن مبلغ حقوق ها
   -- اولین گام لیست پرداختی هایی که پرسنل از حقوق آنها باید کم شود
   -- Payment_Method IN ( '017' /* کسر از حقوق و پاداش */ )   
   INSERT INTO dbo.Misc_Expense_Deduction ( PMTD_CODE ,MSEX_CODE ,CODE )
   SELECT pm.CODE, me.CODE, dbo.GNRT_NVID_U()
     FROM dbo.Request r, dbo.Request_Row rr, dbo.Misc_Expense me, dbo.Payment_Method pm
    WHERE r.RQID = rr.RQST_RQID
      AND rr.FIGH_FILE_NO = me.COCH_FILE_NO
      AND r.RQID = pm.PYMT_RQST_RQID
      AND r.RQST_STAT = '002'
      AND pm.RCPT_MTOD IN ( '017' /* کسر از حقوق و پاداش */)
      AND me.VALD_TYPE = '001'
      AND me.CALC_EXPN_TYPE = '001'
      AND CAST(pm.ACTN_DATE AS DATE) BETWEEN @FromPymtDate AND @ToPymtDate
      /*AND NOT EXISTS(
          SELECT *
            FROM dbo.Misc_Expense_Deduction md
           WHERE md.PMTD_CODE = pm.CODE
      )*/;
      
   --1397/09/04 * برای بروزرسانی مبلغ رکورد های پدر
   UPDATE dbo.Misc_Expense
      SET EXPN_AMNT = (SELECT SUM(pe.EXPN_AMNT) FROM dbo.Payment_Expense pe WHERE pe.MSEX_CODE = dbo.Misc_Expense.CODE AND pe.RECT_CODE = '004')
         ,LOCK_EXPN_AMNT_DNRM = (SELECT SUM(pe.EXPN_AMNT) FROM dbo.Payment_Expense pe WHERE pe.MSEX_CODE = dbo.Misc_Expense.CODE AND pe.RECT_CODE = '005')
         ,LOCK_DATE_DNRM = (SELECT MIN(pe.RECT_DATE) FROM dbo.Payment_Expense pe WHERE pe.MSEX_CODE = dbo.Misc_Expense.CODE AND pe.RECT_CODE = '005')
     WHERE VALD_TYPE = '001'
       AND CALC_EXPN_TYPE = '001';
         
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
