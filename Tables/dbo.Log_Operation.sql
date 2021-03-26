CREATE TABLE [dbo].[Log_Operation]
(
[FIGH_FILE_NO] [bigint] NULL,
[LOID] [bigint] NOT NULL,
[LOG_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LOG_TEXT] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[CRET_HOST_BY] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[MDFY_HOST_BY] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
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
CREATE TRIGGER [dbo].[CG$AINS_LOG]
   ON  [dbo].[Log_Operation]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Log_Operation T
   USING (SELECT * FROM Inserted) S
   ON (T.LOID = S.LOID)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CRET_HOST_BY = (SELECT s.host_name
                             FROM sys.dm_exec_connections AS c  
                             JOIN sys.dm_exec_sessions AS s  
                               ON c.session_id = s.session_id  
                            WHERE c.session_id = @@SPID),
         T.LOID = CASE s.LOID WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.LOID END; 
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
CREATE TRIGGER [dbo].[CG$AUPD_LOG]
   ON  [dbo].[Log_Operation]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Log_Operation T
   USING (SELECT * FROM Inserted) S
   ON (T.LOID = S.LOID)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE(),
         T.MDFY_HOST_BY = (SELECT s.host_name
                             FROM sys.dm_exec_connections AS c  
                             JOIN sys.dm_exec_sessions AS s  
                               ON c.session_id = s.session_id  
                            WHERE c.session_id = @@SPID);
END
GO
ALTER TABLE [dbo].[Log_Operation] ADD CONSTRAINT [PK_LGOP] PRIMARY KEY CLUSTERED  ([LOID]) ON [BLOB]
GO
ALTER TABLE [dbo].[Log_Operation] ADD CONSTRAINT [FK_LGOP_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
