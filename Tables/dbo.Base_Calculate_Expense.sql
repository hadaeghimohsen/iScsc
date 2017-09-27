CREATE TABLE [dbo].[Base_Calculate_Expense]
(
[EPIT_CODE] [bigint] NULL,
[RQTT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COCH_DEG] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CODE] [bigint] NOT NULL CONSTRAINT [DF_Base_Calculate_Expense_CODE] DEFAULT ((0)),
[PRCT_VALU] [float] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_BSEX]
   ON  [dbo].[Base_Calculate_Expense]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   
   MERGE dbo.Base_Calculate_Expense T
   USING (SELECT * FROM INSERTED i) S
   ON (T.Epit_Code = S.Epit_Code AND
       T.Rqtt_Code = S.Rqtt_Code AND
       T.Coch_Deg  = S.Coch_Deg AND
       T.Code      = S.Code)
   WHEN MATCHED THEN
      UPDATE 
      SET CRET_BY   = UPPER(SUSER_NAME())
         ,CRET_DATE = GETDATE()
         ,Code      = dbo.GNRT_NVID_U()
         ,STAT      = '002';

END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_BSEX]
   ON  [dbo].[Base_Calculate_Expense]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   
   MERGE dbo.Base_Calculate_Expense T
   USING (SELECT * FROM INSERTED i) S
   ON (T.Code      = S.Code)
   WHEN MATCHED THEN
      UPDATE 
      SET MDFY_BY   = UPPER(SUSER_NAME())
         ,MDFY_DATE = GETDATE();
         
   DECLARE C$CochCG$AUPD_BSEX CURSOR FOR
      SELECT F.File_No, P.Coch_Deg
        FROM Fighter F, Fighter_Public P
       WHERE F.File_No = P.Figh_File_No
         AND F.Fgpb_Rwno_Dnrm = P.Rwno
         AND P.Rect_Code = '004'
         AND F.Fgpb_Type_Dnrm IN ('003')
         AND F.Conf_Stat = '002'
         AND P.Calc_Expn_Type = '001';
   
   DECLARE C$BsexCG$AUPD_BSEX CURSOR FOR
      SELECT Epit_Code, Rqtt_Code, Coch_Deg, Prct_Valu
        FROM Base_Calculate_Expense
       WHERE Stat = '002';
   
   DECLARE @FileNo BIGINT
          ,@CochDeg VARCHAR(3)
          ,@BCochDeg VARCHAR(3)
          ,@EpitCode BIGINT
          ,@RqttCode VARCHAR(3)
          ,@PrctValu FLOAT;
   
   OPEN C$CochCG$AUPD_BSEX;
   FETCHC$CochCG$AUPD_BSEX:
   FETCH NEXT FROM C$CochCG$AUPD_BSEX INTO @FileNo, @CochDeg;
   
   IF @@FETCH_STATUS <> 0
      GOTO CLOSEC$CochCG$AUPD_BSEX;
      
      OPEN C$BsexCG$AUPD_BSEX;
      FETCHC$BsexCG$AUPD_BSEX:
      FETCH NEXT FROM C$BsexCG$AUPD_BSEX INTO @EpitCode, @RqttCode, @BCochDeg, @PrctValu;
      
      IF @@FETCH_STATUS <> 0
         GOTO CLOSEC$BsexCG$AUPD_BSEX;     
      
      IF @CochDeg = @BCochDeg AND NOT EXISTS(SELECT * FROM Calculate_Expense_Coach WHERE COCH_FILE_NO = @FileNo AND EPIT_CODE = @EpitCode AND RQTT_CODE = @RqttCode)
      BEGIN
         INSERT INTO Calculate_Expense_Coach (COCH_FILE_NO, EPIT_CODE, RQTT_CODE, PRCT_VALU, COCH_DEG)
         VALUES (@FileNo, @EpitCode, @RqttCode, @PrctValu, @CochDeg);
      END
         
      GOTO FETCHC$BsexCG$AUPD_BSEX;
      CLOSEC$BsexCG$AUPD_BSEX:
      CLOSE C$BsexCG$AUPD_BSEX;      
   
   GOTO FETCHC$CochCG$AUPD_BSEX;
   CLOSEC$CochCG$AUPD_BSEX:
   CLOSE C$CochCG$AUPD_BSEX;
   DEALLOCATE C$CochCG$AUPD_BSEX;
   DEALLOCATE C$BsexCG$AUPD_BSEX;

END
;
GO
ALTER TABLE [dbo].[Base_Calculate_Expense] ADD CONSTRAINT [PK_BSEX] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Base_Calculate_Expense] WITH NOCHECK ADD CONSTRAINT [FK_BSEX_EPIT] FOREIGN KEY ([EPIT_CODE]) REFERENCES [dbo].[Expense_Item] ([CODE])
GO
ALTER TABLE [dbo].[Base_Calculate_Expense] ADD CONSTRAINT [FK_BSEX_RQTT] FOREIGN KEY ([RQTT_CODE]) REFERENCES [dbo].[Requester_Type] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'BSEX', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'درجه مربیگری', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'COCH_DEG'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد آیتم درآمد / هزینه', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'EPIT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'درصد', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'PRCT_VALU'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع متقاضی', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'RQTT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'STAT'
GO
