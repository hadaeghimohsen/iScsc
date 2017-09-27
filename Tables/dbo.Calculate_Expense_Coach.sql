CREATE TABLE [dbo].[Calculate_Expense_Coach]
(
[COCH_FILE_NO] [bigint] NULL,
[EPIT_CODE] [bigint] NULL,
[RQTT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COCH_DEG] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CODE] [bigint] NOT NULL CONSTRAINT [DF_Calculate_Expense_Coach_CODE] DEFAULT ((0)),
[PRCT_VALU] [float] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_CSEX]
   ON  [dbo].[Calculate_Expense_Coach]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   
   MERGE dbo.Calculate_Expense_Coach T
   USING (SELECT * FROM INSERTED i) S
   ON (T.Code      = S.Code AND
       T.Coch_File_No = S.Coch_File_No AND
       T.Epit_Code    = S.Epit_Code AND
       T.Rqtt_Code    = S.Rqtt_Code)
   WHEN MATCHED THEN
      UPDATE 
      SET CRET_BY   = UPPER(SUSER_NAME())
         ,CRET_DATE = GETDATE()
         ,CODE      = dbo.Gnrt_nvid_U()
         ,STAT      = '002';
END;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_CSEX]
   ON  [dbo].[Calculate_Expense_Coach]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   
   MERGE dbo.Calculate_Expense_Coach T
   USING (SELECT * FROM INSERTED i) S
   ON (T.Code      = S.Code)
   WHEN MATCHED THEN
      UPDATE 
      SET MDFY_BY   = UPPER(SUSER_NAME())
         ,MDFY_DATE = GETDATE();
END;
GO
ALTER TABLE [dbo].[Calculate_Expense_Coach] ADD CONSTRAINT [PK_CEXC] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Calculate_Expense_Coach] ADD CONSTRAINT [FK_CEXC_EPIT] FOREIGN KEY ([EPIT_CODE]) REFERENCES [dbo].[Expense_Item] ([CODE])
GO
ALTER TABLE [dbo].[Calculate_Expense_Coach] ADD CONSTRAINT [FK_CEXC_FIGH] FOREIGN KEY ([COCH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Calculate_Expense_Coach] ADD CONSTRAINT [FK_CEXC_RQTT] FOREIGN KEY ([RQTT_CODE]) REFERENCES [dbo].[Requester_Type] ([CODE])
GO
