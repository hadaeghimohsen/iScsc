CREATE TABLE [dbo].[Statistic_Detail_Request]
(
[STSD_CODE] [bigint] NULL,
[RQST_RQID] [bigint] NULL,
[CODE] [bigint] NOT NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SDRQ]
   ON  [dbo].[Statistic_Detail_Request]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- Insert statements for trigger here
   MERGE dbo.Statistic_Detail_Request T
   USING (SELECT * FROM Inserted) S
   ON (T.STSD_CODE = S.STSD_CODE AND 
       T.RQST_RQID = S.RQST_RQID AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;
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
CREATE TRIGGER [dbo].[CG$AUPD_SDRQ]
   ON  [dbo].[Statistic_Detail_Request]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Statistic_Detail_Request T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Statistic_Detail_Request] ADD CONSTRAINT [PK_SDRQ] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Statistic_Detail_Request] ADD CONSTRAINT [FK_SDRQ_RQST] FOREIGN KEY ([RQST_RQID]) REFERENCES [dbo].[Request] ([RQID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Statistic_Detail_Request] ADD CONSTRAINT [FK_SDRQ_STSD] FOREIGN KEY ([STSD_CODE]) REFERENCES [dbo].[Statistic_Detail] ([CODE]) ON DELETE CASCADE
GO
