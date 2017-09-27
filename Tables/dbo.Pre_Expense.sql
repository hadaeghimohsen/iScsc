CREATE TABLE [dbo].[Pre_Expense]
(
[EXPN_CODE] [bigint] NULL,
[PRE_EXPN_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QNTY] [int] NULL,
[FREE_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_PEXP]
   ON  [dbo].[Pre_Expense]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Pre_Expense T
   USING (SELECT * FROM INSERTED) S
   ON (T.EXPN_CODE = S.EXPN_CODE AND 
       T.PRE_EXPN_CODE = S.PRE_EXPN_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE = dbo.GNRT_NVID_U()
            ,STAT = ISNULL(S.STAT, '002')
            ,QNTY = ISNULL(S.QNTY, 1)
            ,FREE_STAT = ISNULL(S.FREE_STAT, '001');
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_PEXP]
   ON  [dbo].[Pre_Expense]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Pre_Expense T
   USING (SELECT * FROM INSERTED) S
   ON (T.EXPN_CODE = S.EXPN_CODE AND 
       T.PRE_EXPN_CODE = S.PRE_EXPN_CODE AND
       T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
;
GO
ALTER TABLE [dbo].[Pre_Expense] ADD CONSTRAINT [PK_Pre_Expense] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Pre_Expense] ADD CONSTRAINT [FK_PEXP_EXPN] FOREIGN KEY ([EXPN_CODE]) REFERENCES [dbo].[Expense] ([CODE])
GO
ALTER TABLE [dbo].[Pre_Expense] ADD CONSTRAINT [FK_PPEX_EXPN] FOREIGN KEY ([PRE_EXPN_CODE]) REFERENCES [dbo].[Expense] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'آیا هزینه رایگان می باشد', 'SCHEMA', N'dbo', 'TABLE', N'Pre_Expense', 'COLUMN', N'FREE_STAT'
GO
