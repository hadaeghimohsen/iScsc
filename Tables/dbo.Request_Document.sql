CREATE TABLE [dbo].[Request_Document]
(
[DCMT_DSID] [bigint] NULL,
[RQRQ_CODE] [bigint] NULL,
[RDID] [bigint] NOT NULL CONSTRAINT [DF_DCMT_RDID] DEFAULT ((0)),
[NEED_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_DCMT_NEED_TYPE] DEFAULT ('002'),
[ORIG_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_DCMT_ORIG_TYPE] DEFAULT ('002'),
[FRST_NEED] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_DCMT_FRST_NEED] DEFAULT ('001'),
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
CREATE TRIGGER [dbo].[CG$AINS_RQDC]
   ON  [dbo].[Request_Document]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Request_Document T
   USING (SELECT * FROM INSERTED) S
   ON (T.DCMT_DSID = S.DCMT_DSID AND
       T.RQRQ_CODE = S.RQRQ_CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,RDID      = DBO.GNRT_NVID_U();
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
CREATE TRIGGER [dbo].[CG$AUPD_RQDC]
   ON  [dbo].[Request_Document]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Request_Document T
   USING (SELECT * FROM INSERTED) S
   ON (T.DCMT_DSID = S.DCMT_DSID AND
       T.RQRQ_CODE = S.RQRQ_CODE AND 
       T.RDID      = S.RDID)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();            
END

GO
ALTER TABLE [dbo].[Request_Document] ADD CONSTRAINT [CK_DCMT_FRST_NEED] CHECK (([FRST_NEED]='002' OR [FRST_NEED]='001'))
GO
ALTER TABLE [dbo].[Request_Document] ADD CONSTRAINT [CK_DCMT_NEED_TYPE] CHECK (([NEED_TYPE]='002' OR [NEED_TYPE]='001'))
GO
ALTER TABLE [dbo].[Request_Document] ADD CONSTRAINT [CK_DCMT_ORIG_TYPE] CHECK (([ORIG_TYPE]='002' OR [ORIG_TYPE]='001'))
GO
ALTER TABLE [dbo].[Request_Document] ADD CONSTRAINT [DCMT_PK] PRIMARY KEY CLUSTERED  ([RDID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Request_Document] ADD CONSTRAINT [FK_RQDC_DCMT] FOREIGN KEY ([DCMT_DSID]) REFERENCES [dbo].[Document_Spec] ([DSID]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Request_Document] ADD CONSTRAINT [FK_RQDC_RQRQ] FOREIGN KEY ([RQRQ_CODE]) REFERENCES [dbo].[Request_Requester] ([CODE]) ON DELETE SET NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره مدرک', 'SCHEMA', N'dbo', 'TABLE', N'Request_Document', 'COLUMN', N'RDID'
GO
