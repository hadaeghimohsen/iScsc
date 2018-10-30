CREATE TABLE [dbo].[Aggregation_Operation_Detail]
(
[AGOP_CODE] [bigint] NOT NULL,
[RWNO] [int] NOT NULL,
[AODT_AGOP_CODE] [bigint] NULL,
[AODT_RWNO] [int] NULL,
[FIGH_FILE_NO] [bigint] NULL,
[RQST_RQID] [bigint] NULL,
[ATTN_CODE] [bigint] NULL,
[COCH_FILE_NO] [bigint] NULL,
[MBSP_RWNO] [smallint] NULL,
[ATTN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEBT_AMNT] [bigint] NULL,
[REC_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Aggregation_Operation_Detail_REC_STAT] DEFAULT ('002'),
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Aggregation_Operation_Detail_STAT] DEFAULT ('001'),
[EXPN_CODE] [bigint] NULL,
[MIN_MINT_STEP] [time] (0) NULL,
[STRT_TIME] [datetime] NULL,
[END_TIME] [datetime] NULL,
[TOTL_MINT_DNRM] [int] NULL,
[EXPN_PRIC] [int] NULL,
[EXPN_EXTR_PRCT] [int] NULL,
[REMN_PRIC] [int] NULL,
[TOTL_BUFE_AMNT_DNRM] [bigint] NULL,
[NUMB] [int] NULL CONSTRAINT [DF_Aggregation_Operation_Detail_NUMB] DEFAULT ((1)),
[TOTL_AMNT_DNRM] [bigint] NULL,
[CUST_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CASH_AMNT] [bigint] NULL,
[POS_AMNT] [bigint] NULL,
[AODT_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_APDT]
   ON  [dbo].[Aggregation_Operation_Detail]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Aggregation_Operation_Detail T
   USING (SELECT * FROM INSERTED) S
   ON (T.AGOP_CODE = S.Agop_Code AND
       --T.FIGH_FILE_NO = S.Figh_File_No AND
       T.RWNO      = S.Rwno)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,DEBT_AMNT = (SELECT DEBT_DNRM FROM dbo.Fighter WHERE FILE_NO = S.Figh_File_No)
            ,RWNO = (
               SELECT ISNULL(MAX(RWNO), 0) + 1
                 FROM dbo.Aggregation_Operation_Detail
                WHERE AGOP_CODE = S.Agop_Code
            );
   
   -- *** Create Request
   DECLARE @X XML;
   SELECT @X =(
       SELECT i.Agop_Code AS '@agopcode'
             ,i.figh_File_No AS '@fighfileno'
             ,(SELECT MAX(RWNO)
                 FROM dbo.Aggregation_Operation_Detail
                WHERE AGOP_CODE = i.Agop_Code
                  AND FIGH_FILE_NO = i.FIGH_FILE_NO) AS '@rwno'
         FROM INSERTED i
       FOR XML PATH('Aodt'), ROOT('Agop')
   );
   EXEC AGOP_CRQT_P @X;
