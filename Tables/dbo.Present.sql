CREATE TABLE [dbo].[Present]
(
[PRID] [bigint] NOT NULL,
[MEET_MTID] [bigint] NULL,
[RWNO] [smallint] NULL CONSTRAINT [DF_Present_RWNO] DEFAULT ((0)),
[PRSN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FGPB_FIGH_FILE_NO] [bigint] NULL,
[FGPB_RWNO] [int] NULL,
[FGPB_RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INVT_BY] [bigint] NULL,
[FRST_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LAST_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FATH_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NATL_CODE] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SEX_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRSN_DESC] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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

CREATE TRIGGER [dbo].[CG$AINS_PRSN]
   ON [dbo].[Present]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Present T
   USING (SELECT * FROM INSERTED) S
   ON (T.MEET_MTID = S.MEET_MTID AND
       T.RWNO      = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Present WHERE MEET_MTID = S.MEET_MTID)
            ,PRID      = dbo.GNRT_NWID_U()
            ,FGPB_RWNO = CASE WHEN S.FGPB_FIGH_FILE_NO IS NOT NULL THEN (SELECT F.FGPB_RWNO_DNRM FROM Fighter F WHERE F.FILE_NO = S.FGPB_FIGH_FILE_NO) ELSE NULL END
            ,FGPB_RECT_CODE = CASE WHEN S.FGPB_FIGH_FILE_NO IS NOT NULL THEN '004' ELSE NULL END;
END
;

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CG$AUPD_PRSN]
   ON  [dbo].[Present]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Present T
   USING (SELECT * FROM INSERTED) S
   ON (T.MEET_MTID = S.MEET_MTID AND
       T.RWNO      = S.RWNO      AND
       T.PRID      = S.PRID)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
;

GO
ALTER TABLE [dbo].[Present] ADD CONSTRAINT [PK_PRSN] PRIMARY KEY CLUSTERED  ([PRID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Present] ADD CONSTRAINT [FK_PRSN_FGPB] FOREIGN KEY ([FGPB_FIGH_FILE_NO], [FGPB_RWNO], [FGPB_RECT_CODE]) REFERENCES [dbo].[Fighter_Public] ([FIGH_FILE_NO], [RWNO], [RECT_CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Present] ADD CONSTRAINT [FK_PRSN_MEET] FOREIGN KEY ([MEET_MTID]) REFERENCES [dbo].[Meeting] ([MTID]) ON DELETE CASCADE
GO
