CREATE TABLE [dbo].[External_Device_Weekday_Timing]
(
[EDVW_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[STRT_TIME] [datetime] NULL,
[END_TIME] [datetime] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CMNT] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AINS_EDWT]
   ON  [dbo].[External_Device_Weekday_Timing]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.External_Device_Weekday_Timing T
   USING (SELECT * FROM Inserted) S
   ON (t.EDVW_CODE = s.EDVW_CODE AND 
       T.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(USER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;
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
CREATE TRIGGER [dbo].[CG$AUPD_EDWT]
   ON  [dbo].[External_Device_Weekday_Timing]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   IF EXISTS(SELECT * FROM Inserted i WHERE i.STRT_TIME >= i.END_TIME)
   BEGIN
      RAISERROR(N'ساعت شروع از ساعت پایان بزرگتر میباشد', 16, 1);
      RETURN;
   END 
   
    -- Insert statements for trigger here
   MERGE dbo.External_Device_Weekday_Timing T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(USER_NAME()),
         T.MDFY_DATE = GETDATE(),
         T.STAT = ISNULL(S.STAT, '002');
END
GO
ALTER TABLE [dbo].[External_Device_Weekday_Timing] ADD CONSTRAINT [PK_External_Device_Weekay_Timing] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[External_Device_Weekday_Timing] ADD CONSTRAINT [FK_External_Device_Weekay_Timing_External_Device_Weekday] FOREIGN KEY ([EDVW_CODE]) REFERENCES [dbo].[External_Device_Weekday] ([CODE]) ON DELETE CASCADE
GO
