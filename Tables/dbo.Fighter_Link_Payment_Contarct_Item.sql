CREATE TABLE [dbo].[Fighter_Link_Payment_Contarct_Item]
(
[FIGH_FILE_NO] [bigint] NULL,
[PMCT_ITEM_APBS_CODE] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_FLPC]
   ON  [dbo].[Fighter_Link_Payment_Contarct_Item]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Fighter_Link_Payment_Contarct_Item T
   USING (SELECT * FROM Inserted) S
   ON (t.FIGH_FILE_NO = s.FIGH_FILE_NO AND
       t.PMCT_ITEM_APBS_CODE = s.PMCT_ITEM_APBS_CODE AND
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;
END
GO
ALTER TABLE [dbo].[Fighter_Link_Payment_Contarct_Item] ADD CONSTRAINT [PK_Fighter_Link_Payment_Contarct_Item] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Fighter_Link_Payment_Contarct_Item] ADD CONSTRAINT [FK_Fighter_Link_Payment_Contarct_Item_Fighter] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Fighter_Link_Payment_Contarct_Item] ADD CONSTRAINT [FK_Fighter_Link_Payment_Contarct_Item_Fighter_Link_Payment_Contarct_Item] FOREIGN KEY ([PMCT_ITEM_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
