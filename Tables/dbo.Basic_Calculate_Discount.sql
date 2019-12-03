CREATE TABLE [dbo].[Basic_Calculate_Discount]
(
[SUNT_BUNT_DEPT_ORGN_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SUNT_BUNT_DEPT_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SUNT_BUNT_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SUNT_CODE] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[REGL_YEAR] [smallint] NOT NULL,
[REGL_CODE] [int] NOT NULL,
[RWNO] [int] NOT NULL CONSTRAINT [DF_Basic_Calculate_Discount_RWNO] DEFAULT ((0)),
[CODE] [bigint] NOT NULL,
[EPIT_CODE] [bigint] NULL,
[RQTP_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQTT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AMNT_DSCT] [int] NULL,
[PRCT_DSCT] [int] NULL,
[DSCT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Basic_Calculate_Discount_STAT] DEFAULT ('002'),
[ACTN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DSCT_DESC] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FROM_DATE] [date] NULL,
[TO_DATE] [date] NULL,
[MTOD_CODE] [bigint] NULL,
[CTGY_CODE] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_BCDS]
   ON  [dbo].[Basic_Calculate_Discount]
   AFTER INSERT
AS 
BEGIN
	BEGIN TRY
	   BEGIN TRAN CG$AINS_BCDS
	      -- SET NOCOUNT ON added to prevent extra result sets from
	      -- interfering with SELECT statements.
	      SET NOCOUNT ON;
         
         --IF (
         --   SELECT COUNT(*)
         --     FROM dbo.Basic_Calculate_Discount T, INSERTED S
         --    WHERE T.SUNT_Code          = S.SUNT_Code AND
         --          T.SUNT_Bunt_Code           = S.SUNT_Bunt_Code AND
         --          T.SUNT_BUNT_Dept_Code      = S.SUNT_BUNT_Dept_Code AND
         --          T.SUNT_Bunt_Dept_Orgn_Code = S.SUNT_Bunt_Dept_Orgn_Code AND
         --          T.REGL_YEAR                = S.REGL_YEAR AND
         --          T.REGL_CODE                = S.REGL_CODE AND
         --          ISNULL(S.EPIT_CODE, 0)     = ISNULL(T.EPIT_CODE, 0) AND 
         --          ISNULL(S.RQTP_CODE, '000') = ISNULL(T.RQTP_CODE, '000') AND 
         --          ISNULL(S.CTGY_CODE, 0)     = ISNULL(T.CTGY_CODE, 0)
         --) > 1 
         --BEGIN
         --   RAISERROR ( N'تخفیف برای کل هزینه قبلا وارد شده دیگر قادر به وارد کردن مقدار تخفیف جدید نیستید', -- Message text.
         --            16, -- Severity.
         --            1 -- State.
         --            );
         --END;
         
         IF (
            SELECT COUNT(*)
              FROM dbo.Basic_Calculate_Discount T, INSERTED S
             WHERE T.SUNT_Code          = S.SUNT_Code AND
                   T.SUNT_Bunt_Code           = S.SUNT_Bunt_Code AND
                   T.SUNT_BUNT_Dept_Code      = S.SUNT_BUNT_Dept_Code AND
                   T.SUNT_Bunt_Dept_Orgn_Code = S.SUNT_Bunt_Dept_Orgn_Code AND
                   T.REGL_YEAR                = S.REGL_YEAR AND
                   T.REGL_CODE                = S.REGL_CODE AND
                   S.EPIT_CODE                = T.EPIT_CODE AND 
                   S.RQTP_CODE                = T.RQTP_CODE AND
                   s.RQTT_CODE                = T.RQTT_CODE AND
                   S.CTGY_CODE                = T.CTGY_CODE
         ) > 1 
         BEGIN
            RAISERROR ( N'تخفیف برای  تعرفه مورد نظر قبلا وارد شده دیگر قادر به وارد کردن مقدار تخفیف جدید نیستید', -- Message text.
                     16, -- Severity.
                     1 -- State.
                     );
         END;
         
          -- Insert statements for trigger here
         MERGE dbo.Basic_Calculate_Discount T
         USING (SELECT * FROM INSERTED i) S
         ON (T.SUNT_Code      = S.SUNT_Code AND
             T.SUNT_Bunt_Code = S.SUNT_Bunt_Code AND
             T.SUNT_BUNT_Dept_Code = S.SUNT_BUNT_Dept_Code AND
             T.SUNT_Bunt_Dept_Orgn_Code = S.SUNT_Bunt_Dept_Orgn_Code AND
             T.REGL_YEAR = S.REGL_YEAR AND
             T.REGL_CODE = S.REGL_CODE AND
             T.RWNO = S.RWNO)
         WHEN MATCHED THEN
            UPDATE 
            SET CRET_BY   = UPPER(SUSER_NAME())
               ,CRET_DATE = GETDATE()
               ,T.CODE = CASE S.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.CODE END
               ,RWNO = (SELECT ISNULL(MAX(RWNO), 0) + 1 
                          FROM dbo.Basic_Calculate_Discount 
                         WHERE SUNT_Code                = S.SUNT_Code AND
                               SUNT_Bunt_Code           = S.SUNT_Bunt_Code AND
                               SUNT_BUNT_Dept_Code      = S.SUNT_BUNT_Dept_Code AND
                               SUNT_Bunt_Dept_Orgn_Code = S.SUNT_Bunt_Dept_Orgn_Code AND
                               REGL_YEAR                = S.REGL_YEAR AND
                               REGL_CODE                = S.REGL_CODE);
                               
      COMMIT TRAN CG$AINS_BCDS;
      END TRY
      BEGIN CATCH
         DECLARE @ErrorMessage NVARCHAR(MAX);
         SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         ROLLBACK TRAN CG$AINS_BCDS;
      END CATCH
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
CREATE TRIGGER [dbo].[CG$AUPD_BCDS]
   ON  [dbo].[Basic_Calculate_Discount]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Basic_Calculate_Discount T
   USING (SELECT * FROM INSERTED i) S
   ON (T.SUNT_Code      = S.SUNT_Code AND
       T.SUNT_Bunt_Code = S.SUNT_Bunt_Code AND
       T.SUNT_BUNT_Dept_Code = S.SUNT_BUNT_Dept_Code AND
       T.SUNT_Bunt_Dept_Orgn_Code = S.SUNT_Bunt_Dept_Orgn_Code AND
       T.REGL_YEAR = S.REGL_YEAR AND
       T.REGL_CODE = S.REGL_CODE AND
       T.RWNO = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
      SET MDFY_BY   = UPPER(SUSER_NAME())
         ,MDFY_DATE = GETDATE()
         ,MTOD_CODE = (SELECT cb.MTOD_CODE FROM dbo.Category_Belt cb WHERE cb.CODE = s.CTGY_CODE);
END
GO
ALTER TABLE [dbo].[Basic_Calculate_Discount] ADD CONSTRAINT [PK_BCDS] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Basic_Calculate_Discount] ADD CONSTRAINT [FK_BCDS_CTGY] FOREIGN KEY ([CTGY_CODE]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
ALTER TABLE [dbo].[Basic_Calculate_Discount] ADD CONSTRAINT [FK_BCDS_EPIT] FOREIGN KEY ([EPIT_CODE]) REFERENCES [dbo].[Expense_Item] ([CODE])
GO
ALTER TABLE [dbo].[Basic_Calculate_Discount] ADD CONSTRAINT [FK_BCDS_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE])
GO
ALTER TABLE [dbo].[Basic_Calculate_Discount] ADD CONSTRAINT [FK_BCDS_REGL] FOREIGN KEY ([REGL_YEAR], [REGL_CODE]) REFERENCES [dbo].[Regulation] ([YEAR], [CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Basic_Calculate_Discount] ADD CONSTRAINT [FK_BCDS_SUNT] FOREIGN KEY ([SUNT_BUNT_DEPT_ORGN_CODE], [SUNT_BUNT_DEPT_CODE], [SUNT_BUNT_CODE], [SUNT_CODE]) REFERENCES [dbo].[Sub_Unit] ([BUNT_DEPT_ORGN_CODE], [BUNT_DEPT_CODE], [BUNT_CODE], [CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع محاسبه تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'ACTN_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مقدار مبلغ تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'AMNT_DSCT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شرح تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'DSCT_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع میزان محاسبه تخفیف(درصدی / مبلغی)', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'DSCT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعرفه', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'EPIT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'از تاریخ', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'FROM_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مقدار درصد تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'PRCT_DSCT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد آیین نامه', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'REGL_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'سال آیین نامه', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'REGL_YEAR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'RWNO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مجموعه اصلی', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'SUNT_BUNT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد موسسه', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'SUNT_BUNT_DEPT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد ارگان', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'SUNT_BUNT_DEPT_ORGN_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مجموعه فرعی', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'SUNT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تا تاریخ', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Calculate_Discount', 'COLUMN', N'TO_DATE'
GO
