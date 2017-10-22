CREATE TABLE [dbo].[Member_Ship]
(
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[FIGH_FILE_NO] [bigint] NOT NULL,
[RWNO] [smallint] NOT NULL CONSTRAINT [DF_MBSP_RWNO] DEFAULT ((0)),
[RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STRT_DATE] [datetime] NULL,
[END_DATE] [datetime] NULL,
[NUMB_OF_MONT_DNRM] [int] NULL,
[NUMB_OF_DAYS_DNRM] [int] NULL,
[NUMB_MONT_OFER] [int] NULL CONSTRAINT [DF_Member_Ship_NUMB_MONT_OFER] DEFAULT ((0)),
[NUMB_OF_ATTN_MONT] [int] NULL CONSTRAINT [DF_Member_Ship_NUMB_OF_ATTN_MONT] DEFAULT ((13)),
[NUMB_OF_ATTN_WEEK] [int] NULL CONSTRAINT [DF_Member_Ship_NUMB_OF_ATTN_WEEK] DEFAULT ((3)),
[SUM_ATTN_MONT_DNRM] [int] NULL CONSTRAINT [DF_Member_Ship_REMN_ATTN_MONT_DNRM] DEFAULT ((0)),
[SUM_ATTN_WEEK_DNRM] [int] NULL CONSTRAINT [DF_Member_Ship_REMN_ATTN_WEEK_DNRM] DEFAULT ((0)),
[ATTN_DAY_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Member_Ship_ATTN_DAY_TYPE] DEFAULT ('001'),
[PRNT_CONT] [smallint] NULL,
[SESN_MEET_DATE] [datetime] NULL,
[SESN_MEET_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SMS_SEND] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_MBSP]
   ON  [dbo].[Member_Ship]
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
   END*/
   
   -- UPDATE FIGHTER TABLE
   IF NOT EXISTS(SELECT * FROM Fighter F, Deleted D
                  WHERE F.FILE_NO = D.FIGH_FILE_NO 
                    AND F.MBSP_RWNO_DNRM = D.RWNO
                    AND D.RECT_CODE = '004')
      RETURN;
   
   DECLARE C#ADEL_MBSP CURSOR FOR
   SELECT DISTINCT FIGH_FILE_NO
   FROM DELETED D;
   
   DECLARE @FILENO BIGINT;
   OPEN C#ADEL_MBSP;
   L$NextRow:
   FETCH NEXT FROM C#ADEL_MBSP INTO @FILENO;
   
   -- Fetch Next Row Is Failed
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;

   -- اگر ردیف فعالی برای کارت عضویت برای این شماره پرونده یافت نشد مقدار دینرمال باید درجدول اصلی خالی شود
   IF NOT EXISTS(
      SELECT 
            C.FIGH_FILE_NO, 
            C.RWNO
        FROM dbo.Member_Ship C, Deleted D
       WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO AND
             C.FIGH_FILE_NO = @FILENO        AND
             C.RECT_CODE    = D.RECT_CODE    AND
             C.RECT_CODE    = '004'          AND
             C.RWNO  NOT IN (SELECT D.RWNO FROM Deleted D WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO)
   )
   BEGIN
      UPDATE DBO.Fighter
         SET MBSP_RWNO_DNRM = NULL
       WHERE FILE_NO = @FILENO;
       GOTO L$NextRow;
   END    
      
   MERGE dbo.Fighter T
   USING (SELECT TOP 1 
            C.FIGH_FILE_NO, 
            C.RWNO
            FROM dbo.Member_Ship C, Deleted D
           WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO AND
                 C.FIGH_FILE_NO = @FILENO        AND
                 C.RECT_CODE    = D.RECT_CODE    AND
                 C.RECT_CODE    = '004'          AND
                 C.RWNO  NOT IN (SELECT D.RWNO FROM Deleted D WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO)
           ORDER BY C.RWNO DESC) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO)
   WHEN MATCHED THEN
      UPDATE 
         SET MBSP_RWNO_DNRM = S.RWNO;            

   GOTO L$NextRow;
   L$EndFetch:
   CLOSE C#ADEL_MBSP;
   DEALLOCATE C#ADEL_MBSP;   
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_MBSP]
   ON  [dbo].[Member_Ship]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Member_Ship T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
       T.RECT_CODE      = S.RECT_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,RWNO      = (SELECT ISNULL(MAX(RWNO),0) + 1 FROM MEMBER_SHIP WHERE FIGH_FILE_NO = S.FIGH_FILE_NO AND RECT_CODE = S.RECT_CODE/*RQRO_RQST_RQID < S.RQRO_RQST_RQID*/);

