CREATE TABLE [dbo].[Misc_Expense_Discount]
(
[MSEX_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[AMNT] [decimal] (18, 2) NULL,
[DSCT_APBS_CODE] [bigint] NULL,
[DSCT_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_MSDS]
   ON  [dbo].[Misc_Expense_Discount]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   DECLARE @SumDsctAmnt REAL;
   SELECT @SumDsctAmnt = SUM(med.AMNT)
     FROM dbo.Misc_Expense ms, dbo.Misc_Expense_Discount med, Deleted i
    WHERE ms.CODE = med.MSEX_CODE
      AND med.MSEX_CODE = i.MSEX_CODE;
   
   UPDATE ms
      SET ms.SUM_DSCT_AMNT_DNRM = ISNULL(@SumDsctAmnt, 0)
     FROM dbo.Misc_Expense ms, Deleted i
    WHERE ms.CODE = i.MSEX_CODE;
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
CREATE TRIGGER [dbo].[CG$AINS_MSDS]
   ON  [dbo].[Misc_Expense_Discount]
   AFTER INSERT   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Misc_Expense_Discount T
   USING (SELECT * FROM Inserted) S
   ON (t.MSEX_CODE = s.MSEX_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
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
CREATE TRIGGER [dbo].[CG$AUPD_MSDS]
   ON  [dbo].[Misc_Expense_Discount]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Misc_Expense_Discount T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
   
   
   DECLARE @SumDsctAmnt REAL;
   SELECT @SumDsctAmnt = SUM(med.AMNT)
     FROM dbo.Misc_Expense ms, dbo.Misc_Expense_Discount med, Inserted i
    WHERE ms.CODE = med.MSEX_CODE
      AND med.MSEX_CODE = i.MSEX_CODE;
   
   UPDATE ms
      SET ms.SUM_DSCT_AMNT_DNRM = ISNULL(@SumDsctAmnt, 0)
     FROM dbo.Misc_Expense ms, Inserted i
    WHERE ms.CODE = i.MSEX_CODE;
END
GO
ALTER TABLE [dbo].[Misc_Expense_Discount] ADD CONSTRAINT [PK_Misc_Expense_Discount] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Misc_Expense_Discount] ADD CONSTRAINT [FK_MSDS_DSCT_APBS] FOREIGN KEY ([DSCT_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Misc_Expense_Discount] ADD CONSTRAINT [FK_MSDS_MSEX] FOREIGN KEY ([MSEX_CODE]) REFERENCES [dbo].[Misc_Expense] ([CODE]) ON DELETE CASCADE
GO
