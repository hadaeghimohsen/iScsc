CREATE TABLE [dbo].[Sub_Unit]
(
[BUNT_DEPT_ORGN_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BUNT_DEPT_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BUNT_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CODE] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SUNT_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PENT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SUNT]
   ON  [dbo].[Sub_Unit]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Sub_Unit T
   USING (SELECT * FROM INSERTED i) S
   ON (T.Code      = S.Code AND
       T.Bunt_Code = S.Bunt_Code AND
       T.BUNT_Dept_Code = S.BUNT_Dept_Code AND
       T.Bunt_Dept_Orgn_Code = S.Bunt_Dept_Orgn_Code)
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
CREATE TRIGGER [dbo].[CG$AUPD_SUNT]
   ON  [dbo].[Sub_Unit]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Sub_Unit T
   USING (SELECT * FROM INSERTED i) S
   ON (T.Code      = S.Code AND
       T.Bunt_Code = S.Bunt_Code AND
       T.BUNT_Dept_Code = S.BUNT_Dept_Code AND
       T.Bunt_Dept_Orgn_Code = S.Bunt_Dept_Orgn_Code)
   WHEN MATCHED THEN
      UPDATE 
      SET MDFY_BY   = UPPER(SUSER_NAME())
         ,MDFY_DATE = GETDATE();

END
GO
ALTER TABLE [dbo].[Sub_Unit] ADD CONSTRAINT [PK_SUNT] PRIMARY KEY CLUSTERED  ([BUNT_DEPT_ORGN_CODE], [BUNT_DEPT_CODE], [BUNT_CODE], [CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Sub_Unit] ADD CONSTRAINT [FK_SUNT_BUNT] FOREIGN KEY ([BUNT_DEPT_ORGN_CODE], [BUNT_DEPT_CODE], [BUNT_CODE]) REFERENCES [dbo].[Base_Unit] ([DEPT_ORGN_CODE], [DEPT_CODE], [CODE]) ON DELETE CASCADE
GO
