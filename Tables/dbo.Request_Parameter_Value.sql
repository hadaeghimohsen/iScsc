CREATE TABLE [dbo].[Request_Parameter_Value]
(
[RQPM_CODE] [bigint] NULL,
[APBS_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CMNT] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[CRET_HOST_BY] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL,
[MDFY_HOST_BY] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
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
CREATE TRIGGER [dbo].[CG$AINS_RQPV]
   ON  [dbo].[Request_Parameter_Value]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Request_Parameter_Value T
   USING (SELECT * FROM Inserted) S
   ON (T.RQPM_CODE = S.RQPM_CODE AND 
       T.APBS_CODE = S.APBS_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CRET_HOST_BY = dbo.GET_HOST_U(),
         T.CODE = CASE S.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;
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
CREATE TRIGGER [dbo].[CG$AUPD_RQPV]
   ON  [dbo].[Request_Parameter_Value]
   AFTER UPDATE  
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Request_Parameter_Value T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE(),
         T.MDFY_HOST_BY = dbo.GET_HOST_U();
END
GO
ALTER TABLE [dbo].[Request_Parameter_Value] ADD CONSTRAINT [PK_RQPV] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Request_Parameter_Value] ADD CONSTRAINT [FK_RQPV_APBS] FOREIGN KEY ([APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Request_Parameter_Value] ADD CONSTRAINT [FK_RQPV_RQPM] FOREIGN KEY ([RQPM_CODE]) REFERENCES [dbo].[Request_Parameter] ([CODE]) ON DELETE CASCADE
GO
