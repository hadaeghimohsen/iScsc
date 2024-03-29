CREATE TABLE [dbo].[Category_Belt]
(
[MTOD_CODE] [bigint] NULL,
[CTGY_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL CONSTRAINT [DF_CTGY_CODE] DEFAULT ((0)),
[NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CTGY_DESC] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ORDR] [smallint] NULL CONSTRAINT [DF_CTGY_ORDR] DEFAULT ((1)),
[RED] [smallint] NULL,
[GREN] [smallint] NULL,
[BLUE] [smallint] NULL,
[NATL_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EPIT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NUMB_OF_ATTN_MONT] [int] NULL,
[PRVT_COCH_EXPN] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NUMB_CYCL_DAY] [int] NULL,
[NUMB_MONT_OFER] [int] NULL,
[PRIC] [bigint] NULL,
[FEE_AMNT] [bigint] NULL,
[TAX_PRCT_DNRM] [real] NULL,
[DUTY_PRCT_DNRM] [real] NULL,
[EXPN_EXTR_PRCT_DNRM] [bigint] NULL,
[DFLT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CTGY_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GUST_NUMB] [int] NULL,
[RWRD_ATTN_PRIC] [bigint] NULL,
[SHOW_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_CTGY]
   ON  [dbo].[Category_Belt]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   BEGIN TRY
   BEGIN TRAN CG$ADEL_CTGY_T
      
      IF EXISTS(
         SELECT *
           FROM dbo.Fighter_Public P, DELETED D
          WHERE P.CTGY_CODE = D.Code
      )
      BEGIN
         RAISERROR (N'برای رسته جاری اطلاعاتی در جدول اطلاعات عمومی و سوابق هنرجویان و مربیان وجود دارد که نمی توان آن را حذف کنید', 16, 1);
      END 
    
    -- Insert statements for trigger here
      DELETE dbo.Distance_Category
       WHERE FRST_CTGY_CODE IN (SELECT Code FROM DELETED);
      
      DELETE dbo.Expense
       WHERE CTGY_CODE IS NULL 
         OR CTGY_CODE IN (SELECT Code FROM DELETED);
   
   COMMIT TRAN CG$ADEL_CTGY_T;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN CG$ADEL_CTGY_T;
   END CATCH 
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_CTGY]
   ON  [dbo].[Category_Belt]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Category_Belt T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE      = CASE s.code WHEN 0 THEN dbo.Gnrt_Nvid_U() ELSE s.CODE END
            ,ORDR      = CASE WHEN S.Ordr IS NULL THEN (SELECT COUNT(*) FROM dbo.Category_Belt c WHERE c.MTOD_CODE = S.Mtod_Code) ELSE S.Ordr END
            ,T.EPIT_TYPE = CASE WHEN S.EPIT_TYPE IS NULL THEN '001' ELSE S.EPIT_TYPE END
            ,T.GUST_NUMB = ISNULL(s.GUST_NUMB, 0)
            ,T.NUMB_MONT_OFER = 0;
   
   
   DECLARE C$NewCategory CURSOR FOR
      SELECT DISTINCT MTOD_CODE FROM INSERTED;
   
   DECLARE @Code     BIGINT
          ,@MtodCode BIGINT;
   
   OPEN C$NewCategory;
   L$NextCtgyRow:
   FETCH NEXT FROM C$NewCategory INTO @MtodCode;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndCtgyFetch;
   
   EXEC CRET_EXPN_P @ExtpCode = NULL, @MtodCode = @MtodCode, @CtgyCode = NULL;
   
   GOTO L$NextCtgyRow;
   L$EndCtgyFetch:
   CLOSE C$NewCategory;
   DEALLOCATE C$NewCategory;    
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_CTGY]
   ON  [dbo].[Category_Belt]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Category_Belt T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,T.EPIT_TYPE = CASE WHEN S.EPIT_TYPE IS NULL THEN '001' ELSE S.EPIT_TYPE END
            ,T.NATL_CODE = CASE WHEN LEN(S.NATL_CODE) = 0 THEN NULL ELSE dbo.GET_LPAD_U(ISNULL(S.NATL_CODE, '00'), 2, '0') END
            ,T.SHOW_STAT = ISNULL(s.SHOW_STAT, '002');
            
   /*DECLARE @CtgyCode BIGINT;
   DECLARE C$NewCtgy CURSOR FOR
      SELECT CODE FROM INSERTED
      WHERE MDFY_DATE IS NULL;
   OPEN C$NewCtgy;   
   L$NextRow:
   FETCH NEXT FROM C$NewCtgy INTO @CtgyCode
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
   
	EXEC CRET_EXPN_P
	     @ExtpCode = NULL,
	     @MtodCode = NULL,
	     @CtgyCode = @CtgyCode;
	
	GOTO L$NextRow;     
   
   L$EndFetch:
   CLOSE C$NewCtgy;
   DEALLOCATE C$NewCtgy;*/
   
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
ALTER TABLE [dbo].[Category_Belt] ADD CONSTRAINT [CTGY_PK] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Category_Belt] ADD CONSTRAINT [FK_CTGY_CTGY] FOREIGN KEY ([CTGY_CODE]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
ALTER TABLE [dbo].[Category_Belt] ADD CONSTRAINT [FK_CTGY_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE]) ON DELETE SET NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'رسته پیش فرض', 'SCHEMA', N'dbo', 'TABLE', N'Category_Belt', 'COLUMN', N'DFLT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'متناسب با کدام گزینه آیتم درآمدی و هزینه فرآیندی می باشد', 'SCHEMA', N'dbo', 'TABLE', N'Category_Belt', 'COLUMN', N'EPIT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ کارمزد', 'SCHEMA', N'dbo', 'TABLE', N'Category_Belt', 'COLUMN', N'FEE_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'حداقل تعداد عضو مهمان', 'SCHEMA', N'dbo', 'TABLE', N'Category_Belt', 'COLUMN', N'GUST_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد بین المللی', 'SCHEMA', N'dbo', 'TABLE', N'Category_Belt', 'COLUMN', N'NATL_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'پاداش حضور مشتری در دوره', 'SCHEMA', N'dbo', 'TABLE', N'Category_Belt', 'COLUMN', N'RWRD_ATTN_PRIC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نمایش نرخ ها در فضاهای خاص', 'SCHEMA', N'dbo', 'TABLE', N'Category_Belt', 'COLUMN', N'SHOW_STAT'
GO
