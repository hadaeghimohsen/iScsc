CREATE TABLE [dbo].[Template]
(
[TMID] [bigint] NOT NULL IDENTITY(1, 1),
[TEMP_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TEMP_SECT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TEMP_SUBJ] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TEMP_TEXT] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHER_TEAM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TEMP_NAME] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[USER_NAME] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
create TRIGGER [dbo].[CG$AINS_TEMP]
   ON  [dbo].[Template]
   AFTER INSERT
AS 
BEGIN
	MERGE dbo.Template T
	USING (SELECT * FROM Inserted) S
	ON (T.TMID = S.TMID)
	WHEN MATCHED THEN
	   UPDATE SET
	      T.CRET_BY = UPPER(SUSER_NAME())
	     ,T.CRET_DATE = GETDATE();
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
create TRIGGER [dbo].[CG$AUPD_TEMP]
   ON  [dbo].[Template]
   AFTER UPDATE   
AS 
BEGIN
	MERGE dbo.Template T
	USING (SELECT * FROM Inserted) S
	ON (T.TMID = S.TMID)
	WHEN MATCHED THEN
	   UPDATE SET
	      T.MDFY_BY = UPPER(SUSER_NAME())
	     ,T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Template] ADD CONSTRAINT [PK_TMPL] PRIMARY KEY CLUSTERED  ([TMID]) ON [PRIMARY]
GO
