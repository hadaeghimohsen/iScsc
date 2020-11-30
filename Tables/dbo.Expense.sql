CREATE TABLE [dbo].[Expense]
(
[REGL_YEAR] [smallint] NULL,
[REGL_CODE] [int] NULL,
[EXTP_CODE] [bigint] NULL,
[CTGY_CODE] [bigint] NULL,
[MTOD_CODE] [bigint] NULL,
[GROP_CODE] [bigint] NULL,
[BRND_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL CONSTRAINT [DF_EXPN_CODE] DEFAULT ((0)),
[EXPN_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRIC] [bigint] NOT NULL CONSTRAINT [DF_EXPN_PRIC] DEFAULT ((0)),
[EXTR_PRCT] [bigint] NOT NULL CONSTRAINT [DF_EXPN_EXTR_PRCT] DEFAULT ((0)),
[EXPN_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_EXPN_EXPN_STAT] DEFAULT ('002'),
[ADD_QUTS] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Expense_ADD_QUTS] DEFAULT ('001'),
[COVR_DSCT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Expense_COVR_DSCT] DEFAULT ('002'),
[EXPN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BUY_PRIC] [bigint] NULL,
[BUY_EXTR_PRCT] [bigint] NULL,
[NUMB_OF_STOK] [int] NULL,
[NUMB_OF_SALE] [int] NULL,
[NUMB_OF_REMN_DNRM] [int] NULL,
[ORDR_ITEM] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COVR_TAX] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NUMB_OF_ATTN_MONT] [int] NULL,
[NUMB_OF_ATTN_WEEK] [int] NULL CONSTRAINT [DF_Expense_NUMB_OF_ATTN_WEEK] DEFAULT ((3)),
[MODL_NUMB_BAR_CODE] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRVT_COCH_EXPN] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MIN_NUMB] [int] NULL,
[NUMB_CYCL_DAY] [int] NULL,
[NUMB_MONT_OFER] [int] NULL,
[MIN_TIME] [datetime] NULL,
[RELY_CMND] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_EXPN]
   ON [dbo].[Expense]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   --SELECT * FROM inserted;
   -- Insert statements for trigger here
   
   -- نوع های آیین نامه
   -- 001 = هزینه
   -- 002 = حساب
   -- آیین نامه فعال
   -- 001 = غیرفعال
   -- 002 = فعال
   
   MERGE dbo.Expense T
   USING (SELECT * FROM INSERTED) S
   ON (T.REGL_YEAR = S.REGL_YEAR AND
       T.REGL_CODE = S.REGL_CODE AND
       T.EXTP_CODE = S.EXTP_CODE AND
       T.CTGY_CODE = S.CTGY_CODE AND
       T.MTOD_CODE = S.MTOD_CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE();
            --,CODE      = DBO.GNRT_NVID_U();
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_EXPN]
   ON [dbo].[Expense]
   AFTER UPDATE
