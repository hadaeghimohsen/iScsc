CREATE TABLE [dbo].[Base_Unit]
(
[DEPT_ORGN_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DEPT_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BUNT_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_BUNT]
   ON  [dbo].[Base_Unit]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Base_Unit T
   USING (SELECT * FROM INSERTED i) S
   ON (T.Code      = S.Code AND
       T.Dept_Code = S.Dept_Code AND
       T.Dept_Orgn_Code = S.Dept_Orgn_Code)
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
CREATE TRIGGER [dbo].[CG$AUPD_BUNT]
   ON  [dbo].[Base_Unit]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Base_Unit T
   USING (SELECT * FROM INSERTED i) S
   ON (T.Code      = S.Code AND
       T.Dept_Code = S.Dept_Code AND
       T.Dept_Orgn_Code = S.Dept_Orgn_Code)
   WHEN MATCHED THEN
      UPDATE 
      SET MDFY_BY   = UPPER(SUSER_NAME())
         ,MDFY_DATE = GETDATE();

END
GO
ALTER TABLE [dbo].[Base_Unit] ADD CONSTRAINT [PK_BUNT] PRIMARY KEY CLUSTERED  ([DEPT_ORGN_CODE], [DEPT_CODE], [CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Base_Unit] WITH NOCHECK ADD CONSTRAINT [FK_BUNT_DEPT] FOREIGN KEY ([DEPT_ORGN_CODE], [DEPT_CODE]) REFERENCES [dbo].[Department] ([ORGN_CODE], [CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'شرح', 'SCHEMA', N'dbo', 'TABLE', N'Base_Unit', 'COLUMN', N'BUNT_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد', 'SCHEMA', N'dbo', 'TABLE', N'Base_Unit', 'COLUMN', N'CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد موسسه', 'SCHEMA', N'dbo', 'TABLE', N'Base_Unit', 'COLUMN', N'DEPT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد ارگان', 'SCHEMA', N'dbo', 'TABLE', N'Base_Unit', 'COLUMN', N'DEPT_ORGN_CODE'
GO
