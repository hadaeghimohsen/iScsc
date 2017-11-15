CREATE TABLE [dbo].[Statistic]
(
[CODE] [bigint] NOT NULL,
[STIS_DATE] [date] NULL,
[REGN_PRVN_CNTY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REGN_PRVN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REGN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CLUB_CODE] [bigint] NULL,
[REGL_YEAR] [smallint] NULL,
[REGL_CODE] [int] NULL,
[RQTP_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQTT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FGPB_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_BUNT_DEPT_ORGN_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_BUNT_DEPT_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_BUNT_CODE] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SUNT_CODE] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MTOD_CODE] [bigint] NULL,
[CTGY_CODE] [bigint] NULL,
[CONT] [bigint] NULL,
[AMNT] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_STIS]
   ON  [dbo].[Statistic]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   
   MERGE dbo.Statistic T
   USING (
      SELECT * 
        FROM INSERTED
   ) S
   ON ( T.REGN_PRVN_CNTY_CODE = S.REGN_PRVN_CNTY_CODE 
    AND T.REGN_PRVN_CODE = S.REGN_PRVN_CODE
    AND T.REGN_CODE = S.REGN_CODE
    AND T.CLUB_CODE = S.CLUB_CODE
    AND T.REGL_YEAR = S.REGL_YEAR
    AND T.REGL_CODE = S.REGL_CODE
    AND T.RQTP_CODE = S.RQTP_CODE
    AND T.RQTT_CODE = S.RQTT_CODE
    AND T.FGPB_TYPE = S.FGPB_TYPE
    AND T.SUNT_BUNT_DEPT_ORGN_CODE = S.SUNT_BUNT_DEPT_ORGN_CODE
    AND T.SUNT_BUNT_DEPT_CODE = S.SUNT_BUNT_DEPT_CODE
    AND T.SUNT_BUNT_CODE = S.SUNT_BUNT_CODE
    AND T.SUNT_CODE = S.SUNT_CODE
    AND T.CODE = S.CODE    
   )
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE = dbo.GNRT_NVID_U();
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
CREATE TRIGGER [dbo].[CG$AUPD_STIS]
   ON  [dbo].[Statistic]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   
   MERGE dbo.Statistic T
   USING (
      SELECT * 
        FROM INSERTED
   ) S
   ON ( T.REGN_PRVN_CNTY_CODE = S.REGN_PRVN_CNTY_CODE 
    AND T.REGN_PRVN_CODE = S.REGN_PRVN_CODE
    AND T.REGN_CODE = S.REGN_CODE
    AND T.CLUB_CODE = S.CLUB_CODE
    AND T.REGL_YEAR = S.REGL_YEAR
    AND T.REGL_CODE = S.REGL_CODE
    AND T.RQTP_CODE = S.RQTP_CODE
    AND T.RQTT_CODE = S.RQTT_CODE
    AND T.FGPB_TYPE = S.FGPB_TYPE
    AND T.SUNT_BUNT_DEPT_ORGN_CODE = S.SUNT_BUNT_DEPT_ORGN_CODE
    AND T.SUNT_BUNT_DEPT_CODE = S.SUNT_BUNT_DEPT_CODE
    AND T.SUNT_BUNT_CODE = S.SUNT_BUNT_CODE
    AND T.SUNT_CODE = S.SUNT_CODE
    AND T.CODE = S.CODE    
   )
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Statistic] ADD CONSTRAINT [PK_STIS] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Statistic] ADD CONSTRAINT [FK_STIS_CLUB] FOREIGN KEY ([CLUB_CODE]) REFERENCES [dbo].[Club] ([CODE])
GO
ALTER TABLE [dbo].[Statistic] ADD CONSTRAINT [FK_STIS_CTGY] FOREIGN KEY ([CTGY_CODE]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
ALTER TABLE [dbo].[Statistic] ADD CONSTRAINT [FK_STIS_MTOD] FOREIGN KEY ([MTOD_CODE]) REFERENCES [dbo].[Method] ([CODE])
GO
ALTER TABLE [dbo].[Statistic] ADD CONSTRAINT [FK_STIS_REGL] FOREIGN KEY ([REGL_YEAR], [REGL_CODE]) REFERENCES [dbo].[Regulation] ([YEAR], [CODE])
GO
ALTER TABLE [dbo].[Statistic] ADD CONSTRAINT [FK_STIS_REGN] FOREIGN KEY ([REGN_PRVN_CNTY_CODE], [REGN_PRVN_CODE], [REGN_CODE]) REFERENCES [dbo].[Region] ([PRVN_CNTY_CODE], [PRVN_CODE], [CODE])
GO
ALTER TABLE [dbo].[Statistic] ADD CONSTRAINT [FK_STIS_RQTP] FOREIGN KEY ([RQTP_CODE]) REFERENCES [dbo].[Request_Type] ([CODE])
GO
ALTER TABLE [dbo].[Statistic] ADD CONSTRAINT [FK_STIS_RQTT] FOREIGN KEY ([RQTT_CODE]) REFERENCES [dbo].[Requester_Type] ([CODE])
GO
ALTER TABLE [dbo].[Statistic] ADD CONSTRAINT [FK_STIS_SUNT] FOREIGN KEY ([SUNT_BUNT_DEPT_ORGN_CODE], [SUNT_BUNT_DEPT_CODE], [SUNT_BUNT_CODE], [SUNT_CODE]) REFERENCES [dbo].[Sub_Unit] ([BUNT_DEPT_ORGN_CODE], [BUNT_DEPT_CODE], [BUNT_CODE], [CODE])
GO
