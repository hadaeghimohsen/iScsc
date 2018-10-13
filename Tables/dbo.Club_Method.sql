CREATE TABLE [dbo].[Club_Method]
(
[CLUB_CODE] [bigint] NULL,
[MTOD_CODE] [bigint] NULL,
[COCH_FILE_NO] [bigint] NULL,
[CODE] [bigint] NOT NULL CONSTRAINT [DF_CBMT_RWNO] DEFAULT ((0)),
[DAY_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[STRT_TIME] [time] NOT NULL,
[END_TIME] [time] NOT NULL,
[MTOD_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_CBMT_MTOD_STAT] DEFAULT ('002'),
[SEX_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CBMT_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DFLT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CPCT_NUMB] [int] NULL,
[CPCT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CBMT_TIME] [int] NULL,
[CBMT_TIME_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CLAS_TIME] [int] NULL,
[AMNT] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_CBMT]
   ON  [dbo].[Club_Method]
   AFTER DELETE
AS 
BEGIN
	BEGIN TRY
	BEGIN TRAN T_CG$ADEL_CBMT
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   IF EXISTS(
      SELECT *
        FROM Fighter F, DELETED D
       WHERE F.CBMT_CODE_DNRM = D.CODE          
   ) OR 
      EXISTS(
      SELECT *
        FROM Fighter F, Member_Ship M, Session S, Deleted D
       WHERE F.FILE_NO = M.FIGH_FILE_NO
         AND M.RECT_CODE = '004'
         AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
         AND M.RECT_CODE = S.MBSP_RECT_CODE
         AND M.RWNO = S.MBSP_RWNO
         AND S.CBMT_CODE = D.CODE   
   )
   BEGIN
      RAISERROR(N'شما اجازه حذف کلاس را ندارید. این کلاس قبلا در سابقه هنرجویان ثبت شده و قادر به حذف آن نیستید. اگر می خواهید آن را غیرفعال کنید', 16, 1);
      RETURN;
   END
   
   COMMIT TRAN T_CG$ADEL_CBMT
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T_CG$ADEL_CBMT;
   END CATCH
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_CBMT]
   ON  [dbo].[Club_Method]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   --SELECT * FROM INSERTED;
   -- Insert statements for trigger here
   L$GnrtCode:
   DECLARE @Code BIGINT;
   SET @Code = dbo.GNRT_NVID_U();
   IF EXISTS(SELECT * FROM dbo.Club_Method WHERE CODE = @Code)
   BEGIN
      PRINT 'Found'
      GOTO L$GnrtCode;
   END
    
   MERGE dbo.Club_Method T
   USING (SELECT * FROM INSERTED) S
   ON (T.CLUB_CODE = S.CLUB_CODE AND
       T.MTOD_CODE = S.MTOD_CODE AND
       T.CODE = S.Code)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE      = @Code;
            
   
   --PRINT'Hello'         
   /* ذخیره کردن ایام هفته برای ساعت کلاسی */
   INSERT INTO dbo.Club_Method_Weekday( CODE, CBMT_CODE, WEEK_DAY, STAT ) 
   VALUES  ( dbo.GNRT_NVID_U() ,@Code , '001' ,'002' ),
           ( dbo.GNRT_NVID_U() ,@Code , '002' ,'002' ),
           ( dbo.GNRT_NVID_U() ,@Code , '003' ,'002' ),
           ( dbo.GNRT_NVID_U() ,@Code , '004' ,'002' ),
           ( dbo.GNRT_NVID_U() ,@Code , '005' ,'002' ),
           ( dbo.GNRT_NVID_U() ,@Code , '006' ,'002' ),
           ( dbo.GNRT_NVID_U() ,@Code , '007' ,'002' );
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_CBMT]
   ON  [dbo].[Club_Method]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Club_Method T
   USING (SELECT * FROM INSERTED) S
   ON (T.CLUB_CODE = S.CLUB_CODE AND
       T.MTOD_CODE = S.MTOD_CODE AND
       T.CODE      = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,T.CLAS_TIME = DATEDIFF(MINUTE, S.STRT_TIME, s.END_TIME);
            
   -- اگر برنامه کلاسی برنامه هفتگی نداشته باشد            
   IF NOT EXISTS(
      SELECT *
        FROM dbo.Club_Method_Weekday, INSERTED I
       WHERE CBMT_CODE = I.Code
   )
   BEGIN
      DECLARE @Code BIGINT;
      SELECT @Code = Code FROM INSERTED;
      
      -- ذخیره کردن ایام هفته برای ساعت کلاسی 
      --IF NOT EXISTS (
      --   SELECT * 
      --     FROM dbo.Club_Method_Weekday Cmw, INSERTED I
      --    WHERE Cmw.CBMT_CODE = I.Code
      --)
      --INSERT INTO dbo.Club_Method_Weekday( CODE, CBMT_CODE, WEEK_DAY, STAT ) 
      --VALUES  ( dbo.GNRT_NVID_U() ,@Code , '001' ,'001' ),
      --        ( dbo.GNRT_NVID_U() ,@Code , '002' ,'001' ),
      --        ( dbo.GNRT_NVID_U() ,@Code , '003' ,'001' ),
      --        ( dbo.GNRT_NVID_U() ,@Code , '004' ,'001' ),
      --        ( dbo.GNRT_NVID_U() ,@Code , '005' ,'001' ),
      --        ( dbo.GNRT_NVID_U() ,@Code , '006' ,'001' ),
      --        ( dbo.GNRT_NVID_U() ,@Code , '007' ,'001' );
   END
END
;
GO
ALTER TABLE [dbo].[Club_Method] ADD CONSTRAINT [CK_CBMT_MTOD_STAT] CHECK (([MTOD_STAT]='002' OR [MTOD_STAT]='001'))
GO
ALTER TABLE [dbo].[Club_Method] ADD CONSTRAINT [CK_CBMT_STRT_TIME] CHECK (([STRT_TIME]<[END_TIME]))
GO
ALTER TABLE [dbo].[Club_Method] ADD CONSTRAINT [CK_CBMT_END_TIME] CHECK (([STRT_TIME]<[END_TIME]))
GO
ALTER TABLE [dbo].[Club_Method] ADD CONSTRAINT [PK_CBMT] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Club_Method] ADD CONSTRAINT [FK_CBMT_CLUB] FOREIGN KEY ([CLUB_CODE]) REFERENCES [dbo].[Club] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Club_Method] ADD CONSTRAINT [FK_CBMT_FIGH] FOREIGN KEY ([COCH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Club_Method] ADD CONSTRAINT [FK_CBMT_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ هر جلسه', 'SCHEMA', N'dbo', 'TABLE', N'Club_Method', 'COLUMN', N'AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شرج کلاس رشته و مربی', 'SCHEMA', N'dbo', 'TABLE', N'Club_Method', 'COLUMN', N'CBMT_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان کلاس', 'SCHEMA', N'dbo', 'TABLE', N'Club_Method', 'COLUMN', N'CBMT_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'محدودیت مدت زمان کلاس', 'SCHEMA', N'dbo', 'TABLE', N'Club_Method', 'COLUMN', N'CBMT_TIME_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان کلاس', 'SCHEMA', N'dbo', 'TABLE', N'Club_Method', 'COLUMN', N'CLAS_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'طرفیت کلاس', 'SCHEMA', N'dbo', 'TABLE', N'Club_Method', 'COLUMN', N'CPCT_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'محدودیت در نظر گرفتن ظرفیت کلاس', 'SCHEMA', N'dbo', 'TABLE', N'Club_Method', 'COLUMN', N'CPCT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کلاس پیش فرض', 'SCHEMA', N'dbo', 'TABLE', N'Club_Method', 'COLUMN', N'DFLT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'جنسیت افراد کلاس', 'SCHEMA', N'dbo', 'TABLE', N'Club_Method', 'COLUMN', N'SEX_TYPE'
GO
