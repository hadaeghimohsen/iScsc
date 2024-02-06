CREATE TABLE [dbo].[Dresser_Vip_Fighter]
(
[DRES_CODE] [bigint] NULL,
[MBSP_FIGH_FILE_NO] [bigint] NULL,
[MBSP_RWNO] [smallint] NULL,
[MBSP_RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CODE] [bigint] NOT NULL,
[DRES_NUMB] [int] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPR_DATE] [date] NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [BLOB]
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
CREATE TRIGGER [dbo].[CG$AINS_DVPF]
   ON  [dbo].[Dresser_Vip_Fighter]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Dresser_Vip_Fighter T
   USING (SELECT * FROM Inserted) S
   ON (T.DRES_CODE = S.DRES_CODE AND 
       T.MBSP_FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO AND
       T.MBSP_RWNO = S.MBSP_RWNO AND
       T.MBSP_RECT_CODE = s.MBSP_RECT_CODE AND        
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.STAT = ISNULL(S.STAT, '002'),
         T.DRES_NUMB = (SELECT d.DRES_NUMB
                          FROM dbo.Dresser d
                         WHERE d.CODE = s.DRES_CODE);
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
CREATE TRIGGER [dbo].[CG$AUPD_DVPF]
   ON  [dbo].[Dresser_Vip_Fighter]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Dresser_Vip_Fighter T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Dresser_Vip_Fighter] ADD CONSTRAINT [PK_Dresser_Vip_Fighter] PRIMARY KEY CLUSTERED  ([CODE]) ON [BLOB]
GO
ALTER TABLE [dbo].[Dresser_Vip_Fighter] ADD CONSTRAINT [FK_DVPF_DRES] FOREIGN KEY ([DRES_CODE]) REFERENCES [dbo].[Dresser] ([CODE])
GO
ALTER TABLE [dbo].[Dresser_Vip_Fighter] ADD CONSTRAINT [FK_DVPF_FIGH] FOREIGN KEY ([MBSP_FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Dresser_Vip_Fighter] ADD CONSTRAINT [FK_DVPF_MBSP] FOREIGN KEY ([MBSP_FIGH_FILE_NO], [MBSP_RWNO], [MBSP_RECT_CODE]) REFERENCES [dbo].[Member_Ship] ([FIGH_FILE_NO], [RWNO], [RECT_CODE]) ON DELETE CASCADE
GO
