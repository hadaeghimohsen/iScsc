CREATE TABLE [dbo].[Organ_Document]
(
[SUNT_BUNT_DEPT_ORGN_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_BUNT_DEPT_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_BUNT_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_CODE] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQDC_RDID] [bigint] NULL,
[REGL_YEAR] [smallint] NULL,
[REGL_CODE] [int] NULL,
[DCMT_DSID] [bigint] NULL,
[ODID] [bigint] NOT NULL,
[NEED_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_OGDC]
   ON  [dbo].[Organ_Document]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Organ_Document T
   USING (SELECT * FROM INSERTED) S
   ON (T.SUNT_BUNT_DEPT_ORGN_CODE = S.Sunt_Bunt_Dept_Orgn_Code AND
       T.SUNT_BUNT_DEPT_CODE = S.Sunt_Bunt_Dept_Code AND
       T.Sunt_Bunt_Code = S.Sunt_Bunt_Code AND
       T.Sunt_Code = S.Sunt_Code AND 
       T.RQDC_RDID = S.Rqdc_Rdid)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,ODID = dbo.GNRT_NVID_U()
            ,REGL_YEAR = (SELECT Rq.REGL_YEAR FROM dbo.Request_Document rd, dbo.Request_Requester Rq WHERE Rd.RQRQ_CODE = Rq.CODE AND Rd.Rdid = S.Rqdc_Rdid)
            ,REGL_CODE = (SELECT Rq.REGL_CODE FROM dbo.Request_Document rd, dbo.Request_Requester Rq WHERE Rd.RQRQ_CODE = Rq.CODE AND Rd.Rdid = S.Rqdc_Rdid)
            ,DCMT_DSID = (SELECT DCMT_DSID FROM dbo.Request_Document WHERE Rdid = S.Rqdc_Rdid);
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
CREATE TRIGGER [dbo].[CG$AUPD_OGDC]
   ON  [dbo].[Organ_Document]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Organ_Document T
   USING (SELECT * FROM INSERTED) S
   ON (T.SUNT_BUNT_DEPT_ORGN_CODE = S.Sunt_Bunt_Dept_Orgn_Code AND
       T.SUNT_BUNT_DEPT_CODE = S.Sunt_Bunt_Dept_Code AND
       T.Sunt_Bunt_Code = S.Sunt_Bunt_Code AND
       T.Sunt_Code = S.Sunt_Code AND 
       T.RQDC_RDID = S.Rqdc_Rdid AND 
       T.ODID = S.Odid)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Organ_Document] ADD CONSTRAINT [PK_Organ_Document] PRIMARY KEY CLUSTERED  ([ODID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Organ_Document] ADD CONSTRAINT [FK_OGDC_DCMT] FOREIGN KEY ([DCMT_DSID]) REFERENCES [dbo].[Document_Spec] ([DSID])
GO
ALTER TABLE [dbo].[Organ_Document] ADD CONSTRAINT [FK_OGDC_REGL] FOREIGN KEY ([REGL_YEAR], [REGL_CODE]) REFERENCES [dbo].[Regulation] ([YEAR], [CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Organ_Document] ADD CONSTRAINT [FK_OGDC_RQDC] FOREIGN KEY ([RQDC_RDID]) REFERENCES [dbo].[Request_Document] ([RDID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Organ_Document] ADD CONSTRAINT [FK_OGDC_SUNT] FOREIGN KEY ([SUNT_BUNT_DEPT_ORGN_CODE], [SUNT_BUNT_DEPT_CODE], [SUNT_BUNT_CODE], [SUNT_CODE]) REFERENCES [dbo].[Sub_Unit] ([BUNT_DEPT_ORGN_CODE], [BUNT_DEPT_CODE], [BUNT_CODE], [CODE])
GO
