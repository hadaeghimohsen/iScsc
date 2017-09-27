CREATE TABLE [dbo].[Request_Type]
(
[CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_RQTP_CODE] DEFAULT ('0'),
[SUB_SYS] [smallint] NOT NULL,
[RQTP_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MUST_LOCK] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SAVE_PYMT_ACNT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EPIT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RQTP]
   ON  [dbo].[Request_Type]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Request_Type T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE    = S.CODE AND
       T.SUB_SYS = S.SUB_SYS)
   WHEN MATCHED THEN
      UPDATE
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE();    
            
            
   DECLARE C$NewRequestType CURSOR FOR
      SELECT CODE FROM INSERTED;
   
   DECLARE @Code VARCHAR(3);
   
   OPEN C$NewRequestType;
   L$NextRqtpRow:
   FETCH NEXT FROM C$NewRequestType INTO @Code;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndRqtpFetch;
   
   EXEC CRET_RQRQ_P @RqtpCode = @Code, @RqttCode = NULL;
   
   GOTO L$NextRqtpRow;
   L$EndRqtpFetch:
   CLOSE C$NewRequestType;
   DEALLOCATE C$NewRequestType;        
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_RQTP]
   ON  [dbo].[Request_Type]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Request_Type T
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
ALTER TABLE [dbo].[Request_Type] ADD CONSTRAINT [CK_RQTP_MUST_LOCK] CHECK (([MUST_LOCK]='002' OR [MUST_LOCK]='001'))
GO
ALTER TABLE [dbo].[Request_Type] ADD CONSTRAINT [RQTP_PK] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'متناسب با کدام گزینه آیتم درآمدی و هزینه فرآیندی می باشد', 'SCHEMA', N'dbo', 'TABLE', N'Request_Type', 'COLUMN', N'EPIT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آیا درآمد باشگاه می باشد؟', 'SCHEMA', N'dbo', 'TABLE', N'Request_Type', 'COLUMN', N'SAVE_PYMT_ACNT'
GO
