CREATE TABLE [dbo].[External_Device_Link_Method]
(
[EDEV_CODE] [bigint] NULL,
[MTOD_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NUMB_OF_ATTN] [int] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_EDLM]
   ON  [dbo].[External_Device_Link_Method]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   IF EXISTS(SELECT * FROM Inserted i WHERE i.MTOD_CODE IS NULL)
   BEGIN
      RAISERROR(N'گروه خود را انتخاب نکرده اید', 16, 1);
      RETURN;
   END 
   
   -- Insert statements for trigger here
   MERGE dbo.External_Device_Link_Method T
   USING (SELECT * FROM Inserted) S
   ON (T.EDEV_CODE = S.EDEV_CODE AND 
       t.MTOD_CODE = s.MTOD_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.STAT = ISNULL(S.STAT, '002');
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
CREATE TRIGGER [dbo].[CG$AUPD_EDLM]
   ON  [dbo].[External_Device_Link_Method]
   AFTER UPDATE   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.External_Device_Link_Method T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE(),
         T.NUMB_OF_ATTN = ISNULL(s.NUMB_OF_ATTN, 1);
END
GO
ALTER TABLE [dbo].[External_Device_Link_Method] ADD CONSTRAINT [PK_EDLM] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[External_Device_Link_Method] ADD CONSTRAINT [FK_EDLM_EDEV] FOREIGN KEY ([EDEV_CODE]) REFERENCES [dbo].[External_Device] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[External_Device_Link_Method] ADD CONSTRAINT [FK_EDLM_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'با استفاده کردن از این گزینه میخواهیم مشخص کنیم که اگر حضوری از این سمت دستگاه زده شد چند جلسه از مشتری کسر شود', 'SCHEMA', N'dbo', 'TABLE', N'External_Device_Link_Method', 'COLUMN', N'NUMB_OF_ATTN'
GO
