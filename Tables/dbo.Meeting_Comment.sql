CREATE TABLE [dbo].[Meeting_Comment]
(
[MCID] [bigint] NOT NULL,
[MEET_MTID] [bigint] NULL,
[RWNO] [smallint] NULL CONSTRAINT [DF_Meeting_Comment_RWNO] DEFAULT ((0)),
[CMNT] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RSPN_IMPL] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXP_DATE] [datetime] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_MTCM]
   ON [dbo].[Meeting_Comment]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   --SELECT * FROM inserted;
   
   -- Insert statements for trigger here
   MERGE dbo.Meeting_Comment T
   USING (SELECT MEET_MTID, RWNO FROM INSERTED) S
   ON (T.MEET_MTID = S.MEET_MTID AND
       T.RWNO      = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Meeting_Comment WHERE MEET_MTID = S.MEET_MTID)
            ,MCID      = dbo.GNRT_NVID_U();
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_MTCM]
   ON  [dbo].[Meeting_Comment]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- Insert statements for trigger here
   MERGE dbo.Meeting_Comment T
   USING (SELECT MCID, MEET_MTID, RWNO FROM INSERTED) S
   ON (T.MEET_MTID = S.MEET_MTID AND
       T.RWNO      = S.RWNO      AND
       T.MCID      = S.MCID)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
;
GO
ALTER TABLE [dbo].[Meeting_Comment] ADD CONSTRAINT [PK_MTCM] PRIMARY KEY CLUSTERED  ([MCID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Meeting_Comment] ADD CONSTRAINT [FK_MTCM_MEET] FOREIGN KEY ([MEET_MTID]) REFERENCES [dbo].[Meeting] ([MTID]) ON DELETE CASCADE
GO
