CREATE TABLE [dbo].[Group_Expense]
(
[GEXP_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[LINK_JOIN] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GROP_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR] [smallint] NULL,
[GROP_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUB_GROP_NUMB_DNRM] [bigint] NULL,
[SUB_EXPN_NUMB_DNRM] [bigint] NULL,
[GROP_ORDR] [int] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_GEXP]
   ON  [dbo].[Group_Expense]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Group_Expense T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE   = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET t.CRET_BY   = UPPER(SUSER_NAME())
            ,t.CRET_DATE = GETDATE()
            ,t.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END
            ,t.ORDR = CASE ISNULL(s.ORDR, 0) WHEN 0 THEN (SELECT ISNULL(MAX(ORDR), 0) + 1 FROM dbo.Group_Expense WHERE ISNULL(GEXP_CODE, 0) = ISNULL(s.GEXP_CODE, 0)) ELSE s.ORDR END 
            ,T.STAT = ISNULL(s.STAT, '002')
            ,T.GROP_TYPE = ISNULL(s.GROP_TYPE, '001');
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_GEXP]
   ON  [dbo].[Group_Expense]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- Insert statements for trigger here
   MERGE dbo.Group_Expense T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE   = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,T.SUB_GROP_NUMB_DNRM = (
               SELECT ISNULL(COUNT(ge.CODE), 0)
                 FROM dbo.Group_Expense ge
                WHERE ge.GEXP_CODE = s.CODE
                  AND ge.STAT = '002'
            ),
            t.SUB_EXPN_NUMB_DNRM = 
               CASE WHEN EXISTS(SELECT * FROM dbo.Group_Expense ge WHERE ge.GEXP_CODE = s.CODE) THEN 
                    (
                       SELECT ISNULL(SUM(ge.SUB_EXPN_NUMB_DNRM), 0)
                         FROM dbo.Group_Expense ge
                        WHERE ge.GEXP_CODE = s.CODE
                          AND ge.STAT = '002'
                    )
                    ELSE s.SUB_EXPN_NUMB_DNRM
               END;   
   
   -- بروز رسانی گروه های پدر
   DECLARE C$Gexp CURSOR FOR 
      SELECT i.GEXP_CODE FROM Inserted i;
   
   DECLARE @Code BIGINT,
           @GexpCode BIGINT;
   
   OPEN [C$Gexp];
   L$Loop1:   
   FETCH [C$Gexp] INTO @GexpCode;
   
   IF @@FETCH_STATUS <> 0  
   GOTO L$EndLoop1;
   
   L$Loop2:
   UPDATE dbo.Group_Expense 
      SET SUB_EXPN_NUMB_DNRM = 
          (
              SELECT ISNULL(SUM(ge.SUB_EXPN_NUMB_DNRM), 0)
                FROM dbo.Group_Expense ge
               WHERE ge.GEXP_CODE = @GexpCode
                 AND ge.STAT = '002'
          ),
          SUB_GROP_NUMB_DNRM = 
          (
              SELECT ISNULL(COUNT(ge.CODE), 0)
                FROM dbo.Group_Expense ge
               WHERE ge.GEXP_CODE = @GexpCode
                 AND ge.STAT = '002'
          )
    WHERE CODE = @GexpCode;    
   
   SELECT @Code = ge.GEXP_CODE
     FROM dbo.Group_Expense ge
    WHERE ge.CODE = @GexpCode;
   
   IF @Code IS NOT NULL AND @Code != @GexpCode
   BEGIN
      SET @GexpCode = @Code;
      GOTO L$Loop2;
   END
   
   GOTO L$Loop1;
   L$EndLoop1:
   CLOSE [C$Gexp];
   DEALLOCATE [C$Gexp]
END
;
GO
ALTER TABLE [dbo].[Group_Expense] ADD CONSTRAINT [PK_GEXP] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Group_Expense] ADD CONSTRAINT [FK_GEXP_GEXP] FOREIGN KEY ([GEXP_CODE]) REFERENCES [dbo].[Group_Expense] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'مشخص کردن گروه کالا و برند کالا', 'SCHEMA', N'dbo', 'TABLE', N'Group_Expense', 'COLUMN', N'GROP_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد محصولات', 'SCHEMA', N'dbo', 'TABLE', N'Group_Expense', 'COLUMN', N'SUB_EXPN_NUMB_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد زیر گروه ها', 'SCHEMA', N'dbo', 'TABLE', N'Group_Expense', 'COLUMN', N'SUB_GROP_NUMB_DNRM'
GO
