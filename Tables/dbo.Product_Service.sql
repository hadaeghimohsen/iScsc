CREATE TABLE [dbo].[Product_Service]
(
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[PDCS_CODE] [bigint] NULL,
[SERL_NO] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CODE] [bigint] NOT NULL,
[MAKE_DATE] [date] NULL,
[EXPR_DATE] [date] NULL,
[COMP_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COMP_ADRS] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COMP_SITE] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COMP_TELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COMP_CELL_PHON] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_PDSR]
   ON  [dbo].[Product_Service]
   AFTER INSERT
AS 
BEGIN
	MERGE dbo.Product_Service T
	USING (SELECT * FROM Inserted) S
	ON (t.RQRO_RQST_RQID = s.RQRO_RQST_RQID AND 
	    t.RQRO_RWNO = s.RQRO_RWNO AND 
	    t.PDCS_CODE = s.PDCS_CODE AND 
	    T.CODE = s.CODE)
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
CREATE TRIGGER [dbo].[CG$AUPD_PDSR]
   ON  [dbo].[Product_Service]
   AFTER UPDATE
AS 
BEGIN
	MERGE dbo.Product_Service T
	USING (SELECT * FROM Inserted) S
	ON (T.CODE = s.CODE)
	WHEN MATCHED THEN
	   UPDATE SET
	      T.MDFY_BY = UPPER(SUSER_NAME()),
	      T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Product_Service] ADD CONSTRAINT [PK_PDSR] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Product_Service] ADD CONSTRAINT [FK_PDSR_PDCS] FOREIGN KEY ([PDCS_CODE]) REFERENCES [dbo].[Payment_Detail_Commodity_Sale] ([CODE])
GO
ALTER TABLE [dbo].[Product_Service] ADD CONSTRAINT [FK_PDSR_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO]) ON DELETE CASCADE
GO
