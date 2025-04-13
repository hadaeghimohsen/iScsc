CREATE TABLE [dbo].[Exception_Operation]
(
[FIGH_FILE_NO] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[EXCP_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_EXCP]
   ON  [dbo].[Exception_Operation]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Exception_Operation T
   USING (SELECT * FROM Inserted) S
   ON (T.FIGH_FILE_NO = S.FIGH_FILE_NO AND
       T.EXCP_TYPE = S.EXCP_TYPE)
   WHEN MATCHED THEN
      UPDATE 
         SET t.CRET_BY = UPPER(SUSER_NAME())
            ,t.CRET_DATE = GETDATE()
            ,t.CODE = CASE ISNULL(s.CODE, 0) WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;
         

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
CREATE TRIGGER [dbo].[CG$AUPD_EXCP]
   ON  [dbo].[Exception_Operation]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Exception_Operation T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET t.MDFY_BY = UPPER(SUSER_NAME())
            ,t.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Exception_Operation] ADD CONSTRAINT [PK_Exception_Operation] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Exception_Operation] ADD CONSTRAINT [FK_EXCP_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
