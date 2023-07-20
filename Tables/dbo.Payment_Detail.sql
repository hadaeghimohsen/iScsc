CREATE TABLE [dbo].[Payment_Detail]
(
[PYMT_CASH_CODE] [bigint] NULL,
[PYMT_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[EXPN_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL CONSTRAINT [DF_Payment_Detail_CODE] DEFAULT ((0)),
[PAY_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Payment_D__PAY_S__12AA62A5] DEFAULT ('001'),
[EXPN_PRIC] [bigint] NULL CONSTRAINT [DF__Payment_D__EXPN___139E86DE] DEFAULT ((0)),
[EXPN_EXTR_PRCT] [bigint] NULL CONSTRAINT [DF__Payment_D__EXPN___1492AB17] DEFAULT ((0)),
[REMN_PRIC] [bigint] NULL CONSTRAINT [DF__Payment_D__REMN___1586CF50] DEFAULT ((0)),
[QNTY] [real] NULL CONSTRAINT [DF__Payment_De__QNTY__167AF389] DEFAULT ((1)),
[DOCM_NUMB] [bigint] NULL,
[ISSU_DATE] [datetime] NULL,
[RCPT_MTOD] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Payment_Detail_RCPT_MTOD] DEFAULT ('001'),
[RECV_LETT_NO] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RECV_LETT_DATE] [datetime] NULL,
[PYDT_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ADD_QUTS] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Payment_Detail_ADD_QUTS] DEFAULT ('001'),
[FIGH_FILE_NO] [bigint] NULL,
[PRE_EXPN_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CBMT_CODE_DNRM] [bigint] NULL,
[MTOD_CODE_DNRM] [bigint] NULL,
[CTGY_CODE_DNRM] [bigint] NULL,
[TRAN_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TRAN_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TRAN_DATE] [datetime] NULL,
[TRAN_CBMT_CODE] [bigint] NULL,
[TRAN_MTOD_CODE] [bigint] NULL,
[TRAN_CTGY_CODE] [bigint] NULL,
[TRAN_EXPN_CODE] [bigint] NULL,
[EXPR_DATE] [datetime] NULL,
[MBSP_FIGH_FILE_NO] [bigint] NULL,
[MBSP_RWNO] [smallint] NULL,
[MBSP_RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FROM_NUMB] [bigint] NULL,
[TO_NUMB] [bigint] NULL,
[PROF_AMNT_DNRM] [bigint] NULL,
[DEDU_AMNT_DNRM] [bigint] NULL,
[EXTS_CODE] [bigint] NULL,
[EXTS_RSRV_DATE] [datetime] NULL,
[TOTL_WEGH] [real] NULL,
[UNIT_NUMB] [real] NULL,
[UNIT_APBS_CODE] [bigint] NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$ADEL_PMDT]
   ON  [dbo].[Payment_Detail]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   DECLARE @RQST_RQID            BIGINT,
           @SUM_EXPN_PRIC           BIGINT,
           @SUM_EXPN_EXTR_PRCT      bigINT,
           @SUM_REMN_PRIC           bigINT,
           @SUM_RCPT_EXPN_PRIC      bigINT,
           @SUM_RCPT_EXPN_EXTR_PRCT bigINT,
           @SUM_RCPT_REMN_PRIC      bigINT;

   DECLARE C#ADEL_PMDT CURSOR FOR
      SELECT DISTINCT PYMT_RQST_RQID, PYMT_CASH_CODE
      FROM DELETED D;
   
   DECLARE @RQID BIGINT
          ,@CashCode BIGINT;
   OPEN C#ADEL_PMDT;
   L$NextRow:
   FETCH NEXT FROM C#ADEL_PMDT INTO @RQID, @CashCode;
   
   -- Fetch Next Row Is Failed
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
   
   SET @RQST_RQID = (SELECT TOP 1 PYMT_RQST_RQID FROM DELETED WHERE PYMT_RQST_RQID = @RQID AND PYMT_CASH_CODE = @CashCode);
   
   SELECT @SUM_EXPN_PRIC           = ISNULL(SUM(EXPN_PRIC * QNTY), 0), 
          @SUM_EXPN_EXTR_PRCT      = ISNULL(SUM(EXPN_EXTR_PRCT * QNTY), 0),
          @SUM_REMN_PRIC           = ISNULL(SUM(REMN_PRIC), 0)
     FROM Payment_Detail 
    WHERE PYMT_RQST_RQID = @RQST_RQID
      AND PYMT_CASH_CODE = @CashCode;
   
   SELECT @SUM_RCPT_EXPN_PRIC      = ISNULL(SUM(EXPN_PRIC * QNTY), 0),
          @SUM_RCPT_EXPN_EXTR_PRCT = ISNULL(SUM(EXPN_EXTR_PRCT * QNTY), 0),
          @SUM_RCPT_REMN_PRIC      = ISNULL(SUM(REMN_PRIC), 0)   
     FROM Payment_Detail 
    WHERE PYMT_RQST_RQID = @RQST_RQID 
      AND PYMT_CASH_CODE = @CashCode
      AND PAY_STAT IN ('002', '003');
   
   UPDATE dbo.Payment
      SET SUM_EXPN_PRIC           = @SUM_EXPN_PRIC
         ,SUM_EXPN_EXTR_PRCT      = @SUM_EXPN_EXTR_PRCT
         ,SUM_REMN_PRIC           = @SUM_REMN_PRIC
         ,SUM_RCPT_EXPN_PRIC      = @SUM_RCPT_EXPN_PRIC
         ,SUM_RCPT_EXPN_EXTR_PRCT = @SUM_RCPT_EXPN_EXTR_PRCT
         ,SUM_RCPT_REMN_PRIC      = @SUM_RCPT_REMN_PRIC
    WHERE RQST_RQID = @RQST_RQID
      AND CASH_CODE = @CashCode;
    
   GOTO L$NextRow;
   L$EndFetch:
   CLOSE C#ADEL_PMDT;
   DEALLOCATE C#ADEL_PMDT;    
    
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_PMDT]
   ON  [dbo].[Payment_Detail]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   DECLARE C#AINS_PMDT CURSOR FOR
      SELECT DISTINCT PYMT_RQST_RQID, PYMT_CASH_CODE, Rqro_Rwno, Expn_Code, Expn_Pric FROM INSERTED;
   
   DECLARE @Rqid     BIGINT,
           @CashCode BIGINT,
           @ExpnCode BIGINT,
           @ExpnPric BIGINT,
           @RqroRwno SMALLINT,
           @PayType VARCHAR(3),
           @AmntUnitType VARCHAR(3);
           
   OPEN C#AINS_PMDT;
   L$NextRow:
   FETCH NEXT FROM C#AINS_PMDT INTO @Rqid, @CashCode, @RqroRwno, @ExpnCode, @ExpnPric;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
   
   SELECT @PayType = [TYPE], @AmntUnitType = ISNULL(AMNT_UNIT_TYPE_DNRM, '001')
     FROM Payment
    WHERE RQST_RQID = @Rqid
      AND CASH_CODE = @CashCode;
   
   DECLARE @ExpnExtrPrct INT
          ,@RemnPric INT = 0;

	-- 1396/08/24 * اضافه کردن آیتم هزینه مربوط به نوع ثبت نامی ها
	DECLARE @MtodCode BIGINT
	       ,@CtgyCode BIGINT
	       ,@UnitApbsCode BIGINT;

   SELECT @ExpnPric      = CASE WHEN @ExpnPric = 0 THEN(T.PRIC) ELSE @ExpnPric END
         ,@ExpnExtrPrct  = (T.EXTR_PRCT)
         --,@RemnPric      = ROUND((T.PRIC + T.EXTR_PRCT), CASE @AmntUnitType WHEN '001' THEN -3 WHEN '002' THEN -2 END , 0) - (T.PRIC + T.EXTR_PRCT)
         ,@MtodCode      = MTOD_CODE
	      ,@CtgyCode      = CTGY_CODE
	      ,@UnitApbsCode = T.UNIT_APBS_CODE
   FROM Expense T --, INSERTED S
   WHERE T.CODE = @ExpnCode;
   /*
         T.CODE           = S.EXPN_CODE
     AND S.Pymt_Rqst_Rqid = @Rqid
     AND S.PYMT_CASH_CODE = @CashCode
     AND S.RQRO_RWNO      = @RqroRwno
     AND S.EXPN_CODE      = @ExpnCode;
   */
   /*DECLARE @Code BIGINT;
   L$NextCode:
   SET @Code = dbo.GNRT_NVID_U();
   IF EXISTS (SELECT * from dbo.Payment_Detail WHERE CODE = @Code)
	GOTO L$NextCode;*/
	
   -- Insert statements for trigger here
   MERGE dbo.Payment_Detail T
   USING (SELECT * FROM INSERTED) S
   ON (T.PYMT_RQST_RQID = S.PYMT_RQST_RQID AND
       T.PYMT_CASH_CODE = S.PYMT_CASH_CODE AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.EXPN_CODE      = S.EXPN_CODE      AND
--       T.Cret_By        IS NULL AND
       T.PYMT_RQST_RQID = @Rqid            AND
       T.PYMT_CASH_CODE = @CashCode        AND
       T.RQRO_RWNO      = @RqroRwno        AND
       T.EXPN_CODE      = @ExpnCode)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY        = UPPER(SUSER_NAME())
            ,CRET_DATE      = GETDATE()
            ,CODE           = dbo.GNRT_NVID_U()
            ,EXPN_PRIC      = CASE @PayType WHEN '002' THEN @ExpnPric     ELSE -@ExpnPric END
            ,EXPN_EXTR_PRCT = CASE @PayType WHEN '002' THEN @ExpnExtrPrct ELSE -@ExpnExtrPrct END
            ,REMN_PRIC      = @RemnPric
            ,MTOD_CODE_DNRM = @MtodCode
            ,CTGY_CODE_DNRM = @CtgyCode
            ,UNIT_APBS_CODE = @UnitApbsCode;
   
   -- اضافه شدن گزینه های پیش فرض
   IF EXISTS(
      SELECT *
        FROM dbo.Payment_Detail
       WHERE PYMT_RQST_RQID = @Rqid
         AND RQRO_RWNO = @RqroRwno
         AND ISNULL(PRE_EXPN_STAT, '001') = '001'
         AND EXPN_CODE = @ExpnCode
   )
   BEGIN
      INSERT INTO Payment_Detail(PYMT_CASH_CODE, PYMT_RQST_RQID, RQRO_RWNO, EXPN_CODE, CODE, PAY_STAT, QNTY, PRE_EXPN_STAT, EXPN_PRIC, PYDT_DESC)
      SELECT @CashCode, @Rqid, @RqroRwno, PRE_EXPN_CODE, ABS(CAST(NEWID() AS binary(6)) %1000) + 1, '001', QNTY, '002', CASE p.FREE_STAT WHEN '001' THEN e.PRIC ELSE 0 END, N'آیتم پیش نیاز ' + e.EXPN_DESC
        FROM dbo.Pre_Expense P, dbo.Expense e
       WHERE EXPN_CODE = @ExpnCode
         AND p.PRE_EXPN_CODE = e.CODE
         AND STAT = '002';
   END;
   
   -- 1401/05/028 * Insert Payment_Detail_Cost
   INSERT INTO dbo.Payment_Detail_Cost( PYDT_CODE , EXCO_CODE, CODE ,RWNO ,INIT_AMNT_DNRM ,PYDT_APBS_CODE ,PYDT_DESC ,PYDT_TYPE ,PYDT_AMNT ,PYDT_CALC_AMNT ,RMND_AMNT )
   SELECT pd.CODE, ec.CODE, dbo.GNRT_NVID_U() ,ec.RWNO, ec.INIT_AMNT_DNRM, ec.EXCO_APBS_CODE, ec.EXCO_DESC, ec.EXCO_TYPE, ec.EXCO_AMNT, ec.EXCO_CALC_AMNT, ec.RMND_AMNT
     FROM dbo.Expense_Cost ec, dbo.Payment_Detail pd
    WHERE ec.EXPN_CODE = @ExpnCode
      AND pd.EXPN_CODE = @ExpnCode
      AND pd.PYMT_RQST_RQID = @Rqid
      AND ec.EXCO_STAT = '002';
   
   GOTO L$NextRow;
   L$EndFetch:
   CLOSE C#AINS_PMDT;
   DEALLOCATE C#AINS_PMDT;
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_PMDT]
   ON  [dbo].[Payment_Detail]
   AFTER UPDATE
