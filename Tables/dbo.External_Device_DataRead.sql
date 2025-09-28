CREATE TABLE [dbo].[External_Device_DataRead]
(
[EDEV_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[FNGR_PRNT] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[READ_DATE] [datetime] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_EDRD]
   ON  [dbo].[External_Device_DataRead]
   AFTER INSERT   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.External_Device_DataRead T
   USING (SELECT * FROM Inserted) S
   ON (T.EDEV_CODE = S.EDEV_CODE AND 
       T.FNGR_PRNT = S.FNGR_PRNT AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.READ_DATE = GETDATE(),
         T.STAT = '002';
END
GO
ALTER TABLE [dbo].[External_Device_DataRead] ADD CONSTRAINT [PK_External_Device_DataRead] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[External_Device_DataRead] ADD CONSTRAINT [FK_External_Device_DataRead_External_Device] FOREIGN KEY ([EDEV_CODE]) REFERENCES [dbo].[External_Device] ([CODE]) ON DELETE CASCADE
GO
