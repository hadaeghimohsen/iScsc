CREATE TABLE [dbo].[Reason_Spec]
(
[RQTP_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RWNO] [smallint] NOT NULL CONSTRAINT [DF_Reason_Spec_RWNO] DEFAULT ((0)),
[RESN_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RESN]
   ON  [dbo].[Reason_Spec]
   AFTER INSERT
AS 
BEGIN
	MERGE Reason_Spec T
	USING (SELECT * FROM INSERTED) S
	ON (T.Rqtp_Code = S.Rqtp_Code AND
	    T.Rwno      = S.Rwno)
	WHEN MATCHED THEN
	   UPDATE 
	      SET CRET_BY = UPPER(SUSER_NAME())
	         ,CRET_DATE = GETDATE()
	         ,RWNO = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM Reason_Spec WHERE Rqtp_Code = S.Rqtp_Code);
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
CREATE TRIGGER [dbo].[CG$AUPD_RESN]
   ON  [dbo].[Reason_Spec]
   AFTER UPDATE
AS 
BEGIN
	MERGE Reason_Spec T
	USING (SELECT * FROM INSERTED) S
	ON (T.Rqtp_Code = S.Rqtp_Code AND
	    T.Rwno      = S.Rwno)
	WHEN MATCHED THEN
	   UPDATE 
	      SET MDFY_BY = UPPER(SUSER_NAME())
	         ,MDFY_DATE = GETDATE();
END

GO
ALTER TABLE [dbo].[Reason_Spec] ADD CONSTRAINT [PK_RESN] PRIMARY KEY CLUSTERED  ([RQTP_CODE], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Reason_Spec] ADD CONSTRAINT [FK_RESN_RQTP] FOREIGN KEY ([RQTP_CODE]) REFERENCES [dbo].[Request_Type] ([CODE])
GO
