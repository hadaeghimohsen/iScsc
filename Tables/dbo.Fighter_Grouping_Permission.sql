CREATE TABLE [dbo].[Fighter_Grouping_Permission]
(
[FGRP_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[PERM_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PERM_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CMNT] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[CRET_HOST_BY] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[MDFY_HOST_BY] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
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
CREATE TRIGGER [dbo].[CG$AINS_FGPR]
   ON  [dbo].[Fighter_Grouping_Permission]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Fighter_Grouping_Permission T
   USING (SELECT * FROM Inserted) S
   ON (T.FGRP_CODE = S.FGRP_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CRET_HOST_BY = dbo.GET_HOST_U(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.PERM_STAT = ISNULL(s.PERM_STAT, '002');
   
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
CREATE TRIGGER [dbo].[CG$AUPD_FGPR]
   ON  [dbo].[Fighter_Grouping_Permission]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;  
   
   -- Insert statements for trigger here
   MERGE dbo.Fighter_Grouping_Permission T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE(),
         T.MDFY_HOST_BY = dbo.GET_HOST_U();   
END
GO
ALTER TABLE [dbo].[Fighter_Grouping_Permission] ADD CONSTRAINT [PK_FGPR] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Fighter_Grouping_Permission] ADD CONSTRAINT [FK_FGPR_FGRP] FOREIGN KEY ([FGRP_CODE]) REFERENCES [dbo].[Fighter_Grouping] ([CODE]) ON DELETE CASCADE
GO
