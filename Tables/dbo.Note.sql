CREATE TABLE [dbo].[Note]
(
[AGOP_CODE] [bigint] NULL,
[FIGH_FILE_NO] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RWNO] [int] NULL,
[NOTE_SUBJ] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NOTE_CMNT] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NOTE_DATE] [datetime] NULL,
[VIST_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_NOTE]
   ON  [dbo].[Note]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Note T
   USING (SELECT * FROM Inserted) S
   ON (ISNULL(T.FIGH_FILE_NO, 0) = ISNULL(S.FIGH_FILE_NO, 0) AND 
       ISNULL(t.AGOP_CODE, 0) = ISNULL(s.AGOP_CODE, 0) AND
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE 0 END,
         T.RWNO = (SELECT ISNULL(MAX(n.RWNO), 0) + 1 FROM dbo.Note n WHERE ISNULL(n.FIGH_FILE_NO, 0) = ISNULL(s.FIGH_FILE_NO, 1) OR ISNULL(n.AGOP_CODE, 0) = ISNULL(s.AGOP_CODE, 1)),
         T.NOTE_DATE = GETDATE(),
         T.VIST_STAT = ISNULL(S.VIST_STAT, '001');
         
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
CREATE TRIGGER [dbo].[CG$AUPD_NOTE]
   ON  [dbo].[Note]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Note T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();         
END
GO
ALTER TABLE [dbo].[Note] ADD CONSTRAINT [PK_NOTE] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Note] ADD CONSTRAINT [FK_NOTE_AGOP] FOREIGN KEY ([AGOP_CODE]) REFERENCES [dbo].[Aggregation_Operation] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Note] ADD CONSTRAINT [FK_NOTE_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
