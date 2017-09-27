CREATE TABLE [dbo].[Main_State]
(
[CODE] [smallint] NOT NULL,
[SUB_SYS] [smallint] NOT NULL,
[MSTT_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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

CREATE TRIGGER [dbo].[CG$AINS_MSTT]
   ON  [dbo].[Main_State]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Main_State T
   USING (SELECT * FROM INSERTED) S
   ON (T.CODE    = S.CODE AND
       T.SUB_SYS = S.SUB_SYS)
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

CREATE TRIGGER [dbo].[CG$AUPD_MSTT]
   ON  [dbo].[Main_State]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Main_State T
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
ALTER TABLE [dbo].[Main_State] ADD CONSTRAINT [MSTT_PK] PRIMARY KEY CLUSTERED  ([CODE], [SUB_SYS]) ON [PRIMARY]
GO
