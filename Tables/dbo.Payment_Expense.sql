CREATE TABLE [dbo].[Payment_Expense]
(
[PYDT_CODE] [bigint] NULL,
[MSEX_CODE] [bigint] NULL,
[COCH_FILE_NO] [bigint] NULL,
[CODE] [bigint] NOT NULL CONSTRAINT [DF_Payment_Expense_CODE] DEFAULT ((0)),
[VALD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPN_AMNT] [bigint] NULL,
[EXPN_PRIC] [bigint] NULL,
[PRCT_VALU] [smallint] NULL,
[DECR_PRCT_VALU] [float] NULL,
[DECR_AMNT_DNRM] [bigint] NULL,
[RCPT_PRIC] [bigint] NULL,
[DSCN_PRIC] [bigint] NULL,
[CONF_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CONF_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQTP_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MTOD_CODE] [bigint] NULL,
[CTGY_CODE] [bigint] NULL,
[CLUB_CODE] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_PMEX]
   ON  [dbo].[Payment_Expense]
   AFTER INSERT
AS 
BEGIN
	MERGE Payment_Expense T
	USING (SELECT * FROM INSERTED) S
	ON (T.Pydt_Code = S.Pydt_Code AND
	    T.Code      = S.Code)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE      = dbo.Gnrt_Nvid_U();
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
CREATE TRIGGER [dbo].[CG$AUPD_PMEX]
   ON  [dbo].[Payment_Expense]
   AFTER UPDATE
AS 
BEGIN
	MERGE Payment_Expense T
	USING (SELECT * FROM INSERTED) S
	ON (T.Pydt_Code = S.Pydt_Code AND
	    T.Code      = S.Code)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Payment_Expense] ADD CONSTRAINT [PK_PMEX] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Payment_Expense] ADD CONSTRAINT [FK_PMEX_CLUB] FOREIGN KEY ([CLUB_CODE]) REFERENCES [dbo].[Club] ([CODE])
GO
ALTER TABLE [dbo].[Payment_Expense] ADD CONSTRAINT [FK_PMEX_CTGY] FOREIGN KEY ([CTGY_CODE]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
ALTER TABLE [dbo].[Payment_Expense] ADD CONSTRAINT [FK_PMEX_FIGH] FOREIGN KEY ([COCH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Payment_Expense] ADD CONSTRAINT [FK_PMEX_MSEX] FOREIGN KEY ([MSEX_CODE]) REFERENCES [dbo].[Misc_Expense] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Payment_Expense] ADD CONSTRAINT [FK_PMEX_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE])
GO
ALTER TABLE [dbo].[Payment_Expense] ADD CONSTRAINT [FK_PMEX_PYDT] FOREIGN KEY ([PYDT_CODE]) REFERENCES [dbo].[Payment_Detail] ([CODE])
GO
ALTER TABLE [dbo].[Payment_Expense] ADD CONSTRAINT [FK_PMEX_RQTP] FOREIGN KEY ([RQTP_CODE]) REFERENCES [dbo].[Request_Type] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'شرح تاییدیه یا تایید نشده', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Expense', 'COLUMN', N'CONF_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت مبلغ محاسبه شده
* اگر هنرجو از کلاس استفاده کرده باشد و هزینه را کامل پرداخت کرده باشد بدون هیچ مشکلی هزینه به مربی پرداخت میشود.
* اگر هنرجو پرداخت انجام داده باشد ولی هیچ کلاسی در باشگاه حضور نداشته باشد هزینه مربی با وضعیت خاصی نمایش داده میشود که مدیر تصمیم گیرنده هست.
* اگر هنرجو مبلغی از کلاس خود را پرداخت کرده باشد و از کلاس ها استفاده کرده باشد و بدهی خود را بعد از اتمام دوره تکمیل نکرده باشد باید محاسبه هزینه مربی با وضعیت خاصی مشخص شده باشد.', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Expense', 'COLUMN', N'CONF_STAT'
GO
