CREATE TABLE [dbo].[Misc_Expense_Detail]
(
[MSEX_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[COCH_FILE_NO] [bigint] NULL,
[MTOD_CODE] [bigint] NULL,
[ACTN_CONT_DNRM] [int] NULL,
[UNIT_AMNT_DNRM] [bigint] NULL,
[TOTL_AMNT_DNRM] [bigint] NULL,
[PRVS_DELV_AMNT_DNRM] [bigint] NULL,
[CRNT_AMNT_DNRM] [bigint] NULL,
[MAX_CNTR_AMNT_DNRM] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_MSXD]
   ON  [dbo].[Misc_Expense_Detail]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Misc_Expense_Detail T
   USING (SELECT * FROM Inserted) S
   ON (T.MSEX_CODE = S.MSEX_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE()
        ,T.CODE = dbo.GNRT_NVID_U();
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
CREATE TRIGGER [dbo].[CG$AUPD_MSXD]
   ON  [dbo].[Misc_Expense_Detail]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Misc_Expense_Detail T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,T.MDFY_DATE = GETDATE();
   
   DECLARE C$MSXD CURSOR FOR
      SELECT MSEX_CODE, COCH_FILE_NO, MTOD_CODE
        FROM Inserted;
    
   DECLARE @MsexCode BIGINT
          ,@CochFileNo BIGINT
          ,@MtodCode BIGINT
          ,@ActnCont INT
          ,@UnitAmnt BIGINT
          ,@MaxCntrAmnt BIGINT
          ,@PrvsDelvAmnt BIGINT;
   
   OPEN [C$MSXD];
   LS$MSXD:
   FETCH [C$MSXD] INTO @MsexCode, @CochFileNo, @MtodCode;
   
   IF @@FETCH_STATUS <> 0
      GOTO LE$MSXD;
   
   SELECT @ActnCont = COUNT(pe.CODE)
         ,@UnitAmnt = SUM(pe.EXPN_AMNT)
     FROM dbo.Payment_Expense pe
    WHERE pe.MSEX_CODE = @MsexCode
      AND pe.COCH_FILE_NO = @CochFileNo
      AND pe.MTOD_CODE = @MtodCode;
   
   SELECT @MaxCntrAmnt = MAX(AMNT) 
     FROM dbo.Club_Method 
    WHERE COCH_FILE_NO = @CochFileNo 
      AND MTOD_CODE = @MtodCode 
      AND MTOD_STAT = '002';
   
   SELECT @PrvsDelvAmnt = SUM(med.TOTL_AMNT_DNRM)
     FROM dbo.Misc_Expense_Detail med
    WHERE med.COCH_FILE_NO = @CochFileNo
      AND med.MTOD_CODE = @MtodCode
      AND med.MSEX_CODE > @MsexCode;
   
   UPDATE med
      SET med.ACTN_CONT_DNRM = ISNULL(@ActnCont, 0)
         ,med.UNIT_AMNT_DNRM = ISNULL(@UnitAmnt, 0)
         ,med.TOTL_AMNT_DNRM = ISNULL(@UnitAmnt, 0) * ISNULL(@ActnCont, 0)
         ,med.PRVS_DELV_AMNT_DNRM = ISNULL(@PrvsDelvAmnt, 0)
         ,med.CRNT_AMNT_DNRM = ISNULL(@UnitAmnt, 0) * ISNULL(@ActnCont, 0) + ISNULL(@PrvsDelvAmnt, 0)
         ,med.MAX_CNTR_AMNT_DNRM = ISNULL(@MaxCntrAmnt, 0)
     FROM dbo.Misc_Expense_Detail med
    WHERE med.MSEX_CODE = @MsexCode
      AND med.COCH_FILE_NO = @CochFileNo
      AND med.MTOD_CODE = @MtodCode;
   
   GOTO LS$MSXD;
   LE$MSXD:
   CLOSE [C$MSXD];
   DEALLOCATE [C$MSXD];       
END
GO
ALTER TABLE [dbo].[Misc_Expense_Detail] ADD CONSTRAINT [PK_MSXD] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Misc_Expense_Detail] ADD CONSTRAINT [FK_MSXD_FIGH] FOREIGN KEY ([COCH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Misc_Expense_Detail] ADD CONSTRAINT [FK_MSXD_MSEX] FOREIGN KEY ([MSEX_CODE]) REFERENCES [dbo].[Misc_Expense] ([CODE])
GO
ALTER TABLE [dbo].[Misc_Expense_Detail] ADD CONSTRAINT [FK_MSXD_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'عملکرد', 'SCHEMA', N'dbo', 'TABLE', N'Misc_Expense_Detail', 'COLUMN', N'ACTN_CONT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد سرپرست', 'SCHEMA', N'dbo', 'TABLE', N'Misc_Expense_Detail', 'COLUMN', N'COCH_FILE_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'جمع صورت وضعیت ها تاکنون', 'SCHEMA', N'dbo', 'TABLE', N'Misc_Expense_Detail', 'COLUMN', N'CRNT_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'حداکثر مبلغ قرارداد', 'SCHEMA', N'dbo', 'TABLE', N'Misc_Expense_Detail', 'COLUMN', N'MAX_CNTR_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد محاسبه حقوق و دستمزد', 'SCHEMA', N'dbo', 'TABLE', N'Misc_Expense_Detail', 'COLUMN', N'MSEX_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد گروه', 'SCHEMA', N'dbo', 'TABLE', N'Misc_Expense_Detail', 'COLUMN', N'MTOD_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'پرداختی های قبلی', 'SCHEMA', N'dbo', 'TABLE', N'Misc_Expense_Detail', 'COLUMN', N'PRVS_DELV_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کل مبلغ محاسبه شده', 'SCHEMA', N'dbo', 'TABLE', N'Misc_Expense_Detail', 'COLUMN', N'TOTL_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ واحد عملکرد', 'SCHEMA', N'dbo', 'TABLE', N'Misc_Expense_Detail', 'COLUMN', N'UNIT_AMNT_DNRM'
GO
