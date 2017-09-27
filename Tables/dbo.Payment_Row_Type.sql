CREATE TABLE [dbo].[Payment_Row_Type]
(
[APDT_AGOP_CODE] [bigint] NULL,
[APDT_RWNO] [int] NULL,
[CODE] [bigint] NOT NULL,
[AMNT] [bigint] NULL,
[RCPT_MTOD] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_PYRT]
   ON  [dbo].[Payment_Row_Type]
   AFTER INSERT
AS 
BEGIN
	MERGE dbo.Payment_Row_Type T
	USING (SELECT * FROM INSERTED) S
	ON (T.APDT_AGOP_CODE = S.APDT_AGOP_CODE AND
	    T.APDT_RWNO      = S.APDT_RWNO AND
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
	ON (T.APDT_AGOP_CODE = S.APDT_AGOP_CODE AND
	    T.APDT_RWNO      = S.APDT_RWNO AND
	    T.CODE           = S.CODE)
	WHEN MATCHED THEN
	   UPDATE
	      SET MDFY_BY = UPPER(SUSER_NAME())
	         ,MDFY_DATE = GETDATE()
	         ,ACTN_DATE = ISNULL(S.ACTN_DATE, GETDATE())
	         ,RCPT_MTOD = ISNULL(S.RCPT_MTOD, '003');
	
	IF ( 
	   SELECT SUM(T.AMNT)
	     FROM dbo.Payment_Row_Type T, INSERTED S
	    WHERE T.APDT_AGOP_CODE = S.APDT_AGOP_CODE 
	      AND T.APDT_RWNO      = S.APDT_RWNO 
	      AND T.RCPT_MTOD NOT IN ('006', '005')
	) > (
	   SELECT ISNULL(T.TOTL_AMNT_DNRM, 0)
	     FROM dbo.Aggregation_Operation_Detail T, INSERTED S
	    WHERE T.AGOP_CODE = S.APDT_AGOP_CODE 
	      AND T.RWNO      = S.APDT_RWNO 
	)
	BEGIN
	   RAISERROR (N'مبلغ دریافتی بیش از حد هزینه اعلام شده می باشد', 16, 1);
	END
END
GO
ALTER TABLE [dbo].[Payment_Row_Type] ADD CONSTRAINT [PK_PYRT] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Payment_Row_Type] ADD CONSTRAINT [FK_PYRT_APDT] FOREIGN KEY ([APDT_AGOP_CODE], [APDT_RWNO]) REFERENCES [dbo].[Aggregation_Operation_Detail] ([AGOP_CODE], [RWNO]) ON DELETE CASCADE
GO
