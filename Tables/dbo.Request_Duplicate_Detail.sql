CREATE TABLE [dbo].[Request_Duplicate_Detail]
(
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[RQSD_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[CRET_HOST_BY] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[MDFY_HOST_BY] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
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
CREATE TRIGGER [dbo].[CGAINS_RQDD]
   ON  [dbo].[Request_Duplicate_Detail]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Request_Duplicate_Detail T
   USING (SELECT * FROM Inserted) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND
       T.RQRO_RWNO = S.RQRO_RWNO AND 
       T.RQSD_CODE = S.RQSD_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CRET_HOST_BY = dbo.GET_HOST_U(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.STAT = ISNULL(s.STAT , '002');
   

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
CREATE TRIGGER [dbo].[CGAUPD_RQDD]
   ON  [dbo].[Request_Duplicate_Detail]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Request_Duplicate_Detail T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE(),
         T.MDFY_HOST_BY = dbo.GET_HOST_U();
END
GO
ALTER TABLE [dbo].[Request_Duplicate_Detail] ADD CONSTRAINT [PK_RQDD] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Request_Duplicate_Detail] ADD CONSTRAINT [FK_RQDD_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO])
GO
ALTER TABLE [dbo].[Request_Duplicate_Detail] ADD CONSTRAINT [FK_RQDD_RQSD] FOREIGN KEY ([RQSD_CODE]) REFERENCES [dbo].[Request_Duplicate] ([CODE])
GO