END
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
CREATE TRIGGER [dbo].[CG$AUPD_APDT]
   ON  [dbo].[Aggregation_Operation_Detail]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Aggregation_Operation_Detail T
   USING (SELECT * FROM INSERTED) S
   ON (T.AGOP_CODE = S.Agop_Code AND
       T.FIGH_FILE_NO = S.Figh_File_No AND
       T.RWNO = S.Rwno)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,DEBT_AMNT = (SELECT DEBT_DNRM FROM dbo.Fighter WHERE FILE_NO = S.Figh_File_No)
            ,STAT = CASE S.REC_STAT
                        WHEN '001' THEN '003'
                        WHEN '002' THEN T.STAT
                    END
            ,TOTL_MINT_DNRM = CASE 
                                 WHEN S.END_TIME IS NOT NULL THEN
                                    CASE 
                                       WHEN DATEDIFF(MINUTE, S.STRT_TIME, S.END_TIME) % DATEDIFF(MINUTE, '00:00:00', S.MIN_MINT_STEP) = 0 THEN DATEDIFF(MINUTE, S.STRT_TIME, S.END_TIME)
                                       ELSE ( DATEDIFF(MINUTE, S.STRT_TIME, S.END_TIME) + ( DATEDIFF(MINUTE, '00:00:00', S.MIN_MINT_STEP) - (DATEDIFF(MINUTE, S.STRT_TIME, S.END_TIME) % DATEDIFF(MINUTE, '00:00:00', S.MIN_MINT_STEP))) )
                                    END
                                 ELSE NULL
                              END;
   
   --IF EXISTS (SELECT * FROM INSERTED WHERE REC_STAT = '001' AND STAT = '003')
   --BEGIN
   --   delete dbo.Aggregation_Operation_Detail
   --    WHERE EXISTS(
   --      select *
   --        from INSERTED s
   --       where Aggregation_Operation_Detail.AGOP_CODE = s.agop_code
   --         and Aggregation_Operation_Detail.RWNO = s.rwno
   --    );
   --    RETURN;
   --END
   -- ثبت مبلغ هزینه رزرو میز   
   UPDATE T
      SET T.TOTL_AMNT_DNRM = ISNULL(T.TOTL_BUFE_AMNT_DNRM, 0)
    FROM dbo.Aggregation_Operation_Detail T, INSERTED S
    WHERE T.AGOP_CODE = S.Agop_Code 
      AND T.FIGH_FILE_NO = S.Figh_File_No
      AND T.RWNO = S.Rwno
      AND T.EXPN_CODE IS NULL; 
   
   IF @@ROWCOUNT = 0
      UPDATE T
         SET T.TOTL_AMNT_DNRM = ISNULL(T.TOTL_BUFE_AMNT_DNRM, 0) + ISNULL(T.NUMB, 1) * ( ISNULL(T.EXPN_PRIC, 0) + ISNULL(T.EXPN_EXTR_PRCT, 0) )
        FROM dbo.Aggregation_Operation_Detail T, INSERTED S
       WHERE T.AGOP_CODE = S.Agop_Code 
         AND T.FIGH_FILE_NO = S.Figh_File_No
         AND T.RWNO = S.Rwno
         AND T.EXPN_CODE IS NOT NULL; 
   
   -- 1395/12/27 * آیا مبلغ نقدی داشته است
   --IF EXISTS(
   --   SELECT *
   --     FROM Inserted S
   --    WHERE ISNULL(S.CASH_AMNT, 0) <> (
   --         SELECT SUM(ISNULL(AMNT, 0))
   --           FROM dbo.Payment_Row_Type
   --          WHERE S.AGOP_CODE = APDT_AGOP_CODE
   --            AND S.RWNO = APDT_RWNO
   --            AND RCPT_MTOD = '001' -- پرداخت نقدی
   --      )
   --)
   --BEGIN
   --   DELETE dbo.Payment_Row_Type
   --    WHERE EXISTS(
   --      SELECT *
   --        FROM Inserted S
   --       WHERE s.AGOP_CODE = APDT_AGOP_CODE
   --         AND s.RWNO = APDT_RWNO
   --         AND RCPT_MTOD = '001'
   --    );
   --   INSERT INTO dbo.Payment_Row_Type( APDT_AGOP_CODE ,APDT_RWNO ,CODE ,AMNT ,RCPT_MTOD ,ACTN_DATE )
   --   SELECT s.AGOP_CODE, s.RWNO, 0, s.CASH_AMNT, '001', GETDATE()
   --     FROM Inserted s;
   --END
   
   -- 1395/12/27 * آیا مبلغ کارتی داشته است
   --ELSE IF EXISTS(
   --   SELECT *
   --     FROM Inserted S
   --    WHERE ISNULL(S.POS_AMNT, 0) <> (
   --         SELECT SUM(ISNULL(AMNT, 0))
   --           FROM dbo.Payment_Row_Type
   --          WHERE S.AGOP_CODE = APDT_AGOP_CODE
   --            AND S.RWNO = APDT_RWNO
   --            AND RCPT_MTOD = '003' -- پرداخت کارتی
   --      )
   --)
   --BEGIN
   --   DELETE dbo.Payment_Row_Type
   --    WHERE EXISTS(
   --      SELECT *
   --        FROM Inserted S
   --       WHERE s.AGOP_CODE = APDT_AGOP_CODE
   --         AND s.RWNO = APDT_RWNO
   --         AND RCPT_MTOD = '003'
   --    );
   --   INSERT INTO dbo.Payment_Row_Type( APDT_AGOP_CODE ,APDT_RWNO ,CODE ,AMNT ,RCPT_MTOD ,ACTN_DATE )
   --   SELECT s.AGOP_CODE, s.RWNO, 0, s.POS_AMNT, '003', GETDATE()
   --     FROM Inserted s;
   --END
