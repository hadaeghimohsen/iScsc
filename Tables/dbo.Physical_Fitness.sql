CREATE TABLE [dbo].[Physical_Fitness]
(
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[FIGH_FILE_NO] [bigint] NOT NULL,
[RWNO] [bigint] NOT NULL CONSTRAINT [DF_PSFN_RWNO] DEFAULT ((0)),
[RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PULL_UP] [real] NULL,
[PUSH_UP] [real] NULL,
[SQUT_TRST] [real] NULL,
[SQUT_JUMP] [real] NULL,
[SIT_UP] [real] NULL,
[PHSC_FITN_INDX_DNRM] [real] NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_PSFN]
   ON  [dbo].[Physical_Fitness]
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

   DECLARE C#ADEL_PSFN CURSOR FOR
      SELECT DISTINCT FIGH_FILE_NO
      FROM DELETED D;

   DECLARE @FILENO BIGINT;
   OPEN C#ADEL_PSFN;
   L$NextRow:
   FETCH NEXT FROM C#ADEL_PSFN INTO @FILENO;
   
   -- Fetch Next Row Is Failed
   IF @@FETCH_STATUS <> 0
      GOTO L$EndFetch;
   
   -- اگر ردیف فعالی برای امادگی جسمانی برای این شماره پرونده یافت نشد مقدار دینرمال باید درجدول اصلی خالی شود
   IF NOT EXISTS(
      SELECT 
            C.FIGH_FILE_NO, 
            C.RWNO
        FROM dbo.Physical_Fitness C, Deleted D
       WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO AND
             C.FIGH_FILE_NO = @FILENO        AND
             C.RECT_CODE    = D.RECT_CODE    AND
             C.RECT_CODE    = '004'          AND
             C.RWNO  NOT IN (SELECT D.RWNO FROM Deleted D WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO)
   )
   BEGIN
      UPDATE DBO.Fighter
         SET PSFN_RWNO_DNRM = NULL
       WHERE FILE_NO = @FILENO;
       GOTO L$NextRow;
   END
         
   MERGE dbo.Fighter T
   USING (SELECT TOP 1 
            C.FIGH_FILE_NO, 
            C.RWNO
            FROM dbo.Physical_Fitness C, Deleted D
           WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO AND
                 C.FIGH_FILE_NO = @FILENO        AND
                 C.RECT_CODE    = D.RECT_CODE    AND
                 C.RECT_CODE    = '004'          AND
                 C.RWNO  NOT IN (SELECT D.RWNO FROM Deleted D WHERE C.FIGH_FILE_NO = D.FIGH_FILE_NO)
           ORDER BY C.RWNO DESC) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO)
   WHEN MATCHED THEN
      UPDATE 
         SET PSFN_RWNO_DNRM = S.RWNO;
         
   GOTO L$NextRow;
   L$EndFetch:
   CLOSE C#ADEL_PSFN;
   DEALLOCATE C#ADEL_PSFN;
END


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CG$AINS_PSFN]
   ON  [dbo].[Physical_Fitness]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Physical_Fitness T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
       T.RECT_CODE      = S.RECT_CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY             = UPPER(SUSER_NAME())
            ,CRET_DATE           = GETDATE()
            ,RWNO                = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM PHYSICAL_FITNESS WHERE FIGH_FILE_NO = S.FIGH_FILE_NO AND RQRO_RQST_RQID < S.RQRO_RQST_RQID)
            ;

END
;

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CG$AUPD_PSFN]
   ON  [dbo].[Physical_Fitness]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Physical_Fitness T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO      = S.RQRO_RWNO      AND
       T.FIGH_FILE_NO   = S.FIGH_FILE_NO   AND
       T.RWNO           = S.RWNO           AND
       T.RECT_CODE      = S.RECT_CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY             = UPPER(SUSER_NAME())
            ,MDFY_DATE           = GETDATE()
            ,PHSC_FITN_INDX_DNRM = (S.PULL_UP + S.PUSH_UP + S.SQUT_TRST + S.SQUT_JUMP + S.SIT_UP) / 5;

   -- UPDATE FIGHTER TABLE
   MERGE dbo.Fighter T
   USING (SELECT * FROM INSERTED I 
           WHERE I.RWNO = (SELECT MAX(RWNO) FROM PHYSICAL_FITNESS M 
                            WHERE M.FIGH_FILE_NO = I.FIGH_FILE_NO AND 
                                  M.RECT_CODE    = '004')) S
   ON (T.FILE_NO   = S.FIGH_FILE_NO AND
       S.RECT_CODE = '004')
   WHEN MATCHED THEN
      UPDATE 
         SET PSFN_RWNO_DNRM = S.RWNO;
END
;

GO
ALTER TABLE [dbo].[Physical_Fitness] ADD CONSTRAINT [CK_PSFN_RECT_CODE] CHECK (([RECT_CODE]='004' OR [RECT_CODE]='003' OR [RECT_CODE]='002' OR [RECT_CODE]='001'))
GO
ALTER TABLE [dbo].[Physical_Fitness] ADD CONSTRAINT [PSFN_PK] PRIMARY KEY CLUSTERED  ([FIGH_FILE_NO], [RWNO], [RECT_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Physical_Fitness] ADD CONSTRAINT [FK_PSFN_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Physical_Fitness] ADD CONSTRAINT [FK_PSFN_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO]) ON DELETE SET NULL
GO
