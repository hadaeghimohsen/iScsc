CREATE TABLE [dbo].[Report_Action_Parameter]
(
[CODE] [bigint] NOT NULL,
[RPAC_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FROM_DATE] [date] NULL,
[TO_DATE] [date] NULL,
[RECD_OWNR] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COCH_FILE_NO] [bigint] NULL,
[CBMT_CODE] [bigint] NULL,
[SUNT_BUNT_DEPT_ORGN_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_BUNT_DEPT_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_BUNT_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_CODE] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORGN_CODE_DNRM] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RPAP]
   ON  [dbo].[Report_Action_Parameter]
   AFTER INSERT 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Report_Action_Parameter T
   USING (SELECT * FROM Inserted) S
   ON (t.RPAC_TYPE = s.RPAC_TYPE AND t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
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
CREATE TRIGGER [dbo].[CG$AUPD_RPAP]
   ON  [dbo].[Report_Action_Parameter]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Report_Action_Parameter T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE(),
         T.ORGN_CODE_DNRM = S.SUNT_BUNT_DEPT_ORGN_CODE + S.SUNT_BUNT_DEPT_CODE + s.SUNT_BUNT_CODE + s.SUNT_CODE;
END
GO
ALTER TABLE [dbo].[Report_Action_Parameter] ADD CONSTRAINT [PK_RPAP] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'کاربران ایجاد کننده', 'SCHEMA', N'dbo', 'TABLE', N'Report_Action_Parameter', 'COLUMN', N'RECD_OWNR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع گزارش', 'SCHEMA', N'dbo', 'TABLE', N'Report_Action_Parameter', 'COLUMN', N'RPAC_TYPE'
GO
