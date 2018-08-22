CREATE TABLE [dbo].[Payment]
(
[REGL_YEAR_DNRM] [smallint] NULL,
[REGL_CODE_DNRM] [int] NULL,
[CASH_CODE] [bigint] NOT NULL,
[RQST_RQID] [bigint] NOT NULL,
[TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Payment__TYPE__02FC7413] DEFAULT ('001'),
[RECV_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Payment__RECV_TY__03F0984C] DEFAULT ('001'),
[SUM_EXPN_PRIC] [int] NOT NULL CONSTRAINT [DF__Payment__SUM_EXP__04E4BC85] DEFAULT ((0)),
[SUM_EXPN_EXTR_PRCT] [int] NOT NULL CONSTRAINT [DF__Payment__SUM_EXP__05D8E0BE] DEFAULT ((0)),
[SUM_REMN_PRIC] [int] NOT NULL CONSTRAINT [DF__Payment__SUM_REM__06CD04F7] DEFAULT ((0)),
[SUM_RCPT_EXPN_PRIC] [int] NULL CONSTRAINT [DF__Payment__SUM_RCP__07C12930] DEFAULT ((0)),
[SUM_RCPT_EXPN_EXTR_PRCT] [int] NULL CONSTRAINT [DF__Payment__SUM_RCP__08B54D69] DEFAULT ((0)),
[SUM_RCPT_REMN_PRIC] [int] NULL CONSTRAINT [DF__Payment__SUM_RCP__09A971A2] DEFAULT ((0)),
[SUM_PYMT_DSCN_DNRM] [int] NULL CONSTRAINT [DF_Payment_SUM_PYMT_DSCN_DNRM] DEFAULT ((0)),
[CASH_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CASH_DATE] [datetime] NULL,
[ANNC_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__Payment__ANNC_TY__0A9D95DB] DEFAULT ('001'),
[ANNC_DATE] [datetime] NULL,
[LETT_NO] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LETT_DATE] [datetime] NULL,
[DELV_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Payment_DELV_STAT] DEFAULT ((1)),
[DELV_DATE] [datetime] NULL,
[DELV_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CLUB_CODE_DNRM] [bigint] NULL,
[AMNT_UNIT_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LOCK_DATE] [datetime] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_PYMT]
   ON  [dbo].[Payment]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Payment T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQST_RQID = S.RQST_RQID AND
       T.CASH_CODE = S.CASH_CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,DELV_STAT = '001'
            ,CLUB_CODE_DNRM = 
            CASE WHEN (
				   SELECT TOP 1 CLUB_CODE 
				     FROM Fighter_Public F 
				    WHERE F.Rqro_Rqst_Rqid = S.Rqst_Rqid) IS NOT NULL THEN (
				      SELECT TOP 1 CLUB_CODE 
				        FROM Fighter_Public F 
				       WHERE F.Rqro_Rqst_Rqid = S.Rqst_Rqid)
				    ELSE (
				      SELECT F.Club_Code_Dnrm
				        FROM Fighter F
				       WHERE F.Rqst_Rqid = S.Rqst_Rqid
				    )
				 END
				,T.AMNT_UNIT_TYPE_DNRM = (
				   SELECT ISNULL(AMNT_TYPE, '001')
				     FROM dbo.Regulation
				    WHERE REGL_STAT = '002'
				      AND [TYPE] = '001'
				)
				,T.LOCK_DATE = DATEADD(DAY, 30, GETDATE())
				,T.REGL_YEAR_DNRM = (
				   SELECT YEAR
				     FROM dbo.Regulation
				    WHERE REGL_STAT = '002'
				      AND [TYPE] = '001'
				)
				,T.REGL_CODE_DNRM = (
				   SELECT CODE
				     FROM dbo.Regulation
				    WHERE REGL_STAT = '002'
				      AND [TYPE] = '001'
				);
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_PYMT]
   ON  [dbo].[Payment]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- Insert statements for trigger here
   IF EXISTS(
      SELECT * FROM DELETED D, INSERTED I
      WHERE D.RQST_RQID = I.RQST_RQID
        AND D.TYPE      <> I.TYPE
   )
   BEGIN
      RAISERROR ('مبلغ اعلام هزینه شده از حالت واریز وجه به حالت استرداد وجه و برعکس امکان پذیر نمی باشد', -- Message text.
         16, -- Severity.
         1 -- State.
         );
      ROLLBACK TRANSACTION;
   END;

   -- 1396/03/04 * تاریخ و زمانی که هزینه قفل شده بعدا در سیستم لحاظ گردد
   
   MERGE dbo.Payment T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQST_RQID = S.RQST_RQID AND 
       T.CASH_CODE = S.CASH_CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,CASH_BY   = CASE WHEN S.SUM_EXPN_PRIC = (ISNULL(S.SUM_RCPT_EXPN_PRIC, 0) + S.SUM_PYMT_DSCN_DNRM) AND S.Cash_By IS NULL THEN SUSER_NAME() WHEN S.Cash_By IS NULL THEN NULL ELSE S.Cash_By END
            ,CASH_DATE = CASE WHEN S.SUM_EXPN_PRIC = (ISNULL(S.SUM_RCPT_EXPN_PRIC, 0) + S.SUM_PYMT_DSCN_DNRM) AND S.Cash_Date IS NULL THEN GETDATE()  WHEN S.Cash_Date IS NULL THEN NULL ELSE S.Cash_Date END
            /*,SUM_EXPN_PRIC = S.SUM_EXPN_PRIC - ISNULL(S.SUM_PYMT_DSCN_DNRM, 0)*/;
   
   IF EXISTS(
       SELECT *
         FROM dbo.Payment_Method pm, Inserted i
        WHERE pm.PYMT_RQST_RQID = i.RQST_RQID
   ) OR 
   EXISTS(
       SELECT *
         FROM dbo.Payment_Discount pd, Inserted i
        WHERE pd.PYMT_RQST_RQID = i.RQST_RQID
          AND pd.STAT = '002'
   )
   BEGIN
      UPDATE p
         SET p.SUM_RCPT_EXPN_PRIC = (SELECT ISNULL(SUM(pm.AMNT), 0) FROM dbo.Payment_Method pm WHERE pm.PYMT_RQST_RQID = p.RQST_RQID)
            ,p.SUM_PYMT_DSCN_DNRM = (SELECT ISNULL(SUM(pd.AMNT), 0) FROM dbo.Payment_Discount pd WHERE pd.PYMT_RQST_RQID = p.RQST_RQID)
        FROM dbo.Payment p, Inserted i
       WHERE p.RQST_RQID = i.RQST_RQID
   END;
   
   -- 1396/08/02 * برای آن دسته از درخواست هایی که مشتری کل پرداختی هزینه خود را پرداخت کرده به صورت اتوماتیک وضعیت هزینه پرداخت شده ثبت کنیم     
   /*IF EXISTS(
      SELECT *
        FROM dbo.Payment p , Inserted i
       WHERE p.RQST_RQID = i.RQST_RQID
         AND p.CASH_CODE = i.CASH_CODE
         AND (p.SUM_EXPN_PRIC + ISNULL(p.SUM_EXPN_EXTR_PRCT, 0) - (ISNULL(p.SUM_RCPT_EXPN_PRIC, 0) + ISNULL(p.SUM_PYMT_DSCN_DNRM, 0))) = 0
   )
   BEGIN
      UPDATE pd
         SET pd.PAY_STAT = '002'
            ,pd.DOCM_NUMB = i.CASH_CODE
            ,pd.ISSU_DATE = GETDATE()
        FROM dbo.Payment_Detail pd, Inserted i
       WHERE pd.PYMT_RQST_RQID = i.RQST_RQID
         AND pd.PYMT_CASH_CODE = i.CASH_CODE
         AND PAY_STAT = '001';
   END*/
