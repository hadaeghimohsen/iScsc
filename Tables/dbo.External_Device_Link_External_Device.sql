CREATE TABLE [dbo].[External_Device_Link_External_Device]
(
[EDEV_CODE] [bigint] NULL,
[LINK_EDEV_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_EDLE]
   ON  [dbo].[External_Device_Link_External_Device]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.External_Device_Link_External_Device T
   USING (SELECT * FROM Inserted) S
   ON (T.EDEV_CODE = S.EDEV_CODE AND 
       T.LINK_EDEV_CODE = S.LINK_EDEV_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.STAT = ISNULL(S.STAT, '002');
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
CREATE TRIGGER [dbo].[CG$AUPD_EDLE]
   ON  [dbo].[External_Device_Link_External_Device]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.External_Device_Link_External_Device T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[External_Device_Link_External_Device] ADD CONSTRAINT [PK_EDLE] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[External_Device_Link_External_Device] ADD CONSTRAINT [FK_External_Device_Link_External_Device_External_Device] FOREIGN KEY ([EDEV_CODE]) REFERENCES [dbo].[External_Device] ([CODE])
GO
ALTER TABLE [dbo].[External_Device_Link_External_Device] ADD CONSTRAINT [FK_External_Device_Link_External_Device_External_Device1] FOREIGN KEY ([LINK_EDEV_CODE]) REFERENCES [dbo].[External_Device] ([CODE])
GO
