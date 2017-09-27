CREATE TABLE [dbo].[Premovement_Body_Fitness]
(
[BBFM_BFID] [bigint] NOT NULL,
[PRE_BBFM_BFID] [bigint] NOT NULL,
[PMBF_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ORDR] [smallint] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Premovement_Body_Fitness_STAT] DEFAULT ('002'),
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
CREATE TRIGGER [dbo].[CG$AINS_PMBF]
   ON  [dbo].[Premovement_Body_Fitness]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here   
   
   MERGE dbo.[Premovement_Body_Fitness] T
   USING (SELECT * FROM INSERTED i) S
   ON (T.BBFM_BFID = S.BBFM_BFID AND
       T.PRE_BBFM_BFID = S.PRE_BBFM_BFID)
   WHEN MATCHED THEN
      UPDATE 
      SET CRET_BY   = UPPER(SUSER_NAME())
         ,CRET_DATE = GETDATE();
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_PMBF]
   ON  [dbo].[Premovement_Body_Fitness]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here   
   
   MERGE dbo.[Premovement_Body_Fitness] T
   USING (SELECT * FROM INSERTED i) S
   ON (T.BBFM_BFID = S.BBFM_BFID AND
       T.PRE_BBFM_BFID = S.PRE_BBFM_BFID)
   WHEN MATCHED THEN
      UPDATE 
      SET MDFY_BY   = UPPER(SUSER_NAME())
         ,MDFY_DATE = GETDATE();
END
;
GO
ALTER TABLE [dbo].[Premovement_Body_Fitness] ADD CONSTRAINT [PK_PMBF] PRIMARY KEY CLUSTERED  ([BBFM_BFID], [PRE_BBFM_BFID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Premovement_Body_Fitness] ADD CONSTRAINT [FK_PMBF_BBFM] FOREIGN KEY ([BBFM_BFID]) REFERENCES [dbo].[Basic_Body_Fitness_Movement] ([BFID])
GO
ALTER TABLE [dbo].[Premovement_Body_Fitness] ADD CONSTRAINT [FK_PPBF_BBFM] FOREIGN KEY ([PRE_BBFM_BFID]) REFERENCES [dbo].[Basic_Body_Fitness_Movement] ([BFID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'PMBF', 'SCHEMA', N'dbo', 'TABLE', N'Premovement_Body_Fitness', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'ترتیب اولیت', 'SCHEMA', N'dbo', 'TABLE', N'Premovement_Body_Fitness', 'COLUMN', N'ORDR'
GO
