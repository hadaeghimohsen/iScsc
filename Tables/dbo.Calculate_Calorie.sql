CREATE TABLE [dbo].[Calculate_Calorie]
(
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[FIGH_FILE_NO] [bigint] NOT NULL,
[RWNO] [bigint] NOT NULL CONSTRAINT [DF_CLCL_RWNO] DEFAULT ((0)),
[RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[HEGH] [real] NULL,
[WEGH] [smallint] NULL,
[TRAN_TIME] [int] NULL,
[BASC_ENRG_DNRM] [real] NULL,
[EXTR_ENRG_DNRM] [real] NULL,
[TOTL_ENRG_DNRM] [real] NULL,
[CARB_ENRG_DNRM] [real] NULL,
[FAT_ENRG_DNRM] [real] NULL,
[PROT_ENRG_DNRM] [real] NULL,
[BMI_DNRM] [real] NULL,
[BMI_RSLT_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_CLCL_BMI_RSLT_DNRM] DEFAULT ('001'),
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
CREATE TRIGGER [dbo].[CG$ADEL_CLCL]
   ON  [dbo].[Calculate_Calorie]
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
                    AND F.CLCL_RWNO_DNRM = D.RWNO
                    AND D.RECT_CODE = '004')
      RETURN;
   
   DECLARE C#ADEL_CLCL CURSOR FOR
      SELECT DISTINCT FIGH_FILE_NO
      FROM DELETED D;
   
   DECLARE @FILENO BIGINT;
   OPEN C#ADEL_CLCL;
   L$NextRow:
   FETCH NEXT FROM C#ADEL_CLCL INTO @FILENO;
   
   -- Fetch Next Row Is Failed
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;

   -- اگر ردیف فعالی برای محاسبه کالری برای این شماره پرونده یافت نشد مقدار دینرمال باید درجدول اصلی خالی شود
   IF NOT EXISTS(
      SELECT 
            C.FIGH_FILE_NO, 
            C.RWNO
        FROM dbo.Calculate_Calorie C, Deleted D
       WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO AND
             C.FIGH_FILE_NO = @FILENO        AND
             C.RECT_CODE    = D.RECT_CODE    AND
             C.RECT_CODE    = '004'          AND
             C.RWNO  NOT IN (SELECT D.RWNO FROM Deleted D WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO)
   )
   BEGIN
      UPDATE DBO.Fighter
         SET CLCL_RWNO_DNRM = NULL
       WHERE FILE_NO = @FILENO;
       GOTO L$NextRow;
   END
   
   MERGE dbo.Fighter T
   USING (SELECT TOP 1
            C.FIGH_FILE_NO, 
            C.RWNO
            FROM dbo.Calculate_Calorie C, Deleted D
           WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO AND
                 C.FIGH_FILE_NO = @FILENO        AND
                 C.RECT_CODE    = D.RECT_CODE    AND
                 C.RECT_CODE    = '004'          AND
                 C.RWNO  NOT IN (SELECT D.RWNO FROM Deleted D WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO)
           ORDER BY C.RWNO DESC) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO)
   WHEN MATCHED THEN
      UPDATE 
         SET CLCL_RWNO_DNRM = S.RWNO;
   
   GOTO L$NextRow;
   L$EndFetch:
   CLOSE C#ADEL_CLCL;
   DEALLOCATE C#ADEL_CLCL;
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_CLCL]
   ON  [dbo].[Calculate_Calorie]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   
   MERGE dbo.Calculate_Calorie T
   USING (SELECT * FROM INSERTED i) S
   ON (T.Rqro_Rqst_Rqid = S.Rqro_Rqst_Rqid AND
       T.Rqro_Rwno      = S.Rqro_Rwno AND
       T.Figh_File_No   = S.Figh_File_No AND
       T.Rect_Code      = S.Rect_Code)
   WHEN MATCHED THEN
      UPDATE 
      SET CRET_BY   = UPPER(SUSER_NAME())
         ,CRET_DATE = GETDATE()
         ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM Calculate_Calorie WHERE FIGH_FILE_NO = S.FIGH_FILE_NO AND RECT_CODE = S.RECT_CODE/*RQRO_RQST_RQID < S.RQRO_RQST_RQID*/)
         ;

