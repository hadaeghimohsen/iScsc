CREATE TABLE [dbo].[Meeting]
(
[MTID] [bigint] NOT NULL,
[COMM_CMID] [bigint] NULL,
[RWNO] [smallint] NULL CONSTRAINT [DF_Meeting_RWNO] DEFAULT ((0)),
[ACTN_DATE] [datetime] NULL,
[MEET_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STRT_TIME] [time] NULL,
[END_TIME] [time] NULL,
[MEET_PLAC] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MEET_SUBJ] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_MEET]
   ON [dbo].[Meeting]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Meeting T
   USING (SELECT * FROM INSERTED) S
   ON (T.COMM_CMID = S.COMM_CMID AND
       T.RWNO      = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Meeting WHERE COMM_CMID = S.COMM_CMID)
            ,MTID      = dbo.GNRT_NVID_U();
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_MEET]
   ON  [dbo].[Meeting]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Meeting T
   USING (SELECT * FROM INSERTED) S
   ON (T.COMM_CMID = S.COMM_CMID AND
       T.RWNO      = S.RWNO      AND
       T.MTID      = S.MTID)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
;
GO
ALTER TABLE [dbo].[Meeting] ADD CONSTRAINT [PK_MEET] PRIMARY KEY CLUSTERED  ([MTID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Meeting] ADD CONSTRAINT [FK_MEET_COMM] FOREIGN KEY ([COMM_CMID]) REFERENCES [dbo].[Committee] ([CMID]) ON DELETE CASCADE
GO
