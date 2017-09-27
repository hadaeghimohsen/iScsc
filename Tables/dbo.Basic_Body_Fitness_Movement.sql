CREATE TABLE [dbo].[Basic_Body_Fitness_Movement]
(
[BFID] [bigint] NOT NULL,
[BODY_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[EFCT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BBFM_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REST_TIME_IN_SET] [time] (0) NULL,
[TIME_PER_SET] [time] (0) NULL,
[NUMB_OF_MOVE_IN_SET] [smallint] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_BBFT]
   ON  [dbo].[Basic_Body_Fitness_Movement]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here   
   
   MERGE dbo.[Basic_Body_Fitness_Movement] T
   USING (SELECT * FROM INSERTED i) S
   ON (T.BFID = S.BFID)
   WHEN MATCHED THEN
      UPDATE 
      SET CRET_BY   = UPPER(SUSER_NAME())
         ,CRET_DATE = GETDATE()
         ,BFID      = dbo.GNRT_NVID_U();

END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_BBFT]
   ON  [dbo].[Basic_Body_Fitness_Movement]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here   
   
   MERGE dbo.[Basic_Body_Fitness_Movement] T
   USING (SELECT * FROM INSERTED i) S
   ON (T.BFID = S.BFID)
   WHEN MATCHED THEN
      UPDATE 
      SET MDFY_BY   = UPPER(SUSER_NAME())
         ,MDFY_DATE = GETDATE();
END
;
GO
ALTER TABLE [dbo].[Basic_Body_Fitness_Movement] ADD CONSTRAINT [PK_BBFM] PRIMARY KEY CLUSTERED  ([BFID]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'BBFM', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Body_Fitness_Movement', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'شرح', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Body_Fitness_Movement', 'COLUMN', N'BBFM_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Body_Fitness_Movement', 'COLUMN', N'BFID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'عضو بدن', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Body_Fitness_Movement', 'COLUMN', N'BODY_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع تاثیرگذاری', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Body_Fitness_Movement', 'COLUMN', N'EFCT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد حرکت هر ست', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Body_Fitness_Movement', 'COLUMN', N'NUMB_OF_MOVE_IN_SET'
GO
EXEC sp_addextendedproperty N'MS_Description', N'میزان استراحت هر هست حرکتی', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Body_Fitness_Movement', 'COLUMN', N'REST_TIME_IN_SET'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Body_Fitness_Movement', 'COLUMN', N'STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان هر ست حرکت', 'SCHEMA', N'dbo', 'TABLE', N'Basic_Body_Fitness_Movement', 'COLUMN', N'TIME_PER_SET'
GO
