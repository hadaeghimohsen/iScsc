CREATE TABLE [dbo].[Warehouse_Expense]
(
[WRHS_CODE] [bigint] NULL,
[EXPN_CODE] [bigint] NULL,
[RECD_APBS_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[AMNT] [real] NULL,
[AMNT_DATE] [datetime] NULL,
[CMNT] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_WEXP]
   ON  [dbo].[Warehouse_Expense]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Warehouse_Expense T
   USING (SELECT * FROM Inserted) S
   ON (t.WRHS_CODE = s.WRHS_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.code WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.AMNT_DATE = GETDATE();
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
CREATE TRIGGER [dbo].[CG$AUPD_WEXP]
   ON  [dbo].[Warehouse_Expense]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Warehouse_Expense T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();         
END
GO
ALTER TABLE [dbo].[Warehouse_Expense] ADD CONSTRAINT [PK_Warehouse_Expense] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Warehouse_Expense] ADD CONSTRAINT [FK_WEXP_EXPN] FOREIGN KEY ([EXPN_CODE]) REFERENCES [dbo].[Expense] ([CODE])
GO
ALTER TABLE [dbo].[Warehouse_Expense] ADD CONSTRAINT [FK_WEXP_RECD_APBS] FOREIGN KEY ([RECD_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Warehouse_Expense] ADD CONSTRAINT [FK_WEXP_WRHS] FOREIGN KEY ([WRHS_CODE]) REFERENCES [dbo].[Warehouse] ([CODE]) ON DELETE CASCADE
GO
