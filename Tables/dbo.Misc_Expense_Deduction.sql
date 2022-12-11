CREATE TABLE [dbo].[Misc_Expense_Deduction]
(
[PMTD_CODE] [bigint] NULL,
[MSEX_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[CRET_HOST_BY] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[MDFY_HOST_BY] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
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
CREATE TRIGGER [dbo].[CG$ADEL_MSED]
   ON  [dbo].[Misc_Expense_Deduction]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   UPDATE me
      SET me.SUM_DEDU_AMNT_DNRM =  ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm, dbo.Misc_Expense_Deduction md WHERE me.CODE = md.MSEX_CODE AND md.PMTD_CODE = pm.CODE), 0)
     FROM dbo.Misc_Expense me , Deleted d
    WHERE me.CODE = d.MSEX_CODE;
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
CREATE TRIGGER [dbo].[CG$AINS_MSED]
   ON  [dbo].[Misc_Expense_Deduction]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Misc_Expense_Deduction T
   USING (SELECT * FROM Inserted) S
   ON (T.PMTD_CODE = s.PMTD_CODE AND 
       T.MSEX_CODE = s.MSEX_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CRET_HOST_BY = dbo.GET_HOST_U(),
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
CREATE TRIGGER [dbo].[CG$AUPD_MSED]
   ON  [dbo].[Misc_Expense_Deduction]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Misc_Expense_Deduction T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE(),
         T.MDFY_HOST_BY = dbo.GET_HOST_U();
   
   UPDATE me
      SET me.SUM_DEDU_AMNT_DNRM = ISNULL((SELECT SUM(pm.AMNT) FROM dbo.Payment_Method pm, dbo.Misc_Expense_Deduction md WHERE me.CODE = md.MSEX_CODE AND md.PMTD_CODE = pm.CODE), 0)
     FROM dbo.Misc_Expense me , Inserted i
    WHERE me.CODE = i.MSEX_CODE;
END
GO
ALTER TABLE [dbo].[Misc_Expense_Deduction] ADD CONSTRAINT [PK_MSED] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Misc_Expense_Deduction] ADD CONSTRAINT [FK_MSED_MSEX] FOREIGN KEY ([MSEX_CODE]) REFERENCES [dbo].[Misc_Expense] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Misc_Expense_Deduction] ADD CONSTRAINT [FK_MSED_PMTD] FOREIGN KEY ([PMTD_CODE]) REFERENCES [dbo].[Payment_Method] ([CODE]) ON DELETE CASCADE
GO
