CREATE TABLE [dbo].[Calculate_Expense_Coach]
(
[CODE] [bigint] NOT NULL CONSTRAINT [DF_Calculate_Expense_Coach_CODE] DEFAULT ((0)),
[COCH_FILE_NO] [bigint] NULL,
[EPIT_CODE] [bigint] NULL,
[RQTP_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQTT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COCH_DEG] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXTP_CODE] [bigint] NULL,
[MTOD_CODE] [bigint] NULL,
[CTGY_CODE] [bigint] NULL,
[CALC_EXPN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CALC_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRCT_VALU] [float] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PYMT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MIN_NUMB_ATTN] [smallint] NULL,
[MIN_ATTN_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RDUC_AMNT] [bigint] NULL,
[CBMT_CODE] [bigint] NULL,
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
   ON (T.Code         = S.Code /*AND
       T.Coch_File_No = S.Coch_File_No AND
       T.Epit_Code    = S.Epit_Code AND
       T.Rqtt_Code    = S.Rqtt_Code AND 
       T.RQTP_CODE    = S.RQTP_CODE AND
       T.MTOD_CODE    = S.MTOD_CODE AND
       T.CTGY_CODE    = S.CTGY_CODE AND 
       t.COCH_DEG     = s.COCH_DEG*/)
   WHEN MATCHED THEN
      UPDATE 
      SET CRET_BY   = UPPER(SUSER_NAME())
         ,CRET_DATE = GETDATE()
         ,CODE      = CASE s.CODE WHEN 0 THEN dbo.Gnrt_nvid_U() ELSE s.CODE END;
         
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
ALTER TABLE [dbo].[Calculate_Expense_Coach] ADD CONSTRAINT [FK_CEXC_CBMT] FOREIGN KEY ([CBMT_CODE]) REFERENCES [dbo].[Club_Method] ([CODE])
GO
ALTER TABLE [dbo].[Calculate_Expense_Coach] ADD CONSTRAINT [FK_CEXC_CTGY] FOREIGN KEY ([CTGY_CODE]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
ALTER TABLE [dbo].[Calculate_Expense_Coach] ADD CONSTRAINT [FK_CEXC_EPIT] FOREIGN KEY ([EPIT_CODE]) REFERENCES [dbo].[Expense_Item] ([CODE])
GO
ALTER TABLE [dbo].[Calculate_Expense_Coach] ADD CONSTRAINT [FK_CEXC_EXTP] FOREIGN KEY ([EXTP_CODE]) REFERENCES [dbo].[Expense_Type] ([CODE])
GO
ALTER TABLE [dbo].[Calculate_Expense_Coach] ADD CONSTRAINT [FK_CEXC_FIGH] FOREIGN KEY ([COCH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Calculate_Expense_Coach] ADD CONSTRAINT [FK_CEXC_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE])
GO
ALTER TABLE [dbo].[Calculate_Expense_Coach] ADD CONSTRAINT [FK_CEXC_RQTP] FOREIGN KEY ([RQTP_CODE]) REFERENCES [dbo].[Request_Type] ([CODE])
GO
ALTER TABLE [dbo].[Calculate_Expense_Coach] ADD CONSTRAINT [FK_CEXC_RQTT] FOREIGN KEY ([RQTT_CODE]) REFERENCES [dbo].[Requester_Type] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ دوره مورد نظر می باشد یا تعداد جلسات دوره ای که با مربی گذشته', 'SCHEMA', N'dbo', 'TABLE', N'Calculate_Expense_Coach', 'COLUMN', N'CALC_EXPN_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع محاسبه هزینه (مبلغی یا درصدی)', 'SCHEMA', N'dbo', 'TABLE', N'Calculate_Expense_Coach', 'COLUMN', N'CALC_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مشخص کردن سانس کلاسی', 'SCHEMA', N'dbo', 'TABLE', N'Calculate_Expense_Coach', 'COLUMN', N'CBMT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'رسته', 'SCHEMA', N'dbo', 'TABLE', N'Calculate_Expense_Coach', 'COLUMN', N'CTGY_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع آیتم درآمدی', 'SCHEMA', N'dbo', 'TABLE', N'Calculate_Expense_Coach', 'COLUMN', N'EXTP_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'سبک', 'SCHEMA', N'dbo', 'TABLE', N'Calculate_Expense_Coach', 'COLUMN', N'MTOD_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'درصد محاسبه', 'SCHEMA', N'dbo', 'TABLE', N'Calculate_Expense_Coach', 'COLUMN', N'PRCT_VALU'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ کاهش
این گزینه بیشتر برای برنامه های خصوصی می باشد که بخواهیم با مربی حساب کنیم این گزینه ابتدا میگیم که مبلغ شهریه باشگاه کسر شود و بعد مبلغ باقیمانده درصد آن را محاسبه میکنیم', 'SCHEMA', N'dbo', 'TABLE', N'Calculate_Expense_Coach', 'COLUMN', N'RDUC_AMNT'
GO
