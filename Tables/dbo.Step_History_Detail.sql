CREATE TABLE [dbo].[Step_History_Detail]
(
[SHIS_RQST_RQID] [bigint] NOT NULL,
[SHIS_RWNO] [smallint] NOT NULL,
[RWNO] [smallint] NOT NULL CONSTRAINT [DF_SHID_RWNO] DEFAULT ((0)),
[SSTT_MSTT_SUB_SYS] [smallint] NOT NULL,
[SSTT_MSTT_CODE] [smallint] NOT NULL,
[SSTT_CODE] [smallint] NOT NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SHID]
   ON  [dbo].[Step_History_Detail]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Step_History_Detail T
   USING (SELECT * FROM INSERTED) S
   ON (T.SHIS_RQST_RQID = S.SHIS_RQST_RQID AND
       T.SHIS_RWNO      = S.SHIS_RWNO      AND
       T.RWNO           = S.RWNO)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,FROM_DATE = GETDATE()
            ,TO_DATE   = GETDATE()
            ,RWNO = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM STEP_HISTORY_DETAIL WHERE SHIS_RQST_RQID = S.SHIS_RQST_RQID AND SHIS_RWNO = S.SHIS_RWNO);
            
   MERGE dbo.Step_History_Summery T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQST_RQID = S.SHIS_RQST_RQID AND
       T.RWNO      = S.SHIS_RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET TO_DATE = GETDATE();
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_SHID]
   ON  [dbo].[Step_History_Detail]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Step_History_Detail T
   USING (SELECT * FROM INSERTED) S
   ON (T.SHIS_RQST_RQID = S.SHIS_RQST_RQID AND
       T.SHIS_RWNO      = S.SHIS_RWNO      AND
       T.RWNO           = S.RWNO)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
            
   MERGE dbo.Step_History_Summery T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQST_RQID = S.SHIS_RQST_RQID AND
       T.RWNO      = S.SHIS_RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET TO_DATE = GETDATE();
END
;
GO
ALTER TABLE [dbo].[Step_History_Detail] ADD CONSTRAINT [SHID_PK] PRIMARY KEY CLUSTERED  ([SHIS_RQST_RQID], [SHIS_RWNO], [RWNO]) ON [BLOB]
GO
ALTER TABLE [dbo].[Step_History_Detail] ADD CONSTRAINT [FK_SHID_SHIS] FOREIGN KEY ([SHIS_RQST_RQID], [SHIS_RWNO]) REFERENCES [dbo].[Step_History_Summery] ([RQST_RQID], [RWNO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Step_History_Detail] ADD CONSTRAINT [FK_SHID_SSTT] FOREIGN KEY ([SSTT_MSTT_CODE], [SSTT_MSTT_SUB_SYS], [SSTT_CODE]) REFERENCES [dbo].[Sub_State] ([MSTT_CODE], [MSTT_SUB_SYS], [CODE]) ON DELETE CASCADE
GO
