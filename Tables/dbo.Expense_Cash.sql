CREATE TABLE [dbo].[Expense_Cash]
(
[REGN_PRVN_CNTY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_EXCS_REGN_PRVN_CNTY_CODE] DEFAULT ('001'),
[REGN_PRVN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_EXCS_REGN_PRVN_CODE] DEFAULT ('001'),
[REGN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[REGL_YEAR] [smallint] NOT NULL,
[REGL_CODE] [int] NOT NULL,
[EXTP_CODE] [bigint] NOT NULL,
[CASH_CODE] [bigint] NOT NULL,
[EXCS_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_EXCS_EXCS_STAT] DEFAULT ('002'),
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

CREATE TRIGGER [dbo].[CG$AINS_EXCS]
   ON [dbo].[Expense_Cash] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Expense_Cash T
   USING (SELECT * FROM INSERTED) S
   ON (T.REGL_YEAR = S.REGL_YEAR                     AND
       T.REGL_CODE = S.REGL_CODE                     AND
       T.EXTP_CODE = S.EXTP_CODE                     AND
       T.CASH_CODE = S.CASH_CODE                     AND
       T.REGN_CODE = S.REGN_CODE                     AND
       T.REGN_PRVN_CODE = S.REGN_PRVN_CODE           AND
       T.REGN_PRVN_CNTY_CODE = S.REGN_PRVN_CNTY_CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE();
END
;

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CG$AUPD_EXCS]
   ON [dbo].[Expense_Cash] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
  
   MERGE dbo.Expense_Cash T
   USING (SELECT * FROM INSERTED) S
   ON (T.REGL_YEAR = S.REGL_YEAR                     AND
       T.REGL_CODE = S.REGL_CODE                     AND
       T.EXTP_CODE = S.EXTP_CODE                     AND
       T.CASH_CODE = S.CASH_CODE                     AND
       T.REGN_CODE = S.REGN_CODE                     AND
       T.REGN_PRVN_CODE = S.REGN_PRVN_CODE           AND
       T.REGN_PRVN_CNTY_CODE = S.REGN_PRVN_CNTY_CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
;

GO
ALTER TABLE [dbo].[Expense_Cash] ADD CONSTRAINT [CK_EXCS_EXCS_STAT] CHECK (([EXCS_STAT]='002' OR [EXCS_STAT]='001'))
GO
ALTER TABLE [dbo].[Expense_Cash] ADD CONSTRAINT [PK_EXCS] PRIMARY KEY CLUSTERED  ([REGN_PRVN_CNTY_CODE], [REGN_PRVN_CODE], [REGN_CODE], [REGL_YEAR], [REGL_CODE], [EXTP_CODE], [CASH_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Expense_Cash] ADD CONSTRAINT [FK_EXCS_CASH] FOREIGN KEY ([CASH_CODE]) REFERENCES [dbo].[Cash] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Expense_Cash] ADD CONSTRAINT [FK_EXCS_EXTP] FOREIGN KEY ([EXTP_CODE]) REFERENCES [dbo].[Expense_Type] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Expense_Cash] ADD CONSTRAINT [FK_EXCS_REGL] FOREIGN KEY ([REGL_YEAR], [REGL_CODE]) REFERENCES [dbo].[Regulation] ([YEAR], [CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Expense_Cash] ADD CONSTRAINT [FK_EXCS_REGN] FOREIGN KEY ([REGN_PRVN_CNTY_CODE], [REGN_PRVN_CODE], [REGN_CODE]) REFERENCES [dbo].[Region] ([PRVN_CNTY_CODE], [PRVN_CODE], [CODE]) ON DELETE CASCADE
GO
