CREATE TABLE [dbo].[User_Club_Fgac]
(
[FGA_CODE] [bigint] NOT NULL,
[CLUB_CODE] [bigint] NULL,
[SYS_USER] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MAST_SYS_USER] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REC_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_UCFG_REC_STAT] DEFAULT ('002'),
[VALD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_UCFG_VALD_TYPE] DEFAULT ('002'),
[CRET_BY] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AINS_UCFG]
   ON  [dbo].[User_Club_Fgac]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- Insert statements for trigger here
   MERGE dbo.User_Club_Fgac T
   USING (SELECT * FROM INSERTED) S
   ON (T.CLUB_CODE = S.CLUB_CODE AND
       T.SYS_USER  = S.SYS_USER  AND
       T.REC_STAT  = S.REC_STAT AND
       T.REC_STAT  = '002')
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,FGA_CODE  = dbo.GNRT_NWID_U();
   
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_UCFG]
   ON  [dbo].[User_Club_Fgac]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   IF EXISTS(
      SELECT *
        FROM INSERTED S, User_Club_Fgac T
       WHERE S.FGA_CODE = T.FGA_CODE
         AND T.REC_STAT = '001' -- غیر فعال
         AND T.VALD_TYPE = '001' -- غیرقابل دیدن
   )
   BEGIN
      RAISERROR( N'اطلاعات غیرفعال و غیرقابل دیدن قابل ویرایش شدن نیستن' , 16, 1);
      RETURN;
   END
   
   ELSE IF EXISTS(
      SELECT *
        FROM DELETED S
       WHERE S.REC_STAT = '001' -- غیر فعال
         AND S.VALD_TYPE = '002' -- غیرقابل دیدن
   )
   BEGIN
      UPDATE DBO.User_Club_Fgac
         SET VALD_TYPE = '001'
            ,REC_STAT  = '001'
       WHERE FGA_CODE IN (SELECT FGA_CODE FROM DELETED);
   END
   
   -- Insert statements for trigger here
   MERGE dbo.User_Club_Fgac T
   USING (SELECT * FROM INSERTED) S
   ON (T.CLUB_CODE           = S.CLUB_CODE AND
       T.REC_STAT            = '002'       AND
       T.VALD_TYPE           = S.VALD_TYPE AND
       T.FGA_CODE            = S.FGA_CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE()
            ;
   
END
;
GO
ALTER TABLE [dbo].[User_Club_Fgac] ADD CONSTRAINT [PK_UCFG] PRIMARY KEY CLUSTERED  ([FGA_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[User_Club_Fgac] ADD CONSTRAINT [FK_UCFG_CLUB] FOREIGN KEY ([CLUB_CODE]) REFERENCES [dbo].[Club] ([CODE]) ON DELETE CASCADE
GO
