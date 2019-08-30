CREATE TABLE [dbo].[Payment_Detail]
(
[PYMT_CASH_CODE] [bigint] NULL,
[PYMT_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[EXPN_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL CONSTRAINT [DF_Payment_Detail_CODE] DEFAULT ((0)),
[PAY_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Payment_D__PAY_S__12AA62A5] DEFAULT ('001'),
[EXPN_PRIC] [int] NULL CONSTRAINT [DF__Payment_D__EXPN___139E86DE] DEFAULT ((0)),
[EXPN_EXTR_PRCT] [int] NULL CONSTRAINT [DF__Payment_D__EXPN___1492AB17] DEFAULT ((0)),
[REMN_PRIC] [int] NULL CONSTRAINT [DF__Payment_D__REMN___1586CF50] DEFAULT ((0)),
[QNTY] [smallint] NULL CONSTRAINT [DF__Payment_De__QNTY__167AF389] DEFAULT ((1)),
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
           @SUM_EXPN_PRIC           INT,
           @SUM_EXPN_EXTR_PRCT      INT,
           @SUM_REMN_PRIC           INT,
           @SUM_RCPT_EXPN_PRIC      INT,
           @SUM_RCPT_EXPN_EXTR_PRCT INT,
           @SUM_RCPT_REMN_PRIC      INT;

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
           @ExpnPric INT,
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
          ,@RemnPric INT;

   SELECT @ExpnPric      = CASE WHEN @ExpnPric = 0 THEN(T.PRIC) ELSE @ExpnPric END
         ,@ExpnExtrPrct  = (T.EXTR_PRCT)
         ,@RemnPric      = ROUND((T.PRIC + T.EXTR_PRCT), CASE @AmntUnitType WHEN '001' THEN -3 WHEN '002' THEN -2 END , 0) - (T.PRIC + T.EXTR_PRCT)
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
	
	-- 1396/08/24 * اضافه کردن آیتم هزینه مربوط به نوع ثبت نامی ها
	DECLARE @MtodCode BIGINT
	       ,@CtgyCode BIGINT;
	
	SELECT @MtodCode = e.MTOD_CODE
	      ,@CtgyCode = e.CTGY_CODE
	  FROM dbo.Expense e, Inserted i
	 WHERE e.CODE = i.EXPN_CODE;
	
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
            ,CTGY_CODE_DNRM = @CtgyCode;
   
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
   END
   
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
           @SumExpnPric         INT,
           @SumExpnExtrPrct     INT,
           @SumRemnPric         INT
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
          ,@ExpnPric INT
          ,@Qnty     SMALLINT;
          
   OPEN C#AUPD_PMDT;
   L$NextRow:
   FETCH NEXT FROM C#AUPD_PMDT INTO @Rqid, @CashCode, @RqroRwno, @ExpnCode, @ExpnPric, @Qnty;
   
   -- Fetch Next Row Is Failed
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
   
   SET @RqstRqid = @Rqid;
   
   ---------------
   DECLARE @PayType VARCHAR(3)
          ,@AmntUnitType VARCHAR(3);
   SELECT @PayType = [TYPE], @AmntUnitType = ISNULL(AMNT_UNIT_TYPE_DNRM, '001')
     FROM Payment
     WHERE RQST_RQID = @Rqid
       AND CASH_CODE = @CashCode;
   
   DECLARE @ExpnExtrPrct INT
          ,@RemnPric INT
          ,@CovrDsct VARCHAR(3);
   
   SELECT @ExpnPric =CASE WHEN @ExpnPric = 0 THEN T.PRIC ELSE @ExpnPric END
         ,@ExpnExtrPrct = T.EXTR_PRCT 
         ,@RemnPric = ROUND((T.PRIC + T.EXTR_PRCT) * S.QNTY, CASE @AmntUnitType WHEN '001' THEN -3 WHEN '002' THEN -2 END , 0) - (T.PRIC + T.EXTR_PRCT) * S.QNTY
         ,@CovrDsct = COVR_DSCT
   FROM Expense T, INSERTED S
   WHERE T.CODE = @ExpnCode;
     /*
         T.CODE = S.EXPN_CODE
     AND S.PYMT_RQST_RQID = @Rqid
     AND S.PYMT_CASH_CODE = @CashCode
     AND S.RQRO_RWNO = @RqroRwno
     AND S.EXPN_CODE = @ExpnCode;
     */
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
            ,ISSU_DATE      = CASE WHEN S.PAY_STAT IN ('002', '003') AND S.ISSU_DATE IS NULL THEN GETDATE() WHEN S.ISSU_DATE IS NOT NULL THEN S.ISSU_DATE ELSE NULL END;

   ---------------
   
   SELECT @SumExpnPric           = ISNULL(SUM(EXPN_PRIC * QNTY), 0), 
          @SumExpnExtrPrct       = ISNULL(SUM(EXPN_EXTR_PRCT * QNTY), 0),
          @SumRemnPric           = ISNULL(SUM(REMN_PRIC), 0)
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
	IF EXISTS(
	   SELECT *
	     FROM Payment_Detail T, INSERTED S, dbo.Request R, dbo.Request_Type Rt
	    WHERE T.PYMT_RQST_RQID = S.PYMT_RQST_RQID AND
             T.PYMT_CASH_CODE = S.PYMT_CASH_CODE AND
             T.RQRO_RWNO      = S.RQRO_RWNO      AND
             T.EXPN_CODE      = S.EXPN_CODE      AND
             T.PYMT_RQST_RQID = R.RQID           AND
             R.RQTP_CODE      = Rt.CODE          AND
             Rt.SAVE_PYMT_ACNT = '002'           AND -- درآمدهای باشگاه
             T.PYMT_RQST_RQID = @Rqid            AND
             T.PYMT_CASH_CODE = @CashCode        AND
             T.RQRO_RWNO      = @RqroRwno        AND
             T.EXPN_CODE      = @ExpnCode        AND
             T.PAY_STAT       = '002' -- تایید پرداخت
	)
	BEGIN	   
	   -- درج اطلاعات حسابداری باشگاه
	   DECLARE @Rwno BIGINT
	          ,@AcdtRwno INT
	          ,@ActnDate DATETIME
	          ,@RegnPrvnCntyCode VARCHAR(3)
	          ,@RegnPrvnCode VARCHAR(3)
	          ,@RegnCode VARCHAR(3)
	          ,@ClubCode BIGINT
	          ,@ExpnAmnt BIGINT;	   
	   SET @ActnDate = GETDATE();
	   SELECT @RegnPrvnCntyCode = R.REGN_PRVN_CNTY_CODE
	         ,@RegnPrvnCode = R.REGN_PRVN_CODE
	         ,@RegnCode = R.REGN_CODE
	         ,@ClubCode = P.CLUB_CODE_DNRM
	         ,@ExpnAmnt = P.SUM_RCPT_EXPN_PRIC + ISNULL(SUM_RCPT_EXPN_EXTR_PRCT, 0)
	     FROM Request R, Payment P
	    WHERE R.RQID = P.RQST_RQID
	      AND R.RQID = @Rqid
	      AND P.CASH_CODE = @CashCode;
	   
	   -- 1395/08/10 * بدست آوردن مبلغ استفاده شده از سپرده
	   DECLARE @SumAmntDeposit BIGINT;
	   SELECT @SumAmntDeposit = SUM(AMNT)
        FROM dbo.Payment_Method
       WHERE RCPT_MTOD = '005' -- برداشت از مبلغ سپرده
         AND PYMT_RQST_RQID = @Rqid;
      
      --PRINT @SumAmntDeposit;
      -- اگر مبلغ هزینه از مبلغ استفاده شده از سپرده بیشتر باشد هنرجو باید مبلغ باقیمانده را پرداخت کند
      IF @ExpnAmnt - ISNULL(@SumAmntDeposit, 0) >= 0
         SET @ExpnAmnt -= ISNULL(@SumAmntDeposit, 0);
      
      --PRINT @Rqid;
      
	   --IF NOT EXISTS(
	   --   SELECT *
	   --     FROM Request R, Payment P, Account_Detail ad
	   --    WHERE R.RQID = P.RQST_RQID
   	--      AND R.RQID = @Rqid
   	--      AND P.CASH_CODE = @CashCode
	   --      AND Ad.PYMT_CASH_CODE = P.CASH_CODE
	   --      AND Ad.PYMT_RQST_RQID = P.RQST_RQID	         
	   --) AND ISNULL(@ExpnAmnt, 0) > 0 -- مبلغ درآمد باید مثبت باشد
	   --BEGIN 
	   --   --EXEC dbo.INS_ACTN_P @RegnPrvnCntyCode, @RegnPrvnCode, @RegnCode, @ClubCode, 0, '002', @ActnDate, @Rwno OUT;
	   --   --EXEC dbo.INS_ACDT_P @RegnPrvnCntyCode, @RegnPrvnCode, @RegnCode, @ClubCode, @Rwno, @ExpnAmnt, '002', @ActnDate, @CashCode, @Rqid, NULL, @AcdtRwno OUT;
	   --   PRINT 'No Save Account';
	   --END
	END
   
   -- اگر درآمد شامل تخفیف بشود
   IF @CovrDsct = '002'
   BEGIN
      -- محاسبه تخفیف
      -- Start
      DECLARE @Rslt XML
             ,@Type BIT
             ,@AmntDsct INT
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
            ,@AmntDsct = @Rslt.query('Result').value('(Result/@amntdsct)[1]', 'INT')
            ,@DsctDesc = @Rslt.query('Result').value('(Result/@dsctdesc)[1]', 'NVARCHAR(500)');
      -- 1395/06/17 * پاک کردن مبلغ های تخفیف محاسبه شده
      -- 1397/10/08 * حذف تمامی تخفیفات محاسباتی
      DELETE dbo.Payment_Discount
       WHERE PYMT_CASH_CODE = @CashCode
         AND PYMT_RQST_RQID = @Rqid
         AND RQRO_RWNO = @RqroRwno
         AND AMNT_TYPE = '001';
         --AND EXPN_CODE = @ExpnCode;
      
      IF @Type = 1
      BEGIN
         IF NOT EXISTS(
            SELECT *
              FROM Payment_Discount
             WHERE PYMT_CASH_CODE = @CashCode
               AND PYMT_RQST_RQID = @Rqid
               AND RQRO_RWNO = @RqroRwno
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
ALTER TABLE [dbo].[Payment_Detail] ADD CONSTRAINT [CK__Payment_De__QNTY__176F17C2] CHECK (([QNTY]>=(1)))
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
EXEC sp_addextendedproperty N'MS_Description', N'هزینه هایی که به صورت مشخص شده در اختیار فرد خاصی قرار میگیرد', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Detail', 'COLUMN', N'FIGH_FILE_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'پیش هزینه ها', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Detail', 'COLUMN', N'PRE_EXPN_STAT'
GO
