CREATE TABLE [dbo].[Reason_Request]
(
[RESN_RQTP_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RESN_RWNO] [smallint] NOT NULL,
[RQRO_RQST_RQID] [bigint] NOT NULL,
[RQRO_RWNO] [smallint] NOT NULL,
[RWNO] [smallint] NOT NULL,
[OTHR_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RSRQ]
   ON  [dbo].[Reason_Request]
   AFTER INSERT
AS 
BEGIN
	MERGE Reason_Request T
	USING (SELECT * FROM INSERTED) S
	ON (T.Resn_Rqtp_Code = S.Resn_Rqtp_Code AND
	    T.Resn_Rwno      = S.Resn_Rwno      AND
	    T.Rqro_Rqst_Rqid = S.Rqro_Rqst_Rqid AND
	    T.Rqro_Rwno      = S.Rqro_Rwno      AND
	    T.Rwno           = S.Rwno)
	WHEN MATCHED THEN
	   UPDATE 
	      SET CRET_BY = UPPER(SUSER_NAME())
	         ,CRET_DATE = GETDATE()
	         ,Rwno = (SELECT ISNULL(MAX(RWNO), 0) + 1 
                       FROM Reason_Request T
                      WHERE T.Resn_Rqtp_Code = S.Resn_Rqtp_Code AND
	                         --T.Resn_Rwno      = S.Resn_Rwno      AND
	                         T.Rqro_Rqst_Rqid = S.Rqro_Rqst_Rqid AND
	                         T.Rqro_Rwno      = S.Rqro_Rwno      );
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
CREATE TRIGGER [dbo].[CG$AUPD_RSRQ]
   ON  [dbo].[Reason_Request]
   AFTER UPDATE
AS 
BEGIN
	MERGE Reason_Request T
	USING (SELECT * FROM INSERTED) S
	ON (T.Resn_Rqtp_Code = S.Resn_Rqtp_Code AND
	    T.Resn_Rwno      = S.Resn_Rwno      AND
	    T.Rqro_Rqst_Rqid = S.Rqro_Rqst_Rqid AND
	    T.Rqro_Rwno      = S.Rqro_Rwno      AND
	    T.Rwno           = S.Rwno)
	WHEN MATCHED THEN
	   UPDATE 
	      SET MDFY_BY = UPPER(SUSER_NAME())
	         ,MDFY_DATE = GETDATE();
END

GO
ALTER TABLE [dbo].[Reason_Request] ADD CONSTRAINT [PK_RSRQ] PRIMARY KEY CLUSTERED  ([RESN_RQTP_CODE], [RESN_RWNO], [RQRO_RQST_RQID], [RQRO_RWNO], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Reason_Request] ADD CONSTRAINT [FK_RSRQ_RESN] FOREIGN KEY ([RESN_RQTP_CODE], [RESN_RWNO]) REFERENCES [dbo].[Reason_Spec] ([RQTP_CODE], [RWNO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Reason_Request] ADD CONSTRAINT [FK_RSRQ_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO])
GO
