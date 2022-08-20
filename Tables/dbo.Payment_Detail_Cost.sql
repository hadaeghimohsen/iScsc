CREATE TABLE [dbo].[Payment_Detail_Cost]
(
[PYDT_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RWNO] [smallint] NULL,
[INIT_AMNT_DNRM] [bigint] NULL,
[PYDT_APBS_CODE] [bigint] NULL,
[PYDT_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PYDT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PYDT_AMNT] [bigint] NULL,
[PYDT_CALC_AMNT] [bigint] NULL,
[RMND_AMNT] [bigint] NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
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
CREATE TRIGGER [dbo].[CG$AINS_PDCO]
   ON  [dbo].[Payment_Detail_Cost]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Payment_Detail_Cost T
   USING (SELECT * FROM Inserted) S
   ON (T.PYDT_CODE = S.PYDT_CODE AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE S.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.CODE END;
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
CREATE TRIGGER [dbo].[CG$AUPD_PDCO]
   ON  [dbo].[Payment_Detail_Cost]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Payment_Detail_Cost T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Payment_Detail_Cost] ADD CONSTRAINT [PK_Payment_Detail_Cost] PRIMARY KEY CLUSTERED  ([CODE]) ON [BLOB]
GO
ALTER TABLE [dbo].[Payment_Detail_Cost] ADD CONSTRAINT [FK_PDCO_APBS] FOREIGN KEY ([PYDT_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Payment_Detail_Cost] ADD CONSTRAINT [FK_PDCO_PYDT] FOREIGN KEY ([PYDT_CODE]) REFERENCES [dbo].[Payment_Detail] ([CODE]) ON DELETE CASCADE
GO
