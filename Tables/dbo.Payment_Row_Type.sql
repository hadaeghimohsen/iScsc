CREATE TABLE [dbo].[Payment_Row_Type]
(
[APDT_AGOP_CODE] [bigint] NULL,
[APDT_RWNO] [int] NULL,
[AMNT_TYPE_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[AMNT] [bigint] NULL,
[RCPT_MTOD] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TERM_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TRAN_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CARD_NO] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BANK] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FLOW_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REF_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACTN_DATE] [datetime] NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_PYRT]
   ON  [dbo].[Payment_Row_Type]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   -- 1400/05/24 * پر کردن مبلغ دینرمال کارت خوان
	UPDATE a
	   SET a.POS_AMNT = (SELECT ISNULL(SUM(p.AMNT), 0) FROM dbo.Payment_Row_Type p, Deleted i WHERE p.APDT_AGOP_CODE = i.APDT_AGOP_CODE AND p.APDT_RWNO = i.APDT_RWNO AND p.RCPT_MTOD = '003')
	  FROM dbo.Aggregation_Operation_Detail a, Deleted i
	 WHERE a.AGOP_CODE = i.APDT_AGOP_CODE
	   AND a.RWNO = i.APDT_RWNO;
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
CREATE TRIGGER [dbo].[CG$AINS_PYRT]
   ON  [dbo].[Payment_Row_Type]
   AFTER INSERT
AS 
BEGIN
	MERGE dbo.Payment_Row_Type T
	USING (SELECT * FROM INSERTED) S
	ON (T.APDT_AGOP_CODE = S.APDT_AGOP_CODE AND
	    ISNULL(T.APDT_RWNO, 0) = ISNULL(S.APDT_RWNO, 0) AND
	    T.CODE           = S.CODE)
	WHEN MATCHED THEN
	   UPDATE
	      SET CRET_BY = UPPER(SUSER_NAME())
	         ,CRET_DATE = GETDATE()
	         ,CODE = dbo.GNRT_NVID_U();
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
CREATE TRIGGER [dbo].[CG$AUPD_PYRT]
   ON  [dbo].[Payment_Row_Type]
   AFTER UPDATE
AS 
BEGIN
	MERGE dbo.Payment_Row_Type T
	USING (SELECT * FROM INSERTED) S
	ON (/*T.APDT_AGOP_CODE = S.APDT_AGOP_CODE AND
	    T.APDT_RWNO      = S.APDT_RWNO AND*/
	    T.CODE           = S.CODE)
	WHEN MATCHED THEN
	   UPDATE
	      SET MDFY_BY = UPPER(SUSER_NAME())
	         ,MDFY_DATE = GETDATE()
	         ,ACTN_DATE = ISNULL(S.ACTN_DATE, GETDATE())
	         ,RCPT_MTOD = ISNULL(S.RCPT_MTOD, '003');
	
	--IF ( 
	--   SELECT SUM(T.AMNT)
	--     FROM dbo.Payment_Row_Type T, INSERTED S
	--    WHERE T.APDT_AGOP_CODE = S.APDT_AGOP_CODE 
	--      AND T.APDT_RWNO      = S.APDT_RWNO 
	--      AND T.RCPT_MTOD NOT IN ('006', '005')
	--) > (
	--   SELECT ISNULL(T.TOTL_AMNT_DNRM, 0)
	--     FROM dbo.Aggregation_Operation_Detail T, INSERTED S
	--    WHERE T.AGOP_CODE = S.APDT_AGOP_CODE 
	--      AND T.RWNO      = S.APDT_RWNO 
	--)
	--BEGIN
	--   RAISERROR (N'مبلغ دریافتی بیش از حد هزینه اعلام شده می باشد', 16, 1);
	--END
	
	-- 1397/01/20 * پر کردن مبلغ دینرمال کارت خوان
	UPDATE a
	   SET a.POS_AMNT = (SELECT ISNULL(SUM(p.AMNT), 0) FROM dbo.Payment_Row_Type p, Inserted i WHERE p.APDT_AGOP_CODE = i.APDT_AGOP_CODE AND p.APDT_RWNO = i.APDT_RWNO AND p.RCPT_MTOD = '003')
	  FROM dbo.Aggregation_Operation_Detail a, Inserted i
	 WHERE a.AGOP_CODE = i.APDT_AGOP_CODE
	   AND a.RWNO = i.APDT_RWNO;
	   
END
GO
ALTER TABLE [dbo].[Payment_Row_Type] ADD CONSTRAINT [PK_PYRT] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Payment_Row_Type] ADD CONSTRAINT [FK_PYRT_APBS] FOREIGN KEY ([AMNT_TYPE_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Payment_Row_Type] ADD CONSTRAINT [FK_PYRT_APDT] FOREIGN KEY ([APDT_AGOP_CODE], [APDT_RWNO]) REFERENCES [dbo].[Aggregation_Operation_Detail] ([AGOP_CODE], [RWNO]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع مبلغ ورودی / خروجی', 'SCHEMA', N'dbo', 'TABLE', N'Payment_Row_Type', 'COLUMN', N'AMNT_TYPE_CODE'
GO
