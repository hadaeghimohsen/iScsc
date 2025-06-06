CREATE TABLE [dbo].[Image_Document]
(
[RCDC_RCID] [bigint] NOT NULL,
[RWNO] [smallint] NOT NULL CONSTRAINT [DF_IMAG_RWNO] DEFAULT ((0)),
[IMAG] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_NAME] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_STAT] [smallint] NULL,
[FILE_ID] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [BLOB] TEXTIMAGE_ON [BLOB]
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
CREATE TRIGGER [dbo].[CG$AINS_IMAG]
   ON  [dbo].[Image_Document]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Image_Document T
   USING (SELECT RCDC_RCID FROM INSERTED) S
   ON (T.RCDC_RCID = S.RCDC_RCID)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Image_Document WHERE RCDC_RCID = S.RCDC_RCID)
            ,MDFY_STAT = 0;
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
CREATE TRIGGER [dbo].[CG$AUPD_IMAG]
   ON  [dbo].[Image_Document]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Image_Document T
   USING (SELECT RCDC_RCID, RWNO, IMAG FROM INSERTED) S
   ON (T.RCDC_RCID = S.RCDC_RCID AND
       T.RWNO      = S.RWNO)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,IMAG = CASE S.IMAG WHEN '' THEN NULL ELSE S.IMAG END;
END
GO
ALTER TABLE [dbo].[Image_Document] ADD CONSTRAINT [IMAG_PK] PRIMARY KEY CLUSTERED  ([RCDC_RCID], [RWNO]) ON [BLOB]
GO
ALTER TABLE [dbo].[Image_Document] ADD CONSTRAINT [FK_IMAG_RCDC] FOREIGN KEY ([RCDC_RCID]) REFERENCES [dbo].[Receive_Document] ([RCID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'این گزینه برای شبکه های اجتماعی در نظر گرفته میشود', 'SCHEMA', N'dbo', 'TABLE', N'Image_Document', 'COLUMN', N'FILE_ID'
GO
