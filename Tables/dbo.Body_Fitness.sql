CREATE TABLE [dbo].[Body_Fitness]
(
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[FIGH_FILE_NO] [bigint] NOT NULL,
[RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RWNO] [int] NOT NULL,
[BDFT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MESR_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BODY_FITN_INDX_DNRM] [real] NULL,
[BDFT_RSLT_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AGE_DNRM] [smallint] NULL,
[SEX_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CLCL_FIGH_FILE_NO] [bigint] NULL,
[CLCL_RWNO] [bigint] NULL,
[CLCL_RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TOTL_EXRS_TIME] [time] (0) NULL,
[REST_TIME_BTWN_SET] [time] (0) NULL,
[NUMB_DAY_EXRS_PROG] [smallint] NULL,
[PRE_MOVE_CHCK] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BDFT_DESC] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_BDFT]
   ON  [dbo].[Body_Fitness]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   /*IF SUSER_NAME() <> 'SCSC' 
   BEGIN
      RAISERROR ('شما مجوز حذف فیزیکی اطلاعات رکورد جدول مورد نظر را ندارید. >:(', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRANSACTION;
   END   
   */
   -- UPDATE FIGHTER TABLE
   IF NOT EXISTS(SELECT * FROM Fighter F, Deleted D
                  WHERE F.FILE_NO = D.FIGH_FILE_NO 
                    AND F.BDFT_RWNO_DNRM = D.RWNO
                    AND D.RECT_CODE = '004')
      RETURN;
   
   DECLARE C#ADEL_BDFT CURSOR FOR
      SELECT DISTINCT FIGH_FILE_NO
      FROM DELETED D;
   
   DECLARE @FILENO BIGINT;
   OPEN C#ADEL_BDFT;
   L$NextRow:
   FETCH NEXT FROM C#ADEL_BDFT INTO @FILENO;
   
   -- Fetch Next Row Is Failed
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;

   -- اگر ردیف فعالی برای محاسبه کالری برای این شماره پرونده یافت نشد مقدار دینرمال باید درجدول اصلی خالی شود
   IF NOT EXISTS(
      SELECT 
            C.FIGH_FILE_NO, 
            C.RWNO
        FROM dbo.Body_Fitness C, Deleted D
       WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO AND
             C.FIGH_FILE_NO = @FILENO        AND
             C.RECT_CODE    = D.RECT_CODE    AND
             C.RECT_CODE    = '004'          AND
             C.RWNO  NOT IN (SELECT D.RWNO FROM Deleted D WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO)
   )
   BEGIN
      UPDATE DBO.Fighter
         SET BDFT_RWNO_DNRM = NULL
       WHERE FILE_NO = @FILENO;
       GOTO L$NextRow;
   END
   
   MERGE dbo.Fighter T
   USING (SELECT TOP 1
            C.FIGH_FILE_NO, 
            C.RWNO
            FROM dbo.Body_Fitness C, Deleted D
           WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO AND
                 C.FIGH_FILE_NO = @FILENO        AND
                 C.RECT_CODE    = D.RECT_CODE    AND
                 C.RECT_CODE    = '004'          AND
                 C.RWNO  NOT IN (SELECT D.RWNO FROM Deleted D WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO)
           ORDER BY C.RWNO DESC) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO)
   WHEN MATCHED THEN
      UPDATE 
         SET BDFT_RWNO_DNRM = S.RWNO;
   
   GOTO L$NextRow;
   L$EndFetch:
   CLOSE C#ADEL_BDFT;
   DEALLOCATE C#ADEL_BDFT;
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_BDFT]
   ON  [dbo].[Body_Fitness]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here   
   
   MERGE dbo.Body_Fitness T
   USING (SELECT * FROM INSERTED i) S
   ON (T.Rqro_Rqst_Rqid = S.Rqro_Rqst_Rqid AND
       T.Rqro_Rwno      = S.Rqro_Rwno AND
       T.Figh_File_No   = S.Figh_File_No AND
       T.Rect_Code      = S.Rect_Code)
   WHEN MATCHED THEN
      UPDATE 
      SET CRET_BY   = UPPER(SUSER_NAME())
         ,CRET_DATE = GETDATE()
         ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM Body_Fitness WHERE FIGH_FILE_NO = S.FIGH_FILE_NO AND RECT_CODE = S.RECT_CODE)
         ,AGE_DNRM  = CASE
                           WHEN S.AGE_DNRM IS NULL OR S.AGE_DNRM = 0 THEN (SELECT DATEDIFF(YEAR, BRTH_DATE_DNRM, GETDATE()) FROM dbo.Fighter WHERE File_No = S.FIGH_FILE_NO)
                           ELSE S.AGE_DNRM
                       END
         ,SEX_TYPE_DNRM = CASE
                           WHEN S.SEX_TYPE_DNRM IS NULL THEN (SELECT SEX_TYPE_DNRM FROM dbo.Fighter WHERE File_No = S.FIGH_FILE_NO)
                           ELSE S.SEX_TYPE_DNRM
                          END
         ,CLCL_FIGH_FILE_NO = CASE WHEN (SELECT CLCL_RWNO_DNRM FROM Fighter WHERE File_No = S.Figh_File_No) IS NOT NULL THEN S.Figh_File_No ELSE NULL END
         ,CLCL_RECT_CODE = CASE WHEN (SELECT CLCL_RWNO_DNRM FROM Fighter WHERE File_No = S.Figh_File_No) IS NOT NULL THEN '004' ELSE NULL END
         ,CLCL_RWNO = (SELECT CLCL_RWNO_DNRM FROM Fighter WHERE File_No = S.Figh_File_No);

