CREATE TABLE [dbo].[Cash]
(
[CODE] [bigint] NOT NULL CONSTRAINT [DF_CASH_CODE] DEFAULT ((0)),
[NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_CASH_NAME] DEFAULT ('CASH_NAME_HERE'),
[BANK_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Cash_BANK_NAME] DEFAULT (N'BANK_NAME'),
[BANK_BRNC_CODE] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Cash_BANK_BRNC_CODE] DEFAULT ('BANK_BRNC_CODE'),
[BANK_ACNT_NUMB] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Cash_BANK_ACNT_NUMB] DEFAULT ('BANK_ACNT_NUMB'),
[SHBA_ACNT] [varchar] (26) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CARD_NUMB] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_CASH_TYPE] DEFAULT ('001'),
[CASH_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_CASH_CASH_STAT] DEFAULT ('002'),
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
CREATE TRIGGER [dbo].[CG$AINS_CASH]
   ON  [dbo].[Cash]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Cash T
   USING (SELECT * FROM INSERTED) S
   ON (T.NAME = S.NAME                     AND
       T.BANK_NAME = S.BANK_NAME           AND
       T.BANK_BRNC_CODE = S.BANK_BRNC_CODE AND
       T.BANK_ACNT_NUMB = S.BANK_ACNT_NUMB AND
       T.[TYPE]         = S.[TYPE]         AND
       T.CASH_STAT      = S.CASH_STAT)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE      = DBO.GNRT_NVID_U();
  
   
   DECLARE C$NewCash CURSOR FOR
      SELECT T.Code FROM Cash T, INSERTED S
      WHERE T.BANK_NAME      = S.BANK_NAME      AND
            T.BANK_BRNC_CODE = S.BANK_BRNC_CODE AND
            T.BANK_ACNT_NUMB = S.BANK_ACNT_NUMB AND
            T.[TYPE]         = S.[TYPE]         AND
            T.CASH_STAT      = S.CASH_STAT;
   
   DECLARE @Code     BIGINT;
   
   OPEN C$NewCash;
   L$NextCashRow:
   FETCH NEXT FROM C$NewCash INTO @Code;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndCashFetch;
   
   EXEC CRET_EXCS_P @CashCode = @Code, @ReglYear = NULL, @ReglCode = NULL, @ExtpCode = NULL, @RegnCode = NULL, @PrvnCode = NULL, @CntyCode = NULL;
   
   GOTO L$NextCashRow;
   L$EndCashFetch:
   CLOSE C$NewCash;
   DEALLOCATE C$NewCash; 
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_CASH]
   ON  [dbo].[Cash]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Cash T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE           = S.CODE           AND -- MANDATORY
       T.NAME           = S.NAME           AND
       T.BANK_NAME      = S.BANK_NAME      AND
       T.BANK_BRNC_CODE = S.BANK_BRNC_CODE AND
       T.BANK_ACNT_NUMB = S.BANK_ACNT_NUMB AND
       T.[TYPE]         = S.[TYPE]         AND
       T.CASH_STAT      = S.CASH_STAT)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,NAME      = CASE S.TYPE 
                           WHEN '001' THEN N'بانک ' + S.BANK_NAME + N' شعبه ' + S.BANK_BRNC_CODE + N'، شماره حساب ' + S.BANK_ACNT_NUMB
                           WHEN '002' THEN N'صندوقدار ' + S.BANK_NAME
                         END;
   
   DECLARE @CashCode BIGINT;
   DECLARE C#NewCash CURSOR FOR
      SELECT CODE FROM INSERTED
      WHERE MDFY_DATE IS NULL;
   OPEN C#NewCash;   
   L$NextRow:
   FETCH NEXT FROM C#NewCash INTO @CashCode
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
   
   EXEC CRET_EXCS_P
	     @CashCode = @CashCode,
	     @ReglYear = NULL,
	     @ReglCode = NULL,
	     @ExtpCode = NULL,
	     @RegnCode = NULL,
	     @PrvnCode = NULL,
	     @CntyCode = NULL;
	
	GOTO L$NextRow;     
   
   L$EndFetch:
   CLOSE C#NewCash;
   DEALLOCATE C#NewCash;
END
;
GO
ALTER TABLE [dbo].[Cash] ADD CONSTRAINT [CK_CASH_TYPE] CHECK (([TYPE]='002' OR [TYPE]='001'))
GO
ALTER TABLE [dbo].[Cash] ADD CONSTRAINT [CASH_PK] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
