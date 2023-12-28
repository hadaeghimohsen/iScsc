CREATE TABLE [dbo].[Payment_Contract]
(
[PYMT_CASH_CODE] [bigint] NULL,
[PYMT_RQST_RQID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RITE_DATE] [date] NULL,
[PERU_DATE] [date] NULL,
[SIZE_DATE] [date] NULL,
[DELV_DATE] [date] NULL,
[MODL_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_PMCT]
   ON  [dbo].[Payment_Contract]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Payment_Contract T
   USING (SELECT * FROM Inserted) S
   ON (T.PYMT_CASH_CODE = s.PYMT_CASH_CODE AND 
       T.PYMT_RQST_RQID = s.PYMT_RQST_RQID AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;   
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
CREATE TRIGGER [dbo].[CG$AUPD_PMCT]
   ON  [dbo].[Payment_Contract]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Payment_Contract T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Payment_Contract] ADD CONSTRAINT [PK_PMCT] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Payment_Contract] ADD CONSTRAINT [FK_PMCT_PYMT] FOREIGN KEY ([PYMT_CASH_CODE], [PYMT_RQST_RQID]) REFERENCES [dbo].[Payment] ([CASH_CODE], [RQST_RQID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ پرو', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Contract', 'COLUMN', N'PERU_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ مراسم', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Contract', 'COLUMN', N'RITE_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'سایزگیری', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Contract', 'COLUMN', N'SIZE_DATE'
GO
