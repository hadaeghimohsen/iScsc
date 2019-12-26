CREATE TABLE [dbo].[Payment_Detail_Commodity_Sale]
(
[PYDT_CODE] [bigint] NULL,
[PROD_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_PDCS]
   ON  [dbo].[Payment_Detail_Commodity_Sale]
   AFTER INSERT
AS 
BEGIN
	MERGE dbo.Payment_Detail_Commodity_Sale T
	USING (SELECT * FROM Inserted) S
	ON (t.PYDT_CODE = s.PYDT_CODE AND 
	    t.PROD_CODE = s.PROD_CODE AND
	    t.CODE = s.CODE)
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
CREATE TRIGGER [dbo].[CG$AUPD_PDCS]
   ON  [dbo].[Payment_Detail_Commodity_Sale]
   AFTER UPDATE
AS 
BEGIN
	MERGE dbo.Payment_Detail_Commodity_Sale T
	USING (SELECT * FROM Inserted) S
	ON (t.CODE = s.CODE)
	WHEN MATCHED THEN
	   UPDATE SET
	      T.MDFY_BY = UPPER(SUSER_NAME()),
	      T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Payment_Detail_Commodity_Sale] ADD CONSTRAINT [PK_Payment_Detail_Commodity_Sale] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Payment_Detail_Commodity_Sale] ADD CONSTRAINT [FK_PDCS_PROD] FOREIGN KEY ([PROD_CODE]) REFERENCES [dbo].[Product] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Payment_Detail_Commodity_Sale] ADD CONSTRAINT [FK_PDCS_PYDT] FOREIGN KEY ([PYDT_CODE]) REFERENCES [dbo].[Payment_Detail] ([CODE]) ON DELETE CASCADE
GO
