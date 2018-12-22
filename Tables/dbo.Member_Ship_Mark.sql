CREATE TABLE [dbo].[Member_Ship_Mark]
(
[MBSP_FIGH_FILE_NO] [bigint] NULL,
[MBSP_RWNO] [smallint] NULL,
[MBSP_RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MARK_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[MARK_NUMB] [float] NULL,
[MARK_DESC] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_MBSM]
   ON  [dbo].[Member_Ship_Mark]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF EXISTS(
	   SELECT * 
	     FROM dbo.Member_Ship_Mark t, Inserted s 
	    WHERE T.MBSP_FIGH_FILE_NO = s.MBSP_FIGH_FILE_NO 
         AND T.MBSP_RWNO = S.MBSP_RWNO 
         AND T.MBSP_RECT_CODE = S.MBSP_RECT_CODE 
         AND T.MARK_CODE = S.MARK_CODE
         AND t.CODE <> s.CODE
   )
   BEGIN
      RAISERROR(N'این آیتم قبلا برای این دوره ثبت شده و تکراری میباشد', 16, 1);
      RETURN;
   END

   -- Insert statements for trigger here
   MERGE dbo.Member_Ship_Mark T
   USING (SELECT * FROM Inserted) S
   ON (T.MBSP_FIGH_FILE_NO = s.MBSP_FIGH_FILE_NO AND
       T.MBSP_RWNO = S.MBSP_RWNO AND
       T.MBSP_RECT_CODE = S.MBSP_RECT_CODE AND
       T.MARK_CODE = S.MARK_CODE)
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
CREATE TRIGGER [dbo].[CG$AUPD_MBSM]
   ON  [dbo].[Member_Ship_Mark]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF EXISTS(
	   SELECT * 
	     FROM dbo.Member_Ship_Mark t, Inserted s 
	    WHERE T.MBSP_FIGH_FILE_NO = s.MBSP_FIGH_FILE_NO 
         AND T.MBSP_RWNO = S.MBSP_RWNO 
         AND T.MBSP_RECT_CODE = S.MBSP_RECT_CODE 
         AND T.MARK_CODE = S.MARK_CODE
         AND t.CODE <> s.CODE
   )
   BEGIN
      RAISERROR(N'این آیتم قبلا برای این دوره ثبت شده و تکراری میباشد', 16, 1);
      RETURN;
   END
   
   IF EXISTS(
	   SELECT * 
	     FROM dbo.Member_Ship_Mark t, Inserted s , dbo.App_Base_Define ad
	    WHERE T.MBSP_FIGH_FILE_NO = s.MBSP_FIGH_FILE_NO 
         AND T.MBSP_RWNO = S.MBSP_RWNO 
         AND T.MBSP_RECT_CODE = S.MBSP_RECT_CODE 
         AND T.MARK_CODE = S.MARK_CODE
         AND t.CODE = s.CODE
         AND ad.CODE = t.MARK_CODE
         AND (ad.NUMB IS NOT NULL AND ad.NUMB > 0)
         AND s.MARK_NUMB > ad.NUMB * ISNULL(ad.UNIT, 1)
   )
   BEGIN
      RAISERROR(N'میزان نمره وارد شده بیش از حد مجاز می باشد، لطفا اصلاح کنید', 16, 1);
      RETURN;
   END

   -- Insert statements for trigger here
   MERGE dbo.Member_Ship_Mark T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         t.MDFY_BY = UPPER(SUSER_NAME())
        ,t.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Member_Ship_Mark] ADD CONSTRAINT [PK_MBSM] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Member_Ship_Mark] ADD CONSTRAINT [FK_MBSM_APBS] FOREIGN KEY ([MARK_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE])
GO
ALTER TABLE [dbo].[Member_Ship_Mark] ADD CONSTRAINT [FK_MBSM_MBSP] FOREIGN KEY ([MBSP_FIGH_FILE_NO], [MBSP_RWNO], [MBSP_RECT_CODE]) REFERENCES [dbo].[Member_Ship] ([FIGH_FILE_NO], [RWNO], [RECT_CODE])
GO