AS 
BEGIN
   -- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   
   DECLARE @RqstRqid            BIGINT,
           @SumExpnPric         bigINT,
           @SumExpnExtrPrct     bigINT,
           @SumRemnPric         bigINT
           /*@SumRcptExpnPric     INT,
           @SumRcptExpnExtrPrct INT,
           @SumRcptRemnPric     INT*/;
   
   DECLARE C#AUPD_PMDT CURSOR FOR
      SELECT PYMT_RQST_RQID, PYMT_CASH_CODE, Rqro_Rwno, Expn_Code, Expn_Pric, Qnty
      FROM INSERTED D;
   
   DECLARE @Rqid     BIGINT
          ,@CashCode BIGINT
          ,@RqroRwno SMALLINT
          ,@ExpnCode BIGINT
          ,@ExpnPric bigINT
          ,@Qnty     SMALLINT;
          
   OPEN C#AUPD_PMDT;
   L$NextRow:
   FETCH NEXT FROM C#AUPD_PMDT INTO @Rqid, @CashCode, @RqroRwno, @ExpnCode, @ExpnPric, @Qnty;
   
   -- Fetch Next Row Is Failed
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
   
   -- اگر قیمت توسط کاربر بخواهد کمتر از مقدار آیین نامه ثبت شود باید دسترسی کاربر را چک کنیم
	IF EXISTS(
	   SELECT *
	     FROM Inserted i, dbo.Expense d
	    WHERE i.EXPN_CODE = d.CODE
	      AND ISNULL(i.EXPN_PRIC, 0) < ISNULL(d.PRIC, 0)
	)
	BEGIN
	   DECLARE @AP BIT
             ,@AccessString VARCHAR(250);
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>265</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 265 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END
	END 
	
	-- اگر قیمت توسط کاربر بخواهد بیشتر از مقدار آیین نامه ثبت شود باید دسترسی کاربر را چک کنیم
	IF EXISTS(
	   SELECT *
	     FROM Inserted i, dbo.Expense d
	    WHERE i.EXPN_CODE = d.CODE
	      AND ISNULL(i.EXPN_PRIC, 0) > ISNULL(d.PRIC, 0)
	)
	BEGIN
	   --DECLARE @AP BIT
    --         ,@AccessString VARCHAR(250);
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>266</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 266 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END
	END 
   
   -- اگر قیمت توسط کاربر بخواهد تغییر کند و مقدار در بازه تعریف شده باشد باید دسترسی کاربر را چک کنیم
	IF EXISTS(
	   SELECT *
	     FROM Inserted i, dbo.Expense d
	    WHERE i.EXPN_CODE = d.CODE
	      AND ISNULL(d.MIN_PRIC, 0) > 0
	      AND ISNULL(d.MAX_PRIC, 0) > 0
	      AND NOT(ISNULL(i.EXPN_PRIC, 0) BETWEEN ISNULL(d.MIN_PRIC, 0) AND ISNULL(d.MAX_PRIC, 0))
	)
	BEGIN
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>268</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 268 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END
	END 
   
   SET @RqstRqid = @Rqid;
   
   ---------------
   DECLARE @PayType VARCHAR(3)
          ,@AmntUnitType VARCHAR(3);
   SELECT @PayType = [TYPE], @AmntUnitType = ISNULL(AMNT_UNIT_TYPE_DNRM, '001')
     FROM Payment
     WHERE RQST_RQID = @Rqid
       AND CASH_CODE = @CashCode;
   
   DECLARE @ExpnExtrPrct INT
          ,@RemnPric INT = 0
          ,@CovrDsct VARCHAR(3)
          ,@ProfAmnt BIGINT
          ,@DeduAmnt BIGINT;
   
   SELECT @ExpnPric = CASE WHEN @ExpnPric = 0 THEN T.PRIC ELSE @ExpnPric END
         ,@ExpnExtrPrct = T.EXTR_PRCT 
         --,@RemnPric = ABS(ROUND((T.PRIC + T.EXTR_PRCT) * S.QNTY, CASE @AmntUnitType WHEN '001' THEN -4 WHEN '002' THEN -3 END , 0) - (T.PRIC + T.EXTR_PRCT) * S.QNTY)
         ,@CovrDsct = COVR_DSCT
         ,@ProfAmnt = CASE ISNULL(T.PROF_AMNT_DNRM, 0) WHEN 0 THEN CASE WHEN @ExpnPric = 0 THEN T.PRIC ELSE @ExpnPric END ELSE t.PROF_AMNT_DNRM END
         ,@DeduAmnt = t.DEDU_AMNT_DNRM
   FROM Expense T, INSERTED S
   WHERE T.CODE = @ExpnCode
     AND T.CODE = S.EXPN_CODE
     /*AND S.PYMT_RQST_RQID = @Rqid
     AND S.PYMT_CASH_CODE = @CashCode
     AND S.RQRO_RWNO = @RqroRwno
     AND S.EXPN_CODE = @ExpnCode;*/

   -- Insert statements for trigger here
   MERGE dbo.Payment_Detail T
   USING (SELECT * FROM INSERTED) S
   ON (T.PYMT_RQST_RQID = S.PYMT_RQST_RQID AND
       T.PYMT_CASH_CODE = S.PYMT_CASH_CODE AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.EXPN_CODE      = S.EXPN_CODE      AND
       T.PYMT_RQST_RQID = @Rqid            AND
       T.PYMT_CASH_CODE = @CashCode        AND
       T.RQRO_RWNO      = @RqroRwno        AND
       T.EXPN_CODE      = @ExpnCode)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY        = UPPER(SUSER_NAME())
            ,MDFY_DATE      = GETDATE()
            ,EXPN_PRIC      = CASE @PayType WHEN '002' THEN @ExpnPric      ELSE -@ExpnPric END
            ,EXPN_EXTR_PRCT = CASE @PayType WHEN '002' THEN @ExpnExtrPrct ELSE -@ExpnExtrPrct END
            ,REMN_PRIC      = @RemnPric
            ,ISSU_DATE      = CASE WHEN S.PAY_STAT IN ('002', '003') AND S.ISSU_DATE IS NULL THEN GETDATE() WHEN S.ISSU_DATE IS NOT NULL THEN S.ISSU_DATE ELSE NULL END
            ,PROF_AMNT_DNRM = ISNULL(@ProfAmnt * s.QNTY, 0)
            ,DEDU_AMNT_DNRM = ISNULL(@DeduAmnt * s.QNTY, 0);
   
   ---------------
   
   SELECT @SumExpnPric           = ISNULL(SUM(EXPN_PRIC * QNTY), 0), 
          @SumExpnExtrPrct       = ISNULL(SUM(EXPN_EXTR_PRCT * QNTY), 0),
          @SumRemnPric           = ISNULL(SUM(REMN_PRIC), 0),
          @ProfAmnt              = SUM(PROF_AMNT_DNRM),
          @DeduAmnt              = SUM(DEDU_AMNT_DNRM)
     FROM Payment_Detail 
    WHERE PYMT_RQST_RQID = @RqstRqid
      AND PYMT_CASH_CODE = @CashCode;
   
   -- 1395/12/27 * مبلغ های پرداختی از جدول پرداختی ها مشترک محاسبه و به صورت دینرمال در جدول هزینه قرار میگیرد.
   /*SELECT @SumRcptExpnPric      = ISNULL(SUM(EXPN_PRIC * QNTY), 0),
 @SumRcptExpnExtrPrct  = ISNULL(SUM(EXPN_EXTR_PRCT * QNTY), 0),
          @SumRcptRemnPric      = ISNULL(SUM(REMN_PRIC), 0)   
     FROM Payment_Detail 
    WHERE PYMT_RQST_RQID = @RqstRqid 
      AND PYMT_CASH_CODE = @CashCode
      AND PAY_STAT IN ('002', '003');*/
   
   UPDATE dbo.Payment
      SET SUM_EXPN_PRIC           = @SumExpnPric
         ,SUM_EXPN_EXTR_PRCT      = @SumExpnExtrPrct
         ,SUM_REMN_PRIC           = @SumRemnPric
         ,PROF_AMNT_DNRM          = @ProfAmnt
         ,DEDU_AMNT_DNRM          = @DeduAmnt
         /*
          SUM_EXPN_PRIC           = ROUND(@SumExpnPric, CASE ISNULL(AMNT_UNIT_TYPE_DNRM, '001') WHEN '001' THEN -3 WHEN '002' THEN -2 END)
         ,SUM_EXPN_EXTR_PRCT      = ROUND(@SumExpnExtrPrct, CASE ISNULL(AMNT_UNIT_TYPE_DNRM, '001') WHEN '001' THEN -3 WHEN '002' THEN -2 END)
         ,SUM_REMN_PRIC           = ROUND(@SumRemnPric, CASE ISNULL(AMNT_UNIT_TYPE_DNRM, '001') WHEN '001' THEN -3 WHEN '002' THEN -2 END)
         */
         /*,SUM_RCPT_EXPN_PRIC      = ROUND(@SumRcptExpnPric, -3) - ISNULL(SUM_PYMT_DSCN_DNRM, 0)
         ,SUM_RCPT_EXPN_EXTR_PRCT = ROUND(@SumRcptExpnExtrPrct, -3)
         ,SUM_RCPT_REMN_PRIC      = ROUND(@SumRcptRemnPric, -3)*/
