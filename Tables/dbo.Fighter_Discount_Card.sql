CREATE TABLE [dbo].[Fighter_Discount_Card]
(
[ADVP_CODE] [bigint] NULL,
[FIGH_FILE_NO] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RECD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DISC_CODE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPR_DATE] [datetime] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MTOD_CODE] [bigint] NULL,
[CTGY_CODE] [bigint] NULL,
[DSCT_AMNT] [bigint] NULL,
[DSCT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQTP_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DSCT_DESC] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TEMP_TMID] [bigint] NULL,
[RQST_RQID] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_FGDC]
   ON  [dbo].[Fighter_Discount_Card]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   -- Insert statements for trigger here
   MERGE dbo.Fighter_Discount_Card T
   USING (SELECT * FROM Inserted) S
   ON (T.FIGH_FILE_NO = S.FIGH_FILE_NO AND
       T.CODE = S.CODE)
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
CREATE TRIGGER [dbo].[CG$AUPD_FGDC]
   ON  [dbo].[Fighter_Discount_Card]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   -- Insert statements for trigger here
   MERGE dbo.Fighter_Discount_Card T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE(),
         t.MTOD_CODE = (SELECT c.MTOD_CODE FROM dbo.Category_Belt c WHERE c.CODE = s.CTGY_CODE);
END
GO
ALTER TABLE [dbo].[Fighter_Discount_Card] ADD CONSTRAINT [PK_FGDC] PRIMARY KEY CLUSTERED  ([CODE]) WITH (FILLFACTOR=100) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Fighter_Discount_Card] ADD CONSTRAINT [FK_FGDC_ADVP] FOREIGN KEY ([ADVP_CODE]) REFERENCES [dbo].[Advertising_Parameter] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Fighter_Discount_Card] ADD CONSTRAINT [FK_FGDC_CTGY] FOREIGN KEY ([CTGY_CODE]) REFERENCES [dbo].[Category_Belt] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Fighter_Discount_Card] ADD CONSTRAINT [FK_FGDC_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Fighter_Discount_Card] ADD CONSTRAINT [FK_FGDC_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Fighter_Discount_Card] ADD CONSTRAINT [FK_FGDC_RQST] FOREIGN KEY ([RQST_RQID]) REFERENCES [dbo].[Request] ([RQID]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Fighter_Discount_Card] ADD CONSTRAINT [FK_FGDC_TEMP] FOREIGN KEY ([TEMP_TMID]) REFERENCES [dbo].[Template] ([TMID]) ON DELETE SET NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'زیر گروه', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Discount_Card', 'COLUMN', N'CTGY_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد تخفیف تولید شده برای مشتریان', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Discount_Card', 'COLUMN', N'DISC_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Discount_Card', 'COLUMN', N'DSCT_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'توضیحات کد تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Discount_Card', 'COLUMN', N'DSCT_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Discount_Card', 'COLUMN', N'DSCT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ اعتبار کد تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Discount_Card', 'COLUMN', N'EXPR_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'گروه', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Discount_Card', 'COLUMN', N'MTOD_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع رکورد تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Discount_Card', 'COLUMN', N'RECD_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع درخواست', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Discount_Card', 'COLUMN', N'RQTP_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت کد تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Fighter_Discount_Card', 'COLUMN', N'STAT'
GO
