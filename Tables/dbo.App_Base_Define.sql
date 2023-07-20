CREATE TABLE [dbo].[App_Base_Define]
(
[CODE] [bigint] NOT NULL,
[RWNO] [int] NULL,
[TITL_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ENTY_NAME] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REF_CODE] [bigint] NULL,
[LVRG_VALU] [real] NULL,
[NUMB] [float] NULL,
[UNIT] [smallint] NULL,
[PRT1_TIME] [datetime] NULL,
[PRT2_TIME] [datetime] NULL,
[PRT3_TIME] [datetime] NULL,
[PRT4_TIME] [datetime] NULL,
[PRT5_TIME] [datetime] NULL,
[PRT6_TIME] [datetime] NULL,
[SEX_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COLR] [int] NULL,
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
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AINS_APBS]
   ON  [dbo].[App_Base_Define]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.App_Base_Define T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET T.CRET_BY = UPPER(SUSER_NAME())
            ,T.CRET_DATE = GETDATE()
            ,T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END
            ,RWNO   = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.App_Base_Define WHERE ENTY_NAME = s.ENTY_NAME);

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
CREATE TRIGGER [dbo].[CG$UPD_APBS]
   ON  [dbo].[App_Base_Define]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.App_Base_Define T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET T.MDFY_BY = UPPER(SUSER_NAME())
            ,T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[App_Base_Define] ADD CONSTRAINT [PK_APBS] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[App_Base_Define] ADD CONSTRAINT [FK_RAPB_APBS] FOREIGN KEY ([REF_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'دامنه های کاربری', 'SCHEMA', N'dbo', 'TABLE', N'App_Base_Define', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد', 'SCHEMA', N'dbo', 'TABLE', N'App_Base_Define', 'COLUMN', N'CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'رنگ', 'SCHEMA', N'dbo', 'TABLE', N'App_Base_Define', 'COLUMN', N'COLR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ساعت شروع بلیط فروشی', 'SCHEMA', N'dbo', 'TABLE', N'App_Base_Define', 'COLUMN', N'PRT1_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شروع سانس', 'SCHEMA', N'dbo', 'TABLE', N'App_Base_Define', 'COLUMN', N'PRT2_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ساعت پایان بلیط فروشی', 'SCHEMA', N'dbo', 'TABLE', N'App_Base_Define', 'COLUMN', N'PRT3_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ساعت نزدیک به سانس پایان', 'SCHEMA', N'dbo', 'TABLE', N'App_Base_Define', 'COLUMN', N'PRT4_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ساعت پایان سانس و خروج برای دوش و رختکن', 'SCHEMA', N'dbo', 'TABLE', N'App_Base_Define', 'COLUMN', N'PRT5_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ساعت پایان سانس', 'SCHEMA', N'dbo', 'TABLE', N'App_Base_Define', 'COLUMN', N'PRT6_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ترتیب', 'SCHEMA', N'dbo', 'TABLE', N'App_Base_Define', 'COLUMN', N'RWNO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'جنسیت', 'SCHEMA', N'dbo', 'TABLE', N'App_Base_Define', 'COLUMN', N'SEX_TYPE'
GO