END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_BDFT]
   ON  [dbo].[Body_Fitness]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   
   MERGE dbo.Body_Fitness T
   USING (SELECT * FROM INSERTED i) S
   ON (T.Rqro_Rqst_Rqid = S.Rqro_Rqst_Rqid AND
       T.Rqro_Rwno      = S.Rqro_Rwno AND
       T.Figh_File_No   = S.Figh_File_No AND
       T.Rect_Code      = S.Rect_Code AND
       T.RWNO           = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
      SET MDFY_BY             = UPPER(SUSER_NAME())
         ,MDFY_DATE           = GETDATE()
         ,BODY_FITN_INDX_DNRM = CASE S.MESR_TYPE
                                   WHEN '001' THEN 0
                                   WHEN '002' THEN 1
                                   WHEN '003' THEN 2
                                END
         ,BDFT_RSLT_DNRM       = dbo.GET_BDFT_U('<Body_Fitness  fighfileno="' + CAST(S.Figh_File_No AS VARCHAR(20)) + '" rectcode="'+ S.Rect_Code +'" rwno="'+ CAST(S.Rwno AS VARCHAR(5)) +'"/>');

   -- UPDATE FIGHTER TABLE
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED I 
           WHERE I.RWNO = (SELECT MAX(RWNO) FROM Body_Fitness M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET BDFT_RWNO_DNRM = S.RWNO;
END
;
GO
ALTER TABLE [dbo].[Body_Fitness] ADD CONSTRAINT [PK_BDFT] PRIMARY KEY CLUSTERED  ([FIGH_FILE_NO], [RECT_CODE], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Body_Fitness] ADD CONSTRAINT [FK_BDFT_CLCL] FOREIGN KEY ([CLCL_FIGH_FILE_NO], [CLCL_RWNO], [CLCL_RECT_CODE]) REFERENCES [dbo].[Calculate_Calorie] ([FIGH_FILE_NO], [RWNO], [RECT_CODE])
GO
ALTER TABLE [dbo].[Body_Fitness] ADD CONSTRAINT [FK_BDFT_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Body_Fitness] ADD CONSTRAINT [FK_BDFT_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO])
GO
EXEC sp_addextendedproperty N'MS_Description', N'BDFT', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'سن فرد', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'AGE_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'توضیحات', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'BDFT_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نتیجه شاخص آمادگی جسمانی', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'BDFT_RSLT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تناسب اندام برای ورزشکاران حرفه ای یا متفرقه', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'BDFT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شاخص آمادگی جسمانی', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'BODY_FITN_INDX_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره پرونده محاسبه کالری', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'CLCL_FIGH_FILE_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد رکورد محاسبه کالری', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'CLCL_RECT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف محاسبه کالری پرونده', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'CLCL_RWNO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره پرونده', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'FIGH_FILE_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع اندازه گیری شاخص تناسب اندام', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'MESR_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد روز تمرین در هفته', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'NUMB_DAY_EXRS_PROG'
GO
EXEC sp_addextendedproperty N'MS_Description', N'حرکت های پیش نیاز لحاظ شود یا خیر؟', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'PRE_MOVE_CHCK'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد رکورد', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'RECT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان استراحت بین ست های حرکتی', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'REST_TIME_BTWN_SET'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره درخواست', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'RQRO_RQST_RQID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف درخواست', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'RQRO_RWNO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'RWNO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'جنسیت', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'SEX_TYPE_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان کل تمرین', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness', 'COLUMN', N'TOTL_EXRS_TIME'
GO