END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_CLCL]
   ON  [dbo].[Calculate_Calorie]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   
   MERGE dbo.Calculate_Calorie T
   USING (SELECT * FROM INSERTED i) S
   ON (T.Rqro_Rqst_Rqid = S.Rqro_Rqst_Rqid AND
       T.Rqro_Rwno      = S.Rqro_Rwno AND
       T.Figh_File_No   = S.Figh_File_No AND
       T.Rect_Code      = S.Rect_Code AND
       T.RWNO           = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
      SET MDFY_BY        = UPPER(SUSER_NAME())
         ,MDFY_DATE      = GETDATE()
         ,BASC_ENRG_DNRM = S.WEGH * 24 * 1.3
         ,EXTR_ENRG_DNRM = (S.TRAN_TIME / 60) * S.WEGH * 8.5
         ,TOTL_ENRG_DNRM = (S.WEGH * 24 * 1.3) + ((S.TRAN_TIME / 60) * S.WEGH * 8.5)
         ,CARB_ENRG_DNRM = ((S.WEGH * 24 * 1.3) + ((S.TRAN_TIME / 60) * S.WEGH * 8.5)) * 0.57 / 4
         ,FAT_ENRG_DNRM  = ((S.WEGH * 24 * 1.3) + ((S.TRAN_TIME / 60) * S.WEGH * 8.5)) * 0.3 / 9
         ,PROT_ENRG_DNRM = ((S.WEGH * 24 * 1.3) + ((S.TRAN_TIME / 60) * S.WEGH * 8.5)) * 0.13 / 4
         ,BMI_DNRM       = S.WEGH / POWER(S.HEGH / 100, 2)
         ,BMI_RSLT_DNRM  = CASE 
                            WHEN S.WEGH / POWER(S.HEGH / 100, 2) BETWEEN 0    AND 19.8 THEN '001'
                            WHEN S.WEGH / POWER(S.HEGH / 100, 2) BETWEEN 19.9 AND 26   THEN '002'
                            WHEN S.WEGH / POWER(S.HEGH / 100, 2) BETWEEN 26.1 AND 29   THEN '003'
                            ELSE '004'
                            END;

   -- UPDATE FIGHTER TABLE
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED I 
           WHERE I.RWNO = (SELECT MAX(RWNO) FROM CALCULATE_CALORIE M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET CLCL_RWNO_DNRM = S.RWNO;
END
;
GO
ALTER TABLE [dbo].[Calculate_Calorie] ADD CONSTRAINT [CK_CLCL_BMI_RSLT] CHECK (([BMI_RSLT_DNRM]='004' OR [BMI_RSLT_DNRM]='003' OR [BMI_RSLT_DNRM]='002' OR [BMI_RSLT_DNRM]='001'))
GO
ALTER TABLE [dbo].[Calculate_Calorie] ADD CONSTRAINT [CK_CLCL_RECT_CODE] CHECK (([RECT_CODE]='004' OR [RECT_CODE]='003' OR [RECT_CODE]='002' OR [RECT_CODE]='001'))
GO
ALTER TABLE [dbo].[Calculate_Calorie] ADD CONSTRAINT [CLCL_PK] PRIMARY KEY CLUSTERED  ([FIGH_FILE_NO], [RWNO], [RECT_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Calculate_Calorie] ADD CONSTRAINT [FK_CLCL_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Calculate_Calorie] ADD CONSTRAINT [FK_CLCL_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO])
GO
EXEC sp_addextendedproperty N'MS_Description', N'CLCL', 'SCHEMA', N'dbo', 'TABLE', N'Calculate_Calorie', NULL, NULL
GO