AS 
BEGIN
   BEGIN TRY
   BEGIN TRAN CG$AUPD_EXPN_T
   
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   
   -- نوع های آیین نامه
   -- 001 = هزینه
   -- 002 = حساب
   -- آیین نامه فعال
   -- 001 = غیرفعال
   -- 002 = فعال
   
   DELETE Expense 
   WHERE EXISTS(
      SELECT *
        FROM INSERTED I
       WHERE I.EXTP_CODE IS NULL
       AND Expense.CODE = I.CODE
       AND NOT EXISTS(
         SELECT *
           FROM Payment_Detail pd
          WHERE pd.EXPN_CODE = I.CODE
       )
   );

   -- اگر مبلغ هزینه خواستیم تغییر دهیم باید چک کنیم که قبلا هیچ مبلغ واریزی با نرخ قدیم نداشته باشیم.
   IF EXISTS(SELECT * FROM Payment_Detail Pd, INSERTED I WHERE Pd.EXPN_CODE = I.CODE AND Pd.PAY_STAT = '002' AND Pd.EXPN_PRIC <> I.PRIC AND Pd.EXPN_EXTR_PRCT <> I.EXTR_PRCT)
   BEGIN
      RAISERROR(N'از این نرخ قبلا مورد وصولی داشته اید، شما بایستی آیین نامه درآمد جدیدی ثبت کنید و نرخ جدید را درآن لحاظ کنید', 16, 1);
      RETURN;
   END
   
   --SELECT * FROM Inserted;
   --RAISERROR(N'[CG$AUPD_EXPN]', 16, 1);
   
   MERGE dbo.Expense T
   USING (SELECT E.Code, E.Regl_Year, E.Regl_Code, I.Extp_Code, I.Ctgy_Code, I.Mtod_Code, I.Pric, I.Expn_Desc, I.EXPN_TYPE, I.Numb_Of_Stok, I.Numb_Of_Sale, I.Numb_Of_Remn_Dnrm, I.Covr_Tax, i.ORDR_ITEM FROM INSERTED I, Expense E WHERE I.Code = E.Code) S
   ON (T.REGL_YEAR = S.REGL_YEAR AND
       T.REGL_CODE = S.REGL_CODE AND
       T.EXTP_CODE = S.EXTP_CODE AND
       T.CTGY_CODE = S.CTGY_CODE AND
       T.MTOD_CODE = S.MTOD_CODE AND
       T.CODE      = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()            
            ,EXTR_PRCT = CASE S.Covr_Tax WHEN '002' THEN (SELECT (S.PRIC * (TAX_PRCT + DUTY_PRCT)) / 100 FROM dbo.Regulation WHERE [YEAR] = S.REGL_YEAR AND CODE = S.REGL_CODE AND [TYPE] = '001') ELSE 0 END
            ,EXPN_DESC = CASE WHEN LEN(S.EXPN_DESC) = 0 OR S.EXPN_DESC IS NULL THEN (SELECT EPIT_DESC FROM Expense_Type Et, Expense_Item Ei WHERE Et.Code = S.Extp_Code AND Et.Epit_Code = Ei.Code) ELSE S.Expn_Desc END
            ,NUMB_OF_REMN_DNRM = CASE S.EXPN_TYPE WHEN '001' /* خدمت */ THEN S.NUMB_OF_REMN_DNRM WHEN '002' /* کالا */ THEN ISNULL(S.NUMB_OF_STOK, 0) - ISNULL(S.NUMB_OF_SALE, 0) END
            --,T.ORDR_ITEM = CASE s.ORDR_ITEM 
            --                    WHEN 0 THEN (SELECT ISNULL(MAX(e.ORDR_ITEM), 0) + 1
            --                                            FROM dbo.Expense e
            --                                           WHERE e.EXPN_STAT = '002'
            --                                             AND e.ORDR_ITEM IS NOT NULL) 
            --                    ELSE S.ORDR_ITEM 
            --               END 
            /*,EXPN_DESC = (SELECT EXTP.EXTP_DESC + N' به سبک ' + MTOD.MTOD_DESC + N' با رسته ' + CTGY.CTGY_DESC
                            FROM dbo.Expense_Type EXTP, dbo.Category_Belt CTGY, dbo.Method MTOD
                           WHERE EXTP.CODE = S.EXTP_CODE
                             AND CTGY.CODE = S.CTGY_CODE
                             AND MTOD.CODE = S.MTOD_CODE)*/;

   
   -- بروز رسانی گروه ها، و برندهای پدر
   IF EXISTS(
      SELECT *
        FROM Inserted i
       WHERE i.GROP_CODE IS NOT NULL 
          OR i.BRND_CODE IS NOT NULL
   )
   BEGIN
      -- بروز رسانی گروه جدید
      UPDATE ge
         SET ge.SUB_EXPN_NUMB_DNRM = (SELECT COUNT(e.CODE) FROM dbo.Expense e WHERE e.GROP_CODE = ge.CODE)
        FROM Group_Expense ge, INSERTed i
       WHERE ge.CODE = i.GROP_CODE         
         AND ge.STAT = '002';
      
      IF EXISTS(SELECT * FROM Inserted i, Deleted d WHERE i.GROP_CODE != d.GROP_CODE)
      BEGIN
         -- بروز رسانی گروه جدید
         UPDATE ge
            SET ge.SUB_EXPN_NUMB_DNRM = (SELECT COUNT(e.CODE) FROM dbo.Expense e WHERE e.GROP_CODE = ge.CODE)
           FROM Group_Expense ge, Deleted d
          WHERE ge.CODE = d.GROP_CODE         
            AND ge.STAT = '002';
      END 
      
      -- بروز رسانی برند جدید
      UPDATE ge
         SET ge.SUB_EXPN_NUMB_DNRM = (SELECT COUNT(e.CODE) FROM dbo.Expense e WHERE e.BRND_CODE = ge.CODE)
        FROM Group_Expense ge, INSERTed i
       WHERE ge.CODE = i.BRND_CODE
         AND ge.STAT = '002';
      
      IF EXISTS(SELECT * FROM Inserted i, Deleted d WHERE i.BRND_CODE != d.BRND_CODE)
      BEGIN
         -- بروز رسانی برند قدیم
         UPDATE ge
            SET ge.SUB_EXPN_NUMB_DNRM = (SELECT COUNT(e.CODE) FROM dbo.Expense e WHERE e.BRND_CODE = ge.CODE)
           FROM Group_Expense ge, Deleted d
          WHERE ge.CODE = d.BRND_CODE
            AND ge.STAT = '002';
      END 
      
      -- بروزرسانی اطلاعات درون سیستم ربات
      IF EXISTS(SELECT name FROM sys.databases WHERE name = N'iRoboTech')
      BEGIN
         UPDATE rp
            SET rp.GROP_TEXT_DNRM = ''
           FROM iRoboTech.dbo.Robot_Product rp, Inserted i 
          WHERE rp.TARF_CODE = i.ORDR_ITEM;
      END 
   END
   
   COMMIT TRAN CG$AUPD_EXPN_T;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH;
END
;
GO
ALTER TABLE [dbo].[Expense] ADD CONSTRAINT [CK_EXPN_EXPN_STAT] CHECK (([EXPN_STAT]='002' OR [EXPN_STAT]='001'))
GO
ALTER TABLE [dbo].[Expense] ADD CONSTRAINT [EXPN_PK] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Expense] ADD CONSTRAINT [FK_EXPN_BRND] FOREIGN KEY ([BRND_CODE]) REFERENCES [dbo].[Group_Expense] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Expense] ADD CONSTRAINT [FK_EXPN_CTGY] FOREIGN KEY ([CTGY_CODE]) REFERENCES [dbo].[Category_Belt] ([CODE]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Expense] ADD CONSTRAINT [FK_EXPN_EXTP] FOREIGN KEY ([EXTP_CODE]) REFERENCES [dbo].[Expense_Type] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Expense] ADD CONSTRAINT [FK_EXPN_GROP] FOREIGN KEY ([GROP_CODE]) REFERENCES [dbo].[Group_Expense] ([CODE])
GO
ALTER TABLE [dbo].[Expense] ADD CONSTRAINT [FK_EXPN_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Expense] ADD CONSTRAINT [FK_EXPN_REGL] FOREIGN KEY ([REGL_YEAR], [REGL_CODE]) REFERENCES [dbo].[Regulation] ([YEAR], [CODE]) ON DELETE SET NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'درآمدهای اضافی خارج از برنامه', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'ADD_QUTS'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد برند', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'BRND_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ارزش افزوده خرید', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'BUY_EXTR_PRCT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ خرید', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'BUY_PRIC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شامل محاسبه تخفیف می شود یا خیر', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'COVR_DSCT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ایا هزینه شامل ارزش افزوده می شود؟', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'COVR_TAX'
GO
EXEC sp_addextendedproperty N'MS_Description', N'رسته مشترک', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'CTGY_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شرح هزینه', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'EXPN_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت هزینه', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'EXPN_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع هزینه', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'EXPN_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع هزینه', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'EXTP_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ارزش افزوده', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'EXTR_PRCT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'گروه محصولات', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'GROP_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'میزان حداقل تعداد کالا', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'MIN_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'محاسبه حداقل زمان برای بازی های رزروی', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'MIN_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'سبک مشترک', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'MTOD_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد روز دوره', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'NUMB_CYCL_DAY'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد ماه های تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'NUMB_MONT_OFER'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد جلسات', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'NUMB_OF_ATTN_MONT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد جلسات حضور در هفته', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'NUMB_OF_ATTN_WEEK'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد کالای باقیمانده', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'NUMB_OF_REMN_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد کالای فروخته شده', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'NUMB_OF_SALE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد کل موجودی کالای', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'NUMB_OF_STOK'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'PRIC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد آیین نامه', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'REGL_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'سال آیین نامه', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'REGL_YEAR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'دستور ارسال به رله', 'SCHEMA', N'dbo', 'TABLE', N'Expense', 'COLUMN', N'RELY_CMND'
GO
