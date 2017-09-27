CREATE TABLE [dbo].[Sub_State]
(
[MSTT_CODE] [smallint] NOT NULL,
[MSTT_SUB_SYS] [smallint] NOT NULL,
[CODE] [smallint] NOT NULL,
[SSTT_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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

CREATE TRIGGER [dbo].[CG$AINS_SSTT]
   ON [dbo].[Sub_State]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Sub_State T
   USING (SELECT * FROM INSERTED) S
   ON (T.MSTT_CODE    = S.MSTT_CODE AND
       T.MSTT_SUB_SYS = S.MSTT_SUB_SYS AND 
       T.CODE         = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE();            
END
;

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CG$AUPD_SSTT]
   ON [dbo].[Sub_State]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Sub_State T
   USING (SELECT * FROM INSERTED) S
   ON (T.MSTT_CODE    = S.MSTT_CODE AND
       T.MSTT_SUB_SYS = S.MSTT_SUB_SYS AND 
       T.CODE         = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();            
END
;

GO
ALTER TABLE [dbo].[Sub_State] ADD CONSTRAINT [SSTT_PK] PRIMARY KEY CLUSTERED  ([MSTT_CODE], [MSTT_SUB_SYS], [CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Sub_State] ADD CONSTRAINT [FK_SSTT_MSTT] FOREIGN KEY ([MSTT_CODE], [MSTT_SUB_SYS]) REFERENCES [dbo].[Main_State] ([CODE], [SUB_SYS])
GO
