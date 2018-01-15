CREATE TABLE [dbo].[Method]
(
[CODE] [bigint] NOT NULL CONSTRAINT [DF_MTOD_CODE] DEFAULT ((0)),
[MTOD_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MTOD_CODE] [bigint] NULL,
[NATL_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EPIT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DFLT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MTOD_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHCK_ATTN_ALRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_MTOD]
   ON  [dbo].[Method]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   BEGIN TRY
   BEGIN TRAN CG$ADEL_MTOD_T
      
      IF EXISTS(
         SELECT *
           FROM dbo.Fighter_Public P, DELETED D
          WHERE P.MTOD_CODE = D.Code
      )
      BEGIN
         RAISERROR (N'برای سبک جاری اطلاعاتی در جدول اطلاعات عمومی و سوابق هنرجویان و مربیان وجود دارد که نمی توان آن را حذف کنید', 16, 1);
      END 
      
      IF EXISTS(
         SELECT *
           FROM dbo.Club_Method P, DELETED D
          WHERE P.MTOD_CODE = D.Code
      )
      BEGIN
         RAISERROR (N'برای سبک جاری اطلاعاتی در جدول اطلاعات برنامه کلاسی برای مربیان وجود دارد که نمی توان آن را حذف کنید', 16, 1);
      END 
      
      IF EXISTS(
         SELECT *
           FROM dbo.Fighter P, DELETED D
          WHERE P.MTOD_CODE_DNRM = D.Code
      )
      BEGIN
         RAISERROR (N'برای سبک جاری اطلاعاتی در جدول اطلاعات قعلی هنرجویان و مربیان وجود دارد که نمی توان آن را حذف کنید', 16, 1);
      END 
    -- Insert statements for trigger here
      DELETE dbo.Category_Belt
       WHERE MTOD_CODE IN (SELECT CODE FROM DELETED);
      
      DELETE dbo.Expense
       WHERE MTOD_CODE IS NULL
          OR MTOD_CODE IN (SELECT CODE FROM DELETED);
   
   COMMIT TRAN CG$ADEL_MTOD_T;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN CG$ADEL_MTOD_T;
   END CATCH 
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_MTOD]
   ON  [dbo].[Method]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Method T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE      = DBO.GNRT_NVID_U()
            ,T.EPIT_TYPE = CASE WHEN S.EPIT_TYPE IS NULL THEN '001' ELSE S.EPIT_TYPE END;
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_MTOD]
   ON  [dbo].[Method]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Method T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,T.EPIT_TYPE = CASE WHEN S.EPIT_TYPE IS NULL THEN '001' ELSE S.EPIT_TYPE END; 
            
                       
   DECLARE @MtodCode BIGINT;
   DECLARE C$NewMtod CURSOR FOR
      SELECT CODE FROM INSERTED
      WHERE MDFY_DATE IS NULL;
   OPEN C$NewMtod;   
   L$NextRow:
   FETCH NEXT FROM C$NewMtod INTO @MtodCode
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
   
	EXEC CRET_EXPN_P
	     @ExtpCode = NULL,
	     @MtodCode = @MtodCode,
	     @CtgyCode = NULL;
	
	GOTO L$NextRow;     
   
   L$EndFetch:
   CLOSE C$NewMtod;
   DEALLOCATE C$NewMtod;
END
;
GO
ALTER TABLE [dbo].[Method] ADD CONSTRAINT [MTOD_PK] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Method] ADD CONSTRAINT [FK_MTOD_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'رشته پیش فرض', 'SCHEMA', N'dbo', 'TABLE', N'Method', 'COLUMN', N'DFLT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'متناسب با کدام گزینه آیتم درآمدی و هزینه فرآیندی می باشد', 'SCHEMA', N'dbo', 'TABLE', N'Method', 'COLUMN', N'EPIT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد بین المللی', 'SCHEMA', N'dbo', 'TABLE', N'Method', 'COLUMN', N'NATL_CODE'
GO
