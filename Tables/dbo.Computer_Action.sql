CREATE TABLE [dbo].[Computer_Action]
(
[CODE] [bigint] NOT NULL,
[COMP_NAME] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHCK_DOBL_ATTN_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHCK_ATTN_ALRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MTOD_CODE] [bigint] NULL,
[ANY_DESK_PATH] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ANY_DESK_ID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ANY_DESK_PSWD] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IP_ADRS] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COMP_DESC] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_COMPA]
   ON  [dbo].[Computer_Action]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Computer_Action T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         t.CRET_BY = UPPER(SUSER_NAME())
        ,t.CRET_DATE = GETDATE()
        ,t.CODE = dbo.GNRT_NVID_U();

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
CREATE TRIGGER [dbo].[CG$AUPD_COMPA]
   ON  [dbo].[Computer_Action]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Computer_Action T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         t.MDFY_BY = UPPER(SUSER_NAME())
        ,t.MDFY_DATE = GETDATE()
        ,T.ANY_DESK_PATH = ISNULL(s.ANY_DESK_PATH, 'C:\Program Files (x86)\AnyDesk\Anydesk.exe')
        ,T.ANY_DESK_ID = REPLACE(S.ANY_DESK_ID, ' ', '');
END
GO
ALTER TABLE [dbo].[Computer_Action] ADD CONSTRAINT [PK_COMA] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Computer_Action] ADD CONSTRAINT [FK_COMA_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'حضور یا عدم حضور منشی پشت سیستم
اگر مقدار 1 داشته باشد یعنی منشی حضور دارد
اگر مقدار 2 داشته باشد یعنی منشی حضور ندارد', 'SCHEMA', N'dbo', 'TABLE', N'Computer_Action', 'COLUMN', N'CHCK_ATTN_ALRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'بررسی کردن دوبار خوندن اطلاعات هنرجویان', 'SCHEMA', N'dbo', 'TABLE', N'Computer_Action', 'COLUMN', N'CHCK_DOBL_ATTN_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نام کامپیوتر', 'SCHEMA', N'dbo', 'TABLE', N'Computer_Action', 'COLUMN', N'COMP_NAME'
GO
