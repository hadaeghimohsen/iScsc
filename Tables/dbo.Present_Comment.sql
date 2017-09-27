CREATE TABLE [dbo].[Present_Comment]
(
[PCID] [bigint] NOT NULL,
[PRSN_PRID] [bigint] NULL,
[RWNO] [smallint] NULL CONSTRAINT [DF_Present_Comment_RWNO] DEFAULT ((0)),
[CMNT] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_PRCM]
   ON [dbo].[Present_Comment]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Present_Comment T
   USING (SELECT PRSN_PRID, RWNO FROM INSERTED) S
   ON (T.PRSN_PRID = S.PRSN_PRID AND
       T.RWNO      = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Present_Comment WHERE PRSN_PRID = S.PRSN_PRID)
            ,PCID      = dbo.GNRT_NWID_U();
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_PRCM]
   ON  [dbo].[Present_Comment]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Present_Comment T
   USING (SELECT PCID, PRSN_PRID, RWNO FROM INSERTED) S
   ON (T.PRSN_PRID = S.PRSN_PRID AND
       T.RWNO      = S.RWNO      AND
       T.PCID      = S.PCID)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
;
GO
ALTER TABLE [dbo].[Present_Comment] ADD CONSTRAINT [PK_PRCM] PRIMARY KEY CLUSTERED  ([PCID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Present_Comment] ADD CONSTRAINT [FK_PRCM_PRSN] FOREIGN KEY ([PRSN_PRID]) REFERENCES [dbo].[Present] ([PRID]) ON DELETE CASCADE
GO
