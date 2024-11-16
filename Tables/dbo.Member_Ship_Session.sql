CREATE TABLE [dbo].[Member_Ship_Session]
(
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[MBSP_FIGH_FILE_NO] [bigint] NULL,
[MBSP_RWNO] [smallint] NULL,
[MBSP_RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CODE] [bigint] NOT NULL,
[RWNO] [smallint] NULL,
[SESN_DATE] [date] NULL,
[YEAR_DNRM] [int] NULL,
[CYCL_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WKDY_DNRM] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ATTN_CODE] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_MBSS]
   ON  [dbo].[Member_Ship_Session]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Member_Ship_Session T
   USING (SELECT * FROM inserted) S
   ON (T.MBSP_FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO AND
       T.MBSP_RWNO = S.MBSP_RWNO AND
       T.MBSP_RECT_CODE = S.MBSP_RECT_CODE AND
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         CRET_BY = UPPER(SUSER_NAME()),
         CRET_DATE = GETDATE(),
         CODE = CASE S.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.CODE END,
         RWNO = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Member_Ship_Session T1 WHERE T1.MBSP_FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO AND t1.MBSP_RWNO = s.MBSP_RWNO);
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
CREATE TRIGGER [dbo].[CG$AUPD_MBSS]
   ON  [dbo].[Member_Ship_Session]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Member_Ship_Session T
   USING (SELECT * FROM inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         MDFY_BY = UPPER(SUSER_NAME()),
         MDFY_DATE = GETDATE(),
         YEAR_DNRM = SUBSTRING(dbo.GET_MTOS_U(s.SESN_DATE), 1, 4),
         CYCL_DNRM = dbo.GET_PSTR_U(SUBSTRING(dbo.GET_MTOS_U(s.SESN_DATE), 6, 2), 3),
	      WKDY_DNRM = dbo.GET_PSTR_U(DATEPART(WEEKDAY, s.SESN_DATE), 3);   
END
GO
ALTER TABLE [dbo].[Member_Ship_Session] ADD CONSTRAINT [PK_MBSS] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Member_Ship_Session] ADD CONSTRAINT [FK_MBSS_ATTN] FOREIGN KEY ([ATTN_CODE]) REFERENCES [dbo].[Attendance] ([CODE])
GO
ALTER TABLE [dbo].[Member_Ship_Session] ADD CONSTRAINT [FK_MBSS_MBSP] FOREIGN KEY ([MBSP_FIGH_FILE_NO], [MBSP_RWNO], [MBSP_RECT_CODE]) REFERENCES [dbo].[Member_Ship] ([FIGH_FILE_NO], [RWNO], [RECT_CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Member_Ship_Session] ADD CONSTRAINT [FK_MBSS_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO])
GO
EXEC sp_addextendedproperty N'MS_Description', N'چه تاریخی باید بیاد', 'SCHEMA', N'dbo', 'TABLE', N'Member_Ship_Session', 'COLUMN', N'SESN_DATE'
GO
