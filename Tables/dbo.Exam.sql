CREATE TABLE [dbo].[Exam]
(
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[FIGH_FILE_NO] [bigint] NOT NULL,
[RWNO] [bigint] NOT NULL CONSTRAINT [DF_EXAM_RWNO] DEFAULT ((0)),
[RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_EXAM_TYPE] DEFAULT ('001'),
[TIME] [smallint] NULL,
[CACH_NUMB] [smallint] NULL,
[STEP_HEGH] [real] NULL,
[WEGH] [smallint] NULL,
[SEX_TYPE_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AGE_DNRM] [smallint] NULL,
[RSLT] [int] NULL,
[RSLT_DESC] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_EXAM]
   ON  [dbo].[Exam]
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
                    AND F.PSFN_RWNO_DNRM = D.RWNO
                    AND D.RECT_CODE = '004')
      RETURN;

   DECLARE C#ADEL_EXAM CURSOR FOR
      SELECT DISTINCT FIGH_FILE_NO
      FROM DELETED D;

   DECLARE @FILENO BIGINT;
   OPEN C#ADEL_EXAM;
   L$NextRow:
   FETCH NEXT FROM C#ADEL_EXAM INTO @FILENO;
   
   -- Fetch Next Row Is Failed
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
   
   -- اگر ردیف فعالی برای امادگی جسمانی برای این شماره پرونده یافت نشد مقدار دینرمال باید درجدول اصلی خالی شود
   IF NOT EXISTS(
      SELECT 
            C.FIGH_FILE_NO, 
            C.RWNO
        FROM dbo.Exam C, Deleted D
       WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO AND
             C.FIGH_FILE_NO = @FILENO        AND
             C.RECT_CODE    = D.RECT_CODE    AND
             C.RECT_CODE    = '004'          AND
             C.RWNO  NOT IN (SELECT D.RWNO FROM Deleted D WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO)
   )
   BEGIN
      UPDATE DBO.Fighter
         SET EXAM_RWNO_DNRM = NULL
       WHERE FILE_NO = @FILENO;
       GOTO L$NextRow;
   END
         
   MERGE dbo.Fighter T
   USING (SELECT TOP 1 
            C.FIGH_FILE_NO, 
            C.RWNO
            FROM dbo.Exam C, Deleted D
           WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO AND
                 C.FIGH_FILE_NO = @FILENO        AND
                 C.RECT_CODE    = D.RECT_CODE    AND
                 C.RECT_CODE    = '004'          AND
                 C.RWNO  NOT IN (SELECT D.RWNO FROM Deleted D WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO)
           ORDER BY C.RWNO DESC) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO)
   WHEN MATCHED THEN
      UPDATE 
         SET EXAM_RWNO_DNRM = S.RWNO;
         
   GOTO L$NextRow;
   L$EndFetch:
   CLOSE C#ADEL_EXAM;
   DEALLOCATE C#ADEL_EXAM;
