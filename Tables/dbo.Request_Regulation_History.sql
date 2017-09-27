CREATE TABLE [dbo].[Request_Regulation_History]
(
[RQST_RQID] [bigint] NOT NULL,
[RWNO] [smallint] NOT NULL CONSTRAINT [DF_RRHI_RWNO] DEFAULT ((0)),
[REGL_YEAR] [smallint] NOT NULL,
[REGL_CODE] [int] NOT NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [BLOB]
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
CREATE TRIGGER [dbo].[CG$AINS_RRHI]
   ON  [dbo].[Request_Regulation_History]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Request_Regulation_History T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQST_RQID = S.RQST_RQID AND
       T.REGL_YEAR = S.REGL_YEAR AND
       T.REGL_CODE = S.REGL_CODE)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,RWNO      = (SELECT COUNT(*) + 1 FROM Request_Regulation_History WHERE RQST_RQID = S.RQST_RQID);
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
CREATE TRIGGER [dbo].[CG$AUPD_RRHI]
   ON  [dbo].[Request_Regulation_History]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Request_Regulation_History T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQST_RQID = S.RQST_RQID AND
       T.REGL_YEAR = S.REGL_YEAR AND
       T.REGL_CODE = S.REGL_CODE AND
       T.RWNO      = S.RWNO)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
            
END
GO
ALTER TABLE [dbo].[Request_Regulation_History] ADD CONSTRAINT [RRHI_PK] PRIMARY KEY CLUSTERED  ([RQST_RQID], [RWNO], [REGL_YEAR], [REGL_CODE]) ON [BLOB]
GO
ALTER TABLE [dbo].[Request_Regulation_History] WITH NOCHECK ADD CONSTRAINT [FK_RRHI_REGL] FOREIGN KEY ([REGL_YEAR], [REGL_CODE]) REFERENCES [dbo].[Regulation] ([YEAR], [CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Request_Regulation_History] WITH NOCHECK ADD CONSTRAINT [FK_RRHI_RQST] FOREIGN KEY ([RQST_RQID]) REFERENCES [dbo].[Request] ([RQID]) ON DELETE CASCADE NOT FOR REPLICATION
GO
ALTER TABLE [dbo].[Request_Regulation_History] NOCHECK CONSTRAINT [FK_RRHI_REGL]
GO
ALTER TABLE [dbo].[Request_Regulation_History] NOCHECK CONSTRAINT [FK_RRHI_RQST]
GO
