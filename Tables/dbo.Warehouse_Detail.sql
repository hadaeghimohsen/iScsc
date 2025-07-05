CREATE TABLE [dbo].[Warehouse_Detail]
(
[WRHS_CODE] [bigint] NULL,
[EXPN_CODE] [bigint] NULL,
[FIGH_FILE_NO] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RECD_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WEGH_CONT] [real] NULL,
[QNTY] [real] NULL,
[WEGH] [real] NULL,
[PRIC] [real] NULL,
[SECT_APBS_CODE] [bigint] NULL,
[UNIT_APBS_CODE] [bigint] NULL,
[UNIT_LVRG_VALU_DNRM] [real] NULL,
[SUM_EXPN_AMNT_DNRM] [real] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_WDTL]
   ON  [dbo].[Warehouse_Detail]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Warehouse_Detail T
   USING (SELECT * FROM Inserted) S
   ON (T.WRHS_CODE = S.WRHS_CODE AND 
       T.EXPN_CODE = S.EXPN_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.WEGH_CONT = ISNULL(s.WEGH_CONT, 0),
         T.QNTY = ISNULL(S.QNTY, 0),
         T.WEGH = ISNULL(S.WEGH, 0),
         T.PRIC = ISNULL(S.PRIC, 0);
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
CREATE TRIGGER [dbo].[CG$AUPD_WDTL]
   ON  [dbo].[Warehouse_Detail]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Warehouse_Detail T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE(),
         T.UNIT_LVRG_VALU_DNRM = dbo.GET_LVRU_U(s.UNIT_APBS_CODE),
         T.SUM_EXPN_AMNT_DNRM = s.PRIC * CASE WHEN s.WEGH != 0 THEN s.WEGH ELSE s.QNTY END;
END
GO
ALTER TABLE [dbo].[Warehouse_Detail] ADD CONSTRAINT [PK_WDTL] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Warehouse_Detail] ADD CONSTRAINT [FK_WDTL_EXPN] FOREIGN KEY ([EXPN_CODE]) REFERENCES [dbo].[Expense] ([CODE])
GO
ALTER TABLE [dbo].[Warehouse_Detail] ADD CONSTRAINT [FK_WDTL_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Warehouse_Detail] ADD CONSTRAINT [FK_WDTL_SECT_APBS] FOREIGN KEY ([SECT_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Warehouse_Detail] ADD CONSTRAINT [FK_WDTL_UNIT_APBS] FOREIGN KEY ([UNIT_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Warehouse_Detail] ADD CONSTRAINT [FK_WDTL_WRHS] FOREIGN KEY ([WRHS_CODE]) REFERENCES [dbo].[Warehouse] ([CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'فی خرید', 'SCHEMA', N'dbo', 'TABLE', N'Warehouse_Detail', 'COLUMN', N'PRIC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد', 'SCHEMA', N'dbo', 'TABLE', N'Warehouse_Detail', 'COLUMN', N'QNTY'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت ورود به انبار یا خروج از انبار', 'SCHEMA', N'dbo', 'TABLE', N'Warehouse_Detail', 'COLUMN', N'RECD_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وزن', 'SCHEMA', N'dbo', 'TABLE', N'Warehouse_Detail', 'COLUMN', N'WEGH'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وزن ظرف', 'SCHEMA', N'dbo', 'TABLE', N'Warehouse_Detail', 'COLUMN', N'WEGH_CONT'
GO
