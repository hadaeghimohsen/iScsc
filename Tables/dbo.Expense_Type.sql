CREATE TABLE [dbo].[Expense_Type]
(
[RQRQ_CODE] [bigint] NOT NULL,
[EPIT_CODE] [bigint] NOT NULL,
[EXTP_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL CONSTRAINT [DF_EXTP_CODE] DEFAULT ((0)),
[EXTP_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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

CREATE TRIGGER [dbo].[CG$AINS_EXTP]
   ON [dbo].[Expense_Type]  
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   --PRINT 'INS EXTP';
   
   -- Insert statements for trigger here
   MERGE dbo.Expense_Type T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRQ_CODE = S.RQRQ_CODE AND
       T.EPIT_CODE = S.EPIT_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE      = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE end;
END
;

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CG$AUPD_EXTP]
   ON [dbo].[Expense_Type]  
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Expense_Type T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRQ_CODE = S.RQRQ_CODE AND
       T.EPIT_CODE = S.EPIT_CODE AND
       T.CODE      = S.CODE)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,EXTP_DESC = (SELECT N'هزینه ' + EPIT.EPIT_DESC + ' ' + RQTP.RQTP_DESC + ' ' + RQTT.RQTT_DESC
                            FROM REQUEST_TYPE RQTP, REQUESTER_TYPE RQTT, EXPENSE_ITEM EPIT, REQUEST_REQUESTER RQRQ
                           WHERE RQRQ.CODE      = S.RQRQ_CODE
                             AND RQRQ.RQTP_CODE = RQTP.CODE
                             AND RQRQ.RQTT_CODE = RQTT.CODE
                             AND EPIT.CODE      = S.EPIT_CODE);
                             
   
   
   DECLARE @ExtpCode BIGINT;
   DECLARE C#NewExtp CURSOR FOR
      SELECT CODE FROM INSERTED
      WHERE MDFY_DATE IS NULL;
   OPEN C#NewExtp;   
   L$NextRow:
   FETCH NEXT FROM C#NewExtp INTO @ExtpCode
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
   
   EXEC CRET_EXCS_P
	     @CashCode = NULL,
	     @ReglYear = NULL,
	     @ReglCode = NULL,
	     @ExtpCode = @ExtpCode,
	     @RegnCode = NULL,
	     @PrvnCode = NULL,
	     @CntyCode = NULL;
	
	EXEC CRET_EXPN_P
	     @ExtpCode = @ExtpCode,
	     @MtodCode = NULL,
	     @CtgyCode = NULL;
	
	GOTO L$NextRow;     
   
   L$EndFetch:
   CLOSE C#NewExtp;
   DEALLOCATE C#NewExtp;
   
   -- 1398/06/10 * اگر که مبلغ نرخ بیمه درون سیستم آیین نامه وارد شده باشد به ازای هر ایتم زیر گروه چک میکینم که مبلغ نرخ بیمه بروز شده یا خیر
   IF (SELECT ISNULL(INSR_PRIC, 0) FROM dbo.Regulation WHERE TYPE = '001' AND REGL_STAT = '002') > 0
   BEGIN
      UPDATE e
         SET e.PRIC = rg.INSR_PRIC
            ,e.EXPN_STAT = '002'
        FROM dbo.Expense e
            ,dbo.Expense_Type et
            ,dbo.Request_Requester rr
            ,dbo.Regulation rg
       WHERE e.EXTP_CODE = et.CODE
         AND et.RQRQ_CODE = rr.CODE
         AND rr.RQTP_CODE = '012'
         AND rr.RQTT_CODE = '001'
         AND rr.REGL_YEAR = rg.YEAR
         AND rr.REGL_CODE = rg.CODE
         AND (e.PRIC != rg.INSR_PRIC OR e.EXPN_STAT != '002');
   END;                          
END
;

GO
ALTER TABLE [dbo].[Expense_Type] ADD CONSTRAINT [EXTP_PK] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Expense_Type] ADD CONSTRAINT [FK_EXTP_EPIT] FOREIGN KEY ([EPIT_CODE]) REFERENCES [dbo].[Expense_Item] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Expense_Type] ADD CONSTRAINT [FK_EXTP_EXTP] FOREIGN KEY ([EXTP_CODE]) REFERENCES [dbo].[Expense_Type] ([CODE])
GO
ALTER TABLE [dbo].[Expense_Type] ADD CONSTRAINT [FK_EXTP_RQRQ] FOREIGN KEY ([RQRQ_CODE]) REFERENCES [dbo].[Request_Requester] ([CODE]) ON DELETE CASCADE
GO
