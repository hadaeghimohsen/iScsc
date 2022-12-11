CREATE TABLE [dbo].[Expense_Cost]
(
[EXPN_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RWNO] [smallint] NULL,
[INIT_AMNT_DNRM] [bigint] NULL,
[EXCO_APBS_CODE] [bigint] NULL,
[EXCO_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXCO_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXCO_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXCO_AMNT] [bigint] NULL,
[EXCO_CALC_AMNT] [bigint] NULL,
[RMND_AMNT] [bigint] NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [BLOB]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AINS_EXCO]
   ON  [dbo].[Expense_Cost]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Expense_Cost T
   USING (SELECT * FROM Inserted) S
   ON (T.EXPN_CODE = S.EXPN_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE S.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.CODE END,
         T.RWNO = (SELECT ISNULL(MAX(EC.RWNO), 0) + 1 FROM dbo.Expense_Cost EC WHERE EC.EXPN_CODE = S.EXPN_CODE),
         T.EXCO_STAT = ISNULL(S.EXCO_STAT, '002'),
         T.EXCO_TYPE = ISNULL(S.EXCO_TYPE, '001'),
         T.EXCO_AMNT = ISNULL(s.EXCO_AMNT, 10);
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AUPD_EXCO]
   ON  [dbo].[Expense_Cost]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Expense_Cost T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE(),
         t.RMND_AMNT = ISNULL(s.INIT_AMNT_DNRM, 0) - (ISNULL(S.EXCO_CALC_AMNT, 0));
END
GO
ALTER TABLE [dbo].[Expense_Cost] ADD CONSTRAINT [PK_EXCO] PRIMARY KEY CLUSTERED  ([CODE]) ON [BLOB]
GO
ALTER TABLE [dbo].[Expense_Cost] ADD CONSTRAINT [FK_EXCO_APBS] FOREIGN KEY ([EXCO_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Expense_Cost] ADD CONSTRAINT [FK_EXCO_EXPN] FOREIGN KEY ([EXPN_CODE]) REFERENCES [dbo].[Expense] ([CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'میزان کسری', 'SCHEMA', N'dbo', 'TABLE', N'Expense_Cost', 'COLUMN', N'EXCO_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع آیتم های کسری هزینه', 'SCHEMA', N'dbo', 'TABLE', N'Expense_Cost', 'COLUMN', N'EXCO_APBS_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ کسری محاسبه شده', 'SCHEMA', N'dbo', 'TABLE', N'Expense_Cost', 'COLUMN', N'EXCO_CALC_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'توضیحات', 'SCHEMA', N'dbo', 'TABLE', N'Expense_Cost', 'COLUMN', N'EXCO_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت', 'SCHEMA', N'dbo', 'TABLE', N'Expense_Cost', 'COLUMN', N'EXCO_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع محاسبه کسری (درصدی / مبلغی)', 'SCHEMA', N'dbo', 'TABLE', N'Expense_Cost', 'COLUMN', N'EXCO_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ اولیه', 'SCHEMA', N'dbo', 'TABLE', N'Expense_Cost', 'COLUMN', N'INIT_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'باقیمانده', 'SCHEMA', N'dbo', 'TABLE', N'Expense_Cost', 'COLUMN', N'RMND_AMNT'
GO