END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_MBSP]
   ON  [dbo].[Member_Ship]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Member_Ship T
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
            ,NUMB_OF_MONT_DNRM = CASE 
                                    WHEN DATEDIFF(DAY, S.STRT_DATE, S.END_DATE) < 30 THEN 1
                                    ELSE DATEDIFF(MONTH, S.STRT_DATE, S.END_DATE) 
                                 END
            ,NUMB_OF_DAYS_DNRM = DATEDIFF(DAY, S.STRT_DATE, S.END_DATE) + 1
            /*,CHCK_TOTL_MONT_DNRM = CASE 
                                      WHEN DATEDIFF(MONTH, S.STRT_DATE, S.END_DATE) = 
                                           DATEDIFF(DAY, S.STRT_DATE, S.END_DATE) % 30 AND
                                           DATEDIFF(MONTH, S.STRT_DATE, S.END_DATE) > 0
                                      THEN '002'
                                      ELSE '001'
                                    END*/;
   
   -- چک میکنیم که اگر تعداد ماه های تخفیف بیشتر از تعداد ماه های بازه باشد جلو آن را بگیریم
   IF EXISTS (
      SELECT *
        FROM Member_Ship M, INSERTED I
       WHERE M.RQRO_RQST_RQID = I.RQRO_RQST_RQID
         AND M.RQRO_RWNO = I.RQRO_RWNO
         AND M.RECT_CODE = I.RECT_CODE
         AND M.NUMB_OF_MONT_DNRM < I.NUMB_MONT_OFER
   )
   BEGIN
      RAISERROR (N'تعداد ماه های تخفیف نمی تواند از تعداد کل ماه بیشتر باشد', 16, 1);
      RETURN;
   END;
   
   /*
	TYPE : 
		001 - اعتبار عادی 
		002 - اعتبار مربوط به عضویت سبک
		003 - جلسه خصوصی با مربی
		004 - قرارداد پرسنل
		005 - بلاک کردن یا فریز کردن زمان حضور
		006 - جلسه مشاوره حضوری یا تلفنی
   */
   
   -- UPDATE FIGHTER TABLE
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED I 
           WHERE I.RWNO = (SELECT MAX(RWNO) FROM MEMBER_SHIP M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.TYPE IN ( '001', '004' ) AND
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.TYPE IN ('001', '004') AND
       S.RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET MBSP_RWNO_DNRM = S.RWNO
            ,MBSP_END_DATE = S.End_Date
            ,MBSP_STRT_DATE = S.Strt_Date;
   
   -- رکورد مربوط به جلسه خصوصی با مربی
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED I 
           WHERE I.RWNO = (SELECT MAX(RWNO) FROM MEMBER_SHIP M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.TYPE = '003' AND
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.TYPE = '003' AND
       S.RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET MBCO_RWNO_DNRM = S.RWNO;
   
   -- رکورد مربوط به بلوکه کردن تاریخ حضور
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED I 
           WHERE I.RWNO = (SELECT MAX(RWNO) FROM MEMBER_SHIP M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.TYPE = '005' AND
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.TYPE = '005' AND
       S.RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET MBFZ_RWNO_DNRM = S.RWNO;
   
   -- رکورد مربوط به جلسه مشاوره
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED I 
           WHERE I.RWNO = (SELECT MAX(RWNO) FROM MEMBER_SHIP M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.TYPE = '006' AND
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.TYPE = '006' AND
       S.RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET MBSM_RWNO_DNRM = S.RWNO;
END
;
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [CK_MBSP_RECT_CODE] CHECK (([RECT_CODE]='004' OR [RECT_CODE]='003' OR [RECT_CODE]='002' OR [RECT_CODE]='001'))
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [CK_MBSP_STRT_DATE] CHECK (([STRT_DATE]<=[END_DATE]))
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [CK_MBSP_END_DATE] CHECK (([STRT_DATE]<=[END_DATE]))
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [MBSP_PK] PRIMARY KEY CLUSTERED  ([FIGH_FILE_NO], [RWNO], [RECT_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [UK_MBSP] UNIQUE NONCLUSTERED  ([FIGH_FILE_NO], [RECT_CODE], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [FK_MBSP_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Member_Ship] ADD CONSTRAINT [FK_MBSP_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'Short_Name', N'MBSP', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد ماه های تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', 'COLUMN', N'NUMB_MONT_OFER'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد روز دوره', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', 'COLUMN', N'NUMB_OF_DAYS_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'محاسبه تعداد ماه های بازه تاریخی شروع و پایان', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', 'COLUMN', N'NUMB_OF_MONT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمان و تاریخ برای جلسه مشاوره', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', 'COLUMN', N'SESN_MEET_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت برگذاری جلسه مشاوره', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', 'COLUMN', N'SESN_MEET_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ارسال پیامک انجام شود ', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship', 'COLUMN', N'SMS_SEND'
GO