CREATE TABLE [dbo].[Expense_Type_Step]
(
[EXTP_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[NAME] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QNTY] [int] NULL,
[FROM_TIME] [datetime] NULL,
[TO_TIME] [datetime] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_EXTS]
   ON  [dbo].[Expense_Type_Step]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Expense_Type_Step T
   USING (SELECT * FROM Inserted) S
   ON (T.EXTP_CODE = s.EXTP_CODE AND 
       T.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.STAT = ISNULL(s.STAT, '002');
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
CREATE TRIGGER [dbo].[CG$AUPD_EXTS]
   ON  [dbo].[Expense_Type_Step]
   AFTER UPDATE   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Expense_Type_Step T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Expense_Type_Step] ADD CONSTRAINT [PK_EXTS] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Expense_Type_Step] ADD CONSTRAINT [FK_EXTS_EXTP] FOREIGN KEY ([EXTP_CODE]) REFERENCES [dbo].[Expense_Type] ([CODE]) ON DELETE CASCADE
GO
