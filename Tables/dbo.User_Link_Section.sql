CREATE TABLE [dbo].[User_Link_Section]
(
[USER_DB] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SECT_APBS_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL
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
CREATE TRIGGER [dbo].[CG$AINS_ULNS]
   ON  [dbo].[User_Link_Section]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.User_Link_Section T
   USING (SELECT * FROM Inserted) S
   ON (T.USER_DB = S.USER_DB AND 
       T.SECT_APBS_CODE = S.SECT_APBS_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;
END
GO
ALTER TABLE [dbo].[User_Link_Section] ADD CONSTRAINT [PK_User_Link_Section] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[User_Link_Section] ADD CONSTRAINT [FK_ULNS_SECT_APBS] FOREIGN KEY ([SECT_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
