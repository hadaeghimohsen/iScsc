CREATE TABLE [dbo].[Payment_Check]
(
[PYMT_CASH_CODE] [bigint] NOT NULL,
[PYMT_RQST_RQID] [bigint] NOT NULL,
[RQRO_RQST_RQID] [bigint] NOT NULL,
[RQRO_RWNO] [smallint] NOT NULL,
[RWNO] [smallint] NOT NULL,
[AMNT] [bigint] NULL,
[CHEK_OWNR] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHEK_NO] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHEK_DATE] [date] NULL,
[BANK] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RCPT_DATE] [date] NULL,
[CHEK_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_PMTC]
   ON [dbo].[Payment_Check]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   --DECLARE @TotlRcptAmnt BIGINT;
   --DECLARE @TotlDebtAmnt BIGINT;
   --DECLARE @TotlRemnAmnt BIGINT;
   
   --SELECT @TotlRcptAmnt = 
   --       SUM(Amnt)
   --  FROM dbo.Payment_Check T
   -- WHERE EXISTS(
   --   SELECT *
   --     FROM INSERTED S
   --    WHERE S.PYMT_CASH_CODE = T.PYMT_CASH_CODE
   --      AND S.PYMT_RQST_RQID = T.PYMT_RQST_RQID
   --      AND T.RWNO           <> 0
   -- );
   
   --SELECT @TotlDebtAmnt =
   --       SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT
   --  FROM Payment T
   -- WHERE EXISTS(
   --   SELECT *
   --     FROM INSERTED S
   --    WHERE S.PYMT_CASH_CODE = T.CASH_CODE
   --      AND S.PYMT_RQST_RQID = T.RQST_RQID
   -- );
   
   --SELECT @TotlRemnAmnt = SUM(AMNT)
   --  FROM INSERTED S;
   
   --IF @TotlRemnAmnt + @TotlRcptAmnt > @TotlDebtAmnt
   --   RAISERROR(N'مبلغ بدهی هنرجو کمتر مبلغ وارد شده می باشد. لطفا مبلغ درست را وارد کنید.', 16, 1);
   
   --IF EXISTS(SELECT * FROM INSERTED WHERE AMNT IS NULL)
   --   RAISERROR(N'مبلغ بدهی هنرجو باید مبلغ قابل قبول و درستی باشد.', 16, 1);
   
   -- Insert statements for trigger here
   MERGE dbo.Payment_Check T
   USING (SELECT * FROM INSERTED) S
   ON (T.PYMT_CASH_CODE = S.PYMT_CASH_CODE AND
       T.PYMT_RQST_RQID = S.PYMT_RQST_RQID AND
       T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.RWNO           = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Payment_Check WHERE PYMT_CASH_CODE = S.PYMT_CASH_CODE AND PYMT_RQST_RQID = S.PYMT_RQST_RQID AND RQRO_RQST_RQID = S.RQRO_RQST_RQID AND RQRO_RWNO      = S.RQRO_RWNO);
            --,ACTN_DATE = COALESCE(S.Actn_Date, GETDATE());
   
   -- اگر مبلغ ذخیره شده صفر باشد   
   --DELETE Payment_Method
   -- WHERE EXISTS(
   --   SELECT *
   --     FROM INSERTED S
   --    WHERE S.PYMT_CASH_CODE = Payment_Method.PYMT_CASH_CODE
   --      AND S.PYMT_RQST_RQID = Payment_Method.PYMT_RQST_RQID
   --      AND S.RQRO_RQST_RQID = Payment_Method.RQRO_RQST_RQID
   --      AND S.RQRO_RWNO      = Payment_Method.RQRO_RWNO
   --      AND S.AMNT           = Payment_Method.AMNT
   --      AND Payment_Method.AMNT = 0
   -- )
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_PMTC]
   ON [dbo].[Payment_Check]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   --DECLARE @TotlRcptAmnt BIGINT;
   --DECLARE @TotlDebtAmnt BIGINT;
   --DECLARE @TotlRemnAmnt BIGINT;
   
   --SELECT @TotlRcptAmnt = 
   --       SUM(Amnt)
   --  FROM dbo.Payment_Check T
   -- WHERE EXISTS(
   --   SELECT *
   --     FROM INSERTED S
   --    WHERE S.PYMT_CASH_CODE = T.PYMT_CASH_CODE
   --      AND S.PYMT_RQST_RQID = T.PYMT_RQST_RQID
   --      AND T.RWNO           <> 0
   -- );
   
   --SELECT @TotlDebtAmnt =
   --       SUM_EXPN_PRIC + SUM_EXPN_EXTR_PRCT
   --  FROM Payment T
   -- WHERE EXISTS(
   --   SELECT *
   --     FROM INSERTED S
   --    WHERE S.PYMT_CASH_CODE = T.CASH_CODE
   --      AND S.PYMT_RQST_RQID = T.RQST_RQID
   -- );
   
   --SELECT @TotlRemnAmnt = SUM(AMNT)
   --  FROM INSERTED S;
   
   --IF @TotlRemnAmnt + @TotlRcptAmnt > @TotlDebtAmnt
   --   RAISERROR(N'مبلغ بدهی هنرجو کمتر مبلغ وارد شده می باشد. لطفا مبلغ درست را وارد کنید.', 16, 1);
   
   --IF EXISTS(SELECT * FROM INSERTED WHERE AMNT IS NULL)
   --   RAISERROR(N'مبلغ بدهی هنرجو باید مبلغ قابل قبول و درستی باشد.', 16, 1);
   
   -- Insert statements for trigger here
   MERGE dbo.Payment_Check T
   USING (SELECT * FROM INSERTED) S
   ON (T.PYMT_CASH_CODE = S.PYMT_CASH_CODE AND
       T.PYMT_RQST_RQID = S.PYMT_RQST_RQID AND
       T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.RWNO           = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
            --,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Payment_Check WHERE PYMT_CASH_CODE = S.PYMT_CASH_CODE AND PYMT_RQST_RQID = S.PYMT_RQST_RQID AND RQRO_RQST_RQID = S.RQRO_RQST_RQID AND RQRO_RWNO      = S.RQRO_RWNO);
            --,ACTN_DATE = COALESCE(S.Actn_Date, GETDATE());
   
   -- اگر مبلغ ذخیره شده صفر باشد   
   --DELETE Payment_Method
   -- WHERE EXISTS(
   --   SELECT *
   --     FROM INSERTED S
   --    WHERE S.PYMT_CASH_CODE = Payment_Method.PYMT_CASH_CODE
   --      AND S.PYMT_RQST_RQID = Payment_Method.PYMT_RQST_RQID
   --      AND S.RQRO_RQST_RQID = Payment_Method.RQRO_RQST_RQID
   --      AND S.RQRO_RWNO      = Payment_Method.RQRO_RWNO
   --      AND S.AMNT           = Payment_Method.AMNT
   --      AND Payment_Method.AMNT = 0
   -- )
END
;
GO
ALTER TABLE [dbo].[Payment_Check] ADD CONSTRAINT [PK_PMTC] PRIMARY KEY CLUSTERED  ([PYMT_CASH_CODE], [PYMT_RQST_RQID], [RQRO_RQST_RQID], [RQRO_RWNO], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Payment_Check] ADD CONSTRAINT [FK_PMTC_PYMT] FOREIGN KEY ([PYMT_CASH_CODE], [PYMT_RQST_RQID]) REFERENCES [dbo].[Payment] ([CASH_CODE], [RQST_RQID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Payment_Check] ADD CONSTRAINT [FK_PMTC_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO])
GO
