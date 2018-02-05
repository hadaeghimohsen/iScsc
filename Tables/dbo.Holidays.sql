CREATE TABLE [dbo].[Holidays]
(
[CODE] [bigint] NOT NULL,
[YEAR] [int] NULL,
[CYCL] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HLDY_DATE] [date] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_HLDY]
   ON  [dbo].[Holidays]
   AFTER INSERT 
AS 
BEGIN
	MERGE dbo.Holidays T
	USING (SELECT * FROM Inserted) S
	ON (T.HLDY_DATE = S.HLDY_DATE)
	WHEN MATCHED THEN 
	   UPDATE SET
	      t.CRET_BY = UPPER(SUSER_NAME())
	     ,t.CRET_DATE = GETDATE()
	     ,t.CODE = dbo.GNRT_NVID_U();
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
CREATE TRIGGER [dbo].[CG$AUPD_HLDY]
   ON  [dbo].[Holidays]
   AFTER UPDATE 
AS 
BEGIN
	MERGE dbo.Holidays T
	USING (SELECT * FROM Inserted) S
	ON (T.CODE = s.CODE)
	WHEN MATCHED THEN 
	   UPDATE SET
	      t.MDFY_BY = UPPER(SUSER_NAME())
	     ,t.MDFY_DATE = GETDATE()
	     ,T.YEAR = SUBSTRING(dbo.GET_MTOS_U(s.HLDY_DATE), 1, 4)
	     ,T.CYCL = SUBSTRING(dbo.GET_MTOS_U(s.HLDY_DATE), 6, 2);
END
GO
ALTER TABLE [dbo].[Holidays] ADD CONSTRAINT [PK_HLDY] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
