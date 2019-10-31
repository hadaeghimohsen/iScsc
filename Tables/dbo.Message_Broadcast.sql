CREATE TABLE [dbo].[Message_Broadcast]
(
[CODE] [bigint] NOT NULL CONSTRAINT [DF_Message_Broadcast_CODE] DEFAULT ((0)),
[LINE_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MSGB_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Message_Broadcast_STAT] DEFAULT ('002'),
[TELG_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INSR_FNAM_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Message_Broadcast_INSR_FNAM_STAT] DEFAULT ('001'),
[INSR_CNAM_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Message_Broadcast_INSR_CNAM_STAT] DEFAULT ('002'),
[CLUB_CODE] [bigint] NULL,
[CLUB_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEBT_PRIC] [bigint] NULL,
[MSGB_TEXT] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FROM_DATE] [date] NULL,
[TO_DATE] [date] NULL,
[MIN_NUMB_ATTN_RMND] [int] NULL,
[MIN_NUMB_DAY_RMND] [int] NULL,
[SEND_INFO] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CEL1_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CEL2_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CEL3_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CEL4_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CEL5_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SCDL_DATE] [datetime] NULL,
[BTCH_NUMB] [int] NULL,
[STEP_MIN] [int] NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_MSGB]
   ON  [dbo].[Message_Broadcast]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Message_Broadcast T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE      = DBO.GNRT_NVID_U();
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_MSGB]
   ON  [dbo].[Message_Broadcast]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Message_Broadcast T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
;
GO
ALTER TABLE [dbo].[Message_Broadcast] ADD CONSTRAINT [PK_MSGB] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Message_Broadcast] ADD CONSTRAINT [FK_MSGB_CLUB] FOREIGN KEY ([CLUB_CODE]) REFERENCES [dbo].[Club] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد نفرات بسته های ارسالی', 'SCHEMA', N'dbo', 'TABLE', N'Message_Broadcast', 'COLUMN', N'BTCH_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع خط', 'SCHEMA', N'dbo', 'TABLE', N'Message_Broadcast', 'COLUMN', N'LINE_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'حداقل تعداد جلسات باقیمانده', 'SCHEMA', N'dbo', 'TABLE', N'Message_Broadcast', 'COLUMN', N'MIN_NUMB_ATTN_RMND'
GO
EXEC sp_addextendedproperty N'MS_Description', N'حداقل تعداد روز باقیمانده', 'SCHEMA', N'dbo', 'TABLE', N'Message_Broadcast', 'COLUMN', N'MIN_NUMB_DAY_RMND'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمان بندی برای ارسال پیامک', 'SCHEMA', N'dbo', 'TABLE', N'Message_Broadcast', 'COLUMN', N'SCDL_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ارسال جزئیات پیامک', 'SCHEMA', N'dbo', 'TABLE', N'Message_Broadcast', 'COLUMN', N'SEND_INFO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'گام بعدی برای ارسال بسته های بعدی', 'SCHEMA', N'dbo', 'TABLE', N'Message_Broadcast', 'COLUMN', N'STEP_MIN'
GO
