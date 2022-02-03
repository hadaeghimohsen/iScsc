CREATE TABLE [dbo].[Fighter_Grouping]
(
[FIGH_FILE_NO] [bigint] NULL,
[GROP_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[GROP_DESC] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GROP_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_FGRP]
   ON  [dbo].[Fighter_Grouping]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Fighter_Grouping T
   USING (SELECT * FROM Inserted) S
   ON (T.FIGH_FILE_NO = S.FIGH_FILE_NO AND 
       T.GROP_CODE = S.GROP_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.GROP_STAT = ISNULL(S.GROP_STAT, '002'),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;
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
CREATE TRIGGER [dbo].[CG$AUPD_FGRP]
   ON  [dbo].[Fighter_Grouping]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Fighter_Grouping T
   USING (SELECT * FROM Inserted) S
   ON (T.FIGH_FILE_NO = S.FIGH_FILE_NO AND 
       T.GROP_CODE = S.GROP_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Fighter_Grouping] ADD CONSTRAINT [PK_Fighter_Grouping] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Fighter_Grouping] ADD CONSTRAINT [FK_FGRP_APBS] FOREIGN KEY ([GROP_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Fighter_Grouping] ADD CONSTRAINT [FK_FGRP_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
