CREATE TABLE [dbo].[Request_Requester]
(
[REGL_YEAR] [smallint] NULL CONSTRAINT [DF_Request_Requester_REGL_YEAR] DEFAULT ((0)),
[REGL_CODE] [int] NULL CONSTRAINT [DF_Request_Requester_REGL_CODE] DEFAULT ((0)),
[RQTP_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RQTT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SUB_SYS] [smallint] NOT NULL CONSTRAINT [DF_Request_Requester_SUB_SYS] DEFAULT ((1)),
[CODE] [bigint] NOT NULL CONSTRAINT [DF_Request_Requester_CODE] DEFAULT ((0)),
[PERM_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_RQRQ_PERM_STAT] DEFAULT ('002'),
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

CREATE TRIGGER [dbo].[CG$AINS_RQRQ]
   ON  [dbo].[Request_Requester]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   MERGE dbo.Request_Requester T
   USING (SELECT * FROM INSERTED) S
   ON (T.REGL_YEAR = S.REGL_YEAR AND
       T.REGL_CODE = S.REGL_CODE AND
       T.RQTP_CODE = S.RQTP_CODE AND
       T.RQTT_CODE = S.RQTT_CODE AND
       T.SUB_SYS   = S.SUB_SYS)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE      = DBO.GNRT_NVID_U();
   
   DECLARE C$NewRequestRequester CURSOR FOR
      SELECT T.Code FROM dbo.Request_Requester T, INSERTED S
      WHERE T.REGL_YEAR = S.REGL_YEAR AND
            T.REGL_CODE = S.REGL_CODE AND
            T.RQTP_CODE = S.RQTP_CODE AND
            T.RQTT_CODE = S.RQTT_CODE AND
            T.SUB_SYS   = S.SUB_SYS;
   
   DECLARE @Code     BIGINT
          ,@RqtpCode VARCHAR(3)
          ,@RqttCode VARCHAR(3);
   
   OPEN C$NewRequestRequester;
   L$NextRqrqRow:
   FETCH NEXT FROM C$NewRequestRequester INTO @Code;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndRqrqFetch;
   
   EXEC CRET_EXTP_P @RqrqCode = @Code, @EpitCode = NULL;
   
   GOTO L$NextRqrqRow;
   L$EndRqrqFetch:
   CLOSE C$NewRequestRequester;
   DEALLOCATE C$NewRequestRequester;   
END
;

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CG$AUPD_RQRQ]
   ON  [dbo].[Request_Requester]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   DELETE Request_Requester
   WHERE CODE IN (
      SELECT CODE FROM INSERTED
      WHERE ISNULL(CODE, 0) > 0        
        AND REGL_CODE IS NULL
        AND REGL_YEAR IS NULL);

   -- Insert statements for trigger here
   MERGE dbo.Request_Requester T
   USING (SELECT * FROM INSERTED) S
   ON (T.REGL_YEAR = S.REGL_YEAR AND
       T.REGL_CODE = S.REGL_CODE AND
       T.RQTP_CODE = S.RQTP_CODE AND
       T.RQTT_CODE = S.RQTT_CODE AND
       T.SUB_SYS   = S.SUB_SYS   AND
       T.CODE      = S.CODE)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ,SUB_SYS   = (SELECT SUB_SYS FROM Request_Type WHERE CODE = S.Rqtp_Code)
            ,PERM_STAT = CASE WHEN S.PERM_STAT IS NULL THEN '002' ELSE S.PERM_STAT END;            
END
;

GO
ALTER TABLE [dbo].[Request_Requester] ADD CONSTRAINT [CK_RQRQ_PERM_STAT] CHECK (([PERM_STAT]='002' OR [PERM_STAT]='001'))
GO
ALTER TABLE [dbo].[Request_Requester] ADD CONSTRAINT [RQRQ_PK] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Request_Requester] WITH NOCHECK ADD CONSTRAINT [FK_RQRQ_REGL] FOREIGN KEY ([REGL_YEAR], [REGL_CODE]) REFERENCES [dbo].[Regulation] ([YEAR], [CODE]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Request_Requester] ADD CONSTRAINT [FK_RQRQ_RQTP] FOREIGN KEY ([RQTP_CODE]) REFERENCES [dbo].[Request_Type] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Request_Requester] ADD CONSTRAINT [FK_RQRQ_RQTT] FOREIGN KEY ([RQTT_CODE]) REFERENCES [dbo].[Requester_Type] ([CODE])
GO
