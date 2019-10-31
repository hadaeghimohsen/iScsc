CREATE TABLE [dbo].[Buffet]
(
[APDT_AGOP_CODE] [bigint] NULL,
[APDT_RWNO] [int] NULL,
[CODE] [bigint] NOT NULL,
[EXPN_CODE] [bigint] NULL,
[EXPN_PRIC] [int] NULL,
[EXPN_EXTR_PRCT] [int] NULL,
[QNTY] [int] NULL,
[REC_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_BUFE]
   ON  [dbo].[Buffet]
   AFTER DELETE
AS 
BEGIN
	DECLARE @TotlBufeAmntDnrm BIGINT;
	SELECT @TotlBufeAmntDnrm = SUM((E.PRIC + ISNULL(E.EXTR_PRCT, 0)) * B.QNTY) 
	  FROM dbo.Buffet B, dbo.Expense E, DELETED S
	 WHERE B.APDT_AGOP_CODE = S.APDT_AGOP_CODE 
	   AND B.APDT_RWNO      = S.APDT_RWNO 
	   /*AND B.CODE           = S.CODE
	   AND B.EXPN_CODE      = E.CODE*/;
	
	UPDATE T
	   SET T.TOTL_BUFE_AMNT_DNRM = @TotlBufeAmntDnrm
	  FROM dbo.Aggregation_Operation_Detail T, DELETED S
	 WHERE T.AGOP_CODE      = S.APDT_AGOP_CODE 
	   AND T.RWNO           = S.APDT_RWNO;
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
CREATE TRIGGER [dbo].[CG$AINS_BUFE]
   ON  [dbo].[Buffet]
   AFTER INSERT
AS 
BEGIN
	MERGE dbo.Buffet T
	USING (SELECT * FROM INSERTED) S
	ON (T.APDT_AGOP_CODE = S.APDT_AGOP_CODE AND
	    T.APDT_RWNO      = S.APDT_RWNO AND
	    T.CODE           = S.CODE
	)
	WHEN MATCHED THEN
	   UPDATE
	      SET CRET_BY = UPPER(SUSER_NAME())
	         ,CRET_DATE = GETDATE()
	         ,CODE = dbo.GNRT_NVID_U()
	         ,T.EXPN_PRIC = (SELECT PRIC FROM dbo.Expense WHERE CODE = S.EXPN_CODE)
	         ,T.EXPN_EXTR_PRCT = (SELECT EXTR_PRCT FROM dbo.Expense WHERE CODE = S.EXPN_CODE);
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
CREATE TRIGGER [dbo].[CG$AUPD_BUFE]
   ON  [dbo].[Buffet]
   AFTER UPDATE
AS 
BEGIN
	MERGE dbo.Buffet T
	USING (SELECT * FROM INSERTED) S
	ON (T.APDT_AGOP_CODE = S.APDT_AGOP_CODE AND
	    T.APDT_RWNO      = S.APDT_RWNO AND
	    T.CODE           = S.CODE)
	WHEN MATCHED THEN
	   UPDATE
	      SET MDFY_BY = UPPER(SUSER_NAME())
	         ,MDFY_DATE = GETDATE();
	
	DECLARE @TotlBufeAmntDnrm BIGINT;
	SELECT @TotlBufeAmntDnrm = SUM((ISNULL(B.EXPN_PRIC, E.PRIC) + ISNULL(ISNULL(B.EXPN_EXTR_PRCT, E.EXTR_PRCT), 0)) * B.QNTY) 
	  FROM dbo.Buffet B, dbo.Expense E, INSERTED S
	 WHERE B.APDT_AGOP_CODE = S.APDT_AGOP_CODE 
	   AND B.APDT_RWNO      = S.APDT_RWNO 
	   --AND B.CODE           = S.CODE
	   AND B.EXPN_CODE      = E.CODE;
	
	UPDATE T
	   SET T.TOTL_BUFE_AMNT_DNRM = @TotlBufeAmntDnrm
	  FROM dbo.Aggregation_Operation_Detail T, INSERTED S
	 WHERE T.AGOP_CODE      = S.APDT_AGOP_CODE 
	   AND T.RWNO           = S.APDT_RWNO;
END
GO
ALTER TABLE [dbo].[Buffet] ADD CONSTRAINT [PK_BUFE] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Buffet] ADD CONSTRAINT [FK_BUFE_APDT] FOREIGN KEY ([APDT_AGOP_CODE], [APDT_RWNO]) REFERENCES [dbo].[Aggregation_Operation_Detail] ([AGOP_CODE], [RWNO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Buffet] ADD CONSTRAINT [FK_BUFE_EXPN] FOREIGN KEY ([EXPN_CODE]) REFERENCES [dbo].[Expense] ([CODE]) ON DELETE CASCADE
GO
