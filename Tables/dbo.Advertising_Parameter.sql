CREATE TABLE [dbo].[Advertising_Parameter]
(
[CODE] [bigint] NOT NULL,
[ADVP_NAME] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RECD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPR_DATE] [datetime] NULL,
[DISC_CODE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DSCT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DSCT_AMNT] [bigint] NULL,
[RQTP_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MTOD_CODE] [bigint] NULL,
[CTGY_CODE] [bigint] NULL,
[NUMB_LAST_DAY] [int] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TEMP_TMID] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_ADVP] ON [dbo].[Advertising_Parameter]
AFTER INSERT
AS
BEGIN
   MERGE Advertising_Parameter T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE S.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.CODE END;
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_ADVP] ON [dbo].[Advertising_Parameter]
WITH EXEC AS CALLER
AFTER UPDATE
AS
BEGIN
   MERGE Advertising_Parameter T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE(),
         T.MTOD_CODE = (SELECT cb.MTOD_CODE FROM Category_Belt cb WHERE cb.CODE = S.CTGY_CODE);
END
GO
ALTER TABLE [dbo].[Advertising_Parameter] ADD CONSTRAINT [PK_ADVP] PRIMARY KEY CLUSTERED  ([CODE]) WITH (FILLFACTOR=100) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Advertising_Parameter] ADD CONSTRAINT [FK_ADVP_TEMP] FOREIGN KEY ([TEMP_TMID]) REFERENCES [dbo].[Template] ([TMID]) ON DELETE SET NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'عنوان', 'SCHEMA', N'dbo', 'TABLE', N'Advertising_Parameter', 'COLUMN', N'ADVP_NAME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زیر گروه', 'SCHEMA', N'dbo', 'TABLE', N'Advertising_Parameter', 'COLUMN', N'CTGY_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Advertising_Parameter', 'COLUMN', N'DISC_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مقدار تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Advertising_Parameter', 'COLUMN', N'DSCT_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع محاسبه تخفیف درصدی یا مبلغی', 'SCHEMA', N'dbo', 'TABLE', N'Advertising_Parameter', 'COLUMN', N'DSCT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ اعتبار', 'SCHEMA', N'dbo', 'TABLE', N'Advertising_Parameter', 'COLUMN', N'EXPR_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'گروه', 'SCHEMA', N'dbo', 'TABLE', N'Advertising_Parameter', 'COLUMN', N'MTOD_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد روز گذشته', 'SCHEMA', N'dbo', 'TABLE', N'Advertising_Parameter', 'COLUMN', N'NUMB_LAST_DAY'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع رکورد تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Advertising_Parameter', 'COLUMN', N'RECD_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع درخواست', 'SCHEMA', N'dbo', 'TABLE', N'Advertising_Parameter', 'COLUMN', N'RQTP_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت', 'SCHEMA', N'dbo', 'TABLE', N'Advertising_Parameter', 'COLUMN', N'STAT'
GO
