CREATE TABLE [dbo].[Statistic]
(
[CODE] [bigint] NOT NULL,
[STIS_DATE] [date] NULL,
[STIS_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_STIS]
   ON  [dbo].[Statistic]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   
   MERGE dbo.Statistic T
   USING (
      SELECT * 
        FROM INSERTED
   ) S
   ON ( T.CODE = S.CODE )
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;
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
CREATE TRIGGER [dbo].[CG$AUPD_STIS]
   ON  [dbo].[Statistic]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   
   MERGE dbo.Statistic T
   USING (
      SELECT * 
        FROM INSERTED
   ) S
   ON ( T.CODE = S.CODE )
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Statistic] ADD CONSTRAINT [PK_STIS] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت آمار 
در حال پردازش و ایجاد آمار
ایجاد آمار به اتمام رسیده و آماده گزارش گیری میباشد', 'SCHEMA', N'dbo', 'TABLE', N'Statistic', 'COLUMN', N'STIS_STAT'
GO
