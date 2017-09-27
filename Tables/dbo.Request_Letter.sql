CREATE TABLE [dbo].[Request_Letter]
(
[RLID] [bigint] NOT NULL,
[RQST_RQID] [bigint] NOT NULL,
[RWNO] [smallint] NOT NULL,
[REC_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__Request_L__REC_S__1F04813B] DEFAULT ('002'),
[LETT_NO] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LETT_DATE] [date] NOT NULL,
[LETT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__Request_L__LETT___1FF8A574] DEFAULT ('001'),
[RQLT_DESC] [nvarchar] (240) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RQLT]
   ON  [dbo].[Request_Letter]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Request_Letter T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQST_RQID = S.RQST_RQID AND
       T.RWNO      = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,RLID      = dbo.GNRT_NVID_U()
            ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM Request_Letter WHERE RQST_RQID = S.RQST_RQID);

   
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_RQLT]
   ON  [dbo].[Request_Letter]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Request_Letter T
   USING (SELECT * FROM INSERTED) S
   ON (T.RQST_RQID = S.RQST_RQID AND
       T.RWNO      = S.RWNO      AND
       T.RLID      = S.RLID)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
   
END
;
GO
ALTER TABLE [dbo].[Request_Letter] ADD CONSTRAINT [PK_RQLT] PRIMARY KEY CLUSTERED  ([RLID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Request_Letter] ADD CONSTRAINT [FK_RQLT_RQST] FOREIGN KEY ([RQST_RQID]) REFERENCES [dbo].[Request] ([RQID])
GO
