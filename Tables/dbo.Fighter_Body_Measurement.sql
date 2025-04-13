CREATE TABLE [dbo].[Fighter_Body_Measurement]
(
[FIGH_FILE_NO] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[BODY_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MESR_VALU] [real] NULL,
[CMNT] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [BLOB]
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
CREATE TRIGGER [dbo].[CG$AINS_FGBM]
   ON  [dbo].[Fighter_Body_Measurement]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Fighter_Body_Measurement T
   USING (SELECT * FROM Inserted) S
   ON (T.FIGH_FILE_NO = S.FIGH_FILE_NO AND 
       T.BODY_TYPE = S.BODY_TYPE AND
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.MESR_VALU = ISNULL(s.MESR_VALU, 0);
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
CREATE TRIGGER [dbo].[CG$AUPD_FGBM]
   ON  [dbo].[Fighter_Body_Measurement]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Fighter_Body_Measurement T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Fighter_Body_Measurement] ADD CONSTRAINT [PK_FGBM] PRIMARY KEY CLUSTERED  ([CODE]) ON [BLOB]
GO
ALTER TABLE [dbo].[Fighter_Body_Measurement] ADD CONSTRAINT [FK_FGBM_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
