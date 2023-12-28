CREATE TABLE [dbo].[Payment_Contract_Detail]
(
[PMCT_CODE] [bigint] NULL,
[GROP_ITEM_APBS_CODE] [bigint] NULL,
[SUB_ITEM_APBS_CODE] [bigint] NULL,
[FLPC_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[ITEM_VALU] [real] NULL,
[ITEM_CODE_APBS_CODE] [bigint] NULL,
[ITEM_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_PCTD]
   ON  [dbo].[Payment_Contract_Detail]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Payment_Contract_Detail T
   USING (SELECT * FROM Inserted) S
   ON (T.PMCT_CODE = s.PMCT_CODE AND 
       T.SUB_ITEM_APBS_CODE = s.SUB_ITEM_APBS_CODE AND
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
CREATE TRIGGER [dbo].[CG$AUPD_PCTD]
   ON  [dbo].[Payment_Contract_Detail]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Payment_Contract_Detail T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Payment_Contract_Detail] ADD CONSTRAINT [PK_PCTD] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Payment_Contract_Detail] ADD CONSTRAINT [FK_PCTD_GROP_APBS] FOREIGN KEY ([GROP_ITEM_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Payment_Contract_Detail] ADD CONSTRAINT [FK_PCTD_ITEM_APBS] FOREIGN KEY ([ITEM_CODE_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Payment_Contract_Detail] ADD CONSTRAINT [FK_PCTD_PMCT] FOREIGN KEY ([PMCT_CODE]) REFERENCES [dbo].[Payment_Contract] ([CODE])
GO
ALTER TABLE [dbo].[Payment_Contract_Detail] ADD CONSTRAINT [FK_PCTD_SUM_APBS] FOREIGN KEY ([SUB_ITEM_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Payment_Contract_Detail] ADD CONSTRAINT [FK_PMCD_FLPC] FOREIGN KEY ([FLPC_CODE]) REFERENCES [dbo].[Fighter_Link_Payment_Contarct_Item] ([CODE])
GO
