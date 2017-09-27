CREATE TABLE [dbo].[Organ]
(
[CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ORGN_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_ORGN]
   ON  [dbo].[Organ]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Organ T
   USING (SELECT * FROM INSERTED i) S
   ON (T.Code      = S.Code)
   WHEN MATCHED THEN
      UPDATE 
      SET CRET_BY   = UPPER(SUSER_NAME())
         ,CRET_DATE = GETDATE();

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
CREATE TRIGGER [dbo].[CG$AUPD_ORGN]
   ON  [dbo].[Organ]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Organ T
   USING (SELECT * FROM INSERTED i) S
   ON (T.Code      = S.Code)
   WHEN MATCHED THEN
      UPDATE 
      SET MDFY_BY   = UPPER(SUSER_NAME())
         ,MDFY_DATE = GETDATE();

END
GO
ALTER TABLE [dbo].[Organ] ADD CONSTRAINT [PK_ORGN] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
