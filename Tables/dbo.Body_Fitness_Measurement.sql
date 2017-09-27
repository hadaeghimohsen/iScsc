CREATE TABLE [dbo].[Body_Fitness_Measurement]
(
[BDFT_FIGH_FILE_NO] [bigint] NOT NULL,
[BDFT_RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BDFT_RWNO] [int] NOT NULL,
[BODY_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RWNO] [smallint] NOT NULL,
[BDFM_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MESR_VALU] [real] NULL,
[OLD_RWNO] [smallint] NULL,
[OLD_MESR_VALU] [real] NULL,
[MESR_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_BDFM]
   ON  [dbo].[Body_Fitness_Measurement]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here   
   
   MERGE dbo.Body_Fitness_Measurement T
   USING (SELECT * FROM INSERTED i) S
   ON (T.BDFT_FIGH_FILE_NO = S.BDFT_FIGH_FILE_NO AND
       T.BDFT_RECT_CODE    = S.BDFT_RECT_CODE AND
       T.BDFT_RWNO         = S.BDFT_RWNO AND
       T.BODY_TYPE         = S.BODY_TYPE AND
       T.RWNO              = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
      SET CRET_BY   = UPPER(SUSER_NAME())
         ,CRET_DATE = GETDATE()
         ,OLD_RWNO  = (SELECT BDFT_RWNO_DNRM FROM dbo.Fighter WHERE FILE_NO = S.BDFT_FIGH_FILE_NO)
         ,OLD_MESR_VALU = (SELECT A.MESR_VALU 
                             FROM dbo.Body_Fitness_Measurement a, Fighter F 
                            WHERE A.BDFT_FIGH_FILE_NO = F.FILE_NO 
                              AND A.BDFT_FIGH_FILE_NO = S.BDFT_FIGH_FILE_NO 
                              AND A.RWNO = F.BDFT_RWNO_DNRM 
                              AND A.BDFT_RECT_CODE = '004'
                              AND A.BODY_TYPE = S.BODY_TYPE)
         --,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM Body_Fitness_Measurement WHERE BDFT_FIGH_FILE_NO = S.BDFT_FIGH_FILE_NO AND BDFT_RECT_CODE = S.BDFT_RECT_CODE AND BDFT_RWNO = S.BDFT_RWNO AND BODY_TYPE = S.BODY_TYPE AND RWNO = S.RWNO);\
         ,RWNO      = CAST(S.BODY_TYPE AS SMALLINT);
   
   
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_BDFM]
   ON  [dbo].[Body_Fitness_Measurement]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here   
   
   MERGE dbo.Body_Fitness_Measurement T
   USING (SELECT * FROM INSERTED i) S
   ON (T.BDFT_FIGH_FILE_NO = S.BDFT_FIGH_FILE_NO AND
       T.BDFT_RECT_CODE    = S.BDFT_RECT_CODE AND
       T.BDFT_RWNO         = S.BDFT_RWNO AND
       T.BODY_TYPE         = S.BODY_TYPE AND
       T.RWNO              = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
      SET MDFY_BY   = UPPER(SUSER_NAME())
         ,MDFY_DATE = GETDATE()
         ,MESR_STAT = CASE 
                        WHEN ISNULL(S.MESR_VALU, 0) = ISNULL(S.OLD_MESR_VALU, 0) THEN '001' -- تغییری حاصل نشده
                        WHEN ISNULL(S.MESR_VALU, 0) > ISNULL(S.OLD_MESR_VALU, 0) THEN CASE (SELECT EFCT_TYPE FROM dbo.Change_Body_Fitness WHERE BDFT_FIGH_FILE_NO = S.BDFT_FIGH_FILE_NO AND BDFT_RECT_CODE = '004' AND BDFT_RWNO = S.OLD_RWNO)
                                                                                         WHEN '001' THEN '002' -- تغییرات ایجاد شده حالت استیبل را از بین برده
                                                                                         WHEN '002' THEN '003' -- تغییرات ایجاد شده عکس تمرینات به عمل آورده
                                                                                         WHEN '003' THEN '004' -- تبریک!! نتیجه به دست آمده بدرستی انجام پذیرفته
                                                                                       END
                        WHEN ISNULL(S.MESR_VALU, 0) < ISNULL(S.OLD_MESR_VALU, 0) THEN CASE (SELECT EFCT_TYPE FROM dbo.Change_Body_Fitness WHERE BDFT_FIGH_FILE_NO = S.BDFT_FIGH_FILE_NO AND BDFT_RECT_CODE = '004' AND BDFT_RWNO = S.OLD_RWNO)
                                                                                         WHEN '001' THEN '002' -- تغییرات ایجاد شده حالت استیبل را از بین برده
                                                                                         WHEN '002' THEN '004' -- تبریک!! نتیجه به دست آمده بدرستی انجام پذیرفته
                                                                                         WHEN '003' THEN '003' -- تغییرات ایجاد شده عکس تمرینات به عمل آورده
                                                                                       END
                                                                                    
                      END;

END
;
GO
ALTER TABLE [dbo].[Body_Fitness_Measurement] ADD CONSTRAINT [PK_BDFM] PRIMARY KEY CLUSTERED  ([BDFT_FIGH_FILE_NO], [BDFT_RECT_CODE], [BDFT_RWNO], [BODY_TYPE], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Body_Fitness_Measurement] ADD CONSTRAINT [FK_BDFM_BDFT] FOREIGN KEY ([BDFT_FIGH_FILE_NO], [BDFT_RECT_CODE], [BDFT_RWNO]) REFERENCES [dbo].[Body_Fitness] ([FIGH_FILE_NO], [RECT_CODE], [RWNO])
GO
EXEC sp_addextendedproperty N'MS_Description', N'BDFM', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Measurement', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'توضیحات', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Measurement', 'COLUMN', N'BDFM_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره پرونده', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Measurement', 'COLUMN', N'BDFT_FIGH_FILE_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد رکورد', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Measurement', 'COLUMN', N'BDFT_RECT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Measurement', 'COLUMN', N'BDFT_RWNO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع عضو', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Measurement', 'COLUMN', N'BODY_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت تغییرات بدست آماده', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Measurement', 'COLUMN', N'MESR_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'اندازه', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Measurement', 'COLUMN', N'MESR_VALU'
GO
EXEC sp_addextendedproperty N'MS_Description', N'اندازه گیری قبلی', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Measurement', 'COLUMN', N'OLD_MESR_VALU'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Measurement', 'COLUMN', N'RWNO'
GO