WHERE RQST_RQID = @RqstRqid
  AND CASH_CODE = @CashCode;

   -- ثبت اطلاعات هزینه های ثبت شده در جدول حسابداری برای باشگاه
	--IF EXISTS(
	--   SELECT *
	--     FROM Payment_Detail T, INSERTED S, dbo.Request R, dbo.Request_Type Rt
	--    WHERE T.PYMT_RQST_RQID = S.PYMT_RQST_RQID AND
 --            T.PYMT_CASH_CODE = S.PYMT_CASH_CODE AND
 --            T.RQRO_RWNO      = S.RQRO_RWNO      AND
 --            T.EXPN_CODE      = S.EXPN_CODE      AND
 --            T.PYMT_RQST_RQID = R.RQID           AND
 --            R.RQTP_CODE      = Rt.CODE          AND
 --            Rt.SAVE_PYMT_ACNT = '002'           AND -- درآمدهای باشگاه
 --            T.PYMT_RQST_RQID = @Rqid            AND
 --            T.PYMT_CASH_CODE = @CashCode        AND
 --            T.RQRO_RWNO      = @RqroRwno        AND
 --            T.EXPN_CODE      = @ExpnCode        AND
 --            T.PAY_STAT       = '002' -- تایید پرداخت
	--)
	--BEGIN
	--   -- درج اطلاعات حسابداری باشگاه
	--   DECLARE @Rwno BIGINT
	--          ,@AcdtRwno INT
	--          ,@ActnDate DATETIME
	--          ,@RegnPrvnCntyCode VARCHAR(3)
	--          ,@RegnPrvnCode VARCHAR(3)
	--          ,@RegnCode VARCHAR(3)
	--          ,@ClubCode BIGINT
	--          ,@ExpnAmnt BIGINT;	   
	--   SET @ActnDate = GETDATE();
	--   SELECT @RegnPrvnCntyCode = R.REGN_PRVN_CNTY_CODE
	--         ,@RegnPrvnCode = R.REGN_PRVN_CODE
	--         ,@RegnCode = R.REGN_CODE
	--         ,@ClubCode = P.CLUB_CODE_DNRM
	--         ,@ExpnAmnt = P.SUM_RCPT_EXPN_PRIC + ISNULL(SUM_RCPT_EXPN_EXTR_PRCT, 0)
	--     FROM Request R, Payment P
	--    WHERE R.RQID = P.RQST_RQID
	--      AND R.RQID = @Rqid
	--      AND P.CASH_CODE = @CashCode;
	   
	--   -- 1395/08/10 * بدست آوردن مبلغ استفاده شده از سپرده
	--   DECLARE @SumAmntDeposit BIGINT;
	--   SELECT @SumAmntDeposit = SUM(AMNT)
 --       FROM dbo.Payment_Method
 --      WHERE RCPT_MTOD = '005' -- برداشت از مبلغ سپرده
 --        AND PYMT_RQST_RQID = @Rqid;
      
 --     --PRINT @SumAmntDeposit;
 --     -- اگر مبلغ هزینه از مبلغ استفاده شده از سپرده بیشتر باشد هنرجو باید مبلغ باقیمانده را پرداخت کند
 --     IF @ExpnAmnt - ISNULL(@SumAmntDeposit, 0) >= 0
 --        SET @ExpnAmnt -= ISNULL(@SumAmntDeposit, 0);
      
 --     --PRINT @Rqid;
      
	--   --IF NOT EXISTS(
	--   --   SELECT *
	--   --     FROM Request R, Payment P, Account_Detail ad
	--   --    WHERE R.RQID = P.RQST_RQID
 --  	--      AND R.RQID = @Rqid
 --  	--      AND P.CASH_CODE = @CashCode
	--   --      AND Ad.PYMT_CASH_CODE = P.CASH_CODE
	--   --      AND Ad.PYMT_RQST_RQID = P.RQST_RQID	         
	--   --) AND ISNULL(@ExpnAmnt, 0) > 0 -- مبلغ درآمد باید مثبت باشد
	--   --BEGIN 
	--   --   --EXEC dbo.INS_ACTN_P @RegnPrvnCntyCode, @RegnPrvnCode, @RegnCode, @ClubCode, 0, '002', @ActnDate, @Rwno OUT;
	--   --   --EXEC dbo.INS_ACDT_P @RegnPrvnCntyCode, @RegnPrvnCode, @RegnCode, @ClubCode, @Rwno, @ExpnAmnt, '002', @ActnDate, @CashCode, @Rqid, NULL, @AcdtRwno OUT;
	--   --   PRINT 'No Save Account';
	--   --END
	--END
   
   -- اگر درآمد شامل تخفیف بشود
   
   IF @CovrDsct = '002'
   BEGIN
      -- محاسبه تخفیف
      -- Start
      DECLARE @Rslt XML
             ,@Type BIT
             ,@AmntDsct bigINT
             ,@DsctDesc NVARCHAR(500);
      
      --PRINT @ExpnCode;
      
      SELECT @Rslt = (
         SELECT @Rqid AS '@rqid'
               ,@RqroRwno AS 'Request_Row/@rwno'
               ,@ExpnCode AS 'Request_Row/Expense/@code'
               ,@Qnty AS 'Request_Row/Expense/@qnty'
            FOR XML PATH('Request')
      );

      SELECT @Rslt = dbo.PYDS_CHCK_U(@Rslt);

      SELECT @Type = @Rslt.query('Result').value('(Result/@type)[1]', 'BIT')
            ,@AmntDsct = @Rslt.query('Result').value('(Result/@amntdsct)[1]', 'BIGINT')
            ,@DsctDesc = @Rslt.query('Result').value('(Result/@dsctdesc)[1]', 'NVARCHAR(500)');
      -- 1395/06/17 * پاک کردن مبلغ های تخفیف محاسبه شده
      -- 1397/10/08 * حذف تمامی تخفیفات محاسباتی
      
      DELETE dbo.Payment_Discount
       WHERE PYMT_CASH_CODE = @CashCode
         AND PYMT_RQST_RQID = @Rqid
         AND RQRO_RWNO = @RqroRwno
         AND AMNT_TYPE = '001'
         AND EXPN_CODE = @ExpnCode;
      
      IF @Type = 1
      BEGIN
         IF NOT EXISTS(
            SELECT *
              FROM Payment_Discount
             WHERE PYMT_CASH_CODE = @CashCode
               AND PYMT_RQST_RQID = @Rqid
               AND RQRO_RWNO = @RqroRwno
               AND AMNT_TYPE = '001'
               AND EXPN_CODE = @ExpnCode
         )
         BEGIN  
            --PRINT 'Insert Begin'
            INSERT INTO Payment_Discount (PYMT_CASH_CODE, PYMT_RQST_RQID, RQRO_RWNO, EXPN_CODE, AMNT, AMNT_TYPE, STAT, PYDS_DESC)
            VALUES (@CashCode, @Rqid, @RqroRwno, @ExpnCode, @AmntDsct, '001', '002', N'محاسبه تخفیفات موسسات و ارگان ها' + ' - ' + ISNULL(@DsctDesc, ''));
            --PRINT 'Insert End'
         END
         ELSE
         BEGIN
            --PRINT 'Update Begin'
            UPDATE dbo.Payment_Discount
               SET AMNT = @AmntDsct
             WHERE PYMT_CASH_CODE = @CashCode
               AND PYMT_RQST_RQID = @Rqid
               AND RQRO_RWNO = @RqroRwno
               AND AMNT_TYPE = '001'
               AND Expn_Code = @ExpnCode;      
            --PRINT 'Update End'
         END
      END
      -- End
   END
   ELSE
   BEGIN
      --PRINT 'Delete Begin'
      DELETE Payment_Discount
       WHERE PYMT_CASH_CODE = @CashCode
         AND PYMT_RQST_RQID = @Rqid
         AND RQRO_RWNO = @RqroRwno
         AND Expn_Code = @ExpnCode;      
      --PRINT 'Delete End'
   END
   
   GOTO L$NextRow;
   L$EndFetch:
   CLOSE C#AUPD_PMDT;
   DEALLOCATE C#AUPD_PMDT;
