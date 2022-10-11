CREATE TABLE [dbo].[Fighter_Coupon]
(
[RQRO_RQST_RQID] [bigint] NULL,
[RQRO_RWNO] [smallint] NULL,
[COPN_CODE] [bigint] NULL,
[FIGH_FILE_NO] [bigint] NULL,
[COPN_EXPN_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[COPN_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RQST_RQID] [bigint] NULL,
[CRET_TEMP_TMID] [bigint] NULL,
[USE_TEMP_TMID] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_FCPN]
   ON  [dbo].[Fighter_Coupon]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Fighter_Coupon T
   USING (SELECT * FROM Inserted) S
   ON (T.RQRO_RQST_RQID = S.RQRO_RQST_RQID AND 
       T.RQRO_RWNO = s.RQRO_RWNO AND 
       T.COPN_CODE = s.COPN_CODE AND        
       T.FIGH_FILE_NO = S.FIGH_FILE_NO AND 
       t.COPN_EXPN_CODE = s.COPN_EXPN_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.STAT = ISNULL(s.STAT, '002');
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
CREATE TRIGGER [dbo].[CG$AUPD_FCPN]
   ON  [dbo].[Fighter_Coupon]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Fighter_Coupon T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Fighter_Coupon] ADD CONSTRAINT [PK_Fighter_Coupon] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Fighter_Coupon] ADD CONSTRAINT [FK_FCPN_COPN] FOREIGN KEY ([COPN_CODE]) REFERENCES [dbo].[Coupon] ([CODE])
GO
ALTER TABLE [dbo].[Fighter_Coupon] ADD CONSTRAINT [FK_FCPN_CTMP] FOREIGN KEY ([CRET_TEMP_TMID]) REFERENCES [dbo].[Template] ([TMID])
GO
ALTER TABLE [dbo].[Fighter_Coupon] ADD CONSTRAINT [FK_FCPN_EXPN] FOREIGN KEY ([COPN_EXPN_CODE]) REFERENCES [dbo].[Expense] ([CODE])
GO
ALTER TABLE [dbo].[Fighter_Coupon] ADD CONSTRAINT [FK_FCPN_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Fighter_Coupon] ADD CONSTRAINT [FK_FCPN_RQRO] FOREIGN KEY ([RQRO_RQST_RQID], [RQRO_RWNO]) REFERENCES [dbo].[Request_Row] ([RQST_RQID], [RWNO])
GO
ALTER TABLE [dbo].[Fighter_Coupon] ADD CONSTRAINT [FK_FCPN_RQST] FOREIGN KEY ([RQST_RQID]) REFERENCES [dbo].[Request] ([RQID])
GO
ALTER TABLE [dbo].[Fighter_Coupon] ADD CONSTRAINT [FK_FCPN_UTMP] FOREIGN KEY ([USE_TEMP_TMID]) REFERENCES [dbo].[Template] ([TMID])
GO
