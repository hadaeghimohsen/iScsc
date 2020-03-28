CREATE TABLE [dbo].[Group_Expense]
(
[GEXP_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[GROP_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR] [smallint] NULL,
[GROP_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_GEXP]
   ON  [dbo].[Group_Expense]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Group_Expense T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE   = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE      = DBO.GNRT_NVID_U();
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_GEXP]
   ON  [dbo].[Group_Expense]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Group_Expense T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE   = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
;
GO
ALTER TABLE [dbo].[Group_Expense] ADD CONSTRAINT [PK_GEXP] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Group_Expense] ADD CONSTRAINT [FK_GEXP_GEXP] FOREIGN KEY ([GEXP_CODE]) REFERENCES [dbo].[Group_Expense] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'مشخص کردن گروه کالا و برند کالا', 'SCHEMA', N'dbo', 'TABLE', N'Group_Expense', 'COLUMN', N'GROP_TYPE'
GO