END
;
GO
ALTER TABLE [dbo].[Payment] ADD CONSTRAINT [PYMT_PK] PRIMARY KEY CLUSTERED  ([CASH_CODE], [RQST_RQID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Payment] ADD CONSTRAINT [FK_PYMT_CASH] FOREIGN KEY ([CASH_CODE]) REFERENCES [dbo].[Cash] ([CODE])
GO
ALTER TABLE [dbo].[Payment] ADD CONSTRAINT [FK_PYMT_CLUB] FOREIGN KEY ([CLUB_CODE_DNRM]) REFERENCES [dbo].[Club] ([CODE])
GO
ALTER TABLE [dbo].[Payment] ADD CONSTRAINT [FK_PYMT_REGL] FOREIGN KEY ([REGL_YEAR_DNRM], [REGL_CODE_DNRM]) REFERENCES [dbo].[Regulation] ([YEAR], [CODE])
GO
ALTER TABLE [dbo].[Payment] ADD CONSTRAINT [FK_PYMT_RQST] FOREIGN KEY ([RQST_RQID]) REFERENCES [dbo].[Request] ([RQID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'واحد پولی', 'SCHEMA', N'dbo', 'TABLE', N'Payment', 'COLUMN', N'AMNT_UNIT_TYPE_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان تغییرات هزینه ای', 'SCHEMA', N'dbo', 'TABLE', N'Payment', 'COLUMN', N'LOCK_DATE'
GO
