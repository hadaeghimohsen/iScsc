CREATE TABLE [dbo].[Report_Temporary]
(
[CODE] [bigint] NOT NULL,
[RPAP_CODE] [bigint] NULL,
[RQST_RQID] [bigint] NULL,
[COCH_FILE_NO] [bigint] NULL,
[CBMT_CODE] [bigint] NULL,
[FIGH_FILE_NO] [bigint] NULL,
[CTGY_CODE] [bigint] NULL,
[FNGR_PRNT_DNRM] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MBSP_RWNO] [smallint] NULL,
[MBSP_STRT_DATE] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MBSP_END_DATE] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MBSP_NUMB_ATTN] [int] NULL,
[MBSP_DEBT_DNRM] [bigint] NULL,
[MBSP_PYMT_AMNT] [bigint] NULL,
[MBSP_SUM_EXPN_AMNT] [bigint] NULL,
[MBSP_PYDS_AMNT] [bigint] NULL,
[RQST_CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FGPB_RWNO] [int] NULL
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
CREATE TRIGGER [dbo].[CG$AINS_RPTM]
   ON  [dbo].[Report_Temporary]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Report_Temporary T
   USING (SELECT * FROM Inserted) S
   ON (t.RPAP_CODE = s.RPAP_CODE AND t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END;
END
GO
ALTER TABLE [dbo].[Report_Temporary] ADD CONSTRAINT [PK_RPTM] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Report_Temporary] ADD CONSTRAINT [FK_RPTM_CBMT] FOREIGN KEY ([CBMT_CODE]) REFERENCES [dbo].[Club_Method] ([CODE])
GO
ALTER TABLE [dbo].[Report_Temporary] ADD CONSTRAINT [FK_RPTM_COCH] FOREIGN KEY ([COCH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Report_Temporary] ADD CONSTRAINT [FK_RPTM_CTGY] FOREIGN KEY ([CTGY_CODE]) REFERENCES [dbo].[Category_Belt] ([CODE])
GO
ALTER TABLE [dbo].[Report_Temporary] ADD CONSTRAINT [FK_RPTM_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Report_Temporary] ADD CONSTRAINT [FK_RPTM_RPAP] FOREIGN KEY ([RPAP_CODE]) REFERENCES [dbo].[Report_Action_Parameter] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Report_Temporary] ADD CONSTRAINT [FK_RPTM_RQST] FOREIGN KEY ([RQST_RQID]) REFERENCES [dbo].[Request] ([RQID])
GO
