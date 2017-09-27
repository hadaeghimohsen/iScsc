CREATE TABLE [dbo].[Step_History_Summery]
(
[RQST_RQID] [bigint] NOT NULL,
[RWNO] [smallint] NOT NULL CONSTRAINT [DF_SHIS_RWNO] DEFAULT ((0)),
[SSTT_MSTT_CODE] [smallint] NOT NULL,
[SSTT_MSTT_SUB_SYS] [smallint] NOT NULL,
[FROM_DATE] [datetime] NULL,
[TO_DATE] [datetime] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SHIS]
   ON  [dbo].[Step_History_Summery]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Step_History_Summery T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQST_RQID = S.RQST_RQID AND
       T.RWNO      = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,FROM_DATE = GETDATE()
            ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM STEP_HISTORY_SUMMERY WHERE RQST_RQID = S.RQST_RQID);            
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_SHIS]
   ON  [dbo].[Step_History_Summery]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Step_History_Summery T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQST_RQID = S.RQST_RQID AND
       T.RWNO      <= S.RWNO     AND 
       T.TO_DATE IS NULL)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,TO_DATE   = GETDATE();

END
;
GO
ALTER TABLE [dbo].[Step_History_Summery] ADD CONSTRAINT [SHIS_PK] PRIMARY KEY CLUSTERED  ([RQST_RQID], [RWNO]) ON [BLOB]
GO
ALTER TABLE [dbo].[Step_History_Summery] ADD CONSTRAINT [FK_SHIS_MSTT] FOREIGN KEY ([SSTT_MSTT_CODE], [SSTT_MSTT_SUB_SYS]) REFERENCES [dbo].[Main_State] ([CODE], [SUB_SYS]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Step_History_Summery] ADD CONSTRAINT [FK_SHIS_RQST] FOREIGN KEY ([RQST_RQID]) REFERENCES [dbo].[Request] ([RQID]) ON DELETE CASCADE
GO