END


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_EXAM]
   ON  [dbo].[Exam]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- نوع آزمون ها
   -- 001 = VOTMAX
   -- 002 = چابکی
   -- 003 = تعادل
   -- 004 = هماهنگی
   -- 005 = قدرت
   
   -- Insert statements for trigger here
   MERGE dbo.Exam T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
       T.RECT_CODE      = S.RECT_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY       = UPPER(SUSER_NAME())
            ,CRET_DATE     = GETDATE()
            ,RWNO          = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM EXAM WHERE FIGH_FILE_NO = S.FIGH_FILE_NO AND RECT_CODE = S.RECT_CODE/*RQRO_RQST_RQID < S.RQRO_RQST_RQID*/)
            ,SEX_TYPE_DNRM = (SELECT SEX_TYPE_DNRM FROM Fighter WHERE FILE_NO = S.FIGH_FILE_NO)
            ,AGE_DNRM      = (SELECT DATEDIFF(YEAR, BRTH_DATE_DNRM, GETDATE()) FROM Fighter WHERE FILE_NO = S.FIGH_FILE_NO)
            ;
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_EXAM]
   ON  [dbo].[Exam]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- نوع آزمون ها
   -- 001 = VOTMAX
   -- 002 = چابکی
   -- 003 = تعادل
   -- 004 = هماهنگی
   -- 005 = قدرت
   
   -- Insert statements for trigger here
   MERGE dbo.Exam T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
       T.RWNO           = S.RWNO           AND
       T.RECT_CODE      = S.RECT_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()            
            ,RSLT      = CASE S.[TYPE]
                            WHEN '001' THEN (85.95 - (3.079 * S.[TIME]))
                            WHEN '002' THEN (S.[TIME])
                            WHEN '003' THEN (S.[TIME])
                            WHEN '004' THEN (S.CACH_NUMB)
                            WHEN '005' THEN (((S.STEP_HEGH / 30.48) * (S.WEGH / 0.453)) / S.[TIME])
                         END
            ;

   MERGE dbo.Exam T
   USING (SELECT b.RQRO_RQST_RQID,
                 b.RQRO_RWNO,
                 b.FIGH_FILE_NO,
                 b.RWNO,
                 b.RECT_CODE,
                 b.[TYPE],
                 b.SEX_TYPE_DNRM,
                 b.AGE_DNRM,
                 b.RSLT
            FROM INSERTED a, Exam b WHERE a.RQRO_RQST_RQID = b.RQRO_RQST_RQID AND a.RQRO_RWNO = b.RQRO_RWNO AND a.FIGH_FILE_NO = b.FIGH_FILE_NO AND a.RWNO = b.RWNO AND a.RECT_CODE = b.RECT_CODE) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
       T.RWNO           = S.RWNO           AND
       T.RECT_CODE      = S.RECT_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET RSLT_DESC = CASE                            
                            WHEN S.[TYPE] = '001' THEN -- VOTMAX
                              CASE S.SEX_TYPE_DNRM
                                 WHEN '001' THEN -- MALE
                                    CASE
                                       WHEN S.AGE_DNRM BETWEEN 20 AND 29 THEN
                                          CASE 
                                             WHEN S.RSLT < 36              THEN '001'
                                             WHEN S.RSLT BETWEEN 36 AND 39 THEN '002'
                                             WHEN S.RSLT BETWEEN 40 AND 43 THEN '003'
                                             WHEN S.RSLT BETWEEN 44 AND 49 THEN '004'
                                             WHEN S.RSLT > 49              THEN '005'
                                          END
                                       WHEN S.AGE_DNRM BETWEEN 30 AND 39 THEN
                                          CASE 
                                             WHEN S.RSLT < 34              THEN '001'
                                             WHEN S.RSLT BETWEEN 34 AND 36 THEN '002'
                                             WHEN S.RSLT BETWEEN 37 AND 40 THEN '003'
                                             WHEN S.RSLT BETWEEN 41 AND 45 THEN '004'
                                             WHEN S.RSLT > 45              THEN '005'
                                          END
                                       WHEN S.AGE_DNRM BETWEEN 40 AND 49 THEN
                                          CASE 
                                             WHEN S.RSLT < 32              THEN '001'
                                             WHEN S.RSLT BETWEEN 32 AND 34 THEN '002'
                                             WHEN S.RSLT BETWEEN 35 AND 38 THEN '003'
                                             WHEN S.RSLT BETWEEN 39 AND 44 THEN '004'
    WHEN S.RSLT > 44              THEN '005'
                                          END                                       
                                       WHEN S.AGE_DNRM BETWEEN 50 AND 59 THEN
                                          CASE 
                                             WHEN S.RSLT < 25              THEN '001'
                                             WHEN S.RSLT BETWEEN 25 AND 28 THEN '002'
                                             WHEN S.RSLT BETWEEN 29 AND 30 THEN '003'
                                             WHEN S.RSLT BETWEEN 31 AND 34 THEN '004'
                                             WHEN S.RSLT > 34              THEN '005'
                                          END
                                       WHEN S.AGE_DNRM BETWEEN 60 AND 69 THEN
                                          CASE 
                                             WHEN S.RSLT < 26              THEN '001'
                                             WHEN S.RSLT BETWEEN 26 AND 28 THEN '002'
                                             WHEN S.RSLT BETWEEN 29 AND 31 THEN '003'
                                             WHEN S.RSLT BETWEEN 32 AND 35 THEN '004'
                                             WHEN S.RSLT > 35              THEN '005'
                                          END
                                       WHEN S.AGE_DNRM BETWEEN 70 AND 79 THEN
                                          CASE 
                                             WHEN S.RSLT < 24              THEN '001'
                                             WHEN S.RSLT BETWEEN 24 AND 26 THEN '002'
                                             WHEN S.RSLT BETWEEN 27 AND 29 THEN '003'
                                             WHEN S.RSLT BETWEEN 30 AND 35 THEN '004'
                                             WHEN S.RSLT > 35              THEN '005'
                                          END                                       
                                    END
                                 WHEN '002' THEN -- FEMALE
                                    CASE
                                       WHEN S.AGE_DNRM BETWEEN 20 AND 29 THEN
                                          CASE 
                                             WHEN S.RSLT < 42              THEN '001'
                                             WHEN S.RSLT BETWEEN 42 AND 45 THEN '002'
                                             WHEN S.RSLT BETWEEN 46 AND 50 THEN '003'
                                             WHEN S.RSLT BETWEEN 51 AND 55 THEN '004'
                                             WHEN S.RSLT > 55              THEN '005'
                                          END                                       
                                       WHEN S.AGE_DNRM BETWEEN 30 AND 39 THEN
                                          CASE 
                                             WHEN S.RSLT < 41              THEN '001'
                                             WHEN S.RSLT BETWEEN 41 AND 43 THEN '002'
                                             WHEN S.RSLT BETWEEN 44 AND 47 THEN '003'
                                             WHEN S.RSLT BETWEEN 48 AND 53 THEN '004'
                                             WHEN S.RSLT > 53              THEN '005'
                                          END                                                                             
                                       WHEN S.AGE_DNRM BETWEEN 40 AND 49 THEN
                                          CASE 
                                             WHEN S.RSLT < 38              THEN '001'
                                             WHEN S.RSLT BETWEEN 38 AND 41 THEN '002'
                                             WHEN S.RSLT BETWEEN 42 AND 45 THEN '003'
                                             WHEN S.RSLT BETWEEN 46 AND 52 THEN '004'
 WHEN S.RSLT > 52              THEN '005'
                                          END                                                                              
                                       WHEN S.AGE_DNRM BETWEEN 50 AND 59 THEN
                                          CASE 
                                             WHEN S.RSLT < 35              THEN '001'
                                             WHEN S.RSLT BETWEEN 35 AND 37 THEN '002'
                                             WHEN S.RSLT BETWEEN 38 AND 42 THEN '003'
                                             WHEN S.RSLT BETWEEN 43 AND 49 THEN '004'
                                             WHEN S.RSLT > 49              THEN '005'
                                          END                                       
                                       WHEN S.AGE_DNRM BETWEEN 60 AND 69 THEN
                                          CASE 
                                             WHEN S.RSLT < 31              THEN '001'
                                             WHEN S.RSLT BETWEEN 31 AND 34 THEN '002'
                                             WHEN S.RSLT BETWEEN 35 AND 38 THEN '003'
                                             WHEN S.RSLT BETWEEN 39 AND 45 THEN '004'
                                             WHEN S.RSLT > 45              THEN '005'
                                          END                                                                              
                                       WHEN S.AGE_DNRM BETWEEN 70 AND 79 THEN
                                          CASE 
                                             WHEN S.RSLT < 28              THEN '001'
                                             WHEN S.RSLT BETWEEN 28 AND 30 THEN '002'
                                             WHEN S.RSLT BETWEEN 31 AND 35 THEN '003'
                                             WHEN S.RSLT BETWEEN 36 AND 41 THEN '004'
                                             WHEN S.RSLT > 41              THEN '005'
                                          END                                                                              
                                    END
                              END
                            WHEN S.[TYPE] = '002' THEN -- چابکی
                              CASE S.SEX_TYPE_DNRM
                                 WHEN '001' THEN -- مرد
                                    CASE 
                                       WHEN S.AGE_DNRM < 16 THEN 
                                          CASE 
                                             WHEN S.RSLT < 17.2 THEN '008'
                                             WHEN S.RSLT = 17.2 THEN '007'
                                             WHEN S.RSLT > 17.2 THEN '006'
                                          END
                                       WHEN S.AGE_DNRM BETWEEN 16 AND 18 THEN
                                          CASE 
                                             WHEN S.RSLT < 16.6 THEN '008'
                                             WHEN S.RSLT = 16.6 THEN '007'
                                             WHEN S.RSLT > 16.6 THEN '006'
                                          END
                                       WHEN S.AGE_DNRM > 18 THEN
                                          CASE 
                                             WHEN S.RSLT < 16 THEN '008'
                                             WHEN S.RSLT = 16 THEN '007'
                                             WHEN S.RSLT > 16 THEN '006'
                                          END
                                    END
                                 WHEN '002' THEN -- زن
                                    CASE 
                                       WHEN S.AGE_DNRM < 16 THEN 
                                          CASE 
                                             WHEN S.RSLT < 18.5 THEN '008'
                                         WHEN S.RSLT = 18.5 THEN '007'
                                             WHEN S.RSLT > 18.5 THEN '006'
                                          END
                                       WHEN S.AGE_DNRM BETWEEN 16 AND 18 THEN
                                          CASE 
                                             WHEN S.RSLT < 18.1 THEN '008'
                                             WHEN S.RSLT = 18.1 THEN '007'
                                             WHEN S.RSLT > 18.1 THEN '006'
                                          END
                                       WHEN S.AGE_DNRM > 18 THEN
                                          CASE 
                                             WHEN S.RSLT < 17.5 THEN '008'
                                             WHEN S.RSLT = 17.5 THEN '007'
                                             WHEN S.RSLT > 17.5 THEN '006'
                                          END
                                    END
                              END
                            WHEN S.[TYPE] = '003' THEN -- تعادل
                              CASE S.SEX_TYPE_DNRM
                                 WHEN '001' THEN -- مرد
                                    CASE 
                                       WHEN S.RSLT > 50              THEN '004'
                                       WHEN S.RSLT BETWEEN 37 AND 50 THEN '006'
                                       WHEN S.RSLT BETWEEN 15 AND 36 THEN '007'
                                       WHEN S.RSLT BETWEEN 05 AND 14 THEN '008'
                                       WHEN S.RSLT < 05              THEN '001'
                                    END
                                 WHEN '002' THEN -- زن
                                    CASE 
                                       WHEN S.RSLT > 27              THEN '004'
                                       WHEN S.RSLT BETWEEN 23 AND 27 THEN '006'
                                       WHEN S.RSLT BETWEEN 08 AND 22 THEN '007'
                                       WHEN S.RSLT BETWEEN 03 AND 07 THEN '008'
                                       WHEN S.RSLT < 03              THEN '001'
                                    END                                 
                              END
                            WHEN S.[TYPE] = '004' THEN -- هماهنگی
                              CASE
                                 WHEN S.RSLT > 35              THEN '004'
                                 WHEN S.RSLT BETWEEN 30 AND 35 THEN '003'
                                 WHEN S.RSLT BETWEEN 20 AND 29 THEN '007'
                                 WHEN S.RSLT BETWEEN 15 AND 19 THEN '002'
                                 WHEN S.RSLT < 15              THEN '001'                                 
                              END
                            WHEN S.[TYPE] = '005' THEN -- توان 
                              CASE S.SEX_TYPE_DNRM 
                                 WHEN '001' THEN -- مرد
                                    CASE
                                       WHEN S.AGE_DNRM <  14 THEN
                                          CASE 
                                             WHEN S.RSLT < 600               THEN '001'
                                             WHEN S.RSLT BETWEEN 600 AND 800 THEN '007'
                                             WHEN S.RSLT > 800               THEN '004'
                                          END
                                       WHEN S.AGE_DNRM >= 14 THEN
                                          CASE 
                                             WHEN S.RSLT < 700               THEN '001'
                                             WHEN S.RSLT BETWEEN 700 AND 900 THEN '007'
                                             WHEN S.RSLT > 900               THEN '004'
                                          END 
                                    END
                                 WHEN '002' THEN -- زن
                                    CASE
                                       WHEN S.AGE_DNRM <  14 THEN
                                          CASE 
                                             WHEN S.RSLT < 400               THEN '001'
                                             WHEN S.RSLT BETWEEN 400 AND 600 THEN '007'
                                             WHEN S.RSLT > 600               THEN '004'
                                          END
                                       WHEN S.AGE_DNRM >= 14 THEN
                                          CASE 
                                             WHEN S.RSLT < 500               THEN '001'
                                             WHEN S.RSLT BETWEEN 500 AND 750 THEN '007'
                                             WHEN S.RSLT > 750               THEN '004'
                                          END                                       
                                    END                                 
                              END
                         END;
   -- UPDATE FIGHTER TABLE
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED I 
           WHERE I.RWNO = (SELECT MAX(RWNO) FROM Exam M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET EXAM_RWNO_DNRM = S.RWNO;
END;
GO
ALTER TABLE [dbo].[Exam] ADD CONSTRAINT [CK_EXAM_RECT_CODE] CHECK (([RECT_CODE]='004' OR [RECT_CODE]='003' OR [RECT_CODE]='002' OR [RECT_CODE]='001'))
GO
ALTER TABLE [dbo].[Exam] ADD CONSTRAINT [CK_EXAM_RSLT_DESC] CHECK (([RSLT_DESC]='008' OR [RSLT_DESC]='007' OR [RSLT_DESC]='006' OR [RSLT_DESC]='005' OR [RSLT_DESC]='004' OR [RSLT_DESC]='003' OR [RSLT_DESC]='002' OR [RSLT_DESC]='001'))
GO
ALTER TABLE [dbo].[Exam] ADD CONSTRAINT [CK_EXAM_SEX_TYPE_DNRM] CHECK (([SEX_TYPE_DNRM]='002' OR [SEX_TYPE_DNRM]='001'))
GO
ALTER TABLE [dbo].[Exam] ADD CONSTRAINT [EXAM_PK] PRIMARY KEY CLUSTERED  ([FIGH_FILE_NO], [RWNO], [RECT_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Exam] ADD CONSTRAINT [FK_EXAM_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Exam] ADD CONSTRAINT [FK_EXAM_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO]) ON DELETE CASCADE
GO