END
;
GO
ALTER TABLE [dbo].[Payment_Detail] ADD CONSTRAINT [PK_PYDT] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Payment_Detail] ADD CONSTRAINT [FK_PYDT_CASH] FOREIGN KEY ([PYMT_CASH_CODE]) REFERENCES [dbo].[Cash] ([CODE])
GO
ALTER TABLE [dbo].[Payment_Detail] ADD CONSTRAINT [FK_PYDT_CBMT] FOREIGN KEY ([CBMT_CODE_DNRM]) REFERENCES [dbo].[Club_Method] ([CODE])
GO
ALTER TABLE [dbo].[Payment_Detail] ADD CONSTRAINT [FK_PYDT_CTGY] FOREIGN KEY ([CTGY_CODE_DNRM]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
ALTER TABLE [dbo].[Payment_Detail] ADD CONSTRAINT [FK_PYDT_EXPN] FOREIGN KEY ([EXPN_CODE]) REFERENCES [dbo].[Expense] ([CODE])
GO
ALTER TABLE [dbo].[Payment_Detail] ADD CONSTRAINT [FK_PYDT_EXTS] FOREIGN KEY ([EXTS_CODE]) REFERENCES [dbo].[Expense_Type_Step] ([CODE])
GO
ALTER TABLE [dbo].[Payment_Detail] ADD CONSTRAINT [FK_PYDT_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Payment_Detail] ADD CONSTRAINT [FK_PYDT_MTOD] FOREIGN KEY ([MTOD_CODE_DNRM]) REFERENCES [dbo].[Method] ([CODE])
GO
ALTER TABLE [dbo].[Payment_Detail] ADD CONSTRAINT [FK_PYDT_PYMT] FOREIGN KEY ([PYMT_CASH_CODE], [PYMT_RQST_RQID]) REFERENCES [dbo].[Payment] ([CASH_CODE], [RQST_RQID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Payment_Detail] ADD CONSTRAINT [FK_PYDT_RQRO] FOREIGN KEY ([PYMT_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO])
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ اضافه واریز', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Detail', 'COLUMN', N'ADD_QUTS'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ های کسرشده', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Detail', 'COLUMN', N'DEDU_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ انقضا', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Detail', 'COLUMN', N'EXPR_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'هزینه هایی که به صورت مشخص شده در اختیار فرد خاصی قرار میگیرد', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Detail', 'COLUMN', N'FIGH_FILE_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'فروش کارتهای انبوه به ارگان ها
از شماره', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Detail', 'COLUMN', N'FROM_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'پیش هزینه ها', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Detail', 'COLUMN', N'PRE_EXPN_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ سود نهایی', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Detail', 'COLUMN', N'PROF_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'فروش کارتهای انبوه به ارگان ها
تا شماره', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Detail', 'COLUMN', N'TO_NUMB'
GO
