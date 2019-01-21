CREATE TABLE [dbo].[Expense_Item]
(
[CODE] [bigint] NOT NULL CONSTRAINT [DF_EPIT_CODE] DEFAULT ((0)),
[RQTP_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQTT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EPIT_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_EPIT_TYPE] DEFAULT ('001'),
[AUTO_GNRT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IMAG] [image] NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [BLOB]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_EPIT]
   ON  [dbo].[Expense_Item]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Expense_Item T
   USING (SELECT i.CODE, i.TYPE FROM INSERTED i) S
   ON (T.CODE   = S.CODE AND
       T.[TYPE] = S.[TYPE])
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,[TYPE]    = CASE WHEN S.[TYPE] IS NULL THEN '002' ELSE S.[TYPE] END
            ,CODE      = DBO.GNRT_NVID_U();
   
   DECLARE C$NewExpenseItem CURSOR FOR
      SELECT T.Code FROM Expense_Item T, INSERTED S
      WHERE T.[TYPE] = S.[TYPE]
        AND T.EPIT_DESC = S.EPIT_DESC
        AND T.AUTO_GNRT = '002' -- به صورت اتوماتیک درج شود
        AND T.[TYPE] IN ( '001', '003' ) -- آیتم درآمدی باشد
        ;
   
   DECLARE @Code     BIGINT;
   
   OPEN C$NewExpenseItem;
   L$NextEpitRow:
   FETCH NEXT FROM C$NewExpenseItem INTO @Code;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndEpitFetch;
   
   EXEC CRET_EXTP_P @RqrqCode = NULL, @EpitCode = @Code;
   
   GOTO L$NextEpitRow;
   L$EndEpitFetch:
   CLOSE C$NewExpenseItem;
   DEALLOCATE C$NewExpenseItem; 
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_EPIT]
   ON  [dbo].[Expense_Item]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Expense_Item T
   USING (SELECT i.CODE FROM INSERTED i) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
;
GO
ALTER TABLE [dbo].[Expense_Item] ADD CONSTRAINT [CK_EPIT_TYPE] CHECK (([TYPE]='003' OR [TYPE]='002' OR [TYPE]='001'))
GO
ALTER TABLE [dbo].[Expense_Item] ADD CONSTRAINT [EPIT_PK] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Expense_Item] ADD CONSTRAINT [FK_ٍEPIT_RQTP] FOREIGN KEY ([RQTP_CODE]) REFERENCES [dbo].[Request_Type] ([CODE])
GO
ALTER TABLE [dbo].[Expense_Item] WITH NOCHECK ADD CONSTRAINT [FK_EPIT_RQTT] FOREIGN KEY ([RQTT_CODE]) REFERENCES [dbo].[Requester_Type] ([CODE])
GO
ALTER TABLE [dbo].[Expense_Item] NOCHECK CONSTRAINT [FK_EPIT_RQTT]
GO
EXEC sp_addextendedproperty N'MS_Description', N'بعد از اضافه شدن به لیست در آیتم های درآمدی آیین نامه به صورت دستی اضافه شود یا اتوماتیک', 'SCHEMA', N'dbo', 'TABLE', N'Expense_Item', 'COLUMN', N'AUTO_GNRT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'این ایتم درآمدی مخصوص کدام یکی از واحد های درآمدزا می باشد', 'SCHEMA', N'dbo', 'TABLE', N'Expense_Item', 'COLUMN', N'RQTP_CODE'
GO
