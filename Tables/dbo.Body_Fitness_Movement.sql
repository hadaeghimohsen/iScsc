CREATE TABLE [dbo].[Body_Fitness_Movement]
(
[CHBF_BDFT_FIGH_FILE_NO] [bigint] NOT NULL,
[CHBF_BDFT_RECT_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CHBF_BDFT_RWNO] [int] NOT NULL,
[CHBF_BODY_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CHBF_RWNO] [smallint] NOT NULL,
[RWNO] [smallint] NOT NULL,
[BBFM_BFID] [bigint] NULL,
[WEEK_DAY_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REST_TIME_IN_SET] [time] (0) NULL,
[TIME_PER_SET] [time] (0) NULL,
[CONT] [smallint] NULL CONSTRAINT [DF_Body_Fitness_Movement_CONT] DEFAULT ((3)),
[NUMB_OF_MOVE_IN_SET] [smallint] NULL,
[AMNT_WEGH] [real] NULL,
[ORDR] [smallint] NULL,
[PRE_MOVE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_BFMM]
   ON  [dbo].[Body_Fitness_Movement]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here   
   
   MERGE dbo.Body_Fitness_Movement T
   USING (SELECT * FROM INSERTED i) S
   ON (T.CHBF_BDFT_FIGH_FILE_NO = S.CHBF_BDFT_FIGH_FILE_NO AND
       T.CHBF_BDFT_RECT_CODE    = S.CHBF_BDFT_RECT_CODE AND
       T.CHBF_BDFT_RWNO         = S.CHBF_BDFT_RWNO AND 
       T.CHBF_BODY_TYPE         = S.CHBF_BODY_TYPE AND
       T.CHBF_RWNO              = S.CHBF_RWNO AND
       T.RWNO                   = S.RWNO
       )
   WHEN MATCHED THEN
      UPDATE 
      SET CRET_BY   = UPPER(SUSER_NAME())
         ,CRET_DATE = GETDATE()
         ,RWNO      = (SELECT ISNULL(MAX(RWNO), 0) + 1 
                         FROM Body_Fitness_Movement 
                        WHERE CHBF_BDFT_FIGH_FILE_NO = S.CHBF_BDFT_FIGH_FILE_NO 
                          AND CHBF_BDFT_RECT_CODE = S.CHBF_BDFT_RECT_CODE 
                          AND CHBF_BDFT_RWNO = S.CHBF_BDFT_RWNO 
                          /*AND CHBF_BODY_TYPE = S.CHBF_BODY_TYPE*/);

END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_BFMM]
   ON  [dbo].[Body_Fitness_Movement]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here   
   
   MERGE dbo.Body_Fitness_Movement T
   USING (SELECT * FROM INSERTED i) S
   ON (T.CHBF_BDFT_FIGH_FILE_NO = S.CHBF_BDFT_FIGH_FILE_NO AND
       T.CHBF_BDFT_RECT_CODE    = S.CHBF_BDFT_RECT_CODE AND
       T.CHBF_BDFT_RWNO         = S.CHBF_BDFT_RWNO AND
       T.CHBF_BODY_TYPE         = S.CHBF_BODY_TYPE AND
       T.CHBF_RWNO              = S.CHBF_RWNO AND
       T.RWNO                   = S.RWNO)
   WHEN MATCHED THEN
      UPDATE 
      SET MDFY_BY   = UPPER(SUSER_NAME())
         ,MDFY_DATE = GETDATE();

END
;
GO
ALTER TABLE [dbo].[Body_Fitness_Movement] ADD CONSTRAINT [PK_BFMM] PRIMARY KEY CLUSTERED  ([CHBF_BDFT_FIGH_FILE_NO], [CHBF_BDFT_RECT_CODE], [CHBF_BDFT_RWNO], [CHBF_BODY_TYPE], [CHBF_RWNO], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Body_Fitness_Movement] ADD CONSTRAINT [FK_BDFM_BBFM] FOREIGN KEY ([BBFM_BFID]) REFERENCES [dbo].[Basic_Body_Fitness_Movement] ([BFID])
GO
ALTER TABLE [dbo].[Body_Fitness_Movement] ADD CONSTRAINT [FK_BFMM_CHBF] FOREIGN KEY ([CHBF_BDFT_FIGH_FILE_NO], [CHBF_BDFT_RECT_CODE], [CHBF_BDFT_RWNO], [CHBF_BODY_TYPE], [CHBF_RWNO]) REFERENCES [dbo].[Change_Body_Fitness] ([BDFT_FIGH_FILE_NO], [BDFT_RECT_CODE], [BDFT_RWNO], [BODY_TYPE], [RWNO])
GO
EXEC sp_addextendedproperty N'MS_Description', N'BFMM', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Movement', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'میزان وزنه', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Movement', 'COLUMN', N'AMNT_WEGH'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره پرونده', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Movement', 'COLUMN', N'CHBF_BDFT_FIGH_FILE_NO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد رکورد', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Movement', 'COLUMN', N'CHBF_BDFT_RECT_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Movement', 'COLUMN', N'CHBF_BDFT_RWNO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع عضو', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Movement', 'COLUMN', N'CHBF_BODY_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Movement', 'COLUMN', N'CHBF_RWNO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد هر ست تمرین', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Movement', 'COLUMN', N'NUMB_OF_MOVE_IN_SET'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ترتیب اولویت انجام حرکت ها', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Movement', 'COLUMN', N'ORDR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'حرکت پیش نیاز می باشد؟', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Movement', 'COLUMN', N'PRE_MOVE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمان استراحت بین نیم ست ها', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Movement', 'COLUMN', N'REST_TIME_IN_SET'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Movement', 'COLUMN', N'RWNO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'زمان هر ست تمرین', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Movement', 'COLUMN', N'TIME_PER_SET'
GO
EXEC sp_addextendedproperty N'MS_Description', N'روز های هفته', 'SCHEMA', N'dbo', 'TABLE', N'Body_Fitness_Movement', 'COLUMN', N'WEEK_DAY_TYPE'
GO
