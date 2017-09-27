CREATE TABLE [dbo].[Heart_Zone]
(
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[FIGH_FILE_NO] [bigint] NOT NULL,
[RWNO] [bigint] NOT NULL CONSTRAINT [DF_HERT_RWNO] DEFAULT ((0)),
[RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[REST_HERT_RATE] [smallint] NULL,
[AGE_DNRM] [smallint] NULL CONSTRAINT [DF_Heart_Zone_AGE_DNRM] DEFAULT ((0)),
[MAX_HERT_RATE_DNRM] [real] NULL,
[WORK_HERT_RATE_DNRM] [real] NULL,
[HR60_DNRM] [real] NULL,
[HR70_DNRM] [real] NULL,
[HR80_DNRM] [real] NULL,
[HR85_DNRM] [real] NULL,
[HR90_DNRM] [real] NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_HERT]
   ON  [dbo].[Heart_Zone]
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
                    AND F.HERT_RWNO_DNRM = D.RWNO
                    AND D.RECT_CODE = '004')
      RETURN;

   DECLARE C#ADEL_HERT CURSOR FOR
      SELECT DISTINCT FIGH_FILE_NO
      FROM DELETED D;
   
   DECLARE @FILENO BIGINT;
   OPEN C#ADEL_HERT;
   L$NextRow:
   FETCH NEXT FROM C#ADEL_HERT INTO @FILENO;
   
   -- Fetch Next Row Is Failed
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
   
   -- اگر ردیف فعالی برای ضربان قلب برای این شماره پرونده یافت نشد مقدار دینرمال باید درجدول اصلی خالی شود
   IF NOT EXISTS(
      SELECT 
            C.FIGH_FILE_NO, 
            C.RWNO
        FROM dbo.Heart_Zone C, Deleted D
       WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO AND
             C.FIGH_FILE_NO = @FILENO        AND
             C.RECT_CODE    = D.RECT_CODE    AND
             C.RECT_CODE    = '004'          AND
             C.RWNO  NOT IN (SELECT D.RWNO FROM Deleted D WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO)
   )
   BEGIN
      UPDATE DBO.Fighter
         SET HERT_RWNO_DNRM = NULL
       WHERE FILE_NO = @FILENO;
       GOTO L$NextRow;
   END   
   
   MERGE dbo.Fighter T
   USING (SELECT TOP 1 
            C.FIGH_FILE_NO, 
            C.RWNO             
            FROM dbo.Heart_Zone C, Deleted D
           WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO AND
                 C.FIGH_FILE_NO = @FILENO        AND
                 C.RECT_CODE    = D.RECT_CODE    AND
                 C.RECT_CODE    = '004'          AND
                 C.RWNO  NOT IN (SELECT D.RWNO FROM Deleted D WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO)
           ORDER BY C.RWNO DESC) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO)
   WHEN MATCHED THEN
      UPDATE 
         SET HERT_RWNO_DNRM = S.RWNO;
         
   GOTO L$NextRow;
   L$EndFetch:
   CLOSE C#ADEL_HERT;
   DEALLOCATE C#ADEL_HERT;         
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CG$AINS_HERT]
   ON  [dbo].[Heart_Zone]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Heart_Zone T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
       T.RECT_CODE      = S.RECT_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM HEART_ZONE WHERE FIGH_FILE_NO = S.FIGH_FILE_NO AND RECT_CODE = S.RECT_CODE/*RQRO_RQST_RQID < S.RQRO_RQST_RQID*/)
            ,AGE_DNRM  = CASE
                           WHEN S.AGE_DNRM IS NULL OR S.AGE_DNRM = 0 THEN (SELECT DATEDIFF(YEAR, BRTH_DATE_DNRM, GETDATE()) FROM dbo.Fighter WHERE File_No = S.FIGH_FILE_NO)
                           ELSE S.AGE_DNRM
                         END;

END;

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CG$AUPD_HERT]
   ON  [dbo].[Heart_Zone]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Heart_Zone T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
       T.RWNO           = S.RWNO           AND
       T.RECT_CODE      = S.RECT_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY             = UPPER(SUSER_NAME())
            ,MDFY_DATE           = GETDATE()
            ,MAX_HERT_RATE_DNRM  =   217 - (S.AGE_DNRM * 0.85)
            ,WORK_HERT_RATE_DNRM = ( 217 - (S.AGE_DNRM * 0.85)) - S.REST_HERT_RATE
            ,HR60_DNRM           = ((217 - (S.AGE_DNRM * 0.85)) - S.REST_HERT_RATE) * 0.60 + S.REST_HERT_RATE
            ,HR70_DNRM           = ((217 - (S.AGE_DNRM * 0.85)) - S.REST_HERT_RATE) * 0.70 + S.REST_HERT_RATE
            ,HR80_DNRM           = ((217 - (S.AGE_DNRM * 0.85)) - S.REST_HERT_RATE) * 0.80 + S.REST_HERT_RATE
            ,HR85_DNRM           = ((217 - (S.AGE_DNRM * 0.85)) - S.REST_HERT_RATE) * 0.85 + S.REST_HERT_RATE
            ,HR90_DNRM           = ((217 - (S.AGE_DNRM * 0.85)) - S.REST_HERT_RATE) * 0.90 + S.REST_HERT_RATE;

   -- UPDATE FIGHTER TABLE
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED I 
           WHERE I.RWNO = (SELECT MAX(RWNO) FROM HEART_ZONE M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET HERT_RWNO_DNRM = S.RWNO;
END
;

GO
ALTER TABLE [dbo].[Heart_Zone] ADD CONSTRAINT [CK_HERT_RECT_CODE] CHECK (([RECT_CODE]='004' OR [RECT_CODE]='003' OR [RECT_CODE]='002' OR [RECT_CODE]='001'))
GO
ALTER TABLE [dbo].[Heart_Zone] ADD CONSTRAINT [HERT_PK] PRIMARY KEY CLUSTERED  ([FIGH_FILE_NO], [RWNO], [RECT_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Heart_Zone] ADD CONSTRAINT [FK_HERT_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Heart_Zone] ADD CONSTRAINT [FK_HERT_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO]) ON DELETE SET NULL
GO
