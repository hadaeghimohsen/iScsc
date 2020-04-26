CREATE TABLE [dbo].[Payment_Cost]
(
[PYMT_CASH_CODE] [bigint] NULL,
[PYMT_RQST_RQID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RWNO] [smallint] NULL,
[AMNT] [bigint] NULL,
[COST_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EFCT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COST_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AINS_PYCO]
   ON  [dbo].[Payment_Cost]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Payment_Cost T
   USING (SELECT * FROM Inserted) S
   ON (t.PYMT_CASH_CODE = s.PYMT_CASH_CODE AND 
       t.PYMT_RQST_RQID = s.PYMT_RQST_RQID AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.RWNO = (SELECT ISNULL(MAX(pc.RWNO), 0) + 1 FROM dbo.Payment_Cost pc WHERE pc.PYMT_CASH_CODE = s.PYMT_CASH_CODE AND pc.PYMT_RQST_RQID = s.PYMT_RQST_RQID);
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
CREATE TRIGGER [dbo].[CG$AUPD_PYCO]
   ON  [dbo].[Payment_Cost]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Payment_Cost T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();         
END
GO
ALTER TABLE [dbo].[Payment_Cost] ADD CONSTRAINT [PK_PYCO] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Payment_Cost] ADD CONSTRAINT [FK_PYCO_PYMT] FOREIGN KEY ([PYMT_CASH_CODE], [PYMT_RQST_RQID]) REFERENCES [dbo].[Payment] ([CASH_CODE], [RQST_RQID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع هزینه ای که برای صورتحساب داشته', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Cost', 'COLUMN', N'COST_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع تاثیر گذاری هزینه
مثلا هزینه کارمزد شرکت از صورتحساب فروشگاه کم میشه و همچنین از سود فروشگاه
ولی هزینه کارمزد خدمات غیرحضوری برای فروشگاه هزینه ای محسوب نمیشه
هزینه ارسال بسته ممکن است برای فروشگاه هزینه بر باشد ممکن است هزینه بر نباشد
از گزینه بلی یا خیر استفاده میکنیم', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Cost', 'COLUMN', N'EFCT_TYPE'
GO
