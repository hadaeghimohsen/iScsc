CREATE TABLE [dbo].[Modual_Report_Direct_Print]
(
[MDRP_CODE] [bigint] NULL,
[USER_ID] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COMA_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[DFLT_PRNT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRNT_NAME] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COPY_NUMB] [int] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_MRDP]
   ON  [dbo].[Modual_Report_Direct_Print]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Modual_Report_Direct_Print T
   USING (SELECT * FROM Inserted) S
   ON (T.MDRP_CODE = S.MDRP_CODE AND 
       T.USER_ID = S.USER_ID AND 
       T.COMA_CODE = S.COMA_CODE AND
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.DFLT_PRNT = ISNULL(s.DFLT_PRNT, '001'),
         T.COPY_NUMB = ISNULL(S.COPY_NUMB, 1),
         T.STAT = ISNULL(s.STAT, '002');
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
CREATE TRIGGER [dbo].[CG$AUPD_MRDP]
   ON  [dbo].[Modual_Report_Direct_Print]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Modual_Report_Direct_Print T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
   
   /*UPDATE m
      SET m.DFLT_PRNT = '001'
     FROM dbo.Modual_Report_Direct_Print m, Inserted i
    WHERE m.USER_ID = i.USER_ID
      AND m.COMA_CODE = i.COMA_CODE
      AND i.DFLT_PRNT = '002'
      AND i.CODE != m.CODE;*/
END
GO
ALTER TABLE [dbo].[Modual_Report_Direct_Print] ADD CONSTRAINT [PK_Modual_Report_Direct_Print] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Modual_Report_Direct_Print] ADD CONSTRAINT [FK_MRDP_COMA] FOREIGN KEY ([COMA_CODE]) REFERENCES [dbo].[Computer_Action] ([CODE])
GO
ALTER TABLE [dbo].[Modual_Report_Direct_Print] ADD CONSTRAINT [FK_MRDP_MDRP] FOREIGN KEY ([MDRP_CODE]) REFERENCES [dbo].[Modual_Report] ([CODE])
GO
