CREATE TABLE [dbo].[Change_Body_Fitness]
(
[BDFT_FIGH_FILE_NO] [bigint] NOT NULL,
[BDFT_RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BDFT_RWNO] [int] NOT NULL,
[BODY_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RWNO] [smallint] NOT NULL,
[EFCT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHBF_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRTY_NUMB] [smallint] NULL,
[INDC_WEGH_DUMB] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INDC_AMNT_WEGH_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INDC_AMNT_WEGH] [real] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_CHBF]
   ON  [dbo].[Change_Body_Fitness]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here   
   
   MERGE dbo.[Change_Body_Fitness] T
   USING (SELECT * FROM INSERTED i) S
   ON (T.BDFT_FIGH_FILE_NO = S.BDFT_FIGH_FILE_NO AND
       T.BDFT_RECT_CODE    = S.BDFT_RECT_CODE AND
       T.BDFT_RWNO         = S.BDFT_RWNO AND
       T.BODY_TYPE         = S.BODY_TYPE)
   WHEN MATCHED THEN
      UPDATE 
      SET CRET_BY   = UPPER(SUSER_NAME())
         ,CRET_DATE = GETDATE()
         ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM [Change_Body_Fitness] WHERE BDFT_FIGH_FILE_NO = S.BDFT_FIGH_FILE_NO AND BDFT_RECT_CODE = S.BDFT_RECT_CODE AND BDFT_RWNO = S.BDFT_RWNO /*AND BODY_TYPE = S.BODY_TYPE*/);

END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_CHBF]
   ON  [dbo].[Change_Body_Fitness]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here   
   
   MERGE dbo.Change_Body_Fitness T
   USING (SELECT * FROM INSERTED i) S
   ON (T.BDFT_FIGH_FILE_NO = S.BDFT_FIGH_FILE_NO AND
       T.BDFT_RECT_CODE    = S.BDFT_RECT_CODE AND
       T.BDFT_RWNO         = S.BDFT_RWNO AND
       T.BODY_TYPE         = S.BODY_TYPE AND
       T.RWNO              = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
      SET MDFY_BY   = UPPER(SUSER_NAME())
         ,MDFY_DATE = GETDATE();

END
;
GO
ALTER TABLE [dbo].[Change_Body_Fitness] ADD CONSTRAINT [PK_CHBF] PRIMARY KEY CLUSTERED  ([BDFT_FIGH_FILE_NO], [BDFT_RECT_CODE], [BDFT_RWNO], [BODY_TYPE], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Change_Body_Fitness] ADD CONSTRAINT [FK_CHBF_BDFT] FOREIGN KEY ([BDFT_FIGH_FILE_NO], [BDFT_RECT_CODE], [BDFT_RWNO]) REFERENCES [dbo].[Body_Fitness] ([FIGH_FILE_NO], [RECT_CODE], [RWNO])
GO
EXEC sp_addextendedproperty N'MS_Description', N'CHBF', 'SCHEMA', N'dbo', 'TABLE', N'Change_Body_Fitness', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'مقدار یا درصد افزایش', 'SCHEMA', N'dbo', 'TABLE', N'Change_Body_Fitness', 'COLUMN', N'INDC_AMNT_WEGH'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع افزایش مقدار وزنه', 'SCHEMA', N'dbo', 'TABLE', N'Change_Body_Fitness', 'COLUMN', N'INDC_AMNT_WEGH_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'افزایش یا کاهش وزنه داشته باشیم', 'SCHEMA', N'dbo', 'TABLE', N'Change_Body_Fitness', 'COLUMN', N'INDC_WEGH_DUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'میزان اولویت', 'SCHEMA', N'dbo', 'TABLE', N'Change_Body_Fitness', 'COLUMN', N'PRTY_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت', 'SCHEMA', N'dbo', 'TABLE', N'Change_Body_Fitness', 'COLUMN', N'STAT'
GO
