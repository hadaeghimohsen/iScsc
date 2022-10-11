CREATE TABLE [dbo].[Coupon]
(
[EXPN_CODE] [bigint] NULL,
[COPN_EXPN_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[COPN_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_TEMP_TMID] [bigint] NULL,
[USE_TEMP_TMID] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_COPN]
   ON  [dbo].[Coupon]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Coupon T
   USING (SELECT * FROM Inserted) S
   ON (t.EXPN_CODE = s.EXPN_CODE AND 
       t.COPN_EXPN_CODE = s.COPN_EXPN_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.STAT = ISNULL(s.STAT, '002');
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
CREATE TRIGGER [dbo].[CG$AUPD_COPN]
   ON  [dbo].[Coupon]
   AFTER UPDATE   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Coupon T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Coupon] ADD CONSTRAINT [PK_Coupon] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Coupon] ADD CONSTRAINT [FK_COPN_CTMP] FOREIGN KEY ([CRET_TEMP_TMID]) REFERENCES [dbo].[Template] ([TMID])
GO
ALTER TABLE [dbo].[Coupon] ADD CONSTRAINT [FK_COPN_EXPN1] FOREIGN KEY ([EXPN_CODE]) REFERENCES [dbo].[Expense] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Coupon] ADD CONSTRAINT [FK_COPN_EXPN2] FOREIGN KEY ([COPN_EXPN_CODE]) REFERENCES [dbo].[Expense] ([CODE])
GO
ALTER TABLE [dbo].[Coupon] ADD CONSTRAINT [FK_COPN_UTMP] FOREIGN KEY ([USE_TEMP_TMID]) REFERENCES [dbo].[Template] ([TMID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمانی که رکورد ایجاد میشود برای مشتری پیامک بره', 'SCHEMA', N'dbo', 'TABLE', N'Coupon', 'COLUMN', N'CRET_TEMP_TMID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمانی که رکورد مصرف میشود برای مشتری پیامک بره', 'SCHEMA', N'dbo', 'TABLE', N'Coupon', 'COLUMN', N'USE_TEMP_TMID'
GO
