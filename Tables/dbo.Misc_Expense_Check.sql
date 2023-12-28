CREATE TABLE [dbo].[Misc_Expense_Check]
(
[MSEX_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[AMNT] [decimal] (18, 2) NULL,
[CHEK_OWNR] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHEK_NO] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHEK_DATE] [date] NULL,
[BANK] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RCPT_DATE] [date] NULL,
[CHEK_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_MSCK]
   ON  [dbo].[Misc_Expense_Check]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   DECLARE @SumChckAmnt REAL,
           @SumPymtAmnt REAL;
           
   SELECT @SumChckAmnt = SUM(mec.AMNT)
     FROM dbo.Misc_Expense ms, dbo.Misc_Expense_Check mec, Deleted i
    WHERE ms.CODE = mec.MSEX_CODE
      AND mec.MSEX_CODE = i.MSEX_CODE
      AND mec.CHEK_TYPE = '002';
   
   SELECT @SumPymtAmnt = SUM(mem.AMNT)
     FROM dbo.Misc_Expense ms, dbo.Misc_Expense_Method mem, Deleted i
    WHERE ms.CODE = mem.MSEX_CODE
      AND mem.MSEX_CODE = i.MSEX_CODE;
   
   UPDATE ms
      SET ms.SUM_RCPT_PYMT_DNRM = ISNULL(@SumChckAmnt, 0) + ISNULL(@SumPymtAmnt, 0)
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
CREATE TRIGGER [dbo].[CG$AINS_MSCK]
   ON  [dbo].[Misc_Expense_Check]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Misc_Expense_Check T
   USING (SELECT * FROM Inserted) S
   ON (T.MSEX_CODE = S.MSEX_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.CHEK_TYPE = ISNULL(S.CHEK_TYPE, '001');
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
CREATE TRIGGER [dbo].[CG$AUPD_MSCK]
   ON  [dbo].[Misc_Expense_Check]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Misc_Expense_Check T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
   
   DECLARE @SumChckAmnt REAL,
           @SumPymtAmnt REAL;
           
   SELECT @SumChckAmnt = SUM(mec.AMNT)
     FROM dbo.Misc_Expense ms, dbo.Misc_Expense_Check mec, Inserted i
    WHERE ms.CODE = mec.MSEX_CODE
      AND mec.MSEX_CODE = i.MSEX_CODE
      AND mec.CHEK_TYPE = '002';
   
   SELECT @SumPymtAmnt = SUM(mem.AMNT)
     FROM dbo.Misc_Expense ms, dbo.Misc_Expense_Method mem, Inserted i
    WHERE ms.CODE = mem.MSEX_CODE
      AND mem.MSEX_CODE = i.MSEX_CODE;
   
   UPDATE ms
      SET ms.SUM_RCPT_PYMT_DNRM = ISNULL(@SumChckAmnt, 0) + ISNULL(@SumPymtAmnt, 0)
     FROM dbo.Misc_Expense ms, Inserted i
    WHERE ms.CODE = i.MSEX_CODE;
END
GO
ALTER TABLE [dbo].[Misc_Expense_Check] ADD CONSTRAINT [PK_Misc_Expense_Check] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Misc_Expense_Check] ADD CONSTRAINT [FK_MSCK_MSEX] FOREIGN KEY ([MSEX_CODE]) REFERENCES [dbo].[Misc_Expense] ([CODE]) ON DELETE CASCADE
GO
