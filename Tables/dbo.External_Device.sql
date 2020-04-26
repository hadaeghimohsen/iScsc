CREATE TABLE [dbo].[External_Device]
(
[CODE] [bigint] NOT NULL,
[DEV_COMP_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEV_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEV_CON] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CYCL_READ] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEV_NAME] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PORT_NAME] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BAND_RATE] [int] NULL,
[IP_ADRS] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PORT_SEND] [bigint] NULL,
[PORT_RECV] [bigint] NULL,
[MTOD_CODE] [bigint] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACTN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPN_CODE] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_EXDV]
   ON  [dbo].[External_Device]
   AFTER INSERT   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.External_Device T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME())
        ,t.CRET_DATE = GETDATE()
        ,t.CODE = CASE WHEN ISNULL(s.CODE, 0) = 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;
        
         
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
CREATE TRIGGER [dbo].[CG$AUPD_EXDV]
   ON  [dbo].[External_Device]
   AFTER UPDATE   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.External_Device T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,t.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[External_Device] ADD CONSTRAINT [PK_External_Device] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع وضعیت برخورد با داده رسیده از دستگاه
عملیات حضور و غیاب انجام شود یا 
مبلغ بابت هزینه خدمات از سپرده کسر گردد', 'SCHEMA', N'dbo', 'TABLE', N'External_Device', 'COLUMN', N'ACTN_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'دوره خواندن اطلاعات
برای دستگاه های 
encoder
باید مدت زمان 200 میلی ثانیه مدام دستگاه ریدر را چک کنیم
ولی برای دستگاه های ریدر عادی اطلاعات به صورت 
interupt 
خوانده میشود', 'SCHEMA', N'dbo', 'TABLE', N'External_Device', 'COLUMN', N'CYCL_READ'
GO
EXEC sp_addextendedproperty N'MS_Description', N'دستگاه متعلق به کدام شرکت می باشد مثلا شرکت صائلا', 'SCHEMA', N'dbo', 'TABLE', N'External_Device', 'COLUMN', N'DEV_COMP_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع اتصال دستگاه', 'SCHEMA', N'dbo', 'TABLE', N'External_Device', 'COLUMN', N'DEV_CON'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نام دستگاه', 'SCHEMA', N'dbo', 'TABLE', N'External_Device', 'COLUMN', N'DEV_NAME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع دستگاه مثلا کارت خوان یا گیت تردد', 'SCHEMA', N'dbo', 'TABLE', N'External_Device', 'COLUMN', N'DEV_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'بررسی اینکه گیت کدام مبلغ هزینه را بررسی کند و از سپرده کسر کند', 'SCHEMA', N'dbo', 'TABLE', N'External_Device', 'COLUMN', N'EXPN_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'این گزینه برای گیت ها مورد استفاده قرار میگیرد', 'SCHEMA', N'dbo', 'TABLE', N'External_Device', 'COLUMN', N'IP_ADRS'
GO
EXEC sp_addextendedproperty N'MS_Description', N'بررسی اینکه این دستگاه چه ورزشی راه بررسی میکند', 'SCHEMA', N'dbo', 'TABLE', N'External_Device', 'COLUMN', N'MTOD_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره پورت دریافت داده از گیت', 'SCHEMA', N'dbo', 'TABLE', N'External_Device', 'COLUMN', N'PORT_RECV'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره پورت ارسال داده به گیت', 'SCHEMA', N'dbo', 'TABLE', N'External_Device', 'COLUMN', N'PORT_SEND'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت دستگاه', 'SCHEMA', N'dbo', 'TABLE', N'External_Device', 'COLUMN', N'STAT'
GO
