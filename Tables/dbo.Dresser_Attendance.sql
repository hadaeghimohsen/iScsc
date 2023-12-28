CREATE TABLE [dbo].[Dresser_Attendance]
(
[DRES_CODE] [bigint] NULL,
[ATTN_CODE] [bigint] NULL,
[AODT_AGOP_CODE] [bigint] NULL,
[AODT_RWNO] [int] NULL,
[FIGH_FILE_NO] [bigint] NULL,
[MBSP_RWNO] [smallint] NULL,
[MBSP_RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQST_RQID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[DERS_NUMB] [int] NULL,
[ATTN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LEND_TIME] [time] (0) NULL,
[TKBK_TIME] [time] (0) NULL,
[CONF_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TOTL_MINT] [int] NULL,
[TOTL_HOUR] [int] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_DRAT]
   ON  [dbo].[Dresser_Attendance]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Dresser_Attendance T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE = S.CODE /*AND
       T.DRES_CODE = S.DRES_CODE AND
       T.ATTN_CODE = S.ATTN_CODE*/)
   WHEN MATCHED THEN
      UPDATE 
         SET T.CRET_BY   = UPPER(SUSER_NAME())
            ,T.CRET_DATE = GETDATE()
            ,T.CODE = CASE s.CODE WHEN 0 THEN dbo.Gnrt_Nvid_U() ELSE s.CODE END
            ,T.CONF_STAT = ISNULL(S.CONF_STAT, '001')
            ,T.LEND_TIME = GETDATE()
            ,T.DRES_CODE = CASE 
                             WHEN s.DRES_CODE IS NULL AND ISNULL(S.DERS_NUMB, 0) != 0 THEN
                                (SELECT d.CODE
                                  FROM dbo.Dresser d
                                 WHERE d.DRES_NUMB = s.DERS_NUMB)
                             ELSE s.DRES_CODE
                           END;
                           
   -- 1402/08/19 * ثبت کردن تعداد باز کردن کمد مشتری
   ALTER TABLE dbo.Attendance DISABLE TRIGGER [CG$AUPD_ATTN];
   MERGE dbo.Attendance T
   USING (SELECT * FROM Inserted i) S
   ON (T.CODE = S.ATTN_CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.NUMB_OPEN_DNRM = (SELECT COUNT(*) FROM dbo.Dresser_Attendance a WHERE a.ATTN_CODE = s.ATTN_CODE);
   ALTER TABLE dbo.Attendance ENABLE TRIGGER [CG$AUPD_ATTN];   
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_DRAT]
   ON  [dbo].[Dresser_Attendance]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Dresser_Attendance T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE = S.CODE /*AND
       T.DRES_CODE = S.DRES_CODE AND
       T.ATTN_CODE = S.ATTN_CODE*/)
   WHEN MATCHED THEN
      UPDATE 
         SET T.MDFY_BY   = UPPER(SUSER_NAME())
            ,T.MDFY_DATE = GETDATE()
            ,T.TOTL_MINT = DATEDIFF(MINUTE, S.LEND_TIME, S.TKBK_TIME) % 60
            ,T.TOTL_HOUR = DATEDIFF(HOUR, S.LEND_TIME, S.TKBK_TIME);
END;
GO
ALTER TABLE [dbo].[Dresser_Attendance] ADD CONSTRAINT [PK_DRAT] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Dresser_Attendance] ADD CONSTRAINT [FK_DART_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Dresser_Attendance] ADD CONSTRAINT [FK_DRAT_AODT] FOREIGN KEY ([AODT_AGOP_CODE], [AODT_RWNO]) REFERENCES [dbo].[Aggregation_Operation_Detail] ([AGOP_CODE], [RWNO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Dresser_Attendance] ADD CONSTRAINT [FK_DRAT_ATTN] FOREIGN KEY ([ATTN_CODE]) REFERENCES [dbo].[Attendance] ([CODE])
GO
ALTER TABLE [dbo].[Dresser_Attendance] ADD CONSTRAINT [FK_DRAT_DRES] FOREIGN KEY ([DRES_CODE]) REFERENCES [dbo].[Dresser] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Dresser_Attendance] ADD CONSTRAINT [FK_DRAT_MBSP] FOREIGN KEY ([FIGH_FILE_NO], [MBSP_RWNO], [MBSP_RECT_CODE]) REFERENCES [dbo].[Member_Ship] ([FIGH_FILE_NO], [RWNO], [RECT_CODE])
GO
ALTER TABLE [dbo].[Dresser_Attendance] ADD CONSTRAINT [FK_DRAT_RQST] FOREIGN KEY ([RQST_RQID]) REFERENCES [dbo].[Request] ([RQID]) ON DELETE CASCADE
GO
