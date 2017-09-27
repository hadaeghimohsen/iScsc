CREATE TABLE [dbo].[Planning_Overview]
(
[FIGH_FILE_NO] [bigint] NOT NULL,
[CODE] [bigint] NOT NULL CONSTRAINT [DF_PLAN_CODE] DEFAULT ((0)),
[PLAN_DESC] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[STRT_DATE] [datetime] NOT NULL,
[END_DATE] [datetime] NULL,
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

CREATE TRIGGER [dbo].[CG$AINS_PLAN]
   ON  [dbo].[Planning_Overview]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Planning_Overview T
   USING (SELECT * FROM INSERTED) S
   ON (T.FIGH_FILE_NO = S.FIGH_FILE_NO AND
       T.STRT_DATE    = S.STRT_DATE    AND
       T.END_DATE     = S.END_DATE)
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE      = DBO.GNRT_NVID_U();
END
;

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CG$AUPD_PLAN]
   ON  [dbo].[Planning_Overview]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Planning_Overview T
   USING (SELECT * FROM INSERTED) S
   ON (T.FIGH_FILE_NO = S.FIGH_FILE_NO AND
       T.STRT_DATE    = S.STRT_DATE    AND
       T.END_DATE     = S.END_DATE     AND
       T.CODE         = S.CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();             
END
;

GO
ALTER TABLE [dbo].[Planning_Overview] ADD CONSTRAINT [CK_PLAN_END_DATE] CHECK (([END_DATE]>[STRT_DATE]))
GO
ALTER TABLE [dbo].[Planning_Overview] ADD CONSTRAINT [CK_PLAN_STRT_DATE] CHECK (([STRT_DATE]<[END_DATE]))
GO
ALTER TABLE [dbo].[Planning_Overview] ADD CONSTRAINT [PLAN_PK] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Planning_Overview] ADD CONSTRAINT [FK_PLAN_FIGH] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
