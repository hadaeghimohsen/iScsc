CREATE TABLE [dbo].[Requester_Type]
(
[CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SUB_SYS] [smallint] NOT NULL,
[RQTT_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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

CREATE TRIGGER [dbo].[CG$AINS_RQTT]
   ON  [dbo].[Requester_Type]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Requester_Type T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE    = S.CODE AND
       T.SUB_SYS = S.SUB_SYS)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE();
            
   DECLARE C$NewRequesterType CURSOR FOR
      SELECT CODE FROM INSERTED;
   
   DECLARE @Code VARCHAR(3);
   
   OPEN C$NewRequesterType;
   L$NextRqtpRow:
   FETCH NEXT FROM C$NewRequesterType INTO @Code;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndRqtpFetch;
   
   EXEC CRET_RQRQ_P @RqtpCode = NULL, @RqttCode = @Code;
   
   GOTO L$NextRqtpRow;
   L$EndRqtpFetch:
   CLOSE C$NewRequesterType;
   DEALLOCATE C$NewRequesterType; 
END
;

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CG$AUPD_RQTT]
   ON  [dbo].[Requester_Type]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Requester_Type T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE    = S.CODE AND
       T.SUB_SYS = S.SUB_SYS)
   WHEN MATCHED THEN
      UPDATE
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
;

GO
ALTER TABLE [dbo].[Requester_Type] ADD CONSTRAINT [RQTT_PK] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
