CREATE TABLE [dbo].[Attendance_Wrist]
(
[ATTN_CODE] [bigint] NULL,
[ATNW_FIGH_FILE_NO] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RWNO] [int] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ATNW_FNGR_PRNT_DNRM] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DRES_CODE_DNRM] [bigint] NULL,
[FIGH_FILE_NO_DNRM] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_ATNW]
   ON  [dbo].[Attendance_Wrist]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Attendance_Wrist T
   USING (SELECT * FROM Inserted) S
   ON (T.ATTN_CODE = s.ATTN_CODE AND 
       t.ATNW_FIGH_FILE_NO = s.ATNW_FIGH_FILE_NO AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.RWNO = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Attendance_Wrist aw WHERE aw.ATTN_CODE = S.ATTN_CODE),
         T.STAT = ISNULL(S.STAT, '001'),
         t.FIGH_FILE_NO_DNRM = (SELECT a.FIGH_FILE_NO FROM dbo.Attendance a WHERE a.CODE = s.ATTN_CODE),
         t.DRES_CODE_DNRM = (SELECT TOP 1 d.DRES_CODE FROM dbo.Dresser_Vip_Fighter d WHERE t.ATNW_FIGH_FILE_NO = d.MBSP_FIGH_FILE_NO AND d.STAT = '002');
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
CREATE TRIGGER [dbo].[CG$AUPD_ATNW]
   ON  [dbo].[Attendance_Wrist]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Attendance_Wrist T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Attendance_Wrist] ADD CONSTRAINT [PK_Attendance_Wrist] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Attendance_Wrist] ADD CONSTRAINT [FK_ATNW_ATFG] FOREIGN KEY ([FIGH_FILE_NO_DNRM]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Attendance_Wrist] ADD CONSTRAINT [FK_ATNW_AWFG] FOREIGN KEY ([ATNW_FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Attendance_Wrist] ADD CONSTRAINT [FK_ATNW_DRES] FOREIGN KEY ([DRES_CODE_DNRM]) REFERENCES [dbo].[Dresser] ([CODE])
GO
ALTER TABLE [dbo].[Attendance_Wrist] ADD CONSTRAINT [FK_ATTN_ATNW] FOREIGN KEY ([ATTN_CODE]) REFERENCES [dbo].[Attendance] ([CODE]) ON DELETE CASCADE
GO