END
GO
ALTER TABLE [dbo].[Aggregation_Operation_Detail] ADD CONSTRAINT [PK_AODT] PRIMARY KEY CLUSTERED  ([AGOP_CODE], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Aggregation_Operation_Detail] ADD CONSTRAINT [FK_AODT_AGOP] FOREIGN KEY ([AGOP_CODE]) REFERENCES [dbo].[Aggregation_Operation] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Aggregation_Operation_Detail] ADD CONSTRAINT [FK_AODT_AODT] FOREIGN KEY ([AODT_AGOP_CODE], [AODT_RWNO]) REFERENCES [dbo].[Aggregation_Operation_Detail] ([AGOP_CODE], [RWNO])
GO
ALTER TABLE [dbo].[Aggregation_Operation_Detail] ADD CONSTRAINT [FK_AODT_ATTN] FOREIGN KEY ([ATTN_CODE]) REFERENCES [dbo].[Attendance] ([CODE])
GO
ALTER TABLE [dbo].[Aggregation_Operation_Detail] ADD CONSTRAINT [FK_AODT_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Aggregation_Operation_Detail] ADD CONSTRAINT [FK_AODT_RQST] FOREIGN KEY ([RQST_RQID]) REFERENCES [dbo].[Request] ([RQID])
GO
ALTER TABLE [dbo].[Aggregation_Operation_Detail] ADD CONSTRAINT [FK_APDT_EXPN] FOREIGN KEY ([EXPN_CODE]) REFERENCES [dbo].[Expense] ([CODE])
GO
EXEC sp_addextendedproperty N'MS_Description', N'میزان مبلغ نقدی', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation_Detail', 'COLUMN', N'CASH_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمان پایان', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation_Detail', 'COLUMN', N'END_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آیتم میز رزرو شده', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation_Detail', 'COLUMN', N'EXPN_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ارزش افزوده قیمت میز', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation_Detail', 'COLUMN', N'EXPN_EXTR_PRCT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ قیمت میز', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation_Detail', 'COLUMN', N'EXPN_PRIC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'حداقل میزان زمان برای بازی', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation_Detail', 'COLUMN', N'MIN_MINT_STEP'
GO
EXEC sp_addextendedproperty N'MS_Description', N'میزان مبلغ کارتی', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation_Detail', 'COLUMN', N'POS_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کسر هزار ریال', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation_Detail', 'COLUMN', N'REMN_PRIC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت پایانی بودن شماره پرونده', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation_Detail', 'COLUMN', N'STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمان شروع', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation_Detail', 'COLUMN', N'STRT_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کل مبلغ', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation_Detail', 'COLUMN', N'TOTL_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ هزینه بوفه', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation_Detail', 'COLUMN', N'TOTL_BUFE_AMNT_DNRM'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کل دقایق', 'SCHEMA', N'dbo', 'TABLE', N'Aggregation_Operation_Detail', 'COLUMN', N'TOTL_MINT_DNRM'
GO
