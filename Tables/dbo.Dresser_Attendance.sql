CREATE TABLE [dbo].[Dresser_Attendance]
(
[DRES_CODE] [bigint] NULL,
[ATTN_CODE] [bigint] NULL,
[AODT_AGOP_CODE] [bigint] NULL,
[AODT_RWNO] [int] NULL,
[CODE] [bigint] NOT NULL,
[DERS_NUMB] [int] NULL,
[ATTN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LEND_TIME] [time] (0) NULL,
[TKBK_TIME] [time] (0) NULL,
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
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE = dbo.Gnrt_Nvid_U();
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
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
;
GO
ALTER TABLE [dbo].[Dresser_Attendance] ADD CONSTRAINT [PK_DRAT] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Dresser_Attendance] ADD CONSTRAINT [FK_DRAT_AODT] FOREIGN KEY ([AODT_AGOP_CODE], [AODT_RWNO]) REFERENCES [dbo].[Aggregation_Operation_Detail] ([AGOP_CODE], [RWNO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Dresser_Attendance] ADD CONSTRAINT [FK_DRAT_ATTN] FOREIGN KEY ([ATTN_CODE]) REFERENCES [dbo].[Attendance] ([CODE])
GO
ALTER TABLE [dbo].[Dresser_Attendance] ADD CONSTRAINT [FK_DRAT_DRES] FOREIGN KEY ([DRES_CODE]) REFERENCES [dbo].[Dresser] ([CODE])
GO
