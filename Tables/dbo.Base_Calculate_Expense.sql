CREATE TABLE [dbo].[Base_Calculate_Expense]
(
[CODE] [bigint] NOT NULL CONSTRAINT [DF_Base_Calculate_Expense_CODE] DEFAULT ((0)),
[COCH_DEG] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MTOD_CODE] [bigint] NULL,
[CTGY_CODE] [bigint] NULL,
[CALC_EXPN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CALC_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRCT_VALU] [float] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EPIT_CODE] [bigint] NULL,
[RQTP_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQTT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PYMT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[MIN_NUMB_ATTN] [smallint] NULL
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
       T.RQTP_CODE = S.RQTP_CODE AND
       T.Coch_Deg  = S.Coch_Deg AND
       T.MTOD_CODE = S.MTOD_CODE AND
       T.CTGY_CODE = S.CTGY_CODE AND
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
         AND F.Conf_Stat = '002';
         --AND P.Calc_Expn_Type = '001';
   
   DECLARE C$BsexCG$AUPD_BSEX CURSOR FOR
      SELECT Epit_Code, Rqtt_Code, Coch_Deg, Prct_Valu,
             RQTP_CODE, MTOD_CODE, CTGY_CODE, CALC_TYPE,
             PYMT_STAT, CALC_EXPN_TYPE
        FROM Base_Calculate_Expense
       WHERE Stat = '002';
   
   DECLARE @FileNo BIGINT
          ,@CochDeg VARCHAR(3)
          ,@BCochDeg VARCHAR(3)
          ,@EpitCode BIGINT
          ,@RqttCode VARCHAR(3)
          ,@PrctValu FLOAT
          ,@RqtpCode VARCHAR(3)
          ,@MtodCode BIGINT
          ,@CtgyCode BIGINT
          ,@CalcType VARCHAR(3)
          ,@PymtStat VARCHAR(3)
          ,@CalcExpnType VARCHAR(3);
   
   OPEN C$CochCG$AUPD_BSEX;
   FETCHC$CochCG$AUPD_BSEX:
   FETCH NEXT FROM C$CochCG$AUPD_BSEX INTO @FileNo, @CochDeg;
   
   IF @@FETCH_STATUS <> 0
      GOTO CLOSEC$CochCG$AUPD_BSEX;
      
      OPEN C$BsexCG$AUPD_BSEX;
      FETCHC$BsexCG$AUPD_BSEX:
      FETCH NEXT FROM C$BsexCG$AUPD_BSEX INTO @EpitCode, @RqttCode, @BCochDeg, @PrctValu, @RqtpCode, @MtodCode, @CtgyCode, @CalcType, @PymtStat, @CalcExpnType;
      
      IF @@FETCH_STATUS <> 0
         GOTO CLOSEC$BsexCG$AUPD_BSEX;     
      
      IF @CochDeg = @BCochDeg AND 
         NOT EXISTS(
            SELECT * 
              FROM Calculate_Expense_Coach
             WHERE COCH_FILE_NO = @FileNo 
               AND EPIT_CODE = @EpitCode 
               AND RQTT_CODE = @RqttCode 
               AND RQTP_CODE = @RqtpCode 
               AND MTOD_CODE = @MtodCode 
               AND CTGY_CODE = @CtgyCode 
               AND CALC_TYPE = @CalcType 
               --AND PYMT_STAT = @PymtStat 
               AND CALC_EXPN_TYPE = @CalcExpnType)
      BEGIN
         INSERT INTO Calculate_Expense_Coach (COCH_FILE_NO, EPIT_CODE, RQTT_CODE, PRCT_VALU, COCH_DEG, RQTP_CODE, MTOD_CODE, CTGY_CODE, CALC_TYPE, PYMT_STAT, CALC_EXPN_TYPE)
         VALUES (@FileNo, @EpitCode, @RqttCode, @PrctValu, @CochDeg, @RqtpCode, @MtodCode, @CtgyCode, @CalcType, @PymtStat, @CalcExpnType);
      END
         
      GOTO FETCHC$BsexCG$AUPD_BSEX;
      CLOSEC$BsexCG$AUPD_BSEX:
      CLOSE C$BsexCG$AUPD_BSEX;      
   
   GOTO FETCHC$CochCG$AUPD_BSEX;
   CLOSEC$CochCG$AUPD_BSEX:
   CLOSE C$CochCG$AUPD_BSEX;
   DEALLOCATE C$CochCG$AUPD_BSEX;
   DEALLOCATE C$BsexCG$AUPD_BSEX;
END;
GO
ALTER TABLE [dbo].[Base_Calculate_Expense] ADD CONSTRAINT [PK_BSEX] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Base_Calculate_Expense] ADD CONSTRAINT [FK_BSEX_CTGY] FOREIGN KEY ([CTGY_CODE]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
ALTER TABLE [dbo].[Base_Calculate_Expense] WITH NOCHECK ADD CONSTRAINT [FK_BSEX_EPIT] FOREIGN KEY ([EPIT_CODE]) REFERENCES [dbo].[Expense_Item] ([CODE])
GO
ALTER TABLE [dbo].[Base_Calculate_Expense] ADD CONSTRAINT [FK_BSEX_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE])
GO
ALTER TABLE [dbo].[Base_Calculate_Expense] ADD CONSTRAINT [FK_BSEX_RQTP] FOREIGN KEY ([RQTP_CODE]) REFERENCES [dbo].[Request_Type] ([CODE])
GO
ALTER TABLE [dbo].[Base_Calculate_Expense] ADD CONSTRAINT [FK_BSEX_RQTT] FOREIGN KEY ([RQTT_CODE]) REFERENCES [dbo].[Requester_Type] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'BSEX', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ دوره مورد نظر می باشد یا تعداد جلسات دوره ای که با مربی گذشته', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'CALC_EXPN_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نحوه محاسبه', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'CALC_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'درجه مربیگری', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'COCH_DEG'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زیر گروه', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'CTGY_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد آیتم درآمد / هزینه', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'EPIT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'حداقل تعداد حضوری مشترک', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'MIN_NUMB_ATTN'
GO
EXEC sp_addextendedproperty N'MS_Description', N'گروه', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'MTOD_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'درصد / مبلغ', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'PRCT_VALU'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت پرداخت * اگر صورتحساب تسویه باشد میتوان سند پرداخت دستمزد مربی را داد ولی اگر صورتحساب بدهکار باشد مشخص میکنیم که سند پرداخت دستمزد مربی انجام شود یا خیر تا اینکه صورتحساب تسویه شود که مبلغ دستمزد مربی پرداخت شود.', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'PYMT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع درخواست', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'RQTP_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع متقاضی', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'RQTT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت', 'SCHEMA', N'dbo', 'TABLE', N'Base_Calculate_Expense', 'COLUMN', N'STAT'
GO
