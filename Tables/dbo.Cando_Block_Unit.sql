CREATE TABLE [dbo].[Cando_Block_Unit]
(
[BLOK_CNDO_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BLOK_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[POST_ADRS] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CORD_X] [float] NULL,
[CORD_Y] [float] NULL,
[CMNT] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_CUNT]
   ON  [dbo].[Cando_Block_Unit]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Cando_Block_Unit T
   USING (SELECT * FROM Inserted) S
   ON (T.BLOK_CNDO_CODE = s.BLOK_CNDO_CODE AND 
       T.BLOK_CODE = S.BLOK_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME())
        ,T.CRET_DATE = GETDATE()
        ,T.CODE = dbo.GET_PSTR_U(s.CODE, 3);
   
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
CREATE TRIGGER [dbo].[CG$AUPD_CUNT]
   ON  [dbo].[Cando_Block_Unit]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Cando_Block_Unit T
   USING (SELECT * FROM Inserted) S
   ON (T.BLOK_CNDO_CODE = s.BLOK_CNDO_CODE AND 
       T.BLOK_CODE = S.BLOK_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME())
        ,T.MDFY_DATE = GETDATE();
   
END
GO
ALTER TABLE [dbo].[Cando_Block_Unit] ADD CONSTRAINT [PK_Cando_Block_Unit] PRIMARY KEY CLUSTERED  ([BLOK_CNDO_CODE], [BLOK_CODE], [CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Cando_Block_Unit] ADD CONSTRAINT [FK_UNIT_BLOK] FOREIGN KEY ([BLOK_CNDO_CODE], [BLOK_CODE]) REFERENCES [dbo].[Cando_Block] ([CNDO_CODE], [CODE])
GO
