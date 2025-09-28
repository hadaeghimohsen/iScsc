CREATE TABLE [dbo].[Audit]
(
[FIGH_FILE_NO] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RWNO] [int] NULL,
[AUDT_DATE] [datetime] NULL,
[EXPN_AMNT] [bigint] NULL,
[FEE_AMNT] [bigint] NULL,
[EXTR_PRCT_AMNT] [bigint] NULL,
[SUM_AMNT_DNRM] [bigint] NULL,
[FBAC_CODE] [bigint] NULL,
[PAYC_CODE] [bigint] NULL,
[PAYC_CMNT] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LETT_NO] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CMNT] [nvarchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_AUDT]
   ON  [dbo].[Audit]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Audit T
   USING (SELECT * FROM Inserted) S
   ON (T.FIGH_FILE_NO = S.FIGH_FILE_NO AND
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.RWNO = (SELECT ISNULL(MAX(a.RWNO), 0) + 1 FROM dbo.Audit a WHERE a.FIGH_FILE_NO = S.FIGH_FILE_NO),
         T.AUDT_DATE = ISNULL(S.AUDT_DATE, GETDATE());
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
CREATE TRIGGER [dbo].[CG$AUPD_AUDT]
   ON  [dbo].[Audit]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Audit T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();         
END
GO
ALTER TABLE [dbo].[Audit] ADD CONSTRAINT [PK_Audit] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Audit] ADD CONSTRAINT [FK_Audit_App_Base_Define] FOREIGN KEY ([PAYC_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Audit] ADD CONSTRAINT [FK_Audit_Fighter] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Audit] ADD CONSTRAINT [FK_Audit_Fighter_Bank_Account] FOREIGN KEY ([FBAC_CODE]) REFERENCES [dbo].[Fighter_Bank_Account] ([CODE])
GO
